"""Round 4 bushes made from the approved tree's leaf pixels at 1:1 scale.

The imagegen studies in docs/mockups/rcprix_garden/round4_sources guide only
the four silhouettes. No whole generated picture is shrunk into a sprite.
Only bush_a/b/c/d.png are written.
"""

from pathlib import Path

import numpy as np
from PIL import Image
from scipy.ndimage import binary_dilation

ROOT = Path(__file__).resolve().parents[2]
OUT = ROOT / "textures/minigames/rcprix/garden"
TREE = OUT / "tree_top.png"
INK = np.array((34,38,43,255),dtype=np.uint8)

# Eight approved-tree locations with distinct leaf lighting and silhouettes.
TREE_LEAVES = ((20,16),(52,30),(85,14),(135,18),
               (163,39),(73,64),(124,34),(103,68))

# Size, then (tree leaf index, final x, final y). The rendered clusters are
# 24–27 px across, while their lit leaf masses are about 8–12 px across.
SPECS = {
    "bush_a": ((60,52),((5,15,27),(4,42,28),(0,29,16))),  # round
    "bush_b": ((46,40),((1,12,22),(6,33,22),(2,23,17))),  # wide, low
    "bush_c": ((54,46),((3,19,17),(5,39,29))),              # small/asymmetric
    "bush_d": ((40,34),((7,20,22),(1,20,11))),              # tall-ish
}


def leaf_piece(tree, index):
    cx,cy=TREE_LEAVES[index]
    a=tree[cy-14:cy+15,cx-14:cx+15].copy()
    yy,xx=np.indices((29,29))
    dx=xx-14;dy=yy-14
    # A jagged stepped silhouette keeps intact, unscaled tree pixels. The
    # thin outline follows the shape rather than a smooth circular border.
    radius=(dx/12)**2+(dy/11)**2
    ragged=.12*np.sin(dx*1.4+dy*.3+index)+.09*np.sin(dy*1.7-dx*.5+index)
    core=(radius<1+ragged)&(a[...,3]>0)
    border=binary_dilation(core,iterations=1)&~core
    out=np.zeros_like(a)
    out[core]=a[core]
    out[border]=INK
    return Image.fromarray(out,"RGBA")


def bush(name, tree=None):
    if tree is None:
        tree=np.asarray(Image.open(TREE).convert("RGBA"),dtype=np.uint8)
    size,placed=SPECS[name]
    out=Image.new("RGBA",size,(0,0,0,0))
    for index,x,y in placed:
        piece=leaf_piece(tree,index)
        out.alpha_composite(piece,(x-14,y-14))
    return out


def generate():
    tree=np.asarray(Image.open(TREE).convert("RGBA"),dtype=np.uint8)
    for name in SPECS:
        bush(name,tree).save(OUT/f"{name}.png")
    print("updated four round-4 bushes only")


if __name__=="__main__":
    generate()
