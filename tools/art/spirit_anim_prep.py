"""The animation prep sheets for the designer: every spirit not in the pilot, six to a sheet, realm by
realm, laid out like the pilot (docs/mockups/spirits/anim_pilot): one column per spirit, seven 260 px
rows, each an exact copy of its approved cell, for the designer to edit:
    1 base   2 eyes closed   3 mouth open   4 happy   5 sad   6 move: pose 1   7 move: pose 2
Every row is an in-place edit (2026-11-06: the designer can't cut parts out cleanly, but in-place edits
work): rows 6-7 redraw the moving parts in two poses where they are, the code plays them in turn.
Rows 6-7 stay empty for a spirit with no moving parts. The Tech mutants' key and cogs have their own
sheet, tech_clockwork.png (rows: base, the key turned 1/8, edge-on, 3/8, the cogs a third and two
thirds of a tooth on).

    .venv/bin/python tools/art/spirit_anim_prep.py

Writes docs/mockups/spirits/anim_prep/<realm>_prep_N.png (to edit), <realm>_prep_N_guide.png (labelled,
with each spirit's parts) and manifest.json (every sheet's spirits and parts, for spirit_anim_cut.py).

The parts: name -> kind (how the code moves it). seed / at tell parts apart when they touch or share a
colour ("green", "grey" / "top", "left", "right"); solid drops thin strands. Spirit flags: wobbly (it
rocks from its base instead of hopping, like a daruma or a bell), flicker (its whole top flickers, a
flame body).
"""
import json
import sys
from pathlib import Path

import numpy as np
from PIL import Image, ImageDraw, ImageFont

sys.path.insert(0, str(Path(__file__).parent))
from october_sheet_cut import CELL, ORDER, SP, latest, layout  # noqa: E402

OUT = SP / "anim_prep"
PILOT = {"kakiage", "nacho", "popper", "ladyluck", "komainu", "tengu"}


def P(kind, **kw):
    return dict(kind=kind, **kw)


