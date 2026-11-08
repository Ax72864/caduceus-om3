/* OM-3 1.1 editor test 1 (= probe 2 + on-camera Hue/Light pages + card save).
 * Probe 2 part: looks in a heap block, loaded from C:\OM3MOD\BUNDLES.BIN when valid.
 * Adapted from Caduceus SD loader v3 (cakelesscoder/caduceus-ep7, Apache-2.0): same state encoding,
 * gate, file sequence, header/CRC/range check and pool-handle publication; OM-3 addresses.
 *
 * STATE (u16) = 0x62b4dd16, event-manager padding (camera-proven by probe 1):
 *   0 = not attempted, 0xFFFF = attempted / no table, 1..HMAX = handle h, block at POOL + h - 1.
 * Block (1024 B, class-1 pool, uncached): +0 header (magic 'OM3B'...), +32 8 slots x 64 B
 *   (Caduceus bundle ABI: hue[12] s8 +0, light[12] s8 +12, flags +31 bit1 = H/L enabled; UI sector order).
 * First gated shutter event per power-on: STATE = 0xFFFF; malloc(1024); copy built-in defaults;
 *   fopen/fseek(END)/ftell == 544/fseek(SET)/fread/fclose; header + CRC-32 + per-byte ranges;
 *   any failure -> built-in defaults again; publish h when the block is inside the pool and 4-aligned.
 * The COLOR hook reads the published block only; STATE 0 / 0xFFFF -> stock output.
 * No store into the loaded image; stores: STATE (2x), the heap block, stack frames.
 */
.section .hook_color,"ax"
 jmp hl_pp
.section .hook_shutter,"ax"
 jmp pr_hook
.section .hook_set,"ax"
 call ed_set,[d2,d3,a2,a3],68     /* stock: call 0x60bb528f,[d2,d3,a2,a3],68 (settings manager) */
.section .hook_tone,"ax"
 call tone,[d2,d3,a2,a3],56       /* stock 0x605197d7: mov d3,a0; call 0x60518fa4,[d2,d3,a2,a3],56 */
.section .hook_pmod,"ax"
 jmp ed_pmod                      /* stock 0x6129ba07: clr d3; mov 0x6037ec10,a2 (its first 5 bytes) */

/* ------------------------------------------------------------------ section-1 tail */
.section .ext1,"ax"
/* P validation: out a2 = P; uses d3, a2 only. */
 .macro PVAL miss
 movhu (STATE),d3
 add -1,d3
 cmp HMAX,d3
 bcc \miss
 btst 3,d3
 bne \miss
 mov d3,a2
 add POOL,a2
 mov (a2),d3
 cmp MAGIC,d3
 bne \miss
 .endm

/* PROFID miss: the facade id in d0 is the 12 o'clock id (928 + 12k) of the open editor on the Profiles page.
 * Uses d2, d3, a2 (a2 = P on a hit); d0, d1, a0, a1 kept. */
 .macro PROFID miss
 PVAL \miss
 movbu (AXIS,a2),d3
 cmp 4,d3
 bne \miss
 movbu (EDK,a2),d3
 cmp 4,d3
 bcc \miss
 mov d3,d2
 add d2,d2
 add d3,d2
 asl2 d2
 add 928,d2
 mov d0,d3
 exthu d3
 cmp d2,d3
 bne \miss
 .endm


/* in d0 = setting id; hit: a2 = P, d2 = 64*slot + sector, d3 = 0 Light / 1 Hue. Uses d2, d3, a2 only.
 * COLOR1..4 sector ids 928..975 (12 per profile, UI sector order), P valid, marker, axis 1 (Light) or 2 (Hue). */
 .macro WHERE miss
 mov d0,d2
 exthu d2
 add -928,d2
 cmp 48,d2
 bcc \miss
 clr d3
81:
 cmp 12,d2
 bcs 82f
 add -12,d2
 add 64,d3
 bra 81b
82:
 add d3,d2
 PVAL \miss
 mov (EMARK,a2),d3
 cmp EMAGIC,d3
 bne \miss
 movbu (AXIS,a2),d3
 add -1,d3
 cmp 4,d3                         /* 1..4: Light, Hue, Extras, Film */
 bcc \miss
 .endm

/* after WHERE: a2 = the cell's address - 32 (read with (32,a2)); WB page: only Yellow (A-B, +26) and Green (G-M, +27),
 * any other slice -> \none. Uses d2, d3, a2. */
 .macro CELL none
 cmp 3,d3                         /* Looks page: only 12 o'clock -> the profile's look number P+LIDX+k */
 bne 76f
 mov d2,d3
 and 63,d3
 cmp 0,d3
 bne \none
 mov d2,d3
 lsr 6,d3
 add d3,a2
 add LIDX-32,a2
 bra 74f
76:
 cmp 2,d3                         /* v0.20 Extras page: slice 0..7 (1..8 clockwise from 12 o'clock) -> slot byte xt_tab */
 bne 71f
 mov d2,d3
 and 63,d3
 cmp 9,d3
 bcc \none
 and 0xc0,d2
 add a2,d2                        /* P + 64*slot */
 mov xt_tab,a2
 add d3,a2
 add d3,a2
 add d3,a2
 movbu (a2),d3
 cmp 0,d3
 beq \none
 mov d2,a2
 add d3,a2
 bra 74f
71:
 add d2,a2
 cmp 0,d3
 bne 74f
 add 12,a2
74:
 .endm

hl_pp:
 call color_builder,[d2,d3,a2,a3],96
 movhu (STATE),d0
 cmp 0,d0
 beq hl_out
 mov 63153,d0                     /* effective COLOR profile number (as capture population) */
 clr d1
 mov 0,a0
 call getter,[d2,d3],12
 extbu d0
 add -1,d0
 cmp 4,d0
 bcc hl_out                       /* not COLOR1..4 */
 mov d0,d1                        /* d1 = slot 0..3 */
 movhu (STATE),d0
 add -1,d0                        /* h - 1 */
 cmp HMAX,d0
 bcc hl_out                       /* 0 (-1 wraps), 0xFFFF and out-of-pool handles */
 btst 3,d0
 bne hl_out
 mov d0,a1
 add POOL,a1                      /* a1 = block (uncached) */
 mov (a1),d0
 cmp MAGIC,d0
 bne hl_out
 asl 6,d1
 add d1,a1
 add 32,a1                        /* a1 = slot entry */
 movbu (31,a1),d0
 btst 2,d0
 beq hl_out                       /* H/L not enabled for this slot */
 clr d1
hl_v:                             /* all 24 values -7..7 before any write */
 movbu (d1,a1),d0
 extb d0
 add 7,d0
 cmp 14,d0
 bhi hl_out
 inc d1
 cmp 24,d1
 bne hl_v
 add -12,sp
 mov d2,(0,sp)
 mov d3,(4,sp)
 mov a3,(8,sp)
 mov (12,a2),a0
 add 854,a0                       /* output record 0, hue field (+18) */
 mov hl_lut,a3
 clr d2
hl_w:
 mov d2,d3
 add 60,d3
 movbu (d3,a3),d0                 /* w = perm[r] (UI sector of record r) */
 movbu (d0,a1),d1
 extb d1
 add 7,d1
 add d1,d1
 movhu (d1,a3),d1                 /* hue LUT */
 movhu d1,(a0)
 add 12,d0
 movbu (d0,a1),d1
 extb d1
 add 7,d1
 add d1,d1
 add 30,d1
 movhu (d1,a3),d1                 /* lightness LUT */
 movhu d1,(4,a0)
 add 24,a0
 inc d2
 cmp 12,d2
 bne hl_w
 mov (0,sp),d2
 mov (4,sp),d3
 mov (8,sp),a3
 add 12,sp
hl_out:
 jmp color_resume

pr_hook:                          /* entered by jmp from 0x60415216; frame = 0x60415111's */
 call trig,[d2,d3,a2,a3],36       /* the displaced stock call */
 movhu (STATE),d0
 cmp 0,d0
 bne pr_ed                        /* already attempted this power-on */
 call pr_gate,[d2,d3,a2,a3],36
 bra pr_back
pr_ed:
 call gx_go,[d2,d3,a2,a3],36      /* GX1 test: the space probe (when its section-6 extension loaded), then ed_trig */
pr_back:
 jmp trig_resume

pr_gate:                          /* frame 36: (12,sp) = tid out */
 mov (SECBITS),d0
 and 0x3ff,d0
 cmp 0x3ff,d0
 bne pr_gout                      /* not all 10 sections copied */
 mov sp,a0
 add 12,a0
 call get_tid,[a2],4
 cmp 0,d0
 bne pr_gout                      /* not a task context */
 movhu (HLS_TID),d1
 cmp 0,d1
 beq pr_gout
 btst 0x8000,d1
 bne pr_gout                      /* HLS_EVENT not created yet */
 movhu (12,sp),d0
 cmp d1,d0
 bne pr_gout                      /* not the HLS_EVENT task */
 mov 61440,d1
 mov (MS_A),d0
 cmp d1,d0
 beq pr_go
 mov (MS_B),d0
 cmp d1,d0
 beq pr_go
 mov (MS_C),d0
 cmp d1,d0
 bne pr_gout                      /* no medium MOUNT OK: retry at the next shutter event */
pr_go:
 mov 0xffff,d0
 movhu d0,(STATE)                 /* one attempt per power-on */
 call sd_load,[d2,d3,a2,a3],36
pr_gout:
 ret [d2,d3,a2,a3],36

/* ed_trig (frame 36, (12,sp) = tid out): P valid + marker + dirty == 1 + the same context gate as pr_gate
 * -> dirty = 0, one ed_save, status byte = its result. */
ed_trig:
 PVAL t_out                       /* v0.21: no automatic capture into the selected looks (pf_wb gone): a look
                                     changes only when OK is held on the Looks page (lk_hold) */
 mov (EMARK,a2),d0
 cmp EMAGIC,d0
 bne 1f
 clr d0
 movbu d0,(AXIS,a2)               /* leaving for the shutter: other screens read Saturation again */
 call gd_set,[d2,a2],8            /* d0 = 0: stock guide picture */
1:
 movbu (DIRTY,a2),d0
 cmp 1,d0
 bne t_out
 mov (SECBITS),d0
 and 0x3ff,d0
 cmp 0x3ff,d0
 bne t_out
 mov sp,a0
 add 12,a0
 call get_tid,[a2],4
 cmp 0,d0
 bne t_out
 movhu (HLS_TID),d1
 cmp 0,d1
 beq t_out
 btst 0x8000,d1
 bne t_out
 movhu (12,sp),d0
 cmp d1,d0
 bne t_out
 mov 61440,d1
 mov (MS_A),d0
 cmp d1,d0
 beq t_go
 mov (MS_B),d0
 cmp d1,d0
 beq t_go
 mov (MS_C),d0
 cmp d1,d0
 bne t_out
t_go:
 clr d0
 movbu d0,(DIRTY,a2)              /* one attempt per batch of edits, whatever happens */
 call ed_save,[d2,d3,a2,a3],24
 movbu d0,(STATUS,a2)
 call pf_save,[d2,d3,a2,a3],24
t_out:
 ret [d2,d3,a2,a3],36

/* ---------------------------------------------------------------- on-camera editor (Caduceus look editor
 * phase 1 design, cakelesscoder/caduceus-ep7 Apache-2.0; OM-3 addresses and OM-3 Color Profile editor).
 * Pages (axis byte P+AXIS): 0 Saturation (stock), 2 Hue, 1 Light. INFO in the COLOR1-4 editor:
 *   Saturation (single) -> stock (ALL on) ; ALL on -> stock (ALL off), then Hue ; Hue -> Light ; Light -> Saturation.
 * The H/L values live in the loaded table P (slot +0 hue, +12 light, flags +31 bit1), -5..5 in the editor.
 */

/* ed_get <- facade vtable +12 word 0x60e57480 (GetValue, stock 0x60b86de7). CALLS entry: d0 id, a0 facade,
 * a1 out; -> d0 0 and (a1) = value. Miss: every register and the stack as at entry, jmp stock. */
ed_get:
 cmp 0,a1
 beq g_stock
 movm [d2,d3,a2],(sp)
 mov d0,d2                        /* 916..927: "the selected slice" ids the readout next to Vivid reads */
 exthu d2
 add -916,d2
 cmp 12,d2
 bcc 1f
 PVAL g_miss
 movbu (AXIS,a2),d3               /* only on the Hue / Light / Extras / Film pages: else stock, id unchanged */
 add -1,d3
 cmp 4,d3
 bcc g_miss
 movbu (EDK,a2),d3                /* -> sector id 928 + 12k + slice of the open editor */
 cmp 4,d3
 bcc g_miss
 call vl_s,[d2,d3,a2,a3],20       /* v0.20: the dial label ("Vivid") names the Extras slice (code block) */
 mov d3,d0
 add d0,d0
 add d3,d0
 asl2 d0
 add d2,d0
 add 928,d0
1:
 WHERE g_miss
 CELL 4f
 movbu (32,a2),d0
 extb d0
 cmp -5,d0
 bge 2f
 mov -5,d0
2:
 cmp 5,d0
 ble 3f
 mov 5,d0
 bra 3f
4:
 clr d0                           /* WB page: the other slices read 0 */
3:
g_put:
 mov d0,(a1)
 movm (sp),[d2,d3,a2]
 clr d0
 rets
g_miss:
 movm (sp),[d2,d3,a2]
g_stock:
 jmp stock_get

