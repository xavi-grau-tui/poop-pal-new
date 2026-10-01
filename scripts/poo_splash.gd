extends BaseMinigame
## Splash Hoops — the classic water toy. Two pumps at the bottom of a water tank blow jets
## of bubbles; drop a ball into every basket before the timer runs out. A ball that lands
## in a basket lights it up and falls through, and the floor slopes down to the pumps, so
## every ball always rolls back next to a pump. From level 2 the baskets drift sideways.
##
## Main button: LEFT pump. Forward button: RIGHT pump. Both work the same way:
## hold to keep pumping (a pump runs dry after a moment), release to stop.
##
## How the baskets are reached (mapped with tools/design/splash_sim.py, keep it in sync):
##   100  one pump, on the OUTER ball of the pile (~0.7 s): the jet fans it outwards
##   200  one pump on the INNER ball, or a short push of both pumps
##   300  BOTH pumps held together: the two currents meet in the middle, pull balls to the
##        centre and rise up a column there; let go and the ball drops into the 300.
##        Too short and it doesn't get high enough.
## A ball sitting right on a nozzle goes straight up and back down with one pump only.
## Desktop: also Left/Right arrow keys (or A / D) for the two pumps.

const S := 3.0                          # world px per art pixel (sprites are drawn x3)
# Walls = the edges actually visible through the console's screen window
# (the window shows x 18..945, y 9..936 of the 950x948 play area)
const TANK_L := 18.0
const TANK_R := 945.0
const TANK_T := 12.0

# Funnel floor (matches tools/art/minigame_art.py): lowest at each nozzle
const NOZZLES := [237.0, 713.0]
const FLOOR_Y := 866.0
const FLOOR_SLOPE := 0.42

# --- Water physics ---
const GRAVITY := 380.0                  # things sink slowly
const DRAG := 1.4                       # velocity damping per second
const MAX_SPEED := 800.0
const JET_FORCE := 2600.0
const JET_TOP := 474.0                  # the thrust only acts below mid-screen; above it balls
										# fly on their momentum and just fall back down
const JET_SPREAD := 0.42                # cone widening per px of height
const CENTER_X := 475.0                 # between the two pumps
const MEET_PULL := 20.0                  # both pumps on: the currents pull towards the centre...
const MEET_DAMP := 5.5                  # ...and cancel each other there (no overshoot)
const MEET_MIN_H := 200.0               # (above the pile; baskets can be crossed from below)
const MEET_LIFT := 1900.0               # where they meet the water rises: a column up the middle
const MEET_WIDTH := 110.0
const PUMP_TIME := 0.9                  # held main pump runs dry after this long
const BOUNCE := 0.45

# --- Pieces ---
const BALL_R := 16.0
const CUP_W := 90.0
const CUP_H := 78.0
## Basket spots (see the reach map at the top): the 300 in the centre, below where the
## meeting currents lift the balls; the 200s where a single pump drops the inner ball, low
## enough that a ball carried diagonally to the centre passes over them; the 100s low on
## the outer sides (where a single pump throws the outer ball). None in the jet columns,
## none above another.
const CUP_SLOTS := [
	Vector2(325, 470), Vector2(475, 380), Vector2(625, 470),
	Vector2(130, 545), Vector2(820, 545),
]
const CUP_POINTS := [200, 300, 200, 100, 100]
const LEVEL_TIME := 60.0

const BALL_COLORS := ["pink", "yellow", "mint"]
const OUTLINE := Color8(74, 44, 32)

enum State { PLAY, CLEAR }

var state := State.PLAY
var level := 1
var time_left := LEVEL_TIME
var jets := [
	{ "x": NOZZLES[0], "power": 0.0, "held": false, "hold_time": 0.0 },
	{ "x": NOZZLES[1], "power": 0.0, "held": false, "hold_time": 0.0 },
]
var balls: Array[Dictionary] = []       # { pos, vel, node }
var cups: Array[Dictionary] = []        # { pos, home, rim, full, points, net, rim_node, label }
var bubbles: Array[Dictionary] = []

