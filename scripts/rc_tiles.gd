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
const BUSHES := ["bush_a", "bush_b", "bush_c", "bush_d", "bush_e", "bush_f", "bush_g"]   # (made by tools/art/rcprix_bush_redraw.py)
const BUSHES_PER_SQ := 0.6            # bushes per course square of lawn, all kinds together
const SAME_BUSH_APART := 2.5 * SQ     # the same bush never nearer itself than this (the user: the same one twice on screen)
## TRIAL until the designer's redrawn bushes come (NOTES_ROUND_4): the current ones are doubled
## (Scale2x), their leaves then the trees' size; set false when the new ones are in
const BUSH_X2 := false
const DECOR_SHADE_A := 0.28
const GAP_HOLE := 60.0                # a jump's hole, world px each side of its middle
const HOLE_AHEAD := 40                # the hole's middle this many art px past its square's middle, the way you drive:
                                      # the long ramp then fits in the same square (the user: tight courses lost their jumps)
const OUTLINE := Color8(0x28, 0x1E, 0x28)         # the pieces' one outline colour (BRIEF.md)
const LAMP_X := [18, 45, 72]          # the start gantry's three sockets, px across its 90 (NOTES_ROUND_10)
const FACE_ROWS := 13                 # the raised track's side face under a south edge, with its outline (SIDE 12 + 1)

## Colour grades to compare (DevLaunch "COLOURS"): [name, lighten, saturation, green hue shift]
## (the user 2026-10-27: are the colours too vivid? pastel mockups made the same way)
const GRADES := [["SOFT", 0.15, 0.8, 0.0], ["PASTEL", 0.28, 0.62, 0.0], ["MINTY", 0.32, 0.55, 0.03]]
const GRADE_SHADER := """
shader_type canvas_item;
uniform float lift;
uniform float sat;
uniform float hue_shift;
vec3 hsv(vec3 c) {
	vec4 K = vec4(0.0, -1.0 / 3.0, 2.0 / 3.0, -1.0);
	vec4 p = mix(vec4(c.bg, K.wz), vec4(c.gb, K.xy), step(c.b, c.g));
	vec4 q = mix(vec4(p.xyw, c.r), vec4(c.r, p.yzx), step(p.x, c.r));
	float d = q.x - min(q.w, q.y);
	return vec3(abs(q.z + (q.w - q.y) / (6.0 * d + 1e-10)), d / (q.x + 1e-10), q.x);
}
vec3 rgb(vec3 c) {
	vec3 p = abs(fract(c.xxx + vec3(1.0, 2.0 / 3.0, 1.0 / 3.0)) * 6.0 - 3.0);
	return c.z * mix(vec3(1.0), clamp(p - 1.0, 0.0, 1.0), c.y);
}
void fragment() {
	vec4 t = COLOR;                          // (already the texture times the modulate)
	vec3 c = hsv(t.rgb);
	if (c.z >= 0.18) {                       // (the outlines stay dark, so it stays crisp)
		c.z += (1.0 - c.z) * lift;
		c.y *= sat;
		if (c.x > 0.17 && c.x < 0.45) { c.x += hue_shift; }
	}
	COLOR = vec4(rgb(vec3(fract(c.x), c.y, c.z)), t.a);
}
"""

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

## A piece as a texture made from its image (for _draw calls: the imported texture drew blank there)
static func drawn(name: String) -> Texture2D:
	var key := "drawn_" + name
	if not _cache.has(key):
		var im := img(name)
		_cache[key] = ImageTexture.create_from_image(im) if im else null
	return _cache[key]

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

