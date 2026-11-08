#!/usr/bin/env python3
"""Map Caduceus phase-1 E-P7 1.1 code addresses to OM-3 1.1 and write phase1_map.json."""
import json, sys
sys.path.insert(0, '/home/claude/om3/port')
import align as A

SITES = [
    # (group, name, E-P7 address, note)
    ('hl', 'job constructor', 0x603537eb, 'image job constructor (fn)'),
    ('hl', 'job alloc size', 0x603537f0, 'mov 15488,d0'),
    ('hl', 'job tail memset len', 0x6035390c, 'mov 16,d1'),
    ('hl', 'request callback', 0x60355fd4, 'job callback fn used as type check'),
    ('hl', 'COLOR builder', 0x603b0068, 'fn'),
    ('hl', 'selector', 0x603b0252, 'fn'),
    ('hl', 'builder call (hook)', 0x603b02d9, 'call builder'),
    ('hl', 'builder resume', 0x603b02de, 'mov (60,a2),d0'),
    ('hl', 'converter 1', 0x603e62d1, 'fn'),
    ('hl', 'conv1 hook site', 0x603e66ab, 'movbu (a3),d0; cmp 12,d0'),
    ('hl', 'conv1 succ A', 0x603e66b1, ''),
    ('hl', 'conv1 succ B', 0x603e66d5, ''),
    ('hl', 'converter 2', 0x603e8af1, 'fn'),
    ('hl', 'conv2 hook site', 0x603e91f0, 'mov (36,sp),a0; movbu (a0),d0; cmp 12,d0'),
    ('lv', 'selector entry (lv)', 0x603b02ab, ''),
    ('lv', 'selector exit (lv)', 0x603b0338, ''),
    ('lv', 'global setting getter', 0x6005e971, 'fn'),
    ('lv', 'lv helper', 0x602a85a2, 'fn'),
    ('sd', 'appevent get', 0x602c7f5a, 'fn (HLS_EVENT)'),
    ('sd', 'shutter tracker call (hook)', 0x602c805f, 'call 0x602c818c'),
    ('sd', 'hook resume', 0x602c8064, ''),
    ('sd', 'release-notice check', 0x602c818c, 'fn'),
    ('sd', 'malloc', 0x60022782, 'fn'),
    ('sd', 'free', 0x600227b4, 'fn'),
    ('sd', 'fopen', 0x60634fbc, 'fn'),
    ('sd', 'fclose', 0x60634fc5, 'fn'),
    ('sd', 'fseek', 0x60635243, 'fn'),
    ('sd', 'ftell', 0x606351d9, 'fn'),
    ('sd', 'fread', 0x6063514b, 'fn'),
    ('sd', 'get task id', 0x600317ac, 'fn'),
    ('sd', 'media status setter', 0x6077d590, 'fn'),
    ('sd', 'section copy done', 0x600457e7, 'fn'),
    ('upd', 'FIRMUP_CLI entry', 0x60c95bab, 'fn'),
    ('upd', 'update validator', 0x60c964c1, 'fn'),
    ('upd', 'suffix parser', 0x60c95fd8, 'fn'),
    ('upd', 'flash writer wrapper', 0x60c971e5, 'fn'),
]


def main():
    ep7, om3 = A.load('ep7'), A.load('om3')
    ix = A.Index(om3)
    rows = []
    for g, name, a, note in SITES:
        r = A.map_addr(ep7, ix, a)
        b = r.get('best') or {}
        rows.append(dict(group=g, name=name, ep7=hex(a), note=note, om3=b.get('om3'), support=b.get('support'),
                         fine_ratio=b.get('fine_ratio'), exact_site=b.get('exact_site'),
                         interpolated=b.get('interpolated'), runner_up=(r.get('runner_up') or {}).get('om3'),
                         runner_up_support=(r.get('runner_up') or {}).get('support'), error=r.get('error')))
    json.dump(rows, open('/home/claude/om3/port/phase1_map.json', 'w'), indent=1)
    for x in rows:
        print(f"{x['group']:4} {x['name']:28} {x['ep7']} -> {x['om3']}  support {x['support']}  ratio {x['fine_ratio']}"
              f"  exact {x['exact_site']} interp {x['interpolated']}  2nd {x['runner_up']}({x['runner_up_support']}) {x['error'] or ''}")


if __name__ == '__main__':
    main()
