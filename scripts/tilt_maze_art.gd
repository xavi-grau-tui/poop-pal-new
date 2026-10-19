class_name TiltMazeArt
## Tilt Maze's worlds, drawn in code like the first one (the wooden labyrinth): the same board
## grid (4 world px per board px), a 2 px dark outline round every wall, light from the top-left
## (lit top / left edges, a darker front face at the bottom, a two-step drop shadow on the floor)
## and hard pixels, no gradients. Each world swaps the materials:
##   0 Wooden Toy     plywood floor, planked walls, drilled holes        amber marbles
##   1 Bath Tiles     glazed tiles and grout, ceramic walls, drains       soap bubbles
##   2 The Gut        soft pink lining, plump walls, pores               glowing spores
##   3 Sewer          wet stone flags, brick walls, open manholes         lost rings
##   4 Factory        diamond plate, steel girders, hazard pits           hex nuts
##   5 Space          a starry deck, moon-rock walls, black holes         stars

const THEMES := [
	{   # 0 Wooden Toy (the original look)
		"kind": "wood",
		"floor": [Color8(236, 206, 158), Color8(216, 180, 128), Color8(196, 156, 104)],
		"wall": [Color8(214, 160, 100), Color8(192, 136, 80), Color8(168, 112, 62), Color8(132, 84, 48)],
		"outline": Color8(74, 44, 32), "ink": Color8(58, 38, 30),
		"hole": [Color8(34, 20, 16), Color8(120, 78, 50)],
		"menu": Color8(214, 186, 140),
	},
	{   # 1 Bath Tiles: mint glazed tiles, white grout, pale blue ceramic walls
		"kind": "tiles",
		"floor": [Color8(196, 232, 222), Color8(178, 218, 208), Color8(240, 246, 242)],
		"wall": [Color8(232, 242, 250), Color8(196, 220, 238), Color8(176, 204, 228), Color8(122, 154, 188)],
		"outline": Color8(46, 64, 84), "ink": Color8(70, 104, 120),
		"hole": [Color8(36, 44, 54), Color8(150, 162, 176)],
		"menu": Color8(170, 212, 206),
	},
	{   # 2 The Gut: the pet screen's pinks, a wet sheen on the walls
		"kind": "gut",
		"floor": [Color8(242, 170, 170), Color8(228, 150, 154), Color8(250, 196, 192)],
		"wall": [Color8(222, 112, 128), Color8(198, 86, 106), Color8(176, 68, 92), Color8(130, 44, 70)],
		"outline": Color8(78, 26, 42), "ink": Color8(150, 70, 84),
		"hole": [Color8(60, 14, 30), Color8(176, 84, 100)],
		"menu": Color8(230, 160, 164),
	},
	{   # 3 Sewer: grey-green stone flags, dark brick walls, a murky trickle
		"kind": "sewer",
		"floor": [Color8(150, 162, 140), Color8(134, 146, 124), Color8(116, 130, 108)],
		"wall": [Color8(150, 104, 86), Color8(124, 82, 68), Color8(104, 66, 56), Color8(74, 48, 44)],
		"outline": Color8(34, 36, 34), "ink": Color8(80, 92, 74),
		"hole": [Color8(22, 30, 30), Color8(110, 116, 108)],
		"menu": Color8(146, 160, 136),
	},
	{   # 4 Factory: blue-grey steel, girders with rivets and hazard stripes
		"kind": "factory",
		"floor": [Color8(170, 182, 196), Color8(150, 162, 178), Color8(196, 206, 216)],
		"wall": [Color8(132, 146, 168), Color8(108, 122, 146), Color8(92, 104, 128), Color8(58, 66, 86)],
		"outline": Color8(30, 34, 46), "ink": Color8(84, 96, 116),
		"hole": [Color8(20, 22, 30), Color8(238, 190, 60)],
		"menu": Color8(160, 172, 188),
	},
	{   # 5 Space: a dark deck with stars, lavender moon-rock walls
		"kind": "space",
		"floor": [Color8(40, 42, 82), Color8(32, 34, 70), Color8(232, 228, 255)],
		"wall": [Color8(196, 186, 220), Color8(168, 156, 198), Color8(140, 128, 176), Color8(96, 84, 134)],
		"outline": Color8(14, 12, 30), "ink": Color8(120, 124, 190),
		"hole": [Color8(6, 4, 14), Color8(170, 120, 230)],
		"menu": Color8(92, 90, 150),
	},
]

static var _cache := {}

