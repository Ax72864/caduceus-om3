#!/usr/bin/env python3
"""Emulator tests for probe P1: shutter-hook slice and FLAG-gated colour slice, stock vs probe."""
import json, struct, sys
sys.path.insert(0, '/home/claude/om3/emu'); sys.path.insert(0, '/home/claude/om3/pp')
import slice_test as T
import pp_test as PT

FLAG = 0x62b4dd16
S = 0xa21e0000                     # sp of the appevent function 0x60415111 at the hook
SH_ENTRY, SH_RESUME = 0x60415214, 0x6041521b   # mov (12,sp),a0 ; (hook) ; resume
L_LUT = PT.L_LUT


def shutter_run(image, event, flag0):
    d = T.Dbg()
    d('load', image=image)
    d.write(S - 0x200, b'\xa5' * 0x300)
    d.write(S + 12, struct.pack('<I', S + 16))
    d.write(S + 16, struct.pack('<I', event))
    d.write(FLAG - 6, bytes(16)); d.write(FLAG, struct.pack('<H', flag0))
    regs = dict(d0='0x0', d1='0x0', a0='0x0', a1='0x0', d2='0x22222222', d3='0x33333333',
                a2='0x44444444', a3='0x55555555', pc=hex(SH_ENTRY), sp=hex(S), psw='0x0')
    d('reset', regs=regs)
    r = d('cont', stops=[hex(SH_RESUME)], maxMs=20000)
    res = dict(stop=r.get('stop'), regs=d('regs')['regs'], stack=d.read(S - 0x200, 0x300),
               flag=struct.unpack('<H', d.read(FLAG, 2))[0], flag_area=d.read(FLAG - 6, 16))
    d.close()
    return res


def color_run(image, getter_value, flag0, sat):
    d = T.Dbg()
    d('load', image=image)
    d.write(PT.GETTER, PT.stub(getter_value))
    d.write(FLAG, struct.pack('<H', flag0))
    d.write(T.OUT, bytes(T.OUT_SIZE)); d.write(T.REQ, bytes(0x800)); d.write(T.JOB, bytes(0x100))
    d.write(T.JOB + 12, struct.pack('<I', T.OUT)); d.write(T.REQ + 1739, bytes(v & 0xff for v in sat))
    d('reset', regs=dict(d0='0x0', d1='0x0', a0='0x0', a1='0x0', d2='0x22222222', a3='0x33333333',
                         pc=hex(T.ENTRY), a2=hex(T.JOB), d3=hex(T.REQ), sp=hex(T.SP), psw='0x0'))
    r = d('cont', stops=[hex(T.RESUME)], maxMs=20000)
    res = dict(stop=r.get('stop'), regs=d('regs')['regs'], out=d.read(T.OUT, T.OUT_SIZE),
               flag=struct.unpack('<H', d.read(FLAG, 2))[0])
    d.close()
    return res


def main(probe):
    ok, rep = True, dict(shutter=[], color=[])
    print('-- shutter hook slice')
    for ev in (0x00000100, 0x00000101, 0x02000100, 0x02000101):
        for f0 in (0, 1):
            s, p = shutter_run(T.STOCK, ev, f0), shutter_run(probe, ev, f0)
            sdiff = [i for i in range(0x300) if s['stack'][i] != p['stack'][i]]
            ret_slot = set(range(0x200, 0x204))              # (S): return-address slot of the replayed call
            exp_flag = 1 if f0 == 0 else f0
            chk = dict(
                both_resume=s['regs']['pc'] == p['regs']['pc'] == f'0x{SH_RESUME:08x}',
                no_fault=s['regs']['fault'] == p['regs']['fault'] == '0x00000000',
                regs_same={k: s['regs'][k] for k in ('d2', 'd3', 'a2', 'a3', 'sp')} ==
                          {k: p['regs'][k] for k in ('d2', 'd3', 'a2', 'a3', 'sp')},
                stack_same_except_ret_slot=set(sdiff) <= ret_slot,
                stock_flag_untouched=s['flag'] == f0,
                probe_flag=p['flag'] == exp_flag,
                neighbours_untouched=p['flag_area'][:6] == bytes(6) and p['flag_area'][8:] == bytes(8),
            )
            ok &= all(chk.values())
            rep['shutter'].append(dict(event=hex(ev), flag0=f0, checks=chk, stack_diff=[hex(S - 0x200 + i) for i in sdiff],
                                       event_word_after=p['stack'][0x210:0x214].hex()))
            print(f"event={ev:#010x} flag0={f0} stock_flag={s['flag']} probe_flag={p['flag']} stackdiff={len(sdiff)} "
                  f"{'PASS' if all(chk.values()) else 'FAIL ' + str([k for k, v in chk.items() if not v])}")
    print('-- colour hook slice')
    sat = [-5, -4, -3, -2, -1, 0, 1, 2, 3, 4, 5, -5]
    base = color_run(T.STOCK, 1, 0, sat)
    for f0 in (0, 1, 0xffff):
        for g in (1, 2, 3, 4, 0, 9):
            p = color_run(probe, g, f0, sat)
            diff = [i for i in range(T.OUT_SIZE) if base['out'][i] != p['out'][i]]
            looks = f0 != 0 and g == 1
            hues = [struct.unpack_from('<h', p['out'], 836 + 24 * k + 18)[0] for k in range(12)]
            chk = dict(resume=p['regs']['pc'] == f'0x{T.RESUME:08x}', no_fault=p['regs']['fault'] == '0x00000000',
                       regs=(p['regs']['d2'], p['regs']['d3'], p['regs']['a2'], p['regs']['a3'], p['regs']['sp']) ==
                            ('0x22222222', f'0x{T.REQ:08x}', f'0x{T.JOB:08x}', '0x33333333', f'0x{T.SP:08x}'),
                       output=(hues == [-5000] * 12 and len(diff) == 24) if looks else diff == [],
                       flag_not_written=p['flag'] == f0)
            ok &= all(chk.values())
            rep['color'].append(dict(flag=f0, getter=g, expect='COLOR1 look' if looks else 'stock', checks=chk, diff=len(diff)))
            print(f"flag={f0:#06x} getter={g} expect={'COLOR1 look' if looks else 'stock':11} diff={len(diff):3} "
                  f"{'PASS' if all(chk.values()) else 'FAIL ' + str([k for k, v in chk.items() if not v])}")
    json.dump(rep, open('/home/claude/om3/pp/probe_test_report.json', 'w'), indent=1)
    print('ALL PASS' if ok else 'SOME FAILED')


if __name__ == '__main__':
    main(sys.argv[1])
