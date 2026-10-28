class_name RcAtmosphere
extends Node2D
## RC Prix Garden's air (a TRIAL behind the dev launcher's FX switch, the user 2026-10-28: "shadows and light
## beam effects, morning fog... with low effort"; then: shadows softer, light a bit more, bloomy): over
## everything, clouds' soft shadows drifting across, and the sun's warmth from the top left with a few beams, added
## as light (a glow); under the track, morning mist
## over the lawn on the first levels (the track covers it: never over the race). All on the art's pixel grid,
## crisp shapes with a thin checkerboard at their edges, so it stays pixel art.

const MIST_LEVELS := 3                # levels 1..3: a morning

const SHADE := """
shader_type canvas_item;
uniform vec2 size;                    // the mat, world px
uniform float px;                     // an art pixel, world px
uniform float t0;

float over(float v, float th, float band, vec2 p) {   // 1 past th, 0 before, a checkerboard in a thin band between
	if (v > th + band) return 1.0;
	if (v < th - band) return 0.0;
	return mod(p.x + p.y, 2.0);
}
float hash(vec2 p) { return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453); }
float noise(vec2 p) {
	vec2 i = floor(p), f = fract(p);
	f = f * f * (3.0 - 2.0 * f);
	return mix(mix(hash(i), hash(i + vec2(1, 0)), f.x), mix(hash(i + vec2(0, 1)), hash(i + vec2(1, 1)), f.x), f.y);
}
float fbm(vec2 p) { return noise(p) * 0.6 + noise(p * 2.1 + 7.3) * 0.3 + noise(p * 4.3 + 1.7) * 0.1; }

void fragment() {
	vec2 cell = floor(UV * size / px);            // this art pixel
	vec2 a = cell * px / size;                    // 0..1 over the mat, snapped
	vec2 w = cell * px;
	float t = TIME + t0;
	// clouds' shadows drifting with the wind, soft: three light steps in from their edges
	float c = fbm(w / 480.0 + vec2(t * 0.02, t * 0.008));
	float s = over(c, 0.49, 0.006, cell) + over(c, 0.53, 0.006, cell) + over(c, 0.57, 0.006, cell);
	// a little cool in the far bottom right
	float cool = over(length(a * vec2(1.0, size.y / size.x)), 1.0, 0.01, cell);
	COLOR = vec4(mix(vec3(0.3, 0.4, 0.8), vec3(0.06, 0.08, 0.2), step(0.5, s)), max(0.08 * s, 0.08 * cool));
}
"""

const LIGHT := """
shader_type canvas_item;
render_mode blend_add;                // (light added: it glows, a bloom, instead of tinting)
uniform vec2 size;                    // the mat, world px
uniform float px;                     // an art pixel, world px
uniform float t0;

float over(float v, float th, float band, vec2 p) {   // 1 past th, 0 before, a checkerboard in a thin band between
	if (v > th + band) return 1.0;
	if (v < th - band) return 0.0;
	return mod(p.x + p.y, 2.0);
}
float hash(vec2 p) { return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453); }
float noise(vec2 p) {
	vec2 i = floor(p), f = fract(p);
	f = f * f * (3.0 - 2.0 * f);
	return mix(mix(hash(i), hash(i + vec2(1, 0)), f.x), mix(hash(i + vec2(0, 1)), hash(i + vec2(1, 1)), f.x), f.y);
}
float fbm(vec2 p) { return noise(p) * 0.6 + noise(p * 2.1 + 7.3) * 0.3 + noise(p * 4.3 + 1.7) * 0.1; }

void fragment() {
	vec2 cell = floor(UV * size / px);
	vec2 a = cell * px / size;
	vec2 w = cell * px;
	float t = TIME + t0;
	// the sun's warmth from the top left, in two steps
	float r = length(a * vec2(1.0, size.y / size.x));
	vec3 glow = vec3(0.065, 0.047, 0.018) * (over(-r, -0.8, 0.01, cell) + over(-r, -0.45, 0.01, cell));
	// beams slanting down from the top left, slowly shimmering: a faint halo, the beam, its bright core
	float u = dot(w, normalize(vec2(1.0, -0.55))) / 200.0;
	float band = pow(max(0.0, sin(u * 3.1 + 0.6) * 0.5 + 0.5 + 0.12 * sin(t * 0.35 + u)), 4.0);
	band *= (1.0 - clamp(r / 1.1, 0.0, 1.0)) * (0.75 + 0.25 * sin(t * 0.5 + u * 1.7));
	glow += vec3(0.035, 0.032, 0.02) * over(band, 0.1, 0.02, cell);
	glow += vec3(0.075, 0.065, 0.04) * over(band, 0.22, 0.02, cell);
	glow += vec3(0.05, 0.047, 0.038) * over(band, 0.5, 0.02, cell);
	COLOR = vec4(glow, 1.0);
}
"""

