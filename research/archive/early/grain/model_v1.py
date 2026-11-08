"""Exact integer model of the in-camera grain (v0.21 grain test 1). Y plane only (even bytes of YCbYCr 4:2:2).
Per row: pass 1 makes a noise row from one 32-bit xorshift per 4 pixels: n = lo nibble + hi nibble of a byte
(0..30, triangular); V[x] = (V[x] + n) >> 1 (vertical IIR, V starts at 15); h = (V[x] + V[x-1] + 2) >> 2 (0..15,
V[-1] = 15).
Pass 2: Y' = T[Y][h], T = clamp(Y + (((128h - 943) * g[Y] * S + 2^17) >> 18)), centred on the mean of h, g = midtone-weighted (0..255)."""
import numpy as np
G = np.array([round(255 * (0.35 + 0.65 * (4 * (y / 255) * (1 - y / 255)) ** 0.8)) for y in range(256)], dtype=np.int64)
def table(S):
    y = np.arange(256)[:, None]; h = np.arange(16)[None, :]
    d = ((128 * h - 943) * G[:, None] * S + 131072) >> 18     # (2h - 15 + 0.27) / 64: centred on h's mean 7.365
    return np.clip(y + d, 0, 255).astype(np.uint8)
def xorshift(x):
    x ^= (x << 13) & 0xffffffff; x ^= x >> 17; x ^= (x << 5) & 0xffffffff; return x
def noise(W, H, seed=0x12345678):
    V = np.full(W, 15, dtype=np.int64); out = np.zeros((H, W), dtype=np.uint8); r = seed
    for yy in range(H):
        rs = []
        for _ in range(W // 4):
            r = xorshift(r); rs.append(r)
        b = np.frombuffer(np.array(rs, dtype='<u4').tobytes(), dtype=np.uint8).astype(np.int64)
        n = (b & 15) + (b >> 4)
        V = (V + n) >> 1
        prev = np.concatenate([[15], V[:-1]])                       # v of x - 1 (15 at x = 0)
        out[yy] = (V + prev + 2) >> 2
    return out, r
def apply(Y, S, seed=0x12345678):
    h, _ = noise(Y.shape[1], Y.shape[0], seed)
    return table(S)[Y, h]
if __name__ == '__main__':
    h, _ = noise(1024, 256)
    print('h mean %.2f std %.2f' % (h.mean(), h.std()))
    for S in (64, 96, 144, 200, 280):
        y = np.full((256, 1024), 128, dtype=np.uint8); o = apply(y, S).astype(float)
        print('S', S, 'std at Y128 %.2f, at Y40 %.2f, at Y220 %.2f' % (o.std(), apply(np.full((64, 512), 40, np.uint8), S).std(), apply(np.full((64, 512), 220, np.uint8), S).std()))
