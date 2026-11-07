/* OM-3 1.1 probe P1 (visible): one halfword store into event-manager padding at the
 * first shutter event, read back by the COLOR hook.
 *
 * FLAG = 0x62b4dd16: +174 of the HLS event-manager singleton 0x62b4dc68 (OM-3 counterpart of the
 * E-P7's camera-proven 0x622cbcc2). Constructor 0x60af0bfc writes +172 (u16) and +176 (u32) only;
 * no code references +174/+175; boot clears [0x628ac700, 0x63410088) (0x60021060 -> fill 0x60021466);
 * the same 32-byte line is written by stock at run time (+172 at 0x60af0f90, +180.. by 0x60af19d8..).
 *
 * Hook A (shutter tracker): 0x60415216  call 0x60415343,[d2,d3,a2,a3],36  ->  jmp pr_hook
 *   reached only for events whose low16 is 0x100/0x101 (stock test 0x604151fc..0x60415212).
 *   pr_hook replays the call (same frame), then if FLAG == 0 stores 1, then jmp 0x6041521b.
 *   Uses d0 only (reloaded at 0x6041521b; d1/a0/a1 are set before use after it).
 * Hook B (COLOR builder call): 0x60518615 -> hl_pp (per-profile H/L), now gated on FLAG != 0.
 */
.section .hook_color,"ax"
 jmp hl_pp

.section .hook_shutter,"ax"
 jmp pr_hook

.section .ext,"ax"
hl_pp:
 call color_builder,[d2,d3,a2,a3],96
 movhu (FLAG),d0
 cmp 0,d0
 beq hl_out
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

pr_hook:
 call trig,[d2,d3,a2,a3],36
 movhu (FLAG),d0
 cmp 0,d0
 bne pr_back
 mov 1,d0
 movhu d0,(FLAG)
pr_back:
 jmp trig_resume

.balign 4
hl_flags:
 .byte FLAG1, FLAG2, FLAG3, FLAG4
hl_table:
 .include "table.inc"
hl_end:
