"""Assemble front and rear stands from the delivered sprites for visual review."""
from pathlib import Path

from PIL import Image

ROOT = Path(__file__).resolve().parents[2]
ART = ROOT / "textures/minigames/rcprix/garden"
OUT = ROOT / "docs/mockups/rcprix_garden"


def assemble(view):
    pieces = ("end_a", "mid", "mid", "mid", "end_b")
    base_parts = [Image.open(ART / f"stand_{view}_under_{part}.png").convert("RGBA") for part in pieces]
    top_parts = [Image.open(ART / f"stand_{view}_over_{part}.png").convert("RGBA") for part in pieces]
    if any(a.size != b.size for a, b in zip(base_parts, top_parts)):
        raise ValueError(f"{view}: under/over piece sizes do not match")
    base = Image.new("RGBA", (sum(p.width for p in base_parts), 107))
    top = Image.new("RGBA", base.size)
    x = 0
    for under, over in zip(base_parts, top_parts):
        base.alpha_composite(under, (x, 0))
        top.alpha_composite(over, (x, 0))
        x += under.width
    base.alpha_composite(top)
    return base.resize((base.width * 3, base.height * 3), Image.Resampling.NEAREST)


def main():
    OUT.mkdir(parents=True, exist_ok=True)
    for view in ("front", "back"):
        image = assemble(view)
        page = Image.new("RGBA", image.size, (51, 49, 52, 255))
        page.alpha_composite(image)
        path = OUT / f"stand_{view}_final_3x.png"
        page.save(path)
        print(path)


if __name__ == "__main__":
    main()