## One floor pixel (board px x, y), before the walls' drop shadow
static func floor_px(th: Dictionary, x: int, y: int, knots: Array) -> Color:
	var f: Array = th["floor"]
	match th["kind"]:
		"tiles":
			# 7 px glazed tiles: white grout lines, a glint in each tile's top-left corner, every
			# other tile a touch darker
			var lx := x % 7
			var ly := y % 7
			if lx == 0 or ly == 0:
				return f[2]
			if lx == 1 and ly == 1:
				return f[2].lerp(f[0], 0.4)
			return f[0] if ((x / 7) + (y / 7)) % 2 == 0 else f[1]
		"gut":
			# soft lining: broad gentle folds, a few lighter ridges
			var g := sin(x * 0.2 + sin(y * 0.09) * 2.0) + sin(y * 0.17 + sin(x * 0.11) * 1.4)
			var c: Color = f[0]
			if g > 1.25:
				c = f[2]
			elif g < -1.35:
				c = f[1]
			return c
		"sewer":
			# stone flags: rows 7 px tall, every other row offset, joints dark, a few wet spots
			var row := y / 7
			var lx2 := (x + (3 if row % 2 else 0)) % 10
			if y % 7 == 0 or lx2 == 0:
				return f[2]
			var w := sin(x * 0.9 + y * 0.4) + sin(y * 1.3 - x * 0.2)
			return f[1] if w > 1.3 else f[0]
		"factory":
			# diamond plate: a raised diamond every 6 px, staggered
			var cx := x % 6
			var cy := y % 6
			var off := 3 if (y / 6) % 2 else 0
			var dx := absi(((x + off) % 6) - 3)
			var dy := absi(cy - 3)
			if dx + dy == 1 and cy < 3:
				return f[2]                                   # the diamond's lit top
			if dx + dy == 1:
				return f[1]
			return f[0] if cx != 0 else f[0].darkened(0.04)
		"space":
			# deep blue deck: faint panel seams, a field of fixed stars
			if x % 28 == 0 or y % 28 == 0:
				return f[1]
			var h := int((x * 73856093) ^ (y * 19349663)) & 1023
			if h < 6:
				return f[2]
			if h < 14:
				return f[2].lerp(f[0], 0.6)
			return f[0]
		_:
			# plywood: soft wavy grain bands + a few knots
			var g2 := sin(y * 0.55 + sin(x * 0.07 + y * 0.02) * 2.4)
			var c2: Color = f[0] if g2 < 0.45 else f[1]
			for kp in knots:
				var kd := Vector2((x - kp.x) * 0.6, y - kp.y).length()
				if kd < 2.2:
					c2 = f[2]
				elif kd < 3.4:
					c2 = f[1]
			return c2

## One wall pixel: m = distance to the nearest open side (0 = the edge), d_* to each open side
static func wall_px(th: Dictionary, x: int, y: int, m: int, d_up: int, d_dn: int, d_lf: int, d_rt: int, vertical: bool) -> Color:
	var w: Array = th["wall"]          # [lit top, mid, grain / pattern, front face]
	if m <= 1:
		return th["outline"]                                  # (2 px thick)
	if d_dn <= 4:
		var face: Color = w[3].darkened(0.1 * (4 - d_dn))      # the front face, darker at the base
		if th["kind"] == "factory" and d_dn >= 2 and ((x + y) / 3) % 2 == 0:
			return Color8(226, 178, 52).darkened(0.1 * (4 - d_dn))   # hazard stripes
		return face
	if d_up <= 2 or d_lf <= 2:
		return w[0]                                           # lit edges
	if d_rt <= 2:
		return w[1].darkened(0.08)
	var along := float(y if vertical else x)
	var across := float(x if vertical else y)
	match th["kind"]:
		"tiles":
			# ceramic: square glaze tiles, a glossy pixel on each
			if x % 7 == 0 or y % 7 == 0:
				return w[2]
			return w[0] if x % 7 == 2 and y % 7 == 2 else w[1]
		"gut":
			# plump and wet: soft bands, shiny spots
			var s := sin(along * 0.3 + across * 0.9)
			if s > 0.9 and int(along) % 5 == 0:
				return w[0].lightened(0.25)
			return w[1] if s < 0.3 else w[2]
		"sewer":
			# bricks: 3 px courses, staggered
			var row := y / 3
			if y % 3 == 0 or (x + (2 if row % 2 else 0)) % 6 == 0:
				return w[3]
			return w[1] if (x / 6 + row) % 3 else w[2]
		"factory":
			# a steel girder: a rivet every 6 px along its middle
			if int(along) % 6 == 0 and int(across) % 7 == 3:
				return w[0].lightened(0.2)
			return w[1]
		"space":
			# moon rock: lumpy, with small craters
			var cr := sin(x * 0.8) * sin(y * 0.7) + sin(x * 0.31 + y * 0.53)
			if cr > 1.4:
				return w[3]
			return w[1] if cr < 0.5 else w[2]
		_:
			var grain := sin(across * 1.3 + sin(along * 0.11 + across * 0.7) * 1.6)
			if grain > 0.85:
				return w[2].darkened(0.08)
			return w[1] if grain < 0.35 else w[2]

# ------------------------------------------------------------------ the exit (the trapdoor) and the vault fences, per world

## Each world's trapdoor: [door, door's darker board, straps, strap highlight, seam / rim, frame side,
## handle, the water down there] and how its doors are built ("planks" / "plates" / "flaps")
const HATCH := [
	{ "build": "planks", "c": [Color8(176, 112, 64), Color8(150, 92, 50), Color8(78, 74, 80), Color8(132, 128, 136), Color8(74, 44, 32), Color8(132, 84, 48), Color8(206, 176, 92), Color8(36, 62, 96)] },
	# bath: a chrome drain cover in two halves
	{ "build": "plates", "c": [Color8(214, 226, 236), Color8(184, 198, 212), Color8(150, 164, 180), Color8(250, 252, 255), Color8(46, 64, 84), Color8(122, 154, 188), Color8(250, 252, 255), Color8(60, 120, 170)] },
	# gut: two plump flaps
	{ "build": "flaps", "c": [Color8(224, 118, 132), Color8(200, 92, 112), Color8(176, 68, 92), Color8(246, 170, 176), Color8(78, 26, 42), Color8(130, 44, 70), Color8(250, 196, 192), Color8(110, 40, 60)] },
	# sewer: rusty iron doors with bolts
	{ "build": "plates", "c": [Color8(120, 104, 92), Color8(98, 84, 76), Color8(150, 92, 60), Color8(176, 150, 128), Color8(34, 36, 34), Color8(74, 48, 44), Color8(186, 120, 70), Color8(52, 80, 70)] },
	# factory: steel doors with hazard stripes
	{ "build": "hazard", "c": [Color8(132, 146, 168), Color8(108, 122, 146), Color8(30, 30, 34), Color8(226, 178, 52), Color8(30, 34, 46), Color8(58, 66, 86), Color8(226, 178, 52), Color8(40, 90, 140)] },
	# space: an airlock, white panels and a little light
	{ "build": "airlock", "c": [Color8(232, 228, 248), Color8(200, 194, 226), Color8(140, 128, 176), Color8(255, 255, 255), Color8(14, 12, 30), Color8(96, 84, 134), Color8(120, 236, 200), Color8(70, 40, 120)] },
]

