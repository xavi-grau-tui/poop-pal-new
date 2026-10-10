"""Art for the trial bottom-button layout (scripts/console_layout.gd, NEW_BUTTONS): the forward button
as a square like the orange one (normal + pressed, the forward button's own cream, its >> sign) and a
7-column speaker grill. Then the device picture for the box with that layout
(textures/unboxing/box/device_newbuttons.png), placed exactly like console_layout.gd places them.

    <python with Pillow + numpy> tools/design/console_buttons_new.py
"""
import numpy as np
from PIL import Image

B = "textures/buttons/"
lum = lambda c: 0.299 * c[..., 0] + 0.587 * c[..., 1] + 0.114 * c[..., 2]

def square(main_path, fwd_path, out_path):
    main = Image.open(main_path).convert("RGBA"); fwd = Image.open(fwd_path).convert("RGBA")
    m = np.asarray(main).astype(float); f = np.asarray(fwd).astype(float)
    orange = (m[..., 0] - m[..., 2] > 40) & (m[..., 3] > 0)
    ys, xs = np.where(orange)
    face_c = (int((xs.min() + xs.max()) / 2), int((ys.min() + ys.max()) / 2))
    L = lum(m[..., :3]) / lum(m[face_c[1], face_c[0], :3])
    # the forward button's face colour: its most common light colour (a single sample can hit a shadow)
    px = f[(f[..., 3] > 200) & (f[..., 0] > 150)][:, :3].astype(int)
    vals, counts = np.unique(px, axis=0, return_counts=True)
    cream = vals[counts.argmax()].astype(float)
    out = m.copy(); out[orange, :3] = np.clip(cream[None, :] * L[orange][:, None], 0, 255)
    sq = Image.fromarray(out.astype(np.uint8), "RGBA")
    sign = Image.open(B + "logoforward.png").convert("RGBA")
    s2 = sign.resize((round(sign.width * 1.9), round(sign.height * 1.9)), Image.NEAREST)
    sq.alpha_composite(s2, (face_c[0] - s2.width // 2, face_c[1] - s2.height // 2))
    sq.save(out_path)

square(B + "mainbuttonnormal.png", B + "forwardbuttonnormal.png", B + "forwardsquarenormal.png")
# pressed: like the game's other pressed buttons, the normal one darkened by a flat amount (the
# forward button's pressed face is exactly 120 darker on every channel)
n = np.asarray(Image.open(B + "forwardsquarenormal.png").convert("RGBA")).astype(int)
pr = n.copy(); pr[..., :3] = np.clip(n[..., :3] - 120, 0, 255)
Image.fromarray(pr.astype(np.uint8), "RGBA").save(B + "forwardsquarepressed.png")

sp = Image.open("textures/console/speakerholes.png").convert("RGBA")       # 6 columns, 97 px apart
wide = Image.new("RGBA", (sp.width + 97, sp.height), (0, 0, 0, 0))
wide.paste(sp, (0, 0)); wide.paste(sp.crop((396, 0, sp.width, sp.height)), (396 + 97, 0))
wide.save("textures/console/speakerholes7.png")

# the device picture for the box, with the new layout (device px = Main UI x - 1, y + 1913)
dev = Image.open("textures/unboxing/box/device.png").convert("RGBA")
a = np.asarray(dev).copy(); Y0 = 1360
for (x0, y0, x1, y1) in [(140, 250, 340, 384), (440, 250, 642, 436), (742, 250, 940, 384), (130, 394, 350, 492), (730, 394, 950, 492)]:
    for y in range(Y0 + y0, Y0 + y1):
        a[y, x0:x1] = a[y, 80]                                         # (keeps the panel's seam line)
dev2 = Image.fromarray(a, "RGBA")
def put(img_path, ui_left, ui_top):
    dev2.alpha_composite(Image.open(img_path).convert("RGBA"), (ui_left - 1, ui_top + 1913))
put(B + "mainbuttonnormal.png", 149, -297)
put(B + "soundbuttonnormal.png", 451, -293)
put(B + "forwardsquarenormal.png", 749, -297)
g = wide.resize((round(wide.width * 0.354854), round(wide.height * 0.320924)), Image.LANCZOS)
dev2.alpha_composite(g, (round(541 - 1 - g.width / 2), round(-97 + 1913 - g.height / 2)))
dev2.save("textures/unboxing/box/device_newbuttons.png")
print("ok")
