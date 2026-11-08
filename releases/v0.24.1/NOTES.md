# Caduceus for OM-3 v0.24.1

Replaces v0.24 (withdrawn: with Film Grain High the camera restarted when taking a picture). Everything v0.24 added,
with that fixed and the Shading row hidden.

- **Films in the list:** after COLOR 1–4, Picture Mode lists every film on the card as **FILM 1, FILM 2, …**; the
  film's **name** is the big title, and the quick menu and the shooting screen show **FILM n**. Choosing a film loads
  it onto its COLOR.
- **Changes are kept** per film and per COLOR 1–4 (the camera keeps them in the new `OM3MOD/EDITS.BIN`). **Hold OK**
  on a film puts it back as built, on COLOR n back to the factory. A **`*`** means changed.
- **Picture Mode rows:** Blacks, Whites, A-B, G-M, Sharpness (−5 Off..+2), Noise Filter (Off / Low / Std / High),
  Vignette Correction and Film Grain sit on the camera's Picture Mode screen next to Contrast and Highlight & Shadow.
  The colour wheel row is **HSL**: Color → Color All → Hue → Luminance.
- **Fixed:** Film Grain High no longer restarts the camera.
- **Hidden for now:** the **Shading** row (Shading together with Film Grain turned the photo black and white).
  **Before flashing**, set Shading back to 0 on COLOR 1–4 if you changed it: after flashing you can't see or change
  it. Looks exported from the Control Panel for v0.24.1 leave Shading at 0.
- **Switched off for now:** Glow / Clarity and Art Effects (with them grain can only be added slowly; they stay in
  your looks). Grain with everything else is as fast as normal.
- Camera-tested.

**Copy to the card:** `DCOLYMP` (flash it) and both `OM3MOD` files, `GUIDES.BIN` (made for this firmware: always copy
it with it) and `LABELS.BIN`. Keep your `LOOKS.BIN`, `NAMES.BIN` and `BUNDLES.BIN`; the camera adds `EDITS.BIN`.
Looks exported from the Control Panel with "v0.24.1 or later" can use Noise Filter High.

**Going back to v0.22 or older:** flash that version with its own `GUIDES.BIN`; your `LOOKS.BIN` still works (save it
again from the Control Panel for that version if it uses Noise Filter High). `EDITS.BIN` is ignored there.

Make it: run the launcher and press Return (or `python3 firmware/patch.py --release v0.24.1`). The files here are the
patch (only the bytes Caduceus for OM-3 adds; no OM firmware; the white frame pictures are drawn by the patcher), the
card files and the expected checksums. Full list of changes: [CHANGELOG](../../CHANGELOG.md#v0241).