var tex := {}
var lcd_font: Font
var world: Node2D
var net_layer: Node2D
var bubble_layer: Node2D
var hud_level: Label
var hud_time: Label
var score_label: Label
var banner: Label
var rng := RandomNumberGenerator.new()
var _key_jets := [false, false]
# Phones: each console button only sees one finger (touch is turned into a single mouse), so
# both pumps read the touches directly: touch index -> pump held by that finger
var _touch_jets := {}

func _ready() -> void:
	game_music_path = "res://sounds/music/Underwater Arpeggio.mp3"
	lcd_font = load("res://fonts/pixChicago.ttf")
	for n in ["tank", "cup_rim", "cup_net", "nozzle", "bubble_big", "bubble_small"]:
		tex[n] = load("res://textures/minigames/splash/%s.png" % n)
	for c in BALL_COLORS:
		tex["ball_" + c] = load("res://textures/minigames/splash/ball_%s.png" % c)
	_create_static_nodes()
	super._ready()

func start_game() -> void:
	super.start_game()
	level = 1
	_build_level()
	_show_banner("Pump the water!", 1.6)

# ================================================================== LEVEL

func floor_at(x: float) -> float:
	var d := minf(absf(x - NOZZLES[0]), absf(x - NOZZLES[1]))
	return FLOOR_Y - FLOOR_SLOPE * d

func _build_level() -> void:
	for b in balls:
		b["node"].queue_free()
	for c in cups:
		for k in ["net", "rim_node", "label"]:
			c[k].queue_free()
	balls.clear()
	cups.clear()
	rng.seed = 4271 * level + 3

	var n_balls := 6                                 # 3 per pump; balls are reused, never used up
	time_left = LEVEL_TIME
	_place_cups()

	for i in n_balls:
		var jx: float = NOZZLES[i % 2]
		var pos := Vector2(jx + (i / 2 - 1) * 40.0, floor_at(jx) - 120.0 - (i / 2) * 30.0)
		var s := _sprite(tex["ball_" + BALL_COLORS[i % BALL_COLORS.size()]], pos)
		world.add_child(s)
		balls.append({ "pos": pos, "vel": Vector2.ZERO, "node": s })
	hud_level.text = "LV %d" % level
	state = State.PLAY

func _place_cups() -> void:
	for i in CUP_SLOTS.size():
		var p: Vector2 = CUP_SLOTS[i]
		var c := _make_cup(p, CUP_POINTS[i])
		c["home"] = p
		c["sway"] = minf(12.0 * (level - 1), 36.0)      # level 2+: baskets wobble a little (stay out of the jets)
		c["phase"] = i * 1.3
		cups.append(c)

func _make_cup(center: Vector2, points: int) -> Dictionary:
	# see-through net + solid rim, drawn over the balls (net_layer comes after world) so a
	# ball is seen falling through the basket and dropping out of the bottom of the net.
	# (Layering by tree order only: a z_index would escape the game screen's clip.)
	var net := _sprite(tex["cup_net"], center)
	net_layer.add_child(net)
	var rim := _sprite(tex["cup_rim"], center)
	net_layer.add_child(rim)
	var label := _make_label(center + Vector2(-45, -CUP_H / 2.0 - 34), Vector2(90, 30), 22, HORIZONTAL_ALIGNMENT_CENTER, Color(0.2, 0.3, 0.38))
	label.text = str(points)
	return { "pos": center, "rim": center.y - CUP_H / 2.0 + 12.0, "full": false, "points": points, "net": net, "rim_node": rim, "label": label }

# ================================================================== LOOP

func _process(delta: float) -> void:
	if not is_running:
		return
	_update_jets(delta)
	_update_bubbles(delta)
	if state == State.PLAY:
		time_left -= delta
		if time_left <= 0.0:
			time_left = 0.0
			_refresh_hud()
			end_game()
			return
		_move_cups(delta)
		const STEPS := 4
		for i in STEPS:
			_physics(delta / STEPS)
	for b in balls:
		b["node"].position = b["pos"]
		b["node"].rotation += b["vel"].x * delta / BALL_R
	_refresh_hud()

