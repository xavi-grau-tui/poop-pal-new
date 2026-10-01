extends BaseMinigame
## Tile Break — bounce your pal (curled into a ball) off a toilet-paper roll and smash
## every bathroom tile. Capsules drop sometimes: mint = wide roll, yellow = 3 balls,
## pink = slow ball.
##
## Hold MAIN to move left, hold FORWARD to move right. The ball launches by itself.
## Desktop: also Left / Right arrows (A / D).

const S := 3.0
const TOP := 104.0                      # below the HUD band
const VIS_L := 18.0                     # edges visible through the console's screen window
const VIS_R := 945.0
const PADDLE_Y := 870.0
const PADDLE_SPEED := 980.0
const PADDLE_ACCEL := 7000.0
const BALL_R := 23.0
const BALL_SPEED := 540.0
const BALL_SPEED_MAX := 920.0
const SPEEDUP_PER_HIT := 6.0
const MAX_BOUNCE_ANGLE := deg_to_rad(62.0)
const LIVES := 3
const COLS := 12
const TILE_W := 72.0
const TILE_H := 33.0
const GRID_X := (18.0 + 945.0 - COLS * TILE_W) / 2.0   # centred in the visible window
const GRID_Y := 150.0
const DROP_CHANCE := 0.13
const POWER_TIME := 12.0

const COLORS := { "p": "pink", "y": "yellow", "m": "mint", "b": "blue", "l": "lilac", "g": "gold" }
const LEVELS := [
	["............",
	 "pppppppppppp",
	 "yyyyyyyyyyyy",
	 "mmmmmmmmmmmm",
	 "bbbbbbbbbbbb"],
	["..PP....PP..",
	 ".pyyp..pyyp.",
	 "pymmyppymmyp",
	 "pymmyppymmyp",
	 ".pyyp..pyyp.",
	 "..pp....pp.."],
	["g..........g",
	 "LLLLLLLLLLLL",
	 "b.b.b.b.b.b.",
	 ".m.m.m.m.m.m",
	 "yyyggyyggyyy",
	 "pppppppppppp"],
	["....MMMM....",
	 "..MMyyyyMM..",
	 ".Mybbbbbbym.",
	 "Mybgg..ggbyM",
	 ".Mybbbbbbym.",
	 "..MMyyyyMM..",
	 "....MMMM...."],
]
const OUTLINE := Color8(74, 44, 32)

var level := 0
var lives := LIVES
var paddle_x := 475.0
var paddle_v := 0.0
var paddle_w := 132.0
var left_held := false
var right_held := false
var wide_time := 0.0
var slow_time := 0.0

var balls: Array[Dictionary] = []       # { pos, vel, node, stuck }
var bricks: Array[Dictionary] = []      # { rect, hits, color, node, solid }
var drops: Array[Dictionary] = []       # { pos, kind, node }
var speed := BALL_SPEED
var launch_timer := 0.0

var tex := {}
var ball_texture: Texture2D
var lcd_font: Font
var paddle: Sprite2D
var world: Node2D
var score_label: Label
var level_label: Label
var lives_box: HBoxContainer
var banner: Label
var rng := RandomNumberGenerator.new()

func _ready() -> void:
	game_music_path = "res://sounds/music/Pixel Pulse.mp3"
	lcd_font = load("res://fonts/pixChicago.ttf")
	tex["paddle"] = load("res://textures/minigames/break/paddle.png")
	for c in COLORS.values():
		tex["tile_" + c] = load("res://textures/minigames/break/tile_%s.png" % c)
		var cracked := "res://textures/minigames/break/tile_%s_cracked.png" % c
		if ResourceLoader.exists(cracked):
			tex["tile_%s_cracked" % c] = load(cracked)
	for c in ["mint", "yellow", "pink"]:
		tex["capsule_" + c] = load("res://textures/minigames/break/capsule_%s.png" % c)
	var ball_path := "res://textures/minigames/balls/%s.png" % PetState.form_id
	ball_texture = load(ball_path if PetState.has_poop() and ResourceLoader.exists(ball_path) else "res://textures/minigames/balls/classic.png")
	rng.randomize()
	_create_static_nodes()
	super._ready()

func start_game() -> void:
	super.start_game()
	level = 0
	lives = LIVES
	speed = BALL_SPEED
	_build_level()
	_show_banner("Hold to move!", 1.4)

# ================================================================== LEVEL

