extends BaseMinigame
## Pipe Dream (was Super Puff) — hold to float, release to sink, dodge the pipes.
## Uses placeholder ColorRects until real art is added.

var player: AnimatedSprite2D
var breathing_tween: Tween
var player_vy := 0.0
var is_holding := false

var obstacles: Array[Dictionary] = []
var obstacle_timer := 0.0
var obstacle_interval := 2.3
var scroll_speed := 210.0
var last_gap_center := -1.0

# Progression in two phases, so high scores stay rare (they will unlock rare items):
#   0 -> HARD_AT      calm start to 'hard'   (spacing, speed, gap size, gap jump)
#   HARD_AT -> EXPERT_AT   'hard' to 'expert': pipes closer, gaps smaller and further apart
# Every value stays passable: the pal climbs/falls at most 400 px/s, and the expert gap
# jump can be covered in the time between two pipes.
const HARD_AT := 30.0
const EXPERT_AT := 90.0
const INTERVAL := Vector3(2.3, 1.25, 1.0)       # seconds between pipes (start, hard, expert)
const SPEED := Vector3(210.0, 380.0, 400.0)     # scroll speed (pipe spacing 483 -> 475 -> 400 px)
const GAP := Vector3(270.0, 195.0, 170.0)       # gap height
const GAP_JUMP := Vector3(110.0, 300.0, 300.0)  # max move of the gap centre between pipes

# Drink boost "splash" (water, a lasting status): hitting a pipe the first time makes the
# pal go "boing" and the view roll back a bit, for a second try at that same gap.
# Hitting the same pipe again is game over.
var splash_ready := false
var invuln := 0.0
var boost_icon: Sprite2D
var world_shift := 0.0          # tweened during the roll-back
var _shift_applied := 0.0
var rewinding := false

var score_label: Label
var score_bg: ColorRect

# Player config
const FLOAT_FORCE := -700.0
const GRAVITY := 500.0
# Hitbox smaller than PNG — offset down since poop body is below sprite center
const PLAYER_SIZE := Vector2(75, 60)
const HITBOX_OFFSET := Vector2(0, 40)

# Visual size: every pal is scaled so its body matches the classic poo1 body.
# The hitbox above is fixed, so gameplay is identical whichever pal is playing.
const PLAYER_SCALE := 1.4
const CLASSIC_BODY := Vector2(76, 69)  # poo1 opaque bounds inside its 232x196 texture
const CLASSIC_BOTTOM := 55.0          # poo1 body bottom, relative to texture centre

# Toggle to see the hitbox in-game
const DEBUG_HITBOX := false

# Center of play area in GameContainer local coords
const CENTER_X := 166.0  # slightly left of center for reaction time
const CENTER_Y := 474.0  # vertical center of play area

func _ready() -> void:
	pipe_cap_texture = load("res://textures/minigames/pipe_cap.png")
	pipe_body_texture = load("res://textures/minigames/pipe_body.png")
	cap_height = 65.0  # forced cap height regardless of texture size
	
	# Set game-specific music
	game_music_path = "res://sounds/music/Soft Sky Glide.mp3"
	
	_create_player()
	_create_score_label()
	_setup_boost()
	super._ready()

func _create_clouds() -> void:
	# Load shader and textures
	var scroll_shader = load("res://scripts/shaders/scroll.gdshader") as Shader
	var scroll2_shader = load("res://scripts/shaders/scroll2.gdshader") as Shader
	var cloud_tex1 = load("res://textures/pet-background/clouds3.png") as Texture2D
	var cloud_tex2 = load("res://textures/pet-background/clouds2.png") as Texture2D
	
	if not scroll_shader or not cloud_tex1:
		return
	
	# CloudA - slower layer
	var cloud_a = Sprite2D.new()
	cloud_a.texture = cloud_tex1
	cloud_a.texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED
	cloud_a.z_index = -2
	cloud_a.centered = true
	cloud_a.position = Vector2(PLAY_WIDTH / 2, PLAY_HEIGHT / 2)
	cloud_a.scale = Vector2(2.0, 2.0)
	
	var mat_a = ShaderMaterial.new()
	mat_a.shader = scroll_shader
	mat_a.set_shader_parameter("scroll_speed", 0.07)
	cloud_a.material = mat_a
	add_child(cloud_a)
	
	# CloudB - faster layer
	if scroll2_shader and cloud_tex2:
		var cloud_b = Sprite2D.new()
		cloud_b.texture = cloud_tex2
		cloud_b.texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED
		cloud_b.z_index = -1
		cloud_b.centered = true
		cloud_b.position = Vector2(PLAY_WIDTH / 2, PLAY_HEIGHT / 2)
		cloud_b.scale = Vector2(2.0, 2.0)
		
		var mat_b = ShaderMaterial.new()
		mat_b.shader = scroll2_shader
		mat_b.set_shader_parameter("scroll_speed", 0.14)
		cloud_b.material = mat_b
		add_child(cloud_b)

