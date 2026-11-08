#!/usr/bin/env python3
"""A solid-white baseline JPEG with the camera frame layers' exact header layout (JFIF, q=1 tables, standard
Huffman tables, 4:2:2 YCbCr, no restart markers). Every byte is written here; nothing is copied from the camera.
white(w, h) -> bytes."""
import struct

def _dqt(tid):
    return b'\xff\xdb' + struct.pack('>H', 67) + bytes([tid]) + bytes([1] * 64)

# The standard tables of JPEG Annex K.3 (bits, values).
DC_L = ([0, 1, 5, 1, 1, 1, 1, 1, 1, 0, 0, 0, 0, 0, 0, 0], list(range(12)))
DC_C = ([0, 3, 1, 1, 1, 1, 1, 1, 1, 1, 1, 0, 0, 0, 0, 0], list(range(12)))
AC_L = ([0, 2, 1, 3, 3, 2, 4, 3, 5, 5, 4, 4, 0, 0, 1, 0x7d], bytes.fromhex(
    '01020300041105122131410613516107227114328191a1082342b1c11552d1f02433627282090a161718191a25262728292a3435363738393a'
    '434445464748494a535455565758595a636465666768696a737475767778797a838485868788898a92939495969798999aa2a3a4a5a6a7a8a9'
    'aab2b3b4b5b6b7b8b9bac2c3c4c5c6c7c8c9cad2d3d4d5d6d7d8d9dae1e2e3e4e5e6e7e8e9eaf1f2f3f4f5f6f7f8f9fa'))
AC_C = ([0, 2, 1, 2, 4, 4, 3, 4, 7, 5, 4, 4, 0, 1, 2, 0x77], bytes.fromhex(
    '000102031104052131061241510761711322328108144291a1b1c109233352f0156272d10a162434e125f11718191a262728292a35363738'
    '393a434445464748494a535455565758595a636465666768696a737475767778797a82838485868788898a92939495969798999aa2a3a4a5a6'
    'a7a8a9aab2b3b4b5b6b7b8b9bac2c3c4c5c6c7c8c9cad2d3d4d5d6d7d8d9dae2e3e4e5e6e7e8e9eaf2f3f4f5f6f7f8f9fa'))

def _dht(cls_id, tab):
    bits, vals = tab
    body = bytes([cls_id]) + bytes(bits) + bytes(vals)
    return b'\xff\xc4' + struct.pack('>H', 2 + len(body)) + body

def _codes(tab):
    bits, vals = tab
    out, code, k = {}, 0, 0
    for n in range(1, 17):
        for _ in range(bits[n - 1]):
            out[vals[k]] = (code, n); code += 1; k += 1
        code <<= 1
    return out

def white(w, h):
    dcl, dcc, acl, acc = _codes(DC_L), _codes(DC_C), _codes(AC_L), _codes(AC_C)
    hdr = (b'\xff\xd8' + b'\xff\xe0' + struct.pack('>H', 16) + b'JFIF\x00\x01\x01\x00\x00\x01\x00\x01\x00\x00'
           + _dqt(0) + _dqt(1)
           + b'\xff\xc0' + struct.pack('>HBHHB', 17, 8, h, w, 3) + bytes([1, 0x21, 0, 2, 0x11, 1, 3, 0x11, 1])
           + _dht(0x00, DC_L) + _dht(0x10, AC_L) + _dht(0x01, DC_C) + _dht(0x11, AC_C)
           + b'\xff\xda' + struct.pack('>H', 12) + bytes([3, 1, 0x00, 2, 0x11, 3, 0x11, 0, 63, 0]))
    out, acc_bits, nbits = bytearray(), 0, 0
    def put(code, n):
        nonlocal acc_bits, nbits
        acc_bits = (acc_bits << n) | code; nbits += n
        while nbits >= 8:
            nbits -= 8; b = (acc_bits >> nbits) & 255; out.append(b)
            if b == 0xff: out.append(0)
        acc_bits &= (1 << nbits) - 1
    dc = (255 - 128) * 8                       # white: DC coefficient 1016 with quantizer 1 (category 10)
    cat = dc.bit_length()
    mcus = ((w + 15) // 16) * ((h + 7) // 8)
    eob_l, eob_c = acl[0], acc[0]
    z_l, z_c = dcl[0], dcc[0]
    for i in range(mcus):
        if i == 0:
            put(*dcl[cat]); put(dc, cat)
        else:
            put(*z_l)
        put(*eob_l)
        put(*z_l); put(*eob_l)                 # second Y block: same DC (difference 0)
        put(*z_c); put(*eob_c)                 # Cb
        put(*z_c); put(*eob_c)                 # Cr
    if nbits: put((1 << (8 - nbits)) - 1, 8 - nbits)
    return hdr + bytes(out) + b'\xff\xd9'

if __name__ == '__main__':
    import sys
    w, h = int(sys.argv[1]), int(sys.argv[2])
    open(sys.argv[3], 'wb').write(white(w, h))
