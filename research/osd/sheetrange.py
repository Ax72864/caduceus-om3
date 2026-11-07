import json, sys
sys.path.insert(0,'/home/claude/om3/osd')
from osd11 import decode11, rd
from PIL import Image, ImageDraw
lo, hi, outf = int(sys.argv[1],16), int(sys.argv[2],16), sys.argv[3]
descs = sorted(json.load(open('/home/claude/om3/osd/ok11.json')))
near = [d for d in descs if lo <= d[0] <= hi]
W=1300; y=0; x=0; rowh=0; place=[]
for d in near:
    a,w,h,size,p=d
    if x+max(w,150)+10>W: x=0; y+=rowh+18; rowh=0
    place.append((x,y,d)); x+=max(w,150)+10; rowh=max(rowh,h)
im=Image.new('RGB',(W,y+rowh+20),(40,40,90)); dr=ImageDraw.Draw(im)
for x,y,(a,w,h,size,p) in place:
    px=decode11(rd(p,size),w,h)
    pal={0:(40,40,90)}
    g=Image.new('RGB',(w,h)); g.putdata([pal.get(v,(255,255,255) if v>8 else (120+v*15,120,120)) for v in px])
    im.paste(g,(x,y+14)); dr.text((x,y+2),'%x %dx%d'%(a,w,h),fill=(255,255,0))
im.save(outf); print(len(near), im.size)
