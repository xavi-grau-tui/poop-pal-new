"""Gut decor won in the games (2026-10-16), made like the fairy lights and the bunting: the same
canvas as intestine-front.png (a child sprite at position 0, it breathes with the gut), drawn along
the colon's centre line, snapped to the intestine's chunky pixels; two frames that alternate.

    glow_spores    glowing spores floating round the tube, twinkling       (Tilt Maze 3-8, the Gut)
    cog_garland    little cogs on a string along the tube, turning        (Tilt Maze 5-6, the Factory)
    seaweed        fronds of seaweed growing out from the tube, swaying   (Splash Hoops 3-6)
    koma_lanterns  paper lanterns on a string, flickering                 (Top Spin 3-6)
    maple_leaves   autumn maple leaves caught round the tube, fluttering  (Paper Sumo 3-6)
  the games' gift tracks, at 15 stars:
    bead_garland   wooden beads on a string, like a toy's                 (Tilt Maze)
    checker_bunting checkered racing flags along the tube                 (Pal Prix)
    shimenawa      the sacred straw rope with its zigzag paper strips     (Paper Sumo)
    pinwheels      little pinwheels stuck round the tube, spinning        (Top Spin)

    <venv>/bin/python tools/art/decor_games.py [ids]  -> textures/pet/decor/<id>-1.png, -2.png
                                                         textures/pet/decor/icons/<id>.png (the prize card)
"""
import math, os, sys
import numpy as np
from PIL import Image, ImageDraw

from hires import PROJ, SCR
from decor import centre_line, SRC, DEST, BLOCK

INK = (46, 30, 34, 255)
K = 3                                                  # supersampled, then snapped to BLOCK


def frame_basis(line):
    tang = np.gradient(line, axis=0)
    tang /= np.linalg.norm(tang, axis=1, keepdims=True)
    return tang, np.stack([-tang[:, 1], tang[:, 0]], 1)


