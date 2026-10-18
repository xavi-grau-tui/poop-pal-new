extends RefCounted
class_name PalPrixArt
## Pal Prix's boat and plane (the car is rc_racer.gd's own) and the course pieces of the water and
## the sky: hard pixels on the game's 4 px grid, a dark outline, lit from the top left (the Tilt
## Maze rules), drawn in code like the car. Each toy is "sprite-stacked" like the car: its slices,
## bottom first, the same footprint, nose to the right.

const OUTLINE := Color8(40, 30, 40)

static var _cache := {}

## Rows of characters -> an image (a colour per character, "." = clear)
static func rows_image(rows: Array, cols: Dictionary) -> Image:
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
	return img

static func _tex(img: Image) -> Texture2D:
	return ImageTexture.create_from_image(img)

# ------------------------------------------------------------------ THE BOAT

## A little RC speedboat seen from above, nose to the right, 27 x 14 px: a white hull with a red
## rim, the seat (where the pal sits) behind a windscreen, a wooden foredeck, the outboard motor
const BOAT := [
	"...###############.........",
	"..#RRRRRRRRRRRRRRR##.......",
	".#RWWWWWWWWWWWWWWWRR##.....",
	".#RWwwwwwwwwwwwdddWWRR#....",
	"##RWwSSSSSSSGGwdddddWWR#...",
	"M#RWwSsssssSGGwdddddddWR#..",
	"M#RWwSsssssSGGwddddddddWR#.",
	"M#RWwSsssssSGGwddddddddWR#.",
	"M#RWwSsssssSGGwdddddddWR#..",
	"##RWwSSSSSSSGGwdddddWWR#...",
	".#RWwwwwwwwwwwwdddWWRR#....",
	".#RWWWWWWWWWWWWWWWRR##.....",
	"..#RRRRRRRRRRRRRRR##.......",
	"...###############.........",
]
const BOAT_COLS := {
	"#": OUTLINE, "R": Color8(226, 70, 64), "W": Color8(246, 242, 232), "w": Color8(222, 214, 204),
	"S": Color8(70, 56, 64), "s": Color8(96, 80, 88), "G": Color8(150, 206, 236), "d": Color8(214, 160, 100),
	"M": Color8(60, 58, 68),
}
## Where the pal sits, board px from the boat's middle (along its nose)
const BOAT_SEAT := -5.5

## The boat's slices, bottom first: the dark hull under the water line, the red hull, the white
## hull, the deck with its seat and foredeck, the windscreen's top and the rim's lit edge
static func boat_slices(main := Color8(226, 70, 64), dark := Color8(186, 50, 52)) -> Array[Texture2D]:
	var key := "boat_%s" % main.to_html()
	if key in _cache:
		return _cache[key]
	var cols := BOAT_COLS.duplicate()
	cols["R"] = main
	var top := rows_image(BOAT, cols)
	var out: Array[Texture2D] = []
	for layer in 5:
		var img := Image.create(top.get_width(), top.get_height(), false, Image.FORMAT_RGBA8)
		for y in top.get_height():
			for x in top.get_width():
				var c := top.get_pixel(x, y)
				if c.a == 0.0:
					continue
				var ch := String(BOAT[y])[x]
				var col := Color(0, 0, 0, 0)
				match layer:
					0:
						col = OUTLINE if ch != "M" else c                 # the hull's bottom, dark
					1:
						col = dark if ch in ["R", "W", "w", "d", "S", "s", "G"] else c
					2:
						col = c if ch in ["#", "M", "R"] else (main if ch in ["W", "w"] else dark)
					3:
						col = c                                            # the deck, all of it
					_:
						if ch in ["R"]:
							col = main.lightened(0.2)                      # the rim's lit edge
						elif ch == "G":
							col = c.lightened(0.25)                        # the windscreen's top
						elif ch == "#" and x > 2:
							col = c
				if col.a > 0.0:
					img.set_pixel(x, y, col)
		out.append(_tex(img))
	_cache[key] = out
	return out

# ------------------------------------------------------------------ THE PLANE

