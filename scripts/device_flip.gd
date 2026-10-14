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
	# double-tap whichever logo is showing (HaraTomo's Logo2, or the original Poop Pal one)
	logo = front.get_node("Console/LogoMain")
	for n in ["Console/Logo2", "Console/LogoMain"]:
		var l := front.get_node_or_null(n) as Sprite2D
		if l and l.visible:
			logo = l
			break
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
	if DevLaunch.case_demo:
		_setup_case()

func _exit_tree() -> void:
	if muffle_idx >= 0:
		AudioServer.remove_bus_effect(0, muffle_idx)
		AudioServer.set_bus_volume_db(0, 0.0)

func _input(event: InputEvent) -> void:
	if DevLaunch.case_demo and progress == 1.0 and (case_busy or case_drag == "placed"):
		# the case is going on / coming off, or the finger that put it on is still down: every
		# touch is the case's (that drag ends as a sideways swipe, which would turn the device)
		var up := event as InputEventMouseButton
		if up and not up.pressed:
			case_drag = ""
		if event is InputEventMouse or event is InputEventScreenTouch or event is InputEventScreenDrag:
			get_viewport().set_input_as_handled()
		return
	if DevLaunch.case_demo and progress == 1.0 and not turning and case_on and stickers.handle(event):
		get_viewport().set_input_as_handled()
		return
	if DevLaunch.case_demo and progress == 1.0 and not turning and _case_input(event):
		get_viewport().set_input_as_handled()
		return
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
	if stickers:
		stickers.close()
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
	if front_case:
		_show_front_case(case_on and p <= 0.5)      # (the front's case: only while the front faces you)
	overlay.case_tones = case_on
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
	# ...and with the case on (its colours: Melon Soda)
	const CASE_NEAR := Color8(158, 206, 180)
	const CASE_FAR := Color8(126, 174, 150)
	const CASE_SEAM := Color8(96, 140, 118)
	const CASE_LIT := Color8(206, 240, 220)
	const CASE_OUTLINE := Color8(70, 104, 88)
	var case_tones := false
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
			draw_rect(Rect2(near_x, side.position.y, half, side.size.y), CASE_NEAR if case_tones else NEAR)
			draw_rect(Rect2(far_x, side.position.y, half, side.size.y), CASE_FAR if case_tones else FAR_HALF)
			var seam_x := side.position.x + half
			var w := maxf(side.size.x * 0.06, 1.0)
			draw_line(Vector2(seam_x, side.position.y), Vector2(seam_x, side.end.y), CASE_SEAM if case_tones else SEAM, w)
			# a thin highlight where the side meets the face, then the dark outline
			var lit_x := side.position.x + w if face_left else side.end.x - w
			draw_line(Vector2(lit_x, side.position.y), Vector2(lit_x, side.end.y), CASE_LIT if case_tones else LIT, w)
			draw_rect(side, CASE_OUTLINE if case_tones else OUTLINE, false, minf(4.0, side.size.x * 0.5))


# ================================================================== CASE (dev launcher: CASE)
## A case to try on (docs/ideas_roadmap.md, Coin Shop: cases). On the back its corner pokes in
## from the right like an arrow; drag it in: past the middle of the screen the case slides on
## from above (released before, the corner goes back). Swipe the case UP to take it off: far
## enough and it slides away and comes back as the corner, else it settles back on. With the
## case on, the battery compartment is covered (take the case off to reach it), and the front wears it too (an overlay of the case's own pixels: the screen, the LCD
## and the buttons stay live). Art: textures/cases/melon_*.png (from the mockup's rules).
const CASE_BACK := preload("res://textures/cases/melon_back.png")   # (covers the battery compartment)
const CASE_FRONT := preload("res://textures/cases/melon_front.png")
const CASE_CENTRE := Vector2(540, -960)          # the back's sprites (back coordinates)
const CORNER_TIP := Vector2(910, -615)           # where the corner's tip pokes in
const CORNER_TURN := -45.0                       # degrees: its corner points left, like an arrow
const CASE_HALF := Vector2(540, 960)

