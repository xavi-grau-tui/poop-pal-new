"""Every pal of the evolution tree (data/evolution_tree.json = the user's sheet 4) as game art,
drawn by the pal renderer (docs/mockups/pal_brainstorm/v3/palgen3.py: paint big, shrink to the
55x50 native canvas, shown x2 in a 232x196 frame like the old forms):

    textures/pet/forms/<id>-1.png, -2.png   the idle frames (the 2nd breathes: squash 1.03 x 0.95)
    tools/art/pal_faces.json                each face (x, y, eye spread, eye radius; design units):
                                            the accessories sit on it (accessories.py, scarf.py...)

    <venv>/bin/python tools/art/pals_export.py             all 120, in parallel
    <venv>/bin/python tools/art/pals_export.py bud usagi   only these
Picklet stays exactly as it is (its two frames are the original art).
"""
import json, os, sys
from multiprocessing import Pool
from PIL import Image

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.normpath(os.path.join(HERE, '..', '..'))
sys.path.insert(0, os.path.join(ROOT, 'docs', 'mockups', 'pal_brainstorm', 'v3'))
import palgen3 as G

DATA = os.path.join(ROOT, 'data', 'evolution_tree.json')
DEST = os.path.join(ROOT, 'textures', 'pet', 'forms')
FACES = os.path.join(HERE, 'pal_faces.json')
BREATHE = (1.03, 0.95)
PICKLET_FACE = [55, 74.15, 10.5, 5.4]        # forms_gen's Picklet (the sour baby body)


def framed(im):
    out = Image.new('RGBA', (232, 196), (0, 0, 0, 0))
    out.alpha_composite(im, (60, 60))
    return out


def export(item):
    fid, fm = item
    name, spec, _ = G.parse(fm['line'])
    if spec.get('special') == 'picklet':
        return fid, PICKLET_FACE
    stage = fm['stage_name']
    G.LAST_FACE = None
    one = G.render(spec, stage, name)
    face = list(G.LAST_FACE)
    lift, fit = G.LAST_FIT
    two = G.render(spec, stage, name, lift, fit, 4, BREATHE)
    framed(one).save(os.path.join(DEST, f'{fid}-1.png'))
    framed(two).save(os.path.join(DEST, f'{fid}-2.png'))
    return fid, [float(round(float(v), 2)) for v in face]


if __name__ == '__main__':
    forms = json.load(open(DATA))['forms']
    only = sys.argv[1:]
    todo = [(k, v) for k, v in forms.items() if not only or k in only]
    faces = json.load(open(FACES)) if os.path.exists(FACES) else {}
    with Pool(min(10, os.cpu_count() or 4)) as pool:
        for fid, face in pool.imap_unordered(export, todo):
            faces[fid] = face
            print(fid, face, flush=True)
    faces = {k: faces[k] for k in forms if k in faces}       # (tree order; gone pals dropped)
    with open(FACES, 'w') as f:
        json.dump(faces, f, indent=0)
    print('ok', len(todo))
