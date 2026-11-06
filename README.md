# Caduceus for OM-3

**Caduceus for OM-3** is the OM SYSTEM OM-3 member of the [Caduceus](https://github.com/cakelesscoder/caduceus-ep7)
family, made together with cakelesscoder: open-source firmware patches for the **OM SYSTEM OM-3** (firmware 1.1). It turns
the camera's Color Profile wheel into a full colour editor (per-colour Hue and Light, and an **Extras** page with
noise reduction, glow / clarity, WB shift, Art Effects, Blacks and Whites, laid out as in Caduceus) and adds a **bank
of five complete looks for each of COLOR 1–4** that you build on the camera, or in the browser with the **Caduceus
Control Panel**, and switch between with one dial on the **Film** page.

**Latest: v0.20** ([changelog](CHANGELOG.md)) · **▶ [Control Panel](https://androidfanman.github.io/caduceus-om3/)** · **[Install guide](docs/INSTALL.md)** ·
**[Using it](#using-it)** · Caduceus for the E-P7: [cakelesscoder/caduceus-ep7](https://github.com/cakelesscoder/caduceus-ep7).

> [!WARNING]
> **Early development, use at your own risk.** This is an unofficial, experimental firmware modification. Bugs will
> turn up, and flashing modified firmware can crash or freeze the camera, corrupt photos or the card's data, or leave
> the camera needing a restore. **No responsibility is accepted for any damage, data loss or other harm.** It is
> provided "as is", without warranty of any kind (see the [Apache License 2.0](LICENSE), sections 7–8). Using it may
> affect your warranty with OM Digital Solutions.
>
> Every change is checked in an emulator of the camera's CPU before it goes on a camera, the SD update and restore
> path is proven on a real OM-3, and features marked **camera-tested** below have run on a real camera. Read
> [Safety](#safety) before flashing.

> [!NOTE]
> **Color profiles only.** Everything here works on Picture Mode **COLOR 1–4**. The **Monochrome** profiles are not
> changed: they keep the camera's own editor.

## Features

| Feature | What you get | Status |
|---|---|---|
| **Hue and Light pages** | The Color Profile wheel gains pages, and **INFO** cycles them from any slice. Hue turns a colour toward its neighbour; Light brightens or darkens it, for each of the 12 colours. | Camera-tested |
| **Extras page** | One wheel for the look's extras, as in Caduceus: **1 NR** (the camera's noise reduction per look: Camera / Std / Low / Off), **2 Glow ← → Clarity** (−5..+5), **3 WB amber/blue**, **4 WB green/magenta**, **5 Art Effect** (Star Light, Pin Hole, White Edge, Frame), **6 Blacks**, **7 Whites**. The label next to the value names the sector and what it does ("Glow", "Clarity", "A", "B", "NR Low", "Frame" …). | Camera-tested (v0.20) |
| **Glow, clarity and Art Effects on COLOR** | The camera's own Soft Focus passes, five glow strengths and five clarity strengths (Caduceus's levels), and its Art Effects, on COLOR photos without an Art Filter. Glow and Art Effects also show in **live view**. | Camera-tested (v0.20) |
| **White frame** | The Frame Art Effect draws a clean **white** border of the stock size instead of the rough black film edge (everywhere, Art Filters included). | Camera-tested (v0.20) |
| **Noise reduction per look** | NR is applied at every photo from the selected look and follows a profile switch, without changing your Noise Filter menu setting. | New in v0.20 (pixel comparison still to do) |
| **Look bank** | A **Film** page with 0–5: **1–5** load a whole look (every wheel and Extras value plus Contrast, Sharpness, Shading and Shadows/Midtones/Highlights), **0** is neutral. Five per COLOR, 20 in all. Changes you make are kept in the selected look; a `*` marks a changed look and hold **OK** resets it. | Camera-tested |
| **Look names** | On the Film page, the label under the wheel shows the selected look's name ("Velvia", "Empty" …) in the camera's own label style, from `NAMES.BIN` made by the Control Panel. | Camera-tested |
| **Saved on the card** | Your edits and the bank save to `OM3MOD` on the SD card at the next half-press, written to a new file and read back before the old one is replaced. | Camera-tested |
| **Control Panel** | The Caduceus Control Panel, shared with Caduceus for the E-P7: a switch at the top picks **OM SYSTEM OM-3** or **Olympus PEN E-P7**. On the OM-3 it makes and previews looks on test photos (or your own), then saves them for the card. It starts with 20 Caduceus film looks and takes Caduceus look codes and packs. | Works in any browser |

## Install

You need: an OM-3 on firmware **1.1** (check *Setup › Firmware*), a **fully charged battery**, an SD card, and a
computer with [Python 3.8+](https://www.python.org/downloads/) (Windows, macOS or Linux; a Mac offers to install it).

### 1. Get Caduceus for OM-3

On this page click **Code › Download ZIP** and unzip it (or `git clone` the repo).

### 2. Make the update file on your computer

OM's licence doesn't allow anyone to share their firmware, so the update file is made on your own computer from OM's
official OM-3 1.1 firmware (`OLY_E_147_1100_0000_0000_3.BIN`). The patcher checks it byte for byte, applies the
Caduceus for OM-3 changes and checks the result.

- **Easiest:** in the unzipped folder, double-click the launcher for your system:
  - macOS: `Make SD card files (Mac).command` (the first time: right-click › **Open**)
  - Windows: `Make SD card files (Windows).bat`
- **Or from a terminal** in that folder: `python3 firmware/patch.py` (Windows: `py firmware\patch.py`).

If the official file is in the folder or in Downloads, the patcher uses it; otherwise it asks OM's update server for
it. It refuses any other file or firmware version. It makes the newest version; press Return, or type an older
version (for example `v0.16`) to go back to it. Every version is in [releases](releases/README.md). It creates a folder **`SD card files`** with:

```
DCOLYMP/E1479999.BIN   the patched firmware update      → goes on the SD card
OM3MOD/                GUIDES.BIN (page labels + Extras code) and LABELS.BIN; your edits and looks are saved here → goes on the SD card
restore/E1479999.BIN   the original OM firmware 1.1     → keep on your computer (to undo Caduceus for OM-3)
```

### 3. Copy to the SD card

Put the camera's SD card in your computer and copy the **`DCOLYMP`** and **`OM3MOD`** folders to the top level of
the card (next to the `DCIM` folder). Eject the card properly.

### 4. Flash the camera

1. Put the card in the camera. **Battery fully charged**, camera **off**.
2. **Hold the OK button** and switch the camera **on**. Keep holding OK until the update starts.
3. The light stays **steady** while the update is written (about two minutes). **Do not switch off, open the battery
   door or remove the card.**
4. When the light starts **blinking**, it's finished. Switch the camera off.
5. Switch it on normally.
6. On a computer, delete `DCOLYMP/E1479999.BIN` from the card. Keep `OM3MOD`: that's where your edits and looks
   live.

### 5. Shoot

Switch on, **half-press the shutter once** (that loads your settings from the card), then open a COLOR profile's
wheel: it opens on the Film page, and **INFO** steps through the other pages. See [Using it](#using-it).

### Go back to an earlier version

Run the launcher again and type the version you want (see [releases](releases/README.md)), then copy `DCOLYMP` to
the card and flash as in step 4. Keep `OM3MOD`: every version reads your `LOOKS.BIN` and `BUNDLES.BIN`. Always copy
the release's own `GUIDES.BIN` (and from v0.20 `LABELS.BIN`) with its firmware: from v0.20 `GUIDES.BIN` carries code
built for that exact firmware. Coming from v0.16–v0.18, rename your `PROFILES.BIN` to `LOOKS.BIN` (same format; v0.19
did this by itself, v0.20 no longer does).

### Undo / go back to stock

Copy `restore/E1479999.BIN` from your computer to the card's `DCOLYMP` folder (replacing the patched one) and flash
it exactly as in step 4. The camera is then completely stock 1.1 again.

More detail, troubleshooting and FAQ: **[docs/INSTALL.md](docs/INSTALL.md)**.

## Make your own looks: the Control Panel

The **[Caduceus Control Panel](https://androidfanman.github.io/caduceus-om3/)** is where you make and edit looks
in your browser. It is the same tool as Caduceus for the E-P7: the switch at the very top picks the camera. With
**OM SYSTEM OM-3** selected:

- The left side shows COLOR 1–4 with looks 1–5, numbered as on the camera's Film page ("Empty" for an unused
  number). Drag a look to another number, or use ↑ ↓; × empties a number.
- Edit Hue, Lightness and Saturation for each of the 12 colours, the tone (Highlights, Shadows, Midtones, Blacks,
  Whites), the camera's Contrast, Sharpness and Shading, the **Extras** (NR, Glow ↔ Clarity, Art Effect) and the WB
  shift, with a live preview on test photos or your own (hold **Hold: original** to compare; glow and clarity are
  previewed, Art Effects and NR are not).
- **Export › Save to card…** (Chrome or Edge on a computer) writes `OM3MOD/LOOKS.BIN` and `NAMES.BIN` (the name
  pictures for the camera) straight onto the card; **Card folder (.zip)** downloads both.
- **Open…** the card's `OM3MOD/LOOKS.BIN` to edit looks you made on the camera, then save them back.
- **Caduceus looks:** **Paste code** takes a Caduceus look code or pack link, and **Open…** a Caduceus pack or E-P7
  `LOOKS.BIN`. Each colour look becomes an OM-3 look: Hue, Light, Saturation, WB, the tone, Contrast, Vignette
  (as Shading), NR, glow / clarity and Star Light / Pin Hole carry over; values beyond the OM-3's ±5 are limited, a
  halation (coloured) glow becomes a plain glow, Blur and monochrome looks are left out, and it says which.
- **Share looks** / **Share** make a link to all your looks or to one.

Your work stays in the browser (nothing is uploaded). Looks from the earlier OM-3 Look Lab are brought over the
first time you open it. The preview is an approximation of the camera, good for direction and strength: judge the
final look in live view. On a Mac, Safari's **File › Add to Dock** makes the Control Panel an app.

## Using it

**On the card** (`OM3MOD` at the card's top level):

```
OM3MOD/LOOKS.BIN      the look bank: 5 looks for each of COLOR 1–4 (from the Control Panel, or made on the camera)
OM3MOD/NAMES.BIN      the look names shown on the Film page (from the Control Panel, saved with LOOKS.BIN)
OM3MOD/BUNDLES.BIN    the wheels' current values (the camera writes it; .NEW and .BAK are its safety copies)
OM3MOD/GUIDES.BIN     the page labels under the wheel + the Extras effects code (from the release, with its firmware)
OM3MOD/LABELS.BIN     the Extras labels next to the value (from the release)
```

**Every time you switch on:** **half-press the shutter once.** That loads your settings from the card (nothing is
read at power-on). Until then the wheel works as stock.

**Open the editor:** Picture Mode › **COLOR 1–4** › press **▼** to open the Color Profile wheel. It opens on the
**Film** page, with the selected look's name under the wheel. **INFO** cycles the pages from any slice; the label
under the wheel shows which one:

**Film** → Saturation → Saturation (All) → **Hue** → **Light** → **Extras** → **Film**

The **front dial** moves the selector around the wheel, the **rear dial** changes the value, as on the stock
Saturation wheel. Colour slices run clockwise from Yellow at 12 o'clock: Yellow, Orange, Orange-red, Red, Magenta,
Violet, Blue, Blue-cyan, Cyan, Green-cyan, Green, Yellow-green.

| Page | What the dial does |
|---|---|
| Film | 12 o'clock only, 0–5: **1–5** load that COLOR's look, and the label under the wheel shows its name; **0** = everything neutral |
| Saturation (· All) | the camera's own per-colour saturation (INFO first toggles one colour / all colours, then goes on to Hue) |
| Hue | −5..+5: + turns that colour toward its clockwise neighbour (Yellow → Orange, Blue → Blue-cyan) |
| Light | −5..+5: darker or brighter for that colour |
| Extras | the sectors below, 1 at 12 o'clock then clockwise; the label next to the value names each one |

**The Extras page**

| Sector | Clock | What it does | Values (label) |
|---|---|---|---|
| 1 | 12 | Noise reduction for photos with this look | 0 Camera (NR) · 1 Standard (NR Std) · 2 Low (NR Low) · 3 Off, most texture (NR Off) |
| 2 | 1 | Glow ← → Clarity | −1..−5 glow (Glow), +1..+5 clarity (Clarity), 0 off (Glo/Cla) |
| 3 | 2 | WB amber / blue | + amber (A), − blue (B), 0 (A/B) |
| 4 | 3 | WB green / magenta | + green (G), − magenta (M), 0 (G/M) |
| 5 | 4 | Art Effect | 0 Off · 1 Star Light (Star) · 2 Pin Hole · 4 White Edge (W. Edge) · 5 Frame, a clean white border (Frame); 3 does nothing |
| 6 | 5 | Blacks | + lifts / fades, − crushes |
| 7 | 6 | Whites | + brighter, − softer |
| 8 | 7 | reserved | – |

Glow and the Art Effects show in live view as you frame; clarity shows in the saved photo. NR changes the photo's
own Noise Filter setting (visible in its recorded settings, mostly at high ISO) and leaves your menu setting alone.

**Looks:**
1. On the Film page, turn the 12 o'clock spot to a number. The look loads at once: every wheel and Extras value, plus
   Contrast, Sharpness, Shading and Shadows/Midtones/Highlights on the camera's normal screens.
2. Change anything you like, on the wheel pages or in the normal Picture Mode settings. It belongs to the selected
   look.
3. Turn to another number, or **half-press**, and the look is kept. The bank saves to the card at the next
   half-press.
4. An empty number (its label says **Empty**) loads neutral, so that's how you make a new look on the camera.
   Each COLOR has its own five.
5. The label under the wheel shows the selected look's name. Names come from the Control Panel (`NAMES.BIN`): to
   name a look you made on the camera, open the card's `LOOKS.BIN` in the Control Panel, type the name and save both
   files back. Step by step: [Looks and their names](docs/USING.md#looks-and-their-names).

**Reset:** hold **OK** on the wheel, or on the "COLOR n" item of the Picture Mode list, to put that COLOR's wheels
and Extras back to 0. A `*` next to a COLOR means it has been changed.

**Quick answers**
- *The new pages don't appear?* Half-press once after switching on, and check `OM3MOD` is at the card's top level.
- *Extras values change but nothing happens in the photo?* The card's `GUIDES.BIN` must come from the same release
  as the firmware (it carries the Extras code). Copy the release's `GUIDES.BIN` again.
- *The label still says "Vivid" on Extras?* `LABELS.BIN` is missing from `OM3MOD`: copy it from the release.
- *My changes weren't saved?* They save at the next half-press, and only when the card has an `OM3MOD` folder.
- *Looks from the Control Panel replaced mine?* Copying a `LOOKS.BIN` replaces the camera's bank. To keep
  looks made on the camera, open the card's `LOOKS.BIN` in the Control Panel first, edit, then save back. Its
  file starts every COLOR at 0, so your current camera settings stay until you pick a look.
- *Look names?* They show under the wheel on the Film page, from `NAMES.BIN`. The Control Panel saves it with
  `LOOKS.BIN`: copy both. A look made on the camera shows "Empty" (or "Look n") until you name it in the
  Control Panel and save again. Without `NAMES.BIN` the label just says "Film".
- *Monochrome?* Not supported: the MONO profiles keep the camera's own editor.
- *Want stock back for good?* Flash the restore file (see [Undo](#undo--go-back-to-stock)).

Full page-by-page guide: [docs/USING.md](docs/USING.md). Card file formats: [docs/FORMATS.md](docs/FORMATS.md).

## Safety

- **No responsibility is accepted for damage of any kind.** You flash this at your own risk. This is
  early-development software: expect bugs.
- Only the OM-3 on firmware **1.1** is supported. The patcher refuses any other firmware file, and checks its result
  against the expected checksum before writing it.
- The camera's SD updater (hold **OK** while switching on, file at `DCOLYMP/E1479999.BIN`) is confirmed working on
  the OM-3: steady light while writing, then blinking when done. Every test build has been flashed through it, one
  over another, and the official file goes on the same way.
- A full battery and an uninterrupted write are essential. A failed write can leave the camera unbootable.
- Keep the restore file the patcher makes (`restore/E1479999.BIN`). Flashing it returns the camera completely to
  stock 1.1.
- If something misbehaves: remove the `OM3MOD` folder from the card first (your settings are in it: copy it to your
  computer). If that doesn't help, flash the restore file.

## For developers

- `firmware/src/editor.s`, `editor.ld`: the patch source (MN10300 / AM33 assembly). `firmware/src/xblock.s`: the
  Extras code block (relocatable, appended to `GUIDES.BIN` and loaded from the card at the first half-press).
- `firmware/frames.py`: the white Frame layers (our own JPEGs, written into the resource component).
- `firmware/build.py`: builds the update file from source (needs binutils built for `--target=mn10300-elf`):
  `python3 firmware/build.py --stock OLY_E_147_1100_0000_0000_3.BIN --toolchain BINUTILS_BUILD --out NEW_DIR`.
- `firmware/patch.py` + `releases/vX/patch.json`: the user-side patcher (pure Python) and each release's prebuilt patch (only
  the bytes this project writes).
- `card/`: generators for `GUIDES.BIN` (page labels), `LABELS.BIN` (Extras labels) and `LOOKS.BIN`.
- `tools/mkpatch.py`: makes a release's `patch.json` from a build.
- `webapp/`: the Caduceus Control Panel source (TypeScript + Vite, from cakelesscoder/caduceus-ep7 with the OM-3
  mode added; see [webapp/README.md](webapp/README.md)). `looklab/` is its build, served by GitHub Pages
  (`VITE_DEFAULT_CAMERA=om3 npm run build`, then copy `dist/` to `looklab/`).
- `tools/emulator/`: test harness for [om-emu](https://github.com/flatpanda/om-emu) (E147 model).
- [docs/DEVELOPER_NOTES.md](docs/DEVELOPER_NOTES.md): addresses, hooks and the test history.

## Credits

Built on **[Caduceus](https://github.com/cakelesscoder/caduceus-ep7)** by cakelesscoder (Apache-2.0), firmware patches
for the Olympus PEN E-P7: the on-camera editor design, the bundle-table layout, the Caduceus Control Panel (shared by both cameras), its tone
model and the starter film looks. Test photos are public domain (CC0); see
[webapp/public/samples/CREDITS.md](webapp/public/samples/CREDITS.md). Camera emulation by
[om-emu](https://github.com/flatpanda/om-emu).

"OM SYSTEM", "Olympus" and "OM-3" are trademarks of their owners, as are the film names used for the starter looks.
Not affiliated with OM Digital Solutions, Fujifilm or Kodak.

## License

[Apache License 2.0](LICENSE). See [NOTICE](NOTICE).
