# Changelog

Versions are named v0.N from v0.18 on. Earlier builds were called "test N" while they were tried on the camera; the
same number is used here (test 17 = v0.17).

## Control Panel updates after v0.21
No firmware change: these work with v0.21 as released.

- **Film sims:** a new button (and "From the film sims…" on an empty number) with 60 film looks, one for each film,
  in five groups: Fujifilm simulations, slide film, colour negative, instant film and cinema print. They're our own
  looks, designed by hand from what each film is known for and tuned on the sample photos, using only the OM-3's
  colour settings (Hue, Light and Saturation per colour, Highlights / Shadows / Midtones, Blacks / Whites, Contrast,
  WB shift). No grain, Glow / Clarity or Art Effects: add those yourself if you like. Preview on your photo, add to
  any empty number, remove like any look.
- The grain preview is gentler, closer to how the photo looks on screen.
- **New sample photos** in OM-3 mode: public-domain (CC0) photos at higher resolution, picked for skin, strong
  colour, greens, blues, night light and sunset, next to the colour-frames photo. The preview is sharp on Retina
  screens and the right size in Safari.
- **Lists:** save all four COLORs' looks as a named list and switch between lists (Save as…, Rename, Delete above
  the looks). The list you're on is the one you edit; the looks you already had are the list "Default". When all 20
  numbers are used, adding a film sim asks first and then lets you pick the look to replace.
- **New standard set** (first visit, and New › Reset looks to standard): one theme per COLOR, all film sims except
  Bleach Bypass, with no grain, Glow or Art Effects. COLOR 1 Fujifilm (Classic Chrome, Classic Neg, Reala Ace, Eterna, Pro Neg Std),
  COLOR 2 slide (Velvia 50, Kodachrome 64, Ektachrome E100, Provia 100F, Astia 100F), COLOR 3 negative (Portra 400,
  Portra 160, Ektar 100, Gold 200, Fuji 400H), COLOR 4 cinema and instant (CineStill 800T, Kodak 2383, Vision3 250D,
  FP-100C, Bleach Bypass). Existing lists are not changed.
- Film sims already in the list you're on are marked in Film sims with where they are ("✓ COLOR 2 · 1"), even after
  renaming or editing them, and **Reset look** on a film sim puts that film's values back.

## v0.21
Film grain on colour photos, looks you save on purpose, and a `*` that means "not factory". Camera-tested.

**Grain (Extras sector 9)**
- **Grain 0 Off, 1 Low, 2 Med, 3 High** on COLOR photos: the camera's own Monochrome grain (same texture, its Low /
  Medium / High strengths), on colour. The label reads "Grain" and the value shows the level.
- On its own, or with NR, the WB shift, Blacks / Whites or VigFix, the grain is made by the camera's image
  processor while it develops the photo: no extra time, and every other setting still applies.
- **With Glow / Clarity or an Art Effect** in the same look, the camera's processor can't add it there, so it is
  added to the finished photo in software (brightness only, the same pattern and strengths). **Each photo then takes
  about 3 seconds longer to save, and fast sequential (burst) shooting isn't possible with that look.** Making this
  fast is on the roadmap.
- Grain shows in the saved photo, not in live view.

**VigFix (Extras sector 8)**
- 0 Camera (your Shading Comp. menu setting) or 1 Off: the lens's vignette correction turned off for photos with this
  look, for natural corners, without changing the menu setting (as Caduceus's VigFix). Labels "Vig Cam" / "Vig Off".

**Saving looks on purpose**
- **Hold OK on the Film page** (a look 1–5 selected) saves the COLOR's current settings into that look. This is now
  the only way a look changes: turn to another look without it and your changes are dropped, so the saved look
  stays as it was. You can try things out without losing a look.
- The Film page never resets, and shows no "Reset" hint.
- **Hold OK on Saturation, Hue, Light or Extras** resets the wheels and Extras as before; the selected look stays.
- **Hold OK on the "COLOR n" item** resets the whole COLOR to the factory settings, Picture Mode settings included,
  and sets the Film page back to 0.

**The `*`**
- The `*` after "COLOR n" now means **something differs from the camera's factory settings** for that COLOR, on every
  page (the Film page included). After a reset, or on Film 0, it's gone; change anything and it's back. A selected
  look usually shows one, since the look changes settings.
- **Film 0** now loads the COLOR's own factory settings. Before, it set everything to 0, which on COLOR 2–4 (whose
  factory saturation and tone aren't 0) left a `*` that wouldn't go away.

**Fixes and smaller changes**
- **WB amber / blue and green / magenta now work with Auto WB.** Before, the WB shift was ignored in Auto WB and only
  applied to the other white balance modes.
- The rear dial stops at each Extras sector's first and last value (before, it could go past the end, and the next
  turns back did nothing).
- A reset could leave a saturation value off its factory setting when the wheel was last on the Film or Extras page
  (COLOR 4 kept a `*` after a reset on "COLOR 4"). The wheel now switches to Saturation for the reset and back
  afterwards.

**Control Panel**
- **Grain** (Off / Low / Med / High) and the **lens vignette correction** in the Extras, both written to `LOOKS.BIN`.
- The preview shows the grain as the photo looks at that size.
- **Drag the line on the photo** to compare before and after (it replaces the "Hold: original" button).
- A note under Grain when a look combines it with Glow / Clarity or an Art Effect: slower saving and no fast burst.
- Looks files keep Grain and the lens correction setting (the lens correction setting was lost on reopening before).
- Export › **Firmware on the camera**: v0.20 or older leaves Grain and the lens correction out of `LOOKS.BIN`
  (older firmware would ignore a file with them set).

**Card files and upgrading**
- Copy `DCOLYMP` (flash it) and both new `OM3MOD` files: `GUIDES.BIN` (the Extras code, made for this firmware) and
  `LABELS.BIN` (adds the VigFix and Grain labels). Keep your `LOOKS.BIN`, `NAMES.BIN` and `BUNDLES.BIN`: looks from
  v0.20 load with Grain off and the lens correction as before.
- Going back to v0.20 or older: those reject a `LOOKS.BIN` with Grain or VigFix set. Save it from the Control Panel
  with **v0.20 or older** chosen in Export.
- `patch.py` accepts the official firmware under the name OM's server uses now, `OLY_E_147_1100_0000_0000.BIN`, as
  well as the earlier `…_3.BIN` (issue #2).

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
