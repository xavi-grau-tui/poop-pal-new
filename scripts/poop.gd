# Poop.gd
extends AnimatedSprite2D

@export var blink_times := 6
@export var initial_blink_speed := 0.15
@export var blink_opacity := 0.0
@export var breathing_amount := Vector2(0.03, -0.03)
@export var breathing_time := 1.5

var blink_tween: Tween
var breathing_tween: Tween
var base_scale := Vector2.ONE

func _ready():
	play()
	base_scale = scale
	_start_breathing()

func _start_breathing():
	breathing_tween = create_tween()
	breathing_tween.tween_property(self, "scale", base_scale + breathing_amount, breathing_time) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	breathing_tween.tween_property(self, "scale", base_scale, breathing_time) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	breathing_tween.set_loops()

func blink(custom_times := -1, custom_opacity := -1.0, custom_speed := -1.0):
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
