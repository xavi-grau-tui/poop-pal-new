extends BaseMinigame
## Poo Splash — the classic water ring toy. Two nozzles at the bottom of a water tank
## blow jets of bubbles; float the rings onto the pegs (odd levels) or the balls into
## the cups (even levels) before the timer runs out.
##
## Main button: LEFT jet (hold to keep pumping, the pump runs dry after a moment).
## Forward button: a quick burst from the RIGHT jet.
## Desktop: also Left/Right arrow keys (or A / D) for the two jets.

const S := 3.0                          # world px per art pixel (sprites are drawn x3)
const TANK_L := 24.0                    # water area inside the plastic frame
const TANK_R := 926.0
const TANK_T := 24.0
const FLOOR_Y := 866.0

# --- Water physics ---
const GRAVITY := 230.0                  # things sink slowly
const DRAG := 1.5                       # velocity damping per second
const MAX_SPEED := 760.0
const JET_FORCE := 1500.0
const JET_REACH := 760.0                # height where the jet has faded out
const JET_SPREAD := 0.42                # cone widening per px of height
const PUMP_TIME := 0.9                  # held main jet runs dry after this long
const BURST_TIME := 0.45                # forward burst length

# --- Pieces ---
const RING_R := 30.0                    # collision radius (ring 22 art px wide)
const BALL_R := 16.0
const PEG_HALF := 7.0                   # half width of the peg stick
const PEG_H := 180.0                    # peg height (60 art px)
const HOOK_TOL := 16.0                  # how centred a ring must be to hook
const CUP_W := 90.0
const CUP_H := 78.0
const RING_STACK := 16.0
const LEVEL_TIME := 60.0

const RING_COLORS := ["pink", "yellow", "mint", "blue"]
const BALL_COLORS := ["pink", "yellow", "mint"]
const OUTLINE := Color8(74, 44, 32)

enum State { PLAY, CLEAR }

var state := State.PLAY
var level := 1
var time_left := LEVEL_TIME
var jets := [
	{ "x": 190.0, "power": 0.0, "held": false, "hold_time": 0.0, "burst": 0.0 },
	{ "x": 760.0, "power": 0.0, "held": false, "hold_time": 0.0, "burst": 0.0 },
]
var pieces: Array[Dictionary] = []      # { kind, pos, vel, r, node, tumble, spin, done }
var targets: Array[Dictionary] = []     # { kind, pos, count, back, front }
var bubbles: Array[Dictionary] = []

var tex := {}
var lcd_font: Font
var world: Node2D
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
	for n in ["tank", "peg", "cup_back", "cup_front", "nozzle", "bubble_big", "bubble_small"]:
		tex[n] = load("res://textures/minigames/splash/%s.png" % n)
	for c in RING_COLORS:
		tex["ring_" + c] = load("res://textures/minigames/splash/ring_%s.png" % c)
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

func _build_level() -> void:
	for p in pieces:
		p["node"].queue_free()
	for t in targets:
		for k in ["back", "front", "stick"]:
			if t.has(k):
				t[k].queue_free()
	pieces.clear()
	targets.clear()
	rng.seed = 4271 * level + 3

	var rings := level % 2 == 1
	var n_targets := 2 + int(level >= 3) + int(level >= 7)
	var n_pieces := mini(2 + (level + 1) / 2, 8)
	time_left = LEVEL_TIME + n_pieces * 4.0

	# targets spread across the tank, a bit of random height for variety
	var span := (TANK_R - TANK_L) / n_targets
	for i in n_targets:
		var x := TANK_L + span * (i + 0.5) + rng.randf_range(-span * 0.15, span * 0.15)
		if rings:
			var base_y := FLOOR_Y - rng.randf_range(0.0, 140.0) * float(level > 2)
			targets.append(_make_peg(Vector2(x, base_y)))
		else:
			var y := rng.randf_range(330.0, 560.0)
			targets.append(_make_cup(Vector2(x, y)))

	for i in n_pieces:
		var pos := Vector2(rng.randf_range(TANK_L + 60, TANK_R - 60), FLOOR_Y - 40 - rng.randf() * 30)
		if rings:
			pieces.append(_make_piece("ring", RING_COLORS[i % RING_COLORS.size()], pos, RING_R))
		else:
			pieces.append(_make_piece("ball", BALL_COLORS[i % BALL_COLORS.size()], pos, BALL_R))
	hud_level.text = "LV %d" % level
	state = State.PLAY

