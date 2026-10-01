extends BaseMinigame
## Flipper Belly — a pocket pinball table inside a belly. The pal is the ball.
##
##   main button     = LEFT flipper (it's orange, like the button)
##   forward button  = RIGHT flipper (cream, like the button)
##   speaker button  = nudge the table. Three nudges in a row = TILT: the flippers die
##                     until the ball drains.
## Phones: every finger is read directly, so both flippers work at once.
## Desktop: also Left/A and Right/D for the flippers, Space / Up to nudge.
##
## Table: three bumpers (100), two slingshots (10), the Y-U-M drop targets (150 each, all
## three = 1000 and they come back), and the belly button hole at the top left (250: it
## swallows the ball and spits it out again). Three balls per game.
## Water boost (splash): the first drain of each ball bounces it back up once.
##
## The table is drawn into a small low-res canvas (1/3 size) shown x3, so it is pixel art
## and always matches the physics exactly (same numbers draw it and collide with it).

const K := 3.0                          # world px per table pixel
const GRAVITY := 1150.0
const MAX_SPEED := 1750.0
const BALL_R := 25.0
const WALL_BOUNCE := 0.45
const SUBSTEPS := 10

# Flippers: pivot, length, angles (radians, + = down). Left points right, right points left.
const FLIP_PIVOTS := [Vector2(300, 790), Vector2(660, 790)]
const FLIP_LEN := 140.0
const FLIP_R0 := 16.0                   # thickness at the pivot...
const FLIP_R1 := 9.0                    # ...and at the tip
const FLIP_REST := 0.49                 # ~28 deg down
const FLIP_UP := -0.49
const FLIP_SPEED_UP := 19.0             # rad/s
const FLIP_SPEED_DOWN := 11.0
const FLIP_BOUNCE := 0.25

const BUMPERS := [Vector2(360, 280), Vector2(600, 280), Vector2(480, 400)]
const BUMPER_R := 36.0
const BUMPER_KICK := 560.0
const SLING_KICK := 620.0
const TARGETS := [Vector2(400, 560), Vector2(480, 560), Vector2(560, 560)]
const TARGET_SIZE := Vector2(54, 18)
const TARGET_LETTERS := ["Y", "U", "M"]
const HOLE := Vector2(215, 190)
const HOLE_R := 20.0
const LAUNCH := Vector2(560, 95)
const DRAIN_Y := 975.0
const BALLS := 3

const POINTS := { "bumper": 100, "sling": 10, "target": 150, "yum": 1000, "hole": 250 }

# Colours (the console's palette, belly flavoured)
const OUTLINE := Color8(74, 44, 32)
const BACK := Color8(96, 40, 58)
const FIELD := Color8(150, 72, 90)
const FIELD_DOT := Color8(170, 92, 108)
const WALL := Color8(250, 228, 180)
const ORANGE := Color8(236, 150, 92)
const CREAM := Color8(250, 228, 180)
const PINK := Color8(246, 150, 180)
const PINK_HI := Color8(255, 206, 220)
const GOLD := Color8(255, 220, 120)

var walls: Array = []                    # [a, b, kind] kind: "wall" | "sling0" | "sling1"
var arch: PackedVector2Array
var field_poly: PackedVector2Array
var sling_polys: Array = []
var flippers: Array[Dictionary] = []     # { pivot, sign, angle, vel, held }
var ball := { "pos": Vector2.ZERO, "vel": Vector2.ZERO, "live": false, "spin": 0.0 }
var balls_left := BALLS
var targets_down := [false, false, false]
var bumper_flash := [0.0, 0.0, 0.0]
var sling_flash := [0.0, 0.0]
var hole_timer := 0.0                    # > 0: the ball is inside the belly button
var saved_this_ball := false
var tilted := false
var nudges: Array[float] = []
var _last_nudge := -1.0
var _clock := 0.0
var _touch := {}                         # touch index -> button (0 main, 1 forward, 2 speaker)
var _keys := {}
var dots: PackedVector2Array

