extends BaseMinigame
## Pal Dash — your pal runs on its own. Jump the holes and plungers, grab the golden corn,
## dash through flies. The run gets faster the further you go.
##
## Main button: JUMP (press again in the air for a double jump; release early = shorter jump).
## Forward button: DASH (a short, fast, invincible burst that smashes flies and plungers).
## Desktop: also Space / Up = jump, Right / Shift = dash.

const S := 3.0                          # world px per art pixel
const GROUND_Y := 852.0                 # top of the ground
const TILE := 48.0
const PLAYER_X := 230.0

# --- Movement ---
const GRAVITY := 3300.0
const JUMP_V := -1180.0
const DOUBLE_JUMP_V := -1020.0
const JUMP_CUT := 0.45                  # releasing early keeps this much of the upward speed
const COYOTE := 0.08
const SPEED_START := 400.0
const SPEED_MAX := 780.0
const SPEED_GAIN := 9.0                 # px/s gained per second
const DASH_TIME := 0.24
const DASH_MULT := 2.5
const DASH_COOLDOWN := 1.4

# --- Player body (hitbox around the feet) ---
const BODY_W := 70.0
const BODY_H := 62.0
const PAL_WIDTH := 128.0                # on-screen body width of the pal

const OUTLINE := Color8(74, 44, 32)
const SKY := Color8(236, 170, 170)

var speed := SPEED_START
var run_time := 0.0
var distance := 0.0
var _dist_points := 0.0

var py := GROUND_Y                      # player feet
var vy := 0.0
var on_ground := true
var air_time := 0.0
var jumps_left := 1                     # double jumps left
var jump_held := false
var dash_left := 0.0
var dash_cool := 0.0
var dash_used_in_air := false
var dead := false

var ground: Array[Dictionary] = []      # { x0, x1, node }
var things: Array[Dictionary] = []      # { kind, x, y, w, h, node, ... }
var next_x := 0.0
var rng := RandomNumberGenerator.new()

var tex := {}
var lcd_font: Font
var world: Node2D
var player: AnimatedSprite2D
var ghost_layer: Node2D
var score_label: Label
var dash_label: Label
var banner: Label
var _keys := {}

func _ready() -> void:
	game_music_path = "res://sounds/music/Pixel Dash.mp3"
	lcd_font = load("res://fonts/pixChicago.ttf")
	for n in ["ground_top", "ground", "plunger", "fly_1", "fly_2", "corn"]:
		tex[n] = load("res://textures/minigames/dash/%s.png" % n)
	_create_static_nodes()
	super._ready()

func start_game() -> void:
	super.start_game()
	rng.randomize()
	speed = SPEED_START
	run_time = 0.0
	distance = 0.0
	py = GROUND_Y
	vy = 0.0
	on_ground = true
	dead = false
	dash_left = 0.0
	dash_cool = 0.0
	for g in ground:
		g["node"].queue_free()
	for t in things:
		t["node"].queue_free()
	ground.clear()
	things.clear()
	next_x = -60.0
	_add_ground(1700.0)   # a calm run-up
	_generate()
	_show_banner("Tap to jump!", 1.4)

# ================================================================== LEVEL GENERATION

func _difficulty() -> float:
	return clampf(distance / 9000.0, 0.0, 1.0)

func _generate() -> void:
	while next_x < PLAY_WIDTH + 500.0:
		var d := _difficulty()
		var roll := rng.randf()
		if roll < 0.28:
			_gap(rng.randf_range(120.0, 170.0 + 170.0 * d))
		elif roll < 0.48:
			_plunger_run(1)
		elif roll < 0.58 and d > 0.15:
			_plunger_run(2)
		elif roll < 0.72:
			_fly_run(GROUND_Y - 70.0)
		elif roll < 0.82 and d > 0.3:
			_gap(rng.randf_range(260.0, 320.0), true)
		else:
			_add_ground(rng.randf_range(300.0, 520.0))
			_corn_line(next_x - 300.0, GROUND_Y - 60.0, 4)

func _gap(width: float, with_fly := false) -> void:
	var x0 := next_x
	next_x += width
	_corn_arc(x0 + width / 2.0, GROUND_Y - 150.0, 3, width)
	if with_fly:
		_add_fly(x0 + width / 2.0, GROUND_Y - 260.0)
	_add_ground(rng.randf_range(320.0, 480.0))

