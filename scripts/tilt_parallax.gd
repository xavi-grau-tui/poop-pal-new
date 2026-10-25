extends Node
## 3D "wallpaper" effect on the pet screen: tilting the phone slides the sky and the clouds a
## little behind the gut (the gut, the cam and the pal stay put), so the gut seems to float in
## front of the background, like the iPhone's perspective wallpapers.
##
## Whatever angle you hold the phone at slowly becomes "neutral" (only the movement counts), lying
## down or held up in front of you.
## Deeper layers move more. Desktop (no tilt sensor): the mouse position does it.
## The user (2026-10-19): more noticeable, like the toy games' 3D tilt: the layers slide 2-3x as
## far, each one enlarged round its middle by its slide so no edge shows (the sky's own size, the
## screen's, is kept in its "screen_rect" meta for the boot screen and the welcome card). Then (the
## user: the gut too): the gut, the cam and the pal (PetView, all together) slide the other way,
## FRONT px, so the front and the back pull apart; the menus' slides too, each as one card (the user:
## the slide against the background, not its frame against its panel). PetView is also slid by the
## menus' animations:
## while one plays it's left alone, then the shift goes back on top of where it ended.

const LAYERS := {                    # node under PetBackground -> how far it slides (px)
	"PinkBackground": 44.0,          # the sky: furthest away
	"CloudA": 30.0,                  # far clouds
	"CloudB": 18.0,                  # near clouds
}
const FRONT := 14.0                  # the gut, the cam and the pal: towards you
const GAIN := 2.6                    # tilt (in g) -> -1..1
const SETTLE := 0.08                 # how fast the neutral angle follows the phone (per second; slow, so a held tilt stays)
const SMOOTH := 8.0                  # follow speed of the layers
const INVERT := false                # flip if it moves the wrong way on the phone

var _bg: Node2D
var _home := {}                      # layer -> its scene position
var _n0 := Vector3.ZERO              # the neutral pose (gravity's direction, slowly following the phone)
## A new way of holding the phone (upright -> lying down...): more than POSE_CHANGE from the neutral
## for POSE_HOLD seconds re-centres it quickly (the user: back to the front view), so only tilts
## within it keep the 3D turned
const POSE_CHANGE := 0.6              # radians (~35 degrees)
const POSE_HOLD := 1.2             # (the user: a bit longer before it re-centres)
const RECENTER := 5.0                 # per second, while re-centring
var _away := 0.0
var _recentering := false
var _offset := Vector2.ZERO
var qa_tilt := Vector2.ZERO          # (tools/qa depth=x,y on the pet screen: a pretend tilt)
var _view: Node2D                    # PetView
var _view_anim: AnimationPlayer
var _view_applied := Vector2.ZERO    # the shift on PetView now
var _menus: Array[Node2D] = []        # the menus (each moved whole; their animations move their child "Menu")
var _menus_applied := Vector2.ZERO

func _ready() -> void:
	_bg = get_node_or_null("../PetBackground") as Node2D
	if not _bg:
		set_process(false)
		return
	var mr := get_node_or_null("../Menus")
	if mr:
		for m in mr.get_children():
			if m is Node2D:
				_menus.append(m)
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
	var mw := (_offset * FRONT).round()
	for m in _menus:
		if is_instance_valid(m):
			m.position += mw - _menus_applied
	_menus_applied = mw

## -1..1 on both axes
func _input_tilt(delta: float) -> Vector2:
	var g := Input.get_gravity()
	if g == Vector3.ZERO:
		g = Input.get_accelerometer()
	if g != Vector3.ZERO:
		# measured against the neutral pose in any pose (the user: the phone is held up in front of
		# you, not lying down): its left-right and its forward-back, as the games do (device_tilt)
		var n := g.normalized()
		if _n0 == Vector3.ZERO:
			_n0 = n
		var ang := acos(clampf(n.dot(_n0), -1.0, 1.0))
		_away = _away + delta if ang > POSE_CHANGE else 0.0
		if _away > POSE_HOLD:
			_recentering = true
		if _recentering and ang < 0.04:
			_recentering = false
		var rate := RECENTER if _recentering else SETTLE
		_n0 = _n0.slerp(n, clampf(delta * rate, 0.0, 1.0)).normalized()
		var ex := (Vector3.RIGHT - _n0 * _n0.x).normalized()
		var ey := _n0.cross(ex)
		var d := Vector2(n.dot(ex), n.dot(ey)) * GAIN
		return Vector2(clampf(d.x, -1.0, 1.0), clampf(d.y, -1.0, 1.0))
	if OS.has_feature("mobile"):
		return Vector2.ZERO
	# desktop: the mouse around the window's centre
	var vp := get_viewport()
	var size := vp.get_visible_rect().size
	var m := vp.get_mouse_position()
	var d2 := (m - size / 2.0) / (size / 2.0)
	return Vector2(clampf(d2.x, -1.0, 1.0), clampf(d2.y, -1.0, 1.0))
