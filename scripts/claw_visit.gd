extends Control
## The LUCKY PINCH claw visiting the pet cam: it comes down from the top of the cam window
## holding a glowing capsule, dangles over the pal for a moment (the LCD shows BONUS!), and
## goes back up. Clipped to the cam window, so the cable seems to come from above it.

const CAP_AT := Vector2(13, 19.1)               # (claw pixels) the capsule's centre in visit_claw.png
const CLAW_BOTTOM := 25.0                        # (claw pixels) the tips' bottom
const WINDOW := Rect2(-215, -112, 430, 356)     # the pet cam window, around the pal's spot
const DANGLE_TIME := 2.6

var rig: Node2D
var capsule: Sprite2D
var S := 5.3                                     # one claw pixel = one pal pixel (set in play)

func play(poop: Node2D) -> void:
	var base: Vector2 = poop.get("base_position") if poop.get("base_position") != null else poop.position
	position = base + WINDOW.position
	size = WINDOW.size
	clip_contents = true
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	# where the pal's head is (its visible body top), in this window's coords
	var body: Rect2 = poop.get("_body_rect") if poop.get("_body_rect") != null else Rect2(-30, 0, 60, 50)
	var head_y := -WINDOW.position.y + body.position.y * poop.scale.y
	# painted on the pals' own grid (their art pixel is 2 texture px), so it matches the pal
	S = 2.0 * absf(poop.get("base_scale").x if poop.get("base_scale") != null else poop.scale.x)
	rig = Node2D.new()
	rig.position = Vector2(size.x / 2.0, -120)
	add_child(rig)
	# the cable: one pal pixel of steel with the pals' dark outline on both sides
	var cable_ink := ColorRect.new()
	cable_ink.color = Color8(34, 20, 22)
	cable_ink.position = Vector2(-1.5 * S, -600)
	cable_ink.size = Vector2(3 * S, 600 + S)
	rig.add_child(cable_ink)
	var cable := ColorRect.new()
	cable.color = Color8(178, 176, 198)
	cable.position = Vector2(-0.5 * S, -600)
	cable.size = Vector2(S, 600 + S)
	rig.add_child(cable)
	capsule = _sprite("res://textures/minigames/pinch/visit_capsule.png")
	var claw := _sprite("res://textures/minigames/pinch/visit_claw.png")
	claw.centered = false
	claw.position = Vector2(-claw.texture.get_width() * S / 2.0, 0)
	capsule.position = claw.position + CAP_AT * S
	rig.add_child(capsule)
	rig.add_child(claw)
	# the capsule glows: a soft pulse and a few sparkles
	var glow := capsule.create_tween().set_loops()
	glow.tween_property(capsule, "modulate", Color(1.35, 1.3, 1.0), 0.35)
	glow.tween_property(capsule, "modulate", Color.WHITE, 0.35)
	var stop_y := head_y - 24.0 - CLAW_BOTTOM * S      # the claw's tips ~24px above the head
	_motor(0.9)
	var t := create_tween()
	t.tween_property(rig, "position:y", stop_y, 0.9).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	t.tween_callback(_arrived.bind(poop))
	for i in 4:
		t.tween_property(rig, "rotation", 0.1, DANGLE_TIME / 8.0).set_trans(Tween.TRANS_SINE)
		t.tween_property(rig, "rotation", -0.1, DANGLE_TIME / 8.0).set_trans(Tween.TRANS_SINE)
	t.tween_property(rig, "rotation", 0.0, 0.15)
	t.tween_callback(_motor.bind(0.8))
	t.tween_property(rig, "position:y", -160.0, 0.8).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	t.tween_callback(queue_free)

func _arrived(poop: Node2D) -> void:
	var lcd := get_node_or_null("/root/PoopPal/Main UI/LCD Screen")
	if lcd and lcd.has_method("show_message"):
		lcd.show_message("BONUS!")
		lcd._ding()
	if poop and poop.has_method("_say") and PetState.has_poop():
		poop._say("!?", "res://sounds/fx/giggle_short.wav")
	for i in 6:
		get_tree().create_timer(0.25 * i).timeout.connect(_sparkle)

func _sparkle() -> void:
	if not is_instance_valid(capsule):
		return
	var s := ColorRect.new()
	s.color = Color8(255, 236, 150)
	s.size = Vector2(6, 6)
	s.position = rig.position + capsule.position + Vector2(randf_range(-40, 34), randf_range(-30, 30))
	add_child(s)
	var t := s.create_tween()
	t.tween_property(s, "position:y", s.position.y - 24, 0.5)
	t.parallel().tween_property(s, "modulate:a", 0.0, 0.5)
	t.tween_callback(s.queue_free)

func _motor(secs: float) -> void:
	var sfx := AudioStreamPlayer.new()
	sfx.stream = load("res://sounds/fx/Retro-Vehicle-Motor-02.mp3")
	sfx.volume_db = -20.0
	sfx.pitch_scale = 1.6
	add_child(sfx)
	sfx.play()
	var t := sfx.create_tween()
	t.tween_interval(secs)
	t.tween_callback(sfx.queue_free)

func _sprite(path: String) -> Sprite2D:
	var s := Sprite2D.new()
	s.texture = load(path)
	s.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	s.scale = Vector2(S, S)
	return s
