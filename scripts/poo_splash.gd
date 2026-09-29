extends BaseMinigame
## Poo Splash — the classic water toy. Two pumps at the bottom of a water tank blow jets
## of bubbles; shoot the balls up into the baskets before the timer runs out. Higher
## baskets are worth more. The bottom is a pachinko: balls that miss bounce down through
## the pins and the sloped floor always rolls them back onto a pump.
##
## Main button: LEFT pump (hold to keep pumping, it runs dry after a moment).
## Forward button: a quick burst from the RIGHT pump.
## Desktop: also Left/Right arrow keys (or A / D) for the two pumps.

const S := 3.0                          # world px per art pixel (sprites are drawn x3)
const TANK_L := 24.0                    # water area inside the plastic frame
const TANK_R := 926.0
const TANK_T := 24.0

# Funnel floor (matches tools/art/minigame_art.py): lowest at each nozzle
const NOZZLES := [237.0, 713.0]
const FLOOR_Y := 866.0
const FLOOR_SLOPE := 0.42

# --- Water physics ---
const GRAVITY := 260.0                  # things sink slowly
const DRAG := 1.4                       # velocity damping per second
const MAX_SPEED := 800.0
const JET_FORCE := 1850.0
const JET_REACH := 780.0                # height where the jet has faded out
const JET_SPREAD := 0.42                # cone widening per px of height
const PUMP_TIME := 0.9                  # held main pump runs dry after this long
const BURST_TIME := 0.6                 # forward burst length
const BOUNCE := 0.45

# --- Pieces ---
const BALL_R := 16.0
const PIN_R := 9.0
const CUP_W := 90.0
const CUP_H := 78.0
const JET_CLEAR := 95.0                 # no pins this close to a nozzle column
const LEVEL_TIME := 60.0

const BALL_COLORS := ["pink", "yellow", "mint"]
const OUTLINE := Color8(74, 44, 32)

enum State { PLAY, CLEAR }

var state := State.PLAY
var level := 1
var time_left := LEVEL_TIME
var jets := [
	{ "x": NOZZLES[0], "power": 0.0, "held": false, "hold_time": 0.0, "burst": 0.0 },
	{ "x": NOZZLES[1], "power": 0.0, "held": false, "hold_time": 0.0, "burst": 0.0 },
]
var balls: Array[Dictionary] = []       # { pos, vel, node, done }
var cups: Array[Dictionary] = []        # { pos, rim, full, points, back, front, label }
var pins: Array[Vector2] = []
var bubbles: Array[Dictionary] = []

var tex := {}
var lcd_font: Font
var world: Node2D
var pin_layer: Node2D
var bubble_layer: Node2D
var hud_level: Label
var hud_time: Label
var score_label: Label
var banner: Label
var rng := RandomNumberGenerator.new()
var _key_jets := [false, false]

func _ready() -> void:
	game_music_path = "res://sounds/music/Frédéric Chopin - Nocturne： Op. 9 No. 2 [8 bits].mp3"
	lcd_font = load("res://fonts/pixChicago.ttf")
	for n in ["tank", "cup_back", "cup_front", "nozzle", "bubble_big", "bubble_small", "pin"]:
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
		for k in ["back", "front", "label"]:
			c[k].queue_free()
	for p in pin_layer.get_children():
		p.queue_free()
	balls.clear()
	cups.clear()
	pins.clear()
	rng.seed = 4271 * level + 3

	var n_balls := mini(3 + level, 9)
	var n_cups := mini(n_balls + 3, 12)
	time_left = LEVEL_TIME + n_balls * 3.0
	_place_cups(n_cups)
	_place_pins()

	for i in n_balls:
		var jx: float = NOZZLES[i % 2]
		var pos := Vector2(jx + rng.randf_range(-120, 120), 640.0 - rng.randf() * 80.0)
		var s := _sprite(tex["ball_" + BALL_COLORS[i % BALL_COLORS.size()]], pos)
		world.add_child(s)
		balls.append({ "pos": pos, "vel": Vector2.ZERO, "node": s, "done": false })
	hud_level.text = "LV %d" % level
	state = State.PLAY

func _place_cups(n: int) -> void:
	# spread over the upper tank on a jittered grid; higher = more points
	var cols := 4
	var slots: Array[Vector2] = []
	for r in 3:
		for c in cols:
			var x := TANK_L + 90.0 + c * (TANK_R - TANK_L - 180.0) / (cols - 1)
			slots.append(Vector2(x + (60.0 if r % 2 == 1 else 0.0) - 30.0, 190.0 + r * 150.0))
	for i in range(slots.size() - 1, 0, -1):             # seeded shuffle: same layout per level
		var j := rng.randi_range(0, i)
		var tmp := slots[i]
		slots[i] = slots[j]
		slots[j] = tmp
	for i in mini(n, slots.size()):
		var p := slots[i] + Vector2(rng.randf_range(-25, 25), rng.randf_range(-20, 20))
		var points := 300 if p.y < 280 else (200 if p.y < 430 else 100)
		cups.append(_make_cup(p, points))

