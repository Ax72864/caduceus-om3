#!/bin/bash
# usage: dis.sh START STOP  (runtime addresses, OM-3 1.1 main block)
# OBJDUMP: an mn10300 objdump (see research/README.md, "Toolchain"); OM3_MAIN: the decoded main block, made from the
# official firmware with tools/oe_decode.py (never committed).
OBJDUMP=${OBJDUMP:-mn10300-elf-objdump}
OM3_MAIN=${OM3_MAIN:-decoded/00_0100_50000000.decoded.bin}
"$OBJDUMP" -b binary -m mn10300 -D -z --adjust-vma=0x60021020 --start-address=$1 --stop-address=$2 "$OM3_MAIN" | tail -n +8
