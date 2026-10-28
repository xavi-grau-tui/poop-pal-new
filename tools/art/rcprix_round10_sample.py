"""Draw the Round 10 road-furniture look sample on the final pixel grid."""
from pathlib import Path

from PIL import Image, ImageDraw

ROOT = Path(__file__).resolve().parents[2]
OUT = ROOT / "textures/minigames/rcprix/garden"
DOC = ROOT / "docs/mockups/rcprix_garden"
INK = (40, 30, 40, 255)  # #281E28
ASPHALT = (88, 96, 108, 255)
PAD = (31, 48, 61, 255)
PAD_MID = (37, 75, 91, 255)
CYAN = (48, 204, 218, 255)
CYAN_LIT = (143, 245, 232, 255)
CYAN_SHADE = (25, 133, 157, 255)
WOOD_DARK = (112, 62, 42, 255)
WOOD = (174, 102, 54, 255)
WOOD_LIGHT = (221, 151, 75, 255)
WOOD_HI = (255, 202, 118, 255)
METAL = (80, 83, 99, 255)


def base():
    return Image.new("RGBA", (180, 180), (0, 0, 0, 0))


def start_line():
    im, d = base(), None
    d = ImageDraw.Draw(im)
    # 24 px deep, three rows of 8 px checks, spanning only the asphalt.
    x0, x1, y0, y1 = 78, 102, 52, 128
    # Painted white rails frame the checker without covering the curbs.
    d.rectangle((75, 52, 77, 127), fill=INK)
    d.rectangle((76, 53, 77, 126), fill=(248, 244, 225, 255))
    d.rectangle((102, 52, 104, 127), fill=INK)
    d.rectangle((102, 53, 103, 126), fill=(248, 244, 225, 255))
    d.rectangle((x0 - 1, y0 - 1, x1, y1), fill=INK)
    for row in range(3):
        for col in range(9):
            x, y = x0 + row * 8, y0 + col * 8
            c = (245, 239, 218, 255) if (row + col) % 2 == 0 else (58, 55, 62, 255)
            # Light top, darker lower pixel gives the painted blocks a slight raised edge.
            d.rectangle((x, y, x + 7, y + 6), fill=c)
            d.line((x, y + 7, x + 7, y + 7), fill=(158, 155, 146, 255) if c[0] > 100 else (36, 34, 42, 255))
    # Sparse, opaque scuffs sit beside the paint; they are visible at game scale.
    for box in ((68, 68, 71, 69), (70, 73, 73, 74), (107, 91, 110, 92),
                (109, 96, 112, 97), (66, 111, 68, 112)):
        d.rectangle(box, fill=(72, 77, 88, 255))
    return im


def boost_e():
    im, d = base(), None
    d = ImageDraw.Draw(im)
    # Hard-edged light spill, never translucent, just outside the metal plate.
    d.rectangle((57, 57, 122, 122), fill=(38, 126, 146, 255))
    d.rectangle((58, 58, 121, 121), fill=(54, 173, 187, 255))
    d.rectangle((60, 60, 119, 119), fill=INK)
    d.rectangle((62, 62, 117, 117), fill=(90, 108, 122, 255))
    d.rectangle((64, 64, 115, 115), fill=(145, 161, 169, 255))
    d.rectangle((66, 66, 113, 113), fill=INK)
    d.rectangle((68, 68, 111, 111), fill=PAD)
    d.rectangle((69, 69, 110, 72), fill=PAD_MID)
    d.rectangle((69, 107, 110, 110), fill=(22, 40, 55, 255))
    for x in (74, 87, 100):
        # Three bright east-pointing chevrons, white-cyan at their tips.
        d.polygon([(x - 6, 75), (x - 1, 75), (x + 7, 90), (x - 1, 105),
                   (x - 6, 105), (x + 1, 90)], fill=INK)
        d.polygon([(x - 4, 77), (x - 1, 77), (x + 5, 90), (x - 1, 103),
                   (x - 4, 103), (x + 3, 90)], fill=CYAN_SHADE)
        d.polygon([(x - 3, 78), (x - 1, 78), (x + 4, 90), (x - 1, 102),
                   (x - 3, 102), (x + 2, 90)], fill=CYAN)
        d.rectangle((x + 2, 87, x + 4, 92), fill=CYAN_LIT)
        d.rectangle((x + 3, 89, x + 5, 91), fill=(244, 253, 230, 255))
    # Corner hardware shares the lamp palette.
    for x in (64, 112):
        for y in (64, 112):
            d.rectangle((x - 2, y - 2, x + 2, y + 2), fill=INK)
            d.rectangle((x - 1, y - 1, x + 1, y + 1), fill=CYAN)
            d.point((x - 1, y - 1), fill=CYAN_LIT)
    return im