func _move_cups(delta: float) -> void:
	for c in cups:
		if c["sway"] <= 0.0:
			continue
		c["phase"] += delta * 0.8
		var p: Vector2 = c["home"] + Vector2(sin(c["phase"]) * c["sway"], 0)
		p.x = clampf(p.x, TANK_L + CUP_W / 2.0, TANK_R - CUP_W / 2.0)
		c["pos"] = p
		c["rim"] = p.y - CUP_H / 2.0 + 12.0
		c["net"].position.x = p.x
		c["rim_node"].position.x = p.x
		c["label"].position.x = p.x - 45

func _update_jets(delta: float) -> void:
	_key_jets = [Input.is_key_pressed(KEY_LEFT) or Input.is_key_pressed(KEY_A), Input.is_key_pressed(KEY_RIGHT) or Input.is_key_pressed(KEY_D)]
	for i in 2:
		var j: Dictionary = jets[i]
		var want := 0.0
		if j["held"] or _key_jets[i] or i in _touch_jets.values():
			j["hold_time"] += delta
			want = clampf(1.0 - (j["hold_time"] - PUMP_TIME) / 0.4, 0.0, 1.0)   # pump runs dry
		else:
			j["hold_time"] = 0.0
		var rate := 14.0 if want > j["power"] else 5.0
		j["power"] = move_toward(j["power"], want, rate * delta)
		if j["power"] > 0.05 and rng.randf() < j["power"] * delta * 40.0:
			_spawn_bubble(Vector2(j["x"] + rng.randf_range(-10, 10), FLOOR_Y - 20))
	# both pumps on: bubbles swirl in from both sides towards the middle
	var both: float = minf(jets[0]["power"], jets[1]["power"])
	if both > 0.2 and rng.randf() < both * delta * 30.0:
		var side := -1.0 if rng.randf() < 0.5 else 1.0
		_spawn_bubble(Vector2(CENTER_X + side * rng.randf_range(160, 260), rng.randf_range(420, 640)), -side * rng.randf_range(160, 260))

func _jet_force(p: Vector2, v: Vector2) -> Vector2:
	var f := Vector2.ZERO
	var h := FLOOR_Y - p.y
	# both pumps at once: the two currents meet in the middle of the tank
	var both: float = minf(jets[0]["power"], jets[1]["power"])
	if both > 0.01 and h > MEET_MIN_H:
		f.x += both * (MEET_PULL * (CENTER_X - p.x) - MEET_DAMP * v.x)
		var cx := (p.x - CENTER_X) / MEET_WIDTH
		f.y -= both * MEET_LIFT * exp(-cx * cx)
	if p.y < JET_TOP:
		return f
	var fade := clampf((p.y - JET_TOP) / 60.0, 0.0, 1.0)     # soft edge at mid-screen
	for j in jets:
		if j["power"] <= 0.01:
			continue
		var dx: float = p.x - j["x"]
		var w := 40.0 + h * JET_SPREAD
		var k: float = j["power"] * exp(-(dx / w) * (dx / w)) * fade
		# straight up at the nozzle, fanning out a little higher up
		var fan := clampf((h - 120.0) / 250.0, 0.0, 1.0)
		fan *= 1.0 - both                                       # meeting currents cancel the fan
		f += Vector2((signf(dx) * 0.3 + randf_range(-0.2, 0.2)) * fan, -1.0) * JET_FORCE * k
	return f

func _physics(dt: float) -> void:
	for b in balls:
		var v: Vector2 = b["vel"]
		v.y += GRAVITY * dt
		v += _jet_force(b["pos"], v) * dt
		v *= maxf(0.0, 1.0 - DRAG * dt)
		v = v.limit_length(MAX_SPEED)
		b["prev"] = b["pos"]
		b["pos"] += v * dt
		b["vel"] = v
		_collide_tank(b, dt)
		_collide_cups(b)
	# balls bump into each other
	for a in balls.size():
		for c in range(a + 1, balls.size()):
			var pa: Dictionary = balls[a]
			var pb: Dictionary = balls[c]
			var d: Vector2 = pb["pos"] - pa["pos"]
			var min_d := BALL_R * 2.0
			if d.length_squared() < min_d * min_d and d.length_squared() > 0.01:
				var n := d.normalized()
				var push := (min_d - d.length()) / 2.0
				pa["pos"] -= n * push
				pb["pos"] += n * push
				var rel: float = (pb["vel"] - pa["vel"]).dot(n)
				if rel < 0:
					pa["vel"] += n * rel * 0.5
					pb["vel"] -= n * rel * 0.5

