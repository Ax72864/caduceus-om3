#!/usr/bin/env python3
"""Make an ncall spec (tools/emulator/session_ed1.mjs token `ncall`) that runs the stock RGB-gamma selector
0x605163f8 on a synthetic still request for each effect id, and reads back the three curve pointers (R, G, B).
usage: python3 mk_ncall_sel.py > sel.json
Layout (B = scratch base from the driver): stub B+0 = `call 0x605163f8,[d2,d3,a2,a3],28`, outputs B+0x10/14/18,
request R = B+0x100 (0x800 B zeroed), id at R+8 (bytes hi, mid, u16 low), R+14 = 0x1000 (still development).
"""
import json
SEL = 0x605163f8
IDS = [11, 2000, 2001, 0x01010064, 0x01020064, 0x01010066, 0x01010067, 0x0101006b, 0x0102006b, 0x01010070,
       0x01020070, 0x01030070, 0x01010079, 0x01020079, 0x01030079, 0x0102007b, 0x02000093, 0x02000096]
cases = []
for i in IDS:
    mem = [['B', 'dd'], ['B+1', f'={SEL:#x}-B'], ['B+5', 'f01c'],      # call SEL,[d2,d3,a2,a3],28
           ['B+0x100', '00' * 0x800], ['B+0x10', '00' * 12],
           ['B+0x108', f'{i >> 24 & 255:02x}{i >> 16 & 255:02x}{i & 255:02x}{i >> 8 & 255:02x}'],
           ['B+0x10e', '0010']]
    cases.append({'name': hex(i), 'mem': mem, 'pc': 'B', 'stop': ['B+7'],
                  'regs': {'a0': 'B+0x100', 'a1': 'B+0x10', 'd0': 'B+0x14', 'd1': 'B+0x18'},
                  'read': [['B+0x10', 12]]})
print(json.dumps(cases))
