# Caduceus for OM-3 v0.25

**Fast colour film grain with every setting.** Film Grain on COLOR 1–4 and films is now added by the camera's image
processor as the photo is developed, in full colour, and saves as fast as a photo without grain: with Shading, Glow /
Clarity and Frame too.

- **Fast colour grain:** Low / Med / High, clearly three steps, no change in brightness or colour. It works the way the
  camera's Grainy Film Art Filter adds its grain, kept in colour.
- **Shading is back** on the Picture Mode screen (v0.24.1 hid it), and works with grain.
- **New Picture Mode rows:** **Glow / Clarity** (−5 Glow … +5 Clarity) and **Frame** (Off / On), after Shading.
- **Art Effects are Frame only:** Star Light (slow), Pin Hole and White Edge are gone (Shading does the dark corners).
  A look that still has one of them shows Frame Off.
- **One slower combination:** Glow / Clarity **and** Frame **and** Grain together use the older grain (about 3 s more
  per photo). Every other combination is as fast as normal.
- Everything from v0.24.1 stays: films in the Picture Mode list, changes kept per film, the Picture Mode rows.
- Camera-tested.

**Copy to the card:** `DCOLYMP` (flash it) and both `OM3MOD` files, `GUIDES.BIN` (made for this firmware: always copy
it with it) and `LABELS.BIN`. Keep your `LOOKS.BIN`, `EDITS.BIN`, `NAMES.BIN` and `BUNDLES.BIN`. Looks exported from
the Control Panel with "v0.25 or later" keep their Shading and save Art Effect as Frame or Off.

**Going back to v0.24.1 or older:** flash that version with its own `GUIDES.BIN`; your files still work.

Make it: run the launcher and press Return (or `python3 firmware/patch.py --release v0.25`). The files here are the
patch (only the bytes Caduceus for OM-3 adds; no OM firmware), the card files and the expected checksums. Full list of
changes: [CHANGELOG](../../CHANGELOG.md#v025).
