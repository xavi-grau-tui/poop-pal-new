extends Sprite2D

func _ready():
	scale = Vector2(1.0, 1.0)  # Make sure it starts from the base scale

	# Wait a short moment before starting tween (avoids visible jump)
	await get_tree().create_timer(0.2).timeout

	var tween = create_tween()
	tween.tween_property(self, "scale", Vector2(1.02, 0.98), 1.0).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(self, "scale", Vector2(1.0, 1.0), 1.0).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.set_loops()
