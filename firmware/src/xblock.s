/* Caduceus for OM-3 v0.20 test 5: the Extras code block (appended to GUIDES.BIN, our own code).
 *
 * Runs from its heap buffer (uncached pool, as the camera's malloc returns), relocated in place by entry 0. Linked at
 * XB_LINK; the build links it twice and lists every 32-bit field that moves (absolute: + delta, PC-relative to the
 * firmware: - delta). Entries are 8 bytes apart and reached from the firmware stubs with every register as the stub
 * documents. Slot entry S = P + 32 + 64k of the effective COLOR profile k+1: +49 Glow (-1..-5) / Clarity (+1..+5),
 * +50 Art Effect id (Caduceus: 1 Star Light, 2 Pin Hole, 4 White Edge, 5 Frame), +51 NR (1 Std, 2 Low, 3 Off), +52 VigFix (1: Shading Comp. reads Off).
 * Stores: the job flag word in the stock params / request (as the stock Art Effect code), own stack, the relocation
 * fields of this block (entry 0, once, before the block is published). No mul/div (MDR is the weight getter's return).
 */
 .am33_2
 .text
 .global _start
_start:
xb_base:
 jmp xb_reloc                     /* +0  relocate (called once by x_load: `calls`) */
 .balign 8
 jmp xb_cap                       /* +8  capture flags (s_cap) */
 .balign 8
 jmp xb_lv                        /* +16 live-view / movie request flags (s_lv) */
 .balign 8
 jmp xb_wt                        /* +24 Soft Focus weight (s_wt) */
 .balign 8
 jmp xb_nr                        /* +32 stills Noise Filter / Shading Comp. read (s_nr) */
 .balign 8
 jmp xb_kad                       /* +40 editor ALL state read (k_ad) */
 .balign 8
 jmp xb_vl                        /* +48 dial label of the Extras slice (vl_s) */
 .balign 8
 jmp xb_gs                        /* +56 grain: Soft Focus blend setup wrapper (g_sf) */
 .balign 8
xb_nrel:
 .long 0                          /* relocation count (written by the build) */

/* xb_slot: `call xb_slot,[d2,d3],12` -> a1 = slot entry S of the effective COLOR1..4 profile, or 0. Uses d0, d1, a0. */
xb_slot:
 mov 63153,d0
 clr d1
 mov 0,a0
 call getter,[d2,d3],12
 extbu d0
 add -1,d0
 cmp 4,d0
 bcc 9f
 mov d0,d2
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
 asl 6,d2
 add d2,a1
 add 32,a1
 ret [d2,d3],12
9:
 mov 0,a1
 ret [d2,d3],12

/* xb_art: d1 |= the job flags of S's Art Effect (a1 = S). Uses d0, a0; returns through MDR. */
xb_art:
 movbu (50,a1),d0
 cmp 6,d0
 bcc 1f
 add d0,d0
 mov xb_ft,a0
 movhu (d0,a0),d0
 or d0,d1
1:
 retf [],0

/* capture (Art Effect -> flag converter 0x60555e47): a3 = capture, a2 = params+12 (flags), (-4,a2) = key.
 * Exit as stock: fx_back with d0 = the Art Effect id and a1 = its address, or fx_tail. */
xb_cap:
 mov 38225,a1
 add a3,a1
 movbu (a1),d0
 cmp 0,d0
 bne 8f                           /* the camera's own Art Effect: stock */
 mov (-4,a2),d0
 cmp 0x000b0000,d0                /* key bytes 0, 0, halfword 11: COLOR */
 bne 7f
 call xb_slot,[d2,d3],12
 cmp 0,a1
 beq 7f
 mov (a2),d1
 movbu (49,a1),d0
 movbu (53,a1),a0
 cmp 0,a0
 bne 2f
 cmp 0,d0
 beq 1f
2:
 or 128,d1                        /* Glow / Clarity or Grain: the Soft Focus passes (the weight decides which) */
1:
 call xb_art,[],0
 mov d1,(a2)
 jmp fx_tail
7:
 clr d0
8:
 jmp fx_back

/* live view / movie (record -> development request 0x6046b86c, COLOR, the stock Art Effect gates passed):
 * a2 = request (+12 flags), a3 = record+248, d3 live. Glow only (Clarity is invisible on combiner 12, as Caduceus). */
xb_lv:
 call xb_slot,[d2,d3],12
 cmp 0,a1
 beq 9f
 mov (12,a2),d1
 movbu (49,a1),d0
 btst 0x80,d0
 beq 1f
 or 128,d1
1:
 call xb_art,[],0
 mov d1,(12,a2)
9:
 jmp lv_skip

/* Soft Focus weight (getter 0x605048c1, entered `call ...,[],0`): MDR = return (0x60504edb combiner 11, stills;
 * 0x60504f23 combiner 12), a0 = context, key 11 checked. d0 = w (Q10 weight of the sharp input); stock key 11: 600. */
xb_wt:
 mov mdr,d1
 add -8,sp
 mov d1,(4,sp)
 call xb_slot,[d2,d3],12
 mov 600,d0
 cmp 0,a1
 beq 8f
 movbu (49,a1),d1
 extb d1
 cmp 0,d1
 bne 1f
 movbu (53,a1),d1                 /* no Glow / Clarity: Grain alone -> w 1024, the sharp image unchanged */
 cmp 0,d1
 beq 8f
 mov 1024,d0
 bra 8f
