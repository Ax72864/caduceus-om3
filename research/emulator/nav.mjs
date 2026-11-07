// OM-3 UI walk in an om-emu E147 play session (our script). A PNG after each step.
//   OM_EMU_MODEL=E147 node nav.mjs EMU_DIR OUT_DIR 'ok down right main+1 info ...' [IMAGE]
// tokens: a control id (key click: down, 150 ms, up), main+N / main-N / sub+N / sub-N (dial detents), wait (1 s),
//         mode:N (mode dial position index)
const [EMU, OUT, SCRIPT, IMAGE] = process.argv.slice(2);
const fs = await import('node:fs');
const { createHash } = await import('node:crypto');
const zlib = await import('node:zlib');
const { expandImage } = await import(EMU + '/src/fw/expand.mjs');
const { loadImage, loadBlock } = await import(EMU + '/bin/run.mjs');
const { Player } = await import(EMU + '/src/lab/player.mjs');
const { PLAYER_PARSER } = await import(EMU + '/scenarios/session_replay.mjs');
const { memoryCard } = await import(EMU + '/src/lab/sdcard.mjs');
const { pngRaw } = await import(EMU + '/host/server.mjs');
fs.mkdirSync(OUT, { recursive: true });
const rom = IMAGE ? expandImage(new Uint8Array(fs.readFileSync(IMAGE))) : loadImage();
const env = { rom, resBlock: loadBlock(), createHash, card: memoryCard({}),
  deflate: (b, l) => new Uint8Array(zlib.deflateSync(b, { level: l })), inflate: (b) => new Uint8Array(zlib.inflateSync(b)) };
const pl = new Player({ ...PLAYER_PARSER, no_browser: true, idle: 'off', a15: 'on', out: '<out>', no_wait_on_error: true, device: 'tft' },
  { ...env, wallClock: () => performance.now() / 1000 });
pl.open_session();
const s = pl.session, lab = s.lab;
let n = 0;
const shot = (tag) => {
  const f = `${OUT}/${String(n++).padStart(2, '0')}-${tag.replace(/[^a-z0-9+_-]/gi, '_')}.png`;
  let note = '';
  try { const [w, h, raw] = s.frame('boundary', true); fs.writeFileSync(f, pngRaw(w, h, raw)); }
  catch (e) { note = 'strict frame failed: ' + e.message.split('\n')[0].slice(0, 80);
    try { const [w, h, raw] = s.frame('boundary', false); fs.writeFileSync(f, pngRaw(w, h, raw)); note += ' | saved non-strict'; }
    catch (e2) { note += ' | non-strict failed: ' + e2.message.split('\n')[0].slice(0, 60); } }
  console.log(f, 'gui', '0x' + lab.state().toString(16), lab.state_names.get(lab.state()) ?? '?', note);
};
s.idle_slice(lab.lab_time() + 1500e6); shot('start');
for (const t of SCRIPT.split(/\s+/).filter(Boolean)) {
  const m = /^(main|sub)([+-]\d+)$/.exec(t);
  if (m) { s.dial_input(m[1], parseInt(m[2], 10)); s.camapp.pump(); }
  else if (t === 'wait') { /* idle only */ }
  else if (t.startsWith('mode:')) { s.switch_input('mode_dial', parseInt(t.slice(5), 10)); s.camapp.pump(); }
  else { s.key(t, 'down'); s.camapp.pump(); s.idle_slice(lab.lab_time() + 150e6); s.key(t, 'up'); s.camapp.pump(); }
  s.idle_slice(lab.lab_time() + 1000e6); shot(t);
}
