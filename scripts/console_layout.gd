extends RefCounted
class_name ConsoleLayout
## The bottom buttons' layout, ON TRIAL (2026-10-10). The first layout stays in the scene, so
## switching back is just NEW_BUTTONS = false.
##   first (the scene):  sound (left, grill under it) · orange MAIN (middle) · forward (right, grill)
##   new (NEW_BUTTONS):  orange MAIN (left) · sound (middle, one 7-column grill under it) · forward
##                       (right, a square like the orange button, its cream and >> sign)
## The buttons only move: every one keeps its logic. The art comes from
## tools/design/console_buttons_new.py (it also makes the box's device picture for this layout).

const NEW_BUTTONS := true

## Main UI coords (as the scene places the buttons)
const MAIN_AT := Vector2(149, -297)        # where the sound button's left edge was
const SOUND_AT := Vector2(451, -293)
const FORWARD_AT := Vector2(749, -297)
const GRILL_AT := Vector2(541, -97)        # the new speaker grill's centre
const GRILL_SCALE := Vector2(0.354854, 0.320924)

## The box's picture of the device (the unboxing), matching the layout in use
static func device_picture() -> Texture2D:
	return load("res://textures/unboxing/box/device_newbuttons.png" if NEW_BUTTONS else "res://textures/unboxing/box/device.png")

static func apply(main_ui: Node) -> void:
	if not NEW_BUTTONS:
		return
	var main := main_ui.get_node_or_null("MainButton") as Control
	var sound := main_ui.get_node_or_null("SoundButtons/SoundButton") as Control
	var forward := main_ui.get_node_or_null("SoundButtons/ForwardButton") as TextureButton
	if main:
		main.position = MAIN_AT
	if sound:
		sound.position = SOUND_AT
	if forward:
		forward.texture_normal = load("res://textures/buttons/forwardsquarenormal.png")
		forward.texture_pressed = load("res://textures/buttons/forwardsquarepressed.png")
		forward.size = forward.texture_normal.get_size()
		forward.position = FORWARD_AT
	for path in ["Console/Speaker1", "Console/Speaker2"]:
		var old := main_ui.get_node_or_null(path) as CanvasItem
		if old:
			old.visible = false
	var first := main_ui.get_node_or_null("Console/Speaker1") as Sprite2D
	if first and not main_ui.get_node_or_null("Console/SpeakerCentre"):
		var grill := Sprite2D.new()
		grill.name = "SpeakerCentre"
		grill.texture = load("res://textures/console/speakerholes7.png")
		grill.position = GRILL_AT
		grill.scale = GRILL_SCALE
		grill.z_index = first.z_index
		grill.texture_filter = first.texture_filter
		first.get_parent().add_child(grill)