1:
 blt 5f
 cmp 6,d1                         /* Clarity 1..5 */
 bcc 8f
 mov 1024,d0                      /* combiner 12 (live view classes): no negative gain */
 mov (4,sp),a0
 cmp c11_ret,a0
 bne 8f
 add -1,d1
 add d1,d1
 mov xb_cl,a0
 movhu (d1,a0),d0
 bra 8f
5:
 clr d0
 sub d1,d0                        /* Glow 1..5 */
 cmp 6,d0
 bcc 7f
 add -1,d0
 add d0,d0
 mov xb_gl,a0
 movhu (d0,a0),d0
 bra 8f
7:
 mov 600,d0
8:
 mov (4,sp),d1
 add 8,sp
 mov d1,mdr
 retf [],0

/* property reads (s_nr): the site's `call getter,[d2,d3],12` frame, d0 key, d1, a0 as for the getter. Key 0x9719
 * (stills Noise Filter; capture and Exif sites): NR 1..3 -> the real read, then d0 = 0 Standard / -1 Low / -2 Off.
 * Key 0x8c21 (Shading Comp., sid 61; capture and lens-request sites, v0.21): VigFix 1 -> the real read, then d0 = 0
 * (Off, a stock value). Otherwise the getter as stock. */
xb_nr:
 mov d1,d2
 mov a0,d3
 add -8,sp                        /* (0) call slot, (4) the key */
 mov d0,(4,sp)
 call xb_slot,[d2,d3],12
 mov (4,sp),d1                    /* d1 = key */
 add 8,sp
 cmp 0,a1
 beq 9f
 cmp 38681,d1
 bne 5f
 movbu (51,a1),d0                 /* NR 1..3 */
 add -1,d0
 cmp 3,d0
 bcc 9f
 mov xb_nm,a1
 movbu (d0,a1),d0
 extb d0
 bra 6f
5:
 movbu (52,a1),d0                 /* v0.21 VigFix 1: Shading Comp. reads 0 (Off) */
 cmp 1,d0
 bne 9f
 clr d0
6:
 mov d1,a1                        /* key */
 mov d2,d1
 mov d3,a0
 mov d0,d2                        /* the value to return */
 mov a1,d0
 call getter,[d2,d3],12
 mov d2,d0
 ret [d2,d3],12
9:
 mov d1,d0
 mov d2,d1
 mov d3,a0
 jmp getter

/* editor ALL state (k_ad, `call k_ad,[a2],8` frame, a stub jump): (24,sp) <- GetValue(2201 + k), and when that is not
 * 255, GetValue(2197 + k); (20,sp) = 2197 + k. As k_cur: keeps d2/d3/a3, returns through the frame. */
xb_kad:
 call facade,[],4
 mov (a0),a2
 mov (12,a2),a2
 mov sp,a1
 add 24,a1
 clr d0
 mov d0,(a1)
 mov (20,sp),d0
 add 4,d0
 calls (a2)
 mov (24,sp),d0
 cmp 255,d0
 beq 9f
 call facade,[],4
 mov (a0),a2
 mov (12,a2),a2
 mov sp,a1
 add 24,a1
 mov (20,sp),d0
 calls (a2)
9:
 ret [a2],8

/* ---- grain (v0.21 grain test 3; diagnostics gd1-gd4 measured on the camera, see om3/NOTES.md). The Soft Focus blend setup 0x604be2aa returns with its output, the new
 * buffer 0x1000 (YCbYCr 4:2:2, Y in the even bytes, 2 B/px, rows memHw x 2 B apart), complete in memory (camera
 * probe g2: a pattern written there after the setup is in the JPEG). On a COLOR1-4 still whose look has Grain 1..5
 * (slot +53), every Y byte becomes T[Y][h]: h a 31-level noise row (xb_p1: xorshift32, triangular, vertical IIR,
 * horizontal pair), T = clamp(Y + (((64 h - 945) G[Y] S + 2^17) >> 18)) with G midtone-weighted and S from xb_gstab.
 * The image is reached through this CPU's bus window, one row at a time under the firmware's lock (xb_open), and
 * the cache is flushed at the end. Work buffers: T (8192 B) and V + H (one row each), freed again.
 * grain/model.py is the same computation in Python. Stores: the image's Y bytes, the work buffer, xb_seed. */
xb_p:                             /* leaf: a1 = P or 0. Uses d0 */
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
 retf [],0
9:
 mov 0,a1
 retf [],0

xb_open:                          /* `call xb_open,[d2,d3,a2,a3],28`, d0 = bus address, d1 = length -> a0 = CPU address or 0,
                                     d0 = lock token (the lock is held: close it with xb_close), d1 = 1 window / 0.
                                     Bus 0xa0000000..0xb7ffffff is the DRAM the CPU sees uncached at the same address;
                                     anything else from 0x08000000 goes through this CPU's bus window (the firmware's
                                     own mapper, under the firmware's lock: no task switch, interrupts masked) when the
                                     d1 bytes stay inside the window's 128 MB. */
 mov d0,a3
 mov d1,d3
 clr d0
 call LOCK,[d2],8
 mov d0,a2                        /* token */
 clr d2
 mov a3,d0
 cmp 0x08000000,d0
 bcs 7f
 cmp 0xa0000000,d0
 bcs 3f
 cmp 0xb8000000,d0
 bcc 3f
 mov a3,a0                        /* main DRAM: direct */
 bra 8f
