#!/usr/bin/env python3
"""Stream objdump output for one firmware main block into a compact instruction
table: address, length, first byte, second byte, and a 32-bit operand (abs32 or
call/jmp target when present). Saves an .npz. Usage: tokenize.py ep7|om3 OUT.npz"""
import re, subprocess, sys
import numpy as np

OBJDUMP = '/home/claude/om3/toolchain/build/binutils/objdump'
M = dict(ep7=('/home/claude/om3/ep7_decoded/00_0100_406a0000.decoded.bin', 0x60020020),
         om3=('/home/claude/om3/decoded/00_0100_50000000.decoded.bin', 0x60021020))
path, base = M[sys.argv[1]]
p = subprocess.Popen([OBJDUMP, '-b', 'binary', '-m', 'mn10300', '-D', '-z', '--insn-width=16',
                      f'--adjust-vma={base:#x}', path], stdout=subprocess.PIPE, text=True, bufsize=1 << 20)
rx = re.compile(r'\s*([0-9a-f]+):\t((?:[0-9a-f]{2} )+)\s*\t?(\S*)\s*(.*)')
tgt = re.compile(r'0x([0-9a-f]{8})')
A, L, B0, B1, T = [], [], [], [], []
for line in p.stdout:
    m = rx.match(line)
    if not m:
        continue
    hx = m.group(2).replace(' ', '')
    n = len(hx) // 2
    b0 = int(hx[0:2], 16)
    if b0 == 0xff and n == 1:
        continue                      # break/padding
    A.append(int(m.group(1), 16)); L.append(n); B0.append(b0)
    B1.append(int(hx[2:4], 16) if n > 1 else 0)
    t = tgt.search(m.group(4))
    T.append(int(t.group(1), 16) if t else 0)
p.wait()
np.savez_compressed(sys.argv[2], a=np.array(A, np.uint32), l=np.array(L, np.uint8),
                    b0=np.array(B0, np.uint8), b1=np.array(B1, np.uint8), t=np.array(T, np.uint32), base=base)
print(sys.argv[1], len(A), 'instructions')
