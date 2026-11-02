"""A home's side-window glass (the user, 2026-11-02: the Capsule's shelf objects inside its windows, behind
the glass): its windows are painted on the front, so the objects stand on the window floors over the
front and this pane goes over them: light see-through glass with two highlight lines, on the 925 canvas;
then window_rim.png, the front's own frame round each window (and the window floor's lip), drawn over
both, so the objects sit inside the windows, behind the pod's first layer and the glass (the user).
textures/pet/homes/<home>/side_glass.png, window_rim.png (Shrine: HOMES "shelf_glass").

Run: .venv/bin/python tools/art/side_glass.py
"""
import numpy as np
from PIL import Image, ImageDraw
from scipy import ndimage

RIM = 70                                  # px of the front round each window copied over the objects

WINDOWS = {"capsule_apartment": [(124, 264, 252, 558), (673, 264, 801, 558)]}   # (x0, y0, x1, y1), 925 px

for home, rects in WINDOWS.items():
    im = Image.new("RGBA", (925, 925))
    d = ImageDraw.Draw(im)
    for x0, y0, x1, y1 in rects:
        d.rounded_rectangle((x0, y0, x1, y1), radius=26, fill=(214, 236, 240, 70))
        for k, (dx, w) in enumerate(((18, 8), (40, 4))):             # (the shine: two slanted lines)
            for t in range(0, 70, 2):
                x, y = x0 + dx + t * 0.6, y0 + 40 + t * 2
                d.rectangle((x, y, x + w, y + 2), fill=(255, 255, 255, 120 - k * 40))
    im.save("textures/pet/homes/%s/side_glass.png" % home)
    win = Image.new("L", (925, 925))
    for x0, y0, x1, y1 in rects:
        ImageDraw.Draw(win).rounded_rectangle((x0, y0, x1, y1), radius=26, fill=255)
    inner = np.array(win) > 0
    band = ndimage.binary_dilation(inner, iterations=RIM) & ~inner
    front = np.array(Image.open("textures/pet/homes/%s/front.png" % home).convert("RGBA"))
    front[~band] = 0
    Image.fromarray(front, "RGBA").save("textures/pet/homes/%s/window_rim.png" % home)
    print(home)
