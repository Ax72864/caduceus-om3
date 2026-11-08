#!/usr/bin/env python3
"""Split-toning research (2026-11-07): read the OM-3 1.1 RGB gamma curves from the decoded main block and show
what they do to greys.

usage: python3 curves.py [MAIN.decoded.bin]   (default $OM3_MAIN; made by research/setup.sh, never committed)

The development stage 0x60516ad9 picks three curve objects (R, G, B) through selector 0x605163f8 and copies them
into the job's output O with 0x605169a4 (O+1252 / +1892 / +2532, pointers at O+3172 / +3176 / +3180).
Curve object: +0 8 x u16 header, +16 64 x u16 (fine table), +144 256 x u16 (12-bit, 0..4095).
Row table 0x606d3d3c: 32-B rows of 8 object pointers; stills use column 0 (column 1 = variant flag 0x6052d2d7).
Prints the grey ramp's colour (Cb/Cr in 8-bit JPEG units) for the picture-mode curve and for each art filter
that has its own curves. Read-only; prints text.
"""
import os, struct, sys
import numpy as np

BASE = 0x60021020
path = sys.argv[1] if len(sys.argv) > 1 else os.environ.get('OM3_MAIN')
b = open(path, 'rb').read()
u32 = lambda a: struct.unpack('<I', b[a - BASE:a - BASE + 4])[0]
def curve(a):
    o = a - BASE
    return np.frombuffer(b[o + 144:o + 656], '<u2').astype(float)

ROWS = 0x606d3d3c
row = lambda i: [u32(ROWS + 32 * i + 4 * c) for c in range(8)]
# art filter id -> (R, G, B) rows, read from the handlers of the hash switch 0x606d493c (see research/NOTES.md)
# (rows found by running the selector in the emulator: mk_ncall_sel.py; names of the 0x..79 / 0x..7b ids not confirmed)
ART = {
    'COLOR / picture modes (11)': (0, 0, 0),
    'Cross Process I (0x0101006b)': (5, 6, 7),
    'Cross Process II (0x0102006b)': (9, 10, 11),
    'art 0x01010079': (12, 13, 14),
    'art 0x01020079': (15, 16, 17),
    'art 0x01030079': (18, 19, 20),
    'art 0x0102007b': (21, 22, 23),
}

def ycc(r, g, b):
    y = 0.299 * r + 0.587 * g + 0.114 * b
    return y, 0.564 * (b - y), 0.713 * (r - y)

if __name__ == '__main__':
    for name, (ri, gi, bi) in ART.items():
        R, G, B = (curve(row(i)[0]) / 4095 * 255 for i in (ri, gi, bi))
        print(name, [hex(row(i)[0]) for i in (ri, gi, bi)])
        print('   in    Y     Cb     Cr')
        for k in (0, 8, 16, 32, 48, 64, 96, 128, 160, 192, 224, 255):
            y, cb, cr = ycc(R[k], G[k], B[k])
            print(f'  {k:3d} {y:6.1f} {cb:+6.1f} {cr:+6.1f}   R {R[k]:5.1f} G {G[k]:5.1f} B {B[k]:5.1f}')
