extends RefCounted
class_name PalPrix2Art
## Pal Prix 2177's pixel pieces (the Turbo League): the one craft that turns from a hover car into a
## jet ski into a rocket, and the course's pieces. Hard pixels on the games' 4 px grid, a dark
## outline, lit from the top left (the Tilt Maze rules), drawn in code like Pal Prix's toys. The
## craft is "sprite-stacked" like them: its slices, bottom first, the same 30 x 26 canvas for all
## three forms (the body and the pal's seat never move; only the form's own parts change), nose
## to the right.

const OUTLINE := Color8(40, 30, 40)
const W := 30                          # the craft's canvas (board px)
const H := 26
const LAYERS := 6
## The pal's seat: board px from the canvas's middle, along the nose
const SEAT := -3.0

static var _cache := {}

## The body, the same in every form: the fuselage, the open cockpit (where the pal sits), the
## canopy, the white stripe down the nose
const BODY := [
	"..............................",
	"..............................",
	"..............................",
	"..............................",
	"..............................",
	"..............................",
	"..............................",
	".......###########............",
	".....##LLLLLLLLLLL####........",
	"....#RRRRRRRRRRRRRRRRLL##.....",
	"....#RRrrSSSSSSSGGgRRRRRL##...",
	"....#RrrSsssssssSGGgWWRRRRR#..",
	"....#RrrSsssssssSGGgWWWWWWWW#.",
	"....#RrrSsssssssSGGgWWWWWWWW#.",
	"....#RrrSsssssssSGGgWWRRRRRr#.",
	"....#RRrrSSSSSSSGGgRRRRRrr##..",
	"....#RRRRRRRRRRRRRRRRrr##.....",
	".....##rrrrrrrrrrr####........",
	".......###########............",
	"..............................",
	"..............................",
	"..............................",
	"..............................",
	"..............................",
	"..............................",
	"..............................",
]
## The hover car's own parts: two magnetic pods along its sides (their glowing strips), held by
## struts, and the rear wing joining them
const HOVER := [
	"..............................",
	"..............................",
	"..............................",
	"..###############.............",
	".#KWWWWWWWWWWWWWW##...........",
	"#nCRRRRRRRRRRRRRRRL#..........",
	"#nCrrrrrrrrrrrrrrrr#..........",
	"###mm#####mm#######...........",
	"#k#...........................",
	"#k#...........................",
	"#k#...........................",
	"#k#...........................",
	"#k#...........................",
	"#k#...........................",
	"#k#...........................",
	"#k#...........................",
	"#k#...........................",
	"#k#...........................",
	"###mm#####mm#######...........",
	"#nCRRRRRRRRRRRRRRRL#..........",
	"#nCrrrrrrrrrrrrrrrr#..........",
	".#krrrrrrrrrrrrrrr##..........",
	"..###############.............",
	"..............................",
	"..............................",
	"..............................",
]
## The jet ski's: a white hull round the body (its sponsons), the water jet at its back
const JETSKI := [
	"..............................",
	"..............................",
	"..............................",
	"..............................",
	"..............................",
	"....###########...............",
	"...#KWWWWWWWWWW####...........",
	"..#WwwwwwwwwwwwwwWW###........",
	"..#w#..............WWW##......",
	"..#w#.................W##.....",
	"##w#...................WW#....",
	"nn#.....................W#....",
	"Cn#......................W#...",
	"Cn#......................W#...",
	"nn#.....................W#....",
	"##w#...................WW#....",
	"..#w#.................W##.....",
	"..#w#..............WWW##......",
	"..#WwwwwwwwwwwwwwWW###........",
	"...#wwwwwwwwwww####...........",
	"....###########...............",
	"..............................",
	"..............................",
	"..............................",
	"..............................",
	"..............................",
]
## The rocket's: swept delta wings (white tips, a glowing leading edge), the twin thrusters
const ROCKET := [
	"....######....................",
	"...#KWWWWW#...................",
	"...#cRRRRRR#..................",
	"...#cRRRRRRR#.................",
	"...#cRRRRRRRR#................",
	"...#cRRRRRRRRR#...............",
	"...#cRRRRRRRRRR##.............",
	"..##cRRRRRRRRRRRR##...........",
	"####################..........",
	"#Cm#..........................",
	"#Cm#..........................",
	"####..........................",
	".#k#..........................",
	".#k#..........................",
	"####..........................",
	"#Cm#..........................",
	"#Cm#..........................",
	"####################..........",
	"..##crrrrrrrrrrrr##...........",
	"...#crrrrrrrrrr##.............",
	"...#crrrrrrrrr#...............",
	"...#crrrrrrrr#................",
	"...#crrrrrrr#.................",
	"...#crrrrrr#..................",
	"...#wWWWWW#...................",
	"....######....................",
]
const FORMS := { "hover": HOVER, "jetski": JETSKI, "rocket": ROCKET }

