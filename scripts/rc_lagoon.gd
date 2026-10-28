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
const KINDS := ["sand"]                # (the water: flat colours with moving layers in the shader, the user 2026-10-28)
const VARIANTS := ["a", "b", "c"]
## the bank's edges, from the designer's bank sample (round 1b, round1_bank/bank_paint_4x.png): no outlines;
## foam breaking on the sand (white, a pale teal fringe, scalloped), a strip of wet sand, and a soft fade from
## the channel into the shallows
const FOAM := Color8(0xff, 0xf6, 0xea)
const FOAM_FRINGE := Color8(0xfc, 0xe2, 0xca)    # (warm, not the sample's teal: the user)
const WET := Color8(0xea, 0xaa, 0x6a)
const FADE := [Color8(0xc9, 0x80, 0x84), Color8(0xd3, 0x8c, 0x86), Color8(0xd9, 0x93, 0x87)]   # (the channel's rose into the shallows)
## the sunset across the board, top to bottom, added to the water squares (painted at its middle)
const SKY_TOP := Color8(236, 150, 116)
const SKY_BOTTOM := Color8(176, 104, 140)
const BANK_W := 56.0                  # the sand bank's width, world px (the user: "slightly wider"; was 40)
const BANK_MIN := 12.0                # ...never thinner than this (the sea's edge is a coarse field; small enough for the rounded corners)

static func on(look: String) -> bool:
	return DevLaunch.rc_new_art and look == "lagoon" and ResourceLoader.exists(DIR + "sand_a.png")

static func half_width(level: int) -> float:
	return HALF[RcTiles.wide(level)]

## A water sprite's 4 frames side by side (null: not drawn yet, the shader draws its own)
static func _frames(name: String) -> ImageTexture:
	var parts: Array[Image] = []
	for i in 4:
		var im := _decor_tex("%s_%d" % [name, i])
		if im == null:
			return null
		parts.append(im)
	var w := parts[0].get_width()
	var h := parts[0].get_height()
	var out := Image.create(w * 4, h, false, Image.FORMAT_RGBA8)
	for i in 4:
		out.blit_rect(parts[i], Rect2i(0, 0, w, h), Vector2i(w * i, 0))
	return ImageTexture.create_from_image(out)

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
	m.set_shader_parameter("foam", FOAM)
	m.set_shader_parameter("foam_fringe", FOAM_FRINGE)
	m.set_shader_parameter("wet", WET)
	for i in 3:
		m.set_shader_parameter("fade%d" % i, FADE[i])
	for fx in ["glint", "crest"]:                    # the designer's water sprites (round 1c), if drawn: their frames side by side
		var frames := _frames(fx)
		m.set_shader_parameter("has_" + fx, 1.0 if frames else 0.0)
		if frames:
			m.set_shader_parameter(fx + "_tex", frames)
			m.set_shader_parameter(fx + "_size", Vector2(frames.get_width() / 4, frames.get_height()))
	m.set_shader_parameter("sky_top", SKY_TOP)
	m.set_shader_parameter("sky_bottom", SKY_BOTTOM)
	return m

