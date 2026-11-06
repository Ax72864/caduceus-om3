"""Exact integer model of the in-camera grain (v0.21 grain test 3). Y plane only (even bytes of YCbYCr 4:2:2).
Per row: one 32-bit xorshift per 4 pixels; n = lo nibble + hi nibble of a byte (0..30, triangular);
V[x] = (V[x] + n) >> 1 (vertical IIR, V starts at 15); h = (V[x] + V[x-1] + 1) >> 1 (0..30, V[-1] = 15).
Y' = T[Y][h], T = clamp(Y + (((64h - C) * G[Y] * S + 2^17) >> 18)), C centres h; G follows the camera's own MONO
grain: none in deep shadows, full from the midtones up, a little less at the top. S per level matches MONO
Low / Med / High at levels 1 / 3 / 5 (camera PB051137..148)."""
import numpy as np
def _ss(t): t = min(max(t, 0.0), 1.0); return t * t * (3 - 2 * t)
G = np.array([round(255 * (0.08 + 0.92 * _ss((y - 25) / 75)) * (1 - 0.25 * _ss((y - 200) / 55))) for y in range(256)], dtype=np.int64)
C = 945   # 64 x the mean of h (model: 14.759)
STRENGTH = (28, 56, 84, 112, 141)
def table(S):
    y = np.arange(256)[:, None]; h = np.arange(32)[None, :]
    d = ((64 * h - C) * G[:, None] * S + 131072) >> 18
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
        prev = np.concatenate([[15], V[:-1]])
        out[yy] = (V + prev + 1) >> 1
    return out, r
def apply(Y, S, seed=0x12345678):
    h, _ = noise(Y.shape[1], Y.shape[0], seed)
    return table(S)[Y, h]
