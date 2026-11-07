#!/usr/bin/env python3
"""List OM-3 1100 section descriptors and FF tails just before each 2 KiB-aligned
boundary following the section start. Read-only static survey."""
import struct, sys
from pathlib import Path

BASE = 0x60021020
DESC = 0x60029b28
d = Path(sys.argv[1]).read_bytes()
o = lambda a: a - BASE
secs = []
for i in range(10):
    start, src, flag = struct.unpack_from('<III', d, o(DESC) + 12 * i)
    secs.append((i + 1, start, src, flag))
for sid, start, src, flag in secs:
    print(f'section {sid}: start={start:#x} source={src:#x} flag={flag:#x} '
          f'file_off={start-BASE:#x} src-0x50000020={src-0x50000020:#x}')
# documented ends for 1/4/9; for each section, report the FF run that ends at
# the next start-of-section or end-of-file, scanning downward from the next start.
starts = sorted(s[1] for s in secs) + [BASE + len(d)]
print('\nFF runs immediately before each next section start (candidate tails):')
for sid, start, *_ in secs:
    nxt = min(s for s in starts if s > start)
    end = nxt
    # walk back over FF
    p = o(nxt)
    while p > o(start) and d[p - 1] == 0xFF:
        p -= 1
    print(f' section {sid}: data ends ~{BASE+p:#x}, next start {nxt:#x}, '
          f'FF gap {o(nxt)-p} bytes, 2K-aligned end after data {((BASE+p)+0x7ff)&~0x7ff:#x} '
          f'(loaded tail if so: {(((BASE+p)+0x7ff)&~0x7ff)-(BASE+p)} bytes)')
