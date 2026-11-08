# Using Caduceus for OM-3 on the camera (v0.24.1)

> **Color profiles only:** this is for Picture Mode COLOR 1–4. The Monochrome profiles keep the camera's own editor.
> For v0.20–v0.22 (Film page, Extras page on the wheel) see this page as it was at
> [v0.22](https://github.com/androidfanman/caduceus-om3/blob/v0.22/docs/USING.md).

**After switching on, half-press the shutter once.** That loads your films and changes from the card.

## Films

Make films (looks) in the [Control Panel](https://androidfanman.github.io/caduceus-om3/): up to five for each of
COLOR 1–4. Export `LOOKS.BIN` with **Firmware on the camera: v0.24.1 or later** and copy it to `OM3MOD` on the card.

On the camera, Picture Mode › the COLOR position: the top row lists **COLOR 1–4, then FILM 1, FILM 2, …** (the films
on the card in order, empty numbers skipped). Turn to a film: its **name** is the big title, and it loads onto the
COLOR it belongs to (the Control Panel's COLOR 1 films onto COLOR 1, and so on). The quick menu and the shooting screen
then show **FILM n**.

## Changing a film

Every row under Picture Mode changes the film (or the COLOR) you're on, at once:

| Row | What it does |
|---|---|
| **HSL** | The colour wheel (below) |
| Contrast, Highlight & Shadow | The camera's own |
| **Blk** / **Wht** | Blacks / Whites, −5..+5: + lifts / brightens, − crushes / softens |
| **A-B** / **G-M** | WB shift, −7..+7: amber / blue, green / magenta, in every WB mode (Auto WB included) |
| Sharpness | Sharp: the camera's sharpening, −5 = Off, −4..−1 softer, 0 its normal, +1 / +2 crisper |
| **Noise Filter** | Off / Low / Std / High for photos with this film |
| **Vignette Correction** | Off = the lens's natural corners, On = the camera's correction |
| **Film Grain** | Off / Low / Med / High: the camera's grain on the colour photo |

**The HSL wheel:** on the HSL row press **INFO**. INFO goes **Color** (the camera's saturation, one colour at a time)
→ **Color All** → **Hue** → **Luminance** → Color. The front dial picks the colour, the rear dial the value. Colours
run clockwise from Yellow at 12 o'clock: Yellow, Orange, Orange-red, Red, Magenta, Violet, Blue, Blue-cyan, Cyan,
Green-cyan, Green, Yellow-green. **Hue** (−5..+5): + turns a colour toward its clockwise neighbour (Yellow → Orange,
Blue → Blue-cyan). **Luminance** (−5..+5): darker or brighter for that colour.

Your changes stay with the film: switch to another film and back and they're still there. COLOR 1–4 keep their own
changes the same way. The camera keeps them in `OM3MOD/EDITS.BIN` (saved at the next half-press); `LOOKS.BIN` is never
changed by the camera.

## Resets and the `*`

- **Hold OK on a film** in the list (or on its HSL wheel): the film goes back to how it was built.
- **Hold OK on COLOR n:** the COLOR goes back to the camera's factory settings.
- A **`*`** after COLOR n: something differs from the factory settings. After FILM n: something differs from how the
  film was built. A row with its own `*` is one of the changed settings.

## Grain

Grain is added by the camera's image processor at no cost. Together with **Shading** it turns the photo black and
white, so v0.24.1 hides the Shading row for now: set Shading to 0 on COLOR 1–4 before flashing (afterwards you can't
see or change it), and looks exported for v0.24.1 get Shading 0.
**Glow / Clarity and Art Effects are switched off in v0.24.1**: with them grain could only be added slowly. They
stay in your looks and work again on v0.20–v0.22. Fast grain with every effect is the next project.

## Card files

`LOOKS.BIN` (your films, from the Control Panel), `EDITS.BIN` (your camera changes, written by the camera),
`BUNDLES.BIN` (written by the camera), `GUIDES.BIN` and `LABELS.BIN` (from the release, always with its firmware).
`NAMES.BIN` is only used by v0.17–v0.22. Formats: [FORMATS.md](FORMATS.md).
