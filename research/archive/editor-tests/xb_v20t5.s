/* Caduceus for OM-3 v0.20 test 5: the Extras code block (appended to GUIDES.BIN, our own code).
 *
 * Runs from its heap buffer (uncached pool, as the camera's malloc returns), relocated in place by entry 0. Linked at
 * XB_LINK; the build links it twice and lists every 32-bit field that moves (absolute: + delta, PC-relative to the
 * firmware: - delta). Entries are 8 bytes apart and reached from the firmware stubs with every register as the stub
 * documents. Slot entry S = P + 32 + 64k of the effective COLOR profile k+1: +49 Glow (-1..-5) / Clarity (+1..+5),
 * +50 Art Effect id (Caduceus: 1 Star Light, 2 Pin Hole, 4 White Edge, 5 Frame), +51 NR (1 Std, 2 Low, 3 Off).
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
 jmp xb_nr                        /* +32 stills Noise Filter read (s_nr) */
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
 cmp 0,d0
 beq 1f
 or 128,d1                        /* Glow or Clarity: the Soft Focus passes (the weight decides which) */
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
 beq 8f
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

/* stills Noise Filter read (property 0x9719; capture and Exif sites): the site's `call getter,[d2,d3],12` frame,
 * d0 key, d1, a0 as for the getter. NR 1..3 -> the real read, then d0 = 0 Standard / -1 Low / -2 Off. */
xb_nr:
 mov d1,d2
 mov a0,d3
 call xb_slot,[d2,d3],12
 cmp 0,a1
 beq 9f
 movbu (51,a1),d0
 add -1,d0
 cmp 3,d0
 bcc 9f
 mov xb_nm,a1
 movbu (d0,a1),d0
 extb d0
 mov d2,d1
 mov d3,a0
 mov d0,d2
 mov 38681,d0
 call getter,[d2,d3],12
 mov d2,d0
 ret [d2,d3],12
9:
 mov 38681,d0
 mov d2,d1
 mov d3,a0
 jmp getter

/* entry 0 (`calls`): relocate this block in place -> d0 = its address. Keeps d2, d3, a2, a3. */
xb_reloc:
 add -4,sp
 call 1f,[],0                     /* MDR = the address of 1 (the call word goes to the new slot) */
1:
 mov mdr,d0
 add 4,sp
 add xb_base-1b,d0                /* d0 = the block's address */
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
 mov a2,d0
 movm (sp),[d2,d3,a2,a3]
 rets

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
