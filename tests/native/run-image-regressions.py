#!/usr/bin/env python3
"""Exercise production image conversion and list methods with Foundation doubles."""
from pathlib import Path
import subprocess
import sys
import tempfile

from source_methods import extract_method

root = Path(__file__).resolve().parents[2]
package = Path(sys.argv[1]) if len(sys.argv) > 1 else root
native = (package / 'ios/RNCarPlay.m').read_text()
converter = (package / 'ios/RCTConvert+RNCarPlay.m').read_text()
signature = '+ (UIImage *)RNCPUIImage:'
if signature in converter:
    image_converter = extract_method(converter, signature)
else:
    # Lets the unpatched package compile, then reproduce its fatal conversion.
    image_converter = '+ (UIImage *)RNCPUIImage:(id)json { return [self UIImage:json]; }'
methods = '\n'.join(extract_method(native, signature) for signature in [
    'RCT_EXPORT_METHOD(updateListTemplateItem:',
    '- (BOOL)isImageSourceURL:',
    '- (NSString *)getURLStringFromImageSource:',
    '- (NSArray<CPSelectableListItem>*)parseListItems:',
])
# The test doubles share the same common NSObject base, not the CarPlay protocol.
methods = methods.replace('NSArray<CPSelectableListItem>*', 'NSArray*')
source = (root / 'tests/native/ImageHarness.m').read_text().replace(
    '/* IMAGE_CONVERTER */', image_converter).replace('/* ACTUAL_METHODS */', methods)
with tempfile.TemporaryDirectory(prefix='rncp-images-') as temp:
    path = Path(temp)
    (path / 'test.m').write_text(source)
    subprocess.run(['xcrun', 'clang', '-fobjc-arc', '-fblocks', '-framework',
                    'Foundation', str(path / 'test.m'), '-o', str(path / 'test')], check=True)
    subprocess.run([str(path / 'test')], check=True, timeout=20)

if '[RCTConvert UIImage:' in native or '[RCTConvert UIImage:' in converter:
    raise AssertionError('A CarPlay image conversion bypasses RNCPUIImage')
print('PASS: all native CarPlay image conversion sites use the shared safe boundary')
