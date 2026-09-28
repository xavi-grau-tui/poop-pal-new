extends ParallaxBackground

@export var scroll_speed := Vector2(30, 0)  # Try 30–100 to start

func _process(delta):
	scroll_offset += scroll_speed * delta
