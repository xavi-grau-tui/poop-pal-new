extends RefCounted
class_name RcTiles
## RC Prix's Garden built from the designer's square pieces (docs/mockups/rcprix_garden/BRIEF.md,
## docs/rcprix_art_process.md), a TRIAL behind the dev launcher's RC NEW ART switch (the user,
## 2026-10-27: the original stays until this works as expected). The driving is rc_racer.gd's own:
## its corners are already quarter circles of half a square round the square's corner, exactly the
## pieces' curves, so here only the pictures change, plus: the road as wide as the pieces draw it,
## and the start line, the boost pads and the jumps moved onto whole straight squares (the pieces
## draw them centred there).
##
## The pieces are drawn at twice the board's detail: one art px = ART_PX world px.

const DIR := "res://textures/minigames/rcprix/garden/"
const ART_PX := 2.0
const SQ := 180                       # a square, art px (CELLS["car"] / ART_PX)
const HALF := { false: 88.0, true: 100.0 }    # the road's half width, world px: [later levels, early ones (wide)]
const WIDE_LEVELS := 4                # a world's first 4 levels: the wide road
const BOARD_PX := 4.0                 # rc_racer's PX: world px per old board px
const FRAME := 20                     # the board's wooden frame, art px (rc_racer EDGE * PX / ART_PX)
const SHADE := Vector2(6, 9)          # the track's shadow on the lawn, art px down-right (rc_racer draws it: a dark copy of the track)
const SHADE_COL := Color(0.05, 0.04, 0.1, 0.3)
## the trees' shade (the user, 2026-10-27: no shadows or light yet): the canopies again, dark and
## see-through, down-right of them (the sun top-left), over the lawn and the road, under the car
const TREE_SHADE := Vector2(18, 26)
const TREE_SHADE_COL := Color(0.04, 0.1, 0.06, 0.3)
const DECOR_SHADE := Vector2i(3, 4)   # a bush's or flowers' own little shadow
const DECOR_SHADE_A := 0.28
const GAP_HOLE := 60.0                # a jump's hole, world px each side of its square's middle (the gap pieces')
const RAMP_SHIFT := 50                # the ramp drawn this many art px back from its piece's middle, right before the hole

static var _cache := {}

static func on(look: String) -> bool:
	return DevLaunch.rc_new_art and look == "garden"

static func wide(level: int) -> bool:
	return (level - 1) % GameData.LEVELS_PER_WORLD < WIDE_LEVELS

static func half_width(level: int) -> float:
	return HALF[wide(level)]

static func img(name: String) -> Image:
	if not _cache.has(name):
		var t := load(DIR + name + ".png") as Texture2D
		var im: Image = t.get_image() if t else null
		if im and im.is_compressed():
			im.decompress()
		if im:
			im.convert(Image.FORMAT_RGBA8)
		_cache[name] = im
	return _cache[name]

static func tex(name: String) -> Texture2D:
	return load(DIR + name + ".png")

# ------------------------------------------------------------------ THE GRID

## The course's squares: grid point -> its piece ("straight_h", "corner_ne", ...), from the outline's
## corners (grid points, in order round the loop)
static func pieces(corners: Array) -> Dictionary:
	var path: Array[Vector2i] = []
	for i in corners.size():
		var a: Vector2i = corners[i]
		var b: Vector2i = corners[(i + 1) % corners.size()]
		var step := Vector2i(signi(b.x - a.x), signi(b.y - a.y))
		var p := a
		while p != b:
			path.append(p)
			p += step
	var names := { Vector2i(1, 0): "e", Vector2i(-1, 0): "w", Vector2i(0, 1): "s", Vector2i(0, -1): "n" }
	var out := {}
	for i in path.size():
		var p := path[i]
		var ends := [names[path[i - 1] - p], names[path[(i + 1) % path.size()] - p]]
		if "e" in ends and "w" in ends:
			out[p] = "straight_h"
		elif "n" in ends and "s" in ends:
			out[p] = "straight_v"
		else:
			out[p] = "corner_" + ("n" if "n" in ends else "s") + ("e" if "e" in ends else "w")
	return out

## A grid point's place on the mat (world px)
static func at(g: Vector2i, pad: float, cell: float) -> Vector2:
	return Vector2(g) * cell + Vector2(pad, pad)

## The centre point nearest a place
static func nearest(centre: PackedVector2Array, p: Vector2) -> int:
	var best := 0
	var bd := INF
	for i in centre.size():
		var d := centre[i].distance_squared_to(p)
		if d < bd:
			bd = d
			best = i
	return best

## The straight square nearest a place (its grid point), or (-1, -1)
static func nearest_straight(tiles: Dictionary, p: Vector2, pad: float, cell: float, avoid := []) -> Vector2i:
	var best := Vector2i(-1, -1)
	var bd := INF
	for g in tiles:
		if not String(tiles[g]).begins_with("straight") or g in avoid:
			continue
		var d := at(g, pad, cell).distance_squared_to(p)
		if d < bd:
			bd = d
			best = g
	return best

