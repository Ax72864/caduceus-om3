#!/usr/bin/env python3
"""Emulator slice tests for the per-profile H/L build (om-emu standalone machine).

Slice 0x60518601 -> 0x6051861a, as in emu/slice_test.py, with the settings getter
0x60063380 replaced in emulated memory by a stub returning a chosen value
(`mov imm32,d0; ret [d2,d3],12`), for both stock and patched images.
"""
import json, struct, sys
sys.path.insert(0, '/home/claude/om3/emu')
import slice_test as T

GETTER = 0x60063380
L_LUT = [-300, -250, -200, -150, -100, -50, -25, 0, 25, 50, 100, 150, 200, 250, 300]


def stub(value):
    return b'\xfc\xcc' + struct.pack('<I', value & 0xffffffff) + b'\xdf\xc0\x0c'


def run(image, sat, getter_value, native_getter=False):
    d = T.Dbg()
    d('load', image=image)
    if not native_getter:
        d.write(GETTER, stub(getter_value))
    d.write(T.OUT, bytes(T.OUT_SIZE)); d.write(T.REQ, bytes(0x800)); d.write(T.JOB, bytes(0x100))
    d.write(T.SP - 0x200, b'\xa5' * 0x200)
    d.write(T.JOB + 12, struct.pack('<I', T.OUT))
    d.write(T.REQ + 1739, bytes(v & 0xff for v in sat))
    regs = dict(d0='0x0', d1='0x0', a0='0x0', a1='0x0', d2='0x22222222', a3='0x33333333',
                pc=hex(T.ENTRY), a2=hex(T.JOB), d3=hex(T.REQ), sp=hex(T.SP), psw='0x0')
    d('reset', regs=regs)
    r = d('cont', stops=[hex(T.RESUME)], maxMs=20000)
    out = dict(stop=r.get('stop'), regs=d('regs')['regs'], out=d.read(T.OUT, T.OUT_SIZE),
               req=d.read(T.REQ, 0x800), job=d.read(T.JOB, 0x100), stack=d.read(T.SP - 0x200, 0x200),
               stderr=r.get('stderr', [])[-3:])
    d.close()
    return out


def expected(looks, slot):
    lk = looks.get(f'COLOR{slot + 1}')
    if lk is None:
        return None
    rec = []
    for r in range(12):
        w = 2 * (r % 6) + r // 6
        rec.append((-1000 * lk['hue'][w], L_LUT[lk['light'][w] + 7]))
    return rec


def main(patched, looks_path):
    looks = json.load(open(looks_path))
    sats = {'neutral': [0] * 12, 'ramp': [-5, -4, -3, -2, -1, 0, 1, 2, 3, 4, 5, -5]}
    values = [1, 2, 3, 4, 0, 5, 255, 0x12340002, 0xffffff01]
    results, ok = [], True
    for sname, sat in sats.items():
        s = run(T.STOCK, sat, 1)
        for v in values:
            p = run(patched, sat, v)
            profile = v & 0xff
            exp = expected(looks, profile - 1) if 1 <= profile <= 4 else None
            diff = [i for i in range(T.OUT_SIZE) if s['out'][i] != p['out'][i]]
            allowed = {836 + 24 * k + o for k in range(12) for o in (18, 19, 22, 23)}
            recs = [struct.unpack_from('<hh', p['out'], 836 + 24 * k + 18)[0:1] +
                    struct.unpack_from('<h', p['out'], 836 + 24 * k + 22) for k in range(12)]
            sat_p = [struct.unpack_from('<h', p['out'], 836 + 24 * k + 20)[0] for k in range(12)]
            sat_s = [struct.unpack_from('<h', s['out'], 836 + 24 * k + 20)[0] for k in range(12)]
            checks = dict(
                reached_resume=p['regs']['pc'] == f'0x{T.RESUME:08x}' and p['stop'] == 'break',
                no_fault=p['regs']['fault'] == '0x00000000',
                sp_ok=p['regs']['sp'] == f'0x{T.SP:08x}',
                callee_saved_ok=(p['regs']['d2'], p['regs']['d3'], p['regs']['a2'], p['regs']['a3']) ==
                                ('0x22222222', f'0x{T.REQ:08x}', f'0x{T.JOB:08x}', '0x33333333'),
                diffs_only_hl=set(diff) <= allowed,
                values_ok=(recs == [tuple(x) for x in exp]) if exp else (diff == []),
                saturation_unchanged=sat_p == sat_s,
                request_job_untouched=p['req'] == s['req'] and p['job'] == s['job'],
            )
            ok &= all(checks.values())
            results.append(dict(sat=sname, getter_returns=hex(v), expect='looks of COLOR%d' % profile if exp else 'stock',
                                checks=checks, diff_bytes=len(diff), hue=[r[0] for r in recs], light=[r[1] for r in recs]))
            print(f"{sname:8} getter={hex(v):11} expect={results[-1]['expect']:16} diff={len(diff):3} "
                  f"{'PASS' if all(checks.values()) else 'FAIL ' + str([k for k, x in checks.items() if not x])}")
    # native getter (no stub): informational
    try:
        n = run(patched, [0] * 12, 0, native_getter=True)
        results.append(dict(native_getter=dict(stop=n['stop'], pc=n['regs']['pc'], fault=n['regs']['fault'],
                                               d0=n['regs']['d0'], stderr=n['stderr'])))
        print('native getter run:', n['stop'], n['regs']['pc'], 'fault', n['regs']['fault'], n['stderr'])
    except Exception as e:
        print('native getter run error:', e)
    json.dump(results, open('/home/claude/om3/pp/pp_test_report.json', 'w'), indent=1)
    print('ALL PASS' if ok else 'SOME FAILED')


if __name__ == '__main__':
    main(sys.argv[1], sys.argv[2])