/* ed_default <- facade vtable +156 word 0x60e57510 (GetDefault, stock 0x60b86e44): H/L default 0. */
ed_default:
 cmp 0,a1
 beq d_stock
 movm [d2,d3,a2],(sp)
 WHERE d_miss
 clr d0
 mov d0,(a1)
 movm (sp),[d2,d3,a2]
 rets
d_miss:
 movm (sp),[d2,d3,a2]
d_stock:
 jmp stock_default

/* ed_set <- 0x60b8798b `call 0x60bb528f,[d2,d3,a2,a3],68` in the facade SetValue (mode 0): entered exactly like
 * the settings manager (d0 id, d1 value, a0 inner, a1 mode; d2/d3/a2/a3 saved by the call; return address at
 * (68,sp)). H/L hit: value -5..5 into the table, slot H/L bit, dirty; then the manager runs for the id with its
 * unchanged Saturation value, so its listeners refresh the screen as after a stock edit. */
ed_set:
 WHERE s_stock
 cmp -5,d1
 blt s_bad
 cmp 5,d1
 bgt s_bad
 cmp 3,d3
 bne 1f
 jmp s_look                       /* Looks page (sec 3) */
1:
 cmp 2,d3
 beq s_x
 cmp 0,d3
 bne 4f
 add 12,d2                        /* Light */
4:
 add 32,d2
 movbu d1,(d2,a2)                 /* the value first ... */
 and 0xc0,d2                      /* 64*slot (32 + 12 + 11 < 64) */
 add 63,d2
 movbu (d2,a2),d1
 or 2,d1
 movbu d1,(d2,a2)                 /* ... then the slot's H/L enable bit ... */
s_dirty:                          /* test 16: hand edits belong to the selected bank profile (saved back at the half-press) */
s_dirty2:
 mov 1,d1
 movbu d1,(DIRTY,a2)              /* ... then dirty (saved to the card on the next half-press) */
 mov d0,d2
 mov a0,d3
 mov a1,a2
 add -4,sp                        /* the getter's return address goes below our frame */
 call sget,[],4                   /* d0 = the id's Saturation value (0x603f0111; keeps d2/d3/a2/a3) */
 add 4,sp
 mov d0,d1
 mov (68,sp),d0                   /* MDR = the setter's return address again, as the stock call left it */
 mov d0,mdr
 mov d2,d0
 mov d3,a0
 mov a2,a1
 jmp manager
s_x:                              /* Extras page: d2 = 64*slot + slice, d1 = value; a3 free (saved by the setter frame).
                                   * xt_tab {slot byte, min, max}; A-B / G-M also turn the slot's WB override on */
 mov d2,d3
 and 63,d3
 cmp 9,d3
 bcc s_bad
 mov xt_tab,a3
 add d3,a3
 add d3,a3
 add d3,a3
 movbu (a3),d3
 cmp 0,d3
 beq s_bad
 and 0xc0,d2
 add 32,d2
 add d3,d2                        /* 64*slot + 32 + byte */
 movbu (1,a3),d3                  /* (v0.21: the dial itself now stops at the cell's range, pf_cnt / pf_vbi) */
 extb d3
 cmp d3,d1
 blt s_bad
 movbu (2,a3),d3
 extb d3
 cmp d3,d1
 bgt s_bad
 movbu d1,(d2,a2)                 /* the value first ... */
 movbu (a3),d3
 cmp 28,d3
 bcc 7f                           /* not WB */
 and 0xc0,d2
 add 57,d2                        /* ... then wb_flags (+25): bit0 on, bit7 off */
 movbu (d2,a2),d1
 or 1,d1
 and 0x7f,d1
 movbu d1,(d2,a2)
7:
 bra s_dirty
s_bad:
 clr d0
 ret [d2,d3,a2,a3],68
s_stock:
 jmp manager

/* ed_init <- COLOR1-4 editor records +4 (stock 0x6122393a, CALLS, d0 = the editor key 0x1540..0x1543, a0 parent).
 * Test 18: with a profile bank, a new editor starts on the Profiles page (axis 4), else on Saturation. The page,
 * EDK (this editor's COLOR, from d0) and the first-use marker are set before the stock init, so the children build
 * their value lists for that page (count / value-by-index: Profiles 0..5). INFO order unchanged:
 * Profiles -> Saturation -> (All) -> Hue -> Light -> WB/BW -> Profiles. Registers as at entry for the stock init. */
ed_init:
 movm [d3,a2],(sp)
 PVAL i_out
 movm [other],(sp)                /* d0 (the key), d1, a0, a1 for the stock init */
 add -4,sp
 call ei_page,[],4
 add 4,sp
 movm (sp),[other]
i_out:
 movm (sp),[d3,a2]
 jmp stock_init


/* wb_get <- the 12 WB fine-tune reads (`mov 34041|38521,d0; mov 0,a0; clr d1; call 0x60063380,[d2,d3],12`): capture
 * WB resolution 0x60457982.., pipeline params 0x604631b2/c5, WB record 0x604876c3/d8. Entered with the getter's own
 * frame: d0 key, d1 idx, a0 0 -> d0 (type 9: sign-extended s8). Returns the stock value, plus the active COLOR
 * profile's A-B / G-M (slot +26 / +27 when wb_flags +25 & 0x81 == 1) clamped to -7..7 (additive, as asked). */
wb_get:
 mov d0,d2                        /* key (d2/d3 saved by the site's call) */
 call getter,[d2,d3],12           /* the stock value */
 mov d0,d3
 mov 38017,d0                     /* picture mode (6 -> 40209), as capture population reads it */
 clr d1
 mov 0,a0
 call getter,[d2,d3],12
 extbu d0
 cmp 6,d0
 bne 1f
 mov 40209,d0
 clr d1
 mov 0,a0
 call getter,[d2,d3],12
 extbu d0
1:
 cmp 11,d0                        /* COLOR profiles only */
 bne 9f
 mov 63153,d0
 clr d1
 mov 0,a0
 call getter,[d2,d3],12
 extbu d0
 add -1,d0
 cmp 4,d0
 bcc 9f
 mov d0,d1                        /* slot 0..3 */
 movhu (STATE),d0
 add -1,d0
 cmp HMAX,d0
 bcc 9f
 btst 3,d0
 bne 9f
 mov d0,a1
 add POOL,a1
 mov (a1),d0
 cmp MAGIC,d0
 bne 9f
 asl 6,d1
 add d1,a1
 add 32,a1                        /* slot entry */
 movbu (25,a1),d0
 and 0x81,d0
 cmp 1,d0
 bne 9f
 movbu (26,a1),d0                 /* A-B: 34041, and the Auto WB ones 7401 / 7433 (v0.21) */
 cmp 34041,d2
 beq 2f
 cmp 7401,d2
 beq 2f
 cmp 7433,d2
 beq 2f
 movbu (27,a1),d0                 /* G-M: 38521, and the Auto WB ones 7417 / 7449 (v0.21) */
 cmp 38521,d2
 beq 2f
 cmp 7417,d2
 beq 2f
 cmp 7449,d2
 bne 9f
2:
 extb d0
 cmp -7,d0
 blt 9f
 cmp 7,d0
 bgt 9f
 extb d3
 add d0,d3
 cmp -7,d3
 bge 3f
 mov -7,d3
3:
 cmp 7,d3
 ble 9f
 mov 7,d3
9:
 mov d3,d0
 ret [d2,d3],12

/* pf_cnt <- facade vtable +28 word 0x60e57490 (count, stock 0x60b86e09): d0 id, a0 facade -> d0 count. COLOR1-4
 * cell ids 928..975 ask code block +96 (xb_cv: the Looks page's 12 o'clock 0..5; v0.21 an Extras cell its own range,
 * so the dial stops at the ends); anything else, or no answer: stock. */
pf_cnt:
 movm [d2,d3,a2],(sp)
 add -4,sp
 mov d0,d2
 exthu d0
 add -928,d0
 cmp 48,d0
 bcc 9f
 call xp,[],0
 beq 9f
 add 96,a1
 mov d2,d0
 calls (a1)                       /* -> d0 count, d1 1 hit / 0 miss */
 cmp 0,d1
 bne 8f
9:
 mov d2,d0
 add 4,sp
 movm (sp),[d2,d3,a2]
 jmp stock_cnt
8:
 add 4,sp
 movm (sp),[d2,d3,a2]
 rets

/* pf_vbi <- facade vtable +32 word 0x60e57494 (value by index, stock 0x60b87031): d0 id, d1 index, a0 facade,
 * a1 out (or 0) -> d0 value (-1 = no such index), (a1) = the same. Cell ids 928..975: code block +104 (xb_vb,
 * d3 = out); anything else, or no answer: stock. */
pf_vbi:
 movm [d2,d3,a2],(sp)
 add -4,sp
 mov d0,d2
 mov a1,d3
 mov d1,a2
 exthu d0
 add -928,d0
 cmp 48,d0
 bcc 9f
 call xp,[],0                     /* keeps d1 */
 beq 9f
 add 104,a1
 mov d2,d0
 calls (a1)                       /* d0 id, d1 index, d3 out -> d0 value, d1 1 hit / 0 miss */
 cmp 0,d1
 bne 8f
9:
 mov d2,d0
 mov a2,d1
 mov d3,a1
 add 4,sp
 movm (sp),[d2,d3,a2]
 jmp stock_vbi
8:
 add 4,sp
 movm (sp),[d2,d3,a2]
 rets

.balign 2
hl_lut:                           /* +0: hue raw[ui+7] (15 hw); +30: lightness raw[ui+7]; +60: perm[12] */
 .hword 7000,6000,5000,4000,3000,2000,1000,0,-1000,-2000,-3000,-4000,-5000,-6000,-7000
 .hword -300,-250,-200,-150,-100,-50,-25,0,25,50,100,150,200,250,300
 .byte 0,2,4,6,8,10,1,3,5,7,9,11
ext1_end:

/* ------------------------------------------------------------------ section-4 tail */
.section .ext4,"ax"
sd_load:                          /* frame 36 */
 mov 1024,d0
 call malloc,[],4
 mov a0,a2
 cmp 0,a2
 beq sd_out
 clr d0                           /* editor: the whole block starts at 0 (marker, page, dirty) */
 clr d2
sd_z:
 movbu d0,(d2,a2)
 inc d2
 cmp 1024,d2
 bne sd_z
 call sd_def,[d2],8               /* built-in defaults into the block */
 mov sd_path,a0
 mov sd_mode,a1
 call fopen,[],4
 mov a0,a3
 cmp 0,a3
 beq sd_pub                       /* no file: publish the defaults */
 mov a3,a0
 clr d0
 mov 1,d1                         /* whence 1 = END */
 call fseek,[d2,d3,a2,a3],20
 cmp 0,d0
 bne sd_close
 mov a3,a0
 call ftell,[d2,a2,a3],16
 mov d0,d3                        /* file size */
 cmp FILE_LEN,d3
 bne sd_close
 mov a3,a0
 clr d0
 mov 2,d1                         /* whence 2 = SET */
 call fseek,[d2,d3,a2,a3],20
 cmp 0,d0
 bne sd_close
 mov a2,a0
 mov 1,d0
 mov d3,d1
 mov a3,a1
 call fread,[d2,d3,a2,a3],24
 mov d0,d2                        /* bytes read */
 mov a3,a0
 call fclose,[d2,a2,a3],16
 cmp d3,d2
 bne sd_redef
 mov a2,a0
 call sd_check,[d2,d3,a2,a3],16
 cmp 0,d0
 beq sd_pub                       /* valid file: keep it */
 bra sd_redef
sd_close:
 mov a3,a0
 call fclose,[d2,a2,a3],16
sd_redef:
 call sd_def,[d2],8
sd_pub:
 clr d1
 mov d1,(LPTR,a2)                 /* no looks / look numbers 0 until lk_load publishes */
 mov d1,(LIDX,a2)
 mov a2,d0
 add NEG_POOL,d0                  /* buf - POOL */
 cmp HMAX,d0
 bcc sd_free                      /* block not wholly inside the class-1 pool */
 btst 3,d0
 bne sd_free                      /* not 4-aligned */
 inc d0
 movhu d0,(STATE)                 /* publish: the colour hook switches to the block */
 call gd_load,[d2,d3,a2,a3],28    /* editor guide pictures from C:\OM3MOD\GUIDES.BIN (optional) */
 call pf_load,[d2,d3,a2,a3],28    /* look bank from C:\OM3MOD\LOOKS.BIN (test 16; PROFILES.BIN before v0.19) */
 call nm_load,[d2,d3,a2,a3],36    /* profile name pictures from C:\OM3MOD\NAMES.BIN (test 17) */
 bra sd_out                       /* block kept for the rest of the power-on */
sd_free:
 mov a2,a0
 call free,[],4
sd_out:
 ret [d2,d3,a2,a3],36

sd_def:                           /* a2 = block: the built-in defaults (neutral): the header with its CRC, then 512 zero */
 mov sd_hdr,a0                    /* test 17: made here instead of copied from a 544-byte table (frees code space) */
 clr d2
sd_d1:
 clr d0
 cmp HDR_LEN,d2
 bcc 1f
 movbu (d2,a0),d0
1:
 movbu d0,(d2,a2)
 inc d2
 cmp FILE_LEN,d2
 bne sd_d1
 mov DEF_CRC,d0
 mov d0,(16,a2)
 ret [d2],8

/* sd_check (Caduceus v1): a0 = buffer -> d0 = 0 valid, 1 invalid. */
sd_check:
 mov a0,a2
 mov sd_hdr,a3
 clr d2
