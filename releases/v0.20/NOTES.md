# Caduceus for OM-3 v0.20

The Color Profile wheel now matches Caduceus: **Film** → Saturation → (All) → **Hue** → **Light** → **Extras** → Film.

- **Film** page (was Looks): five looks per COLOR, as before.
- **Extras** page, sector 1 at 12 o'clock then clockwise: **1 NR** (Camera / Std / Low / Off, per look, applied at
  each photo) · **2 Glow ← → Clarity** (−5..+5) · **3 WB A/B** · **4 WB G/M** · **5 Art Effect** (Star Light,
  Pin Hole, White Edge, Frame) · **6 Blacks** · **7 Whites**. The label next to the value names the sector
  (Glow, Clarity, A, B, G, M, NR Low, Frame …).
- Glow and Art Effects show in **live view**. The **Frame** effect is now a clean **white** border.
- INFO changes page from any slice; hold-OK reset and the `*` include the Extras.
- Camera-tested.

**Copy to the card:** `DCOLYMP` (flash it) and both new `OM3MOD` files: `GUIDES.BIN` (page labels + the Extras code,
made for this firmware: always copy it with it) and `LABELS.BIN` (the Extras labels). Keep your `LOOKS.BIN`,
`NAMES.BIN` and `BUNDLES.BIN`.

**Coming from v0.16–v0.18:** rename `PROFILES.BIN` to `LOOKS.BIN` (same format); v0.20 no longer reads `PROFILES.BIN`.

Make it: run the launcher and press Return (or `python3 firmware/patch.py --release v0.20`). The files here are the
patch (only the bytes Caduceus for OM-3 adds; no OM firmware; the white frame pictures are drawn by the patcher), the
card files and the expected checksums. Full list of changes: [CHANGELOG](../../CHANGELOG.md#v020).
