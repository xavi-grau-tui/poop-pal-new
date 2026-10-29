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
const SOCK_FOOT := Vector2(-75, -42)   # the windsock's pole foot from the start line, art px (on the runway near its back corner behind the plane, the user)
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

## The ground image, art px, for a board of `size` board px (rc_racer's PX = 2 art px): the fields, then the
## hedges on every field's edges, the river and its bridges, the decor in some fields (mills: windmills, their sails
## turning on their own sprites, RcSky.sails)
static var mills: Array[Vector2] = []  # the windmills' hubs in the last ground made, art px
const HEDGE_TREES := 0.3               # of the edges, a tree line (the rest a low hedge)
const DECOR := [["farmhouse_barn", 0.16], ["copse", 0.12], ["haystacks", 0.08], ["pond", 0.06], ["windmill_tower", 0.04],
	["village", 0.04], ["church", 0.03]]   # each field's chance of one
const BRIDGE_EVERY := 520              # art px along the river
const RIVER_CLEAR := 40.0              # decor this far from the river's middle at least, art px

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
	var xy := func(u: float, v: float) -> Vector2: return Vector2((0.9 * u - 0.32 * v) / DET, (0.24 * u + 0.86 * v) / DET)
	var lo := Vector2(INF, INF)
	var hi := Vector2(-INF, -INF)
	for c in [Vector2(0, 0), Vector2(w, 0), Vector2(0, h), Vector2(w, h)]:
		var q: Vector2 = uv.call(c.x, c.y)
		lo = lo.min(q)
		hi = hi.max(q)
	var cells: Array = []                             # [u0, v0, hash]
	for fy in range(int(floorf(lo.y / 76.0)), int(floorf(hi.y / 76.0)) + 1):
		for fx in range(int(floorf(lo.x / 92.0)), int(floorf(hi.x / 92.0)) + 1):
			var hsh := ((fx * 73856093) ^ (fy * 19349663)) & 0xffff
			cells.append([92.0 * fx, 76.0 * fy, hsh])
	# the fields
	for cell in cells:
		var u0: float = cell[0]
		var v0: float = cell[1]
		var hsh: int = cell[2]
		var patch: Image = patches[hsh % patches.size()]
		# its box (its four corners back in x, y), and where in the square it's cut from (a little shift each)
		var bl := Vector2(INF, INF)
		var bh := Vector2(-INF, -INF)
		for cu in [u0, u0 + 92.0]:
			for cv in [v0, v0 + 76.0]:
				var p: Vector2 = xy.call(cu, cv)
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
	# the hedges: on each field's top edge (along u) and left edge (along v), centred on it
	var hedges := [[img("hedge_low_a"), img("hedge_low_b")], [img("hedge_tree_line_a"), img("hedge_tree_line_b")]]
	for cell in cells:
		var u0: float = cell[0]
		var v0: float = cell[1]
		var hsh: int = cell[2]
		for e in 2:
			var trees := ((hsh >> (3 + e * 4)) % 10) < int(HEDGE_TREES * 10.0)
			var hd: Image = hedges[1 if trees else 0][e]
			if hd == null:
				continue
			var mid: Vector2 = xy.call(u0 + 46.0, v0) if e == 0 else xy.call(u0, v0 + 38.0)
			_put(out, hd, mid)
	# the river and its bridges
	var river := img("river")
	var river_y := func(x: float) -> float: return 2.0 * (size.y * 0.6 - 60.0 * sin(x * 0.5 * 0.012))
	if river:
		var rh := river.get_height()
		for x in w:
			var top := int(river_y.call(x)) - rh / 2
			var col := x % river.get_width()
			for r in rh:
				var c := river.get_pixel(col, r)
				if c.a > 0.5 and top + r >= 0 and top + r < h:
					out.set_pixel(x, top + r, c)
		# (a bridge where a field's short edge crosses the river: it carries the hedge's line over the water, the
		# user: one leading nowhere made no sense; seen from the side, up to the right like those edges)
		var bridge := img("decor_stone_bridge")
		if bridge:
			var last := -INF
			var crossings: Array[Vector2] = []
			for cell in cells:
				var a0: Vector2 = xy.call(float(cell[0]), float(cell[1]))
				var a1: Vector2 = xy.call(float(cell[0]), float(cell[1]) + 76.0)
				var f0: float = a0.y - river_y.call(a0.x)
				var f1: float = a1.y - river_y.call(a1.x)
				if signf(f0) == signf(f1):
					continue
				var lo_t := 0.0
				var hi_t := 1.0
				for _i in 12:
					var mt := (lo_t + hi_t) * 0.5
					var q := a0.lerp(a1, mt)
					if signf(q.y - river_y.call(q.x)) == signf(f0):
						lo_t = mt
					else:
						hi_t = mt
				crossings.append(a0.lerp(a1, lo_t))
			crossings.sort_custom(func(p, q): return p.x < q.x)
			for c in crossings:
				if c.x - last >= BRIDGE_EVERY and c.x > 0.0 and c.x < w:
					_put(out, bridge, c)
					last = c.x
	# the decor: in some fields, near their middle (never on the river)
	mills.clear()
	var total := 0.0
	for d in DECOR:
		total += float(d[1])
	for cell in cells:
		var hsh: int = cell[2]
		var roll := float((hsh * 2654435761) % 1000) / 1000.0
		if roll >= total:
			continue
		var acc := 0.0
		var kind := ""
		for d in DECOR:
			acc += float(d[1])
			if roll < acc:
				kind = d[0]
				break
		var at: Vector2 = xy.call(float(cell[0]) + 46.0 + float((hsh >> 4) % 21 - 10), float(cell[1]) + 38.0 + float((hsh >> 9) % 17 - 8))
		if absf(at.y - river_y.call(at.x)) < RIVER_CLEAR:
			continue
		var im := img("decor_" + kind)
		if im:
			_put(out, im, at)
			if kind == "windmill_tower":
				mills.append(at)
	return out

