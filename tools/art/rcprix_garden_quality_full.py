"""Apply the approved painted Garden finish to all 76 locked-size sprites.

Road masks come from the geometry renderer. Painted imagegen sources live in
docs/mockups/rcprix_garden/quality_sample, and are sampled with nearest-neighbour.
"""

from __future__ import annotations

import math
from pathlib import Path

import numpy as np
from PIL import Image, ImageDraw, ImageOps

from rcprix_templates import (CURB, FRAME, GROUND, OVERLAYS, ROAD,
                              ROAD_HALF, ROAD_HALF_WIDE, SPRITES, SQ, SIZES)
from rcprix_garden_full import (GOLD, PLUM, RED, WHITE, frame_piece, overlay,
                                small_sprite)
from rcprix_garden_quality_sample import painted_source, polish_road
from rcprix_garden_round3 import seamless_a, variant_from_a, bush as round3_bush

ROOT = Path(__file__).resolve().parents[2]
OUT = ROOT / "textures/minigames/rcprix/garden"
SOURCES = ROOT / "docs/mockups/rcprix_garden/quality_sample"


def cutout_source(name, size, flip_x=False):
    """Fit a transparent painted source at the sprite's exact hard-pixel size."""
    raw = Image.open(SOURCES / f"{name}_painted_source.png").convert("RGBA")
    alpha = np.asarray(raw.getchannel("A"))
    ys, xs = np.where(alpha >= 128)
    raw = raw.crop((int(xs.min()), int(ys.min()), int(xs.max()+1), int(ys.max()+1)))
    if flip_x:
        raw = ImageOps.mirror(raw)
    w, h = size
    fitted = raw.resize((w-2,h-2),Image.Resampling.NEAREST)
    a = np.asarray(fitted).copy()
    a[...,3] = np.where(a[...,3]>=128,255,0).astype(np.uint8)
    result = Image.new("RGBA",size,(0,0,0,0))
    result.alpha_composite(Image.fromarray(a,"RGBA"),(1,1))
    return result


def tree_sprite(name,size):
    top = cutout_source("tree_canopy",(200,110))
    if name=="tree_top":
        return top
    if name=="tree_bottom":
        return ImageOps.flip(top)
    side = top.transpose(Image.Transpose.ROTATE_90)
    return side if name=="tree_left" else ImageOps.mirror(side)


def bush_sprite(name,size):
    return round3_bush(name,size)


def car_slices():
    """Separate the painted car into the six existing depth roles."""
    car = cutout_source("car",(44,32))
    a = np.asarray(car).copy()
    yy, xx = np.indices((32,44))
    opaque = a[...,3]>0
    dark = (a[...,0]<115)&(a[...,1]<115)&(a[...,2]<125)
    cyan = (a[...,2]>a[...,0]+20)&(a[...,1]>a[...,0]+20)
    wheel_zone = ((yy<10)|(yy>=23))&(((xx>=2)&(xx<17))|((xx>=27)&(xx<42)))
    wheels = opaque&dark&wheel_zone
    # Include the rubber's mid-grey pixels in the four wheel zones.
    wheels |= opaque&wheel_zone&(a[...,0]<150)&(a[...,2]<170)
    body = opaque&~wheels&~cyan
    cabin = opaque&cyan
    result = []
    for i in range(6):
        layer = np.zeros_like(a)
        if i<2:
            layer[wheels] = a[wheels]
            # Central chassis is visible between the wheels only at the base.
            im = Image.fromarray(layer,"RGBA")
            d = ImageDraw.Draw(im)
            d.rounded_rectangle((10,11,33,20),radius=3,fill=(53,45,55,255),outline=PLUM)
            if i==1:
                d.line((13,12,29,12),fill=(115,111,119,255),width=1)
            result.append(im)
        elif i<4:
            layer[body] = a[body]
            # The body slices repeat their footprint to form a solid toy shell.
            im = Image.fromarray(layer,"RGBA")
            if i==3:
                d = ImageDraw.Draw(im)
                d.line((11,8,19,8),fill=(255,168,125,255),width=1)
            result.append(im)
        elif i==4:
            im = Image.new("RGBA",(44,32),(0,0,0,0))
            d = ImageDraw.Draw(im)
            d.rounded_rectangle((18,9,32,23),radius=4,fill=(150,40,46,255),outline=PLUM)
            layer[cabin] = a[cabin]
            im.alpha_composite(Image.fromarray(layer,"RGBA"))
            result.append(im)
        else:
            im = Image.new("RGBA",(44,32),(0,0,0,0))
            d = ImageDraw.Draw(im)
            # A complete roof cap keeps the highlight attached to the car.
            d.rounded_rectangle((16,7,33,23),radius=5,fill=(215,51,51,255),outline=PLUM)
            d.rounded_rectangle((21,11,30,20),radius=3,fill=(73,164,184,255),outline=(26,73,94,255))
            d.line((18,9,27,9),fill=(255,177,127,255),width=2)
            d.line((21,12,25,12),fill=(219,249,249,255),width=1)
            result.append(im)
    return result


