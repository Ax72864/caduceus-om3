#!/usr/bin/env python3
"""Left-column pictures for our Picture Mode rows (v0.23), drawn from scratch (DejaVu Sans Condensed, a free font) in
the camera's OSD text style (palette 0 clear, 7 dark edge 2 px, 10 white fill, 11 / 12 soft fill); no camera graphics
are copied.
- Slider rows (46 x 46, the stock "S" icon's size): the words "Blk" / "Wht" / "A-B" / "G-M" in the place of the
  Sharpness row's "S", so the camera draws its own value ("-2") next to them.
- Choice rows (100 x 76, the stock "COLOR / 1" cell picture's size): two lines, the setting's short name over its
  value: "Vignette" Off / On, "Noise" Off / Low / Std / High.
Output: OSD type-11 streams, patched into the firmware by build.py (in PICTURES order; ids 0x7f80 + index).
usage: mkicons.py [--preview PNG]"""
import argparse
import numpy as np
from PIL import Image, ImageDraw, ImageFont
from scipy import ndimage

FONT = '/usr/share/fonts/truetype/dejavu/DejaVuSansCondensed.ttf'
W, H = 46, 46                      # slider-row icon
CW, CH = 100, 76                   # choice-row cell picture
# (lines, width, height): one line = (text, cap height px, baseline row)
PICTURES = [
    ([('Blk', 20, 33)], W, H), ([('Wht', 20, 33)], W, H), ([('A-B', 20, 33)], W, H), ([('G-M', 20, 33)], W, H),
    ([('Vignette', 15, 30), ('Off', 18, 60)], CW, CH), ([('Vignette', 15, 30), ('On', 18, 60)], CW, CH),
    ([('Noise', 15, 30), ('Off', 18, 60)], CW, CH), ([('Noise', 15, 30), ('Low', 18, 60)], CW, CH),
    ([('Noise', 15, 30), ('Std', 18, 60)], CW, CH), ([('Noise', 15, 30), ('High', 18, 60)], CW, CH),
]


def word(txt, cap, maxw, sx=1.0):
    """The word's ink coverage 0..1, cap height `cap`, `sx` times its width, squeezed to fit maxw; and its baseline row
    in that array."""
    S = 8
    f = ImageFont.truetype(FONT, 100 * S)
    im = Image.new('L', (100 * S * (len(txt) + 1), 200 * S), 0)
    ImageDraw.Draw(im).text((20 * S, 40 * S), txt, font=f, fill=255)
    a = np.array(im)
    hb = Image.new('L', (200 * S, 200 * S), 0); ImageDraw.Draw(hb).text((20 * S, 40 * S), 'H', font=f, fill=255)
    rows = np.nonzero(np.array(hb).any(axis=1))[0]
    cap_top, cap_bot = rows.min(), rows.max()
    cols = np.nonzero(a.any(axis=0))[0]
    ink = np.nonzero(a.any(axis=1))[0]
    a = a[ink.min():ink.max() + 1, cols.min():cols.max() + 1]
    scale = cap / (cap_bot - cap_top + 1)
    w = a.shape[1] * scale * sx
    sq = min(1.0, maxw / w)
    out_w, out_h = max(1, round(w * sq)), max(1, round(a.shape[0] * scale))
    small = np.array(Image.fromarray(a).resize((out_w, out_h), Image.BOX)).astype(float) / 255
    return small, (cap_bot - ink.min()) * scale


def picture(lines, w, h, sx=1.0, th=(0.30, 0.50, 0.70)):
    """w x h palette indices: fill 10, soft 11 / 12 (coverage thresholds th), a 2 px dark edge 7 round the ink."""
    cov = np.zeros((h, w))
    for txt, cap, base in lines:
        small, b = word(txt, cap, w - 6, sx)
        y0, x0 = int(round(base - b)), (w - small.shape[1]) // 2
        sh = cov[y0:y0 + small.shape[0], x0:x0 + small.shape[1]]
        cov[y0:y0 + small.shape[0], x0:x0 + small.shape[1]] = np.maximum(sh, small[:sh.shape[0], :sh.shape[1]])
    return quant(cov, th)


def quant(cov, th=(0.30, 0.50, 0.70)):
    px = np.zeros(cov.shape, dtype=np.uint8)
    px[cov >= th[0]] = 12
    px[cov >= th[1]] = 11
    px[cov >= th[2]] = 10
    ink = px > 0
    px[ndimage.binary_dilation(ink, structure=np.ones((3, 3)), iterations=2) & ~ink] = 7
    return px


