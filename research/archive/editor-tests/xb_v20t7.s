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
 jmp xb_kad                       /* +40 editor ALL state read (k_ad) */
 .balign 8
 jmp xb_vl                        /* +48 dial label of the Extras slice (vl_s) */
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
 .set XL_N, 21
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
 * On the Extras page, slices 1..7: the "Vivid" picture's descriptor (VDESC, 70 x 30) shows the label for the slice
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
 cmp 7,d2
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
xb_vt:                            /* slice 1..7: slot byte, mode, first label, max */
 .byte 51,0,0,3                   /* 1 NR: Camera, Std, Low, Off */
 .byte 49,1,4,0                   /* 2 Glow (-), Clarity (+), Glow/Clar. (0) */
 .byte 26,1,7,0                   /* 3 Blue (-), Amber (+), A-B (0) */
 .byte 27,1,10,0                  /* 4 Magenta (-), Green (+), G-M (0) */
 .byte 50,0,13,5                  /* 5 Art Effect: Off, Star Light, Pin Hole, (Off), White Edge, Frame */
 .byte 47,2,19,0                  /* 6 Blacks */
 .byte 48,2,20,0                  /* 7 Whites */
xb_lpath:
 .asciz "C:\\OM3MOD\\LABELS.BIN"
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
