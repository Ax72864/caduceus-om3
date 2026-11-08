#!/usr/bin/env python3
"""Emulator test of the stock RGB-gamma copier 0x605169a4 (a0 = output O, a1/d0/d1 = R/G/B curve objects).
usage: python3 copier_test.py make > copier.json      (then: NCALL=copier.json NOUT=out.json session_ed1.mjs ... ncall)
       python3 copier_test.py check out.json          (compares the emulator's O with the curve data in $OM3_MAIN)
O = B+0x1000 (0x1000 B, pre-filled with 0xA5 to see what is written). Cases: Cross Process I, COLOR, Vintage-like 0x01010079.
"""
import json, os, struct, sys
COPY, BASE = 0x605169a4, 0x60021020
CASES = {'XP1': (0x6066dbac, 0x6066e03c, 0x6066e4cc), 'COLOR': (0x6066c04c,) * 3,
         'A79': (0x60671b8c, 0x6067201c, 0x606724ac)}
if sys.argv[1] == 'make':
    out = []
    for n, (r, g, b) in CASES.items():
        out.append({'name': n, 'pc': 'B', 'stop': ['B+7'],
                    'mem': [['B', 'dd'], ['B+1', f'={COPY:#x}-B'], ['B+5', 'f020'], ['B+0x1000', 'a5' * 0x1000]],
                    'regs': {'a0': 'B+0x1000', 'a1': hex(r), 'd0': hex(g), 'd1': hex(b)},
                    'read': [['B+0x1000', 0x1000]]})
    print(json.dumps(out))
else:
    d = json.load(open(sys.argv[2])); blob = open(os.environ['OM3_MAIN'], 'rb').read()
    Bv = int(d['B'], 16); O = Bv + 0x1000
    for o, (n, objs) in zip(d['out'], CASES.items()):
        m = bytes.fromhex(o['mem'][0]); ok = True
        for ch, (obj, off) in enumerate(zip(objs, (1252, 1892, 2532))):
            src = obj - BASE
            ok &= m[off:off + 512] == blob[src + 144:src + 656]          # 256 x u16
            ok &= m[off + 512:off + 640] == blob[src + 16:src + 144]     # 64 x u16 fine table
            ok &= struct.unpack('<I', m[3172 + 4 * ch:3176 + 4 * ch])[0] == O + off
        written = [i for i in range(0x1000) if m[i] != 0xa5]
        spans = []
        for i in written:
            if spans and spans[-1][1] == i - 1: spans[-1][1] = i
            else: spans.append([i, i])
        print(n, 'steps', o['steps'], 'copies+pointers OK' if ok else 'MISMATCH',
              'written', [f'{a}..{b}' for a, b in spans])
