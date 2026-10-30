// Executes the production NowPlayingTemplate wrapper with a controlled native bridge, and an asset
// resolver that behaves like React Native's: a key that names an image but holds a plain string
// comes back null. `systemImage` ended in "Image", so parseConfig resolved every SF Symbol name to
// null and all three buttons reached CarPlay as placeholder circles.
const { test } = require('node:test');
const assert = require('node:assert/strict');
const fs = require('node:fs');
const path = require('node:path');
const vm = require('node:vm');
const ts = require('typescript');
const packageRoot = process.env.CARPLAY_PACKAGE_ROOT || path.resolve(__dirname, '..');
const sourceKind = process.env.CARPLAY_SOURCE_KIND || 'src';
const extension = sourceKind === 'lib' ? '.js' : '.ts';

const resolveAssetSource = source => {
  if (source && typeof source === 'object') return source;
  return typeof source === 'number' ? { uri: 'asset-' + source, width: 78, height: 78, scale: 1 } : null;
};

function harness() {
  const created = [], updated = [], cache = new Map();
  const bridge = {
    createTemplate: (id, config) => created.push(config),
    updateTemplate: (id, config) => updated.push(config),
  };
  const carplay = { bridge, emitter: { addListener: () => ({ remove() {} }) } };
  const native = { Platform: { OS: 'ios', select: options => options.ios }, Image: { resolveAssetSource } };
  function load(file) {
    if (cache.has(file)) return cache.get(file).exports;
    const module = { exports: {} }; cache.set(file, module);
    const source = ts.transpileModule(fs.readFileSync(file, 'utf8'), { compilerOptions: { module: ts.ModuleKind.CommonJS, target: ts.ScriptTarget.ES2020 } }).outputText;
    const localRequire = name => {
      if (name === 'react-native') return native;
      if (name.includes('resolveAssetSource')) return { default: resolveAssetSource };
      if (name === '../CarPlay') return { CarPlay: carplay };
      if (name.startsWith('.')) return load(path.resolve(path.dirname(file), name + extension));
      throw new Error('Unexpected import: ' + name);
    };
    vm.runInNewContext(source, { module, exports: module.exports, require: localRequire, console }, { filename: file });
    return module.exports;
  }
  const { NowPlayingTemplate } = load(path.join(packageRoot, sourceKind, 'templates/NowPlayingTemplate' + extension));
  return { NowPlayingTemplate, created, updated };
}

// Values cross a vm context, so compare their JSON shape rather than their realm's prototypes.
const plain = value => JSON.parse(JSON.stringify(value));

const buttons = [
  { id: 'save', type: 'image', systemImageName: 'heart.fill', image: 7 },
  { id: 'shuffle', type: 'image', systemImageName: 'shuffle', image: 8, selected: true },
  { id: 'repeat', type: 'image', systemImageName: 'repeat.1', selected: false },
];

test('symbol names, selected state and fallback images reach the bridge on create', () => {
  const h = harness();
  new h.NowPlayingTemplate({ buttons });
  const sent = plain(h.created[0].buttons);
  assert.deepEqual(sent.map(b => b.systemImageName), ['heart.fill', 'shuffle', 'repeat.1']);
  assert.deepEqual(sent.map(b => b.selected ?? null), [null, true, false]);
  assert.equal(sent[0].image.uri, 'asset-7');
  assert.equal(sent[2].image, undefined);
});

test('and survive updateTemplate, which rebuilds every button', () => {
  const h = harness();
  const template = new h.NowPlayingTemplate({ buttons: [] });
  template.updateTemplate({ buttons });
  const sent = plain(h.updated[0].buttons);
  assert.deepEqual(sent.map(b => b.systemImageName), ['heart.fill', 'shuffle', 'repeat.1']);
  assert.equal(sent[1].selected, true);
});
