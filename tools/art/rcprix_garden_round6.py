"""Repaint the seven approved Garden bush silhouettes on their final pixel grids.

The grid seeds derive from imagegen studies, nearest-fitted to the approved
round-5 masks. Only bush_a through bush_g are written by this script.
"""
from pathlib import Path

import numpy as np
from PIL import Image
from scipy.ndimage import binary_dilation, distance_transform_edt, label, median_filter

from check_rcprix_art import TREE_TONES

ROOT = Path(__file__).resolve().parents[2]
SEEDS = ROOT / "docs/mockups/rcprix_garden/round6_sources"
OUT = ROOT / "textures/minigames/rcprix/garden"
REPS = {"a": 0, "b": 4, "c": 1, "d": 1, "e": 2, "f": 4, "g": 6}


def bush(n):
    """Return the tree-toned bush with the seed's exact size and alpha mask."""
    a=np.asarray(Image.open(SEEDS/f'bush_{n}.png').convert('RGBA')).copy();op=a[...,3]>0
    tone=np.linalg.norm(a[...,:3].astype(float)[...,None,:]-TREE_TONES[None,None],axis=-1).argmin(-1)
    _,inds=distance_transform_edt(~op,return_indices=True);z=tone[tuple(inds)]
    for i in range(REPS[n]): z=median_filter(z,size=3,mode='nearest')
    if n in 'bcefg':
     q=2 if n in 'bc' else 3
     from scipy.ndimage import zoom
     small=Image.fromarray(z.astype('uint8')).resize((max(1,round(z.shape[1]/q)),max(1,round(z.shape[0]/q))),Image.Resampling.NEAREST)
     z=np.asarray(small.resize((z.shape[1],z.shape[0]),Image.Resampling.NEAREST))
    tone[op]=z[op]
    # Begin with the study's coherent light patches, remove the smallest specks.
    bright=(tone>=4)&op
    lab,k=label(bright)
    areas=np.bincount(lab.ravel())
    limit=12 if n in 'abcd' else 5
    keep=np.zeros_like(bright)
    for j in range(1,k+1):
     if areas[j]>=limit:keep|=lab==j
    # If all are tiny, keep the largest two.
    if not keep.any():
     for j in np.argsort(areas[1:])[-2:]+1:keep|=lab==j
    target={'f':.27,'g':.35}.get(n,.36 if n in 'abcd' else .31)
    for t in range(5):
     if keep.sum()/op.sum()>=target:break
     keep=binary_dilation(keep,iterations=1)&op
    # Reclassify brightness; light/highlight will be split by top-left position.
    tone[(tone>=4)&op]=3
    tone[keep]=4
    # The imagegen source provides the dark-to-mid planes. Remove stray interior ink.
    pad=np.pad(op,1)
    edge=op&~(pad[:-2,1:-1]&pad[2:,1:-1]&pad[1:-1,:-2]&pad[1:-1,2:])
    tone[(tone==0)&op&~edge]=1
    # Give about one third of each light patch a top-left tip.
    lab,k=label(keep)
    yy,xx=np.indices(op.shape)
    for j in range(1,k+1):
     ys,xs=np.where(lab==j)
     if len(xs)<5:continue
     order=np.argsort((xs-xs.min())+(ys-ys.min())+.15*((xs*7+ys*11)%7))
     take=max(2,round(len(xs)*.30))
     tone[ys[order[:take]],xs[order[:take]]]=5
    # Outline the original silhouette with its exact 1px tree ink. 85% ink,
    # remaining edge pixels are deep shadow (never light).
    selector=((xx*7+yy*11)%20)<17
    tone[edge&selector]=0
    tone[edge&~selector]=1
    # A slightly wider dark edge and a coherent mid-green transition over deep
    # shadows mirror the reference tree's layered leaf clusters.
    if n=='a':tone[edge]=0
    shadow_goal=.29
    if ((tone==1)&op).sum()/op.sum()>shadow_goal:
     dist=distance_transform_edt(tone!=4)
     candidate=(tone==1)&op&~edge
     ys,xs=np.where(candidate)
     order=np.argsort(dist[ys,xs]+.03*((xs//3*7+ys//3*11)%9))
     excess=round(((tone==1)&op).sum()-shadow_goal*op.sum())
     tone[ys[order[:excess]],xs[order[:excess]]]=2
    if n in 'efg':
     from scipy.ndimage import binary_erosion
     # Consolidate tiny colour islands into the surrounding leaf plane.
     for _ in range(2):
      for v in (1,2,3,4,5):
       lab,k=label((tone==v)&op&~edge)
       for j in range(1,k+1):
        region=lab==j
        if region.sum()>=({'g':30}.get(n,10)):continue
        ring=binary_dilation(region)&~region&op&~edge
        ns=tone[ring];ns=ns[ns!=0]
        if len(ns):tone[region]=np.bincount(ns,minlength=6).argmax()
    if n in 'fg':
     # Broaden the middle-green shoulder below light leaf planes.
     ys,xs=np.where((tone==4)&op&~edge)
     shadow_distance=distance_transform_edt(tone!=1)
     order=np.argsort(shadow_distance[ys,xs]-.01*(ys+xs))
     take=round(op.sum()*({'f':.06,'g':.13}[n]))
     tone[ys[order[:take]],xs[order[:take]]]=3
    a[..., :3] = TREE_TONES[tone].astype(np.uint8)
    return Image.fromarray(a, "RGBA")


def generate():
    for letter in "abcdefg":
        bush(letter).save(OUT / f"bush_{letter}.png")
    print("Updated bush_a through bush_g only")


if __name__ == "__main__":
    generate()
