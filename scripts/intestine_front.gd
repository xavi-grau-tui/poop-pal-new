extends Sprite2D

## Gut decor (Collection): overlays drawn on intestine-front's own canvas, so as children
## they breathe with it. Frames are cycled for the twinkle.
const DECOR_FRAME_TIME := 0.6

var decor: Sprite2D
var _decor_frames: Array[Texture2D] = []
var _decor_frame := 0
var _decor_timer: Timer

func _ready():
	scale = Vector2(1.0, 1.0)  # Make sure it starts from the base scale

	decor = Sprite2D.new()
	decor.name = "Decor"
	add_child(decor)
	_decor_timer = Timer.new()
	_decor_timer.wait_time = DECOR_FRAME_TIME
	_decor_timer.timeout.connect(_next_decor_frame)
	add_child(_decor_timer)
	Collection.equipped_changed.connect(func(category, _id):
		if category == "decor":
			_apply_decor())
	_apply_decor()

	# Wait a short moment before starting tween (avoids visible jump)
	await get_tree().create_timer(0.2).timeout

	var tween = create_tween()
	tween.tween_property(self, "scale", Vector2(1.02, 0.98), 1.0).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(self, "scale", Vector2(1.0, 1.0), 1.0).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.set_loops()

func _apply_decor() -> void:
	_decor_frames.clear()
	for path in Collection.DECOR.get(Collection.equipped_decor, {}).get("frames", []):
		_decor_frames.append(load(path))
	_decor_frame = 0
	decor.texture = _decor_frames[0] if not _decor_frames.is_empty() else null
	if _decor_frames.size() > 1:
		_decor_timer.start()
	else:
		_decor_timer.stop()

func _next_decor_frame() -> void:
	if _decor_frames.is_empty():
		return
	_decor_frame = (_decor_frame + 1) % _decor_frames.size()
	decor.texture = _decor_frames[_decor_frame]
