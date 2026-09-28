from hires import *
c = Canvas(32, 32, 16)
cx, cy = 16, 16.6
dx, dy = c.x - cx, (c.y - cy) * 1.18
d = np.hypot(dx, dy); Rm, tw = 9.0, 4.9
t = np.clip(1 - ((d - Rm) / tw) ** 2, 0, 1)
ring = t > 0
h = np.sqrt(t)
dough = [(92, 44, 24), (150, 84, 40), (190, 118, 56), (218, 156, 84), (240, 196, 130)]
material(c, h, ring, dough, bump=5, spec_amt=0.15, grain=0.10)
ang = np.arctan2(dy, dx)
wave = 1.8 * np.sin(ang * 6 + 0.5) + 1.2 * np.sin(ang * 11) + 1.2
icing = ring & (dy < wave) & (np.abs(d - Rm) < tw - 0.7)
icing_pal = [(120, 40, 70), (190, 80, 118), (228, 122, 156), (248, 170, 196), (255, 226, 236)]
material(c, np.sqrt(t) * 1.05, icing, icing_pal, bump=5, spec_amt=0.45, spec_pow=30, grain=0.05, ao=0.2)
seam(c, icing, ring & ~icing, 0.45, np.array([120, 50, 40], np.float32))
dots(c, 22, (4, 3, 28, 22, lambda x, y: (lambda D, Y: abs(D - Rm) < tw - 1.8 and Y < 1.2*math.sin(math.atan2(Y,x-cx)*6)+1)(math.hypot(x - cx, (y - cy) * 1.18), (y - cy) * 1.18)),
     [(255, 250, 225), (110, 190, 230), (140, 205, 100), (255, 205, 70), (170, 120, 220)], r=0.65, seed=3)
outline(c, c.a > 0.5, 1.0)
big, small = shrink(c)
small.save(SCR + '/donut2.png'); big.resize((256, 256)).save(SCR + '/donut2_big.png')
