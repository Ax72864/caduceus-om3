import sys, numpy as np
sys.path.insert(0, '/home/claude/om3/port')
import xmatch as X
z = np.load('/home/claude/om3/port/dis/om3.npz')
a, t = z['a'], z['t']
for s in sys.argv[1:]:
    tg = int(s, 16)
    idx = np.nonzero(t == tg)[0]
    out = []
    for i in idx[:12]:
        ins = X.disasm(X.OM3, int(a[i]), int(a[i]) + 8)
        out.append('%x %s' % (int(a[i]), ins[0][2] if ins else '?'))
    print(hex(tg), len(idx), out)
