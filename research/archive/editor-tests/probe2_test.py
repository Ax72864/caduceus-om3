#!/usr/bin/env python3
"""Probe 2 colour-reader slice tests: block in the class-1 pool, STATE handle, getter stub."""
import json, struct, sys
sys.path.insert(0, '/home/claude/om3/emu'); sys.path.insert(0, '/home/claude/om3/pp')
import slice_test as T
import pp_test as PT
import build_probe2 as BP

STATE, POOL = 0x62b4dd16, 0xa2852000
HUE = lambda u: -1000 * u
LIGHT = lambda u: PT.L_LUT[u + 7]


def run(image, state, block_at, block, getter):
    d = T.Dbg()
    d('load', image=image)
    d.write(PT.GETTER, PT.stub(getter))
    d.write(STATE, struct.pack('<H', state))
    if block is not None:
        d.write(block_at, block)
    d.write(T.OUT, bytes(T.OUT_SIZE)); d.write(T.REQ, bytes(0x800)); d.write(T.JOB, bytes(0x100))
    d.write(T.JOB + 12, struct.pack('<I', T.OUT)); d.write(T.REQ + 1739, bytes([3, 0xfd, 1, 0, 0, 2, 0, 0, 0xff, 0, 4, 0]))
    d.write(T.SP - 0x40, b'\xa5' * 0x40)
    d('reset', regs=dict(d0='0x0', d1='0x0', a0='0x0', a1='0x0', d2='0x22222222', a3='0x33333333',
                         pc=hex(T.ENTRY), a2=hex(T.JOB), d3=hex(T.REQ), sp=hex(T.SP), psw='0x0'))
    r = d('cont', stops=[hex(T.RESUME)], maxMs=20000)
    res = dict(stop=r.get('stop'), regs=d('regs')['regs'], out=d.read(T.OUT, T.OUT_SIZE),
               block_after=d.read(block_at, 544) if block is not None else None)
    d.close()
    return res


def recs(out):
    return [(struct.unpack_from('<h', out, 836 + 24 * k + 18)[0], struct.unpack_from('<h', out, 836 + 24 * k + 22)[0])
            for k in range(12)]


def expect_for(slot):
    return [(HUE(slot['hue'][2 * (r % 6) + r // 6]), LIGHT(slot['light'][2 * (r % 6) + r // 6])) for r in range(12)]


def main(image):
    mixed = {'hue': [-7, -6, -5, -4, -3, -2, -1, 1, 2, 3, 4, 5], 'light': [7, 6, 5, 4, 3, 2, -2, -3, -4, -5, -6, -7]}
    dflt = BP.make_file({0: BP.C1})
    test = BP.make_file({0: BP.C1, 1: BP.C2, 2: mixed})
    bad_magic = b'EP7B' + test[4:]
    out_of_range = bytearray(test); out_of_range[32 + 64 * 1 + 5] = 8           # COLOR2 hue[5] = 8
    slot_off = bytearray(test); slot_off[32 + 64 * 1 + 31] = 0                   # COLOR2 flags: H/L off
    off = 0x400
    h = off + 1
    cases = [
        ('state 0 (not attempted)', 0, off, test, 1, None),
        ('state 0xFFFF (no table)', 0xffff, off, test, 1, None),
        ('defaults block, COLOR1', h, off, dflt, 1, BP.C1),
        ('defaults block, COLOR2 (absent)', h, off, dflt, 2, None),
        ('test file block, COLOR1', h, off, test, 1, BP.C1),
        ('test file block, COLOR2', h, off, test, 2, BP.C2),
        ('test file block, COLOR3 mixed', h, off, test, 3, mixed),
        ('test file block, COLOR4 (absent)', h, off, test, 4, None),
        ('test file block, profile 0', h, off, test, 0, None),
        ('test file block, profile 5', h, off, test, 5, None),
        ('misaligned handle', h + 1, off + 1, test, 1, None),
        ('handle past pool limit', 0xae82, 0xae81, test, 1, None),
        ('last valid handle', 0xae81, 0xae80, test, 2, BP.C2),
        ('wrong magic', h, off, bad_magic, 1, None),
        ('value out of range in COLOR2', h, off, bytes(out_of_range), 2, None),
        ('COLOR2 slot H/L flag off', h, off, bytes(slot_off), 2, None),
    ]
    base = run(T.STOCK, 0, off, test, 1)
    ok, rep = True, []
    for name, state, at, blk, g, exp in cases:
        p = run(image, state, POOL + at, blk, g)
        diff = [i for i in range(T.OUT_SIZE) if base['out'][i] != p['out'][i]]
        allowed = {836 + 24 * k + o for k in range(12) for o in (18, 19, 22, 23)}
        chk = dict(resume=p['regs']['pc'] == f'0x{T.RESUME:08x}' and p['stop'] == 'break',
                   no_fault=p['regs']['fault'] == '0x00000000',
                   callee_saved=(p['regs']['d2'], p['regs']['d3'], p['regs']['a2'], p['regs']['a3'], p['regs']['sp']) ==
                                ('0x22222222', f'0x{T.REQ:08x}', f'0x{T.JOB:08x}', '0x33333333', f'0x{T.SP:08x}'),
                   only_hl=set(diff) <= allowed,
                   values=(recs(p['out']) == expect_for(exp)) if exp else diff == [],
                   block_untouched=p['block_after'] == blk)
        ok &= all(chk.values())
        rep.append(dict(case=name, checks=chk, diff=len(diff)))
        print(f"{name:34} diff={len(diff):3} {'PASS' if all(chk.values()) else 'FAIL ' + str([k for k, v in chk.items() if not v])}")
    json.dump(rep, open('/home/claude/om3/pp/probe2_test_report.json', 'w'), indent=1)
    print('ALL PASS' if ok else 'SOME FAILED')


if __name__ == '__main__':
    main(sys.argv[1])
