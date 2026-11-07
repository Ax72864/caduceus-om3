# Research

How Caduceus for OM-3 was worked out, and the tools to keep going. Nothing here is needed to build or install a
release (that is `firmware/`, `card/` and `webapp/`). No OM firmware, decoded firmware, disassembly dumps or camera
graphics are stored here: the tools make them from the official firmware file you download yourself.

| Path | What it is |
|---|---|
| [`NOTES.md`](NOTES.md) | **The lab notebook.** Every firmware address, hook, test result and dead end, in order (newest at the end). Read the section for an area before changing it. "camera" = seen on a real OM-3, "emulator" = om-emu only. |
| [`../docs/DEVELOPER_NOTES.md`](../docs/DEVELOPER_NOTES.md) | The cleaned-up summary per release. |
| [`../docs/FILM_SIMULATION_ROADMAP.md`](../docs/FILM_SIMULATION_ROADMAP.md) | What we want to add for film looks, with effort and status. |
| `grain/` | The grain model (bit-exact with the camera's Monochrome grain). |
| `tools/` | Decode the firmware container (`oe_decode.py`), list its sections and free tails (`sections.py`), check anchor addresses (`check_anchors.py`), disassemble a range (`dis.sh`). |
| `emulator/` | More scripts for [om-emu](https://github.com/flatpanda/om-emu) (OM-3 = model E147); the main test driver `session_ed1.mjs` (keys, dials, screenshots, traces, memory dumps) and `card_add_file.py` / `card_get_file.py` (files on and off an emulator SD card image) are in `../tools/emulator/`. Here: `gapprobe.mjs` checks which RAM the firmware writes; `nav.mjs`, `trace_edit.mjs` walk and trace the UI. |
| `porting/` | Map E-P7 1.1 addresses (Caduceus for the E-P7) to OM-3 1.1 code by instruction-shape matching. |
| `osd/` | The camera's OSD picture format (type-11 streams) and the first guide / label makers (the current ones are `card/mkguides.py`, `card/mklabels.py`). |
| `archive/editor-tests/` | Every editor test build from test 1 to v0.20 test 7 (sources and build scripts), as described in `NOTES.md`. |
| `archive/experiments/` | Later experiment trees (grain routes `g21`, `gdx`, `glog`, `gprepo`, `gw`, `gwA`; looks `gz`, `gz2`) as patches against the v0.21 release, plus standalone variant sources. |
| `archive/early/` | The first proof of concept, early window / grain / frame / looks / profiles scripts. |

Scripts in `archive/` and some in `osd/` and `porting/` still name the paths of the workspace they were written in
(`/home/claude/om3/...`): read them as a record, or change the paths to yours.

Work in progress lives on branches, not here: `feature/...` for features meant to ship, `experiment/...` for tests
that answer a question (see their README banners).

## Setting up

1. **Firmware.** Download the official OM-3 firmware 1.1 (`OLY_E_147_1100_0000_0000.BIN`, sha256 `8c133084…696d`;
   `firmware/patch.py --download` fetches it). Decode it with `python3 tools/oe_decode.py`; the main block is
   component 0 (sha256 `5e8d376e…7d59`).
2. **Toolchain.** GNU binutils 2.42 for MN10300 (AM33). Built from the Ubuntu source package with:
   `../binutils-2.42/configure --target=mn10300-elf --disable-nls --disable-werror --disable-gdb --disable-sim
   --disable-gprof --disable-gold --disable-libctf --disable-gprofng --with-system-zlib --disable-shared && make`.
   `firmware/build.py --toolchain <build dir>` uses its `gas`, `ld`, `objcopy` and `nm`.
3. **Build.** `python3 firmware/build.py --stock OLY_E_147_1100_0000_0000.BIN --toolchain <build dir> --out <dir>`
   makes the firmware package, `main.bin` (the patched main block, for the emulator) and the card files.
4. **Emulator.** Clone [om-emu](https://github.com/flatpanda/om-emu), then for example
   `OM_EMU_MODEL=E147 node tools/emulator/session_ed1.mjs <om-emu>/emu <out>/main.bin CARD.omsd OUT.json SAVE.omsd 's1 ok ok down shot:a.png'`.
   Tokens: `s1` half-press, key names (`ok`, `down`, `info`, `menu` …), `main+N` / `sub+N` dials, `hold:ok`,
   `shot:FILE.png`, `dump:FILE`; env `WATCH=pc,pc` (+ `WSTACK=1`) traces those addresses. Each step prints the
   editor state as JSON.

## Rules learned the hard way

- **Only proven space.** New code goes in the section tails inside the loader's copy ranges (ext1–ext10 in
  `firmware/editor.ld`) or in the GUIDES.BIN code block. The empty stretches between sections are not loaded on the
  camera even though the emulator shows them (see `NOTES.md`, "Space audit" and "Picture-mode sliders").
- **Emulator first, camera second.** Every build is checked in the emulator, then on the camera; only camera-tested
  builds are released.
- **Rebuild must match.** A release's `patch.json` must rebuild the camera-tested package byte for byte
  (`firmware/patch.py --release vX` against its `SHA256SUMS`).