def flowers_sprite(name,size):
    im = Image.new("RGBA",size,(0,0,0,0))
    d = ImageDraw.Draw(im)
    points = ((4,7),(10,3),(13,8)) if name.endswith("a") else ((3,3),(8,8),(13,5))
    for i,(x,y) in enumerate(points):
        petal = (254,245,222,255) if (i+(name.endswith("b")))%2 else (244,179,180,255)
        d.rectangle((x-2,y+2,x+2,y+3),fill=(55,126,55,255))
        for dx,dy in ((-2,0),(2,0),(0,-2),(0,2)):
            d.rectangle((x+dx,y+dy,x+dx+1,y+dy+1),fill=petal)
        d.rectangle((x,y,x+1,y+1),fill=(255,216,105,255))
    return im


def polished_small(name,size):
    im = small_sprite(name,size)
    d = ImageDraw.Draw(im)
    if name=="crate":
        d.polygon([(3,4),(15,4),(13,7),(5,7)],fill=(228,166,91,255))
        d.line((5,7,5,15),fill=(102,57,42,255),width=1)
        d.point((4,4),fill=(247,205,124,255))
        d.point((16,15),fill=(66,38,41,255))
    elif name=="lamp_post":
        d.line((2,4,7,4),fill=(255,239,165,255),width=1)
        d.point((3,6),fill=(255,247,200,255))
        d.line((4,10,4,16),fill=(227,153,78,255),width=1)
    elif name=="start_lamp":
        # White and greys only so runtime tinting stays predictable.
        im = Image.new("RGBA",size,(0,0,0,0))
        d = ImageDraw.Draw(im)
        d.ellipse((2,2,29,29),fill=(91,91,91,255),outline=(39,39,39,255),width=2)
        d.ellipse((5,5,26,26),fill=(220,220,220,255),outline=(156,156,156,255),width=2)
        d.arc((8,7,23,23),190,292,fill=(255,255,255,255),width=3)
        d.arc((9,9,24,24),14,80,fill=(181,181,181,255),width=2)
    elif name=="spring":
        d.line((2,12,21,12),fill=PLUM,width=2)
        for x in (4,9,14,19):
            d.point((x,5),fill=(255,255,244,255))
            d.point((x+1,7),fill=(142,141,148,255))
    elif name=="balloon":
        d.arc((3,2,14,15),185,290,fill=(255,196,151,255),width=2)
        d.line((8,20,9,24),fill=(124,69,56,255),width=1)
    elif name=="sparkle":
        d.line((9,2,9,7),fill=(255,251,229,255),width=2)
        d.point((3,8),fill=(255,251,229,255))
    elif name=="helmet":
        d.line((5,3,10,3),fill=(255,155,118,255),width=2)
        d.point((12,8),fill=(255,243,215,255))
    return im


def polished_frame(name,size):
    im = frame_piece(name,size)
    d = ImageDraw.Draw(im)
    w,h = size
    if name.startswith("frame_corner"):
        d.line((5,6,14,6),fill=(241,185,105,255),width=2)
        d.point((8,9),fill=(255,221,135,255))
    elif w>h:
        for x in range(8,w,45):
            d.line((x,12,x+12,12),fill=(122,69,45,255),width=1)
            d.line((x+4,15,x+10,15),fill=(217,159,86,255),width=1)
    else:
        for y in range(8,h,45):
            d.line((12,y,12,y+12),fill=(122,69,45,255),width=1)
            d.line((15,y+4,15,y+10),fill=(217,159,86,255),width=1)
    return im


