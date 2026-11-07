import struct, json
from collections import Counter
recs = [(0xa403d000, open('/tmp/claude-0/img0.bin', 'rb').read()), (0xa46dd000, open('/tmp/claude-0/img1.bin', 'rb').read())]
def rd(ptr, n):
    for base, d in recs:
        if base <= ptr and ptr + n <= base + len(d): return d[ptr - base:ptr - base + n]
descs = []
for ri, (base, d) in enumerate(recs):
    for o in range(0, len(d) - 24, 4):
        fmt, w, h, f6, u1, u2 = struct.unpack_from('<6H', d, o)
        size, payload, flags = struct.unpack_from('<3I', d, o + 12)
        if fmt != 14 or f6 != 8 or not (1 <= w <= 1024 and 1 <= h <= 1024 and 4 < size < 0x200000): continue
        hd = rd(payload, 4)
        if not hd or hd[3] != 11: continue
        descs.append((base + o, w, h, size, payload))
def dec(data, w, h, tw, rb, group_bits=64):
    per = group_bits // tw; gb = group_bits // 8
    px = 0; tokens = 0; mask = (1 << tw) - 1
    while px < w * h:
        g, s = divmod(tokens, per); off = 4 + gb * g
        if off + gb > len(data): return None
        word = int.from_bytes(data[off:off + gb], 'little')
        tok = (word >> (tw * s)) & mask
        px += (tok & ((1 << rb) - 1)) + 1
        tokens += 1
    if px != w * h: return None
    used = 4 + gb * ((tokens + per - 1) // per)
    return used
res = Counter()
sample = descs[:300]
for tw in range(4, 17):
    for rb in range(1, 6):
        if rb >= tw: continue
        for gbits in (32, 64):
            ok = 0
            for a, w, h, size, p in sample:
                data = rd(p, size)
                u = dec(data, w, h, tw, rb, gbits)
                if u is not None and abs(u - size) <= 8: ok += 1
            if ok: res[(tw, rb, gbits)] = ok
for k, n in res.most_common(8): print(k, n, '/', len(sample))
json.dump(descs, open('/home/claude/om3/osd/descs11.json', 'w'))