# id -> (parts, flags). Not listed: no moving parts, hops.
SPIRITS = {
    # Mountain
    "peapod": ({"sprout": P("sway")}, {}),
    "melon_pan": ({"sprout": P("sway")}, {}),
    "usagi": ({"leaf": P("sway", at="top"), "petal": P("bob", at="right")}, {}),
    "yomogi": ({"leaf": P("sway")}, {}),
    "usagi_manju": ({"petal": P("bob")}, {}),
    "yamabiko": ({"cloud_l": P("bob", at="left"), "cloud_r": P("bob", at="right")}, {}),
    "kinoko": ({"little": P("bob")}, {}),
    "mujina": ({"leaf": P("sway")}, {}),
    "kodama": ({"sprout": P("sway")}, {}),
    "karasu_tengu": ({"cap": P("slip", seed="dark", solid=True), "wing_l": P("flap", seed="white", at="left"),
                      "wing_r": P("flap", seed="white", at="right")}, {}),
    "gherk": ({"antennae": P("sway")}, {}),
    "kiwi_bird": ({}, {"wobbly": True}),
    "bud": ({"sprout": P("sway")}, {}),
    "karakuri": ({"key": P("spin", seed="gold", at="top"), "sprout": P("sway", seed="green")}, {}),
    "zorb": ({"star": P("sway", at="top"), "stars": P("twinkle", at="rest")}, {}),
    # Moon
    "leafwing": ({"flowers": P("sway")}, {}),
    "owlet": ({"wing_l": P("flap", at="left"), "wing_r": P("flap", at="right")}, {}),
    "scarab": ({"wisp_l": P("flame", at="left"), "wisp_r": P("flame", at="right")}, {"flicker": True}),
    "fudge": ({"ears": P("twitch")}, {}),
    "bonbon": ({"ears": P("twitch", at="top"), "pestle": P("bob", at="right")}, {}),
    "kuri": ({"ears": P("twitch")}, {}),
    "gremlin": ({"wisps": P("bob")}, {}),
    "churro": ({"star": P("twinkle")}, {}),
    "choco_taco": ({"chime": P("swing", solid=True)}, {"wobbly": True}),
    "hot_cocoa": ({}, {"wobbly": True}),
    "taiyaki": ({"tail": P("wag")}, {}),
    "bumble": ({"leaf": P("sway")}, {}),
    "ramune": ({"marble": P("bob")}, {}),
    "cocoa_9": ({"key": P("spin", solid=True)}, {}),
    "kaguya": ({"sparkles": P("twinkle", seed="gold"), "leaves": P("sway", seed="green")}, {}),
    "tsukuyomi": ({"ears": P("twitch")}, {}),
    # Fox
    "kitsune": ({"shide": P("sway")}, {}),
    "kyubi": ({"wisp_l": P("flame", at="left"), "wisp_r": P("flame", at="right")}, {}),
    "konoha": ({"leaf": P("sway")}, {}),
    "waffle": ({"leaf": P("sway")}, {}),
    "fried_egg": ({"tail": P("wag")}, {}),
    "burger": ({"leaf": P("sway", at="top"), "tail": P("wag", at="right")}, {}),
    "hot_dog": ({"tail": P("wag")}, {}),
    "fish_taco": ({"tail": P("wag", at="right"), "flask": P("bob", at="left")}, {}),
    "drumstick": ({"bachi_l": P("beat", at="left"), "bachi_r": P("beat", at="right")}, {}),
    "kitsu": ({"tassel": P("swing", solid=True)}, {"wobbly": True}),
    "hothog": ({"sprout": P("sway")}, {}),
    "walrusk": ({}, {"wobbly": True}),
    "robobear": ({"key": P("spin", solid=True)}, {}),
    "nebula_nug": ({"flame": P("flame", seed="blue", at="top"), "stars": P("twinkle", seed="gold")}, {}),
    "sunbear": ({"leaf": P("sway", at="top"), "tail": P("wag", at="right")}, {}),
    # Fire
    "hoozuki": ({"leaf": P("sway")}, {}),
    "pepper_plant": ({"leaves": P("sway")}, {}),
    "chameleon": ({}, {"wobbly": True}),
    "daruma": ({}, {"wobbly": True}),
    "oo_daruma": ({}, {"wobbly": True}),
    "burrito": ({"smoke": P("bob")}, {}),
    "firebug": ({"bolt": P("bolt")}, {}),
    "salamander": ({"drops": P("bob")}, {"flicker": True}),
    "ember": ({}, {"flicker": True}),
    "mecha_oni": ({"key": P("spin", solid=True)}, {}),
    "comet_chili": ({"spark": P("flame")}, {}),
    "hou_ou": ({"crest": P("flame", at="top"), "tail": P("flame", at="right")}, {}),
    # River
    "kappa_maki": ({"leaf": P("sway", at="top"), "drop": P("bob", at="right")}, {}),
    "ume_onigiri": ({"drip": P("bob")}, {}),
    "granny": ({"bud": P("sway")}, {}),
    "sourpatch": ({"leaf": P("sway")}, {}),
    "lemon_sweet": ({"cherries": P("sway")}, {}),
    "cream_soda": ({"cherry": P("sway")}, {}),
    "lime": ({"drops": P("bob", seed="blue"), "leaf": P("sway", seed="green")}, {}),
    "hermit": ({}, {"wobbly": True}),
    "anemone": ({"splashes": P("bob")}, {}),
    "calamari": ({"fin_l": P("flap", at="left"), "fin_r": P("flap", at="right")}, {}),
    "octopepper": ({"knot": P("sway")}, {}),
    "axel": ({"gills_l": P("flap", at="left"), "gills_r": P("flap", at="right")}, {}),
    "teru_teru": ({"drops": P("bob")}, {"wobbly": True}),
    "omamori": ({}, {"wobbly": True}),
    "kokeshi": ({}, {"wobbly": True}),
    "robofrog": ({"key": P("spin", solid=True)}, {}),
    "ningyo": ({"fin_l": P("flap", at="left"), "fin_r": P("flap", at="right")}, {}),
    "frog_king": ({"crown": P("bob", solid=True)}, {}),
}