func _build_level() -> void:
	for b in bricks:
		b["node"].queue_free()
	bricks.clear()
	_clear_drops()
	var rows: Array = LEVELS[level % LEVELS.size()]
	for r in rows.size():
		var row: String = rows[r]
		for c in COLS:
			var ch := row[c]
			if ch == ".":
				continue
			var color: String = COLORS[ch.to_lower()]
			var rect := Rect2(GRID_X + c * TILE_W, GRID_Y + r * TILE_H, TILE_W, TILE_H)
			var s := _sprite(tex["tile_" + color], rect.get_center())
			world.add_child(s)
			bricks.append({ "rect": rect, "hits": 2 if ch != ch.to_lower() else 1, "color": color, "node": s, "solid": ch == "g" })
	level_label.text = "LV %d" % (level + 1)
	speed = BALL_SPEED + 40.0 * (level / LEVELS.size())    # every lap of the levels is faster
	_reset_balls()
	_refresh_lives()

func _reset_balls() -> void:
	for b in balls:
		b["node"].queue_free()
	balls.clear()
	_add_ball(Vector2(paddle_x, PADDLE_Y - 18 - BALL_R), Vector2.ZERO, true)
	launch_timer = 1.1

func _add_ball(pos: Vector2, vel: Vector2, stuck := false) -> void:
	var s := Sprite2D.new()
	s.texture = ball_texture
	s.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	s.scale = Vector2.ONE * (BALL_R * 2.0 / 40.0)
	world.add_child(s)
	balls.append({ "pos": pos, "vel": vel, "node": s, "stuck": stuck })

# ================================================================== LOOP

func _process(delta: float) -> void:
	if not is_running:
		return
	_move_paddle(delta)
	wide_time = maxf(0.0, wide_time - delta)
	slow_time = maxf(0.0, slow_time - delta)
	paddle_w = lerpf(paddle_w, 132.0 * (1.5 if wide_time > 0.0 else 1.0), minf(1.0, delta * 8.0))
	paddle.scale.x = S * paddle_w / 132.0
	paddle.position = Vector2(paddle_x, PADDLE_Y)

	if launch_timer > 0.0:
		launch_timer -= delta
		if launch_timer <= 0.0:
			for b in balls:
				if b["stuck"]:
					b["stuck"] = false
					b["vel"] = Vector2.from_angle(-PI / 2 + rng.randf_range(-0.35, 0.35)) * speed
	const STEPS := 4
	for i in STEPS:
		_step_balls(delta / STEPS)
	_update_drops(delta)
	for b in balls:
		b["node"].position = b["pos"]
		b["node"].rotation += b["vel"].x * delta / BALL_R
	score_label.text = str(score)
	score_label.add_theme_font_size_override("font_size", 36 if str(score).length() <= 5 else 30)

func _move_paddle(delta: float) -> void:
	var dir := 0.0
	if left_held or Input.is_key_pressed(KEY_LEFT) or Input.is_key_pressed(KEY_A):
		dir -= 1.0
	if right_held or Input.is_key_pressed(KEY_RIGHT) or Input.is_key_pressed(KEY_D):
		dir += 1.0
	paddle_v = move_toward(paddle_v, dir * PADDLE_SPEED, PADDLE_ACCEL * delta)
	var lo := VIS_L + paddle_w / 2.0
	var hi := VIS_R - paddle_w / 2.0
	paddle_x = clampf(paddle_x + paddle_v * delta, lo, hi)
	if paddle_x <= lo or paddle_x >= hi:
		paddle_v = 0.0

func _step_balls(dt: float) -> void:
	for i in range(balls.size() - 1, -1, -1):
		var b: Dictionary = balls[i]
		if b["stuck"]:
			b["pos"] = Vector2(paddle_x, PADDLE_Y - 18 - BALL_R)
			continue
		var v: Vector2 = b["vel"]
		var mult := 0.7 if slow_time > 0.0 else 1.0
		v = v.normalized() * speed * mult
		var p: Vector2 = b["pos"] + v * dt
		# walls
		if p.x < VIS_L + BALL_R:
			p.x = VIS_L + BALL_R; v.x = absf(v.x)
		elif p.x > VIS_R - BALL_R:
			p.x = VIS_R - BALL_R; v.x = -absf(v.x)
		if p.y < TOP + BALL_R:
			p.y = TOP + BALL_R; v.y = absf(v.y)
		# paddle: the bounce angle depends on where the roll is hit
		var half := paddle_w / 2.0
		if v.y > 0 and p.y + BALL_R >= PADDLE_Y - 16 and p.y < PADDLE_Y + 10 and absf(p.x - paddle_x) < half + BALL_R * 0.6:
			var off := clampf((p.x - paddle_x) / half, -1.0, 1.0)
			v = Vector2.from_angle(-PI / 2 + off * MAX_BOUNCE_ANGLE) * v.length()
			p.y = PADDLE_Y - 16 - BALL_R
			_squash_paddle()
			_sfx("res://sounds/fx/click-6.mp3", -10.0)
		# bricks
		for j in range(bricks.size() - 1, -1, -1):
			var br: Dictionary = bricks[j]
			var r: Rect2 = br["rect"]
			var closest := Vector2(clampf(p.x, r.position.x, r.end.x), clampf(p.y, r.position.y, r.end.y))
			var d := p - closest
			if d.length_squared() >= BALL_R * BALL_R:
				continue
			# push out along the shallowest axis and reflect
			var over_x := BALL_R - absf(p.x - r.get_center().x) + r.size.x / 2.0
			var over_y := BALL_R - absf(p.y - r.get_center().y) + r.size.y / 2.0
			if over_x < over_y:
				p.x += signf(p.x - r.get_center().x) * over_x
				v.x = signf(p.x - r.get_center().x) * absf(v.x)
			else:
				p.y += signf(p.y - r.get_center().y) * over_y
				v.y = signf(p.y - r.get_center().y) * absf(v.y)
			_hit_brick(j)
			break
		b["pos"] = p
		b["vel"] = v
		if p.y > PLAY_HEIGHT + BALL_R:
			b["node"].queue_free()
			balls.remove_at(i)
	if balls.is_empty() and is_running:
		_lose_life()