## The trapdoor's frame: a rim round a deep opening (seen when it opens), s = its opening + 4
static func hatch_frame(w: int, s: int) -> Texture2D:
	var key := "hframe_%d" % w
	if key in _cache:
		return _cache[key]
	var c: Array = HATCH[w]["c"]
	var img := _img(s, s)
	for y in s:
		for x in s:
			var e := mini(mini(x, y), mini(s - 1 - x, s - 1 - y))
			var col: Color
			if e == 0:
				col = c[4]
			elif e == 1:
				col = c[5] if (x + y) % 5 != 0 else c[5].darkened(0.15)
			elif e == 2 and (y == 2 or x == 2):
				col = c[4].darkened(0.2)                     # the opening's shadowed inner lip
			else:
				col = c[7]                                   # deep water down there
			img.set_pixel(x, y, col)
	for p in [Vector2i(1, 1), Vector2i(s - 2, 1), Vector2i(1, s - 2), Vector2i(s - 2, s - 2)]:
		img.set_pixel(p.x, p.y, c[3] if w != 0 else Color8(70, 70, 76))     # corner bolts
	return _tex(key, img)

## One trapdoor door (the left one; the right is mirrored): hinge on the left edge, the seam on
## the right with half of the handle; w x h px
static func hatch_leaf(w: int, lw: int, lh: int) -> Texture2D:
	var key := "hleaf_%d" % w
	if key in _cache:
		return _cache[key]
	var c: Array = HATCH[w]["c"]
	var build: String = HATCH[w]["build"]
	var img := _img(lw, lh)
	for y in lh:
		for x in lw:
			var col: Color = c[0]
			match build:
				"planks":
					col = c[0] if (y / 3) % 2 == 0 else c[1]
					if y % 3 == 2:
						col = col.darkened(0.18)             # gaps between the boards
					if (x * 7 + y * 3) % 11 == 0:
						col = col.darkened(0.08)             # grain specks
					if y == 3 or y == lh - 4:
						col = c[2] if x > 0 else c[3]        # iron straps from the hinge
				"plates":
					col = c[0] if y < lh / 2 else c[1]       # lit top half, shaded bottom
					if y == 1 or x == 1:
						col = c[3]                           # a lit bevel
					if (x == 2 or x == lw - 3) and (y == 2 or y == lh - 3):
						col = c[2]                           # bolts
					if y % 4 == 0 and x > 2 and x < lw - 3 and build == "plates" and w == 1:
						col = c[2].lightened(0.3)            # the drain's slots
				"flaps":
					var bulge := sin(float(y) / lh * PI)
					col = c[0].lerp(c[3], 0.35) if x < lw * 0.4 * bulge + 1 else (c[0] if x < lw - 2 else c[1])
					if (x + y * 2) % 9 == 0:
						col = c[1]                           # wrinkles
				"hazard":
					col = c[0] if y < lh / 2 else c[1]
					if y >= lh - 4 or y <= 2:
						col = c[3] if ((x + y) / 2) % 2 == 0 else c[2]   # hazard bands
					if y == 3:
						col = c[3].darkened(0.4)
				"airlock":
					col = c[0] if y < lh / 2 else c[1]
					if y % 5 == 0:
						col = c[2]                           # panel seams
					if x == 1:
						col = c[3]
			if x == lw - 1:
				col = c[4]                                   # the seam
			elif x == 0 and y % 6 == 1 and build == "planks":
				col = c[3]                                   # hinge pins
			img.set_pixel(x, y, col)
	# half of the handle at the seam (a ring, a grip, a light...)
	for p in [Vector2i(lw - 3, 8), Vector2i(lw - 4, 9), Vector2i(lw - 3, 10), Vector2i(lw - 2, 11)]:
		img.set_pixel(p.x, p.y, c[6])
	img.set_pixel(lw - 2, 8, c[6].darkened(0.45))
	return _tex(key, img)

# ------------------------------------------------------------------ small sprites (shown x4)

static func _img(w: int, h: int) -> Image:
	return Image.create(w, h, false, Image.FORMAT_RGBA8)

static func _tex(key: String, img: Image) -> Texture2D:
	var t := ImageTexture.create_from_image(img)
	_cache[key] = t
	return t

## A hole in the floor, in the world's material (17 x 17 px): the board's dark pit, a rim lit at
## the bottom and shadowed at the top, plus the world's detail (a drain's bars, a pit's hazard ring...)
static func hole(w: int) -> Texture2D:
	var key := "hole_%d" % w
	if key in _cache:
		return _cache[key]
	var th: Dictionary = THEMES[w]
	var dark: Color = th["hole"][0]
	var rim: Color = th["hole"][1]
	const S := 17
	var r := 7.0
	var img := _img(S, S)
	var c := Vector2(S / 2.0, S / 2.0)
	for y in S:
		for x in S:
			var off := Vector2(x + 0.5, y + 0.5) - c
			var d := off.length()
			if d > r + 0.5:
				continue
			var col := dark
			if d > r - 0.5:
				col = rim.lightened(0.15) if off.y > 0 else th["outline"]
			elif d > r - 1.5 and off.y > 0:
				col = rim
			elif d < r * 0.45:
				col = dark.darkened(0.3)
			match th["kind"]:
				"tiles":                       # a drain: steel bars across
					if d <= r - 1.5 and x % 3 == 0:
						col = rim.darkened(0.15)
				"factory":                     # a hazard ring round the pit
					if d > r - 1.5 and d <= r + 0.5 and int(off.angle() * 4.0 / PI + 8.0) % 2 == 0:
						col = Color8(30, 30, 34)
				"space":                       # a black hole: a violet swirl round the dark
					if d > r * 0.45 and d <= r - 1.5 and fposmod(off.angle() * 2.0 / TAU + d * 0.18, 1.0) < 0.3:
						col = rim.darkened(0.35)
				"gut":                         # a pore: a puckered pink lip
					if d > r - 2.5 and d <= r - 1.5:
						col = rim.darkened(0.2)
			img.set_pixel(x, y, col)
	return _tex(key, img)