sd_h1:
 movbu (d2,a2),d0
 movbu (d2,a3),d1
 cmp d1,d0
 bne sd_bad
 inc d2
 cmp 16,d2
 bne sd_h1
 mov 20,d2
sd_h2:
 movbu (d2,a2),d0
 movbu (d2,a3),d1
 cmp d1,d0
 bne sd_bad
 inc d2
 cmp HDR_LEN,d2
 bne sd_h2
 mov -1,d0
 mov a2,a0
 mov 16,d1
 call sd_crc,[d2,d3],12
 mov a2,a0
 add 20,a0
 mov CRC_TAIL,d1
 call sd_crc,[d2,d3],12
 not d0
 clr d2
sd_c1:
 movbu (16,a2),d1
 mov d0,d3
 and 255,d3
 cmp d3,d1
 bne sd_bad
 lsr 8,d0
 inc a2
 inc d2
 cmp 4,d2
 bne sd_c1
 add -4,a2
 mov a2,a0
 add HDR_LEN,a0
 clr d2
sd_r1:
 movbu (d2,a0),d0
 extb d0
 mov d2,d1
 and 63,d1
 mov sd_lo,a1
 movbu (d1,a1),d3
 extb d3
 sub d3,d0
 mov sd_span,a1
 movbu (d1,a1),d3
 cmp d3,d0
 bhi sd_bad
 inc d2
 cmp PAYLOAD_LEN,d2
 bne sd_r1
 clr d0
 ret [d2,d3,a2,a3],16
sd_bad:
 mov 1,d0
 ret [d2,d3,a2,a3],16

/* sd_crc: d0 = running CRC, a0 = data, d1 = length (> 0) -> d0. */
sd_crc:
 movbu (a0),d2
 xor d2,d0
 mov 8,d3
sd_b1:
 btst 1,d0
 beq sd_b0
 lsr 1,d0
 xor 0xedb88320,d0
 bra sd_b2
sd_b0:
 lsr 1,d0
sd_b2:
 add -1,d3
 bne sd_b1
 inc a0
 add -1,d1
 bne sd_crc
 ret [d2,d3],12

/* ---------------------------------------------------------------- editor save (HLS_EVENT, from ed_trig)
 * a2 = P (validated) -> d0 status: 1 saved, 2 no memory, 3 .NEW failed, 4 .BIN failed (.NEW is good).
 * S = malloc(1664): image S+0 (544 B, header CRC-32 recomputed), old .BIN S+OLD, read-back S+RBD.
 * Order (Caduceus): BUNDLES.NEW (read back) -> old BUNDLES.BIN copied to BUNDLES.BAK -> BUNDLES.BIN (read back). */
ed_save:
 mov 1664,d0
 call malloc,[],4
 mov a0,a3
 mov 2,d0
 cmp 0,a3
 beq v_ret
 clr d2                           /* copy P[0..543] -> S */
1:
 movbu (d2,a2),d0
 movbu d0,(d2,a3)
 inc d2
 cmp FILE_LEN,d2
 bne 1b
 mov -1,d0                        /* header CRC-32 of S[0..15] + S[20..543] at S+16 */
 mov a3,a0
 mov 16,d1
 call sd_crc,[d2,d3],12
 mov a3,a0
 add 20,a0
 mov CRC_TAIL,d1
 call sd_crc,[d2,d3],12
 not d0
 mov d0,(16,a3)
 mov ed_p_new,a0                  /* 1. BUNDLES.NEW, verified by read-back */
 mov a3,a1
 call ed_wfile,[d2,d3,a2,a3],28
 mov d0,d3
 mov 3,d0
 cmp 0,d3
 bne v_free
 mov sd_path,a0                   /* 2. old BUNDLES.BIN -> BUNDLES.BAK (only a 544-byte file) */
 mov sd_mode,a1
 call fopen,[],4
 cmp 0,a0
 beq 3f
 mov a0,a2                        /* a2 = handle (P no longer needed) */
 mov a3,a0
 add OLD,a0
 mov 1,d0
 mov FILE_LEN,d1
 mov a2,a1
 call fread,[d2,d3,a2,a3],24
 mov d0,d3
 mov a2,a0
 call fclose,[d2,a2,a3],16
 cmp FILE_LEN,d3
 bne 3f
 mov ed_p_bak,a0
 mov a3,a1
 add OLD,a1
 call ed_wfile,[d2,d3,a2,a3],28   /* a .BAK failure does not stop the save */
3:
 mov sd_path,a0                   /* 3. BUNDLES.BIN, verified by read-back */
 mov a3,a1
 call ed_wfile,[d2,d3,a2,a3],28
 mov d0,d3
 mov 4,d0
 cmp 0,d3
 bne v_free
 mov 1,d0
v_free:
 mov d0,d2
 mov a3,a0
 call free,[],4
 mov d2,d0
v_ret:
 ret [d2,d3,a2,a3],24

/* ed_wfile: a0 path, a1 buf (FILE_LEN bytes), a3 = S -> d0 0 ok / 1 fail. Read-back into S+RBD.
 * Locals: (4,sp) buf, (8,sp) handle. */
ed_wfile:
 mov a0,a2
 mov a1,(4,sp)
 mov ed_m_w,a1
 call fopen,[],4
 cmp 0,a0
 beq w_fail
 mov a0,(8,sp)
 mov a0,a1                        /* fwrite(buf, 1, n, h) */
 mov FILE_LEN,d1
 mov 1,d0
 mov (4,sp),a0
 call fwrite,[d2,d3,a2,a3],24
 mov d0,d3
 mov (8,sp),a0
 call fclose,[d2,a2,a3],16
 cmp FILE_LEN,d3
 bne w_fail
 mov a2,a0                        /* read back */
 mov sd_mode,a1
 call fopen,[],4
 cmp 0,a0
 beq w_fail
 mov a0,(8,sp)
 mov a0,a1
 mov a3,a0
 add RBD,a0
 mov 1,d0
 mov FILE_LEN,d1
 call fread,[d2,d3,a2,a3],24
 mov d0,d3
 mov (8,sp),a0
 call fclose,[d2,a2,a3],16
 cmp FILE_LEN,d3
 bne w_fail
 mov (4,sp),a0
 mov a3,a1
 add RBD,a1
 mov FILE_LEN,d2
5:
 movbu (a0),d0
 movbu (a1),d1
 cmp d0,d1
 bne w_fail
 inc a0
 inc a1
 add -1,d2
 bne 5b
 clr d0
 ret [d2,d3,a2,a3],28
w_fail:
 mov 1,d0
 ret [d2,d3,a2,a3],28

ed_p_new:
 .asciz "C:\\OM3MOD\\BUNDLES.NEW"
ed_p_bak:
 .asciz "C:\\OM3MOD\\BUNDLES.BAK"
ed_m_w:
 .asciz "w"
sd_path:
 .asciz "C:\\OM3MOD\\BUNDLES.BIN"
sd_mode:
 .asciz "r"
.balign 4
 .include "data4.inc"            /* sd_hdr (32), sd_lo (64), sd_span (64); DEF_CRC (test 17) */
ext4_end:

/* ------------------------------------------------------------------ section-6 tail: editor INFO cycle, cursor read,
 * wheel outline (reached only from section-6/7 GUI code) */
.section .ext6,"ax"
/* ed_info <- COLOR1-4 editor records +44 (stock 0x6122661b; the router 0x61223ca6 sends INFO 0x9014 there).
 * CALLS entry: d0 event, d1 arg, a0 parent. Locals: (4) d1, (8) a1, (12) cursor id, (16) value, (20) P. */
ed_info:
 cmp 0x9014,d0
 beq k_go
 jmp stock_info
k_go:
 movm [d2,d3,a2,a3],(sp)
 add -24,sp
 mov d1,(4,sp)
 mov a1,(8,sp)
 mov a0,a3
 cmp 0,a3
 beq f_no
 movhu (96,a3),d0                 /* editor key 0x1540..0x1543 = COLOR1..4 */
 add -0x1540,d0
 cmp 4,d0
 bcc f_no
 mov d0,d1
 add 2197,d1
 mov d1,(12,sp)                   /* the editor's cursor setting 2197..2200 (255 = ALL) */
 mov d0,d2                        /* first sector id = 928 + 12k */
 asl2 d2
 mov d2,d1
 add d1,d1
 add d1,d2
 add 928,d2
 mov a3,a0                        /* children 1..12 present, ids in order */
 mov 12,d1
 mov d2,d0
5:
 mov (128,a0),a1
 cmp 0,a1
 beq f_no
 movhu (80,a1),d3
 cmp d0,d3
 bne f_no
 inc d0
 add 4,a0
 add -1,d1
 bne 5b
 PVAL f_no
 mov a2,(20,sp)
 mov (12,sp),d0                   /* the editor's profile k (for the readout's slice ids 916..927) */
 add -2197,d0
 movbu d0,(EDK,a2)
 mov (EMARK,a2),d0                /* first use since the load: marker, page Saturation */
 cmp EMAGIC,d0
 beq 6f
 clr d0
 movbu d0,(AXIS,a2)
 movbu d0,(DIRTY,a2)
 movbu d0,(STATUS,a2)
 mov EMAGIC,d0
 mov d0,(EMARK,a2)
6:
 call k_ad,[a2],8                 /* (16,sp) = the ALL state (2201 + k), as the stock INFO handler reads it */
 mov (16,sp),d0
 cmp 255,d0
 beq k_all
 mov (20,sp),a2
 movbu (AXIS,a2),d1
 cmp 0,d1
 beq f_no                         /* Saturation, single: stock INFO turns ALL on */
 bra k_step
k_all:
 mov a3,a0                        /* ALL on: the stock INFO handler turns it off */
 mov 0x9014,d0
 mov (4,sp),d1
 mov (8,sp),a1
 calls stock_info                 /* keeps d2/d3/a2/a3 */
 mov d0,d2                        /* its result */
 call k_ad,[a2],8
 mov (16,sp),d0
 cmp 255,d0
 bne k_step
7:
 mov d2,d0                        /* stock left ALL on (or no value): its result, no page change */
 ret [d2,d3,a2,a3],40
k_step:
 mov (20,sp),a2
 movbu (AXIS,a2),d0               /* S -> H -> L -> Extras -> (Film, when LOOKS.BIN loaded) -> S */
 mov 2,d1
 cmp 0,d0
 beq 8f
 mov 1,d1
 cmp 2,d0
 beq 8f
 mov 3,d1
 cmp 1,d0
 beq 8f
 clr d1
 cmp 3,d0
 bne 8f
 mov (LPTR,a2),d1
 cmp 0,d1
 beq 8f
 mov 4,d1
8:
 movbu d1,(AXIS,a2)
 mov d1,d0
 call gd_set,[d2,a2],8            /* the guide picture for the new page */
 mov 128,d2                       /* refresh children 1..12 from the facade (stock 0x611b20ea) */
9:
 mov a3,a0
 add d2,a0
 mov (a0),a0
 call refresh,[d2,d3,a2,a3],68
 add 4,d2
 cmp 176,d2
 bne 9b
 call k_cur,[a2],8                  /* poke: the cursor setting re-written with its own value */
 cmp 0,d0
 bne 10f                          /* no value (yet): no poke */
 call facade,[],4
 mov (a0),a2
 mov (4,a2),a2                    /* SetValue(id, mode 0, value) */
 mov (16,sp),a1
 clr d1
 mov (12,sp),d0
 calls (a2)
10:
 mov 1,d0
 ret [d2,d3,a2,a3],40
/* k_ad: `call k_ad,[a2],8` from ed_info's frame (as k_cur): (24,sp) <- the ALL state. The code block reads the stock
 * INFO handler's setting 2201 + k (0x615ac0b4) and, when that is not 255, the cursor 2197 + k (the camera shows ALL in
 * either, depending on the slice it was entered from). Without a code block: k_cur (2197 + k only). */
k_ad:
 call xp,[],0
 cmp 0,a1
 beq 9f
 add 40,a1
 jmp (a1)
9:
 jmp k_cur
f_no:
 mov a3,a0
 mov 0x9014,d0
 mov (4,sp),d1
 mov (8,sp),a1
 add 24,sp
 movm (sp),[d2,d3,a2,a3]
 jmp stock_info

.section .ext1,"ax"                /* v0.20 test 5: k_cur moved from the sec-6 tail (x_load) */
/* k_cur: `call k_cur,[a2],8` from ed_info's frame (sp = ed_info's sp - 8: its (12) is our (20), its (16) our (24)):
 * facade GetValue(cursor id, &value) -> d0 (0 = ok). Keeps d2/d3/a2/a3. */
k_cur:
 call facade,[],4
 mov (a0),a2
 mov (12,a2),a2
 mov sp,a1
 add 24,a1
 mov (20,sp),d0
 calls (a2)
 ret [a2],8

.section .ext8,"ax"                /* ed_poly moved from the sec-6 tail (test 12: CELL grew) */
/* ed_poly <- the 48 sector reads of the Color Profile wheel drawing (0x60b1d0ca..0x60b1d354, case 6: profile = setting 903,
 * cursor 2197.., 12 x `mov id,d0; call 0x603f039d,[],4; movbu d0,(160+i,sp)`). Entered `call ed_poly,[],4`, d0 = id.
 * Hue / Light page: the value the editor shows (-5..5), so the wheel outline follows the page.
 * Otherwise jmp 0x603f039d (the stock getter body) with every register as at entry. Keeps d2/d3/a2/a3. */
