# Using the colour editor on the camera

> **Color profiles only:** this is for Picture Mode COLOR 1–4. The Monochrome profiles keep the camera's own editor.

Picture Mode › **COLOR 1–4** › press **▼** to open the Color Profile wheel. It opens on the **Looks** page (v0.18;
on a card without a usable `LOOKS.BIN`, on Saturation). **INFO** changes the page:

**Looks** → Saturation → (Saturation ALL) → **Hue** → **Light** → **WB/BW** → **Looks**

The label under the wheel shows the page. The rear dial picks a colour slice and the front dial changes the value,
the same as the stock Saturation wheel. Slices run clockwise from Yellow at 12 o'clock: Yellow, Orange, Orange-red,
Red, Magenta, Violet, Blue, Blue-cyan, Cyan, Green-cyan, Green, Yellow-green.

## Pages

- **Saturation**: the camera's own.
- **Hue** (−5..+5): + turns a slice toward its clockwise neighbour (Yellow → Orange, Blue → Blue-cyan).
- **Light** (−5..+5): darker / brighter for that slice. Steps grow as they go out.
- **WB/BW**: 12 o'clock A/B (+ amber, − blue), 6 o'clock G/M (+ green, − magenta), 3 o'clock **Blacks**
  (+ lifts/fades, − crushes), 9 o'clock **Whites** (+ brighter, − softer). Other slices do nothing.
- **Looks** (0..5, 12 o'clock only):
  - **0**: nothing. Everything goes neutral.
  - **1–5**: loads that COLOR's look: all wheels plus Contrast, Sharpness, Shading and
    Shadows/Midtones/Highlights. An empty number loads neutral, ready to build a new look.
  - Whatever you change while a look is selected (wheels or the normal menu items) belongs to that look.
    Turning to another number keeps it, and the next half-press saves the bank to the card.
  - Each COLOR has its own five looks.
  - The label under the wheel shows the selected look's name ("Empty" for a number with no look), from
    `NAMES.BIN`. At 0 it says "Looks".

Holding **OK** on the wheel, or on the "COLOR n" item of the picture-mode list, resets that COLOR's wheels
(Saturation, Hue, Light and WB/BW) to 0. A `*` next to a COLOR means it has been changed.

## Looks and their names

Each of COLOR 1–4 has five look numbers. A look holds everything: the four wheels (Saturation, Hue, Light,
WB/BW) plus Contrast, Sharpness, Shading and Shadows/Midtones/Highlights. On the **Looks** page, the 12 o'clock
spot picks one, and the label under the wheel shows its name:

| Dial | What loads | Label under the wheel |
|---|---|---|
| 0 | nothing: everything neutral | **Looks** |
| 1–5 with a look | that look | its name, e.g. **Velvia** |
| 1–5 with no look | neutral, ready to build a new one | **Empty** |

The names come from `OM3MOD/NAMES.BIN`. The camera can't draw text in that spot, only pictures, so the Control
Panel draws each name as a small picture in the camera's own label style and saves them in `NAMES.BIN` next to
`LOOKS.BIN`. The camera reads both at the first half-press after you switch on. It saves `LOOKS.BIN` itself
when you change looks, but it never changes `NAMES.BIN`: names only change when you save from the Control Panel.
Without `NAMES.BIN` (or with a damaged one) the label just says "Looks".

### Make looks in the Control Panel

1. Open the [Caduceus Control Panel](https://androidfanman.github.io/caduceus-om3/) and check **OM SYSTEM OM-3** is
   selected at the very top (the other choice is the E-P7). The left side lists COLOR 1–4 with looks 1–5.
2. Click a number. For one that says **Empty**, choose **Blank look**, **From the built-in library…** or
   **Paste a code…** (a Caduceus look code or link). Click a look to edit it; × empties its number; drag or ↑ ↓
   moves it to another number.
3. Give it a name (up to 15 letters, numbers and symbols). Long names are squeezed to fit, and if one COLOR's five
   names don't fit the camera's space, its lettering is made a little smaller.
4. **Export › Save to card…** (Chrome or Edge on a computer) writes `LOOKS.BIN` and `NAMES.BIN` into the card's
   `OM3MOD` folder. Elsewhere, **Card folder (.zip)** downloads both: copy them into `OM3MOD` on the card.
5. Put the card in the camera, switch on and half-press once. Every COLOR starts at 0; turn the Looks dial to a
   number to load that look.

Always copy both files together. Moving or emptying looks in the Control Panel changes their numbers, and the
names follow only if `NAMES.BIN` is copied too.

### Make a look on the camera

1. Open the COLOR's wheel, press **INFO** to the Looks page and turn to a number that says **Empty**. Everything
   goes neutral.
2. Build the look on the wheel pages and in the normal Picture Mode settings (Contrast, Sharpness, Shading,
   Shadows/Midtones/Highlights). Everything you change belongs to that number.
3. Half-press: the camera saves it into `LOOKS.BIN` on the card.

It works straight away, but the label still says **Empty**: the camera has no way to type a name, and it doesn't
change `NAMES.BIN`. To name it:

1. Put the card in your computer and open the card's `OM3MOD/LOOKS.BIN` in the Control Panel (**Open…**). The camera's looks appear with their numbers; one you made shows as "Look n".
2. Type its name, then save both files back to the card as above.

Don't change looks on the camera between opening the card's `LOOKS.BIN` and copying the new files back: the
copy replaces the camera's whole bank. If you save it from the Control Panel without a name, it is labelled "Look n".

### Change or rename a look

- **On the camera:** select it on the Looks page and change anything; the next half-press saves it. Its name
  stays.
- **In the Control Panel:** open the card's `LOOKS.BIN`, change or rename it, and save both files back.

## Files on the card (`OM3MOD`)

| File | What it is |
|---|---|
| `BUNDLES.BIN` | the wheels' current values (written by the camera; `.NEW` / `.BAK` are its safety copies) |
| `LOOKS.BIN` | the look bank: 4 COLORs × 5 looks. Made by the camera, or by the Control Panel |
| `GUIDES.BIN` | the page labels under the wheel (optional; without it the stock label shows) |
| `NAMES.BIN` | the look names for the Looks page, made by the Control Panel with `LOOKS.BIN` (optional; the camera never changes it) |

Copying a `LOOKS.BIN` from the Control Panel replaces the camera's bank. To keep looks made on the camera, open
the card's `LOOKS.BIN` in the Control Panel first, edit, then save back. Its file starts every COLOR at 0, so
your current camera settings stay until you pick a look.