func _place_pins() -> void:
	# pachinko rows above the funnels, leaving a clear column over each pump
	for r in 4:
		var y := 600.0 + r * 46.0
		var x := TANK_L + 36.0 + (34.0 if r % 2 == 1 else 0.0)
		while x < TANK_R - 20.0:
			var near_jet := absf(x - NOZZLES[0]) < JET_CLEAR or absf(x - NOZZLES[1]) < JET_CLEAR
			var near_wall := x < TANK_L + 50.0 or x > TANK_R - 50.0
			if not near_jet and not near_wall and y < floor_at(x) - 75.0:   # room for balls to roll under
				pins.append(Vector2(x, y))
				pin_layer.add_child(_sprite(tex["pin"], Vector2(x, y)))
			x += 68.0

func _make_cup(center: Vector2, points: int) -> Dictionary:
	var back := _sprite(tex["cup_back"], center)
	world.add_child(back)
	world.move_child(back, 0)
	var front := _sprite(tex["cup_front"], center)
	front.z_index = 1                                   # in front of the ball it catches
	world.add_child(front)
	var label := _make_label(center + Vector2(-45, -CUP_H / 2.0 - 34), Vector2(90, 30), 22, HORIZONTAL_ALIGNMENT_CENTER, Color(0.2, 0.3, 0.38))
	label.text = str(points)
	return { "pos": center, "rim": center.y - CUP_H / 2.0 + 12.0, "full": false, "points": points, "back": back, "front": front, "label": label }

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
		const STEPS := 4
		for i in STEPS:
			_physics(delta / STEPS)
		_check_cups()
	for b in balls:
		if not b["done"]:
			b["node"].position = b["pos"]
			b["node"].rotation += b["vel"].x * delta / BALL_R
	_refresh_hud()

func _update_jets(delta: float) -> void:
	_key_jets = [Input.is_key_pressed(KEY_LEFT) or Input.is_key_pressed(KEY_A), Input.is_key_pressed(KEY_RIGHT) or Input.is_key_pressed(KEY_D)]
	for i in 2:
		var j: Dictionary = jets[i]
		var want := 0.0
		if j["held"] or _key_jets[i]:
			j["hold_time"] += delta
			want = clampf(1.0 - (j["hold_time"] - PUMP_TIME) / 0.4, 0.0, 1.0)   # pump runs dry
		else:
			j["hold_time"] = 0.0
		if j["burst"] > 0.0:
			j["burst"] -= delta
			want = maxf(want, clampf(j["burst"] / BURST_TIME * 1.6, 0.0, 1.0))
		var rate := 14.0 if want > j["power"] else 5.0
		j["power"] = move_toward(j["power"], want, rate * delta)
		if j["power"] > 0.05 and rng.randf() < j["power"] * delta * 40.0:
			_spawn_bubble(Vector2(j["x"] + rng.randf_range(-10, 10), FLOOR_Y - 20))

func _jet_force(p: Vector2) -> Vector2:
	var f := Vector2.ZERO
	for j in jets:
		if j["power"] <= 0.01:
			continue
		var h := FLOOR_Y - p.y
		if h < 0:
			continue
		var dx: float = p.x - j["x"]
		var w := 40.0 + h * JET_SPREAD
		var fall := clampf(1.0 - h / JET_REACH, 0.15, 1.0)
		var k: float = j["power"] * exp(-(dx / w) * (dx / w)) * fall
		# straight up at the nozzle, fanning out higher up (so balls leave the pit upwards)
		var fan := clampf((h - 120.0) / 350.0, 0.0, 1.0)
		f += Vector2((signf(dx) * 0.4 + randf_range(-0.25, 0.25)) * fan, -1.0) * JET_FORCE * k
		# the whole tank churns a little: a wide, weak current that swirls away from the jet
		var wide: float = j["power"] * exp(-(dx / (w * 4.0)) * (dx / (w * 4.0))) * 0.2
		f += Vector2(signf(dx) * 0.8 * fan, -0.6) * JET_FORCE * wide
	return f

