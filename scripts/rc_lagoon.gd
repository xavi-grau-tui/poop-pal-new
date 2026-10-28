extends RefCounted
class_name RcLagoon
## RC Prix's Lagoon in the designer's art (docs/mockups/rcprix_lagoon/PLAN.md), a TRIAL behind the dev
## launcher's RC ART switch like the Garden (the user, 2026-10-28: the old look must stay a switch away).
## Not square pieces: the water's edges are soft bands that run past a square (two channels side by side
## share one sand spit), so the game keeps the shapes, the distance to the channel's centre as now, and
## the designer gives the look: seamless squares of open water, channel, shallows and sand (three
## variants each, sharing their border so any mix joins), the bank's edges drawn crisp in their colours.
## A shader on the board draws it at twice the board's detail (one art px = ART_PX world px). What isn't
## redrawn yet keeps the old board's pixels: the islands, the palms, the sandbars and the frame
## (rc_racer's _keep).

const DIR := "res://textures/minigames/rcprix/lagoon/"
const ART_PX := 2.0
const SQ := 190                       # a square, art px (CELLS["boat"] / ART_PX)
const HALF := { false: 106.0, true: 116.0 }   # the channel's half width, world px: [later levels, early ones (wide)]
const KINDS := ["water", "channel", "shallows", "sand"]
const VARIANTS := ["a", "b", "c"]
## the bank's edges (round 1: the current colours until the designer's bank sample)
const OUTLINE := Color8(118, 82, 58)
const WET := Color8(214, 180, 126)
const FOAM := Color8(255, 240, 226)
## the sunset across the board, top to bottom, added to the water squares (painted at its middle)
const SKY_TOP := Color8(236, 150, 116)
const SKY_BOTTOM := Color8(176, 104, 140)
const BANK_W := 40.0                  # the sand bank's width, world px (as the old one's ~10 board px)
const BANK_MIN := 24.0                # ...never thinner than this (the sea's edge is a coarse field)

static func on(look: String) -> bool:
	return DevLaunch.rc_new_art and look == "lagoon" and ResourceLoader.exists(DIR + "water_a.png")

static func half_width(level: int) -> float:
	return HALF[RcTiles.wide(level)]

## A 0/1 mask as 0/255 (the shader reads it 0..1)
static func _full(mask: PackedByteArray) -> PackedByteArray:
	var out := PackedByteArray()
	out.resize(mask.size())
	for i in mask.size():
		out[i] = 255 if mask[i] != 0 else 0
	return out

## A kind's three variants side by side (A | B | C), one texture for the shader
static func _atlas(kind: String) -> ImageTexture:
	var parts: Array[Image] = []
	for v in VARIANTS:
		var path: String = DIR + kind + "_" + v + ".png"
		var t := load(path if ResourceLoader.exists(path) else DIR + kind + "_a.png") as Texture2D
		var im := t.get_image()
		if im.is_compressed():
			im.decompress()
		im.convert(Image.FORMAT_RGBA8)
		parts.append(im)
	var out := Image.create(SQ * 3, SQ, false, Image.FORMAT_RGBA8)
	for i in 3:
		out.blit_rect(parts[i], Rect2i(0, 0, SQ, SQ), Vector2i(SQ * i, 0))
	return ImageTexture.create_from_image(out)

## The board's material, from rc_racer's fields: _dist (each board px's distance to the centre line, board
## px), _keep (1: the old board's pixel stays), _sea (per coarse cell, how far inside the open water, world
## px; <= 0: sand)
static func material(rc) -> ShaderMaterial:
	var w: int = rc._bw
	var h: int = rc._bh
	var d := PackedFloat32Array()
	d.resize(w * h)
	for i in w * h:
		d[i] = minf(rc._dist[i], 4000.0)
	var dist_im := Image.create_from_data(w, h, false, Image.FORMAT_RF, d.to_byte_array())
	var keep_im := Image.create_from_data(w, h, false, Image.FORMAT_R8, _full(rc._keep))
	var sea_im := Image.create_from_data(rc._sea_w, rc._sea_h, false, Image.FORMAT_RF, rc._sea.to_byte_array())
	var sh := Shader.new()
	sh.code = SHADER
	var m := ShaderMaterial.new()
	m.shader = sh
	m.set_shader_parameter("dist_tex", ImageTexture.create_from_image(dist_im))
	m.set_shader_parameter("keep_tex", ImageTexture.create_from_image(keep_im))
	m.set_shader_parameter("sea_tex", ImageTexture.create_from_image(sea_im))
	for kind in KINDS:
		m.set_shader_parameter(kind + "_tex", _atlas(kind))
	var k: float = rc.PX / ART_PX                    # art px per board px
	m.set_shader_parameter("board_size", Vector2(w, h))
	m.set_shader_parameter("sea_size", Vector2(rc._sea_w, rc._sea_h))
	m.set_shader_parameter("sea_cell", float(rc.SEA_CELL))
	m.set_shader_parameter("k", k)
	m.set_shader_parameter("sq", float(SQ))
	m.set_shader_parameter("hw", rc.half_w / ART_PX)
	m.set_shader_parameter("shore", rc.SHORE_PAINT / ART_PX)
	m.set_shader_parameter("bank_min", BANK_MIN / ART_PX)
	m.set_shader_parameter("art_px", ART_PX)
	m.set_shader_parameter("outline", OUTLINE)
	m.set_shader_parameter("wet", WET)
	m.set_shader_parameter("foam", FOAM)
	m.set_shader_parameter("sky_top", SKY_TOP)
	m.set_shader_parameter("sky_bottom", SKY_BOTTOM)
	return m

