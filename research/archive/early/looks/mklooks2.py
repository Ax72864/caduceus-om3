#!/usr/bin/env python3
"""LOOKS.BIN v2 for the OM-3 Looks page (firmware test 15+): 5 looks per COLOR profile.
 0 'OM3K' | 4 u32 total 992 | 8 u32 CRC-32 (zlib) of bytes 12..991 | 12 u16 version 2 | 14 u16 20 |
 16..19 u8 looks defined for COLOR1..4 (0..5) | 20..31 zero | 32 20 x 32-B looks (COLOR k look j at 5k + j - 1) |
 672 20 x 16-B names (ASCII, NUL padded; ignored by the camera).
Look: hue[12] s8 +0, light[12] s8 +12 (-5..5, UI sector order from 12 o'clock), +24 wb on (0/1), +25 A-B, +26 G-M,
+27 Blacks, +28 Whites (s8 -5..5), +29..31 zero. Unused records are all zero."""
import json, struct, sys, zlib

def look_bytes(L):
    h, l = L.get('hue', [0] * 12), L.get('light', [0] * 12)
    ab, gm = L.get('wb_ab', L.get('ab', 0)), L.get('wb_gm', L.get('gm', 0))
    vals = list(h) + list(l) + [1 if (ab or gm) else 0, ab, gm, L.get('blacks', 0), L.get('whites', 0), 0, 0, 0]
    assert len(vals) == 32 and all(-5 <= v <= 5 for v in vals)
    return bytes(v & 0xff for v in vals)

def make(profiles):
    """profiles: list of 4 lists (COLOR1..4) of up to 5 looks."""
    assert len(profiles) == 4 and all(len(p) <= 5 for p in profiles)
    recs, names = bytearray(640), bytearray(320)
    for k, p in enumerate(profiles):
        for j, L in enumerate(p):
            r = 5 * k + j
            recs[32 * r:32 * r + 32] = look_bytes(L)
            nm = L.get('name', '')[:15].encode('ascii', 'replace')
            names[16 * r:16 * r + len(nm)] = nm
    tail = struct.pack('<HH', 2, 20) + bytes(len(p) for p in profiles) + bytes(12) + bytes(recs) + bytes(names)
    out = b'OM3K' + struct.pack('<II', 992, zlib.crc32(tail) & 0xffffffff) + tail
    assert len(out) == 992
    return out

if __name__ == '__main__':
    d = json.load(open(sys.argv[1]))
    open(sys.argv[2], 'wb').write(make([d.get(f'COLOR{k}', []) for k in (1, 2, 3, 4)]))
