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

var mystery: Sprite2D
var mystery_tween: Tween
var flush_charge := 0.0
var _time := 0.0

func _ready():
	base_scale = scale
	base_position = position
	_spawn_mystery.call_deferred()
	PetState.form_changed.connect(_on_form_changed)

	if PetState.has_poop():
		sprite_frames = PetState.build_sprite_frames()
		play("idle")
		_start_breathing()
	else:
		modulate.a = 0.0

func _process(delta: float) -> void:
	_time += delta
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
	scale = Vector2.ZERO
	modulate = Color(1, 1, 1, 1)
	fx_tween = create_tween()
	fx_tween.tween_property(self, "scale", base_scale, 0.7).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)
	_play_sfx("res://sounds/fx/gamecoin.wav", -8.0)
	await fx_tween.finished
	_start_breathing()

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
	mystery.texture = load("res://textures/menus/mistery_pink.png")
	mystery.scale = Vector2(0.9, 0.9)
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
	mystery_tween.tween_property(mystery, "scale", Vector2(1.3, 1.3), 0.1)
	mystery_tween.parallel().tween_property(mystery, "modulate:a", 0.0, 0.15)
	mystery_tween.tween_callback(func():
		mystery.visible = false
		mystery.scale = Vector2(0.9, 0.9))

func _play_sfx(path: String, volume_db: float) -> void:
	var stream = load(path) as AudioStream
	if not stream:
		return
	var sfx = AudioStreamPlayer.new()
	sfx.stream = stream
	sfx.volume_db = volume_db
	var sound_btn = get_node_or_null("/root/PoopPal/Main UI/SoundButtons/SoundButton")
	if sound_btn and sound_btn.button_pressed:
		sfx.volume_db = linear_to_db(0.0)
	add_child(sfx)
	sfx.play()
	sfx.finished.connect(sfx.queue_free)