def ramp_e():
    from rcprix_garden_round10_finish import ramp
    return ramp("e", False)


def gantry():
    im = Image.new("RGBA", (90, 32), (0, 0, 0, 0))
    d = ImageDraw.Draw(im)
    # Roof and warm-metal fascia frame three fixed socket centres.
    d.polygon([(3, 6), (7, 2), (82, 2), (87, 6), (86, 9), (4, 9)], fill=INK)
    d.line((8, 3, 81, 3), fill=(160, 161, 163, 255), width=2)
    d.rectangle((5, 8, 84, 29), fill=INK)
    d.rectangle((7, 10, 82, 27), fill=(65, 65, 77, 255))
    # Brushed warm-metal fascia replaces the race checker stripe.
    d.rectangle((8, 9, 81, 11), fill=(114, 104, 101, 255))
    d.line((9, 9, 80, 9), fill=(211, 181, 125, 255), width=1)
    d.rectangle((0, 13, 5, 24), fill=INK)
    d.rectangle((1, 14, 4, 22), fill=WOOD_LIGHT)
    d.rectangle((84, 13, 89, 24), fill=INK)
    d.rectangle((85, 14, 88, 22), fill=WOOD_LIGHT)
    for x in (18, 45, 72):
        d.ellipse((x - 10, 6, x + 10, 27), fill=INK)
        d.ellipse((x - 8, 8, x + 8, 25), fill=(119, 119, 129, 255))
        d.ellipse((x - 6, 10, x + 6, 22), fill=(25, 24, 33, 255))
        d.arc((x - 8, 8, x + 6, 22), 190, 275, fill=(220, 217, 202, 255), width=2)
    d.rectangle((7, 28, 82, 29), fill=INK)
    return im


def lamp(state):
    im = Image.new("RGBA", (22, 22), (0, 0, 0, 0))
    d = ImageDraw.Draw(im)
    d.ellipse((0, 0, 21, 21), fill=INK)
    if state == "off":
        d.ellipse((2, 2, 19, 19), fill=(82, 80, 87, 255))
        d.ellipse((5, 5, 16, 16), fill=(46, 45, 55, 255))
        d.rectangle((6, 4, 10, 6), fill=(215, 213, 202, 255))
        d.line((5, 16, 15, 16), fill=(31, 29, 39, 255), width=2)
    else:
        main, bright, edge, ring = ((216, 48, 55, 255), (255, 148, 126, 255), (129, 36, 49, 255), (255, 91, 74, 255)) if state == "red" else ((67, 190, 82, 255), (184, 255, 128, 255), (34, 105, 54, 255), (119, 229, 99, 255))
        d.ellipse((1, 1, 20, 20), fill=edge)
        d.ellipse((4, 3, 18, 18), fill=ring)
        d.ellipse((6, 5, 16, 16), fill=main)
        d.ellipse((8, 7, 14, 13), fill=bright)
        d.rectangle((7, 5, 11, 7), fill=(255, 246, 210, 255))
        d.rectangle((8, 16, 14, 17), fill=edge)
        # Solid-colour rim lets light spill onto the gantry socket beneath.
        d.arc((1, 1, 20, 20), 195, 330, fill=ring, width=2)
    return im


