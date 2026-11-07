#!/usr/bin/env python3
"""LOOKS.BIN v1 for the OM-3 Looks page (firmware test 14+):
 0 'OM3K' | 4 u32 total | 8 u32 CRC-32 (zlib) of bytes 12..total-1 | 12 u16 version 1 | 14 u16 n (1..16) | 16..31 zero |
 32 n x 32-B looks | n x 16-B names (ASCII, NUL padded; ignored by the camera).
Look: hue[12] s8 +0, light[12] s8 +12 (-5..5, UI sector order from 12 o'clock), +24 wb on (0/1), +25 A-B, +26 G-M,
+27 Blacks, +28 Whites (s8 -5..5), +29..31 zero."""
import json, struct, sys, zlib

def look_bytes(L):
    h, l = L.get('hue', [0] * 12), L.get('light', [0] * 12)
    ab, gm = L.get('wb_ab', 0), L.get('wb_gm', 0)
    on = 1 if (ab or gm) else 0
    vals = list(h) + list(l) + [on, ab, gm, L.get('blacks', 0), L.get('whites', 0), 0, 0, 0]
    assert len(vals) == 32 and all(-5 <= v <= 5 for v in vals)
    return bytes(v & 0xff for v in vals)

def make(looks):
    n = len(looks); assert 1 <= n <= 16
    recs = b''.join(look_bytes(L) for L in looks)
    names = b''.join(L.get('name', '')[:15].encode('ascii', 'replace').ljust(16, b'\0') for L in looks)
    total = 32 + 48 * n
    tail = struct.pack('<HH', 1, n) + bytes(16) + recs + names
    crc = zlib.crc32(tail) & 0xffffffff
    out = b'OM3K' + struct.pack('<II', total, crc) + tail
    assert len(out) == total
    return out

if __name__ == '__main__':
    looks = json.load(open(sys.argv[1]))
    open(sys.argv[2], 'wb').write(make(looks))