func _collide_tank(b: Dictionary, dt: float) -> void:
	var pos: Vector2 = b["pos"]
	var v: Vector2 = b["vel"]
	if pos.x < TANK_L + BALL_R:
		pos.x = TANK_L + BALL_R; v.x = absf(v.x) * BOUNCE
	elif pos.x > TANK_R - BALL_R:
		pos.x = TANK_R - BALL_R; v.x = -absf(v.x) * BOUNCE
	if pos.y < TANK_T + BALL_R:
		pos.y = TANK_T + BALL_R; v.y = absf(v.y) * 0.3
	# sloped floor: everything rolls down to the nearest pump
	var fy := floor_at(pos.x)
	if pos.y > fy - BALL_R:
		pos.y = fy - BALL_R
		var near: float = NOZZLES[0] if absf(pos.x - NOZZLES[0]) < absf(pos.x - NOZZLES[1]) else NOZZLES[1]
		var side := signf(pos.x - near)
		# the floor rises away from the pump: dy/dx = -side * slope, so its upward normal is:
		var n := Vector2(-side * FLOOR_SLOPE, -1.0).normalized()
		var into := v.dot(n)
		if into < 0.0:
			v -= n * into * (1.0 + BOUNCE * 0.3)
		v.x -= side * 420.0 * dt                                  # roll down the slope
		if absf(pos.x - near) < 8.0:
			v.x *= 0.85                                           # settle right over the nozzle
	b["pos"] = pos
	b["vel"] = v

## Basket colliders, relative to the basket centre (from the basket art, x3):
## the two ends of the rim are round knobs; the net's slanted sides are solid walls (both
## sides: outside they push balls away, inside they guide a ball down through the net);
## the bottom of the net is an open hole both ways: balls fall out of it, and a ball pushed
## up from below can pass through the basket (it only scores coming down over the rim).
const RIM_KNOB_L := Vector2(-40, -22)
const RIM_KNOB_R := Vector2(40, -22)
const RIM_KNOB_R_SIZE := 8.0
const NET_WALL_L := [Vector2(-38, -12), Vector2(-27, 36)]
const NET_WALL_R := [Vector2(38, -12), Vector2(27, 36)]
const NET_WALL_THICK := 3.0
const RIM_LINE_Y := -16.0                # crossing this line downward between the knobs = in

func _collide_cups(b: Dictionary) -> void:
	for c in cups:
		var cp: Vector2 = c["pos"]
		var d: Vector2 = b["pos"] - cp
		if absf(d.x) > 80.0 or absf(d.y) > 80.0:
			continue
		# scoring: dropped in over the rim, between the knobs
		var prev_d: Vector2 = b.get("prev", b["pos"]) - cp
		if not c["full"] and b["vel"].y > 0 and prev_d.y <= RIM_LINE_Y and d.y > RIM_LINE_Y and absf(d.x) < RIM_KNOB_R.x - RIM_KNOB_R_SIZE:
			_fill_cup(b, c)
		# rim knobs
		for k in [RIM_KNOB_L, RIM_KNOB_R]:
			_bounce_off_point(b, cp + k, RIM_KNOB_R_SIZE)
		# net walls
		for w in [NET_WALL_L, NET_WALL_R]:
			var a: Vector2 = cp + w[0]
			var e: Vector2 = cp + w[1]
			var q := Geometry2D.get_closest_point_to_segment(b["pos"], a, e)
			_bounce_off_point(b, q, NET_WALL_THICK)

