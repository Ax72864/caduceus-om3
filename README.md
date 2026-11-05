# OM-3 Color Lab

On-camera colour editing for the **OM SYSTEM OM-3** (firmware **1.1**): Hue, Light and WB/B·W wheels for
COLOR 1–4, plus a bank of **5 full profiles per COLOR** that you can build on the camera or in the
**Look Lab** web tool and switch between with one dial.

**▶ [OM-3 Color Lab](https://androidfanman.github.io/om3-color-lab/)**

> [!NOTE]
> **Color profiles only.** Everything here works on Picture Mode **COLOR 1–4** (the Color Profiles). The
> **Monochrome** profiles (MONO 1–4) are not changed: they keep the camera's own editor and have no Hue, Light,
> WB/BW or Profiles pages.

> [!WARNING]
> **Unofficial, experimental firmware modification. Use at your own risk.** Flashing modified firmware can crash
> or freeze the camera, corrupt photos or the card, or leave the camera needing a restore. It is provided "as is",
> without warranty of any kind (see the [Apache License 2.0](LICENSE), sections 7–8), and it may affect your
> warranty with OM Digital Solutions. Every change is checked in an emulator of the camera's CPU before it goes on
> a camera; features below marked *camera-tested* have run on a real OM-3.

## What you get

| Feature | What it does | Status |
|---|---|---|
| **Hue and Light pages** | The Color Profile wheel gains pages: INFO cycles Saturation → (ALL) → Hue → Light → WB/BW → Profiles. Hue + turns a colour toward its clockwise neighbour; Light brightens or darkens it. | Camera-tested |
| **WB / B·W page** | 12 o'clock A/B (amber–blue) and 6 o'clock G/M (green–magenta) shift per COLOR, 3 o'clock Blacks, 9 o'clock Whites (the ends of the tone curve). | Camera-tested |
| **Profiles page** | 12 o'clock spot 0–5. **0** = nothing (all neutral), **1–5** = that COLOR's profile 1–5: every wheel plus Contrast, Sharpness, Shading and Shadows/Midtones/Highlights. Changes you make are kept in the selected profile; empty numbers start neutral. | Camera-tested |
| **Saved on the card** | Edits save to `OM3MOD/BUNDLES.BIN` and `OM3MOD/PROFILES.BIN` on a half-press (write, read back, then replace). | Camera-tested |
| **Look Lab** | A web page to make, preview and save profiles (`looklab/`). Opens the camera's `PROFILES.BIN`, edits it, writes it back. | Works in any browser |

## Install

You need an OM-3 on firmware **1.1** (Setup › Firmware), a **fully charged battery**, an SD card, and a computer
with Python 3.8 or newer (macOS offers to install it the first time).

1. **Get this project:** Code › Download ZIP, and unzip it.
2. **Get OM's official firmware 1.1** file `OLY_E_147_1100_0000_0000_3.BIN` and put it in the unzipped folder
   (or in Downloads). OM's licence doesn't allow sharing it, so this project never contains it.
3. **Make the update file:** double-click `Make SD card files (Mac).command` or `Make SD card files (Windows).bat`.
   It checks the official file byte for byte, applies the patch and checks the result, then makes a folder
   `SD card files` with `DCOLYMP`, `OM3MOD` and `restore`. (On a Mac, the first time: right-click › Open.)
4. **Copy `DCOLYMP` and `OM3MOD`** to the top of the SD card.
5. **Flash:** card in the camera, hold **OK** while turning the camera on, confirm the update. It takes about two
   minutes; don't turn the camera off.

**Going back to stock:** put `SD card files/restore/E1479999.BIN` in the card's `DCOLYMP` folder instead and flash
the same way.

How to use the new pages: [docs/USING.md](docs/USING.md). File formats: [docs/FORMATS.md](docs/FORMATS.md).

## Look Lab

**https://androidfanman.github.io/om3-color-lab/** — it starts with 20 of the Caduceus film looks (5 per COLOR) to
try and edit. `looklab/index.html` is a self-contained page: open it from a web server (for example GitHub Pages) in any browser.
In Chrome or Edge on a computer, **Save to the SD card…** writes `OM3MOD/PROFILES.BIN` straight onto the card;
elsewhere, **Save card files (.zip)** downloads it. Work is kept in the browser. On a Mac, Safari's File › Add to
Dock makes it an app.

## For developers

- `firmware/src/editor.s`, `editor.ld`: the patch source (MN10300 / AM33 assembly).
- `firmware/build.py`: builds the update file from source (needs binutils built for `--target=mn10300-elf`).
- `firmware/patch.py` + `firmware/patches/*.json`: the user-side patcher (pure Python) and the prebuilt patch.
- `card/`: generators for `GUIDES.BIN` (page labels) and `PROFILES.BIN`.
- `tools/emulator/`: test harness for [om-emu](https://github.com/flatpanda/om-emu) (E147 model).
- [docs/DEVELOPER_NOTES.md](docs/DEVELOPER_NOTES.md): addresses, hooks and the test history.

## Credits

Built on **[Caduceus](https://github.com/cakelesscoder/caduceus-ep7)** by cakelesscoder (Apache-2.0), firmware
patches for the Olympus PEN E-P7: the editor design, the bundle-table layout, the Look Lab tone model and
starter looks. See [NOTICE](NOTICE). Not affiliated with OM Digital Solutions.
