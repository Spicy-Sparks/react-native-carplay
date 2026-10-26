// Executes the production TypeScript wrappers with a controlled native bridge.
const { test } = require('node:test');
const assert = require('node:assert/strict');
const { EventEmitter } = require('node:events');
const fs = require('node:fs');
const path = require('node:path');
const vm = require('node:vm');
const ts = require('typescript');
const packageRoot = process.env.CARPLAY_PACKAGE_ROOT || path.resolve(__dirname, '..');
const sourceKind = process.env.CARPLAY_SOURCE_KIND || 'src';
const extension = sourceKind === 'lib' ? '.js' : '.ts';

const deferred = () => {
  let resolve, reject;
  const promise = new Promise((yes, no) => { resolve = yes; reject = no; });
  return { promise, resolve, reject };
};
const flush = async () => { for (let i = 0; i < 15; i++) await Promise.resolve(); };
function harness(legacy = false) {
  const events = new EventEmitter();
  events.setMaxListeners(0);
  const replies = [], selections = [], errors = [], cache = new Map();
  const bridge = {
    createTemplate() {}, updateTemplate() {},
    reactToUpdatedSearchText: (...args) => replies.push(args),
    reactToSelectedResult: (...args) => selections.push(args),
    ...(!legacy && {
      reactToUpdatedSearchTextForRequest: (...args) => replies.push(args),
      reactToSelectedResultForRequest: (...args) => selections.push(args),
    }),
  };
  const carplay = { bridge, emitter: { addListener(name, callback) {
    events.on(name, callback);
    return { remove: () => events.off(name, callback) };
  } } };
  const native = { Platform: { OS: 'ios', select: options => options.ios }, Image: { resolveAssetSource: image => image } };
  function load(file) {
    if (cache.has(file)) return cache.get(file).exports;
    const module = { exports: {} }; cache.set(file, module);
    const source = ts.transpileModule(fs.readFileSync(file, 'utf8'), { compilerOptions: { module: ts.ModuleKind.CommonJS, target: ts.ScriptTarget.ES2020 } }).outputText;
    const localRequire = name => {
      if (name === 'react-native') return native;
      if (name.includes('resolveAssetSource')) return { default: image => image };
      if (name === '../CarPlay') return { CarPlay: carplay };
      if (name.startsWith('.')) return load(path.resolve(path.dirname(file), name + extension));
      throw new Error('Unexpected import: ' + name);
    };
    vm.runInNewContext(source, { module, exports: module.exports, require: localRequire, console: { error: (...args) => errors.push(args) } }, { filename: file });
    return module.exports;
  }
  const SearchTemplate = load(path.join(packageRoot, sourceKind, 'templates/SearchTemplate' + extension)).SearchTemplate;
  const ListTemplate = load(path.join(packageRoot, sourceKind, 'templates/ListTemplate' + extension)).ListTemplate;
  const emit = (name, template, fields = {}) => events.emit(name, { templateId: template.id, ...fields });
  return { SearchTemplate, ListTemplate, events, emit, replies, selections, errors };
}

test('out-of-order searches complete their own token and discard stale rows', async () => {
  const h = harness(), a = deferred(), b = deferred();
  const template = new h.SearchTemplate({ onSearch: query => query === 'a' ? a.promise : b.promise });
  h.emit('updatedSearchText', template, { searchText: 'a', requestId: '1' });
  h.emit('updatedSearchText', template, { searchText: 'b', requestId: '2' });
  await flush(); b.resolve([{ text: 'new' }]); await flush();
  a.resolve([{ text: 'old' }]); await flush();
  assert.equal(h.replies.length, 2);
  assert.equal(h.replies[0][0][0].text, 'new');
  assert.equal(h.replies[0][2], '2');
  assert.equal(h.replies[1][0].length, 0);
  assert.equal(h.replies[1][2], '1');
});

test('search and list selections never consume each other and await dispatch', async () => {
  const h = harness(), a = deferred(), b = deferred();
  const search = new h.SearchTemplate({ onItemSelect: () => a.promise });
  const list = new h.ListTemplate({ sections: [], onItemSelect: () => b.promise });
  h.emit('selectedResult', search, { index: 0, requestId: 'search' });
  h.emit('didSelectListItem', list, { index: 0, requestId: 'list' });
  await flush(); assert.equal(h.selections.length, 0);
  a.resolve(); await flush(); b.resolve(); await flush();
  assert.deepEqual(h.selections, [[search.id, 'search'], [list.id, 'list']]);
});

test('synchronous throws, rejected callbacks and absent handlers finish native requests', async () => {
  const h = harness();
  const search = new h.SearchTemplate({ onSearch() { throw new Error('offline'); }, onItemSelect: async () => { throw new Error('failed'); } });
  const list = new h.ListTemplate({ sections: [] });
  h.emit('updatedSearchText', search, { searchText: 'query', requestId: 'q' });
  h.emit('selectedResult', search, { index: 0, requestId: 's' });
  h.emit('didSelectListItem', list, { index: 0, requestId: 'l' });
  await flush();
  assert.equal(h.errors.length, 2);
  assert.equal(h.replies[0][0].length, 0);
  assert.equal(h.replies[0][2], 'q');
  assert.equal(h.selections.length, 2);
});

test('old native binaries receive only the latest response across templates', async () => {
  const h = harness(true), a = deferred(), b = deferred();
  const first = new h.SearchTemplate({ onSearch: () => a.promise });
  const second = new h.SearchTemplate({ onSearch: () => b.promise });
  h.emit('updatedSearchText', first, { searchText: 'a' });
  h.emit('updatedSearchText', second, { searchText: 'b' });
  await flush(); a.resolve([{ text: 'old' }]); await flush();
  assert.equal(h.replies.length, 0);
  b.resolve([{ text: 'new' }]); await flush();
  assert.equal(h.replies.length, 1);
  assert.equal(h.replies[0][1], second.id);
});

test('hiding preserves a reusable template; removal releases every listener exactly once', async () => {
  const h = harness(); let removed = 0;
  const template = new h.SearchTemplate({ onSearch: async () => [{ text: 'ok' }], onRemoved: () => removed++ });
  h.emit('didDisappear', template);
  assert.equal(template.disposed, false);
  h.emit('updatedSearchText', template, { searchText: 'again', requestId: 'back' });
  await flush(); assert.equal(h.replies.length, 1);
  h.emit('templateRemoved', template); template.dispose();
  assert.equal(removed, 1);
  assert.equal(h.events.eventNames().length, 0);
  for (let i = 0; i < 25; i++) {
    const next = new h.SearchTemplate({}); h.emit('templateRemoved', next);
  }
  assert.equal(h.events.eventNames().length, 0);
});

test('a pending search cannot publish rows after native removal', async () => {
  const h = harness(), pending = deferred();
  const template = new h.SearchTemplate({ onSearch: () => pending.promise });
  h.emit('updatedSearchText', template, { searchText: 'query', requestId: 'gone' });
  await flush(); h.emit('templateRemoved', template);
  pending.resolve([{ text: 'too late' }]); await flush();
  assert.equal(h.replies[0][0].length, 0);
  assert.equal(h.replies[0][2], 'gone');
});