var lcd_font: Font
var view: SubViewport
var canvas: Node2D
var table_sprite: Sprite2D
var pal_ball: Sprite2D
var target_labels: Array[Label] = []
var score_label: Label
var balls_box: HBoxContainer
var banner: Label
var drop_icon: TextureRect

func _ready() -> void:
	lcd_font = load("res://fonts/pixChicago.ttf")
	_build_geometry()
	for i in 2:
		flippers.append({ "pivot": FLIP_PIVOTS[i], "sign": 1.0 if i == 0 else -1.0, "angle": FLIP_REST, "vel": 0.0, "held": false })
	_create_nodes()
	super._ready()

func start_game() -> void:
	super.start_game()
	balls_left = BALLS
	_refresh_hud()
	_serve(1.0)

# ================================================================== TABLE

func _build_geometry() -> void:
	# arch: half an ellipse over the top
	arch = PackedVector2Array()
	var c := Vector2(480, 300)
	for i in 25:
		var a := PI + PI * i / 24.0
		arch.append(c + Vector2(cos(a) * 440.0, sin(a) * 270.0))
	for i in arch.size() - 1:
		walls.append([arch[i], arch[i + 1], "wall"])
	var outline := [Vector2(40, 300), Vector2(40, 600), FLIP_PIVOTS[0] + Vector2(-6, -4)]
	var outline_r := [Vector2(920, 300), Vector2(920, 600), FLIP_PIVOTS[1] + Vector2(6, -4)]
	for pts in [outline, outline_r]:
		for i in pts.size() - 1:
			walls.append([pts[i], pts[i + 1], "wall"])
	# slingshots: the long face (towards the middle) kicks
	sling_polys = [
		PackedVector2Array([Vector2(100, 500), Vector2(100, 610), Vector2(200, 680)]),
		PackedVector2Array([Vector2(860, 500), Vector2(860, 610), Vector2(760, 680)]),
	]
	for s in 2:
		var p: PackedVector2Array = sling_polys[s]
		walls.append([p[0], p[2], "sling%d" % s])
		walls.append([p[0], p[1], "wall"])
		walls.append([p[1], p[2], "wall"])
	# the playfield shape (for drawing)
	field_poly = PackedVector2Array(arch)
	field_poly.append(Vector2(920, 600))
	field_poly.append(FLIP_PIVOTS[1] + Vector2(6, -4))
	field_poly.append(FLIP_PIVOTS[0] + Vector2(-6, -4))
	field_poly.append(Vector2(40, 600))
	# texture: soft "villi" dots on the playfield
	var rng := RandomNumberGenerator.new()
	rng.seed = 11
	dots = PackedVector2Array()
	while dots.size() < 70:
		var p := Vector2(rng.randf_range(60, 900), rng.randf_range(60, 900))
		if Geometry2D.is_point_in_polygon(p, field_poly):
			dots.append(p)

func _flip_tip(f: Dictionary) -> Vector2:
	return f["pivot"] + Vector2(f["sign"] * cos(f["angle"]), sin(f["angle"])) * FLIP_LEN

# ================================================================== LOOP

func _process(delta: float) -> void:
	_clock += delta
	for i in 3:
		bumper_flash[i] = maxf(0.0, bumper_flash[i] - delta)
	for i in 2:
		sling_flash[i] = maxf(0.0, sling_flash[i] - delta)
	if not is_running:
		canvas.queue_redraw()
		return
	_read_keys()
	var dt := minf(delta, 1.0 / 30.0) / SUBSTEPS
	for _s in SUBSTEPS:
		_step_flippers(dt)
		if ball["live"] and hole_timer <= 0.0:
			_step_ball(dt)
	if hole_timer > 0.0:
		hole_timer -= delta
		if hole_timer <= 0.0:
			_spit_out()
	_update_ball_sprite(delta)
	canvas.queue_redraw()

func _step_flippers(dt: float) -> void:
	for i in 2:
		var f: Dictionary = flippers[i]
		var up := _flipper_held(i) and not tilted
		var target := FLIP_UP if up else FLIP_REST
		var speed := FLIP_SPEED_UP if up else FLIP_SPEED_DOWN
		var d: float = target - f["angle"]
		var stepv := clampf(d, -speed * dt, speed * dt)
		f["angle"] += stepv
		f["vel"] = stepv / dt

