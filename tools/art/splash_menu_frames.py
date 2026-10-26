"""Splash Hoops' world-menu level frames, from the designer's atlas
(docs/mockups/splash_hoops_world_menu/tile_frame_atlas.png: 3 x 4, normal lagoon / sunset / reef,
normal night / storm / deep, then the selected ones in the same order) to game pieces at the art's own
pixel size (~4.33 atlas px each; the game draws them x3, 9-sliced to the level cell):

    <python with Pillow + numpy + scipy> tools/art/splash_menu_frames.py

writes textures/minigames/splash/menu/frame_<world>.png and frame_<world>_sel.png. Each frame is
sampled at its pixels' centres (no blending), the soft glow round the selected ones dropped (alpha
kept only where solid) - the selection reads from its gold rim and sparks."""
from pathlib import Path

import numpy as np
from PIL import Image
from scipy import ndimage

ROOT = Path(__file__).resolve().parents[2]
ATLAS = ROOT / "docs" / "mockups" / "splash_hoops_world_menu" / "tile_frame_atlas.png"
OUT = ROOT / "textures" / "minigames" / "splash" / "menu"
WORLDS = ["lagoon", "sunset", "reef", "night", "storm", "deep"]
PX = 4.33


def main():
    a = np.asarray(Image.open(ATLAS).convert("RGBA"))
    lab, _ = ndimage.label(a[..., 3] > 128)
    boxes = [sl for sl in ndimage.find_objects(lab) if (sl[0].stop - sl[0].start) * (sl[1].stop - sl[1].start) > 20000]
    boxes.sort(key=lambda sl: (round(sl[0].start / 100), sl[1].start))
    OUT.mkdir(parents=True, exist_ok=True)
    for i, sl in enumerate(boxes):
        f = a[sl]
        w, h = round(f.shape[1] / PX), round(f.shape[0] / PX)
        ys = np.clip(((np.arange(h) + 0.5) * f.shape[0] / h).astype(int), 0, f.shape[0] - 1)
        xs = np.clip(((np.arange(w) + 0.5) * f.shape[1] / w).astype(int), 0, f.shape[1] - 1)
        s = f[ys][:, xs].copy()
        s[..., 3] = np.where(s[..., 3] > 200, 255, 0)
        name = WORLDS[i % 6] + ("_sel" if i >= 6 else "")
        Image.fromarray(s, "RGBA").save(OUT / f"frame_{name}.png")
        print(name, s.shape[1], "x", s.shape[0])


if __name__ == "__main__":
    main()
