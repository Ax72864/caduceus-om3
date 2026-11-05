# Caduceus for OM-3 v0.19

- **Profiles are now Looks**, as in Caduceus: the wheel page is labelled **Looks**, and the bank on the card is
  `OM3MOD/LOOKS.BIN` (same format as before).
- Upgrading keeps your bank: when there is no `LOOKS.BIN` yet, the camera reads your `PROFILES.BIN`, and the next
  half-press save writes `LOOKS.BIN`. The old `PROFILES.BIN` is left on the card (delete it whenever you like).
- Copy the new `GUIDES.BIN` too (the "Looks" label). `NAMES.BIN` is unchanged.
- Everything in v0.18: Hue, Light, WB/BW and Looks pages, 5 looks per COLOR with names, the wheel opens on Looks.
- Emulator-tested (old `PROFILES.BIN` loads and saves to `LOOKS.BIN`; `LOOKS.BIN` wins when both exist).

Make it: run the launcher and press Return (or `python3 firmware/patch.py --release v0.19`). The files here are the
patch (only the bytes Caduceus for OM-3 adds; no OM firmware), the page labels and the expected checksums.
