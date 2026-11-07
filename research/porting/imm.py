import sys, re, struct, numpy as np
sys.path.insert(0, '/home/claude/om3/port'); import xmatch as X
z = np.load('/home/claude/om3/port/dis/om3.npz'); a = z['a']; l = z['l']
d = open('/home/claude/om3/decoded/00_0100_50000000.decoded.bin', 'rb').read(); B = 0x60021020
lo, hi = (int(sys.argv[2], 16), int(sys.argv[3], 16)) if len(sys.argv) > 3 else (0, 1 << 32)
for v in [int(x) for x in sys.argv[1].split(',')]:
    p = struct.pack('<H', v); hits = []
    for m in re.finditer(re.escape(p), d):
        o = m.start() + B
        if not lo <= o < hi: continue
        i = np.searchsorted(a, o, side='right') - 1
        if i < 0: continue
        s = int(a[i])
        if s < o < s + int(l[i]):
            ins = X.disasm(X.OM3, s, s + 8)
            if ins and str(v) in ins[0][2]: hits.append('%x %s' % (s, ins[0][2]))
    print(v, len(hits), hits[:30])
