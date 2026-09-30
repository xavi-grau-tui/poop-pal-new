extends Node2D
## Status aura for a drink boost: a soft pixel glow pulsing behind the pal, plus a small drip
## now and then. Add it as a child of the pal's sprite (it draws behind it and follows every
## squash, bounce and flush of the sprite).
##
##   var aura := BoostAura.new(); pal.add_child(aura); aura.setup("splash", body_rect)

class_name BoostAura

const COLORS := {
	"splash": [Color8(96, 176, 236), Color8(150, 210, 250)],    # glow, drips
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
		return
	_drip_timer -= delta
	if _drip_timer <= 0.0:
		_drip_timer = randf_range(0.8, 1.6)
		_drip()

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
