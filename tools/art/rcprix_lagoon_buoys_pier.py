"""Paint Lagoon buoy slices from their guides plus the pier post/foam sprites.

All drawing is performed on the final game-pixel grid; each pixel is expanded
to one hard 4x4 block. Buoy mask geometry and the four 1px magenta registration
marks come directly from round2_buoy_guides.
"""
from pathlib import Path
import math
import runpy
import struct
import zlib

ROOT = Path(__file__).resolve().parents[2]
PAINT = ROOT / "docs/mockups/rcprix_lagoon/round2_paint"
GUIDES = ROOT / "docs/mockups/rcprix_lagoon/round2_buoy_guides"
read_png = runpy.run_path(str(ROOT / "tools/art/lagoon_round2_export.py"))["read_png"]

INK = (40, 34, 44)
PINK = (255, 0, 255)


def write_png(path, w, h, rgba):
    def chunk(tag, data):
        return struct.pack(">I", len(data)) + tag + data + struct.pack(">I", zlib.crc32(tag + data) & 0xffffffff)
    scan = b"".join(b"\0" + rgba[y * w * 4:(y + 1) * w * 4] for y in range(h))
    payload = (b"\x89PNG\r\n\x1a\n" + chunk(b"IHDR", struct.pack(">IIBBBBB", w, h, 8, 6, 0, 0, 0))
               + chunk(b"IDAT", zlib.compress(scan, 9)) + chunk(b"IEND", b""))
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_bytes(payload)


def put_block(out, width, x, y, color, alpha=255):
    r, g, b = color
    for dy in range(4):
        for dx in range(4):
            i = (((y * 4 + dy) * width) + x * 4 + dx) * 4
            out[i:i + 4] = bytes((r, g, b, alpha))


def buoy_colors(kind, red):
    if red:
        base = (226, 70, 64); shade = (173, 53, 52); mid = (236, 96, 78)
        light = (255, 151, 119); glint = (255, 228, 188)
    else:
        base = (250, 196, 60); shade = (187, 127, 29); mid = (239, 171, 43)
        light = (255, 222, 105); glint = (255, 244, 184)
    if kind == 0:
        return ((54, 58, 73), (82, 91, 112), (119, 127, 144), (148, 152, 160))
    if kind == 1:
        return (shade, base, mid, light)
    if kind == 2:
        return ((182, 174, 169), (220, 215, 207), (246, 242, 230), (255, 252, 244))
    if kind == 3:
        return (shade, base, light, glint)
    return (shade, base, light, glint)


def buoy_outline(kind, red):
    if kind == 0:
        return (43, 48, 62)
    if kind == 2:
        return (113, 88, 73)
    return (119, 43, 43) if red else (125, 82, 24)


def paint_buoy(color_name, red, kind):
    guide = GUIDES / f"buoy_{color_name}_{kind}_guide_4x.png"
    w, h, src = read_png(guide)
    if (w, h) != (56, 56):
        raise ValueError(f"unexpected buoy guide size {guide.name}: {w}x{h}")
    mask = [[False] * 14 for _ in range(14)]
    for y in range(14):
        for x in range(14):
            count = 0
            for dy in range(4):
                for dx in range(4):
                    i = (((y * 4 + dy) * w) + x * 4 + dx) * 4
                    if src[i + 3] >= 128 and tuple(src[i:i + 3]) != PINK:
                        count += 1
            mask[y][x] = count >= 8
    cols = buoy_colors(kind, red)
    outline = buoy_outline(kind, red)
    out = bytearray(w * h * 4)
    cx = 3.0 if kind == 4 else 3.5
    cy = 3.0 if kind == 4 else 3.5
    # The guide was authored at 7x7 then enlarged 2x; use its original center
    # in game coordinates, retaining its exact slice silhouette.
    cx *= 2; cy *= 2
    for y in range(14):
        for x in range(14):
            if not mask[y][x]:
                continue
            edge = any(not (0 <= x + dx < 14 and 0 <= y + dy < 14 and mask[y + dy][x + dx])
                       for dy in (-1, 0, 1) for dx in (-1, 0, 1) if dx or dy)
            if edge:
                color = outline
            else:
                # Light comes from upper left; the lower-right arc is the shade.
                lx, ly = x - cx, y - cy
                score = lx + ly
                dist = math.hypot(lx, ly)
                if kind == 0:
                    color = cols[3] if score < -2.5 else cols[2] if score < 0 else cols[1]
                elif kind == 2:
                    color = cols[3] if score < -6 else cols[2] if score < 1.5 else cols[0]
                elif kind == 4:
                    color = cols[3] if score < -1 else cols[2] if score < 1 else cols[1]
                else:
                    color = cols[3] if score < -2.5 else cols[2] if score < 0.5 else cols[1] if score < 2 else cols[0]
                    # A compact highlight on the lit cap/top, not a stripe.
                    if kind == 3 and x <= 8 and y <= 8 and dist < 2.2:
                        color = cols[3]
            alpha = 140 if kind == 0 else 255
            put_block(out, w, x, y, color, alpha)
    # The 1px registration marks are preserved exactly as on the guide. They
    # occupy only one pixel in their otherwise-transparent 4x4 cells.
    for x, y in ((0, 0), (55, 0), (0, 55), (55, 55)):
        i = (y * w + x) * 4
        out[i:i + 4] = bytes((*PINK, 255))
    name = PAINT / f"buoy_{color_name}_{kind}_4x.png"
    write_png(name, w, h, out)


