"""Food menu: the type tag (Green, Sweet...) replaces the kcal box of the option frame.

    python3 tools/art/food_tag.py
        -> textures/menus/foodmenulabel_food.png   the frame without the kcal box (food pages)
        -> textures/menus/foodtag.png              that box, pale, tinted per type in game

The drink page keeps foodmenulabel.png (with its kcal box).
"""
import os
import numpy as np
from PIL import Image

HERE = os.path.dirname(os.path.abspath(__file__))
MENUS = os.path.join(HERE, '..', '..', 'textures', 'menus')
BOX = (274, 49, 381, 100)          # the kcal box in foodmenulabel.png (x0, y0, x1, y1)

src = np.asarray(Image.open(os.path.join(MENUS, 'foodmenulabel.png')).convert('RGBA')).astype(np.int32)
x0, y0, x1, y1 = BOX
w, h = x1 - x0, y1 - y0

# 1) the frame without the box: the cream card texture from just left of it fills the hole
frame = src.copy()
frame[y0:y1, x0:x1] = src[y0:y1, x0 - w - 6:x0 - 6]
Image.fromarray(frame.astype(np.uint8), 'RGBA').save(os.path.join(MENUS, 'foodmenulabel_food.png'))

# 2) the box on its own, made pale (near white, keeping its texture) so a modulate tints it
box = src[y0:y1, x0:x1].copy()
cream = np.median(src[y0:y1, x0 - w - 6:x0 - 6, :3].reshape(-1, 3), axis=0)
is_box = np.abs(box[..., :3] - cream).sum(-1) > 18
lum = box[..., :3].mean(-1)
lum = lum / lum[is_box].mean()
pale = np.zeros_like(box)
pale[..., :3] = np.clip(240 * lum[..., None], 0, 255)
pale[..., 3] = np.where(is_box, 255, 0)
Image.fromarray(pale.astype(np.uint8), 'RGBA').save(os.path.join(MENUS, 'foodtag.png'))
print('ok', w, h)
