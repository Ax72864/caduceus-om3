
### 2026-11-07 — Sliders test 2: code moved into proven space (emulator only)

- `.ext11` (the slider code, 560 B) moved from the base-image FF tail (0x60133000, unloaded on the camera) to
  0x60f49800, the start of the 64 KiB section-6 extension. build.py raises the loader end word 0x60045e9c from
  0x60f49800 to 0x60f59800, the exact patch the camera-tested GX2 probe used. Image diff against test 1: only the
  loader word, the moved code and the branches/pointers into it.
- Emulator: Sharpness row on COLOR 1 goes 0 → −3 → −5 (minus greyed) → +2 (plus greyed), readout and dot right;
  Contrast row still ±2. **Emulator only.**
- Package: E1479999.BIN sha256 5cc25974…, GUIDES.BIN a1927a32…, LABELS.BIN unchanged (v0.22, 6932bfb8…). Put on the
  owner's card and checked by checksum. Camera result: pending.

### 2026-11-07 — Sliders test 2 camera result; tests 3 and 4
- **Camera-tested (test 2):** the Sharpness row works on COLOR 1-4 with the code in the section-6 extension. Owner:
  +2 did not reach the right end (one 62 px step for the whole -5..+2 bar), which looked off.
- Test 3 (emulator only): sl_dot splits the bar at 0 (on the centre mark): below 0 steps 62 px (-5 at the left end),
  above 0 the stock 155 px (+2 at the right end).
- Test 4 (emulator only): Grain on the camera's own **Film Grain Effect** row (item 5400, the MONO 1-4 row: string
  2778, choices Off / Low / Medium / High, 2779..2782). Added to pm_list after Contrast.
  - The row's setting id per picture mode: 0x611c308a searches table 0x6153670c ({mode, id} x 4: MONO 57/58/59/65 ->
    999..1002), COLOR got 0. build.py points it at gr_tab (8 entries: the stock four + COLOR 54/55/56/64 -> our ids
    GRB 0x7e00 + k) and raises its count (0x611c30b6) to 8.
  - The left column's id lookup 0x611d1963 (table 0x6154cc80, count shared with item 131 at 0x611d19b2): hook_lc at
    0x611d1982 sends 5400 to gr_tab with count 8 (item 131 untouched). Its icon value is GetValue(998) (0x611d0b6d,
    MONO "the mode's grain"): sl_slot answers 998 on COLOR 1-4 like 7.
  - Facade handlers take GRB..GRB+3: count 4, value by index 0..3, selectable 0..3, get / set slot +53 (the Extras
    Grain byte, then s_dirty). The stock choice row wraps High -> Off on the dial (stock behaviour).
  - Emulator: Off / Low / Med / High selectable, title follows ("Film Grain Effect Medium"), the value stays when
    leaving and coming back, the left-column icon follows; Sharpness and Contrast unchanged.
- Package test 4: E1479999.BIN f4e07404…, GUIDES.BIN c8e8ec7c…, LABELS.BIN unchanged (6932bfb8…). On the owner's card,
  checked by checksum. Camera result: pending. Not checked: MONO 1-4's own grain row (its table entries are kept
  first, unchanged), touch on the row, and whether the photo grain matches the row (same byte as the Extras wheel).
- Strings: the camera's text table is in decoded section 01 (UTF-16LE); index at file offset 0x24a0ac, u32 entries
  minus 0xa4f22020 = the string's file offset (256 Sharpness, 91 Contrast, 227 Saturation, 4809 Shading Effect).
