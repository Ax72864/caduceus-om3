#!/usr/bin/env python3
"""Build the OM-3 1.1 probe P1 package (shutter-event flag store + gated per-profile H/L)."""
import argparse, hashlib, json, struct, subprocess, sys
from pathlib import Path
sys.path.insert(0, '/home/claude/om3/tools'); sys.path.insert(0, '/home/claude/om3/pp')
from oe_decode import parse, encode, wordsum
import build_pp as P

HERE = Path(__file__).resolve().parent
HOOKS = {'.hook_color': (0x60518615, bytes.fromhex('cd6cfdf060')),        # call 0x60518381,[d2,d3,a2,a3],96
         '.hook_shutter': (0x60415216, bytes.fromhex('cd2d01f024'))}       # call 0x60415343,[d2,d3,a2,a3],36
SHUTTER_CONTEXT = (0x604151fc, '5810fae0fffffac80001c80e5810fae0fffffac80101c9095c0c')
FLAG = 0x62b4dd16


def build(looks_path, out):
    looks = json.loads(Path(looks_path).read_text())
    flags, rows = P.table(looks)
    out = Path(out); out.mkdir(parents=True, exist_ok=False)
    (out / 'table.inc').write_text(''.join(f' .hword {h},{l}\n' for rec in rows for h, l in rec))
    syms = [f'--defsym=FLAG{i+1}={f}' for i, f in enumerate(flags)]
    subprocess.run([P.AS, '-I', out, *syms, '-o', out / 'p.o', HERE / 'probe.s'], check=True)
    subprocess.run([P.LD, '-T', HERE / 'probe.ld', '-o', out / 'p.elf', out / 'p.o'], check=True)
    blobs = {}
    for s in list(HOOKS) + ['.ext']:
        subprocess.run([P.OBJCOPY, '-O', 'binary', '-j', s, out / 'p.elf', out / (s[1:] + '.bin')], check=True)
        blobs[s] = (out / (s[1:] + '.bin')).read_bytes()
    raw = Path('/mnt/user-data/uploads/OLY_E_147_1100_0000_0000_3.BIN').read_bytes()
    assert hashlib.sha256(raw).hexdigest() == P.STOCK_SHA
    comps = parse(raw); mc = comps[0]
    assert hashlib.sha256(mc['dec']).hexdigest() == P.MAIN_SHA
    m = bytearray(mc['dec']); o = lambda a: a - P.BASE
    # --- stock preconditions
    a, ctx = SHUTTER_CONTEXT
    assert m[o(a):o(a) + len(ctx) // 2].hex() == ctx, 'shutter hook context'
    for s, (addr, stock) in HOOKS.items():
        assert bytes(m[o(addr):o(addr) + 5]) == stock and len(blobs[s]) == 5, s
    ext = blobs['.ext']
    assert P.EXT_LO + len(ext) <= P.EXT_MAX, len(ext)
    assert set(m[o(P.TAIL_FF):o(P.SEC1_END)]) == {0xff}
    # FLAG: never referenced as a 32-bit literal (cached/uncached); inside boot-cleared .bss
    for v in (FLAG, FLAG + 1, FLAG + 0x40000000, FLAG + 0x40000001):
        assert bytes(m).count(struct.pack('<I', v)) == 0, hex(v)
    assert 0x628ac700 <= FLAG < 0x63410088
    # --- apply
    for s, (addr, _) in HOOKS.items():
        m[o(addr):o(addr) + 5] = blobs[s]
    m[o(P.EXT_LO):o(P.EXT_LO) + len(ext)] = ext
    # the only new absolute references to FLAG are ours
    refs = [P.BASE + i for i in range(len(m) - 3) if m[i:i + 4] == struct.pack('<I', FLAG)]
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
    rep = dict(package_sha256=hashlib.sha256(pkg).hexdigest(), main_sha256=hashlib.sha256(bytes(m)).hexdigest(),
               main_bytes_changed=sum(x != y for x, y in zip(m, mc['dec'])), flags=flags,
               hooks={s: dict(addr=hex(a), stock=st.hex(), new=blobs[s].hex()) for s, (a, st) in HOOKS.items()},
               ext=dict(addr=hex(P.EXT_LO), bytes=len(ext)), flag=hex(FLAG), flag_literal_sites=[hex(r) for r in refs],
               symbols={l.split()[2]: l.split()[0] for l in nm.splitlines() if len(l.split()) == 3})
    (out / 'build.json').write_text(json.dumps(rep, indent=1))
    print(json.dumps(rep, indent=1))


if __name__ == '__main__':
    ap = argparse.ArgumentParser(); ap.add_argument('looks'); ap.add_argument('--out', required=True)
    a = ap.parse_args(); build(a.looks, a.out)
