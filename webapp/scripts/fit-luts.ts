// Fit OM-3 look settings to film-emulation 3D LUTs (developer tool; the LUTs themselves are never stored here).
//   npx vite-node scripts/fit-luts.ts DIR OUT.json [id ...]
// DIR holds src.bin (sample pixels, u8 RGB: the sample photos + synthetic colours + a grey ramp) and tgt/<id>.bin (each
// LUT's output for them), made by a small Python prep step. For each LUT, the look's integer settings (Hue / Light /
// Saturation per sector, Highlights / Shadows / Midtones, Blacks / Whites, Contrast, WB A-B / G-M) are found by
// coordinate descent on the mean CIE ΔE76 between the preview model (src/preview.ts, OM-3 mode) and the LUT.
import { readFileSync, writeFileSync } from 'node:fs';
import { join } from 'node:path';
import { blankLook, type Look } from '../src/pack';
import { renderLook } from '../src/preview';

const [DIR, OUT, ...only] = process.argv.slice(2);
const list = JSON.parse(readFileSync(join(DIR, 'list.json'), 'utf8')) as { n: number; natural: number; items: string[] };
const srcAll = new Uint8Array(readFileSync(join(DIR, 'src.bin')));
// subsample: every 4th natural pixel, all synthetic colours and the grey ramp
const pick: number[] = [];
for (let i = 0; i < list.n; i++) if (i >= list.natural || i % 4 === 0) pick.push(i);
const N = pick.length;
const img = (n: number) => ({ data: new Uint8ClampedArray(n * 4), width: n, height: 1 }) as unknown as ImageData;
const src = img(N);
pick.forEach((j, i) => { src.data[i * 4] = srcAll[j * 3]; src.data[i * 4 + 1] = srcAll[j * 3 + 1]; src.data[i * 4 + 2] = srcAll[j * 3 + 2]; src.data[i * 4 + 3] = 255; });

const lin = (v: number) => { const x = v / 255; return x <= 0.04045 ? x / 12.92 : ((x + 0.055) / 1.055) ** 2.4; };
const LIN = Float64Array.from({ length: 256 }, (_, i) => lin(i));
const f = (t: number) => (t > 216 / 24389 ? Math.cbrt(t) : (t * 24389 / 27 + 16) / 116);
function lab(d: Uint8ClampedArray | Uint8Array, i: number, stride: number): [number, number, number] {
  const r = LIN[d[i * stride]], g = LIN[d[i * stride + 1]], b = LIN[d[i * stride + 2]];
  const X = (0.4124 * r + 0.3576 * g + 0.1805 * b) / 0.95047, Y = 0.2126 * r + 0.7152 * g + 0.0722 * b, Z = (0.0193 * r + 0.1192 * g + 0.9505 * b) / 1.08883;
  const fx = f(X), fy = f(Y), fz = f(Z);
  return [116 * fy - 16, 500 * (fx - fy), 200 * (fy - fz)];
}
type P = { key: string; get: (l: Look) => number; set: (l: Look, v: number) => void; lim: number; w: number };
const params: P[] = [];
for (const arr of ['hue', 'light', 'sat'] as const) for (let i = 0; i < 12; i++)
  params.push({ key: `${arr}${i}`, get: (l) => l[arr][i], set: (l, v) => { l[arr][i] = v; }, lim: 5, w: 0.015 });
for (const k of ['highlights', 'shadows', 'midtones'] as const) params.push({ key: k, get: (l) => l.tone[k], set: (l, v) => { l.tone[k] = v; }, lim: 7, w: 0.01 });
for (const k of ['blacks', 'whites'] as const) params.push({ key: k, get: (l) => l.tone[k], set: (l, v) => { l.tone[k] = v; }, lim: 5, w: 0.01 });
params.push({ key: 'contrast', get: (l) => l.advice.contrast ?? 0, set: (l, v) => { l.advice.contrast = v; }, lim: 2, w: 0.05 });
params.push({ key: 'ab', get: (l) => l.wb?.a_b ?? 0, set: (l, v) => { l.wb = { a_b: v, g_m: l.wb?.g_m ?? 0 }; }, lim: 5, w: 0.015 });
params.push({ key: 'gm', get: (l) => l.wb?.g_m ?? 0, set: (l, v) => { l.wb = { a_b: l.wb?.a_b ?? 0, g_m: v }; }, lim: 5, w: 0.015 });

const out: Record<string, unknown>[] = [];
for (const id of list.items) {
  if (only.length && !only.some((o) => id.includes(o))) continue;
  const tAll = new Uint8Array(readFileSync(join(DIR, 'tgt', id.replace('/', '__') + '.bin')));
  const tLab = pick.map((j) => lab(tAll, j, 3));
  const dst = img(N);
  const loss = (l: Look) => {
    renderLook(src, dst, l, { advice: true, camera: 'om3' });
    let s = 0;
    for (let i = 0; i < N; i++) { const a = lab(dst.data, i, 4), b = tLab[i]; s += Math.hypot(a[0] - b[0], a[1] - b[1], a[2] - b[2]); }
    return s / N;
  };
  // small values are preferred: each setting costs w * v^2 ΔE, so a setting only moves when it clearly helps
  // (keeps the fit from leaning on extreme Light values, which the model knows least well)
  const cost = (l: Look) => loss(l) + params.reduce((a, p) => a + p.w * p.get(l) ** 2, 0);
  const look = blankLook('colour', 'fit');
  look.advice = { contrast: 0 };
  const before = loss(look);
  let best = cost(look);
  for (let pass = 0; pass < 12; pass++) {
    let improved = false;
    for (const p of params) {
      const v0 = p.get(look);
      for (const step of [1, -1, 2, -2]) {
        const v = v0 + step;
        if (Math.abs(v) > p.lim) continue;
        p.set(look, v);
        const e = cost(look);
        if (e < best - 1e-4) { best = e; improved = true; break; }
        p.set(look, v0);
      }
    }
    if (!improved) break;
  }
  if (look.wb && !look.wb.a_b && !look.wb.g_m) look.wb = null;
  const after = loss(look);
  out.push({ id, before: +before.toFixed(2), after: +after.toFixed(2), hue: look.hue, light: look.light, sat: look.sat, tone: look.tone, contrast: look.advice.contrast ?? 0, wb: look.wb });
  console.log(`${id.padEnd(48)} ΔE ${before.toFixed(2)} -> ${after.toFixed(2)}`);
  writeFileSync(OUT, JSON.stringify(out, null, 1));
}
