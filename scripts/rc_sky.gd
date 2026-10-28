extends RefCounted
class_name RcSky
## RC Prix's Sky in the designer's art (docs/mockups/rcprix_sky/PLAN.md), a TRIAL behind the dev launcher's
## RC ART switch like the Garden and the Lagoon (the old look stays a switch away). Round 1: the rings, the
## start pad (its deck, the start line, the landing lights, the drone rotors as pieces the game spins) and
## the cloud the Garden's stands sit on, their canopy light blue. The ground far below and the drifting
## clouds are still the old ones (later rounds). One art px = ART_PX world px.

const DIR := "res://textures/minigames/rcprix/sky/"
const ART_PX := 2.0
const RINGS := [86, 88, 90, 92, 94, 96, 98, 100, 102, 104, 106, 108, 110, 112, 114, 116, 118, 120, 122, 124]   # the sizes
                                       # on the grid (ring_r, world px; tools/art/rcprix_sky_from_sources.py): the nearest drawn
const PAD_MARGIN := 33                 # the pad's picture reaches this far past its deck, art px (the guides: the rotors)
const CLOUD_MARGIN := 22               # the stand's cloud reaches this far past its pieces, art px (the guides)
const CANOPY_HUE := 0.56               # the stand's canopy, light blue (the user, 2026-10-28)
static var _imgs := {}
static var _texs := {}

static func on(look: String) -> bool:
	return DevLaunch.rc_new_art and look == "sky" and ResourceLoader.exists(DIR + "ring_124.png")

static func img(name: String) -> Image:
	if not _imgs.has(name):
		var path := DIR + name + ".png"
		var im: Image = null
		if ResourceLoader.exists(path):
			im = (load(path) as Texture2D).get_image()
			if im.is_compressed():
				im.decompress()
			im.convert(Image.FORMAT_RGBA8)
		_imgs[name] = im
	return _imgs[name]

## A piece as a texture for _draw calls (flipped across / down when asked: the rotors' arms)
static func tex(name: String, flip_x := false, flip_y := false) -> Texture2D:
	var key := "%s_%s_%s" % [name, flip_x, flip_y]
	if not _texs.has(key):
		var im := img(name)
		if im == null:
			_texs[key] = null
		else:
			im = im.duplicate()
			if flip_x:
				im.flip_x()
			if flip_y:
				im.flip_y()
			_texs[key] = ImageTexture.create_from_image(im)
	return _texs[key]

## One half of a ring, its look "candy" / "gold" / "grey": the designer's wide ring at the painted size nearest
## r (turned over its diagonal for a course going sideways: the light stays top left), only the pixels on
## the half the plane flies in by (upper) or leaves by. -> [texture, its top left (world px), its scale]
static func ring_half(r: float, look: String, n: Vector2, d: Vector2, upper: bool) -> Array:
	var size: int = RINGS[0]
	for s in RINGS:
		if absf(s - r) < absf(size - r):
			size = s
	var name := "ring_%d" % size if look == "candy" else "ring_%s_%d" % [look, size]
	var im := img(name).duplicate()
	if absf(n.y) > absf(n.x):
		im.rotate_90(CLOCKWISE)                       # (then mirrored: over the diagonal)
		im.flip_x()
	var half := Vector2(im.get_width(), im.get_height()) * 0.5
	for y in im.get_height():
		for x in im.get_width():
			var q := (Vector2(x + 0.5, y + 0.5) - half) * ART_PX
			if (q.dot(d) <= 0.0) != upper:
				im.set_pixel(x, y, Color(0, 0, 0, 0))
	return [ImageTexture.create_from_image(im), -half * ART_PX, ART_PX]

## The cloud under a stand `long` art px long, whole (round 2: one per stand length; null: the round 1 cloud,
## cut and repeated like the stand)
static func stand_cloud(view: String, layer: String, long: int) -> Texture2D:
	return tex("stand_cloud_%s_%s_%d" % [view, layer, long])

## A stand piece with its canopy light blue (the Garden's greens turned, as the Lagoon turned them warm)
static func stand_tex(name: String) -> Texture2D:
	var key := "stand_" + name
	if not _texs.has(key):
		var im := RcTiles.img(name)
		if im == null:
			_texs[key] = null
			return null
		im = im.duplicate()
		for y in im.get_height():
			for x in im.get_width():
				var c := im.get_pixel(x, y)
				if c.a > 0.0 and c.s > 0.25 and c.h > 0.2 and c.h < 0.5:
					im.set_pixel(x, y, Color.from_hsv(CANOPY_HUE, minf(1.0, c.s * 0.55), minf(1.0, c.v * 1.35), c.a))
		_texs[key] = ImageTexture.create_from_image(im)
	return _texs[key]

