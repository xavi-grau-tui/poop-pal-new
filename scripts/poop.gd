# Poop.gd
extends AnimatedSprite2D

@export var blink_times := 6
@export var initial_blink_speed := 0.15
@export var blink_opacity := 0.0
@export var breathing_amount := Vector2(0.03, -0.03)
@export var breathing_time := 1.5

# Offset from this node to the visual centre of the poop body (texture has padding above)
@export var body_offset := Vector2(0, 50)

var blink_tween: Tween
var breathing_tween: Tween
var fx_tween: Tween
var base_scale := Vector2.ONE
var base_position := Vector2.ZERO

const MYSTERY_SCALE := 2.2   # the "EAT" sign shown before the first meal
var mystery: Sprite2D
var mystery_tween: Tween
var flush_charge := 0.0
var _time := 0.0

# Tickling: rub a finger back and forth over the pal and it giggles
const TICKLE_STROKES := 4          # back-and-forth strokes needed...
const TICKLE_WINDOW := 2.5         # ...within this many seconds (a relaxed rub is fine)
const TICKLE_STROKE_MIN := 5.0     # texels of travel for a stroke to count
const TICKLE_COOLDOWN := 1.4
var _rub_last := Vector2.ZERO
var _rub_dir := 0.0
var _rub_travel := 0.0
var _rub_times: Array[float] = []
var _rub_active := false
var _tickling := false
var _tickle_ready_at := 0.0
var _body_rect := Rect2()          # visible body, in local (texture) coords

# Drink boost badge: a little icon in the top-right corner of the pal's frame (pet cam)
const BOOST_BADGE_POS := Vector2(670, -955)        # inside the frame's cream area, top-right
var boost_badge: Sprite2D
var aura: BoostAura                                 # glow + drips on the pal while a boost is on
var _badge_bob: Tween

# Worn accessory (Collection): a separate sprite on the same canvas as the form. It stays
# still while the pal breathes, and only follows real movement (hops, shakes, flush).
const ACCESSORY_FOLLOW_SCALE := 0.12   # scale changes smaller than this (breathing) are ignored
var accessory: Sprite2D

func _ready():
	base_scale = scale
	base_position = position
	_spawn_mystery.call_deferred()
	PetState.form_changed.connect(_on_form_changed)
	accessory = Sprite2D.new()
	accessory.name = "Accessory"
	get_parent().add_child.call_deferred(accessory)
	_place_accessory_above.call_deferred()
	animation_changed.connect(_refresh_accessory)
	Collection.equipped_changed.connect(func(category, _id):
		if category == "accessories":
			_refresh_accessory())

	frame_changed.connect(_update_body_rect)
	_setup_boost_badge.call_deferred()
	if PetState.has_poop():
		sprite_frames = PetState.build_sprite_frames()
		play("idle")
		_start_breathing()
	else:
		modulate.a = 0.0
	_refresh_accessory()

func _process(delta: float) -> void:
	_time += delta
	_follow_accessory()
	if flush_charge > 0.0:
		rotation = sin(_time * 38.0) * 0.07 * flush_charge
		position = base_position + Vector2(sin(_time * 53.0) * 4.0 * flush_charge, 0)

func _start_breathing():
	if breathing_tween:
		breathing_tween.kill()
	breathing_tween = create_tween()
	breathing_tween.tween_property(self, "scale", base_scale + breathing_amount, breathing_time) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	breathing_tween.tween_property(self, "scale", base_scale, breathing_time) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	breathing_tween.set_loops()

func _stop_all_tweens():
	for t in [breathing_tween, blink_tween, fx_tween]:
		if t:
			t.kill()

func blink(custom_times := -1, custom_opacity := -1.0, custom_speed := -1.0):
	if not PetState.has_poop():
		return
	if breathing_tween:
		breathing_tween.kill()

	var times = blink_times if custom_times < 0 else custom_times
	var opacity = blink_opacity if custom_opacity < 0.0 else custom_opacity
	var speed = initial_blink_speed if custom_speed < 0.0 else custom_speed

	blink_tween = create_tween()

	for i in range(times):
		blink_tween.tween_property(self, "modulate:a", opacity, speed)
		blink_tween.tween_property(self, "modulate:a", 1.0, speed)
		speed *= 0.75

	await blink_tween.finished
	_start_breathing()

# ------------------------------------------------------------------ TICKLING