func _hit_brick(j: int) -> void:
	var br: Dictionary = bricks[j]
	var n: Sprite2D = br["node"]
	if br["solid"]:
		_sfx("res://sounds/fx/clack.mp3", -12.0)
		var tw := create_tween()
		tw.tween_property(n, "modulate", Color(2, 2, 2), 0.04)
		tw.tween_property(n, "modulate", Color(1, 1, 1), 0.1)
		return
	br["hits"] -= 1
	speed = minf(BALL_SPEED_MAX, speed + SPEEDUP_PER_HIT)
	add_score(10)
	if br["hits"] > 0:
		n.texture = tex.get("tile_%s_cracked" % br["color"], n.texture)
		_sfx("res://sounds/fx/clack.mp3", -9.0)
		return
	_sfx("res://sounds/fx/click-5.mp3", -6.0)
	bricks.remove_at(j)
	var tw := create_tween()
	tw.tween_property(n, "scale", n.scale * Vector2(1.3, 0.2), 0.12)
	tw.parallel().tween_property(n, "modulate:a", 0.0, 0.12)
	tw.tween_callback(n.queue_free)
	if rng.randf() < DROP_CHANCE:
		_spawn_drop(br["rect"].get_center())
	for b in bricks:
		if not b["solid"]:
			return
	_level_clear()

func _level_clear() -> void:
	add_score(100)
	_show_banner("Clear! +100", 1.2)
	for b in balls:
		b["stuck"] = true
		b["vel"] = Vector2.ZERO
	launch_timer = 99.0
	await get_tree().create_timer(1.6).timeout
	if not is_running:
		return
	level += 1
	_build_level()
	_show_banner("Level %d" % (level + 1), 1.0)

func _lose_life() -> void:
	lives -= 1
	_refresh_lives()
	_clear_drops()
	wide_time = 0.0
	slow_time = 0.0
	if lives <= 0:
		end_game()
		return
	_play_error_sound()
	_reset_balls()

# ================================================================== POWER-UPS

func _spawn_drop(at: Vector2) -> void:
	var kinds := ["mint", "yellow", "pink"]
	var kind: String = kinds[rng.randi() % kinds.size()]
	var s := _sprite(tex["capsule_" + kind], at)
	world.add_child(s)
	drops.append({ "pos": at, "kind": kind, "node": s })

func _update_drops(delta: float) -> void:
	for i in range(drops.size() - 1, -1, -1):
		var d: Dictionary = drops[i]
		d["pos"].y += 230.0 * delta
		d["node"].position = d["pos"]
		if absf(d["pos"].y - PADDLE_Y) < 26 and absf(d["pos"].x - paddle_x) < paddle_w / 2.0 + 20:
			_apply_power(d["kind"])
			d["node"].queue_free()
			drops.remove_at(i)
		elif d["pos"].y > PLAY_HEIGHT + 30:
			d["node"].queue_free()
			drops.remove_at(i)

func _apply_power(kind: String) -> void:
	_sfx("res://sounds/fx/gamecoin.wav", -9.0)
	match kind:
		"mint":
			wide_time = POWER_TIME
			_float_text("WIDE!", Vector2(paddle_x, PADDLE_Y - 40))
		"pink":
			slow_time = POWER_TIME
			_float_text("SLOW!", Vector2(paddle_x, PADDLE_Y - 40))
		"yellow":
			_float_text("x3!", Vector2(paddle_x, PADDLE_Y - 40))
			var src: Array[Dictionary] = balls.duplicate()
			for b in src:
				if b["stuck"]:
					continue
				for a in [-0.4, 0.4]:
					_add_ball(b["pos"], b["vel"].rotated(a))

