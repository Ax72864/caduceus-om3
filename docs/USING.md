# Using the colour editor on the camera

> **Color profiles only:** this is for Picture Mode COLOR 1–4. The Monochrome profiles keep the camera's own editor.

Picture Mode › **COLOR 1–4** › press **▼** to open the Color Profile wheel. It opens on the **Film** page (on a card
without a usable `LOOKS.BIN`, on Saturation). **INFO** changes the page, wherever the selector is:

**Film** → Saturation → (Saturation ALL) → **Hue** → **Light** → **Extras** → **Film**

The label under the wheel shows the page. The **front dial** moves the selector around the wheel and the **rear
dial** changes the value, as on the stock Saturation wheel. On Saturation, the first INFO is the camera's own step to
"all colours" and the second goes on to Hue.

Colour slices run clockwise from Yellow at 12 o'clock: Yellow, Orange, Orange-red, Red, Magenta, Violet, Blue,
Blue-cyan, Cyan, Green-cyan, Green, Yellow-green.

## Pages

- **Film** (0..5, 12 o'clock only): picks a look. **0** = nothing (everything neutral), **1–5** = that COLOR's look,
  with its name under the wheel. See [Looks and their names](#looks-and-their-names).
- **Saturation**: the camera's own.
- **Hue** (−5..+5): + turns a slice toward its clockwise neighbour (Yellow → Orange, Blue → Blue-cyan).
- **Light** (−5..+5): darker / brighter for that slice. Steps grow as they go out.
- **Extras**: eight effect sectors (below).

## The Extras page

Sector 1 is at 12 o'clock and the others follow clockwise, one per hour. The label next to the value (where the
stock wheel says "Vivid") names the sector and what its value does.

| Sector | Clock | What it does | Values | Label |
|---|---|---|---|---|
| 1 | 12 | **NR**: the camera's noise reduction (Noise Filter) for each photo with this look | 0 Camera (your menu setting), 1 Std, 2 Low, 3 Off (most texture) | NR / NR Std / NR Low / NR Off |
| 2 | 1 | **Glow ← → Clarity** | −1..−5 glow (soft highlight bloom, −5 strongest), +1..+5 clarity (local contrast), 0 off | Glow / Clarity / Glo/Cla |
| 3 | 2 | **WB amber / blue** | + amber, − blue (−5..+5) | A / B / A/B |
| 4 | 3 | **WB green / magenta** | + green, − magenta (−5..+5) | G / M / G/M |
| 5 | 4 | **Art Effect** | 0 Off, 1 Star Light, 2 Pin Hole, 4 White Edge, 5 Frame (a clean white border); 3 does nothing (Caduceus numbers) | Art Off / Star / Pin Hole / W. Edge / Frame |
| 6 | 5 | **Blacks**: the dark end of the tone curve | + lifts / fades, − crushes (−5..+5) | Blacks |
| 7 | 6 | **Whites**: the bright end | + brighter, − softer (−5..+5) | Whites |
| 8 | 7 | (reserved) | – | Vivid |

- NR, Glow and Art Effects are set per look, at every shot, without changing your menu settings. NR shows in the
  photo's recorded settings; its effect is mostly visible at high ISO.
- **Live view** shows Glow and the Art Effects as you frame. Clarity shows only in the saved photo.
- The WB shift is added to the camera's own white balance and fine-tune.
- The labels come from `OM3MOD/LABELS.BIN`, and the effects from code at the end of `OM3MOD/GUIDES.BIN`. Copy both
  from the same release as the firmware: with an older `GUIDES.BIN` the Extras values still save but the effects
  don't run, and without `LABELS.BIN` the label just says "Vivid".

## Reset and the `*`

Hold **OK** on the wheel, or on the "COLOR n" item of the Picture Mode list, to reset that COLOR: Saturation, Hue,
Light and every Extras value go back to 0. A `*` next to the COLOR (and the look name) means something has been
changed, Extras included.

## Looks and their names

Each of COLOR 1–4 has five look numbers. A look holds everything: the wheels (Saturation, Hue, Light), the Extras
page (NR, Glow/Clarity, WB shift, Art Effect, Blacks, Whites) plus Contrast, Sharpness, Shading and
Shadows/Midtones/Highlights. On the **Film** page, the 12 o'clock spot picks one, and the label under the wheel shows
its name:

| Dial | What loads | Label under the wheel |
|---|---|---|
| 0 | nothing: everything neutral | **Film** |
| 1–5 with a look | that look | its name, e.g. **Velvia** |
| 1–5 with no look | neutral, ready to build a new one | **Empty** |

The names come from `OM3MOD/NAMES.BIN`. The camera can't draw text in that spot, only pictures, so the Control
Panel draws each name as a small picture in the camera's own label style and saves them in `NAMES.BIN` next to
`LOOKS.BIN`. The camera reads both at the first half-press after you switch on. It saves `LOOKS.BIN` itself
when you change looks, but it never changes `NAMES.BIN`: names only change when you save from the Control Panel.
Without `NAMES.BIN` (or with a damaged one) the label just says "Film".

### Make looks in the Control Panel

1. Open cakelesscoder's [Caduceus Control Panel](https://cakelesscoder.github.io/caduceus-ep7/). The first time, its setup pop-up asks for your camera:
   choose **OM SYSTEM OM-3** (later: the **Camera** button).
2. Your looks are one list, and its order is the Film page: the first 20 colour looks go to COLOR 1 looks 1–5,
   COLOR 2 looks 1–5, and so on. Drag looks in the list to give them other numbers. Add looks from the built-in
   library, a Caduceus look code or link, or start a new one.
3. Give each look a name (up to 15 letters, numbers and symbols). Long names are squeezed to fit, and if one
   COLOR's five names don't fit the camera's space, its lettering is made a little smaller.
4. Set the **Extras** the same way as on the camera: NR, Glow ↔ Clarity, Art Effect and the WB shift (Blacks and
   Whites are with the tone).
5. **Export** › **Card folder (.zip)** downloads `OM3MOD/LOOKS.BIN` and `OM3MOD/NAMES.BIN`: unzip it at the card's
   top level (never into `DCOLYMP`), or use the single-file buttons and put both files in `OM3MOD`.
6. Put the card in the camera, switch on and half-press once. Every COLOR starts at 0; turn the Film dial to a
   number to load that look.

Always copy both files together: the names only match their looks if `NAMES.BIN` is copied too.

### Make a look on the camera

1. Open the COLOR's wheel, press **INFO** to the Film page and turn to a number that says **Empty**. Everything
   goes neutral.
2. Build the look on the wheel pages and in the normal Picture Mode settings (Contrast, Sharpness, Shading,
   Shadows/Midtones/Highlights). Everything you change belongs to that number.
3. Half-press: the camera saves it into `LOOKS.BIN` on the card.

It works straight away, but the label still says **Empty**: the camera has no way to type a name, and it doesn't
change `NAMES.BIN`. To name it:

1. Put the card in your computer and open the card's `OM3MOD/LOOKS.BIN` in the Control Panel (**Open…**). The
   camera's looks appear in the list in their order; one you made shows as "Look n". Empty numbers close up, so
   check the order (drag looks back) before you export.
2. Type its name, then export both files back to the card as above.

Don't change looks on the camera between opening the card's `LOOKS.BIN` and copying the new files back: the
copy replaces the camera's whole bank. If you save it from the Control Panel without a name, it is labelled "Look n".

### Change or rename a look

- **On the camera:** select it on the Film page and change anything; the next half-press saves it. Its name
  stays.
- **In the Control Panel:** open the card's `LOOKS.BIN`, change or rename it, and export both files back.

## Files on the card (`OM3MOD`)

| File | What it is |
|---|---|
| `BUNDLES.BIN` | the wheels' current values (written by the camera; `.NEW` / `.BAK` are its safety copies) |
| `LOOKS.BIN` | the look bank: 4 COLORs × 5 looks. Made by the camera, or by the Control Panel |
| `GUIDES.BIN` | the page labels under the wheel and, from v0.20, the Extras effects code (keep it with its firmware) |
| `LABELS.BIN` | the Extras labels next to the value (v0.20; optional, without it the label says "Vivid") |
| `NAMES.BIN` | the look names for the Film page, made by the Control Panel with `LOOKS.BIN` (optional; the camera never changes it) |

Copying a `LOOKS.BIN` from the Control Panel replaces the camera's bank. To keep looks made on the camera, open
the card's `LOOKS.BIN` in the Control Panel first, edit, then save back. Its file starts every COLOR at 0, so
your current camera settings stay until you pick a look.

Coming from v0.17 or v0.18? Your bank there is `PROFILES.BIN`; from v0.20 the camera reads only `LOOKS.BIN`. Rename
`PROFILES.BIN` to `LOOKS.BIN` (same format), or open it in the Control Panel and save `LOOKS.BIN`.
