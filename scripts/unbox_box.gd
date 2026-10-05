extends CanvasLayer
## First launch, before the films: the device still in its retail box, seen from above.
## Peel the round seal off the lid's edge, swipe the lid away (cardboard sound), then swipe
## the device up out of its tray: it rises, showing the instruction booklet that lay under
## it, and comes back down towards you, growing until it is the game's own device. The box
## is screen-space art on top of everything; its device picture is the game's first frame
## (films on), so when it lands this layer goes and nothing changes on screen.
##
## Created by Unboxing (as its child, so it hears input before everything else). Art and
## layout: tools/design/box_art.py -> textures/unboxing/box/ (keep the rects in sync).

signal opened

const DEV_RECT := Rect2(216, 500, 648, 1152)        # the device in its tray (scale 0.6)
const BOOK_POS := Vector2(255, 716)
const SEAL_C := Vector2(540, 1886)                  # a wide clear tape strip
const SEAL_SIZE := Vector2(320, 120)

const PEEL_SOUND := preload("res://sounds/fx/film_peel.wav")
const LID_SOUND := preload("res://sounds/fx/box_lid.wav")
const LAND_SOUND := preload("res://sounds/fx/box_land.wav")
const FULL_DEVICE := preload("res://textures/unboxing/box/device.png")

enum { SEAL, LID, DEVICE, OUT }
var step := SEAL
var dragging := false
var press_pos := Vector2.ZERO

var seal: Sprite2D
var lid: Node2D
var lid_shadow: ColorRect
var device: Sprite2D
var crackle: AudioStreamPlayer

func _ready() -> void:
	layer = 110                      # above the flip's and the boot's overlays (100)
	_sprite(preload("res://textures/unboxing/box/insert.png"), Vector2.ZERO)
	_sprite(preload("res://textures/unboxing/box/booklet.png"), BOOK_POS)
	# in the tray it is the pre-scaled picture (pixel-identical to the launch splash); once
	# it moves it becomes the full-size one, scaled
	device = Sprite2D.new()
	device.texture = preload("res://textures/unboxing/box/device_tray.png")
	device.position = DEV_RECT.get_center()
	add_child(device)
	lid_shadow = ColorRect.new()
	lid_shadow.size = Vector2(1080, 1920)
	lid_shadow.color = Color(0, 0, 0, 0)
	lid_shadow.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(lid_shadow)
	lid = Node2D.new()                # pivots on the screen's centre, so it can lift towards you
	lid.position = Vector2(540, 960)
	add_child(lid)
	var lid_art := _sprite(preload("res://textures/unboxing/box/lid.png"), Vector2(-540, -960))
	lid_art.reparent(lid, false)
	seal = Sprite2D.new()
	seal.texture = preload("res://textures/unboxing/box/seal.png")
	seal.position = SEAL_C
	lid.add_child(seal)
	seal.position = SEAL_C - lid.position
	crackle = AudioStreamPlayer.new()
	var stream: AudioStreamWAV = PEEL_SOUND.duplicate()
	stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
	stream.loop_end = int(stream.get_length() * stream.mix_rate)
	crackle.stream = stream
	crackle.volume_db = -22.0
	crackle.pitch_scale = 1.5
	add_child(crackle)

func _sprite(tex: Texture2D, pos: Vector2) -> Sprite2D:
	var s := Sprite2D.new()
	s.texture = tex
	s.centered = false
	s.position = pos
	add_child(s)
	return s

func _sfx(stream: AudioStream, db: float) -> void:
	var p := AudioStreamPlayer.new()
	p.stream = stream
	p.volume_db = db
	get_tree().root.add_child(p)     # (outlives the box, which goes as the device lands)
	p.play()
	p.finished.connect(p.queue_free)

# ------------------------------------------------------------------ input

func _input(event: InputEvent) -> void:
	if not (event is InputEventMouse or event is InputEventScreenTouch or event is InputEventScreenDrag):
		return
	get_viewport().set_input_as_handled()        # nothing behind the box takes a touch
	var tap := event as InputEventMouseButton
	var motion := event as InputEventMouseMotion
	if tap and tap.button_index != MOUSE_BUTTON_LEFT:
		return
	if tap and tap.pressed:
		_press(tap.position)
	elif motion and dragging:
		_drag(motion.position - press_pos)
		if step == SEAL:
			_seal_crackle(motion.position)
	elif tap and not tap.pressed and dragging:
		dragging = false
		_release(tap.position - press_pos)

func _press(pos: Vector2) -> void:
	match step:
		SEAL:
			dragging = Rect2(SEAL_C - SEAL_SIZE / 2.0, SEAL_SIZE).grow(60.0).has_point(pos)
			if dragging:
				crackle.volume_db = -80.0
				crackle.play(randf() * 0.8)
				seal_last = pos
		LID:
			dragging = true
		DEVICE:
			dragging = DEV_RECT.grow(30).has_point(pos)
	press_pos = pos

