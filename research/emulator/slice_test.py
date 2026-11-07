#!/usr/bin/env python3
"""Function-slice test of the OM-3 1.1 COLOR builder call, stock vs patched,
on om-emu's standalone MN10300 machine (emu/bin/debug.mjs --serve).

Slice: pc 0x60518601 (selector, just before the builder call) -> stop at
0x6051861a (the selector's instruction after the call; the patch's jmp back
lands there too). The selector's job (a2) and request (d3) are synthetic RAM
structures; the COLOR table, gains and the movhu (0x606bb1d8) word come from
the firmware image itself.
"""
import json, subprocess, sys, os, struct

EMU = '/home/claude/flatpanda/om-emu'
NODE = '/home/claude/node26/package/bin/node'
STOCK = 'unpacked/E147/OLY_E_147_1100_0000_0000.BIN.blk00000000.OE.0100.bin'
PATCHED = '/home/claude/om3/check/poc_decoded/00_0100_50000000.decoded.bin'

JOB, REQ, OUT, SP = 0xa2120000, 0xa2110000, 0xa2100000, 0xa21f0000
OUT_SIZE = 0x1200            # builder writes up to OUT+4384
ENTRY, RESUME = 0x60518601, 0x6051861a
SENT = dict(d2=0x22222222, a3=0x33333333, d0=0, d1=0, a0=0, a1=0)


class Dbg:
    def __init__(self):
        env = dict(os.environ, OM_EMU_MODEL='E147')
        self.p = subprocess.Popen([NODE, 'emu/bin/debug.mjs', '--serve'], cwd=EMU, env=env,
                                  stdin=subprocess.PIPE, stdout=subprocess.PIPE, text=True)
        self.n = 0

    def __call__(self, op, **kw):
        self.n += 1
        self.p.stdin.write(json.dumps(dict(id=self.n, op=op, **kw)) + '\n'); self.p.stdin.flush()
        r = json.loads(self.p.stdout.readline())
        if not r.get('ok'):
            raise RuntimeError(f'{op}: {r}')
        return r

    def read(self, a, n):
        out = b''
        while n:
            k = min(n, 0x800)
            out += bytes.fromhex(self('read', addr=hex(a), size=k)['hex']); a += k; n -= k
        return out

    def write(self, a, b):
        while b:
            k = b[:0x400]
            self('write', addr=hex(a), hex=k.hex()); a += len(k); b = b[len(k):]

    def close(self):
        try: self('quit')
        except Exception: pass
        self.p.wait(timeout=30)


def run(image, sat, trace=None):
    d = Dbg()
    d('load', image=image)
    # synthetic RAM: zero the regions, then build job + request
    d.write(OUT, bytes(OUT_SIZE)); d.write(REQ, bytes(0x800)); d.write(JOB, bytes(0x100))
    d.write(SP - 0x200, b'\xa5' * 0x200)            # poison below SP: see what the frame writes
    d.write(JOB + 12, struct.pack('<I', OUT))
    d.write(REQ + 1739, bytes(v & 0xff for v in sat))
    regs = dict(SENT, pc=hex(ENTRY), a2=hex(JOB), d3=hex(REQ), sp=hex(SP), psw='0x0')
    regs = {k: (hex(v) if isinstance(v, int) else v) for k, v in regs.items()}
    d('reset', regs=regs)
    if trace:
        d('trace', exec=trace, format='jsonl')
    r = d('cont', stops=[hex(RESUME)], maxMs=20000)
    if trace:
        d('trace', off=True)
    regs_after = d('regs')['regs']
    out = d.read(OUT, OUT_SIZE)
    req = d.read(REQ, 0x800)
    job = d.read(JOB, 0x100)
    stack = d.read(SP - 0x200, 0x200)
    d.close()
    return dict(stop=r, regs=regs_after, out=out, req=req, job=job, stack=stack)