3:
 and 0x07ffffff,d0
 add d3,d0
 cmp 0x08000001,d0
 bcc 7f
 mov (0x8050),d1                  /* this CPU's window register: 0x98100058 + 0x400 cpu (cpu 3: + 0x1000) */
 mov 0x98100058,a0
 cmp 0,d1
 beq 4f
 add 0x400,a0
 cmp 1,d1
 beq 4f
 add 0x400,a0
 cmp 2,d1
 beq 4f
 add 0x800,a0
4:
 mov (a0),d1
 lsr 24,d1
 mov a3,d0
 lsr 27,d0
 cmp d0,d1
 bne 5f
 mov a3,d0                        /* already ours (and nothing else runs here while the lock is held) */
 and 0x07ffffff,d0
 or 0xb8000000,d0
 mov d0,a0
 mov 1,d2
 bra 8f
5:
 mov a3,a0
 call WINMAP,[d2,d3,a2,a3],28
 mov 1,d2
 bra 8f
7:
 mov 0,a0
8:
 mov a2,d0
 mov d2,d1
 ret [d2,d3,a2,a3],28

xb_close:                         /* `call xb_close,[d2],8`, d0 = token */
 call UNLOCK,[d2],8
 ret [d2],8

xb_rec:                           /* `call xb_rec,[d2,d3],12`, a0 = job -> a1 = record of buffer 0x1000, or 0 */
 mov a0,d3
 mov 4096,d0
 call BUFIDX,[d2,d3],8
 exthu d0
 cmp 48,d0
 bcc 9f
 mov d0,d1
 asl 3,d1                         /* 8 i */
 mov d1,d2
 asl 2,d2                         /* 32 i */
 add d2,d1                        /* 40 i */
 asl 1,d2                         /* 64 i */
 add d2,d1                        /* 104 i */
 mov d3,a0
 mov (10276,a0),a1
 add d1,a1
 ret [d2,d3],12
9:
 mov 0,a1
 ret [d2,d3],12


 .set P_DIRTY, 685
 .set P_LPTR, 708
 .set USCLK, 0x98900284           /* TEST: the microsecond free-run counter (timer channel 33) */
xb_gs:                            /* `calls` (0,sp) = return, a0 = job */
 movm [d2,d3,a2,a3],(sp)
 add -16,sp                       /* (0) call slot, (4) job, (8) level, (12) result */
 mov a0,(4,sp)
 call xb_slot,[d2,d3],12
 cmp 0,a1
 beq 90f
 movbu (53,a1),d0
 add -1,d0
 cmp 5,d0
 bcs 10f
90:                               /* no grain: the stock setup, as if called directly */
 mov (4,sp),a0
 add 16,sp
 movm (sp),[d2,d3,a2,a3]
 jmp SF_ENT
10:
 inc d0
 mov d0,(8,sp)
 mov (4,sp),a0
 mov SF_ENT,a1
 calls (a1)
 mov d0,(12,sp)
 cmp 0,d0
 bne 20f
 mov (4,sp),a0
 call xb_rec,[d2,d3],12
 cmp 0,a1
 beq 20f
 mov a1,a0
 mov (8,sp),d0
 call xb_grain,[d2,d3,a2,a3],128
20:
 mov (12,sp),d0
 ret [d2,d3,a2,a3],32

/* xb_grain: `call xb_grain,[d2,d3,a2,a3],128` (112 B of locals), a0 = buffer record, d0 = level 1..5. The heavy
 * loops (xb_p1s, xb_p2s) run from the cached alias of this block (heap memory is uncached) on work buffers used
 * through their cached alias; image rows go through the bus window's cached view and are written back (FLUSH)
 * before the lock is released. K rows share one lock and one FLUSH (TEST gr4: K = 1 on odd levels, 2 on even).
 * Locals: (0) call slot, (4) rec, (8) S, (12) T (malloc), (16) row, (20) bus, (24) pitch, (28) words, (32) groups,
 * (36) V + 2 H (malloc), (40) token, (44) Hw, (48) Vw, (52) cached rows, (56) start time, (60) level, (92) K,
 * (96) rows this pass, (100) H0, (104) H1; loop parameters (64) V, (68) H, (72) groups, (76) r, (80) row, (84) words,
 * (88) T. */
xb_grain:
 mov a0,(4,sp)
 mov d0,(60,sp)
 mov (USCLK),d1                   /* TEST: time */
 mov d1,(56,sp)
 mov 1,d1                         /* TEST: K */
 btst 1,d0
 bne 1f
 mov 2,d1