func _bounce_off_point(b: Dictionary, q: Vector2, r: float) -> void:
	var d: Vector2 = b["pos"] - q
	var min_d := BALL_R + r
	if d.length_squared() >= min_d * min_d:
		return
	var n := d.normalized() if d.length_squared() > 0.01 else Vector2.UP
	b["pos"] = q + n * min_d
	var v: Vector2 = b["vel"]
	var into := v.dot(n)
	if into < 0.0:
		v -= n * into * (1.0 + BOUNCE)
	if n.y < -0.9 and absf(v.x) < 40.0:
		# sitting right on top of a knob: tip it off, in or out
		v.x += (1.0 if randf() < 0.5 else -1.0) * 90.0
	b["vel"] = v

func _fill_cup(_b: Dictionary, c: Dictionary) -> void:
	c["full"] = true
	c["net"].modulate = Color(1.7, 1.3, 0.55)        # a filled basket lights up gold
	var tw := create_tween()
	tw.tween_property(c["rim_node"], "scale", Vector2(S * 1.15, S * 0.85), 0.08)
	tw.tween_property(c["rim_node"], "scale", Vector2(S, S), 0.2).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	c["label"].modulate.a = 0.3
	add_score(c["points"])
	_float_text("+%d" % c["points"], c["pos"])
	_sfx("res://sounds/fx/gamecoin.wav", -9.0)
	for q in cups:
		if not q["full"]:
			return
	_level_clear()

func _level_clear() -> void:
	state = State.CLEAR
	var bonus := int(time_left) * 5
	if bonus > 0:
		add_score(bonus)
	_show_banner("Clear! +%d" % bonus, 1.4)
	await get_tree().create_timer(1.8).timeout
	if not is_running:
		return
	level += 1
	_build_level()
	_show_banner("Level %d" % level, 1.0)

# ================================================================== BUBBLES

func _spawn_bubble(at: Vector2, vx := 0.0) -> void:
	var big := randf() < 0.35
	var s := _sprite(tex["bubble_big" if big else "bubble_small"], at)
	bubble_layer.add_child(s)
	bubbles.append({ "node": s, "vy": -randf_range(260, 420), "vx": vx, "phase": randf() * TAU, "x": at.x })

func _update_bubbles(delta: float) -> void:
	for i in range(bubbles.size() - 1, -1, -1):
		var b: Dictionary = bubbles[i]
		var n: Sprite2D = b["node"]
		b["phase"] += delta * 9.0
		n.position.y += b["vy"] * delta
		b["x"] += b["vx"] * delta
		b["vx"] *= maxf(0.0, 1.0 - 1.5 * delta)
		n.position.x = b["x"] + sin(b["phase"]) * 6.0
		if n.position.y < TANK_T + 16:
			n.queue_free()
			bubbles.remove_at(i)

# ================================================================== NODES / HUD

func _create_static_nodes() -> void:
	var bg := ColorRect.new()
	bg.color = OUTLINE
	bg.size = Vector2(PLAY_WIDTH, PLAY_HEIGHT)
	add_child(bg)
	var tank := _sprite(tex["tank"], Vector2.ZERO)
	tank.centered = false
	add_child(tank)

	# the current pal "printed" on the back panel, like the toy's artwork
	var frames: SpriteFrames = PetState.build_sprite_frames() if PetState.has_poop() else null
	if frames:
		var print_art := _sprite(frames.get_frame_texture("idle", 0), Vector2(PLAY_WIDTH / 2.0, 330))
		print_art.scale = Vector2(3.2, 3.2)
		print_art.modulate = Color(1, 1, 1, 0.16)
		add_child(print_art)

	for x in NOZZLES:
		add_child(_sprite(tex["nozzle"], Vector2(x, FLOOR_Y - 12)))

	world = Node2D.new()
	add_child(world)
	net_layer = Node2D.new()
	add_child(net_layer)
	bubble_layer = Node2D.new()
	add_child(bubble_layer)

	hud_level = _make_label(Vector2(40, 34), Vector2(160, 52), 38, HORIZONTAL_ALIGNMENT_LEFT, Color(0.2, 0.3, 0.38))
	hud_time = _make_label(Vector2(PLAY_WIDTH / 2 - 85, 34), Vector2(170, 52), 38, HORIZONTAL_ALIGNMENT_CENTER, Color(0.2, 0.3, 0.38))
	var frame := ColorRect.new()
	frame.color = Color(0, 0, 0)
	frame.position = Vector2(PLAY_WIDTH - 245, 30)
	frame.size = Vector2(205, 70)
	add_child(frame)
	var box := ColorRect.new()
	box.color = Color(0.65, 0.72, 0.6)   # LCD green, like the other games
	box.position = frame.position + Vector2(5, 5)
	box.size = frame.size - Vector2(10, 10)
	add_child(box)
	score_label = _make_label(box.position + Vector2(6, 0), box.size - Vector2(18, 0), 36, HORIZONTAL_ALIGNMENT_RIGHT, Color(0.2, 0.15, 0.05))

	banner = _make_label(Vector2(0, PLAY_HEIGHT / 2 - 60), Vector2(PLAY_WIDTH, 120), 54, HORIZONTAL_ALIGNMENT_CENTER, Color(1, 0.97, 0.9))
	banner.add_theme_color_override("font_outline_color", OUTLINE)
	banner.add_theme_constant_override("outline_size", 14)
	banner.modulate.a = 0.0

