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
 cmp 4,d3
 bcc \miss
 .endm

/* after WHERE: a2 = the cell's address - 32 (read with (32,a2)); WB page: only Yellow (A-B, +26) and Green (G-M, +27),
 * any other slice -> \none. Uses d2, d3, a2. */
 .macro CELL none
 cmp 3,d3                         /* Looks page: every slice reads 0 (the readout shows the look number) */
 beq \none
 cmp 2,d3
 bne 71f
 mov d2,d3
 and 63,d3
 and 0xc0,d2
 add d2,a2
 cmp 0,d3                         /* WB page: 12 o'clock A-B, 6 G-M, 3 Blacks, 9 Whites */
 bne 72f
 add 26,a2
 bra 74f
72:
 cmp 6,d3
 bne 73f
 add 27,a2
 bra 74f
73:
 cmp 3,d3
 bne 75f
 add 47,a2
 bra 74f
75:
 cmp 9,d3
 bne \none
 add 48,a2
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
 call ed_trig,[d2,d3,a2,a3],36    /* editor: save the edits to the card when dirty */
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
 PVAL t_out
 mov (EMARK,a2),d0
 cmp EMAGIC,d0
 bne t_out
 clr d0
 movbu d0,(AXIS,a2)               /* leaving for the shutter: other screens read Saturation again */
 call gd_set,[d2,a2],8            /* d0 = 0: stock guide picture */
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
 movbu (AXIS,a2),d3               /* only on the Hue / Light / WB / Looks pages: else stock, id unchanged */
 cmp 4,d3
 beq g_look
 add -1,d3
 cmp 4,d3
 bcc g_miss
 movbu (EDK,a2),d3                /* -> sector id 928 + 12k + slice of the open editor */
 cmp 4,d3
 bcc g_miss
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
g_look:                           /* Looks page readout: the open profile's look number 0..n */
 movbu (EDK,a2),d3
 cmp 4,d3
 bcc g_miss
 add d3,a2
 movbu (LIDX,a2),d0
 bra g_put
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
 beq s_bad                        /* Looks page: steps go through lk_up / lk_down, never here */
 cmp 2,d3
 beq s_wb
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
s_dirty:
 mov d0,d2                        /* a hand edit: this profile's look number back to 0 ("My own" = what is there now) */
 exthu d2
 add -928,d2
 mov LIDX,d3
1:
 cmp 12,d2
 bcs 2f
 add -12,d2
 inc d3
 bra 1b
2:
 clr d2
 movbu d2,(d3,a2)
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
s_wb:                             /* WB page: 12 o'clock -> wb_ab (+26), 6 o'clock -> wb_gm (+27),
                                   * 3 o'clock -> Blacks (+47), 9 o'clock -> Whites (+48); others refused */
 mov d2,d3
 and 63,d3
 and 0xc0,d2
 add 58,d2                        /* 64*slot + 32 + 26 */
 cmp 0,d3
 beq 5f
 cmp 6,d3
 beq 6f
 add 21,d2                        /* 64*slot + 32 + 47 */
 cmp 3,d3
 beq 7f
 inc d2                           /* +48 */
 cmp 9,d3
 bne s_bad
7:
 movbu d1,(d2,a2)                 /* Blacks / Whites: the value, no WB flag */
 bra s_dirty
6:
 inc d2
5:
 movbu d1,(d2,a2)                 /* the value first ... */
 and 0xc0,d2
 add 57,d2                        /* wb_flags (+25): bit0 on, bit7 off */
 movbu (d2,a2),d1
 or 1,d1
 and 0x7f,d1
 movbu d1,(d2,a2)
 bra s_dirty
s_bad:
 clr d0
 ret [d2,d3,a2,a3],68
s_stock:
 jmp manager

