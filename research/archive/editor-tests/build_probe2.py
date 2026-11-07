#!/usr/bin/env python3
"""Build OM-3 1.1 probe 2 (heap looks + SD file) and its test BUNDLES.BIN.

File format = Caduceus BUNDLES.BIN v1 (cakelesscoder/caduceus-ep7, Apache-2.0) with OM-3 identity:
  0 magic 'OM3B' | 4 u16 version 1 | 6 u16 header_len 32 | 8 u32 fw_build 1100 | 12 u32 payload_len 512
  16 u32 CRC-32 (zlib) over bytes 0..15 ++ 20..543 | 20 4 bytes OM-3 decoded-main SHA-256 prefix | 24..31 zero
  32.. 8 slots x 64 B (Caduceus layout.json; ranges = Caduceus RANGES + TONE_RANGES).
"""
import argparse, hashlib, json, struct, subprocess, sys, zlib
from pathlib import Path
sys.path.insert(0, '/home/claude/om3/tools'); sys.path.insert(0, '/home/claude/om3/pp')
from oe_decode import parse, encode, wordsum
import build_pp as P

HERE = Path(__file__).resolve().parent
LAYOUT = Path('/home/claude/cad/caduceus-ep7/patches/bundles/layout.json')
HOOKS = {'.hook_color': (0x60518615, bytes.fromhex('cd6cfdf060')),
         '.hook_shutter': (0x60415216, bytes.fromhex('cd2d01f024'))}
SHUTTER_CONTEXT = (0x604151fc, '5810fae0fffffac80001c80e5810fae0fffffac80101c9095c0c')
EXT1 = (0x6031e920, 0x6031ebf0)          # section-1 tail (FF from 0x6031e910, end 0x6031f000)
EXT4 = (0x60a8f100, 0x60a8f7f0)          # section-4 tail (FF from 0x60a8f088, end 0x60a8f800)
STATE = 0x62b4dd16
MAGIC = b'OM3B'
RANGES = {'hue': (-7, 7), 'light': (-7, 7), 'grain': (0, 6), 'wb_flags': (0, 1), 'wb_ab': (-7, 7),
          'wb_gm': (-7, 7), 'effect_id': (0, 3), 'effect_strength': (0, 5), 'vignette': (-5, 5),
          'flags': (0, 3), 'colour': (0, 1), 'sat': (-5, 5), 'bloom_tint': (0, 4), 'art_effect': (0, 5),
          'blacks': (-5, 5), 'whites': (-5, 5)}


def range_table():
    lay = json.loads(LAYOUT.read_text())
    fields = dict(lay['fields']); fields.update(lay['color_fields'])
    lo, hi = [0] * 64, [0] * 64
    for name, (off, n, *_) in fields.items():
        a, b = RANGES[name]
        for k in range(off, off + n):
            lo[k], hi[k] = a, b
    return lo, [h - l for l, h in zip(lo, hi)]


def header(crc=0):
    return MAGIC + struct.pack('<HHIII', 1, 32, 1100, 512, crc) + bytes.fromhex(P.MAIN_SHA[:8]) + bytes(8)


def make_file(slots):
    """slots: {index: {'hue': [12], 'light': [12]}} -> 544-byte file (flags bit1 set for those slots)."""
    table = bytearray(512)
    for k, s in slots.items():
        for i, v in enumerate(s['hue']):
            table[64 * k + i] = v & 0xff
        for i, v in enumerate(s['light']):
            table[64 * k + 12 + i] = v & 0xff
        table[64 * k + 31] = 2
    body = header(0) + bytes(table)
    crc = zlib.crc32(body[:16] + body[20:]) & 0xffffffff
    out = header(crc) + bytes(table)
    assert len(out) == 544
    return out


def table_ok(buf, lo, span):
    return all(((((buf[32 + i] ^ 0x80) - 0x80) - lo[i % 64]) & 0xffffffff) <= span[i % 64] for i in range(512))


def db(b):
    return ''.join(' .byte ' + ','.join(f'0x{x:02x}' for x in b[i:i + 16]) + '\n' for i in range(0, len(b), 16))


