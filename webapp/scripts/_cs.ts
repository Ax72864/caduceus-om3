import { readFileSync, writeFileSync } from 'node:fs';
import films from '../src/data/om3films.json';
import { renderLook } from '../src/preview';
import { blankLook } from '../src/pack';
const D = '/tmp/claude-0/-home-claude/b7be4900-e88b-5a00-8626-c1de18df64bc/scratchpad/cs/';
const meta = JSON.parse(readFileSync(D + 'meta.json', 'utf8')) as [string, number, number][];
const imgs = meta.map(([p, w, h]) => ({ data: new Uint8ClampedArray(readFileSync(D + p + '.rgba')), width: w, height: h }) as unknown as ImageData);
const list = [{ name: 'Original', group: '-', l: null }, ...(films as any).films.map((f: any) => ({ name: f.name, group: f.group, l: f }))];
const bufs: Buffer[] = [];
for (const f of list) for (const im of imgs) {
  const out = { data: new Uint8ClampedArray(im.data.length), width: im.width, height: im.height } as unknown as ImageData;
  if (!f.l) out.data.set(im.data); else {
    const l = blankLook('colour', f.name); l.hue = f.l.hue; l.light = f.l.light; l.sat = f.l.sat; l.tone = f.l.tone; l.advice = { contrast: f.l.contrast, sharpness: 0 }; l.wb = f.l.wb;
    renderLook(im, out, l, { advice: true, camera: 'om3' });
  }
  bufs.push(Buffer.from(out.data.buffer));
}
writeFileSync(D + 'out.rgba', Buffer.concat(bufs)); writeFileSync(D + 'names.json', JSON.stringify(list.map((f) => [f.name, f.group])));