/* ed_init <- COLOR1-4 editor records +4 (stock 0x6122393a, CALLS, a0 parent): a new editor starts on Saturation. */
ed_init:
 movm [d3,a2],(sp)
 PVAL i_out
 mov (EMARK,a2),d3
 cmp EMAGIC,d3
 bne i_out
 clr d3
 movbu d3,(AXIS,a2)
 add -20,sp
 mov d0,(4,sp)
 mov d1,(8,sp)
 mov a0,(12,sp)
 mov a1,(16,sp)
 clr d0
 call gd_set,[d2,a2],8
 mov (4,sp),d0
 mov (8,sp),d1
 mov (12,sp),a0
 mov (16,sp),a1
 add 20,sp
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
 movbu (26,a1),d0                 /* A-B */
 cmp 34041,d2
 beq 2f
 movbu (27,a1),d0                 /* G-M */
 cmp 38521,d2
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
 call lk_load,[d2,d3,a2,a3],28    /* look library from C:\OM3MOD\LOOKS.BIN (optional, test 14) */
 bra sd_out                       /* block kept for the rest of the power-on */
sd_free:
 mov a2,a0
 call free,[],4
sd_out:
 ret [d2,d3,a2,a3],36

sd_def:                           /* a2 = block: copy FILE_LEN bytes of built-in defaults */
 mov sd_default,a0
 clr d2
sd_d1:
 movbu (d2,a0),d0
 movbu d0,(d2,a2)
 inc d2
 cmp FILE_LEN,d2
 bne sd_d1
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
 .include "data4.inc"            /* sd_hdr (32), sd_lo (64), sd_span (64), sd_default (544) */
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
 call k_cur,[a2],8                  /* d0 = 0 ok, (16,sp) = cursor value */
 cmp 0,d0
 bne f_no
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
 call k_cur,[a2],8
 cmp 0,d0
 bne 7f
 mov (16,sp),d0
 cmp 255,d0
 bne k_step
7:
 mov d2,d0                        /* stock left ALL on (or no value): its result, no page change */
 ret [d2,d3,a2,a3],40
k_step:
 mov (20,sp),a2
 movbu (AXIS,a2),d0               /* S -> H -> L -> WB/BW -> (Looks, when LOOKS.BIN loaded) -> S */
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
 bne 10f
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
f_no:
 mov a3,a0
 mov 0x9014,d0
 mov (4,sp),d1
 mov (8,sp),a1
 add 24,sp
 movm (sp),[d2,d3,a2,a3]
 jmp stock_info

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
 cmp GSTOCK_P,d1
 beq 1f
 cmp 0,a1
 beq 9f                           /* someone else's payload: leave it */
 mov a1,d2
 sub d2,d1                        /* payload - G */
 cmp 24576,d1
 bcc 9f
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
 mov 28,d1                        /* hue[12], light[12], +24 grain, +25 wb_flags, +26 A-B, +27 G-M */
2:
 movbu d0,(a0)
 inc a0
 add -1,d1
 bne 2b
 movbu d0,(a0)                    /* +28 effect id, +29 glow strength */
 movbu d0,(1,a0)
 movbu d0,(19,a0)                 /* +47 Blacks, +48 Whites (a0 = entry + 28) */
 movbu d0,(20,a0)
 mov (12,sp),d1                   /* look number 0 */
 add -2197,d1
 mov a2,a0
 add d1,a0
 movbu d0,(LIDX,a0)
 mov 1,d0
 movbu d0,(DIRTY,a2)              /* saved to the card on the next half-press */
 cmp 0,d2
 beq 4f                           /* on Saturation the stock reset already redrew */
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
 clr d3
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
 call ed_isdef,[d2,d3,a2],24
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
 * They drive the '*' after COLOR n / the look name and the "Reset [OK hold]" guide. Stock first; a COLOR1-4 sector
 * id that stock calls default is reported changed when its Hue or Light is non-zero, or when the profile's WB shift is
 * on and non-zero. Reads only. */
ed_isdef:
 mov d0,d2
 PVAL 85f
 movbu (AXIS,a2),d3               /* stock compare on Saturation, whatever page is open ... */
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
 movbu (29,a0),d3                 /* Glow strength */
 cmp 0,d3
 bne 7f
 movbu (47,a0),d3                 /* Blacks / Whites */
 cmp 0,d3
 bne 7f
 movbu (48,a0),d3
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

gd_path:
 .asciz "C:\\OM3MOD\\GUIDES.BIN"
gd_mode:
 .asciz "r"
