#!/usr/bin/env python3
"""Copy files out of an om-emu OMSD card image. usage: card_get_file.py CARD.omsd DOS_PATH LOCAL [DOS_PATH LOCAL ...]"""
import os, struct, subprocess, sys, tempfile
SECTOR = 512
b = open(sys.argv[1], 'rb').read()
assert b[:4] == b'OMSD'
sectors, n = struct.unpack_from('<II', b, 8)
data = {struct.unpack_from('<I', b, 16 + i * 516)[0]: b[20 + i * 516:20 + i * 516 + 512] for i in range(n)}
part = struct.unpack_from('<I', data[0], 0x1c6)[0]
with tempfile.TemporaryDirectory() as td:
    img = os.path.join(td, 'card.img')
    with open(img, 'wb') as f:
        f.truncate(sectors * SECTOR)
        for k, v in data.items(): f.seek(k * SECTOR); f.write(v)
    env = dict(os.environ, MTOOLS_SKIP_CHECK='1'); t = f'{img}@@{part * SECTOR}'
    print(subprocess.run(['mdir', '-i', t, '::/OM3MOD'], capture_output=True, text=True, env=env).stdout)
    a = sys.argv[2:]
    for dos, loc in zip(a[::2], a[1::2]):
        subprocess.run(['mcopy', '-o', '-i', t, '::/' + dos, loc], check=True, env=env)