## The collectible of a world (15 x 15 px, x4): taken = a dull ghost of it
static func pickup(w: int, taken := false) -> Texture2D:
	var key := "pick_%d_%s" % [w, taken]
	if key in _cache:
		return _cache[key]
	const S := 15
	var img := _img(S, S)
	var c := Vector2(S / 2.0, S / 2.0)
	for y in S:
		for x in S:
			var off := Vector2(x + 0.5, y + 0.5) - c
			var d := off.length()
			var col := Color(0, 0, 0, 0)
			match w:
				1:  # a soap bubble: a clear ball, a pale rim, a big white glint
					if d <= 7.0:
						col = Color8(150, 200, 230, 110)
						if d > 6.0:
							col = Color8(60, 110, 150)
						elif d > 4.9:
							col = Color8(206, 236, 250, 200)
						if Vector2(off.x + 2.6, off.y + 2.6).length() < 1.7:
							col = Color8(255, 255, 255)
						elif off.x > 1.5 and off.y > 1.5 and absf(d - 4.4) < 0.7:
							col = Color8(236, 196, 250, 220)      # a rainbow sheen
				2:  # a glowing spore: a lit ball in a soft green halo, its glow brightest up-left
					if d <= 7.0:
						col = Color8(160, 236, 120, 90)
						if d > 6.2:
							col = Color8(70, 130, 60, 160)
						elif d < 5.4:
							col = _sphere_px(off, 5.4, [Color8(255, 255, 230), Color8(244, 255, 196), Color8(196, 246, 120), Color8(140, 214, 96), Color8(96, 170, 74)], Color8(96, 170, 74))
				3:  # a lost gold ring
					if d <= 7.0 and d >= 3.0:
						col = Color8(244, 196, 70) if off.x + off.y < 0 else Color8(206, 146, 40)
						if d > 6.1 or d < 3.9:
							col = Color8(110, 70, 20)
						elif Vector2(off.x + 3.0, off.y + 3.0).length() < 1.2:
							col = Color8(255, 246, 200)
						if absf(off.x - 0.5) < 1.6 and off.y < -5.0:
							col = Color8(150, 220, 240)               # its gem
				4:  # a hex nut
					var hx := maxf(absf(off.x) * 0.866 + absf(off.y) * 0.5, absf(off.y))
					if hx <= 6.6 and d >= 2.3:
						col = Color8(196, 204, 216) if off.x + off.y < 0 else Color8(148, 156, 172)
						if hx > 5.7 or d < 3.2:
							col = Color8(52, 58, 74)
						elif absf(off.x + off.y + 6.0) < 1.0:
							col = Color8(240, 244, 250)
				5:  # a little star
					var a := off.angle() + PI / 2.0
					var edge := 3.4 + 3.4 * pow(absf(cos(a * 2.5)), 3.0)
					if d <= edge:
						col = Color8(252, 226, 96) if off.x + off.y < 0 else Color8(236, 176, 50)
						if d > edge - 1.0:
							col = Color8(120, 70, 20)
						elif Vector2(off.x + 1.6, off.y + 1.6).length() < 1.1:
							col = Color8(255, 252, 220)
				_:  # 0: an amber glass marble: a lit ball, a glint, light through the glass below
					if d <= 7.0:
						col = _sphere_px(off, 7.0, [Color8(255, 246, 214), Color8(250, 200, 96), Color8(234, 160, 56), Color8(204, 118, 36), Color8(150, 78, 24)], Color8(112, 58, 20))
						if d <= 6.0 and Vector2(off.x - 1.8, off.y - 2.2).length() < 1.4:
							col = Color8(252, 210, 110)              # light through the glass
			if col.a > 0.0 and taken:
				col = Color(col.r * 0.5 + 0.2, col.g * 0.45 + 0.15, col.b * 0.45 + 0.13, col.a * 0.45)
			img.set_pixel(x, y, col)
	return _tex(key, img)

## A ball's pixel, lit like the pal's ball (tilt_ball.gdshader: from the top-left, in front): off
## from its middle, r its radius; tones [shine, lit, mid, shade, dark side], the outline ink, a bounce
## of light along the lower right rim
const LIGHT := Vector3(-0.55, -0.65, 0.75)
static func _sphere_px(off: Vector2, r: float, tones: Array, ink: Color) -> Color:
	var d := off.length()
	if d > r:
		return Color(0, 0, 0, 0)
	if d > r - 1.0:
		return ink
	var q := off / (r - 1.0)
	var n := Vector3(q.x, q.y, sqrt(maxf(0.0, 1.0 - q.length_squared())))
	var dif := n.dot(LIGHT.normalized())
	if dif > 0.95:
		return tones[0]
	if dif > 0.72:
		return tones[1]
	if dif > 0.4:
		return tones[2]
	if dif > 0.1 or (q.length() > 0.6 and q.x + q.y > 0.75):
		return tones[3]
	return tones[4]