# ------------------------------------------------------------------ THE PICTURES

## The floor (lawn, decor, the frame), the raised track (road pieces, overlays)
## and the branches over it, each an image at ART_PX world px per px: [floor, track, canopy]
static func paint(rc) -> Array:
	var w := int(ceilf(rc.mat_size.x / ART_PX))
	var h := int(ceilf(rc.mat_size.y / ART_PX))
	var tiles: Dictionary = rc._tiles
	var suffix := "_wide" if wide(rc.level) else ""
	var org := func(g: Vector2i) -> Vector2i:          # a square's top-left, art px
		return Vector2i(((at(g, rc._tile_pad, rc.cell) - Vector2(rc.cell, rc.cell) / 2.0) / ART_PX).round())
	var rng := RandomNumberGenerator.new()
	rng.seed = 7919 * rc.course_seed + 5
	# the raised track: the pieces, a jump's gap piece, then what lies on them
	var track := Image.create(w, h, false, Image.FORMAT_RGBA8)
	var gap_at := {}
	for gp in rc._gap_squares:
		gap_at[gp[0]] = gp[1]
	for g in tiles:
		var name: String = tiles[g]
		if gap_at.has(g):
			name = "gap_h" if name == "straight_h" else "gap_v"
		_stamp(track, img(name + suffix), org.call(g))
		if name.begins_with("corner") and rc._rail_squares.has(g):
			_stamp(track, img("tyres_" + name.substr(7) + suffix), org.call(g))
	_stamp(track, img(("start_h" if tiles.get(rc._start_square, "") == "straight_h" else "start_v") + suffix), org.call(rc._start_square))
	for pd in rc._pad_squares:
		_stamp(track, img("boost_" + _compass(pd[1]) + suffix), org.call(pd[0]))
	for gp in rc._gap_squares:
		var d: Vector2 = gp[1]
		_stamp(track, img("ramp_" + _compass(d) + suffix), org.call(gp[0]) - Vector2i(d.round()) * RAMP_SHIFT)
	# the lawn: the three grasses mixed, on the pieces' grid
	var floor_img := Image.create(w, h, false, Image.FORMAT_RGBA8)
	var grass := [img("grass_a"), img("grass_b"), img("grass_c")]
	var o0: Vector2i = org.call(Vector2i.ZERO)
	var ox := posmod(o0.x, SQ) - SQ
	var oy := posmod(o0.y, SQ) - SQ
	for y in range(oy, h, SQ):
		for x in range(ox, w, SQ):
			floor_img.blit_rect(grass[rng.randi() % 3], Rect2i(0, 0, SQ, SQ), Vector2i(x, y))
	# decor on the lawn: off the track (and its tyre walls), the stand and the frame
	var stand: Rect2 = Rect2(rc.crowd.rect.position / ART_PX, rc.crowd.rect.size / ART_PX).grow(6.0) if rc.crowd.visible else Rect2()
	var clear := func(r: Rect2i) -> bool:
		if r.position.x < FRAME + 2 or r.position.y < FRAME + 2 or r.end.x > w - FRAME - 2 or r.end.y > h - FRAME - 2:
			return false
		if stand.intersects(Rect2(r)):
			return false
		for yy in range(r.position.y - 6, r.end.y + 6, 4):
			for xx in range(r.position.x - 6, r.end.x + 6, 4):
				if xx >= 0 and yy >= 0 and xx < w and yy < h and track.get_pixel(xx, yy).a > 0.0:
					return false
		return true
	var area := float(w * h) / float(SQ * SQ)
	for spec in [["bush_a", 0.5], ["bush_b", 0.5], ["flowers_a", 1.2], ["flowers_b", 1.2]]:
		var im := img(spec[0])
		for _k in int(area * float(spec[1])):
			for _try in 12:
				var p := Vector2i(rng.randi_range(0, w - im.get_width()), rng.randi_range(0, h - im.get_height()))
				if clear.call(Rect2i(p, im.get_size())):
					_stamp(floor_img, _shadow_of(im), p + DECOR_SHADE)
					_stamp(floor_img, im, p)
					break
	# the wooden frame round the mat
	_frame(floor_img, w, h)
	# the branches over everything: the old Garden's trees (rc_racer._plant_trees: on the edges),
	# each the designer's canopy hanging over its edge
	var canopy := Image.create(w, h, false, Image.FORMAT_RGBA8)
	var bw: float = rc.mat_size.x / BOARD_PX
	var bh: float = rc.mat_size.y / BOARD_PX
	for tr in rc._trees:
		var c: Vector2 = tr[0]
		var name := "tree_top"
		if c.y <= 2.0:
			pass
		elif c.y >= bh - 2.0:
			name = "tree_bottom"
		elif c.x <= 2.0:
			name = "tree_left"
		else:
			name = "tree_right"
		var im := img(name)
		var p := Vector2i((c * BOARD_PX / ART_PX).round()) - im.get_size() / 2
		match name:
			"tree_top": p.y = 0
			"tree_bottom": p.y = h - im.get_height()
			"tree_left": p.x = 0
			"tree_right": p.x = w - im.get_width()
		_stamp(canopy, im, p)
	return [floor_img, track, canopy]