func _input(event: InputEvent) -> void:
	# finger drags (phone) or a dragged mouse (desktop); the phone's emulated mouse is ignored
	var lp: Vector2
	if event is InputEventScreenDrag:
		lp = to_local(get_canvas_transform().affine_inverse() * event.position)
	elif event is InputEventMouseMotion and event.device != InputEvent.DEVICE_ID_EMULATION and (event.button_mask & MOUSE_BUTTON_MASK_LEFT):
		lp = to_local(get_global_mouse_position())
	elif (event is InputEventScreenTouch or event is InputEventMouseButton) and not event.pressed:
		_rub_active = false
		return
	else:
		return
	if not _can_be_touched():
		return
	if not _body_rect.grow(6.0).has_point(lp):
		_rub_active = false
		return
	if not _rub_active:
		_rub_active = true
		_rub_last = lp
		_rub_dir = 0.0
		_rub_travel = 0.0
		return
	var dx := lp.x - _rub_last.x
	_rub_last = lp
	if absf(dx) < 0.01:
		return
	var dir := signf(dx)
	if dir != _rub_dir and _rub_dir != 0.0 and _rub_travel >= TICKLE_STROKE_MIN:
		_on_stroke()
		_rub_travel = 0.0
	if dir != _rub_dir:
		_rub_travel = 0.0
	_rub_dir = dir
	_rub_travel += absf(dx)

func _can_be_touched() -> bool:
	if not PetState.has_poop() or _tickling or flush_charge > 0.0 or modulate.a < 0.5:
		return false
	if GameScreen.is_active or not get_parent().visible:
		return false
	for b in get_tree().get_nodes_in_group("menu_toggle_buttons"):
		if b.button_pressed:
			return false
	return true

func _on_stroke() -> void:
	var now := Time.get_ticks_msec() / 1000.0
	_rub_times.append(now)
	while not _rub_times.is_empty() and now - _rub_times[0] > TICKLE_WINDOW:
		_rub_times.pop_front()
	# every stroke gives a tiny squish, so the pal feels touched
	if not (fx_tween and fx_tween.is_running()):
		var t := create_tween()
		t.tween_property(self, "scale", base_scale * Vector2(1.06, 0.95), 0.05)
		t.tween_property(self, "scale", base_scale, 0.08)
	if _rub_times.size() >= TICKLE_STROKES and now >= _tickle_ready_at:
		_rub_times.clear()
		_tickle()

func _tickle() -> void:
	_tickling = true
	_stop_all_tweens()
	scale = base_scale
	_play_sfx("res://sounds/fx/giggle.wav", -10.0)
	_hearts()
	fx_tween = create_tween()
	# wriggle, a happy little hop, wriggle again
	for i in 4:
		var dir := -1.0 if i % 2 == 0 else 1.0
		fx_tween.tween_property(self, "rotation", 0.14 * dir, 0.06)
		fx_tween.parallel().tween_property(self, "scale", base_scale * Vector2(1.08, 0.92), 0.06)
	fx_tween.tween_property(self, "rotation", 0.0, 0.05)
	fx_tween.tween_property(self, "position:y", base_position.y - 22.0, 0.14).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	fx_tween.parallel().tween_property(self, "scale", base_scale * Vector2(0.94, 1.08), 0.14)
	fx_tween.tween_property(self, "position:y", base_position.y, 0.14).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	fx_tween.tween_property(self, "scale", base_scale * Vector2(1.12, 0.88), 0.06)
	for i in 4:
		var dir := 1.0 if i % 2 == 0 else -1.0
		fx_tween.tween_property(self, "rotation", 0.1 * dir, 0.07)
	fx_tween.tween_property(self, "rotation", 0.0, 0.06)
	fx_tween.parallel().tween_property(self, "scale", base_scale, 0.2).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	await fx_tween.finished
	position = base_position
	rotation = 0.0
	_tickling = false
	_tickle_ready_at = Time.get_ticks_msec() / 1000.0 + TICKLE_COOLDOWN
	_start_breathing()