var case_on := false
var case_sprite: Sprite2D           # on the back: over the shell, under the battery lid
var corner: Sprite2D
var front_case: Sprite2D           # (under the buttons)
var front_case_top: Sprite2D       # (over the logo and the screws)
var case_buttons := []             # [button, its normal, pressed, the case's normal, pressed]
var case_drag := ""                 # "" / "corner" / "case" / "placed" (the finger still down)
var case_busy := false              # the case going on / coming off: no turn meanwhile
var stickers = null                 # the sticker book and the stickers (case_stickers.gd)
var drag_from := Vector2.ZERO
var corner_rest := Vector2.ZERO

func _setup_case() -> void:
	case_sprite = Sprite2D.new()
	case_sprite.texture = CASE_BACK
	case_sprite.position = CASE_CENTRE
	case_sprite.visible = false
	back.add_child(case_sprite)                     # (over the battery lid too: the case covers it)
	corner = Sprite2D.new()
	corner.texture = CASE_BACK
	corner.rotation_degrees = CORNER_TURN
	corner_rest = CORNER_TIP - (-CASE_HALF).rotated(deg_to_rad(CORNER_TURN))
	corner.position = corner_rest
	back.add_child(corner)
	stickers = preload("res://scripts/case_stickers.gd").new()
	stickers.case_sprite = case_sprite
	stickers.corner = corner
	back.add_child(stickers)                        # (above the case: its book peeks in at the left)
	# the front: a base layer over the console body and under every button (solid where they sit,
	# so a button pressed or not always lands on the case), a top layer for the carved logo and
	# the screws, and Melon Soda images for the menu buttons (their frame in the case's colours)
	var console := front.get_node("Console")
	front_case = _case_layer(CASE_FRONT, 3)            # (over the screen's frame art, z 3; under every button)
	console.add_child(front_case)
	front_case_top = _case_layer(load("res://textures/cases/melon_front_top.png"), 4)
	console.add_child(front_case_top)
	for b in [["MenuButtons/FoodButton", "buttonfood"], ["MenuButtons/GameButton", "padbutton"], ["MenuButtons/SettingsButton", "settingsbutton"]]:
		var btn := front.get_node_or_null(b[0]) as TextureButton
		if btn:
			case_buttons.append([btn, btn.texture_normal, btn.texture_pressed,
				load("res://textures/cases/melon_%snormal.png" % b[1]), load("res://textures/cases/melon_%spressed.png" % b[1])])
	# (no automatic turn: you flip the device yourself, double-tap the logo, to find the corner)

func _back_pos(screen_pos: Vector2) -> Vector2:
	return back.get_global_transform_with_canvas().affine_inverse() * screen_pos

func _case_input(event: InputEvent) -> bool:
	var mb := event as InputEventMouseButton
	var mm := event as InputEventMouseMotion
	if mb and mb.button_index == MOUSE_BUTTON_LEFT:
		var p := _back_pos(mb.position)
		if mb.pressed:
			drag_from = p
			if not case_on and corner.visible:
				var c := corner.get_global_transform_with_canvas().affine_inverse() * mb.position
				if Rect2(-CASE_HALF, CASE_HALF * 2.0).has_point(c) and p.x < 1080.0:
					case_drag = "corner"
					return true
			return false                            # (a tap / swipe for the turn: not ours yet)
		# released
		if case_drag == "corner":
			case_drag = ""
			create_tween().tween_property(corner, "position", corner_rest, 0.25).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
			return true
		if case_drag == "case":
			case_drag = ""
			if case_sprite.position.y < CASE_CENTRE.y - 960.0 * 0.5:
				_take_case_off()
			else:
				create_tween().tween_property(case_sprite, "position", CASE_CENTRE, 0.25).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
			return true
		return false
	if mm and mm.button_mask & MOUSE_BUTTON_MASK_LEFT:
		var p := _back_pos(mm.position)
		var d := p - drag_from
		if case_drag == "corner":
			corner.position = corner_rest + Vector2(minf(0.0, d.x), 0.0)      # the case shows more as it comes in
			if p.x < 540.0:
				case_drag = "placed"                # (until this finger lifts, no turn)
				_put_case_on()
			return true
		if case_on and case_drag == "" and d.y < -24.0 and absf(d.y) > absf(d.x):
			case_drag = "case"                      # a swipe up: the case comes off with the finger
		if case_drag == "case":
			case_sprite.position = CASE_CENTRE + Vector2(0.0, minf(0.0, d.y))
			return true
	return false