## A little RC plane seen from above, nose to the right, 26 x 26 px: a yellow fuselage, red wings
## with white tips, the tailplane, a spinning propeller (a pale blur), the cockpit for the pal
const PLANE := [
	"..........######..........",
	".........#wWWWWw#.........",
	".........#RRRRRR#.........",
	".........#RRRRRR#.........",
	".........#RRRRRR#.........",
	".........#RRRRRR#.........",
	".........#RRRRRR#.........",
	"..###....#RRRRRR#.........",
	".#RRR#...#RRRRRR#......P..",
	".#RRR#####rrrrrr#####.PPP.",
	".#RRRYYYYYYYYYYYYYYYY#PPP.",
	".#RRRYYYYYYYSSSSSYYYYYPPPP",
	".#FFFYYYYYYYSsssSYYYYYPPPP",
	".#FFFYYYYYYYSsssSYYYYYPPPP",
	".#RRRYYYYYYYSSSSSYYYYYPPPP",
	".#RRRYYYYYYYYYYYYYYYY#PPP.",
	".#RRR#####rrrrrr#####.PPP.",
	".#RRR#...#RRRRRR#......P..",
	"..###....#RRRRRR#.........",
	".........#RRRRRR#.........",
	".........#RRRRRR#.........",
	".........#RRRRRR#.........",
	".........#RRRRRR#.........",
	".........#RRRRRR#.........",
	".........#wWWWWw#.........",
	"..........######..........",
]
const PLANE_COLS := {
	"#": OUTLINE, "R": Color8(226, 70, 64), "r": Color8(190, 46, 50), "W": Color8(250, 246, 236),
	"w": Color8(222, 214, 204), "Y": Color8(250, 210, 84), "S": Color8(70, 56, 64), "s": Color8(96, 80, 88),
	"P": Color8(220, 224, 232), "F": Color8(190, 46, 50),
}
const PLANE_SEAT := 1.0

## The plane's slices, bottom first: its dark underside, the wings (wide), the fuselage, its lit
## top with the cockpit, and the tail fin standing up at the back
## (with_prop false: no blur at the nose, the plane wears its own spinning propeller: propeller())
static func plane_slices(main := Color8(226, 70, 64), body := Color8(250, 210, 84), with_prop := true) -> Array[Texture2D]:
	var key := "plane_%s_%s_%s" % [main.to_html(), body.to_html(), with_prop]
	if key in _cache:
		return _cache[key]
	var cols := PLANE_COLS.duplicate()
	cols["R"] = main
	cols["r"] = main.darkened(0.16)
	cols["F"] = main.darkened(0.16)
	cols["Y"] = body
	var top := rows_image(PLANE, cols)
	var out: Array[Texture2D] = []
	for layer in 4:
		var img := Image.create(top.get_width(), top.get_height(), false, Image.FORMAT_RGBA8)
		for y in top.get_height():
			for x in top.get_width():
				var c := top.get_pixel(x, y)
				if c.a == 0.0:
					continue
				var ch := String(PLANE[y])[x]
				var on_body := y >= 9 and y <= 16 and x >= 5 and x <= 21
				var col := Color(0, 0, 0, 0)
				match layer:
					0:
						if on_body and ch != "P":
							col = OUTLINE                                  # the fuselage's underside
					1:
						if ch != "P":
							col = c.darkened(0.22) if ch in ["R", "r", "W", "w"] else c   # the wings, in their shade
					2:
						if on_body and ch != "P":
							col = c
						elif ch == "P" and with_prop:
							col = Color(c.r, c.g, c.b, 0.8)                # the propeller's blur
					_:
						if ch == "F":
							col = main.darkened(0.3)                       # the tail fin, up top
						elif on_body and ch in ["Y"]:
							col = body.lightened(0.18)
						elif ch in ["S", "s"]:
							col = c
				if col.a > 0.0:
					img.set_pixel(x, y, col)
		out.append(_tex(img))
	_cache[key] = out
	return out

## The plane's wings rolled into a turn (dip: +1 the right wing down, -1 the left): the lowered
## wing in shade, the raised one catching the light (the user, 2026-10-18: turning left and right
## looked the same)
static func plane_wings(main: Color, body: Color, dip: int) -> Texture2D:
	var key := "wings_%s_%s_%d" % [main.to_html(), body.to_html(), dip]
	if key in _cache:
		return _cache[key]
	var cols := PLANE_COLS.duplicate()
	cols["R"] = main
	cols["r"] = main.darkened(0.16)
	cols["F"] = main.darkened(0.16)
	cols["Y"] = body
	var top := rows_image(PLANE, cols)
	var img := Image.create(top.get_width(), top.get_height(), false, Image.FORMAT_RGBA8)
	var mid := top.get_height() / 2.0
	for y in top.get_height():
		for x in top.get_width():
			var c := top.get_pixel(x, y)
			var ch := String(PLANE[y])[x]
			if c.a == 0.0 or ch == "P":
				continue
			var col := c.darkened(0.22) if ch in ["R", "r", "W", "w"] else c
			var right := y + 0.5 > mid                                     # (the nose to the right: +y is the right wing)
			if ch != "#" and absf(y + 0.5 - mid) > 4.0:
				col = col.darkened(0.3) if right == (dip > 0) else col.lightened(0.28)
			img.set_pixel(x, y, col)
	_cache[key] = _tex(img)
	return _cache[key]

