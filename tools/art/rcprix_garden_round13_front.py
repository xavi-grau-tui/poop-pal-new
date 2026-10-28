"""Draw the approved round-13 front stand sample directly on its final pixel grid."""
from pathlib import Path
from PIL import Image, ImageDraw

ROOT = Path(__file__).resolve().parents[2]
OUT = ROOT / "textures/minigames/rcprix/garden"
DOC = ROOT / "docs/mockups/rcprix_garden"
INK = (40, 30, 40, 255)  # #281E28
VOID = (58, 34, 37, 255)
DARK = (88, 47, 38, 255)
SHADOW = (119, 66, 43, 255)
MID = (172, 101, 59, 255)
LIT = (207, 135, 76, 255)
TOP = (236, 178, 106, 255)
EDGE = (252, 210, 143, 255)
GREEN_D = (40, 82, 51, 255)
GREEN = (67, 135, 65, 255)
GREEN_L = (99, 164, 77, 255)
CREAM_D = (188, 180, 152, 255)
CREAM = (242, 229, 194, 255)
CREAM_L = (255, 247, 216, 255)
WHITE = (245, 246, 234, 255)
GREY = (179, 184, 181, 255)
AIR = (0, 0, 0, 0)
W, H = 280, 96


def front_under():
    im = Image.new("RGBA", (W, H), AIR)
    d = ImageDraw.Draw(im)
    # Uprights sit behind the planks. The middle pattern repeats every 56 px.
    for x in range(28, 253, 56):
        d.rectangle((x + 25, 21, x + 28, 94), fill=INK)
        d.rectangle((x + 26, 22, x + 27, 92), fill=MID)
        d.line((x + 26, 23, x + 26, 90), fill=TOP)
    for row in range(5):
        y = 20 + 15 * row
        # Dark recess: the cheering pals stand in this opening.
        d.rectangle((5, y, W - 6, y + 5), fill=VOID)
        d.line((5, y, W - 6, y), fill=INK)
        # Exposed posts divide the opening, as in the approved stand image.
        for x in range(53, W - 15, 56):
            d.rectangle((x, y + 1, x + 3, y + 5), fill=INK)
            d.rectangle((x + 1, y + 1, x + 2, y + 4), fill=SHADOW)
            d.line((x + 1, y + 1, x + 1, y + 3), fill=MID)
        # A visibly solid 4 px plank with a lit top and a shaded front face.
        d.line((5, y + 6, W - 6, y + 6), fill=INK)
        d.line((5, y + 7, W - 6, y + 7), fill=EDGE)
        d.rectangle((5, y + 8, W - 6, y + 10), fill=LIT)
        d.line((5, y + 10, W - 6, y + 10), fill=TOP)
        d.rectangle((5, y + 11, W - 6, y + 12), fill=MID)
        d.line((5, y + 13, W - 6, y + 13), fill=SHADOW)
        d.line((5, y + 14, W - 6, y + 14), fill=INK)
        # Sparse 2–4 px wood marks, never a noisy single-pixel texture.
        for x in range(16 + 7 * (row % 2), W - 12, 56):
            d.rectangle((x, y + 9, x + 3, y + 9), fill=MID)
            d.rectangle((x + 23, y + 12, x + 25, y + 12), fill=DARK)
    # Side frames climb with each tier. They are structural, not a flat border.
    for left in (True, False):
        for row in range(5):
            y = 20 + 15 * row
            inset = 4 + row * 2
            x = inset if left else W - 1 - inset - 3
            d.rectangle((x - 1, y - 1, x + 4, y + 15), fill=INK)
            d.rectangle((x, y, x + 3, y + 13), fill=SHADOW)
            d.rectangle((x, y, x + 1, y + 11), fill=LIT)
            d.line((x, y + 1, x, y + 7), fill=TOP)
            d.rectangle((x, y + 12, x + 3, y + 13), fill=DARK)
    return im