def main():
    OUT.mkdir(parents=True, exist_ok=True)
    assets = {
        "start_h": start_line(), "boost_e": boost_e(), "ramp_e": ramp_e(),
        "start_gantry": gantry(), "start_lamp_off": lamp("off"),
        "start_lamp_red": lamp("red"), "start_lamp_green": lamp("green"),
    }
    for name, im in assets.items():
        im.save(OUT / f"{name}.png", optimize=True)
    preview(assets)
    print("Wrote", ", ".join(f"{n} {im.width}x{im.height}" for n, im in assets.items()))


def preview(assets):
    # Show actual delivered PNGs over the approved road and adjacent lawn.
    grass = Image.open(OUT / "grass_a.png").convert("RGBA")
    road = Image.open(OUT / "straight_h.png").convert("RGBA")
    cell = grass.copy()
    cell.alpha_composite(road)
    cell.alpha_composite(assets["start_h"])
    cell = cell.resize((540, 540), Image.Resampling.NEAREST)
    cell.save(DOC / "round10_sample_startline_3x.png")

    pad_cell = grass.copy()
    pad_cell.alpha_composite(road)
    pad_cell.alpha_composite(assets["boost_e"])
    pad_cell = pad_cell.resize((540, 540), Image.Resampling.NEAREST)
    pad_cell.save(DOC / "round10_sample_boost_3x.png")

    ramp_cell = grass.copy()
    ramp_cell.alpha_composite(road)
    ramp_cell.alpha_composite(assets["ramp_e"])
    ramp_cell = ramp_cell.resize((540, 540), Image.Resampling.NEAREST)
    ramp_cell.save(DOC / "round10_sample_ramp_3x.png")

    # Contact sheet at 3× nearest-neighbour: loose sprites stay transparent on cream.
    swatch = Image.new("RGBA", (760, 230), (239, 233, 216, 255))
    d = ImageDraw.Draw(swatch)
    gantry = assets["start_gantry"].resize((270, 96), Image.Resampling.NEAREST)
    swatch.alpha_composite(gantry, (24, 18))
    for cx, name in zip((18, 45, 72), ("start_lamp_off", "start_lamp_red", "start_lamp_green")):
        icon = assets[name].resize((66, 66), Image.Resampling.NEAREST)
        swatch.alpha_composite(icon, (24 + (cx - 11) * 3, 18 + (16 - 11) * 3))
    for i, name in enumerate(("start_lamp_off", "start_lamp_red", "start_lamp_green")):
        icon = assets[name].resize((66, 66), Image.Resampling.NEAREST)
        swatch.alpha_composite(icon, (68 + i * 92, 135))
        d.text((53 + i * 92, 207), name.replace("start_lamp_", ""), fill=INK)
    swatch.save(DOC / "round10_sample_lights_3x.png")

    # One overview for visual review, also made only from the delivered PNGs.
    panels = [Image.open(DOC / f"round10_sample_{n}_3x.png").convert("RGB")
              for n in ("startline", "boost", "ramp")]
    overview = Image.new("RGB", (1700, 960), (239, 233, 216))
    labels = ImageDraw.Draw(overview)
    for i, (panel, label) in enumerate(zip(panels, ("Start / finish", "Boost", "Ramp"))):
        x = 20 + i * 560
        labels.text((x, 12), label, fill=INK)
        overview.paste(panel, (x, 38))
    overview.paste(swatch.convert("RGB"), (20, 596))
    tree = Image.open(OUT / "tree_top.png").convert("RGBA")
    tree_ground = Image.new("RGBA", (600, 330))
    grass_big = grass.resize((540, 540), Image.Resampling.NEAREST)
    tree_ground.alpha_composite(grass_big, (0, 0))
    tree_ground.alpha_composite(tree.resize((600, 330), Image.Resampling.NEAREST))
    labels.text((960, 596), "Approved grass and tree at 3x", fill=INK)
    overview.paste(tree_ground.convert("RGB"), (960, 616))
    overview.save(DOC / "round10_sample_overview.png")


if __name__ == "__main__":
    main()
