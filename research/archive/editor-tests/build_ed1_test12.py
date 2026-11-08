#!/usr/bin/env python3
"""Build OM-3 1.1 editor test 1 (probe 2 + on-camera Hue/Light pages + card save) and a neutral BUNDLES.BIN.

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
         '.hook_shutter': (0x60415216, bytes.fromhex('cd2d01f024')),
         '.hook_set': (0x60b8798b, bytes.fromhex('dd04d90200f044')),
         '.hook_pmod': (0x6129ba07, bytes.fromhex('0cfcde10ec')),
         '.hook_tone': (0x605197d7, bytes.fromhex('f1eccdcbf7f038')),
         '.hook_glow_flag': (0x60555ee5, bytes.fromhex('fc433a930000')),
         '.hook_glow_w': (0x605048c1, bytes.fromhex('f824302c5802')),
         '.hook_glow_lv': (0x60479daf, bytes.fromhex('dd9c990300f024'))}
# data words (flash image, patched at build time): stock target -> our symbol
WORDS = {0x60e57480: (0x60b86de7, 'ed_get'), 0x60e57510: (0x60b86e44, 'ed_default'),
         **{a + 4: (0x6122393a, 'ed_init') for a in (0x615adcc4, 0x615adcfc, 0x615add34, 0x615add6c)},
         **{a + 44: (0x6122661b, 'ed_info') for a in (0x615adcc4, 0x615adcfc, 0x615add34, 0x615add6c)},
         **{a + 36: (0x61225d52, 'ed_event') for a in (0x615adcc4, 0x615adcfc, 0x615add34, 0x615add6c)}}
def poly_sites(m, o):
    """The 48 sector reads in the wheel drawing code: `mov id,d0` (2c lo hi) then `call 0x603f039d,[],4` (7 B)."""
    out = []
    a = 0x60b1d0c7
    while a < 0x60b1d35b:
        b0 = m[o(a)]
        if b0 == 0x2c and m[o(a) + 3] == 0xdd:
            v = m[o(a) + 1] | m[o(a) + 2] << 8
            rel = struct.unpack_from('<i', m, o(a) + 4)[0]
            if 928 <= v <= 975 and (a + 3 + rel) & 0xffffffff == 0x603f039d and m[o(a) + 8:o(a) + 10] == b'\x00\x04':
                out.append((a + 3, v))
                a += 10
                continue
        a += 1
    return out
RECORD_KEYS = {0x615adcc4: 0x1540, 0x615adcfc: 0x1541, 0x615add34: 0x1542, 0x615add6c: 0x1543}
SHUTTER_CONTEXT = (0x604151fc, '5810fae0fffffac80001c80e5810fae0fffffac80101c9095c0c')
EXT1 = (0x6031e920, 0x6031eff0)          # section-1 tail (FF from 0x6031e910, end 0x6031f000)
EXT4 = (0x60a8f100, 0x60a8f7f0)
EXT10 = (0x61aa4300, 0x61aa47f0)
EXT8 = (0x617e45f0, 0x617e47f0)            # section-8 tail (FF from 0x617e45e0, end 0x617e4800)
EXT3 = (0x6081fe10, 0x6081fff0)            # section-3 tail (FF from 0x6081fe00, end 0x60820000)
EXT5 = (0x60adb5b0, 0x60adb7f0)            # section-5 tail (FF from 0x60adb5a0, end 0x60adb800)
EXT6 = (0x60f49590, 0x60f497f0)            # section-6 tail (FF from 0x60f49580, end 0x60f49800)          # section-10 tail (FF from 0x61aa42f0, end 0x61aa4800)          # section-4 tail (FF from 0x60a8f088, end 0x60a8f800)
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
    subprocess.run([P.AS, '-I', out, '-o', out / 'p.o', HERE / 'ed1.s'], check=True)
    subprocess.run([P.LD, '-T', HERE / 'ed1.ld', '-o', out / 'p.elf', out / 'p.o'], check=True)
    blobs = {}
    for s in list(HOOKS) + ['.ext1', '.ext4', '.ext10', '.ext6', '.ext5', '.ext3', '.ext8']:
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
        assert bytes(m[o(addr):o(addr) + len(stock)]) == stock and len(blobs[s]) == len(stock), (s, blobs[s].hex())
    nm0 = subprocess.run([P.TC / 'binutils/nm-new', out / 'p.elf'], capture_output=True, text=True).stdout
    sy = {l.split()[2]: int(l.split()[0], 16) for l in nm0.splitlines() if len(l.split()) == 3}
    for a, k in RECORD_KEYS.items():
        assert struct.unpack_from('<H', m, o(a))[0] == k
    for a, (stock, name) in WORDS.items():
        assert struct.unpack_from('<I', m, o(a))[0] == stock, hex(a)
        assert bytes(m).count(struct.pack('<I', stock)) == sum(1 for v in WORDS.values() if v[0] == stock), hex(stock)
    for (lo_, hi_), s, ff_from, end in ((EXT1, '.ext1', 0x6031e910, 0x6031f000), (EXT4, '.ext4', 0x60a8f088, 0x60a8f800), (EXT10, '.ext10', 0x61aa42f0, 0x61aa4800), (EXT6, '.ext6', 0x60f49580, 0x60f49800), (EXT5, '.ext5', 0x60adb5a0, 0x60adb800), (EXT3, '.ext3', 0x6081fe00, 0x60820000), (EXT8, '.ext8', 0x617e45e0, 0x617e4800)):
        assert lo_ + len(blobs[s]) <= hi_, (s, len(blobs[s]))
        assert set(m[o(ff_from):o(end)]) == {0xff} and m[o(ff_from) - 1] != 0xff, s
    for v in (STATE, STATE + 1, STATE + 0x40000000, STATE + 0x40000001):
        assert bytes(m).count(struct.pack('<I', v)) == 0
    for s, (addr, stock) in HOOKS.items():
        m[o(addr):o(addr) + len(stock)] = blobs[s]
    for a, (stock, name) in WORDS.items():
        struct.pack_into('<I', m, o(a), sy[name])
    WB_SITES = [0x60457982, 0x6045799c, 0x60457b91, 0x60457ba9, 0x60457c4d, 0x60457c65, 0x60457ce5, 0x60457cff,
                0x604631b2, 0x604631c5, 0x604876c3, 0x604876d8]
    for a in WB_SITES:
        assert m[o(a)] == 0xdd and m[o(a) + 5:o(a) + 7] == b'\xc0\x0c', hex(a)
        assert (a + struct.unpack_from('<i', m, o(a) + 1)[0]) & 0xffffffff == 0x60063380, hex(a)
        back = bytes(m[o(a) - 14:o(a)])
        assert struct.pack('<I', 34041) in back or struct.pack('<I', 38521) in back, hex(a)
        m[o(a) + 1:o(a) + 5] = struct.pack('<i', sy['wb_get'] - a)
    ISDEF_SITES = [0x611d18a7, 0x611d18e8, 0x611d18f6, 0x611d1939, 0x611d1946, 0x611d1953, 0x611d1ac3]   # 0x6129ba33 (near call) via .hook_pmod
    for a in ISDEF_SITES:
        assert m[o(a)] == 0xdd and (a + struct.unpack_from('<i', m, o(a) + 1)[0]) & 0xffffffff == 0x6129bad6, hex(a)
        assert m[o(a) + 6] == 24, hex(a)
        m[o(a) + 1:o(a) + 5] = struct.pack('<i', sy['ed_isdef'] - a)
    ps = poly_sites(m, o)
    assert [v for _, v in ps] == [v for v in range(928, 976) if v not in (939, 951, 963)] and ps[-1][0] == 0x60b1d354, ps
    for a in (0x60b1d156, 0x60b1d1ff, 0x60b1d2a8):   # mov 939/951/963,d0; jmp 0x60b1d354 (the shared last read)
        assert m[o(a)] == 0x2c and m[o(a) + 3] == 0xcc and (a + 3 + struct.unpack_from('<h', m, o(a) + 4)[0]) & 0xffffffff == 0x60b1d354, hex(a)
    for a, v in ps:
        m[o(a):o(a) + 7] = b'\xdd' + struct.pack('<i', sy['ed_poly'] - a) + b'\x00\x04'
    m[o(EXT1[0]):o(EXT1[0]) + len(blobs['.ext1'])] = blobs['.ext1']
    m[o(EXT4[0]):o(EXT4[0]) + len(blobs['.ext4'])] = blobs['.ext4']
    m[o(EXT10[0]):o(EXT10[0]) + len(blobs['.ext10'])] = blobs['.ext10']
    m[o(EXT6[0]):o(EXT6[0]) + len(blobs['.ext6'])] = blobs['.ext6']
    m[o(EXT5[0]):o(EXT5[0]) + len(blobs['.ext5'])] = blobs['.ext5']
    m[o(EXT3[0]):o(EXT3[0]) + len(blobs['.ext3'])] = blobs['.ext3']
    m[o(EXT8[0]):o(EXT8[0]) + len(blobs['.ext8'])] = blobs['.ext8']
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
               ext1=dict(addr=hex(EXT1[0]), bytes=len(blobs['.ext1'])), ext4=dict(addr=hex(EXT4[0]), bytes=len(blobs['.ext4'])), ext10=dict(addr=hex(EXT10[0]), bytes=len(blobs['.ext10'])), ext6=dict(addr=hex(EXT6[0]), bytes=len(blobs['.ext6'])), ext5=dict(addr=hex(EXT5[0]), bytes=len(blobs['.ext5'])), ext3=dict(addr=hex(EXT3[0]), bytes=len(blobs['.ext3'])), ext8=dict(addr=hex(EXT8[0]), bytes=len(blobs['.ext8'])),
               bundles_bin_sha256=hashlib.sha256(test).hexdigest(), defaults_sha256=hashlib.sha256(dflt).hexdigest(),
               symbols={k: hex(v) for k, v in syms.items() if k.startswith(('hl_', 'pr_', 'sd_', 'ext', 'ed_', 'k_', 't_', 'gd_', 'wb_'))})
    (out / 'build.json').write_text(json.dumps(rep, indent=1))
    print(json.dumps({k: v for k, v in rep.items() if k != 'symbols'}, indent=1))
    return syms


C1 = {'hue': [5] * 12, 'light': [0] * 12}
C2 = {'hue': [-5] * 12, 'light': [0] * 12}

if __name__ == '__main__':
    ap = argparse.ArgumentParser(); ap.add_argument('--out', required=True)
    a = ap.parse_args(); build({}, {}, a.out)       # neutral built-in defaults and a neutral card file