def polished_overlay(name,half):
    im = overlay(name,half)
    d = ImageDraw.Draw(im)
    p = im.load()
    if name.startswith("start_"):
        for y in range(SQ):
            for x in range(SQ):
                if p[x,y][3]==0:
                    continue
                old=p[x,y]
                p[x,y] = ((255,252,240,255) if old==WHITE and (x+y)%8<4 else
                          (229,223,208,255) if old==WHITE else
                          (44,37,47,255) if (x+y)%8<4 else (58,51,61,255))
    elif name.startswith("boost_"):
        for y in range(SQ):
            for x in range(SQ):
                old=p[x,y]
                if old==GOLD:
                    p[x,y]=(250,191,57,255) if (x+y)%7<4 else (230,157,44,255)
    elif name.startswith("ramp_"):
        direction=name[-1]
        a=SQ//2
        span=half-CURB-7
        def pt(t,u):
            return {"e":(a+t,a+u),"w":(a-t,a+u),"s":(a+u,a+t),"n":(a+u,a-t)}[direction]
        # Direction arrow painted on the existing slope, inside its footprint.
        d.line([pt(-8,-7),pt(6,0),pt(-8,7)],fill=(239,247,226,255),width=3,joint="curve")
        d.line([pt(-15,-span),pt(12,-span)],fill=(207,238,229,255),width=1)
    elif name.startswith("tyres_"):
        # Keep the wall on the locked outer arc, but finish both ends inside
        # the tile with round caps instead of clipping tyre silhouettes.
        im = Image.new("RGBA",(SQ,SQ),(0,0,0,0))
        d = ImageDraw.Draw(im)
        corner=name[-2:]
        cx=SQ if corner[1]=="e" else 0
        cy=0 if corner[0]=="n" else SQ
        sx=-1 if cx else 1
        sy=1 if cy==0 else -1
        def on_arc(theta,radial):
            radius=SQ/2+half+radial
            return (round(cx+sx*radius*math.cos(theta)),
                    round(cy+sy*radius*math.sin(theta)))
        path=[on_arc(.085+i*(math.pi/2-.17)/64,12) for i in range(65)]
        d.line(path,fill=PLUM,width=21,joint="curve")
        for x,y in (path[0],path[-1]):
            d.ellipse((x-10,y-10,x+10,y+10),fill=PLUM)
        for row,radial in ((0,18),(1,6)):
            for i in range(18):
                theta=.115+(i+(0 if row==0 else .45))*(math.pi/2-.23)/18
                x,y=on_arc(theta,radial)
                d.ellipse((x-8,y-7,x+8,y+7),fill=PLUM)
                d.ellipse((x-6,y-5,x+6,y+5),fill=(49,47,58,255))
                d.arc((x-5,y-4,x+5,y+3),190,335,fill=(113,111,123,255),width=2)
                d.ellipse((x-2,y-2,x+2,y+2),fill=PLUM)
    return im


def generate():
    OUT.mkdir(parents=True,exist_ok=True)
    asphalt=painted_source("asphalt")
    # Road positions, masks and join pixels come from the locked geometry code.
    for half,suffix in ((ROAD_HALF,""),(ROAD_HALF_WIDE,"_wide")):
        for name,_ in ROAD:
            polished=polish_road(name,asphalt,half)
            polished.save(OUT/f"{name}{suffix}.png")
        for name,_ in OVERLAYS:
            polished_overlay(name,half).save(OUT/f"{name}{suffix}.png")
    grass_a = seamless_a()
    for letter, pixels in (("a",grass_a),("b",variant_from_a(grass_a,"b")),
                           ("c",variant_from_a(grass_a,"c"))):
        Image.fromarray(pixels,"RGBA").save(OUT/f"grass_{letter}.png")
    cars=car_slices()
    for i,im in enumerate(cars):
        im.save(OUT/f"car_slice_{i}.png")
    for name,_,w,h in SPRITES:
        if name.startswith("car_slice_"):
            continue
        size=(w,h)
        if name.startswith("tree_"):
            im=tree_sprite(name,size)
        elif name.startswith("bush_"):
            im=bush_sprite(name,size)
        elif name.startswith("flowers_"):
            im=flowers_sprite(name,size)
        elif name.startswith("frame_"):
            im=polished_frame(name,size)
        else:
            im=polished_small(name,size)
        im.save(OUT/f"{name}.png")
    print(f"wrote {len(SIZES)} painted Garden assets to {OUT}")


if __name__=="__main__":
    generate()