def front_over():
    im = Image.new("RGBA", (W, H), AIR)
    d = ImageDraw.Draw(im)
    # Back rail and roof brackets, with transparent space beneath the awning.
    d.rectangle((5, 2, W - 6, 5), fill=INK)
    d.line((7, 3, W - 8, 3), fill=TOP)
    for x in (14, 70, 126, 182, 238):
        d.rectangle((x, 13, x + 3, 28), fill=INK)
        d.rectangle((x + 1, 15, x + 2, 26), fill=SHADOW)
    # 7 px fabric stripes, continuing cleanly through every 56 px middle.
    for x in range(4, W - 4):
        phase = ((x - 4) // 7) % 2
        base, light, shade = ((GREEN, GREEN_L, GREEN_D) if phase == 0
                              else (CREAM, CREAM_L, CREAM_D))
        d.line((x, 6, x, 16), fill=base)
        d.point((x, 7), fill=light)
        d.line((x, 16, x, 18), fill=shade)
        # Each stripe has a stepped scalloped lower edge.
        local = (x - 4) % 7
        if 1 <= local <= 5:
            d.point((x, 19), fill=shade)
        if 2 <= local <= 4:
            d.point((x, 20), fill=shade)
    d.rectangle((4, 5, W - 5, 5), fill=INK)
    d.line((5, 6, W - 6, 6), fill=CREAM_L)
    # Thin dark fold under the scallops, but no opaque slab over the pals.
    for x in range(4, W - 4):
        local = (x - 4) % 7
        edge_y = 21 if 2 <= local <= 4 else (20 if 1 <= local <= 5 else 19)
        d.point((x, edge_y), fill=INK)
    # Angled timber supports at both ends, preserving the reference silhouette.
    for left in (True, False):
        x0 = 0 if left else W - 5
        d.rectangle((x0, 0, x0 + 4, 30), fill=INK)
        d.rectangle((x0 + 1, 2, x0 + 3, 27), fill=SHADOW)
        d.line((x0 + 1, 3, x0 + 1, 22), fill=TOP)
        for step in range(3):
            xx = (5 + step * 2) if left else (W - 7 - step * 2)
            yy = 11 + step * 4
            d.rectangle((xx, yy, xx + 2, yy + 3), fill=INK)
            d.rectangle((xx + 1, yy + 1, xx + 2, yy + 2), fill=LIT)
    return im


def flag(frame):
    im = Image.new("RGBA", (12, 24), AIR)
    d = ImageDraw.Draw(im)
    d.rectangle((1, 2, 3, 23), fill=INK)
    d.rectangle((2, 3, 2, 22), fill=MID)
    d.rectangle((1, 1, 3, 2), fill=TOP)
    outer = [
        [(3, 5), (7, 5), (11, 8), (8, 11), (11, 14), (3, 13)],
        [(3, 6), (7, 5), (10, 7), (11, 10), (8, 12), (3, 11)],
        [(3, 7), (7, 7), (11, 5), (9, 10), (11, 12), (7, 14), (3, 12)],
    ][frame]
    d.polygon(outer, fill=INK)
    inner = [
        [(4, 6), (7, 6), (10, 8), (7, 11), (9, 13), (4, 12)],
        [(4, 7), (7, 6), (9, 8), (10, 10), (7, 11), (4, 10)],
        [(4, 8), (7, 8), (10, 6), (8, 10), (10, 12), (7, 13), (4, 11)],
    ][frame]
    d.polygon(inner, fill=WHITE)
    d.line((5, 7 + frame // 2, 7, 7 + frame // 2), fill=(255, 255, 250, 255))
    d.rectangle((7, 10, 8, 11), fill=GREY)
    return im


def save_parts(im, layer):
    boxes = {"end_a": (0, 28), "mid": (28, 84), "end_b": (252, 280)}
    for part, (l, r) in boxes.items():
        im.crop((l, 0, r, H)).save(OUT / f"stand_front_{layer}_{part}.png")


def assemble(layer):
    image = Image.new("RGBA", (W, H), AIR)
    at = 0
    for name in ("end_a", "mid", "mid", "mid", "mid", "end_b"):
        p = Image.open(OUT / f"stand_front_{layer}_{name}.png").convert("RGBA")
        image.alpha_composite(p, (at, 0))
        at += p.width
    return image


def preview():
    under = assemble("under")
    over = assemble("over")
    whole = Image.alpha_composite(under, over)
    # Every panel is assembled from the actual delivered slices.
    board = Image.new("RGBA", (310, 410), (238, 234, 219, 255))
    board.alpha_composite(under, (15, 8))
    board.alpha_composite(over, (15, 110))
    board.alpha_composite(whole, (15, 212))
    road = Image.open(OUT / "straight_h.png").convert("RGBA")
    tree = Image.open(OUT / "tree_top.png").convert("RGBA")
    board.alpha_composite(road.crop((0, 0, 180, 90)), (15, 312))
    board.alpha_composite(tree.resize((88, 48), Image.Resampling.NEAREST), (209, 321))
    for i in range(3):
        board.alpha_composite(Image.open(OUT / f"stand_flag_{i}.png").convert("RGBA"),
                              (230 + i * 20, 179))
    board.resize((930, 1230), Image.Resampling.NEAREST).save(DOC / "round13_front_layers_3x.png")


def main():
    OUT.mkdir(parents=True, exist_ok=True)
    save_parts(front_under(), "under")
    save_parts(front_over(), "over")
    for i in range(3):
        flag(i).save(OUT / f"stand_flag_{i}.png")
    preview()
    print("Round 13 front sample: six layer pieces, three roof flags, 3x delivered-PNG preview")


if __name__ == "__main__":
    main()