const SHADER := """
shader_type canvas_item;
uniform sampler2D dist_tex : filter_linear;      // board px to the centre line
uniform sampler2D keep_tex : filter_nearest;     // 1: the old board's pixel
uniform sampler2D sea_tex : filter_linear;       // per coarse cell: world px inside the open water (<= 0: sand)
uniform sampler2D sand_tex : filter_nearest;     // the designer's sand: variants A | B | C, a square each
uniform vec2 board_size;                         // board px
uniform vec2 sea_size;                           // the coarse cells
uniform float sea_cell;                          // board px per cell
uniform float art_px;                            // world px per art px
uniform float k;                                 // art px per board px
uniform float soften = 7.0;                      // board px: how far the distance is averaged (rounds the corners)
uniform float sq;                                // a square, art px
uniform float hw;                                // the channel's half width, art px
uniform float shore;                             // the shallows' width past it
uniform float bank_min;                          // the sand bank's least width
uniform vec4 foam : source_color;
uniform vec4 foam_fringe : source_color;
uniform vec4 wet : source_color;
uniform vec4 fade0 : source_color;
uniform vec4 fade1 : source_color;
uniform vec4 fade2 : source_color;
uniform sampler2D glint_tex : filter_nearest;    // the designer's glint and crest frames (4 side by side)
uniform sampler2D crest_tex : filter_nearest;
uniform float has_glint = 0.0;
uniform float has_crest = 0.0;
uniform vec2 glint_size = vec2(5.0, 5.0);
uniform vec2 crest_size = vec2(10.0, 3.0);
uniform vec4 sky_top : source_color;
uniform vec4 sky_bottom : source_color;
// the water's colours: the original Lagoon's warm sunset (the user, 2026-10-28: option 3's plum was too purple,
// "more like the original but improved"): peach open water, a dusty rose channel a little deeper
const vec3 OPEN = vec3(0.878, 0.580, 0.498);       // #e0947f
const vec3 OPEN_DARK = vec3(0.808, 0.490, 0.478);  // #ce7d7a
const vec3 OPEN_LIT = vec3(0.965, 0.753, 0.561);   // #f6c08f
const vec3 OPEN_GLINT = vec3(1.0, 0.886, 0.659);   // #ffe2a8
const vec3 CHAN = vec3(0.757, 0.463, 0.502);       // #c17680
const vec3 CHAN_DEEP = vec3(0.678, 0.400, 0.471);  // #ad6678
const vec3 CHAN_LIT = vec3(0.808, 0.529, 0.537);   // #ce8789
const vec3 CHAN_CREST = vec3(0.925, 0.663, 0.588); // #eca996
const vec3 CHAN_GLINT = vec3(0.976, 0.824, 0.639); // #f9d2a3
// the shallows: lighter, warmer water over the sand, as the original (the user: the teal was a sudden blue border)
const vec3 SHAL_DEEP = vec3(0.871, 0.596, 0.529);  // #de9887
const vec3 SHAL = vec3(0.914, 0.659, 0.561);       // #e9a88f
const vec3 SHAL_LIT = vec3(0.953, 0.737, 0.604);   // #f3bc9a
const vec3 SHAL_PALE = vec3(0.984, 0.831, 0.682);  // #fbd4ae

float hash(vec2 p) { return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453); }
float noise(vec2 p) {
	vec2 i = floor(p), f = fract(p);
	f = f * f * (3.0 - 2.0 * f);
	return mix(mix(hash(i), hash(i + vec2(1, 0)), f.x), mix(hash(i + vec2(0, 1)), hash(i + vec2(1, 1)), f.x), f.y);
}
float fbm(vec2 p) { return noise(p) * 0.6 + noise(p * 2.1 + 7.3) * 0.3 + noise(p * 4.3 + 1.7) * 0.1; }
// 1 past th, 0 before, a checkerboard in a thin band between (crisp pixel art steps)
float over(float v, float th, float band, vec2 c) {
	if (v > th + band) return 1.0;
	if (v < th - band) return 0.0;
	return mod(c.x + c.y, 2.0);
}
// a kind's square at this art px: one of its three variants, picked per square
vec3 tile(sampler2D t, vec2 cell) {
	vec2 s = floor(cell / sq);
	float v = floor(hash(s * 1.37 + 0.71) * 3.0);
	vec2 in_sq = mod(cell, sq) + 0.5;
	return texture(t, vec2((v * sq + in_sq.x) / (sq * 3.0), in_sq.y / sq)).rgb;
}
// the sunset, top to bottom, eight steps (a checkerboard between), half strength
vec3 sky(vec2 cell, float rows) {
	float y = cell.y / rows * 8.0;
	float st = floor(y);
	if (fract(y) > 0.9 && mod(cell.x + cell.y, 2.0) < 1.0) st += 1.0;
	float t = clamp(st / 7.0, 0.0, 1.0);
	return (mix(sky_top.rgb, sky_bottom.rgb, t) - mix(sky_top.rgb, sky_bottom.rgb, 0.5)) * 0.4;
}
// the sandy bottom seen through the water (the user, 2026-10-28): the designer's sand, wobbling a little as
// through moving water; its lighter ripples one step lighter, its darker ones one step darker, `amount` by
// depth. Under every other layer and never over them: the caller draws it first
vec3 bottom(vec3 c, vec2 cell, float t, float amount) {
	vec2 wob = vec2(floor(sin(t * 0.9 + cell.y * 0.07) * 1.5 + 0.5), floor(cos(t * 0.7 + cell.x * 0.05) + 0.5));
	vec3 s = tile(sand_tex, cell + wob);
	vec3 dv = s - vec3(0.992, 0.847, 0.482);                      // (against the sand's base, #fdd87b)
	float v = dot(dv, vec3(0.3, 0.5, 0.2)) * 3.0 + dv.b * 1.2;     // its ripples (cooler: lighter here) and damp patches (darker)
	return c + vec3(1.0, 0.9, 0.8) * clamp(v, -0.4, 0.15) * 0.5 * amount;    // (light and shade only, in the water's own hue; the user: a bit more)
}
// short wave crests that rise, run a little with the wind and sink again: 1 its lit top, 2 its shade below
float crest(vec2 cell, float t, vec2 size, float rate, float seed) {
	vec2 p = cell + vec2(floor(t * 2.0), 0.0);
	vec2 g = floor(p / size);
	vec2 q = p - g * size;
	float h = hash(g + seed);
	vec2 at = vec2(2.0 + floor(h * (size.x - 12.0)), 1.0 + floor(fract(h * 7.13) * (size.y - 3.0)));
	float len = 3.0 + floor(fract(h * 3.7) * 5.0);
	float life = sin(t * rate + h * 6.283);
	float grow = life > 0.25 ? floor((life - 0.25) / 0.75 * len) + 1.0 : 0.0;
	vec2 o = q - at;
	if (has_crest > 0.5) {                        // the designer's frames: their shape, the water's colours (lit / shade)
		if (life <= 0.25 || o.x < 0.0 || o.y < 0.0 || o.x >= crest_size.x || o.y >= crest_size.y) return 0.0;
		float fr = min(floor((life - 0.25) / 0.75 * 4.0), 3.0);
		vec4 px = texture(crest_tex, vec2((fr * crest_size.x + o.x + 0.5) / (crest_size.x * 4.0), (o.y + 0.5) / crest_size.y));
		if (px.a < 0.5) return 0.0;
		return dot(px.rgb, vec3(0.3, 0.5, 0.2)) > 0.7 ? 1.0 : 2.0;
	}
	if (o.y == 0.0 && o.x >= 0.0 && o.x < grow) return 1.0;
	if (o.y == 1.0 && o.x >= 1.0 && o.x < grow + 1.0) return 2.0;
	return 0.0;
}
// the designer's glint at this art px, its colours as drawn (alpha 0: none)
vec4 glint_px(vec2 cell, float t, float chance, float seed) {
	vec2 g = floor(cell / 9.0);
	vec2 q = cell - g * 9.0;
	float h = hash(g + seed);
	if (h > chance) return vec4(0.0);
	vec2 at = floor(vec2(fract(h * 13.7), fract(h * 7.9)) * (9.0 - glint_size.x));
	float ph = fract(t * 0.45 + fract(h * 31.0));
	if (ph >= 0.32) return vec4(0.0);
	vec2 o = q - at;
	if (o.x < 0.0 || o.y < 0.0 || o.x >= glint_size.x || o.y >= glint_size.y) return vec4(0.0);
	float fr = floor(ph / 0.08);
	return texture(glint_tex, vec2((fr * glint_size.x + o.x + 0.5) / (glint_size.x * 4.0), (o.y + 0.5) / glint_size.y));
}
// a sun glint twinkling: 1 its glow, 2 its bright heart (a dot, then a little cross, then a dot)
float glint(vec2 cell, float t, float chance, float seed) {
	vec2 g = floor(cell / 9.0);
	vec2 q = cell - g * 9.0;
	float h = hash(g + seed);
	if (h > chance) return 0.0;
	vec2 at = floor(vec2(fract(h * 13.7), fract(h * 7.9)) * 7.0) + 1.0;
	float ph = fract(t * 0.45 + fract(h * 31.0));
	vec2 o = q - at;
	float m = abs(o.x) + abs(o.y);
	if (ph < 0.08) return m == 0.0 ? 1.0 : 0.0;
	if (ph < 0.18) return m == 0.0 ? 2.0 : (m == 1.0 ? 1.0 : 0.0);
	if (ph < 0.24) return m == 0.0 ? 1.0 : 0.0;
	return 0.0;
}

void fragment() {
	vec2 cell = floor(UV * board_size * k);          // this art px
	vec2 at = (cell + 0.5) / (board_size * k);
	if (texture(keep_tex, at).r > 0.5) {
		COLOR = texture(TEXTURE, at);
	} else {
		float t = TIME;
		float rows = board_size.y * k;
		// art px to the centre line, softened: the average round a little disc, so the bands' corners on the
		// inside of a turn come out round (the user: "too sharp"); straight banks stay as they are
		vec2 bp = 1.0 / board_size;
		float d = 0.0;
		for (int i = 0; i < 12; i++) {
			float a = float(i) * 0.5236;
			d += texture(dist_tex, at + vec2(cos(a), sin(a)) * soften * bp).r;
		}
		d = (d / 12.0 * 0.75 + texture(dist_tex, at).r * 0.25) * k;
		float wob = (noise(cell / 26.0) - 0.5) * 3.0;
		float bank = hw + shore + wob;
		vec2 sea_at = ((cell + 0.5) / k / sea_cell) / sea_size;
		float sea = texture(sea_tex, sea_at).r / art_px + (noise(cell / 18.0 + 13.0) - 0.5) * 4.0;   // art px into the water
		if (d < bank + bank_min) sea = min(sea, -2.0);                // (the bank: always sand)
		bool check = mod(cell.x + cell.y, 2.0) < 1.0;
		// the swell: big slow bands of lighter and darker water drifting with the wind
		float swell = fbm(cell / vec2(70.0, 34.0) + vec2(t * 0.025, t * 0.01));
		// the sun's road across the water, from the top left: more glints along it
		float road = 1.0 - clamp(abs((cell.x - cell.y * 0.6) / (board_size.x * k) - 0.32) * 5.0, 0.0, 1.0);
		vec3 c;
		if (d <= hw) {                                               // the channel: deep plum, darker in its middle
			c = CHAN;
			c = bottom(c, cell, t, 0.4 + 0.35 * clamp(d / hw - 0.5, 0.0, 1.0));    // (faintest in the deep lane's middle)
			c = mix(c, CHAN_DEEP, over(1.0 - d / hw, 0.55, 0.03, cell));
			c = mix(c, CHAN_LIT, over(swell, 0.6, 0.02, cell));
			float cr = crest(cell, t, vec2(26.0, 11.0), 0.9, 1.0);
			if (cr == 1.0) c = CHAN_CREST; else if (cr == 2.0) c = CHAN_DEEP;
			if (has_glint > 0.5) { vec4 gp = glint_px(cell, t, 0.05 + 0.25 * road, 4.0); if (gp.a > 0.5) c = gp.rgb; }
			else { float gl = glint(cell, t, 0.05 + 0.25 * road, 4.0); if (gl == 2.0) c = CHAN_GLINT; else if (gl == 1.0) c = CHAN_CREST; }
			c += sky(cell, rows);
		} else if (d < bank) {                                       // the shallows: teal, paler toward the sand
			float into = (d - hw) / (bank - hw);
			c = SHAL_DEEP;
			c = mix(c, SHAL, over(into, 0.35, 0.04, cell));
			c = mix(c, SHAL_LIT, over(into, 0.7, 0.04, cell));
			c = bottom(c, cell, t, 0.8 + 0.4 * into);                  // (clearest where it's shallowest)
			// the light rippling on the sandy bottom
			float v = abs(sin(fbm(cell / 13.0 + vec2(t * 0.12, -t * 0.07)) * 14.0));
			if (v < 0.09) c = mix(SHAL_LIT, SHAL_PALE, step(0.6, into));
			float f = d - hw;                                        // the channel fading into the shallows
			if (f < 1.0) c = fade0.rgb;
			else if (f < 2.0) c = check ? fade1.rgb : fade0.rgb;
			else if (f < 3.0) c = check ? fade2.rgb : fade1.rgb;
			else if (f < 4.0 && check) c = fade2.rgb;
			// the foam breaking on the sand, washing up and back
			float scallop = noise(cell / 4.0 + vec2(t * 0.4, 0.0)) * 2.0 + noise(cell / 1.7 + 7.0);
			float swash = (sin(t * 1.1 + noise(cell / 40.0) * 6.283) * 0.5 + 0.5) * 2.5;
			float to_sand = bank - d;
			if (to_sand < 1.0 + scallop * 0.7 + swash) c = foam.rgb;
			else if (to_sand < 2.0 + scallop + swash) c = foam_fringe.rgb;
			else if (abs(to_sand - (4.5 + swash * 1.6)) < 0.6 && noise(cell / 3.0 + t * 0.2) > 0.55) c = foam_fringe.rgb;   // (a line of foam behind it)
		} else if (sea <= 0.0) {                                     // the sand: the bank, and the narrow gaps filled
			if (d < bank + 2.0 + noise(cell / 3.0) * 1.5 || sea > -2.0) c = wet.rgb;
			else c = tile(sand_tex, cell);
		} else {                                                     // the open lagoon
			c = OPEN;
			c = bottom(c, cell, t, 0.6);
			c = mix(c, OPEN_DARK, over(1.0 - swell, 0.62, 0.02, cell));
			float cr = crest(cell, t, vec2(22.0, 9.0), 1.1, 2.0);
			if (cr == 1.0) c = OPEN_LIT; else if (cr == 2.0) c = OPEN_DARK;
			if (has_glint > 0.5) { vec4 gp = glint_px(cell, t, 0.04 + 0.5 * road, 3.0); if (gp.a > 0.5) c = gp.rgb; }
			else { float gl = glint(cell, t, 0.04 + 0.5 * road, 3.0); if (gl == 2.0) c = OPEN_GLINT; else if (gl == 1.0) c = OPEN_LIT; }
			if (sea < 1.0 + sin(t * 1.1 + cell.x * 0.05) || (sea < 2.5 && check)) c = foam_fringe.rgb;   // (foam lapping the beach)
			c += sky(cell, rows);
		}
		COLOR = vec4(c, 1.0);
	}
}
"""

