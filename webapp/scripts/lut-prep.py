"""Prep for scripts/fit-luts.ts: sample pixels (the Control Panel's sample photos + synthetic colours + a grey ramp)
and each LUT's output for them (trilinear). Writes OUT/src.bin and OUT/tgt/<group>__<name>.bin (u8 RGB) and
OUT/list.json. The LUTs are only read; nothing of them is stored except their output for these pixels.
usage: python3 scripts/lut-prep.py LUT_DIR OUT_DIR   (LUT_DIR: <group>/<name>.cube, sRGB in and out)"""
import json, os, sys, numpy as np
from PIL import Image
LUTS, OUTD = sys.argv[1], sys.argv[2]; SAMPLES = os.path.join(os.path.dirname(os.path.abspath(__file__)), '..', 'public', 'samples')
def load_cube(p):
    n=None; dmin=np.zeros(3); dmax=np.ones(3); rows=[]
    for line in open(p):
        t=line.strip()
        if not t or t.startswith('#'): continue
        k=t.split()
        if k[0]=='LUT_3D_SIZE': n=int(k[1])
        elif k[0]=='DOMAIN_MIN': dmin=np.array(list(map(float,k[1:4])))
        elif k[0]=='DOMAIN_MAX': dmax=np.array(list(map(float,k[1:4])))
        elif k[0][0] in '-.0123456789': rows.append(list(map(float,k[:3])))
    a=np.array(rows); assert len(a)==n**3, (p,len(a),n)
    return a.reshape(n,n,n,3), dmin, dmax   # index [b][g][r] (red fastest)
def apply(lut, rgb):
    t,dmin,dmax=lut; n=t.shape[0]
    x=(rgb-dmin)/(dmax-dmin)*(n-1); x=np.clip(x,0,n-1-1e-9); i=np.floor(x).astype(int); f=x-i
    r,g,b=i[:,0],i[:,1],i[:,2]; fr,fg,fb=f[:,0:1],f[:,1:2],f[:,2:3]
    c=lambda db,dg,dr: t[b+db,g+dg,r+dr]
    out=0
    for db in (0,1):
        for dg in (0,1):
            for dr in (0,1):
                w=(fb if db else 1-fb)*(fg if dg else 1-fg)*(fr if dr else 1-fr)
                out=out+w*c(db,dg,dr)
    return np.clip(out,0,1)
# source pixels
px=[]
for f in ['brasserie.jpg','forest.jpg','frames.jpg','harbour.jpg','neon.jpg','portrait.jpg']:   # the fit's fixed photo set
    if not f.endswith('.jpg'): continue
    im=Image.open(os.path.join(SAMPLES,f)).convert('RGB'); im.thumbnail((128,128)); px.append(np.asarray(im).reshape(-1,3))
nat=np.concatenate(px)
rng=np.random.default_rng(1)
import colorsys
syn=np.array([colorsys.hsv_to_rgb(h,s,v) for h,s,v in zip(rng.random(4000), 0.15+0.8*rng.random(4000), 0.15+0.85*rng.random(4000))])
syn=(syn*255+0.5).astype(np.uint8)
grey=np.repeat(np.linspace(0,255,64).astype(np.uint8)[:,None],3,1)
src=np.concatenate([nat,syn,grey]).astype(np.uint8)
print('pixels', len(src), 'natural', len(nat))
os.makedirs(os.path.join(OUTD,'tgt'),exist_ok=True); src.tofile(os.path.join(OUTD,'src.bin'))
items=[]
for root,_,files in os.walk(LUTS):
    for fn in sorted(files):
        if not fn.endswith('.cube'): continue
        p=os.path.join(root,fn); grp=os.path.basename(root); idn=grp+'/'+fn[:-5]
        out=apply(load_cube(p), src.astype(float)/255)
        (out*255+0.5).astype(np.uint8).tofile(os.path.join(OUTD,'tgt',idn.replace('/','__')+'.bin'))
        items.append(idn)
json.dump({'n':len(src),'natural':len(nat),'items':sorted(items)},open(os.path.join(OUTD,'list.json'),'w'),indent=1)
print(len(items),'luts')