## The low fence across a vault's door (the Fizzy pal hops it): pickets in the world's material
## under the striped rail (that rail is what says "a low fence" in every world), w x 9 px
## The pickets' colours per world: [lit, shaded] (wood, white ceramic, pink, rusty iron, steel, moon white)
const PICKETS := [
	[Color8(222, 172, 110), Color8(176, 124, 74)], [Color8(240, 246, 250), Color8(188, 210, 228)],
	[Color8(236, 140, 150), Color8(198, 92, 110)], [Color8(150, 112, 92), Color8(112, 80, 66)],
	[Color8(170, 182, 200), Color8(120, 134, 158)], [Color8(226, 220, 246), Color8(176, 166, 210)],
]

## lvl: the fence's height (the gate's level): one striped rail per level, a higher fence needs
## a stronger fizzy drink
static func fence(w: int, vertical: bool, world := 0, lvl := 1) -> Texture2D:
	var key := "fence_%d_%s_%d_%d" % [w, vertical, world, lvl]
	var pk: Array = PICKETS[world]
	if key in _cache:
		return _cache[key]
	var long := w
	var rails := clampi(lvl, 1, 3)
	var SHORT := 9 + (rails - 1) * 3
	var img := _img(SHORT if vertical else long, long if vertical else SHORT)
	var ink := Color8(58, 34, 30)
	var top := 1 + (rails - 1) * 3                       # (the pickets start under the last rail)
	for a in long:
		for b in SHORT:
			var col := Color(0, 0, 0, 0)
			if b <= top + 2 and b >= 1:
				var rb := (b - 1) % 3
				if rb == 0:
					col = ink                                 # each rail's top edge
				else:
					col = Color8(236, 76, 76) if (a / 3) % 2 == 0 else Color8(250, 244, 230)   # the striped rail
					if rb == 1:
						col = col.lightened(0.15)
			elif b <= top + 6:
				if a % 4 == 3:
					col = Color(0, 0, 0, 0)                  # the gaps between the pickets
				else:
					col = pk[0] if b < top + 5 else pk[1]
			elif b == top + 7 and a % 4 != 3:
				col = ink                                     # the pickets' feet
			if (a == 0 or a == long - 1) and b >= 1:
				col = ink                                     # the end posts
			if col.a > 0.0:
				if vertical:
					img.set_pixel(b, a, col)
				else:
					img.set_pixel(a, b, col)
	return _tex(key, img)

## A cracked wall across a vault's door (a sturdy pal rams through it): a block of the world's
## wall, lit on top, its front face darker, split by dark cracks; w x 8 px
static func cracked_wall(w: int, vertical: bool, world := 0) -> Texture2D:
	var key := "crack_%d_%s_%d" % [w, vertical, world]
	if key in _cache:
		return _cache[key]
	var th: Dictionary = THEMES[world]
	var wc: Array = th["wall"]
	var ink: Color = th["outline"]
	const SHORT := 8
	var img := _img(SHORT if vertical else w, w if vertical else SHORT)
	for a in w:
		for b in SHORT:
			var col: Color = wc[1]
			if b == 0 or b == SHORT - 1 or a == 0 or a == w - 1:
				col = ink
			elif b == 1:
				col = wc[0]                                   # the lit top edge
			elif b >= SHORT - 3:
				col = wc[2]                                   # the darker front face
			# the cracks: a zigzag every 7 px, a branch on the long ones
			var ca := a % 7
			if b >= 1 and b < SHORT - 1 and ((ca == 3 and b % 2 == 0) or (ca == 4 and b % 2 == 1)) and a > 1 and a < w - 2:
				col = ink
			if b == 3 and (a % 7 == 5 or a % 7 == 6) and a < w - 2:
				col = ink.lerp(wc[2], 0.3)
			if vertical:
				img.set_pixel(b, a, col)
			else:
				img.set_pixel(a, b, col)
	return _tex(key, img)

## A deep water channel across a vault's door (a splashy pal skims over it): dark deep water in
## the middle, lighter water and foam at its banks, ripples; w x 10 px
static func channel(w: int, vertical: bool) -> Texture2D:
	var key := "chan_%d_%s" % [w, vertical]
	if key in _cache:
		return _cache[key]
	const SHORT := 10
	var img := _img(SHORT if vertical else w, w if vertical else SHORT)
	for a in w:
		for b in SHORT:
			var col := Color8(54, 104, 168)
			if b == 0 or b == SHORT - 1:
				col = Color8(36, 52, 84)                      # the banks' edge
			elif b == 1 or b == SHORT - 2:
				col = Color8(226, 244, 252) if (a / 2) % 3 != 0 else Color8(150, 200, 236)   # foam
			elif b == 2 or b == SHORT - 3:
				col = Color8(96, 156, 214)
			elif b >= 4 and b <= 5:
				col = Color8(32, 70, 128)                     # the deep middle
			if (b == 3 and a % 6 == 2) or (b == 6 and a % 6 == 5):
				col = Color8(170, 214, 244)                   # ripples
			if vertical:
				img.set_pixel(b, a, col)
			else:
				img.set_pixel(a, b, col)
	return _tex(key, img)

## A shutter across a vault's door (it snaps open for an instant: a focused pal times it): metal
## slats with lit edges, a warning stripe at each end; w x 7 px
static func shutter(w: int, vertical: bool, world := 0) -> Texture2D:
	var key := "shut_%d_%s_%d" % [w, vertical, world]
	if key in _cache:
		return _cache[key]
	var ink: Color = THEMES[world]["outline"]
	const SHORT := 7
	var img := _img(SHORT if vertical else w, w if vertical else SHORT)
	for a in w:
		for b in SHORT:
			var col := Color8(176, 186, 200)
			if b == 0 or b == SHORT - 1 or a == 0 or a == w - 1:
				col = ink
			elif a % 3 == 0:
				col = Color8(120, 130, 150)                   # between the slats
			elif b == 1:
				col = Color8(222, 230, 240)
			elif b == SHORT - 2:
				col = Color8(140, 150, 168)
			if (a <= 3 or a >= w - 4) and b > 0 and b < SHORT - 1 and a > 0 and a < w - 1:
				col = Color8(250, 204, 60) if (a + b) % 2 == 0 else Color8(40, 40, 46)   # hazard ends
			if vertical:
				img.set_pixel(b, a, col)
			else:
				img.set_pixel(a, b, col)
	return _tex(key, img)