func _make_piece(kind: String, color: String, pos: Vector2, r: float) -> Dictionary:
	var s := _sprite(tex[kind + "_" + color], pos)
	world.add_child(s)
	return { "kind": kind, "pos": pos, "vel": Vector2.ZERO, "r": r, "node": s,
		"tumble": rng.randf() * TAU, "spin": 0.0, "done": false }

func _make_peg(base: Vector2) -> Dictionary:
	var stick := _sprite(tex["peg"], base - Vector2(0, PEG_H / 2.0))
	world.add_child(stick)
	world.move_child(stick, 0)
	return { "kind": "peg", "pos": base, "top": base.y - PEG_H + 6.0, "count": 0, "stick": stick }

func _make_cup(center: Vector2) -> Dictionary:
	var back := _sprite(tex["cup_back"], center)
	world.add_child(back)
	world.move_child(back, 0)
	var front := _sprite(tex["cup_front"], center)
	front.z_index = 1                                   # in front of the balls it catches
	world.add_child(front)
	return { "kind": "cup", "pos": center, "rim": center.y - CUP_H / 2.0 + 12.0, "count": 0, "back": back, "front": front }

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
		const STEPS := 3
		for i in STEPS:
			_physics(delta / STEPS)
		_check_targets()
	for p in pieces:
		_draw_piece(p, delta)
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
		# bubbles
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
		f += Vector2(signf(dx) * 0.35 + rng.randf_range(-0.25, 0.25), -1.0) * JET_FORCE * k
		# the whole tank churns a little: a wide, weak current that swirls away from the jet
		var wide: float = j["power"] * exp(-(dx / (w * 4.0)) * (dx / (w * 4.0))) * 0.22
		f += Vector2(signf(dx) * 0.8, -0.6) * JET_FORCE * wide
	return f

func _physics(dt: float) -> void:
	for p in pieces:
		if p["done"]:
			continue
		var v: Vector2 = p["vel"]
		v.y += GRAVITY * dt
		v += _jet_force(p["pos"]) * dt
		v *= maxf(0.0, 1.0 - DRAG * dt)
		v = v.limit_length(MAX_SPEED)
		var prev: Vector2 = p["pos"]
		p["pos"] = prev + v * dt
		p["vel"] = v
		p["prev"] = prev
		_collide_tank(p)
		_collide_targets(p)
	# pieces bump into each other
	for a in pieces.size():
		for b in range(a + 1, pieces.size()):
			var pa: Dictionary = pieces[a]
			var pb: Dictionary = pieces[b]
			if pa["done"] or pb["done"]:
				continue
			var d: Vector2 = pb["pos"] - pa["pos"]
			var min_d: float = (pa["r"] + pb["r"]) * 0.8
			if d.length_squared() < min_d * min_d and d.length_squared() > 0.01:
				var n := d.normalized()
				var push := (min_d - d.length()) / 2.0
				pa["pos"] -= n * push
				pb["pos"] += n * push
				var rel: float = (pb["vel"] - pa["vel"]).dot(n)
				if rel < 0:
					pa["vel"] += n * rel * 0.5
					pb["vel"] -= n * rel * 0.5

func _collide_tank(p: Dictionary) -> void:
	var r: float = p["r"]
	var pos: Vector2 = p["pos"]
	var v: Vector2 = p["vel"]
	if pos.x < TANK_L + r:
		pos.x = TANK_L + r; v.x = absf(v.x) * 0.4
	elif pos.x > TANK_R - r:
		pos.x = TANK_R - r; v.x = -absf(v.x) * 0.4
	if pos.y < TANK_T + r:
		pos.y = TANK_T + r; v.y = absf(v.y) * 0.3
	var floor_r := r * (0.45 if p["kind"] == "ring" else 1.0)   # rings lie flat on the sand
	if pos.y > FLOOR_Y - floor_r:
		pos.y = FLOOR_Y - floor_r
		v.y = minf(v.y, 0.0)
		v.x *= 0.92
	p["pos"] = pos
	p["vel"] = v