# what the designer reads under each column (the parts in words, and faces of their own)
NOTES = {
    "karasu_tengu": "the beak opens to eat",
    "kiwi": "its face peeks out of the front segment: keep it there",
    "honeybear": "the big eyes close as lids; the beak opens to eat",
    "hot_cocoa": "the eyes sit in the bell's dark mouth: keep them there",
    "fish_taco": "its grin is its face: open = grin wider, sad = grin turned down",
    "comet_chili": "the big round eyes: lids close over them",
    "burrito": "the pig snout stays; the mouth opens under it",
    "hou_ou": "the beak opens to eat",
    "karakasa": "the single eye like the lantern's; mouth open = its long tongue out",
    "daruma": "the brows stay", "oo_daruma": "the brows stay",
    "kyubi": "its face is under the mask: change only that",
    "kiwi_bird": "keep the raised brow",
}
PART_WORDS = {
    "sprout": "the sprout", "leaf": "the leaf", "leaves": "the leaves", "petal": "the falling petal",
    "cloud_l": "left cloud", "cloud_r": "right cloud", "little": "the little mushroom", "cap": "the tokin cap",
    "wing_l": "left wing", "wing_r": "right wing", "antennae": "the antennae", "key": "the wind-up key",
    "star": "the star", "stars": "the tiny stars", "flowers": "the flowers", "wisp_l": "left wisp",
    "wisp_r": "right wisp", "ears": "the ears", "pestle": "the pestle", "wisps": "the little wisps",
    "chime": "the chime's strip and bead", "tail": "the tail", "marble": "the marble", "sparkles": "the sparkles",
    "shide": "the paper zigzags", "flask": "the sake flask", "bachi_l": "left drumstick",
    "bachi_r": "right drumstick", "tassel": "the tassel", "flame": "the flame", "smoke": "the smoke curl",
    "bolt": "the bolt", "drops": "the drops", "spark": "the spark on top", "crest": "the flame crest",
    "drop": "the drop", "drip": "the drip", "bud": "the lotus bud", "cherries": "the cherries",
    "cherry": "the cherry", "splashes": "the splashes", "fin_l": "left fin", "fin_r": "right fin",
    "knot": "the headband's knot ends", "gills_l": "left gills", "gills_r": "right gills", "crown": "the crown",
}


POSES = {
    "sway": ("{p} tilted left", "{p} tilted right"), "twitch": ("{p} pricked up", "{p} flopped a little"),
    "wag": ("{p} swung up", "{p} swung the other way"), "flap": ("{p} raised", "{p} lowered"),
    "swing": ("{p} swung left", "{p} swung right"), "bob": ("{p} up a little", "{p} down a little"),
    "flame": ("{p} taller", "{p} lower, leaning"), "bolt": ("{p} bigger, brighter", "{p} smaller"),
    "beat": ("{p} raised", "{p} down"), "slip": ("{p} tipped over one eye", "{p} lifted a little"),
    "twinkle": ("{p} smaller", "{p} bigger, brighter"),
}


def pose_lines(parts):
    posed = {k: v for k, v in parts.items() if v["kind"] != "spin"}
    out = []
    if any(v["kind"] == "spin" for v in parts.values()):
        out.append("key and cogs: on the clockwork sheet")
    if not posed:
        return out + ["no other moving parts: rows 6-7 empty"] if out else ["no moving parts: rows 6-7 empty"]
    for i in (0, 1):
        bits = []
        for nm, v in posed.items():
            word = PART_WORDS[nm].replace("the ", "")
            if v["kind"] == "beat":           # (the drumsticks take turns)
                bits.append(f"{word} {'raised' if (i == 0) == nm.endswith('_l') else 'down'}")
            else:
                bits.append(POSES[v["kind"]][i].format(p=word))
        out.append(f"pose {i + 1}: " + ", ".join(bits))
    return out


