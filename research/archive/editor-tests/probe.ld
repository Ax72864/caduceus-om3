SECTIONS {
  .hook_color   0x60518615 : { *(.hook_color) }
  .hook_shutter 0x60415216 : { *(.hook_shutter) }
  .ext          0x6031e920 : { *(.ext) }
}
color_builder = 0x60518381;
color_resume  = 0x6051861a;
getter        = 0x60063380;
trig          = 0x60415343;
trig_resume   = 0x6041521b;
FLAG          = 0x62b4dd16;
