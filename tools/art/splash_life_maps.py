"""Splash Hoops: each world's "life map" for its moving background (scripts/shaders/splash_world_life.gdshader;
the user, 2026-10-26: the backgrounds should move, each in its own way, keeping their look).

    <python with Pillow + numpy + scipy> tools/art/splash_life_maps.py

Reads textures/minigames/splash/new_shrine/<world>.png, lays it out exactly as the game's back panel
(SplashArt.tank_layers: the picture fitted under the top band, MARGIN px past every edge) and writes
textures/minigames/splash/new_shrine/life/<world>.png, the panel's size, one channel each:
  R  how far up its plant a pixel is (0 = not near a plant; 1..255 base to tip): the sway grows with it
  G  a light line of the painted caustics on the floor (they ripple and a glint runs along them)
  B  255 a plant's pixel (a leaf or its dark outline), 128 a glowing speck (stars, plankton, glowing coral,
     bubbles: they twinkle or pulse)
The plants are found by colour inside each world's PLANTS boxes (panel px), one plant per connected
blob (its base its lowest pixel, or its top for one hanging from the panel's top)."""
from pathlib import Path

import numpy as np
from PIL import Image
from scipy import ndimage

ROOT = Path(__file__).resolve().parents[2]
ART = ROOT / "textures" / "minigames" / "splash" / "new_shrine"
W, H, MARGIN, BAND = 317, 316, 20, 104.0 / 3.0

# panel px boxes (x0, y0, x1, y1) where the seaweed is; "glow": which specks twinkle; "caustics": the floor's light web
WORLDS = {
    "lagoon": {"plants": [(19, 127, 57, 176), (52, 200, 84, 238), (20, 240, 61, 282), (306, 150, 337, 187),
                          (310, 207, 337, 246), (274, 252, 313, 300)], "glow": None, "caustics": True},
    "sunset": {"plants": [(15, 155, 150, 336), (225, 180, 345, 336)], "glow": None, "caustics": False, "dark_leaves": True},
    "reef": {"plants": [(55, 205, 110, 300), (255, 205, 320, 310), (20, 160, 60, 200)], "glow": "bubbles", "caustics": False},
    "night": {"plants": [(15, 185, 135, 336), (225, 205, 345, 336)], "glow": "night", "caustics": False, "dark_leaves": True, "leaf_hue": 180},
    "storm": {"plants": [(10, 135, 135, 336), (235, 145, 345, 336)], "glow": "bubbles", "glow_below": 150, "caustics": False},
    "deep": {"plants": [(20, 95, 115, 280), (255, 0, 345, 280)], "glow": "cyan", "caustics": False},
}


def panel(world):
    src = np.asarray(Image.open(ART / f"{world}.png").convert("RGB"))
    ys = np.clip(np.floor((np.arange(-MARGIN, H + MARGIN) - BAND) / (H - BAND) * src.shape[0] + 0.5).astype(int), 0, src.shape[0] - 1)
    xs = np.clip(np.arange(-MARGIN, W + MARGIN), 0, W - 1)
    return src[ys][:, xs].astype(float) / 255.0


def hsv(a):
    mx, mn = a.max(-1), a.min(-1)
    d = np.where(mx - mn == 0, 1e-6, mx - mn)
    r, g, b = a[..., 0], a[..., 1], a[..., 2]
    h = np.where(mx == r, (g - b) / d % 6, np.where(mx == g, (b - r) / d + 2, (r - g) / d + 4)) * 60
    return h, (mx - mn) / np.maximum(mx, 1e-6), mx


