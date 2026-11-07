"""OM-3 OSD bitmap decoder for descriptor format 14 / field6 8, stream type 11 (our own; inferred):
header 4 B (h-1: 10 bits, w-1: 10 bits at bit 12, byte 3 = 11), then 64-bit little-endian groups of five 12-bit tokens
(bits 60..63 zero; the last group may be cut short), token = index << 4 | (run - 1)."""
import struct, json
recs = [(0xa403d000, open('/tmp/claude-0/img0.bin', 'rb').read()), (0xa46dd000, open('/tmp/claude-0/img1.bin', 'rb').read())]
def rd(ptr, n):
    for base, d in recs:
        if base <= ptr and ptr + n <= base + len(d): return d[ptr - base:ptr - base + n]
def decode11(data, w, h):
    px = bytearray(); g = 0
    while len(px) < w * h:
        chunk = data[4 + 8 * g:12 + 8 * g]
        if not chunk: raise ValueError('truncated')
        word = int.from_bytes(chunk.ljust(8, b'\0'), 'little')
        if word >> 60: raise ValueError('pad')
        for s in range(5):
            if len(px) >= w * h: break
            t = (word >> (12 * s)) & 4095
            run = (t & 15) + 1
            if len(px) + run > w * h: raise ValueError('overrun')
            px.extend(bytes([t >> 4]) * run)
        g += 1
    return bytes(px)
def encode11(px, w, h):
    toks = []; i = 0
    while i < len(px):
        v = px[i]; r = 1
        while r < 16 and i + r < len(px) and px[i + r] == v: r += 1
        toks.append(v << 4 | (r - 1)); i += r
    hdr = bytes([(h - 1) & 255, ((h - 1) >> 8 & 3) | (((w - 1) & 15) << 4), ((w - 1) >> 4) & 63, 11])
    out = bytearray(hdr)
    for k in range(0, len(toks), 5):
        word = 0
        for s, t in enumerate(toks[k:k + 5]): word |= t << (12 * s)
        out += word.to_bytes(8, 'little')
    return bytes(out)
if __name__ == '__main__':
    descs = json.load(open('/home/claude/om3/osd/descs11.json'))
    ok = bad = 0; okl = []
    for a, w, h, size, p in descs:
        try:
            px = decode11(rd(p, size), w, h); ok += 1; okl.append((a, w, h, size, p))
        except ValueError: bad += 1
    print('ok', ok, 'bad', bad)
    json.dump(okl, open('/home/claude/om3/osd/ok11.json', 'w'))