func _step_ball(dt: float) -> void:
	var v: Vector2 = ball["vel"]
	v.y += GRAVITY * dt
	v = v.limit_length(MAX_SPEED)
	ball["vel"] = v
	ball["pos"] += v * dt
	for w in walls:
		_collide_segment(w[0], w[1], w[2])
	for i in 3:
		_collide_bumper(i)
	for i in 3:
		if not targets_down[i]:
			_collide_target(i)
	for i in 2:
		_collide_flipper(flippers[i])
	# belly button
	if ball["pos"].distance_to(HOLE) < HOLE_R and ball["vel"].length() < 1300.0:
		_swallow()
	if ball["pos"].y > DRAIN_Y:
		_drain()

func _collide_segment(a: Vector2, b: Vector2, kind: String) -> void:
	var p: Vector2 = ball["pos"]
	var q := Geometry2D.get_closest_point_to_segment(p, a, b)
	var d := p - q
	var dist := d.length()
	if dist >= BALL_R or dist < 0.001:
		return
	var n := d / dist
	ball["pos"] = q + n * BALL_R
	var v: Vector2 = ball["vel"]
	var vn := v.dot(n)
	if vn < 0.0:
		v -= (1.0 + WALL_BOUNCE) * vn * n
		v -= (v - v.dot(n) * n) * 0.02            # a little friction along the wall
		if kind.begins_with("sling") and vn < -120.0:
			var s := int(kind.substr(5))
			v += n * SLING_KICK
			sling_flash[s] = 0.12
			_sfx("res://sounds/fx/pin_sling.wav", -12.0)
			add_score(POINTS["sling"])
		ball["vel"] = v

func _collide_bumper(i: int) -> void:
	var c: Vector2 = BUMPERS[i]
	var d: Vector2 = ball["pos"] - c
	var dist := d.length()
	if dist >= BUMPER_R + BALL_R or dist < 0.001:
		return
	var n := d / dist
	ball["pos"] = c + n * (BUMPER_R + BALL_R)
	var v: Vector2 = ball["vel"]
	var vn := v.dot(n)
	if vn < 0.0:
		v -= 2.0 * vn * n * 0.6
	ball["vel"] = v + n * BUMPER_KICK
	if bumper_flash[i] <= 0.0:
		_sfx("res://sounds/fx/pin_bumper.wav", -10.0)
		add_score(POINTS["bumper"])
		_float_text("100", c + Vector2(0, -BUMPER_R))
	bumper_flash[i] = 0.15

func _collide_target(i: int) -> void:
	var r := Rect2(TARGETS[i] - TARGET_SIZE / 2.0, TARGET_SIZE)
	var p: Vector2 = ball["pos"]
	var q := Vector2(clampf(p.x, r.position.x, r.end.x), clampf(p.y, r.position.y, r.end.y))
	var d := p - q
	var dist := d.length()
	if dist >= BALL_R:
		return
	var n := d / dist if dist > 0.001 else Vector2.UP
	ball["pos"] = q + n * BALL_R
	var v: Vector2 = ball["vel"]
	var vn := v.dot(n)
	if vn < 0.0:
		v -= (1.0 + WALL_BOUNCE) * vn * n
	ball["vel"] = v
	# it drops
	targets_down[i] = true
	target_labels[i].modulate = Color(1, 1, 1, 0.0)
	_sfx("res://sounds/fx/pin_target.wav", -12.0)
	add_score(POINTS["target"])
	if not (false in targets_down):
		add_score(POINTS["yum"])
		_sfx("res://sounds/fx/pin_jackpot.wav", -9.0)
		_show_banner("YUM!  +1000", 1.0)
		get_tree().create_timer(1.6).timeout.connect(_reset_targets)

func _reset_targets() -> void:
	if not is_inside_tree():
		return
	targets_down = [false, false, false]
	for l in target_labels:
		l.modulate = Color.WHITE

