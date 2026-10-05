"""Builds the app icon: Picklet (the sour baby) on the pet screen's pink.

    <python with Pillow + numpy> tools/design/app_icon.py [preview.png]

Writes icon.png (1024x1024, opaque as iOS requires; project.godot's config/icon points
here, and the iOS export generates every icon size from it)."""
import sys
from pathlib import Path

import numpy as np
from PIL import Image, ImageDraw, ImageFilter

ROOT = Path(__file__).resolve().parents[2]
SIZE = 1024
PINK = (229, 165, 166)                     # textures/pet-background/background.png
PINK_TOP = (238, 184, 184)
SHADOW = (180, 110, 116)


def main():
    pal = Image.open(ROOT / "textures/pet/forms/picklet-1.png").convert("RGBA")
    pal = pal.crop(pal.getbbox())
    # the form sheets are art pixels doubled: back to art res, then whole-number upscale
    art = pal.resize((pal.width // 2, pal.height // 2), Image.NEAREST)
    k = int(SIZE * 0.66) // art.width
    big = art.resize((art.width * k, art.height * k), Image.NEAREST)

    # soft vertical gradient in the pet-screen pink
    t = np.linspace(0, 1, SIZE)[:, None, None]
    grad = (np.array(PINK_TOP) * (1 - t) + np.array(PINK) * t).repeat(SIZE, 1)
    icon = Image.fromarray(grad.astype(np.uint8), "RGB").convert("RGBA")

    x = (SIZE - big.width) // 2
    y = (SIZE - big.height) // 2 + 40
    # ground shadow
    sh = Image.new("RGBA", (SIZE, SIZE), (0, 0, 0, 0))
    ImageDraw.Draw(sh).ellipse((x + 60, y + big.height - 50, x + big.width - 60, y + big.height + 40), fill=SHADOW + (150,))
    icon.alpha_composite(sh.filter(ImageFilter.GaussianBlur(18)))
    icon.alpha_composite(big, (x, y))
    icon.convert("RGB").save(ROOT / "icon.png")

    if len(sys.argv) > 1:   # how it looks on the home screen (rounded mask)
        m = Image.new("L", (SIZE, SIZE), 0)
        ImageDraw.Draw(m).rounded_rectangle((0, 0, SIZE - 1, SIZE - 1), radius=225, fill=255)
        prev = Image.new("RGBA", (SIZE, SIZE), (0, 0, 0, 0))
        prev.paste(icon, (0, 0), m)
        board = Image.new("RGBA", (560, 300), (30, 30, 34, 255))
        for i, s in enumerate((240, 120, 60)):
            board.alpha_composite(prev.resize((s, s), Image.LANCZOS), (20 + sum((240, 120, 60)[:i]) + 30 * i, 30))
        board.save(sys.argv[1])
    print("wrote icon.png")


if __name__ == "__main__":
    main()
