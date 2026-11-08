import struct, json
recs = [(0xa403d000, open('/tmp/claude-0/img0.bin', 'rb').read()), (0xa46dd000, open('/tmp/claude-0/img1.bin', 'rb').read())]
def rd(ptr, n):
    for base, d in recs:
        if base <= ptr and ptr + n <= base + len(d): return d[ptr - base:ptr - base + n]
descs = json.load(open('/home/claude/om3/osd/descs11.json'))
def analyse(a, w, h, size, p):
    data = rd(p, size)
    groups = [int.from_bytes(data[4 + 8 * g:12 + 8 * g], 'little') for g in range((size - 4) // 8)]
    pads = set(g >> 60 for g in groups)
    px = 0; n = 0
    for g in groups:
        for s in range(5):
            t = (g >> (12 * s)) & 4095
            px += (t & 15) + 1; n += 1
    return pads, px, w * h, (size - 4) % 8
for d in descs[:12]:
    print(d[1], d[2], d[3], analyse(*d))
