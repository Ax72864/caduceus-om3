"""Build 'Hue [INFO]' / 'Light [INFO]' guide bitmaps (175x50, palette like stock 'Color All [INFO]' 0xa49ecdf8):
INFO box copied pixel-for-pixel from stock; the word drawn with a narrow bold font, fill 10, outline 7, soft edges 9."""
import sys, json, struct
sys.path.insert(0, '/home/claude/om3/osd')
from osd11 import decode11, encode11, rd
from PIL import Image, ImageDraw, ImageFont, ImageFilter
import numpy as np
W, H = 175, 50
d = rd(0xa49ecdf8, 24); size, p = struct.unpack_from('<2I', d, 12)
stock = np.frombuffer(decode11(rd(p, size), W, H), dtype=np.uint8).reshape(H, W)
cols = np.nonzero(stock.any(axis=0))[0]
# the INFO box: rightmost run of non-empty columns
box_x0 = max(c for c in range(W) if stock[:, c].any() and not stock[:, c - 1].any()) if True else 0
rows = np.nonzero(stock[:, :box_x0].any(axis=1))[0]
text_top, text_bot = rows.min(), rows.max()          # stock word extent (with outline)
SQ = float(sys.argv[2]) if len(sys.argv) > 2 else 0.82
FONT = sys.argv[1] if len(sys.argv) > 1 else '/usr/share/fonts/truetype/liberation/LiberationSansNarrow-Bold.ttf'
def word(txt):
    target = text_bot - text_top + 1 - 4              # glyph ink height inside the 2-px outline
    for fs in range(10, 80):
        f = ImageFont.truetype(FONT, fs)
        im = Image.new('L', (400, 100), 0); ImageDraw.Draw(im).text((10, 10), 'ClH', font=f, fill=255)
        a = np.array(im); r = np.nonzero(a.max(axis=1) > 128)[0]
        if r.max() - r.min() + 1 >= target: break
    im = Image.new('L', (400, 100), 0); ImageDraw.Draw(im).text((10, 10), txt, font=f, fill=255)
    a = np.array(im).astype(int)
    ys, xs = np.nonzero(a > 40); a = a[ys.min():ys.max() + 1, xs.min():xs.max() + 1]
    sq = Image.fromarray(a.astype(np.uint8)).resize((max(1, int(a.shape[1] * SQ)), a.shape[0]), Image.LANCZOS)
    a = np.array(sq).astype(int)
    fill = a > 150
    soft = (a > 40) & ~fill
    m = Image.fromarray((fill | soft).astype(np.uint8) * 255)
    o1 = np.array(m.filter(ImageFilter.MaxFilter(5))) > 0      # 2-px outline
    o2 = np.array(m.filter(ImageFilter.MaxFilter(7))) > 0      # soft rim
    out = np.zeros(a.shape[:1] and (a.shape[0] + 6, a.shape[1] + 6), dtype=np.uint8)
    def pad(x): return np.pad(x, 3)
    out[pad(o2)] = 9; out[pad(o1)] = 7; out[pad(soft)] = 11; out[pad(fill)] = 10
    return out
def build(txt):
    img = np.zeros((H, W), dtype=np.uint8)
    img[:, box_x0:] = stock[:, box_x0:]
    wd = word(txt); h, w = wd.shape
    y0 = text_top - 2 + (text_bot - text_top + 5 - h) // 2; x0 = max(0, (box_x0 - 4) - w)
    assert w <= box_x0 - 2, (txt, w, box_x0)
    img[y0:y0 + h, x0:x0 + w] = np.where(wd > 0, wd, img[y0:y0 + h, x0:x0 + w])
    return img
if __name__ == '__main__':
    out = {}
    pal = {0: (30, 30, 60), 7: (20, 20, 20), 8: (90, 90, 90), 9: (60, 60, 60), 10: (255, 255, 255), 11: (200, 200, 200), 12: (160, 160, 160)}
    sheet = Image.new('RGB', (W * 3 + 40, H * 3 * 3 + 40), (30, 30, 60))
    for k, (name, px) in enumerate([('stock', stock)] + [(t, build(t)) for t in ('Hue', 'Light')]):
        rgb = Image.new('RGB', (W, H)); rgb.putdata([pal.get(int(v), (255, 0, 255)) for v in px.flatten()])
        sheet.paste(rgb.resize((W * 3, H * 3), Image.NEAREST), (20, 20 + k * H * 3))
        if name != 'stock':
            enc = encode11(bytes(px.flatten()), W, H)
            assert decode11(enc, W, H) == bytes(px.flatten())
            out[name] = enc.hex()
    sheet.save('guide_preview.png')
    json.dump(out, open('guide_new.json', 'w'))
    print('box_x0', box_x0, 'text rows', text_top, text_bot, {k: len(v) // 2 for k, v in out.items()})
