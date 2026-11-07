"""Scan OM-3 image records for format-14/field6-8 bitmap descriptors (24 B: <6H3I) whose payload stream
header (byte3 == 3) matches the descriptor size; our own reader (format notes: fishcu/oly_fw_analysis)."""
import struct, sys, json
recs = [(0xa403d000, open('/tmp/claude-0/img0.bin', 'rb').read()), (0xa46dd000, open('/tmp/claude-0/img1.bin', 'rb').read())]
def rd(ptr, n):
    for base, d in recs:
        if base <= ptr and ptr + n <= base + len(d): return d[ptr - base:ptr - base + n]
    return None
out = []
for ri, (base, d) in enumerate(recs):
    for o in range(0, len(d) - 24, 2):
        fmt, w, h, f6 = struct.unpack_from('<4H', d, o)
        if fmt != 14 or f6 != 8 or not (1 <= w <= 1024 and 1 <= h <= 1024): continue
        size, payload, flags = struct.unpack_from('<3I', d, o + 12)
        if not (4 < size < 0x100000): continue
        hd = rd(payload, 4)
        if not hd or hd[3] != 3: continue
        eh = (hd[0] | ((hd[1] & 3) << 8)) + 1; ew = ((hd[1] >> 4) | ((hd[2] & 63) << 4)) + 1
        if (ew, eh) != (w, h): continue
        out.append(dict(rec=ri, desc=base + o, w=w, h=h, size=size, payload=payload, flags=flags))
print(len(out))
json.dump(out, open('/home/claude/om3/osd/descs.json', 'w'))
from collections import Counter
print(Counter(r['rec'] for r in out))
