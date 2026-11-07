# OM-3 1.1 (build 1100) firmware port — working notes

> The research lab notebook, kept as written during the work (2026-11-04 onward) and continued here from now on.
> Paths like `pp/…`, `osd/…`, `tools/…`, `port/…` and the tree names (`gz2`, `g21`, `gxt` …) were workspace folders:
> their sources now live under `research/` (see `research/README.md`). Newest sections are at the end.
> Status words matter: "camera" / "camera-tested" = seen on a real OM-3; "emulator" = om-emu only; anything else is
> analysis. Read the relevant section before changing that area of the firmware.

All addresses: OM-3 runtime (decoded main + 0x60021020). E-P7 1.1 base 0x60020020.
Stock: OLY_E_147_1100_0000_0000.BIN sha 8c133084…696d, main 5e8d376e…7d59.

## Proven on the camera
- SD update: DCOLYMP/E1479999.BIN, hold OK at power-on; steady ~2 min, then blink. Restore = official file.
- Hue/lightness: builder 0x60518381, single call 0x60518615 (call …,[d2,d3,a2,a3],96), resume 0x6051861a.
  Output records at output(=(12,a2))+836, stride 24; hue +18, sat +20, light +22. Record r = UI sector 2(r%6)+r/6.
  Hue raw = -1000*ui moves yellow->orange->red (toward the NEXT sector; opposite to Caduceus' sim convention).
- Live view uses the same builder call.
- Profile number: getter 0x60063380(d0=63153, d1=0, a0=0) ,[d2,d3],12 -> 1..4 = COLOR1..4.
- Spare state: u16 0x62b4dd16 (= HLS event-manager singleton 0x62b4dc68 +174), boot-cleared, unreferenced.
- Half-press hook: 0x60415216 call 0x60415343,[d2,d3,a2,a3],36 -> resume 0x6041521b.
- Probe 2 (camera-proven): gate (SECBITS 0xa32de590 == 0x3ff, get_tid 0x6003193e == HLS tid 0x62b4dd14,
  media word 0x603692f8/0x60369300/0x60369308 == 0xF000), malloc 0x60024068 (class 1 pool 0xa2852000..0xa285d280),
  fopen 0x608d4d22, fclose 0x608d4d2b, fseek 0x608d4fb1 (2 SET, 0 CUR, 1 END), ftell 0x608d4f47, fread 0x608d4eb7,
  free 0x6002409a. File C:\OM3MOD\BUNDLES.BIN = Caduceus format with magic 'OM3B', OM-3 sha prefix.
  STATE: 0 none, 0xFFFF attempted, h = buf-pool+1 (block 1024 B).
- Code space used: section-1 tail 0x6031e920..0x6031ebf0 (FF from 0x6031e910, end 0x6031f000);
  section-4 tail 0x60a8f100..0x60a8f7f0 (FF from 0x60a8f088, end 0x60a8f800). Section-2 tail 0x607187a8 (92 B).
  Sections load 1..10 in order (0x600455c5…), loader 0x60045ed5 sets bit (id-1) in 0xa32de590.

## Colour Profile editor (emulator traces, om-emu E147 play session)
- Reach: OK (SCP, Picture Mode "COLOR 1" selected) -> OK (picture-mode screen, COLOR1-4 tabs) -> DOWN
  ("Color Vivid" item = the wheel; emulator cannot compose its plane: PLANC_UNOBSERVED).
- COLOR1 sector setting IDs 928..939 (E-P7 927..938 + 1). Cursor setting 2197: 1..12 sector, 0xFF = ALL.
- Main dial = value step; sub dial / arrows = sector; INFO toggles ALL (cursor 0xFF). Delete: no setting change.
- Editor step handler (E-P7 Up/Down family): 0x61223ef7 receives event 0x9004 (step).
- GUI save path: facade table 0x60e57474 (OM-3 API ids = E-P7 - 1): [1] 0x60b8781f is the editor's SetValue
  (called with 928 and 2197); H1 site = 0x60b8798b `call 0x60bb528f,[d2,d3,a2,a3],68`
  (d0 id, d1 value ((24,sp)), a0 inner ((a2)), a1 mode ((28,sp)); after: cmp 1,d0 -> else a3 = 128).
  Settings manager 0x60bb528f (cmp 4508 special case, as E-P7 0x60827440).
- Facade table 0x60e57474 (56 words; refs 0x60b869d2/f2; singleton ptr (0x60369acc), getter `call 0x60b8696a,[],4` -> a0).
  OM-3 api ids = E-P7 ids, but the OM-3 table has one extra word at [1]: +4 SetValue 0x60b8781f (d0 id, d1 mode, a1 value),
  +12 GetValue 0x60b86de7 (d0 id, a1 out -> d0 0; word 0x60e57480), +28 count 0x60b86e09, +32 value-by-index 0x60b87031,
  +40 selectable 0x60b86a01, +156 GetDefault 0x60b86e44 (word 0x60e57510). (+8 0x60b87ae2 is not used by the editor.)
- Editor records (56 B, key +0): 0x615adcc4/cfc/d34/d6c = keys 0x1540..0x1543 = COLOR1..4. +4 init 0x6122393a,
  +8 child_get 0x61223acd, +12 Up 0x61223ef7, +16 Down 0x612241b6, +36 event 0x61225d52, +44 INFO 0x6122661b.
  Parent: +96 key, +122 cursor index (0 = ALL path in Up), +124 child[0] (cursor), +128.. children 1..12; parent+68.. =
  record+36..: router 0x61223ca6: 0x900c/63541 -> +72, INFO 0x9014 -> +76, 0x9015 -> +80, 0x9012 -> +84, else +68.
  Child: +80 setting id, +92 count. Child refresh `call 0x611b20ea,[d2,d3,a2,a3],68` (a0 child).
- Descriptor table 0x615ae61c.. {u16 key, u16 13, u32 list}: COLOR1 2197 + 928..939, COLOR2 2198 + 940..951,
  COLOR3 2199 + 952..963, COLOR4 2200 + 964..975. Cursor setting 255 = ALL (OM-3 has no ALL globals; INFO toggles it
  via SetValue(cursor, 0, 1|255)). Key -> cursor id table 0x615b3db4 (0x6122809f).
- Stock setting getter 0x603f0111 (`call ...,[],4`, d0 id -> value). Settings manager 0x60bb528f (2 callers).
- fwrite 0x608d4da9 (`call ...,[d2,d3,a2,a3],24`, a0 buf, d0 1, d1 n, a1 fp -> count); fopen "w" works (emulator FS).
- Strings (en): 2761 "All colors@A028@", 2762 "Single color@A028@" (E-P7 2755/2756 + 6); no immediate use found yet.
  View part table at .data 0x6037a37c = [0x611c8260, 0x611c8296, 0x611c8335, 0x611c84a3] belongs to the 615/616
  (2-value) view, NOT the COLOR wheel. Guide label and wheel polygon producer for COLOR: still open.
- Section table 0x60029b28 {dest, flash, flag}; ends via 0x60045e6c. Free FF tails: s1 0x6031e910..f000,
  s2 92 B, s3 0x6081fe00..0x60820000, s4 0x60a8f088..f800, s5 0x60adb5a0..b800, s6 0x60f49580..9800,
  s8 0x617e45e0..4800, s9 0x619a966c..9800, s10 0x61aa42f0..4800. RAM = flash + 0x10021000.

## Editor test 1 (pp/ed1.s, build_ed1.py; emulator-verified, not camera-tested)
- = probe 2 + ed_get/ed_default (facade words), ed_set (0x60b8798b), ed_init/ed_info (records +4/+44), ed_trig in the
  half-press hook (save when dirty), ed_save/ed_wfile (.NEW -> .BAK -> .BIN, read-back verified), block zeroed at load.
- Heap P: +680 'OM3E', +684 axis (0 S, 2 Hue, 1 Light), +685 dirty, +686 status (1 saved, 2 no mem, 3 .NEW fail, 4 .BIN fail).
- INFO: S single -> stock (ALL) -> Hue -> Light -> S. Half-press resets the page to S and saves.
- Emulator: edits land in the right slot (COLOR1 slot 0, COLOR2 slot 1), save files CRC-valid, reload restores them,
  no-folder save fails cleanly (status 3), stock path without the loader unchanged. Wheel shape and guide text stay stock.
- Camera 2026-11-04: editor test 1 WORKS (H/L edit + shot, no freeze); the selected slice changes its own colour (sector map confirmed). User: confusing without a page label.

## Tools (this workspace)
- port/align.py (E-P7 -> OM-3 fuzzy matcher), port/xmatch.py (disasm helpers), dis/*.npz
- pp/build_probe2.py, pp/probe2.s/.ld, pp/probe2_test.py, pp/session_probe2.mjs (FIX_GATE=1), pp/card_add_file.py
- ui/nav.mjs (walk + PNG), ui/trace_edit.mjs (PC diff + register watch)
- om-emu at /home/claude/flatpanda/om-emu (Node 26 at /home/claude/node26/package/bin); modelcheck needs --no-port.
- Camera test 2: 2761/2762 never shown on the OM-3 wheel (no label change). Wheel texts (photos): dial labels
  "Color <swatch>" / "Vivid ±0" (single), "Color All" / "Vivid All" (ALL), guide "Color All [INFO]" / "Color Select [INFO]".
  Not whole strings in the en table: composed from words (3231 "Color", 310/1663 "Vivid", 52/442 "All", 2114 "Select").
- Test 3 (out-ed3): string getter hook swaps "Vivid" (310, 1663) -> "Hue" / "Light" on axis 2 / 1. Unit-tested.
- Test 3 camera: no change ("Vivid"/"Color All" are not drawn from the string table; likely image text). Label parked.
- Wheel polygon producer FOUND: 0x60b1d08d.. (case 6): profile = setting 903 (1..4), cursor 2197..2200 -> (172,sp),
  12 x `mov id,d0; call 0x603f039d,[],4; movbu d0,(160+i,sp)` (slice 12 of COLOR1-3 via shared 0x60b1d354).
  Test 4 (out-ed4): 45 call sites -> ed_poly (Hue/Light values on those pages). Emulator: outline values follow the page,
  redraw on INFO and on every edit. ed_str/hook_str removed.
- OSD bitmaps (resource block 0101, image records at 0xa403d000 / 0xa46dd000): descriptor <6H3I> fmt 14, w, h, 8, 0, 0,
  size, payload, flags; stream header (h-1, w-1, type); type 11 = 64-bit groups of five 12-bit tokens (index<<4 | run-1),
  6877/6877 decode (osd/osd11.py). Guide pictures: 0xa49ecdf8 "Color All [INFO]" (175x50, payload 0xa49ebe40, 4022 B),
  0xa49edf88 "Color Select [INFO]". The main CPU re-reads the descriptor on every draw (emulator watch). "Vivid"/"Color"
  dial labels are not bitmaps there (font-drawn by the graphics engine?).
- Test 5 (out-ed5): GUIDES.BIN (OM3MOD, 'OM3G', CRC) loaded after BUNDLES into the heap (P+700); gd_set swaps the
  "Color All" descriptor size/payload to Hue/Light pictures on those pages, stock otherwise (ed_info/ed_init/ed_trig).
  Emulator: swaps on each page change; the draw reads our picture data.
- Test 6 (out-ed6): held-OK reset = event 0x903e -> router catch-all -> record +36 (stock 0x61225d52). ed_event (sec 10):
  stock reset with the page forced to Saturation, then the slot's hue/light zeroed, dirty, children refreshed + poke on
  H/L pages. Emulator: reset from the Light page -> sat 0 (stock), hue/light 0, saved on half-press.
- Test 7 (out-ed7): per-profile additive WB. Keys 34041 (A-B) / 38521 (G-M) read by getter 0x60063380 (type 9, s8
  sign-extended) at 12 sites (capture WB 0x60457982..cff, params 0x604631b2/c5, record 0x604876c3/d8) -> wb_get (sec 1):
  stock + slot +26/+27 when wb_flags (+25) & 0x81 == 1, picture mode 38017 (6 -> 40209) == 11, profile 63153; clamp +-7.
  WB page = axis 3 (INFO S -> H -> L -> WB -> S): Yellow (928+12k) = A-B, Green (938+12k) = G-M, other slices refused.
  ed_info/k_cur/ed_poly moved to sec-6 tail 0x60f49590. GUIDES.BIN v2: s3 (WB picture) at +24; limit 12 KB.
  Emulator (wb_get single-stepped inside the live session): 0 before, +2 after A-B +2 on COLOR1, survives reload,
  reset clears it. The 12 reads themselves do not run in the emulator (no capture pipeline): camera test needed.
- Front dial on the wheel: from slice 1, + goes to ALL, then 12, 11, ...; - goes 2, 3, ...
- Test 8 (out-ed8, sha e777043f...): '*' and the "Reset [OK hold]" guide come from stock is-default 0x6129bad6
  (GetValue vs GetDefault; the guide only shows when the profile is changed, which is why reset seemed missing after
  Hue/Light/WB-only edits). ed_isdef (sec10) wraps the 7 far calls (0x611d18a7/18e8/18f6/1939/1946/1953/1ac3) and
  ed_pmod replaces "COLOR profile changed?" 0x6129ba07 (5-byte jmp hook; near call 0x6129ba33 can't reach sec10):
  a sector id reads changed if its hue/light != 0 or the profile's WB is on and != 0. Emulator: Hue-only and WB-only
  edits show COLOR*/Vivid* and Reset; hold OK clears sat + hue/light/WB; '*' goes away. Mono loop 0x6129b9f0 untouched.
- Emulator screenshots: session_ed1.mjs token shot:FILE.png (lab.compose raw, channels look swapped).
- Test 9 (out-ed9, sha 7976c4f3...): whole-profile reset = hold OK on the "COLOR n" item of the picture-mode list ->
  event 0xf881 (63617) to every item; the wheel record gets it via the router catch-all (ed_event). ed_event now takes
  0x903e and 0xf881 (event kept at (24,sp), frame 28): stock reset on Saturation, then the slot's hue/light/WB cleared +
  dirty. Emulator: hue+light+WB -> hold OK on COLOR 1 -> all zero, every '*' and the Reset guide gone, saved (status 1)
  on half-press; wheel hold-OK unchanged; editing after the reset fine. (A single main-3 token = one step in the emu.)
- Test 10 (out-ed10, sha d68daeff...): the readout next to "Vivid" is built by 0x611d1308: cursor 2201..2204 (by
  picture mode 54/55/56/64), slice -> ids 916..927 (table 0x6154cd00), facade GetValue of that id. ed_get now maps
  916..927 on the Hue/Light/WB pages to 928 + 12k + slice (k = P+687 EDK, stored by ed_info) -> the readout follows
  the page (emu: Hue +2, Light -1, WB +1, Saturation +3). ed_isdef runs the stock compare with AXIS 0, so Saturation
  changes count on every page (Reset guide on the Hue page after a Saturation-only change). Was the same in tests 1-9:
  the readout always showed Saturation.
- Test 11 (out-ed11): WB page = 12 o'clock (sector 0) A-B +26, 6 o'clock (sector 6) G-M +27, 3 o'clock (sector 3)
  Blacks +47, 9 o'clock (sector 9) Whites +48 (Caduceus v0.19 slot ABI; loader range -5..5 there already), others
  refused. Blacks/Whites count for the '*' and are cleared by both resets.
  Tone ends = port of Caduceus E-P7 patches/tone_ends: stage list 0x605197cb.. (COLOR 0x60518573, luminance-LUT
  builder 0x60518db2 = E-P7 0x603b0a70, next 0x60518fa4 = 0x603b0c66). OM-3 offsets: R+1568 art override (E-P7
  1524), C+60 mask 0x4134063e (0x8268063e), O+3828 LUT pointer (2608), O+3832 buffer (2612), stock tone step clears
  O+0 bit 16 (E-P7 O+4 bit 8). Hook 0x605197d7 `call tone,[d2,d3,a2,a3],56` (stock f1ec cdcbf7f038), code sec 5
  tail 0x60adb5b0 (451 B). Profile via getter 63153 (as hl_pp). Frame 52 (d0 at +48: the getter call writes its
  return word at (0,sp)). In-session native test (token tonecall, 127 cases): LUT == ep7_tone.remap bit-exact,
  registers/MDR/sp preserved, idempotent, out-of-range = 0. Capture/LV pipeline itself not emulated: camera test.
- GUIDES.BIN v3 (sha 9f195ef3..., 9948 B): page 3 label "WB/BW" (mkguide2.py: same font 42, squeeze narrowed to
  0.74 so the fill fits cols 2..102); Hue/Light streams byte-identical to v2. No firmware change (test 11 stays).
  The emulator selects stream 3 on the WB page (desc 4052 B) but does not draw heap labels.
- Test 12 (out-ed12, pkg sha 22fe28ac...): per-profile Glow = port of Caduceus E-P7 patches/bloom + the bloom part of
  patches/lv_art. Stock Soft Focus passes (job flag 0x80) on COLOR jobs, weight by strength (942/881/819/748/666 =
  blur share 8..35 %). OM-3 map: converter 0x60555e47 (E-P7 0x603eab39), hook 0x60555ee5 (movbu (37690,a3),d0, 6 B)
  -> glow_flag; weight getter 0x605048c1 (E-P7 0x6039fee8, key ctx+48) -> glow_w (key 11: P+GLOW 688 -> w, else
  600); combiners 11 0x60504ecd / 12 0x60504f15; LV development handler 0x60479c01 (E-P7 0x60321d3b), its ctor call
  0x60479daf -> glow_lv (params +8 key, +12 flags, +40 type; type 0x3x not 0x1xx). Profile = getter 63153. Slot +28
  effect 1, +29 strength (Caduceus ABI). Code: sec-3 tail 0x6081fe10 (370 B); ed_poly moved to sec-8 tail 0x617e45f0.
  UI: INFO S -> H -> L -> WB/BW -> Glow (axis 4) -> S; Glow page 12 o'clock = strength 0..5 (negatives, other slices
  refused); '*', both resets, readout, save/reload verified in the emulator. Native ncall: 24 glow cases + tone 127 pass.
  GUIDES.BIN v4 (sha d53a7423..., 13192 B): s4 "Glow" at +28 after s3; loader limit raised to 24 KB (test 11 and
  earlier reject this file -> stock labels). Not emulated: the Soft Focus passes themselves (camera test).
  Glow colours: not built. Caduceus tried tints (chroma spread, test13b/13c: no visible colour; mask route: garbled
  frames; blur-buffer read: crash) and ships glow without colour (v0.14+).
