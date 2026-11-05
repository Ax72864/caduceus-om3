# Card file formats (`C:\OM3MOD\`)

All multi-byte values little-endian. CRC-32 = zlib/PNG CRC-32. Signed values are s8.

## PROFILES.BIN v1 (1632 bytes)

| Offset | Size | Field |
|---|---|---|
| 0 | 4 | magic `OM3P` |
| 4 | 4 | total length 1632 |
| 8 | 4 | CRC-32 of bytes 12..1631 |
| 12 | 2 | version 1 |
| 14 | 2 | record count 20 |
| 16 | 4 | selection per COLOR 1..4 (0..5; the camera writes what is selected, the Look Lab writes 0) |
| 20 | 12 | zero |
| 32 | 20 × 64 | records: COLOR k (0..3) profile v (1..5) at index 5k + v − 1 |
| 1312 | 20 × 16 | names, ASCII, zero-padded (up to 15 characters) |

Record (64 bytes): `+0` hue[12], `+12` light[12], `+24` saturation[12] (all −5..5, slices clockwise from Yellow),
`+36` WB shift on (0/1), `+37` A/B, `+38` G/M, `+39` Blacks, `+40` Whites (−5..5), `+41` Contrast (−2..2),
`+42` Sharpness (−2..2), `+43` Shading (−5..5), `+44` Shadows, `+45` Midtones, `+46` Highlights (−7..7), `+47..63` zero.

The camera checks size, magic, CRC, version, selection range and every record byte's range; a file that fails is
ignored and left alone (the Profiles page is then hidden). With no file, the camera starts a neutral bank and
writes the file the first time a profile is used. Writes go to `PROFILES.NEW`, are read back, then to `PROFILES.BIN`.

Generators: `card/mkprofiles.py` (JSON → file) and the Look Lab (`profilesBin` / `readProfiles`), byte-identical.

## BUNDLES.BIN (544 bytes)

Caduceus BUNDLES.BIN v1 layout with OM-3 identity: `OM3B` | u16 version 1 | u16 header 32 | u32 firmware build 1100 |
u32 payload 512 | u32 CRC-32 over bytes 0..15 + 20..543 | 4 bytes decoded-firmware SHA-256 prefix | 8 zero |
8 slots × 64 bytes (slot k = COLOR k+1): hue[12] `+0`, light[12] `+12`, `+25` WB flags (bit 0 on), `+26` A/B,
`+27` G/M, `+31` flags (bit 1 = Hue/Light on), `+47` Blacks, `+48` Whites.

## GUIDES.BIN v4

`OM3G` | u32 total | u32 CRC-32 of bytes 12.. | u16 width 175 | u16 height 50 | u32 length of streams 1..4 |
streams (Hue, Light, WB/BW, Profiles), each padded to 4 bytes. Streams are OM-3 OSD type-11 pictures (palette
indices, run-length tokens); see `card/mkguides.py`.

## NAMES.BIN v1

Pictures of the profile names, shown under the wheel on the Profiles page. Written by the Look Lab (`namesBin`)
together with `PROFILES.BIN`, in the camera's label style (`card/mkguides.py` metrics).

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
| 64 | 20 × 4 | entries {u16 offset in its group, u16 length}: COLOR k profile v at 5k + v − 1 (length 0 = none) |
| 144 | … | group data: OSD type-11 pictures, 175 × 50, each 4-byte aligned |

The camera loads each group into its own buffer at the first half-press and checks the CRC and every picture's
header; a file that fails is ignored (the label then says "Profiles").
