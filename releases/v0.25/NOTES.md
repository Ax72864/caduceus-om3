# Caduceus for OM-3 v0.25

**Fast colour film grain, a WB grid row, a Glow row, settings kept over power off, and 20 new film sims.**

- **Fast colour grain:** Film Grain (Low / Med / High) is added by the camera's image processor as the photo is
  developed, in full colour, and saves as fast as a photo without grain, with every other setting. Three clearly
  different steps, no change in brightness or colour.
- **WB row:** one row in place of A-B and G-M, with a small grid preview and the numbers under WB± (like "A2.G1").
  **OK**, left / right or a dial opens the camera's own WB fine-tune screen on the film's shift.
- **Glow row:** + is Glow (soft glow), − is Clarity (local contrast).
- **Shading is back**, with its number in line, and works with grain.
- **Kept over power off:** your changes to films and COLOR 1–4, and the film you were on.
- Picture Mode opens on its top row; the viewfinder shows the film's name.
- **No Art Effects any more** (Star Light, Pin Hole, White Edge and Frame are gone; Shading does the dark corners).
- Everything from v0.24.1 stays: films in the Picture Mode list, changes kept per film, Hold OK resets.
- Firmware camera-tested.

## The 20 film sims (optional `LOOKS.BIN`)

Our own looks, designed from what each film is known for and made only of the camera's settings (no grain, Glow /
Clarity or Art Effects, so you can add those yourself). On the camera they're FILM 1–20 after COLOR 1–4:

| FILM | Name | The look |
|---|---|---|
| 1 | Portra 400 | Warm, soft contrast, natural skin, bright and airy |
| 2 | Gold 200 | Warm and golden, rich yellows |
| 3 | Kodachrome 64 | Deep reds, golden yellows, dark rich blues, dense shadows |
| 4 | Portra 800 | Warmer and richer than Portra 400 |
| 5 | CineStill 800T | Cool, teal-leaning night look with warm skin and strong reds |
| 6 | Ektar 100 | Saturated and punchy, bold reds, clean blues |
| 7 | Ultramax 400 | Warm, saturated, punchy |
| 8 | Pro 400H | Soft pastels, airy highlights, minty greens, cyan skies |
| 9 | Velvia 50 | Very saturated landscape slide, deep blues, lush greens |
| 10 | Superia 400 | Green-leaning, cyan skies, snappy |
| 11 | ColorPlus 200 | Warm, yellow-golden, softer and more muted than Gold |
| 12 | CineStill 400D | Soft, warm daylight, pastel colour |
| 13 | Fuji C200 | Cool greens and blues, clear and airy |
| 14 | Ektachrome E100 | Clean, neutral slide colour, crisp, clear blues |
| 15 | Reala 100 | Natural, accurate colour |
| 16 | Provia 100F | Accurate slide colour, clean skies, crisp |
| 17 | Vision3 250D | Natural, very soft daylight cinema look, open shadows |
| 18 | Fuji Eterna | Muted, understated cinema look, soft contrast |
| 19 | Astia 100F | Soft slide film for people, gentle contrast |
| 20 | Agfa Ultra 100 | Extremely saturated, bold reds and blues |

The names describe what inspired each look; they aren't the film makers' own products or presets. They were tuned on
the Control Panel's preview (an approximation of the camera): check them in live view and adjust to taste.

**Copy to the card:** `DCOLYMP` (flash it) and the `OM3MOD` files `GUIDES.BIN` (made for this firmware: always copy
it with it) and `LABELS.BIN`. Keep your `EDITS.BIN`, `NAMES.BIN` and `BUNDLES.BIN`.
**To get the 20 films:** also copy this release's `LOOKS.BIN` (on the release page, or in `releases/v0.25` of the
project) to `OM3MOD`. This **replaces your own films**, so keep a
copy of your old `LOOKS.BIN` if you want it (changes you made on the camera to the old films no longer apply). Or
build your own set in the Control Panel: it starts with the same 20 (**New › Reset looks to standard**), and exports
with "v0.25 or later".

**Going back to v0.24.1 or older:** flash that version with its own `GUIDES.BIN`; your files still work.

Make it: run the launcher and press Return (or `python3 firmware/patch.py --release v0.25`). The files here are the
patch (only the bytes Caduceus for OM-3 adds; no OM firmware), the card files and the expected checksums. Full list of
changes: [CHANGELOG](../../CHANGELOG.md#v025).