- Test 13 (out-ed13, pkg sha 177b3df7...): test 12 (glow, never flashed) + page order Hue -> Saturation -> (stock
  Color All) -> Light -> WB/BW -> Glow -> Hue; ed_init opens the wheel on Hue (sets EMARK/EDK on first use).
  Readout label (stock "Vivid" picture, descriptor 0xa4cf688c 70x30, payload 0xa4cf6210/1660 B) follows the page from
  LABELS.BIN ('OM3L' | total | crc | 70 | 30 | size[5] by axis | streams from 36; Saturation/Light/Hue/WB/BW/Glow,
  osd/mklabel.py + mklabels_bin.py, 7928 B); lb_load (sec 4) / lb_check (sec 6) / gl_set (sec 8, from gd_set).
  The labels are pictures, not strings (string-table swaps change nothing); the emulator does not draw heap pictures
  and a wider (140 px) label also vanished there, so the labels keep the 70x30 box ("Saturation" font 25, squeeze 0.54).
  malloc above 16384 B never returns in the emulator: both loaders capped at 16 KB (GUIDES.BIN v4 13192 B unchanged).
  Bug found and fixed in emulation: gd_set had no scratch word, so its nested call's return word overwrote the saved a2
  of its caller (ed_trig then skipped the save); gd_set now reserves 4 B around the call.
  Crop modes (Caduceus ASPECT.md): 145 edits / 2 KB over 8 camera rounds on E-P7 (menu + SCP lists, static validator,
  capture/LV geometry, CapThr switches, size text, icons, boot clamp). Not started for OM-3.
- Camera 2026-11-04: test 13 -> "values move, no effect" on every page (Hue, Light, WB/BW, Glow): nothing rendered,
  existing recipes included; the save still ran (BUNDLES.NEW/BAK identical to BIN). Test 12 (= test 11 + Glow, old order)
  flashed as a bisect: Hue/Light/WB/BW work again, Glow shows nothing. So the test-13-only changes (ed_init opening on Hue +
  EDK/EMARK there, k_step reorder, gl_set readout-label swap of VDESC 0xa4cf688c, lb_load/LABELS.BIN 8 KB) broke rendering;
  exact cause not found. User: drop Glow entirely, keep the default page order, no readout labels.
- Test 14 (out-ed14, pkg sha bc18a10a..., ed1_test14.s/.ld, build_ed1_test14.py) = test 12 minus Glow (glow hooks back to
  stock, ext3 reused) + a Looks page. INFO: S -> (ALL) -> H -> L -> WB/BW -> Looks (axis 4, only when LOOKS.BIN loaded) -> S.
  Main dial on Looks: COLOR1-4 editor records +12/+16 (stock Up 0x61223ef7 / Down 0x612241b6, data words) -> lk_up/lk_down
  (ext3): look n +-1 with wrap 0..n; leaving 0 keeps the 64-B slot entry at P+BKUP(720)+64k, back at 0 puts it back; a look
  writes hue/light, +25 wb on, +26/+27, +47/+48, +31 |= 2; dirty; children refreshed + cursor poked (as ed_event).
  (The child value widgets cache their own value and clamp to -5..5, so the stock step path cannot reach > 5: verified.)
  P+LPTR 708 (heap copy of LOOKS.BIN), P+LIDX 712+k (look number, 0 = "My own"; cleared at load, by hand edits in s_dirty
  and by both resets). Readout on Looks = look number (ed_get 916..927 -> LIDX[EDK]); wheel cells read 0.
  Readout number tables extended at build time: 0x611d16e6 / 0x611d1757 `mov 0x6154caa0|0x6154caf8,a0; mov 11,d3` ->
  rd_sign/rd_mag (22 entries, -5..16) in the section-9 tail 0x619a9670 (FF from 0x619a966c). lk_load (ext8) after gd_load,
  lk_check (ext4). LOOKS.BIN v1 ('OM3K' | total | crc32(12..) | u16 1 | u16 n 1..16 | 16 zero | n x 32 looks | n x 16 names),
  generator looks/mklooks.py (== the Look Lab web tool, byte-checked). GUIDES.BIN = v4 layout with s4 "Looks" (13056 B,
  sha 0699cdb9...). Emulator: steps/wrap/restore/hand-edit reset/save verified, no LOOKS.BIN -> WB -> S.
- OM-3 Look Lab web tool: claude.ai artifact 45ab6f55-8f0c-4464-aae7-5d4384f6798e (looklab/), db doc lab/state, downloads
  (zip of OM3MOD/LOOKS.BIN [+ BUNDLES.BIN]); BUNDLES export byte-identical to the card file for the same values.
