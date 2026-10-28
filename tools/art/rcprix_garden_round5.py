"""Export seven Garden bushes from the round-5 imagegen studies.

Only bush_a through bush_g are written. Every final pixel samples one source
block with nearest-neighbour selection; there is no smooth resampling. The
final-grid colour cleanup broadens lit clusters without changing silhouettes.
"""

from pathlib import Path

import numpy as np
from PIL import Image
from scipy.ndimage import binary_dilation, label

ROOT = Path(__file__).resolve().parents[2]
OUT = ROOT / "textures/minigames/rcprix/garden"
SOURCE = ROOT / "docs/mockups/rcprix_garden/round5_sources"

SIZES = {
    "a": (90,76), "b": (108,46), "c": (86,64), "d": (94,80),
    "e": (44,38), "f": (38,32), "g": (48,36),
}


def source_on_grid(letter, size):
    raw=np.asarray(Image.open(SOURCE/f"bush_{letter}_source.png").convert("RGBA"))
    yy,xx=np.where(raw[...,3]>=128)
    crop=raw[int(yy.min()):int(yy.max())+1,int(xx.min()):int(xx.max())+1]
    w,h=size
    # Select exactly one source pixel from each final-grid block; never blend
    # two source pixels together or create half-transparent edge pixels.
    sy=np.minimum(crop.shape[0]-1,((np.arange(h-2)+.5)*crop.shape[0]/(h-2)).astype(int))
    sx=np.minimum(crop.shape[1]-1,((np.arange(w-2)+.5)*crop.shape[1]/(w-2)).astype(int))
    a=np.zeros((h,w,4),dtype=np.uint8)
    a[1:-1,1:-1]=crop[sy[:,None],sx[None,:]]
    a[...,3]=np.where(a[...,3]>=128,255,0).astype(np.uint8)
    return a


def bush(letter):
    a=source_on_grid(letter,SIZES[letter])
    mask=a[...,3]>0
    red=a[...,0].astype(np.float32)
    green=a[...,1].astype(np.float32)
    # Match the approved tree's highlight range without flattening its
    # dark-green undersides or the plum outline.
    a[...,0]=np.clip(np.rint(red-np.maximum(0,red-120)*.47),0,255).astype(np.uint8)
    a[...,1]=np.clip(np.rint(green-np.maximum(0,green-185)*.23),0,255).astype(np.uint8)
    if letter in "abcd":
        # One final-grid pixel of extension turns small highlight tips into
        # broader 10–12 px leaf masses while keeping each approved outline.
        bright=(a[...,1]>196)&(a[...,0]>120)&mask
        expanded=binary_dilation(bright,iterations=1)&mask
        a[expanded,:3]=np.maximum(a[expanded,:3],(128,190,59))
    else:
        # The small bushes carry two or three major leaf masses. Keep only
        # those broad highlights, expand them one pixel to 10–12px, and turn
        # isolated fine flecks into the normal green midtone.
        bright=(a[...,0]>140)&(a[...,1]>205)&mask
        groups,count=label(bright)
        keep_count=2 if letter=="f" else 3
        biggest=sorted(range(1,count+1),
                       key=lambda i:int((groups==i).sum()),reverse=True)[:keep_count]
        keep=np.isin(groups,biggest)
        a[bright&~keep,:3]=(96,178,56)
        expanded=binary_dilation(keep,iterations=1)&mask
        a[expanded&~keep,:3]=(142,207,64)
    a[...,3]=np.where(mask,255,0).astype(np.uint8)
    return Image.fromarray(a,"RGBA")


def generate():
    for letter in SIZES:
        bush(letter).save(OUT/f"bush_{letter}.png")
    print("updated bush_a through bush_g only")


if __name__=="__main__":
    generate()
