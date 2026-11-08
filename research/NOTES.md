
### 2026-11-07 — Sliders test 2: code moved into proven space (emulator only)

- `.ext11` (the slider code, 560 B) moved from the base-image FF tail (0x60133000, unloaded on the camera) to
  0x60f49800, the start of the 64 KiB section-6 extension. build.py raises the loader end word 0x60045e9c from
  0x60f49800 to 0x60f59800, the exact patch the camera-tested GX2 probe used. Image diff against test 1: only the
  loader word, the moved code and the branches/pointers into it.
- Emulator: Sharpness row on COLOR 1 goes 0 → −3 → −5 (minus greyed) → +2 (plus greyed), readout and dot right;
  Contrast row still ±2. **Emulator only.**
- Package: E1479999.BIN sha256 5cc25974…, GUIDES.BIN a1927a32…, LABELS.BIN unchanged (v0.22, 6932bfb8…). Put on the
  owner's card and checked by checksum. Camera result: pending.