func _plunger_run(stack: int) -> void:
	var x0 := next_x
	_add_ground(rng.randf_range(460.0, 600.0))
	var px := x0 + rng.randf_range(200.0, 260.0)
	for i in stack:
		_add_plunger(px, GROUND_Y - i * 78.0)
	if stack == 1:
		_corn_arc(px, GROUND_Y - 190.0, 3, 180.0)

func _fly_run(y: float) -> void:
	var x0 := next_x
	_add_ground(rng.randf_range(460.0, 600.0))
	_add_fly(x0 + rng.randf_range(220.0, 300.0), y)

func _add_ground(length: float) -> void:
	var node := Node2D.new()
	node.position = Vector2(next_x, GROUND_Y)
	var top := _tiles(tex["ground_top"], length)
	node.add_child(top)
	var fill := _tiles(tex["ground"], length)
	fill.position.y = TILE
	node.add_child(fill)
	world.add_child(node)
	ground.append({ "x0": next_x, "x1": next_x + length, "node": node })
	next_x += length

func _tiles(t: Texture2D, length: float) -> Sprite2D:
	var s := Sprite2D.new()
	s.texture = t
	s.centered = false
	s.texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED
	s.region_enabled = true
	s.region_rect = Rect2(0, 0, length / S, 16)
	s.scale = Vector2(S, S)
	s.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	return s

func _add_plunger(x: float, bottom: float) -> void:
	var s := _sprite(tex["plunger"], Vector2(x, bottom - 42.0))
	world.add_child(s)
	things.append({ "kind": "plunger", "x": x, "y": bottom - 36.0, "w": 40.0, "h": 72.0, "node": s })

func _add_fly(x: float, y: float) -> void:
	var s := _sprite(tex["fly_1"], Vector2(x, y))
	world.add_child(s)
	things.append({ "kind": "fly", "x": x, "y": y, "base_y": y, "w": 46.0, "h": 34.0, "node": s, "phase": rng.randf() * TAU })

func _add_corn(x: float, y: float) -> void:
	var s := _sprite(tex["corn"], Vector2(x, y))
	world.add_child(s)
	things.append({ "kind": "corn", "x": x, "y": y, "w": 34.0, "h": 38.0, "node": s, "phase": x * 0.02 })

func _corn_arc(cx: float, top: float, n: int, width: float) -> void:
	for i in n:
		var t := (i + 0.5) / n - 0.5
		_add_corn(cx + t * width * 0.8, top + t * t * 160.0)

func _corn_line(x0: float, y: float, n: int) -> void:
	for i in n:
		_add_corn(x0 + i * 60.0, y)

# ================================================================== LOOP

func _process(delta: float) -> void:
	if not is_running:
		return
	_read_keys()
	if dead:
		return
	run_time += delta
	speed = minf(SPEED_MAX, SPEED_START + run_time * SPEED_GAIN)
	var dashing := dash_left > 0.0
	var v := speed * (DASH_MULT if dashing else 1.0)
	dash_left = maxf(0.0, dash_left - delta)
	dash_cool = maxf(0.0, dash_cool - delta)

	# scroll the world
	var dx := v * delta
	distance += dx
	_dist_points += dx / 25.0
	if _dist_points >= 1.0:
		add_score(int(_dist_points))
		_dist_points -= int(_dist_points)
	next_x -= dx
	for g in ground:
		g["x0"] -= dx
		g["x1"] -= dx
		g["node"].position.x = g["x0"]
	for t in things:
		t["x"] -= dx
	_cleanup()
	_generate()

	# vertical movement
	if dashing:
		vy = 0.0
	else:
		vy += GRAVITY * delta
	py += vy * delta
	var support := _ground_under(PLAYER_X)
	if support and vy >= 0.0 and py >= GROUND_Y and py - vy * delta <= GROUND_Y + 2.0:
		if not on_ground:
			_land()
		py = GROUND_Y
		vy = 0.0
		on_ground = true
		air_time = 0.0
	else:
		if on_ground and not support:
			on_ground = false
		elif on_ground and py < GROUND_Y:
			on_ground = false
		air_time += delta
		if air_time > COYOTE:
			on_ground = on_ground and support
	if support and py > GROUND_Y + 14.0 and not on_ground:
		_die("Splat!")        # fell in a hole and ran into its far wall
		return
	if py > PLAY_HEIGHT + 120.0:
		_die("Fell in!")
		return

	_update_things(delta, dashing)
	_animate_player(delta, dashing)
	_refresh_hud()

func _ground_under(x: float) -> bool:
	for g in ground:
		if x + BODY_W * 0.3 > g["x0"] and x - BODY_W * 0.3 < g["x1"]:
			return true
	return false

