# Caduceus for OM-3 v0.22

Sharpness as part of the look.

- **Sharp** (Extras sector 10): the camera's sharpening for photos with a look, **−5 to +2 in the camera's own
  numbers**. **0 is the camera's normal**, +1 / +2 crisper, −1 and −2 as in the stock menu, **−3 and −4 softer than
  the menu goes**, and **−5 = Off** (no sharpening; the label reads "Sharp Off"). Works with Grain and every other
  Extra.
- The camera's own **Sharpness row is gone from the COLOR 1–4 screen** (Contrast is now the last row), so the two
  never overlap. Its stored value is ignored for COLOR photos and no longer counts toward the `*`.
- Each look keeps its Sharp in `LOOKS.BIN`. The Control Panel's film sims now set it too.
- Camera-tested.

**Copy to the card:** `DCOLYMP` (flash it) and both `OM3MOD` files, `GUIDES.BIN` (the Extras code, made for this
firmware: always copy it with it) and `LABELS.BIN` (adds the Sharp labels). Keep your `LOOKS.BIN`, `NAMES.BIN` and
`BUNDLES.BIN`.

**Going back to v0.21 or older:** they ignore a `LOOKS.BIN` with Sharp set; save it from the Control Panel with
"v0.21" (or "v0.20 or older") chosen in Export, which puts the sharpness back in the camera's Sharpness setting.

Make it: run the launcher and press Return (or `python3 firmware/patch.py --release v0.22`). The files here are the
patch (only the bytes Caduceus for OM-3 adds; no OM firmware; the white frame pictures are drawn by the patcher), the
card files and the expected checksums. Full list of changes: [CHANGELOG](../../CHANGELOG.md#v022).
