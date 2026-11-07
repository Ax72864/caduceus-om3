#!/usr/bin/env python3
"""Find the OM-3 1.1 counterpart of an E-P7 1.1 code address.

Method: disassemble a window of E-P7 code around ADDR (with objdump, synced to
instruction boundaries at ADDR), build a "shape" pattern that keeps each
instruction's opcode byte(s) and wildcards its operands (addresses, call/jump
displacements, struct offsets, immediates), then regex-search the whole OM-3
main program for that shape. Candidates are scored by how many of the
wildcarded bytes also match exactly, as a tie-breaker.

Read-only; prints JSON.
"""
import json, re, subprocess, sys
from functools import lru_cache

OBJDUMP = '/home/claude/om3/toolchain/build/binutils/objdump'
EP7 = dict(path='/home/claude/om3/ep7_decoded/00_0100_406a0000.decoded.bin', base=0x60020020)
OM3 = dict(path='/home/claude/om3/decoded/00_0100_50000000.decoded.bin', base=0x60021020)


@lru_cache(None)
def blob(p):
    return open(p, 'rb').read()


def disasm(m, start, stop):
    out = subprocess.run([OBJDUMP, '-b', 'binary', '-m', 'mn10300', '-D', '-z', '--insn-width=16',
                          f"--adjust-vma={m['base']:#x}", f'--start-address={start:#x}',
                          f'--stop-address={stop:#x}', m['path']], capture_output=True, text=True).stdout
    ins = []
    for line in out.splitlines():
        mm = re.match(r'\s*([0-9a-f]+):\t((?:[0-9a-f]{2} )+)\s*\t?(.*)', line)
        if mm:
            a = int(mm.group(1), 16); b = bytes.fromhex(mm.group(2).replace(' ', ''))
            ins.append((a, b, mm.group(3).strip()))
    return ins


def window(m, addr, back=40, fwd=72):
    """Instructions covering [addr-back, addr+fwd), with an instruction starting exactly at addr."""
    for k in range(back, back + 24):
        ins = disasm(m, addr - k, addr + fwd)
        if any(a == addr for a, _, _ in ins):
            ins = [i for i in ins if i[0] >= addr - back]
            # drop leading partial (first instruction may start before addr-back: fine)
            return ins
    return disasm(m, addr, addr + fwd)


PREFIX2 = set(range(0xf0, 0xff))   # f0..fe: two-byte opcode prefixes


def shape(ins, loose=False):
    """Regex bytes: keep opcode byte(s), wildcard operands. loose: also wildcard 2nd byte of f8-fe."""
    pat, fixed, full = b'', 0, b''
    for _, b, txt in ins:
        keep = 1
        if b[0] in PREFIX2 and len(b) >= 2:
            keep = 2
            if loose and b[0] >= 0xf8 and len(b) > 2:
                keep = 2
        if len(b) <= 2 and b[0] not in (0xc8, 0xc9, 0xc0, 0xc1, 0xc2, 0xc3, 0xc4, 0xc5, 0xc6, 0xc7, 0xca, 0xcb):
            keep = len(b)          # short register-only instructions: keep whole
        for i, x in enumerate(b):
            if i < keep:
                pat += re.escape(bytes([x])); fixed += 1
            else:
                pat += b'.'
        full += b
    return pat, fixed, full


def locate(addr, back=40, fwd=72, src=EP7, dst=OM3, maxhits=8):
    ins = window(src, addr, back, fwd)
    if not ins:
        return dict(addr=hex(addr), error='no disassembly')
    first = ins[0][0]
    pat, fixed, full = shape(ins)
    data = blob(dst['path'])
    hits = []
    for mm in re.finditer(pat, data, re.DOTALL):
        cand = mm.start()
        seg = data[cand:cand + len(full)]
        same = sum(1 for x, y in zip(seg, full) if x == y)
        hits.append((same, dst['base'] + cand + (addr - first)))
        if len(hits) > 200:
            break
    hits.sort(reverse=True)
    return dict(addr=hex(addr), window=[hex(first), hex(ins[-1][0] + len(ins[-1][1]))],
                insns=len(ins), fixed_bytes=fixed, bytes=len(full), nhits=len(hits),
                best=[dict(om3=hex(a), exact_bytes=s) for s, a in hits[:maxhits]])


if __name__ == '__main__':
    for a in sys.argv[1:]:
        print(json.dumps(locate(int(a, 16))))