## Main button tap on the pet screen: a quick chuckle and a little bounce (no hearts).
## Tapping again while it's still bouncing just restarts the bounce.
func poke() -> void:
	if not PetState.has_poop() or _tickling or flush_charge > 0.0 or modulate.a < 0.5:
		return
	if fx_tween and fx_tween.is_running() and not has_meta("poking"):
		return                               # busy hatching / evolving
	_stop_all_tweens()
	set_meta("poking", true)
	position = base_position
	rotation = 0.0
	_play_sfx("res://sounds/fx/giggle_short.wav", -12.0, randf_range(0.92, 1.12))
	var lean := 0.07 if randf() < 0.5 else -0.07
	fx_tween = create_tween()
	fx_tween.tween_property(self, "scale", base_scale * Vector2(1.1, 0.9), 0.05)
	fx_tween.tween_property(self, "position:y", base_position.y - 12.0, 0.1).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	fx_tween.parallel().tween_property(self, "scale", base_scale * Vector2(0.96, 1.05), 0.1)
	fx_tween.parallel().tween_property(self, "rotation", lean, 0.1)
	fx_tween.tween_property(self, "position:y", base_position.y, 0.1).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	fx_tween.parallel().tween_property(self, "rotation", 0.0, 0.1)
	fx_tween.tween_property(self, "scale", base_scale, 0.14).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	var mine := fx_tween
	await mine.finished
	if fx_tween == mine:                     # (not restarted by another tap)
		remove_meta("poking")
		_start_breathing()

func _hearts() -> void:
	# three little pixel hearts float up from the pal
	var img := Image.create(7, 6, false, Image.FORMAT_RGBA8)
	var rows := [".##.##.", "#######", "#######", ".#####.", "..###..", "...#..."]
	for y in rows.size():
		for x in 7:
			if rows[y][x] == "#":
				img.set_pixel(x, y, Color8(246, 110, 150) if y > 0 or x % 3 != 1 else Color8(255, 190, 210))
	var heart := ImageTexture.create_from_image(img)
	var top := base_position + Vector2(0, (_body_rect.position.y) * base_scale.y)
	for i in 3:
		var h := Sprite2D.new()
		h.texture = heart
		h.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		h.scale = Vector2(5, 5)
		h.position = top + Vector2((i - 1) * 46.0, 10.0)
		h.modulate.a = 0.0
		h.z_index = 2                      # in front of the gut (the pet view isn't clipped)
		get_parent().add_child(h)
		var t := create_tween()
		t.tween_interval(i * 0.12)
		t.tween_property(h, "modulate:a", 1.0, 0.1)
		t.parallel().tween_property(h, "position:y", h.position.y - 60.0, 0.9).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
		t.tween_property(h, "modulate:a", 0.0, 0.25)
		t.tween_callback(h.queue_free)

func _update_body_rect() -> void:
	if not sprite_frames or not sprite_frames.has_animation(animation):
		return
	var tex := sprite_frames.get_frame_texture(animation, frame)
	if tex == null:
		return
	var img := tex.get_image()
	var used := img.get_used_rect() if img else Rect2i(Vector2i.ZERO, tex.get_size())
	_body_rect = Rect2(Vector2(used.position) - tex.get_size() / 2.0, used.size)

func _setup_boost_badge() -> void:
	boost_badge = Sprite2D.new()
	boost_badge.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	boost_badge.scale = Vector2(5, 5)
	boost_badge.position = BOOST_BADGE_POS
	boost_badge.z_index = 2
	boost_badge.visible = false
	get_parent().add_child(boost_badge)
	aura = BoostAura.new()
	aura.visible = false
	add_child(aura)
	PetState.boost_changed.connect(_on_boost_changed)
	_on_boost_changed(PetState.boost, false)

func _on_boost_changed(id: String, animate := true) -> void:
	if not boost_badge:
		return
	if _badge_bob:
		_badge_bob.kill()
	_refresh_aura()
	if id == "":
		if boost_badge.visible and animate:
			var t := create_tween()
			t.tween_property(boost_badge, "modulate:a", 0.0, 0.3)
			t.tween_callback(boost_badge.hide)
		else:
			boost_badge.hide()
		return
	boost_badge.texture = PetState.boost_icon(id)
	boost_badge.position = BOOST_BADGE_POS
	boost_badge.modulate.a = 1.0
	boost_badge.show()
	if animate:                                  # pops in when you drink, with a watery boing
		_play_sfx("res://sounds/fx/water_boing.wav", -11.0)
		boost_badge.scale = Vector2.ZERO
		create_tween().tween_property(boost_badge, "scale", Vector2(5, 5), 0.35).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_badge_bob = create_tween().set_loops()
	_badge_bob.tween_property(boost_badge, "position:y", BOOST_BADGE_POS.y - 6, 0.7).set_trans(Tween.TRANS_SINE)
	_badge_bob.tween_property(boost_badge, "position:y", BOOST_BADGE_POS.y, 0.7).set_trans(Tween.TRANS_SINE)