ext10_end:

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
 mov (8,a1),d0                    /* key 11 (COLOR) <=> word 0x000b0000 */
 cmp 0xb0000,d0
 bne t9
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
 * lk_up / lk_down <- COLOR1-4 editor records +12 / +16 (stock Up 0x61223ef7 / Down 0x612241b6: main-dial steps;
 * CALLS, d1 arg, a0 parent; neither reads d0 or a1). On the Looks page (axis 4, P valid, marker, looks loaded): one
 * look forward / back with wrap 0..n, the slot rewritten, dirty, children re-read and the cursor poked (as ed_event),
 * -> d0 1. Anything else: every register as at entry, jmp stock. Locals as ed_event: (4) d1, (8) a1, (12) cursor id,
 * (16) cursor value, (20) P, (24) d0. Stores: the heap block P, own frame. */
.section .ext3,"ax"
lk_up:
 movm [d2,d3,a2,a3],(sp)
 add -28,sp
 mov 1,d2
 bra lk_go
lk_down:
 movm [d2,d3,a2,a3],(sp)
 add -28,sp
 mov -1,d2
lk_go:
 mov d0,(24,sp)
 mov d1,(4,sp)
 mov a1,(8,sp)
 mov a0,a3
 cmp 0,a3
 beq l_no
 movhu (96,a3),d0                 /* editor key 0x1540..0x1543 = COLOR1..4 */
 add -0x1540,d0
 cmp 4,d0
 bcc l_no
 add 2197,d0
 mov d0,(12,sp)                   /* cursor setting id */
 PVAL l_no
 mov (EMARK,a2),d0
 cmp EMAGIC,d0
 bne l_no
 movbu (AXIS,a2),d0
 cmp 4,d0
 bne l_no
 mov (LPTR,a2),a1
 cmp 0,a1
 beq l_no
 mov a2,(20,sp)
 movhu (14,a1),d1                 /* n */
 mov (12,sp),d0
 add -2197,d0                     /* k */
 mov a2,a0
 add d0,a0
 movbu (LIDX,a0),d3               /* old */
 add d3,d2                        /* new = old +- 1, wrapping 0..n */
 cmp 0,d2
 bge 1f
 mov d1,d2
1:
 cmp d1,d2
 ble 2f
 clr d2
2:
 movbu d2,(LIDX,a0)
 mov d0,d1
 asl 6,d1                         /* 64k */
 cmp 0,d3
 bne 3f
 mov a2,a0                        /* leaving "My own": keep the slot entry */
 add d1,a0
 add 32,a0
 mov a2,a1
 add d1,a1
 add BKUP,a1
 mov 64,d3
5:
 movbu (a0),d0
 movbu d0,(a1)
 inc a0
 inc a1
 add -1,d3
 bne 5b
3:
 mov a2,a0
 add d1,a0
 add 32,a0                        /* a0 = slot entry */
 cmp 0,d2
 bne 4f
 mov a2,a1                        /* back to "My own": the kept entry */
 add d1,a1
 add BKUP,a1
 mov 64,d3
6:
 movbu (a1),d0
 movbu d0,(a0)
 inc a0
 inc a1
 add -1,d3
 bne 6b
 bra 8f
4:
 mov (LPTR,a2),a1                 /* look new-1 */
 mov d2,d0
 add -1,d0
 asl 5,d0
 add 32,d0
 add d0,a1
 mov 24,d3                        /* hue[12], light[12] */
7:
 movbu (a1),d0
 movbu d0,(a0)
 inc a0
 inc a1
 add -1,d3
 bne 7b
 movbu (a1),d0                    /* a0 = entry + 24, a1 = look + 24 */
 movbu d0,(1,a0)                  /* +25 wb flags: 1 on / 0 off */
 movbu (1,a1),d0
 movbu d0,(2,a0)                  /* +26 A-B */
 movbu (2,a1),d0
 movbu d0,(3,a0)                  /* +27 G-M */
 movbu (3,a1),d0
 movbu d0,(23,a0)                 /* +47 Blacks */
 movbu (4,a1),d0
 movbu d0,(24,a0)                 /* +48 Whites */
 movbu (7,a0),d0
 or 2,d0
 movbu d0,(7,a0)                  /* +31 flags: H/L on */
8:
 mov 1,d0
 movbu d0,(DIRTY,a2)              /* saved to the card on the next half-press */
 mov 128,d2                       /* children 1..12 re-read, cursor poked: the screen rebuilds */
