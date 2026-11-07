"""Like lut-prep.py, but for Lightroom presets (.xmp): an approximate Lightroom renderer makes each preset's output for
the sample pixels, for scripts/fit-luts.ts. It covers the colour parts of a preset (HSL, colour grading / split
toning, Point Color, the point tone curves); local effects (Clarity, Texture, Dehaze, grain, sharpening) have no
OM-3 equivalent and are left out. Lightroom's exact maths isn't public, so this is a model, not a match: fits made
from it are a guide to the preset's colour, not a copy. The presets are only read; nothing of them is stored.
usage: python3 scripts/lr-prep.py XMP_DIR SRC_BIN OUT_DIR   (SRC_BIN: lut-prep.py's src.bin, so both fits share pixels)"""
import json, os, re, sys, numpy as np

XMP, SRC, OUTD = sys.argv[1], sys.argv[2], sys.argv[3]

def parse(path):
    t = open(path, encoding='utf-8').read()
    a = {k: float(v) for k, v in re.findall(r'crs:(\w+)="([-+]?[0-9.]+)"', t)}
    seq = lambda tag: (re.findall(r'<rdf:li>(.*?)</rdf:li>', m.group(1)) if (m := re.search(
        r'<crs:%s>\s*<rdf:Seq>(.*?)</rdf:Seq>' % tag, t, re.S)) else [])
    curve = lambda tag: [tuple(map(float, p.split(','))) for p in seq(tag)] or [(0, 0), (255, 255)]
    pts = [list(map(float, p.split(','))) for p in seq('PointColors')]
    return a, {c: curve('ToneCurvePV2012' + c) for c in ('', 'Red', 'Green', 'Blue')}, [p for p in pts if p[0] >= 0]

# --- colour spaces (sRGB D65 <-> CIELab) ---
def lin(x): return np.where(x <= 0.04045, x / 12.92, ((x + 0.055) / 1.055) ** 2.4)
def gam(x): x = np.clip(x, 0, 1); return np.where(x <= 0.0031308, x * 12.92, 1.055 * x ** (1 / 2.4) - 0.055)
M = np.array([[0.4124, 0.3576, 0.1805], [0.2126, 0.7152, 0.0722], [0.0193, 0.1192, 0.9505]]); MI = np.linalg.inv(M)
W = np.array([0.95047, 1.0, 1.08883])
def f(t): return np.where(t > 216 / 24389, np.cbrt(t), (t * 24389 / 27 + 16) / 116)
def fi(t): return np.where(t ** 3 > 216 / 24389, t ** 3, (116 * t - 16) * 27 / 24389)
def to_lab(rgb):
    xyz = lin(rgb) @ M.T / W; fx, fy, fz = f(xyz[:, 0]), f(xyz[:, 1]), f(xyz[:, 2])
    return np.stack([116 * fy - 16, 500 * (fx - fy), 200 * (fy - fz)], 1)
def from_lab(lab):
    fy = (lab[:, 0] + 16) / 116; fx = fy + lab[:, 1] / 500; fz = fy - lab[:, 2] / 200
    return gam(np.stack([fi(fx), fi(fy), fi(fz)], 1) * W @ MI.T)
def hsv_hue(rgb):
    mx, mn = rgb.max(1), rgb.min(1); d = np.where(mx - mn < 1e-9, 1e-9, mx - mn); r, g, b = rgb.T
    h = np.where(mx == r, (g - b) / d % 6, np.where(mx == g, (b - r) / d + 2, (r - g) / d + 4)) * 60
    return h % 360
def hue_dir(h_deg):
    """Lab a/b unit direction of a fully saturated colour of HSV hue h."""
    c = np.array([[*__import__('colorsys').hsv_to_rgb(h_deg / 360, 1, 1)]]); ab = to_lab(c)[0, 1:]
    return ab / np.hypot(*ab)

# --- HSL panel: 8 bands with Lightroom's centres; weights are triangles between neighbouring centres ---
BANDS = ['Red', 'Orange', 'Yellow', 'Green', 'Aqua', 'Blue', 'Purple', 'Magenta']
CENT = np.array([0, 30, 60, 120, 180, 240, 270, 300.0])
def band_weights(h):
    w = np.zeros((len(h), 8))
    for i in range(8):
        lo, c, hi = CENT[i - 1] - (360 if i == 0 else 0), CENT[i], CENT[(i + 1) % 8] + (360 if i == 7 else 0)
        d = (h - c + 180) % 360 - 180
        w[:, i] = np.where(d < 0, np.clip(1 + d / (c - lo), 0, 1), np.clip(1 - d / (hi - c), 0, 1))
    return w / w.sum(1, keepdims=True)
GAP_UP = np.array([(CENT[(i + 1) % 8] - CENT[i]) % 360 for i in range(8)]); GAP_DN = np.roll(GAP_UP, 1)