ed_poly:
 movm [d2,d3,a2],(sp)
 WHERE p_miss
 CELL 4f
 movbu (32,a2),d0
 extb d0
 cmp -5,d0
 bge 2f
 mov -5,d0
2:
 cmp 5,d0
 ble 3f
 mov 5,d0
 bra 3f
4:
 clr d0
3:
 movm (sp),[d2,d3,a2]
 ret [],4
p_miss:
 movm (sp),[d2,d3,a2]
 jmp aget

ext6_end:

/* ------------------------------------------------------------------ section-10 tail: editor guide pictures
 * GUIDES.BIN: 'OM3G' | u32 total | u32 CRC-32 of bytes 12.. | u16 175 | u16 50 | u32 s1 | u32 s2 | 8 zero |
 * Hue stream at +32 | Light stream at +32 + align4(s1). Streams = OM-3 OSD type 11, 175 x 50 (as the stock
 * "Color All [INFO]" picture, descriptor GDESC in the resource RAM). */
.section .ext10,"ax"
/* gd_load: `call gd_load,[d2,d3,a2,a3],28`, a2 = P. Locals (4) handle, (8) buffer. Stores: P+GPTR, the heap buffer. */
gd_load:
 clr d0
 mov d0,(GPTR,a2)
 mov d0,(XPTR,a2)                 /* v0.20: no code block until this load has one */
 mov gd_path,a0
 mov gd_mode,a1
 call fopen,[],4
 cmp 0,a0
 beq 9f
 mov a0,(4,sp)
 clr d0
 mov 1,d1                         /* END */
 call fseek,[d2,d3,a2,a3],20
 cmp 0,d0
 bne 8f
 mov (4,sp),a0
 call ftell,[d2,a2,a3],16
 mov d0,d3                        /* n */
 cmp 33,d3
 bcs 8f
 cmp 24577,d3                      /* test 12: up to 24 KB (5 pictures) */
 bcc 8f
 mov (4,sp),a0
 clr d0
 mov 2,d1                         /* SET */
 call fseek,[d2,d3,a2,a3],20
 cmp 0,d0
 bne 8f
 mov d3,d0
 call malloc,[],4
 cmp 0,a0
 beq 8f
 mov a0,(8,sp)
 mov 1,d0
 mov d3,d1
 mov (4,sp),a1
 call fread,[d2,d3,a2,a3],24
 mov d0,d2
 mov (4,sp),a0
 call fclose,[d2,a2,a3],16
 cmp d3,d2
 bne 7f
 mov (8,sp),a0
 call gd_check,[d2,d3,a2,a3],16
 cmp 0,d0
 bne 7f
 mov (8,sp),d0
 mov d0,(GPTR,a2)                 /* published last */
 call x_load,[d2,d3],12           /* v0.20: the code block, if this file carries one for this firmware */
 bra 9f
7:
 mov (8,sp),a0
 call free,[],4
 bra 9f
8:
 mov (4,sp),a0
 call fclose,[d2,a2,a3],16
9:
 ret [d2,d3,a2,a3],28

/* gd_check: a0 = buffer, d3 = n -> d0 0 valid / 1 invalid. */
gd_check:
 mov a0,a3
 mov (a3),d0
 cmp GMAGIC,d0
 bne 1f
 mov (4,a3),d0
 cmp d3,d0
 bne 1f
 mov -1,d0
 mov a3,a0
 add 12,a0
 mov d3,d1
 add -12,d1
 call sd_crc,[d2,d3],12
 not d0
 mov (8,a3),d1
 cmp d1,d0
 bne 1f
 movhu (12,a3),d0
 cmp 175,d0
 bne 1f
 movhu (14,a3),d0
 cmp 50,d0
 bne 1f
 mov (16,a3),d0                   /* s1 */
 cmp 9,d0
 bcs 1f
 mov (20,a3),d1                   /* s2 */
 cmp 9,d1
 bcs 1f
 add 3,d0
 and -4,d0
 mov d0,d2                        /* align4(s1) */
 add 32,d0
 add d1,d0
 cmp d3,d0
 bhi 1f                           /* streams inside the file */
 mov (32,a3),d0
 cmp GHDR,d0
 bne 1f
 mov a3,a0
 add d2,a0
 mov (32,a0),d0
 cmp GHDR,d0
 bne 1f
 mov (24,a3),d1                   /* s3: optional third (WB) stream */
 cmp 0,d1
 beq 2f
 cmp 9,d1
 bcs 1f
 mov (20,a3),d0
 add 3,d0
 and -4,d0
 add d2,d0
 add 32,d0                        /* its offset */
 mov d0,d2
 add d1,d0
 cmp d3,d0
 bhi 1f
 mov a3,a0
 add d2,a0
 mov (a0),d0
 cmp GHDR,d0
 bne 1f
 mov (28,a3),d0                   /* s4: optional fourth (Glow) stream, after s3 */
 cmp 0,d0
 beq 2f
 cmp 9,d0
 bcs 1f
 add 3,d1
 and -4,d1
 add d1,d2                        /* its offset = s3 offset + align4(s3) */
 add d2,d0
 cmp d3,d0
 bhi 1f
 mov a3,a0
 add d2,a0
 mov (a0),d0
 cmp GHDR,d0
 bne 1f
2:
 clr d0
 ret [d2,d3,a2,a3],16
1:
 mov 1,d0
 ret [d2,d3,a2,a3],16

/* gd_set: `call gd_set,[d2,a2],8`, a2 = P, d0 = page (2 Hue, 1 Light, else stock). Uses d1, a0, a1.
 * Only when the descriptor is the stock 14/175x50/8 one and its payload is the stock stream or one of ours. */
gd_set:
 mov GDESC,a0
 movhu (a0),d1
 cmp 14,d1
 bne 9f
 movhu (2,a0),d1
 cmp 175,d1
 bne 9f
 movhu (4,a0),d1
 cmp 50,d1
 bne 9f
 movhu (6,a0),d1
 cmp 8,d1
 bne 9f
 mov (GPTR,a2),a1
 mov (16,a0),d1
 add -4,sp
 call nm_own,[],0                 /* a name picture of ours: d1 = GSTOCK_P */
 add 4,sp
 mov (GPTR,a2),a1
 cmp GSTOCK_P,d1
 beq 1f
 cmp 0,a1
 beq 9f                           /* someone else's payload: leave it */
 mov a1,d2
 sub d2,d1                        /* payload - G */
 cmp 24576,d1
 bcc 9f
1:
 cmp 4,d0
 bne 1f
 add -4,sp
 call nm_pick,[],0                /* Profiles page: the selected profile's name picture, if NAMES.BIN has one */
 add 4,sp
 cmp 0,d0
 beq 9f
 mov 4,d0
 mov (GPTR,a2),a1
1:
 cmp 0,a1
 beq 4f
 cmp 2,d0
 beq 2f
 cmp 1,d0
 beq 3f
 cmp 4,d0
 beq 6f
 cmp 3,d0
 bne 4f
 mov (24,a1),d1                   /* WB picture, if the file has one */
 cmp 0,d1
 bne 5f
4:
 mov GSTOCK_S,d1
 mov d1,(12,a0)
 mov GSTOCK_P,d1
 mov d1,(16,a0)
 bra 9f
2:
 mov (16,a1),d1
 mov d1,(12,a0)
 mov a1,d1
 add 32,d1
 mov d1,(16,a0)
 bra 9f
3:
 mov (20,a1),d1
 mov d1,(12,a0)
 mov (16,a1),d1
 add 3,d1
 and -4,d1
 add 32,d1
 mov a1,d2
 add d2,d1
 mov d1,(16,a0)
 bra 9f
5:
 mov d1,(12,a0)                   /* s3 */
 mov (16,a1),d1
 add 3,d1
 and -4,d1
 mov (20,a1),d2
 add 3,d2
 and -4,d2
 add d2,d1
 add 32,d1
 mov a1,d2
 add d2,d1
 mov d1,(16,a0)
9:
 ret [d2,a2],8
6:                                /* Glow picture (s4 at +28), if the file has one and an s3 */
 mov (28,a1),d1
 cmp 0,d1
 beq 4b
 mov (24,a1),d2
 cmp 0,d2
 beq 4b
 mov d1,(12,a0)                   /* s4 */
 mov (16,a1),d1
 add 3,d1
 and -4,d1
 add 3,d2
 and -4,d2
 add d2,d1                        /* align4(s1) + align4(s3) */
 mov (20,a1),d2
 add 3,d2
 and -4,d2
 add d2,d1                        /* + align4(s2) */
 add 32,d1
 mov a1,d2
 add d2,d1
 mov d1,(16,a0)
 bra 9b


/* ed_event <- COLOR1-4 editor records +36 (stock 0x61225d52; the router's catch-all, which handles the held-OK
 * reset 0x903e). CALLS: d0 event, d1 arg, a0 parent. Reset with a loaded table: the stock reset runs with the page
 * set to Saturation (so it resets the stock saturation), then the profile's Hue and Light are cleared, marked dirty
 * (saved on the next half-press), and the current page's children and screen refreshed. Locals as ed_info:
 * (4) d1, (8) a1, (12) cursor id, (16) value, (20) P, (24) event (0x903e wheel / 0xf881 COLOR n item). Everything else: jmp stock, registers intact. */
ed_event:
 cmp 0x903e,d0                    /* held OK on the wheel */
 beq 1f
 cmp 0xf881,d0                    /* held OK on the COLOR n item: the whole profile */
 beq 1f
 jmp stock_event
1:
 movm [d2,d3,a2,a3],(sp)
 add -28,sp
 mov d1,(4,sp)
 mov a1,(8,sp)
 mov d0,(24,sp)                   /* the event */
 mov a0,a3
 cmp 0,a3
 beq e_no
 movhu (96,a3),d0                 /* editor key 0x1540..0x1543 = COLOR1..4 */
 add -0x1540,d0
 cmp 4,d0
 bcc e_no
 mov d0,d1
 add 2197,d1
 mov d1,(12,sp)                   /* cursor setting id (for k_cur / the poke) */
 PVAL e_no
 mov a2,(20,sp)
 movbu (AXIS,a2),d2               /* the page the user is on */
 jmp lk_hold                      /* v0.21: code block +88 (the Looks page saves the look; the whole-profile reset
                                     also clears the look selection), else e_rst */
e_rst:
 clr d1
 movbu d1,(AXIS,a2)               /* stock reset on Saturation */
 mov a3,a0
 mov (24,sp),d0
 mov (4,sp),d1
 mov (8,sp),a1
 calls stock_event                /* keeps d2/d3/a2/a3 */
 mov d0,d3                        /* its result */
 mov (20,sp),a2
 movbu d2,(AXIS,a2)               /* back to the user's page */
 mov (12,sp),d0                   /* slot k = cursor id - 2197 */
 add -2197,d0
 asl 6,d0
 add 32,d0
 mov a2,a0
 add d0,a0                        /* slot entry: hue[12] +0, light[12] +12 */
 clr d0
 mov 54,d1                        /* slot +0..53 (hue, light, WB, flags, Blacks/Whites, Extras glow/art/NR/VigFix) */
2:
 movbu d0,(a0)
 inc a0
 add -1,d1
 bne 2b
 mov 1,d0
 movbu d0,(DIRTY,a2)              /* saved to the card on the next half-press */
 cmp 0,d2
 beq 4f                           /* on Saturation the stock reset already redrew */
e_lk:
 mov 128,d2                       /* Hue/Light page: children 1..12 re-read (now 0) */
3:
 mov a3,a0
 add d2,a0
 mov (a0),a0
 cmp 0,a0
 beq 4f
 call refresh,[d2,d3,a2,a3],68
 add 4,d2
 cmp 176,d2
 bne 3b
 call k_cur,[a2],8                /* poke the cursor setting so the screen rebuilds */
 cmp 0,d0
 bne 4f
 call facade,[],4
 mov (a0),a2
 mov (4,a2),a2
 mov (16,sp),a1
 clr d1
 mov (12,sp),d0
 calls (a2)
4:
e_ret:
 mov d3,d0
 ret [d2,d3,a2,a3],44
e_no:
 mov a3,a0
 mov (24,sp),d0
 mov (4,sp),d1
 mov (8,sp),a1
 add 28,sp
 movm (sp),[d2,d3,a2,a3]
 jmp stock_event

/* ed_pmod <- jmp from 0x6129ba07, stock "COLOR profile changed?" (d0 picture mode 54/55/56/64 = COLOR1/2/3/4; its 18
 * settings at 0x6037ec10/eca0/ed30/edc0, 8-byte entries, id at +4). The same loop as stock but through ed_isdef, so
 * the '*' after COLOR n and the look name also follow Hue, Light and WB. Frame: the caller's call [d2,d3,a2],16. */
ed_pmod:
 clr d3                           /* v0.21 lk11: '*' = anything differs from the factory defaults (look or not) */
 mov 0x6037ec10,a2
 cmp 54,d0
 beq 1f
 mov 0x6037eca0,a2
 cmp 55,d0
 beq 1f
 mov 0x6037ed30,a2
 cmp 56,d0
 beq 1f
 mov 0x6037edc0,a2
 cmp 64,d0
 bne 3f
1:
 clr d2
 inc4 a2
2:
 mov (a2),d0
 call ed_isd0,[d2,d3,a2],24
 cmp d3,d0
 bne 4f
 mov 1,d3
 bra 3f
4:
 inc d2
 add 8,a2
 cmp 18,d2
 bcs 2b
3:
 mov d3,d0
 ret [d2,d3,a2],16

