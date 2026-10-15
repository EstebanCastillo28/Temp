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
# 1) stands de otras marcas -> neutros y sin texto
others=[(938,255,1108,322),(938,342,1108,410),(765,525,858,609),(890,525,952,609),(983,525,1076,609),
(983,442,1076,498),(517,636,610,692),(517,718,610,774),(641,636,735,692),(641,718,735,774),(890,636,952,692),
(890,718,952,774),(983,636,1076,692),(1107,580,1139,733),(444,587,513,612),(444,612,473,710),(1107,446,1139,472),
(602,802,674,830),(676,802,742,822),(912,806,978,830),(1070,780,1138,830)]
for r in others: d.rectangle(r,fill=GREY,outline=GEDGE)
for r in [(636,574,662,582),(463,613,508,625),(465,831,500,840)]: d.rectangle(r,fill=(255,255,255))
d.rectangle((444,709,473,724),fill=GREY,outline=GEDGE)
# 2) stands de las marcas (clave, rectangulos, rotar)
mine=[('igoma',[(447,778,512,830)],0),('huyser',[(685,428,722,612),(581,583,722,612)],0),
('a3mobile',[(765,442,858,498)],0),('green',[(890,442,952,498),(810,376,916,410)],0),
('ofero',[(765,636,858,692),(765,718,858,774)],0),('ewe',[(835,806,912,830)],0),
('honeywhale',[(983,718,1076,774)],0)]
NAMES={'igoma':'IGOMA','huyser':'HUYSER','a3mobile':'A3MOBILE\n(Revoo)','green':'GREEN','ofero':'OFERO','ewe':'EWE','honeywhale':'HONEY WHALE','vantilisto':'VANTILISTO'}
def logo_for(k):
    for e in ('png','jpg','jpeg','webp'):
        p=f'{D}/logos/{k}.{e}'
        if os.path.exists(p): return Image.open(p).convert('RGBA')
def slot(r,k,vertical=False):
    x0,y0,x1,y1=r; w,h=x1-x0,y1-y0
    if vertical: w,h=h,w
    c=Image.new('RGBA',(w,h),(255,255,255,255)); cd=ImageDraw.Draw(c)
    L=logo_for(k); m=3
    if L:
        L.thumbnail((w-2*m,h-2*m)); c.alpha_composite(L,((w-L.width)//2,(h-L.height)//2))
    else:
        t=NAMES[k].split('\n')[0]; s=min(14,max(6,int(w/(len(t)*0.75))))
        f=font(s); cd.text((w/2,h/2),t,fill=(20,20,20),font=f,anchor='mm')
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
V=logo_for('vantilisto')
if V:
    V.thumbnail((vr[2]-vr[0]-20,vr[3]-vr[1]-20)); im.paste(V,(vr[0]+(vr[2]-vr[0]-V.width)//2,vr[1]+(vr[3]-vr[1]-V.height)//2),V)
else: d.text(((vr[0]+vr[2])/2,(vr[1]+vr[3])/2),'VANTILISTO',fill=(0,0,0),font=font(34),anchor='mm')
im.save(f'{D}/plano_pabellon4_vantilisto.png'); print('ok')
