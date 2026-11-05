# Releases

Each folder is one version: the patch (`patch.json`, only the bytes Caduceus for OM-3 adds to OM's firmware), the
card files it needs, the expected checksums, and short notes. No OM firmware is stored here.

| Version | What's new | Status |
|---|---|---|
| [v0.17](v0.17/NOTES.md) | Profile names on the Profiles page (`NAMES.BIN`) | Camera-tested |
| [v0.16](v0.16/NOTES.md) | Profile bank: 5 profiles per COLOR, Profiles dial 0–5 | Camera-tested |

The launchers (`Make SD card files (Mac).command` / `(Windows).bat`) make the newest version and ask whether you
want an older one. From a terminal: `python3 firmware/patch.py --release v0.16`.

**Going back to an older version:** make its files, copy `DCOLYMP` to the card and flash as usual. Keep your
`OM3MOD/PROFILES.BIN` and `BUNDLES.BIN`; every version reads them. Files a version doesn't know (for example
`NAMES.BIN` on v0.16) are ignored.

**Going back to stock:** flash `SD card files/restore/E1479999.BIN`, the official firmware the patcher saved.

The whole project as it was at each version is also on the repo's Releases / Tags page (`v0.16`, `v0.17`).
See [CHANGELOG.md](../CHANGELOG.md) for the full history.