func _make_pipe(pos: Vector2, sz: Vector2, cap_on_top: bool) -> Node2D:
	var container = Node2D.new()
	container.position = pos

	if pipe_body_texture and pipe_cap_texture:
		# Body — stretches to fill pipe minus cap
		var body_h := sz.y - cap_height
		if body_h > 0:
			var body = Sprite2D.new()
			body.texture = pipe_body_texture
			body.centered = false
			# Scale to match pipe width and body height
			var tex_w := float(pipe_body_texture.get_width())
			var tex_h := float(pipe_body_texture.get_height())
			body.scale = Vector2(sz.x / tex_w, body_h / tex_h)
			if cap_on_top:
				body.position = Vector2(0, cap_height)
			else:
				body.position = Vector2(0, 0)
			container.add_child(body)

		# Cap — fixed height, scaled to pipe width
		var cap = Sprite2D.new()
		cap.texture = pipe_cap_texture
		cap.centered = false
		var cap_tex_w := float(pipe_cap_texture.get_width())
		var cap_tex_h := float(pipe_cap_texture.get_height())
		cap.scale = Vector2(sz.x / cap_tex_w, cap_height / cap_tex_h)
		if cap_on_top:
			# Bottom pipe — cap at top, facing up (normal orientation)
			cap.position = Vector2(0, 0)
		else:
			# Top pipe — cap at bottom, facing down (flip vertically)
			cap.flip_v = true
			cap.position = Vector2(0, sz.y - cap_height)
		container.add_child(cap)
	else:
		# Fallback to colored rect
		var rect = ColorRect.new()
		rect.color = Color(0.9, 0.88, 0.85)
		rect.position = Vector2.ZERO
		rect.size = sz
		container.add_child(rect)

	# Store size for collision
	container.set_meta("size", sz)
	return container

func _create_background() -> void:
	var bg = ColorRect.new()
	bg.color = Color(0.4, 0.7, 0.85)  # water blue color
	bg.position = Vector2(PLAY_LEFT, PLAY_TOP)
	bg.size = Vector2(PLAY_RIGHT - PLAY_LEFT, PLAY_BOTTOM - PLAY_TOP)
	bg.z_index = -10
	add_child(bg)

func _create_player() -> void:
	player = AnimatedSprite2D.new()
	# Play as the current pal; fall back to the classic poop before the first meal
	var frames: SpriteFrames = PetState.build_sprite_frames() if PetState.has_poop() else null
	var fit := 1.0
	if frames:
		fit = _fit_to_classic_size(frames.get_frame_texture("idle", 0))
	else:
		frames = SpriteFrames.new()
		frames.add_animation("idle")
		frames.set_animation_speed("idle", 1.0)
		frames.set_animation_loop("idle", true)
		var tex1 = load("res://textures/pet/poo1-1.png")
		var tex2 = load("res://textures/pet/poo1-2.png")
		if tex1:
			frames.add_frame("idle", tex1)
		if tex2:
			frames.add_frame("idle", tex2)
	player.sprite_frames = frames
	player.play("idle")
	player.scale = Vector2(PLAYER_SCALE, PLAYER_SCALE) * fit
	# Keep the body's bottom where poo1's is, so the (unchanged) hitbox still lines up
	player.offset = Vector2(0, CLASSIC_BOTTOM * (1.0 / fit - 1.0))
	player.z_index = 0  # default, game over overlay renders on top by add order
	player.position = Vector2(CENTER_X, CENTER_Y)
	add_child(player)
	_start_breathing()