## A colour grade (1.. = GRADES) as a material, or null for 0 (as drawn). The scenery takes
## DevLaunch.rc_grade (normal colours by default), the stand and its audience SOFT (the user
## 2026-10-27: "keep the normal colours and put the audience in soft colours"); the car never
static func grade_material(n: int) -> ShaderMaterial:
	if n <= 0 or n > GRADES.size():
		return null
	var g: Array = GRADES[n - 1]
	var sh := Shader.new()
	sh.code = GRADE_SHADER
	var m := ShaderMaterial.new()
	m.shader = sh
	m.set_shader_parameter("lift", g[1])
	m.set_shader_parameter("sat", g[2])
	m.set_shader_parameter("hue_shift", g[3])
	return m

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
	var walls := Image.create(w, h, false, Image.FORMAT_RGBA8)   # (the barriers alone: no tree over them)
	var gap_at := {}
	for gp in rc._gap_squares:
		gap_at[gp[0]] = gp[1]
	for g in tiles:
		var name: String = tiles[g]
		if gap_at.has(g):
			_stamp(track, gap_piece(name, suffix, gap_at[g]), org.call(g))
			continue
		_stamp(track, img(name + suffix), org.call(g))
	for g in rc._rail_squares:                         # (the barriers after every road piece: a straight's side face never over a run-on)
		_tyres_on([track, walls], String(tiles[g]).substr(7), suffix, rc.level, g, tiles, org.call(g))
	_stamp(track, img(("start_h" if tiles.get(rc._start_square, "") == "straight_h" else "start_v") + suffix), org.call(rc._start_square))
	for pd in rc._pad_squares:
		_stamp(track, img("boost_" + _compass(pd[1]) + suffix), org.call(pd[0]))
	for gp in rc._gap_squares:
		var d: Vector2 = gp[1]
		_stamp(track, img("ramp_" + _compass(d) + suffix), org.call(gp[0]) - Vector2i(d.round()) * ramp_shift())
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
	var stands: Array = rc._stands().map(func(st): return Rect2(st.rect.position / ART_PX, st.rect.size / ART_PX).grow(6.0))
	var placed: Array[Rect2i] = []                      # (decor never on other decor: the user, flowers were over bushes)
	var clear := func(r: Rect2i) -> bool:
		for q in placed:
			if q.grow(4).intersects(r):
				return false
		if r.position.x < FRAME + 2 or r.position.y < FRAME + 2 or r.end.x > w - FRAME - 2 or r.end.y > h - FRAME - 2:
			return false
		for sr in stands:
			if sr.intersects(Rect2(r)):
				return false
		for yy in range(r.position.y - 6, r.end.y + 6, 4):
			for xx in range(r.position.x - 6, r.end.x + 6, 4):
				if xx >= 0 and yy >= 0 and xx < w and yy < h and track.get_pixel(xx, yy).a > 0.0:
					return false
		return true
	var area := float(w * h) / float(SQ * SQ)
	# the bushes, every kind drawn so far, each kind kept well apart from itself; then the flowers
	var kinds: Array = BUSHES.filter(func(n): return ResourceLoader.exists(DIR + n + ".png"))
	var where := {}                                     # bush kind -> its centres so far
	for _k in int(area * BUSHES_PER_SQ):
		for _try in 16:
			var name: String = kinds[rng.randi() % kinds.size()]
			var im := _bush(name)
			var p := Vector2i(rng.randi_range(0, w - im.get_width()), rng.randi_range(0, h - im.get_height()))
			var mid := Vector2(p) + Vector2(im.get_size()) / 2.0
			if where.get(name, []).any(func(c): return c.distance_to(mid) < SAME_BUSH_APART):
				continue
			if clear.call(Rect2i(p, im.get_size())):
				placed.append(Rect2i(p, im.get_size()))
				where[name] = where.get(name, []) + [mid]
				_stamp(floor_img, _shadow_of(im), p + DECOR_SHADE)
				_stamp(floor_img, im, p)
				break
	for spec in [["flowers_a", 1.2], ["flowers_b", 1.2]]:
		var im := img(spec[0])
		for _k in int(area * float(spec[1])):
			for _try in 12:
				var p := Vector2i(rng.randi_range(0, w - im.get_width()), rng.randi_range(0, h - im.get_height()))
				if clear.call(Rect2i(p, im.get_size())):
					placed.append(Rect2i(p, im.get_size()))
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
		if not _hides(im, p, walls):
			_stamp(canopy, im, p)
	return [floor_img, track, canopy]

## Would the picture at p cover any of `under`'s pixels (sampled every 3 px)?
static func _hides(im: Image, p: Vector2i, under: Image) -> bool:
	for y in range(0, im.get_height(), 3):
		for x in range(0, im.get_width(), 3):
			var q := p + Vector2i(x, y)
			if q.x >= 0 and q.y >= 0 and q.x < under.get_width() and q.y < under.get_height() \
					and im.get_pixel(x, y).a > 0.0 and under.get_pixel(q.x, q.y).a > 0.0:
				return true
	return false

## A bush, doubled with Scale2x (a TRIAL, the user 2026-10-27: the designer's bushes, shrunk from big
## pictures, looked denser than the trees, as if farther away; doubled, their leaves match the trees')
static func _bush(name: String) -> Image:
	if not BUSH_X2:
		return img(name)
	var key := name + "_x2"
	if not _cache.has(key):
		_cache[key] = scale2x(img(name))
	return _cache[key]

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

## A corner's tyre wall: red/white, or on even levels the second colours (blue/yellow) once drawn
## (the user 2026-10-27: both, mixed by level; 2026-10-28: the blocks on every curve, TYRES_ALT off)
const TYRES_ALT := false
static func _tyres(corner: String, suffix: String, level: int) -> Image:
	var alt := "tyres_" + corner + "_alt" + suffix
	if TYRES_ALT and level % 2 == 0 and ResourceLoader.exists(DIR + alt + ".png"):
		return img(alt)
	return img("tyres_" + corner + suffix)

