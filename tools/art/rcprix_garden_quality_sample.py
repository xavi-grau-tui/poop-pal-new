"""Painted material samples fitted to RC Prix Garden's locked geometry.

The material sources were made with built-in imagegen. This script samples them
at the final pixel grid and clips them to unchanged road alpha masks. It writes
review samples only; the 76 game assets stay untouched pending approval.
"""

from __future__ import annotations

import math
from pathlib import Path

import numpy as np
from PIL import Image, ImageChops

from rcprix_templates import CURB, ROAD_HALF, SQ
from rcprix_garden_pilot import road_coordinates
from rcprix_garden_full import PLUM, SIDE_DARK, SIDE_LIT, WHITE, WHITE_SHADE, road_piece, top

OUT = Path(__file__).resolve().parents[2] / "docs/mockups/rcprix_garden/quality_sample"
GREENS = np.array([(92,151,61), (101,160,64), (110,169,66),
                   (120,178,69), (131,188,73), (143,198,79)], dtype=np.uint8)


def painted_source(name):
    source = {
        "grass_a": "grass_painted_source_v2.png",
        "grass_b": "grass_b_painted_source.png",
        "grass_c": "grass_c_painted_source.png",
    }.get(name, f"{name}_painted_source.png")
    raw = np.asarray(Image.open(OUT / source).convert("RGB")
                     .resize((SQ,SQ), Image.Resampling.NEAREST), dtype=np.float32).copy()
    if name.startswith("grass"):
        # Remove only flowers crossing the boundary; keep the painted grass.
        yy, xx = np.indices((SQ,SQ))
        edge = (xx<12)|(xx>=SQ-12)|(yy<12)|(yy>=SQ-12)
        flower = (raw[...,0]>raw[...,1]+10)|((raw[...,0]>185)&(raw[...,2]>120))
        raw[edge&flower] = (119,182,68)
    # Reconcile opposite edges. Grass gets a short, partial transition so the
    # pattern continues across a seam without duplicated edge columns.
    band = 6 if name.startswith("grass") else 16
    max_strength = .78 if name.startswith("grass") else 1.0
    for axis in (1,0):
        for i in range(band):
            j = SQ-1-i
            a = (raw[:,i] if axis==1 else raw[i]).copy()
            b = (raw[:,j] if axis==1 else raw[j]).copy()
            mean = (a+b)/2
            strength = max_strength*(band-i)/band
            if axis==1:
                raw[:,i] = a*(1-strength)+mean*strength
                raw[:,j] = b*(1-strength)+mean*strength
            else:
                raw[i] = a*(1-strength)+mean*strength
                raw[j] = b*(1-strength)+mean*strength
    return np.uint8(np.clip(np.rint(raw),0,255))


def grass_sample(variant="a"):
    raw = painted_source(f"grass_{variant}")
    a = np.empty((SQ,SQ,4), dtype=np.uint8)
    a[...,:3] = GREENS[np.digitize(raw[...,1], [149,158,168,179,190])]
    pink = (raw[...,0]>raw[...,1]+18)&(raw[...,0]>160)
    cream = (raw[...,0]>180)&(raw[...,1]>175)&(raw[...,2]>130)&~pink
    gold = (raw[...,0]>175)&(raw[...,1]>135)&(raw[...,2]<145)&~pink
    a[pink,:3] = (239,173,179)
    a[cream,:3] = (252,245,222)
    a[gold,:3] = (249,215,102)
    a[...,3] = 255
    # No copied boundary columns/rows. The partial painted-edge reconciliation
    # above keeps neighbouring colors close without a repeated seam strip.
    return Image.fromarray(a,"RGBA")