func _fit_to_classic_size(tex: Texture2D) -> float:
	if not tex:
		return 1.0
	var img := tex.get_image()
	if not img:
		return 1.0
	var used := img.get_used_rect()
	if used.size.x <= 0 or used.size.y <= 0:
		return 1.0
	return minf(CLASSIC_BODY.x / used.size.x, CLASSIC_BODY.y / used.size.y)

func _start_breathing() -> void:
	var base_scale := player.scale
	breathing_tween = create_tween()
	breathing_tween.tween_property(player, "scale", base_scale + Vector2(0.03, -0.03), 1.5) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	breathing_tween.tween_property(player, "scale", base_scale, 1.5) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	breathing_tween.set_loops()

func _create_score_label() -> void:
	# Black frame
	var frame = ColorRect.new()
	frame.color = Color(0, 0, 0)
	frame.position = Vector2(PLAY_LEFT + 795, PLAY_TOP + 45)
	frame.size = Vector2(110, 70)
	add_child(frame)
	
	# Background square matching LCD screen background (darker)
	score_bg = ColorRect.new()
	score_bg.color = Color(0.65, 0.72, 0.6)  # darker LCD green
	score_bg.position = Vector2(PLAY_LEFT + 800, PLAY_TOP + 50)
	score_bg.size = Vector2(100, 60)  # sized for 3 digits
	add_child(score_bg)
	
	# Score label with LCD font - right-aligned in box
	score_label = Label.new()
	score_label.position = Vector2(PLAY_LEFT + 810, PLAY_TOP + 50)
	score_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	score_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	score_label.size = Vector2(80, 60)
	var lcd_font = load("res://fonts/pixChicago.ttf")
	if lcd_font:
		score_label.add_theme_font_override("font", lcd_font)
	score_label.add_theme_font_size_override("font_size", 36)
	score_label.add_theme_color_override("font_color", Color(0.2, 0.15, 0.05, 1))
	score_label.text = "0"
	add_child(score_label)

func _process(delta: float) -> void:
	if not is_running:
		return

	_update_player(delta)
	_update_obstacles(delta)
	if not rewinding:
		_spawn_obstacles(delta)
	if invuln > 0.0:
		invuln -= delta
		player.modulate.a = 0.35 if int(invuln * 14.0) % 2 == 0 else 1.0
		if invuln <= 0.0:
			player.modulate.a = 1.0
	else:
		_check_collisions()
	score_label.text = str(score)
	if DEBUG_HITBOX:
		queue_redraw()

# --- Player movement ---

func _update_player(delta: float) -> void:
	if is_holding:
		player_vy += FLOAT_FORCE * delta
	else:
		player_vy += GRAVITY * delta

	player_vy = clampf(player_vy, -400.0, 400.0)
	player.position.y += player_vy * delta

	# Clamp to play area using visual sprite size (not hitbox)
	# Use smaller factor since PNG has transparent padding around the poop
	var visual_half_h := 196.0 * PLAYER_SCALE * 0.28
	if player.position.y - visual_half_h < PLAY_TOP:
		player.position.y = PLAY_TOP + visual_half_h
		player_vy = 0
	if player.position.y + visual_half_h > PLAY_BOTTOM:
		player.position.y = PLAY_BOTTOM - visual_half_h
		player_vy = 0

# --- Obstacles ---

# Pipe textures — replace with your own PNGs
# pipe_cap: the fixed-size tip/lip at the opening (faces the gap)
# pipe_body: the shaft that stretches to fill the rest
var pipe_cap_texture: Texture2D = null
var pipe_body_texture: Texture2D = null
var cap_height := 40.0  # height of the cap in pixels

