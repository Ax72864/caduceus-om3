# Releases

Each folder is one version: the patch (`patch.json`, only the bytes Caduceus for OM-3 adds to OM's firmware), the
card files it needs, the expected checksums, and short notes. No OM firmware is stored here.

| Version | What's new | Status |
|---|---|---|
| [v0.20](v0.20/NOTES.md) | Film page, Extras page (NR, Glow/Clarity, WB, Art Effects, Blacks/Whites) with labels, live-view effects, white Frame | Camera-tested |
| [v0.19](v0.19/NOTES.md) | Profiles are now Looks: the Looks page, `LOOKS.BIN` (reads your `PROFILES.BIN`) | Camera-tested |
| [v0.18](v0.18/NOTES.md) | The wheel opens on the Profiles page | Camera-tested |
| [v0.17](v0.17/NOTES.md) | Profile names on the Profiles page (`NAMES.BIN`) | Camera-tested |
| [v0.16](v0.16/NOTES.md) | Profile bank: 5 profiles per COLOR, Profiles dial 0–5 | Camera-tested |

The launchers (`Make SD card files (Mac).command` / `(Windows).bat`) make the newest version and ask whether you
want an older one. From a terminal: `python3 firmware/patch.py --release v0.16`.

**Going back to an older version:** make its files, copy `DCOLYMP` to the card and flash as usual. Keep your
`OM3MOD` files; every version reads `BUNDLES.BIN`. The look bank is `LOOKS.BIN` from v0.19 and `PROFILES.BIN` in
v0.16–v0.18: going back from v0.19 or later, copy `LOOKS.BIN` to `PROFILES.BIN` so the older version sees your latest looks.
Always copy the version's own `GUIDES.BIN` (from v0.20 it carries code made for that firmware); older versions ignore `LABELS.BIN`. Files a version doesn't know (for example
`NAMES.BIN` on v0.16) are ignored.

**Going back to stock:** flash `SD card files/restore/E1479999.BIN`, the official firmware the patcher saved.

Each version is also published on the repo's **Releases** page (tag `v0.16` … `v0.20`) with the whole project as
it was at that version: a GitHub Action (`.github/workflows/releases.yml`) publishes every folder here once, so a
new version only needs its folder.
See [CHANGELOG.md](../CHANGELOG.md) for the full history.
