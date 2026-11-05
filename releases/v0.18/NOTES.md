# Caduceus for OM-3 v0.18

- The Color Profile wheel now opens on the **Profiles** page, showing the selected profile's name. INFO order is
  unchanged: Profiles → Saturation → (All) → Hue → Light → WB/BW → Profiles.
- Everything in v0.17: Hue, Light and WB/BW pages, the profile bank (5 per COLOR) and profile names (`NAMES.BIN`).
- Card files: `GUIDES.BIN` (page labels). Make `PROFILES.BIN` and `NAMES.BIN` in the Look Lab.
- Camera-tested.

Make it: run the launcher and press Return (or `python3 firmware/patch.py --release v0.18`). The files here are the
patch (only the bytes Caduceus for OM-3 adds; no OM firmware), the page labels and the expected checksums.