## A treasure chest (a lucky pal finds the key): shut, or open with its lid up; 15 x 14 px
static func chest(open: bool) -> Texture2D:
	var key := "chest_%s" % open
	if key in _cache:
		return _cache[key]
	var rows_shut := [
		"...............",
		"..###########..",
		".#WWWWWWWWWWW#.",
		"#WwwwwGwwwwwwW#",
		"#wwwwwGwwwwwww#",
		"###############",
		"#bbbbbGbbbbbbb#",
		"#bbbbGKGbbbbbb#",
		"#bbbbbKbbbbbbb#",
		"#ddddddddddddd#",
		"#ddddddddddddd#",
		"#GdddddddddddG#",
		"###############",
		"...............",
	]
	var rows_open := [
		"..###########..",
		".#WWWWWWWWWWW#.",
		"#wWWWWWWWWWWWw#",
		"#####.....#####",
		"#oooooooooooooo#".substr(0, 15),
		"#oOOOOOOOOOOOo#",
		"#bbbbbGbbbbbbb#",
		"#bbbbbbbbbbbbb#",
		"#bbbbbbbbbbbbb#",
		"#ddddddddddddd#",
		"#ddddddddddddd#",
		"#GdddddddddddG#",
		"###############",
		"...............",
	]
	var cols := { "#": Color8(58, 34, 26), "W": Color8(206, 136, 70), "w": Color8(178, 108, 52),
		"b": Color8(188, 118, 58), "d": Color8(150, 88, 42), "G": Color8(246, 204, 70), "K": Color8(58, 34, 26),
		"o": Color8(40, 22, 18), "O": Color8(250, 226, 120) }
	var rows: Array = rows_open if open else rows_shut
	var img := _img(15, 14)
	for y in rows.size():
		for x in mini(15, String(rows[y]).length()):
			var ch: String = rows[y][x]
			if ch in cols:
				img.set_pixel(x, y, cols[ch])
	return _tex(key, img)

# ---------------------------------------------------------------- BLOCKERS (one kind per world)

## A round thing seen from above, lit from the top-left: fill colours [lit, mid, shade], an outline
static func _disc(img: Image, c: Vector2, r: float, cols: Array, ink: Color) -> void:
	for y in img.get_height():
		for x in img.get_width():
			var off := Vector2(x + 0.5, y + 0.5) - c
			var d := off.length()
			if d > r + 0.5:
				continue
			var col: Color = cols[1]
			if d > r - 0.5:
				col = ink
			elif (off.x + off.y) < -r * 0.55:
				col = cols[0]
			elif (off.x + off.y) > r * 0.5:
				col = cols[2]
			img.set_pixel(x, y, col)

## World 1: a wooden peg that pops up in a doorway. up = its round top (a peg standing up),
## else the flush disc it sinks into; 17 x 17 px
static func peg(up: bool) -> Texture2D:
	var key := "peg_%s" % up
	if key in _cache:
		return _cache[key]
	var img := _img(17, 17)
	var ink := Color8(74, 44, 32)
	if up:
		_disc(img, Vector2(8.5, 8.5), 7.5, [Color8(246, 204, 140), Color8(224, 170, 104), Color8(186, 128, 72)], ink)
		for x in range(5, 12):                                # the end grain's rings
			if Vector2(x + 0.5 - 8.5, 0).length() < 3.6:
				img.set_pixel(x, 8, Color8(196, 140, 84))
		img.set_pixel(8, 7, Color8(196, 140, 84))
		img.set_pixel(8, 9, Color8(196, 140, 84))
	else:
		# sunk flush with the board: a plug of the floor's own plywood, ringed by its dark seam,
		# a little dot in the middle (where it pops up from)
		var c := Vector2(8.5, 8.5)
		for y in 17:
			for x in 17:
				var d := (Vector2(x + 0.5, y + 0.5) - c).length()
				if d > 7.0:
					continue
				var col := Color8(230, 196, 146)
				if d > 6.2:
					col = Color8(150, 104, 66)
				elif d > 5.4:
					col = Color8(212, 172, 118)
				elif d < 1.2:
					col = Color8(150, 104, 66)
				img.set_pixel(x, y, col)
	return _tex(key, img)

## The marble tray's empty socket on the HUD rail: a dark round recess with a lit lower lip
static func socket() -> Texture2D:
	if "socket" in _cache:
		return _cache["socket"]
	var img := _img(15, 15)
	var c := Vector2(7.5, 7.5)
	for y in 15:
		for x in 15:
			var off := Vector2(x + 0.5, y + 0.5) - c
			var d := off.length()
			if d > 7.0:
				continue
			var col := Color(0.0, 0.0, 0.0, 0.42)
			if d > 6.0:
				col = Color(1.0, 0.95, 0.85, 0.35) if off.y > 0.0 else Color(0.0, 0.0, 0.0, 0.6)
			img.set_pixel(x, y, col)
	return _tex("socket", img)