func _collide_flipper(f: Dictionary) -> void:
	var a: Vector2 = f["pivot"]
	var b := _flip_tip(f)
	var p: Vector2 = ball["pos"]
	var ab := b - a
	var s := clampf((p - a).dot(ab) / ab.length_squared(), 0.0, 1.0)
	var q := a + ab * s
	var rad := lerpf(FLIP_R0, FLIP_R1, s)
	var d := p - q
	var dist := d.length()
	if dist >= BALL_R + rad or dist < 0.001:
		return
	var n := d / dist
	ball["pos"] = q + n * (BALL_R + rad)
	# the flipper's surface moves where the ball touches it (faster near the tip)
	var ang: float = f["angle"]
	var surf: Vector2 = Vector2(-f["sign"] * sin(ang), cos(ang)) * (s * FLIP_LEN) * f["vel"]
	var v: Vector2 = ball["vel"]
	var rel: Vector2 = v - surf
	var vn: float = rel.dot(n)
	if vn < 0.0:
		rel -= (1.0 + FLIP_BOUNCE) * vn * n
		ball["vel"] = rel + surf

# ================================================================== BALL EVENTS

func _serve(wait: float) -> void:
	ball["live"] = false
	pal_ball.visible = false
	saved_this_ball = false
	tilted = false
	nudges.clear()
	await get_tree().create_timer(wait).timeout
	if not is_running:
		return
	ball["pos"] = LAUNCH
	ball["vel"] = Vector2(randf_range(-220, -120), 0)
	ball["live"] = true
	pal_ball.visible = true

func _drain() -> void:
	# water boost: the first drain of every ball bounces it back up, once
	if PetState.boost == "splash" and not saved_this_ball:
		saved_this_ball = true
		ball["pos"] = Vector2(480, DRAIN_Y - 30)
		ball["vel"] = Vector2(randf_range(-90, 90), -1250)
		_sfx("res://sounds/fx/water_boing.wav", -10.0)
		_show_banner("Splash save!", 0.7)
		if drop_icon:
			drop_icon.modulate.a = 0.3
		return
	ball["live"] = false
	pal_ball.visible = false
	balls_left -= 1
	_refresh_hud()
	_sfx("res://sounds/fx/pin_drain.wav", -10.0)
	if balls_left <= 0:
		await get_tree().create_timer(0.6).timeout
		if is_running:
			end_game()
		return
	if drop_icon:
		drop_icon.modulate.a = 1.0
	_show_banner("Ball %d" % (BALLS - balls_left + 1), 0.8)
	_serve(1.3)

func _swallow() -> void:
	hole_timer = 1.0
	ball["pos"] = HOLE
	ball["vel"] = Vector2.ZERO
	pal_ball.visible = false
	_sfx("res://sounds/fx/pin_gulp.wav", -8.0)
	add_score(POINTS["hole"])
	_float_text("250", HOLE)

func _spit_out() -> void:
	ball["pos"] = HOLE + Vector2(30, 34)
	ball["vel"] = Vector2(320, 380)
	pal_ball.visible = true
	_sfx("res://sounds/fx/pin_bumper.wav", -12.0)

# ================================================================== NUDGE / TILT

func _nudge() -> void:
	if not ball["live"] or tilted or is_game_over:
		return
	if _clock - _last_nudge < 0.1:
		return                                     # (the same press read twice)
	_last_nudge = _clock
	nudges.append(_clock)
	while not nudges.is_empty() and _clock - nudges[0] > 3.5:
		nudges.pop_front()
	ball["vel"] += Vector2(randf_range(-160, 160), -340)
	var tw := create_tween()
	tw.tween_property(table_sprite, "position", Vector2(randf_range(-8, 8), -8), 0.05)
	tw.tween_property(table_sprite, "position", Vector2.ZERO, 0.12)
	_sfx("res://sounds/fx/pin_flipper.wav", -8.0)
	if nudges.size() >= 3:
		tilted = true
		_sfx("res://sounds/fx/pin_tilt.wav", -8.0)
		_show_banner("TILT!", 1.2)
	elif nudges.size() == 2:
		_show_banner("careful...", 0.6)

# ================================================================== DRAWING

