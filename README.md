# Caduceus for OM-3

**Caduceus for OM-3** is the OM SYSTEM OM-3 member of the [Caduceus](https://github.com/cakelesscoder/caduceus-ep7)
family, made together with cakelesscoder: open-source firmware patches for the **OM SYSTEM OM-3** (firmware 1.1). It turns
the camera's Color Profile wheel into a full colour editor (per-colour Hue and Light, a WB/B·W page with Blacks and
Whites) and adds a **bank of five complete profiles for each of COLOR 1–4** that you build on the camera, or in the
browser with the **Caduceus Control Panel**, and switch between with one dial.

**Latest: v0.18** ([changelog](CHANGELOG.md)) · **▶ [Control Panel](https://androidfanman.github.io/caduceus-om3/)** · **[Install guide](docs/INSTALL.md)** ·
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
| **Hue and Light pages** | The Color Profile wheel gains pages, and **INFO** cycles them. Hue turns a colour toward its neighbour; Light brightens or darkens it, for each of the 12 colours. | Camera-tested |
| **WB/BW page** | Per-profile white balance shift (amber/blue, green/magenta) plus **Blacks** and **Whites**: the two ends of the tone curve (crushed or faded blacks, bright or soft whites). | Camera-tested |
| **Profile bank** | A **Profiles** page with 0–5: **1–5** load a whole profile (every wheel plus Contrast, Sharpness, Shading and Shadows/Midtones/Highlights), **0** is neutral. Five per COLOR, 20 in all. Changes you make are kept in the selected profile. | Camera-tested |
| **Profile names** | On the Profiles page, the label under the wheel shows the selected profile's name ("Velvia", "Empty" …) in the camera's own label style, from `NAMES.BIN` made by the Control Panel. | Camera-tested |
| **Saved on the card** | Your edits and the bank save to `OM3MOD` on the SD card at the next half-press, written to a new file and read back before the old one is replaced. | Camera-tested |
| **Control Panel** | The Caduceus Control Panel, shared with Caduceus for the E-P7: a switch at the top picks **OM SYSTEM OM-3** or **Olympus PEN E-P7**. On the OM-3 it makes and previews profiles on test photos (or your own), then saves them for the card. It starts with 20 Caduceus film looks and takes Caduceus look codes and packs. | Works in any browser |

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
OM3MOD/                the page labels; your edits and profiles are saved here → goes on the SD card
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
6. On a computer, delete `DCOLYMP/E1479999.BIN` from the card. Keep `OM3MOD`: that's where your edits and profiles
   live.

### 5. Shoot

Switch on, **half-press the shutter once** (that loads your settings from the card), then open a COLOR profile's
wheel: it opens on the Profiles page, and **INFO** steps through the other pages. See [Using it](#using-it).

### Go back to an earlier version

Run the launcher again and type the version you want (see [releases](releases/README.md)), then copy `DCOLYMP` to
the card and flash as in step 4. Keep `OM3MOD`: every version reads your `PROFILES.BIN` and `BUNDLES.BIN`.

### Undo / go back to stock

Copy `restore/E1479999.BIN` from your computer to the card's `DCOLYMP` folder (replacing the patched one) and flash
it exactly as in step 4. The camera is then completely stock 1.1 again.

More detail, troubleshooting and FAQ: **[docs/INSTALL.md](docs/INSTALL.md)**.

## Make your own profiles: the Control Panel

The **[Caduceus Control Panel](https://androidfanman.github.io/caduceus-om3/)** is where you make and edit profiles
in your browser. It is the same tool as Caduceus for the E-P7: the switch at the very top picks the camera. With
**OM SYSTEM OM-3** selected:

- The left side shows COLOR 1–4 with profiles 1–5, numbered as on the camera's Profiles page ("Empty" for an unused
  number). Drag a profile to another number, or use ↑ ↓; × empties a number.
- Edit Hue, Lightness and Saturation for each of the 12 colours, the tone (Highlights, Shadows, Midtones, Blacks,
  Whites), the camera's Contrast, Sharpness and Shading, and the WB shift, with a live preview on test photos or your
  own (hold **Hold: original** to compare).
- **Export › Save to card…** (Chrome or Edge on a computer) writes `OM3MOD/PROFILES.BIN` and `NAMES.BIN` (the name
  pictures for the camera) straight onto the card; **Card folder (.zip)** downloads both.
- **Open…** the card's `OM3MOD/PROFILES.BIN` to edit profiles you made on the camera, then save them back.
- **Caduceus looks:** **Paste code** takes a Caduceus look code or pack link, and **Open…** a Caduceus pack or E-P7
  `LOOKS.BIN`. Each colour look becomes an OM-3 profile: Hue, Light, Saturation, WB, the tone, Contrast and Vignette
  (as Shading) carry over; values beyond the OM-3's ±5 are limited; E-P7-only features (noise filter, glow,
  clarity, Art Effects) and monochrome looks are left out, and it says which.
- **Share profiles** / **Share** make a link to all your profiles or to one.

Your work stays in the browser (nothing is uploaded). Profiles from the earlier OM-3 Look Lab are brought over the
first time you open it. The preview is an approximation of the camera, good for direction and strength: judge the
final look in live view. On a Mac, Safari's **File › Add to Dock** makes the Control Panel an app.

## Using it

**On the card** (`OM3MOD` at the card's top level):

```
OM3MOD/PROFILES.BIN   the profile bank: 5 profiles for each of COLOR 1–4 (from the Control Panel, or made on the camera)
OM3MOD/NAMES.BIN      the profile names shown on the Profiles page (from the Control Panel, saved with PROFILES.BIN)
OM3MOD/BUNDLES.BIN    the wheels' current values (the camera writes it; .NEW and .BAK are its safety copies)
OM3MOD/GUIDES.BIN     the page labels under the wheel
```

**Every time you switch on:** **half-press the shutter once.** That loads your settings from the card (nothing is
read at power-on). Until then the wheel works as stock.

**Open the editor:** Picture Mode › **COLOR 1–4** › press **▼** to open the Color Profile wheel. It opens on the
**Profiles** page, with the selected profile's name under the wheel. **INFO** cycles the pages; the label under the
wheel shows which one:

**Profiles** → Saturation → Saturation (All) → **Hue** → **Light** → **WB/BW** → **Profiles**

One dial picks the colour slice, the other changes the value, as on the stock Saturation wheel. Slices run
clockwise from Yellow at 12 o'clock: Yellow, Orange, Orange-red, Red, Magenta, Violet, Blue, Blue-cyan, Cyan,
Green-cyan, Green, Yellow-green.

| Page | What the dial does |
|---|---|
| Saturation (· All) | the camera's own per-colour saturation (INFO also toggles one colour / all colours) |
| Hue | −5..+5: + turns that colour toward its clockwise neighbour (Yellow → Orange, Blue → Blue-cyan) |
| Light | −5..+5: darker or brighter for that colour |
| WB/BW | 12 o'clock A/B (+ amber, − blue) · 6 o'clock G/M (+ green, − magenta) · 3 o'clock **Blacks** (+ fades, − crushes) · 9 o'clock **Whites** (+ brighter, − softer) |
| Profiles | 12 o'clock only, 0–5: **1–5** load that COLOR's profile, and the label under the wheel shows its name; **0** = everything neutral |

**Profiles:**
1. On the Profiles page, turn the 12 o'clock spot to a number. The profile loads at once: every wheel, plus Contrast,
   Sharpness, Shading and Shadows/Midtones/Highlights on the camera's normal screens.
2. Change anything you like, on the wheel pages or in the normal Picture Mode settings. It belongs to the selected
   profile.
3. Turn to another number, or **half-press**, and the profile is kept. The bank saves to the card at the next
   half-press.
4. An empty number (its label says **Empty**) loads neutral, so that's how you make a new profile on the camera.
   Each COLOR has its own five.
5. The label under the wheel shows the selected profile's name. Names come from the Control Panel (`NAMES.BIN`): to
   name a profile you made on the camera, open the card's `PROFILES.BIN` in the Control Panel, type the name and save both
   files back. Step by step: [Profiles and their names](docs/USING.md#profiles-and-their-names).

**Reset:** hold **OK** on the wheel, or on the "COLOR n" item of the Picture Mode list, to put that COLOR's wheels
back to 0. A `*` next to a COLOR means it has been changed.

**Quick answers**
- *The new pages don't appear?* Half-press once after switching on, and check `OM3MOD` is at the card's top level.
- *My changes weren't saved?* They save at the next half-press, and only when the card has an `OM3MOD` folder.
- *Profiles from the Control Panel replaced mine?* Copying a `PROFILES.BIN` replaces the camera's bank. To keep
  profiles made on the camera, open the card's `PROFILES.BIN` in the Control Panel first, edit, then save back. Its
  file starts every COLOR at 0, so your current camera settings stay until you pick a profile.
- *Profile names?* They show under the wheel on the Profiles page, from `NAMES.BIN`. The Control Panel saves it with
  `PROFILES.BIN`: copy both. A profile made on the camera shows "Empty" (or "Profile n") until you name it in the
  Control Panel and save again. Without `NAMES.BIN` the label just says "Profiles".
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

- `firmware/src/editor.s`, `editor.ld`: the patch source (MN10300 / AM33 assembly).
- `firmware/build.py`: builds the update file from source (needs binutils built for `--target=mn10300-elf`):
  `python3 firmware/build.py --stock OLY_E_147_1100_0000_0000_3.BIN --toolchain BINUTILS_BUILD --out NEW_DIR`.
- `firmware/patch.py` + `releases/vX/patch.json`: the user-side patcher (pure Python) and each release's prebuilt patch (only
  the bytes this project writes).
- `card/`: generators for `GUIDES.BIN` (page labels) and `PROFILES.BIN`.
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