func _refresh_aura() -> void:
	if not aura:
		return
	aura.visible = PetState.boost != "" and PetState.has_poop()
	if aura.visible:
		_update_body_rect()
		aura.setup(PetState.boost, _body_rect)

func _place_accessory_above() -> void:
	if accessory and accessory.get_parent():
		accessory.get_parent().move_child(accessory, get_index() + 1)

func _follow_accessory() -> void:
	if not accessory:
		return
	accessory.position = position
	accessory.rotation = rotation
	accessory.modulate = modulate
	accessory.visible = visible
	var ratio := scale / base_scale
	var big := absf(ratio.x - 1.0) > ACCESSORY_FOLLOW_SCALE or absf(ratio.y - 1.0) > ACCESSORY_FOLLOW_SCALE
	accessory.scale = scale if big else base_scale

func _refresh_accessory() -> void:
	_update_body_rect()
	_refresh_aura()
	if not accessory:
		return
	var dir: String = Collection.ACCESSORIES.get(Collection.equipped_accessory, {}).get("dir", "")
	var path := "%s%s-1.png" % [dir, PetState.form_id]      # one still frame (no breathing)
	if dir == "" or not PetState.has_poop() or not ResourceLoader.exists(path):
		accessory.texture = null
		return
	accessory.texture = load(path)

# ------------------------------------------------------------------ PET CYCLE

func _on_form_changed(_form_id: String, reason: String) -> void:
	match reason:
		"hatch":
			_play_hatch()
		"evolve":
			_play_evolve()
		"flush":
			_show_mystery()

func _play_hatch() -> void:
	_stop_all_tweens()
	_hide_mystery()
	sprite_frames = PetState.build_sprite_frames()
	play("idle")
	_refresh_accessory()
	scale = Vector2.ZERO
	modulate = Color(1, 1, 1, 1)
	fx_tween = create_tween()
	fx_tween.tween_property(self, "scale", base_scale, 0.7).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)
	_play_sfx("res://sounds/fx/gamecoin.wav", -8.0)
	get_tree().create_timer(0.45).timeout.connect(_say_hi)
	await fx_tween.finished
	_start_breathing()

## A new pal greets you: a little "hi!" noise, a tiny hop and "hi!" floating up the cam
func _say_hi() -> void:
	_say("hi!", "res://sounds/fx/hi.wav")

## Flush: the pal says goodbye before it spins away
func say_bye() -> void:
	_say("bye!", "res://sounds/fx/bye.wav")

func _say(word: String, sound: String) -> void:
	if not PetState.has_poop():
		return
	_play_sfx(sound, -9.0, randf_range(0.97, 1.06))
	var hop := create_tween()
	hop.tween_property(self, "position:y", base_position.y - 10.0, 0.1).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	hop.tween_property(self, "position:y", base_position.y, 0.12).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	var l := Label.new()
	l.text = word
	var f = load("res://fonts/pixChicago.ttf")
	if f:
		l.add_theme_font_override("font", f)
	l.add_theme_font_size_override("font_size", 46)
	l.add_theme_color_override("font_color", Color8(250, 244, 214))
	l.add_theme_color_override("font_outline_color", Color8(74, 44, 32))
	l.add_theme_constant_override("outline_size", 12)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.size = Vector2(160, 60)
	l.z_index = 2
	var start := base_position + Vector2(-150, (_body_rect.position.y) * base_scale.y - 40)   # a bit to the left
	l.position = start
	l.modulate.a = 0.0
	l.scale = Vector2(0.6, 0.6)
	l.pivot_offset = l.size / 2.0
	get_parent().add_child(l)
	var t := create_tween()
	t.tween_property(l, "modulate:a", 1.0, 0.12)
	t.parallel().tween_property(l, "scale", Vector2.ONE, 0.25).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	t.parallel().tween_property(l, "position:y", start.y - 70.0, 1.3).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	t.tween_property(l, "modulate:a", 0.0, 0.35)
	t.tween_callback(l.queue_free)

