#!/usr/bin/env python3
"""Independently check the repo's published OM-3 1.1 COLOR anchor addresses
against our own decoded main payload. Read-only."""
import hashlib, json, struct, sys
from pathlib import Path

MAIN = Path(sys.argv[1])
BASE = 0x60021020
TABLE, TABLE_BYTES = 0x606ba608, 3028
TABLE_SHA = 'a33d64bdb78ac41ba24ccbff820380f563211a095ac08a12a7c37a51b5c00531'
GAINS = 0x606d413c
BUILDER = (0x60518381, 0x60518560)
TABLE_INSN, BUILDER_CALL = 0x6051860a, 0x60518615
ENTRY_JUMP, INIT = 0x82, 0xa5

d = MAIN.read_bytes()
o = lambda a: a - BASE
res = {}
res['main_sha_ok'] = hashlib.sha256(d).hexdigest() == \
    '5e8d376e9111a44ac0352f26030d7c1b17026d42c45f3600cfa02a0e8c5b7d59'
t = d[o(TABLE):o(TABLE) + TABLE_BYTES]
res['color_table_sha_ok'] = hashlib.sha256(t).hexdigest() == TABLE_SHA
res['color_table_unique'] = d.count(t) == 1
tgt = struct.unpack_from('<I', d, ENTRY_JUMP + 2)[0]
res['entry_jump_ok'] = d[ENTRY_JUMP:ENTRY_JUMP+2] == b'\xfc\xdc' and tgt - INIT == BASE
res['table_load_insn_ok'] = d[o(TABLE_INSN):o(TABLE_INSN)+6] == b'\xfc\xdc' + struct.pack('<I', TABLE)
c = o(BUILDER_CALL)
res['selector_calls_builder'] = d[c] == 0xcd and BUILDER_CALL + struct.unpack_from('<h', d, c+1)[0] == BUILDER[0]
ptrs = struct.unpack_from('<12I', d, o(GAINS))
res['gains'] = [struct.unpack_from('<HH', d, o(p)) for p in ptrs]
recs = []
for r in range(12):
    recs.append(struct.unpack_from('<hhh', t, r*28 + 12))
res['table_records_hue_sat_light'] = recs
print(json.dumps(res, indent=1))