def build(defaults, testfile, out):
    out = Path(out); out.mkdir(parents=True, exist_ok=False)
    lo, span = range_table()
    dflt, test = make_file(defaults), make_file(testfile)
    assert table_ok(dflt, lo, span) and table_ok(test, lo, span)
    (out / 'data4.inc').write_text('sd_hdr:\n' + db(header(0)) + 'sd_lo:\n' + db(bytes(v & 0xff for v in lo)) +
                                   'sd_span:\n' + db(bytes(span)) + 'sd_default:\n' + db(dflt))
    (out / 'BUNDLES.BIN').write_bytes(test)
    subprocess.run([P.AS, '-I', out, '-o', out / 'p.o', HERE / 'probe2.s'], check=True)
    subprocess.run([P.LD, '-T', HERE / 'probe2.ld', '-o', out / 'p.elf', out / 'p.o'], check=True)
    blobs = {}
    for s in list(HOOKS) + ['.ext1', '.ext4']:
        subprocess.run([P.OBJCOPY, '-O', 'binary', '-j', s, out / 'p.elf', out / (s[1:] + '.bin')], check=True)
        blobs[s] = (out / (s[1:] + '.bin')).read_bytes()
    raw = Path('/mnt/user-data/uploads/OLY_E_147_1100_0000_0000_3.BIN').read_bytes()
    assert hashlib.sha256(raw).hexdigest() == P.STOCK_SHA
    comps = parse(raw); mc = comps[0]
    assert hashlib.sha256(mc['dec']).hexdigest() == P.MAIN_SHA
    m = bytearray(mc['dec']); o = lambda a: a - P.BASE
    a, ctx = SHUTTER_CONTEXT
    assert m[o(a):o(a) + len(ctx) // 2].hex() == ctx
    for s, (addr, stock) in HOOKS.items():
        assert bytes(m[o(addr):o(addr) + 5]) == stock and len(blobs[s]) == 5, s
    for (lo_, hi_), s, ff_from, end in ((EXT1, '.ext1', 0x6031e910, 0x6031f000), (EXT4, '.ext4', 0x60a8f088, 0x60a8f800)):
        assert lo_ + len(blobs[s]) <= hi_, (s, len(blobs[s]))
        assert set(m[o(ff_from):o(end)]) == {0xff} and m[o(ff_from) - 1] != 0xff, s
    for v in (STATE, STATE + 1, STATE + 0x40000000, STATE + 0x40000001):
        assert bytes(m).count(struct.pack('<I', v)) == 0
    for s, (addr, _) in HOOKS.items():
        m[o(addr):o(addr) + 5] = blobs[s]
    m[o(EXT1[0]):o(EXT1[0]) + len(blobs['.ext1'])] = blobs['.ext1']
    m[o(EXT4[0]):o(EXT4[0]) + len(blobs['.ext4'])] = blobs['.ext4']
    hdr, trl = mc['hdr'], bytearray(mc['trl'])
    struct.pack_into('<I', trl, 28, 0)
    struct.pack_into('<I', trl, 28, (-(wordsum(hdr) + wordsum(bytes(m)) + wordsum(bytes(trl)))) & 0xFFFFFFFF)
    pkg = b''.join((hdr + encode(bytes(m)) + bytes(trl)) if i == 0 else (c['hdr'] + c['enc'] + c['trl'])
                   for i, c in enumerate(comps))
    again = parse(pkg)
    assert all(c['checksum_ok'] for c in again) and again[0]['dec'] == bytes(m) and len(pkg) == len(raw)
    assert all(again[i]['dec'] == comps[i]['dec'] for i in range(1, len(comps)))
    (out / 'main.bin').write_bytes(bytes(m)); (out / 'E1479999.BIN').write_bytes(pkg)
    nm = subprocess.run([P.TC / 'binutils/nm-new', out / 'p.elf'], capture_output=True, text=True).stdout
    syms = {l.split()[2]: int(l.split()[0], 16) for l in nm.splitlines() if len(l.split()) == 3}
    rep = dict(package_sha256=hashlib.sha256(pkg).hexdigest(), main_sha256=hashlib.sha256(bytes(m)).hexdigest(),
               main_bytes_changed=sum(x != y for x, y in zip(m, mc['dec'])),
               ext1=dict(addr=hex(EXT1[0]), bytes=len(blobs['.ext1'])), ext4=dict(addr=hex(EXT4[0]), bytes=len(blobs['.ext4'])),
               bundles_bin_sha256=hashlib.sha256(test).hexdigest(), defaults_sha256=hashlib.sha256(dflt).hexdigest(),
               symbols={k: hex(v) for k, v in syms.items() if k.startswith(('hl_', 'pr_', 'sd_', 'ext'))})
    (out / 'build.json').write_text(json.dumps(rep, indent=1))
    print(json.dumps({k: v for k, v in rep.items() if k != 'symbols'}, indent=1))
    return syms


C1 = {'hue': [5] * 12, 'light': [0] * 12}
C2 = {'hue': [-5] * 12, 'light': [0] * 12}

if __name__ == '__main__':
    ap = argparse.ArgumentParser(); ap.add_argument('--out', required=True)
    a = ap.parse_args(); build({0: C1}, {0: C1, 1: C2}, a.out)