/* ed_isdef <- the nine calls of stock "is at default" 0x6129bad6 (call [d2,d3,a2],24; d0 id -> d0 1 default, 0 changed).
 * They drive the '*' after COLOR n / the look name and the "Reset [OK hold]" guide (v0.21: with a look selected,
 * ed_pmod asks the code block instead). Stock first; a COLOR1-4 sector
 * id that stock calls default is reported changed when its Hue or Light is non-zero, or when the profile's WB shift is
 * on and non-zero. Reads only. */
ed_isd0:                          /* lk11: ed_pmod's entry ('*'): the Looks page is compared too */
 mov 1,d1
 bra 86f
ed_isdef:
 clr d1
86:
 mov d0,d2
 PVAL 85f
 movbu (AXIS,a2),d3               /* stock compare on Saturation, whatever page is open ... */
 cmp 4,d3                         /* v0.21: the Looks page reads "at default": no "Reset [OK hold]" guide there */
 bne 87f                          /* (OK held there saves the look, it never resets) */
 cmp 0,d1
 beq 8f
87:
 clr d0
 movbu d0,(AXIS,a2)
 mov d2,d0
 call stock_isdef,[d2,d3,a2],24   /* keeps d2/d3/a2 */
 movbu d3,(AXIS,a2)               /* ... then the page back */
 cmp 0,d0
 beq 9f
 exthu d2
 add -928,d2
 cmp 48,d2
 bcc 8f
 mov a2,a0
 add 32,a0                        /* slot 0 entry */
81:
 cmp 12,d2
 bcs 82f
 add -12,d2
 add 64,a0
 bra 81b
82:
 movbu (47,a0),d3                 /* Blacks, Whites, Extras Glow/Clarity, Art Effect, NR, VigFix: any non-zero */
 mov (48,a0),d1                   /* +48..51 (slot entries are 4-aligned: P + 32 + 64k) */
 or d1,d3
 mov (52,a0),d1                   /* +52..55: VigFix, Grain, two zero bytes */
 or d1,d3
 cmp 0,d3
 bne 7f
 movbu (25,a0),d3                 /* WB on: bit0 set, bit7 clear */
 and 0x81,d3
 cmp 1,d3
 bne 83f
 movbu (26,a0),d3
 cmp 0,d3
 bne 7f
 movbu (27,a0),d3
 cmp 0,d3
 bne 7f
83:
 add d2,a0
 movbu (a0),d3                    /* hue */
 cmp 0,d3
 bne 7f
 movbu (12,a0),d3                 /* light */
 cmp 0,d3
 bne 7f
8:
 mov 1,d0
 bra 9f
7:
 clr d0
9:
 ret [d2,d3,a2],24
85:                               /* no table: stock as is */
 mov d2,d0
 call stock_isdef,[d2,d3,a2],24
 ret [d2,d3,a2],24

ext10_end:

.section .ext3,"ax"
gd_mode:                          /* v0.21: moved from the section-10 tail (room for the Looks-page guide test) */
 .asciz "r"

/* ------------------------------------------------------------------ section-5 tail: per-profile Blacks / Whites
 * Port of Caduceus E-P7 patches/tone_ends (cakelesscoder/caduceus-ep7, Apache-2.0, docs/TONE_ENDS.md) to OM-3.
 * Hook 0x605197d7 in the development stage list (0x605197cb COLOR stage, 0x605197d2 luminance-LUT builder
 * 0x60518db2 = E-P7 0x603b0a70): the 7-byte call keeps the stock register list, frame and return address
 * (0x605197de); tone replays `mov d3,a0` and jumps to 0x60518fa4, which returns there.
 * d3 = context C; C+4 = request R, C+12 = output O; O+3828 = active 256 x u16 luminance LUT (10-bit, E-P7 O+2608),
 * O+3832 = the job's own 512-B buffer (E-P7 O+2612); the stock tone step also clears O+0 bit 16 (E-P7 O+4 bit 8).
 * Gates: LUT present; idempotent (O+3828 == O+3832 is remapped only when the builder rebuilt it this pass: art
 * override R+1568 or C+60 & 0x4134063e, the builder's own test); request key 11 (COLOR); table P valid; some COLOR
 * slot has Blacks/Whites != 0; effective COLOR profile 1..4 (getter 63153, as hl_pp / wb_get); slot +47 Blacks,
 * +48 Whites, s8 -5..5 (outside counts as 0). Remap = Caduceus tools/ep7_tone.py remap(), bit-exact.
 * Stores: own stack frame, O+3832..O+4343, O+3828, O+0. */
.section .ext5,"ax"
tone:
 add -52,sp
 mov d0,(48,sp)              /* (0,sp) is the getter call's return word */
 mov d1,(4,sp)
 mov d2,(8,sp)
 mov d3,(12,sp)
 mov a1,(16,sp)
 mov a2,(20,sp)
 mov a3,(24,sp)
 mov mdr,d0
 mov d0,(28,sp)
 mov d3,a2                        /* a2 = context C */
 mov (12,a2),a3                   /* a3 = output O */
 mov (3828,a3),d0
 cmp 0,d0
 beq t9                           /* no LUT */
 mov a3,d1
 add 3832,d1
 cmp d1,d0
 bne t1
 mov (4,a2),a1
 mov (1568,a1),d1
 cmp 0,d1
 bne t1
 mov (60,a2),d1
 and 0x4134063e,d1
 beq t9                           /* last pass's output (ours): keep */
t1:
 mov (4,a2),a1                    /* request R */
 movhu (10,a1),d0                 /* key 11 (COLOR), or 12 with +1731 0 (a COLOR still taking the camera's grain; */
 cmp 11,d0                        /* MONO has 0xa0 there) */
 beq 1f
 cmp 12,d0
 bne t9
 movbu (1731,a1),d0
 cmp 0,d0
 bne t9
1:
 PVAL t9                          /* a2 = P (C no longer needed) */
 mov a2,a0
 add 32,a0
 clr d1                           /* any COLOR slot with Blacks/Whites? */
 mov 4,d2
t2:
 movbu (47,a0),d0
 or d0,d1
 movbu (48,a0),d0
 or d0,d1
 add 64,a0
 add -1,d2
 bne t2
 cmp 0,d1
 beq t9                           /* no getter call */
 mov 63153,d0                     /* effective COLOR profile number */
 clr d1
 mov 0,a0
 call getter,[d2,d3],12           /* keeps a2/a3 */
 add -1,d0
 cmp 4,d0
 bcc t9
 asl 6,d0
 add 32,d0
 mov a2,a0
 add d0,a0                        /* a0 = slot entry */
 movbu (47,a0),d0                 /* Blacks */
 extb d0
 add 5,d0
 cmp 11,d0
 bcs 3f
 mov 5,d0
3:
 add -5,d0
 movbu (48,a0),d1                 /* Whites */
 extb d1
 add 5,d1
 cmp 11,d1
 bcs 4f
 mov 5,d1
4:
 add -5,d1
 mov d0,d2
 or d1,d2
 beq t9                           /* B = W = 0: no copy, no store */
 clr d2                           /* lo = 8B (B > 0) */
 clr d3                           /* cB = -12B (B < 0) */
 cmp 0,d0
 blt 5f
 mov d0,d2
 asl 3,d2
 bra 6f
5:
 mov -12,d3
 mul d0,d3
6:
 mov d2,(32,sp)
 mov d3,(36,sp)
 mov 1023,d3                      /* hi = 1023 + 10W (W < 0) */
 clr d2                           /* cW = 12W (W > 0) */
 cmp 0,d1
 blt 7f
 mov 12,d2
 mul d1,d2
 bra 8f
7:
 mov 10,d0
 mul d1,d0
 add d0,d3
8:
 mov d2,(40,sp)
 mov (32,sp),d0
 sub d0,d3                        /* span = hi - lo */
 mov 1025,d0
 mul d0,d3
 mov d3,(44,sp)                   /* K = span * 1025 */
 mov a3,a0
 add 3832,a0                      /* a0 = O+3832 */
 mov (3828,a3),a1
 cmp a0,a1
 beq 1f
 clr d1
2:
 movhu (d1,a1),d0
 movhu d0,(d1,a0)
 add 2,d1
 cmp 512,d1
 bne 2b
 mov a0,(3828,a3)                 /* O+3828 = O+3832 */
1:
 mov (a3),d0
 and -65537,d0                    /* clear O+0 bit 16, as the stock tone step does */
 mov d0,(a3)
 mov a0,a1
 add 512,a1
 clr d3                           /* running max */
10:
 movhu (a0),d0
 cmp 1023,d0
 bls 11f
 mov 1023,d0
11:
 mov 1023,d1                      /* toe crush: y -= cB * ((t*t>>10)*t>>10) >> 10, t = 1023 - y */
 sub d0,d1
 mov d1,d2
 mul d1,d2
 lsr 10,d2
 mul d1,d2
 lsr 10,d2
 mov (36,sp),d1
 mul d1,d2
 lsr 10,d2
 sub d2,d0
 bge 12f
 clr d0
12:
 mov d0,d2                        /* shoulder push: y += cW * ((y*y>>10)*y>>10) >> 10 */
 mul d0,d2
 lsr 10,d2
 mul d0,d2
 lsr 10,d2
 mov (40,sp),d1
 mul d1,d2
 lsr 10,d2
 add d2,d0
 cmp 1023,d0
 bls 13f
 mov 1023,d0
13:
 mov (44,sp),d1                   /* y = lo + (y*K + 0xFFFFF) >> 20 */
 mul d1,d0
 add 1048575,d0
 lsr 20,d0
 mov (32,sp),d1
 add d1,d0
 cmp d3,d0                        /* running max */
 bcc 14f
 mov d3,d0
14:
 mov d0,d3
 movhu d0,(a0)
 add 2,a0
 cmp a1,a0
 bne 10b
t9:
 mov (28,sp),d0
 mov d0,mdr
 mov (48,sp),d0
 mov (4,sp),d1
 mov (8,sp),d2
 mov (12,sp),d3
 mov (16,sp),a1
 mov (20,sp),a2
 mov (24,sp),a3
 add 52,sp
 mov d3,a0                        /* displaced 0x605197d7 */
 jmp tone_next                    /* 0x60518fa4; returns to 0x605197de */


/* ------------------------------------------------------------------ section-3 tail: look library page (test 14)
 * LOOKS.BIN (written by the OM-3 Look Lab web tool): 'OM3K' | u32 total | u32 CRC-32 of bytes 12.. | u16 version 1 |
 * u16 n (1..16) | 16 zero | n x 32-B looks | n x 16-B names (ignored here). Look: hue[12] +0, light[12] +12 (s8 -5..5,
 * UI sector order), +24 wb on (0/1), +25 A-B, +26 G-M, +27 Blacks, +28 Whites (s8 -5..5), +29..31 zero.
 * P+LPTR = the checked heap copy (0 = none), P+LIDX+k = profile k's look number (0 = "My own"), P+BKUP+64k = the
 * slot entry as it was when profile k left look 0 (put back on the way to 0). Hand edits (s_dirty) and the resets set
 * the number back to 0. Not saved: after a power cycle the saved slot simply is "My own".
 *
 * (test 14: lk_up / lk_down <- COLOR1-4 editor records; test 15: s_look below instead) +12 / +16 (stock Up 0x61223ef7 / Down 0x612241b6: main-dial steps;
 * CALLS, d1 arg, a0 parent; neither reads d0 or a1). On the Looks page (axis 4, P valid, marker, looks loaded): one
 * look forward / back with wrap 0..n, the slot rewritten, dirty, children re-read and the cursor poked (as ed_event),
 * -> d0 1. Anything else: every register as at entry, jmp stock. Locals as ed_event: (4) d1, (8) a1, (12) cursor id,
 * (16) cursor value, (20) P, (24) d0. Stores: the heap block P, own frame. */
.section .ext3,"ax"
s_look:                           /* after WHERE (a2 = P, d2 = 64k + slice, d3 = 3); d0 id, d1 value, a0 inner, a1 mode */
 mov d2,d3                        /* Profile bank: 12 o'clock value 1..5 = bank profile, anything else = 0 (neutral). */
 and 63,d3                        /* Every value is accepted (the dial widget keeps what it asked for). */
 cmp 0,d3
 bne 8f
 mov (LPTR,a2),a3
 cmp 0,a3
 beq 8f
 lsr 6,d2                         /* k */
 add -24,sp                       /* (0) call scratch, (4) id, (8) inner, (12) mode, (16) k, (20) new profile */
 mov d0,(4,sp)
 mov a0,(8,sp)
 mov a1,(12,sp)
 mov d2,(16,sp)
 mov a2,a0
 add d2,a0
 movbu (LIDX,a0),d0
 extb d0                          /* old value */
 movbu d1,(LIDX,a0)               /* new value: what the wheel and readout show */
 cmp 1,d1
 blt 1f
 cmp 5,d1
 ble 2f
1:
 clr d1
2:
 cmp 1,d0
 blt 1f
 cmp 5,d0
 ble 2f
1:
 clr d0
2:
 mov d1,(20,sp)
 cmp d0,d1
 beq 7f
 mov (16,sp),d2                   /* v0.21: leaving a look keeps it as saved (unsaved edits are dropped) */                   /* load the new one (0: neutral) into the slot and the camera's own settings */
 mov (20,sp),d3
 mov (8,sp),a0
 mov (12,sp),a1
 call pf_put,[d2,d3,a2,a3],40
 mov 4,d0
 call gd_set,[d2,a2],8            /* test 17: the name picture of the new profile (redrawn with the dial step) */