## ---- The ground far below (round 3): the designer's field paintings on today's diagonal grid
## (rc_racer _sky_floor: in board px, u = x * 0.86 + y * 0.32 in steps of 46, v = y * 0.9 - x * 0.24 in steps of 38;
## here in art px, twice as fine: steps of 92 and 76). Each field is filled from its kind's square (turned to the
## grid in tools/art/rcprix_sky_from_sources.py), row by row; the hedges and the river drawn as today's for now
## (the designer's come next); the haze, the clouds' shadows and the see-through clouds in GROUND_SHADER, as today.
const FIELD_KINDS := ["wheat", "young_green_crop", "meadow", "ploughed_earth", "pasture", "orchard", "vegetable_rows", "hay"]
const FIELD_PATCH := 132               # a kind's square, art px (bigger than any field's box: 126 x 103)
const DET := 0.86 * 0.9 + 0.32 * 0.24  # (the grid's u, v back to x, y)
const HEDGE := Color8(120, 160, 110)
const HEDGE_TREE := Color8(96, 140, 96)
const RIVER := Color8(176, 210, 230)
const RIVER_BANK := Color8(206, 216, 176)

static func has_ground() -> bool:
	return ResourceLoader.exists(DIR + "field_wheat.png")

## The ground image, art px, for a board of `size` board px (rc_racer's PX = 2 art px)
static func ground(size: Vector2i) -> Image:
	var w := size.x * 2
	var h := size.y * 2
	var out := Image.create(w, h, false, Image.FORMAT_RGBA8)
	out.fill(Color8(170, 200, 140))
	var patches: Array[Image] = []
	for k in FIELD_KINDS:
		var p := img("field_" + k)
		if p:
			patches.append(p)
	var uv := func(x: float, y: float) -> Vector2: return Vector2(x * 0.86 + y * 0.32, y * 0.9 - x * 0.24)
	var lo := Vector2(INF, INF)
	var hi := Vector2(-INF, -INF)
	for c in [Vector2(0, 0), Vector2(w, 0), Vector2(0, h), Vector2(w, h)]:
		var q: Vector2 = uv.call(c.x, c.y)
		lo = lo.min(q)
		hi = hi.max(q)
	for fy in range(int(floorf(lo.y / 76.0)), int(floorf(hi.y / 76.0)) + 1):
		for fx in range(int(floorf(lo.x / 92.0)), int(floorf(hi.x / 92.0)) + 1):
			var hsh := ((fx * 73856093) ^ (fy * 19349663)) & 0xffff
			var patch: Image = patches[hsh % patches.size()]
			var u0 := 92.0 * fx
			var v0 := 76.0 * fy
			# its box (its four corners back in x, y), and where in the square it's cut from (a little shift each)
			var bl := Vector2(INF, INF)
			var bh := Vector2(-INF, -INF)
			for cu in [u0, u0 + 92.0]:
				for cv in [v0, v0 + 76.0]:
					var p := Vector2((0.9 * cu - 0.32 * cv) / DET, (0.24 * cu + 0.86 * cv) / DET)
					bl = bl.min(p)
					bh = bh.max(p)
			var box := Rect2i(Vector2i(bl.floor()), Vector2i((bh - bl.floor()).ceil()))
			var off := Vector2i((hsh / 8) % maxi(1, FIELD_PATCH - box.size.x + 1), (hsh / 64) % maxi(1, FIELD_PATCH - box.size.y + 1))
			for y in range(maxi(0, box.position.y), mini(h, box.end.y + 1)):
				var yc := y + 0.5
				# the row's span inside the field: u in [u0, u0 + 92), v in [v0, v0 + 76) (pixel centres)
				var a := maxf((u0 - 0.32 * yc) / 0.86, (0.9 * yc - v0 - 76.0) / 0.24)
				var b := minf((u0 + 92.0 - 0.32 * yc) / 0.86, (0.9 * yc - v0) / 0.24)
				var xs := maxi(0, int(ceilf(a - 0.5)))
				var xe := mini(w - 1, int(ceilf(b - 0.5)) - 1)
				if xs > xe:
					continue
				var sx := clampi(xs - box.position.x + off.x, 0, FIELD_PATCH - 1)
				var sy := clampi(y - box.position.y + off.y, 0, FIELD_PATCH - 1)
				out.blit_rect(patch, Rect2i(sx, sy, mini(xe - xs + 1, FIELD_PATCH - sx), 1), Vector2i(xs, y))
			_hedge(out, Vector2((0.9 * u0 - 0.32 * v0) / DET, (0.24 * u0 + 0.86 * v0) / DET), Vector2(0.9 * 92.0, 0.24 * 92.0) / DET, hsh)
			_hedge(out, Vector2((0.9 * u0 - 0.32 * v0) / DET, (0.24 * u0 + 0.86 * v0) / DET), Vector2(-0.32 * 76.0, 0.86 * 76.0) / DET, hsh / 3)
	_river(out, size.y)
	return out

