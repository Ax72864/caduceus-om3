import struct,sys
d=open(sys.argv[1],'rb').read()
print(d[:4], struct.unpack_from('<5I',d,4))
for k in range(4):
    S=d[48+6144*k:48+6144*(k+1)]
    nrec,n0,n3,t0,key,flags=struct.unpack_from('<6I',S,0)
    print(f'slot {k}: recs {nrec} k0 {n0} k3 {n3} key {key:#x} flags {flags:#x} cap {list(S[24:32])}')
    for i in range(min(nrec,95)):
        r=S[32+32*i:64+32*i]
        comb,kind,stage,r14,eff,rkey,fmt,ms,rq=struct.unpack_from('<BBHHHIHHI',r,0)
        print(f'  {i:2d} c{comb:3d} k{kind:2d} st {stage:#06x} r14 {r14:#06x} eff {eff:#06x} key {rkey:#x} fmt {fmt:#06x} ms {ms:5d} req {rq:#x} win {r[20:32].hex()}')
