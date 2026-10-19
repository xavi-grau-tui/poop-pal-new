extends Node
## 3D "wallpaper" effect on the pet screen: tilting the phone slides the sky and the clouds a
## little behind the gut (the gut, the cam and the pal stay put), so the gut seems to float in
## front of the background, like the iPhone's perspective wallpapers.
##
## Whatever angle you hold the phone at slowly becomes "neutral" (only the movement counts).
## Deeper layers move more. Desktop (no tilt sensor): the mouse position does it.
## The user (2026-10-19): more noticeable, like the toy games' 3D tilt: the layers slide 2-3x as
## far, each one enlarged round its middle by its slide so no edge shows (the sky's own size, the
## screen's, is kept in its "screen_rect" meta for the boot screen and the welcome card). Then (the
## user: the gut too): the gut, the cam and the pal (PetView, all together) slide the other way,
## FRONT px, so the front and the back pull apart. PetView is also slid by the menus' animations:
## while one plays it's left alone, then the shift goes back on top of where it ended.

const LAYERS := {                    # node under PetBackground -> how far it slides (px)
	"PinkBackground": 44.0,          # the sky: furthest away
	"CloudA": 30.0,                  # far clouds
	"CloudB": 18.0,                  # near clouds
}
const FRONT := 14.0                  # the gut, the cam and the pal: towards you
const GAIN := 2.6                    # tilt (in g) -> -1..1
const SETTLE := 0.5                  # how fast the neutral angle follows the phone (per second)
const SMOOTH := 8.0                  # follow speed of the layers
const INVERT := false                # flip if it moves the wrong way on the phone

var _bg: Node2D
var _home := {}                      # layer -> its scene position
var _neutral := Vector2.ZERO
var _has_neutral := false
var _offset := Vector2.ZERO
var qa_tilt := Vector2.ZERO          # (tools/qa depth=x,y on the pet screen: a pretend tilt)
var _view: Node2D                    # PetView
var _view_anim: AnimationPlayer
var _view_applied := Vector2.ZERO    # the shift on PetView now

func _ready() -> void:
	_bg = get_node_or_null("../PetBackground") as Node2D
	if not _bg:
		set_process(false)
		return
	_view = get_node_or_null("../PetView") as Node2D
	if _view:
		_view_anim = _view.get_node_or_null("AnimationPlayer") as AnimationPlayer
	for n in LAYERS:
		var layer := _bg.get_node_or_null(n) as Sprite2D
		if layer:
			_home[layer] = layer.position
			if not layer.has_meta("screen_rect"):
				var r := layer.get_rect()
				layer.set_meta("screen_rect", Rect2(layer.position + r.position * layer.scale, r.size * layer.scale))
			# enlarged by its slide on each side (and a little more), round its middle
			var w: float = r_size(layer).x
			layer.scale *= (w + LAYERS[n] * 2.0 + 8.0) / w

func r_size(s: Sprite2D) -> Vector2:
	return s.get_rect().size * s.scale

func _process(delta: float) -> void:
	var target := _input_tilt(delta) if qa_tilt == Vector2.ZERO else qa_tilt
	if INVERT:
		target = -target
	_offset = _offset.lerp(target, clampf(delta * SMOOTH, 0.0, 1.0))
	for layer in _home:
		if is_instance_valid(layer):
			# the background moves against the tilt, so it seems to sit behind the gut
			layer.position = _home[layer] - _offset * LAYERS[layer.name]
	if is_instance_valid(_view):
		if _view_anim and _view_anim.is_playing():
			_view_applied = Vector2.ZERO             # (the animation sets where it is)
		else:
			var want := (_offset * FRONT).round()
			_view.position += want - _view_applied
			_view_applied = want

## -1..1 on both axes
func _input_tilt(delta: float) -> Vector2:
	var g := Input.get_gravity()
	if g == Vector3.ZERO:
		g = Input.get_accelerometer()
	if g != Vector3.ZERO:
		var t := Vector2(g.x, -g.y) / 9.8
		if not _has_neutral:
			_neutral = t
			_has_neutral = true
		_neutral = _neutral.lerp(t, clampf(delta * SETTLE, 0.0, 1.0))
		var d := (t - _neutral) * GAIN
		return Vector2(clampf(d.x, -1.0, 1.0), clampf(d.y, -1.0, 1.0))
	if OS.has_feature("mobile"):
		return Vector2.ZERO
	# desktop: the mouse around the window's centre
	var vp := get_viewport()
	var size := vp.get_visible_rect().size
	var m := vp.get_mouse_position()
	var d2 := (m - size / 2.0) / (size / 2.0)
	return Vector2(clampf(d2.x, -1.0, 1.0), clampf(d2.y, -1.0, 1.0))
