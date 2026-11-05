#!/usr/bin/env python3
"""Add a file to an om-emu OMSD card image (FAT32 partition at the firmware's offset) with mtools.
usage: card_add_file.py IN.omsd OUT.omsd LOCAL_FILE DOS_DIR DOS_NAME"""
import os, struct, subprocess, sys, tempfile

SECTOR = 512
inp, outp, local, ddir, dname = sys.argv[1:6]
b = open(inp, 'rb').read()
assert b[:4] == b'OMSD' and struct.unpack_from('<I', b, 4)[0] == 1
sectors, n = struct.unpack_from('<II', b, 8)
data = {struct.unpack_from('<I', b, 16 + i * 516)[0]: b[20 + i * 516:20 + i * 516 + 512] for i in range(n)}
# partition start from the MBR (sector 0, first entry LBA at 0x1c6)
part = struct.unpack_from('<I', data[0], 0x1c6)[0]
with tempfile.TemporaryDirectory() as td:
    img = os.path.join(td, 'card.img')
    with open(img, 'wb') as f:
        f.truncate(sectors * SECTOR)
        for k, v in data.items():
            f.seek(k * SECTOR); f.write(v)
    env = dict(os.environ, MTOOLS_SKIP_CHECK='1')
    target = f'{img}@@{part * SECTOR}'
    subprocess.run(['mmd', '-D', 's', '-i', target, f'::/{ddir}'], check=False, env=env, capture_output=True)
    subprocess.run(['mcopy', '-o', '-i', target, local, f'::/{ddir}/{dname}'], check=True, env=env)
    print(subprocess.run(['mdir', '-i', target, f'::/{ddir}'], capture_output=True, text=True, env=env).stdout)
    # collect allocated non-zero sectors (SEEK_DATA/SEEK_HOLE over the sparse file)
    newdata = {}
    fd = os.open(img, os.O_RDONLY)
    try:
        off, end = 0, sectors * SECTOR
        while off < end:
            try:
                ds = os.lseek(fd, off, os.SEEK_DATA)
            except OSError:
                break
            he = os.lseek(fd, ds, os.SEEK_HOLE)
            s0, s1 = ds // SECTOR, (he + SECTOR - 1) // SECTOR
            for s in range(s0, s1):
                os.lseek(fd, s * SECTOR, os.SEEK_SET)
                blk = os.read(fd, SECTOR)
                if s in data or any(blk):
                    newdata[s] = blk
            off = s1 * SECTOR
    finally:
        os.close(fd)
keys = sorted(newdata)
out = bytearray(b'OMSD' + struct.pack('<III', 1, sectors, len(keys)))
for k in keys:
    out += struct.pack('<I', k) + newdata[k]
open(outp, 'wb').write(out)
print('partition at sector', part, '| sectors kept', len(data), '->', len(keys))
