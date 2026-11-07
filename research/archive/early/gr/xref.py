#!/usr/bin/env python3
"""xref.py ADDR...: calls/jumps (rel16/rel32, call/calls/jmp) and data words pointing at ADDR in OM-3 main."""
import struct,sys
d=open('/home/claude/om3/decoded/00_0100_50000000.decoded.bin','rb').read();B=0x60021020
T=[int(a,16) for a in sys.argv[1:]]
for t in T:
    out=[]
    for j in range(len(d)-5):
        op=d[j]; a=B+j
        if op==0xdd and (a+struct.unpack_from('<i',d,j+1)[0])&0xffffffff==t: out.append(('call32',hex(a)))
        elif op==0xcd and (a+struct.unpack_from('<h',d,j+1)[0])&0xffffffff==t: out.append(('call16',hex(a)))
        elif op==0xdc and (a+struct.unpack_from('<i',d,j+1)[0])&0xffffffff==t: out.append(('jmp32',hex(a)))
        elif op==0xcc and (a+struct.unpack_from('<h',d,j+1)[0])&0xffffffff==t: out.append(('jmp16',hex(a)))
        elif op==0xfa and d[j+1]==0xff and (a+struct.unpack_from('<h',d,j+2)[0])&0xffffffff==t: out.append(('calls16',hex(a)))
        elif op==0xfc and d[j+1]==0xff and (a+struct.unpack_from('<i',d,j+2)[0])&0xffffffff==t: out.append(('calls32',hex(a)))
    p=struct.pack('<I',t); j=0
    while True:
        j=d.find(p,j)
        if j<0: break
        out.append(('word',hex(B+j))); j+=1
    print(hex(t),out[:40])
