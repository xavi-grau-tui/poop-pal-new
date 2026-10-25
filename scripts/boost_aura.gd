extends Node2D
## Status aura for a drink boost: a soft pixel glow pulsing behind the pal, plus a small drip
## now and then. Add it as a child of the pal's sprite (it draws behind it and follows every
## squash, bounce and flush of the sprite).
##
##   var aura := BoostAura.new(); pal.add_child(aura); aura.setup("splash", body_rect)

class_name BoostAura

const COLORS := {
	"splash": [Color8(96, 176, 236), Color8(150, 210, 250)],    # glow, drips
	"fizz": [Color8(236, 120, 80), Color8(255, 196, 170)],
	"focus": [Color8(246, 204, 70), Color8(255, 238, 160)],
	"sturdy": [Color8(236, 232, 224), Color8(255, 255, 255)],
	"lucky": [Color8(250, 164, 70), Color8(255, 214, 150)],
}
const GLOW_W := 24
const GLOW_H := 18

var glow: Sprite2D
var _body := Rect2()
var _drip_timer := 0.0
var _color := Color.WHITE
var _drip_color := Color.WHITE

func setup(boost_id: String, body_rect: Rect2) -> void:
	var c: Array = COLORS.get(boost_id, [Color.WHITE, Color.WHITE])
	_color = c[0]
	_drip_color = c[1]
	_body = body_rect
	show_behind_parent = true
	if not glow:
		glow = Sprite2D.new()
		glow.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		glow.show_behind_parent = true
		add_child(glow)
	glow.texture = _glow_texture(_color)
	glow.visible = not _in_shrine()          # (the shrine has its plasma instead)
	glow.position = _body.get_center()
	var s := Vector2(_body.size.x * 1.3 / GLOW_W, _body.size.y * 1.45 / GLOW_H)
	glow.scale = s
	var t := glow.create_tween().set_loops()
	t.tween_property(glow, "modulate:a", 0.55, 0.8).set_trans(Tween.TRANS_SINE)
	t.parallel().tween_property(glow, "scale", s * 1.08, 0.8).set_trans(Tween.TRANS_SINE)
	t.tween_property(glow, "modulate:a", 1.0, 0.8).set_trans(Tween.TRANS_SINE)
	t.parallel().tween_property(glow, "scale", s, 0.8).set_trans(Tween.TRANS_SINE)

func _process(delta: float) -> void:
	if not visible or _body.size == Vector2.ZERO:
		_was_on = false
		return
	if _in_shrine():
		_plasma_step(delta)
		return
	elif plasma:
		plasma.hide()
		if glow:
			glow.show()
	_drip_timer -= delta
	if _drip_timer <= 0.0:
		_drip_timer = randf_range(0.8, 1.6)
		_drip()

func _in_shrine() -> bool:
	var pal := get_parent()
	return pal != null and pal.get_parent() != null and pal.get_parent().has_node("Shrine")

# ------------------------------------------------------------------ THE SHRINE'S PLASMA AURA
## In the shrine the boost burns round the spirit as one pixel-art flame (the user: a plasma aura,
## like a will-o'-wisp's, a bit see-through, in the boost's colour): it hugs the body, rises into
## tongues over its top that flicker, break off and drift away, sparks rising off it. Its frames
## are made here from the body's size (texels of the pal's picture, so it's pixel art at the pal's
## own scale): a flame field (the distance out from the body, allowed further the higher up)
## broken up by noise flowing upward (seamless: two layers crossfaded), in three tones (a deeper
## edge, the colour, a light core).
const PLASMA_FRAMES := 12
const PLASMA_FPS := 11.0
const PLASMA_RISE := 14.0             # its pixels the noise flows up over one loop
const PLASMA_PX := 2                  # its pixels, in the pal's texels (chunky, like the references)

var plasma: Sprite2D
var _plasma_frames: Array[Texture2D] = []
var _plasma_key := ""
var _plasma_t := 0.0
var _spark_t := 0.0
# (the user: it appeared too suddenly) when it comes on it catches from the spirit's base and climbs
# it, a bright edge leading, over a few quick frames, before it settles into its loop
const IGNITE_FRAMES := 10
const IGNITE_FPS := 15.0
var _ignite_frames: Array[Texture2D] = []
var _ignite_t := -1.0                 # (-1: done)
var _was_on := false

func _plasma_step(delta: float) -> void:
	var key := "%s|%s" % [_color.to_html(), str(_body)]
	if key != _plasma_key:
		_plasma_key = key
		_build_plasma()
	if glow:
		glow.hide()
	plasma.show()
	if not _was_on:
		_was_on = true
		_ignite_t = 0.0
		_plasma_t = 0.0
	if _ignite_t >= 0.0:
		var f := int(_ignite_t * IGNITE_FPS)
		_ignite_t += delta
		if f < IGNITE_FRAMES:
			plasma.texture = _ignite_frames[f]
			if f == IGNITE_FRAMES / 2:
				_spark()
			return
		_ignite_t = -1.0
	_plasma_t += delta
	plasma.texture = _plasma_frames[int(_plasma_t * PLASMA_FPS) % PLASMA_FRAMES]
	_spark_t -= delta
	if _spark_t <= 0.0:
		_spark_t = randf_range(0.12, 0.3)
		_spark()

