#!/usr/bin/env python3
"""White frames for the OM-3 Frame Art Effect (Caduceus for OM-3 v0.20).

The camera keeps each Frame picture as a pair of JPEGs in firmware component 2 (loaded at 0x458c0000; directory of
{u32 address, u32 size} at +0x400, entries 1..26, each JPEG 32 B into its entry): a frame layer, then a window mask
(white = the photo). We replace only each frame layer, with a picture made here: white wherever the camera's own
window mask is black (the frame), black inside the window. The window edges are the masks' own, so the frame keeps
the stock size; the black part (unused under the mask) is snapped inward to the JPEG 8 x 8 grid, so every block is
flat and the encoder below is exact. Header layout as the stock layers (JFIF, quantizer 1, the standard Annex K
Huffman tables, 4:2:2 YCbCr, no restart markers); the rest of each entry is zero, as stock. Pure Python, no OM bytes.
"""
import hashlib, struct

BASE = 0x458c0000
# directory entry of the frame layer, width, height, window x0, x1, y0, y1 (pixels; measured from the stock masks)
LAYERS = [(1, 5184, 3456, 126, 5054, 75, 3365), (3, 2912, 3888, 95, 2820, 131, 3761),
          (5, 5184, 3888, 143, 5027, 120, 3784), (7, 3888, 3888, 100, 3798, 94, 3792),
          (9, 5184, 2920, 172, 5020, 93, 2819), (11, 640, 480, 18, 621, 14, 466),
          (13, 1280, 720, 36, 1247, 19, 700), (15, 1920, 1080, 55, 1870, 29, 1050),
          (17, 1024, 688, 24, 999, 15, 670), (19, 576, 768, 17, 559, 23, 745),
          (21, 1024, 768, 30, 993, 23, 745), (23, 768, 768, 20, 748, 20, 749),
          (25, 1024, 576, 29, 997, 16, 560)]

DC_L = ([0, 1, 5, 1, 1, 1, 1, 1, 1, 0, 0, 0, 0, 0, 0, 0], bytes(range(12)))
DC_C = ([0, 3, 1, 1, 1, 1, 1, 1, 1, 1, 1, 0, 0, 0, 0, 0], bytes(range(12)))
AC_L = ([0, 2, 1, 3, 3, 2, 4, 3, 5, 5, 4, 4, 0, 0, 1, 0x7d], bytes.fromhex(
    '01020300041105122131410613516107227114328191a1082342b1c11552d1f02433627282090a161718191a25262728292a3435363738393a'
    '434445464748494a535455565758595a636465666768696a737475767778797a838485868788898a92939495969798999aa2a3a4a5a6a7a8a9'
    'aab2b3b4b5b6b7b8b9bac2c3c4c5c6c7c8c9cad2d3d4d5d6d7d8d9dae1e2e3e4e5e6e7e8e9eaf1f2f3f4f5f6f7f8f9fa'))
AC_C = ([0, 2, 1, 2, 4, 4, 3, 4, 7, 5, 4, 4, 0, 1, 2, 0x77], bytes.fromhex(
    '000102031104052131061241510761711322328108144291a1b1c109233352f0156272d10a162434e125f11718191a262728292a35363738'
    '393a434445464748494a535455565758595a636465666768696a737475767778797a82838485868788898a92939495969798999aa2a3a4a5a6'
    'a7a8a9aab2b3b4b5b6b7b8b9bac2c3c4c5c6c7c8c9cad2d3d4d5d6d7d8d9dae2e3e4e5e6e7e8e9eaf2f3f4f5f6f7f8f9fa'))


def _seg(marker, body):
    return bytes([0xff, marker]) + struct.pack('>H', 2 + len(body)) + body


def _codes(tab):
    bits, vals = tab
    out, code, k = {}, 0, 0
    for n in range(1, 17):
        for _ in range(bits[n - 1]):
            out[vals[k]] = (code, n); code += 1; k += 1
        code <<= 1
    return out