1:
 mov d1,(92,sp)
 add -1,d0
 add d0,d0
 mov xb_gstab,a1
 movhu (d0,a1),d0
 mov d0,(8,sp)                    /* S */
 movhu (16,a0),d0                 /* format 0x0c02 only */
 cmp 0x0c02,d0
 bne 99f
 mov (4,a0),d0                    /* 32-bit bus address */
 cmp 0,d0
 bne 99f
 movhu (20,a0),d0                 /* Hw: 4 .. 8192, a multiple of 4 */
 mov d0,(44,sp)
 cmp 4,d0
 bcs 99f
 cmp 8193,d0
 bcc 99f
 btst 3,d0
 bne 99f
 movhu (18,a0),d1                 /* memHw >= Hw */
 cmp d0,d1
 bcs 99f
 add d1,d1
 mov d1,(24,sp)
 movhu (22,a0),d1
 mov d1,(48,sp)
 cmp 0,d1
 beq 99f
 mov d0,d1
 lsr 1,d1
 mov d1,(28,sp)
 mov d1,(84,sp)
 lsr 1,d1
 mov d1,(32,sp)
 mov d1,(72,sp)
 mov (a0),d1
 mov d1,(20,sp)
 mov d0,d1                        /* V and two H rows */
 add d0,d0
 add d1,d0
 call malloc,[],4
 cmp 0,a0
 beq 99f
 mov a0,(36,sp)
 mov 8192,d0                      /* T: 256 Y x 32 h */
 call malloc,[],4
 cmp 0,a0
 bne 1f
 mov (36,sp),a0
 call free,[],4
 bra 99f
1:
 mov a0,(12,sp)
 call FLUSH,[d2,d3],16            /* no stale lines for the work buffers' cached aliases */
 mov (12,sp),d0
 call xb_cach,[],0
 mov a0,(88,sp)                   /* T, cached */
 mov (8,sp),d3
 mov xb_G,a1
 call xb_tbl,[d2,d3,a2,a3],16
 mov (36,sp),d0                   /* V = 15 */
 call xb_cach,[],0
 mov a0,(64,sp)
 mov (44,sp),d1
 mov a0,a1
 add d1,a1
 mov a1,(100,sp)                  /* H0 */
 add d1,a1
 mov a1,(104,sp)                  /* H1 */
 mov 15,d0
1:
 movbu d0,(a0)
 inc a0
 add -1,d1
 bne 1b
 mov xb_seed,a0
 mov (a0),d0
 cmp 0,d0
 bne 2f
 mov 0x12345678,d0
2:
 mov d0,(76,sp)
 clr d0
 mov d0,(16,sp)
3:                                /* pass loop: K rows (fewer at the end) */
 mov (48,sp),d0
 mov (16,sp),d1
 sub d1,d0                        /* rows left */
 mov (92,sp),d1
 cmp d1,d0
 bcc 1f
 mov d0,d1
1:
 mov d1,(96,sp)
 mov (100,sp),a0                  /* noise rows: H0 (and H1) */
 mov a0,(68,sp)
 mov xb_p1s,d0
 call xb_cach,[],0
 calls (a0)
 mov (96,sp),d0
 cmp 2,d0
 bcs 2f
 mov (104,sp),a0
 mov a0,(68,sp)
 mov xb_p1s,d0
 call xb_cach,[],0
 calls (a0)
2:
 mov (16,sp),d0
 mov (24,sp),d1
 mul d1,d0
 mov (20,sp),d1
 add d1,d0                        /* the first row's bus address */
 mov (96,sp),d1
 add -1,d1
 mov (24,sp),d2
 mul d2,d1
 mov (44,sp),d2
 add d2,d2
 add d2,d1                        /* the length of the rows */
 call xb_open,[d2,d3,a2,a3],28
 mov d0,(40,sp)
 cmp 0,a0
 beq 4f                           /* rows across the window's edge (at most one pass): left as they are */
 clr d1                           /* through the window: its cached view (0xb8.. -> 0x78..; camera gd4: 0.63
                                     against 1.08 ms a row), the rows' lines written back before the lock goes */
 mov a0,d0
 cmp 0xb8000000,d0
 bcs 9f
 add -0x40000000,d0
 mov d0,a0
 mov 1,d1
9:
 mov d1,(52,sp)
 mov a0,(80,sp)
 mov (100,sp),a1
 mov a1,(68,sp)
 mov xb_p2s,d0
 call xb_cach,[],0
 calls (a0)                       /* row 1: row, H, words, T at (80, 68, 84, 88,sp) */
 mov (96,sp),d0
 cmp 2,d0
 bcs 5f
 mov (80,sp),d0
 mov (24,sp),d1
 add d1,d0
 mov d0,(80,sp)
 mov (104,sp),a1
 mov a1,(68,sp)
 mov xb_p2s,d0
 call xb_cach,[],0
 calls (a0)                       /* row 2 */
5:
 mov (52,sp),d1
 cmp 0,d1
 beq 4f
 call FLUSH,[d2,d3],16            /* the rows' cached lines back to memory, under the lock */
4:
 mov (40,sp),d0
 call xb_close,[d2],8
 mov (16,sp),d0
 mov (96,sp),d1
 add d1,d0
 mov d0,(16,sp)
 mov (48,sp),d1
 cmp d1,d0
 bcs 3b
 mov xb_seed,a0
 mov (76,sp),d0
 mov d0,(a0)
 call FLUSH,[d2,d3],16            /* write back the work buffers, drop the cached lines */
 mov (12,sp),a0
 call free,[],4
 mov (36,sp),a0
 call free,[],4
 mov (USCLK),d0                   /* TEST: elapsed -> LOOKS header +20 + 2 (level - 1), u16 in 1024 us */
 mov (56,sp),d1
 sub d1,d0
 cmp 0,d0
 bge 1f
 not d0
 inc d0
1:
 lsr 10,d0
 cmp 0x10000,d0
 bcs 2f
 mov 0xffff,d0
