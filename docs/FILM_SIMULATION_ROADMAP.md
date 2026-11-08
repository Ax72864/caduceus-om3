# Film Simulation Roadmap

**Goal:** make the OM-3 with Caduceus the best film-replicating camera available: looks that render like real film
stock straight out of the camera, and that load and shoot like a roll of film.

Last updated 2026-11-07 (evening: space probes, split toning research). Update the status column as work moves, and add findings to the research log at the end
(details go in [`research/NOTES.md`](../research/NOTES.md)). The general roadmap is [`ROADMAP.md`](../ROADMAP.md).

**Effort:** Low = a few sessions on known hooks · Medium = new firmware work on parts we already understand ·
Large = a new area of the firmware · Hard = no camera feature to borrow, everything drawn or computed by us.
**Status:** Not started · Researching · Proven possible · Building · Camera testing · Done · Parked.
Efforts are estimates from what we know of the firmware today.

**Gate for most items: firmware space.** The space proven safe is almost full. The firmware-space probe
(branch [`experiment/firmware-space-probe`](../../../tree/experiment/firmware-space-probe)) ran on the camera on
2026-11-07: moving a section's loaded end works. **64 KiB proven** (section 6, with photos, video and Wi-Fi in use), so
new features have room; more can be opened up the same way.

## Next steps

1. **Move the picture-mode slider code into the proven 64 KiB** and make a safe sliders test build.
   (Space probes done 2026-11-07: 4 KiB, then 64 KiB, loaded and intact on the camera.)
2. **Research coloured glow (halation)** in the emulator: whether the Soft Focus glow can take a colour, as on the
   E-P7. (Split toning research done 2026-11-07: see the table; building it can now use the proven 64 KiB.)
3. **White balance mode and exposure compensation per look:** quick wins that make a look behave like a roll.
4. **Finish the picture-mode sliders** (branch
   [`feature/v0.23-alpha-profile-sliders`](../../../tree/feature/v0.23-alpha-profile-sliders)) once there is safe space for their code.

## The film look itself

| Feature | Why it matters for film | Effort | Status | Research notes |
|---|---|---|---|---|
| Split toning: colour by brightness | Teal shadows and warm highlights (cinema), cool shadows (Portra), green shadows (Superia). The colour wheel works by hue only. | Medium | Researching (mechanism found, emulator) | Cross Process and (likely) Vintage do it with three different R/G/B tone curves in the camera's RGB gamma stage. The job keeps its own copy of the curves, so a look can bend them: 6 bytes per look, about 100-150 B of code. Emulator-checked on the stock code; not camera-tested. Blocked by code space (needs a hook in sections 1-5, or the space probe). |
| Coloured glow (halation) | The red glow around lights of CineStill and other cinema film. | Medium | Not started | Our glow runs on the camera's Soft Focus blend. Caduceus for the E-P7 has a glow colour; the OM-3 port left it out. Check the OM-3 blend for a colour input. |
| Highlight roll-off and toe | Film compresses highlights gently and has a soft toe in the blacks. | Medium | Not started | We already hook the tone curve builder (Highlights / Shadows / Midtones, Blacks / Whites). Add a shoulder setting, and colour that fades toward white. |
| Grain by brightness, size and roughness | Film grain is strongest in the midtones and depends on the stock. | Medium | Not started | Today: the camera's Monochrome grain (Low / Med / High), the same everywhere. Look for its size and strength parameters. |
| Faster grain with Glow or Art Effects | Grain plus glow costs about 3 s per photo and blocks burst shooting. | Medium | Researching | On the main roadmap. The v0.21 timing work on the slow route is the starting point. |

## Shooting like a roll of film