## A sprite's shadow: its shape, dark and see-through
static func _shadow_of(src: Image) -> Image:
	var key := "shadow_%d" % src.get_instance_id()
	if not _cache.has(key):
		var sh := Image.create(src.get_width(), src.get_height(), false, Image.FORMAT_RGBA8)
		for y in src.get_height():
			for x in src.get_width():
				if src.get_pixel(x, y).a > 0.0:
					sh.set_pixel(x, y, Color(0.05, 0.08, 0.04, DECOR_SHADE_A))
		_cache[key] = sh
	return _cache[key]

static func _compass(d: Vector2) -> String:
	if absf(d.x) > absf(d.y):
		return "e" if d.x > 0.0 else "w"
	return "s" if d.y > 0.0 else "n"

static func _stamp(dst: Image, src: Image, p: Vector2i) -> void:
	if src:
		dst.blend_rect(src, Rect2i(Vector2i.ZERO, src.get_size()), p)

static func _frame(dst: Image, w: int, h: int) -> void:
	var top := img("frame_top")
	var bottom := img("frame_bottom")
	var left := img("frame_left")
	var right := img("frame_right")
	for x in range(FRAME, w - FRAME, SQ):
		var n := mini(SQ, w - FRAME - x)
		dst.blit_rect(top, Rect2i(0, 0, n, FRAME), Vector2i(x, 0))
		dst.blit_rect(bottom, Rect2i(0, 0, n, FRAME), Vector2i(x, h - FRAME))
	for y in range(FRAME, h - FRAME, SQ):
		var n := mini(SQ, h - FRAME - y)
		dst.blit_rect(left, Rect2i(0, 0, FRAME, n), Vector2i(0, y))
		dst.blit_rect(right, Rect2i(0, 0, FRAME, n), Vector2i(w - FRAME, y))
	dst.blit_rect(img("frame_corner_tl"), Rect2i(0, 0, FRAME, FRAME), Vector2i(0, 0))
	dst.blit_rect(img("frame_corner_tr"), Rect2i(0, 0, FRAME, FRAME), Vector2i(w - FRAME, 0))
	dst.blit_rect(img("frame_corner_bl"), Rect2i(0, 0, FRAME, FRAME), Vector2i(0, h - FRAME))
	dst.blit_rect(img("frame_corner_br"), Rect2i(0, 0, FRAME, FRAME), Vector2i(w - FRAME, h - FRAME))

## The car's slices (bottom first): the code's original car (rc_racer.car_slices, the user 2026-10-27:
## nicer than the designer's), doubled with Scale2x so it matches the pieces' finer pixels: its
## stair-step diagonals rounded off, no blur, no new colours
static func car_slices(original: Array[Texture2D]) -> Array[Texture2D]:
	var out: Array[Texture2D] = []
	for t in original:
		out.append(ImageTexture.create_from_image(scale2x(t.get_image())))
	return out

## Scale2x (EPX): each pixel into four, a corner taking a neighbour's colour where two neighbours agree
static func scale2x(src: Image) -> Image:
	var w := src.get_width()
	var h := src.get_height()
	var dst := Image.create(w * 2, h * 2, false, Image.FORMAT_RGBA8)
	var px := func(x: int, y: int) -> Color:
		return src.get_pixel(clampi(x, 0, w - 1), clampi(y, 0, h - 1))
	for y in h:
		for x in w:
			var p: Color = px.call(x, y)
			var a: Color = px.call(x, y - 1)
			var b: Color = px.call(x + 1, y)
			var c: Color = px.call(x - 1, y)
			var d: Color = px.call(x, y + 1)
			var e0 := p
			var e1 := p
			var e2 := p
			var e3 := p
			if c == a and c != d and a != b:
				e0 = a
			if a == b and a != c and b != d:
				e1 = b
			if d == c and d != b and c != a:
				e2 = c
			if b == d and b != a and d != c:
				e3 = d
			dst.set_pixel(x * 2, y * 2, e0)
			dst.set_pixel(x * 2 + 1, y * 2, e1)
			dst.set_pixel(x * 2, y * 2 + 1, e2)
			dst.set_pixel(x * 2 + 1, y * 2 + 1, e3)
	return dst