def curb_color(old, offset, progress, name, y, half=ROAD_HALF):
    white = old in (WHITE,WHITE_SHADE)
    cross = max(0,min(CURB-1,int(offset-(-half if offset<0 else half-CURB))))
    if name.startswith("corner_"):
        cy = 0 if name[-2]=="n" else SQ
        top_at_low = y>=cy
    else:
        top_at_low = True
    height_from_top = cross if top_at_low else CURB-1-cross
    # Within the locked six-pixel footprint: one bright bevel, two illuminated
    # face pixels, then a warm/grey lower edge. The outside plum contour and
    # separate one-pixel road-side lip remain in their approved positions.
    if white:
        col = ((255,255,245,255) if height_from_top<=1 else
               (246,240,225,255) if height_from_top<=3 else
               (183,177,169,255))
    else:
        col = ((255,112,78,255) if height_from_top<=1 else
               (228,49,48,255) if height_from_top<=3 else
               (145,35,45,255))
    # A fine trailing shadow separates the raised blocks without changing
    # their existing positions or the six-pixel curb footprint.
    if name.startswith("corner_"):
        radius = SQ/2+(half-CURB/2)*(1 if offset>0 else -1)
        stripe = radius*math.pi/2/(20 if offset>0 else 8)
        phase = (progress*radius/(SQ/2))%stripe
    else:
        stripe, phase = 10, progress%10
    if phase>stripe-1 and height_from_top>0:
        return (140,136,135,255) if white else (117,32,42,255)
    if phase<1 and height_from_top in (1,2):
        return (255,252,240,255) if white else (255,127,89,255)
    return col


def polish_road(name, texture, half=ROAD_HALF):
    im = road_piece(name,half)
    mask = im.getchannel("A").tobytes()
    p = im.load()
    length = SQ*math.pi/4 if name.startswith("corner_") else SQ
    for y in range(SQ):
        for x in range(SQ):
            old = p[x,y]
            if old[3]==0 or old==PLUM:
                continue
            offset, progress = road_coordinates(name,x,y)
            away = abs(offset)
            if away<half:
                if away>=half-1:
                    p[x,y] = PLUM
                elif away>=half-CURB:
                    p[x,y] = curb_color(old,offset,progress,name,y,half)
                elif away>=half-CURB-1:
                    p[x,y] = (53,38,49,255)
                elif old[0]>200 and old[1]>200 and old[2]>190:
                    p[x,y] = (253,249,237,255)
                else:
                    u = min(SQ-1,max(0,round(progress/length*(SQ-1))))
                    # Curves reverse the signed normal at some joins. Sampling
                    # by unsigned distance gives the same painted material on
                    # both sides of each tangent without a vertical seam.
                    v = min(SQ-1,max(0,round(away/half*(SQ-1))))
                    sr,sg,sb = map(int,texture[v,u])
                    wear = 9*math.exp(-((offset/23)**2))-8*(away/(half-CURB))**1.7
                    level = max(79,min(122,round(((sr+sg+sb)/3+6+wear)/3)*3))
                    p[x,y] = (level-2,level-1,level+8,255)
            elif old in (SIDE_LIT,SIDE_DARK):
                depth = next((up for up in range(1,13) if top(name,x,y-up,half)),12)
                p[x,y] = ((255,196,75,255) if depth<=2 else
                          (244,151,49,255) if depth<=5 else
                          (191,99,42,255) if depth<=9 else
                          (117,58,42,255))
    assert im.getchannel("A").tobytes()==mask
    return im


def main():
    OUT.mkdir(parents=True,exist_ok=True)
    grass = grass_sample()
    asphalt = painted_source("asphalt")
    corner = polish_road("corner_se",asphalt)
    straight = polish_road("straight_h",asphalt)
    for name,im in (("grass_a",grass),("corner_se",corner),("straight_h",straight)):
        im.save(OUT/f"{name}.png")
    board = Image.new("RGBA",(SQ*3,SQ),(126,191,72,255))
    # Shift the same seamless sample beneath the middle road piece to avoid
    # implying that the final A/B/C set will repeat one flower rhythm.
    for i in range(3):
        tile = ImageChops.offset(grass,63,57) if i==1 else grass
        board.alpha_composite(tile,(i*SQ,0))
    board.alpha_composite(corner,(0,0))
    board.alpha_composite(straight,(SQ,0))
    board.resize((SQ*6,SQ*2),Image.Resampling.NEAREST).save(OUT/"three_piece_preview_2x.png")
    board.crop((105,35,270,145)).resize((825,550),Image.Resampling.NEAREST).save(OUT/"curb_detail_5x.png")
    print("painted quality approval samples saved to",OUT)


if __name__=="__main__":
    main()
