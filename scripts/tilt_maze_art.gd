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
				2:  # a glowing spore: a bright core, a soft green halo
					if d <= 7.0:
						col = Color8(160, 236, 120, 90)
						if d < 5.2:
							col = Color8(196, 246, 120)
						if d < 3.6:
							col = Color8(244, 255, 196)
						if d > 6.2 and d <= 7.0:
							col = Color8(70, 130, 60, 160)
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
				_:  # 0: an amber glass marble: warm gold, a darker lower half, a glint
					if d <= 7.0:
						col = Color8(246, 186, 74) if off.x + off.y < 0 else Color8(214, 132, 40)
						if d > 6.1:
							col = Color8(112, 58, 20)
						elif Vector2(off.x + 2.5, off.y + 2.5).length() < 1.6:
							col = Color8(255, 240, 200)
						elif Vector2(off.x - 2.0, off.y - 2.4).length() < 1.3:
							col = Color8(250, 214, 120)              # light through the glass
			if col.a > 0.0 and taken:
				col = Color(col.r * 0.5 + 0.2, col.g * 0.45 + 0.15, col.b * 0.45 + 0.13, col.a * 0.45)
			img.set_pixel(x, y, col)
	return _tex(key, img)

## The low fence across a vault's door (the Fizzy pal hops it): wooden pickets under a striped
## rail, w x 9 px (w = the opening), seen from above at a slant like the walls
static func fence(w: int, vertical: bool) -> Texture2D:
	var key := "fence_%d_%s" % [w, vertical]
	if key in _cache:
		return _cache[key]
	var long := w
	const SHORT := 9
	var img := _img(SHORT if vertical else long, long if vertical else SHORT)
	var ink := Color8(58, 34, 30)
	for a in long:
		for b in SHORT:
			var col := Color(0, 0, 0, 0)
			if b == 1:
				col = ink                                     # the rail's top edge
			elif b <= 3:
				col = Color8(236, 76, 76) if (a / 3) % 2 == 0 else Color8(250, 244, 230)   # the striped rail
				if b == 2:
					col = col.lightened(0.15)
			elif b <= 7:
				if a % 4 == 3:
					col = Color(0, 0, 0, 0)                  # the gaps between the pickets
				else:
					col = Color8(222, 172, 110) if b < 6 else Color8(176, 124, 74)
			elif b == 8 and a % 4 != 3:
				col = ink                                     # the pickets' feet
			if (a == 0 or a == long - 1) and b >= 1:
				col = ink                                     # the end posts
			if col.a > 0.0:
				if vertical:
					img.set_pixel(b, a, col)
				else:
					img.set_pixel(a, b, col)
	return _tex(key, img)

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

## A small sign hung on a vault's fence: the drink type that opens it (its boost icon on a card)
static func sign_card() -> Texture2D:
	if "sign" in _cache:
		return _cache["sign"]
	var img := _img(13, 13)
	for y in 13:
		for x in 13:
			var e := mini(mini(x, y), mini(12 - x, 12 - y))
			if e == 0 and (x == 0 or x == 12) and (y == 0 or y == 12):
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
