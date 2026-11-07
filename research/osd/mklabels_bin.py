"""LABELS.BIN: 'OM3L' | u32 total | u32 crc32(bytes 12..end) | u16 70 | u16 30 | u32 size[5] by page
(0 Saturation, 1 Light, 2 Hue, 3 WB/BW, 4 Glow) | streams from 36, each 4-aligned (OM-3 OSD type 11, 70 x 30)."""
import json, struct, zlib, sys
lb = json.load(open('/home/claude/om3/osd/label_new.json'))
al = lambda b: b + bytes((-len(b)) % 4)
v = [bytes.fromhex(lb[k]) for k in ('Saturation', 'Light', 'Hue', 'WB/BW', 'Glow')]
body = struct.pack('<HH5I', 70, 30, *[len(x) for x in v]) + b''.join(al(x) for x in v)
total = 12 + len(body)
out = b'OM3L' + struct.pack('<II', total, zlib.crc32(body) & 0xffffffff) + body
assert len(out) == total <= 16384
open(sys.argv[1], 'wb').write(out); print(len(out), [len(x) for x in v])
