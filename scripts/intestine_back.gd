# Intestine-back.gd
extends Sprite2D

# — EXPORTS —
@export var blink_opacity     : float                   = 0.3

# Food‑specific
@export var food_blink_loops    : int    = 5
@export var food_blink_duration : float  = 0.15
@export var food_delay          : float  = 0.0
@export var food_sound_time     : float  = 1.0
@export var food_sound          : AudioStreamPlayer2D

# Drink‑specific
@export var drink_blink_loops    : int    = 5
@export var drink_blink_duration : float  = 0.15
@export var drink_delay          : float  = 0.0
@export var drink_sound_time     : float  = 1.0
@export var drink_sound          : AudioStreamPlayer2D

# Poop blink — food
@export var poop_blink_delay_food    : float = 1.0
@export var poop_blink_times_food    : int   = 30
@export var poop_blink_opacity_food  : float = 0.2
@export var poop_blink_speed_food    : float = 0.5

# Poop blink — drink
@export var poop_blink_delay_drink   : float = 1.0
@export var poop_blink_times_drink   : int   = 10
@export var poop_blink_opacity_drink : float = 0.1
@export var poop_blink_speed_drink   : float = 0.7

# — INTERNAL TWEENS —
var _idle_tween  : Tween
var _blink_tween : Tween

func _ready() -> void:
	_start_idle_breathing()

func _start_idle_breathing() -> void:
	_idle_tween = create_tween()
	_idle_tween.tween_property(self, "scale", Vector2(1.015,0.985), 1.5) \
			   .set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	_idle_tween.tween_property(self, "scale", Vector2(1,1),       1.5) \
			   .set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	_idle_tween.set_loops()

# — FOOD FLOW —
func play_blink_effect_food() -> void:
	if food_delay > 0.0:
		await get_tree().create_timer(food_delay).timeout
	if food_sound:
		food_sound.play()

	if _idle_tween:
		_idle_tween.kill()
	_blink_tween = create_tween()
	for i in range(food_blink_loops):
		_blink_tween.tween_property(self, "modulate:a", blink_opacity, food_blink_duration)
		_blink_tween.tween_property(self, "modulate:a", 1.0,         food_blink_duration)

	# poop blink for food
	await get_tree().create_timer(poop_blink_delay_food).timeout
	var poop = get_node_or_null("../Poop")
	if poop and poop.has_method("blink"):
		poop.blink(poop_blink_times_food, poop_blink_opacity_food, poop_blink_speed_food)

	await _blink_tween.finished

	if food_sound:
		await get_tree().create_timer(food_sound_time).timeout
		food_sound.stop()

	_start_idle_breathing()

# — DRINK FLOW —
func play_blink_effect_drink() -> void:
	if drink_delay > 0.0:
		await get_tree().create_timer(drink_delay).timeout
	if drink_sound:
		drink_sound.play()

	if _idle_tween:
		_idle_tween.kill()
	_blink_tween = create_tween()
	for i in range(drink_blink_loops):
		_blink_tween.tween_property(self, "modulate:a", blink_opacity, drink_blink_duration)
		_blink_tween.tween_property(self, "modulate:a", 1.0,          drink_blink_duration)

	# poop blink for drink
	await get_tree().create_timer(poop_blink_delay_drink).timeout
	var poop = get_node_or_null("../Poop")
	if poop and poop.has_method("blink"):
		poop.blink(poop_blink_times_drink, poop_blink_opacity_drink, poop_blink_speed_drink)

	await _blink_tween.finished

	if drink_sound:
		await get_tree().create_timer(drink_sound_time).timeout
		drink_sound.stop()

	_start_idle_breathing()
