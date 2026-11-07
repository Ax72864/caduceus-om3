#!/usr/bin/env python3
"""Fuzzy E-P7 -> OM-3 code-address mapping by k-gram diagonal voting + local alignment.

tokens: a coarse instruction shape that ignores register numbers and operands:
  prefixed (f0..fe): (b0, b1 high nibble, length); others: (b0 high nibble, length)
k-grams of K tokens are hashed; for a window of E-P7 instructions around the
query, every OM-3 position sharing a k-gram votes for the diagonal
(om_index - ep7_index). The winning diagonal is refined with difflib on the
finer shape (b0, b1 for prefixed) to place the exact instruction.
"""
import difflib, json, sys
import numpy as np

K = 6
D = '/home/claude/om3/port/dis/'


def load(name):
    z = np.load(D + name + '.npz')
    a, l, b0, b1, t = z['a'], z['l'], z['b0'].astype(np.uint32), z['b1'].astype(np.uint32), z['t']
    pref = (b0 >= 0xf0) & (b0 <= 0xfe)
    coarse = np.where(pref, (b0 << 12) | ((b1 >> 4) << 8) | l, ((b0 >> 4) << 8) | l).astype(np.uint64)
    fine = np.where(pref, (b0 << 16) | (b1 << 8) | l, (b0 << 8) | l).astype(np.uint64)
    return dict(a=a, l=l, b0=b0, b1=b1, t=t, coarse=coarse, fine=fine)


def kgram_hash(tok):
    h = np.zeros(len(tok) - K + 1, np.uint64)
    P = np.uint64(1000003)
    for i in range(K):
        h = h * P + tok[i:len(tok) - K + 1 + i]
    return h


class Index:
    def __init__(self, m):
        self.m = m
        h = kgram_hash(m['coarse'])
        self.order = np.argsort(h, kind='stable')
        self.sorted = h[self.order]

    def lookup(self, hv, cap=64):
        lo = np.searchsorted(self.sorted, hv, 'left'); hi = np.searchsorted(self.sorted, hv, 'right')
        if hi - lo > cap:
            return None
        return self.order[lo:hi]


def idx_of(m, addr):
    i = int(np.searchsorted(m['a'], addr))
    return i if i < len(m['a']) and m['a'][i] == addr else None


def map_addr(src, ix, addr, half=40):
    qi = idx_of(src, addr)
    if qi is None:
        return dict(addr=hex(addr), error='not an instruction boundary in source')
    lo, hi = max(0, qi - half), min(len(src['a']), qi + half)
    q = src['coarse'][lo:hi]
    qh = kgram_hash(q)
    votes = {}
    for j, hv in enumerate(qh):
        pos = ix.lookup(hv)
        if pos is None:
            continue
        for p in pos:
            d = int(p) - (lo + j)
            votes[d] = votes.get(d, 0) + 1
    if not votes:
        return dict(addr=hex(addr), votes=0)
    # merge near diagonals (small insertions shift the diagonal)
    best = sorted(votes.items(), key=lambda kv: -kv[1])[:5]
    dst = ix.m
    cands = []
    for d, v in best:
        center = qi + d
        clo, chi = max(0, center - half - 10), min(len(dst['a']), center + half + 10)
        sm = difflib.SequenceMatcher(None, list(src['fine'][lo:hi]), list(dst['fine'][clo:chi]), autojunk=False)
        target, interp = None, False
        blocks = [b for b in sm.get_matching_blocks() if b.size]
        for blk in blocks:
            if blk.a <= qi - lo < blk.a + blk.size:
                target = clo + blk.b + (qi - lo - blk.a)
        if target is None and blocks:
            # nearest matched block before the query instruction: carry its offset forward
            prev = [b for b in blocks if b.a + b.size <= qi - lo]
            if prev:
                b = prev[-1]
                target = min(clo + b.b + (qi - lo - b.a), len(dst['a']) - 1); interp = True
        ratio = sm.ratio()
        support = sum(c for dd, c in votes.items() if abs(dd - d) <= 3)
        cands.append(dict(om3=hex(int(dst['a'][target])) if target is not None else None,
                          diag_votes=v, support=support, fine_ratio=round(ratio, 3), interpolated=interp,
                          exact_site=bool(target is not None and src['l'][qi] == dst['l'][target] and
                                      src['b0'][qi] == dst['b0'][target])))
    cands.sort(key=lambda c: (c['om3'] is not None, c['support'], c['fine_ratio']), reverse=True)
    top = cands[0]
    second = next((c for c in cands[1:] if c['om3'] and c['om3'] != top['om3']), None)
    return dict(addr=hex(addr), best=top, runner_up=second, kgrams=len(qh))


if __name__ == '__main__':
    import time
    t0 = time.time()
    ep7, om3 = load('ep7'), load('om3')
    ix = Index(om3)
    print('index built', round(time.time() - t0, 1), 's', file=sys.stderr)
    for a in sys.argv[1:]:
        print(json.dumps(map_addr(ep7, ix, int(a, 16))))