7:
 mov (4,sp),d0
 mov (8,sp),a0
 mov (12,sp),a1
 add 24,sp
 jmp s_dirty2                     /* dirty, then the manager with the id's Saturation value (screen refresh) */
8:
 jmp s_bad

/* pf_cap: `call pf_cap,[d2,d3,a2,a3],28`, a2 = P, d2 = k (0..3), d3 = profile 1..5: the bank record <- COLOR k now
 * (slot hue/light/WB/Blacks/Whites + the camera's own 18 settings via the getter). Locals (0) scratch, (4) offset,
 * (8) k. Stores: the bank record only. */
pf_cap:
 mov d2,d0
 asl2 d0
 add d2,d0
 add d3,d0
 add -1,d0
 asl 6,d0
 add 32,d0
 mov (LPTR,a2),a3
 add d0,a3                        /* a3 = record */
pf_capto:                         /* v0.21: the same into a3 (code block xb_lkd: a scratch record) */
 mov d2,(8,sp)
 mov d2,d0
 asl 6,d0
 add 32,d0
 mov a2,a0
 add d0,a0                        /* a0 = slot entry */
 mov a3,a1
 mov 24,d1
1:
 movbu (a0),d0
 movbu d0,(a1)
 inc a0
 inc a1
 add -1,d1
 bne 1b
 movbu (1,a0),d0                  /* a0 = slot + 24 */
 and 1,d0
 movbu d0,(36,a3)
 movbu (2,a0),d0
 movbu d0,(37,a3)
 movbu (3,a0),d0
 movbu d0,(38,a3)
 movbu (23,a0),d0
 movbu d0,(39,a3)
 movbu (24,a0),d0
 movbu d0,(40,a3)
 movbu (25,a0),d0                 /* v0.20: slot +49 Glow/Clarity, +50 Frame -> record +47, +48 */
 movbu d0,(47,a3)
 movbu (26,a0),d0
 movbu d0,(48,a3)
 movbu (27,a0),d0                 /* slot +51 NR -> record +49 */
 movbu d0,(49,a3)
 movbu (28,a0),d0                 /* v0.21: slot +52 VigFix -> record +50 */
 movbu d0,(50,a3)
 movbu (29,a0),d0                 /* slot +53 Grain -> record +51 */
 movbu d0,(51,a3)
 clr d3
2:
 mov pf_ids,a0
 mov d3,d0
 asl2 d0
 add d0,a0
 movbu (3,a0),d0
 mov d0,(4,sp)
 movbu (2,a0),d1
 mov (8,sp),d2
 mul d2,d1
 movhu (a0),d0
 add d1,d0                        /* id for COLOR k */
 call sget,[],4                   /* d0 = value (keeps d2/d3/a2/a3) */
 mov (4,sp),d1
 movbu d0,(d1,a3)
 inc d3
 cmp 18,d3
 bne 2b
 ret [d2,d3,a2,a3],28

/* pf_load: `call pf_load,[d2,d3,a2,a3],28` from sd_load after gd_load, a2 = P. Locals (4) handle, (8) buffer.
 * LOOKS.BIN (PF_LEN B; v0.19, before: PROFILES.BIN, read when there is no LOOKS.BIN) checked -> bank; no file -> a neutral bank (saved on the first half-press save);
 * a file that fails the check -> no bank (the file is left alone). P+LIDX+k = the saved selection. Stores: P+LPTR,
 * P+LIDX, the heap buffer, own frame. */
.section .ext8,"ax"
pf_load:
 mov PF_LEN,d0
 call malloc,[],4
 cmp 0,a0
 beq 9f
 mov a0,(8,sp)
 call pf_open,[],4                /* LOOKS.BIN, else PROFILES.BIN (v0.19) */
 cmp 0,a0
 beq 5f                           /* no file: neutral bank */
 mov a0,(4,sp)
 mov (8,sp),a0
 mov 1,d0
 mov PF_LEN,d1
 mov (4,sp),a1
 call fread,[d2,d3,a2,a3],24
 mov d0,d2
 mov (4,sp),a0
 call fclose,[d2,a2,a3],16
 cmp PF_LEN,d2
 bne 7f
 mov (8,sp),a0
 mov PF_LEN,d3
 call pf_check,[d2,d3,a2,a3],20
 cmp 0,d0
 bne 7f
 mov (8,sp),a0
 clr d2
1:
 mov a0,a1
 add d2,a1
 movbu (16,a1),d0                 /* saved selection */
 mov a2,a1
 add d2,a1
 movbu d0,(LIDX,a1)
 inc d2
 cmp 4,d2
 bne 1b
 bra 6f
5:
 mov (8,sp),a0
 mov PF_LEN,d1
 clr d0
2:
 movbu d0,(a0)
 inc a0
 add -1,d1
 bne 2b
 mov (8,sp),a0
 mov PFMAGIC,d0
 mov d0,(a0)
 mov PF_LEN,d0
 mov d0,(4,a0)
 mov 1,d0
 movhu d0,(12,a0)
 mov 20,d0
 movhu d0,(14,a0)
6:
 mov (8,sp),d0
 mov d0,(LPTR,a2)                 /* published last */
 bra 9f
7:
 mov (8,sp),a0
 call free,[],4
9:
 ret [d2,d3,a2,a3],28

/* pf_check: `call pf_check,[d2,d3,a2,a3],20`, a0 = buffer, d3 = size -> d0 0 ok / 1 bad. Reads only.
 * PROFILES.BIN v1: 'OM3P' | u32 1632 | crc32(12..) | u16 1 | u16 20 | sel[4] 0..5 | 12 zero | 20 x 64-B records
 * (COLOR k profile v at 5k + v - 1) | 20 x 16-B names. Record: hue[12] +0, light[12] +12, sat[12] +24, +36 wb on,
 * +37 A-B, +38 G-M, +39 Blacks, +40 Whites, +41 Contrast, +42 Sharpness, +43 Shading, +44 Shadows, +45 Midtones,
 * +46 Highlights, +47..63 zero. */
.section .ext4,"ax"
pf_check:
 mov a0,a3
 mov (a3),d0
 cmp PFMAGIC,d0
 bne 9f
 mov (4,a3),d0
 cmp d3,d0
 bne 9f
 mov -1,d0
 mov a3,a0
 add 12,a0
 mov d3,d1
 add -12,d1
 call sd_crc,[d2,d3],12
 not d0
 mov (8,a3),d1
 cmp d1,d0
 bne 9f
 movhu (12,a3),d0
 cmp 1,d0
 bne 9f
 movhu (14,a3),d0
 cmp 20,d0
 bne 9f
 clr d2
2:
 mov a3,a0
 add d2,a0
 movbu (16,a0),d0
 cmp 5,d0
 bhi 9f
 inc d2
 cmp 4,d2
 bne 2b
 mov 1280,d1
 mov a3,a0
 add 32,a0
 mov pf_lo,a1
 clr d2
1:
 movbu (a0),d0
 extb d0
 movbu (a1),d3
 extb d3
 sub d3,d0
 cmp 0,d3
 blt 4f
 clr d3                           /* lo >= 0: span 1 for byte 36, else 0 */
 cmp 36,d2
 bne 5f
 mov 1,d3
 bra 5f
4:
 not d3                           /* lo < 0: span = -2 lo */
 inc d3
 add d3,d3
5:
 cmp d3,d0
 bhi 9f
 inc a0
 inc a1
 inc d2
 cmp 64,d2
 bne 3f
 clr d2
 mov pf_lo,a1
3:
 add -1,d1
 bne 1b
 clr d0
 ret [d2,d3,a2,a3],20
9:
 mov 1,d0
 ret [d2,d3,a2,a3],20


/* ------------------------------------------------------------------ section-9 tail: profile bank (test 16) */
.section .ext9,"ax"
/* pf_put: `call pf_put,[d2,d3,a2,a3],40` from s_look (inside the facade SetValue: a0 inner, a1 mode), a2 = P,
 * d2 = k, d3 = profile 1..5 or 0 (neutral): the slot entry <- the record, then the camera's own 18 settings of
 * COLOR k through the settings manager (as the GUI's own edits). Locals (0) scratch, (4) inner, (8) mode, (12) k,
 * (16) record or 0, (20) i. Stores: the slot entry, the camera's settings (manager), own frame. */
pf_put:
 mov a0,(4,sp)
 mov a1,(8,sp)
 mov d2,(12,sp)
 mov 0,a3
 cmp 0,d3
 beq 1f
 mov d2,d0
 asl2 d0
 add d2,d0
 add d3,d0
 add -1,d0
 asl 6,d0
 add 32,d0
 mov (LPTR,a2),a3
 add d0,a3
1:
 mov a3,(16,sp)
 mov d2,d0
 asl 6,d0
 add 32,d0
 mov a2,a0
 add d0,a0                        /* slot entry */
 mov a3,a1
 mov 24,d1
2:
 clr d0
 cmp 0,a1
 beq 3f
 movbu (a1),d0
 inc a1
3:
 movbu d0,(a0)
 inc a0
 add -1,d1
 bne 2b
 mov pf_bt,a1                     /* rec +36..40, +47..50 -> slot +25..27, +47, +48, +49..52 (0 for neutral) */
8:
 movbu (a1),d2
 movbu (1,a1),d3
 clr d0
 cmp 0,a3
 beq 7f
 movbu (d2,a3),d0
7:
 movbu d0,(d3,a0)
 add 2,a1
 cmp pf_bt+20,a1
 bne 8b
 movbu (7,a0),d0
 or 2,d0
 movbu d0,(7,a0)                  /* +31 flags: H/L on */
 clr d0
 mov d0,(20,sp)
5:
 mov (20,sp),d3
 mov pf_ids,a0
 mov d3,d0
 asl2 d0
 add d0,a0
 movbu (2,a0),d1
 mov (12,sp),d2
 mul d2,d1
 movhu (a0),d0
 add d1,d0                        /* id */
 movbu (3,a0),d2                  /* record offset */
 mov (16,sp),a1
 cmp 0,a1
 bne 61f
 call pf_dflt,[d2,a3],16          /* lk11: neutral = the camera's factory default of this setting */
 bra 6f
61:
 movbu (d2,a1),d1
 extb d1
6:
 mov (4,sp),a0
 mov (8,sp),a1
 call manager,[d2,d3,a2,a3],68
 mov (20,sp),d3
 inc d3
 mov d3,(20,sp)
 cmp 18,d3
 bne 5b
 ret [d2,d3,a2,a3],40
pf_bt:                            /* record offset, slot offset - 24 */
 .byte 36,1, 37,2, 38,3, 39,23, 40,24, 47,25, 48,26, 49,27, 50,28, 51,29

.section .ext1,"ax"
/* lk_hold (v0.21) <- ed_event on the Looks page (axis 4), in its frame (a2 = P, a3 = parent, d2 = 4, (12,sp) cursor
 * id, (24,sp) event): code block +88 (xb_lkh) does it: OK held on the wheel with a look selected saves COLOR k into the
 * look (pf_cap, dirty, refresh: e_lk), no look: nothing (e_ret), OK held on "COLOR n" (0xf881): the reset (e_rst).
 * Without the code block: the reset. */
/* pf_dflt (lk11): `call pf_dflt,[d2,a3],16` from pf_put, d0 = setting id -> d1 = its factory default (the stock
 * GetDefault, facade +156, as the stock "is at default" check reads it on Saturation), d0 kept. */
pf_dflt:
 mov d0,d2
 clr d1
 mov d1,(4,sp)
 call facade,[],4                 /* a0 = the facade; its GetDefault without our page hook (ed_default reads 0 on */
 mov stock_default,a3             /* the Hue/Light/Looks pages) */
 mov sp,a1
 inc4 a1
 mov d2,d0
 calls (a3)
 mov (4,sp),d1
 mov d2,d0
 ret [d2,a3],16

lk_hold:
 call xp,[],0
 beq 7f
 add 88,a1
 jmp (a1)
7:
 jmp e_rst


.section .ext9,"ax"
/* pf_save: `call pf_save,[d2,d3,a2,a3],24` from ed_trig after ed_save, a2 = P: selection bytes, CRC, then
 * LOOKS.NEW and LOOKS.BIN (v0.19; PROFILES.* before), each read back. Locals (0) scratch, (4) read-back buffer. */
pf_save:
 mov (LPTR,a2),a3
 cmp 0,a3
 beq 9f
 clr d2
1:
 mov a2,a0
 add d2,a0
 movbu (LIDX,a0),d0
 extb d0
 cmp 1,d0
 blt 2f
 cmp 5,d0
 ble 3f
2:
 clr d0
3:
 mov a3,a0
 add d2,a0
 movbu d0,(16,a0)
 inc d2
 cmp 4,d2
 bne 1b
 mov -1,d0
 mov a3,a0
 add 12,a0
 mov PF_LEN-12,d1
 call sd_crc,[d2,d3],12
 not d0
 mov d0,(8,a3)
 mov PF_LEN,d0
 call malloc,[],4
 cmp 0,a0
 beq 9f
 mov a0,(4,sp)
 mov a0,d2
 mov pf_pnew,a0
 call pf_w,[d2,d3,a2,a3],28
 cmp 0,d0
 bne 8f
 mov (4,sp),d2
 mov pf_pbin,a0
 call pf_w,[d2,d3,a2,a3],28
8:
 mov (4,sp),a0
 call free,[],4
9:
 mov (XPTR,a2),a1                 /* v0.21: code block +72 after each half-press save (HLS_EVENT task) */
 cmp 0,a1
 beq 7f
 add 72,a1
 calls (a1)