const SHADER := """
shader_type canvas_item;
uniform sampler2D dist_tex : filter_linear;      // board px to the centre line
uniform sampler2D keep_tex : filter_nearest;     // 1: the old board's pixel
uniform sampler2D sea_tex : filter_linear;       // per coarse cell: world px inside the open water (<= 0: sand)
uniform sampler2D water_tex : filter_nearest;    // each: variants A | B | C, a square each
uniform sampler2D channel_tex : filter_nearest;
uniform sampler2D shallows_tex : filter_nearest;
uniform sampler2D sand_tex : filter_nearest;
uniform vec2 board_size;                         // board px
uniform vec2 sea_size;                           // the coarse cells
uniform float sea_cell;                          // board px per cell
uniform float art_px;                            // world px per art px
uniform float k;                                 // art px per board px
uniform float sq;                                // a square, art px
uniform float hw;                                // the channel's half width, art px
uniform float shore;                             // the shallows' width past it
uniform float bank_min;                          // the sand bank's least width
uniform vec4 outline : source_color;
uniform vec4 wet : source_color;
uniform vec4 foam : source_color;
uniform vec4 sky_top : source_color;
uniform vec4 sky_bottom : source_color;

float hash(vec2 p) { return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453); }
float noise(vec2 p) {
	vec2 i = floor(p), f = fract(p);
	f = f * f * (3.0 - 2.0 * f);
	return mix(mix(hash(i), hash(i + vec2(1, 0)), f.x), mix(hash(i + vec2(0, 1)), hash(i + vec2(1, 1)), f.x), f.y);
}
// a kind's square at this art px: one of its three variants, picked per square
vec3 tile(sampler2D t, vec2 cell) {
	vec2 s = floor(cell / sq);
	float v = floor(hash(s * 1.37 + 0.71) * 3.0);
	vec2 in_sq = mod(cell, sq) + 0.5;
	return texture(t, vec2((v * sq + in_sq.x) / (sq * 3.0), in_sq.y / sq)).rgb;
}
// the sunset, top to bottom, in eight steps (a checkerboard between): added to the water squares
vec3 sky(vec2 cell, float rows) {
	float y = cell.y / rows * 8.0;
	float st = floor(y);
	if (fract(y) > 0.9 && mod(cell.x + cell.y, 2.0) < 1.0) st += 1.0;
	float t = clamp(st / 7.0, 0.0, 1.0);
	return mix(sky_top.rgb, sky_bottom.rgb, t) - mix(sky_top.rgb, sky_bottom.rgb, 0.5);
}

void fragment() {
	vec2 cell = floor(UV * board_size * k);          // this art px
	vec2 at = (cell + 0.5) / (board_size * k);
	if (texture(keep_tex, at).r > 0.5) {
		COLOR = texture(TEXTURE, at);
	} else {
		float d = texture(dist_tex, at).r * k;       // art px to the centre line
		float wob = (noise(cell / 26.0) - 0.5) * 3.0;
		float bank = hw + shore + wob;
		vec2 sea_at = ((cell + 0.5) / k / sea_cell) / sea_size;
		float sea = texture(sea_tex, sea_at).r / art_px + (noise(cell / 18.0 + 13.0) - 0.5) * 4.0;   // art px into the water
		if (d < bank + bank_min) sea = min(sea, -2.0);                // (the bank: always sand)
		bool check = mod(cell.x + cell.y, 2.0) < 1.0;
		vec3 c;
		if (d <= hw) {
			c = tile(channel_tex, cell) + sky(cell, board_size.y * k);
		} else if (d < bank) {
			c = tile(shallows_tex, cell) + sky(cell, board_size.y * k);
			if (d > bank - 2.0 && check) c = foam.rgb;              // (foam where it breaks on the sand)
		} else if (sea <= 0.0) {                                     // the sand: the bank, and the narrow gaps filled
			if (d < bank + 1.0 || sea > -1.0) c = outline.rgb;
			else if (d < bank + 2.0 || sea > -2.0) c = wet.rgb;
			else c = tile(sand_tex, cell);
		} else {
			c = tile(water_tex, cell) + sky(cell, board_size.y * k);
			if (sea < 1.5 && check) c = foam.rgb;                    // (a line of foam along the beach)
		}
		c = mix(c, vec3(1.0, 0.667, 0.431), 0.12);                 // (the sunset's warmth over all, as the old _lit)
		COLOR = vec4(c, 1.0);
	}
}
"""

