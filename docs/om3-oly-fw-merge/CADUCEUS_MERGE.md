# OM-3 Caduceus + feature-pack merge

Builds a single SD package on **OM-3 1.1 / 1100** that combines:

- **Caduceus for OM-3 v0.22** (camera-tested colour / Look editor)
- Verified **ring-native**, **wifi-5ghz**, **shutter-sound** + three custom WAV slots

## Why not a blind stack

| Conflict | Resolution |
| --- | --- |
| `ring-native` cave `0x6031e910` vs Caduceus `ext1` `0x6031e920` | Relocate ring cave to **`0x60339660`** (first free byte after shutter WAV; extend section-1 end so it loads). **Do not** use `0x60388000` — that address sits past section-1 end `0x60339660` and bootloops |
| Shared facade words `0x60e57480/90/94` | Keep Caduceus pointers; on miss Caduceus restores entry state then `jmp` to **shutter full entries** (then shutter → stock). |
| Shutter-only facade `0x60e57478` / `0x60e5749c` | Applied normally |
| MN103 `dc` rel32 | **`target = insn_addr + rel`** (not +5). The old +5 encoder aimed 5 bytes early and bootlooped any chain/ring retarget. |

Miss path: **Caduceus editor → shutter menu → stock**.

## Rebuild (offline)

```bash
# 1) Caduceus + code features (ring relocated, wifi, shutter + facade chain)
python tools/om3_caduceus_feature_merge.py \
  --out generated/om3-caduceus-ring-wifi-shutter \
  --write-container \
  --stage-sd generated/om3-sd-install/caduceus-v022-ring-wifi-shutter

# 2) Inject WAV slots (preferred: CPython 3.12 + om3_shutter_slots.py)
#    Fallback used here: transplant deltas from the verified slots build
python tools/om3_transplant_shutter_slots.py \
  --target-main generated/om3-caduceus-ring-wifi-shutter/main.decoded.bin \
  --out generated/om3-caduceus-ring-wifi-shutter-slots123 \
  --write-container \
  --stage-sd generated/om3-sd-install/caduceus-v022-ring-wifi-shutter-slots123 \
  --om3mod generated/om3-sd-install/caduceus-v022-ring-wifi-shutter/OM3MOD

# 3) Structural self-test
python tools/om3_caduceus_merge_selftest.py \
  --out generated/om3-caduceus-merge/selftest-slots123
```

## Install tree（推荐上卡包）

**精简二分包（Caduceus + 电子快门/WAV only，无 ring / 无 WiFi 5GHz）**：

`generated/om3-sd-ready/caduceus-v022-shutter-only-blog-looks/`

```bash
python tools/om3_caduceus_feature_merge.py --features shutter-sound \
  --out generated/om3-caduceus-shutter-only --write-container \
  --stage-sd generated/om3-sd-install/caduceus-v022-shutter-only
python tools/om3_transplant_shutter_slots.py \
  --target-main generated/om3-caduceus-shutter-only/main.decoded.bin \
  --out generated/om3-caduceus-shutter-only-slots123 --write-container \
  --stage-sd generated/om3-sd-install/caduceus-v022-shutter-only-slots123 \
  --om3mod generated/om3-sd-install/caduceus-v022-shutter-only/OM3MOD
```

全量合并包（含 ring/wifi；历史上多次 bootloop，仅作对照）：

`generated/om3-sd-ready/caduceus-v022-merged-blog-looks/`

中文说明：[SD_READY_刷机与预设.md](SD_READY_刷机与预设.md)

仅固件（无 LOOKS/NAMES）的中间产物：

`generated/om3-sd-install/caduceus-v022-shutter-only-slots123/`  
`generated/om3-sd-install/caduceus-v022-ring-wifi-shutter-slots123/`

| Path | Role |
| --- | --- |
| `DCOLYMP/E1479999.BIN` | Merged update |
| `OM3MOD/GUIDES.BIN` + `LABELS.BIN` (+ `LOOKS.BIN`/`NAMES.BIN` in sd-ready) | Caduceus card extras |
| `restore/E1479999.BIN` | Stock 1.1 |

Flash ritual: same as [FLASH_WORKFLOW.md](../../boot/om-3/FLASH_WORKFLOW.md) (Slot 1, hold **OK**). After flash keep `OM3MOD`; half-press once to load Caduceus settings.

## Status

| Check | Result |
| --- | --- |
| **Body（推荐包）** | `caduceus-v022-shutter-only-blog-looks`：**开机 + HSL + 色彩预设 + 快门音效** 已通过（2026-11） |
| Offline tools | `om3_caduceus_feature_merge.py --features shutter-sound` + WAV transplant |
| 全量 ring/wifi | **未**在 Caduceus 同包机身验证通过；勿作推荐 |
| 能力说明 / 错题集 | [VERIFIED_CAPABILITIES.md](VERIFIED_CAPABILITIES.md) · [MERGE_MISTAKES.md](MERGE_MISTAKES.md) |
| Prior feature pack alone | Body OK 2026-11-04 |
| Caduceus alone | Upstream camera-tested v0.22 |
