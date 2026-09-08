#!/usr/bin/env python3
"""Compile real RNCarPlay methods with native Foundation fakes for deterministic races."""
from pathlib import Path
import subprocess, tempfile, sys
root=Path(__file__).resolve().parents[2]
s=(Path(sys.argv[1]) if len(sys.argv)>1 else root/'ios/RNCarPlay.m').read_text()
def method(start):
 a=s.index(start); body=s.index('{',a); end=body+1; depth=1
 while depth:
  if s[end]=='{': depth+=1
  elif s[end]=='}': depth-=1
  end+=1
 return s[a:end]
source=(Path(__file__).with_name('Harness.m')).read_text().replace('/* ACTUAL_METHODS */','\n'.join(method(x) for x in ['RCT_EXPORT_METHOD(pushTemplate:', '- (void)updateItemImageWithURL:', '- (void)updateListRowItemImageWithURL:']))
with tempfile.TemporaryDirectory(prefix='rncp-native-') as temp:
 p=Path(temp);(p/'test.m').write_text(source)
 subprocess.run(['xcrun','clang','-fobjc-arc','-fblocks','-framework','Foundation',str(p/'test.m'),'-o',str(p/'test')],check=True)
 subprocess.run([str(p/'test')],check=True,timeout=20)
