"""The cases' brief and a preview for new case designs (2026-11-07), so the designer can see a case
exactly as the game will build it, without touching textures/.

A case is Melon Soda's own shell (textures/cases/melon_*.png: its carved logos, its holes, its rim,
its raised button frames) recoloured on a three-tone ramp (outline, body, light), with a print laid
on its FLAT parts only (never on the carving, the rim or the button frames): tools/art/cases_games.py.
The print is pixel art on the console's own grid: 1 print px = 4 screen px, a 270 x 480 picture for
the back and one for the front (the front only shows round the screens and buttons).

    .venv/bin/python tools/art/case_preview.py --brief
        -> docs/mockups/cases_brief/back_print_area.png, front_print_area.png (270 x 480: white =
           where the print shows, grey = carving / rim / frames, the case's colour only; clear = holes)
           and print_area_guide.png (both, 2x, labelled)

    .venv/bin/python tools/art/case_preview.py <id> <outline> <body> <light> <back.png> [front.png]
        e.g. torii "#6a1e16" "#d8452e" "#f6d2b8" docs/mockups/cases/round1/torii/back_print.png
        -> docs/mockups/cases/round1/<id>/preview.png (front and back as the game builds them)
"""
import os
import sys

import numpy as np
from PIL import Image, ImageDraw

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from cases_games import DIR, MELON, PX, ROOT, near, recolour  # noqa: E402

BRIEF = os.path.join(ROOT, "docs", "mockups", "cases_brief")
OUTR = os.path.join(ROOT, "docs", "mockups", "cases", "round1")


def layer(name):
    src = np.asarray(Image.open(os.path.join(DIR, f"melon_{name}.png")).convert("RGBA"))
    rgb, a = src[..., :3], src[..., 3]
    flat = (near(rgb, MELON["body"], 5) | near(rgb, MELON["dots"], 10)) & (a > 0)
    if name == "front":
        # the KamiTomo logo's patch and the corners lie on top (melon_front_top.png): case colour only
        flat &= np.asarray(Image.open(os.path.join(DIR, "melon_front_top.png")).convert("RGBA"))[..., 3] == 0
    return rgb, a, flat


def front_top(theme):
    src = np.asarray(Image.open(os.path.join(DIR, "melon_front_top.png")).convert("RGBA"))
    new = recolour(src[..., :3].astype(np.float32), theme)
    return Image.fromarray(np.dstack([new.astype(np.uint8), src[..., 3]]), "RGBA")


def brief():
    os.makedirs(BRIEF, exist_ok=True)
    tiles = []
    for name in ("back", "front"):
        rgb, a, flat = layer(name)
        small = lambda m: m.reshape(480, PX, 270, PX).mean((1, 3)) > 0.5
        f, op = small(flat), small(a > 0)
        img = np.zeros((480, 270, 4), np.uint8)
        if name == "front":
            op |= small(np.asarray(Image.open(os.path.join(DIR, "melon_front_top.png")).convert("RGBA"))[..., 3] > 0)
        img[op] = (150, 150, 150, 255)
        img[f] = (255, 255, 255, 255)
        im = Image.fromarray(img)
        im.save(os.path.join(BRIEF, f"{name}_print_area.png"))
        tiles.append(im)
    g = Image.new("RGB", (2 * 540 + 60, 960 + 70), (34, 28, 34))
    d = ImageDraw.Draw(g)
    for i, (im, label) in enumerate(zip(tiles, ("BACK", "FRONT"))):
        big = im.resize((540, 960), Image.NEAREST)
        g.paste(big, (20 + i * 560, 50), big)
        d.text((20 + i * 560, 14), f"{label}: white = the print shows, grey = the case's colour only (carving, rim, frames)",
               fill=(245, 236, 226))
    g.save(os.path.join(BRIEF, "print_area_guide.png"))
    print(BRIEF)


def hexrgb(h):
    h = h.lstrip("#")
    return tuple(int(h[i:i + 2], 16) for i in (0, 2, 4))


def preview(cid, outline, body, light, back_png, front_png=None):
    theme = {"outline": hexrgb(outline), "body": hexrgb(body), "dots": hexrgb(light)}
    out = []
    for name, png in (("front", front_png or back_png), ("back", back_png)):
        rgb, a, flat = layer(name)
        new = recolour(rgb.astype(np.float32), theme)
        art = np.asarray(Image.open(png).convert("RGB")).astype(np.float32)
        if art.shape[:2] != (480, 270):
            raise SystemExit(f"{png}: the print must be 270 x 480 (the console's grid), not {art.shape[1]} x {art.shape[0]}")
        big = np.repeat(np.repeat(art, PX, 0), PX, 1)
        new[flat] = big[flat]
        im = Image.fromarray(np.dstack([new.astype(np.uint8), a]), "RGBA")
        if name == "front":
            im.alpha_composite(front_top(theme))
        out.append(im)
    os.makedirs(os.path.join(OUTR, cid), exist_ok=True)
    sheet = Image.new("RGB", (2 * 540 + 60, 960 + 40), (34, 28, 34))
    for i, im in enumerate(out):
        small = im.resize((540, 960), Image.NEAREST)
        sheet.paste(small, (20 + i * 560, 20), small)
    path = os.path.join(OUTR, cid, "preview.png")
    sheet.save(path)
    print(path)


if __name__ == "__main__":
    if sys.argv[1:2] == ["--brief"]:
        brief()
    else:
        preview(*sys.argv[1:])