2:
 mov d0,(56,sp)
 call xb_p,[],0
 cmp 0,a1
 beq 99f
 mov 1,d0
 movbu d0,(P_DIRTY,a1)
 mov (P_LPTR,a1),a0
 cmp 0,a0
 beq 99f
 mov (60,sp),d1
 add -1,d1
 add d1,d1
 add d1,a0
 mov (56,sp),d0
 movbu d0,(20,a0)
 lsr 8,d0
 movbu d0,(21,a0)
99:
 ret [d2,d3,a2,a3],128

/* xb_cach: leaf, d0 = an address -> a0 = its cached alias (0xa0000000..0xb7ffffff -> - 0x40000000), else itself */
xb_cach:
 mov d0,a0
 cmp 0xa0000000,d0
 bcs 1f
 cmp 0xb8000000,d0
 bcc 1f
 add -0x40000000,d0
 mov d0,a0
1:
 retf [],0

/* xb_tbl: `call xb_tbl,[d2,d3,a2,a3],16`, a0 = T (4096 B), a1 = G, d3 = S. T[16 y + h] = clamp(y + delta). */
xb_tbl:
 clr d2
1:
 movbu (a1),d0
 inc a1
 mul d3,d0
 mov d0,a2                        /* G[y] S */
 mov -945,d1                      /* 64 h - 945 for h 0..30: centred on h's mean (grain/model.py) */
2:
 mov a2,d0
 mul d1,d0
 add 131072,d0
 asr 18,d0
 add d2,d0
 cmp 0,d0
 bge 3f
 clr d0
3:
 cmp 255,d0
 ble 4f
 mov 255,d0
4:
 movbu d0,(a0)
 inc a0
 add 64,d1
 cmp 1103,d1                     /* 32 entries per Y: 64 x 32 - 945 */
 bne 2b
 inc d2
 cmp 256,d2
 bne 1b
 ret [d2,d3,a2,a3],16

/* xb_p1s: `calls (a0)` from xb_grain (sp = its sp): V (64,sp), H (68), groups of 4 px (72), r (76, in and out).
 * Per px: n = lo + hi nibble of a random byte, v = (V + n) >> 1 -> V, h = (v + v_left + 1) >> 1 -> H (v_left = 15
 * at x 0). Four pixels at a time in one word (byte k = pixel 4i + k): n = (r & 0x0f..) + ((r >> 4) & 0x0f..),
 * v = (V & n) + (((V ^ n) & 0xfe..) >> 1), v_left = v << 8 | the previous word's v >> 24, h = ((v + v_left +
 * 0x01..) >> 1) & 0x7f..; no byte carries (bytes <= 61). Same values as grain/model.py. Uses d0..d3, a0..a3. */
xb_p1s:
 mov (64,sp),a0
 mov (68,sp),a1
 mov (72,sp),a2
 mov (76,sp),a3                   /* r stays in a3: the stack is uncached */
 mov 0x0f000000,d3                /* the previous word's v: 15 in byte 3 */
1:
 mov a3,d0                        /* xorshift32 */
 mov d0,d2
 asl 13,d2
 xor d2,d0
 mov d0,d2
 lsr 17,d2
 xor d2,d0
 mov d0,d2
 asl 5,d2
 xor d2,d0
 mov d0,a3
 mov d0,d1
 lsr 4,d1
 and 0x0f0f0f0f,d0
 and 0x0f0f0f0f,d1
 add d1,d0                        /* n */
 mov (a0),d1                      /* V */
 mov d1,d2
 and d0,d2                        /* V & n */
 xor d0,d1
 and 0xfefefefe,d1
 lsr 1,d1
 add d2,d1                        /* v */
 mov d1,(a0)
 add 4,a0
 lsr 24,d3
 mov d1,d2
 asl 8,d2
 or d3,d2                         /* v_left */
 mov d1,d3                        /* (the next word's previous) */
 add d1,d2
 add 0x01010101,d2
 lsr 1,d2
 and 0x7f7f7f7f,d2                /* h = (v + v_left + 1) >> 1, 0..30 */
 mov d2,(a1)
 add 4,a1
 add -1,a2
 cmp 0,a2
 bne 1b
 mov a3,(76,sp)
 rets

/* xb_p2s: `calls (a0)` from xb_grain: the row (80,sp), H (68), words (84), T (88). Y0, Y1 of each word -> T[Y][h].
 * Uses d0..d3, a0..a3. */
xb_p2s:
 mov (80,sp),a0
 mov (68,sp),a1
 mov (84,sp),a2
 mov (88,sp),a3
1:
 mov (a0),d0
 mov d0,d1
 and 0xff,d1
 asl 5,d1
 movbu (a1),d2
 or d2,d1
 movbu (d1,a3),d1                 /* Y0' */
 mov d0,d2
 lsr 16,d2
 and 0xff,d2
 asl 5,d2
 movbu (1,a1),d3
 or d3,d2
 movbu (d2,a3),d2                 /* Y1' */
 and 0xff00ff00,d0
 or d1,d0
 asl 16,d2
 or d2,d0
 mov d0,(a0)
 add 4,a0
 add 2,a1
 add -1,a2
 cmp 0,a2
 bne 1b
 rets

 .balign 4
xb_seed:
 .long 0

/* entry 0 (`calls`): relocate this block in place -> d0 = its address. Keeps d2, d3, a2, a3. */
xb_reloc:                         /* a2 = P (x_load) */
 add -4,sp
 call 1f,[],0                     /* MDR = the address of 1 (the call word goes to the new slot) */
