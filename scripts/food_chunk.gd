extends Sprite2D

var fall_tween: Tween

func set_texture_region(texture: Texture2D, region: Rect2):
	self.texture = texture
	self.region_enabled = true
	self.region_rect = region

func fall_to(destination: Vector2, duration: float):
	fall_tween = create_tween()
	fall_tween.tween_property(self, "position", destination, duration).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	fall_tween.tween_callback(Callable(self, "queue_free"))