func _create_nodes() -> void:
	var bg := ColorRect.new()
	bg.color = BACK
	bg.size = Vector2(PLAY_WIDTH, PLAY_HEIGHT)
	add_child(bg)
	view = SubViewport.new()
	view.size = Vector2i(int(ceil(PLAY_WIDTH / K)), int(ceil(PLAY_HEIGHT / K)))
	view.transparent_bg = true
	view.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	view.canvas_item_default_texture_filter = Viewport.DEFAULT_CANVAS_ITEM_TEXTURE_FILTER_NEAREST
	add_child(view)
	canvas = Node2D.new()
	canvas.scale = Vector2.ONE / K
	canvas.draw.connect(_draw_table)
	view.add_child(canvas)
	table_sprite = Sprite2D.new()
	table_sprite.centered = false
	table_sprite.texture = view.get_texture()
	table_sprite.scale = Vector2(K, K)
	table_sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	add_child(table_sprite)
	# Y U M letters on the targets
	for i in 3:
		var l := _make_label(TARGETS[i] - Vector2(30, 21), Vector2(60, 40), 22, HORIZONTAL_ALIGNMENT_CENTER, OUTLINE)
		l.text = TARGET_LETTERS[i]
		target_labels.append(l)
	# the ball: the pal itself (or a steel ball when there's no pal)
	pal_ball = Sprite2D.new()
	pal_ball.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	pal_ball.visible = false
	var frames: SpriteFrames = PetState.build_sprite_frames() if PetState.has_poop() else null
	if frames:
		var tex: Texture2D = frames.get_frame_texture("idle", 0)
		pal_ball.texture = tex
		var used := tex.get_image().get_used_rect()
		var body := Rect2(Vector2(used.position) - tex.get_size() / 2.0, used.size)
		pal_ball.offset = -body.get_center()
		var sc := (BALL_R * 2.4) / maxf(body.size.x, body.size.y)
		pal_ball.scale = Vector2(sc, sc)
	else:
		pal_ball.texture = _steel_ball_texture()
		pal_ball.scale = Vector2(K, K)
	add_child(pal_ball)
	# HUD: balls left (top left), score (top right)
	balls_box = HBoxContainer.new()
	balls_box.position = Vector2(34, 30)
	balls_box.add_theme_constant_override("separation", 10)
	add_child(balls_box)
	if PetState.boost == "splash":
		drop_icon = TextureRect.new()
		drop_icon.texture = PetState.boost_icon("splash")
		drop_icon.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		drop_icon.position = Vector2(36, 80)
		drop_icon.scale = Vector2(3, 3)
		add_child(drop_icon)
	var frame := ColorRect.new()
	frame.color = Color(0, 0, 0)
	frame.position = Vector2(PLAY_WIDTH - 230, 18)
	frame.size = Vector2(205, 70)
	add_child(frame)
	var box := ColorRect.new()
	box.color = Color(0.65, 0.72, 0.6)
	box.position = frame.position + Vector2(5, 5)
	box.size = frame.size - Vector2(10, 10)
	add_child(box)
	score_label = _make_label(box.position + Vector2(6, 0), box.size - Vector2(18, 0), 36, HORIZONTAL_ALIGNMENT_RIGHT, Color(0.2, 0.15, 0.05))
	banner = _make_label(Vector2(0, 640), Vector2(PLAY_WIDTH, 100), 54, HORIZONTAL_ALIGNMENT_CENTER, Color(1, 0.97, 0.9))
	banner.add_theme_color_override("font_outline_color", OUTLINE)
	banner.add_theme_constant_override("outline_size", 14)
	banner.modulate.a = 0.0