1:
 mov mdr,d0
 add 4,sp
 add xb_base-1b,d0                /* d0 = the block's address */
 mov d0,a0
 add xb_pp-xb_base,a0
 mov a2,(a0)                      /* P, for the label loader */
 movm [d2,d3,a2,a3],(sp)
 mov d0,a2
 mov d0,d3
 add -XB_LINK,d3                  /* delta */
 mov a2,a3
 add xb_end-xb_base,a3            /* the relocation list */
 mov a2,a0
 add xb_nrel-xb_base,a0
 mov (a0),d2
2:
 cmp 0,d2
 beq 4f
 mov (a3),d1
 mov d1,d0
 and 0x7fffffff,d0
 mov a2,a0
 add d0,a0                        /* the field (any alignment: byte access) */
 mov d3,a1                        /* bit 31 set: absolute, + delta */
 cmp 0,d1
 blt 3f
 clr d0                           /* else PC-relative to the firmware: - delta */
 sub d3,d0
 mov d0,a1
3:
 movbu (3,a0),d0
 asl 8,d0
 movbu (2,a0),d1
 or d1,d0
 asl 8,d0
 movbu (1,a0),d1
 or d1,d0
 asl 8,d0
 movbu (a0),d1
 or d1,d0
 mov a1,d1
 add d1,d0
 movbu d0,(a0)
 lsr 8,d0
 movbu d0,(1,a0)
 lsr 8,d0
 movbu d0,(2,a0)
 lsr 8,d0
 movbu d0,(3,a0)
 add 4,a3
 add -1,d2
 bra 2b
4:
 call xb_lbl,[d2,d3,a2,a3],24     /* relocated: absolute addresses and firmware calls are live now */
 mov a2,d0
 movm (sp),[d2,d3,a2,a3]
 rets

/* ---- dial labels: OM3MOD/LABELS.BIN v2 = 'OM3V' | u32 total | u32 CRC-32 of bytes 12.. | u32 n (21) | n bitmaps
 * 30 rows x 9 bytes (70 px, MSB first, 1 = letter fill). One heap copy (XL_FILE B) and one 2 KB stream buffer; the
 * label is drawn and encoded (OSD type 11, 70 x 30) only when it changes. */
 .set XL_N, 24
 .set XL_BM, 270
 .set XL_FILE, 16+XL_N*XL_BM
 .set XL_OUT, 2048
/* xb_lbl: `call xb_lbl,[d2,d3,a2,a3],24` once, after relocation. Locals (4) handle, (8) file buffer. Stores: xb_lb,
 * xb_lo, xb_lc (this block), the heap buffers, own frame. Anything wrong: no labels (xb_lb = 0). */
xb_lbl:
 mov xb_lpath,a0
 mov gd_mode,a1
 call fopen,[],4
 cmp 0,a0
 beq 9f
 mov a0,(4,sp)
 mov XL_FILE+4,d0
 call malloc,[],4
 cmp 0,a0
 beq 8f
 mov a0,(8,sp)
 mov 1,d0
 mov XL_FILE+4,d1                 /* one more than the file: a longer file is refused */
 mov (4,sp),a1
 call fread,[d2,d3,a2,a3],24
 cmp XL_FILE,d0
 bne 8f
 mov (8,sp),a2
 mov (a2),d0
 cmp 0x56334d4f,d0                /* 'OM3V' */
 bne 8f
 mov (4,a2),d0
 cmp XL_FILE,d0
 bne 8f
 mov (12,a2),d0
 cmp XL_N,d0
 bne 8f
 mov -1,d0
 mov a2,a0
 add 12,a0
 mov XL_FILE-12,d1
 call sd_crc,[d2,d3],12
 not d0
 mov (8,a2),d1
 cmp d1,d0
 bne 8f
 mov XL_OUT,d0
 call malloc,[],4
 cmp 0,a0
 beq 8f
 mov xb_lo,a1
 mov a0,(a1)
 mov -1,d0
 mov xb_lc,a1
 mov d0,(a1)                      /* nothing drawn yet */
 mov xb_lb,a1
 mov a2,(a1)                      /* published last */
8:
 mov (4,sp),a0
 call fclose,[d2,a2,a3],16
9:
 ret [d2,d3,a2,a3],24

/* xb_px: `call xb_px,[],0`, d1 = x, d2 = y (any value), a3 = bitmap -> d0 = 1 letter fill, else 0. Uses d3, a0. */
xb_px:
 cmp 70,d1
 bcc 9f
 cmp 30,d2
 bcc 9f
 mov d2,d0
 asl 3,d0
 add d2,d0                        /* 9y */
 mov a3,a0
 add d0,a0
 mov d1,d0
 lsr 3,d0
 add d0,a0
 movbu (a0),d0
 mov d1,d3
 and 7,d3
 asl d3,d0
 and 128,d0
 lsr 7,d0
 retf [],0
9:
 clr d0
 retf [],0

/* xb_rend: `call xb_rend,[d2,d3,a2,a3],64`, d0 = label -> d0 = stream length in xb_lo. Locals: (4) x, (8) y, (12) out,
 * (16) bit buffer, (20) bits in it, (24) tokens in the word, (28) value, (32) run, (36) out end. */
 .macro XB_TOK                    /* d0 = token -> the stream (12 bits; after 5 tokens 4 zero bits) */
 mov (20,sp),d1
 asl d1,d0
 mov (16,sp),d2
 or d0,d2
 add 12,d1
 mov (24,sp),d0
 inc d0
 cmp 5,d0
 bne 1f
 clr d0
 add 4,d1