## The plane's propeller spinning, seen from above (frame 0-11): its sweep, a see-through bar
## across the nose with a soft dark edge (it shows on a light sky), shimmering frame to frame, and
## the blades' two bright glints sweeping along it from the tips through the hub and out the other
## side (the user, 2026-10-18: it has to look like it's moving, not a fixed piece), a red hub. The
## game shows a new frame every frame drawn: the glints step every second frame (30 a second)
static func propeller(frame: int) -> Texture2D:
	var key := "prop_%d" % frame
	if key not in _cache:
		var img := Image.create(5, 15, false, Image.FORMAT_RGBA8)
		var cy := 7
		var shimmer := frame % 2 == 0
		for y in 15:
			var tip := absi(y - cy) >= 7
			img.set_pixel(1, y, Color8(70, 70, 100, 70))
			img.set_pixel(3, y, Color8(70, 70, 100, 70))
			img.set_pixel(2, y, Color8(250, 252, 255, (110 if tip else 200) if shimmer else (80 if tip else 150)))
		var d: int = [6, 4, 2, -2, -4, -6][(frame / 2) % 6]
		for g: int in [cy + d, cy - d]:
			img.set_pixel(2, g, Color8(255, 255, 255))
			for x in [1, 3]:
				img.set_pixel(x, g, Color8(255, 255, 255, 170))
			var trail: int = g - signi(d) if g > cy else g + signi(d)
			if trail >= 0 and trail < 15:
				img.set_pixel(2, trail, Color8(255, 255, 255, 220))
		for y in [cy - 1, cy, cy + 1]:
			for x in 5:
				img.set_pixel(x, y, OUTLINE)
		img.set_pixel(1, cy, Color8(226, 70, 64))
		img.set_pixel(2, cy, Color8(255, 150, 130))
		img.set_pixel(3, cy, Color8(190, 46, 50))
		_cache[key] = _tex(img)
	return _cache[key]

# ------------------------------------------------------------------ THE WATER'S PIECES

## A buoy on the channel's rope: a red and white float, 5 x 5 px
static func buoy(red := true) -> Texture2D:
	var key := "buoy_%s" % red
	if key not in _cache:
		var c := Color8(226, 70, 64) if red else Color8(246, 242, 232)
		_cache[key] = _tex(rows_image([
			".###.",
			"#lcc#",
			"#ccd#",
			"#cdd#",
			".###.",
		], { "#": OUTLINE, "l": c.lightened(0.45), "c": c, "d": c.darkened(0.2) }))
	return _cache[key]

## A rock in the channel: a grey boulder, 13 x 11 px (its foam ring is the water's: _paint)
static func rock(k := 0) -> Texture2D:
	var key := "rock_%d" % k
	if key not in _cache:
		var rows := [
			"...#####.....",
			"..#lllmm##...",
			".#llmmmmmm#..",
			"#llmmmmmmmd#.",
			"#lmmmmmmmmdd#",
			"#mmmmmmmmddd#",
			"#mmmmmmmdddd#",
			".#mmmmmddddd#",
			"..#ddddddd##.",
			"...#######...",
			".............",
		] if k % 2 == 0 else [
			"....####.....",
			"..##llmm#....",
			".#llmmmmm##..",
			"#llmmmmmmmm#.",
			"#lmmmmmmmmmd#",
			"#mmmmmmmmmdd#",
			".#mmmmmmmddd#",
			".#mmmmmmdddd#",
			"..##dddddd##.",
			"....######...",
			".............",
		]
		_cache[key] = _tex(rows_image(rows, { "#": OUTLINE, "l": Color8(196, 196, 204), "m": Color8(150, 148, 160), "d": Color8(108, 106, 120) }))
	return _cache[key]

## A floating log, 26 x 7 px, along x (its cut ends showing the rings)
static func log_texture() -> Texture2D:
	if "log" not in _cache:
		_cache["log"] = _tex(rows_image([
			".########################.",
			"#eLLLLLLLLLLLLLLLLLLLLLLe#",
			"#EllllllllbllllllllllllE#.",
			"#EmmmmmmmmmmmmmbmmmmmmmE#",
			"#EddddddddddddddddddddddE#",
			"#eDDDDDDDDDDDDDDDDDDDDDe#",
			".########################.",
		], { "#": OUTLINE, "L": Color8(196, 140, 88), "l": Color8(176, 122, 74), "m": Color8(156, 104, 62),
			"d": Color8(134, 88, 52), "D": Color8(112, 72, 42), "b": Color8(120, 78, 46),
			"E": Color8(232, 196, 140), "e": Color8(206, 166, 110) }))
	return _cache["log"]