7:
 ret [d2,d3,a2,a3],24

.section .ext6,"ax"
/* pf_w: `call pf_w,[d2,d3,a2,a3],28`, a0 path, a3 bank (PF_LEN B), d2 read-back buffer -> d0 0 ok / 1 fail.
 * Locals (4) handle, (8) path. */
pf_w:
 mov a0,(8,sp)
 mov ed_m_w,a1
 call fopen,[],4
 cmp 0,a0
 beq 9f
 mov a0,(4,sp)
 mov a0,a1
 mov PF_LEN,d1
 mov 1,d0
 mov a3,a0
 call fwrite,[d2,d3,a2,a3],24
 mov d0,d3
 mov (4,sp),a0
 call fclose,[d2,a2,a3],16
 cmp PF_LEN,d3
 bne 9f
 mov (8,sp),a0
 mov sd_mode,a1
 call fopen,[],4
 cmp 0,a0
 beq 9f
 mov a0,(4,sp)
 mov a0,a1
 mov d2,a0
 mov 1,d0
 mov PF_LEN,d1
 call fread,[d2,d3,a2,a3],24
 mov d0,d3
 mov (4,sp),a0
 call fclose,[d2,a2,a3],16
 cmp PF_LEN,d3
 bne 9f
 mov a3,a0
 mov d2,a1
 mov PF_LEN,d3
5:
 movbu (a0),d0
 movbu (a1),d1
 cmp d0,d1
 bne 9f
 inc a0
 inc a1
 add -1,d3
 bne 5b
 clr d0
 ret [d2,d3,a2,a3],28
9:
 mov 1,d0
 ret [d2,d3,a2,a3],28

 .section .ext5,"ax"
 .balign 2
pf_ids:                           /* u16 id for COLOR1, u8 step per COLOR, u8 record offset */
 .irp s,0,1,2,3,4,5,6,7,8,9,10,11
 .hword 928+\s
 .byte 12, 24+\s
 .endr
 .hword 908
 .byte 1, 41                      /* Contrast */
 .hword 904
 .byte 1, 42                      /* Sharpness */
 .hword 912
 .byte 1, 43                      /* Shading */
 .hword 978
 .byte 3, 44                      /* Shadows */
 .hword 977
 .byte 3, 45                      /* Midtones */
 .hword 976
 .byte 3, 46                      /* Highlights */
.section .ext3,"ax"
pf_lo:                            /* record byte i: lo; span = -2 lo for lo < 0, 1 for byte 36 (WB on 0/1), else 0
                                     (test 18: the span half of this table is computed, to make room) */
 .byte -5,-5,-5,-5,-5,-5,-5,-5,-5,-5,-5,-5, -5,-5,-5,-5,-5,-5,-5,-5,-5,-5,-5,-5, -5,-5,-5,-5,-5,-5,-5,-5,-5,-5,-5,-5
 .byte 0, -5,-5,-5,-5, -2,-2,-5, -7,-7,-7, -5,-5,-5, -1, -5, 0,0,0,0,0,0,0,0,0,0,0,0
pf_pnew:
 .asciz "C:\\OM3MOD\\LOOKS.NEW"
pf_pbin:
 .asciz "C:\\OM3MOD\\LOOKS.BIN"

/* ------------------------------------------------------------------ Profiles page dial range 0..5 (test 16b)
 * The dial's value list is built from the facade's count (+28) and value-by-index (+32) every time the editor's
 * children are refreshed (editor open, each INFO page change). On the Profiles page the 12 o'clock id gets 6 values,
 * 0..5, so the dial stops at 0 and 5. Everything else: stock, registers as at entry. CALLS entries. */
.section .ext1,"ax"
/* ------------------------------------------------------------------ profile names (test 17)
 * NAMES.BIN v1 (written by the Look Lab with PROFILES.BIN): 'OM3N' | u32 total | u32 crc32(bytes 12..) | u16 1 |
 * u16 20 | u16 175 | u16 50 | 12 zero | 4 groups {u32 offset, u32 length} at 32 (group k = COLOR k's pictures,
 * contiguous from 144, each <= 16384 B) | 20 entries {u16 offset in its group, u16 length} at 64 (COLOR k profile v
 * at 5k + v - 1; length 0 = none) | group data. A picture = an OSD type-11 stream 175 x 50 (header GHDR).
 * P+NENT = the 20 entries, P+NPTR+4k = group k's heap copy (0 = none). */
.section .ext4,"ax"
/* nm_load: `call nm_load,[d2,d3,a2,a3],36` from sd_load (HLS task), a2 = P. Locals (4) handle, (8) CRC, (12) k,
 * (16) next offset. The 64-byte header is read into P+TBUF (the title buffers, not yet in use). Stores: P+NENT,
 * P+NPTR, heap buffers, own frame. */
nm_load:
 clr d0
 mov d0,(NPTR,a2)
 mov d0,(NPTR+4,a2)
 mov d0,(NPTR+8,a2)
 mov d0,(NPTR+12,a2)
 mov nm_path,a0
 mov gd_mode,a1
 call fopen,[],4
 cmp 0,a0
 beq 9f
 mov a0,(4,sp)
 mov a2,a0
 add TBUF,a0
 mov 1,d0
 mov 64,d1
 mov (4,sp),a1
 call fread,[d2,d3,a2,a3],24
 cmp 64,d0
 bne 7f
 mov (TBUF,a2),d0
 cmp NMAGIC,d0
 bne 7f
 mov (TBUF+12,a2),d0              /* u16 1 | u16 20 */
 cmp 0x00140001,d0
 bne 7f
 mov (TBUF+16,a2),d0              /* u16 175 | u16 50 */
 cmp 0x003200af,d0
 bne 7f
 mov a2,a0
 add NENT,a0
 mov 1,d0
 mov 80,d1
 mov (4,sp),a1
 call fread,[d2,d3,a2,a3],24
 cmp 80,d0
 bne 7f
 mov -1,d0
 mov a2,a0
 add TBUF+12,a0
 mov 52,d1
 call sd_crc,[d2,d3],12
 mov a2,a0
 add NENT,a0
 mov 80,d1
 call sd_crc,[d2,d3],12
 mov d0,(8,sp)
 mov 144,d0
 mov d0,(16,sp)
 clr d3
1:
 mov d3,(12,sp)
 mov a2,a0
 asl2 d3
 asl d3
 add d3,a0                        /* a0 = P + 8k */
 mov (TBUF+32,a0),d0
 mov (16,sp),d1
 cmp d1,d0
 bne 7f                           /* groups must follow each other */
 mov (TBUF+36,a0),d2              /* length */
 cmp 0,d2
 beq 3f
 cmp 16385,d2
 bcc 7f
 mov d2,d0
 call malloc,[],4
 cmp 0,a0
 beq 7f
 mov (12,sp),d3
 mov a2,a1
 asl2 d3
 add d3,a1
 mov a0,(NPTR,a1)                 /* kept at once, so the failure path frees it */
 mov 1,d0
 mov d2,d1
 mov (4,sp),a1
 call fread,[d2,d3,a2,a3],24
 cmp d2,d0
 bne 7f
 mov (12,sp),d3
 mov a2,a1
 asl2 d3
 add d3,a1
 mov (NPTR,a1),a0
 mov (8,sp),d0
 mov d2,d1
 call sd_crc,[d2,d3],12
 mov d0,(8,sp)
 mov (16,sp),d0
 add d2,d0
 mov d0,(16,sp)
3:
 mov (12,sp),d3
 inc d3
 cmp 4,d3
 bne 1b
 mov (4,sp),a0
 call fclose,[d2,a2,a3],16
 mov (TBUF+4,a2),d0
 mov (16,sp),d1
 cmp d1,d0
 bne 8f
 mov (8,sp),d0
 not d0
 mov (TBUF+8,a2),d1
 cmp d1,d0
 bne 8f
 clr d3                           /* entries: in their group, 4-aligned, and a 175 x 50 picture */
5:
 mov a2,a1
 mov d3,d0
 asl2 d0
 add d0,a1                        /* a1 = P + 4i */
 movhu (NENT+2,a1),d2
 cmp 0,d2
 beq 6f
 movhu (NENT,a1),d1
 mov d3,d0                        /* k = i / 5 */
 mov 0,a0
4:
 cmp 5,d0
 bcs 2f
 add -5,d0
 inc a0
 bra 4b
2:
 mov a0,d0
 mov a2,a0
 asl2 d0
 add d0,a0                        /* a0 = P + 4k */
 asl d0                           /* 8k */
 mov a2,a3
 add d0,a3
 mov (TBUF+36,a3),d0              /* group length */
 btst 3,d1
 bne 4f
 add d1,d2
 cmp d0,d2
 bhi 4f
 mov (NPTR,a0),a0
 cmp 0,a0
 beq 4f
 add d1,a0
 mov (a0),d0
 cmp GHDR,d0
 beq 6f
4:
 clr d0
 movhu d0,(NENT+2,a1)             /* not usable: none */
6:
 inc d3
 cmp 20,d3
 bne 5b
 bra 9f
7:
 mov (4,sp),a0
 call fclose,[d2,a2,a3],16
8:
 clr d3                           /* free whatever was kept */
1:
 mov a2,a1
 mov d3,d0
 asl2 d0
 add d0,a1
 mov (NPTR,a1),a0
 cmp 0,a0
 beq 2f
 clr d0
 mov d0,(NPTR,a1)
 call free,[],4
2:
 inc d3
 cmp 4,d3
 bne 1b
9:
 ret [d2,d3,a2,a3],36

/* nm_pick: `add -4,sp; call nm_pick,[],0; add 4,sp` from gd_set, a2 = P, a0 = GDESC: the name picture of the open
 * editor's COLOR (EDK) and its profile (LIDX) -> descriptor (12) size, (16) payload, d0 0; else d0 1, descriptor
 * untouched. Keeps a0, a2, a3, d3; uses d1, d2, a1. Returns through MDR. */
nm_pick:
 movm [d3],(sp)
 movbu (EDK,a2),d3
 cmp 4,d3
 bcc 9f
 mov a2,a1
 add d3,a1
 movbu (LIDX,a1),d2
 extb d2
 cmp 1,d2
 blt 9f
 cmp 5,d2
 bgt 9f
 mov d3,d1                        /* 4 * (5k + v - 1) */
 asl2 d1
 add d3,d1
 add d2,d1
 add -1,d1
 asl2 d1
 mov a2,a1
 add d1,a1
 movhu (NENT+2,a1),d2             /* length */
 cmp 0,d2
 beq 9f
 movhu (NENT,a1),d1               /* offset */
 asl2 d3
 mov a2,a1
 add d3,a1
 mov (NPTR,a1),d3
 cmp 0,d3
 beq 9f
 add d3,d1
 mov d2,(12,a0)
 mov d1,(16,a0)
 clr d0
 movm (sp),[d3]
 retf [],0
9:
 mov 1,d0
 movm (sp),[d3]
 retf [],0

.section .ext8,"ax"
/* nm_own: `add -4,sp; call nm_own,[],0; add 4,sp` from gd_set, a2 = P, d1 = the descriptor's payload: inside one of
 * our name buffers -> d1 = GSTOCK_P (so gd_set may switch it). Keeps d0, a0, a1, d3; uses d2. */
nm_own:
 movm [d3],(sp)
 clr d3
1:
 mov a2,a1                        /* a1 is reloaded by gd_set after this call */
 add d3,a1
 mov (NPTR,a1),d2
 cmp 0,d2
 beq 2f
 sub d1,d2                        /* d2 = buffer - payload ... */
 not d2
 inc d2                           /* ... negated: payload - buffer */
 cmp 16384,d2
 bcs 8f
2:
 add 4,d3
 cmp 16,d3
 bne 1b
 movm (sp),[d3]
 retf [],0
8:
 mov GSTOCK_P,d1
 movm (sp),[d3]
 retf [],0

.section .ext9,"ax"
gd_path:                          /* test 17: moved here from the section-10 tail (room for the name pictures) */
 .asciz "C:\\OM3MOD\\GUIDES.BIN"

.section .ext4,"ax"
nm_path:                          /* v0.21: moved from the section-9 tail (room for the pf_save block call) */
 .asciz "C:\\OM3MOD\\NAMES.BIN"

.section .ext3,"ax"
/* ei_page: `call ei_page,[],4` from ed_init (test 18), d0 = editor key 0x1540 + k, a2 = P: EDK = k, first-use
 * marker, page = Profiles (4) with a bank, else Saturation (0), and that page's guide picture. Uses d0..d3, a0, a1
 * (ed_init saved them). Stores: P+EDK, P+EMARK/DIRTY/STATUS (first use), P+AXIS, the guide descriptor (gd_set). */
ei_page:
 mov d0,d3
 exthu d3
 add -0x1540,d3
 cmp 4,d3
 bcc 9f                           /* not a COLOR editor key: leave it all */
 movbu d3,(EDK,a2)
 mov (EMARK,a2),d3
 cmp EMAGIC,d3
 beq 2f
 clr d3
 movbu d3,(DIRTY,a2)
 movbu d3,(STATUS,a2)
 mov EMAGIC,d3
 mov d3,(EMARK,a2)
2:
 mov (LPTR,a2),d3
 cmp 0,d3
 beq 3f
 mov 4,d3
3:
 movbu d3,(AXIS,a2)
 mov d3,d0
 call gd_set,[d2,a2],8
9:
 ret [],4

