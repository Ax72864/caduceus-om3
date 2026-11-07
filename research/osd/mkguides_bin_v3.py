"""GUIDES.BIN v2 (s3 = WB at +24, 0 = none): 'OM3G' | u32 total | u32 crc32(bytes 12..end) | u16 w | u16 h | u32 s1 | u32 s2 | 8 zero |
stream 1 (Hue) at 32 | stream 2 (Light) at 32 + align4(s1). Streams: OM-3 OSD type-11 (osd11.encode11)."""
import json, struct, zlib, sys
g = json.load(open('/home/claude/om3/osd/guide_new.json'))
s1, s2, s3 = bytes.fromhex(g['Hue']), bytes.fromhex(g['Light']), bytes.fromhex(g['WB'])
a1 = (len(s1) + 3) & ~3
a2 = (len(s2) + 3) & ~3
body = struct.pack('<HHIII', 175, 50, len(s1), len(s2), len(s3)) + bytes(4) + s1 + bytes(a1 - len(s1)) + s2 + bytes(a2 - len(s2)) + s3
body += bytes((-len(body)) % 4)
total = 12 + len(body)
crc = zlib.crc32(body) & 0xffffffff
out = b'OM3G' + struct.pack('<II', total, crc) + body
assert len(out) == total
open(sys.argv[1], 'wb').write(out)
print(len(out), hex(crc), len(s1), len(s2), a1)
