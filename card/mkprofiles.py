#!/usr/bin/env python3
"""LOOKS.BIN v1 (the look bank; PROFILES.BIN before v0.19, same format), 1632 B:
'OM3P' | u32 1632 | u32 crc32(bytes 12..) | u16 1 | u16 20 | sel[4] (0..5) | 12 zero |
20 x 64-B records at 32 (COLOR k profile v at 5k + v - 1) | 20 x 16-B names at 1312.
Record: hue[12] +0, light[12] +12, sat[12] +24 (all -5..5, 12 o'clock clockwise), +36 wb on (0/1), +37 A-B, +38 G-M,
+39 Blacks, +40 Whites (-5..5), +41 Contrast (-2..2), +42 Sharpness (-2..2), +43 Shading (-5..5), +44 Shadows,
+45 Midtones, +46 Highlights (-7..7), v0.20 Extras: +47 Glow (-5..-1) / Clarity (1..5), +48 Art Effect (0 Off, 1 Star Light,
2 Pin Hole, 4 White Edge, 5 Frame), +49 NR (0 Camera, 1 Std, 2 Low, 3 Off, 4 High from v0.23), v0.21: +50 VigFix (0 Camera, 1 Off: lens shading correction off), +51 Grain (0 Off, 1 Low, 2 Med, 3 High),
v0.22: +52 Sharp (-5..+2 in the camera's numbers, -5 Off; json 'sharp22'; the v0.22 export leaves +42 at 0); +53..63 zero.
usage: mkprofiles.py IN.json OUT.BIN   (json: {"sel":[..4], "prof":[[{...} or null x5] x4]})"""
import json, struct, sys, zlib
LEN = 1632
def rec(p):
    b = bytearray(64)
    if not p: return b
    def arr(k):
        a = p.get(k, [0] * 12); assert len(a) == 12; return a
    vals = arr('hue') + arr('light') + arr('sat') + [1 if p.get('wb') else 0, p.get('ab', 0), p.get('gm', 0), p.get('blacks', 0),
           p.get('whites', 0), p.get('contrast', 0), p.get('sharp', 0), p.get('shading', 0), p.get('sh', 0), p.get('mid', 0), p.get('hi', 0),
           p.get('fx', 0), p.get('art', 0), p.get('nr', 0), p.get('vig', 0), p.get('grain', 0), p.get('sharp22', 0)]
    lim = [5] * 36 + [1, 5, 5, 5, 5, 2, 2, 5, 7, 7, 7, 5, 5, 4, 1, 3, 2]
    for i, (v, m) in enumerate(zip(vals, lim)):
        lo = 0 if i in (36, 48, 49, 50, 51) else -5 if i == 52 else -m
        assert lo <= v <= m and not (i == 48 and v == 3), (i, v); b[i] = v & 255
    return b
def build(d):
    sel = d.get('sel', [0, 0, 0, 0]); assert all(0 <= s <= 5 for s in sel)
    body = bytearray(LEN); body[0:4] = b'OM3P'; struct.pack_into('<IIHH', body, 4, LEN, 0, 1, 20); body[16:20] = bytes(sel)
    for k in range(4):
        for j in range(5):
            p = d['prof'][k][j] if k < len(d['prof']) and j < len(d['prof'][k]) else None
            body[32 + 64 * (5 * k + j):96 + 64 * (5 * k + j)] = rec(p)
            nm = ((p or {}).get('name', '')).encode('ascii', 'replace')[:15]
            body[1312 + 16 * (5 * k + j):1312 + 16 * (5 * k + j) + len(nm)] = nm
    struct.pack_into('<I', body, 8, zlib.crc32(body[12:]) & 0xffffffff)
    return bytes(body)
if __name__ == '__main__':
    open(sys.argv[2], 'wb').write(build(json.load(open(sys.argv[1]))))
