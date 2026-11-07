#!/usr/bin/env python3
"""Syntax-check the production converter against real iOS SDK types, without Pods."""
from pathlib import Path
import subprocess
import tempfile

root = Path(__file__).resolve().parents[2]
sdk = subprocess.check_output(
    ['xcrun', '--sdk', 'iphonesimulator', '--show-sdk-path'], text=True).strip()
with tempfile.TemporaryDirectory(prefix='rncp-image-sdk-') as temp:
    path = Path(temp)
    react = path / 'React'
    react.mkdir()
    (react / 'RCTConvert.h').write_text('''
#import <UIKit/UIKit.h>
#import <CoreLocation/CoreLocation.h>
@interface RCTConvert : NSObject
+ (UIImage *)UIImage:(id)json;
+ (BOOL)BOOL:(id)json;
+ (double)double:(id)json;
+ (NSString *)NSString:(id)json;
+ (NSArray<NSString *> *)NSStringArray:(id)json;
@end
#define RCT_ENUM_CONVERTER(type, values, fallback, getter) \\
    + (type)type:(id)json { return fallback; }
''')
    (react / 'RCTConvert+CoreLocation.h').write_text('')
    (react / 'RCTLog.h').write_text('#define RCTLogWarn(...) NSLog(__VA_ARGS__)\n')
    subprocess.run([
        'xcrun', 'clang', '-fobjc-arc', '-fblocks', '-fsyntax-only',
        '-target', 'arm64-apple-ios16.0-simulator', '-isysroot', sdk,
        # The pre-existing category declarations mix annotated/unannotated types.
        '-I', str(path), '-Werror', '-Wno-nullability-completeness',
        str(root / 'ios/RCTConvert+RNCarPlay.m'),
    ], check=True)
print('PASS: production image converter compiles against real UIKit/CarPlay iOS SDK types')
