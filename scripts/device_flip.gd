extends Node2D
## Double-tap the Poop Pal logo and the whole device turns around to show its back
## (scenes/console_back.tscn); swipe left/right (or double-tap) on the back to turn it front again.
##
## Created at runtime by MenuManager as a sibling of "Main UI". The turn is faked in 2D:
## the visible face squeezes to edge-on around the screen centre while lifting a little
## and darkening, then the other face opens out the same way.

const BACK_SCENE := preload("res://scenes/console_back.tscn")

const PIVOT := Vector2(540, -960)   # screen centre in Main UI coordinates
const TURN_TIME := 0.55
const LIFT := 0.07                  # extra scale at edge-on, as if picked up to turn it
const SHADE := 0.35                 # how much a face darkens as it turns away
const DOUBLE_TAP := 0.4             # max seconds between the two taps
const LOGO_PAD := 20.0              # tap slack around the logo, px
const SWIPE_MIN := 120.0            # horizontal drag on the back that counts as a swipe, px
const SWAY := 140.0                 # a swiped turn drifts this far toward the swipe at edge-on

var front: Node2D
var back: Node2D
var logo: Sprite2D
var progress := 0.0                 # 0 = front, 1 = back
var turning := false
var last_tap := -10.0
var press_pos := Vector2.ZERO
var swing := 0.0                    # -1 / 1 while a swiped turn is drifting left / right

func _ready() -> void:
	front = get_parent().get_node("Main UI")
	logo = front.get_node("Console/LogoMain")
	back = BACK_SCENE.instantiate()
	back.visible = false
	add_child(back)

func _input(event: InputEvent) -> void:
	var tap := event as InputEventMouseButton
	if not tap or tap.button_index != MOUSE_BUTTON_LEFT:
		return
	var showing_back := progress > 0.5
	if turning:
		get_viewport().set_input_as_handled()
		return
	if not tap.pressed:
		if showing_back:
			get_viewport().set_input_as_handled()
			var drag := tap.position - press_pos
			if absf(drag.x) >= SWIPE_MIN and absf(drag.x) > absf(drag.y) * 1.5:
				last_tap = -10.0
				_turn(0.0, signf(drag.x))
		return
	press_pos = tap.position
	if not showing_back and not (_can_turn() and _on_logo(tap.position)):
		return
	if showing_back:
		get_viewport().set_input_as_handled()   # nothing on the back takes taps
	var now := Time.get_ticks_msec() / 1000.0
	if now - last_tap <= DOUBLE_TAP:
		last_tap = -10.0
		get_viewport().set_input_as_handled()
		_turn(0.0 if showing_back else 1.0)
	else:
		last_tap = now

func _can_turn() -> bool:
	# not during the power-on sequence or while a minigame is running
	if front.get_node_or_null("BootSequence"):
		return false
	var gs := front.get_node_or_null("GameScreen")
	return not (gs and gs.get("current_game"))

func _on_logo(screen_pos: Vector2) -> bool:
	var world := get_viewport().get_canvas_transform().affine_inverse() * screen_pos
	return logo.get_rect().grow(LOGO_PAD / logo.scale.x).has_point(logo.to_local(world))

func _turn(target: float, direction := 0.0) -> void:
	turning = true
	swing = direction
	var t := create_tween()
	t.tween_method(_apply, progress, target, TURN_TIME).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	t.tween_callback(func(): turning = false)

func _apply(p: float) -> void:
	progress = p
	var angle := p * PI
	var edge := sin(angle)                      # 0 face-on, 1 edge-on
	var squeeze := maxf(absf(cos(angle)), 0.001)
	var lift := 1.0 + LIFT * edge
	var face := back if p > 0.5 else front
	var hidden := front if face == back else back
	hidden.visible = false
	face.visible = true
	face.scale = Vector2(squeeze * lift, lift)
	face.position = PIVOT - PIVOT * face.scale + Vector2(swing * SWAY * edge, 0)
	var s := 1.0 - SHADE * edge
	face.modulate = Color(s, s, s)
	if p == 0.0 or p == 1.0:
		face.scale = Vector2.ONE
		face.position = Vector2.ZERO
		face.modulate = Color.WHITE