func _refresh_hud() -> void:
	hud_time.text = "%d" % ceili(time_left)
	hud_time.add_theme_color_override("font_color", Color(0.75, 0.15, 0.2) if time_left < 10.0 else Color(0.2, 0.3, 0.38))
	score_label.add_theme_font_size_override("font_size", 36 if str(score).length() <= 5 else 30)
	score_label.text = str(score)

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
	var l := _make_label(at + Vector2(-60, -70), Vector2(120, 40), 28, HORIZONTAL_ALIGNMENT_CENTER, Color(1, 0.95, 0.85))
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
	var sound_btn = get_node_or_null("/root/PoopPal/Main UI/SoundButtons/SoundButton")
	if sound_btn and sound_btn.button_pressed:
		sfx.volume_db = linear_to_db(0.0)
	add_child(sfx)
	sfx.play()
	sfx.finished.connect(sfx.queue_free)
	if max_time > 0.0:
		get_tree().create_timer(max_time).timeout.connect(func():
			if is_instance_valid(sfx):
				sfx.queue_free())

# ================================================================== INPUT

func on_main_button_pressed() -> void:
	if is_game_over:
		super.on_main_button_pressed()
		return
	_pump(0, true)

func on_main_button_released() -> void:
	_pump(0, false)

func on_forward_button_down() -> void:
	if not is_game_over:
		_pump(1, true)

func on_forward_button_up() -> void:
	_pump(1, false)

func on_forward_button_pressed() -> void:
	# (fires on release, after on_forward_button_up) only used on the game over screen
	if is_game_over:
		super.on_forward_button_pressed()

func _input(event: InputEvent) -> void:
	if not (event is InputEventScreenTouch) or not is_running or is_game_over:
		return
	if event.pressed:
		var j := _pump_at(event.position)
		if j >= 0:
			if not _pump_active(j):
				_sfx("res://sounds/fx/underwater-247531.mp3", -14.0, 0.6)
			_touch_jets[event.index] = j
	else:
		_touch_jets.erase(event.index)

## Which pump button a screen position is on (0 = main, 1 = forward, -1 = neither)
func _pump_at(screen_pos: Vector2) -> int:
	var paths := ["/root/PoopPal/Main UI/MainButton", "/root/PoopPal/Main UI/SoundButtons/ForwardButton"]
	for i in paths.size():
		var b := get_node_or_null(paths[i]) as Control
		if b and (b.get_global_transform_with_canvas() * Rect2(Vector2.ZERO, b.size)).grow(20).has_point(screen_pos):
			return i
	return -1

func _pump_active(i: int) -> bool:
	return jets[i]["held"] or i in _touch_jets.values()

func _pump(i: int, down: bool) -> void:
	var was := _pump_active(i)
	jets[i]["held"] = down
	if down and not was:
		_sfx("res://sounds/fx/underwater-247531.mp3", -14.0, 0.6)

func end_game() -> void:
	jets[0]["held"] = false
	jets[1]["held"] = false
	super.end_game()        # (its overlay is added last, so it covers the baskets)