func _spawn_obstacles(delta: float) -> void:
	obstacle_timer += delta
	if obstacle_timer < obstacle_interval:
		return
	obstacle_timer = 0.0

	# How far into the run we are
	var gap_size := _phase(GAP)
	var min_c := PLAY_TOP + 80.0 + gap_size / 2.0
	var max_c := PLAY_BOTTOM - 80.0 - gap_size / 2.0
	if last_gap_center < 0.0:
		last_gap_center = player.position.y + HITBOX_OFFSET.y     # first gap: where the pal is
	var jump := _phase(GAP_JUMP)
	var centre := clampf(last_gap_center + randf_range(-jump, jump), min_c, max_c)
	last_gap_center = centre
	var gap_y := centre - gap_size / 2.0

	var pipe_width := 90.0
	# Spawn just outside the right edge — clipping hides the overflow
	var spawn_x := PLAY_RIGHT

	# Top pipe — cap faces down (at bottom, toward gap)
	var top_h := gap_y - PLAY_TOP
	var top = _make_pipe(Vector2(spawn_x, PLAY_TOP), Vector2(pipe_width, top_h), false)
	add_child(top)
	move_child(top, player.get_index())  # insert before player

	# Bottom pipe — cap faces up (at top, toward gap)
	var bot_h := PLAY_BOTTOM - (gap_y + gap_size)
	var bottom = _make_pipe(Vector2(spawn_x, gap_y + gap_size), Vector2(pipe_width, bot_h), true)
	add_child(bottom)
	move_child(bottom, player.get_index())  # insert before player

	obstacles.append({
		"top": top,
		"bottom": bottom,
		"scored": false,
		"width": pipe_width
	})

	# Next pipe: a little closer and faster as the score climbs
	obstacle_interval = _phase(INTERVAL)
	scroll_speed = _phase(SPEED)

## start -> hard over the first HARD_AT points, then hard -> expert until EXPERT_AT
func _phase(v: Vector3) -> float:
	if score <= HARD_AT:
		return lerpf(v.x, v.y, score / HARD_AT)
	return lerpf(v.y, v.z, clampf((score - HARD_AT) / (EXPERT_AT - HARD_AT), 0.0, 1.0))

func _update_obstacles(delta: float) -> void:
	if rewinding:
		var ds := world_shift - _shift_applied
		_shift_applied = world_shift
		for o in obstacles:
			o["top"].position.x += ds
			o["bottom"].position.x += ds
		return
	var to_remove := []
	for i in range(obstacles.size()):
		var obs = obstacles[i]
		var top: Node2D = obs["top"]
		var bottom: Node2D = obs["bottom"]

		top.position.x -= scroll_speed * delta
		bottom.position.x -= scroll_speed * delta

		# Score when obstacle passes the player
		if not obs["scored"] and top.position.x + obs["width"] < player.position.x:
			obs["scored"] = true
			add_score(1)

		# Remove when off screen left
		if top.position.x + obs["width"] < PLAY_LEFT - 50:
			to_remove.append(i)

	for i in range(to_remove.size() - 1, -1, -1):
		var obs = obstacles[to_remove[i]]
		obs["top"].queue_free()
		obs["bottom"].queue_free()
		obstacles.remove_at(to_remove[i])

# --- Collision ---

func _get_player_hitbox() -> Rect2:
	var half := PLAYER_SIZE * 0.5
	var center := player.position + HITBOX_OFFSET
	return Rect2(center - half, PLAYER_SIZE)

func _check_collisions() -> void:
	var player_rect := _get_player_hitbox()

	for obs in obstacles:
		var top: Node2D = obs["top"]
		var bottom: Node2D = obs["bottom"]
		var top_sz: Vector2 = top.get_meta("size")
		var bot_sz: Vector2 = bottom.get_meta("size")
		var top_rect := Rect2(top.position, top_sz)
		var bottom_rect := Rect2(bottom.position, bot_sz)

		if player_rect.intersects(top_rect) or player_rect.intersects(bottom_rect):
			if splash_ready and not obs.get("bounced", false):
				obs["bounced"] = true
				_splash(top.position.x, player_rect)
				return
			end_game()
			return

# --- Drink boost: splash ---

func _setup_boost() -> void:
	splash_ready = PetState.boost == "splash"
	boost_icon = Sprite2D.new()
	boost_icon.texture = PetState.boost_icon("splash")
	boost_icon.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	boost_icon.scale = Vector2(6, 6)
	boost_icon.position = Vector2(PLAY_LEFT + 760, PLAY_TOP + 80)   # next to the score box
	boost_icon.visible = splash_ready
	add_child(boost_icon)
	if splash_ready:
		var aura := BoostAura.new()
		player.add_child(aura)
		var tex := player.sprite_frames.get_frame_texture(player.animation, 0)
		var img := tex.get_image()
		var used := img.get_used_rect() if img else Rect2i(Vector2i.ZERO, tex.get_size())
		aura.setup("splash", Rect2(Vector2(used.position) - tex.get_size() / 2.0, used.size))
	if splash_ready:
		var t := boost_icon.create_tween().set_loops()
		t.tween_property(boost_icon, "position:y", boost_icon.position.y - 5, 0.6).set_trans(Tween.TRANS_SINE)
		t.tween_property(boost_icon, "position:y", boost_icon.position.y, 0.6).set_trans(Tween.TRANS_SINE)