1:
 mov d0,(24,sp)
 mov (12,sp),a0
2:
 cmp 8,d1
 bcs 3f
 mov (36,sp),d0
 cmp d0,a0
 bcc 3f                           /* never past the buffer */
 movbu d2,(a0)
 inc a0
 lsr 8,d2
 add -8,d1
 bra 2b
3:
 mov a0,(12,sp)
 mov d2,(16,sp)
 mov d1,(20,sp)
 .endm
xb_rend:
 mov xb_lb,a0
 mov (a0),a3
 add 16,a3
 cmp 0,d0
 beq 2f
1:
 add XL_BM,a3
 add -1,d0
 bne 1b
2:
 mov xb_lo,a0
 mov (a0),a0
 mov a0,d0
 add XL_OUT,d0
 mov d0,(36,sp)
 mov 0x0b04501d,d0                /* stream header: 70 x 30, type 11 */
 mov d0,(a0)
 add 4,a0
 mov a0,(12,sp)
 clr d0
 mov d0,(16,sp)
 mov d0,(20,sp)
 mov d0,(24,sp)
 mov d0,(32,sp)
 mov d0,(8,sp)
10:
 clr d0
 mov d0,(4,sp)
11:
 mov (4,sp),d1                    /* class of (x, y) */
 mov (8,sp),d2
 call xb_px,[],0
 mov 10,a2
 cmp 0,d0
 bne 15f
 mov -1,a1                        /* 8 neighbours: dark edge 7 */
12:
 mov -1,a2
13:
 mov (4,sp),d1
 mov a2,d0
 add d0,d1
 mov (8,sp),d2
 mov a1,d0
 add d0,d2
 call xb_px,[],0
 cmp 0,d0
 bne 14f
 inc a2
 cmp 2,a2
 bne 13b
 inc a1
 cmp 2,a1
 bne 12b
 mov -2,a1                        /* out to 2 px: grey 8 */
16:
 mov -2,a2
17:
 mov (4,sp),d1
 mov a2,d0
 add d0,d1
 mov (8,sp),d2
 mov a1,d0
 add d0,d2
 call xb_px,[],0
 cmp 0,d0
 bne 18f
 inc a2
 cmp 3,a2
 bne 17b
 inc a1
 cmp 3,a1
 bne 16b
 mov 0,a2
 bra 15f
14:
 mov 7,a2
 bra 15f
18:
 mov 8,a2
15:
 mov a2,d0                        /* d0 = the class; extend the run or emit it */
 mov (32,sp),d1
 cmp 0,d1
 beq 19f
 mov (28,sp),d2
 cmp d2,d0
 bne 20f
 cmp 16,d1
 bcc 20f
 inc d1
 mov d1,(32,sp)
 bra 21f
20:
 mov d0,(40,sp)                   /* the new class (scratch) */
 mov (28,sp),d0
 asl 4,d0
 add -1,d1
 or d1,d0
 XB_TOK
 mov (40,sp),d0
19:
 mov d0,(28,sp)
 mov 1,d0
 mov d0,(32,sp)
21:
 mov (4,sp),d0
 inc d0
 mov d0,(4,sp)
 cmp 70,d0
 bne 11b
 mov (8,sp),d0
 inc d0
 mov d0,(8,sp)
 cmp 30,d0
 bne 10b
 mov (28,sp),d0                   /* the last run */
 asl 4,d0
 mov (32,sp),d1
 add -1,d1
 or d1,d0
 XB_TOK
22:
 mov (24,sp),d0                   /* zero tokens to the end of the word */
 cmp 0,d0
 beq 23f
 clr d0
 XB_TOK
 bra 22b
23:
 mov (12,sp),d0
 mov xb_lo,a0
 mov (a0),d1
 sub d1,d0
 ret [d2,d3,a2,a3],64

/* label vl (vl_s jump; frame [d2,d3,a2,a3],20 of vl_s): d2 = slice, a2 = P, a3 = the caller's a0, d3 its a1.
 * On the Extras page, slices 1..8: the "Vivid" picture's descriptor (VDESC, 70 x 30) shows the label for the slice
 * and its value; anywhere else the stock picture. Only a descriptor that is 70 x 30 with the stock payload or ours is
 * touched. Stores: VDESC +12 size, +16 payload (as gd_set does for the guide picture), xb_lc, the stream buffer. */
xb_vl:
 add -12,sp                       /* (0) call slot (xb_rend's return word), (4) the caller's a1, (8) its a0 */
 mov d3,(4,sp)
 mov a3,(8,sp)
 mov xb_lb,a0
 mov (a0),d0
 cmp 0,d0
 beq 9f                           /* no labels */
 mov VDESC,a0
 movhu (2,a0),d0
 cmp 70,d0
 bne 9f
 movhu (4,a0),d0
 cmp 30,d0
 bne 9f
 mov (16,a0),d0                   /* current payload: stock or ours? */
 cmp VSTOCK_P,d0
 beq 2f
 mov xb_lo,a1
 mov (a1),d1
 cmp d1,d0
 bne 9f