func _physics(dt: float) -> void:
	for b in balls:
		if b["done"]:
			continue
		var v: Vector2 = b["vel"]
		v.y += GRAVITY * dt
		v += _jet_force(b["pos"]) * dt
		v *= maxf(0.0, 1.0 - DRAG * dt)
		v = v.limit_length(MAX_SPEED)
		b["prev"] = b["pos"]
		b["pos"] += v * dt
		b["vel"] = v
		_collide_tank(b, dt)
		_collide_pins(b)
		_collide_cups(b)
	# balls bump into each other
	for a in balls.size():
		for c in range(a + 1, balls.size()):
			var pa: Dictionary = balls[a]
			var pb: Dictionary = balls[c]
			if pa["done"] or pb["done"]:
				continue
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
		var n := Vector2(side * FLOOR_SLOPE, -1.0).normalized()   # surface normal (up)
		var into := v.dot(n)
		if into < 0.0:
			v -= n * into * (1.0 + BOUNCE * 0.3)
		v.x -= side * 420.0 * dt                                  # roll down the slope
		if absf(pos.x - near) < 8.0:
			v.x *= 0.85                                           # settle right over the nozzle
	b["pos"] = pos
	b["vel"] = v

func _collide_pins(b: Dictionary) -> void:
	for p in pins:
		var d: Vector2 = b["pos"] - p
		var min_d := BALL_R + PIN_R
		if d.length_squared() < min_d * min_d:
			var n := d.normalized() if d.length_squared() > 0.01 else Vector2.UP
			b["pos"] = p + n * min_d
			var v: Vector2 = b["vel"]
			var into := v.dot(n)
			if into < 0.0:
				v -= n * into * (1.0 + BOUNCE)
				v.x += randf_range(-30, 30)                        # pachinko chaos
			if absf(n.x) < 0.35 and n.y < 0.0:
				v.x += (1.0 if randf() < 0.5 else -1.0) * 60.0     # never balance on top of a pin
			b["vel"] = v

func _collide_cups(b: Dictionary) -> void:
	# cup walls are solid; only the open top of an empty cup lets a ball in
	for c in cups:
		var half := Vector2(CUP_W / 2.0, CUP_H / 2.0)
		var d: Vector2 = b["pos"] - c["pos"]
		if absf(d.x) >= half.x + BALL_R or absf(d.y) >= half.y + BALL_R:
			continue
		var in_mouth: bool = not c["full"] and absf(d.x) < half.x - BALL_R and b["pos"].y < c["rim"] + 6
		if in_mouth:
			continue
		var ox: float = half.x + BALL_R - absf(d.x)
		var oy: float = half.y + BALL_R - absf(d.y)
		if ox < oy:
			b["pos"].x += signf(d.x) * ox
			b["vel"].x *= -BOUNCE
		else:
			b["pos"].y += signf(d.y) * oy
			b["vel"].y *= -BOUNCE

func _check_cups() -> void:
	for b in balls:
		if b["done"] or not b.has("prev"):
			continue
		for c in cups:
			if c["full"]:
				continue
			var dx: float = absf(b["pos"].x - c["pos"].x)
			if b["vel"].y > 0 and dx < CUP_W / 2.0 - BALL_R and b["prev"].y <= c["rim"] and b["pos"].y > c["rim"]:
				_score_ball(b, c)
				break

func _score_ball(b: Dictionary, c: Dictionary) -> void:
	b["done"] = true
	c["full"] = true
	var rest: Vector2 = c["pos"] + Vector2(0, CUP_H / 2.0 - 30.0)
	var tw := create_tween()
	tw.tween_property(b["node"], "position", rest, 0.3).set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)
	b["pos"] = rest
	c["label"].modulate.a = 0.3
	add_score(c["points"])
	_float_text("+%d" % c["points"], rest)
	_sfx("res://sounds/fx/gamecoin.wav", -9.0)
	for q in balls:
		if not q["done"]:
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

func _spawn_bubble(at: Vector2) -> void:
	var big := randf() < 0.35
	var s := _sprite(tex["bubble_big" if big else "bubble_small"], at)
	bubble_layer.add_child(s)
	bubbles.append({ "node": s, "vy": -randf_range(260, 420), "phase": randf() * TAU, "x": at.x })

func _update_bubbles(delta: float) -> void:
	for i in range(bubbles.size() - 1, -1, -1):
		var b: Dictionary = bubbles[i]
		var n: Sprite2D = b["node"]
		b["phase"] += delta * 9.0
		n.position.y += b["vy"] * delta
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

	pin_layer = Node2D.new()
	add_child(pin_layer)
	world = Node2D.new()
	add_child(world)
	bubble_layer = Node2D.new()
	bubble_layer.z_index = 2
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
	banner.z_index = 3

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
	l.z_index = 3
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
	jets[0]["held"] = true
	_sfx("res://sounds/fx/underwater-247531.mp3", -14.0, 0.6)

func on_main_button_released() -> void:
	jets[0]["held"] = false

func on_forward_button_pressed() -> void:
	if is_game_over:
		super.on_forward_button_pressed()
		return
	jets[1]["burst"] = BURST_TIME
	_sfx("res://sounds/fx/underwater-247531.mp3", -14.0, 0.5)

func end_game() -> void:
	jets[0]["held"] = false
	super.end_game()