def render(rgb, a, curves, points):
    lab = to_lab(rgb); L, A, B = lab.T.copy(); C = np.hypot(A, B); H = np.arctan2(B, A)
    gate = np.clip(C / 20, 0, 1)                      # HSL leaves greys alone
    w = band_weights(hsv_hue(rgb))
    hv = np.array([a.get('HueAdjustment' + b, 0) for b in BANDS]) / 100
    sv = np.array([a.get('SaturationAdjustment' + b, 0) for b in BANDS]) / 100
    lv = np.array([a.get('LuminanceAdjustment' + b, 0) for b in BANDS]) / 100
    dh = w @ (hv * np.where(hv > 0, GAP_UP, GAP_DN) * 0.6)    # ±100 moves about 60% of the way to the next band
    H = H + np.radians(dh) * gate
    C = C * np.clip(1 + w @ sv, 0, None)
    L = L + (w @ lv) * 25 * gate * np.clip(C / 45, 0, 1)
    # Point Color: [src hue (rad), src sat, src lum (linear), hue shift, sat shift, lum shift, range, hue/sat/lum ranges]
    if points:
        sat = np.clip(C / 100, 0, 1); lum = fi((L + 16) / 116)
        for p in points:
            sh, ss, sl, dh_, ds, dl, amt = p[:7]; rg = [p[7:11], p[11:15], p[15:19]]
            def win(x, r, span):   # x: distance from the source (signed), mapped to 0..1 around 0.5
                u = np.clip(0.5 + x / (2 * span), 0, 1); r0, r1, r2, r3 = r
                return np.clip(np.minimum((u - r0) / max(r1 - r0, 1e-3), (r3 - u) / max(r3 - r2, 1e-3)), 0, 1)
            hd = (H - sh + np.pi) % (2 * np.pi) - np.pi
            sel = win(hd, rg[0], np.radians(45) * (0.5 + amt)) * win(sat - ss, rg[1], 0.5) * win(lum - sl, rg[2], 0.5)
            H = H + sel * dh_ * 1.0; C = C * (1 + sel * ds); L = L + sel * dl * 30
    A, B = C * np.cos(H), C * np.sin(H)
    # colour grading (split toning = the shadow / highlight wheels)
    t = np.clip(L / 100, 0, 1); bal = a.get('SplitToningBalance', 0) / 100
    t = np.clip(t - bal * 0.25, 0, 1)
    masks = {'Shadow': (1 - t) ** 2, 'Highlight': t ** 2, 'Midtone': 2 * t * (1 - t)}
    for zone, m in masks.items():
        hue = a.get('SplitToning%sHue' % zone, a.get('ColorGrade%sHue' % zone, 0))
        s = a.get('SplitToning%sSaturation' % zone, a.get('ColorGrade%sSat' % zone, 0)) / 100
        if s: u = hue_dir(hue); A = A + m * s * 20 * u[0]; B = B + m * s * 20 * u[1]
    out = from_lab(np.stack([L, A, B], 1))
    # point curves, in sRGB: master, then per channel (Lightroom's curves are splines; PCHIP keeps them monotone)
    def apply_curve(x, pts):
        if pts == [(0, 0), (255, 255)]: return x
        xs, ys = np.array(pts).T / 255; x = np.clip(x, xs[0], xs[-1])
        if len(xs) == 2: return np.interp(x, xs, ys)
        hk = np.diff(xs); dk = np.diff(ys) / hk; m = np.zeros(len(xs))   # Fritsch-Carlson monotone cubic (PCHIP)
        for i in range(1, len(xs) - 1):
            if dk[i - 1] * dk[i] > 0:
                w1, w2 = 2 * hk[i] + hk[i - 1], hk[i] + 2 * hk[i - 1]; m[i] = (w1 + w2) / (w1 / dk[i - 1] + w2 / dk[i])
        m[0], m[-1] = dk[0], dk[-1]
        i = np.clip(np.searchsorted(xs, x) - 1, 0, len(xs) - 2); t = (x - xs[i]) / hk[i]
        return np.clip((2 * t**3 - 3 * t**2 + 1) * ys[i] + (t**3 - 2 * t**2 + t) * hk[i] * m[i]
                       + (-2 * t**3 + 3 * t**2) * ys[i + 1] + (t**3 - t**2) * hk[i] * m[i + 1], 0, 1)
    out = apply_curve(out, curves[''])
    for i, c in enumerate(('Red', 'Green', 'Blue')): out[:, i] = apply_curve(out[:, i], curves[c])
    return np.clip(out, 0, 1)

src = np.fromfile(SRC, np.uint8).reshape(-1, 3); rgb = src.astype(float) / 255
os.makedirs(os.path.join(OUTD, 'tgt'), exist_ok=True); src.tofile(os.path.join(OUTD, 'src.bin'))
lj = json.load(open(os.path.join(os.path.dirname(os.path.abspath(SRC)), 'list.json')))
items = []
for fn in sorted(os.listdir(XMP)):
    if not fn.endswith('.xmp'): continue
    idn = 'parvec/' + re.sub(r'\W+', '_', fn[:-4].replace(' parvec', '')).strip('_')
    out = render(rgb, *parse(os.path.join(XMP, fn)))
    (out * 255 + 0.5).astype(np.uint8).tofile(os.path.join(OUTD, 'tgt', idn.replace('/', '__') + '.bin'))
    d = np.abs(to_lab(out) - to_lab(rgb)); items.append(idn); print(idn, 'mean |ΔLab| from source', d.mean(0).round(2))
json.dump({'n': len(src), 'natural': lj['natural'], 'items': items}, open(os.path.join(OUTD, 'list.json'), 'w'), indent=1)
