extends Node2D
class_name DrinkWaterfallSpawner

static var is_locked := false

@export var stream_scene  : PackedScene
@export var stream_color  : Color = Color.CYAN
@export var fall_duration : float = 0.6
@export var hold_time     : float = 2.0
@export var fade_time     : float = 0.25
@export var fall_sound    : AudioStreamPlayer2D

func spawn_drink_stream() -> void:
	if is_locked or stream_scene == null:
		return
	is_locked = true

	# 1) instantiate and tint
	var stream = stream_scene.instantiate() as DrinkWaterfall
	stream.position = Vector2(0, -120)
	add_child(stream)

	print("Sending color to stream:", stream_color)
	stream.setup(stream_color)
	print("🎨 Final color to apply:", stream_color)

	# 2) play splash sound
	if fall_sound:
		fall_sound.play()

	# 3) fade-in + fall → hold → fade-out
	var end_pos = Vector2(0, 300)
	var tw = create_tween()

	# fade in
	tw.tween_property(stream, "modulate:a", 1.0, fade_time)

	# fall
	tw.parallel().tween_property(stream, "position", end_pos, fall_duration)\
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)

	# hold
	tw.tween_interval(hold_time)

	# --- Fade out both Body and Foam independently ---
	var body = stream.get_node_or_null("Body")
	var foam = stream.get_node_or_null("Foam")

	if body:
		tw.tween_property(body, "modulate:a", 0.0, fade_time) \
			.set_trans(Tween.TRANS_QUINT).set_ease(Tween.EASE_OUT)

	if foam:
		tw.parallel().tween_property(foam, "modulate:a", 0.0, fade_time + 0.00) \
			.set_trans(Tween.TRANS_QUINT).set_ease(Tween.EASE_OUT)

	# optional callback when fade completes
	tw.tween_callback(stream.queue_free)

	await tw.finished

	# 4) trigger intestine blink
	var intestines = get_node_or_null("../Intestine-back")
	if intestines and intestines.has_method("play_blink_effect_drink"):
		await intestines.play_blink_effect_drink()

	is_locked = false
