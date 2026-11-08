# Roadmap

What's planned for Caduceus for OM-3. Nothing here is promised or dated: features land when they work on a real camera.
Ideas and requests are welcome in [Issues](https://github.com/androidfanman/caduceus-om3/issues).

| Feature | What it means | Status |
|---|---|---|
| **More crop modes** | Extra aspect ratios such as XPan 65:24 and 21:9, as in Caduceus for the E-P7. | Planned |
| **Panasonic aperture rings** | The aperture ring on Panasonic lenses that have one sets the aperture on the OM-3. | Planned |
| **Fast grain with every effect** | Grain as fast as on its own together with Shading, Glow, Clarity and Art Effects (v0.24 switches Glow / Clarity and Art Effects off and adds grain slowly with Shading). Leads: run Shading in colour on fast-grain photos; copy how the Grainy Film Art Filter keeps its grain through Art Effects. | Researching |

## Video

| Feature | What it means | Status |
|---|---|---|
| **Colour profiles in video** | The colour profiles and their wheels (Hue, Light, Extras) also apply when recording video. | Planned |
| **10-bit beyond Log and HLG** | Today the OM-3 records 10-bit only with OM-Log400 or HLG; the other profiles are 8-bit H.264, which bands and blocks when graded. Allow 10-bit with the standard and COLOR profiles, or failing that, cleaner 8-bit encoding ([#1](https://github.com/androidfanman/caduceus-om3/issues/1)). | Investigating |

## Done

| Feature | Released |
|---|---|
| **Films in the Picture Mode list**: FILM 1, FILM 2, … after COLOR 1–4 with their names (title, quick menu, shooting screen); changes kept per film (`EDITS.BIN`); hold OK = as built; `*` = changed | v0.24 |
| **Picture Mode rows**: Blacks, Whites, A-B, G-M, Sharp, Noise Filter (High new), Vignette Correction and Film Grain on the camera's own screen; HSL wheel Color → Color All → Hue → Luminance | v0.24 |
| **Sharpness per look**: Sharp on the Extras page (−5 Off..+2), replacing the camera's Sharpness row on COLOR 1–4 | v0.22 |
| **Colour grain**: Off / Low / Med / High on the COLOR profiles, from the camera's own grain engine | v0.21 |

See the [changelog](CHANGELOG.md) for what each release already contains.