# v0.24 film cells (100 x 76, the stock "COLOR / 1" strip cell's size): "FILM" over the film's number, matched to the
# stock cells' measured metrics (owner: "the same style and size as COLOR 1-4"): word fill rows 16..36 and 73 px for
# "COLOR" -> cap 20, baseline 36, 0.88 width, coverage thresholds 0.2 / 0.4 / 0.6 in our font; digits fill rows
# 43..68, 9..16 px wide -> cap 26, baseline 69, 0.95 width. The camera
# draws them itself when the films load (firmware fl_mk): the "FILM" line (rows 0..FT-1) as it is, then each digit's
# picture (FD rows, FW wide) under it, centred; two digits overlap by 2 px (their dark edges), a digit pixel replacing
# only clear or edge pixels. film_cell() is the same rule, for the preview and the checks.
FCW, FCH, FT = 100, 76, 40
FD = FCH - FT


def film_top():
    return picture([('FILM', 20, 36)], FCW, FT, 0.88, (0.20, 0.40, 0.60))


def film_digits():
    """10 arrays FD x FW: the digits 0..9, cap 24, baseline 68 - FT, centred in a common width."""
    small = [word(str(d), 26, 99, 0.95) for d in range(10)]
    fw = max(a.shape[1] for a, _ in small) + 4
    out = []
    for a, b in small:
        cov = np.zeros((FD, fw))
        y0, x0 = int(round(69 - FT - b)), (fw - a.shape[1]) // 2
        cov[y0:y0 + a.shape[0], x0:x0 + a.shape[1]] = a
        out.append(quant(cov))
    return out


def film_cell(n, top=None, digs=None):
    top = film_top() if top is None else top
    digs = film_digits() if digs is None else digs
    fw = digs[0].shape[1]
    px = np.zeros((FCH, FCW), dtype=np.uint8)
    px[:FT] = top
    ds = [int(c) for c in str(n)]
    tw = len(ds) * fw - 2 * (len(ds) - 1)
    x = (FCW - tw) // 2
    for d in ds:
        g = digs[d]
        for yy in range(FD):
            for xx in range(fw):
                v, c = g[yy, xx], px[FT + yy, x + xx]
                if v and (c == 0 or c == 7):
                    px[FT + yy, x + xx] = v
        x += fw - 2
    return px


def pack4(a):
    """palette rows, two pixels a byte (low nibble first)"""
    f = a.flatten().tolist()
    if len(f) % 2: f.append(0)
    return bytes(f[i] | f[i + 1] << 4 for i in range(0, len(f), 2))


def encode11(px, w, h):
    """OSD type-11 stream; as the stock pictures, no run crosses a row's end."""
    toks, i = [], 0
    while i < len(px):
        v, r = px[i], 1
        while r < 16 and (i + r) % w and px[i + r] == v: r += 1
        toks.append(v << 4 | (r - 1)); i += r
    out = bytearray([(h - 1) & 255, ((h - 1) >> 8 & 3) | (((w - 1) & 15) << 4), ((w - 1) >> 4) & 63, 11])
    for k in range(0, len(toks), 5):
        word_ = 0
        for s, t in enumerate(toks[k:k + 5]): word_ |= t << (12 * s)
        out += word_.to_bytes(8, 'little')
    return bytes(out)


def streams():
    """[(w, h, stream)] in PICTURES order."""
    return [(w, h, encode11(bytes(picture(l, w, h).flatten()), w, h)) for l, w, h in PICTURES]


if __name__ == '__main__':
    ap = argparse.ArgumentParser(); ap.add_argument('--preview'); a = ap.parse_args()
    print([len(s) for _, _, s in streams()], 'bytes')
    if a.preview:
        pal = {0: (40, 40, 40), 7: (10, 10, 10), 10: (255, 255, 255), 11: (210, 210, 210), 12: (150, 150, 150)}
        sheet = Image.new('RGB', (len(PICTURES) * (CW + 10), CH), (40, 40, 40))
        for k, (l, w, h) in enumerate(PICTURES):
            rgb = Image.new('RGB', (w, h)); rgb.putdata([pal[int(v)] for v in picture(l, w, h).flatten()])
            sheet.paste(rgb, (k * (CW + 10), 0))
        sheet.resize((sheet.width * 2, CH * 2), Image.NEAREST).save(a.preview)