## The case slides on from above and clicks into place; the front wears it too
func _put_case_on() -> void:
	case_busy = true
	# the whole case rises from the side and up out of the screen, straightening as it goes...
	var t := create_tween().set_parallel(true)
	t.tween_property(corner, "position", Vector2(CASE_CENTRE.x, CASE_CENTRE.y - 2200), 0.8).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	t.tween_property(corner, "rotation_degrees", 0.0, 0.8).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	var s := create_tween()
	s.tween_interval(0.8)
	s.tween_callback(func():
		corner.visible = false
		corner.rotation_degrees = CORNER_TURN
		case_sprite.position = CASE_CENTRE + Vector2(0, -1920)
		case_sprite.visible = true)
	# ...then comes down onto the device, gently, and clicks
	s.tween_property(case_sprite, "position", CASE_CENTRE, 0.75).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	s.tween_callback(func():
		case_on = true
		case_busy = false
		stickers.show_book(true)
		Input.vibrate_handheld(30)
		_case_click())

## Up and away; its corner comes back in from the right
func _take_case_off() -> void:
	case_on = false
	case_busy = true
	stickers.show_book(false)
	var t := create_tween()
	t.tween_property(case_sprite, "position", CASE_CENTRE + Vector2(0, -1920), 0.3).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	t.tween_callback(func():
		case_sprite.visible = false
		corner.position = corner_rest + Vector2(500, 0)      # (then its corner slides back in from the side)
		corner.visible = true)
	t.tween_property(corner, "position", corner_rest, 0.35).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	t.tween_callback(func(): case_busy = false)

func _case_click() -> void:
	var a := AudioStreamPlayer.new()
	a.stream = load("res://sounds/fx/clack.mp3")
	a.volume_db = -8.0
	add_child(a)
	a.play()
	a.finished.connect(a.queue_free)

func _case_layer(t: Texture2D, z: int) -> Sprite2D:
	var sp := Sprite2D.new()
	sp.texture = t
	sp.centered = false
	# (the console's pieces are y-sorted: anchored at the bottom, the case is drawn after the
	# screen's frame and the logo at its z, not under them)
	# screen-sized art: lined up with what the camera shows (it isn't exactly at the console's
	# middle: at -1920 the case sat 6 px high and covered the screens' bottom edges)
	sp.position = Vector2(0, 0)
	sp.offset = cam.position - Vector2(540, 960)
	sp.z_index = z
	sp.visible = false
	return sp

func _show_front_case(on: bool) -> void:
	if front_case.visible == on:
		return
	front_case.visible = on
	front_case_top.visible = on
	var mirror := front.get_node_or_null("Console/LeftEdgeMirror") as CanvasItem
	if mirror:
		mirror.visible = not on                     # (the case's art has its own left side)
	var screen := front.get_node_or_null("Console/MainScreen") as Sprite2D
	if screen:
		if not screen.has_meta("plain"):
			screen.set_meta("plain", screen.texture)
		screen.texture = load("res://textures/cases/melon_frame3.png") if on else screen.get_meta("plain")
	var spk := front.get_node_or_null("Console/SpeakerCentre") as CanvasItem
	if spk:
		spk.visible = not on                        # (the case's art has the grille: holes on the case;
		                                            # Speaker1/2 are the old side ones, always hidden)
	for c in case_buttons:
		var btn: TextureButton = c[0]
		var normal: Texture2D = c[3] if on else c[1]
		var pressed: Texture2D = c[4] if on else c[2]
		btn.texture_normal = pressed if btn.button_pressed else normal     # (menu_buttons.gd swaps these on toggle)
		btn.texture_pressed = pressed
		btn.set("normal_texture", normal)
		btn.set("pressed_texture", pressed)