## A piece blended in centred on `at` (art px)
static func _put(out: Image, im: Image, at: Vector2) -> void:
	out.blend_rect(im, Rect2i(Vector2i.ZERO, im.get_size()), Vector2i((at - Vector2(im.get_size()) * 0.5).round()))

## The windmills' sails, made as pale as the ground round them (GROUND_SHADER's softening and haze, baked:
## they turn on their own sprite, not through the shader)
static func sails() -> Texture2D:
	if not _texs.has("sails_hazed"):
		var im := img("decor_windmill_sails")
		if im == null:
			_texs["sails_hazed"] = null
			return null
		im = im.duplicate()
		for y in im.get_height():
			for x in im.get_width():
				var c := im.get_pixel(x, y)
				if c.a <= 0.0:
					continue
				var v := Vector3(minf(1.0, c.r * 1.03 + 0.01), minf(1.0, c.g * 1.03 + 0.01), minf(1.0, c.b * 1.04 + 0.02))
				var l := v.dot(Vector3(0.3, 0.59, 0.11))
				v = v.lerp(Vector3(l, l, l), 0.3).lerp(Vector3(0.8, 0.86, 0.72), 0.35).lerp(Vector3(200, 224, 244) / 255.0, 0.52)
				im.set_pixel(x, y, Color(v.x, v.y, v.z, c.a))
		_texs["sails_hazed"] = ImageTexture.create_from_image(im)
	return _texs["sails_hazed"]

## The haze over it (it's a long way down), the clouds' shadows, the see-through clouds between it and the plane:
## _sky_floor's, on the art grid; noise_tex holds rc_racer's _cloud_noise at 2 board px a texel
const GROUND_SHADER := """
shader_type canvas_item;
uniform sampler2D noise_tex : filter_linear, repeat_disable;
uniform vec2 art_size;
uniform vec2 noise_size;
uniform float desaturate = 0.3;
uniform float flatten = 0.35;
uniform float haze = 0.52;
uniform bool painted_clouds = false;    // (the designer's drifting clouds and their shadows instead: SkyClouds)
float noise_at(vec2 b) { return texture(noise_tex, (b * 0.5 + 0.5) / noise_size).r * 2.0 - 1.0; }
void fragment() {
	vec2 p = floor(UV * art_size) + 0.5;
	vec2 b = p * 0.5;                       // board px
	vec4 c = texture(TEXTURE, UV);
	c.rgb = min(vec3(1.0), c.rgb * vec3(1.03, 1.03, 1.04) + vec3(0.01, 0.01, 0.02));   // noon (_lit)
	if (!painted_clouds && noise_at(b - vec2(17.5, 27.5)) > 0.28) c.rgb *= 0.88;      // a cloud's shadow
	// far away (the user: paler, like the original): the paintings' contrast and colour softened, then the haze
	float l = dot(c.rgb, vec3(0.3, 0.59, 0.11));
	c.rgb = mix(c.rgb, vec3(l), desaturate);
	c.rgb = mix(c.rgb, vec3(0.80, 0.86, 0.72), flatten);
	c.rgb = mix(c.rgb, vec3(200.0, 224.0, 244.0) / 255.0, haze);
	float n = noise_at(b);
	ivec2 q = ivec2(p) % 2;
	float d = q.y == 0 ? (q.x == 0 ? 0.125 : 0.625) : (q.x == 0 ? 0.875 : 0.375);
	if (!painted_clouds && (n > 0.28 || (n > 0.22 && d < 0.5))) c.rgb = mix(c.rgb, vec3(250.0, 252.0, 255.0) / 255.0, 0.6);   // a cloud
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
	m.set_shader_parameter("painted_clouds", false)   # (the original far clouds stay under the painted ones: the user)
	return m

## ---- The drifting clouds (the designer's, round 4): nearly see-through, in two layers between the plane and the
## ground (each at its own depth: rc_racer SkyClouds), their shadows drifting over the fields
const CLOUDS_LOW := ["cloud_large_a", "cloud_large_b", "cloud_medium_a", "cloud_medium_b"]
const CLOUDS_HIGH := ["cloud_medium_a", "cloud_medium_b", "cloud_small_a", "cloud_small_b"]

static func has_clouds() -> bool:
	return ResourceLoader.exists(DIR + "cloud_large_a.png")

## A drifting cloud made paler (far away): its colours eased towards the sky's haze by `amount` (0: as painted)
static func paled(name: String, amount: float) -> Texture2D:
	if amount <= 0.0:
		return tex(name)
	var key := "%s_pale_%.2f" % [name, amount]
	if not _texs.has(key):
		var im := img(name)
		if im == null:
			_texs[key] = null
			return null
		im = im.duplicate()
		var haze := Color8(226, 236, 248)
		for y in im.get_height():
			for x in im.get_width():
				var c := im.get_pixel(x, y)
				if c.a > 0.0:
					var p := c.lerp(haze, amount)
					im.set_pixel(x, y, Color(p.r, p.g, p.b, c.a))
		_texs[key] = ImageTexture.create_from_image(im)
	return _texs[key]

static func balloon(k: int) -> Texture2D:
	return tex("balloon_blue" if k % 2 == 0 else "balloon_pink")
