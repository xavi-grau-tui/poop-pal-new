"""Run from the repo root: <python with Pillow, numpy, scipy> tools/art/rcprix_bush_redraw.py
Redraw the approved round-6 bush drawings at a bigger final size as clean pixel art:
smooth resample of the big drawing, lock to the tree's six colours, clean specks, 1 px outline."""
import sys; sys.path.insert(0,'tools/art')
import numpy as np; from PIL import Image, ImageFilter
from scipy import ndimage
from check_rcprix_art import TREE_TONES, tree_match, TREE_MATCH
from rcprix_templates import SIZES
SRC="docs/mockups/rcprix_garden/round6_sources/"
S="textures/minigames/rcprix/garden/"
import os; os.makedirs(S,exist_ok=True)
SIGMA=0.75
OUT=np.array([0x25,0x1a,0x24])
LOBES={}
# the small ones: the designer's round-8 small sketches (only 5-8 big rosettes each)
SMALL_SRC="docs/mockups/rcprix_garden/round8_imagegen_studies/bush_{}_study.png"
def redraw(n, W, H):
    src=LOBES.get(n,(n,None))
    path=SMALL_SRC.format(n) if n in "efg" else SRC+f"bush_{src[0]}_tone_study.png"
    im=Image.open(path).convert('RGBA'); im=im.crop(im.getchannel('A').getbbox())
    BW,BH=SIZES["bush_"+src[0]]; k=min((BW-2)/im.width,(BH-2)/im.height)
    if src[1]:
        x0,y0,x1,y1=src[1]; im=im.crop((int(x0*im.width),int(y0*im.height),int(x1*im.width),int(y1*im.height)))
        k=min(k,(W-2)/im.width*1.15,(H-2)/im.height*1.15)
    w,h=round(im.width*k),round(im.height*k)
    # premultiplied smooth resample
    a=np.asarray(im).astype(float); al=a[...,3:]/255
    pm=Image.fromarray(np.uint8(np.dstack([a[...,:3]*al, a[...,3:]]))).resize((w,h),Image.LANCZOS)
    p=np.asarray(pm).astype(float); A=p[...,3]; rgb=p[...,:3]/np.maximum(A[...,None]/255,1e-3)
    mask=A>140
    mask=ndimage.binary_opening(mask,np.ones((2,2)))|ndimage.binary_erosion(mask)  # drop 1px slivers
    mask=ndimage.binary_fill_holes(mask)
    # tones by brightness rank, in the tree's shares (keeps the drawing, matches the tree's light)
    lum=(0.3*rgb[...,0]+0.59*rgb[...,1]+0.11*rgb[...,2])
    lum=ndimage.gaussian_filter(lum,SIGMA)
    v=lum[mask]; cuts=np.quantile(v,np.cumsum([0.05,0.25,0.11,0.19,0.27])[:-0] if False else np.cumsum([0.05,0.25,0.11,0.19,0.27]))
    tone=np.digitize(lum,cuts); tone[~mask]=-1
    if src[1]:   # a lobe: keep whole leaf rosettes mostly inside an oval, so the edge follows the leaves
        seeds,_=ndimage.label(tone>=4)      # each light patch is one rosette; every pixel joins the nearest
        _,(iy,ix)=ndimage.distance_transform_edt(seeds==0,return_indices=True)
        reg=np.where(mask,seeds[iy,ix],0)
        yy,xx=np.mgrid[0:h,0:w]; ov=((xx-w/2)/(w/2*0.86))**2+((yy-h/2)/(h/2*0.86))**2<=1
        keep=np.zeros_like(mask)
        for r in range(1,reg.max()+1):
            m=reg==r
            if m.sum() and (m&ov).sum()/m.sum()>=0.6: keep|=m
        keep=ndimage.binary_closing(keep,np.ones((3,3)))&mask
        lab,nl=ndimage.label(keep)
        if nl>1: keep=lab==np.bincount(lab.ravel())[1:].argmax()+1
        keep=ndimage.binary_fill_holes(keep)
        bb=ndimage.find_objects(keep.astype(int))[0]
        mask=keep[bb]; tone=tone[bb]; tone[~mask]=-1; h,w=mask.shape
        if w>W-2 or h>H-2: raise SystemExit(f"{n} lobe {w}x{h} too big for {W}x{H}")
    # clean: replace pixels whose tone differs from all 4 neighbours (specks) by the neighbours' majority
    for _ in range(2):
        t=np.pad(tone,1,constant_values=-1); nb=np.stack([t[:-2,1:-1],t[2:,1:-1],t[1:-1,:-2],t[1:-1,2:]])
        lone=mask&(nb!=tone).all(0)
        for y,x in zip(*np.nonzero(lone)):
            v=nb[:,y,x]; v=v[v>=0]
            if len(v): tone[y,x]=np.bincount(v).argmax()
    # outline: outer ring of the mask = outline colour; inner outline-colour only where it was deep gap
    pad=np.pad(mask,1); edge=mask&~(pad[:-2,1:-1]&pad[2:,1:-1]&pad[1:-1,:-2]&pad[1:-1,2:])
    tone[edge]=0
    o=np.zeros((h,w,4),np.uint8); o[...,:3]=TREE_TONES[np.clip(tone,0,5)]; o[...,3]=mask*255
    c=Image.new('RGBA',(W,H)); c.alpha_composite(Image.fromarray(o),((W-w)//2,H-1-h)); return c
res={}
for n in "abcdefg":
    W,H=SIZES["bush_"+n]; c=redraw(n,W,H); c.save(S+f"bush_{n}.png"); res[n]=c
    g=tree_match(np.asarray(c)); print(n,(W,H),[f"{k} {g[k]:.2f}" for k,(lo,hi) in TREE_MATCH.items() if not lo<=g[k]<=hi] or "matches tree")
tree=Image.open("textures/minigames/rcprix/garden/tree_top.png").convert('RGBA').crop((0,0,110,110))
W=118+sum(c.width+10 for c in res.values()); sh=Image.new('RGBA',(W,112),(222,214,186,255)); sh.alpha_composite(tree,(2,1)); x=118
for c in res.values(): sh.alpha_composite(c,(x,1)); x+=c.width+10
sh.resize((W*4,112*4),Image.NEAREST).save("docs/mockups/rcprix_garden/round8_redraw_4x.png")