def plants(a, boxes, dark_leaves=False, leaf_hue=150):
    h, s, v = hsv(a)
    leaf = (h > 45) & (h < leaf_hue) & (s > 0.28) & (v > (0.14 if dark_leaves else 0.22)) & (v < 0.9)
    box = np.zeros(leaf.shape, bool)
    for x0, y0, x1, y1 in boxes:
        box[y0:y1, x0:x1] = True
    leaf &= box
    dark = (v < 0.3) & box & ndimage.binary_dilation(leaf, iterations=1)
    plant = leaf | dark
    up = np.zeros(leaf.shape)
    lab, n = ndimage.label(plant, structure=np.ones((3, 3)))
    for i, sl in enumerate(ndimage.find_objects(lab), 1):
        hgt = sl[0].stop - sl[0].start
        wid = sl[1].stop - sl[1].start
        if hgt < 12 or hgt < wid * 0.8:                 # (moss on a rock, a lily pad: wider than tall)
            plant[lab == i] = False                 # (moss and specks: they stay still)
            continue
        ys = np.arange(sl[0].start, sl[0].stop)[:, None]
        hanging = sl[0].start <= MARGIN + 2
        f = (ys - sl[0].start) / hgt if hanging else (sl[0].stop - ys) / hgt
        y0, y1 = max(sl[0].start - 3, 0), min(sl[0].stop + 3, up.shape[0])
        x0, x1 = max(sl[1].start - 4, 0), min(sl[1].stop + 4, up.shape[1])
        ys2 = np.arange(y0, y1)[:, None]
        f2 = np.clip((ys2 - sl[0].start) / hgt if hanging else (sl[0].stop - ys2) / hgt, 0.0, 1.0)
        up[y0:y1, x0:x1] = np.maximum(up[y0:y1, x0:x1], np.broadcast_to(np.maximum(f2, 1e-3), (y1 - y0, x1 - x0)))
    return plant, up


def glow(a, kind, below=0):
    h, s, v = hsv(a)
    lum = a @ [0.3, 0.59, 0.11]
    local = ndimage.uniform_filter(lum, 7)
    if kind == "night":                           # stars in the sky, the plankton's yellow dots
        m = ((lum - local > 0.18) & (lum > 0.6)) | ((h > 40) & (h < 70) & (s > 0.4) & (v > 0.7) & (lum - local > 0.12))
    elif kind == "cyan":                          # the glowing corals and the bubbles
        m = (h > 165) & (h < 200) & (s > 0.4) & (v > 0.6)
    elif kind == "bubbles":                       # the bubbles' light rims
        m = (lum - local > 0.12) & (lum > 0.55) & (s < 0.45)
    else:
        return np.zeros(lum.shape, bool)
    lab, n = ndimage.label(m)
    sizes = ndimage.sum(m, lab, range(1, n + 1))
    keep = np.isin(lab, np.nonzero(sizes <= 6)[0] + 1)         # (specks only: not a cloud's or a wave's edge)
    keep[:max(MARGIN + 2, below)] = False
    return keep & m


def caustics(a, plant):
    r, g = a[..., 0], a[..., 1]
    lum = a @ [0.3, 0.59, 0.11]
    line = (lum - ndimage.uniform_filter(lum, 7) > 0.03) & (r - ndimage.uniform_filter(r, 7) > 0.04)
    rock = ndimage.binary_dilation((r > g + 0.02) | (lum < 0.3), iterations=1)
    line &= ~plant & ~rock
    line[:58] = False
    line[:, :MARGIN] = False
    line[:, -MARGIN:] = False
    return ndimage.binary_opening(line, structure=np.ones((1, 2))) | ndimage.binary_opening(line, structure=np.ones((2, 1)))


def main():
    (ART / "life").mkdir(exist_ok=True)
    for world, cfg in WORLDS.items():
        a = panel(world)
        plant, up = plants(a, cfg["plants"], cfg.get("dark_leaves", False), cfg.get("leaf_hue", 150))
        out = np.zeros(a.shape[:2] + (4,), np.uint8)
        out[..., 3] = 255
        out[..., 0] = np.where(up > 0, 1 + np.round(up * 254), 0).astype(np.uint8)
        if cfg["caustics"]:
            out[..., 1] = caustics(a, plant) * 255
        out[..., 2] = np.where(plant, 255, np.where(glow(a, cfg["glow"], cfg.get("glow_below", 0)) & ~plant, 128, 0)).astype(np.uint8)
        Image.fromarray(out, "RGBA").save(ART / "life" / f"{world}.png")
        print(world, "plant px", int(plant.sum()), "glow px", int((out[..., 2] == 128).sum()))


if __name__ == "__main__":
    main()
