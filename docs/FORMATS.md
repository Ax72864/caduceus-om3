# Card file formats (`C:\OM3MOD\`)

All multi-byte values little-endian. CRC-32 = zlib/PNG CRC-32. Signed values are s8.

## LOOKS.BIN v1 (1632 bytes)

Called `PROFILES.BIN` in v0.16–v0.18 (same format). v0.19 reads `LOOKS.BIN`, or `PROFILES.BIN` when there is no
`LOOKS.BIN`, and always writes `LOOKS.BIN`. v0.20 reads only `LOOKS.BIN` and adds the Extras bytes `+47..+49` (zero in
older files, which therefore load unchanged).

| Offset | Size | Field |
|---|---|---|
| 0 | 4 | magic `OM3P` |
| 4 | 4 | total length 1632 |
| 8 | 4 | CRC-32 of bytes 12..1631 |
| 12 | 2 | version 1 |
| 14 | 2 | record count 20 |
| 16 | 4 | selection per COLOR 1..4 (0..5; the camera writes what is selected, the Control Panel writes 0) |
| 20 | 12 | zero |
| 32 | 20 × 64 | records: COLOR k (0..3) look v (1..5) at index 5k + v − 1 |
| 1312 | 20 × 16 | names, ASCII, zero-padded (up to 15 characters) |

Record (64 bytes): `+0` hue[12], `+12` light[12], `+24` saturation[12] (all −5..5, slices clockwise from Yellow),
`+36` WB shift on (0/1), `+37` A/B, `+38` G/M, `+39` Blacks, `+40` Whites (−5..5), `+41` Contrast (−2..2),
`+42` Sharpness (−2..2), `+43` Shading (−5..5), `+44` Shadows, `+45` Midtones, `+46` Highlights (−7..7),
v0.20: `+47` Glow (−5..−1) / Clarity (1..5), `+48` Art Effect (0 Off, 1 Star Light, 2 Pin Hole, 3 none, 4 White Edge,
5 Frame: the Caduceus ids), `+49` NR (0 Camera, 1 Standard, 2 Low, 3 Off), `+50..63` zero. Bytes `+47..+49` are
checked as −5..5 by the camera; the editor keeps them in the ranges above.

The camera checks size, magic, CRC, version, selection range and every record byte's range; a file that fails is
ignored and left alone (the Looks page is then hidden). With no file, the camera starts a neutral bank and
writes the file the first time a look is used. Writes go to `LOOKS.NEW`, are read back, then to `LOOKS.BIN`.

Generators: `card/mkprofiles.py` (JSON → file) and the Control Panel (`webapp/src/om3.ts`: `profilesBin` / `readProfiles`), byte-identical
(`webapp/tests/om3.test.ts`).

## BUNDLES.BIN (544 bytes)

Caduceus BUNDLES.BIN v1 layout with OM-3 identity: `OM3B` | u16 version 1 | u16 header 32 | u32 firmware build 1100 |
u32 payload 512 | u32 CRC-32 over bytes 0..15 + 20..543 | 4 bytes decoded-firmware SHA-256 prefix | 8 zero |
8 slots × 64 bytes (slot k = COLOR k+1): hue[12] `+0`, light[12] `+12`, `+25` WB flags (bit 0 on), `+26` A/B,
`+27` G/M, `+31` flags (bit 1 = Hue/Light on), `+47` Blacks, `+48` Whites, v0.20 Extras: `+49` Glow/Clarity,
`+50` Art Effect, `+51` NR (as the LOOKS.BIN record's `+47..+49`).

## GUIDES.BIN v4

`OM3G` | u32 total | u32 CRC-32 of bytes 12.. | u16 width 175 | u16 height 50 | u32 length of streams 1..4 |
streams (Hue, Light, Extras, Film; before v0.20: Hue, Light, WB/BW, Looks), each padded to 4 bytes. Streams are OM-3
OSD type-11 pictures (palette indices, run-length tokens); see `card/mkguides.py`.

From v0.20 the file ends with the **Extras code block** (our code, built from `firmware/src/xblock.s` by
`firmware/build.py`): code (linked at 0x10000000) | u32 relocations (bit 31 set: absolute, + delta; else
PC-relative to the firmware, − delta) | {u32 tag, u32 end − code, u32 code length, u32 count}. The firmware loads it
with the pictures, checks the tag (made from the firmware image, so a block only runs on the firmware it was built
with), relocates it in its heap buffer and runs the Extras effects from it. A `GUIDES.BIN` without a matching block
still gives the page labels; the Extras values then save but don't change the photo.

## LABELS.BIN v2 (5686 bytes, v0.20)

The Extras labels next to the value (the stock "Vivid" picture, 70 × 30). `OM3V` | u32 total | u32 CRC-32 of bytes
12.. | u32 count 21 | 21 bitmaps of 30 rows × 9 bytes (70 px, MSB first, 1 = letter). The camera draws the picture
from the bitmap (white letters, a 1 px dark edge, grey out to 2 px) and encodes it only when the label changes.
Labels, in order: NR, NR Std, NR Low, NR Off · Glow, Clarity, Glo/Cla · B, A, A/B · M, G, G/M · Art Off, Star,
Pin Hole, Art Off, W. Edge, Frame · Blacks, Whites. See `card/mklabels.py`.

## NAMES.BIN v1

Pictures of the look names, shown under the wheel on the Film page. Written by the Control Panel (`webapp/src/om3names.ts`: `namesBin`)
together with `LOOKS.BIN`, in the camera's label style (`card/mkguides.py` metrics).

| Offset | Size | Field |
|---|---|---|
| 0 | 4 | magic `OM3N` |
| 4 | 4 | total length |
| 8 | 4 | CRC-32 of bytes 12..end |
| 12 | 2 | version 1 |
| 14 | 2 | entry count 20 |
| 16 | 2 | picture width 175 |
| 18 | 2 | picture height 50 |
| 20 | 12 | zero |
| 32 | 4 × 8 | groups {u32 offset, u32 length}: COLOR k's five pictures, contiguous from 144, each group ≤ 16384 bytes |
| 64 | 20 × 4 | entries {u16 offset in its group, u16 length}: COLOR k look v at 5k + v − 1 (length 0 = none) |
| 144 | … | group data: OSD type-11 pictures, 175 × 50, each 4-byte aligned |

The camera loads each group into its own buffer at the first half-press and checks the CRC and every picture's
header; a file that fails is ignored (the label then says "Film").