const MIST := """
shader_type canvas_item;
uniform vec2 size;
uniform float px;
uniform float amount;

float over(float v, float th, float band, vec2 p) {   // 1 past th, 0 before, a checkerboard in a thin band between
	if (v > th + band) return 1.0;
	if (v < th - band) return 0.0;
	return mod(p.x + p.y, 2.0);
}
float hash(vec2 p) { return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453); }
float noise(vec2 p) {
	vec2 i = floor(p), f = fract(p);
	f = f * f * (3.0 - 2.0 * f);
	return mix(mix(hash(i), hash(i + vec2(1, 0)), f.x), mix(hash(i + vec2(0, 1)), hash(i + vec2(1, 1)), f.x), f.y);
}

void fragment() {
	vec2 cell = floor(UV * size / px);
	vec2 w = cell * px;
	float edge = min(min(w.x, size.x - w.x), min(w.y, size.y - w.y));
	float near_edge = 1.0 - smoothstep(60.0, 420.0, edge);          // thicker toward the mat's edges
	float m = noise(w / 300.0 + vec2(TIME * 0.02, 0.0)) * 0.65 + noise(w / 120.0 - vec2(TIME * 0.035, TIME * 0.01)) * 0.35;
	float fog = clamp((m - 0.3) * 1.8, 0.0, 1.0) * (0.5 + 0.5 * near_edge) * amount;
	float a = over(fog, 0.25, 0.015, cell) * 0.5 + over(fog, 0.55, 0.015, cell) * 0.5;   // two crisp steps
	COLOR = vec4(0.93, 0.96, 1.0, 0.62 * a);
}
"""

var _shade: ColorRect
var _light: ColorRect
var _mist: ColorRect

## Over the mat painted at `art_px` world px per art pixel: the shade and the light on top of `world`, the mist
## just above `board`
func start(world: Node2D, board: Node2D, size: Vector2, art_px: float, level: int) -> void:
	stop()
	var t0 := randf() * 100.0
	_shade = _layer(SHADE, size, art_px)
	_light = _layer(LIGHT, size, art_px)
	for n in [_shade, _light]:
		n.material.set_shader_parameter("t0", t0)
		world.add_child(n)
	if level <= MIST_LEVELS:
		_mist = _layer(MIST, size, art_px)
		_mist.material.set_shader_parameter("amount", 1.0 - 0.25 * (level - 1))
		world.add_child(_mist)
		world.move_child(_mist, board.get_index() + 1)

func stop() -> void:
	for n in [_shade, _light, _mist]:
		if n and is_instance_valid(n):
			n.queue_free()
	_shade = null
	_light = null
	_mist = null

func _layer(code: String, size: Vector2, art_px: float) -> ColorRect:
	var r := ColorRect.new()
	r.size = size
	r.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var sh := Shader.new()
	sh.code = code
	var m := ShaderMaterial.new()
	m.shader = sh
	m.set_shader_parameter("size", size)
	m.set_shader_parameter("px", art_px)
	r.material = m
	return r
