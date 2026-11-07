# Caduceus for OM-3 v0.21

Film grain on colour photos, looks you save on purpose, and a `*` that means "not factory".

- **Grain** (Extras sector 9): Off / Low / Med / High, the camera's own Monochrome grain on COLOR photos, with every
  other setting kept. **With Glow / Clarity or an Art Effect in the same look, each photo takes about 3 seconds
  longer to save and fast sequential (burst) shooting isn't possible**: the grain is then added in software after
  the photo is developed. On its own, or with the other Extras, it costs no time.
- **VigFix** (Extras sector 8): the lens's vignette correction off for photos with a look (Vig Off), or as your menu
  setting (Vig Cam).
- **Hold OK on the Film page saves** your changes into the selected look. Turning to another look without that drops
  them. Hold OK on the other pages resets the wheels; hold OK on "COLOR n" resets the whole COLOR to its factory
  settings and the Film page to 0.
- The **`*`** means something differs from the camera's factory settings, on every page. Film 0 now loads each
  COLOR's own factory settings.
- WB A/B and G/M now work with **Auto WB**. The Extras dial stops at each sector's ends.
- Camera-tested.

**Copy to the card:** `DCOLYMP` (flash it) and both `OM3MOD` files, `GUIDES.BIN` (the Extras code, made for this
firmware: always copy it with it) and `LABELS.BIN` (adds the VigFix and Grain labels). Keep your `LOOKS.BIN`,
`NAMES.BIN` and `BUNDLES.BIN`.

**Going back to v0.20 or older:** they ignore a `LOOKS.BIN` with Grain or VigFix set; save it from the Control Panel
with "v0.20 or older" chosen in Export.

Make it: run the launcher and press Return (or `python3 firmware/patch.py --release v0.21`). The files here are the
patch (only the bytes Caduceus for OM-3 adds; no OM firmware; the white frame pictures are drawn by the patcher), the
card files and the expected checksums. Full list of changes: [CHANGELOG](../../CHANGELOG.md#v021).