- Test 15 (out-ed15, pkg sha e56cea26..., ed1_test15.s/.ld, build_ed1_test15.py): per-profile looks, 5 each. Looks page
  (axis 4) = 12 o'clock spot only, value through the normal facade path (no record +12/+16 hooks, no readout tables):
  CELL -> P+LIDX+k (s8); ed_set -> s_look (sec 3): every -5..5 value is accepted and stored (the dial child caches what it
  asked for, so refusing desyncs it: seen in emulation, refused 3 then -1 gave no change); look = value 1..c_k, anything
  else = "My own" (backup P+BKUP+64k taken on leaving look 0, put back on return); then s_dirty2 (dirty + manager).
  LOOKS.BIN v2 (992 B fixed): 'OM3K' | 992 | crc32(12..) | u16 2 | u16 20 | c[4] (0..5) | 12 zero | 20 x 32 looks
  (COLOR k look j at 5k+j-1) | 20 x 16 names. looks/mklooks2.py == Look Lab (byte-checked). Emulator: COLOR1 and COLOR2
  (tab 'right') apply their own records; undefined/negative = own; restore and save verified.
- Look Lab v3 (artifact seq 5): recipe-card styling, 4 profile groups x 5 looks, db doc lab/state v3 (prof, own).
- Test 16 (out-ed16, pkg sha df0480df..., ed1_test16.s/.ld, build_ed1_test16.py): profile bank. Axis 4 page "Profiles"
  (GUIDES.BIN = osd/GUIDES_profiles.BIN, 13680 B, sha 4704f4d0...). 12 o'clock value 1..5 = COLOR k's bank profile,
  anything else = 0 = neutral. s_look (ext3): leaving profile e_old >= 1 -> pf_cap (ext3: slot hue/light/WB/BW + 18 stock
  settings via sget: sat 928+12k+s, contrast 908+k, sharp 904+k, shading 912+k, Sh 978+3k, Mid 977+3k, Hi 976+3k), then
  pf_put (ext9: slot <- record, flags |= 2, the 18 settings through `call manager,[d2,d3,a2,a3],68` with the SetValue's
  a0/a1). Hand edits and resets no longer clear LIDX. ed_trig: pf_wb (ext1) runs BEFORE the EMARK gate (menu-only edits
  count), captures selected profiles, CRC before/after -> DIRTY; after ed_save, pf_save (ext9) writes sel + CRC, then
  PROFILES.NEW and PROFILES.BIN (pf_w, ext6, read-back compare). pf_load (ext8): file checked by pf_check (ext4,
  tables pf_lo in ext3) -> bank + LIDX = sel; no file -> neutral heap bank; bad file -> no bank (page hidden, file kept).
  Stack-frame rule used: `call f,[d2,d3,a2,a3],N` saves the regs at N-16..N-1 of the callee frame; locals 4..N-17.
  PROFILES.BIN v1 1632 B: 'OM3P' | 1632 | crc32(12..) | u16 1 | u16 20 | sel[4] | 12 zero | 20 x 64 records (5k+v-1:
  hue12 light12 sat12, +36 wb on, +37 ab, +38 gm, +39 blacks, +40 whites, +41 contrast, +42 sharp, +43 shading, +44 Sh,
  +45 Mid, +46 Hi) | 20 x 16 names at 1312. profiles/mkprofiles.py == Look Lab profilesBin (byte-checked).
  Emulator (session_ed1.mjs IMAGE = out-ed16/main.bin, EMU /home/claude/flatpanda/om-emu/emu; new token `vals` reads the
  18 settings x 4 through the getter; snap shows lptr/lidx): switching saves/loads all 18 + slot (incl. +-7, +-2, -5),
  COLOR2 separate, write-back after S-page-only edits, save/reload with sel, bad CRC ignored, recipe bank loads exactly.
  Negative dial values show as -1..-5 but mean 0. Look Lab artifact seq 12: profiles UI, PROFILES.BIN export (sel 0) and
  import (replaces); older LOOKS/BUNDLES import as wheel-only profiles.
- Test 16b (out-ed16, pkg sha 4894d1f9...): Profiles dial limited to 0..5. The dial's value list is rebuilt from facade
  count (+28 word 0x60e57490, stock 0x60b86e09) and value-by-index (+32 word 0x60e57494, stock 0x60b87031) at every
  children refresh (editor open, each INFO page change; seen with WATCH). pf_cnt (ext10) / pf_vbi (ext8) return 6 /
  index 0..5 for the 12 o'clock id when AXIS 4 (shared check pf_is, ext1, macro PROFID); else stock. Emulator: stops at
  0 and 5, Saturation page still -5..5. Camera: test 16 confirmed working before this change.
- Test 17 (pp/ed1_test17.s/.ld, build_ed1_test17.py, out-ed17, pkg sha 536d47cf...): profile names on the Profiles page.
  The editor draws no table strings (string getter 0x610f56a6 never called inside the wheel editor; only 2755 on the
  Picture Mode screen / SCP), and the readout digits are glyph codes, so names are pictures: NAMES.BIN v1 ('OM3N',
  4 groups <= 16 KB, 20 entries {u16 off, u16 len}, type-11 175x50 streams, CRC) written by the Look Lab (namesBin).
  nm_load (ext4, HLS task after pf_load): one malloc per COLOR group (large heap: 16 KB blocks; the class-1 pool has
  only ~5 KB left), CRC + per-entry header checks. gd_set: axis 4 -> nm_pick (ext4) = picture of (EDK, LIDX), else the
  "Profiles" label; nm_own (ext8) lets gd_set switch away from a name buffer. s_look calls gd_set(4) after a switch;
  the guide payload is re-read on every dial step (WRANGE trace), so the name follows the dial. sd_def now builds the
  neutral defaults from sd_hdr + DEF_CRC (544-byte table removed from ext4); gd_path moved to ext9.
  Emulator: names follow 1..5 on COLOR1/COLOR2, reopening shows the saved profile's name, 0 -> Profiles label,
  damaged / missing NAMES.BIN -> Profiles label, defaults path + save valid. Not drawable in the emulator: camera test.
  Titles ("Color Profile n" -> name via string-table pointers, tt_set) written but dropped for code space (283 B).
  GUI task tid 168 vs HLS 164: file I/O stays in the HLS-task load.
- Test 18 (pp/ed1_test18.s, out-ed18, pkg sha c2fbc731...): the wheel opens on the Profiles page. ed_init (ext1, CALLS,
  d0 = editor key 0x1540+k: traced) -> ei_page (ext3, `call ei_page,[],4`): EDK = k, first-use marker, AXIS = 4 with a
  bank (else 0), gd_set; all before the stock init so the children build the 0..5 list. INFO order unchanged
  (4 -> 0 -> ALL -> 2 -> 1 -> 3 -> 4). Room: pf_lo span half computed in pf_check (lo < 0: -2 lo; byte 36: 1).
  Emulator: opens on Profiles with the name, COLOR2 from its key, Hue/Light/WB edits land in P and in the saved
  BUNDLES.BIN (the test-13 failure was edits never reaching P: saved file identical), PROFILES.BIN saved.

## v0.20 grain research (2026-11-05)
- E-P7 history (cakelesscoder docs/GRAIN_PORT.md, CHANGELOG v0.21/v0.22): combiner-32 grain on COLOR jobs = nothing
  visible on full-size stills; COLOR job + stock MONO mask/grain passes (grain_c) = colour, no grain. Never tried on a
  camera: the reverse, a real MONO job with its colour put back (MONO_COLOUR.md capture hooks, dropped by the user).
- OM-3 map (E-P7 -> OM-3): grain gains 0x604ec0ce -> 0x60667dc2 (110/300/600, 50/75/100 at +6); combiner selector
  0x603b5200 -> ~0x6052cf6x (0x0901 -> 31 at 0x6052d042, 0x0902 -> 32); handler 31 reads level request+1751
  (E-P7 1828; request offsets -77 around here), gain -> bank+148. HSL selector mode test 0x603b02bf -> 0x605185fd
  (sat request+1739, table 0x606ba608, control (0x606bb1d8), general path 0x6051863f). Chroma stage 0x603b132a ->
  0x6051958c (key (48,ctx), tone lookup 0x60519452 at 0x605195b2, COLOR result 0x60519568). Matrix stage filter id
  request+1731 at 0x605196d2 (E-P7 1802), matrix fn 0x605147a2 (E-P7 0x603acfe4). Mono curve flag request+1731 bit 7
  at 0x60518f41 ((107, req+1624)). Packer (E-P7 0x60353db9 merge) not found on OM-3 (different code shape).
- Test v0.20-t1 (pp/ed1_v20t1.s, out-ed20t1, pkg f8c1b71c...): every MONO capture renders neutral colour (g_sel: COLOR
  HSL call with a zero sat table; g_chr: no grey/toning constant; g_mat: filter id 0); grain/shading/route stock.
  Curve flag left as is (mono tone curve on colour). Camera question: colour + grain on a MONO profile with Film Grain on.
- Camera: test 1 BOOTLOOPS (recovered by flashing v0.19). Cause (static, likely): the hooked stage code lives in section 2
  and runs before later sections load; g_mat/g_zero sat in section 8 (FF at the time -> exception). Section 1-5 code is
  proven safe on that pipeline (hl_pp sec 1, tone sec 5). Test 1b (out-ed20t1b, pkg 314633d6...): g_sel sec 1, g_chr sec 3,
  g_zero+g_mat sec 4 (room from moving BUNDLES.NEW/.BAK path strings to secs 6/9; save path emulator == v0.19).
- Test 1b camera: boots; MONO JPEG still grey, Cb=Cr=128 exactly (stddev 0), grain strong. Grey comes from kind-3 dispatcher 0x60513115: format 0x0c04 -> grey list 0x60519ea5 (0x60519572 constant chroma). Test 1c (out-ed20t1c, pkg dd558c4b...): call there -> colour list 0x60519e87.
- Test 1c camera: still Cb=Cr=128 exactly. Conclusion: MONO route is luma-only end to end; colour + ISP grain not
  reachable without changing the route's image formats (E-P7 grain_c did the reverse: colour, no grain). Grain parked.

## v0.20 Extras research
- Art Effect -> job flag converter 0x60555e47 (E-P7 0x603eab39): capture+38225 = Art Effect id, jump table 0x606e5f88:
  1 Soft Focus 0x80, 2 Pin Hole 0x400, 3 Frame 0x8000, 4 White Edge 0x2000, 5 Star Light 0x40, 6/7 Diorama 0x100/0x200,
  8/9 Shade 0x800/0x1000; tail: capture+37690|37691 != 0 -> 0x800000 (mono grain/filter route) else cleared.
  Params: key at params+8 (u32 LE 0x000b0000 = COLOR), flags params+12 (= a2). Callers 0x6054f6fa, 0x60553ac2, both
  after the key writer 0x60555d10.
- Work-list builder default path 0x604b917f tests the same flags for every key (0x80 at 0x604b9249 ...), as E-P7.
- Soft Focus weight getter 0x605048c1: key 0x01010065 uses its level, any other key w = 600.
- Test 2 (out-ed20t2, pkg d4db1f42...) = v0.19 + fx_hook at 0x60555e50: COLOR capture without an Art Effect gets
  COLOR1 Soft Focus, COLOR2 Frame, COLOR3 Star Light, COLOR4 none. Question: do Art Effect passes render on COLOR stills.

## v0.20 test 3 (Extras page + white frames) — built 2026-11-05, pkg b5268286…
- Extras page = axis 5 (INFO: … WB/BW → Extras → Looks). 12 o'clock slot+49 (Glow < 0; Clarity > 0 not rendered yet),
  6 o'clock slot+50 (Frame > 0). CELL folds Extras into the WB branch (+23, odd-bit sectors refused). LOOKS.BIN +47/+48.
- fx_hook at 0x60555e50 (section-2 tail + ext6 fx_fl): COLOR key 0x000b0000, no stock Art Effect → flags |= 0x80 / 0x8000.
  The converter's (0,sp) is its outgoing slot (calls 0x61a30a5a, never reads it), so no add -4,sp around the getter.
  Emulator ncall of 0x60555e47: glow+frame 0x8080, frame 0x8000, glow 0x80, MONO and stock Art Effects untouched.
