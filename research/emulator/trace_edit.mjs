// Trace the OM-3 Color Profile wheel editor in an om-emu E147 session (our script).
//   OM_EMU_MODEL=E147 node trace_edit.mjs EMU_DIR OUT.json 'nav tokens to the editor' 'edit tokens' [watch pcs comma-sep]
// 1) navigate; 2) baseline: trace all PCs while idling 1.3 s; 3) trace all PCs during the edit tokens;
// 4) report PCs (and their hit counts) seen only in the edit, plus register snapshots at the watch PCs.
const [EMU, OUT, NAV, EDIT, WATCH] = process.argv.slice(2);
const fs = await import('node:fs');
const { createHash } = await import('node:crypto');
const zlib = await import('node:zlib');
const { loadImage, loadBlock } = await import(EMU + '/bin/run.mjs');
const { Player } = await import(EMU + '/src/lab/player.mjs');
const { PLAYER_PARSER } = await import(EMU + '/scenarios/session_replay.mjs');
const { memoryCard } = await import(EMU + '/src/lab/sdcard.mjs');
const { Debugger } = await import(EMU + '/src/debug/debugger.mjs');
const env = { rom: loadImage(), resBlock: loadBlock(), createHash, card: memoryCard({}),
  deflate: (b, l) => new Uint8Array(zlib.deflateSync(b, { level: l })), inflate: (b) => new Uint8Array(zlib.inflateSync(b)) };
const pl = new Player({ ...PLAYER_PARSER, no_browser: true, idle: 'off', a15: 'on', out: '<out>', no_wait_on_error: true, device: 'tft' },
  { ...env, wallClock: () => performance.now() / 1000 });
pl.open_session();
const s = pl.session, lab = s.lab;
const step = (t) => {
  const m = /^(main|sub)([+-]\d+)$/.exec(t);
  if (m) { s.dial_input(m[1], parseInt(m[2], 10)); s.camapp.pump(); }
  else if (t !== 'wait') { s.key(t, 'down'); s.camapp.pump(); s.idle_slice(lab.lab_time() + 150e6); s.key(t, 'up'); s.camapp.pump(); }
  s.idle_slice(lab.lab_time() + 1000e6);
};
s.idle_slice(lab.lab_time() + 1500e6);
for (const t of NAV.split(/\s+/).filter(Boolean)) step(t);
const dbg = Debugger.attach(lab.sim, { lab });
const watch = new Set((WATCH || '').split(',').filter(Boolean).map((x) => parseInt(x, 16) >>> 0));
const run = (tokens) => {
  const counts = new Map(), snaps = [];
  dbg.traceExec((r) => {
    counts.set(r.pc, (counts.get(r.pc) ?? 0) + 1);
    if (watch.has(r.pc) && snaps.length < (+process.env.SNAPS || 200)) { const g = dbg.regs(); const o = { pc: '0x' + r.pc.toString(16) }; for (const k of ['d0','d1','d2','d3','a0','a1','a2','a3','sp','mdr']) o[k] = '0x' + ((g[k] ?? 0) >>> 0).toString(16); { const b = lab.sim.read((g.sp >>> 0), 4); o.at_sp = '0x' + ((b[0] | b[1] << 8 | b[2] << 16 | b[3] << 24) >>> 0).toString(16); } snaps.push(o); }
  });
  if (tokens === null) s.idle_slice(lab.lab_time() + 1300e6); else for (const t of tokens) step(t);
  dbg.traceExec(null);
  return { counts, snaps };
};
const base = run(null);
const edit = run(EDIT.split(/\s+/).filter(Boolean));
const only = [...edit.counts.entries()].filter(([pc]) => !base.counts.has(pc)).sort((a, b) => a[0] - b[0]);
const res = { gui: lab.state(), gui_name: lab.state_names.get(lab.state()) ?? '?', base_pcs: base.counts.size, edit_pcs: edit.counts.size,
  only_in_edit: only.map(([pc, c]) => ['0x' + pc.toString(16), c]), watch_hits: edit.snaps, watch_hits_base: base.snaps.length };
fs.writeFileSync(OUT, JSON.stringify(res));
console.log(JSON.stringify({ gui: res.gui_name, base_pcs: res.base_pcs, edit_pcs: res.edit_pcs, only: only.length, watch: edit.snaps.slice(0, 12) }));
