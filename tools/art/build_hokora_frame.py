"""Build the restored forest frame baseline for NEW SHRINE."""
from pathlib import Path
import numpy as np
from PIL import Image, ImageDraw, ImageFilter

ROOT = Path(__file__).resolve().parents[2]
SOURCE = Path(__file__).resolve().parent / "shrine" / "chosen_front_frame_source.png"
DEST = ROOT / "textures" / "pet" / "shrine_new"
GRID = 160
PIXELS = 925
ROOM_OPEN = (31, 33, 80, 77)
OPEN = tuple(round(v * GRID / 110) for v in ROOM_OPEN)


def main():
    source = Image.open(SOURCE).convert("RGBA")
    small = source.resize((GRID, round(100 * GRID / 110)), Image.Resampling.NEAREST)
    raw = Image.new("RGBA", (GRID, GRID), (0, 0, 0, 0))
    raw.alpha_composite(small, (1, 0))

    # Restrained palette reduction and the pale wash used in the earlier phone preview.
    # Remove near-transparent source residue before building any depth silhouettes.
    # Pixel-art edges use binary coverage; faint background specks must not become outlines.
    alpha = raw.getchannel("A").point(lambda a: 255 if a >= 128 else 0)
    rgb = raw.convert("RGB").quantize(colors=28, method=Image.Quantize.FASTOCTREE).convert("RGB")
    pixels = np.asarray(rgb).astype(np.float32)
    lum = pixels @ np.array([0.299, 0.587, 0.114], dtype=np.float32)
    pale = np.array([238.0, 223.0, 201.0], dtype=np.float32)
    pixels[lum > 72] = pixels[lum > 72] * 0.86 + pale * 0.14
    source_art = Image.fromarray(np.clip(pixels, 0, 255).astype(np.uint8), "RGB").convert("RGBA")
    source_art.putalpha(alpha)

    def gx(v):
        return round(v * GRID / 110)

    x0, y0, x1, y1 = OPEN
    # Preserve the complete selected front art as supplied.
    front = source_art.copy()

    DEST.mkdir(parents=True, exist_ok=True)
    front = front.resize((PIXELS, PIXELS), Image.Resampling.NEAREST)
    front.save(DEST / "front.png", optimize=True)
    # Restore the previous migration interior. Keep the stone shelf and offering table assets.
    original_inside = Image.open(ROOT / "textures" / "pet" / "shrine" / "inside.png").convert("RGBA")
    original_inside.save(DEST / "inside.png", optimize=True)

    # Low-detail side material sampled from the shell itself. The restored
    # baseline extrudes the complete front silhouette, as it did before the shell experiment.
    side_rgb = front.convert("RGB").filter(ImageFilter.BoxBlur(18))
    gray = side_rgb.convert("L").convert("RGB")
    side_rgb = Image.blend(side_rgb, gray, 0.38).point(lambda p: round(p * 0.78))
    side = side_rgb.convert("RGBA")
    # Roof depth is a quiet, continuous material, not repeated front-tile bands.
    # Close single-cell nicks on the depth silhouette while retaining pixel steps.
    roof_end = round(32 * PIXELS / 110)
    depth_alpha = front.getchannel("A")
    small_alpha = source_art.getchannel("A")
    regular = small_alpha.filter(ImageFilter.MaxFilter(3)).filter(ImageFilter.MinFilter(3))
    regular = regular.resize((PIXELS, PIXELS), Image.Resampling.NEAREST)
    depth_alpha.paste(regular.crop((0, 0, PIXELS, roof_end)), (0, 0))
    side.paste((111, 76, 62, 255), (0, 0, PIXELS, roof_end))
    side.putalpha(depth_alpha)
    # The back silhouette gets a crisp outline while retaining the exact shell aperture.
    eroded = depth_alpha.filter(ImageFilter.MinFilter(13))
    edge_mask = Image.fromarray((np.asarray(depth_alpha) > np.asarray(eroded)).astype(np.uint8) * 255, "L")
    back = side.copy()
    dark = Image.new("RGBA", front.size, (54, 35, 45, 255))
    back.paste(dark, mask=edge_mask)
    back.putalpha(depth_alpha)
    # First wall-only structural pass: the front roots/leaves stay on their
    # existing sprite. Only straight wall posts and the structural plinth run
    # through the depth. Preserve the already-approved roof depth byte for byte.
    shell = Image.new("RGBA", (GRID, GRID), (0, 0, 0, 0))
    draw = ImageDraw.Draw(shell)
    wall_color = (116, 82, 68, 255)
    base_color = (102, 69, 56, 255)
    def block(bounds, color):
        a, b, c, d = (gx(v) for v in bounds)
        draw.rectangle((a, b, c - 1, d - 1), fill=color)
    block((24, 32, 31, 86), wall_color)
    block((80, 32, 87, 86), wall_color)
    block((24, 32, 87, 33), wall_color)
    block((20, 84, 91, 94), base_color)
    block((25, 94, 34, 98), base_color)
    block((77, 94, 86, 98), base_color)
    shell = shell.resize((PIXELS, PIXELS), Image.Resampling.NEAREST)
    shell_alpha = shell.getchannel("A")
    shell_eroded = shell_alpha.filter(ImageFilter.MinFilter(13))
    shell_edge = Image.fromarray((np.asarray(shell_alpha) > np.asarray(shell_eroded)).astype(np.uint8) * 255, "L")
    shell_back = shell.copy()
    shell_back.paste(dark, mask=shell_edge)
    shell_back.putalpha(shell_alpha)
    lower = (0, roof_end, PIXELS, PIXELS)
    side.paste(shell.crop(lower), (0, roof_end))
    back.paste(shell_back.crop(lower), (0, roof_end))
    side.save(DEST / "side.png", optimize=True)
    back.save(DEST / "side_back.png", optimize=True)
    print(f"Wrote restored forest frame to {DEST} (room {OPEN})")


if __name__ == "__main__":
    main()
