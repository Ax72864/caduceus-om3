SECTIONS {
  .hook_color   0x60518615 : { *(.hook_color) }
  .hook_shutter 0x60415216 : { *(.hook_shutter) }
  .ext1         0x6031e920 : { *(.ext1) }
  .ext4         0x60a8f100 : { *(.ext4) }
  .hook_set     0x60b8798b : { *(.hook_set) }
  .hook_pmod    0x6129ba07 : { *(.hook_pmod) }
  .hook_tone    0x605197d7 : { *(.hook_tone) }
  .hook_fx      0x60555e50 : { *(.hook_fx) }
  .ext3         0x6081fe10 : { *(.ext3) }
  .ext8         0x617e45f0 : { *(.ext8) }
  .ext5         0x60adb5b0 : { *(.ext5) }
  .ext10        0x61aa4300 : { *(.ext10) }
  .ext6         0x60f49590 : { *(.ext6) }
  .ext9         0x619a9670 : { *(.ext9) }
}
color_builder = 0x60518381;
color_resume  = 0x6051861a;
getter        = 0x60063380;
trig          = 0x60415343;
trig_resume   = 0x6041521b;
get_tid       = 0x6003193e;
malloc        = 0x60024068;
free          = 0x6002409a;
fopen         = 0x608d4d22;
fclose        = 0x608d4d2b;
fseek         = 0x608d4fb1;
ftell         = 0x608d4f47;
fread         = 0x608d4eb7;
STATE         = 0x62b4dd16;
HLS_TID       = 0x62b4dd14;
SECBITS       = 0xa32de590;
MS_A          = 0x603692f8;
MS_B          = 0x60369300;
MS_C          = 0x60369308;
POOL          = 0xa2852000;
NEG_POOL      = 0x5d7ae000;
HMAX          = 0xae81;
MAGIC         = 0x42334d4f;
FILE_LEN      = 544;
HDR_LEN       = 32;
PAYLOAD_LEN   = 512;
CRC_TAIL      = 524;
stock_get     = 0x60b86de7;
stock_cnt     = 0x60b86e09;
stock_vbi     = 0x60b87031;
stock_default = 0x60b86e44;
manager       = 0x60bb528f;
sget          = 0x603f0111;
stock_init    = 0x6122393a;
stock_info    = 0x6122661b;
refresh       = 0x611b20ea;
facade        = 0x60b8696a;
fwrite        = 0x608d4da9;
EMARK         = 680;
AXIS          = 684;
DIRTY         = 685;
STATUS        = 686;
EDK           = 687;
GLOW          = 688;
EMAGIC        = 0x45334d4f;
OLD           = 544;
RBD           = 1088;
aget          = 0x603f039d;
GPTR          = 700;
GMAGIC        = 0x47334d4f;
GHDR          = 0x0b0ae031;
GDESC         = 0xa49ecdf8;
GSTOCK_P      = 0xa49ebe40;
GSTOCK_S      = 4022;
stock_isdef   = 0x6129bad6;
tone_next     = 0x60518fa4;
LPTR          = 708;
LIDX          = 712;
BKUP          = 720;
LKMAGIC       = 0x4b334d4f;
PFMAGIC       = 0x50334d4f;
PF_LEN        = 1632;
NMAGIC        = 0x4e334d4f;
NENT          = 720;
NPTR          = 800;
TTAB          = 816;
TORG          = 820;
TBUF          = 836;
stock_up      = 0x61223ef7;
stock_down    = 0x612241b6;
stock_event   = 0x61225d52;
fx_back       = 0x60555e56;