func _build_plasma() -> void:
	var k := float(PLASMA_PX)
	var bs := _body.size / k                                       # (in its own pixels)
	var r := bs * 0.5
	var top := bs.y * 0.5                                          # (the user: not too high)
	var w := int(ceilf(bs.x + 12.0))
	var h := int(ceilf(bs.y + top + 8.0))
	var c := Vector2(w * 0.5, top + 5.0 + r.y)
	_plasma_frames.clear()
	for f in PLASMA_FRAMES:
		_plasma_frames.append(ImageTexture.create_from_image(_plasma_image(float(f) / PLASMA_FRAMES, w, h, c, r, top, -INF)))
	# the catching: the flame's front climbing from under the body to over its tongues' tips
	_ignite_frames.clear()
	for f in IGNITE_FRAMES:
		var g := float(f + 1) / IGNITE_FRAMES
		var front := lerpf(c.y + r.y + 4.0, -3.0, 1.0 - pow(1.0 - g, 1.5))
		_ignite_frames.append(ImageTexture.create_from_image(_plasma_image(float(f) / PLASMA_FRAMES, w, h, c, r, top, front)))
	if not plasma:
		plasma = Sprite2D.new()
		plasma.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		plasma.show_behind_parent = true
		add_child(plasma)
	plasma.centered = false
	plasma.scale = Vector2(k, k)
	plasma.position = (_body.get_center() - c * k).round()

## One frame of the flame (u: where in its loop); `front`: rows above it not caught yet (its edge
## ragged and bright), -INF for the whole flame
func _plasma_image(u: float, w: int, h: int, c: Vector2, r: Vector2, top: float, front: float) -> Image:
	var edge := Color(_color.r, _color.g, _color.b).darkened(0.18)
	var core := _drip_color.lerp(Color.WHITE, 0.25)
	# the tongues: where along the top (-1..1 of the half width), how tall (of `top`), their phase
	var tongues := [[-0.62, 0.55, 0.0], [-0.22, 0.95, 0.37], [0.2, 0.8, 0.71], [0.6, 0.6, 0.18]]
	var img := Image.create(w, h, false, Image.FORMAT_RGBA8)
	for y in h:
		for x in w:
			var p := Vector2(x + 0.5, y + 0.5)
			var fr := front + sin(x * 0.9 + u * 20.0) * 1.2 + sin(x * 0.37) * 1.5
			if p.y < fr:
				continue
			# the rim: the body's oval grown a little (more at the sides, less underneath)
			var q := (p - c) / (r + Vector2(3.6, 3.4 if p.y < c.y else 1.0))
			var d := (q.length() - 1.0) * minf(r.x, r.y)
			for tg in tongues:
				var tx: float = c.x + float(tg[0]) * r.x
				var base: float = c.y - r.y * sqrt(maxf(0.0, 1.0 - pow(float(tg[0]), 2.0))) - 1.0
				var ph: float = TAU * (u + float(tg[2]))
				var th: float = top * float(tg[1]) * (0.75 + 0.25 * sin(ph))
				var ty := (base - p.y) / th                          # 0 at its foot, 1 at its tip
				if ty > -0.2 and ty < 1.0:
					var sway := sin(ph * 2.0) * 1.3 * ty * ty
					var half := 4.4 * pow(1.0 - clampf(ty, 0.0, 1.0), 0.6) + 0.4
					d = _smin(d, absf(p.x - tx - sway) - half, 3.0)
				# a bit of it breaking off over the tip, rising and shrinking
				var bu := fmod(u * 2.0 + float(tg[2]), 1.0)
				var by := base - th - 1.0 - bu * 5.0
				var br := 1.9 * (1.0 - bu)
				if br > 0.3:
					d = minf(d, p.distance_to(Vector2(tx + sin(ph * 2.0) * 1.3, by)) - br)
			if d >= 0.0:
				continue
			var col: Color
			if d < -2.2:
				col = Color(core.r, core.g, core.b, 0.75)
			elif d < -1.0:
				col = Color(_color.r, _color.g, _color.b, 0.68)
			else:
				col = Color(edge.r, edge.g, edge.b, 0.6)
			if p.y < fr + 1.5 and d < -0.5:                  # (the catching edge, bright)
				col = Color(core.r, core.g, core.b, 0.9)
			img.set_pixel(x, y, col)
	return img