9:
 mov a3,a0
 add d2,a0
 mov (a0),a0
 cmp 0,a0
 beq 10f
 call refresh,[d2,d3,a2,a3],68
 add 4,d2
 cmp 176,d2
 bne 9b
 call k_cur,[a2],8
 cmp 0,d0
 bne 10f
 call facade,[],4
 mov (a0),a2
 mov (4,a2),a2
 mov (16,sp),a1
 clr d1
 mov (12,sp),d0
 calls (a2)
10:
 mov 1,d0
 ret [d2,d3,a2,a3],44
l_no:
 mov stock_up,a1
 cmp 1,d2
 beq 1f
 mov stock_down,a1
1:
 mov a3,a0
 mov (24,sp),d0
 mov (4,sp),d1
 add 28,sp
 movm (sp),[d2,d3,a2,a3]
 jmp (a1)

/* lk_load: `call lk_load,[d2,d3,a2,a3],28` from sd_load after gd_load, a2 = P. Locals (4) handle, (8) buffer.
 * 80..800 B, read whole, lk_check -> P+LPTR (published last). Stores: P+LPTR, the heap buffer, own frame. */
.section .ext8,"ax"
lk_load:
 mov lk_path,a0
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
 mov d0,d3                        /* n bytes */
 cmp 80,d3
 bcs 8f
 cmp 801,d3
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
 call lk_check,[d2,d3,a2,a3],16
 cmp 0,d0
 bne 7f
 mov (8,sp),d0
 mov d0,(LPTR,a2)                 /* published last */
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
lk_path:
 .asciz "C:\\OM3MOD\\LOOKS.BIN"
 .balign 2

/* lk_check: `call lk_check,[d2,d3,a2,a3],16`, a0 = buffer, d3 = size -> d0 0 ok / 1 bad. Reads only. */
.section .ext4,"ax"
lk_check:
 mov a0,a3
 mov (a3),d0
 cmp LKMAGIC,d0
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
 movhu (14,a3),d2                 /* n 1..16 */
 cmp 0,d2
 beq 9f
 cmp 17,d2
 bcc 9f
 mov d2,d0
 asl 4,d0
 mov d0,d1
 add d1,d0
 add d1,d0
 add 32,d0                        /* 32 + 48n */
 cmp d3,d0
 bne 9f
 mov d2,d1
 asl 5,d1                         /* 32n look bytes, per-byte ranges */
 mov a3,a0
 add 32,a0
 mov lk_lo,a1
 clr d2
1:
 movbu (a0),d0
 extb d0
 movbu (a1),d3
 extb d3
 sub d3,d0
 movbu (32,a1),d3
 cmp d3,d0
 bhi 9f
 inc a0
 inc a1
 inc d2
 cmp 32,d2
 bne 2f
 clr d2
 mov lk_lo,a1
2:
 add -1,d1
 bne 1b
 clr d0
 ret [d2,d3,a2,a3],16
9:
 mov 1,d0
 ret [d2,d3,a2,a3],16
lk_lo:                            /* look byte i: lo, then span (value - lo <= span, unsigned) */
 .byte -5,-5,-5,-5,-5,-5,-5,-5,-5,-5,-5,-5, -5,-5,-5,-5,-5,-5,-5,-5,-5,-5,-5,-5, 0, -5,-5,-5,-5, 0,0,0
 .byte 10,10,10,10,10,10,10,10,10,10,10,10, 10,10,10,10,10,10,10,10,10,10,10,10, 1, 10,10,10,10, 0,0,0

/* ------------------------------------------------------------------ section-9 tail: readout number tables
 * The Color Profile readout (display types 5397/1011/5399) maps the value through two (value, x) tables of 11 entries
 * (-5..5): sign class (3 -, 1 zero, 2 +) at 0x6154caa0 and magnitude at 0x6154caf8. Build time: both lookups point at
 * these copies extended to -5..16 (22 entries), so the Looks page can show look numbers up to 16. Same entries for
 * -5..5. Read only. */
.section .ext9,"ax"
 .balign 4
rd_sign:
 .irp v,-5,-4,-3,-2,-1
 .long \v, 3
 .endr
 .long 0, 1
 .irp v,1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16
 .long \v, 2
 .endr
rd_mag:
 .irp v,5,4,3,2,1
 .long -\v, \v
 .endr
 .irp v,0,1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16
 .long \v, \v
 .endr