func _draw_table() -> void:
	var c := canvas
	# playfield
	c.draw_colored_polygon(field_poly, FIELD)
	for d in dots:
		c.draw_rect(Rect2(d - Vector2(3, 3), Vector2(6, 6)), FIELD_DOT)
	# belly button: a dark dimple with a swirl
	c.draw_circle(HOLE, HOLE_R + 12, OUTLINE)
	c.draw_circle(HOLE, HOLE_R + 6, Color8(120, 52, 66))
	c.draw_arc(HOLE, HOLE_R - 4, 0.3, 4.4, 10, Color8(70, 26, 40), 6)
	if hole_timer > 0.0:
		c.draw_circle(HOLE, HOLE_R + 6, GOLD.lerp(Color8(120, 52, 66), 0.5 + 0.5 * sin(_clock * 20.0)))
	# walls: dark outline under a cream rail
	for w in walls:
		if w[2] == "wall":
			c.draw_line(w[0], w[1], OUTLINE, 21)
	for w in walls:
		if w[2] == "wall":
			c.draw_line(w[0], w[1], WALL, 9)
	for p in arch:
		c.draw_circle(p, 10, OUTLINE)
	c.draw_polyline(arch, WALL, 9)
	# slingshots
	for s in 2:
		var p: PackedVector2Array = sling_polys[s]
		c.draw_colored_polygon(p, OUTLINE)
		var inner := PackedVector2Array()
		var ctr: Vector2 = (p[0] + p[1] + p[2]) / 3.0
		for v in p:
			inner.append(ctr + (v - ctr) * 0.7)
		c.draw_colored_polygon(inner, PINK_HI if sling_flash[s] > 0.0 else ORANGE)
		c.draw_line(p[0], p[2], WALL if sling_flash[s] > 0.0 else OUTLINE, 9)
	# bumpers: pink polyps
	for i in 3:
		var bc: Vector2 = BUMPERS[i]
		var lit: bool = bumper_flash[i] > 0.0
		c.draw_circle(bc, BUMPER_R + 6, OUTLINE)
		c.draw_circle(bc, BUMPER_R, Color.WHITE if lit else PINK)
		c.draw_circle(bc + Vector2(0, -6), BUMPER_R * 0.55, PINK if lit else PINK_HI)
		c.draw_circle(bc + Vector2(-9, -15), 6, Color.WHITE)
	# drop targets
	for i in 3:
		var r := Rect2(TARGETS[i] - TARGET_SIZE / 2.0, TARGET_SIZE)
		if targets_down[i]:
			c.draw_rect(r.grow_individual(0, -6, 0, -6), Color8(110, 50, 66))
		else:
			c.draw_rect(r.grow(6), OUTLINE)
			c.draw_rect(r, GOLD)
	# flippers: left orange (main button), right cream (forward button)
	for i in 2:
		var f: Dictionary = flippers[i]
		var a: Vector2 = f["pivot"]
		var b := _flip_tip(f)
		var col := ORANGE if i == 0 else CREAM
		_draw_capsule(c, a, b, FLIP_R0 + 6, FLIP_R1 + 6, OUTLINE)
		_draw_capsule(c, a, b, FLIP_R0, FLIP_R1, Color(0.45, 0.45, 0.45) if tilted else col)
		c.draw_circle(a, 6, OUTLINE)

func _draw_capsule(c: Node2D, a: Vector2, b: Vector2, r0: float, r1: float, col: Color) -> void:
	var dir := (b - a).normalized()
	var nrm := Vector2(-dir.y, dir.x)
	c.draw_colored_polygon(PackedVector2Array([a + nrm * r0, b + nrm * r1, b - nrm * r1, a - nrm * r0]), col)
	c.draw_circle(a, r0, col)
	c.draw_circle(b, r1, col)

func _update_ball_sprite(delta: float) -> void:
	if not ball["live"] or hole_timer > 0.0:
		return
	pal_ball.position = ball["pos"] + table_sprite.position
	# rolls: turns with its sideways speed
	ball["spin"] += ball["vel"].x / BALL_R * delta * 0.6
	pal_ball.rotation = ball["spin"]

static func _steel_ball_texture() -> Texture2D:
	var n := 15
	var img := Image.create(n, n, false, Image.FORMAT_RGBA8)
	for y in n:
		for x in n:
			var d := Vector2(x + 0.5 - n / 2.0, y + 0.5 - n / 2.0)
			if d.length() <= 7.4:
				var shade := 0.55 + 0.4 * clampf(-(d.x + d.y) / 10.0, -1.0, 1.0)
				img.set_pixel(x, y, Color(shade, shade, shade * 1.05) if d.length() < 6.4 else Color8(40, 30, 34))
	img.set_pixel(5, 4, Color.WHITE)
	img.set_pixel(4, 5, Color.WHITE)
	return ImageTexture.create_from_image(img)