## Boing: the pal squashes against the pipe and the view rolls back smoothly, so the same
## gap comes again. The status stays (it's water, not an extra life).
func _splash(pipe_x: float, player_rect: Rect2) -> void:
	var push := maxf(0.0, player_rect.end.x + 150.0 - pipe_x)
	rewinding = true
	world_shift = 0.0
	_shift_applied = 0.0
	var roll := create_tween()
	roll.tween_property(self, "world_shift", push, 0.45).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	roll.tween_callback(func():
		rewinding = false
		world_shift = 0.0
		_shift_applied = 0.0)
	player_vy = -120.0
	invuln = 0.8
	# boing: squash against the pipe, then spring back
	var base: Vector2 = player.get_meta("base_scale", player.scale)
	player.set_meta("base_scale", base)
	var b := create_tween()
	b.tween_property(player, "scale", base * Vector2(0.7, 1.25), 0.07)
	b.tween_property(player, "scale", base * Vector2(1.2, 0.85), 0.1)
	b.tween_property(player, "scale", base, 0.35).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)
	# the HUD drop pulses (the status stays)
	var t := create_tween()
	t.tween_property(boost_icon, "scale", Vector2(8.5, 8.5), 0.1)
	t.tween_property(boost_icon, "scale", Vector2(6, 6), 0.25).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	# BOING! text + droplets
	var l := Label.new()
	l.text = "BOING!"
	var f = load("res://fonts/pixChicago.ttf")
	if f:
		l.add_theme_font_override("font", f)
	l.add_theme_font_size_override("font_size", 40)
	l.add_theme_color_override("font_color", Color8(200, 232, 250))
	l.add_theme_color_override("font_outline_color", Color8(46, 40, 60))
	l.add_theme_constant_override("outline_size", 10)
	l.position = player.position + Vector2(-80, -130)
	add_child(l)
	var lt := create_tween()
	lt.tween_property(l, "position:y", l.position.y - 50, 0.7)
	lt.parallel().tween_property(l, "modulate:a", 0.0, 0.7)
	lt.tween_callback(l.queue_free)
	for i in 6:
		var dr := ColorRect.new()
		dr.color = Color8(160, 210, 245)
		dr.size = Vector2(10, 10)
		dr.position = player.position + Vector2(20, 20)
		add_child(dr)
		var dir := Vector2.from_angle(-PI * 0.2 - i * PI * 0.12) * 90.0
		var dt := create_tween()
		dt.tween_property(dr, "position", dr.position + dir, 0.35)
		dt.parallel().tween_property(dr, "modulate:a", 0.0, 0.35)
		dt.tween_callback(dr.queue_free)
	var sfx := AudioStreamPlayer.new()
	sfx.stream = load("res://sounds/fx/underwater-247531.mp3")
	sfx.volume_db = -10.0
	add_child(sfx)
	sfx.play()
	get_tree().create_timer(0.5).timeout.connect(func():
		if is_instance_valid(sfx):
			sfx.queue_free())

# --- Input hooks ---

func on_main_button_pressed() -> void:
	if is_game_over:
		super.on_main_button_pressed()
		return
	is_holding = true

func on_main_button_released() -> void:
	if is_game_over:
		return
	is_holding = false

func on_forward_button_pressed() -> void:
	if is_game_over:
		super.on_forward_button_pressed()
		return
	# Future: activate drink ability
	pass

func end_game() -> void:
	if breathing_tween:
		breathing_tween.kill()
		breathing_tween = null
	if player:
		player.stop()
	is_holding = false
	# Base handles error sound, game over UI, and score reporting
	super.end_game()

func _draw() -> void:
	if DEBUG_HITBOX and player:
		var rect := _get_player_hitbox()
		draw_rect(rect, Color(1, 0, 0, 0.4))
