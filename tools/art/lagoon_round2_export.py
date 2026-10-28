"""Crop generated Round 2 Lagoon sprite studies onto their final 4x pixel grids.

This only performs hard-alpha cleanup, cropping and nearest-neighbour sizing. It does
not draw or recolor artwork. Run from the repository root after putting the source
atlases in docs/mockups/rcprix_lagoon/round2_paint/source_atlases/.
"""
from __future__ import annotations

import math
import struct
import zlib
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
PAINT = ROOT / "docs/mockups/rcprix_lagoon/round2_paint"
SRC = PAINT / "source_atlases"


def read_png(path: Path):
    raw = path.read_bytes()
    if raw[:8] != b"\x89PNG\r\n\x1a\n":
        raise ValueError(f"not PNG: {path}")
    pos, chunks, width, height, depth, ctype = 8, [], None, None, None, None
    while pos < len(raw):
        n = struct.unpack(">I", raw[pos:pos + 4])[0]
        typ = raw[pos + 4:pos + 8]
        dat = raw[pos + 8:pos + 8 + n]
        pos += n + 12
        if typ == b"IHDR":
            width, height, depth, ctype, comp, filt, inter = struct.unpack(">IIBBBBB", dat)
            if depth != 8 or ctype != 6 or inter != 0:
                raise ValueError(f"expected non-interlaced 8-bit RGBA PNG: {path}")
        elif typ == b"IDAT":
            chunks.append(dat)
        elif typ == b"IEND":
            break
    bpp = 4
    scan = zlib.decompress(b"".join(chunks))
    stride = width * bpp
    pixels = bytearray(height * stride)
    p = 0
    for y in range(height):
        ft = scan[p]; p += 1
        row = bytearray(scan[p:p + stride]); p += stride
        prev = pixels[(y - 1) * stride:y * stride] if y else bytearray(stride)
        for x in range(stride):
            a = row[x - bpp] if x >= bpp else 0
            b = prev[x]
            c = prev[x - bpp] if x >= bpp else 0
            if ft == 1: row[x] = (row[x] + a) & 255
            elif ft == 2: row[x] = (row[x] + b) & 255
            elif ft == 3: row[x] = (row[x] + ((a + b) >> 1)) & 255
            elif ft == 4:
                q = a + b - c
                pa, pb, pc = abs(q - a), abs(q - b), abs(q - c)
                pr = a if pa <= pb and pa <= pc else b if pb <= pc else c
                row[x] = (row[x] + pr) & 255
            elif ft != 0: raise ValueError(f"unsupported PNG filter {ft}")
        pixels[y * stride:(y + 1) * stride] = row
    return width, height, pixels


def write_png(path: Path, w: int, h: int, px: bytearray):
    def chunk(tag, data):
        return struct.pack(">I", len(data)) + tag + data + struct.pack(">I", zlib.crc32(tag + data) & 0xffffffff)
    scan = b"".join(b"\0" + px[y * w * 4:(y + 1) * w * 4] for y in range(h))
    data = b"\x89PNG\r\n\x1a\n" + chunk(b"IHDR", struct.pack(">IIBBBBB", w, h, 8, 6, 0, 0, 0))
    data += chunk(b"IDAT", zlib.compress(scan, 9)) + chunk(b"IEND", b"")
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_bytes(data)


def export_region(image: Path, name: str, region, game_size, pad=0.94, threshold=176):
    w, h, px = read_png(image)
    x0, y0, x1, y1 = region
    x0, y0, x1, y1 = max(0, x0), max(0, y0), min(w, x1), min(h, y1)
    pts = [(x, y) for y in range(y0, y1) for x in range(x0, x1)
           if px[(y * w + x) * 4 + 3] >= threshold]
    if not pts:
        raise ValueError(f"no opaque artwork in {image.name} region {region}")
    bx0, bx1 = min(x for x, _ in pts), max(x for x, _ in pts) + 1
    by0, by1 = min(y for _, y in pts), max(y for _, y in pts) + 1
    cropw, croph = bx1 - bx0, by1 - by0
    gw, gh = game_size
    ow, oh = gw * 4, gh * 4
    iw, ih = max(1, round(ow * pad)), max(1, round(oh * pad))
    # Fit while retaining proportions; all enlargement is nearest-neighbour.
    scale = min(iw / cropw, ih / croph)
    nw, nh = max(1, round(cropw * scale)), max(1, round(croph * scale))
    ox, oy = (ow - nw) // 2, (oh - nh) // 2
    out = bytearray(ow * oh * 4)
    for dy in range(nh):
        sy = by0 + min(croph - 1, dy * croph // nh)
        for dx in range(nw):
            sx = bx0 + min(cropw - 1, dx * cropw // nw)
            si, di = (sy * w + sx) * 4, ((oy + dy) * ow + ox + dx) * 4
            a = px[si + 3]
            if a >= threshold:
                # Generated PNGs are premultiplied at soft edges; unpremultiply before
                # making every retained pixel fully opaque.
                out[di:di + 3] = bytes(min(255, round(px[si + c] * 255 / a)) for c in range(3))
                out[di + 3] = 255
    write_png(PAINT / f"{name}_4x.png", ow, oh, out)
    print(f"{name}: {ow}x{oh} (game {gw}x{gh}), source crop {cropw}x{croph}")


def main():
    # Atlas cells; objects are centered in the four quadrants.
    quads = lambda w, h: [(0, 0, w//2, h//2), (w//2, 0, w, h//2),
                          (0, h//2, w//2, h), (w//2, h//2, w, h)]
    shells = SRC / "shells.png"
    sw, sh, _ = read_png(shells)
    for name, region, size in zip(("shell", "shell_b", "shell_c", "shell_d"), quads(sw, sh),
                                  ((14, 12), (12, 12), (14, 10), (6, 6))):
        export_region(shells, name, region, size)
    stones = SRC / "pebbles.png"
    pw, ph, _ = read_png(stones)
    for name, region, size in zip(("pebble", "pebble_b", "pebble_c", "pebble_d"), quads(pw, ph),
                                  ((10, 8), (14, 8), (12, 10), (14, 12))):
        export_region(stones, name, region, size)
    islands = SRC / "islands.png"
    iw, ih, _ = read_png(islands)
    for name, region, size in zip(("island_a", "island_b", "island_c", "island_d"), quads(iw, ih),
                                  ((90, 50), (120, 64), (150, 80), (180, 70))):
        export_region(islands, name, region, size, pad=0.98)
    palms = SRC / "palm_rocks.png"
    rw, rh, _ = read_png(palms)
    for name, region, size in (("palm_b", (0, 0, rw//2, rh), (30, 40)),
                               ("rock_a", (rw//2, 0, int(rw*.69), rh), (14, 10)),
                               ("rock_b", (int(rw*.69), 0, rw, rh), (22, 14))):
        export_region(palms, name, region, size)
    export_region(SRC / "starfish_c.png", "starfish_c", (0, 0, 1312, 1199), (18, 16))
    export_region(SRC / "seagrass_c.png", "seagrass_c", (0, 0, 1313, 1198), (12, 14))

    # Preserve the two approved models each, verbatim, as the starting set for this round.
    for srcname, outname in (("starfish_4x.png", "starfish_4x.png"),
                             ("starfish_b_4x.png", "starfish_b_4x.png"),
                             ("seagrass_4x.png", "seagrass_4x.png"),
                             ("seagrass_b_4x.png", "seagrass_b_4x.png")):
        source = ROOT / "docs/mockups/rcprix_lagoon/round1c_paint" / srcname
        (PAINT / outname).write_bytes(source.read_bytes())
        print(f"kept approved {outname}")


if __name__ == "__main__":
    main()
