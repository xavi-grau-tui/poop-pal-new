extends Node
## 3D "wallpaper" effect on the pet screen: tilting the phone slides the sky and the clouds a
## little behind the gut (the gut, the cam and the pal stay put), so the gut seems to float in
## front of the background, like the iPhone's perspective wallpapers.
##
## Whatever angle you hold the phone at slowly becomes "neutral" (only the movement counts).
## Deeper layers move more. Desktop (no tilt sensor): the mouse position does it.

const LAYERS := {                    # node under PetBackground -> how far it slides (px)
	"PinkBackground": 18.0,          # the sky: furthest away
	"CloudA": 13.0,                  # far clouds
	"CloudB": 8.0,                   # near clouds
}
const GAIN := 2.6                    # tilt (in g) -> -1..1
const SETTLE := 0.5                  # how fast the neutral angle follows the phone (per second)
const SMOOTH := 8.0                  # follow speed of the layers
const INVERT := false                # flip if it moves the wrong way on the phone

var _bg: Node2D
var _home := {}                      # layer -> its scene position
var _neutral := Vector2.ZERO
var _has_neutral := false
var _offset := Vector2.ZERO

func _ready() -> void:
	_bg = get_node_or_null("../PetBackground") as Node2D
	if not _bg:
		set_process(false)
		return
	for n in LAYERS:
		var layer := _bg.get_node_or_null(n) as Node2D
		if layer:
			_home[layer] = layer.position

func _process(delta: float) -> void:
	var target := _input_tilt(delta)
	if INVERT:
		target = -target
	_offset = _offset.lerp(target, clampf(delta * SMOOTH, 0.0, 1.0))
	for layer in _home:
		if is_instance_valid(layer):
			# the background moves against the tilt, so it seems to sit behind the gut
			layer.position = _home[layer] - _offset * LAYERS[layer.name]

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