def header(w, h):
    return (b'\xff\xd8' + _seg(0xe0, b'JFIF\x00\x01\x01\x00\x00\x01\x00\x01\x00\x00')
            + _seg(0xdb, b'\x00' + bytes([1] * 64)) + _seg(0xdb, b'\x01' + bytes([1] * 64))
            + _seg(0xc0, struct.pack('>BHHB', 8, h, w, 3) + bytes([1, 0x21, 0, 2, 0x11, 1, 3, 0x11, 1]))
            + _seg(0xc4, bytes([0x00]) + bytes(DC_L[0]) + DC_L[1]) + _seg(0xc4, bytes([0x10]) + bytes(AC_L[0]) + AC_L[1])
            + _seg(0xc4, bytes([0x01]) + bytes(DC_C[0]) + DC_C[1]) + _seg(0xc4, bytes([0x11]) + bytes(AC_C[0]) + AC_C[1])
            + _seg(0xda, bytes([3, 1, 0x00, 2, 0x11, 3, 0x11, 0, 63, 0])))


def layer(w, h, win=None):
    """Flat 8 x 8 blocks: luma 255 (white), or 0 (black) for blocks wholly inside the window (x0, x1, y0, y1)."""
    dcl, dcc, eob_l, eob_c = _codes(DC_L), _codes(DC_C), _codes(AC_L)[0], _codes(AC_C)[0]
    if win:
        x0, x1, y0, y1 = win
        bx0, bx1, by0, by1 = -(-x0 // 8), x1 // 8, -(-y0 // 8), y1 // 8
    else:
        bx0 = bx1 = by0 = by1 = 0
    out, acc, nb = bytearray(), 0, 0

    def put(code, n):
        nonlocal acc, nb
        acc = (acc << n) | code; nb += n
        while nb >= 8:
            nb -= 8; b = (acc >> nb) & 255; out.append(b)
            if b == 0xff: out.append(0)
        acc &= (1 << nb) - 1

    def diff(v):                                    # DC difference: category code, then the value bits
        if v == 0:
            put(*dcl[0]); return
        c = abs(v).bit_length(); put(*dcl[c]); put(v if v > 0 else v + (1 << c) - 1, c)

    pred = 0
    for my in range((h + 7) // 8):
        for mx in range((w + 15) // 16):
            for bx in (2 * mx, 2 * mx + 1):
                dc = -1024 if (bx0 <= bx < bx1 and by0 <= my < by1) else 1016
                diff(dc - pred); pred = dc; put(*eob_l)
            put(*dcc[0]); put(*eob_c)               # Cb, Cr: neutral, difference 0
            put(*dcc[0]); put(*eob_c)
    if nb: put((1 << (8 - nb)) - 1, 8 - nb)
    return header(w, h) + bytes(out) + b'\xff\xd9'


def patch(dec):
    """Component 2 decoded -> the same with white frame layers. Refuses anything unexpected."""
    m = bytearray(dec)
    for k, w, h, x0, x1, y0, y1 in LAYERS:
        a, n = struct.unpack_from('<II', m, 0x400 + 16 * k)
        o = a - BASE + 0x20
        hd = header(w, h)
        if bytes(m[o:o + len(hd)]) != hd or any(m[a - BASE:o]):
            raise ValueError(f'frame layer {k}: not the expected JPEG')
        new = layer(w, h, (x0, x1, y0, y1))
        if len(new) > n - 0x20:
            raise ValueError(f'frame layer {k}: too big')
        m[o:a - BASE + n] = new + bytes(n - 0x20 - len(new))
    return bytes(m)


if __name__ == '__main__':
    import sys
    d = open(sys.argv[1], 'rb').read(); p = patch(d)
    print(hashlib.sha256(d).hexdigest(), '->', hashlib.sha256(p).hexdigest(), sum(x != y for x, y in zip(d, p)), 'bytes changed')
