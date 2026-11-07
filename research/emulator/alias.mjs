const [EMU, IMAGE, CARD] = process.argv.slice(2);
const fs = await import('node:fs'); const { createHash } = await import('node:crypto'); const zlib = await import('node:zlib');
const { expandImage } = await import(EMU + '/src/fw/expand.mjs'); const { loadBlock } = await import(EMU + '/bin/run.mjs');
const { Player } = await import(EMU + '/src/lab/player.mjs'); const { PLAYER_PARSER } = await import(EMU + '/scenarios/session_replay.mjs');
const { cardFromImage } = await import(EMU + '/src/lab/sdcard.mjs');
let c0 = cardFromImage(new Uint8Array(fs.readFileSync(CARD))); const card = { open: () => c0, save: (x) => { c0 = x; } };
const rom = expandImage(new Uint8Array(fs.readFileSync(IMAGE)));
const pl = new Player({ ...PLAYER_PARSER, no_browser: true, idle: 'off', a15: 'on', out: '<out>', no_wait_on_error: true, device: 'tft' },
  { rom, resBlock: loadBlock(), createHash, card, deflate: (b, l) => new Uint8Array(zlib.deflateSync(b, { level: l })), inflate: (b) => new Uint8Array(zlib.inflateSync(b)), wallClock: () => performance.now() / 1000 });
pl.open_session(); const lab = pl.session.lab;
const hx = (a, n = 8) => Buffer.from(lab.sim.read(a, n)).toString('hex');
console.log('pre-boot 0x60f49800', hx(0x60f49800), 'section6 start', hx(0x60adc000), 'section0', hx(0x60021020));
lab.sim.write(0x60f49800, Uint8Array.of(1, 2, 3, 4)); console.log('alias 0xa0f49800 after write at 0x60..:', hx(0xa0f49800, 4));
lab.sim.write(0xa0acfc08, Uint8Array.of(9, 9, 9, 9)); console.log('0x60acfc08 after write at 0xa0..:', hx(0x60acfc08, 4));
pl.session.idle_slice(lab.lab_time() + 2500e6);
console.log('post-boot 0x60acfc00', hx(0x60acfc00, 32), '0x618000e0', hx(0x618000e0, 16), '0xa08218f0', hx(0xa08218f0, 16));
console.log('section6 start after boot', hx(0x60adc000), 'gap s6', hx(0x60f49800, 4));
