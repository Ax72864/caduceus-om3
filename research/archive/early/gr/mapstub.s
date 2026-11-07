 .am33_2
 .text
 .global _start
_start:
 mov a0,d0
 lsr 27,d0
 asl 24,d0
 or 0x00161514,d0
 mov d0,(0x98100058)
 mov a0,d0
 and 0x07ffffff,d0
 or 0xb8000000,d0
 mov d0,a0
 ret [d2,d3,a2,a3],28
