"""Put the 120 new spirits into the game (2026-11-07, the user: "install all the new spirits with
animations and names/info in the tomopedia").

From the cleaned animation frames (docs/mockups/spirits/anim_frames/: spirit_anim_cut.py,
spirit_face_clean.py, spirit_parts.py), docs/ being ignored by Godot:

  textures/spirits/<id>/            every face, body and part frame the animation plays
                                    (scripts/spirit_anim.gd), as they are
  data/spirit_rig.json              each spirit's parts and flags (anim_frames/rig.json)
  textures/spirits/forms/<id>-1.png the spirit in the OLD pals' picture format (232 x 196, 1 art px =
  textures/spirits/forms/<id>-2.png 2 texels, standing on the old pals' baseline, centred like them):
                                    -1 the approved sprite, -2 its eyes shut. Everything that shows
                                    a pal's picture (the Tomopedia, the balls, the games, Lucky
                                    Pinch) takes these with no change of its own (PetState.apply_art)

The old pals' art stays where it was (textures/pet/forms/): the dev launcher's SPIRITS: OLD shows it.

    .venv/bin/python tools/art/spirits_install.py
"""
import json
import shutil
from pathlib import Path

from PIL import Image

ROOT = Path(__file__).resolve().parents[2]
SRC = ROOT / "docs/mockups/spirits/anim_frames"
DST = ROOT / "textures/spirits"
FORMS = DST / "forms"
W, H = 232, 196            # the old pals' canvas
CX, BOTTOM = 116, 158      # their centre column and the row under their feet
ART_BASE = 54              # the 56 art canvas's floor row


def old_format(png):
    art = Image.open(png).convert("RGBA")
    big = art.resize((112, 112), Image.NEAREST)
    can = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    can.alpha_composite(big, (CX - 56, BOTTOM - (ART_BASE + 1) * 2))
    return can


def main():
    ids = sorted(p.name for p in SRC.iterdir() if p.is_dir() and (p / "base.png").exists())
    FORMS.mkdir(parents=True, exist_ok=True)
    n = 0
    for sid in ids:
        d = DST / sid
        if d.exists():
            shutil.rmtree(d)
        d.mkdir(parents=True)
        for f in sorted((SRC / sid).glob("*.png")):
            shutil.copy2(f, d / f.name)
            n += 1
        old_format(SRC / sid / "base.png").save(FORMS / f"{sid}-1.png")
        closed = SRC / sid / "closed.png"
        old_format(closed if closed.exists() else SRC / sid / "base.png").save(FORMS / f"{sid}-2.png")
    rig = json.load(open(SRC / "rig.json"))
    json.dump(rig, open(ROOT / "data/spirit_rig.json", "w"), indent=1)
    print(f"{len(ids)} spirits, {n} frames -> {DST.relative_to(ROOT)}; rig -> data/spirit_rig.json")


if __name__ == "__main__":
    main()
