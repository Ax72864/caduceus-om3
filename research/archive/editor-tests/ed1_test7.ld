SECTIONS {
  .hook_color   0x60518615 : { *(.hook_color) }
  .hook_shutter 0x60415216 : { *(.hook_shutter) }
  .ext1         0x6031e920 : { *(.ext1) }
  .ext4         0x60a8f100 : { *(.ext4) }
  .hook_set     0x60b8798b : { *(.hook_set) }
  .ext10        0x61aa4300 : { *(.ext10) }
  .ext6         0x60f49590 : { *(.ext6) }
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
stock_event   = 0x61225d52;