## The sand's decor (the user, 2026-10-28: starfish etc. like the original): pebbles, starfish and shells
## along the banks and over the sand of the filled gaps, seagrass in the shallows by the sand; one image over the board at
## art px. Each kind a PNG (round 1: the original ones drawn at its size, until the designer's)
const DECOR := ["pebble", "starfish", "shell", "coconut", "seaweed", "urchin", "pebbles", "tracks"]   # (the crabs are alive: rc_racer's BeachCrabs)
const DECOR_CHANCE := [0.12, 0.07, 0.09, 0.03, 0.06, 0.04, 0.05, 0.02]   # per spot along a bank (the user took out the driftwood,
                                                       # beach grass, sandcastle and bucket: they didn't read well)
const INLAND_DECOR := 1.0 / 4100.0              # per art px² of the filled gaps' sand (the user: less, better spread; then 10% more)
const DECOR_DENSITY := 0.66                      # all the bank decor's chances scaled by this (was 1, then 0.6)
const SAME_APART := 70.0                         # the same kind never nearer itself than this (art px: the user, stars bunched up)
const DECOR_GAP := 6                             # px clear round every piece
const SEAGRASS_CHANCE := 0.3

## The small decor's outline in its own colour, darker (the user, 2026-10-28: not near-black): each dark edge
## pixel takes the colour of the fill next to it, darkened
const SOFT_OUTLINE := ["starfish", "shell", "pebble", "seagrass", "crab", "coconut", "seaweed", "urchin"]
static func _soft_outline(im: Image) -> void:
	var w := im.get_width()
	var h := im.get_height()
	var src := im.duplicate() as Image
	for y in h:
		for x in w:
			var c := src.get_pixel(x, y)
			if c.a < 0.5 or c.get_luminance() > 0.42:
				continue
			var best := Color(0, 0, 0, 0)
			for o in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1), Vector2i(1, 1), Vector2i(-1, -1), Vector2i(1, -1), Vector2i(-1, 1)]:
				var q: Vector2i = Vector2i(x, y) + o
				if q.x < 0 or q.y < 0 or q.x >= w or q.y >= h:
					continue
				var n := src.get_pixel(q.x, q.y)
				if n.a > 0.5 and n.get_luminance() > best.get_luminance():
					best = n
			if best.a > 0.0:
				im.set_pixel(x, y, Color(best.darkened(0.42), 1.0))