def emit_grid(name, gw, gh, grid):
    w, h = gw * 4, gh * 4
    out = bytearray(w * h * 4)
    for y in range(gh):
        for x in range(gw):
            if grid[y][x] is not None:
                put_block(out, w, x, y, grid[y][x])
    write_png(PAINT / f"{name}_4x.png", w, h, out)


def pier_post():
    # A slender square-cut timber pile, end grain on top, bright upper-left edge.
    grid = [[None] * 6 for _ in range(16)]
    p = {
        "ink": (77, 47, 36), "deep": (91, 53, 38), "wood": (137, 82, 48),
        "mid": (174, 112, 62), "light": (211, 151, 84), "glint": (235, 190, 121),
    }
    rows = [
        [None, None, "ink", "ink", None, None],
        [None, "ink", "glint", "light", "ink", None],
        ["ink", "light", "mid", "mid", "deep", "ink"],
        ["ink", "light", "wood", "mid", "deep", "ink"],
        ["ink", "mid", "wood", "mid", "deep", "ink"],
        ["ink", "light", "mid", "wood", "deep", "ink"],
        ["ink", "mid", "wood", "mid", "deep", "ink"],
        ["ink", "light", "wood", "mid", "deep", "ink"],
        ["ink", "mid", "mid", "wood", "deep", "ink"],
        ["ink", "light", "wood", "mid", "deep", "ink"],
        ["ink", "mid", "wood", "mid", "deep", "ink"],
        ["ink", "light", "mid", "wood", "deep", "ink"],
        ["ink", "mid", "wood", "mid", "deep", "ink"],
        ["ink", "wood", "mid", "wood", "deep", "ink"],
        [None, "ink", "deep", "deep", "ink", None],
        [None, None, "deep", "deep", None, None],
    ]
    for y, row in enumerate(rows):
        for x, key in enumerate(row):
            if key:
                grid[y][x] = p[key]
    emit_grid("pier_post", 6, 16, grid)


def pier_foam(frame):
    # Flat elliptical lapping ring around the piling, with its center left clear.
    grid = [[None] * 14 for _ in range(4)]
    fringe = (252, 226, 202)
    foam = (255, 246, 234)
    shade = (228, 183, 158)
    cx = 6.5 + (0.35 if frame else 0.0)
    for y in range(4):
        for x in range(14):
            dx, dy = (x - cx) / 6.4, (y - 1.5) / 1.55
            outer = dx * dx + dy * dy
            inner = ((x - cx) / 3.1) ** 2 + ((y - 1.5) / 0.62) ** 2
            if outer <= 1.0 and inner >= 1.0:
                # Light upper-left lip; frame two shifts the bright foam around the ring.
                if (x + y + frame * 3) % 5 == 0:
                    grid[y][x] = shade
                elif y == 0 or (frame == 0 and x < 5) or (frame == 1 and x > 8):
                    grid[y][x] = foam
                else:
                    grid[y][x] = fringe
    emit_grid(f"pier_foam_{frame}", 14, 4, grid)


def main():
    for color_name, red in (("red", True), ("yellow", False)):
        for kind in range(5):
            paint_buoy(color_name, red, kind)
            print(f"painted buoy_{color_name}_{kind}_4x.png")
    pier_post()
    pier_foam(0)
    pier_foam(1)
    print("painted pier_post and pier_foam_0..1")


if __name__ == "__main__":
    main()
