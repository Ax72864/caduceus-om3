#!/usr/bin/env python3
"""Build the OM-3 1.1 hue/lightness proof-of-concept package.

Inputs: stock OLY_E_147_1100_0000_0000.BIN (exact hash) and the two binary
spans from hl_poc.elf. Only the main component (kind 0x100) is modified; all
other components are copied unchanged. Output: a new full-size package.
"""
import argparse, hashlib, json, struct, sys
from pathlib import Path
sys.path.insert(0, str(Path(__file__).resolve().parents[1] / 'tools'))
from oe_decode import parse, encode, decode, wordsum  # our own decoder

STOCK_SHA = '8c133084414533159f587bf46bfb4152714c4074312a47c8d8503e33d605696d'
MAIN_SHA = '5e8d376e9111a44ac0352f26030d7c1b17026d42c45f3600cfa02a0e8c5b7d59'
BASE = 0x60021020
HOOK, HOOK_STOCK = 0x60518615, bytes.fromhex('cd6cfdf060')     # call builder,[..],96
EXT_LO, EXT_HI = 0x607187a8, 0x60718800                        # section 2 loaded tail
TABLE_END = 0x607187a4                                          # end of 13-entry ctor table


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('--stock', required=True)
    ap.add_argument('--hook', required=True)
    ap.add_argument('--ext', required=True)
    ap.add_argument('--out', required=True)
    a = ap.parse_args()
    raw = Path(a.stock).read_bytes()
    assert hashlib.sha256(raw).hexdigest() == STOCK_SHA, 'stock hash'
    comps = parse(raw)
    assert all(c['checksum_ok'] for c in comps)
    main_c = comps[0]
    assert main_c['kind'] == 0x100 and hashlib.sha256(main_c['dec']).hexdigest() == MAIN_SHA
    m = bytearray(main_c['dec'])
    o = lambda x: x - BASE
    hook, ext = Path(a.hook).read_bytes(), Path(a.ext).read_bytes()
    # --- stock preconditions
    assert bytes(m[o(HOOK):o(HOOK) + 5]) == HOOK_STOCK, 'hook site'
    assert len(hook) == 5
    assert EXT_LO + len(ext) <= EXT_HI, 'extension too large'
    assert m[o(TABLE_END):o(EXT_HI)] == b'\xff' * (EXT_HI - TABLE_END), 'tail not FF'
    # --- apply
    m[o(HOOK):o(HOOK) + 5] = hook
    m[o(EXT_LO):o(EXT_LO) + len(ext)] = ext
    changed = sum(x != y for x, y in zip(m, main_c['dec']))
    # --- fix additive checksum: last trailer word makes the total zero
    hdr, trl = main_c['hdr'], bytearray(main_c['trl'])
    struct.pack_into('<I', trl, 28, 0)
    fix = (-(wordsum(hdr) + wordsum(bytes(m)) + wordsum(bytes(trl)))) & 0xFFFFFFFF
    struct.pack_into('<I', trl, 28, fix)
    out = bytearray()
    for i, c in enumerate(comps):
        if i == 0:
            out += hdr + encode(bytes(m)) + bytes(trl)
        else:
            out += c['hdr'] + c['enc'] + c['trl']
    out = bytes(out)
    # --- re-parse and verify
    again = parse(out)
    assert all(c['checksum_ok'] for c in again), 'checksum after patch'
    assert len(out) == len(raw)
    assert [c['hdr'][:28] for c in again] == [c['hdr'][:28] for c in comps]
    for i in range(1, len(comps)):
        assert again[i]['dec'] == comps[i]['dec']
    assert again[0]['dec'] == bytes(m)
    diff_file = [i for i in range(len(raw)) if raw[i] != out[i]] if False else None
    od = Path(a.out); od.mkdir(parents=True, exist_ok=False)
    (od / 'OLY_E_147_1100_0000_0000.BIN').write_bytes(out)
    rep = dict(stock_sha256=STOCK_SHA, output_sha256=hashlib.sha256(out).hexdigest(),
               output_bytes=len(out), patched_main_sha256=hashlib.sha256(bytes(m)).hexdigest(),
               main_bytes_changed=changed, hook=dict(address=hex(HOOK), stock=HOOK_STOCK.hex(),
               new=hook.hex()), extension=dict(address=hex(EXT_LO), bytes=len(ext), hex=ext.hex()),
               main_trailer_checksum=dict(old=main_c['trl'][28:].hex(), new=bytes(trl[28:]).hex()),
               other_components_unchanged=True, all_checksums_valid=True)
    (od / 'build.json').write_text(json.dumps(rep, indent=2))
    print(json.dumps(rep, indent=2))


if __name__ == '__main__':
    main()
