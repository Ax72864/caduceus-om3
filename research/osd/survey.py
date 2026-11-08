import struct
from collections import Counter
recs = [(0xa403d000, open('/tmp/claude-0/img0.bin', 'rb').read()), (0xa46dd000, open('/tmp/claude-0/img1.bin', 'rb').read())]
def rd(ptr, n):
    for base, d in recs:
        if base <= ptr and ptr + n <= base + len(d): return d[ptr - base:ptr - base + n]
c = Counter(); ex = {}
for ri, (base, d) in enumerate(recs):
    for o in range(0, len(d) - 24, 4):
        fmt, w, h, f6, u1, u2 = struct.unpack_from('<6H', d, o)
        size, payload, flags = struct.unpack_from('<3I', d, o + 12)
        if not (1 <= w <= 1024 and 1 <= h <= 1024 and 4 < size < 0x200000): continue
        hd = rd(payload, 4)
        if not hd: continue
        k = (ri, fmt, f6, hd[3]); c[k] += 1; ex.setdefault(k, (hex(base + o), w, h, size, hex(payload), hd.hex()))
for k, n in c.most_common(25): print(k, n, ex[k])
# record 0 word 0 (pointer into itself) and first words
d = recs[0][1]; print([hex(x) for x in struct.unpack_from('<8I', d, 0)])
d = recs[1][1]; print([hex(x) for x in struct.unpack_from('<8I', d, 0)])
