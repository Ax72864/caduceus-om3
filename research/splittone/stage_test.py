#!/usr/bin/env python3
"""Emulator test of the development stage 0x60516ad9 (matrix -> THIS -> 0x60515e64 -> COLOR ...) on a synthetic
still request: does a COLOR still (id 11, context key 11) reach the copier call 0x60516c8d, and with which curves?
usage: python3 stage_test.py make > stage.json ; python3 stage_test.py check out.json
C = B+0x200 (C+4 = R, C+12 = O, C+48 = key), R = B+0x400 (0x800 B, R+1660.. image size), O = B+0x1000 (0x1000 B).
Each id runs twice: stop at the copier call (registers = its arguments), and to the stage's return.
"""
import json, sys
STAGE, HOOK = 0x60516ad9, 0x60516c8d
IDS = {'COLOR': (11, 11), 'XP1': (0x0101006b, 11), 'A79': (0x01010079, 11), 'COLORgrain': (12, 12)}   # (request id at R+8, context key C+48); a COLOR still on the camera-grain route has id 12
def mem(i, key):
    w = lambda a, v: [a, f'={v}']
    return [['B', 'dd'], ['B+1', f'={STAGE:#x}-B'], ['B+5', 'f010'],
            ['B+0x200', '00' * 0x100], ['B+0x400', '00' * 0x800], ['B+0x1000', '00' * 0x1000],
            w('B+0x204', 'B+0x400'), w('B+0x20c', 'B+0x1000'), w('B+0x230', hex(key)),
            ['B+0x408', f'{i >> 24 & 255:02x}{i >> 16 & 255:02x}{i & 255:02x}{i >> 8 & 255:02x}'],
            ['B+0x40e', '0010'],
            ['B+0x400+1660', '40143018' * 2]]   # R+1660.. = 5184 x 3888 twice (divisors in 0x6052d41a)
if sys.argv[1] == 'make':
    out = []
    for n, (i, key) in IDS.items():
        out.append({'name': n + '@hook', 'pc': 'B', 'stop': ['B+7', hex(HOOK)], 'mem': mem(i, key), 'regs': {'a0': 'B+0x200'}})
        out.append({'name': n + '@ret', 'pc': 'B', 'stop': ['B+7'], 'mem': mem(i, key), 'regs': {'a0': 'B+0x200'},
                    'read': [['B+0x1000+3172', 12], ['B+0x1000+1252', 8], ['B+0x1000+1892', 8], ['B+0x1000+2532', 8]]})
    print(json.dumps(out))
else:
    d = json.load(open(sys.argv[2]))
    for o in d['out']:
        g = o['regs']
        print(o['name'].ljust(16), 'steps', str(o['steps']).rjust(6), 'pc', g['pc'],
              ('args a0 %s a1 %s d0 %s d1 %s' % (g['a0'], g['a1'], g['d0'], g['d1'])) if o['name'].endswith('@hook') else o['mem'])
