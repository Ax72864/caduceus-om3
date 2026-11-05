# Changelog

Versions are named v0.N from v0.18 on. Earlier builds were called "test N" while they were tried on the camera; the
same number is used here (test 17 = v0.17).

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