func _play_evolve() -> void:
	_stop_all_tweens()
	scale = base_scale
	modulate = Color(1, 1, 1, 1)

	fx_tween = create_tween()
	# 1) nervous shake that speeds up
	var shake_time := 0.12
	for i in range(8):
		var dir := -1.0 if i % 2 == 0 else 1.0
		fx_tween.tween_property(self, "rotation", 0.08 * dir, shake_time)
		shake_time *= 0.85
	fx_tween.tween_property(self, "rotation", 0.0, 0.05)
	# 2) squash down + flash white
	fx_tween.tween_property(self, "scale", base_scale * Vector2(1.25, 0.7), 0.15)
	fx_tween.parallel().tween_property(self, "modulate", Color(4, 4, 4, 1), 0.15)
	# 3) swap to the new form at peak brightness
	fx_tween.tween_callback(func():
		sprite_frames = PetState.build_sprite_frames()
		play("idle")
		_refresh_accessory()
		_play_sfx("res://sounds/fx/gamecoin.wav", -6.0))
	# 4) spring back out
	fx_tween.tween_property(self, "scale", base_scale, 0.8).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)
	fx_tween.parallel().tween_property(self, "modulate", Color(1, 1, 1, 1), 0.5)
	await fx_tween.finished
	_start_breathing()

func play_flush() -> void:
	set_flush_charge(0.0)
	_stop_all_tweens()
	fx_tween = create_tween()
	fx_tween.tween_property(self, "rotation", TAU * 2.0, 0.9).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	fx_tween.parallel().tween_property(self, "scale", Vector2.ZERO, 0.9).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	fx_tween.parallel().tween_property(self, "position", base_position + Vector2(0, 160), 0.9).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	await fx_tween.finished
	modulate.a = 0.0
	rotation = 0.0
	position = base_position
	scale = base_scale

func set_flush_charge(value: float) -> void:
	flush_charge = value
	if value <= 0.0:
		rotation = 0.0
		position = base_position

# ------------------------------------------------------------------ MYSTERY "?" (no poop yet)

func _spawn_mystery() -> void:
	mystery = Sprite2D.new()
	mystery.texture = load("res://textures/menus/eat_pink.png")
	mystery.scale = Vector2(MYSTERY_SCALE, MYSTERY_SCALE)
	mystery.position = base_position + body_offset
	get_parent().add_child(mystery)
	get_parent().move_child(mystery, get_index() + 1)
	mystery.visible = false
	if not PetState.has_poop():
		_show_mystery()

func _show_mystery() -> void:
	if not mystery:
		return
	mystery.visible = true
	mystery.modulate.a = 0.0
	mystery.position = base_position + body_offset
	if mystery_tween:
		mystery_tween.kill()
	mystery_tween = create_tween()
	mystery_tween.tween_property(mystery, "modulate:a", 1.0, 0.4)
	var bob = create_tween().set_loops()
	bob.tween_property(mystery, "position:y", base_position.y + body_offset.y - 18, 0.9).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	bob.tween_property(mystery, "position:y", base_position.y + body_offset.y, 0.9).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	mystery.set_meta("bob", bob)

func _hide_mystery() -> void:
	if not mystery or not mystery.visible:
		return
	if mystery.has_meta("bob"):
		(mystery.get_meta("bob") as Tween).kill()
	if mystery_tween:
		mystery_tween.kill()
	mystery_tween = create_tween()
	mystery_tween.tween_property(mystery, "scale", Vector2(MYSTERY_SCALE, MYSTERY_SCALE) * 1.4, 0.1)
	mystery_tween.parallel().tween_property(mystery, "modulate:a", 0.0, 0.15)
	mystery_tween.tween_callback(func():
		mystery.visible = false
		mystery.scale = Vector2(MYSTERY_SCALE, MYSTERY_SCALE))

func _play_sfx(path: String, volume_db: float, pitch := 1.0) -> void:
	var stream = load(path) as AudioStream
	if not stream:
		return
	var sfx = AudioStreamPlayer.new()
	sfx.stream = stream
	sfx.volume_db = volume_db
	sfx.pitch_scale = pitch
	var sound_btn = get_node_or_null("/root/PoopPal/Main UI/SoundButtons/SoundButton")
	if sound_btn and sound_btn.button_pressed:
		sfx.volume_db = linear_to_db(0.0)
	add_child(sfx)
	sfx.play()
	sfx.finished.connect(sfx.queue_free)