## One of a kind's variants, the small ones more often (the user, 2026-10-28: the big ones felt too big): by
## 1 / its area; none past DECOR_MAX px
const DECOR_MAX := 16
static func _pick_small(variants: Array, rng: RandomNumberGenerator) -> Image:
	var ok := variants.filter(func(im): return maxi(im.get_width(), im.get_height()) <= DECOR_MAX)
	if ok.is_empty():
		ok = variants
	var total := 0.0
	for im in ok:
		total += 1.0 / float(im.get_width() * im.get_height())
	var roll := rng.randf() * total
	for im in ok:
		roll -= 1.0 / float(im.get_width() * im.get_height())
		if roll <= 0.0:
			return im
	return ok[0]

static func _decor_tex(name: String) -> Image:
	var path := DIR + name + ".png"
	if not ResourceLoader.exists(path):
		return null
	var im := (load(path) as Texture2D).get_image()
	if im.is_compressed():
		im.decompress()
	im.convert(Image.FORMAT_RGBA8)
	if SOFT_OUTLINE.any(func(k): return name.begins_with(k)):
		_soft_outline(im)
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
	var placed: Array = []                       # [kind, where] of every piece put so far
	var total_chance := 0.0
	for ch in DECOR_CHANCE:
		total_chance += ch
	var put := func(n: String, p: Vector2) -> void:
		if not kinds.has(n):
			return
		var im: Image = _pick_small(kinds[n], rng)
		var r := Rect2i(Vector2i(p.round()) - im.get_size() / 2, im.get_size())
		var b := Vector2i(p / k)
		if r.position.x < rc.EDGE * k or r.position.y < rc.EDGE * k or r.end.x > w - rc.EDGE * k or r.end.y > h - rc.EDGE * k:
			return
		if rc._keep[b.y * rc._bw + b.x] != 0:
			return                               # (not on an island, a sandbar, the frame)
		for q in taken:
			if q.grow(DECOR_GAP).intersects(r):
				return                           # (never on, or crowding, other decor)
		for sp in placed:
			if sp[0] == n and (sp[1] as Vector2).distance_to(p) < SAME_APART:
				return                           # (the same kind kept apart)
		placed.append([n, p])
		taken.append(r)
		out.blend_rect(im, Rect2i(Vector2i.ZERO, im.get_size()), r.position)
	var pick := func() -> String:
		var roll := rng.randf() * total_chance           # (all the kinds: it used to weigh only the first three)
		for i in DECOR.size():
			roll -= DECOR_CHANCE[i]
			if roll <= 0.0:
				return DECOR[i]
		return DECOR[0]
	if ResourceLoader.exists(RcTiles.DIR + "frame_top.png"):
		RcTiles._frame(out, w, h)                    # (the Garden's wooden frame: the same 20 px border, the user)
	_start_line(out, rc)
	# the islands first (the designer's, round 1b), on the spots rc_racer chose (_sandbars), with their palms
	var isles: Array[Rect2i] = []
	for sb in rc._sandbars:
		var before := taken.size()
		_island_at(out, rc, sb[0] * k, sb[1], rng, taken)
		if taken.size() > before and float(sb[1]) > 0.9:
			isles.append(taken[before])
	_rocks(out, rc, rng, taken, isles)              # (after the islands: never under one, the user)
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
			if roll < total_chance * DECOR_DENSITY:
				put.call(pick.call(), p)
			if rng.randf() < SEAGRASS_CHANCE:         # seagrass in the shallows, by the sand
				var g: Vector2 = c0 + n0 * sd * (bank - rng.randf_range(5.0, 12.0))
				if absf(dist_at.call(g) - (g - c0).length()) < 4.0:
					put.call("seagrass", g)
	# over the filled gaps' sand
	_sand_bits(out, rc, rng, bank)
	var spots := PackedInt32Array()               # (the sand of the filled gaps, away from its edges)
	for i in rc._bw * rc._bh:
		var ci: int = rc._sea_cell(Vector2i(i % rc._bw, i / rc._bw))
		if ci >= 0 and rc._sea[ci] < -24.0 and rc._dist[i] * k > bank + 30.0:
			spots.append(i)
	for t in int(spots.size() * k * k * INLAND_DECOR):
		var i: int = spots[rng.randi_range(0, spots.size() - 1)]
		put.call(pick.call(), Vector2(i % rc._bw, i / rc._bw) * k + Vector2(rng.randf_range(0, k), rng.randf_range(0, k)))
	return out

