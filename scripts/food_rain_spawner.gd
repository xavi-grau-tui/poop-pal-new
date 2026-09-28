# FoodRainSpawner.gd
extends Node2D
class_name FoodRainSpawner

static var is_locked := false

@export var chunk_scene     : PackedScene
@export var fall_area_width := 300
@export var fall_duration   : float = 0.8
@export var chunk_scale     : float = 1.4
@export var fall_sound      : AudioStreamPlayer2D

func spawn_food_chunks(texture: Texture2D) -> void:
	if is_locked or chunk_scene == null:
		return
	is_locked = true

	if fall_sound:
		fall_sound.play()

	var chunk_size  = texture.get_size() / 3.0
	var chunk_index = 0

	for y in range(3):
		for x in range(3):
			var chunk = chunk_scene.instantiate()
			var region = Rect2(
				(Vector2(x, y) * chunk_size).floor(),
				chunk_size.floor()
			)
			chunk.set_texture_region(texture, region)
			chunk.position = Vector2(
				randf_range(-fall_area_width/2, fall_area_width/2),
				-50
			)
			chunk.scale = Vector2(chunk_scale, chunk_scale)
			add_child(chunk)

			await get_tree().create_timer(0.07 * chunk_index).timeout
			chunk.fall_to(Vector2(chunk.position.x, 300), fall_duration)
			chunk_index += 1

	# wait until all have fallen
	await get_tree().create_timer(fall_duration).timeout

	# trigger intestine food‑blink
	var intestines = get_node_or_null("../Intestine-back")
	if intestines and intestines.has_method("play_blink_effect_food"):
		await intestines.play_blink_effect_food()

	is_locked = false