## World 2: a rubber duck seen from above, its head towards +x; 17 x 15 px
static func duck() -> Texture2D:
	if "duck" in _cache:
		return _cache["duck"]
	var rows := [
		".................",
		"....######.......",
		"...#YYYYYY##.....",
		"..#YyyyyyyY#####.",
		".#YyyyyyyyY#YYY#.",
		".#yyyyyyyyy#yyYY#",
		"#yyyyyyyyyyyyKyO#",
		"#yyyyyyyyyyyyyyOO",
		"#yyyyyyyyyyyyyyOO",
		"#ssyyyyyyyyyyyyy#",
		".#ssyyyyyyy#yyy#.",
		".#sssssyyss#####.",
		"..##sssssss#.....",
		"....#######......",
		".................",
	]
	var cols := { "#": Color8(74, 50, 20), "Y": Color8(255, 240, 140), "y": Color8(250, 214, 64), "s": Color8(222, 172, 40),
		"K": Color8(30, 24, 20), "O": Color8(240, 120, 40) }
	var img := _img(17, 15)
	for y in rows.size():
		for x in 17:
			var ch: String = rows[y][x]
			if ch in cols:
				img.set_pixel(x, y, cols[ch])
	return _tex("duck", img)

## World 3: one of a gut valve's two fleshy lips (they close in from both sides of a doorway);
## 9 x 15 px, the lip's round edge on the right
static func valve_lip() -> Texture2D:
	if "lip" in _cache:
		return _cache["lip"]
	var img := _img(9, 15)
	var ink := Color8(78, 26, 42)
	for y in 15:
		for x in 9:
			var off := Vector2((x + 0.5) - 1.0, (y + 0.5) - 7.5)
			var e := Vector2(off.x / 7.6, off.y / 7.2).length()     # an oval bulging to the right
			if e > 1.0 or off.x < -1.0:
				continue
			var col := Color8(222, 112, 128)
			if e > 0.86:
				col = ink
			elif off.y < -3.0 and off.x > 1.0:
				col = Color8(246, 160, 168)                   # the wet sheen on top
			elif off.y > 3.0:
				col = Color8(184, 76, 98)
			if absi(int(off.y)) % 3 == 0 and off.x > 4.0 and e < 0.86:
				col = Color8(170, 66, 88)                     # wrinkles
			img.set_pixel(x, y, col)
	return _tex("lip", img)

## World 4: a sewer rat seen from above, its nose towards +x; frame 0 / 1 (its legs); 19 x 11 px
static func rat(frame: int) -> Texture2D:
	var key := "rat_%d" % frame
	if key in _cache:
		return _cache[key]
	var rows := [
		"..........#.#......",
		"....#####.#P#......",
		"...#ggggg#####.....",
		"t.#gGGGGGGGgg###...",
		".t#gGGGGGGGGGgggK#.",
		"..tgGGGGGGGGGGgggPN",
		".t#gGGGGGGGGGgggK#.",
		"t.#gGGGGGGGgg###...",
		"...#ggggg#####.....",
		"....#####.#P#......",
		"..........#.#......",
	]
	var cols := { "#": Color8(34, 30, 34), "g": Color8(110, 104, 112), "G": Color8(150, 144, 152), "K": Color8(20, 18, 22),
		"P": Color8(236, 150, 160), "N": Color8(236, 120, 140), "t": Color8(196, 130, 140) }
	var img := _img(19, 11)
	for y in rows.size():
		for x in 19:
			var ch: String = rows[y][x]
			if ch in cols:
				var yy := y
				if frame == 1 and ch == "P" and (y <= 1 or y >= 9):
					continue                                  # (the other step: feet tucked in)
				img.set_pixel(x, yy, cols[ch])
	return _tex(key, img)

## World 4: the rat's den, a little round sewer grate in the floor it pops out of and back into
## (dark slots between grey bars, a lit rim); 15 x 15 px
static func rat_den() -> Texture2D:
	if "den" in _cache:
		return _cache["den"]
	var img := _img(15, 15)
	var c := Vector2(7.5, 7.5)
	for y in 15:
		for x in 15:
			var off := Vector2(x + 0.5, y + 0.5) - c
			var d := off.length()
			if d > 7.0:
				continue
			var col := Color8(96, 98, 104)
			if d > 6.0:
				col = Color8(36, 34, 40)
			elif d > 5.0:
				col = Color8(150, 152, 158) if off.x + off.y < 0.0 else Color8(110, 112, 118)
			elif y % 3 == 1:
				col = Color8(24, 22, 28)                          # the slots
			img.set_pixel(x, y, col)
	return _tex("den", img)

## World 5: a fire jet's burner plate in the floor (a round grate with a hazard ring); 15 x 15 px
static func burner() -> Texture2D:
	if "burner" in _cache:
		return _cache["burner"]
	var img := _img(15, 15)
	var c := Vector2(7.5, 7.5)
	for y in 15:
		for x in 15:
			var off := Vector2(x + 0.5, y + 0.5) - c
			var d := off.length()
			if d > 7.0:
				continue
			var col := Color8(60, 62, 72)
			if d > 6.0:
				col = Color8(30, 34, 46)
			elif d > 4.6:
				col = Color8(250, 204, 60) if int(off.angle() * 4.0 / PI + 8.0) % 2 == 0 else Color8(36, 36, 40)
			elif (x + y) % 3 == 0:
				col = Color8(34, 34, 40)                      # the grate's holes
			img.set_pixel(x, y, col)
	return _tex("burner", img)

