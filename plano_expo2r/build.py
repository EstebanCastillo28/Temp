"""Recrea el plano del Pabellon 4 solo con las marcas indicadas.
Uso: python3 build.py   (logos opcionales en ./logos/<clave>.png|jpg ; vantilisto.png)
Claves: igoma huyser a3mobile ofero ewe green honeywhale vantilisto"""
import os
from PIL import Image, ImageDraw, ImageFont
D=os.path.dirname(os.path.abspath(__file__))
im=Image.open(f'{D}/original.webp').convert('RGB'); d=ImageDraw.Draw(im)
GREEN=(146,208,80); EDGE=(60,110,30); GREY=(226,231,222); GEDGE=(150,160,145)
def font(s):
    for p in ('/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf',):
        if os.path.exists(p): return ImageFont.truetype(p,s)
    return ImageFont.load_default()
# 1) los stands de otras marcas se dejan tal cual estan en el original
for r in [(636,574,662,582),(465,831,500,840)]: d.rectangle(r,fill=(255,255,255))
# 2) stands de las marcas (clave, rectangulos, rotar)
mine=[('igoma',[(447,778,512,830)],0),('huyser',[(685,428,722,612),(581,583,722,612)],0),
('a3mobile',[(765,442,858,498)],0),('green',[(890,442,952,498),(810,376,916,410)],0),
('ofero',[(765,636,858,692),(765,718,858,774)],0),('ewe',[(835,806,912,830)],0),
('honeywhale',[(983,718,1076,774)],0)]
NAMES={'igoma':'IGOMA','huyser':'HUYSER','a3mobile':'A3MOBILE\n(Revoo)','green':'GREEN','ofero':'OFERO','ewe':'EWE','honeywhale':'HONEY WHALE','vantilisto':'VANTILISTO'}
def logo_for(k):
    for e in ('png','jpg','jpeg','webp'):
        p=f'{D}/logos/{k}.{e}'
        if os.path.exists(p):
            L=Image.open(p).convert('RGBA'); bb=L.getchannel('A').point(lambda v:255 if v>10 else 0).getbbox()
            return L.crop(bb) if bb else L
def put(c,k,box):
    x0,y0,x1,y1=box; w,h=x1-x0,y1-y0; L=logo_for(k)
    if L:
        px=[p for p in L.resize((16,16)).getdata() if p[3]>128]
        if px and sum(sum(p[:3]) for p in px)/len(px)>600:  # logo blanco -> fondo oscuro
            ImageDraw.Draw(c).rectangle((x0-2,y0-2,x1+2,y1+2),fill=(35,35,35,255))
        L=L.copy(); L.thumbnail((w,h),Image.LANCZOS); c.alpha_composite(L,(x0+(w-L.width)//2,y0+(h-L.height)//2))
    else:
        t=NAMES[k].split('\n')[0]; f=font(min(14,max(6,int(w/(len(t)*0.75)))))
        ImageDraw.Draw(c).text(((x0+x1)/2,(y0+y1)/2),t,fill=(20,20,20),font=f,anchor='mm')
def slot(r,k,vertical=False):
    x0,y0,x1,y1=r; w,h=x1-x0,y1-y0
    if vertical: w,h=h,w
    c=Image.new('RGBA',(w,h),(255,255,255,255)); m=3
    if w>=h*1.6:   # horizontal: marca | VANTILISTO
        cut=int(w*0.58); put(c,k,(m,m,cut-m,h-m)); put(c,'vantilisto',(cut+m,m,w-m,h-m))
        ImageDraw.Draw(c).line((cut,m+1,cut,h-m-1),fill=(200,200,200))
    else:          # apilado
        cut=int(h*0.6); put(c,k,(m,m,w-m,cut-m)); put(c,'vantilisto',(m,cut+m,w-m,h-m))
        ImageDraw.Draw(c).line((m+1,cut,w-m-1,cut),fill=(200,200,200))
    if vertical: c=c.rotate(90,expand=True)
    im.paste(c.convert('RGB'),(x0,y0))
for k,rects,_ in mine:
    for i,r in enumerate(rects):
        d.rectangle(r,fill=GREEN,outline=EDGE)
        x0,y0,x1,y1=r; pad=4
        inner=(x0+pad,y0+pad,x1-pad,y1-pad)
        if k=='huyser' and i==0: inner=(x0+4,y0+4,x1-4,y0+150); slot(inner,k,True)
        elif k=='huyser': inner=(x0+4,y0+4,x0+70,y1-4); slot(inner,k)
        elif k=='green' and i==1: slot(inner,k)
        else: slot(inner,k)
# 3) cabecera: logo EXPO2R original + VANTILISTO + leyenda ajustada
orig=Image.open(f'{D}/original.webp').convert('RGB')
vr=(1190,165,1560,265)
d.rounded_rectangle(vr,12,fill=(255,255,255),outline=(0,0,0),width=2)
d.text((vr[0]+14,vr[1]+12),'Aliado / Apoya:',fill=(0,0,0),font=font(14))
c=Image.new('RGBA',(vr[2]-vr[0],vr[3]-vr[1]),(255,255,255,0)); put(c,'vantilisto',(20,34,c.width-20,c.height-10)); im.paste(c,(vr[0],vr[1]),c)
im.save(f'{D}/plano_pabellon4_vantilisto.png'); print('ok')