func _cleanup() -> void:
	for i in range(ground.size() - 1, -1, -1):
		if ground[i]["x1"] < -100.0:
			ground[i]["node"].queue_free()
			ground.remove_at(i)
	for i in range(things.size() - 1, -1, -1):
		if things[i]["x"] < -120.0:
			things[i]["node"].queue_free()
			things.remove_at(i)

func _update_things(delta: float, dashing: bool) -> void:
	var body := Rect2(PLAYER_X - BODY_W / 2.0, py - BODY_H, BODY_W, BODY_H)
	for i in range(things.size() - 1, -1, -1):
		var t: Dictionary = things[i]
		var n: Sprite2D = t["node"]
		match t["kind"]:
			"fly":
				t["phase"] += delta * 5.0
				t["y"] = t["base_y"] + sin(t["phase"]) * 16.0
				n.texture = tex["fly_1"] if int(run_time * 14.0) % 2 == 0 else tex["fly_2"]
			"corn":
				t["phase"] += delta * 4.0
				n.position.y = t["y"] + sin(t["phase"]) * 5.0
		n.position.x = t["x"]
		if t["kind"] != "corn":
			n.position.y = t["y"] if t["kind"] == "fly" else n.position.y
		var r := Rect2(t["x"] - t["w"] / 2.0, t["y"] - t["h"] / 2.0, t["w"], t["h"])
		if not body.intersects(r):
			continue
		if t["kind"] == "corn":
			add_score(10)
			_sfx("res://sounds/fx/gamecoin.wav", -14.0)
			_pop(n)
			things.remove_at(i)
		elif dashing:
			add_score(50)
			_float_text("+50", Vector2(t["x"], t["y"]))
			_sfx("res://sounds/fx/clack.mp3", -6.0)
			_smash(n)
			things.remove_at(i)
		else:
			_die("Ouch!")
			return

func _land() -> void:
	jumps_left = 1
	dash_used_in_air = false
	var tw := create_tween()
	var base := player.get_meta("base_scale") as Vector2
	tw.tween_property(player, "scale", base * Vector2(1.25, 0.78), 0.06)
	tw.tween_property(player, "scale", base, 0.18).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

func _animate_player(delta: float, dashing: bool) -> void:
	player.position = Vector2(PLAYER_X, py)
	var base := player.get_meta("base_scale") as Vector2
	if dashing:
		player.rotation = lerp_angle(player.rotation, 0.25, minf(1.0, delta * 20.0))
		if int(run_time * 60.0) % 3 == 0:
			_ghost()
	elif on_ground:
		var bob := sin(run_time * 22.0)
		player.rotation = bob * 0.08
		player.offset.y = player.get_meta("base_offset_y") - absf(bob) * 6.0
	else:
		player.rotation = lerp_angle(player.rotation, clampf(vy * 0.0003, -0.25, 0.3), minf(1.0, delta * 10.0))
		if not player.get_meta("squashing", false):
			var stretch := clampf(-vy / 2400.0, -0.1, 0.18)
			player.scale = base * Vector2(1.0 - stretch * 0.6, 1.0 + stretch)

func _ghost() -> void:
	var g := Sprite2D.new()
	g.texture = player.sprite_frames.get_frame_texture(player.animation, player.frame)
	g.position = player.position
	g.offset = player.offset
	g.scale = player.scale
	g.rotation = player.rotation
	g.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	g.modulate = Color(1.0, 0.85, 0.95, 0.55)
	ghost_layer.add_child(g)
	var tw := create_tween()
	tw.tween_property(g, "modulate:a", 0.0, 0.22)
	tw.parallel().tween_property(g, "position:x", g.position.x - 50.0, 0.22)
	tw.tween_callback(g.queue_free)

func _die(msg: String) -> void:
	dead = true
	_show_banner(msg, 0.8)
	var tw := create_tween()
	tw.tween_property(player, "position:y", player.position.y - 90.0, 0.25).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)
	tw.parallel().tween_property(player, "rotation", PI, 0.5)
	tw.tween_property(player, "position:y", PLAY_HEIGHT + 200.0, 0.45).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_QUAD)
	tw.tween_callback(func():
		banner.modulate.a = 0.0
		end_game())

# ================================================================== INPUT

