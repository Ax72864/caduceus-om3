#!/usr/bin/env python3
"""Decode a GLOG.BIN written by the fast-grain logger (experiment/fast-grain-log: 'GLG2' fg1/fg2 = 4 slots,
'GLG3' fg3 = 8 slots). Prints the header, each slot's records, and with --diff a word diff of the slots' copy A
(the first development request) without pointer-like words.  Usage: glog3.py GLOG.BIN [--diff]"""
import struct, sys

b = open(sys.argv[1], 'rb').read()
mag = b[:4]
NS = 8 if mag == b'GLG3' else 4
HDR, SL, CA = 32 + 4 * NS, 7168, 1600
h = struct.unpack_from('<4s7I', b, 0)
print('header', h[0].decode(), 'total', h[1], 'marks', h[2], 'current', h[3], 'selector calls', h[5], 'records', h[6])
for s in range(NS):
    sl = b[HDR + s * SL:HDR + (s + 1) * SL]
    n, ca, cb, cc, key, fl = struct.unpack_from('<6I', sl, 0)
    if not (n or key):
        continue
    print(f'\nslot {s}: {n} records, copies A{ca} B{cb} C{cc}, capture key {key:#010x}')
    for i in range(min(n, 48)):
        r = sl[32 + 32 * i:64 + 32 * i]
        stage, typ, eff = struct.unpack_from('<HHH', r, 2)
        ctx, req = struct.unpack_from('<II', r, 8)
        print(f' {i:2} combiner {r[0]:3} kind {r[1]:2} stage {stage:#06x} type {typ:#06x} effect {eff:#06x}'
              f' context {ctx:#x} request {req:#x} | {r[20:32].hex(" ")}')
if '--diff' in sys.argv:
    A = [b[HDR + s * SL + CA:HDR + s * SL + CA + 1856] for s in range(NS)
         if struct.unpack_from('<I', b, HDR + s * SL + 4)[0]]
    w = lambda x, o: struct.unpack_from('<I', x, o)[0]
    ptr = lambda v: (v >> 24) in {0x0b, 0x0c, 0x2b, 0x2c} | set(range(0x60, 0x64)) | set(range(0xa0, 0xb0))
    print('\ncopy A word diff (offset, one column per slot with a copy A)')
    for o in range(0, 1856, 4):
        v = [w(x, o) for x in A]
        if len(set(v)) > 1 and not all(ptr(x) or x == 0 for x in v):
            print(f'{o:5} ' + ' '.join(f'{x:08x}' for x in v))
