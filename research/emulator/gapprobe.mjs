// Gap probe: fill the RAM between the main image's loaded sections with a sentinel before boot, run a session,
// then report which bytes were ever written (anything not equal to the sentinel).
//   OM_EMU_MODEL=E147 node gapprobe.mjs EMU_DIR IMAGE CARD.omsd 'tokens...' OUT.json
const [EMU, IMAGE, CARD, SCRIPT, OUT] = process.argv.slice(2);
const fs = await import('node:fs');
const { createHash } = await import('node:crypto');
const zlib = await import('node:zlib');
const { expandImage } = await import(EMU + '/src/fw/expand.mjs');
const { loadBlock } = await import(EMU + '/bin/run.mjs');
const { Player } = await import(EMU + '/src/lab/player.mjs');
const { PLAYER_PARSER } = await import(EMU + '/scenarios/session_replay.mjs');
const { cardFromImage } = await import(EMU + '/src/lab/sdcard.mjs');
let c0 = cardFromImage(new Uint8Array(fs.readFileSync(CARD)));
const card = { open: () => c0, save: (x) => { c0 = x; } };
const rom = expandImage(new Uint8Array(fs.readFileSync(IMAGE)));
const env = { rom, resBlock: loadBlock(), createHash, card,
  deflate: (b, l) => new Uint8Array(zlib.deflateSync(b, { level: l })), inflate: (b) => new Uint8Array(zlib.inflateSync(b)) };
const pl = new Player({ ...PLAYER_PARSER, no_browser: true, idle: 'off', a15: 'on', out: '<out>', no_wait_on_error: true, device: 'tft' },
  { ...env, wallClock: () => performance.now() / 1000 });
pl.open_session();
const s = pl.session, lab = s.lab;
const GAPS = { s2: [0x60718800, 0x6075a800], s3: [0x60820000, 0x60828000], s4: [0x60a8f800, 0x60ad8000], s5: [0x60adb800, 0x60adc000],
  s6: [0x60f49800, 0x6103f000], s7: [0x6164b000, 0x6169e800], s8: [0x617e4800, 0x61809000], s9: [0x619a9800, 0x619fd000],
  s10a: [0x61aa4800, 0x61aad000], s10b: [0x61aade00, 0x62020000] };
const SENT = 0xa5;
const before = {};
for (const [k, [lo, hi]] of Object.entries(GAPS)) {
  before[k] = Buffer.from(lab.sim.read(lo, hi - lo)).toString('hex').slice(0, 32);
  for (let a = lo; a < hi; a += 0x10000) lab.sim.write(a, new Uint8Array(Math.min(0x10000, hi - a)).fill(SENT));
}
s.idle_slice(lab.lab_time() + 2500e6);
for (const t of SCRIPT.split(/\s+/).filter(Boolean)) {
  const m = /^(main|sub)([+-]\d+)$/.exec(t);
  if (m) { s.dial_input(m[1], parseInt(m[2], 10)); s.camapp.pump(); }
  else if (t.startsWith('hold:')) { const k = t.slice(5); s.key(k, 'down'); s.camapp.pump(); s.idle_slice(lab.lab_time() + 2000e6); s.key(k, 'up'); s.camapp.pump(); }
  else if (t !== 'wait') { s.key(t, 'down'); s.camapp.pump(); s.idle_slice(lab.lab_time() + 150e6); s.key(t, 'up'); s.camapp.pump(); }
  s.idle_slice(lab.lab_time() + 1500e6);
}
const out = { state: lab.state_names.get(lab.state()) ?? lab.state(), gaps: {} };
for (const [k, [lo, hi]] of Object.entries(GAPS)) {
  const b = lab.sim.read(lo, hi - lo);
  const runs = []; let st = -1, untouched = 0;
  for (let i = 0; i <= b.length; i++) {
    const w = i < b.length && b[i] !== SENT;
    if (i < b.length && !w) untouched++;
    if (w && st < 0) st = i;
    if (!w && st >= 0) { if (i - st >= 1) runs.push([st, i]); st = -1; }
  }
  // merge runs closer than 256 B
  const merged = [];
  for (const r of runs) { const l = merged[merged.length - 1]; if (l && r[0] - l[1] < 256) l[1] = r[1]; else merged.push([...r]); }
  out.gaps[k] = { lo: lo.toString(16), size: hi - lo, untouched, written: hi - lo - untouched, before: before[k],
    used: merged.slice(0, 40).map(([a, z]) => [(lo + a).toString(16), z - a]), nused: merged.length,
    lastWritten: merged.length ? (lo + merged[merged.length - 1][1]).toString(16) : null };
}
fs.writeFileSync(OUT, JSON.stringify(out, null, 1));
console.log(JSON.stringify(Object.fromEntries(Object.entries(out.gaps).map(([k, g]) => [k, `${g.size} B, written ${g.written}, untouched ${g.untouched}, ${g.nused} areas, last ${g.lastWritten}`])), null, 1));
console.log('state', out.state);