func _jump() -> void:
	if dead or not is_running:
		return
	jump_held = true
	if on_ground or air_time <= COYOTE:
		vy = JUMP_V
		on_ground = false
		air_time = COYOTE + 0.01
		_sfx("res://sounds/fx/sfx_sounds_falling4.wav", -16.0, 0.12)
	elif jumps_left > 0:
		jumps_left -= 1
		vy = DOUBLE_JUMP_V
		dash_left = 0.0
		_puff()
		_sfx("res://sounds/fx/sfx_sounds_falling4.wav", -14.0, 0.12)

func _release_jump() -> void:
	jump_held = false
	if vy < -300.0:
		vy *= JUMP_CUT

func _dash() -> void:
	if dead or not is_running or dash_cool > 0.0 or (not on_ground and dash_used_in_air):
		return
	dash_left = DASH_TIME
	dash_cool = DASH_COOLDOWN
	if not on_ground:
		dash_used_in_air = true
	vy = 0.0
	_sfx("res://sounds/fx/underwater-247531.mp3", -18.0, 0.25)

func on_main_button_pressed() -> void:
	if is_game_over:
		super.on_main_button_pressed()
		return
	_jump()

func on_main_button_released() -> void:
	_release_jump()

func on_forward_button_down() -> void:
	if not is_game_over:
		_dash()

func on_forward_button_pressed() -> void:
	if is_game_over:
		super.on_forward_button_pressed()   # (dash already fired on button down)

func _read_keys() -> void:
	for k in [KEY_SPACE, KEY_UP, KEY_RIGHT, KEY_SHIFT]:
		var down := Input.is_key_pressed(k)
		var was: bool = _keys.get(k, false)
		if down and not was:
			if k in [KEY_SPACE, KEY_UP]:
				_jump()
			else:
				_dash()
		elif was and not down and k in [KEY_SPACE, KEY_UP]:
			_release_jump()
		_keys[k] = down

# ================================================================== NODES / FX / HUD

func _create_static_nodes() -> void:
	var sky := ColorRect.new()
	sky.color = SKY
	sky.size = Vector2(PLAY_WIDTH, PLAY_HEIGHT)
	add_child(sky)
	_create_clouds()

	world = Node2D.new()
	add_child(world)
	ghost_layer = Node2D.new()
	add_child(ghost_layer)

	player = AnimatedSprite2D.new()
	player.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	var frames: SpriteFrames = PetState.build_sprite_frames() if PetState.has_poop() else null
	if frames == null:
		frames = SpriteFrames.new()
		frames.add_frame("default", load("res://textures/minigames/balls/classic.png"))
	player.sprite_frames = frames
	var anim := "idle" if frames.has_animation("idle") else "default"
	player.play(anim)
	var tex0 := frames.get_frame_texture(anim, 0)
	var img := tex0.get_image()
	var used := img.get_used_rect() if img else Rect2i(0, 0, tex0.get_width(), tex0.get_height())
	var k := PAL_WIDTH / maxf(1.0, used.size.x)
	player.scale = Vector2(k, k)
	player.set_meta("base_scale", player.scale)
	# feet at the node origin: bottom of the visible body sits on the ground line
	var bottom := float(used.position.y + used.size.y) - tex0.get_height() / 2.0
	player.offset = Vector2(0, -bottom)
	player.set_meta("base_offset_y", -bottom)
	add_child(player)

	var frame := ColorRect.new()
	frame.color = Color(0, 0, 0)
	frame.position = Vector2(PLAY_WIDTH - 245, 24)
	frame.size = Vector2(205, 70)
	add_child(frame)
	var box := ColorRect.new()
	box.color = Color(0.65, 0.72, 0.6)
	box.position = frame.position + Vector2(5, 5)
	box.size = frame.size - Vector2(10, 10)
	add_child(box)
	score_label = _make_label(box.position + Vector2(6, 0), box.size - Vector2(18, 0), 36, HORIZONTAL_ALIGNMENT_RIGHT, Color(0.2, 0.15, 0.05))
	dash_label = _make_label(Vector2(36, 28), Vector2(200, 60), 38, HORIZONTAL_ALIGNMENT_LEFT, Color(1, 0.97, 0.9))
	dash_label.add_theme_color_override("font_outline_color", OUTLINE)
	dash_label.add_theme_constant_override("outline_size", 10)
	dash_label.text = "DASH"

	banner = _make_label(Vector2(0, PLAY_HEIGHT / 2 - 160), Vector2(PLAY_WIDTH, 120), 54, HORIZONTAL_ALIGNMENT_CENTER, Color(1, 0.97, 0.9))
	banner.add_theme_color_override("font_outline_color", OUTLINE)
	banner.add_theme_constant_override("outline_size", 14)
	banner.modulate.a = 0.0