## A corner's barrier stamped at its square's top-left `at`: a file wider than the square (round 21) has a
## margin round it with the wall's run-on past each end of the curve, kept only where the next square that way
## is a straight (at a hairpin the next corner walls itself). RUN_ONS false (the user, 2026-10-28: they looked
## detached): only the curve's own wall
const RUN_ONS := false
const RUN_STRIPS := { "n": Vector2i(0, -1), "s": Vector2i(0, 1), "w": Vector2i(-1, 0), "e": Vector2i(1, 0) }
static func _tyres_on(dst: Array, corner: String, suffix: String, level: int, g: Vector2i, tiles: Dictionary, at: Vector2i) -> void:
	var im := _tyres(corner, suffix, level)
	if im == null:
		return
	var run := (im.get_width() - SQ) / 2
	if run <= 0:
		for d in dst:
			_stamp(d, im, at)
		return
	var copied := false
	for e in corner:
		if RUN_ONS and String(tiles.get(g + RUN_STRIPS[e], "")).begins_with("straight"):
			continue
		if not copied:
			im = im.duplicate()
			copied = true
		var strip: Rect2i = { "n": Rect2i(run, 0, SQ, run), "s": Rect2i(run, run + SQ, SQ, run),
			"w": Rect2i(0, run, run, SQ), "e": Rect2i(run + SQ, run, run, SQ) }[e]
		im.fill_rect(strip, Color(0, 0, 0, 0))
	for d in dst:
		_stamp(d, im, at - Vector2i(run, run))

## The middle of a jump's hole (world px) in its square, driving `dir`
static func hole_at(g: Vector2i, pad: float, cell: float, dir: Vector2) -> Vector2:
	return at(g, pad, cell) + dir * float(HOLE_AHEAD) * ART_PX

## The ramp's reach (ramp_e's drawing, px across its square): [its low end, its high end]. The game
## draws it so the high end meets the hole (ramp_shift) and makes the ramp as long as drawn
## (the user 2026-10-27: the designer's long ramp; the others are its turns and mirror)
static func ramp_reach() -> Vector2i:
	if not _cache.has("ramp_reach"):
		var r := img("ramp_e").get_used_rect()
		_cache["ramp_reach"] = Vector2i(r.position.x, r.end.x) if r.size.x > 0 else Vector2i(SQ / 2 - 20, SQ / 2 + 20)
	return _cache["ramp_reach"]

## How far back from its square the ramp is drawn, art px: its high end right at the hole's start
static func ramp_shift() -> int:
	return ramp_reach().y - (SQ / 2 + HOLE_AHEAD - int(GAP_HOLE / ART_PX))

## The ramp's length, world px (where the car counts as on it)
static func ramp_length() -> float:
	return float(ramp_reach().y - ramp_reach().x) * ART_PX

## A jump's square: its straight piece with the hole cut out (GAP_HOLE each side of HOLE_AHEAD past the middle), the
## cut ends outlined and, where a road end faces down the screen, the raised side face under it.
## (Built from the straight, so it always matches the road: the user, the designer's gap pieces
## had corner curbs and an unfinished surface at the cut)
static func gap_piece(straight: String, suffix: String, dir: Vector2) -> Image:
	var ahead := HOLE_AHEAD * int(signf(dir.x + dir.y))  # (down / right: further along the piece)
	var key := "gap_%s%s_%d" % [straight, suffix, ahead]
	if _cache.has(key):
		return _cache[key]
	var im: Image = img(straight + suffix).duplicate()
	var half := int(GAP_HOLE / ART_PX)
	var a := SQ / 2 + ahead - half                       # the hole: [a, b)
	var b := SQ / 2 + ahead + half
	var vertical := straight == "straight_v"
	var at := func(u: int, v: int) -> Vector2i:          # u along the road, v across it
		return Vector2i(v, u) if vertical else Vector2i(u, v)
	for u in range(a, b):
		for v in SQ:
			im.set_pixelv(at.call(u, v), Color(0, 0, 0, 0))
	for v in SQ:                                         # the cut ends' outline
		for u in [a - 1, b]:
			if im.get_pixelv(at.call(u, v)).a > 0.0:
				im.set_pixelv(at.call(u, v), OUTLINE)
	if vertical:                                         # the upper end faces south: its side face, as the straight's
		var across: Image = img("straight_h" + suffix)
		var face: Array[Color] = []
		for y in range(SQ - 1, -1, -1):                  # the straight's bottom: outline, then the face up to the road
			var c := across.get_pixel(SQ / 2, y)
			if c.a == 0.0:
				if face.is_empty():
					continue
				break
			face.push_front(c)
			if face.size() > FACE_ROWS:
				break
		for x in SQ:
			if im.get_pixel(x, a - 1).a > 0.0:
				for i in face.size():
					im.set_pixel(x, a + i, face[i])
	_cache[key] = im
	return im

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