## The colours: the player's red (Pal Prix's car), the rivals' blue, yellow and green
const BODY_COLS := {
	"red": [Color8(226, 70, 64), Color8(182, 46, 50), Color8(255, 140, 118)],
	"blue": [Color8(70, 130, 220), Color8(46, 90, 170), Color8(150, 196, 250)],
	"yellow": [Color8(244, 196, 64), Color8(196, 146, 36), Color8(255, 234, 150)],
	"green": [Color8(100, 190, 110), Color8(64, 140, 76), Color8(170, 230, 160)],
	"purple": [Color8(160, 100, 220), Color8(112, 64, 170), Color8(212, 170, 250)],
}

static func _palette(col: String) -> Dictionary:
	var b: Array = BODY_COLS.get(col, BODY_COLS["red"])
	return {
		"#": OUTLINE, "R": b[0], "r": b[1], "L": b[2], "W": Color8(248, 244, 234), "w": Color8(200, 194, 208),
		"S": Color8(64, 50, 60), "s": Color8(100, 84, 96), "G": Color8(126, 196, 236), "g": Color8(228, 248, 255),
		"C": Color8(110, 240, 255), "c": Color8(40, 160, 214), "M": Color8(150, 154, 176), "m": Color8(96, 98, 120),
		"K": Color8(224, 230, 244), "k": Color8(62, 64, 84), "n": Color8(46, 48, 66),
	}

## The top view of a form (its part unfolded `k` of the way: 0 folded into the body, 1 out),
## as characters per px (the body over the part)
static func _chars(form: String, k: float) -> Array:
	var part: Array = FORMS[form]
	var out: Array = []
	for y in H:
		var row := ""
		# (unfolding: the part's rows pulled in towards the middle line, out to their place)
		var sy := int(roundf(12.5 + (y - 12.5) / maxf(k, 0.05)))
		for x in W:
			var ch := "."
			if sy >= 0 and sy < H:
				ch = String(part[sy])[x]
			var b := String(BODY[y])[x]
			if b != ".":
				ch = b
			row += ch
		out.append(row)
	return out

## The craft as slices, bottom first: its dark underside (a glow peeking out under a hover pod),
## its sides in shade, its full top, then its lit rim with the cockpit open (the pal sits in it)
static func slices(form: String, col := "red", k := 1.0) -> Array[Texture2D]:
	var key := "%s_%s_%.2f" % [form, col, k]
	if _cache.has(key):
		return _cache[key]
	var pal := _palette(col)
	var chars := _chars(form, k)
	var out: Array[Texture2D] = []
	for layer in LAYERS:
		var img := Image.create(W, H, false, Image.FORMAT_RGBA8)
		for y in H:
			var row: String = chars[y]
			for x in W:
				var ch := row[x]
				if ch == "." or not pal.has(ch):
					continue
				var c: Color = pal[ch]
				var col2: Color
				match layer:
					0:
						col2 = pal["c"] if ch == "C" else OUTLINE
					1:
						col2 = OUTLINE if ch == "#" else c.darkened(0.45)
					2:
						col2 = OUTLINE if ch == "#" else c.darkened(0.3)
					3:
						col2 = OUTLINE if ch == "#" else c.darkened(0.15)
					4:
						col2 = c
					_:
						if ch == "S" or ch == "s":
							continue                               # (the cockpit is open)
						col2 = c.lightened(0.12) if ch == "R" else c
				img.set_pixel(x, y, col2)
		out.append(ImageTexture.create_from_image(img))
	_cache[key] = out
	return out

