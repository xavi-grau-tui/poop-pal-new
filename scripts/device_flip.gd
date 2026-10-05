extends Node2D
## Double-tap the Poop Pal logo and the whole device turns around to show its back
## (scenes/console_back.tscn); swipe left/right (or double-tap) on the back to turn it front again.
##
## Created at runtime by MenuManager as a sibling of "Main UI". The front is never hidden,
## moved or scaled, so whatever is going on (an animation, a menu, even a minigame) carries
## on untouched while the back is up. The turn is done with the camera: its zoom squeezes
## the device to edge-on and back, a screen-space overlay draws the case's side (its
## thickness) next to the face and covers everything outside the device, and the back
## sprite sits above the whole front while it is the face showing.
##
## The speakers are on the front, so turning it away muffles everything (a low-pass on
## the Master bus sweeps down as the back comes round), and each turn ends with a small
## buzz, as if it settled in your hand.

const BACK_SCENE := preload("res://scenes/console_back.tscn")

const TURN_TIME := 0.7
const LIFT := 0.07                  # extra scale at edge-on, as if picked up to turn it
const SHADE := 0.35                 # how much a face darkens as it turns away
const THICK := 90.0                 # case thickness seen edge-on, screen px
const DOUBLE_TAP := 0.4             # max seconds between the two taps
const LOGO_PAD := 20.0              # tap slack around the logo, px
const SWIPE_MIN := 120.0            # horizontal drag on the back that counts as a swipe, px
const SWAY := 140.0                 # a swiped turn drifts this far toward the swipe at edge-on
const DEVICE := Rect2(0, -1920, 1080, 1920)   # the device in Main UI coordinates
const OPEN_HZ := 20000.0            # low-pass cutoff facing the front (effectively off)
const MUFFLED_HZ := 700.0           # ...and with the speakers facing away
const MUFFLED_DB := -4.0            # the back is a little quieter too
const SETTLE_BUZZ_MS := 18          # vibration when a turn finishes
# ...fired this close to the end of the turn: the device already fills the screen there
# (the eased tail barely moves), so the buzz lands on the visible stop
const SETTLE_AT := 0.08

var front: Node2D
var back: Node2D
var logo: Sprite2D
var cam: Camera2D
var overlay: Overlay
var progress := 0.0                 # 0 = front, 1 = back
var turning := false
var last_tap := -10.0
var press_pos := Vector2.ZERO
var swing := 0.0                    # -1 / 1 while a swiped turn is drifting left / right
var rest_rect: Rect2                # the device on screen when face-on
var base_zoom: Vector2
var base_offset: Vector2
var muffle: AudioEffectLowPassFilter
var muffle_idx := -1
var turn_target := 0.0
var settled := true                 # the settle buzz has fired for this turn

func _ready() -> void:
	front = get_parent().get_node("Main UI")
	logo = front.get_node("Console/LogoMain")
	cam = get_parent().get_node("Camera2D")
	back = BACK_SCENE.instantiate()
	back.visible = false
	back.z_as_relative = false
	back.z_index = RenderingServer.CANVAS_ITEM_Z_MAX - 1   # above everything on the front
	add_child(back)
	var layer := CanvasLayer.new()
	layer.layer = 100
	add_child(layer)
	overlay = Overlay.new()
	overlay.visible = false
	layer.add_child(overlay)
	muffle = AudioEffectLowPassFilter.new()
	muffle.cutoff_hz = OPEN_HZ
	AudioServer.add_bus_effect(0, muffle)
	muffle_idx = AudioServer.get_bus_effect_count(0) - 1
	AudioServer.set_bus_effect_enabled(0, muffle_idx, false)

func _exit_tree() -> void:
	if muffle_idx >= 0:
		AudioServer.remove_bus_effect(0, muffle_idx)
		AudioServer.set_bus_volume_db(0, 0.0)

func _input(event: InputEvent) -> void:
	var showing_back := progress > 0.5
	var pointer := event is InputEventMouse or event is InputEventScreenTouch or event is InputEventScreenDrag
	if pointer and (turning or showing_back):
		get_viewport().set_input_as_handled()   # the front keeps running but takes no input
	var tap := event as InputEventMouseButton
	if not tap or tap.button_index != MOUSE_BUTTON_LEFT or turning:
		return
	if not tap.pressed:
		if showing_back:
			var drag := tap.position - press_pos
			if absf(drag.x) >= SWIPE_MIN and absf(drag.x) > absf(drag.y) * 1.5:
				last_tap = -10.0
				_turn(0.0, signf(drag.x))
		return
	press_pos = tap.position
	if not showing_back and not (_can_turn() and _on_logo(tap.position)):
		return
	var now := Time.get_ticks_msec() / 1000.0
	if now - last_tap <= DOUBLE_TAP:
		last_tap = -10.0
		get_viewport().set_input_as_handled()
		_turn(0.0 if showing_back else 1.0)
	else:
		last_tap = now

func _can_turn() -> bool:
	# not during the power-on sequence (but yes before it, while unboxing: no power yet)
	return Unboxing.waiting() or front.get_node_or_null("BootSequence") == null

func _on_logo(screen_pos: Vector2) -> bool:
	var world := get_viewport().get_canvas_transform().affine_inverse() * screen_pos
	return logo.get_rect().grow(LOGO_PAD / logo.scale.x).has_point(logo.to_local(world))