## The sand's decor (the user, 2026-10-28: starfish etc. like the original): pebbles, starfish and shells
## along the banks and over the sand of the filled gaps, seagrass in the shallows by the sand; one image over the board at
## art px. Each kind a PNG (round 1: the original ones drawn at its size, until the designer's)
const DECOR := ["pebble", "starfish", "shell"]
const DECOR_CHANCE := [0.16, 0.08, 0.1]          # per spot along a bank, as the original
const INLAND_DECOR := 1.0 / 2600.0              # per art px² of the filled gaps' sand
const SEAGRASS_CHANCE := 0.3
const WARM := Color(1.0, 0.667, 0.431)          # (the sunset's warmth, as the board's)

static func _decor_tex(name: String) -> Image:
	var path := DIR + name + ".png"
	if not ResourceLoader.exists(path):
		return null
	var im := (load(path) as Texture2D).get_image()
	if im.is_compressed():
		im.decompress()
	im.convert(Image.FORMAT_RGBA8)
	for y in im.get_height():                    # (warmed like the board)
		for x in im.get_width():
			var c := im.get_pixel(x, y)
			if c.a > 0.0:
				im.set_pixel(x, y, Color(c.lerp(WARM, 0.12), c.a))
	return im

static func decor(rc) -> Image:
	var k := int(rc.PX / ART_PX)
	var w: int = rc._bw * k
	var h: int = rc._bh * k
	var out := Image.create(w, h, false, Image.FORMAT_RGBA8)
	var kinds := {}                              # kind -> its variants (starfish, starfish_b, starfish_c...)
	for n in DECOR + ["seagrass"]:
		for v in ["", "_b", "_c", "_d"]:
			var im := _decor_tex(n + v)
			if im:
				if not kinds.has(n):
					kinds[n] = []
				kinds[n].append(im)
	if kinds.is_empty():
		return out
	var rng := RandomNumberGenerator.new()
	rng.seed = 91 * rc.course_seed + 3
	var hw: float = rc.half_w / ART_PX
	var bank: float = hw + rc.SHORE_PAINT / ART_PX
	var taken: Array[Rect2i] = []
	var dist_at := func(p: Vector2) -> float:
		var b := Vector2i(p / k)
		if b.x < 0 or b.y < 0 or b.x >= rc._bw or b.y >= rc._bh:
			return -1.0
		return rc._dist[b.y * rc._bw + b.x] * k
	var put := func(n: String, p: Vector2) -> void:
		if not kinds.has(n):
			return
		var im: Image = kinds[n][rng.randi_range(0, kinds[n].size() - 1)]
		var r := Rect2i(Vector2i(p.round()) - im.get_size() / 2, im.get_size())
		var b := Vector2i(p / k)
		if r.position.x < rc.EDGE * k or r.position.y < rc.EDGE * k or r.end.x > w - rc.EDGE * k or r.end.y > h - rc.EDGE * k:
			return
		if rc._keep[b.y * rc._bw + b.x] != 0:
			return                               # (not on an island, a sandbar, the frame)
		for q in taken:
			if q.grow(2).intersects(r):
				return                           # (never on other decor)
		taken.append(r)
		out.blend_rect(im, Rect2i(Vector2i.ZERO, im.get_size()), r.position)
	var pick := func() -> String:
		var roll := rng.randf() * (DECOR_CHANCE[0] + DECOR_CHANCE[1] + DECOR_CHANCE[2])
		for i in DECOR.size():
			roll -= DECOR_CHANCE[i]
			if roll <= 0.0:
				return DECOR[i]
		return DECOR[0]
	# along the banks, both sides
	for s0 in range(0, rc.count, 3):
		var c0: Vector2 = rc.centre[s0] / ART_PX
		var n0: Vector2 = rc._normal(s0)
		for sd in [-1.0, 1.0]:
			var at: float = bank + 9.0 + rng.randf_range(-3.0, 3.0)
			var p: Vector2 = c0 + n0 * sd * at
			if absf(dist_at.call(p) - at) > 4.0:
				continue                         # (another stretch of the course is nearer here)
			var roll := rng.randf()
			if roll < DECOR_CHANCE[0] + DECOR_CHANCE[1] + DECOR_CHANCE[2]:
				put.call(pick.call(), p)
			if rng.randf() < SEAGRASS_CHANCE:         # seagrass in the shallows, by the sand
				var g: Vector2 = c0 + n0 * sd * (bank - rng.randf_range(5.0, 12.0))
				if absf(dist_at.call(g) - (g - c0).length()) < 4.0:
					put.call("seagrass", g)
	# over the filled gaps' sand
	var spots := PackedInt32Array()               # (the sand of the filled gaps, away from its edges)
	for i in rc._bw * rc._bh:
		var ci: int = rc._sea_cell(Vector2i(i % rc._bw, i / rc._bw))
		if ci >= 0 and rc._sea[ci] < -24.0 and rc._dist[i] * k > bank + 30.0:
			spots.append(i)
	for t in int(spots.size() * k * k * INLAND_DECOR):
		var i: int = spots[rng.randi_range(0, spots.size() - 1)]
		put.call(pick.call(), Vector2(i % rc._bw, i / rc._bw) * k + Vector2(rng.randf_range(0, k), rng.randf_range(0, k)))
	return out