## The form's top view as one picture (its slices stacked), for the how-to card and the menu
static func icon(form: String, col := "red") -> Texture2D:
	var key := "icon_%s_%s" % [form, col]
	if _cache.has(key):
		return _cache[key]
	var sl := slices(form, col)
	var img := Image.create(W, H + LAYERS, false, Image.FORMAT_RGBA8)
	for li in sl.size():
		var src := sl[li].get_image()
		img.blend_rect(src, Rect2i(0, 0, W, H), Vector2i(0, LAYERS - li))
	var used := img.get_used_rect()
	var cw := int(ceilf(maxf(used.size.x, used.size.y * 1.375)))
	var ch := int(ceilf(cw / 1.375))
	var out := Image.create(cw, ch, false, Image.FORMAT_RGBA8)
	out.blend_rect(img, used, Vector2i((cw - used.size.x) / 2, (ch - used.size.y) / 2))
	_cache[key] = ImageTexture.create_from_image(out)
	return _cache[key]

## The hover car's glow on the ground under it (added on, pulsing): a soft cyan oval in steps
static func hover_glow() -> Texture2D:
	if _cache.has("glow"):
		return _cache["glow"]
	var img := Image.create(34, 24, false, Image.FORMAT_RGBA8)
	for y in 24:
		for x in 34:
			var o := Vector2((x + 0.5 - 17.0) / 17.0, (y + 0.5 - 12.0) / 12.0)
			var d := o.length()
			if d >= 1.0:
				continue
			var a := floorf((1.0 - d) * 4.0) / 4.0 * 0.55
			img.set_pixel(x, y, Color(0.4, 0.9, 1.0, a))
	_cache["glow"] = ImageTexture.create_from_image(img)
	return _cache["glow"]

## A lumpy round thing lit from the top left, outlined: the base of the iceberg, the asteroid, the moon
static func _lump(r: float, k: int, cols: Array, bumps := 0.22) -> Image:
	var s := int(ceilf(r * 2.0 + 6.0))
	var img := Image.create(s, s, false, Image.FORMAT_RGBA8)
	var rng := RandomNumberGenerator.new()
	rng.seed = 7717 * k + 3
	var ph := rng.randf() * TAU
	var ph2 := rng.randf() * TAU
	var c := Vector2(s / 2.0, s / 2.0)
	var inside := func(p: Vector2) -> bool:
		var o: Vector2 = p - c
		var a := o.angle()
		return o.length() < r * (1.0 + bumps * sin(a * 3.0 + ph) * 0.6 + bumps * 0.4 * sin(a * 5.0 + ph2))
	for y in s:
		for x in s:
			var p := Vector2(x + 0.5, y + 0.5)
			if not inside.call(p):
				continue
			var edge: bool = not inside.call(p + Vector2(1, 0)) or not inside.call(p - Vector2(1, 0)) or not inside.call(p + Vector2(0, 1)) or not inside.call(p - Vector2(0, 1))
			if edge:
				img.set_pixel(x, y, OUTLINE)
				continue
			var o2 := (p - c) / r
			var light := -(o2.x + o2.y) * 0.7 + 0.15
			var col: Color = cols[1]
			if light > 0.35:
				col = cols[0]
			elif light < -0.3:
				col = cols[2]
			img.set_pixel(x, y, col)
	return img

