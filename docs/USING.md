# Using the colour editor on the camera

> **Color profiles only:** this is for Picture Mode COLOR 1–4. The Monochrome profiles keep the camera's own editor.

Picture Mode › **COLOR 1–4** › press **▼** to open the Color Profile wheel. **INFO** changes the page:

Saturation → (Saturation ALL) → **Hue** → **Light** → **WB/BW** → **Profiles** → Saturation

The label under the wheel shows the page. The rear dial picks a colour slice and the front dial changes the value,
the same as the stock Saturation wheel. Slices run clockwise from Yellow at 12 o'clock: Yellow, Orange, Orange-red,
Red, Magenta, Violet, Blue, Blue-cyan, Cyan, Green-cyan, Green, Yellow-green.

## Pages

- **Saturation**: the camera's own.
- **Hue** (−5..+5): + turns a slice toward its clockwise neighbour (Yellow → Orange, Blue → Blue-cyan).
- **Light** (−5..+5): darker / brighter for that slice. Steps grow as they go out.
- **WB/BW**: 12 o'clock A/B (+ amber, − blue), 6 o'clock G/M (+ green, − magenta), 3 o'clock **Blacks**
  (+ lifts/fades, − crushes), 9 o'clock **Whites** (+ brighter, − softer). Other slices do nothing.
- **Profiles** (0..5, 12 o'clock only):
  - **0**: nothing. Everything goes neutral.
  - **1–5**: loads that COLOR's profile: all wheels plus Contrast, Sharpness, Shading and
    Shadows/Midtones/Highlights. An empty number loads neutral, ready to build a new profile.
  - Whatever you change while a profile is selected (wheels or the normal menu items) belongs to that profile.
    Turning to another number keeps it, and the next half-press saves the bank to the card.
  - Each COLOR has its own five profiles.

Holding **OK** on the wheel, or on the "COLOR n" item of the picture-mode list, resets that COLOR's wheels
(Saturation, Hue, Light and WB/BW) to 0. A `*` next to a COLOR means it has been changed.

## Files on the card (`OM3MOD`)

| File | What it is |
|---|---|
| `BUNDLES.BIN` | the wheels' current values (written by the camera; `.NEW` / `.BAK` are its safety copies) |
| `PROFILES.BIN` | the profile bank: 4 COLORs × 5 profiles. Made by the camera, or by the Look Lab |
| `GUIDES.BIN` | the page labels under the wheel (optional; without it the stock label shows) |

Copying a `PROFILES.BIN` from the Look Lab replaces the camera's bank. To keep profiles made on the camera, open
the card's `PROFILES.BIN` in the Look Lab first, edit, then save back. A Look Lab file starts every COLOR at 0, so
your current camera settings stay until you pick a profile.