## The designer's islands and palms (round 1b): the game draws round each its shallows (teal, foam at the
## beach) and its shadow on the water, and puts palms on the bigger ones (rc_racer's islands: their size `sc`)
const ISLANDS := ["island_a", "island_b", "island_c", "island_d"]
const PALMS := ["palm_a", "palm_b"]
const ISLE_RING := 7                            # its shallows, art px round it
const RING := [Color8(0xff, 0xf6, 0xea), Color8(0xfc, 0xe2, 0xca), Color8(0xf3, 0xbc, 0x9a), Color8(0xe9, 0xa8, 0x8f)]
const SHADOW := Color(0.16, 0.06, 0.2, 0.3)
const SHADOW_AT := Vector2i(5, 4)
static var _rings := {}                         # island name -> its shallows ring image (made once)

static func has_islands() -> bool:
	return ISLANDS.any(func(n): return ResourceLoader.exists(DIR + n + ".png"))

static func _shadow_of(im: Image) -> Image:
	var sh := Image.create(im.get_width(), im.get_height(), false, Image.FORMAT_RGBA8)
	for y in im.get_height():
		for x in im.get_width():
			if im.get_pixel(x, y).a > 0.5:
				sh.set_pixel(x, y, SHADOW)
	return sh

static func _ring_of(rc, name: String, im: Image) -> Image:
	if _rings.has(name):
		return _rings[name]
	var r := ISLE_RING
	var w := im.get_width() + 2 * r
	var h := im.get_height() + 2 * r
	var src := PackedByteArray()
	src.resize(w * h)
	for y in im.get_height():
		for x in im.get_width():
			if im.get_pixel(x, y).a > 0.5:
				src[(y + r) * w + x + r] = 1
	var d: PackedFloat32Array = rc._chamfer(src, w, h)
	var ring := Image.create(w, h, false, Image.FORMAT_RGBA8)
	for y in h:
		for x in w:
			var v := d[y * w + x]
			if v <= 0.0 or v > r:
				continue
			var c: Color
			if v <= 1.5:
				c = RING[0]
			elif v <= 2.5 or (v <= 3.5 and (x + y) % 2 == 0):
				c = RING[1]
			elif v <= r - 1.0 or (x + y) % 2 == 0:
				c = RING[2] if (x * 3 + y * 5) % 7 != 0 else RING[3]
			else:
				continue
			ring.set_pixel(x, y, c)
	_rings[name] = ring
	return ring

