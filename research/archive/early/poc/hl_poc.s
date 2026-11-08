/* OM-3 1.1 (build 1100) proof of concept: fixed hue/lightness in all
 * twelve COLOR sector records.
 *
 * Hook: the selector's single call to the twelve-sector builder
 *   0x60518615: call 0x60518381,[d2,d3,a2,a3],96   (5 bytes)
 * is replaced by "jmp hl_poc". hl_poc performs the identical call (all
 * argument registers d0,d1,a0,a1 are untouched by the jmp), then writes
 * fixed hue (+18) and lightness (+22) halfwords into each of the twelve
 * 24-byte output records at output+836, and resumes at 0x6051861a.
 *
 * Register use after the builder returns: only d0, d1, a0 (all reloaded
 * by the stock code at 0x6051861a.. before being read). d2,d3,a2,a3 are
 * restored by the builder's own ret. No stack use, no extra CALL (MDR
 * unchanged relative to stock).
 *
 * Placement: section 2 loaded tail 0x607187a4..0x60718800 (92 bytes),
 * immediately after section 2's bounded 13-entry constructor table, in the
 * same section as the hook site. Stock source hue/lightness are zero in all
 * twelve table records, so writing == adding.
 */
.section .hook,"ax"
 jmp hl_poc

.section .ext,"ax"
hl_poc:
 call color_builder,[d2,d3,a2,a3],96
 mov (12,a2),a0
 add 854,a0
 mov 12,d1
hl_loop:
 mov HUE,d0
 movhu d0,(a0)
 mov LIGHT,d0
 movhu d0,(4,a0)
 add 24,a0
 add -1,d1
 bne hl_loop
 jmp color_resume