## An iceberg floating on the fjord: white and ice blue, a darker foot in the water
static func iceberg(k := 0) -> Texture2D:
	var key := "berg_%d" % k
	if not _cache.has(key):
		var foot := _lump(13.0, k, [Color8(90, 160, 200), Color8(60, 130, 176), Color8(40, 100, 150)], 0.28)
		var img := Image.create(foot.get_width(), foot.get_height() + 4, false, Image.FORMAT_RGBA8)
		img.blend_rect(foot, Rect2i(Vector2i.ZERO, foot.get_size()), Vector2i(0, 4))
		var body := _lump(10.5, k, [Color8(250, 252, 255), Color8(206, 226, 246), Color8(150, 184, 222)], 0.3)
		img.blend_rect(body, Rect2i(Vector2i.ZERO, body.get_size()), Vector2i((img.get_width() - body.get_width()) / 2, (img.get_height() - body.get_height()) / 2 - 1))
		# its top, a step up: a smaller lump lit brighter
		var top := _lump(5.0, k + 50, [Color(1, 1, 1), Color8(228, 240, 252), Color8(186, 210, 238)], 0.25)
		img.blend_rect(top, Rect2i(Vector2i.ZERO, top.get_size()), Vector2i(img.get_width() / 2 - top.get_width() / 2 - 2, img.get_height() / 2 - top.get_height() / 2 - 3))
		_cache[key] = ImageTexture.create_from_image(img)
	return _cache[key]

## An asteroid: a grey-violet rock with craters, lit top left (it turns as it drifts)
static func asteroid(k := 0) -> Texture2D:
	var key := "rock_%d" % k
	if not _cache.has(key):
		var img := _lump(12.0, k, [Color8(170, 160, 186), Color8(120, 110, 136), Color8(74, 66, 88)], 0.28)
		var rng := RandomNumberGenerator.new()
		rng.seed = 919 * k + 1
		for n in 3:
			var cc := Vector2(rng.randf_range(7.0, img.get_width() - 7.0), rng.randf_range(7.0, img.get_height() - 7.0))
			var cr := rng.randf_range(1.5, 2.6)
			for y in img.get_height():
				for x in img.get_width():
					var o := Vector2(x + 0.5, y + 0.5) - cc
					if o.length() < cr and img.get_pixel(x, y).a > 0.5 and img.get_pixel(x, y) != OUTLINE:
						img.set_pixel(x, y, Color8(60, 52, 74) if o.x + o.y < 0.0 else Color8(150, 140, 168))
		_cache[key] = ImageTexture.create_from_image(img)
	return _cache[key]

## A moon to swing round (Saturn's Rings): pale, cratered, lit top left, bigger
static func moon(k := 0) -> Texture2D:
	var key := "moon_%d" % (k % 3)
	if not _cache.has(key):
		var tones: Array = [[Color8(240, 236, 224), Color8(200, 194, 184), Color8(140, 134, 132)],
			[Color8(250, 214, 170), Color8(214, 168, 124), Color8(150, 110, 90)],
			[Color8(214, 230, 250), Color8(170, 190, 222), Color8(110, 126, 170)]][k % 3]
		var img := _lump(16.0, k, tones, 0.06)
		var rng := RandomNumberGenerator.new()
		rng.seed = 313 * k + 7
		for n in 5:
			var cc := Vector2(rng.randf_range(9.0, img.get_width() - 9.0), rng.randf_range(9.0, img.get_height() - 9.0))
			var cr := rng.randf_range(1.5, 3.5)
			for y in img.get_height():
				for x in img.get_width():
					var o := Vector2(x + 0.5, y + 0.5) - cc
					if o.length() < cr and img.get_pixel(x, y).a > 0.5 and img.get_pixel(x, y) != OUTLINE:
						img.set_pixel(x, y, (tones[2] as Color) if o.x + o.y < 0.0 else (tones[0] as Color))
		_cache[key] = ImageTexture.create_from_image(img)
	return _cache[key]

## A cargo crate across the road (the sturdy secret): grey metal, hazard stripes, outlined
static func crate() -> Texture2D:
	if not _cache.has("crate"):
		_cache["crate"] = rows_texture([
			"############",
			"#KKKKKKKKKK#",
			"#KMMMMMMMMm#",
			"#KYkYkYkYkm#",
			"#KkYkYkYkYm#",
			"#KMMMMMMMMm#",
			"#KM#MMMM#Mm#",
			"#KMMMMMMMMm#",
			"#mmmmmmmmmm#",
			"############",
		], { "#": OUTLINE, "K": Color8(206, 212, 228), "M": Color8(150, 156, 176), "m": Color8(100, 104, 124), "Y": Color8(252, 210, 64), "k": Color8(40, 36, 48) })
	return _cache["crate"]