2:
 movbu (AXIS,a2),d3
 cmp 3,d3
 bne 7f
 cmp 9,d2
 bcc 7f
 movbu (EDK,a2),d3
 asl 6,d3
 add 32,d3
 add a2,d3
 mov d3,a1                        /* slot entry */
 mov xb_vt,a0
 add d2,a0
 add d2,a0
 add d2,a0
 add d2,a0                        /* {byte, mode, first label, max} */
 movbu (a0),d3
 add d3,a1
 movbu (a1),d3
 extb d3                          /* the value */
 movbu (2,a0),d1                  /* first label */
 movbu (1,a0),d0                  /* mode */
 cmp 1,d0
 beq 4f
 bcs 3f
 bra 6f                           /* 2: fixed */
3:
 cmp 0,d3                         /* 0: first + value, 0..max */
 blt 6f
 movbu (3,a0),d0
 cmp d0,d3
 bgt 6f
 add d3,d1
 bra 6f
4:
 cmp 0,d3                         /* 1: first + (negative 0, positive 1, zero 2) */
 blt 6f
 inc d1
 cmp 0,d3
 bgt 6f
 inc d1
6:
 mov xb_lc,a0                     /* label d1: draw it if it is not the one in the buffer */
 mov (a0),d0
 cmp d1,d0
 beq 5f
 mov d1,(a0)
 mov d1,d0
 call xb_rend,[d2,d3,a2,a3],64
 mov xb_ll,a0
 mov d0,(a0)
5:
 mov xb_ll,a0
 mov (a0),d0
 mov xb_lo,a0
 mov (a0),d1
 bra 8f
7:
 mov VSTOCK_S,d0                  /* the stock picture */
 mov VSTOCK_P,d1
8:
 mov VDESC,a0
 mov d0,(12,a0)
 mov d1,(16,a0)
9:
 mov (4,sp),a1
 mov (8,sp),a0
 add 12,sp
 ret [d2,d3,a2,a3],20

 .balign 4
xb_pp:
 .long 0                          /* P (written by xb_reloc) */
xb_lb:
 .long 0                          /* LABELS.BIN heap copy, 0 = none */
xb_lo:
 .long 0                          /* the stream buffer */
xb_lc:
 .long -1                         /* the label in it */
xb_ll:
 .long 0                          /* its length */
xb_vt:                            /* slice 1..8: slot byte, mode, first label, max */
 .byte 51,0,0,3                   /* 1 NR: Camera, Std, Low, Off */
 .byte 49,1,4,0                   /* 2 Glow (-), Clarity (+), Glow/Clar. (0) */
 .byte 26,1,7,0                   /* 3 Blue (-), Amber (+), A-B (0) */
 .byte 27,1,10,0                  /* 4 Magenta (-), Green (+), G-M (0) */
 .byte 50,0,13,5                  /* 5 Art Effect: Off, Star Light, Pin Hole, (Off), White Edge, Frame */
 .byte 47,2,19,0                  /* 6 Blacks */
 .byte 48,2,20,0                  /* 7 Whites */
 .byte 52,0,21,1                  /* 8 VigFix: Camera, Off (v0.21) */
 .byte 53,2,23,0                  /* 9 Grain (the readout shows the level) */
xb_lpath:
 .asciz "C:\\OM3MOD\\LABELS.BIN"
 .balign 2
xb_gstab:                         /* Grain 1..5 -> S (user: 5 = MONO Med, 2 ~ MONO Low) */
 .hword 28, 56, 84, 112, 141
xb_G:                             /* grain weight by Y, 0..255 (grain/model.py: the MONO grain shape) */
 .byte 20,20,20,20,20,20,20,20,20,20,20,20,20,20,20,20
 .byte 20,20,20,20,20,20,20,20,20,20,21,21,21,22,23,25
 .byte 26,28,30,32,34,36,39,42,45,48,51,54,58,62,65,69
 .byte 73,77,81,85,90,94,99,103,108,112,117,121,126,131,135,140
 .byte 145,149,154,159,163,168,172,177,181,186,190,194,198,202,206,210
 .byte 214,217,221,224,228,231,234,236,239,241,244,246,248,249,251,252
 .byte 253,254,255,255,255,255,255,255,255,255,255,255,255,255,255,255
 .byte 255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255
 .byte 255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255
 .byte 255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255
 .byte 255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255
 .byte 255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255
 .byte 255,255,255,255,255,255,255,255,255,255,255,254,254,254,253,252
 .byte 251,250,249,248,247,246,245,243,242,240,239,237,236,234,233,231
 .byte 229,227,226,224,222,221,219,217,215,214,212,210,209,207,206,204
 .byte 203,202,200,199,198,197,196,195,194,193,193,192,192,191,191,191
 .balign 2
xb_ft:                            /* Art Effect id -> job flags: -, Star Light, Pin Hole, -, White Edge, Frame */
 .hword 0, 0x40, 0x400, 0, 0x2000, 0x8000
xb_gl:                            /* Glow 1..5 -> w (Caduceus bloom LUT) */
 .hword 942, 881, 819, 748, 666
xb_cl:                            /* Clarity 1..5 -> w > 1024 on combiner 11 (unsharp mask, Caduceus) */
 .hword 1100, 1180, 1260, 1340, 1420
xb_nm:                            /* NR 1 Std, 2 Low, 3 Off -> the stills Noise Filter value */
 .byte 0, -1, -2
 .balign 4
xb_end:
