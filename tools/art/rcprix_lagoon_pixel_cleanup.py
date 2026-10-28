"""Snap the current Round 2 Lagoon paintings to the game's 4x pixel grid.

Keeps each source alpha silhouette, maps each game pixel to a small, explicit
material palette, adds a single-pixel dark perimeter, then replicates each pixel
to a hard 4x4 block. No external imaging package is required.
"""
from pathlib import Path
import runpy

ROOT = Path(__file__).resolve().parents[2]
PAINT = ROOT / "docs/mockups/rcprix_lagoon/round2_paint"
read_png = runpy.run_path(str(ROOT / "tools/art/lagoon_round2_export.py"))["read_png"]

PALETTES = {
    "shell": ["281E28", "98584B", "C77B63", "E7A082", "F3C7A4", "FFF0D4"],
    "pebble": ["281E28", "69564F", "90796D", "B19A86", "D2BBA1", "F1E0C7"],
    "starfish": ["281E28", "AD454C", "D36561", "E98672", "F4B18D", "FFE0B5"],
    "seagrass": ["281E28", "4E5E3B", "6F7D43", "8C9650", "AFAC66", "E7CE83"],
    "palm": ["281E28", "294A35", "3F6841", "5A7D47", "77914F", "9EAA61",
             "70452F", "95603A", "B77B47", "D5A35D"],
    "rock": ["281E28", "62504D", "79645D", "958077", "B09B8C", "CBB7A5", "E4D3BC", "F4E7D2"],
}
ISLAND = {
    "outline": "281E28",
    "soil": ["4B302B", "704633", "95603E"],
    "sand": ["C59455", "DDB76F", "EED08A", "F7DDA0"],
    "grass": ["3D5034", "53663A", "6C7A42", "82904B", "9CA05A"],
}


def rgb(hexstr):
    return tuple(bytes.fromhex(hexstr))


def nearest(color, palette):
    return min(palette, key=lambda p: sum((color[i] - p[i]) ** 2 for i in range(3)))


def palette_for(color, material):
    if material != "island":
        return nearest(color, [rgb(c) for c in PALETTES[material][1:]])
    r, g, b = color
    lum = (r * 3 + g * 6 + b) / 10
    # Separate the original artwork's three painted materials before snapping:
    # green crown, pale beach, and the darker cut-earth underside.
    if lum < 125 and r > g * 1.18 and b < g * .9:
        group = ISLAND["soil"]
    elif g >= r * .86 and g > b * 1.12:
        group = ISLAND["grass"]
    elif lum < 148 and r > g * 1.18 and b < g * .85:
        group = ISLAND["soil"]
    else:
        group = ISLAND["sand"]
    return nearest(color, [rgb(c) for c in group])


def main():
    # These four models were already accepted and remain pixel-exact as delivered.
    preserve = {"starfish_4x.png", "starfish_b_4x.png", "seagrass_4x.png", "seagrass_b_4x.png"}
    for path in sorted(PAINT.glob("*_4x.png")):
        if path.name in preserve:
            continue
        w, h, src = read_png(path)
        if w % 4 or h % 4:
            raise ValueError(f"{path.name} is not 4x aligned ({w}x{h})")
        gw, gh = w // 4, h // 4
        material = path.name.split("_", 1)[0]
        if material not in PALETTES and material != "island":
            raise ValueError(f"No pixel palette for {path.name}")
        mask = [[False] * gw for _ in range(gh)]
        colors = [[(0, 0, 0)] * gw for _ in range(gh)]
        for y in range(gh):
            for x in range(gw):
                samples = []
                for dy in range(4):
                    for dx in range(4):
                        i = (((y * 4 + dy) * w) + x * 4 + dx) * 4
                        if src[i + 3] >= 128:
                            samples.append(tuple(src[i:i + 3]))
                if len(samples) >= 8:
                    mask[y][x] = True
                    colors[y][x] = tuple(sum(c[k] for c in samples) // len(samples) for k in range(3))
        grid = [[None] * gw for _ in range(gh)]
        for y in range(gh):
            for x in range(gw):
                if not mask[y][x]:
                    continue
                edge = any(not (0 <= x + dx < gw and 0 <= y + dy < gh and mask[y + dy][x + dx])
                           for dy in (-1, 0, 1) for dx in (-1, 0, 1) if dx or dy)
                if edge:
                    grid[y][x] = rgb("281E28")
                else:
                    grid[y][x] = palette_for(colors[y][x], material)
        out = bytearray(w * h * 4)
        for y in range(gh):
            for x in range(gw):
                c = grid[y][x]
                if c is None:
                    continue
                for dy in range(4):
                    for dx in range(4):
                        i = (((y * 4 + dy) * w) + x * 4 + dx) * 4
                        out[i:i + 3] = bytes(c)
                        out[i + 3] = 255
        path.write_bytes(encode_png(w, h, out))
        used = len({grid[y][x] for y in range(gh) for x in range(gw) if grid[y][x] is not None})
        print(f"snapped {path.name}: {gw}x{gh} game pixels, {used} palette colours")


def encode_png(w, h, px):
    import struct, zlib
    def chunk(tag, data):
        return struct.pack(">I", len(data)) + tag + data + struct.pack(">I", zlib.crc32(tag + data) & 0xffffffff)
    scan = b"".join(b"\0" + px[y * w * 4:(y + 1) * w * 4] for y in range(h))
    return (b"\x89PNG\r\n\x1a\n" + chunk(b"IHDR", struct.pack(">IIBBBBB", w, h, 8, 6, 0, 0, 0))
            + chunk(b"IDAT", zlib.compress(scan, 9)) + chunk(b"IEND", b""))


if __name__ == "__main__":
    main()
