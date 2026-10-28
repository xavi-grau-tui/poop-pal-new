"""Round 3: larger bush clusters and grass tiles with a shared seamless edge.

After round 4, this rebuilds only the three grass tiles. The older bush
generator remains below for historical reference but is no longer invoked.
"""

from pathlib import Path

import numpy as np
from PIL import Image
from scipy.ndimage import gaussian_filter

from rcprix_garden_quality_sample import grass_sample

ROOT = Path(__file__).resolve().parents[2]
OUT = ROOT / "textures/minigames/rcprix/garden"
SRC = ROOT / "docs/mockups/rcprix_garden/quality_sample"
SQ = 180


def rounded_noise(shape, seed, radius):
    rng = np.random.default_rng(seed)
    field = gaussian_filter(rng.standard_normal(shape), radius, mode="wrap")
    field /= max(field.std(), 1e-6)
    return field


def seamless_a():
    """Move the edge discontinuities to a cross and quilt over that cross.

    All source strips are full-strength grass from the approved A tile. They
    are copied, not colour-blended. Wavy cut boundaries conceal the joins.
    """
    base = np.asarray(grass_sample("a"), dtype=np.uint8)
    shifted = np.roll(base, (SQ//2, SQ//2), axis=(0,1))
    out = shifted.copy()
    n = rounded_noise((SQ,SQ), 711, 6)
    # The shifted outer edges already come from A's continuous middle.
    # Both replacement strips are sampled away from the broken centre cross.
    for y in range(SQ):
        wobble = int(np.clip(n[y,90]*4,-6,6))
        lo,hi = 67+wobble,113+wobble
        out[y,lo:hi] = shifted[y,36+(lo-67):36+(hi-67)]
    n2 = rounded_noise((SQ,SQ), 977, 6)
    for x in range(SQ):
        wobble = int(np.clip(n2[90,x]*4,-6,6))
        lo,hi = 67+wobble,113+wobble
        out[lo:hi,x] = shifted[36+(lo-67):36+(hi-67),x]
    # A contiguous interior patch repairs the intersection of those strips.
    # Its irregular boundary sits far from the tile edges.
    patch = base[43:103,43:103]
    noise = rounded_noise((60,60), 1803, 3)
    for py in range(60):
        for px in range(60):
            edge = min(px,py,59-px,59-py)
            if edge > 5+noise[py,px]*2:
                out[60+py,60+px] = patch[py,px]
    return np.roll(out, (-SQ//2,-SQ//2), axis=(0,1))


def variant_from_a(a, letter):
    """Vary the interior only; the outer 16px are bit-for-bit A."""
    old = np.asarray(grass_sample(letter), dtype=np.uint8)
    yy,xx = np.indices((SQ,SQ))
    dist = np.minimum.reduce((xx,yy,SQ-1-xx,SQ-1-yy))
    field = rounded_noise((SQ,SQ), 2501 if letter=="b" else 3109, 4)
    # No straight inset line: broad, irregular patch selection grows to the
    # alternate layout through the 16–38px interior transition.
    threshold = 28 + np.clip(field*3,-6,6)
    choose = (dist>=16)&(dist>threshold)
    out = a.copy()
    out[choose] = old[choose]
    return out


def bush(name, size):
    source = ("bush_round3_large_clusters_source.png" if name=="bush_a"
              else "bush_b_round3_source.png")
    im = Image.open(SRC/source).convert("RGBA")
    alpha = np.asarray(im.getchannel("A"))
    ys,xs = np.where(alpha>=128)
    im = im.crop((int(xs.min()),int(ys.min()),int(xs.max()+1),int(ys.max()+1)))
    w,h=size
    im=im.resize((w-2,h-2),Image.Resampling.NEAREST)
    a=np.asarray(im).copy()
    a[...,3]=np.where(a[...,3]>=128,255,0).astype(np.uint8)
    # The generated source has hotter yellow highlights than the approved
    # tree. Bring only those top tones into the tree's actual RGB range.
    red=a[...,0].astype(np.float32)
    green=a[...,1].astype(np.float32)
    a[...,0]=np.clip(np.rint(red-np.maximum(0,red-120)*.47),0,255).astype(np.uint8)
    a[...,1]=np.clip(np.rint(green-np.maximum(0,green-185)*.23),0,255).astype(np.uint8)
    result=Image.new("RGBA",size,(0,0,0,0))
    result.alpha_composite(Image.fromarray(a,"RGBA"),(1,1))
    return result


def generate():
    a=seamless_a()
    for letter,arr in (("a",a),("b",variant_from_a(a,"b")),
                       ("c",variant_from_a(a,"c"))):
        Image.fromarray(arr,"RGBA").save(OUT/f"grass_{letter}.png")
    print("updated grass_a/b/c only; round-4 bushes remain untouched")


if __name__=="__main__":
    generate()