static func _island_at(out: Image, rc, at: Vector2, sc: float, rng: RandomNumberGenerator, taken: Array[Rect2i]) -> void:
	var best := ""
	var best_d := INF
	for n in ISLANDS:                           # (the one nearest its size: rc_racer's islands are 120 x sc px wide)
		var tex := _decor_tex(n)
		if tex and absf(tex.get_width() - 120.0 * sc) < best_d:
			best_d = absf(tex.get_width() - 120.0 * sc)
			best = n
	if best == "":
		return
	var im := _decor_tex(best)
	var pos := Vector2i(at.round()) - im.get_size() / 2
	var ring := _ring_of(rc, best, im)
	out.blend_rect(ring, Rect2i(Vector2i.ZERO, ring.get_size()), pos - Vector2i(ISLE_RING, ISLE_RING))
	var sh := _shadow_of(im)
	out.blend_rect(sh, Rect2i(Vector2i.ZERO, sh.get_size()), pos + SHADOW_AT)
	out.blend_rect(im, Rect2i(Vector2i.ZERO, im.get_size()), pos)
	taken.append(Rect2i(pos, im.get_size()).grow(ISLE_RING))
	var palms: Array[Image] = []
	for n in PALMS:
		var p := _decor_tex(n)
		if p:
			palms.append(p)
	if palms.is_empty():
		return
	var count := (2 if sc > 1.05 else 1) if sc > 0.85 else 0
	for i in count:
		var palm: Image = palms[rng.randi_range(0, palms.size() - 1)]
		var foot := Vector2i(at.round()) + Vector2i(rng.randi_range(-im.get_width() / 5, im.get_width() / 5), -2 + i * 6)
		var pp := foot - Vector2i(palm.get_width() / 2, palm.get_height())
		var psh := _shadow_of(palm)
		out.blend_rect(psh, Rect2i(Vector2i.ZERO, psh.get_size()), pp + Vector2i(9, 6))
		out.blend_rect(palm, Rect2i(Vector2i.ZERO, palm.get_size()), pp)

