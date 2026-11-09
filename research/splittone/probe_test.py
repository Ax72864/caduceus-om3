#!/usr/bin/env python3
"""Emulator test of split toning (st_run; probe st1, v0.26): stock RGB gamma stage 0x60516ad9 on a synthetic COLOR
still, then our tone hook (tone -> st_run -> tone_next), twice (the second pass must not bend again).
usage: python3 probe_test.py make TONE_ADDR [SLOTBYTES] > spec.json  (NCALL=spec.json NOUT=out.json sess7.mjs ... 'tokens ncall')
       SLOTBYTES (v0.26): hex for COLOR 1's slot +55..+58 (Shadows colour, strength, Highlights colour, strength),
       e.g. 08050105 = Cyan 5 / Orange 5; written to P+87 before the passes.
       python3 probe_test.py check out.json   (prints grey tints of the result, R/G/B identical or not)
"""
import json, sys
STAGE, NEXT = 0x60516ad9, 0x60518fa4
def mem():
    return [['B', 'dd'], ['B+1', f'={STAGE:#x}-B'], ['B+5', 'f010'],            # call stage,[d2,d3,a2,a3],16
            ['B+7', 'dd'], ['B+8', '=TONE-(B+7)'], ['B+12', 'f038'],          # call tone,[d2,d3,a2,a3],56
            ['B+0x200', '00' * 0x100], ['B+0x400', '00' * 0x800], ['B+0x1000', '00' * 0x1000],
            ['B+0x204', '=B+0x400'], ['B+0x20c', '=B+0x1000'], ['B+0x230', '=11'],
            ['B+0x408', '00000b00'], ['B+0x40e', '0010'], ['B+0x400+1660', '40143018' * 2]]
if sys.argv[1] == 'make':
    T = sys.argv[2]
    rd = [['B+0x1000+1252', 1920]]
    m = [[a, v.replace('TONE', T)] for a, v in mem()]
    if len(sys.argv) > 3: m.append(['P+87', sys.argv[3]])
    again = [['B+0x1000', '00' * 4], ['B', 'cb' * 7]]                           # second pass: tone only (nop the stage call)
    print(json.dumps([{'name': 'pass1', 'pc': 'B', 'regs': {'a0': 'B+0x200', 'd3': 'B+0x200'}, 'stop': [hex(NEXT)], 'mem': m, 'read': rd, 'max': 3000000},
                      {'name': 'pass2', 'pc': 'B', 'regs': {'a0': 'B+0x200', 'd3': 'B+0x200'}, 'stop': [hex(NEXT)], 'mem': [['B', 'cb' * 7]], 'read': rd, 'max': 3000000}]))
else:
    d = json.load(open(sys.argv[2]))
    for o in d['out']:
        b = bytes.fromhex(o['mem'][0]); ch = [[int.from_bytes(b[640 * c + 2 * i:640 * c + 2 * i + 2], 'little') for i in range(320)] for c in range(3)]
        print(o['name'], 'steps', o['steps'], 'pc', o['regs']['pc'], 'R==G==B' if ch[0] == ch[1] == ch[2] else 'toned')
        for i in (16, 32, 64, 96, 128, 192, 240):
            r, g, bb = (x[i] / 16 for x in ch); y = .299 * r + .587 * g + .114 * bb
            print(f'   in {i:3d}  R {r:6.1f} G {g:6.1f} B {bb:6.1f}   Y {y:6.1f} Cb {0.564 * (bb - y):+5.1f} Cr {0.713 * (r - y):+5.1f}')
        print('   rising:', all(all(x[i + 1] >= x[i] for i in range(255)) for x in ch))
