SECTIONS {
  .hook 0x60518615 : { *(.hook) }
  .ext  0x607187a8 : { *(.ext) }
}
color_builder = 0x60518381;
color_resume  = 0x6051861a;