def records(out):
    rows = []
    for k in range(12):
        rec = out[836 + 24 * k: 836 + 24 * (k + 1)]
        w = struct.unpack('<6I', rec)
        hue, = struct.unpack_from('<h', rec, 18)
        sat, = struct.unpack_from('<h', rec, 20)
        light, = struct.unpack_from('<h', rec, 22)
        rows.append(dict(rec=k, hue=hue, sat=sat, light=light, words=[f'{x:08x}' for x in w]))
    return rows


def main():
    cases = {
        'neutral': [0] * 12,
        'ramp': [-5, -4, -3, -2, -1, 0, 1, 2, 3, 4, 5, -5],
        'extremes': [7, -7, 5, -5, 3, -3, 1, -1, 7, -7, 0, 2],
    }
    report = {}
    ok = True
    for name, sat in cases.items():
        s = run(STOCK, sat)
        p = run(PATCHED, sat, trace=f'/home/claude/om3/emu/trace-{name}.jsonl' if name == 'ramp' else None)
        res = {}
        for img, x in (('stock', s), ('patched', p)):
            res[img] = dict(stop_kind=x['stop'].get('stop') or x['stop'].get('reason') or x['stop'],
                            pc=x['regs']['pc'], sp=x['regs']['sp'],
                            preserved={k: x['regs'][k] for k in ('d2', 'd3', 'a2', 'a3')},
                            insns=int(x['regs']['insns'], 16), fault=x['regs']['fault'])
        diff = [i for i in range(OUT_SIZE) if s['out'][i] != p['out'][i]]
        allowed = set()
        for k in range(12):
            base = 836 + 24 * k
            allowed |= {base + 18, base + 19, base + 22, base + 23}
        rs, rp = records(s['out']), records(p['out'])
        checks = dict(
            both_reached_resume=s['regs']['pc'] == p['regs']['pc'] == f'0x{RESUME:08x}',
            no_fault=s['regs']['fault'] == p['regs']['fault'] == '0x00000000',
            sp_identical=s['regs']['sp'] == p['regs']['sp'] == f'0x{SP:08x}',
            callee_saved_identical=res['stock']['preserved'] == res['patched']['preserved'],
            callee_saved_match_inputs=res['stock']['preserved'] == dict(d2='0x22222222', d3=f'0x{REQ:08x}', a2=f'0x{JOB:08x}', a3='0x33333333'),
            output_diffs_only_in_hue_light=set(diff) <= allowed,
            patched_hue_all_minus5000=all(r['hue'] == -5000 for r in rp),
            patched_light_all_zero=all(r['light'] == 0 for r in rp),
            stock_hue_light_zero=all(r['hue'] == 0 and r['light'] == 0 for r in rs),
            saturation_identical=[r['sat'] for r in rs] == [r['sat'] for r in rp],
            request_untouched=s['req'] == p['req'],
            job_identical=s['job'] == p['job'],
        )
        ok &= all(checks.values())
        report[name] = dict(sat_request=sat, runs=res, checks=checks, output_bytes_differing=len(diff),
                            stock_records=rs, patched_records=rp,
                            stack_bytes_differing=sum(a != b for a, b in zip(s['stack'], p['stack'])))
    json.dump(report, open('/home/claude/om3/emu/slice_report.json', 'w'), indent=1)
    for name, r in report.items():
        print(f"== {name}: sat request {r['sat_request']}")
        print('  runs:', json.dumps(r['runs']))
        print('  checks:', json.dumps(r['checks']))
        print('  output bytes differing:', r['output_bytes_differing'], ' stack bytes differing:', r['stack_bytes_differing'])
        print('  stock   sat:', [x['sat'] for x in r['stock_records']], 'hue:', [x['hue'] for x in r['stock_records']])
        print('  patched sat:', [x['sat'] for x in r['patched_records']], 'hue:', [x['hue'] for x in r['patched_records']])
    print('ALL CHECKS PASS' if ok else 'SOME CHECK FAILED')


if __name__ == '__main__':
    main()