func _collide_targets(p: Dictionary) -> void:
	for t in targets:
		if t["kind"] == "peg":
			# the stick is solid for anything not threaded on it
			var dx: float = p["pos"].x - t["pos"].x
			var r: float = p["r"] * (0.35 if p["kind"] == "ring" else 1.0)
			if p["pos"].y > t["top"] and absf(dx) < PEG_HALF + r:
				if p["kind"] == "ring" and absf(dx) < HOOK_TOL:
					continue                                    # centred: it's being threaded
				p["pos"].x = t["pos"].x + signf(dx if dx != 0 else 1.0) * (PEG_HALF + r)
				p["vel"].x *= -0.3
		else:
			# cup walls are solid; only the open top lets things in
			var c: Vector2 = t["pos"]
			var half := Vector2(CUP_W / 2.0, CUP_H / 2.0)
			var d: Vector2 = p["pos"] - c
			if absf(d.x) < half.x + p["r"] and absf(d.y) < half.y + p["r"]:
				var inside_mouth: bool = p["kind"] == "ball" and absf(d.x) < half.x - p["r"] and p["pos"].y < t["rim"] + 6
				if inside_mouth:
					continue
				var ox: float = half.x + p["r"] - absf(d.x)
				var oy: float = half.y + p["r"] - absf(d.y)
				if ox < oy:
					p["pos"].x += signf(d.x) * ox
					p["vel"].x *= -0.35
				else:
					p["pos"].y += signf(d.y) * oy
					p["vel"].y *= -0.35

func _check_targets() -> void:
	for p in pieces:
		if p["done"] or not p.has("prev"):
			continue
		for t in targets:
			if t["kind"] == "peg" and p["kind"] == "ring":
				var dx: float = absf(p["pos"].x - t["pos"].x)
				if p["vel"].y > 0 and dx < HOOK_TOL and p["prev"].y <= t["top"] and p["pos"].y > t["top"]:
					_score_piece(p, t, Vector2(t["pos"].x, t["pos"].y - 16 - t["count"] * RING_STACK))
					break
			elif t["kind"] == "cup" and p["kind"] == "ball":
				var dx: float = absf(p["pos"].x - t["pos"].x)
				if p["vel"].y > 0 and dx < CUP_W / 2.0 - BALL_R and p["prev"].y <= t["rim"] and p["pos"].y > t["rim"]:
					var slot: int = t["count"]
					var rest: Vector2 = t["pos"] + Vector2((slot % 3 - 1) * 24.0, CUP_H / 2.0 - 26.0 - (slot / 3) * 22.0)
					_score_piece(p, t, rest)
					break

func _score_piece(p: Dictionary, t: Dictionary, rest: Vector2) -> void:
	p["done"] = true
	t["count"] += 1
	p["vel"] = Vector2.ZERO
	var node: Sprite2D = p["node"]
	var tw := create_tween()
	tw.tween_property(node, "position", rest, 0.35).set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)
	p["pos"] = rest
	add_score(100)
	_float_text("+100", rest)
	_sfx("res://sounds/fx/gamecoin.wav", -9.0)
	for q in pieces:
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

# ================================================================== DRAWING

func _draw_piece(p: Dictionary, delta: float) -> void:
	var node: Sprite2D = p["node"]
	if p["done"]:
		if p["kind"] == "ring":
			node.scale.y = lerpf(node.scale.y, S * 0.38, minf(1.0, delta * 10.0))   # lies flat on the peg
			node.rotation = lerp_angle(node.rotation, 0.0, minf(1.0, delta * 10.0))
		return
	node.position = p["pos"]
	if p["kind"] == "ring":
		# tumbling in the water: the ring turns in 3D, faked by squashing it
		var v: Vector2 = p["vel"]
		p["tumble"] += (v.length() * 0.012 + 0.3) * delta
		var on_floor: bool = p["pos"].y >= FLOOR_Y - p["r"] * 0.45 - 0.5
		var flat := S * 0.38
		var target_y: float = flat if on_floor and v.length() < 40.0 else S * (0.38 + 0.62 * absf(cos(p["tumble"])))
		node.scale = Vector2(S, lerpf(node.scale.y, target_y, minf(1.0, delta * 8.0)))
		node.rotation = lerp_angle(node.rotation, clampf(v.x * 0.0012, -0.5, 0.5), minf(1.0, delta * 6.0))
	else:
		node.rotation += p["vel"].x * delta / BALL_R

func _spawn_bubble(at: Vector2) -> void:
	var big := rng.randf() < 0.35
	var s := _sprite(tex["bubble_big" if big else "bubble_small"], at)
	bubble_layer.add_child(s)
	bubbles.append({ "node": s, "vy": -rng.randf_range(260, 420), "phase": rng.randf() * TAU, "x": at.x })

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

	for j in jets:
		var nz := _sprite(tex["nozzle"], Vector2(j["x"], FLOOR_Y - 12))
		add_child(nz)

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
	var digits := str(score).length()
	score_label.add_theme_font_size_override("font_size", 36 if digits <= 5 else 30)
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