## The empty shrine's waiting spirit (hitodama: a little wandering flame of pale light, before the
## first offering gives it a shape; poop.gd shows it where the gut shows its EAT sign): a round
## body with one tongue rising off it, swaying, bits breaking off; the plasma aura's three tones
static func wisp_texture(col := Color8(150, 200, 238), light := Color8(226, 242, 255)) -> Texture2D:
	var w := 26
	var h := 46                                     # (room above for the bits breaking off: none cut)
	var frames := 10
	var edge := col.darkened(0.2)
	var core := light
	var anim := AnimatedTexture.new()
	anim.frames = frames
	anim.speed_scale = 1.0
	var c := Vector2(w * 0.5, h - 9.5)
	for f in frames:
		var u := float(f) / frames
		var ph := TAU * u
		var img := Image.create(w, h, false, Image.FORMAT_RGBA8)
		for y in h:
			for x in w:
				var p := Vector2(x + 0.5, y + 0.5)
				var d := p.distance_to(c) - 7.8
				var ty := (c.y - p.y) / (17.0 + 2.5 * sin(ph))
				if ty > 0.0 and ty < 1.0:                       # (from its middle up: its bottom stays round)
					var sway := sin(ph + ty * 2.4) * 2.2 * ty * ty
					var half := 6.8 * pow(1.0 - clampf(ty, 0.0, 1.0), 0.7) + 0.4
					d = _smin(d, absf(p.x - c.x - sway) - half, 3.0)
				var bu := fmod(u * 2.0, 1.0)
				var br := 1.6 * (1.0 - bu)
				if br > 0.3:
					d = minf(d, p.distance_to(Vector2(c.x + sin(ph * 2.0) * 2.0, c.y - 19.0 - bu * 6.0)) - br)
				if d >= 0.0:
					continue
				var colr: Color
				if d < -3.6:
					colr = Color(core.r, core.g, core.b, 0.95)
				elif d < -1.4:
					colr = Color(col.r, col.g, col.b, 0.85)
				else:
					colr = Color(edge.r, edge.g, edge.b, 0.75)
				img.set_pixel(x, y, colr)
		anim.set_frame_texture(f, ImageTexture.create_from_image(img))
		anim.set_frame_duration(f, 0.09)
	return anim

## Smooth minimum (a soft union of two shapes' distances)
static func _smin(a: float, b: float, k: float) -> float:
	var hh := clampf(0.5 + 0.5 * (b - a) / k, 0.0, 1.0)
	return lerpf(b, a, hh) - k * hh * (1.0 - hh)

## A spark off the flame's top, drifting up and out
func _spark() -> void:
	var d := ColorRect.new()
	d.color = _drip_color.lerp(Color.WHITE, 0.3)
	d.size = Vector2.ONE * PLASMA_PX
	d.show_behind_parent = true
	var x := _body.get_center().x + randf_range(-_body.size.x * 0.3, _body.size.x * 0.3)
	d.position = Vector2(roundf(x), roundf(_body.position.y - _body.size.y * randf_range(0.15, 0.4)))
	add_child(d)
	var t := d.create_tween()
	var dx := randf_range(-3.0, 3.0)
	t.tween_property(d, "position", d.position + Vector2(roundf(dx), -randf_range(6, 11)), randf_range(0.6, 0.9))
	t.parallel().tween_property(d, "modulate:a", 0.0, 0.8).set_delay(0.2)
	t.tween_callback(d.queue_free)

func _drip() -> void:
	var d := ColorRect.new()
	d.color = _drip_color
	d.size = Vector2(2, 3)                     # in the pal's texels (the sprite is scaled up)
	d.show_behind_parent = false
	var x := randf_range(_body.position.x + _body.size.x * 0.2, _body.end.x - _body.size.x * 0.2)
	d.position = Vector2(x, _body.position.y + _body.size.y * randf_range(0.2, 0.6))
	add_child(d)
	var t := d.create_tween()
	t.tween_property(d, "position:y", d.position.y + 10.0, 0.7).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_QUAD)
	t.parallel().tween_property(d, "modulate:a", 0.0, 0.7)
	t.tween_callback(d.queue_free)

## A soft oval with 3 stepped alpha levels (pixel-art glow)
static func _glow_texture(col: Color) -> Texture2D:
	var img := Image.create(GLOW_W, GLOW_H, false, Image.FORMAT_RGBA8)
	for y in GLOW_H:
		for x in GLOW_W:
			var dx := (x + 0.5 - GLOW_W / 2.0) / (GLOW_W / 2.0)
			var dy := (y + 0.5 - GLOW_H / 2.0) / (GLOW_H / 2.0)
			var r := sqrt(dx * dx + dy * dy)
			var a := 0.0
			# "ki" halo: brightest in a band around the body, fading outwards
			if r < 0.62:
				a = 0.3
			elif r < 0.82:
				a = 0.75
			elif r < 0.93:
				a = 0.45
			elif r < 1.0:
				a = 0.2
			if a > 0.0:
				img.set_pixel(x, y, Color(col.r, col.g, col.b, a))
	return ImageTexture.create_from_image(img)
