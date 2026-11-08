# Caduceus for OM-3

**Caduceus for OM-3** is the OM SYSTEM OM-3 member of the [Caduceus](https://github.com/cakelesscoder/caduceus-ep7)
family, made together with cakelesscoder: open-source firmware patches for the **OM SYSTEM OM-3** (firmware 1.1). It puts
**your films in the camera's Picture Mode list** (FILM 1, FILM 2, … after COLOR 1–4, up to five per COLOR, each with
its name), turns the Color Profile wheel into a colour editor (per-colour Hue and Luminance next to the camera's
Saturation), and adds the look's settings to the camera's own Picture Mode screen: Blacks, Whites, WB shift, Sharp,
Noise Filter, lens vignette correction and film grain. Films are made in the browser with the **Caduceus Control
Panel**; changes you make on the camera are kept per film.

**Latest: v0.24.1** ([changelog](CHANGELOG.md)) · **▶ [Control Panel](https://androidfanman.github.io/caduceus-om3/)** · **[Install guide](docs/INSTALL.md)** ·
**[Using it](#using-it)** · **[Roadmap](ROADMAP.md)** · Caduceus for the E-P7: [cakelesscoder/caduceus-ep7](https://github.com/cakelesscoder/caduceus-ep7).

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
| **Films in the Picture Mode list** | After COLOR 1–4, Picture Mode lists your films as **FILM 1, FILM 2, …** (up to 20, five per COLOR, from `LOOKS.BIN`). The film's name is the big title; the quick menu and the shooting screen show FILM n. Choosing a film loads it onto its COLOR. | Camera-tested (v0.24.1) |
| **Changes kept** | What you change on a film, or on COLOR 1–4, stays when you switch away and back (kept by the camera in `EDITS.BIN`). **Hold OK** on a film: back as built; on COLOR n: back to the factory. A `*` marks what is changed. | Camera-tested (v0.24.1) |
| **Hue and Luminance** | The Color Profile wheel (the **HSL** row) gains pages: **INFO** goes Color → Color All → Hue → Luminance. Hue turns a colour toward its neighbour; Luminance brightens or darkens it, for each of the 12 colours. | Camera-tested |
| **Picture Mode rows** | On COLOR 1–4: **Blacks**, **Whites** (−5..+5), **A-B**, **G-M** (WB shift −7..+7, in every WB mode, Auto WB included), **Sharpness** (−5 Off..+2), **Noise Filter** (Off / Low / Std / High), **Vignette Correction** (the lens's vignette correction Off / On) and **Film Grain**, next to the camera's Contrast and Highlight & Shadow. The **Shading** row is hidden in v0.24.1 (with grain it turned the photo black and white). | Camera-tested (v0.24.1) |
| **Film grain on COLOR** | The camera's own Monochrome grain, at its Low / Med / High strengths, on colour photos, at no extra time. Not together with **Shading** (the photo turns black and white), which v0.24.1 hides for now. | Camera-tested |
| **Glow, clarity and Art Effects** | Switched **off** in v0.24.1: with them, grain could only be added slowly. They stay in your looks and come back when fast grain works with them ([roadmap](ROADMAP.md)). v0.20–v0.22 have them. | Off in v0.24.1 |
| **Saved on the card** | Your changes save to `OM3MOD` on the SD card at the next half-press, written to a new file and read back before the old one is replaced. | Camera-tested |
| **Control Panel** | The Caduceus Control Panel, shared with Caduceus for the E-P7: a switch at the top picks **OM SYSTEM OM-3** or **Olympus PEN E-P7**. On the OM-3 it makes and previews looks on test photos (or your own), with 60 film sims, then saves them for the card. | Works in any browser |

## Install

You need: an OM-3 on firmware **1.1** (check *Setup › Firmware*), a **fully charged battery**, an SD card, and a
computer with [Python 3.8+](https://www.python.org/downloads/) (Windows, macOS or Linux; a Mac offers to install it).

### 1. Get Caduceus for OM-3

On this page click **Code › Download ZIP** and unzip it (or `git clone` the repo).

### 2. Make the update file on your computer

OM's licence doesn't allow anyone to share their firmware, so the update file is made on your own computer from OM's
official OM-3 1.1 firmware (`OLY_E_147_1100_0000_0000.BIN`, or `…_3.BIN` from an earlier download). The patcher checks it byte for byte, applies the
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

Switch on, **half-press the shutter once** (that loads your films and settings from the card), then open Picture
Mode: your films follow COLOR 1–4 in the list. See [Using it](#using-it).

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

- The left side shows COLOR 1–4 with looks 1–5 ("Empty" for an unused number); on the camera they become FILM 1,
  FILM 2, … in the Picture Mode list, in this order, skipping empty numbers. Drag a look to another number, or use ↑ ↓; × empties a number.
- **Lists** keep whole sets of looks (all four COLORs) under a name, like playlists: **Save as…** stores the
  current set as a new list, the **List** menu switches between them, and **Rename** / **Delete** manage them.
  Changes save into the list you're on; the looks you had before are the list **Default**. Lists stay in this
  browser; export a list to put it on the card.
- **Film sims** opens 60 film looks, one for each film: the Fujifilm simulations (Provia, Velvia, Astia, Classic
  Chrome, Classic Neg, Eterna, Reala Ace, Nostalgic Neg…), slide films (Velvia, Provia, Kodachrome, Ektachrome…),
  colour negatives (Portra, Ektar, Gold, ColorPlus, Ultramax, Superia, Fuji 400H, CineStill 50D / 400D / 800T,
  Harman Phoenix, LomoChrome '92…), instant films (FP-100C, Polaroid, Instax) and cinema print stocks. They're our own
  looks, designed from what each film is known for and made of ordinary OM-3 settings; none uses grain, Glow /
  Clarity or an Art Effect, so you can add those yourself. Click one to preview it on your photo, **+ Add** puts it in an
  empty number, and × in the list removes it again. Films already in your list are marked with where they are. The
  standard set you start with uses them: Fujifilm on COLOR 1, slide on COLOR 2, negative on COLOR 3, cinema and
  instant on COLOR 4.
- Edit Hue, Lightness and Saturation for each of the 12 colours, the tone (Highlights, Shadows, Midtones, Blacks,
  Whites), the camera's Contrast and Shading, the **Extras** (NR, lens vignette correction, Grain, Sharp,
  Glow ↔ Clarity, Art Effect) and the WB shift, with a live preview on test photos or your own (drag the line on the
  photo to compare before and after; grain, glow and clarity are previewed, Art Effects, NR and the lens correction
  are not). Glow / Clarity and Art Effects are switched off on firmware v0.24.1 (the editor says so); a look that
  combines Grain with Shading gets a note that the photo turns black and white (exports for v0.24.1 save Shading as 0).
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
OM3MOD/LOOKS.BIN      your films: up to 5 for each of COLOR 1–4, with their names (from the Control Panel)
OM3MOD/EDITS.BIN      the changes you made on the camera, per film and per COLOR (the camera writes it)
OM3MOD/BUNDLES.BIN    the wheels' current values (the camera writes it; .NEW and .BAK are its safety copies)
OM3MOD/GUIDES.BIN     the labels under the wheel + Caduceus code (from the release, with its firmware)
OM3MOD/LABELS.BIN     labels (from the release)
OM3MOD/NAMES.BIN      name pictures for v0.17–v0.22 (not needed by v0.24.1; harmless)
```

**Every time you switch on:** **half-press the shutter once.** That loads your films and changes from the card
(nothing is read at power-on). Until then Picture Mode works as stock.

**Choosing a film:** Picture Mode › the COLOR position. The top row lists **COLOR 1–4, then FILM 1, FILM 2, …**: turn
to a film and its name shows as the big title. The film loads onto the COLOR it belongs to (FILM 1–5 on COLOR 1, the
next five on COLOR 2 and so on, counting only the films on the card), and from then on the quick menu and the shooting
screen show **FILM n**.

**The rows** under Picture Mode: **HSL** (the colour wheel), Contrast, Highlight & Shadow, **Blk** (Blacks), **Wht**
(Whites), **A-B**, **G-M**, Sharpness (Sharp, −5 = Off .. +2), **Noise Filter** (Off / Low / Std / High), **Vignette
Correction** (Off = natural corners, On = the camera's correction) and **Film Grain** (Off / Low / Med /
High). They change the film or COLOR you're on, and the photo straight away.

**The HSL wheel:** on the HSL row press **INFO**. INFO goes **Color** (the camera's saturation, one colour) → **Color
All** → **Hue** → **Luminance** → Color. The front dial picks the colour, the rear dial the value. Colours run
clockwise from Yellow at 12 o'clock: Yellow, Orange, Orange-red, Red, Magenta, Violet, Blue, Blue-cyan, Cyan,
Green-cyan, Green, Yellow-green. Hue + turns a colour toward its clockwise neighbour (Yellow → Orange); Luminance
makes it brighter or darker (−5..+5).

**Your changes are kept:** change anything on a film (or on COLOR 1–4) and it stays when you switch to another film
and back. The camera keeps the changes in `EDITS.BIN` (saved at the next half-press); the film as built stays as it is
in `LOOKS.BIN`.

**Hold OK:**
- **On a film in the list** (or on the HSL wheel of a film): the film goes back to how it was built.
- **On COLOR n:** the whole COLOR goes back to the camera's factory settings.

A **`*`** means changed: after COLOR n, something differs from the factory settings; after FILM n, something differs
from how the film was built. Rows show their own `*` too.

**Grain:** grain is added by the camera's image processor at no cost. With **Shading** in the same film or COLOR it
turns the photo black and white, so v0.24.1 hides the Shading row (set Shading to 0 before flashing: after that you
can't see or change it). Glow / Clarity and Art Effects are switched off in v0.24.1: with them grain could only be added
slowly. Making grain fast with every effect is on the
[roadmap](ROADMAP.md).

**Quick answers**
- *No films in the list?* Half-press once after switching on, and check `OM3MOD/LOOKS.BIN` is on the card.
- *Settings change but nothing happens in the photo?* The card's `GUIDES.BIN` must come from the same release as the
  firmware. Copy the release's `GUIDES.BIN` again.
- *My changes were lost?* They save at the next half-press, and only when the card has an `OM3MOD` folder.
- *Photos with grain come out black and white?* That film or COLOR has Shading: export it again from the Control
  Panel for v0.24.1 (Shading 0), or set Shading to 0 on v0.22 before flashing.
- *New films from the Control Panel?* Export `LOOKS.BIN` (choose "v0.24.1 or later") and copy it to `OM3MOD`. A film
  you changed in the Control Panel starts again as built; the others keep your camera changes. Deleting `EDITS.BIN`
  puts every film back as built.
- *Monochrome?* Not supported: the MONO profiles keep the camera's own editor.
- *Want stock back for good?* Flash the restore file (see [Undo](#undo--go-back-to-stock)).

More: [docs/USING.md](docs/USING.md). Card file formats: [docs/FORMATS.md](docs/FORMATS.md).

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
- [research/](research/README.md): the full lab notebook (`research/NOTES.md`: every address, test and dead end),
  firmware and emulator tools, and archived experiments.
- [docs/FILM_SIMULATION_ROADMAP.md](docs/FILM_SIMULATION_ROADMAP.md): planned film-look features, effort and status.
- [CLAUDE.md](CLAUDE.md): working rules for AI-assisted sessions on this repo (useful for any contributor).

## Credits

Built on **[Caduceus](https://github.com/cakelesscoder/caduceus-ep7)** by cakelesscoder (Apache-2.0), firmware patches
for the Olympus PEN E-P7: the on-camera editor design, the bundle-table layout, the Caduceus Control Panel (shared by both cameras), its tone
model and the starter film looks. Sample photos are public domain (CC0), except the sunset by Joonas Lyytinen (CC BY 2.0); see [webapp/public/samples/CREDITS.md](webapp/public/samples/CREDITS.md). Camera emulation by
[om-emu](https://github.com/flatpanda/om-emu).

"OM SYSTEM", "Olympus" and "OM-3" are trademarks of their owners, as are the film names used for the starter looks.
Not affiliated with OM Digital Solutions, Fujifilm or Kodak.

## License

[Apache License 2.0](LICENSE). See [NOTICE](NOTICE).