func _clear_drops() -> void:
	for d in drops:
		d["node"].queue_free()
	drops.clear()

# ================================================================== NODES / HUD

func _create_static_nodes() -> void:
	# bathroom wall: two creams in a checker with grout lines
	var img := Image.create(32, 32, false, Image.FORMAT_RGBA8)
	var c1 := Color8(250, 242, 226)
	var c2 := Color8(246, 226, 222)
	var grout := Color8(222, 200, 186)
	for y in 32:
		for x in 32:
			var col := c1 if ((x / 16) + (y / 16)) % 2 == 0 else c2
			if x % 16 == 15 or y % 16 == 15:
				col = grout
			img.set_pixel(x, y, col)
	var wall := Sprite2D.new()
	wall.texture = ImageTexture.create_from_image(img)
	wall.centered = false
	wall.texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED
	wall.region_enabled = true
	wall.region_rect = Rect2(0, 0, PLAY_WIDTH / S, PLAY_HEIGHT / S)
	wall.scale = Vector2(S, S)
	wall.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	add_child(wall)
	var band := ColorRect.new()
	band.color = OUTLINE
	band.size = Vector2(PLAY_WIDTH, TOP)
	add_child(band)

	world = Node2D.new()
	add_child(world)
	paddle = _sprite(tex["paddle"], Vector2(paddle_x, PADDLE_Y))
	add_child(paddle)

	level_label = _make_label(Vector2(30, 22), Vector2(150, 60), 38, HORIZONTAL_ALIGNMENT_LEFT, Color(0.98, 0.93, 0.84))
	lives_box = HBoxContainer.new()
	lives_box.position = Vector2(170, 30)
	lives_box.add_theme_constant_override("separation", 6)
	add_child(lives_box)
	var frame := ColorRect.new()
	frame.color = Color(0, 0, 0)
	frame.position = Vector2(PLAY_WIDTH - 245, 16)
	frame.size = Vector2(205, 72)
	add_child(frame)
	var box := ColorRect.new()
	box.color = Color(0.65, 0.72, 0.6)
	box.position = frame.position + Vector2(5, 5)
	box.size = frame.size - Vector2(10, 10)
	add_child(box)
	score_label = _make_label(box.position + Vector2(6, 0), box.size - Vector2(18, 0), 36, HORIZONTAL_ALIGNMENT_RIGHT, Color(0.2, 0.15, 0.05))

	banner = _make_label(Vector2(0, 560), Vector2(PLAY_WIDTH, 120), 54, HORIZONTAL_ALIGNMENT_CENTER, Color(1, 0.97, 0.9))
	banner.add_theme_color_override("font_outline_color", OUTLINE)
	banner.add_theme_constant_override("outline_size", 14)
	banner.modulate.a = 0.0

func _refresh_lives() -> void:
	for n in lives_box.get_children():
		n.queue_free()
	for i in LIVES:
		var t := TextureRect.new()
		t.texture = ball_texture
		t.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		t.custom_minimum_size = Vector2(40, 40)
		t.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		t.modulate = Color(1, 1, 1, 1) if i < lives else Color(0, 0, 0, 0.35)
		lives_box.add_child(t)

func _squash_paddle() -> void:
	var tw := create_tween()
	tw.tween_property(paddle, "scale:y", S * 0.8, 0.05)
	tw.tween_property(paddle, "scale:y", S, 0.12)

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
	var l := _make_label(at + Vector2(-80, -60), Vector2(160, 40), 30, HORIZONTAL_ALIGNMENT_CENTER, Color(1, 0.95, 0.85))
	l.add_theme_color_override("font_outline_color", OUTLINE)
	l.add_theme_constant_override("outline_size", 10)
	l.text = text
	var t := create_tween()
	t.tween_property(l, "position:y", l.position.y - 50, 0.7)
	t.parallel().tween_property(l, "modulate:a", 0.0, 0.7)
	t.tween_callback(l.queue_free)

func _sfx(path: String, volume_db: float) -> void:
	var stream = load(path) as AudioStream
	if not stream:
		return
	var sfx := AudioStreamPlayer.new()
	sfx.stream = stream
	sfx.volume_db = volume_db
	add_child(sfx)
	sfx.play()
	sfx.finished.connect(sfx.queue_free)

# ================================================================== INPUT

func on_main_button_pressed() -> void:
	if is_game_over:
		super.on_main_button_pressed()
		return
	left_held = true

func on_main_button_released() -> void:
	left_held = false

func on_forward_button_down() -> void:
	if not is_game_over:
		right_held = true

func on_forward_button_up() -> void:
	right_held = false

func on_forward_button_pressed() -> void:
	if is_game_over:
		super.on_forward_button_pressed()

func end_game() -> void:
	left_held = false
	right_held = false
	super.end_game()