## The start line, floating (the user, 2026-10-28): a checkered pontoon across the channel at the start, its
## shadow on the water, and a checkered flag on a post at each end in the shallows. Drawn by the game until
## the designer's (round 2)
const START_HALF := 4                           # the pontoon's half thickness, art px
const START_INK := Color8(0x28, 0x1e, 0x28)
const START_LIGHT := Color8(0xff, 0xf6, 0xea)
const START_DARK := Color8(0x3a, 0x2c, 0x3a)
const POST := Color8(0x8a, 0x5a, 0x3c)

static func _start_line(out: Image, rc) -> void:
	var at: Vector2 = rc.centre[0] / ART_PX
	var dir: Vector2 = (rc.centre[2] - rc.centre[0]).normalized()
	var nrm := Vector2(-dir.y, dir.x)
	var hw: float = rc.half_w / ART_PX
	var reach := int(hw + 16.0)
	var shadow := Color(0.16, 0.06, 0.2, 0.3)
	for pass_i in 2:                            # its shadow first, then the pontoon
		for y in range(int(at.y) - reach, int(at.y) + reach + 1):
			for x in range(int(at.x) - reach, int(at.x) + reach + 1):
				if x < 0 or y < 0 or x >= out.get_width() or y >= out.get_height():
					continue
				var o := Vector2(x + 0.5, y + 0.5) - at - (Vector2(3, 4) if pass_i == 0 else Vector2.ZERO)
				var u := o.dot(dir)
				var v := o.dot(nrm)
				if absf(u) > START_HALF + 1 or absf(v) > hw - 2.0:
					continue
				if pass_i == 0:
					out.set_pixel(x, y, out.get_pixel(x, y).blend(shadow))
					continue
				var c: Color
				if absf(u) > START_HALF or absf(v) > hw - 3.0:
					c = START_INK
				else:
					var check := (int(floor((v + 400.0) / 4.0)) + int(floor((u + 40.0) / 4.0))) % 2 == 0
					c = START_LIGHT if check else START_DARK
					if u < -START_HALF + 1.0:
						c = c.lightened(0.15)          # (its lit edge, toward the top left)
				out.set_pixel(x, y, c)
	# (its flags: the stand's own waving flags, rc_racer's FinishFlags, the user)


## The designer's buoys (round 2), if drawn: 5 slices per colour, 14x14 px each, the same stack and behaviour
## as today's (rc_racer's FloatingBuoys); {} until they're in
static func buoy_slices(look: String) -> Dictionary:
	if not on(look):
		return {}
	var out := {}
	for red in [true, false]:
		var arr: Array[Texture2D] = []
		for k in 5:
			var im := _decor_tex("buoy_%s_%d" % ["red" if red else "yellow", k])
			if im == null:
				return {}
			arr.append(ImageTexture.create_from_image(im))
		out[red] = arr
	return out

## Tiny bits on the sand between the bigger decor (the user, 2026-10-28: "smaller decor, no clear shape, a
## similar colour, different sizes"): little clumps of 1 to 5 px in the sand's and shells' colours
const BITS := [Color8(0xed, 0xd8, 0x90), Color8(0xea, 0xaa, 0x6a), Color8(0xfc, 0xc9, 0x6e), Color8(0xff, 0xf6, 0xea),
	Color8(0xe0, 0x94, 0x7f), Color8(0xc8, 0x9a, 0x70)]
const BITS_PER_PX := 1.0 / 260.0               # per art px² of sand