| Feature | Why it matters for film | Effort | Status | Research notes |
|---|---|---|---|---|
| White balance mode per look | Tungsten film (CineStill 800T) shoots at 3200 K, daylight film at 5500 K. Today a look can only shift WB. | Low | Not started | Looks already write 18 camera settings when chosen; WB mode and Kelvin are more of the same kind. |
| Exposure compensation per look | Overexposed Portra, pushed Tri-X. Optional per look. | Low | Not started | Same route. Decide whether it adds to the user's exposure dial or sets it. |
| ISO per look | "Load" Portra 400 and the camera shoots at ISO 400. Optional. | Low | Not started | Same route. Off by default. |
| Frame shape per look | XPan 65:24, square 6×6, 4:5 for 6×7, half-frame. | Medium | Not started | Ties into the crop modes on the main roadmap (Caduceus for the E-P7 has XPan and 21:9). |
| Film borders | A black film-edge or an instant-print border, besides today's white Frame. | Medium | Not started | The Frame Art Effect already draws our own border. New borders are generic shapes, not copies of film-stock markings. |

## Bigger projects

| Feature | Why it matters for film | Effort | Status | Research notes |
|---|---|---|---|---|
| Black-and-white film looks | Tri-X, HP5, Delta 3200, Acros. Looks are COLOR-only today. | Large | Not started | Needs the Monochrome profiles: colour filter, toning, grain, contrast and the Film-page bank. Their editor is separate from the COLOR wheel. |
| Film looks in video | Rare among cameras. | Large | Not started | On the main roadmap. v0.22's Sharp is photos only; the video path was not traced. |
| Light leaks and date stamps | Point-and-shoot touches. | Hard | Parked | No camera feature to borrow. Lowest priority. |

## Control Panel

| Feature | Why it matters for film | Effort | Status | Research notes |
|---|---|---|---|---|
| A preview calibrated to the camera | Film sims and photo-matched looks are only as good as the preview's model of the OM-3. | Medium | Not started | Shoot a colour chart and scenes on the OM-3 at each setting step, then fit the preview to them. |
| Photo-to-look instructions | Build a look from any photo, opened by a link. | Low | Done | [`docs/PHOTO_TO_LOOK.md`](PHOTO_TO_LOOK.md), tested end to end 2026-11-07. |

## Already done

| Date | Item | What it gives film looks |
|---|---|---|
| 2026-11-07 | v0.22 Sharp | Sharpening per look, −5 (Off) to +2; film sims set it. |
| 2026-11-07 | Photo-to-look instructions | A look built from any photo, loaded by a link. |
| 2026-11-06 | 60 film sims | Our own looks, one per film, in five groups. |
| 2026-11-06 | v0.21 Grain and VigFix | The camera's own grain on colour photos; lens vignette correction off per look. |
| 2026-11-05 | v0.20 Extras page | NR per look, Glow / Clarity, WB shift, Art Effects, Blacks / Whites, white Frame. |
| 2026-11-05 | v0.19 Looks | Five complete looks per COLOR with names, chosen on the Film page. |

## Research log

Newest first. Full details in [`research/NOTES.md`](../research/NOTES.md).

| Date | Topic | Finding |
|---|---|---|
| 2026-11-07 | Firmware space (camera) | 64 KiB probe: section 6 loads 64 KiB more; all 16248 pattern words intact after photos and a video. New features can use that space. |
| 2026-11-07 | Firmware space (camera) | Probe on the camera: moving section 6's loaded end by 4 KiB works; the code there ran, its pattern stayed intact over 45 checks (photos, video and Wi-Fi in use), and nothing wrote into any gap. Gaps hold no file bytes unless a loaded end is moved. |
| 2026-11-07 | Split toning | Cross Process (and likely Vintage) tint by brightness with separate R/G/B tone curves in the RGB gamma stage. COLOR photos use one curve for all three; the job copies it, so our code could bend each channel after the copy. Emulator-checked on stock code; a design and preview model exist; building needs code space. |
| 2026-11-07 | Firmware space | The camera does not load the empty stretches between firmware sections; the sliders test put code in one and must not be flashed. |
| 2026-11-07 | Picture-mode sliders | Camera slider rows can be pointed at our own values with their own range, readout and end stops. Sharp works this way in the emulator. |
| 2026-11-07 | Sharp and video | Sharp changes the photo capture path only; video most likely keeps the hidden stock Sharpness. Not tested. |
| 2026-11-06 | Firmware space | About 2.3 MiB of empty space sits between sections; nothing wrote to it in the emulator. The probe build tests whether the camera can load and use it. |