def clockwork(sheets):
    """the Tech mutants' sheet: base, the key turned 1/8, edge-on, 3/8, the cogs 1/3 and 2/3 of a tooth"""
    tech = [("mountain", "karakuri"), ("moon", "cocoa_9"), ("fox", "robobear"), ("fire", "mecha_oni"),
            ("river", "robofrog")]
    rows = ["1 base (don't edit)", "2 key turned 1/8", "3 key edge-on", "4 key turned 3/8", "5 cogs 1/3 tooth on",
            "6 cogs 2/3 tooth on"]
    bg = None
    cells = []
    for realm, sid in tech:
        sheet = sheets[realm]
        cols = layout(realm)
        c, r = next((c, r) for c, col in enumerate(cols) for r, s in enumerate(col) if s == sid)
        cells.append(sheet.crop((c * CELL, r * CELL, (c + 1) * CELL, (r + 1) * CELL)))
        bg = bg or tuple(int(v) for v in np.median(np.array(sheet)[:6].reshape(-1, 3), 0))
    sh = Image.new("RGB", (len(tech) * CELL, len(rows) * CELL), bg)
    for i, cell in enumerate(cells):
        for row in range(len(rows)):
            sh.paste(cell, (i * CELL, row * CELL))
    sh.save(OUT / "tech_clockwork.png")
    f = ImageFont.truetype("/System/Library/Fonts/Avenir Next.ttc", 20, index=2)
    L, T = 250, 40
    g = Image.new("RGB", (L + sh.width, T + sh.height), (40, 36, 46))
    g.paste(sh, (L, T))
    d = ImageDraw.Draw(g)
    for i, (_, sid) in enumerate(tech):
        d.text((L + i * CELL + 10, 8), sid, font=f, fill=(240, 230, 245))
    for row, label in enumerate(rows):
        d.text((12, T + row * CELL + CELL // 2 - 14), label, font=f, fill=(240, 230, 245))
    g.save(OUT / "tech_clockwork_guide.png")
    return {"name": "tech_clockwork", "rows": rows,
            "spirits": [{"realm": r, "id": s, "parts": {"key": P("spin"), "cogs": P("spin")}} for r, s in tech]}


def build():
    OUT.mkdir(parents=True, exist_ok=True)
    f = ImageFont.truetype("/System/Library/Fonts/Avenir Next.ttc", 20, index=2)
    fs = ImageFont.truetype("/System/Library/Fonts/Avenir Next.ttc", 15, index=5)
    rows = ["1 base (don't edit)", "2 eyes closed", "3 mouth open (eating)", "4 happy", "5 sad",
            "6 move: pose 1", "7 move: pose 2"]
    manifest = {"sheets": []}
    for realm in ORDER:
        sheet = Image.open(latest(realm)).convert("RGB")
        bg = tuple(int(v) for v in np.median(np.array(sheet)[:6].reshape(-1, 3), 0))
        cols = layout(realm)
        ids = [sid for col in cols for sid in col if sid not in PILOT]
        for n, start in enumerate(range(0, len(ids), 6), start=1):
            group = ids[start:start + 6]
            sh = Image.new("RGB", (len(group) * CELL, 7 * CELL), bg)
            entries = []
            for i, sid in enumerate(group):
                c, r = next((c, r) for c, col in enumerate(cols) for r, s in enumerate(col) if s == sid)
                cell = sheet.crop((c * CELL, r * CELL, (c + 1) * CELL, (r + 1) * CELL))
                parts, flags = SPIRITS.get(sid, ({}, {}))
                posed = {k: v for k, v in parts.items() if v["kind"] != "spin"}
                for row in range(7 if posed else 5):
                    sh.paste(cell, (i * CELL, row * CELL))
                entries.append({"realm": realm, "id": sid, "parts": parts, **flags})
            name = f"{realm}_prep_{n}"
            sh.save(OUT / f"{name}.png")
            # the guide: labels over each column, the rows named, each spirit's parts and face note under it
            L, T, B = 250, 40, 120
            g = Image.new("RGB", (L + sh.width, T + sh.height + B), (40, 36, 46))
            g.paste(sh, (L, T))
            d = ImageDraw.Draw(g)
            for i, e in enumerate(entries):
                d.text((L + i * CELL + 10, 8), e["id"], font=f, fill=(240, 230, 245))
                lines = pose_lines(e["parts"])
                if e["id"] in NOTES:
                    lines.append("face: " + NOTES[e["id"]])
                y = T + sh.height + 8
                for line in lines:
                    for chunk in _wrap(d, line, fs, CELL - 16):
                        d.text((L + i * CELL + 8, y), chunk, font=fs, fill=(235, 215, 170))
                        y += 19
            for row, label in enumerate(rows):
                d.text((12, T + row * CELL + CELL // 2 - 14), label, font=f, fill=(240, 230, 245))
            for i in range(8):
                d.line((L, T + i * CELL, g.width, T + i * CELL), fill=(120, 110, 130), width=1)
            g.save(OUT / f"{name}_guide.png")
            manifest["sheets"].append({"name": name, "spirits": entries})
            print(name, [e["id"] for e in entries])
    manifest["clockwork"] = clockwork({r: Image.open(latest(r)).convert("RGB") for r in ORDER})
    (OUT / "manifest.json").write_text(json.dumps(manifest, indent=1))


def _wrap(d, text, font, width):
    out, line = [], ""
    for w in text.split(" "):
        t = (line + " " + w).strip()
        if d.textlength(t, font=font) > width and line:
            out.append(line)
            line = w
        else:
            line = t
    return out + [line] if line else out


if __name__ == "__main__":
    build()