static func _sand_bits(out: Image, rc, rng: RandomNumberGenerator, bank: float) -> void:
	var k := int(rc.PX / ART_PX)
	var w := out.get_width()
	var h := out.get_height()
	var tries := int(w * h * BITS_PER_PX)
	for i in tries:
		var p := Vector2i(rng.randi_range(rc.EDGE * k + 4, w - rc.EDGE * k - 5), rng.randi_range(rc.EDGE * k + 4, h - rc.EDGE * k - 5))
		var b := p / k
		var d: float = rc._dist[b.y * rc._bw + b.x] * k
		var ci: int = rc._sea_cell(b)
		var on_bank := d > bank + 4.0 and d < bank + 16.0
		var on_fill: bool = ci >= 0 and rc._sea[ci] < -16.0 and d > bank + 4.0
		if not (on_bank or on_fill) or rc._keep[b.y * rc._bw + b.x] != 0 or out.get_pixel(p.x, p.y).a > 0.0:
			continue
		var col: Color = BITS[rng.randi_range(0, BITS.size() - 1)]
		var n: int = [1, 1, 2, 2, 3, 4, 5][rng.randi_range(0, 6)]   # (mostly tiny, now and then a little clump)
		var q := p
		for j in n:
			if out.get_pixel(q.x, q.y).a == 0.0:
				out.set_pixel(q.x, q.y, col)
			var step: Vector2i = [Vector2i(1, 0), Vector2i(0, 1), Vector2i(-1, 0), Vector2i(1, 1)][rng.randi_range(0, 3)]
			q += step

## The designer's pier pieces (round 2) as textures to draw (null: not drawn yet, rc_racer draws its own)
static var _pier := {}
static func pier_tex(name: String) -> Texture2D:
	if not _pier.has(name):
		var im := _decor_tex(name)
		_pier[name] = ImageTexture.create_from_image(im) if im else null
	return _pier[name]

## The Garden's stand pieces for the Lagoon (the user, 2026-10-28: the canopy's green to a colour that fits the
## Lagoon): its greens turned coral, their light and shade kept; the cream stripes, the wood and the rest as drawn
const CANOPY_HUE := 0.03                         # pale peach-pink (the user picked it of three; plain red came out maroon)
static var _stands := {}
static func stand_tex(name: String) -> Texture2D:
	if not _stands.has(name):
		var im := RcTiles.img(name)
		if im == null:
			_stands[name] = null
			return null
		im = im.duplicate()
		for y in im.get_height():
			for x in im.get_width():
				var c := im.get_pixel(x, y)
				if c.a > 0.0 and c.s > 0.25 and c.h > 0.2 and c.h < 0.5:
					im.set_pixel(x, y, Color.from_hsv(CANOPY_HUE, minf(1.0, c.s * 0.6), minf(1.0, c.v * 1.5), c.a))
		_stands[name] = ImageTexture.create_from_image(im)
	return _stands[name]

## The designer's rocks (round 2): a few in the open water, away from the course, and some at the islands'
## edges, each with its foam ring and shadow like the islands (the user: "rocks in the water")
const ROCKS := ["rock_a", "rock_b"]
const ROCKS_PER_SQ := 0.08                       # per course square of the board

static func _rocks(out: Image, rc, rng: RandomNumberGenerator, taken: Array[Rect2i], isles: Array[Rect2i]) -> void:
	var kinds: Array[String] = []
	for n in ROCKS:
		if _decor_tex(n):
			kinds.append(n)
	if kinds.is_empty():
		return
	var k := int(rc.PX / ART_PX)
	var w := out.get_width()
	var h := out.get_height()
	var want := int(float(w * h) / float(SQ * SQ) * ROCKS_PER_SQ) + 2
	var spots: Array[Vector2] = []
	for r in isles:                                # (by the bigger islands: just outside, in the water at its front or side)
		var a := rng.randf_range(0.15, PI - 0.15)
		var c := Vector2(r.get_center())
		spots.append(c + Vector2(cos(a) * (r.size.x / 2.0 + 9.0), sin(a) * (r.size.y / 2.0 + 7.0)))
	for tries in want * 20:                        # (in the open water, where it's wide)
		if spots.size() >= want + rc._sandbars.size():
			break
		var p := Vector2(rng.randi_range(rc.EDGE * k + 20, w - rc.EDGE * k - 20), rng.randi_range(rc.EDGE * k + 20, h - rc.EDGE * k - 20))
		var ci: int = rc._sea_cell(Vector2i(p / k))
		if ci >= 0 and rc._sea[ci] > 10.0 and rc._clear[ci] > 90.0:
			spots.append(p)
	for p in spots:
		var name: String = kinds[rng.randi_range(0, kinds.size() - 1)]
		var im := _decor_tex(name)
		var pos := Vector2i(p.round()) - im.get_size() / 2
		var r := Rect2i(pos, im.get_size()).grow(ISLE_RING)
		if r.position.x < rc.EDGE * k or r.position.y < rc.EDGE * k or r.end.x > w - rc.EDGE * k or r.end.y > h - rc.EDGE * k:
			continue
		if taken.any(func(q): return q.intersects(r)):
			continue
		var ring := _ring_of(rc, name, im)
		out.blend_rect(ring, Rect2i(Vector2i.ZERO, ring.get_size()), pos - Vector2i(ISLE_RING, ISLE_RING))
		var sh := _shadow_of(im)
		out.blend_rect(sh, Rect2i(Vector2i.ZERO, sh.get_size()), pos + Vector2i(3, 2))
		out.blend_rect(im, Rect2i(Vector2i.ZERO, im.get_size()), pos)
		taken.append(r)
