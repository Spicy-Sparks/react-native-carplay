#!/usr/bin/env python3
"""Compile real RNCarPlay methods with native Foundation fakes for deterministic races."""
from pathlib import Path
import subprocess, tempfile, sys
from source_methods import extract_method
root=Path(__file__).resolve().parents[2]
s=(Path(sys.argv[1]) if len(sys.argv)>1 else root/'ios/RNCarPlay.m').read_text()
def method(start):
 return extract_method(s, start)
source=(Path(__file__).with_name('Harness.m')).read_text().replace('/* ACTUAL_METHODS */','\n'.join(method(x) for x in ['RCT_EXPORT_METHOD(pushTemplate:', '- (void)updateItemImageWithURL:', '- (void)updateListRowItemImageWithURL:', 'RCT_EXPORT_METHOD(reactToUpdatedSearchText:', '- (NSNumber *)listItemIndex:']))
with tempfile.TemporaryDirectory(prefix='rncp-native-') as temp:
 p=Path(temp);(p/'test.m').write_text(source)
 subprocess.run(['xcrun','clang','-fobjc-arc','-fblocks','-framework','Foundation',str(p/'test.m'),'-o',str(p/'test')],check=True)
 subprocess.run([str(p/'test')],check=True,timeout=20)

request_methods = [
    '- (NSString *)nextRequestId', '- (void)completeSearch:',
    '- (void)completeSelection:', '- (void)cancelSearchesForTemplate:',
    '- (void)cancelRequestsForTemplate:', '- (void)removeSearchTemplate:',
    'RCT_EXPORT_METHOD(reactToUpdatedSearchTextForRequest:',
    'RCT_EXPORT_METHOD(reactToSelectedResultForRequest:',
    '- (void)searchTemplate:(CPSearchTemplate *)searchTemplate selectedResult:',
    '- (void)searchTemplate:(CPSearchTemplate *)searchTemplate updatedSearchText:',
    '- (NSNumber *)listItemIndex:',
    '- (void)listTemplate:(CPListTemplate *)listTemplate didSelectListItem:',
    '- (void)templateDidDisappear:',
]
request_source = Path(__file__).with_name('RequestHarness.m').read_text().replace(
    '/* ACTUAL_METHODS */', '\n'.join(method(x) for x in request_methods))
with tempfile.TemporaryDirectory(prefix='rncp-requests-') as temp:
 p=Path(temp);(p/'test.m').write_text(request_source)
 subprocess.run(['xcrun','clang','-fobjc-arc','-fblocks','-framework','Foundation',str(p/'test.m'),'-o',str(p/'test')],check=True)
 subprocess.run([str(p/'test')],check=True,timeout=20)
