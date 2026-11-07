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

- **Film** (0..5, 12 o'clock only): picks a look. **0** = nothing (the COLOR's factory settings), **1–5** = that
  COLOR's look, with its name under the wheel. Hold **OK** here to save your changes into the selected look. See
  [Looks and their names](#looks-and-their-names).
- **Saturation**: the camera's own.
- **Hue** (−5..+5): + turns a slice toward its clockwise neighbour (Yellow → Orange, Blue → Blue-cyan).
- **Light** (−5..+5): darker / brighter for that slice. Steps grow as they go out.
- **Extras**: ten effect sectors (below).

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
| 8 | 7 | **VigFix**: the lens's vignette (shading) correction for each photo with this look | 0 Camera (your Shading Comp. setting), 1 Off (natural corners) | Vig Cam / Vig Off |
| 9 | 8 | **Grain**: film grain from the camera's own grain engine | 0 Off, 1 Low, 2 Med, 3 High | Grain (with the number) |
| 10 | 9 | **Sharp**: the camera's sharpening for each photo with this look (v0.22) | −5..+2 in the camera's own numbers: 0 its normal, +1 / +2 crisper, −1..−4 softer (−3 and −4 go past the stock menu), −5 Off (no sharpening) | Sharp / Sharp Off |

- NR, Glow, Art Effects and VigFix are set per look, at every shot, without changing your menu settings. NR shows in
  the photo's recorded settings; its effect is mostly visible at high ISO.
- **Live view** shows Glow and the Art Effects as you frame. Clarity and Grain show only in the saved photo.
- The WB shift is added to the camera's own white balance and fine-tune, in every white balance mode including
  **Auto WB**.
- **Grain** is the same texture as the camera's Monochrome grain, on the colour photo, and Low / Med / High match the
  Monochrome levels. On its own, or with any of the other Extras, it is added by the camera's image processor: no
  delay. **With Glow / Clarity or an Art Effect** the camera can't add it that way, so it is added afterwards by the
  camera's processor in software (brightness only, the same look): each photo then takes **about 3 seconds longer to
  save**, and fast sequential (burst) shooting isn't possible with that look.
- **Sharp** replaces the camera's own Sharpness setting for COLOR 1–4: from v0.22 that row is no longer on the COLOR
  screen (Contrast is the last row), and the stock value is ignored for COLOR photos. Sharp 0 is exactly the camera's
  normal sharpening.
- The rear dial stops at each sector's first and last value.
- The labels come from `OM3MOD/LABELS.BIN`, and the effects from code at the end of `OM3MOD/GUIDES.BIN`. Copy both
  from the same release as the firmware: with an older `GUIDES.BIN` the Extras values still save but the effects
  don't run, and without `LABELS.BIN` the label just says "Vivid".

## Saving, reset and the `*`

Hold **OK**: what it does depends on where you are.

| Where | Hold OK |
|---|---|
| Film page, with a look (1–5) selected | **saves** the COLOR's current settings into that look. Nothing is reset here. |
| Saturation, Hue, Light or Extras page | **resets** the wheels: Saturation back to the factory setting, Hue, Light, the WB shift and every Extras value to 0. The selected look stays selected. |
| the "COLOR n" item of the Picture Mode list | **resets the whole COLOR**: every wheel, Extras value and Picture Mode setting back to the factory settings, and the Film page back to 0. |

A `*` next to the COLOR (and the look name) means something differs from the camera's **factory settings** for that
COLOR: any wheel, any Extras value, or a Picture Mode setting. After a reset, or with the Film page on 0, it's gone;
change anything and it's back. A selected look normally shows a `*` too, because the look itself changes settings.

## Looks and their names

Each of COLOR 1–4 has five look numbers. A look holds everything: the wheels (Saturation, Hue, Light), the Extras
page (NR, Glow/Clarity, WB shift, Art Effect, Blacks, Whites, VigFix, Grain, Sharp) plus Contrast, Shading and
Shadows/Midtones/Highlights. On the **Film** page, the 12 o'clock spot picks one, and the label under the wheel shows
its name:

| Dial | What loads | Label under the wheel |
|---|---|---|
| 0 | nothing: the COLOR's factory settings | **Film** |
| 1–5 with a look | that look | its name, e.g. **Velvia** |
| 1–5 with no look | neutral, ready to build a new one | **Empty** |

The names come from `OM3MOD/NAMES.BIN`. The camera can't draw text in that spot, only pictures, so the Control
Panel draws each name as a small picture in the camera's own label style and saves them in `NAMES.BIN` next to
`LOOKS.BIN`. The camera reads both at the first half-press after you switch on. It saves `LOOKS.BIN` itself
when you change looks, but it never changes `NAMES.BIN`: names only change when you save from the Control Panel.
Without `NAMES.BIN` (or with a damaged one) the label just says "Film".

### Make looks in the Control Panel

1. Open the [Caduceus Control Panel](https://androidfanman.github.io/caduceus-om3/) and check **OM SYSTEM OM-3** is
   selected at the very top (the other choice is the E-P7). The left side lists COLOR 1–4 with looks 1–5.
2. Click a number. For one that says **Empty**, choose **Blank look**, **From the built-in library…** or
   **Paste a code…** (a Caduceus look code or link). Click a look to edit it; × empties its number; drag or ↑ ↓
   moves it to another number.
3. Give it a name (up to 15 letters, numbers and symbols). Long names are squeezed to fit, and if one COLOR's five
   names don't fit the camera's space, its lettering is made a little smaller.
4. Set the **Extras** the same way as on the camera: NR, lens vignette correction, Grain, Sharp, Glow ↔ Clarity, Art Effect
   and the WB shift (Blacks and Whites are in the Tone panel). The preview shows the grain; drag the line on the photo
   to compare before and after. A look with Grain and Glow / Clarity or an Art Effect gets a note that it saves
   more slowly on the camera.
5. **Export › Save to card…** (Chrome or Edge on a computer) writes `LOOKS.BIN` and `NAMES.BIN` into the card's
   `OM3MOD` folder. Elsewhere, **Card folder (.zip)** downloads both: copy them into `OM3MOD` on the card.
6. Put the card in the camera, switch on and half-press once. Every COLOR starts at 0; turn the Film dial to a
   number to load that look.

Always copy both files together. Moving or emptying looks in the Control Panel changes their numbers, and the
names follow only if `NAMES.BIN` is copied too.

### Make a look on the camera

1. Open the COLOR's wheel, press **INFO** to the Film page and turn to a number that says **Empty**. Everything
   goes neutral.
2. Build the look on the wheel pages and in the normal Picture Mode settings (Contrast, Shading,
   Shadows/Midtones/Highlights).
3. Press **INFO** back to the Film page and **hold OK**: that saves it into that number. The next half-press writes
   `LOOKS.BIN` to the card. Turning to another number without holding OK first drops the changes.

It works straight away, but the label still says **Empty**: the camera has no way to type a name, and it doesn't
change `NAMES.BIN`. To name it:

1. Put the card in your computer and open the card's `OM3MOD/LOOKS.BIN` in the Control Panel (**Open…**). The camera's looks appear with their numbers; one you made shows as "Look n".
2. Type its name, then save both files back to the card as above.

Don't change looks on the camera between opening the card's `LOOKS.BIN` and copying the new files back: the
copy replaces the camera's whole bank. If you save it from the Control Panel without a name, it is labelled "Look n".

### Change or rename a look

- **On the camera:** select it on the Film page, change anything, then go back to the Film page and **hold OK** to
  keep the changes in the look (the next half-press writes them to the card). Turn to another look without holding OK
  and the look stays as it was saved: handy for trying things out. Its name stays.
- **In the Control Panel:** open the card's `LOOKS.BIN`, change or rename it, and save both files back.

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