# ================================================================== HUD / FX

func _refresh_hud() -> void:
	for ch in balls_box.get_children():
		ch.queue_free()
	for i in BALLS:
		var r := ColorRect.new()
		r.custom_minimum_size = Vector2(26, 26)
		r.color = CREAM if i < balls_left else Color(1, 1, 1, 0.15)
		balls_box.add_child(r)
	score_label.text = str(score)

func add_score(points: int) -> void:
	super.add_score(points)
	if score_label:
		score_label.add_theme_font_size_override("font_size", 36 if str(score).length() <= 5 else 30)
		score_label.text = str(score)

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
	move_child(banner, get_child_count() - 1)
	var t := create_tween()
	t.tween_property(banner, "modulate:a", 1.0, 0.12)
	t.tween_interval(hold)
	t.tween_property(banner, "modulate:a", 0.0, 0.3)

func _float_text(text: String, at: Vector2) -> void:
	var l := _make_label(at + Vector2(-60, -40), Vector2(120, 40), 26, HORIZONTAL_ALIGNMENT_CENTER, Color(1, 0.95, 0.85))
	l.add_theme_color_override("font_outline_color", OUTLINE)
	l.add_theme_constant_override("outline_size", 10)
	l.text = text
	var t := create_tween()
	t.tween_property(l, "position:y", l.position.y - 40, 0.5)
	t.parallel().tween_property(l, "modulate:a", 0.0, 0.5)
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

func _flipper_held(i: int) -> bool:
	return flippers[i]["held"] or i in _touch.values()

func _set_flipper(i: int, down: bool) -> void:
	var was := _flipper_held(i)
	flippers[i]["held"] = down
	if down and not was and is_running and not tilted:
		_sfx("res://sounds/fx/pin_flipper.wav", -9.0)

func on_main_button_pressed() -> void:
	if is_game_over:
		super.on_main_button_pressed()
		return
	_set_flipper(0, true)

func on_main_button_released() -> void:
	_set_flipper(0, false)

func on_forward_button_down() -> void:
	if not is_game_over:
		_set_flipper(1, true)

func on_forward_button_up() -> void:
	_set_flipper(1, false)

func on_forward_button_pressed() -> void:
	if is_game_over:
		super.on_forward_button_pressed()

## The speaker button nudges the table (sound_button.gd routes it here instead of muting)
func on_sound_button_pressed() -> void:
	_nudge()

func _input(event: InputEvent) -> void:
	if not (event is InputEventScreenTouch) or is_game_over:
		return
	if event.pressed:
		var b := _button_at(event.position)
		if b == 2:
			_nudge()
		elif b >= 0:
			var was := _flipper_held(b)
			_touch[event.index] = b
			if not was and is_running and not tilted:
				_sfx("res://sounds/fx/pin_flipper.wav", -9.0)
	else:
		_touch.erase(event.index)

func _button_at(screen_pos: Vector2) -> int:
	var paths := ["/root/PoopPal/Main UI/MainButton", "/root/PoopPal/Main UI/SoundButtons/ForwardButton", "/root/PoopPal/Main UI/SoundButtons/SoundButton"]
	for i in paths.size():
		var b := get_node_or_null(paths[i]) as Control
		if b and (b.get_global_transform_with_canvas() * Rect2(Vector2.ZERO, b.size)).grow(20).has_point(screen_pos):
			return i
	return -1

func _read_keys() -> void:
	var map := { KEY_LEFT: 0, KEY_A: 0, KEY_RIGHT: 1, KEY_D: 1, KEY_SPACE: 2, KEY_UP: 2 }
	for k in map:
		var down := Input.is_key_pressed(k)
		if down != _keys.get(k, false):
			if map[k] == 2:
				if down:
					_nudge()
			else:
				_set_flipper(map[k], down)
		_keys[k] = down

func freeze() -> void:
	super.freeze()
	for f in flippers:
		f["held"] = false

func end_game() -> void:
	for f in flippers:
		f["held"] = false
	_touch.clear()
	super.end_game()