## A field's edge from `a` along `along`: a hedge 2 art px thick, a darker tree on it now and then
static func _hedge(out: Image, a: Vector2, along: Vector2, seed_n: int) -> void:
	var n := int(along.length() * 2.0)
	var side := Vector2(-along.y, along.x).normalized()
	for i in n:
		var p := a + along * (float(i) / n)
		for q in [p, p + side]:
			var x := int(q.x)
			var y := int(q.y)
			if x >= 0 and y >= 0 and x < out.get_width() and y < out.get_height():
				out.set_pixel(x, y, HEDGE_TREE if (i / 2 + seed_n) % 9 < 2 else HEDGE)

## Today's pale river winding across (_sky_floor's: its middle bh * 0.6 - 60 sin(x * 0.012) board px), 16 art px wide
static func _river(out: Image, bh: int) -> void:
	for x in out.get_width():
		var yc := int(2.0 * (bh * 0.6 - 60.0 * sin(x * 0.5 * 0.012)))
		for dy in range(-9, 10):
			var y := yc + dy
			if y >= 0 and y < out.get_height():
				out.set_pixel(x, y, RIVER_BANK if absi(dy) > 7 else RIVER)

## The haze over it (it's a long way down), the clouds' shadows, the see-through clouds between it and the plane:
## _sky_floor's, on the art grid; noise_tex holds rc_racer's _cloud_noise at 2 board px a texel
const GROUND_SHADER := """
shader_type canvas_item;
uniform sampler2D noise_tex : filter_linear, repeat_disable;
uniform vec2 art_size;
uniform vec2 noise_size;
float noise_at(vec2 b) { return texture(noise_tex, (b * 0.5 + 0.5) / noise_size).r * 2.0 - 1.0; }
void fragment() {
	vec2 p = floor(UV * art_size) + 0.5;
	vec2 b = p * 0.5;                       // board px
	vec4 c = texture(TEXTURE, UV);
	c.rgb = min(vec3(1.0), c.rgb * vec3(1.03, 1.03, 1.04) + vec3(0.01, 0.01, 0.02));   // noon (_lit)
	if (noise_at(b - vec2(17.5, 27.5)) > 0.28) c.rgb *= 0.88;                         // a cloud's shadow
	c.rgb = mix(c.rgb, vec3(200.0, 224.0, 244.0) / 255.0, 0.42);                      // the haze
	float n = noise_at(b);
	ivec2 q = ivec2(p) % 2;
	float d = q.y == 0 ? (q.x == 0 ? 0.125 : 0.625) : (q.x == 0 ? 0.875 : 0.375);
	if (n > 0.28 || (n > 0.22 && d < 0.5)) c.rgb = mix(c.rgb, vec3(250.0, 252.0, 255.0) / 255.0, 0.6);   // a cloud
	COLOR = c;
}
"""

static func ground_material(noise: FastNoiseLite, size: Vector2i) -> ShaderMaterial:
	var nw := size.x / 2 + 2
	var nh := size.y / 2 + 2
	var im := Image.create(nw, nh, false, Image.FORMAT_L8)
	for y in nh:
		for x in nw:
			var v := noise.get_noise_2d(x * 2.0 * 0.8, y * 2.0 * 0.8)
			im.set_pixel(x, y, Color(v * 0.5 + 0.5, 0, 0))
	var sh := Shader.new()
	sh.code = GROUND_SHADER
	var m := ShaderMaterial.new()
	m.shader = sh
	m.set_shader_parameter("noise_tex", ImageTexture.create_from_image(im))
	m.set_shader_parameter("art_size", Vector2(size * 2))
	m.set_shader_parameter("noise_size", Vector2(nw, nh))
	return m
