#!/usr/bin/env python3
"""Build the OM-3 1.1 per-profile hue/lightness package from a looks JSON.

looks JSON: {"COLOR1": {"hue": [12 ints -7..7], "light": [12 ints -7..7]}, ... }
Sector order (UI): yellow, orange, orange_red, red, magenta, violet, blue,
blue_cyan, cyan, green_cyan, green, yellow_green. A missing profile = disabled.
Scales (PEN-F HSL patch): hue raw = -1000*ui; lightness raw = L_LUT[ui+7].
Record r of the builder output holds UI sector w = 2*(r%6) + r//6.
"""
import argparse, hashlib, json, struct, subprocess, sys
from pathlib import Path
sys.path.insert(0, '/home/claude/om3/tools')
from oe_decode import parse, encode, wordsum

TC = Path('/home/claude/om3/toolchain/build')
AS, LD, OBJCOPY = TC / 'gas/as-new', TC / 'ld/ld-new', TC / 'binutils/objcopy'
HERE = Path(__file__).resolve().parent
STOCK_SHA = '8c133084414533159f587bf46bfb4152714c4074312a47c8d8503e33d605696d'
MAIN_SHA = '5e8d376e9111a44ac0352f26030d7c1b17026d42c45f3600cfa02a0e8c5b7d59'
BASE = 0x60021020
HOOK, HOOK_STOCK = 0x60518615, bytes.fromhex('cd6cfdf060')
EXT_LO, EXT_MAX = 0x6031e920, 0x6031ebf0      # section-1 loaded tail; FF from 0x6031e910, load end 0x6031f000
TAIL_FF, SEC1_END = 0x6031e910, 0x6031f000
L_LUT = [-300, -250, -200, -150, -100, -50, -25, 0, 25, 50, 100, 150, 200, 250, 300]
SECTORS = ['yellow', 'orange', 'orange_red', 'red', 'magenta', 'violet', 'blue', 'blue_cyan', 'cyan',
           'green_cyan', 'green', 'yellow_green']


def table(looks):
    flags, rows = [], []
    for k in range(1, 5):
        lk = looks.get(f'COLOR{k}')
        if lk is None:
            flags.append(0); rows.append([(0, 0)] * 12); continue
        h, l = lk['hue'], lk['light']
        assert len(h) == len(l) == 12 and all(isinstance(v, int) and -7 <= v <= 7 for v in h + l), f'COLOR{k} values'
        flags.append(1)
        rec = []
        for r in range(12):
            w = 2 * (r % 6) + r // 6
            rec.append((-1000 * h[w], L_LUT[l[w] + 7]))
        rows.append(rec)
    return flags, rows


def build(looks_path, out):
    looks = json.loads(Path(looks_path).read_text())
    flags, rows = table(looks)
    out = Path(out); out.mkdir(parents=True, exist_ok=False)
    inc = ''.join(f' .hword {hv},{lv}\n' for rec in rows for hv, lv in rec)
    (out / 'table.inc').write_text(inc)
    syms = [f'--defsym=FLAG{i+1}={f}' for i, f in enumerate(flags)]
    subprocess.run([AS, '-I', out, *syms, '-o', out / 'hl.o', HERE / 'hl_pp.s'], check=True)
    subprocess.run([LD, '-T', HERE / 'layout.ld', '-o', out / 'hl.elf', out / 'hl.o'], check=True)
    for s in ('hook', 'ext'):
        subprocess.run([OBJCOPY, '-O', 'binary', '-j', '.' + s, out / 'hl.elf', out / f'{s}.bin'], check=True)
    hook, ext = (out / 'hook.bin').read_bytes(), (out / 'ext.bin').read_bytes()
    nm = subprocess.run([TC / 'binutils/nm-new', out / 'hl.elf'], capture_output=True, text=True).stdout
    sym = {l.split()[2]: int(l.split()[0], 16) for l in nm.splitlines() if len(l.split()) == 3}
    raw = Path('/mnt/user-data/uploads/OLY_E_147_1100_0000_0000_3.BIN').read_bytes()
    assert hashlib.sha256(raw).hexdigest() == STOCK_SHA
    comps = parse(raw); mc = comps[0]
    assert all(c['checksum_ok'] for c in comps) and hashlib.sha256(mc['dec']).hexdigest() == MAIN_SHA
    m = bytearray(mc['dec']); o = lambda a: a - BASE
    # --- stock preconditions
    assert bytes(m[o(HOOK):o(HOOK) + 5]) == HOOK_STOCK and len(hook) == 5
    assert EXT_LO + len(ext) <= EXT_MAX, f'extension {len(ext)} B too large'
    assert set(m[o(TAIL_FF):o(SEC1_END)]) == {0xff} and m[o(TAIL_FF) - 1] != 0xff, 'section-1 tail'
    assert struct.unpack_from('<I', m, o(0x60045e82) + 2)[0] == SEC1_END, 'section-1 end getter'
    assert m[o(0x60063380):o(0x60063380) + 1] != b'\xff'
    # --- apply
    m[o(HOOK):o(HOOK) + 5] = hook
    m[o(EXT_LO):o(EXT_LO) + len(ext)] = ext
    hdr, trl = mc['hdr'], bytearray(mc['trl'])
    struct.pack_into('<I', trl, 28, 0)
    struct.pack_into('<I', trl, 28, (-(wordsum(hdr) + wordsum(bytes(m)) + wordsum(bytes(trl)))) & 0xFFFFFFFF)
    pkg = b''.join((hdr + encode(bytes(m)) + bytes(trl)) if i == 0 else (c['hdr'] + c['enc'] + c['trl'])
                   for i, c in enumerate(comps))
    again = parse(pkg)
    assert all(c['checksum_ok'] for c in again) and again[0]['dec'] == bytes(m)
    assert all(again[i]['dec'] == comps[i]['dec'] for i in range(1, len(comps))) and len(pkg) == len(raw)
    changed = sum(a != b for a, b in zip(m, mc['dec']))
    (out / 'main.bin').write_bytes(bytes(m))
    (out / 'E1479999.BIN').write_bytes(pkg)
    rep = dict(looks=looks, flags=flags, stock_sha256=STOCK_SHA, package_sha256=hashlib.sha256(pkg).hexdigest(),
               main_sha256=hashlib.sha256(bytes(m)).hexdigest(), main_bytes_changed=changed,
               hook=dict(addr=hex(HOOK), stock=HOOK_STOCK.hex(), new=hook.hex()),
               ext=dict(addr=hex(EXT_LO), bytes=len(ext), end=hex(EXT_LO + len(ext))),
               symbols={k: hex(v) for k, v in sym.items() if k.startswith('hl_')},
               table_records=[[list(p) for p in rec] for rec in rows])
    (out / 'build.json').write_text(json.dumps(rep, indent=1))
    print(json.dumps({k: v for k, v in rep.items() if k not in ('table_records', 'looks')}, indent=1))


if __name__ == '__main__':
    ap = argparse.ArgumentParser(); ap.add_argument('looks'); ap.add_argument('--out', required=True)
    a = ap.parse_args(); build(a.looks, a.out)
