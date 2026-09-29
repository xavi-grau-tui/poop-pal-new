# Art generators

Python scripts that produced the generated art (paint large with soft shading, then
downscale, to match the existing Poop Pal assets).

Needs Python 3 with `pillow` and `numpy`:

    python3 -m venv .venv && .venv/bin/pip install pillow numpy
    cd tools/art
    ../../.venv/bin/python forms.py    # pet forms  -> textures/pet/forms/*-1.png, *-2.png
    ../../.venv/bin/python balls.py    # maze balls -> textures/minigames/balls/*.png
    ../../.venv/bin/python food.py     # donut      -> out/donut2.png (copy to textures/food/donut.png)
    ../../.venv/bin/python title.py "POO|MAZE" ../../textures/menus/poomaze.png
    ../../.venv/bin/python accessories.py   # pal accessories, one file per form + frame -> textures/pet/accessories/<item>/
    ../../.venv/bin/python minigame_art.py  # Splash / Dash / Break / Germ Zap sprites (needs scipy)
    ../../.venv/bin/python decor.py         # gut decor (needs scipy + scikit-image) -> textures/pet/decor/
    ../../.venv/bin/python loop_pattern.py glasses ../../textures/menus/glassesloopbackground.png

`hires.py` holds the shared renderer (metaball shapes, shading, outline, face).
Previews and hi-res masters go to `tools/art/out/` (not committed).