func _turn(target: float, direction := 0.0) -> void:
	if progress == 0.0 or progress == 1.0:
		base_zoom = cam.zoom
		base_offset = cam.offset
		rest_rect = _device_on_screen()
	turning = true
	swing = direction
	turn_target = target
	settled = false
	var t := create_tween()
	t.tween_method(_apply, progress, target, TURN_TIME).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	t.tween_callback(func(): turning = false)

func _device_on_screen() -> Rect2:
	var xf := get_viewport().get_canvas_transform() * front.get_global_transform()
	var r := Rect2(xf * DEVICE.position, Vector2.ZERO)
	for c in [DEVICE.end, Vector2(DEVICE.position.x, DEVICE.end.y), Vector2(DEVICE.end.x, DEVICE.position.y)]:
		r = r.expand(xf * c)
	return r

func _apply(p: float) -> void:
	progress = p
	back.visible = p > 0.5
	_set_muffle(p)
	if not settled and absf(p - turn_target) <= SETTLE_AT:
		settled = true
		Input.vibrate_handheld(SETTLE_BUZZ_MS)
	if p == 0.0 or p == 1.0:
		cam.zoom = base_zoom
		cam.offset = base_offset
		cam.force_update_scroll()
		overlay.visible = false
		return
	var angle := p * PI
	var edge := sin(angle)                      # 0 face-on, 1 edge-on
	var lift := 1.0 + LIFT * edge
	var zoom := Vector2(maxf(absf(cos(angle)), 0.002) * lift, lift)
	var face_w := rest_rect.size.x * zoom.x
	var face_h := rest_rect.size.y * zoom.y
	var side_w := THICK * edge * lift
	# where the camera zoom alone would put the face (it zooms about the screen centre)
	var mid := get_viewport().get_visible_rect().size / 2.0
	var zoomed := mid + (rest_rect.get_center() - mid) * zoom
	# lay the face and the case side out like a box turning: the side leads during the
	# first half of the turn and trails during the second
	var left := zoomed.x + swing * SWAY * edge - (face_w + side_w) / 2.0
	var side_first := (p < 0.5) == (swing >= 0.0)
	var face_x := left + side_w if side_first else left
	var side_x := left if side_first else left + face_w
	var shift := face_x + face_w / 2.0 - zoomed.x
	cam.zoom = base_zoom * zoom
	cam.offset = base_offset + Vector2(-shift / cam.zoom.x, 0.0)
	cam.force_update_scroll()
	var top := zoomed.y - face_h / 2.0
	overlay.face = Rect2(face_x, top, face_w, face_h)
	overlay.side = Rect2(side_x, top, side_w, face_h)
	overlay.shade = SHADE * edge
	overlay.face_left = not side_first
	overlay.visible = true
	overlay.queue_redraw()


## How far the speakers face away (0 front .. 1 back) -> low-pass cutoff and volume.
## The cutoff moves on a log scale, so the muffling sounds even through the turn.
func _set_muffle(p: float) -> void:
	AudioServer.set_bus_effect_enabled(0, muffle_idx, p > 0.0)
	muffle.cutoff_hz = OPEN_HZ * pow(MUFFLED_HZ / OPEN_HZ, p)
	AudioServer.set_bus_volume_db(0, MUFFLED_DB * p)


## Screen-space: hides everything outside the turning device, draws its side and darkens
## the face as it turns away.
class Overlay extends Node2D:
	const NEAR := Color8(214, 188, 152)    # the shell half next to the face showing
	const FAR_HALF := Color8(178, 146, 110)   # the other half, turned further from the light
	const SEAM := Color8(120, 88, 62)
	const LIT := Color8(250, 237, 217)
	const OUTLINE := Color8(72, 49, 37)
	const FAR := 100000.0

	var face := Rect2()
	var side := Rect2()
	var shade := 0.0
	var face_left := false              # the face is left of the side (else right)

	func _draw() -> void:
		var bg := RenderingServer.get_default_clear_color()
		var u := face.merge(side)
		draw_rect(Rect2(-FAR, -FAR, FAR + u.position.x, FAR * 2.0), bg)
		draw_rect(Rect2(u.end.x, -FAR, FAR, FAR * 2.0), bg)
		draw_rect(Rect2(u.position.x, -FAR, u.size.x, FAR + u.position.y), bg)
		draw_rect(Rect2(u.position.x, u.end.y, u.size.x, FAR), bg)
		if shade > 0.0:
			draw_rect(face, Color(0, 0, 0, shade))
		if side.size.x >= 1.0:
			# two shell halves meeting at a seam, the one by the face catching more light
			var half := side.size.x * 0.5
			var near_x := side.position.x if face_left else side.position.x + half
			var far_x := side.position.x + half if face_left else side.position.x
			draw_rect(Rect2(near_x, side.position.y, half, side.size.y), NEAR)
			draw_rect(Rect2(far_x, side.position.y, half, side.size.y), FAR_HALF)
			var seam_x := side.position.x + half
			var w := maxf(side.size.x * 0.06, 1.0)
			draw_line(Vector2(seam_x, side.position.y), Vector2(seam_x, side.end.y), SEAM, w)
			# a thin highlight where the side meets the face, then the dark outline
			var lit_x := side.position.x + w if face_left else side.end.x - w
			draw_line(Vector2(lit_x, side.position.y), Vector2(lit_x, side.end.y), LIT, w)
			draw_rect(side, OUTLINE, false, minf(4.0, side.size.x * 0.5))
