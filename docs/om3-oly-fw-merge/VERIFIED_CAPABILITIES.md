# OM-3 已验证固件能力说明（机身实测）

**基准机身固件：** OM-3 1.1 / 1100  
**上游色彩底包：** Caduceus for OM-3 **v0.22**  
**当前推荐上卡包：** `generated/om3-sd-ready/caduceus-v022-shutter-only-blog-looks/`  
**容器 SHA-256：** `4ccee72884dba087235a45f76af06c17b01b846fee83b90aa7f4939888ed3efc`

## 已确认可用

| 能力 | 状态 | 说明 |
| --- | --- | --- |
| 正常开机 / 不循环重启 | 已通过 | 官方恢复后再刷本包可进系统 |
| Caduceus HSL / 色彩编辑 | 已通过 | COLOR 1–4 编辑、拨轮、Extras 等 |
| 色彩预设 LOOKS / NAMES | 已通过 | 含 blog 预设与 Empty DIY 槽 |
| 电子快门自定义音效 | 已通过 | 菜单可选多档；三槽 WAV 可播放 |
| Caduceus GUIDES / LABELS | 已随包 | 刷机后保留 `OM3MOD` |

## 本包刻意未合并（排除项）

| 能力 | 状态 | 原因 |
| --- | --- | --- |
| 松下镜头光圈环（ring-native） | **未合并** | 与 Caduceus 同包时仍会导致开机循环；需单独再攻 |
| Wi‑Fi 5 GHz（wifi-5ghz） | **未合并** | 与 ring 一并排除，缩小二分面 |

对照：历史上 **feature-only**（无 Caduceus）机身可用 ring/wifi/shutter；**Caduceus alone** 上游已测；**Caduceus + shutter（本包）** 已测通过。

## 结构要点（正确改动摘要）

1. **底包：** Caduceus v0.22 `patch.apply`，保留 `ext1` 与 facade `GetValue/count/vbi`。
2. **电子快门：** 应用 shutter multibody / remaining / native；**跳过** 与 Caduceus 冲突的 facade 字 `0x60e57480/90/94`。
3. **Facade 链：** Caduceus miss（已恢复入口寄存器/栈）→ **shutter 完整入口** → 非快门 id 再回 stock。  
   写入/屏蔽字 `0x60e57478` / `0x60e5749c` 由 shutter 占用。
4. **MN103 `dc` 跳转：** `target = insn_addr + rel32`（**不是** `+5`）。
5. **Section-1 end：** 无 ring 时仍须抬高，使 `0x6031f000+` 的 shutter 洞穴与 WAV 落在加载范围内（本包 end `0x60339800`）。
6. **WAV：** 三槽 transplant / inject；slot2 `@0x603244b0`。
7. **OM3MOD：** `GUIDES.BIN` / `LABELS.BIN` + `LOOKS.BIN` / `NAMES.BIN`；`restore/E1479999.BIN` = 官方 1.1。

## 重建命令

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

上卡目录再附带 blog LOOKS 后即为 `om3-sd-ready/caduceus-v022-shutter-only-blog-looks`。

## 相关文档

- 合并流程与冲突表：[CADUCEUS_MERGE.md](CADUCEUS_MERGE.md)
- 错题集（错误改动）：[MERGE_MISTAKES.md](MERGE_MISTAKES.md)
- 刷机流程：[FLASH_WORKFLOW.md](../../boot/om-3/FLASH_WORKFLOW.md)
