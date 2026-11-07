/* OM-3 1.1 (build 1100): per-profile hue/lightness, flashed table (v1 test).
 *
 * Hook: selector's single call to the 12-sector COLOR builder
 *   0x60518615  call 0x60518381,[d2,d3,a2,a3],96   ->  jmp hl_pp
 * Only reached on the selector's picture-mode == 11 (COLOR) branch.
 *
 * hl_pp: (1) replays the builder call (argument registers untouched by the jmp);
 *        (2) asks the stock settings getter for the effective COLOR profile number,
 *            exactly as capture population does at 0x603e7e1a..0x603e7e2f:
 *            d0 = 63153 (0xF6B1), d1 = 0, a0 = 0; call 0x60063380,[d2,d3],12 -> d0;
 *        (3) profile 1..4 -> slot 0..3; slot disabled or out of range -> stock output;
 *        (4) copies 12 (hue, lightness) i16 pairs, pre-permuted to record order and
 *            pre-scaled at build time, to output+836+24r (+18 hue, +22 lightness);
 *        (5) jmp 0x6051861a (stock resume).
 * Registers: only d0, d1, a0, a1 are used after the builder returns (all dead at
 * 0x6051861a). d2, d3, a2, a3 are callee-saved through the getter call.
 * No stack use beyond the getter's own call frame; no mul/div/setlb.
 */
.section .hook,"ax"
 jmp hl_pp

.section .ext,"ax"
hl_pp:
 call color_builder,[d2,d3,a2,a3],96
 mov 63153,d0
 clr d1
 mov 0,a0
 call getter,[d2,d3],12
 extbu d0
 add -1,d0
 cmp 4,d0
 bcc hl_out
 mov hl_flags,a0
 movbu (d0,a0),d1
 cmp 0,d1
 beq hl_out
 mov d0,d1
 asl 5,d0
 asl 4,d1
 add d1,d0
 mov hl_table,a1
 add d0,a1
 mov (12,a2),a0
 add 854,a0
 mov 12,d1
hl_loop:
 movhu (a1),d0
 movhu d0,(a0)
 movhu (2,a1),d0
 movhu d0,(4,a0)
 add 4,a1
 add 24,a0
 add -1,d1
 bne hl_loop
hl_out:
 jmp color_resume

.balign 4
hl_flags:
 .byte FLAG1, FLAG2, FLAG3, FLAG4
hl_table:
 .include "table.inc"
hl_end:
