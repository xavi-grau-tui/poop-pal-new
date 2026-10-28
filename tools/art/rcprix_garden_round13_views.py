"""Round 13 rear and right-side stand views, drawn on the final sprite grid."""
from pathlib import Path
from PIL import Image, ImageDraw

from rcprix_garden_round13_front import (ROOT, OUT, DOC, INK, DARK, SHADOW, MID,
                                         LIT, TOP, EDGE, GREEN, GREEN_D, GREEN_L,
                                         CREAM, CREAM_D, CREAM_L, AIR, W, H)


def rear_under():
    im = Image.new("RGBA", (W, H), AIR)
    d = ImageDraw.Draw(im)
    # Rear uprights and their cross-braces are all that occupies the gaps.
    # Everything else between benches stays transparent for the audience.
    for x in range(25, W - 20, 56):
        d.rectangle((x, 20, x + 3, 94), fill=INK)
        d.rectangle((x + 1, 21, x + 2, 92), fill=SHADOW)
        d.line((x + 1, 22, x + 1, 90), fill=MID)
        for y in (38, 68):
            d.rectangle((x - 2, y, x + 5, y + 2), fill=INK)
            d.line((x - 1, y + 1, x + 4, y + 1), fill=MID)
    for row in range(5):
        y = 20 + row * 15
        d.line((5, y + 5, W - 6, y + 5), fill=INK)
        d.line((5, y + 6, W - 6, y + 6), fill=EDGE)
        d.rectangle((5, y + 7, W - 6, y + 9), fill=LIT)
        d.line((5, y + 10, W - 6, y + 10), fill=MID)
        d.rectangle((5, y + 11, W - 6, y + 12), fill=SHADOW)
        d.line((5, y + 13, W - 6, y + 13), fill=INK)
        for x in range(12 + (row % 2) * 9, W - 8, 56):
            d.rectangle((x, y + 9, x + 3, y + 9), fill=MID)
    # The same stepped timber silhouette as the front, viewed from behind.
    for left in (True, False):
        for row in range(5):
            y = 20 + row * 15
            x = 4 + row * 2 if left else W - 8 - row * 2
            d.rectangle((x - 1, y - 1, x + 4, y + 15), fill=INK)
            d.rectangle((x, y, x + 3, y + 13), fill=SHADOW)
            d.line((x, y + 1, x, y + 10), fill=TOP)
            d.rectangle((x, y + 12, x + 3, y + 13), fill=DARK)
    return im


def rear_over():
    im = Image.new("RGBA", (W, H), AIR)
    d = ImageDraw.Draw(im)
    # The roof is nearest the viewer, at the lower edge. It occupies only
    # 18 px; there is no rear wall across the audience openings.
    for x in range(4, W - 4):
        local = (x - 4) % 7
        is_green = ((x - 4) // 7) % 2 == 0
        base, light, shade = ((GREEN, GREEN_L, GREEN_D) if is_green else
                              (CREAM, CREAM_L, CREAM_D))
        for y in range(77, 94):
            d.point((x, y), fill=base)
        d.point((x, 78), fill=light)
        d.point((x, 92), fill=shade)
        # The free fabric lip points inward, with the same 7 px scallop.
        if 1 <= local <= 5:
            d.point((x, 76), fill=shade)
        if 2 <= local <= 4:
            d.point((x, 75), fill=shade)
        d.point((x, 74 if 2 <= local <= 4 else 75 if 1 <= local <= 5 else 76), fill=INK)
    d.line((4, 94, W - 5, 94), fill=INK)
    d.line((5, 93, W - 6, 93), fill=CREAM_D)
    # Roof edge and a slim near rail at the ends. No continuous rear panel.
    for left in (True, False):
        x = 0 if left else W - 5
        d.rectangle((x, 68, x + 4, 95), fill=INK)
        d.rectangle((x + 1, 70, x + 3, 93), fill=SHADOW)
        d.line((x + 1, 71, x + 1, 91), fill=TOP)
        for step in range(3):
            xx = 5 + step * 2 if left else W - 7 - step * 2
            yy = 79 + step * 4
            d.rectangle((xx, yy, xx + 2, yy + 3), fill=INK)
            d.rectangle((xx + 1, yy + 1, xx + 2, yy + 2), fill=LIT)
    return im


def side_under():
    im = Image.new("RGBA", (H, W), AIR)
    d = ImageDraw.Draw(im)
    # Seats run the length of the stand; five stepped tiers cross its width.
    # These are drawn directly in their side-view orientation rather than
    # rotating the front sprite and rotating its lighting with it.
    tiers = ((13, 13), (32, 12), (50, 11), (66, 10), (79, 9))
    for y in range(28, W - 27, 56):
        for x, _ in tiers:
            d.rectangle((x + 3, y + 24, x + 6, y + 28), fill=INK)
            d.rectangle((x + 4, y + 25, x + 5, y + 27), fill=MID)
    for row, (x, width) in enumerate(tiers):
        # Stagger the near and far ends: the front row projects farther
        # toward the viewer, while the raised rows recede under the roof.
        far = 4 + row * 6
        near = W - 5 - row * 6
        d.line((x, far, x, near), fill=INK)
        d.line((x + 1, far, x + 1, near), fill=EDGE)
        d.rectangle((x + 2, far, x + width - 5, near), fill=LIT)
        d.line((x + width - 4, far, x + width - 4, near), fill=MID)
        d.rectangle((x + width - 3, far, x + width - 2, near), fill=SHADOW)
        d.line((x + width - 1, far, x + width - 1, near), fill=INK)
        # The exposed near end cap makes each tier a solid plank.
        d.rectangle((x, near - 3, x + width - 1, near), fill=INK)
        d.rectangle((x + 1, near - 3, x + width - 3, near - 1), fill=SHADOW)
        d.line((x + 1, near - 3, x + width - 4, near - 3), fill=TOP)
        for y in range(17 + row * 3, near - 9, 56):
            d.rectangle((x + 3, y, x + 4, y + 3), fill=MID)
    for at_top in (True, False):
        for row, (x, width) in enumerate(tiers):
            y = 3 + row * 6 if at_top else W - 8 - row * 6
            d.rectangle((x, y - 1, x + width, y + 4), fill=INK)
            d.rectangle((x + 1, y, x + width - 2, y + 3), fill=SHADOW)
            d.line((x + 1, y, x + width - 3, y), fill=TOP)
    return im


def side_over():
    im = Image.new("RGBA", (H, W), AIR)
    d = ImageDraw.Draw(im)
    # The right-hand awning edge only. The 7 px stripes repeat through the
    # 56 px middle, and the rest is clear for pals between the layers.
    for y in range(4, W - 4):
        local = (y - 4) % 7
        is_green = ((y - 4) // 7) % 2 == 0
        base, light, shade = ((GREEN, GREEN_L, GREEN_D) if is_green else
                              (CREAM, CREAM_L, CREAM_D))
        # Narrow at the distant end, opening into the longer near canopy.
        lip = 78 + max(0, (28 - y + 5) // 6) if y < 28 else (
            78 - max(0, (y - 252 + 5) // 6) if y >= 252 else 78)
        d.line((lip, y, 92, y), fill=base)
        d.point((lip + 1, y), fill=light)
        d.point((92, y), fill=shade)
        if 1 <= local <= 5:
            d.point((lip - 1, y), fill=shade)
        if 2 <= local <= 4:
            d.point((lip - 2, y), fill=shade)
        d.point((lip - 3 if 2 <= local <= 4 else lip - 2 if 1 <= local <= 5 else lip - 1, y), fill=INK)
    d.line((93, 4, 93, W - 5), fill=INK)
    for top in (True, False):
        y = 0 if top else W - 5
        x = 76 if top else 68
        d.rectangle((x, y, 95, y + 4), fill=INK)
        d.rectangle((x + 2, y + 1, 93, y + 3), fill=SHADOW)
        d.line((x + 3, y + 1, 92, y + 1), fill=TOP)
    return im


def save_pieces(image, view, layer):
    boxes = (("end_a", 0, 28), ("mid", 28, 84), ("end_b", 252, 280))
    for part, l, r in boxes:
        crop = image.crop((l, 0, r, H)) if view == "back" else image.crop((0, l, H, r))
        crop.save(OUT / f"stand_{view}_{layer}_{part}.png")


def assemble(view, layer):
    im = Image.new("RGBA", (W, H) if view != "side" else (H, W), AIR)
    pos = 0
    for part in ("end_a", "mid", "mid", "mid", "mid", "end_b"):
        piece = Image.open(OUT / f"stand_{view}_{layer}_{part}.png").convert("RGBA")
        im.alpha_composite(piece, (pos, 0) if view != "side" else (0, pos))
        pos += piece.width if view != "side" else piece.height
    return im


def preview():
    board = Image.new("RGBA", (780, 430), (238, 234, 219, 255))
    from rcprix_garden_round13_front import assemble as front_assemble
    for idx, view in enumerate(("front", "back")):
        under = front_assemble("under") if view == "front" else assemble("back", "under")
        over = front_assemble("over") if view == "front" else assemble("back", "over")
        composite = Image.alpha_composite(under, over)
        board.alpha_composite(under, (15, 10 + idx * 205))
        board.alpha_composite(over, (15, 110 + idx * 205))
        board.alpha_composite(composite, (315, 60 + idx * 205))
    side_under_im = assemble("side", "under")
    side_over_im = assemble("side", "over")
    side = Image.alpha_composite(side_under_im, side_over_im)
    board.alpha_composite(side, (665, 75))
    board.resize((1560, 860), Image.Resampling.NEAREST).save(DOC / "round13_all_views_2x.png")
    # Landscape reading of the exact side PNGs makes their long receding
    # bench ends and roof projection easier to judge beside the study.
    long_view = side.transpose(Image.Transpose.ROTATE_90)
    long_view.resize((840, 288), Image.Resampling.NEAREST).save(DOC / "round13_side_long_3x.png")


def main():
    save_pieces(rear_under(), "back", "under")
    save_pieces(rear_over(), "back", "over")
    save_pieces(side_under(), "side", "under")
    save_pieces(side_over(), "side", "over")
    preview()
    print("Round 13 rear and side: 12 PNGs, all-views preview from delivered pieces")


if __name__ == "__main__":
    main()
