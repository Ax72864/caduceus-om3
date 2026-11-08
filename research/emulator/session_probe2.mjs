// Probe-2 loader check in a full om-emu E147 play session (our script; om-emu APIs as bin/modelcheck.mjs uses them).
//   OM_EMU_MODEL=E147 node session_probe2.mjs EMU_DIR IMAGE CARD(blank|path.omsd) OUT.json [SAVE.omsd]
// Starts the session, reads STATE before and after an S1 half-press (and a second S1), then S2 and PLAY;
// dumps the published heap block. The card is a blank 8 GiB SDHC (formatted by the firmware) or a saved OMSD image.
const [EMU, IMAGE, CARD, OUT, SAVE] = process.argv.slice(2);
const fs = await import('node:fs');
const { createHash } = await import('node:crypto');
const zlib = await import('node:zlib');
const { expandImage } = await import(EMU + '/src/fw/expand.mjs');
const { loadBlock } = await import(EMU + '/bin/run.mjs');
const { Player } = await import(EMU + '/src/lab/player.mjs');
const { PLAYER_PARSER } = await import(EMU + '/scenarios/session_replay.mjs');
const { memoryCard, cardFromImage, cardImage } = await import(EMU + '/src/lab/sdcard.mjs');
const STATE = 0x62b4dd16, POOL = 0xa2852000, HMAX = 0xae81;
let card = CARD === 'blank' ? memoryCard({}) : (() => { let c = cardFromImage(new Uint8Array(fs.readFileSync(CARD))); return { open: () => c, save: (x) => { c = x; } }; })();
const rom = expandImage(new Uint8Array(fs.readFileSync(IMAGE)));
const env = { rom, resBlock: loadBlock(), createHash, card,
  deflate: (b, l) => new Uint8Array(zlib.deflateSync(b, { level: l })), inflate: (b) => new Uint8Array(zlib.inflateSync(b)) };
const pl = new Player({ ...PLAYER_PARSER, no_browser: true, idle: 'off', a15: 'on', out: '<out>', no_wait_on_error: true, device: 'tft' },
  { ...env, wallClock: () => performance.now() / 1000 });
pl.open_session();
const s = pl.session, lab = s.lab, log = [];
const u16 = (a) => { const b = lab.sim.read(a, 2); return b[0] | b[1] << 8; };
const hex = (b) => Buffer.from(b).toString('hex');
const snap = (k) => {
  const st = u16(STATE), e = { step: k, state: st, gui: lab.state(), mounted: s.storage ? s.storage.mounted : null };
  if (st >= 1 && st - 1 < HMAX && ((st - 1) & 3) === 0) e.block = hex(lab.sim.read(POOL + st - 1, 544));
  e.neighbours = hex(lab.sim.read(STATE - 2, 8));
  const u32 = (a) => { const b = lab.sim.read(a, 4); return (b[0] | b[1] << 8 | b[2] << 16 | b[3] << 24) >>> 0; };
  e.secbits = u32(0xa32de590).toString(16); e.hls_tid = u16(0x62b4dd14); e.ms = [0x603692f8, 0x60369300, 0x60369308].map((a) => u32(a).toString(16));
  log.push(e);
};
s.idle_slice(lab.lab_time() + 1500e6); snap('start');
// emulator gaps (see report): the boot section loader (flat image) and the app media manager's mount word are stood in.
// Set them as the camera sets them: section bits 0..9 (0x60045ed5) and one medium MOUNT OK (0x60bf441d -> 0x60b00031).
if (process.env.FIX_GATE === '1') { lab.sim.write(0xa32de590, new Uint8Array([0xff, 0x03, 0, 0])); lab.sim.write(0x60369308, new Uint8Array([0x00, 0xf0, 0, 0])); snap('gate-fixed'); }
for (const k of ['s1', 's1', 's2', 'play', 'play']) {
  s.key(k, 'down'); s.camapp.pump(); s.idle_slice(lab.lab_time() + 150e6); s.key(k, 'up'); s.camapp.pump();
  s.idle_slice(lab.lab_time() + 1200e6); snap(k);
}
const st = s.storage;
const res = { log, card: st ? { kind: st.card.kind, mounted: st.mounted, formatted: st.formatted, files: st.files.length } : null };
if (SAVE && st) fs.writeFileSync(SAVE, cardImage(st.card));
fs.writeFileSync(OUT, JSON.stringify(res, null, 1));
console.log(JSON.stringify({ steps: log.map((e) => [e.step, e.state, e.gui, e.mounted, e.secbits, e.hls_tid, e.ms.join('/'), e.block ? e.block.slice(0, 16) + '..' : null]), card: res.card }));
