extends BaseMinigame
## Super Puff — hold to float, release to sink, dodge obstacles.
## Uses placeholder ColorRects until real art is added.

var player: AnimatedSprite2D
var breathing_tween: Tween
var player_vy := 0.0
var is_holding := false

var obstacles: Array[Dictionary] = []
var obstacle_timer := 0.0
var obstacle_interval := 1.7
var scroll_speed := 250.0

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
	_spawn_obstacles(delta)
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

	# Random gap position, clamped well within bounds
	var gap_size := 200.0
	var min_y := PLAY_TOP + 80.0
	var max_y := PLAY_BOTTOM - gap_size - 80.0
	var gap_y := randf_range(min_y, max_y)

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

	# Gradually increase difficulty
	obstacle_interval = maxf(1.0, obstacle_interval - 0.02)
	scroll_speed = minf(400.0, scroll_speed + 2.0)

func _update_obstacles(delta: float) -> void:
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
			end_game()
			return

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