## A fire jet's flame (frame 0 / 1 flicker); small = the blue pilot flame before it flares;
## 15 x 17 px, its base at the bottom middle
static func flame(frame: int, small: bool) -> Texture2D:
	var key := "flame_%d_%s" % [frame, small]
	if key in _cache:
		return _cache[key]
	var img := _img(15, 17)
	var h := 6.0 if small else 15.0
	var w := 3.0 if small else 6.5
	for y in 17:
		for x in 15:
			var fx := (x + 0.5 - 7.5) / w
			var fy := (16.5 - (y + 0.5)) / h                # 0 at the base, 1 at the tip
			if fy < 0.0 or fy > 1.0:
				continue
			var wob := sin(fy * 7.0 + frame * 2.2) * 0.12
			var half := (1.0 - fy) * (0.6 + 0.4 * sin(fy * PI)) + 0.08
			var dx := absf(fx - wob)
			if dx > half:
				continue
			var t := dx / maxf(half, 0.01)
			var col: Color
			if small:
				col = Color8(120, 190, 255) if t < 0.5 else Color8(60, 110, 220)
			else:
				col = Color8(255, 246, 180) if t < 0.35 and fy < 0.7 else (Color8(252, 188, 60) if t < 0.7 else Color8(232, 96, 40))
			if t > 0.85:
				col = Color8(120, 40, 24) if not small else Color8(30, 50, 120)
			img.set_pixel(x, y, col)
	return _tex(key, img)

## World 6: a meteor (a glowing rock with a trail), 17 x 17 px; its target ring, 19 x 19 px
static func meteor() -> Texture2D:
	if "meteor" in _cache:
		return _cache["meteor"]
	var img := _img(17, 17)
	for y in 17:
		for x in 17:
			var off := Vector2(x + 0.5 - 10.5, y + 0.5 - 6.5)
			var d := off.length()
			if d <= 5.5:
				var col := Color8(150, 120, 110) if off.x + off.y < 0 else Color8(104, 80, 76)
				if d > 4.6:
					col = Color8(40, 24, 30)
				elif Vector2(off.x + 1.5, off.y + 1.5).length() < 1.2:
					col = Color8(240, 210, 190)
				img.set_pixel(x, y, col)
			else:
				# the trail, streaming down-left behind it
				var along := -(off.x - off.y) / 1.414
				var across := absf(off.x + off.y) / 1.414
				if along > 4.0 and along < 14.0 and across < (14.0 - along) * 0.32:
					img.set_pixel(x, y, Color8(255, 220, 120) if across < 1.0 else Color8(240, 140, 80, 200))
	return _tex("meteor", img)

static func target_ring() -> Texture2D:
	if "target" in _cache:
		return _cache["target"]
	var img := _img(19, 19)
	var c := Vector2(9.5, 9.5)
	for y in 19:
		for x in 19:
			var d := (Vector2(x + 0.5, y + 0.5) - c).length()
			if absf(d - 8.0) < 0.7:
				img.set_pixel(x, y, Color8(255, 110, 110))
			elif d < 7.0:
				img.set_pixel(x, y, Color(0.05, 0.02, 0.1, 0.35))
	return _tex("target", img)

## A horseshoe magnet on a girder (12 x 12 px)
static func magnet() -> Texture2D:
	if "magnet" in _cache:
		return _cache["magnet"]
	var rows := [
		"..########..",
		".#RRRRRRRR#.",
		"#RRrrrrrrRR#",
		"#Rr######rR#",
		"#Rr#....#rR#",
		"#Rr#....#rR#",
		"#Rr#....#rR#",
		"#Rr#....#rR#",
		"#SS#....#SS#",
		"#Ss#....#Ss#",
		"#ss#....#ss#",
		"####....####",
	]
	var cols := { "#": Color8(40, 30, 40), "R": Color8(226, 70, 70), "r": Color8(176, 40, 52), "S": Color8(240, 244, 250), "s": Color8(170, 178, 194) }
	var img := _img(12, 12)
	for y in 12:
		for x in 12:
			var ch: String = rows[y][x]
			if ch in cols:
				img.set_pixel(x, y, cols[ch])
	return _tex("magnet", img)

## A goo puddle on the space deck (slows the ball): r px, a lumpy green blob
static func goo(r: int) -> Texture2D:
	var key := "goo_%d" % r
	if key in _cache:
		return _cache[key]
	var S := r * 2 + 2
	var img := _img(S, S)
	var c := Vector2(S / 2.0, S / 2.0)
	for y in S:
		for x in S:
			var off := Vector2(x + 0.5, y + 0.5) - c
			var lump := r + sin(off.angle() * 5.0) * 1.2
			var d := off.length()
			if d > lump:
				continue
			var col := Color8(120, 214, 96) if off.y < 0 else Color8(84, 176, 70)
			if d > lump - 1.0:
				col = Color8(30, 70, 34)
			elif (x * 5 + y * 3) % 17 == 0:
				col = Color8(196, 250, 160)                  # a bubble
			img.set_pixel(x, y, col)
	return _tex(key, img)

## A small sign by a vault's gate: the drink type that opens it and its level (UiArt.gate_badge
## on a card); 15 x 18 px
static func sign_card() -> Texture2D:
	if "sign" in _cache:
		return _cache["sign"]
	var img := _img(15, 18)
	for y in 18:
		for x in 15:
			var e := mini(mini(x, y), mini(14 - x, 17 - y))
			if e == 0 and (x == 0 or x == 14) and (y == 0 or y == 17):
				continue
			img.set_pixel(x, y, Color8(58, 38, 30) if e == 0 else Color8(250, 244, 214))
	return _tex("sign", img)

## A twinkle (5 x 5 px), for a vault's prize
static func twinkle() -> Texture2D:
	if "twinkle" in _cache:
		return _cache["twinkle"]
	var img := _img(5, 5)
	for p in [Vector2i(2, 0), Vector2i(2, 1), Vector2i(0, 2), Vector2i(1, 2), Vector2i(3, 2), Vector2i(4, 2), Vector2i(2, 3), Vector2i(2, 4)]:
		img.set_pixel(p.x, p.y, Color8(255, 250, 220))
	img.set_pixel(2, 2, Color8(255, 255, 255))
	return _tex("twinkle", img)
