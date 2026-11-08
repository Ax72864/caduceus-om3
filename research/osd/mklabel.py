"""Readout labels (the 'Vivid' picture 0xa4cf688c, 70x30) for each wheel page, fitted to the stock 'Vivid' metrics:
cap rows 3..26 (24 px), x-height rows 9..26, baseline row 26, edge = dark 7 (1 px), grey 8, faint 9; soft fill 11/12."""
import sys, json
sys.path.insert(0, '/home/claude/om3/osd')
from osd11 import decode11, encode11, rd
from PIL import Image, ImageDraw, ImageFont
import numpy as np
from scipy import ndimage
W, H, BASE, CAP = 70, 30, 26, 24
FONT = '/usr/share/fonts/truetype/dejavu/DejaVuSansCondensed.ttf'
descs = {d[0]: d for d in json.load(open('/home/claude/om3/osd/descs11.json'))}
_, sw, sh, ssize, sp = descs[0xa4cf688c]
stock = np.frombuffer(decode11(rd(sp, ssize), sw, sh), dtype=np.uint8).reshape(sh, sw)
def raster(txt, fs, sq):
    S = 4
    f = ImageFont.truetype(FONT, fs * S)
    im = Image.new('L', (fs * S * len(txt) + 200, fs * S * 2), 0); ImageDraw.Draw(im).text((50, 20), txt, font=f, fill=255)
    a = np.array(im); xs = np.nonzero(a.any(axis=0))[0]
    im = im.crop((xs.min(), 0, xs.max() + 1, a.shape[0]))
    small = im.resize((max(1, round(im.width / S * sq)), round(im.height / S)), Image.LANCZOS)
    return np.array(small).astype(int)
def cap_rows(fs):
    a = raster('H', fs, 1.0); r = np.nonzero((a > 128).any(axis=1))[0]; return r.min(), r.max()
def build(txt, cap=CAP, maxw=62):
    fs = next(f for f in range(10, 60) if (lambda r: r[1] - r[0] + 1)(cap_rows(f)) >= cap)
    sq = 0.80
    a = raster(txt, fs, sq)
    while a.shape[1] > maxw and sq > 0.45:
        sq = round(sq - 0.02, 2); a = raster(txt, fs, sq)
    top, base = cap_rows(fs)
    shift = BASE - base
    desc_max = H - 3 - BASE                         # rows below the baseline that still leave room for the edge
    ink = np.nonzero((a > 40).any(axis=1))[0]
    if ink.max() - base > desc_max:                 # squeeze the descender (g) into the rows left
        tail = Image.fromarray(a[base + 1:ink.max() + 1].astype(np.uint8))
        tail = np.array(tail.resize((tail.width, desc_max), Image.LANCZOS)).astype(int)
        a = np.vstack([a[:base + 1], tail, np.zeros((a.shape[0] - base - 1 - desc_max, a.shape[1]), dtype=int)])
    fill = a > 128; soft = (a > 60) & ~fill
    lay = np.zeros((H, W), dtype=np.uint8)
    h, w = fill.shape
    x0 = 5 + (maxw - w) // 2 if txt != 'Saturation' else 4
    x0 = 5                                          # left-aligned like stock (fill from col 5)
    for y in range(h):
        yy = y + shift
        if not 0 <= yy < H: continue
        for x in range(w):
            if fill[y, x]: lay[yy, x0 + x] = 10
            elif soft[y, x]: lay[yy, x0 + x] = 11 if a[y, x] > 100 else 12
    fm = lay == 10
    e = ndimage.distance_transform_edt(~fm)
    out = np.zeros_like(lay)
    out[(e > 0) & (e <= 1.0)] = 7
    out[(e > 1.0) & (e <= 2.0)] = 8
    out[(e > 2.0) & (e <= 2.5)] = 9
    out[(lay == 11) | (lay == 12)] = lay[(lay == 11) | (lay == 12)]
    out[fm] = 10
    return out, fs, sq
if __name__ == '__main__':
    pal = {0: (30, 30, 60), 7: (20, 20, 20), 8: (90, 90, 90), 9: (60, 60, 60), 10: (255, 255, 255), 11: (200, 200, 200), 12: (160, 160, 160)}
    words = [('stock', None), ('Saturation', 18), ('Hue', CAP), ('Light', CAP), ('WB/BW', CAP), ('Glow', CAP)]
    sheet = Image.new('RGB', (W * 4 + 40, (H * 4 + 10) * len(words) + 20), (30, 30, 60)); out = {}
    for k, (txt, cap) in enumerate(words):
        if txt == 'stock': px = stock
        else:
            px, fs, sq = build(txt, cap)
            r = np.nonzero((px == 10).any(axis=1))[0]; c = np.nonzero((px == 10).any(axis=0))[0]
            print(txt, 'font', fs, 'squeeze', sq, 'fill rows', r.min(), r.max(), 'cols', c.min(), c.max())
            enc = encode11(bytes(px.flatten()), W, H); assert decode11(enc, W, H) == bytes(px.flatten()); out[txt] = enc.hex()
        rgb = Image.new('RGB', (W, H)); rgb.putdata([pal.get(int(v), (255, 0, 255)) for v in px.flatten()])
        sheet.paste(rgb.resize((W * 4, H * 4), Image.NEAREST), (20, 10 + k * (H * 4 + 10)))
    sheet.save('/home/claude/om3/osd/label_preview.png'); json.dump(out, open('/home/claude/om3/osd/label_new.json', 'w'))
    print({k: len(v) // 2 for k, v in out.items()})
