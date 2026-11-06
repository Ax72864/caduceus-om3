# Changelog

Versions are named v0.N from v0.18 on. Earlier builds were called "test N" while they were tried on the camera; the
same number is used here (test 17 = v0.17).

## v0.20
The Color Profile wheel now matches Caduceus for the E-P7: a **Film** page, the colour pages and one **Extras** page
with the look's effects. Camera-tested.

**Pages**
- INFO order: **Film** → Saturation → (All) → **Hue** → **Light** → **Extras** → **Film**. The **Looks** page is now
  called **Film** on the camera (the card file is still `LOOKS.BIN`). The **WB/BW** page is gone: its four values
  moved onto the Extras page.
- **INFO changes page from any slice.** Before, INFO away from 12 o'clock switched to "all colours" instead. The
  editor now reads the camera's own "all colours" state the way the stock INFO does (the camera keeps it in one of two
  settings, depending on the slice it was entered from), so Saturation → All → Hue also works from any slice.

**Extras page** (sector 1 at 12 o'clock, then clockwise)
- **1 NR**: the camera's noise reduction for photos with this look: 0 Camera (your menu setting), 1 Standard, 2 Low,
  3 Off (most texture). It is applied at every photo (the stills Noise Filter reads at capture and in the photo's
  recorded settings) and follows a profile switch; the menu setting itself is never changed.
- **2 Glow ← → Clarity**: −1..−5 glow, the camera's Soft Focus passes on a COLOR photo with Caduceus's five strengths
  (−5 is about the stock Soft Focus); +1..+5 clarity, the same passes with a negative blur weight (an unsharp mask
  with a large radius, as Caduceus). 0 is off.
- **3 WB amber / blue** and **4 WB green / magenta** (−5..+5), added to the camera's own white balance.
- **5 Art Effect**: 1 Star Light, 2 Pin Hole, 4 White Edge, 5 Frame on COLOR photos without an Art Filter (the
  numbers are Caduceus's; 3 does nothing).
- **6 Blacks** and **7 Whites** (−5..+5), the ends of the tone curve.
- **8**: reserved (Caduceus's VigFix is not built for the OM-3 yet).
- **Dial labels:** on Extras, the label next to the value (stock: "Vivid") names the sector and what its value does:
  NR / NR Std / NR Low / NR Off, Glow / Clarity / Glo/Cla, A / B / A/B, G / M / G/M, Art Off / Star / Pin Hole /
  W. Edge / Frame, Blacks, Whites. Other pages keep "Vivid". From the new `OM3MOD/LABELS.BIN`.
- Every Extras value is part of the look: it saves into `LOOKS.BIN` (record bytes +47..+49) and `BUNDLES.BIN`, loads
  with a Film pick, counts for the `*`, and is cleared by the hold-OK reset.

**Live view**
- Glow and the Art Effects now show in live view on COLOR profiles, through the same switch the camera uses for Art
  Filter previews. Clarity shows only in the saved photo (as in Caduceus). Movies recorded with such a look get the
  effect too.

**White frame**
- The Frame Art Effect draws a clean **white** border of the stock size instead of the rough black film edge. The
  firmware's 13 frame pictures are replaced by our own JPEGs (white outside the stock window, nothing copied from OM),
  so this applies everywhere the Frame effect is used, Art Filters included.

**Fixes**
- Hold-OK reset works on the Extras values, and from any page (before, a look whose only change was an Extras value
  looked unchanged, so neither the `*` nor the reset reacted).
- The `*` appears for Extras changes.

**Card files and upgrading**
- New `OM3MOD/GUIDES.BIN` (labels "Extras" and "Film") that also carries the **Extras code**: the firmware had no room
  left, so the effects run from a block of code at the end of this file, loaded and checked at the first half-press.
  The block only runs on the firmware it was built with: always copy the release's `GUIDES.BIN` with its firmware.
  Without it the editor still works and saves the Extras values, but the effects are off.
- New `OM3MOD/LABELS.BIN` (the Extras labels; optional).
- `PROFILES.BIN` is no longer read (v0.19 converted it): coming from v0.16–v0.18, rename it to `LOOKS.BIN`.
- Looks saved by earlier versions load with every Extras value at 0. A test-build card with "Frame" at 1 shows Star
  Light now: set sector 5 to 5.

**Control Panel**
- OM-3 mode has the Extras: **NR** (Camera / Std / Low / Off), **Glow ↔ Clarity** and **Art Effect** (Off, Star Light,
  Pin Hole, White Edge, Frame), saved in `LOOKS.BIN`; the preview shows glow and clarity. Caduceus looks bring their
  NR, glow / clarity and Star Light / Pin Hole along (a halation glow becomes a plain glow; Blur is left out). Text
  says Film and Extras.

**Installer and project**
- `firmware/patch.py` makes v0.20 including the white frames (it draws the 13 pictures itself and patches only those
  bytes of the resource component) and writes `GUIDES.BIN` and `LABELS.BIN` to `OM3MOD`. Older releases build as
  before. `tools/mkpatch.py` makes a release's `patch.json`; `firmware/build.py` builds everything from source,
  byte-identical to the release.

## v0.19
- **Profiles are now Looks**, matching Caduceus: the wheel page is labelled **Looks** (new `GUIDES.BIN`) and the
  bank is `OM3MOD/LOOKS.BIN` (same format). With no `LOOKS.BIN` yet, the camera reads the `PROFILES.BIN` of
  v0.16–v0.18 and the next save writes `LOOKS.BIN`. The Control Panel's OM-3 mode says Looks and exports
  `LOOKS.BIN` (plus a `PROFILES.BIN` button for v0.17–v0.18).

## Control Panel (no new firmware)
- The OM-3 Look Lab is now the **Caduceus Control Panel**, the same tool as Caduceus for the E-P7, with a camera
  switch at the very top: **Olympus PEN E-P7** shows cakelesscoder's panel unchanged, **OM SYSTEM OM-3** the version
  for this firmware (COLOR 1–4 × profiles 1–5, OM-3 ranges, Contrast / Sharpness / Shading, `PROFILES.BIN` +
  `NAMES.BIN` export, Caduceus looks converted). Profiles from the old Look Lab are brought over. Works with v0.17+.

## v0.18
- The Color Profile wheel opens on the **Profiles** page, with the selected profile's name. INFO order unchanged:
  Profiles → Saturation → (All) → Hue → Light → WB/BW → Profiles. Camera-tested.

## v0.17
- **Profile names** under the wheel on the Profiles page ("Velvia", "Empty" …), from `OM3MOD/NAMES.BIN`, drawn by
  the Look Lab in the camera's own label style. Camera-tested.

## v0.16 (test 16 / 16b)
- **Profile bank:** 5 profiles for each of COLOR 1–4 in `OM3MOD/PROFILES.BIN`, each holding every wheel plus
  Contrast, Sharpness, Shading and Shadows/Midtones/Highlights. Profiles page dial 0–5 (0 = neutral); changes made on
  the camera are kept in the selected profile and saved at the half-press. Camera-tested.

## v0.15
- Per-COLOR looks page (wheels only); replaced by the profile bank in v0.16.

## v0.11
- On-camera **Hue**, **Light** and **WB/BW** pages (A/B, G/M, Blacks, Whites) for COLOR 1–4, saved to
  `OM3MOD/BUNDLES.BIN`; page labels from `GUIDES.BIN`. Camera-tested.
