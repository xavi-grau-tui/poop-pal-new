extends Node
class_name ButtonTouchLook
## Lets the console buttons LOOK pressed under any finger (2026-10-10). The phone turns only
## the first finger into a mouse click, so with two buttons held (both pumps in Splash Hoops)
## only the first one showed pressed. This watches the touches itself and shows its button's
## pressed art while a finger is on it. Looks only: what a press does stays with the button.
##   ButtonTouchLook.attach_all(main_ui)       # (MainButton calls it once)

const BUTTONS := ["MainButton", "SoundButtons/SoundButton", "SoundButtons/ForwardButton"]
const GROW := 20.0                       # the same margin the games use to read a touch

var button: TextureButton
var _touches := {}                       # touch index -> true, the fingers on this button
var _normal: Texture2D                   # its own art, put back when the last finger lifts

static func attach_all(main_ui: Node) -> void:
	for path in BUTTONS:
		var b := main_ui.get_node_or_null(path) as TextureButton
		if b and not b.has_node("TouchLook"):
			var look := ButtonTouchLook.new()
			look.name = "TouchLook"
			look.button = b
			b.add_child(look)

func _input(event: InputEvent) -> void:
	if not (event is InputEventScreenTouch) or not button.is_visible_in_tree():
		return
	if event.pressed:
		var rect := Rect2(Vector2.ZERO, button.size).grow(GROW)
		if (button.get_global_transform_with_canvas() * rect).has_point(event.position):
			_touches[event.index] = true
	else:
		_touches.erase(event.index)
	_show(not _touches.is_empty())

func _show(down: bool) -> void:
	if down and not _normal and button.texture_pressed:
		_normal = button.texture_normal
		button.texture_normal = button.texture_pressed
	elif not down and _normal:
		# (unless something else changed its art meanwhile, e.g. the button layout on trial)
		if button.texture_normal == button.texture_pressed:
			button.texture_normal = _normal
		_normal = null