/* pf_open (v0.19): `call pf_open,[],4` -> a0 = fopen(LOOKS.BIN), or when there is none fopen(PROFILES.BIN), the
 * name before v0.19 (read once; the next save writes LOOKS.BIN), or 0. Uses d0, d1, a0, a1 (as fopen).
 * v0.20: moved to the section-7 tail (runs only from the gated half-press load). */
.section .ext7,"ax"
pf_open:                          /* v0.20: LOOKS.BIN only (a v0.17/v0.18 PROFILES.BIN: rename it, same format) */
 mov pf_pbin,a0
 mov gd_mode,a1
 call fopen,[],4
 ret [],4

/* vl_s: `call vl_s,[d2,d3,a2,a3],20` from ed_get's readout path, d2 = slice, a2 = P; keeps d0..d1? no: keeps a0, a1
 * (and the frame's d2, d3, a2, a3). Code block +48 does the work; without one, nothing. */
vl_s:
 mov a0,a3
 mov a1,d3
 call xp,[],0
 cmp 0,a1
 beq 9f
 add 48,a1
 jmp (a1)
9:
 mov a3,a0
 mov d3,a1
 ret [d2,d3,a2,a3],20

/* ------------------------------------------------------------------ v0.20 Extras (test 3)
 * Extras page (axis 5, INFO after WB/BW): 12 o'clock Glow/Clarity -5..5 at slot +49 (- = Glow; + = Clarity, not yet
 * rendered), 6 o'clock Frame at slot +50 (> 0 = on). Look records +47/+48. A COLOR still (no stock Art Effect)
 * gets job flag 0x80 (the stock Soft Focus passes at the stock weight 600) for Glow and 0x8000 (the Frame passes)
 * for Frame, in the Art Effect -> flag converter 0x60555e47 (test 2 showed both render on COLOR stills).
 * Stores: the slot bytes (editor), the job flag word in the converter's params block (as stock), own stack. */
.section .ext9,"ax"
xt_tab:                           /* Extras slices 1..9: slot byte, min, max (0 = no cell) */
 .byte 51,0,3                     /* 1 NR: 0 Camera, 1 Std, 2 Low, 3 Off (stored; applied in a later test) */
 .byte 49,-5,5                    /* 2 Glow (-) / Clarity (+) */
 .byte 26,-5,5                    /* 3 WB A-B */
 .byte 27,-5,5                    /* 4 WB G-M */
 .byte 50,0,5                     /* 5 Art Effect: 0 Off, 1 Star Light, 2 Pin Hole, 3 -, 4 White Edge, 5 Frame (Caduceus ids) */
 .byte 47,-5,5                    /* 6 Blacks */
 .byte 48,-5,5                    /* 7 Whites */
 .byte 52,0,1                     /* 8 VigFix: 0 Camera (Shading Comp. as set), 1 Off (v0.21) */
 .byte 53,0,3                     /* 9 Grain: 0 off, 1 Low, 2 Medium, 3 High (v0.21) */

/* ------------------------------------------------------------------ v0.20 test 5: code block from the card
 * The Extras effects run from a code block at the end of GUIDES.BIN (built with this firmware; tag XTAG), loaded
 * with the guide pictures at the half-press load, relocated in its heap buffer by its own entry 0, and published at
 * P+XPTR (0 = none). Every hook below goes stock when there is no block. Stubs that run inside section-2 code live in
 * the section-2 tail (always loaded there). Block entries: +0 relocate, +8 capture flags, +16 live-view flags,
 * +24 Soft Focus weight, +32 stills NR read. Stores here: P+XPTR (x_load, gd_load) only. */
.section .hook_fx,"ax"
 jmp s_cap                        /* stock 0x60555e50: movbu (a1),d0; cmp 0,d0; blt 0x60555ebc */
 nop

/* 0x6046b8bb..0x6046b8d7 (record -> development request, Art Effect gate): the same checks in fewer bytes, plus
 * COLOR (picture mode 11) -> s_lv. Stock: (8,sp) = d2 here (record+234 == 1), record+644 = (396,a3). */
.section .hook_lv,"ax"
 cmp 1,d2
 beq lv_x                         /* 0x6046b8ee: bra 0x6046b94f (no Art Effect) */
 movbu (396,a3),d0
 cmp 1,d0
 beq lv_x
 movbu (a0),d0                    /* picture mode (record+250) */
 cmp 11,d0
 bne 1f
 jmp s_lv
1:
 cmp 100,d0
 blt lv_x
 nop
 nop                              /* -> 0x6046b8d8: movbu (4,a3),d0 (the Art Effect switch) */

.section .hook_wt,"ax"
 jmp s_wt                         /* stock 0x605048c1: mov (48,a0),a1; mov 600,d0 */
 nop

.section .hook_nr1,"ax"
 call s_nr,[d2,d3],12             /* stock 0x603c8038: call getter (0x9719 stills Noise Filter) */
.section .hook_cl,"ax"
 call s_cl,[d2,a2],12

.section .hook_nr2,"ax"
 call s_nr,[d2,d3],12             /* stock 0x603e7891 (capture +37674) */

.section .ext2,"ax"
/* xp: `call xp,[],0` -> a1 = the code block (relocated) or 0. Uses d0; returns through MDR. */
xp:                               /* also Z = (a1 == 0) for the ext2 stubs (v0.21) */
 movhu (STATE),d0
 add -1,d0
 mov 0,a1
 btst 3,d0
 bne 1f
 mov d0,a1
 add POOL,a1
 mov (XPTR,a1),a1
1:
 cmp 0,a1
 retf [],0

s_lv:                             /* d0 = 11, a2 = request, a3 = record+248; d3 live */
 call xp,[],0
 beq 9f
 add 16,a1
 jmp (a1)
9:
 jmp lv_skip                      /* 0x6046b94f */

s_nr:                             /* the site's `call ...,[d2,d3],12` frame; d0 key, d1, a0 as for the getter */
 mov d0,d3
 call xp,[],0
 mov d3,d0                        /* (mov keeps Z) */
 beq 9f
 add 32,a1
 jmp (a1)
9:
 jmp getter

s_cl:                             /* v0.21 grain: request configuration 0x604955f1 `call s_cl,[d2,a2],12`, a0 = context.
                                     Code block +64 marks a plain COLOR still for the camera's grain, then the selector */
 call xp,[],0
 beq 9f
 add 64,a1
 jmp (a1)
9:
 jmp SEL                          /* 0x6052cf39, in the same frame as the stock call */

.section .ext5,"ax"
s_wt:                             /* leaf: MDR = return, a0 = combiner context; keep a0 for the stock getter */
 mov (48,a0),a1
 cmp 11,a1                        /* job key 11: COLOR */
 bne 9f
 mov mdr,d1
 call xp,[],0
 mov d1,mdr
 cmp 0,a1
 beq 9f
 add 24,a1
 jmp (a1)
9:
 mov (48,a0),a1
 mov 600,d0
 jmp wt_back                      /* 0x605048c7: cmp 0x01010065,a1 */

.section .ext3,"ax"
g_sf:                             /* grain: the Soft Focus blend setup (work-list word 0x604b9288), `calls` */
 add -4,sp
 call xp,[],0
 add 4,sp
 cmp 0,a1
 beq 9f
 add 56,a1
 jmp (a1)
9:
 jmp 0x604be2aa

.section .ext8,"ax"
s_cap:                            /* a3 = capture, a2 = params+12 (flags), (-4,a2) = key */
 call xp,[],0
 cmp 0,a1
 beq 9f
 add 8,a1
 jmp (a1)
9:
 mov 38225,a1                     /* as stock 0x60555e4b */
 add a3,a1
 movbu (a1),d0
 jmp fx_back

.section .ext6,"ax"
/* x_load: `call x_load,[d2,d3],12` from gd_load after the pictures are published, a2 = P. Block at the end of the
 * file: ... code, relocations, {tag, end - code, code length, count}. */
x_load:
 mov (GPTR,a2),a0
 mov (4,a0),d0
 add d0,a0                        /* end */
 mov (-16,a0),d0
x_tagref:
 cmp XTAG,d0
 bne 9f
 mov (-12,a0),d0
 sub d0,a0                        /* code */
 calls (a0)                       /* relocate in place -> d0 = code */
 mov d0,(XPTR,a2)
9:
 ret [d2,d3],12


/* ================================================================== GX2 space test (not a release)
 * Section 6's load end is raised by 64 KB (0x60f49800 -> 0x60f59800, build.py; GX1 proved 4 KB on the camera), so the loader copies the area below
 * from the update file into RAM. It holds a header, the probe and a known pattern. At every half-press (after the
 * settings load), gx_go calls the probe when the header is there, then goes on to ed_trig as before.
 * The probe (same task / media gate as the saves): 1. checks the pattern word by word (did the loader copy it, is it
 * still intact); 2. sums one never-loaded gap per half-press, round robin over 8 (sections 2-9's FF gaps; the first
 * round is the baseline, later rounds count changes: anything writing there would show); 3. writes the results to
 * OM3MOD/GAPTEST.BIN. Read-only on the gaps. */
.section .ext8,"ax"
gx_go:                            /* call gx_go,[d2,d3,a2,a3],36 from pr_hook, in place of ed_trig */
 mov (gx_hdr),d0
 cmp 0x32545847,d0                /* 'GXT2': the extension was loaded */
 bne 1f
 call gx_probe,[d2,d3,a2,a3],40
1:
 jmp ed_trig

.section .gx,"ax"
gx_hdr:
 .long 0x32545847, 0x10000, 0, 0
gx_probe:                         /* frame 40: (0) call slot, (4) handle, (12) tid */
 mov (SECBITS),d0
 and 0x3ff,d0
 cmp 0x3ff,d0
 bne gx_out
 mov sp,a0
 add 12,a0
 call get_tid,[a2],4
 cmp 0,d0
 bne gx_out
 movhu (HLS_TID),d1
 cmp 0,d1
 beq gx_out
 btst 0x8000,d1
 bne gx_out
 movhu (12,sp),d0
 cmp d1,d0
 bne gx_out
 mov 61440,d1
 mov (MS_A),d0
 cmp d1,d0
 beq 1f
 mov (MS_B),d0
 cmp d1,d0
 beq 1f
 mov (MS_C),d0
 cmp d1,d0
 bne gx_out
1:
 mov (gx_pass),d2                 /* pass number 1, 2, ... */
 inc d2
 mov d2,(gx_pass)
 /* 1. the pattern: word i = (i + (i << 16)) ^ 0x5a3c96e1 */
 mov gx_pat,a0
 clr d3
 clr d1
 mov d1,(gx_bad)
2:
 mov d3,d0
 asl 16,d0
 add d3,d0
 xor 0x5a3c96e1,d0
 mov (a0),d1
 cmp d0,d1
 beq 3f
 mov (gx_bad),d1
 inc d1
 mov d1,(gx_bad)
3:
 inc4 a0
 inc d3
 cmp GX_NPAT,d3
 bne 2b
 /* 2. one gap: r = (pass - 1) & 7, round = (pass - 1) >> 3 */
 mov d2,d3
 add -1,d3
 and 7,d3
 mov d3,d0
 asl 3,d0
 mov gx_rg,a0
 add d0,a0
 mov (4,a0),a1                    /* end */
 mov (a0),a0                      /* start */
 clr d0
4:
 mov (a0),d1
 add d1,d0
 inc4 a0
 cmp a1,a0
 bcs 4b
 mov d3,d1
 asl2 d1
 mov gx_last,a0
 add d1,a0
 mov d0,(a0)                      /* this round's sum */
 mov d2,d1
 add -1,d1
 lsr 3,d1
 cmp 0,d1
 bne 5f
 mov gx_base - gx_last,d1         /* first round: the baseline */
 add d1,a0
 mov d0,(a0)
 bra 6f
5:
 mov gx_base - gx_last,d1
 add d1,a0
 mov (a0),d1
 cmp d0,d1
 beq 6f
 mov gx_chg - gx_base,d1          /* changed since the baseline */
 add d1,a0
 mov (a0),d1
 inc d1
 mov d1,(a0)
6:
 /* 3. the results file */
 mov gx_path,a0
 mov gx_mode,a1
 call fopen,[],4
 cmp 0,a0
 beq gx_out
 mov a0,(4,sp)
 mov (4,sp),a1
 mov gx_res_end - gx_res,d1
 mov 1,d0
 mov gx_res,a0
 call fwrite,[d2,d3,a2,a3],24
 mov (4,sp),a0
 call fclose,[d2,a2,a3],16
gx_out:
 ret [d2,d3,a2,a3],40
 .balign 4
gx_rg:                            /* the never-loaded gaps (section 6's starts after this extension) */
 .long 0x60718800, 0x6075a800, 0x60820000, 0x60828000, 0x60a8f800, 0x60ad8000, 0x60adb800, 0x60adc000
 .long 0x60f59800, 0x6103f000, 0x6164b000, 0x6169e800, 0x617e4800, 0x61809000, 0x619a9800, 0x619fd000
gx_res:                           /* GAPTEST.BIN: 'GXR2', passes, bad pattern words (last pass), pattern words */
 .long 0x32525847                 /* 'GXR2' */
gx_pass:
 .long 0
gx_bad:
 .long 0
 .long GX_NPAT
gx_base:
 .space 32
gx_last:
 .space 32
gx_chg:
 .space 32
gx_res_end:
gx_path:
 .asciz "C:\\OM3MOD\\GAPTEST.BIN"
gx_mode:
 .asciz "w"
 .balign 16
gx_pat:                           /* filled by build.py up to 0x60f59800 */
 .set GX_NPAT, (0x10000 - (gx_pat - gx_hdr)) / 4