func _create_clouds() -> void:
	var layers := [
		["res://scripts/shaders/scroll.gdshader", "res://textures/pet-background/clouds3.png", 0.05],
		["res://scripts/shaders/scroll2.gdshader", "res://textures/pet-background/clouds2.png", 0.1],
	]
	for l in layers:
		var shader = load(l[0]) as Shader
		var t = load(l[1]) as Texture2D
		if not shader or not t:
			continue
		var c := Sprite2D.new()
		c.texture = t
		c.texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED
		c.position = Vector2(PLAY_WIDTH / 2, PLAY_HEIGHT / 2)
		c.scale = Vector2(1.03, 1.03)   # same framing as the pet screen
		var mat := ShaderMaterial.new()
		mat.shader = shader
		mat.set_shader_parameter("scroll_speed", l[2])
		c.material = mat
		add_child(c)

func _refresh_hud() -> void:
	score_label.add_theme_font_size_override("font_size", 36 if str(score).length() <= 5 else 30)
	score_label.text = str(score)
	var ready := dash_cool <= 0.0
	dash_label.modulate = Color(1, 1, 1, 1.0 if ready else 0.35)

func _puff() -> void:
	for i in 5:
		var c := ColorRect.new()
		c.color = Color(1, 0.97, 0.92, 0.9)
		c.size = Vector2(9, 9)
		c.position = Vector2(PLAYER_X - 4, py - 4)
		add_child(c)
		var dir := Vector2.from_angle(PI * 0.5 + (i - 2) * 0.45) * 60.0
		var tw := create_tween()
		tw.tween_property(c, "position", c.position + dir, 0.25)
		tw.parallel().tween_property(c, "modulate:a", 0.0, 0.25)
		tw.tween_callback(c.queue_free)

func _pop(n: Node2D) -> void:
	var tw := create_tween()
	tw.tween_property(n, "scale", n.scale * 1.6, 0.12)
	tw.parallel().tween_property(n, "modulate:a", 0.0, 0.12)
	tw.tween_callback(n.queue_free)

func _smash(n: Node2D) -> void:
	var tw := create_tween()
	tw.tween_property(n, "position", n.position + Vector2(260, -180), 0.4)
	tw.parallel().tween_property(n, "rotation", 6.0, 0.4)
	tw.parallel().tween_property(n, "modulate:a", 0.0, 0.4)
	tw.tween_callback(n.queue_free)

func _sprite(t: Texture2D, pos: Vector2) -> Sprite2D:
	var s := Sprite2D.new()
	s.texture = t
	s.position = pos
	s.scale = Vector2(S, S)
	s.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	return s

func _make_label(pos: Vector2, sz: Vector2, font_size: int, align: int, color: Color) -> Label:
	var l := Label.new()
	l.position = pos
	l.size = sz
	l.horizontal_alignment = align
	l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	if lcd_font:
		l.add_theme_font_override("font", lcd_font)
	l.add_theme_font_size_override("font_size", font_size)
	l.add_theme_color_override("font_color", color)
	add_child(l)
	return l

func _show_banner(text: String, hold: float) -> void:
	banner.text = text
	var t := create_tween()
	t.tween_property(banner, "modulate:a", 1.0, 0.15)
	t.tween_interval(hold)
	t.tween_property(banner, "modulate:a", 0.0, 0.3)

func _float_text(text: String, at: Vector2) -> void:
	var l := _make_label(at + Vector2(-60, -60), Vector2(120, 40), 28, HORIZONTAL_ALIGNMENT_CENTER, Color(1, 0.95, 0.85))
	l.add_theme_color_override("font_outline_color", OUTLINE)
	l.add_theme_constant_override("outline_size", 10)
	l.text = text
	var t := create_tween()
	t.tween_property(l, "position:y", l.position.y - 40, 0.6)
	t.parallel().tween_property(l, "modulate:a", 0.0, 0.6)
	t.tween_callback(l.queue_free)

func _sfx(path: String, volume_db: float, max_time := 0.0) -> void:
	var stream = load(path) as AudioStream
	if not stream:
		return
	var sfx := AudioStreamPlayer.new()
	sfx.stream = stream
	sfx.volume_db = volume_db
	add_child(sfx)
	sfx.play()
	sfx.finished.connect(sfx.queue_free)
	if max_time > 0.0:
		get_tree().create_timer(max_time).timeout.connect(func():
			if is_instance_valid(sfx):
				sfx.queue_free())
