import json,sys
from PIL import Image, ImageDraw
d=json.load(open('build/paths.json'))
keys=[k for k in d if k.endswith('_1') or (len(sys.argv)>1 and sys.argv[1] in k)]
cols=5; sc=0.2
W=int(1080*sc); H=int(1920*sc)
rows=(len(keys)+cols-1)//cols
img=Image.new('RGB',(cols*W,rows*H),(20,30,40))
dr=ImageDraw.Draw(img)
for n,k in enumerate(keys):
    ox=(n%cols)*W; oy=(n//cols)*H
    dr.rectangle([ox,oy,ox+W-1,oy+H-1],outline=(80,80,80))
    pts=[(ox+p[0]*sc,oy+p[1]*sc) for p in d[k]['pts']]
    dr.line(pts,fill=(255,220,80) if not d[k]['reason'] else (255,80,80),width=3)
    f=d[k]['frog']; dr.ellipse([ox+f[0]*sc-8,oy+f[1]*sc-8,ox+f[0]*sc+8,oy+f[1]*sc+8],fill=(80,255,120))
    dr.text((ox+4,oy+4),k+' '+d[k]['reason'],fill=(255,255,255))
img.save('build/paths.png')