var seal_last := Vector2.ZERO
var seal_speed := 0.0

## The seal's peel sound follows the finger's speed (like the films): quiet when it stops.
func _seal_crackle(pos: Vector2) -> void:
	var dt := maxf(get_process_delta_time(), 0.001)
	seal_speed = lerpf(seal_speed, pos.distance_to(seal_last) / dt, 0.4)
	seal_last = pos
	_seal_volume()

func _seal_volume() -> void:
	var amount := clampf(seal_speed / 900.0, 0.0, 1.0)
	crackle.volume_db = -20.0 + linear_to_db(sqrt(maxf(amount, 0.001)))
	crackle.pitch_scale = 1.3 + 0.4 * amount

func _process(_delta: float) -> void:
	if step == SEAL and dragging:            # the finger stopped: the crackle trails off
		seal_speed *= 0.85
		_seal_volume()

func _drag(d: Vector2) -> void:
	match step:
		SEAL:                                    # it comes away with the finger
			d = d.limit_length(320.0)
			seal.position = SEAL_C - lid.position + d
			seal.rotation = d.x * 0.002
		LID:                                     # lifted off upwards, a little towards you
			var up := clampf(-d.y, 0.0, 900.0)
			lid.position.y = 960.0 - up
			lid.scale = Vector2.ONE * (1.0 + 0.05 * up / 900.0)
			lid_shadow.color.a = 0.25 * up / 900.0
		DEVICE:                                  # pulled up out of the tray
			_full_size_device()
			device.position.y = DEV_RECT.get_center().y - clampf(-d.y, 0.0, 420.0)

func _full_size_device() -> void:
	if device.texture != FULL_DEVICE:
		device.texture = FULL_DEVICE
		device.scale = Vector2.ONE * (DEV_RECT.size.x / 1080.0)

func _release(d: Vector2) -> void:
	match step:
		SEAL:
			var fade := crackle.create_tween()   # (let go too soon: gone at once; peeled off: a short tail)
			fade.tween_property(crackle, "volume_db", -60.0, 0.2 if d.length() > 90.0 else 0.06)
			fade.tween_callback(crackle.stop)
			if d.length() > 90.0:
				step = LID
				var t := seal.create_tween().set_parallel(true)
				t.tween_property(seal, "position", seal.position + d.normalized() * 500.0, 0.3).set_ease(Tween.EASE_IN)
				t.tween_property(seal, "modulate:a", 0.0, 0.3)
				t.chain().tween_callback(seal.queue_free)
			else:
				var t := seal.create_tween().set_parallel(true)
				t.tween_property(seal, "position", SEAL_C - lid.position, 0.2).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
				t.tween_property(seal, "rotation", 0.0, 0.2)
		LID:
			if -d.y > 220.0:
				step = DEVICE
				_sfx(LID_SOUND, -8.0)
				var t := create_tween().set_parallel(true)
				t.tween_property(lid, "position:y", -1400.0, 0.4).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
				t.tween_property(lid, "scale", Vector2.ONE * 1.08, 0.4)
				t.tween_property(lid_shadow, "color:a", 0.0, 0.4)
				t.chain().tween_callback(func(): lid.queue_free(); lid_shadow.queue_free())
			else:
				var t := create_tween().set_parallel(true)
				t.tween_property(lid, "position:y", 960.0, 0.25).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
				t.tween_property(lid, "scale", Vector2.ONE, 0.25)
				t.tween_property(lid_shadow, "color:a", 0.0, 0.25)
		DEVICE:
			if -d.y > 120.0:
				step = OUT
				_take_out()
			else:
				_full_size_device()
				create_tween().tween_property(device, "position:y", DEV_RECT.get_center().y, 0.25) \
					.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

## Up out of the tray and straight back down towards you in one movement (the booklet
## shows underneath as it passes: it's there, for later), growing until it is the game's
## own device, and a soft landing.
func _take_out() -> void:
	_full_size_device()
	var t := create_tween()
	# one fluent arc: up (the booklet shows for about a second as it passes) and straight down
	t.tween_property(device, "position:y", -260.0, 0.5).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	t.tween_property(device, "position", Vector2(540, 960), 0.55).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	t.parallel().tween_property(device, "scale", Vector2.ONE, 0.55).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	t.tween_callback(func():
		Input.vibrate_handheld(30)
		_sfx(LAND_SOUND, -10.0))
	t.tween_property(device, "scale", Vector2.ONE * 1.015, 0.06).set_ease(Tween.EASE_OUT)
	t.tween_property(device, "scale", Vector2.ONE, 0.1).set_ease(Tween.EASE_IN_OUT)
	t.tween_interval(0.05)
	t.tween_callback(func():
		opened.emit()
		queue_free())
