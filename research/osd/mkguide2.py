"""Guide pictures 'Hue [INFO]' / 'Light [INFO]' fitted to the stock 'Color All [INFO]' metrics (fill index 10:
cap/ascender rows 10..40, x-height rows 18..40, baseline row 40, 'o' 15 px wide), outline 7 (2 px), rim 9."""
import sys, json, struct
sys.path.insert(0, '/home/claude/om3/osd')
from osd11 import decode11, encode11, rd
from PIL import Image, ImageDraw, ImageFont, ImageFilter
import numpy as np
W, H, BOX = 175, 50, 109
FONT = '/usr/share/fonts/truetype/dejavu/DejaVuSansCondensed.ttf'
d = rd(0xa49ecdf8, 24); size, p = struct.unpack_from('<2I', d, 12)
stock = np.frombuffer(decode11(rd(p, size), W, H), dtype=np.uint8).reshape(H, W)
CAP, XH, OW = 31, 23, 15
DESC = 6                                 # deepest fill row 46: the 2-px edge + rim end by row 49                 # stock fill heights and 'o' width
def raster(txt, fs, sq):
    S = 4                                 # supersample
    f = ImageFont.truetype(FONT, fs * S)
    im = Image.new('L', (fs * S * len(txt) + 200, fs * S * 2), 0); ImageDraw.Draw(im).text((50, 20), txt, font=f, fill=255)
    a = np.array(im); ys, xs = np.nonzero(a > 0)
    asc = ImageFont.truetype(FONT, fs * S).getbbox('H')                   # cap box at the same origin
    im = im.crop((xs.min(), 0, xs.max() + 1, a.shape[0]))
    small = im.resize((max(1, round(im.width / S * sq)), round(im.height / S)), Image.LANCZOS)
    return np.array(small).astype(int), (20 + asc[1]) / S, (20 + asc[3]) / S     # array, cap top, baseline (rows)
def metrics(fill):
    return np.nonzero(fill.any(axis=1))[0]
def fit(txt):
    best = None
    for fs in range(20, 60):
        a, top, base = raster('H', fs, 1.0)
        r = metrics(a > 128)
        if r.max() - r.min() + 1 >= CAP: break
    for sq in [x / 100 for x in range(60, 111)]:
        a, _, _ = raster('o', fs, sq); c = np.nonzero((a > 128).any(axis=0))[0]
        if c.max() - c.min() + 1 >= OW: break
    a, top, base = raster(txt, fs, sq)
    while a.shape[1] > 100 and sq > 0.5:                 # long words: narrow until the fill fits cols 2..102
        sq = round(sq - 0.02, 2); a, top, base = raster(txt, fs, sq)
    return a, fs, sq, base
def build(txt):
    a, fs, sq, base = fit(txt)
    a0, _, _ = raster(txt[0], fs, sq); base_row = np.nonzero((a0 > 128).any(axis=1))[0].max()
    ink = np.nonzero((a > 40).any(axis=1))[0]
    desc = ink.max() - base_row                     # rows below the baseline (the 'g' tail)
    if desc > DESC:                                 # squeeze only the tail so it and its edge fit (rows 41..49)
        tail = Image.fromarray(a[base_row + 1:ink.max() + 1].astype(np.uint8))
        tail = np.array(tail.resize((tail.width, DESC), Image.LANCZOS)).astype(int)
        a = np.vstack([a[:base_row + 1], tail, np.zeros((a.shape[0] - base_row - 1 - DESC, a.shape[1]), dtype=int)])
    fill = a > 128; soft = (a > 40) & ~fill
    rows = np.nonzero(fill.any(axis=1))[0]
    # baseline: the bottom fill row of the 'H'/'L' (first glyph, flat bottom)
    a0, _, _ = raster(txt[0], fs, sq); base_row = np.nonzero((a0 > 128).any(axis=1))[0].max()
    shift = 40 - base_row                                                   # place the baseline on row 40
    img = np.zeros((H, W), dtype=np.uint8); img[:, BOX:] = stock[:, BOX:]
    lay = np.zeros((H, W), dtype=np.uint8)
    h, w = fill.shape
    x0 = 102 - w + 1                                                        # right fill edge at col 102, as stock
    assert x0 >= 2, (txt, w)
    for y in range(h):
        yy = y + shift
        if not 0 <= yy < H: continue
        for x in range(w):
            if fill[y, x]: lay[yy, x0 + x] = 10
            elif soft[y, x]: lay[yy, x0 + x] = 11
    from scipy import ndimage
    fillm = lay == 10
    e = ndimage.distance_transform_edt(~fillm)          # distance to the white fill, as the stock edge is built
    word = np.zeros_like(lay)
    word[(e > 0) & (e <= 1.0)] = 7                        # orthogonal neighbours: dark ...
    word[(e > 0) & (e <= 1.0) & (lay == 11)] = 11          # ... or light where the glyph edge is soft
    word[(e > 1.0) & (e < 1.5)] = 12                       # diagonal neighbours: light grey (stock 12)
    word[(e >= 1.5) & (e <= 2.0)] = 7                     # the dark line
    word[(e > 2.0) & (e <= 2.9)] = 9                      # faint rim (stock 9), partial like stock
    word[fillm] = 10
    word[:, BOX - 2:] = 0
    img[:, :BOX - 2] = word[:, :BOX - 2]
    return img, fs, sq
if __name__ == '__main__':
    pal = {0: (30, 30, 60), 7: (20, 20, 20), 8: (90, 90, 90), 9: (60, 60, 60), 10: (255, 255, 255), 11: (200, 200, 200), 12: (160, 160, 160)}
    sheet = Image.new('RGB', (W * 3 + 40, H * 3 * 5 + 40), (30, 30, 60)); out = {}
    for k, txt in enumerate(['stock', 'Hue', 'Light', 'WB/BW', 'Glow']):
        if txt == 'stock': px = stock
        else:
            px, fs, sq = build(txt)
            r = np.nonzero((px[:, :BOX] == 10).any(axis=1))[0]
            print(txt, 'font', fs, 'squeeze', sq, 'fill rows', r.min(), r.max())
            enc = encode11(bytes(px.flatten()), W, H); assert decode11(enc, W, H) == bytes(px.flatten()); out[txt] = enc.hex()
        rgb = Image.new('RGB', (W, H)); rgb.putdata([pal.get(int(v), (255, 0, 255)) for v in px.flatten()])
        sheet.paste(rgb.resize((W * 3, H * 3), Image.NEAREST), (20, 20 + k * H * 3))
    sheet.save('guide_preview2.png'); out['WB'] = out.pop('WB/BW'); json.dump(out, open('guide_new.json', 'w'))
    print({k: len(v) // 2 for k, v in out.items()})