- Emulator: the sub dial does not move the wheel cursor; main after sub = "All" (+1 on every cell), same on the stock WB page.
- Component 2 frame pairs: directory {addr,size} at +0x400, entries 1..26 (odd = layer, even = window mask), JPEG at +0x20,
  zero padding. Masks are exact binary rectangles (not 8-aligned). New layers (om3/frame/frames.py): white outside the
  window, black for 8x8 blocks wholly inside it → correct for lerp and additive blends. Header = libjpeg q=1 4:2:2
  layout, byte-identical to the stock headers; pure-Python DC-only encoder (matches libjpeg on all-white images).
  comp2 sha 3d9fd442… → 3185b34e…; checksum = same wordsum rule as main.

## v0.20 test 4 (Film page + merged Extras, Caduceus layout) — pkg cdf9b961…
- INFO: Film(4) → S → (All) → H(2) → L(1) → Extras(3) → Film. Axis 5 gone; WB/BW page merged into Extras.
- Extras slice i (0 = 12 o'clock, clockwise) via xt_tab {slot byte, min, max}: 1 NR +51 (0..3), 2 Glow/Clarity +49,
  3 A-B +26, 4 G-M +27 (both set wb_flags bit0), 5 Art +50 (Caduceus ids 0 off,1 Star,2 Pin Hole,3 -,4 White Edge,5 Frame),
  6 Blacks +47, 7 Whites +48, 8 none. Record +47 glow, +48 art, +49 NR. fx_ft maps art id → 0x40/0x400/0x2000/0x8000.
- Emulator: ranges hold (NR stops at 0), All mode steps every cell (stock behaviour), save/reload ok, ncall flags ok.
- Live view lead: 0x6046b86c (record → development request; same 0x9d05 error code as E-P7 0x60312f42) maps the
  Art Effect to job flags only for picture mode ≥ 100 (0x6046b8bb). COLOR hook there = Caduceus H2 analogue. Not in emulator.
- Code space is the blocker for NR/clarity/LV (≈90 B free in total). Plan: relocatable code block loaded from the card.

## v0.20 test 5 (code block from the card) — pkg db3fdf0b…, GUIDES.BIN 4aa16a60… (tag 0x58c632cc)
- GUIDES.BIN = pictures + code block at the end: code (linked 0x10000000) | relocs (bit31 abs +Δ, else PC-rel −Δ) |
  {tag, end−code, len, n}. x_load (ext6, from gd_load) checks the tag ('X' + 3 B of the image SHA with placeholder),
  `calls` entry 0 (PIC relocator, byte-wise fields), publishes P+XPTR (692; cleared at gd_load start).
- Stubs (section-2 tail unless noted): xp (STATE→P→XPTR, uses d0, retf), s_lv, s_nr; s_wt (ext5), s_cap (ext8).
  Hooks: 0x6046b8bb (29 B gate rewrite, COLOR → s_lv), 0x605048c1 (jmp s_wt), NR reads 0x603c8038 / 0x603e7891 (call s_nr),
  0x60555e50 (jmp s_cap). k_cur moved to ext1 for room.
- Block: cap flags (glow or clarity → 0x80, art table), lv flags (glow only), weight (glow 942..666, clarity 1100..1420 on
  combiner 11 / 1024 on 12; stock 600), NR (1 Std 0, 2 Low −1, 3 Off −2 after the real read).
- Emulator: relocated block == direct link at its address (except the relocator's own Δ constant); every entry's ncall
  matches the model; with an old GUIDES.BIN every hook is stock.

## v0.20 test 6 — pkg 18a65aa3…, GUIDES.BIN cd3c9f5b…
- Camera report (t5): INFO off 12 o'clock toggles All colors on every page (front dial). stock_info is reachable only via
  the record words, so k_go fell to stock; the only cursor-dependent check is k_cur (GetValue 2197+k). t6: a failed
  cursor read counts as "not ALL" (page step); the poke is skipped without a value. Unverified cause (emulator always reads).
- Forcing the cursor to 1 does not move the wheel: the dial widget keeps its own index (0x611b4570 SetValue from the
  widget's list[index]); a SetValue + view refresh leaves the index, so the next edit hits the old slice. Not used.
- Held-OK reset now clears slot +0..51 (adds Extras +49..51; +31 flags cleared, set again by the next H/L edit).
- t6b (pkg 8dee00e8…, GUIDES c25deb84…, tag 0x584f9219): the stock INFO handler's ALL id is 2201 + k (table 0x615ac0b4),
  not the wheel cursor 2197 + k. Entered from 12 o'clock, ALL shows as 2197 = 255 (2201 stays 1); from another slice as
  2201 = 255 (2197 keeps the slice). k_ad (stub → block +40) reads 2201, then 2197. Emulator: S → ALL → H from 12 and 3.
- ed_isdef now counts slot +47..51 (Blacks, Whites, Glow/Clarity, Art, NR) as changed: '*' and, likely, the stock
  Reset guide (the reset on an Extras-only change never reached ed_event before).

## v0.20 test 7 (Extras dial labels) — pkg 6eb202d3…, GUIDES ea1b9009…, LABELS.BIN v2 06bc64d5… (5686 B)
- The dial label ("Vivid", VDESC 0xa4cf688c 70x30, stock payload 0xa4cf6210 / 1660 B) names the Extras slice + value.
  ed_get's readout path (ids 916..927) calls vl_s (ext7) → block +48 xb_vl: Extras page slices 1..7 → label index from
  xb_vt {slot byte, mode (value / sign / fixed), first, max}; elsewhere stock. Only a 70x30 descriptor with the stock
  payload or ours is touched.
- Heap: the uncached pool is small (~45 KB, P/GUIDES/NAMES/LOOKS in it): 21 pre-encoded labels (36 KB) exhausted it
  in the emulator (malloc 0 at #20). LABELS.BIN v2 = 1-bit letter bitmaps (21 x 270 B); xb_rend draws fill 10, 1 px
  edge 7, grey 8 to 2 px and encodes type 11 into one 2 KB buffer, only when the label changes. Heap use ~7.7 KB.
  Emulator: every label byte-identical to mklabels.render + encode11.
- Bug found in emulation: a call from xb_vl wrote its return word over the saved a1 at (0,sp), ed_get then stored the
  readout into the block's code → crash on the next label. Fixed with a separate call slot.
- PROFILES.BIN fallback dropped (room): v0.17/v0.18 users rename PROFILES.BIN to LOOKS.BIN (same format).
- LABELS.BIN titles (user): NR, Glo/Cla, B/A/A-B as 'B' 'A' 'A/B', 'M' 'G' 'G/M' (sha 4fdee1ff…). Card file only.

## v0.21 test 1 (VigFix) — pkg 1b39002d…, GUIDES e3ee2cfa…, LABELS 96b6623f… (23 labels)
- Shading Comp. = sid 61, key 0x8c21: the setting-ID table 0x6062555c is identical to the E-P7's 0x604d6c14 for its first
  252 entries ([61] = 0x8c21, [143] = 0x9719). Seven reads `mov 35873,d0 ... call getter,[d2,d3],12`: 0x603d4f84,
  0x603dc2ed (settings snapshot 0x62a74d07), 0x603eab70 / 0x603eac45 / 0x6070c6ce / 0x6070c855 (request flag 0x2000 when
  1, the E-P7 R2 shape), 0x60457e83 (capture +5456, R1). All seven -> s_nr (rel32), which passes the key to block +32.
- xb_nr dispatches on the key: 0x9719 NR as v0.20, else slot +52 == 1 -> real read, then 0. Emulator ncall: key 0xf6b1
  (stock 1) -> 1 / 0 for VigFix 0 / 1; NR 2 -> -1, 3 -> -2; d2/d3/a2/a3/sp intact.
- Editor: xt_tab sector 8 {52, 0, 1}; ed_isdef reads +48..51 as one word (slot entries 4-aligned) + 52; reset 53 bytes;
  record +50 <-> slot +52 (pf_cap, pf_bt); pf_lo[50] = -1; BUNDLES range +52 0..1. Labels 21 "Vig Cam", 22 "Vig Off"
  (streams 1508 / 1548 B, equal to Python). Emulator: sector 8 0..1, `*`, hold-OK reset, half-press save, LOOKS.BIN
  look pick loads +50 and an edit saves to the record. v0.20 rejects a LOOKS.BIN / BUNDLES.BIN with a 1 there.
- Also in RAWNR params: ausEffectiveShadingCoefficient[], ucShadingCancel (string 0x61a80656..) — if the getter override
  shows no change on photos, that is where lens shading reaches the pixels.

## Grain on COLOR: own grain (research 2026-11-05)
- IMGPRO_MDL modules (strings 0x61a80180..): ENCODE_JPEG, COPY_YCC, PAINT_YCC (Y/Cb/Cr fill), COMPOSE_RAW, RAWNR, IFINISH
  (development: stBufferICam -> stBufferYCC), ART_EFFECT, CMP_BLEND; CPUs IMGPRO_MDL_CPU0..2. Image descriptor
  (IMGPRO_CTRL_SRC/DST dumper ~0x61a33504): Address (64-bit: lo, hi), AddressC (64-bit), usDataFormat, usMemHw,
  usUseHw/usUseVw (src) or usHw/usVw (dst), offsets, centre; format union YCC / JPEG / BAYER / THUMB.
- Debug buffer dump ("mvr dump", kinds 0..16, 13 = ENCODE JPEG): register 0x6045a91a(d0 kind, a0 CPU address, d1 size)
  -> tables 0xa32de700 / 0xa32de744; check 0x6045b267 (mask 0xa32de68c); the dumper writes from the CPU address. The
  registered addresses are plain 32-bit uncached (e.g. 0xafbd8980, sizes up to 24 MB): CPU can see image memory there.
- CPU-side JPEG encode requests: only 0x6047a3f9 (callers 0x60467334: 160x120 thumbnail / 640x480 screennail, src fmt
  0x0c02, dst 0x1c02 JPEG, memHw 192 / 704; 0x60469fd7 <- 0x60474a0a in fn 0x6047484a: memHw 1344, a ~1280-wide view
  JPEG; then kind 13 registered via 0x60469ffb). The full-size main JPEG is not encoded through these: probably inside
  the still job's module chain. Next: find where the still job runs ENCODE_JPEG for the main image (or where the main
  YCC buffer is complete), then a probe that writes a bit pattern into the top rows of the Y data (proves CPU access,
  carries the descriptor out in the photo itself, no file I/O needed).

## Grain probe g1 (om3/gprepo; out-g1b: pkg 9a1891d3…, GUIDES 47a247d5…; LABELS = v0.21t1)
- Soft Focus on OM-3 (builder 0x604b917f, flag 0x80 at 0x604b9249): classes 0-3 -> pass pusher 0x604be238 + entry
  0x604be2aa / cb 0x604be445 (0x604b8c80 at 0x604b928c); classes 4-8 -> entry 0x604be4b6 / cb 0x604be650. Class byte
  job+5385. Blend setup 0x604be2aa (`calls` callee, a0 = job): BUFIDX 0x604afdf9(job, id) -> index (< 48), records =
  *(job+10276) + 104 i (+0 addr lo, +4 hi, +16 fmt, +18 memHw, +20 Hw, +22 Vw, +88 size, +92 id); request
  0x604b60ce(job, 0): (12) stage 0xf005, (1084) effect 0x0402, +20 input 0x1000 (80 B), +96 input 0x1061, +704 output
  desc fmt 0x0c02, memHw (Hw + 63) & ~63, size memHw*Vw*2 -> 0x604af7c0 alloc new 0x1000; submit 0x604b5a83; then
  releases 0x1060, old 0x1000, 0x1061 (0x604afa9e).
- g1: work-list word 0x604b9288 -> g_sf (ext3; EXT3 end moved to 0x6081fff8) -> block +56 xb_gp: on a COLOR1-4 look
  with Glow/Clarity: pattern A into the input 0x1000 before the stock setup (rows 0-31 even 0xeb / odd 0x80, 32-63
  swapped, 64-95 barcode addr lo, 96-127 barcode memHw<<16|Vw; 32 px per bit, 1 = 0xeb), stock setup, pattern B into
  the new 0x1000 at byte 5120 (barcode lo, barcode memHw|Vw, white band). LOOKS header +20..31 = input record info
  + flags; DIRTY = 1. Writes only via the uncached alias of a 0x6/7/A/B address with hi 0.
- Emulator (fake job 0xb0000000, records 0xb0010000, image 0xb0100000): gate off -> stock, regs/sp intact; probe ->
  bands and barcodes exact, header 0xb0100000 / 0 / 1024 / 600 / 0x02 / flags 0x43, DIRTY 1. Block firmware symbols
  must come by --defsym (a `.set` absolute gave a wrong PC-relative jmp: fixed).

## Grain probe g1 camera result (PB051113/14, LOOKS.BIN header) and g2
- g1 ran twice, no crash, stock setup ok: input 0x1000 = bus 0x4dfe7000 (hi 0), memHw 5184, Vw 3888, format 0x0c02;
  A and B refused (not a 0x6/7/A/B address). So the full-size developed image is NOT CPU-addressed directly.
- CPU bus window: 0xB8000000..0xBFFFFFFF aliases bus (reg byte 3) << 27; per-CPU registers 0x98100058 (+0x4c) CPU0,
  0x98100458 CPU1, 0x98100858 CPU2, 0x98101058 CPU3 (CPU id (0x8050)). Firmware mapper 0x60071018 (`call ...,[d2,d3,a2,
  a3],28`, a0 = bus -> a0 = 0xB8000000 | (bus & 0x07ffffff), 0 on refusal: < 0x08000000 or 0xa0000000..0xb7ffffff);
  takes lock 0x60075f73 (d0 0 -> token: dispatch off + interrupt mask) / unlock 0x60075fbc, cache flush 0x60070e69,
  writes both window registers, per-CPU state table. Users: 0x60540c81 / 0x60540cea only.
- g2 (out-g2, GUIDES 93c6803e…, firmware = g1): xb_open (lock, direct for DRAM bus 0xa0000000..0xb7ffffff, else the
  mapper when the 3.5 MB stays in the window) / xb_close (unlock); header +30 bit4/bit5 = A/B via window. Emulator:
  direct path exact; window path exact with a minimal mapper stub (the emulator's buswin lacks reg 0x4c and the
  flush completion bit).

## Grain probe g2 camera result (PB051115/16) and grain test 1
- g2: A and B both written through the bus window, both in the JPEG: input 0x1000 at bus 0x4dfe7000, blend output
  0x1000 at bus 0x52cca000, 5184 x 3888, memHw 5184 (pitch 10368), format 0x0c02 = YCbYCr with Y in the even bytes
  (band even 0xeb / odd 0x80 -> white; even 0x80 / odd 0xeb -> magenta). The blend is complete when the stock setup
  returns (B survives), so the image after 0x604be2aa returns is the place for grain. Internal Y ~ JPEG Y (235 -> 226,
  128 -> 120 measured through RGB). No crash.
- Grain test 1 (om3/gprepo, out-gr1d: pkg 0aceebb4…, GUIDES 58d26773…, LABELS 73a28cb9… (24 labels)):
  slot +53 Grain 0..5 (record +51, pf_lo -5, BUNDLES 0..5), Extras sector 9 (8 o'clock, label "Grain");
  xb_cap sets 0x80 for Glow/Clarity or Grain; xb_wt w = 1024 for Grain alone; xb_gs (block +56, via g_sf) calls the
  stock setup, then xb_grain on the new 0x1000: malloc 4096 + 2 Hw (T, V, H), per row xb_p1 (noise) and, under
  xb_open (lock + mapper, per row), xb_p2 (Y -> T[Y][h]); FLUSH 0x60070e69 at the end; xb_seed carries on.
  Strength S 20/32/46/64/90 -> sigma 3.4/5.3/7.8/10.9/15.2 at Y 128 (grain/model.py, exact). Emulator: Y bytes ==
  model at levels 3 and 5, chroma untouched, bad format untouched, d2/d3/a2/a3/sp intact; wrapper gate on/off ok;
  sector 9 0..5, label 1236 B (== Python), reset, LOOKS record +51 saved.
  Frame rule (bitten twice): `call f,[regs],N` -> N includes the saved registers: locals only below N - 4*regs, and
  the caller's N must equal the callee's ret N.
- Grain test 1 on the camera: sector 9 works, the shot reboots the camera while it saves (likely the grain pass:
  too long -> watchdog, or the per-row mapper / lock). Diagnostic gd1 (GUIDES e97d7ab9…, firmware = gr1): Grain
  level = mode (1 buffer + T, 2 + noise rows, 3 + 64 image rows, 4 + 512, 5 all), S fixed 90; elapsed from the us
  counter 0x98900284 (E143 board timer channel 33) >> 10 -> LOOKS header +20 + 2 (mode - 1) (u16), +30 modes done,
  +31 runs; DIRTY set.
- gd1 camera: mode 1 ok, mode 2 (noise rows only, no image access) rebooted: the CPU loops themselves are too slow.
  Cause (I): the block and the malloc buffers are in uncached heap (0xa...), so every instruction fetch and buffer
  access goes to DRAM. gd2 (GUIDES 1e782503…): xb_p1s / xb_p2s run via `calls` at the block's cached alias
  (- 0x40000000; parameters in xb_grain's locals 64..88), T/V/H through the work buffer's cached alias, FLUSH before
  and after; xb_grain frame 112. Emulator: modes 1-5 return clean, mode 5 == model.
- gd2 camera (PB051119..123): no reboot in any mode; grain bands exactly where expected (fine-noise std top 64 rows
  10.5 vs 3.0, full image 9-12 at mode 5). Times: mode 1 13 ms, 2 1374 ms (noise for 3888 rows), 3 1440 ms, 4 1965 ms
  -> ~1.15 ms per grained row (mapper per row + uncached window), full image est. ~5.8 s (mode 5 time not saved).
- gd3 (GUIDES ebba1f03…): xb_p1s 4 px per word (SWAR, == model), xb_open reads this CPU's window register under the
  lock and calls the mapper only when the segment differs. Emulator: modes 1-5 and a window-path mode 5 == model.
- gd3 camera (PB051124..129): mode 1 14 ms, 2 804 ms (SWAR noise, was 1374), 3 866, 4 1364, 5 5059 ms. Per grained
  row ~1.09 ms either way: the mapper skip saved little; the uncached word-by-word window access dominates (~4.2 s).
  DRAM 384 MB (emulator board): cached 0x60000000-0x77ffffff, uncached 0xa0000000-0xb7ffffff, window 0xb8000000-
  0xbfffffff; 0x78000000-0x7fffffff presumably the window's cached view (the mapper flushes before every remap).
- gd4 (GUIDES c24eee88…): mode 3 = 512 rows uncached window (baseline), 4 = 512 rows through 0x78.. (cached) with
  FLUSH after each row under the lock, 5 = all rows cached. A 4-px xb_p2s variant had an index bug (h2 bits leaked
  into Y1's index): dropped, the verified per-word loop kept. Emulator: modes 1-5 == model (cached view not modelled).
- gd4 camera (PB051130..136): no reboot; mode 1 13 ms, 2 775, 3 1330 (512 rows uncached: 1.08 ms/row), 4 1097
  (512 rows cached view 0x78..: 0.63 ms/row), 5 2933 ms (whole image cached). Bands exactly where expected; full
  images grained on every row and column (no gaps): the 0x78000000 cached window view is real and per-row FLUSH works.
- Grain test 2 (out-gr2, GUIDES 25131b51…, firmware = gr1 0aceebb4): levels 1..5 -> S 20/32/46/64/90, cached window
  for window rows with FLUSH per row, diagnostics removed. Emulator: levels 1-5 == model on the direct path.
- Grain test 2 on camera works (user: "slow feeling", ~3 s). Strength reference PB051137-139 MONO Low/Med/High vs
  PB051144-148 COLOR 1-5 (same scene). Flat-area grain sigma (Y - gauss 4, MAD; shadows / mids 80-170 / highs
  170-230): MONO Low 2.4/~10/9, Med 2.3/~25/25, High 2.2/34-49/41; COLOR 1 2.9/5/3, 3 5.1/9/6, 5 9.4/16/12. MONO
  grain: none in deep shadows, flat mids-highs, finer (lag-1 autocorrelation ~0 vs ours 0.34).
- Grain test 3 (out-gr3b, GUIDES 32f3e5e6…): h 31 levels ((v + v_left + 1) >> 1), T 256 x 32 (8192 B, own malloc),
  C 945, G = MONO shape (0.08 + 0.92 smoothstep(25..100)) x (1 - 0.25 smoothstep(200..255)), S 56/98/141/183/225 for
  ~10/17/25/32/40 measured on camera. Emulator: levels 1-5 == model. (A table loop end of 1039 left T 31 wide:
  caught by the model check.)
- Grain test 3 camera (PB051150-155, levels 1-5): mids 9.5 / 16.7 / 23.4 / 30 / 36 (targets hit). User: 5 is far
  too much, 3 should be the max. New S 28/56/84/112/141 (5 = old 3 = MONO Med, 2 = MONO Low).
- Grain test 4 (out-gr4, GUIDES b1da205e…): xb_p1s keeps r in a3 (it was a stack load/store per 4 px; stacks look
  uncached), K rows per lock + FLUSH (TEST: K 1 on odd levels, 2 on even; V + 2 H buffer), timing -> LOOKS header
  +20 + 2 (level - 1) and DIRTY (TEST). Emulator: levels 1-5 == model, 5-row image at K 2 too.

## Grain log probe gl1 (om3/glog; out-gl1: pkg 29cceaa6…, GUIDES ed01ec0d…) — research into the stock MONO grain
- Findings (static): OM-3 has the E-P7 combiner 31/32 grain handlers (0x60504fd2 / 0x605050a0, gains 0x60667dc2/c8) but
  the selector reaches them only for key 0x1 (dead: keys < 12 go to the effect-code path); work-list key table
  0x606c957c has no key 12 either (MONO = default path; key 12 only zeroes job+5340/5344/5348 at 0x604b8d38).
  MONO grain setting = capture+37720 -> params(job+8508)+264 (+37721 -> +265), copied only for mode 12 (0x6054fd52,
  0x60553e44); key-12 gate 0x604b3f28 folds it into params+248 (|0x80 | lvl<<4). Filter/tone = capture+37690/37691
  -> params+248/249 for every mode; 0x800000 flag -> kind-3 request +1091/+1092. Combiner 33 (0x60505142, effect
  0x0afd) has a key-12 toning branch (table 0x606adcb6). Op-chain runner 0x6049d343 (types 1..42, type 12 sets
  S+1552 bit 24 when S+264) is used only by 0x604b4dcc <- 0x608b0a91 (factory/test path), not normal stills.
- gl1: hook 0x60504b5d (combiner config -> selector) -> s_cl (ext3, replaces g_sf; work-list word stock = no CPU
  grain) -> block +64 xb_lg logs every request's combiner/kind/stage/effect/key/format + 12 request bytes for 4 s
  after each capture (xb_mark from xb_cap, 4 slots) and copies the first two kind-0 requests (1856 B) and first
  kind-3 request (1152 B); pf_save tail -> block +72 xb_lw writes OM3MOD/GLOG.BIN (35872 B). nm_path moved to ext4.
- Emulator: boots, GUIDES/LOOKS load, editor edit + half-press save status 1 through the new pf_save tail, no GLOG
  without a capture. Logging itself needs the camera. Card backup before gl1: deliver/backup-pre-gl1.
- gl1 camera (PB051167-169, MONO off / MONO High / COLOR): shots fine, one half-press save (between shots 2 and 3),
  no GLOG.BIN. gl1b (GUIDES 82ce5a1d…, firmware unchanged): LOOKS header +20 marks, +21 log buffers, +22 key byte 2,
  +24 xb_lw calls, +25 log data, +26 GLOG open ok, +27 PROFILES.NEW fallback open ok, +28 fwrite bytes/256;
  P DIRTY after each mark and after a write attempt. User LOOKS header +20..31 zeroed (CRC = zlib crc32 of 12..).
- gl1b camera (PB051170-172): header marks 3, buffers 0, key 11, xb_lw calls 2: xb_mark ran every shot, malloc(35872)
  failed. Firmware malloc 0x60024068: <=192 / <=2112 / <=16448 B pools, larger -> error, 0 (also caps GUIDES.BIN!).
- gl1c (GUIDES 15920 B): header 48 B in the block (+32 four slot pointers), slots 6144 B each malloc'd at the first
  half-press save (xb_lw), 95 records, first kind-0 copy +3072, kind-3 copy +4928; GLOG.BIN = 48 + 4 x 6144 = 24624.
  Emulator: buffers allocated at the first save (+21 = 1), saves ok.
- gl1c camera (PB051173-176): GLOG.BIN written; marks MONO, MONO, COLOR; 0 records: 0x60504b5d runs only after the
  first selection 0x604955f1 (fn 0x604955ed, callers 0x60493d7a / 0x604950ce) found a combiner (-> 0x60504779 ->
  0x60504b2b). So plain MONO (grain off/High) and COLOR stills use no combiner at all. Capture bytes at a3+37690..
  all 0 at mark time (MONO High: +37720 = 0 there).
- gl2 (pkg c0509b3c…, GUIDES new tag): + hook 0x604955f1 -> s_cl (every request). Emulator boot/save ok.
- gl2 camera (PB051177-180): marks MONO, MONO, COLOR, 0 records again (block loaded = firmware gl2 is on). The
  combiner config 0x60504779 has one caller (0x604955ed, after the 0x604955f1 selection), so Glow stills pass there.
  gl2b (GUIDES only): log header +20 xb_lg calls, +24 past slot checks, +28 inside the 4 s window. Test adds a Glow shot.
- gl2b camera (PB061181-185, + a Glow shot): xb_lg calls 8572, past slot checks 5409, inside 4 s window 0 -> the
  window test is what dropped everything (USCLK likely per CPU: marks and request config run on different CPUs).
  gl2c (GUIDES only): no window, the first 95 after a mark; record +14 = CPU id (0x8050); slot +24 = mark CPU id.
- gl2c camera (PB061186-190): records! LV request 0x625b0d20 (+14 = 0x0130/0x0030) floods; stills +14 = 0x1000.
  MONO kind-0 dev: effect 0x0c00 -> combiner 33 (0x60505142: mono/toning config, +1732 tone, +1729, +1752), key 12,
  request +1751 = Film Grain level (Off 0, High 3), +1731 = 0xa0 (MONO only), kind-3 +1091 = 0xa0. COLOR: effect 0
  (Glow: 0x0400 + combiners 12/11). All on CPU 2 (marks too) -> the clock theory is wrong; the window failed anyway.
  CORRECTION: the selector/builder hash tables store key-11: table key 0x1 = job key 12. So MONO -> work-list handler
  0x604b908d (mask/grain passes 0x604bba9d / 0x604bbbd0 when job+5356 == 0) and selector 0x6052d03d: stage 0x0901 ->
  combiner 31, 0x0902 -> 32 (the E-P7 grain, reads +1751). Not seen in gl2c: LV filled the 95 records first.
- gl2d (GUIDES only): skip +14 0x0030/0x0130; 63 records; copy A = first kind-0 stage-0 (+2048), B = first stage 0x09xx
  (+3904), 1856 B each.
- gl2d camera (PB061191-195): still-only log. MONO still = kind-0 dev (effect 0x0c00, combiner 33, configured 4-6x)
  + kind-3 final (effect 0, fmt 0x0c02). NO 0x0901/0x0902 passes: Off and High have the same steps; the only
  structural request difference is +1751 (0 -> 3). MONO vs COLOR dev request: +10 key 12/11, +1731 0xa0/0, +1756
  0x0c00/0, +1751. (Readers of +1751 in code: only combiner 31/32 handlers - so the grain consumer is elsewhere.)
- gl3 TEST (GUIDES 16064 B - near the 16448 malloc cap!): COLOR still dev request (kind 0, +14 0x1000, +10 11) gets
  by profile Grain: 1 +1751=3; 2 +effect 0x0c00; 3 +1731=0xa0; 4 +1751,+1731; 5 = 3 + key 12. xb_gt from xb_mark.
- gl3 camera (PB061196 extra, 197-201 = Grain 1-5, 202 MONO High): 1-4 colour, no grain (hp MAD 2.6); 5 (request
  key 12) = grey Cb=Cr=128 with grain = the MONO reference (MAD 31.5). Writing request +10 = 12 turns the later
  config calls' context key to 12: combiner 33's key-12 branch (mode 92 = 0x2a1400, chroma 128..152 zeroed, 144 /
  152 = 0x2a1500, toning 84/88, luma 108..120) -> grain + flat chroma. Grain 3 (combiner 33, key 11) = no grain.
- gl4 TEST (pkg 98ca76b5…, GUIDES 16216): xp now ends `cmp 0,a1` (s_lv / s_nr drop theirs); s_h (ext2) = combiner
  33 handler word -> block +80 xb_h33: stock handler, then for a forced COLOR capture (all levels = MONO request)
  COLOR chroma back by Grain: 1 chroma block; 2 +toning 0; 3 +92 = 0; 4 +luma 108..120 init; 5 none.
- gl4 camera (PB061203 = Grain 0, 204-208 = G1-5): G1 grey + grain (chroma block restore did nothing), G2 (toning 0)
  solid green + strong grain, G3 (92 = 0) solid magenta, weaker grain, G4 grey + grain, G5 MONO + grain. White /
  tinted vignette in all. => the chroma entering combiner 33 is already flat with request key 12 (upstream MONO
  matrix); 84/88 only set the chroma level. (92) 0x2a1400 = luma source select incl. the grain (0x2a?).
- gl5 (GUIDES 16276, firmware = gl4): request stays COLOR (+1751 = 3, effect 0x0c00; G3 also +1731 = 0xa0);
  xb_h33 runs combiner 33 with context key 12 for the handler only, then G1 chroma block, G2 +toning 0,
  G3 = G2 + 1731, G4 G2 + luma init, G5 untouched.
- gl5 camera (PB061209 = 0, 210-214 = G1-5): G1 / G5 grey (Cb = Cr = 128), no grain; G2-G4 green (toning 0), no
  grain. => grain is made upstream only for a request with key 12; combiner 33's MONO config flattens chroma (with
  92 = 0x2a1400 the likely cause; the 128..152 block restore is not enough).
- gl6 (GUIDES 16196): MONO request (key 12, +1751 3); G1-3 effect 0x0c00 with combiner 33 run as COLOR (context key
  11 for the handler), G3 then 92 = 0x2a1400; G4-5 effect 0 (no combiner 33); +1731 0xa0 on 1, 3, 4.
- gl6 camera (PB061215 = 0, 216-220 = G1-5): **COLOUR + STOCK GRAIN.** MONO request (key 12, +1751 3): G4/G5
  (effect 0, no combiner 33) = natural colour with full MONO-High grain (Y hp 26.3, Cb/Cr hp ~1.9/1.2 = some chroma
  speckle), normal vignetting; G1/G2 (combiner 33 run as COLOR) = same + a white vignette; G3 (92 = 0x2a1400) green.
  => the grain is made in development for request key 12; the grey comes only from combiner 33's MONO config.
  +1731 makes no visible difference. Recipe: still COLOR dev request -> +10 = 12, +1751 = level, nothing else.
- gl7 (GUIDES 16172): that recipe; Grain 1 -> 1751 = 1, 2 -> 2, 3-5 -> 3.
- gl7 camera (PB061221-230): Grain 1/2/3 = hp 7 / 17 / 25 (Low/Med/High), back-to-back fine, profile colours fine.
  User: keep 3 stock levels. Grain gone (hp ~2) with Frame (228-229) and Glow (230).
- gl7 Art log (GLOG9): Frame = dev eff 0 (key 12, 1751 3, same as plain) + k3 0xf005 eff 0x0300 combiner 10 + final;
  Glow = dev eff 0x0400 + 0x0401 + 0x0402 c11; Star = dev eff 0 + 0x0100 / c135 0x0104 / 0x0101 (k0 key 2) / 0x0103 /
  c136 0x0106; White Edge = dev eff 0x0500 combiner 13. No grain in any. Final kind-3 request carries no grain field
  (MONO off vs high: only addresses differ; +10 12, +1091 0xa0). => grain survives only dev -> final directly.
- gl8 (GUIDES 16168): copy B = the first kind-3 stage-0 (final) request, to diff plain grain vs Frame.
- gl8 camera (GLOG10: plain G3 / Frame G3 / Star G3 / plain G0): dev requests identical (plain has a 2nd output
  1600x1200 0x0c02 at +1112..1175). KEY: plain G3's dev request is configured twice (context key 0xb, then 0xc
  after our +10 edit); with Frame/Star it is configured once (context 0xb) -> no grain. The grain needs the context
  key 12 at configuration time.
- gl9 (GUIDES 16168): xb_lg also writes context +48 = 12 when it marks the request.
- gl9 camera (PB061242-246): Art / Glow / White Edge still no grain (context 12 at the only config); plain still
  grain (hp 24). The difference is the dev OUTPUT format (+1100): plain 0x1c02 (JPEG-ready, straight to the k10
  encoder) + a 1600x1200 0x0c02 2nd output (+1112..1175); any Art Effect / Glow: 0x0c02 to memory, then an extra
  kind-3 pass (stage 0xf005, effect 0) converts to 0x1c02. => the grain belongs to the 0x1c02 output stage.
  +1751 is read by no CPU code except combiners 31/32 (never selected here) -> the image processor reads the request.
- gl10 TEST (GUIDES 16296): Grain 1/2 mark the kind-3 0xf005 effect-0 conversion pass (+10 / context 12, +1079 = 3;
  2 also +1091 0xa0), 3 the final stage-0 pass instead.

## v0.21 candidate g21 (hybrid grain) — out-g21b
- Tree om3/g21 (from gprepo: VigFix + CPU grain test 4). Grain 0..3 = Off / Low / Medium / High (xt_tab sector 9 {53,0,3}).
- Camera route (plain COLOR, Grain > 0, no Glow/Clarity (+49), no Art Effect (+50)): xb_cap stores xb_gt = min(grain,3)
  (no 0x80). Flash hook 0x604955f1 `call s_cl,[d2,a2],12` (ext2; xp now returns Z) -> block +64 xb_dev: request kind 0,
  +14 0x1000, +10 11 -> +1751 = xb_gt, +10 = 12, context +48 = 12; then jmp SEL 0x6052cf39 (reads only a0). Uses d0 d1 a1.
- CPU route (Grain with Glow/Clarity or an Art Effect): 0x80 as before; xb_wt w 1024 without Glow; xb_gs levels 1..3
  (older 4, 5 -> 3), S table 28 / 68 / 112 (= camera Low / Med / High by band-pass contrast). xb_grain TEST timing and
  K parity removed (K = 2).
- LABELS.BIN 27 labels (XL_N 27): 23..26 "Grain Off/Low/Med/High"; xb_vt slice 9 {53,0,23,3}.
- GUIDES.BIN 14964 B (< 16448 malloc cap). Emulator (V4): boots, look 1 picked, sector 9 0->1->2->3 stops at 3, labels
  Off/Low/Med/High streams 1572/1652/1620/1660 (== Python), main-1 back to 2, half-press save: LOOKS record +51 = 2, CRC ok.
- Open (camera): plain L/M/H, Glow/Frame/Star/Pin Hole/White Edge + grain, back-to-back, MONO, Grain 0, RAW edit in
  playback after a grain shot (xb_gt stays set until the next capture).
- 2026-11-06 DELIVERY MISTAKE: v0.21 candidate E1479999.BIN was copied to the card ROOT. The SD updater (hold OK at
  power-on) reads DCOLYMP/E1479999.BIN, so the camera re-flashed the gl10 file still in DCOLYMP (tag 0x588d1bd0):
  v0.21 GUIDES refused (tag 0x5822d06e) -> no Extras / labels / wheel switching. Firmware ALWAYS goes to DCOLYMP/.
- gt1 (GUIDES acaaafc8…, LABELS back to 24 / "Grain"): xb_dg writes LOOKS header +20.. per capture. Camera PB061256
  (Grain 3, nothing else): glow 0, art 0, grain 3, xb_gt 0, flags 0x80 -> took the CPU branch. Cause: `movbu (49,a1),a0`
  / `movbu (50,a1),a0` (fb 2a, AM33 extended Rn form) misread on the camera (worked in the emulator). Photo Y hp 12.2,
  Cb/Cr 0.7/0.9 (CPU grain). gt2: xb_cap uses data registers only; no fb-prefixed instruction left in the block.
- gt2 camera (PB061257/258, Grain 3 plain): xb_gt 3, flags 0, xb_dev marked, no CPU pass; Y hp 12.2 / 10.7,
  Cb/Cr ~1.8 (camera grain), fast. g21e (GUIDES 14960 B, firmware unchanged 833a7497…): diagnostics removed; user
  LOOKS.BIN header +20..31 zeroed (CRC fixed). Next: effects matrix.
- gt3 camera (user): effects + grain all OK; but with the camera route, Blacks / Whites / A-B / G-M / NR / VigFix do
  not apply (only grain shows). Known cause for Blacks/Whites: tone gate needs request key word 0x000b0000 (we set
  +10 = 12). WB / NR / Vig are capture getter overrides -> key-12 development takes them from elsewhere (not traced).
  g21f (GUIDES 15000 B): camera route only when slot +26, +27, +47, +48, +49, +50, +51, +52 are all 0; else CPU grain.
- gt4 TEST (GUIDES 14956 B, out-gt4; g21f saved as om3/xblock_g21f.s): camera route for any look without Glow/Art
  again; xb_dev writes +1751 and context +48 = 12 only, request +10 stays 11 -> does grain survive, and do tone / WB /
  NR / Vig apply?
- gt4 camera: no grain with context key 12 alone (+10 must be 12). Back to g21f logic. User: speed up the CPU grain.
- gs1 TEST (GUIDES 15144 B, out-gs1): noise strip = 2 noise rows (V + 2H buffer), fresh per band of 32 rows, each
  image row reads h at a random offset (xorshift, mask = 2^k - 1 < Hw) -> no per-row noise pass (was ~0.78 s);
  K rows per lock + FLUSH generic loop (edge: retry the pass with one row). TEST: S 68 at every level, K 2 / 8 / 16
  for levels 1 / 2 / 3, elapsed (1024 us units) -> LOOKS header +20 + 2 (level - 1), DIRTY.

## Option 1: camera grain + all settings (research) — om3/gw
- Request config fn 0x604955ed: SEL(C) -> if result: combiner config 0x60504779, format checks, 0x604980b5. Key 12
  plain dev: SEL table key 1 -> 0x6052d03d needs stage 0x0901/0x0902 (not a dev request) -> 0x6052d0c2 path.
- gw1 (pkg 986c454d…, GUIDES 15760 B, out-gw1): firmware = v0.21 + pf_save tail -> block +72 (nm_path moved to
  ext4, now full) + tone gate: request key 11, or 12 with +1731 == 0 (MONO has 0xa0). Block: camera route for any
  look without Glow/Art (TEST), xb_dev calls SEL itself and logs (GLOG 'GLG1': 4 slots x 6144, 16 records, copies
  A first sight +544, C after each dev call +2400, B at the first kind-3 call +4256, 1856 B), xb_mark slot header
  +16.. Glow Art A-B G-M Blacks Whites NR Vig Grain xb_gt flags CPU. Emulator: boot, editor, save x2 fine.
- gw1 camera (PB061284-299, Daylight WB, aligned pairs): with the tone gate fix every setting survives the camera
  grain: Blacks / Whites (tone maps identical within ±3 after registration), A-B (+5: wall Cb -8.1 G0 / -8.4 G3),
  G-M, NR Off (shadow noise ISO 12800 Y 25-45: 6.95 with grain ~ 7.2 without), Vig Off. Request after config (copy B):
  G0 vs G3 differ only at +1751 and +1148 (1 / 3). Side effect: camera-grain shots ~9-11% less chroma (Cb/Cr spread).
- g21g (GUIDES 14968 B, for firmware gw1 986c454d…): camera route for every look without Glow / Art Effect; logger
  removed; block +72 = rets (pf_save hook kept). Emulator: editor, saves fine. = v0.21 candidate (firmware gw1).
- 2026-11-06 restored user's looks: LOOKS.BIN = PROFILES.BIN (Nov 4, all 12 named looks intact) with sel 0 and header zeroed (fe1ad5a6…); card's previous LOOKS kept at om3/deliver/LOOKS-card-before-restore-20261106.BIN. Cause of damage: pf_wb captures live state into the SELECTED look at each save.
- Look saving (user: "save only on purpose", in v0.21). lk1 (pkg 6a0d0cea…, GUIDES 15204 B, tree om3/gw): ed_trig no
  longer calls pf_wb (removed); s_look no longer captures the look it leaves; ed_event on the Looks page (axis 4)
  -> lk_hold (ext1): held OK with a look selected = pf_cap into that look + dirty + refresh (no look: the reset);
  pf_cap split (pf_capto: a3 = destination); ed_pmod -> lk_pm (ext1) -> block +80 xb_lkd: '*' = COLOR k now (pf_capto
  into xb_lkbuf, pre-filled from the record) differs from its selected look; -1 -> stock defaults test.
  Emulator (L2): pick look 1, Grain edit, save -> record untouched (only sel); OK held on the Looks page (wheel) ->
  dirty, slot kept, save -> record 0 +51 = 1 only. With the cursor moved down (L1) hold did nothing. '*' camera test.
- lk2 (pkg e0af1a78…, GUIDES 15204 B): user: no reset on the Looks page at all. lk_hold without a selected look ->
  nothing (-> 1, ed_event e_ret). Emulator (M1): Looks page, no look, OK held -> Grain 1 and hue kept; Saturation page
  OK held -> full reset (hue, Extras 0). Hold INFO not possible (router gets one 0x9014 per press, hold or not);
  REC / AF-ON never reach the editor; multi-selector press / |o| close it.
- lk2 camera: (1) Looks page still shows "Reset [OK hold]"; (2) the whole-profile reset (OK held on "COLOR n", event
  0xf881) was gone: the axis byte stays 4 there, so lk_hold took it. lk3 (pkg a876a502…, GUIDES 15204 B): lk_hold acts
  only on 0x903e (low byte 0x3e at (24,sp)), else e_rst; ed_isdef returns "default" while axis == 4 (no Reset guide on
  the Looks page; side effect: no '*' there via ed_isdef with no look selected); gd_mode moved to ext3 for room
  (ext1 and ext10 now full). Emulator (N1/N2): wheel hold with look 1 -> record saved; `up` to COLOR 1, OK held ->
  0xf881 -> hue and Grain cleared (axis 4).
- User: A-B / G-M ignored under Auto WB (fine with any preset). Capture WB 0x60457940..: capture +37644 selects the
  branch; presets read 34041 / 38521, Auto WB (default branch 0x60457d22, and 0x60457ae4) reads its own fine-tune keys
  7401 / 7417 (or 7433 / 7449, by (36,sp) / capture +37677) into the same capture +37734 / +37736; a second
  population 0x618e6610.. reads them too. lk4 (pkg a278edc3…, GUIDES 15296 B): 9 Auto WB getter sites -> wb_get,
  which now takes 7401 / 7433 as A-B and 7417 / 7449 as G-M. Room in ext1: lk_hold's body moved to the block
  (+88 xb_lkh, jmp from the 16-byte flash stub; e_lk / e_ret / e_rst by defsym). Emulator: look save on the wheel,
  COLOR 1 reset fine. AWB effect needs the camera.
- lk5/lk6 (user tweaks): (1) whole-profile reset (0xf881) also clears the look selection: ed_event always jumps to
  lk_hold -> block xb_lkh (0xf881: LIDX k = 0, e_rst; 0x903e on axis 4: save; else e_rst). (2) Extras dial dead
  clicks past a slice's max (the dial widget's index ran on; ed_set refusing or clamping did not help): pf_cnt /
  pf_vbi now give Extras cells (928 + 12k + slice, axis 3, EMARK) their xt_tab range via block +96 xb_cv / +104
  xb_vb; both rewritten in ext1, old copies removed (ext10, ext8). Room: wb_get's body moved to the block (+112
  xb_wb; 19-byte flash stub, stock value without a block). s_x clamps instead of refusing. lk6 (pkg d595455b…,
  GUIDES 15740 B). Emulator (S1): Looks dial 1, 2, back 1; Grain 1, 2, 3, 3, 3 then -1 -> 2 at once; Blacks -2..1
  and back; Saturation page fine; save ok. (3) "COLOR n" -> look names: deferred to v0.22 (several bitmap sizes and
  '*' variants, name pictures at those sizes, heap space).
- lk6 camera: REBOOT at every half-press. Not reproducible in the emulator (no capture / AE pipeline there). Suspect:
  wb_get's body running from the code block (heap) for the WB fine-tune reads at S1 (pipeline params / AWB, likely
  another core). lk7 (pkg 4405d38d…, GUIDES 15596 B): wb_get back in flash, instruction for instruction as lk4
  (camera-proven); room from pf_is (111 B) -> block xb_pf; pf_cnt / pf_vbi = stubs (ids 928..975 only -> block +96 /
  +104, else stock); s_x refuses again (the dial range makes clamping moot). Emulator (T1): Looks dial, Grain stops
  at 3 and comes back at once, Blacks, wheel save, COLOR 1 reset (look cleared), save. Lesson: hooks on capture /
  AE paths stay in flash or proven block entries; do not move them to the block without a camera test.
- lk7 camera: no reboot; but switching Natural / MONO -> COLOR hangs ~1 s, goes black, then COLOR (also with no look).
  With a mismatched GUIDES (block not loaded) the hang is gone -> block. Switching to COLOR opens the wheel editor:
  its children build their lists = 12 pf_cnt + 127 pf_vbi calls, now all into the block (uncached heap: every
  instruction fetch from DRAM). lk9 (GUIDES 15664 B, firmware = lk7): entries +96 / +104 go through trampolines to the
  cached alias (-0x40000000) of xb_cv / xb_vb, which only call block code (xb_pf, xb_xt, xb_p). NOT for code that
  calls the firmware: its PC-relative fields are relocated for the uncached address (lk8 ran xb_lkd cached ->
  pf_capto call landed at 0x2081fe97, emulator trap). Emulator (X9): editor open 127 vbi via the cached path, Looks
  dial, Grain range, wheel save, COLOR 1 reset, save all fine.
- lk9 camera: still hangs / looks like a reboot into COLOR. tA (GUIDES-only test, out-tA): xb_cv / xb_vb answer nothing (stock lists) to split count/vbi from the rest.
- tA camera: no restart when count/vbi go stock -> the dial-range answers cause the COLOR switch restart. lk10
  (GUIDES 15640 B, firmware lk7): xb_cv / xb_vb rewritten frameless (one 4-byte call slot) around a leaf xb_cell
  (P, axis 4 Looks 12 o'clock / axis 3 Extras cell with marker), cached trampolines, no firmware calls. Theory:
  stack depth in the switch path (lk7 / lk9 added ~48 B of frames). Emulator (A10): Looks dial, Grain range, Blacks,
  empty sectors, wheel save, COLOR 1 reset, save fine.
- lk10 camera: COLOR switch fine (user confirmed). => v0.21 candidate = firmware lk7 (pkg 4405d38d…) + GUIDES lk10
  (0b936448…), LABELS gt1 (73a28cb9…, 24 labels), source tree om3/gw.

## COLOR 2-4 whole-profile reset bug (user report on lk7 + GUIDES lk10)
- Report: hold OK on "COLOR n" (n = 2..4) -> only the stock Saturation wheel, INFO shows no other pages, until another
  mode is selected. COLOR1 fine.
- Emulator (pp/session_ed1.mjs: 'right' in the picture-mode list = next COLOR; snap now logs EDK; vals adds 2197+k,
  2201+k): NOT reproduced on COLOR2/3/4, with or without edits, look selected, from pages 0/1/3/4, the user's own
  card files (LOOKS 8d2701f3…, BUNDLES fe109ce4…), double hold, half-press after. Reset sets 2197+k and 2201+k to 1.
- Diagnostic gdx (GUIDES-only 660aa498…, 16388 B, flash unchanged): block logs 'K' (each k_ad = k_go passed its checks:
  k, AXIS, EDK, 2201 value, final ALL state), 'H' (xb_lkh: event, AXIS, EDK, LIDX), 'C' (editor key, children id bits,
  first id), 'S' at the save -> OM3MOD/GLOG.BIN (8 + 48 x 8 B). Decoder: scratchpad glog.py. Emulator: records as
  expected. No K after the H/C on the camera = k_go rejects (children / PVAL); K with final 255 stuck = ALL state.
- Camera log (gdx): one reset (COLOR2, H/C ok, children fff), then K records stepping pages normally: bug not seen.
  "Reset all of them" = COLOR3/4 were already blank (BUNDLES.BAK). User's real complaint: the '*'.

## lk11 (tree gz; pkg 9c423edb…, GUIDES bdbb61f1… — block relinked, pair them): '*' = differs from OM factory defaults
- User rule: every wheel at the OM factory default -> no '*'; any change -> '*' (with or without a film).
- ed_pmod: lk_pm (look compare, block +80 xb_lkd) dropped; clr d3 + stock loop through ed_isd0 = ed_isdef that
  also compares on the Looks page (d1 = 1; ed_isdef's own callers d1 = 0 keep "default" there: no Reset guide).
- Film 0 ("none") wrote 0 to the 18 camera settings: COLOR2-4 factory defaults are not 0 (COLOR2 sat 1,1,0,0,0,0,
  1,1,0,0,1,1, tone 3/0/-3 on 979..981) -> '*' after film 0. pf_put neutral now = pf_dflt (ext1): stock_default
  0x60b86e44 (facade +156 stock; ed_default reads 0 on H/L/Looks pages) per id.
- Emulator (pmod probe = call 0x6129ba07 per picture mode; dflt:ADDR probe): reset -> 0; film 1 -> 1; film 0 -> 0
  with factory values; Hue / Extras edit -> 1, edit back -> 0; Looks page shows it too.

## lk12 (tree gz2; GUIDES d991fecd…, firmware = lk11 9c423edb… unchanged): COLOR4 '*' after the reset
- Camera: COLOR4 keeps '*' after "COLOR 4" hold-OK reset. Emulator (film on COLOR4, reset): 964 (12 o'clock) = 0, not
  its factory -4. Cause: the reset ran with the children still holding the Looks page dial list (0..5); the stock
  reset's -4 came back clamped to 0. COLOR1-3 12 o'clock defaults (0, 1, 4) are inside 0..5. Same risk for page
  resets from Extras (slice ranges).
- Fix (block only): xb_lkh's resets jump to xb_rpre: page != Saturation -> AXIS 0, children 1..12 re-read (REFRESH
  0x611b20ea, stock lists), then E_RST (puts the page back and re-reads as before).
- Emulator: COLOR4 film -> reset -> -4,0,0,0,-1,-1,-1,0,0,0,0,-4, '*' 0, INFO pages cycle; Extras-page reset on
  COLOR3 -> factory 4,4,4,4,4,3,...; Hue/Extras page resets keep the film selection (and its contrast/tone) -> '*'.

## Space audit (2026-11-06, after v0.21)
- Our flash space: 10 section tails (ext1..ext10) inside the loader's copy ranges, 7492 B in all; used 7372 B
  (ext1 1742/1744, ext4 1776/1776, ext10 1232/1264, ext6 600/608, ext5 572/576, ext3 481/492, ext8 461/512,
  ext9 379/384, ext2 83/88, ext7 46/48): ~120 B left. GUIDES.BIN 15676 B of the 16448 B malloc cap (code block 3744 B,
  the rest guide pictures); uncached pool ~45 KB shared.
- Loader 0x60045ed5: copies dest..end for sections 1..10 (dest/src from table 0x60029b28, end from the jump table at
  0x60045e6c: one `mov imm32` each at 0x60045e84/8c/c4/94/b4/9c/a4/bc/ac/cd, the ONLY references to those values),
  length = end - dest through 0x600232d1 (flags 0x10200).
- Between each loaded end and the next section start the file is all FF (never loaded): s2 270336 B, s3 32768,
  s4 296960, s5 2048, s6 1005568, s7 342016, s8 149504, s9 342016 = 2441216 B (~2.33 MiB). s10: 0x61aa4800..0x62020fe0
  holds data at 0x61aad000..0x61aaddc0 (referenced from boot code 0x600211d8 etc.) — leave s10 alone.
- Emulator (pp/gapprobe.mjs): sentinel 0xA5 written over every gap before boot; boot + half-press + editor + INFO
  pages + playback + menus wrote 0 bytes in any gap (aliases 0x60/0xa0 verified to share memory). Static scan: no
  aligned references to the gaps besides the end constants (unaligned code-byte false positives only).
- Not yet covered: video recording, Wi-Fi/Bluetooth, USB, the SD updater — a camera probe is needed before using a gap.
- Unused in our own code since lk11: block xb_lkd + xb_lkbuf (~0x377 B incl. 64 B buffer), xb_sv stub.
- GX1 space test (tree om3/gxt, out-gx1; pkg see outputs/gx1, GUIDES rebuilt for it): section 6 end 0x60f49800 ->
  0x60f4a800 (loader word 0x60045e9c); 0x60f49800.. = 'GXT1' header + probe + 888-word pattern. pr_hook calls
  gx_go (ext8, +26 B) -> gx_probe when the header is loaded -> ed_trig. Probe: same gate as saves; pattern check;
  one gap sum per pass (round robin s2..s9, s6 from 0x60f4a800; round 0 = baseline); writes OM3MOD/GAPTEST.BIN
  (112 B: GXR1, passes, bad, npat, base[8], last[8], changed[8]) every pass. Emulator: 25 passes, bad 0, changed 0.
  No GAPTEST.BIN on the camera = the extension was not loaded (loader change ineffective).

## v0.22 Sharp (2026-11-07; camera-tested)
- Details in docs/DEVELOPER_NOTES.md ("v0.22 Sharp"). Capture read 0x603e767f (key 0x8119) -> s_nr -> block xb_nr;
  slot +54 / record +52, -5..+2, -5 sent as -7. Column builder 0x611bd814 / switch table 0x61533520: COLOR 1-4
  -> pm_color (5 rows, Sharpness dropped). Camera: Off clearly softer than 0; quick grain fine; row removal fine.
- Video: not traced. The hook is the stills capture read; video most likely keeps the hidden stock Sharpness.

## Picture-mode sliders research (2026-11-07; emulator only; branch feature/v0.23-alpha-profile-sliders)
- COLOR column items (list 0x61530758, count via the builder's switch): 111 Picture Mode, 5397 wheel, 5398 Highlight
  & Shadow, 5399 Shading, 7 Sharpness, 8 Contrast. Item table 0x6154c2a8 (17 x 40 B, keyed by item id; slider items
  7 / 8 / 59 / 5399 have a type-4 title field: string ids 256 / 91 / 227 / 4809). Column list object: count +92,
  cursor +94, item ids array at +108 (vtable 0x61533620: +8 count 0x611b405c, +16 item 0x611b4083).
- Slider rows read the *virtual* id in the left column (GetValue(7) / (8) / (1016)) and the resolved id (904+k /
  908+k / 912+k) in the bar: the bar's value list comes from facade +28 count and +32 value-by-index, +40
  selectable (0x60b86a01, word 0x60e5749c) per value; changes go through facade SetValue (our .hook_set site).
- Left-column readout: 0x611d1697 (sign) and 0x611d1708 (digit) look the value up in per-item tables: 5 entries
  (-2..+2) for 7/8/59 (0x6154c648 / 0x6154c670 ...), 11 entries (-5..+5) for 5399/1011/5397 (0x6154caa0 /
  0x6154caf8). Out-of-table values draw blank.
- Bar setup 0x611d0f99: ends per item (7/8/59: a3 = -2, d0 = 2 at 0x611d106a; 5399: -5 / 5), dot x = centre +
  value x 155 px (0x611d10ff `mul 155`; Shading's path 62 px). The "-" / "+" grey out at value == min / max.
  0x612af358: 5 vs 11 steps per item (likely touch mapping; not patched).
- Result (emulator): the Sharpness row as the Sharp slider -5..+2 with correct readout, ends, dot; in sync with the
  Extras wheel; looks and the hold-OK reset update it; Contrast untouched.
- MISTAKE (do not repeat): the slider code went into ext11 = 0x60133000, inside the FF run 0x60128e40..0x60134000 at
  the end of the image's first part. The space audit above says the FF stretches between sections are NOT loaded
  on the camera (the emulator maps the whole image, so it hides this). That build must not be flashed. Only the
  ext1..ext10 tails (inside the loader's copy ranges) are proven; the gap-space probe (branch
  experiment/firmware-space-probe) is the way to get more.
- Calling convention lesson: `call f,[regs],N` writes the return address at (0,sp) of the caller, so a CALLS-entered
  hook that pushes registers with movm must `add -4,sp` before its own `call` (and undo it), as pf_cnt does.
  Also `call` overwrites MDR: save it around calls in a `rets` routine.


## Session wrap-up (2026-11-07)
- Released: v0.22 (Sharp, camera-tested; film sims carry Sharp). Control Panel live with it.
- Pushed branches: `feature/v0.23-alpha-profile-sliders` (Sharp on the Sharpness row; emulator only; DO NOT FLASH:
  code in unloaded space, must move first), `experiment/firmware-space-probe` (GX1 probe on v0.21; not yet run on
  the camera), `experiment/grain-cpu-colour` (parked grain test 4). Old `v022-sharp` branch on GitHub is stale
  (same as v0.22); the owner may delete it.
- Repo now holds the whole lab: this notebook, tools, emulator scripts, archives, `CLAUDE.md`,
  `research/setup.sh` (asks for the owner's firmware file; tested from scratch), `docs/FILM_SIMULATION_ROADMAP.md`,
  `docs/PHOTO_TO_LOOK.md`. The claude.ai Project "Om3 Firmware Build" has matching custom instructions.
- The official firmware file stays on the owner's Mac (too large for chat or Project uploads, 30 MB limit): link the
  session to the Mac or have it attached.
- Next (see the roadmap): 1. the owner runs the firmware-space probe on the camera; 2. emulator research on split
  toning and coloured glow; 3. WB mode / exposure compensation per look; 4. move the slider code to proven space.
