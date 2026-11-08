#!/usr/bin/env python3
"""Left-column icons for the Picture Mode rows Blacks / Whites (v0.23): the words "Blk" / "Wht" drawn in the place of
the Sharpness row's "S" icon, so the camera draws its own value ("-2") next to them as on the stock slider rows.
Drawn from scratch (DejaVu Sans Condensed, a free font) to the stock icon's metrics (46 x 46) and the camera's OSD
text style (palette 0 clear, 7 dark edge 2 px, 10 white fill, 11 / 12 soft fill); no camera graphics are copied.
Output: OSD type-11 streams (as card/mklabels.py's encode11), patched into the firmware by build.py.
usage: mkicons.py [--preview PNG]"""
import argparse
import numpy as np
from PIL import Image, ImageDraw, ImageFont
from scipy import ndimage

W, H = 46, 46                      # the stock "S" icon's size (its slot in the left column)
CAP = 20                           # cap height in px, as the camera's value digits next to the icon
FONT = '/usr/share/fonts/truetype/dejavu/DejaVuSansCondensed.ttf'
ICONS = ['Blk', 'Wht']


def coverage(txt, maxw):
    """The word's ink coverage 0..1 on the W x H grid, cap height CAP, centred, squeezed to fit maxw."""
    S = 8
    f = ImageFont.truetype(FONT, 100 * S)
    im = Image.new('L', (100 * S * len(txt), 200 * S), 0)
    ImageDraw.Draw(im).text((20 * S, 40 * S), txt, font=f, fill=255)
    a = np.array(im)
    hb = Image.new('L', (200 * S, 200 * S), 0); ImageDraw.Draw(hb).text((20 * S, 40 * S), 'H', font=f, fill=255)
    rows = np.nonzero(np.array(hb).any(axis=1))[0]
    cap_top, cap_bot = rows.min(), rows.max()
    cols = np.nonzero(a.any(axis=0))[0]
    ink_rows = np.nonzero(a.any(axis=1))[0]
    a = a[ink_rows.min():ink_rows.max() + 1, cols.min():cols.max() + 1]
    scale = CAP / (cap_bot - cap_top + 1)
    w = a.shape[1] * scale
    sq = min(1.0, maxw / w)
    out_w, out_h = max(1, round(w * sq)), max(1, round(a.shape[0] * scale))
    small = np.array(Image.fromarray(a).resize((out_w, out_h), Image.BOX)).astype(float) / 255
    cov = np.zeros((H, W))
    top = (H - CAP) // 2 - (cap_top - ink_rows.min()) * scale
    y0, x0 = int(round(top)), (W - out_w) // 2
    cov[y0:y0 + out_h, x0:x0 + out_w] = small
    return cov


def icon(txt):
    """W x H palette indices: fill 10, soft 11 / 12, a 2 px dark edge 7 round the ink."""
    c = coverage(txt, W - 6)
    px = np.zeros((H, W), dtype=np.uint8)
    px[c >= 0.30] = 12
    px[c >= 0.50] = 11
    px[c >= 0.70] = 10
    ink = px > 0
    edge = ndimage.binary_dilation(ink, structure=np.ones((3, 3)), iterations=2) & ~ink
    px[edge] = 7
    return px


def encode11(px, w, h):
    """OSD type-11 stream; as the stock pictures, no run crosses a row's end."""
    toks, i = [], 0
    while i < len(px):
        v, r = px[i], 1
        while r < 16 and (i + r) % w and px[i + r] == v: r += 1
        toks.append(v << 4 | (r - 1)); i += r
    out = bytearray([(h - 1) & 255, ((h - 1) >> 8 & 3) | (((w - 1) & 15) << 4), ((w - 1) >> 4) & 63, 11])
    for k in range(0, len(toks), 5):
        word = 0
        for s, t in enumerate(toks[k:k + 5]): word |= t << (12 * s)
        out += word.to_bytes(8, 'little')
    return bytes(out)


def streams():
    return [encode11(bytes(icon(t).flatten()), W, H) for t in ICONS]


if __name__ == '__main__':
    ap = argparse.ArgumentParser(); ap.add_argument('--preview'); a = ap.parse_args()
    print([len(s) for s in streams()], 'bytes')
    if a.preview:
        pal = {0: (40, 40, 40), 7: (10, 10, 10), 10: (255, 255, 255), 11: (210, 210, 210), 12: (150, 150, 150)}
        sheet = Image.new('RGB', (W * 2 + 10, H), (40, 40, 40))
        for k, t in enumerate(ICONS):
            rgb = Image.new('RGB', (W, H)); rgb.putdata([pal[int(v)] for v in icon(t).flatten()])
            sheet.paste(rgb, (k * (W + 10), 0))
        sheet.resize((sheet.width * 6, H * 6), Image.NEAREST).save(a.preview)