## A hidden gift's sparkle (the lucky secret)
static func sparkle() -> Texture2D:
	if not _cache.has("sparkle"):
		_cache["sparkle"] = rows_texture([
			"....#....",
			"...#w#...",
			"..#wyw#..",
			"##wyyyw##",
			"#wyyyyyw#",
			"##wyyyw##",
			"..#wyw#..",
			"...#w#...",
			"....#....",
		], { "#": Color8(120, 80, 30), "w": Color8(255, 250, 220), "y": Color8(255, 220, 110) })
	return _cache["sparkle"]

## A buoy as a stack of round slices, bottom first (Pal Prix's, in a futuristic colour): its dark
## waterline, its body, a white band, its lit top, a glowing cap; 7 px across
static func buoy_slices(c: Color) -> Array[Texture2D]:
	var key := "buoy_%s" % c.to_html()
	if _cache.has(key):
		return _cache[key]
	var w := Color8(240, 246, 255)
	var out: Array[Texture2D] = []
	for kind in 5:
		var img := Image.create(7, 7, false, Image.FORMAT_RGBA8)
		var rr := 3.6 if kind < 4 else 1.7
		var cen := Vector2(3.5, 3.5) if kind < 4 else Vector2(3.0, 3.0)
		for y in 7:
			for x in 7:
				var o := Vector2(x + 0.5, y + 0.5) - cen
				var d := o.length()
				if d > rr:
					continue
				var rim := d > rr - 1.0
				var lit := o.x + o.y < -1.2
				var shade := o.x + o.y > 1.6
				var col: Color
				match kind:
					0:
						col = Color8(20, 30, 60, 140)
					1:
						col = OUTLINE if rim else Color8(56, 60, 84)
					2:
						col = OUTLINE if rim else (w if lit else (Color8(190, 200, 220) if shade else Color8(222, 228, 240)))
					3:
						col = OUTLINE if rim else (c.lightened(0.45) if lit else (c.darkened(0.25) if shade else c))
					_:
						col = Color(1, 1, 1) if o.x + o.y < 0.0 else c.lightened(0.5)
				img.set_pixel(x, y, col)
		out.append(ImageTexture.create_from_image(img))
	_cache[key] = out
	return out

## The glass cabin over the pal (space-age, the user 2026-10-19): a bubble canopy over the seat
## and the windscreen, see-through tinted glass, a dark rim, glints top left; 13 x 9 px
static func canopy() -> Texture2D:
	if _cache.has("canopy"):
		return _cache["canopy"]
	var img := Image.create(13, 9, false, Image.FORMAT_RGBA8)
	for y in 9:
		for x in 13:
			var o := Vector2((x + 0.5 - 6.5) / 6.5, (y + 0.5 - 4.5) / 4.5)
			var d := o.length()
			if d > 1.0:
				continue
			var col := Color(0.62, 0.9, 1.0, 0.3)
			if d > 0.8:
				col = Color8(36, 44, 72)
			elif o.x + o.y < -0.75 and d < 0.72 and d > 0.4:
				col = Color(1, 1, 1, 0.8)
			elif absf(o.x + o.y + 0.05) < 0.14 and d < 0.78:
				col = Color(1, 1, 1, 0.38)                   # (a glare across the glass)
			elif o.x > 0.45 and absf(o.y) < 0.3:
				col = Color(0.75, 0.95, 1.0, 0.5)
			img.set_pixel(x, y, col)
	_cache["canopy"] = ImageTexture.create_from_image(img)
	return _cache["canopy"]

## Rows of characters -> a texture (a colour per character, "." = clear)
static func rows_texture(rows: Array, cols: Dictionary) -> Texture2D:
	var w := 0
	for r in rows:
		w = maxi(w, String(r).length())
	var img := Image.create(w, rows.size(), false, Image.FORMAT_RGBA8)
	for y in rows.size():
		var row := String(rows[y])
		for x in row.length():
			var ch := row[x]
			if cols.has(ch):
				img.set_pixel(x, y, cols[ch])
	return ImageTexture.create_from_image(img)