def snap(im, size, soft=False):
    W, H = size
    small = im.resize((W // BLOCK, H // BLOCK), Image.LANCZOS)
    a = np.asarray(small).copy()
    if soft:                                           # (glows keep a few steps of alpha)
        solid = a[..., 3] > 150
        a[..., 3] = np.where(solid, 255, np.where(a[..., 3] > 25, (a[..., 3] // 40) * 40, 0))
    else:
        a[..., 3] = np.where(a[..., 3] > 130, 255, 0)
    small = Image.fromarray(a, 'RGBA').resize(((W // BLOCK) * BLOCK, (H // BLOCK) * BLOCK), Image.NEAREST)
    canvas = Image.new('RGBA', (W, H), (0, 0, 0, 0))
    canvas.alpha_composite(small, (0, 0))
    return canvas


def every(s, gap, start=0.0):
    """indices along the line, one every `gap` px of tube"""
    out, nxt = [], start
    for i in range(len(s)):
        if s[i] >= nxt:
            out.append(i)
            nxt += gap
    return out


def glow_spores(line, s, radius, frame, size):
    W, H = size
    im = Image.new('RGBA', (W * K, H * K), (0, 0, 0, 0))
    glow = Image.new('RGBA', im.size, (0, 0, 0, 0))
    d, g = ImageDraw.Draw(im), ImageDraw.Draw(glow)
    tang, nrm = frame_basis(line)
    cols = [(140, 255, 220), (200, 255, 140), (210, 170, 255)]
    rng = np.random.default_rng(7)
    for n, i in enumerate(every(s, 58.0, 20.0)):
        side = 1 if n % 2 == 0 else -1
        off = radius[i] * (.8 + rng.uniform(0, .55)) + rng.uniform(4, 26)
        x, y = (line[i] + nrm[i] * side * off + tang[i] * rng.uniform(-14, 14)) * K
        col = cols[n % len(cols)]
        lit = (n + frame) % 2 == 0
        r = (11 if lit else 8) * K
        if lit:
            g.ellipse([x - r * 3.2, y - r * 3.2, x + r * 3.2, y + r * 3.2], fill=col + (55,))
            g.ellipse([x - r * 2, y - r * 2, x + r * 2, y + r * 2], fill=col + (110,))
        d.ellipse([x - r, y - r, x + r, y + r], fill=(col if lit else tuple(int(c * .6) for c in col)) + (255,))
        d.ellipse([x - r * .5, y - r * .55, x, y - r * .05], fill=(255, 255, 255, 255))
    return snap(Image.alpha_composite(glow, im), size, soft=True)


def _gear(d, x, y, r, teeth, ang, col):
    pts = []
    for j in range(teeth * 2):
        a0 = ang + j * math.pi / teeth
        rr = r if j % 2 == 0 else r * .78
        for t in (-.32, .32):
            a = a0 + t * math.pi / teeth
            pts.append((x + math.cos(a) * rr, y + math.sin(a) * rr))
    d.polygon(pts, fill=INK)
    inner = [(x + (px - x) * .84, y + (py - y) * .84) for px, py in pts]
    d.polygon(inner, fill=col + (255,))
    hl = tuple(min(255, int(c * 1.25)) for c in col)
    d.ellipse([x - r * .5, y - r * .5, x + r * .5, y + r * .5], fill=hl + (255,))
    d.ellipse([x - r * .22, y - r * .22, x + r * .22, y + r * .22], fill=INK)


def cog_garland(line, s, radius, frame, size):
    W, H = size
    im = Image.new('RGBA', (W * K, H * K), (0, 0, 0, 0))
    d = ImageDraw.Draw(im)
    tang, nrm = frame_basis(line)
    gap = 104.0
    droop = 9.0 * np.abs(np.sin(math.pi * s / gap))
    path = line + nrm * (radius * .55 + droop)[:, None]
    for i in range(len(path) - 1):
        d.line([tuple(path[i] * K), tuple(path[i + 1] * K)], fill=INK, width=int(9 * K))
    cols = [(214, 166, 72), (170, 176, 190), (200, 120, 70)]
    for n, i in enumerate(every(s, gap, gap / 2)):
        p = path[i] + nrm[i] * 30
        d.line([tuple(path[i] * K), tuple(p * K)], fill=INK, width=int(6 * K))
        turn = (frame * .5 + n * .3) * math.pi / 8
        _gear(d, p[0] * K, p[1] * K, 26 * K, 8, turn if n % 2 == 0 else -turn, cols[n % len(cols)])
    return snap(im, size)


def seaweed(line, s, radius, frame, size):
    W, H = size
    im = Image.new('RGBA', (W * K, H * K), (0, 0, 0, 0))
    d = ImageDraw.Draw(im)
    tang, nrm = frame_basis(line)
    cols = [(58, 150, 92), (40, 132, 124), (96, 170, 84)]
    for n, i in enumerate(every(s, 120.0, 30.0)):
        side = 1 if n % 3 != 2 else -1
        base = line[i] + nrm[i] * side * radius[i] * .62
        ln = 84 + (n % 3) * 20
        pts = []
        for j in range(13):                                         # a wavy ribbon, swaying at its tip
            t = j / 12
            sway = math.sin(t * 7.0 + n * 1.7 + frame * 1.2) * (8 + 16 * t)
            q = base + nrm[i] * side * ln * t + tang[i] * sway
            pts.append(q)
        col = cols[n % len(cols)]
        for j in range(12):
            w_ = (28 - j * 1.4) * K
            d.line([tuple(pts[j] * K), tuple(pts[j + 1] * K)], fill=INK, width=int(w_ + 14 * K))
            d.ellipse([pts[j + 1][0] * K - (w_ + 14 * K) / 2, pts[j + 1][1] * K - (w_ + 14 * K) / 2, pts[j + 1][0] * K + (w_ + 14 * K) / 2, pts[j + 1][1] * K + (w_ + 14 * K) / 2], fill=INK)
        for j in range(12):
            w_ = (28 - j * 1.4) * K
            d.line([tuple(pts[j] * K), tuple(pts[j + 1] * K)], fill=col + (255,), width=int(w_))
            d.ellipse([pts[j + 1][0] * K - w_ / 2, pts[j + 1][1] * K - w_ / 2, pts[j + 1][0] * K + w_ / 2, pts[j + 1][1] * K + w_ / 2], fill=col + (255,))
        hl = tuple(min(255, int(c * 1.35)) for c in col)
        for j in range(1, 10):
            d.line([tuple(pts[j] * K), tuple(pts[j + 1] * K)], fill=hl + (255,), width=int(6 * K))
    return snap(im, size)


def koma_lanterns(line, s, radius, frame, size):
    W, H = size
    im = Image.new('RGBA', (W * K, H * K), (0, 0, 0, 0))
    glow = Image.new('RGBA', im.size, (0, 0, 0, 0))
    d, g = ImageDraw.Draw(im), ImageDraw.Draw(glow)
    tang, nrm = frame_basis(line)
    gap = 118.0
    droop = 11.0 * np.abs(np.sin(math.pi * s / gap))
    path = line + nrm * (radius * .55 + droop)[:, None]
    for i in range(len(path) - 1):
        d.line([tuple(path[i] * K), tuple(path[i + 1] * K)], fill=INK, width=int(8 * K))
    for n, i in enumerate(every(s, gap, gap / 2)):
        c = path[i] + nrm[i] * 34
        x, y = c * K
        red = n % 2 == 0
        body = (226, 70, 54) if red else (250, 238, 214)
        bright = (n + frame) % 2 == 0
        rx, ry = 20 * K, 26 * K
        g.ellipse([x - rx * 2.4, y - ry * 2, x + rx * 2.4, y + ry * 2], fill=(255, 170, 90, 70 if bright else 40))
        d.line([tuple(path[i] * K), (x, y - ry)], fill=INK, width=int(5 * K))
        d.ellipse([x - rx - 3 * K, y - ry - 3 * K, x + rx + 3 * K, y + ry + 3 * K], fill=INK)
        d.ellipse([x - rx, y - ry, x + rx, y + ry], fill=body + (255,))
        d.ellipse([x - rx * .5, y - ry * .55, x + rx * .5, y + ry * .55], fill=(255, 220, 150, 255) if bright else tuple(int(v * .96) for v in body) + (255,))
        for t in (-.55, 0, .55):                                    # the ribs
            d.line([(x - rx * .95 * math.sqrt(1 - t * t), y + ry * t), (x + rx * .95 * math.sqrt(1 - t * t), y + ry * t)], fill=INK, width=int(2 * K))
        for cy_ in (y - ry - 2 * K, y + ry + 2 * K):                # the caps
            d.rectangle([x - rx * .55, cy_ - 4 * K, x + rx * .55, cy_ + 4 * K], fill=INK)
    return snap(Image.alpha_composite(glow, im), size, soft=True)


def _maple(d, x, y, r, ang, col):
    pts = []
    for j in range(10):                                           # five lobes, pointed
        a = ang - math.pi / 2 + j * math.pi / 5
        rr = r if j % 2 == 0 else r * .42
        pts.append((x + math.cos(a) * rr, y + math.sin(a) * rr))
    d.polygon(pts, fill=INK)
    d.polygon([(x + (px - x) * .8, y + (py - y) * .8) for px, py in pts], fill=col + (255,))
    d.line([(x, y), (x + math.cos(ang + math.pi / 2) * r * 1.1, y + math.sin(ang + math.pi / 2) * r * 1.1)], fill=INK, width=int(7 * K))


def maple_leaves(line, s, radius, frame, size):
    W, H = size
    im = Image.new('RGBA', (W * K, H * K), (0, 0, 0, 0))
    d = ImageDraw.Draw(im)
    tang, nrm = frame_basis(line)
    cols = [(214, 58, 44), (236, 120, 44), (246, 176, 62), (180, 40, 44)]
    rng = np.random.default_rng(11)
    for n, i in enumerate(every(s, 96.0, 20.0)):
        side = 1 if n % 2 == 0 else -1
        off = radius[i] * (.3 + rng.uniform(0, .45))
        p = line[i] + nrm[i] * side * off + tang[i] * rng.uniform(-12, 12)
        ang = rng.uniform(0, math.tau) + (.22 if (n + frame) % 2 == 0 else -.22)
        _maple(d, p[0] * K, p[1] * K, (36 + rng.uniform(0, 10)) * K, ang, cols[n % len(cols)])
    return snap(im, size)


def _string(d, line, s, radius, nrm, gap, sag, width=9):
    droop = sag * np.abs(np.sin(math.pi * s / gap))
    path = line + nrm * (radius * .55 + droop)[:, None]
    for i in range(len(path) - 1):
        d.line([tuple(path[i] * K), tuple(path[i + 1] * K)], fill=INK, width=int(width * K))
    return path


def bead_garland(line, s, radius, frame, size):
    W, H = size
    im = Image.new('RGBA', (W * K, H * K), (0, 0, 0, 0))
    d = ImageDraw.Draw(im)
    tang, nrm = frame_basis(line)
    path = _string(d, line, s, radius, nrm, 150.0, 14.0, 7)
    cols = [(206, 150, 92), (226, 186, 120), (170, 112, 70), (196, 96, 76)]
    for n, i in enumerate(every(s, 36.0, (frame * 18.0))):
        x, y = path[i] * K
        r = (15 if n % 3 else 18) * K
        col = cols[n % len(cols)]
        d.ellipse([x - r - 3 * K, y - r - 3 * K, x + r + 3 * K, y + r + 3 * K], fill=INK)
        d.ellipse([x - r, y - r, x + r, y + r], fill=col + (255,))
        d.ellipse([x - r * .55, y - r * .6, x - r * .05, y - r * .15], fill=tuple(min(255, int(v * 1.25)) for v in col) + (255,))
    return snap(im, size)


def checker_bunting(line, s, radius, frame, size):
    W, H = size
    im = Image.new('RGBA', (W * K, H * K), (0, 0, 0, 0))
    d = ImageDraw.Draw(im)
    tang, nrm = frame_basis(line)
    path = _string(d, line, s, radius, nrm, 184.0, 10.0, 10)
    for n, i in enumerate(every(s, 92.0, 46.0)):
        p, t = path[i], tang[i]
        ang = math.atan2(nrm[i][1], nrm[i][0]) + (0.18 if (n + frame) % 2 == 0 else -0.18)
        out = np.array([math.cos(ang), math.sin(ang)])
        a, b, tip = p - t * 28, p + t * 28, p + out * 74
        d.polygon([tuple(a * K), tuple(b * K), tuple(tip * K)], fill=INK)
        inset = lambda q: p + (q - p) * .82 + out * 3
        ia, ib, it = inset(a), inset(b), inset(tip)
        d.polygon([tuple(ia * K), tuple(ib * K), tuple(it * K)], fill=(250, 248, 240, 255))
        for u in range(4):                                # the checks: rows of squares down the flag
            for v in range(4):
                if (u + v) % 2:
                    continue
                q0 = ia + (ib - ia) * (u / 4) + (it - ia) * 0
                c0 = p + t * (-24 + u * 12) + out * (6 + v * 15)
                cw = 12 * (1 - v * .22)
                quad = [c0, c0 + t * cw, c0 + t * cw + out * 15, c0 + out * 15]
                d.polygon([tuple(q * K) for q in quad], fill=INK)
        d.polygon([tuple(a * K), tuple(ia * K), tuple(it * K), tuple(tip * K)], fill=INK)      # (the left edge, tidy)
    return snap(im, size)


def shimenawa(line, s, radius, frame, size):
    W, H = size
    im = Image.new('RGBA', (W * K, H * K), (0, 0, 0, 0))
    d = ImageDraw.Draw(im)
    tang, nrm = frame_basis(line)
    path = line + nrm * (radius * .5)[:, None]
    for i in range(len(path) - 1):                          # the rope: thick, twisted straw
        d.line([tuple(path[i] * K), tuple(path[i + 1] * K)], fill=INK, width=int(34 * K))
    for i in range(len(path) - 1):
        d.line([tuple(path[i] * K), tuple(path[i + 1] * K)], fill=(220, 192, 116, 255), width=int(26 * K))
    for i in every(s, 22.0):
        p = path[i]
        a, b = p - nrm[i] * 11 - tang[i] * 5, p + nrm[i] * 11 + tang[i] * 5
        d.line([tuple(a * K), tuple(b * K)], fill=(168, 136, 64, 255), width=int(5 * K))
    for n, i in enumerate(every(s, 120.0, 60.0)):            # the shide: zigzag paper, swaying
        p = path[i] + nrm[i] * 14
        sway = (5 if (n + frame) % 2 == 0 else -5)
        o, t = nrm[i], tang[i] + nrm[i] * (sway / 60)
        st, w_ = 16.0, 9.0
        pts = [p - t * w_, p + t * w_, p + t * w_ + o * st, p + t * (w_ * 3) + o * st, p + t * (w_ * 3) + o * st * 2,
               p + t * w_ + o * st * 2, p + t * w_ + o * st * 3, p - t * w_ + o * st * 3, p - t * w_ + o * st * 2,
               p + t * w_ * .9 + o * st * 2, p + t * w_ * .9 + o * st, p - t * w_ + o * st]
        d.polygon([tuple(q * K) for q in pts], fill=INK)
        inner = [p + (q - p) * .86 + o * 2 for q in pts]
        d.polygon([tuple(q * K) for q in inner], fill=(252, 250, 244, 255))
    return snap(im, size)


def pinwheels(line, s, radius, frame, size):
    W, H = size
    im = Image.new('RGBA', (W * K, H * K), (0, 0, 0, 0))
    d = ImageDraw.Draw(im)
    tang, nrm = frame_basis(line)
    cols = [(226, 64, 58), (246, 204, 70), (70, 130, 214), (96, 184, 96)]
    for n, i in enumerate(every(s, 140.0, 50.0)):
        side = 1 if n % 2 == 0 else -1
        base = line[i] + nrm[i] * side * radius[i] * .55
        hub = base + nrm[i] * side * 72
        d.line([tuple(base * K), tuple(hub * K)], fill=INK, width=int(9 * K))
        d.line([tuple(base * K), tuple(hub * K)], fill=(200, 160, 110, 255), width=int(4 * K))
        spin = frame * math.pi / 4 + n * .7
        for j in range(4):                                  # four blades, each a curled triangle
            a = spin + j * math.pi / 2
            p1 = hub + np.array([math.cos(a), math.sin(a)]) * 48
            p2 = hub + np.array([math.cos(a + .9), math.sin(a + .9)]) * 28
            d.polygon([tuple(hub * K), tuple(p1 * K), tuple(p2 * K)], fill=INK)
            q1 = hub + (p1 - hub) * .86
            q2 = hub + (p2 - hub) * .8
            d.polygon([tuple(hub * K), tuple(q1 * K), tuple(q2 * K)], fill=cols[(j + n) % 4] + (255,))
        d.ellipse([hub[0] * K - 6 * K, hub[1] * K - 6 * K, hub[0] * K + 6 * K, hub[1] * K + 6 * K], fill=INK)
    return snap(im, size)


ITEMS = {'bead_garland': bead_garland, 'checker_bunting': checker_bunting, 'shimenawa': shimenawa, 'pinwheels': pinwheels,
         'glow_spores': glow_spores, 'cog_garland': cog_garland, 'seaweed': seaweed,
         'koma_lanterns': koma_lanterns, 'maple_leaves': maple_leaves}


def icon(gut, over):
    """the prize card's picture: a corner of the colon with the decor on it (as the menu shows it)"""
    im = gut.copy()
    im.alpha_composite(over)
    crop = im.crop((60, 90, 440, 450))
    out = Image.new('RGBA', crop.size, (236, 170, 170, 255))
    out.alpha_composite(crop)
    return out.resize((96, 91), Image.LANCZOS)


if __name__ == '__main__':
    only = sys.argv[1:] or list(ITEMS)
    src = Image.open(SRC).convert('RGBA')
    line, s, radius = centre_line(np.asarray(src)[..., 3])
    os.makedirs(os.path.join(DEST, 'icons'), exist_ok=True)
    for item in only:
        prev = Image.new('RGBA', (src.width * 2, src.height), (236, 170, 170, 255))
        for f in range(2):
            img = ITEMS[item](line, s, radius, f, src.size)
            img.save(os.path.join(DEST, f'{item}-{f + 1}.png'))
            prev.alpha_composite(src, (f * src.width, 0))
            prev.alpha_composite(img, (f * src.width, 0))
            if f == 0:
                icon(src, img).save(os.path.join(DEST, 'icons', f'{item}.png'))
        os.makedirs(SCR, exist_ok=True)
        prev.resize((prev.width // 2, prev.height // 2)).save(os.path.join(SCR, f'{item}_preview.png'))
        print(item, 'ok', flush=True)