## A floating wooden ramp, 14 x 12 px, nose to the right (it rises that way): yellow and dark
## chevrons on a wooden frame
static func water_ramp() -> Texture2D:
	if "wramp" not in _cache:
		_cache["wramp"] = _tex(rows_image([
			"##############",
			"#wwwwwwwwwwww#",
			"#wyyYyyYyyYyw#",
			"#wyYyyYyyYyyw#",
			"#wYyyYyyYyyYw#",
			"#wyYyyYyyYyyw#",
			"#wyyYyyYyyYyw#",
			"#wyYyyYyyYyyw#",
			"#wYyyYyyYyyYw#",
			"#wyYyyYyyYyyw#",
			"#wwwwwwwwwwww#",
			"##############",
		], { "#": OUTLINE, "w": Color8(176, 122, 74), "y": Color8(252, 210, 64), "Y": Color8(70, 64, 78) }))
	return _cache["wramp"]

# ------------------------------------------------------------------ THE SKY'S PIECES

## A hot-air balloon seen from above at an angle, 19 x 24 px: a striped envelope, its basket
## hanging below on its ropes
static func balloon(k := 0) -> Texture2D:
	var key := "hot_%d" % k
	if key not in _cache:
		var pairs := [[Color8(236, 96, 84), Color8(250, 210, 84)], [Color8(110, 170, 236), Color8(250, 246, 236)],
			[Color8(186, 130, 226), Color8(120, 206, 130)], [Color8(250, 160, 190), Color8(250, 246, 236)]]
		var pr: Array = pairs[k % pairs.size()]
		var rows := [
			"......#######......",
			"....##aabbaabb##...",
			"...#laabbaabbaab#..",
			"..#llaabbaabbaabb#.",
			".#llaabbaabbaabbad#",
			".#laabbaabbaabbadd#",
			"#llaabbaabbaabbaadd#",
			"#laabbaabbaabbaaddd#",
			"#laabbaabbaabbaaddd#",
			"#laabbaabbaabbaaddd#",
			".#aabbaabbaabbaadd#.",
			".#aabbaabbaabbaddd#.",
			"..#abbaabbaabbadd#..",
			"...#bbaabbaabbdd#...",
			"....##aabbaabb##....",
			"......#aabbaa#......",
			".......#####........",
			".......#...#........",
			".......#...#........",
			"......#.....#.......",
			"......#######.......",
			"......#kkkkk#.......",
			"......#KKKKK#.......",
			"......#######.......",
		]
		_cache[key] = _tex(rows_image(rows, { "#": OUTLINE, "a": pr[0], "b": pr[1], "l": pr[1].lightened(0.4),
			"d": pr[0].darkened(0.25), "k": Color8(196, 140, 88), "K": Color8(150, 104, 62) }))
	return _cache[key]

## A puff of cloud, `r` board px across its middle: lumpy white, lit top left, a soft blue shade
## below; `dark`: a storm cloud (grey-violet, darker under)
static func cloud(r: int, k := 0, dark := false) -> Texture2D:
	var key := "cloud_%d_%d_%s" % [r, k, dark]
	if key in _cache:
		return _cache[key]
	var w := r * 2 + 6
	var h := int(r * 1.4) + 6
	var img := Image.create(w, h, false, Image.FORMAT_RGBA8)
	var rng := RandomNumberGenerator.new()
	rng.seed = 991 * k + r
	var lumps: Array = []
	for i in 5:
		var lx := rng.randf_range(r * 0.45, w - r * 0.45 - 3)
		var ly := rng.randf_range(h * 0.42, h * 0.62)
		lumps.append([Vector2(lx, ly), rng.randf_range(r * 0.42, r * 0.62)])
	var hi := Color8(255, 255, 255) if not dark else Color8(150, 140, 170)
	var mid := Color8(236, 242, 250) if not dark else Color8(112, 104, 136)
	var lo := Color8(196, 214, 236) if not dark else Color8(74, 68, 96)
	var inside := {}
	for y in h:
		for x in w:
			for lp in lumps:
				if Vector2(x + 0.5, y + 0.5).distance_to(lp[0]) < lp[1]:
					inside[Vector2i(x, y)] = true
					break
	for p in inside:
		var x: int = p.x
		var y: int = p.y
		var col := mid
		var up := not inside.has(Vector2i(x, y - 2)) or not inside.has(Vector2i(x - 2, y))
		var down := not inside.has(Vector2i(x, y + 2)) or not inside.has(Vector2i(x + 2, y + 1))
		if up and not down:
			col = hi
		elif down:
			col = lo
		img.set_pixel(x, y, col)
	_cache[key] = _tex(img)
	return _cache[key]
