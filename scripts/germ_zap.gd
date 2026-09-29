extends BaseMinigame
## Germ Zap — a colony of germs is growing in the gut. Your pal fires soap bubbles
## non-stop; you only steer. The twist: germs left alive DIVIDE (mitosis!), so the colony
## grows back. If the infection meter fills up, it's game over. Some germs dive at you and
## spit slime.
##
## Hold MAIN to move left, hold FORWARD to move right. Firing is automatic.
## Desktop: also Left / Right arrows (A / D).

const S := 3.0
const TOP := 100.0
const PLAYER_Y := 850.0
const PLAYER_SPEED := 820.0
const PLAYER_ACCEL := 6500.0
const FIRE_RATE := 0.2
const SHOT_SPEED := 980.0
const SLIME_SPEED := 400.0
const LIVES := 3
const INVULN := 1.6

const COLS := 8
const ROWS := 5
const SLOT := Vector2(96, 72)
const MAX_COLONY := 32                  # this many germs alive = infected (game over)

const TYPES := {
	"coccus":   { "hp": 1, "points": 50,  "radius": 28.0, "divide": 9.0,  "dive": 0.25 },
	"bacillus": { "hp": 1, "points": 80,  "radius": 30.0, "divide": 11.0, "dive": 0.6 },
	"virus":    { "hp": 2, "points": 150, "radius": 32.0, "divide": 14.0, "dive": 0.35 },
}
const GERM_S := 3.6                    # germs are drawn a bit bigger than other sprites
const OUTLINE := Color8(74, 44, 32)

var lives := LIVES
var wave := 0
var player_x := 475.0
var player_v := 0.0
var left_held := false
var right_held := false
var fire_timer := 0.0
var invuln := 0.0
var triple_time := 0.0
var t := 0.0
var dive_timer := 2.5
var wave_busy := false

var germs: Array[Dictionary] = []       # { type, slot, hp, node, state(enter/form/dive), grow, ... }
var shots: Array[Dictionary] = []
var slimes: Array[Dictionary] = []
var drops: Array[Dictionary] = []
var cells: Array[Dictionary] = []       # background floaters

var tex := {}
var lcd_font: Font
var player: AnimatedSprite2D
var world: Node2D
var score_label: Label
var wave_label: Label
var lives_box: HBoxContainer
var meter_fill: ColorRect
var banner: Label
var rng := RandomNumberGenerator.new()

func _ready() -> void:
	game_music_path = "res://sounds/music/M.T. - Hoffnungslos [8 bits].mp3"
	lcd_font = load("res://fonts/pixChicago.ttf")
	for kind in TYPES:
		for f in [1, 2]:
			tex["%s_%d" % [kind, f]] = load("res://textures/minigames/germ/%s_%d.png" % [kind, f])
	tex["slime"] = load("res://textures/minigames/germ/slime.png")
	tex["soap"] = load("res://textures/minigames/germ/soap.png")
	tex["capsule"] = load("res://textures/minigames/break/capsule_mint.png")
	rng.randomize()
	_create_static_nodes()
	super._ready()

func start_game() -> void:
	super.start_game()
	lives = LIVES
	wave = 0
	_refresh_lives()
	_next_wave()

# ================================================================== WAVES / COLONY

func _slot_pos(slot: Vector2i) -> Vector2:
	var sway := sin(t * 0.7) * 70.0
	var origin := Vector2((PLAY_WIDTH - (COLS - 1) * SLOT.x) / 2.0 + sway, TOP + 90.0 + sin(t * 0.45) * 14.0)
	return origin + Vector2(slot.x * SLOT.x, slot.y * SLOT.y)

func _free_slots() -> Array[Vector2i]:
	var used := {}
	for g in germs:
		used[g["slot"]] = true
	var out: Array[Vector2i] = []
	for y in ROWS:
		for x in COLS:
			if not used.has(Vector2i(x, y)):
				out.append(Vector2i(x, y))
	return out

func _next_wave() -> void:
	wave += 1
	wave_busy = true
	wave_label.text = "WAVE %d" % wave
	_show_banner("Wave %d" % wave, 1.0)
	await get_tree().create_timer(1.0).timeout
	if not is_running:
		return
	var n := mini(8 + wave * 2, 22)
	var free := _free_slots()
	free.shuffle()
	for i in mini(n, free.size()):
		var kind := "coccus"
		var r := rng.randf()
		if wave >= 2 and r < 0.3:
			kind = "bacillus"
		if wave >= 3 and r < 0.12:
			kind = "virus"
		_spawn_germ(kind, free[i], Vector2(PLAY_WIDTH / 2.0 + (1 if i % 2 == 0 else -1) * rng.randf_range(100, 460), TOP - 60), 0.08 * i)
	wave_busy = false

func _spawn_germ(kind: String, slot: Vector2i, from: Vector2, delay := 0.0) -> Dictionary:
	var s := _sprite(tex[kind + "_1"], from)
	s.scale = Vector2(GERM_S, GERM_S)
	world.add_child(s)
	var g := { "type": kind, "slot": slot, "hp": TYPES[kind]["hp"], "node": s, "state": "enter",
		"from": from, "enter_t": -delay, "grow": rng.randf_range(0.0, 0.3), "pos": from, "phase": rng.randf() * TAU }
	germs.append(g)
	return g

func _divide(g: Dictionary) -> void:
	# mitosis: the germ stretches, then a copy pops out into the nearest free slot
	var free := _free_slots()
	g["grow"] = 0.0
	if free.is_empty():
		return
	free.sort_custom(func(a, b): return (a - g["slot"]).length_squared() < (b - g["slot"]).length_squared())
	var n: Sprite2D = g["node"]
	var tw := create_tween()
	tw.tween_property(n, "scale", Vector2(GERM_S * 1.4, GERM_S * 0.75), 0.18)
	tw.tween_property(n, "scale", Vector2(GERM_S, GERM_S), 0.2).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	var child := _spawn_germ(g["type"], free[0], g["pos"])
	child["state"] = "enter"
	child["enter_t"] = 0.4
	_sfx("res://sounds/fx/sfx_sounds_falling4.wav", -20.0, 0.1)

# ================================================================== LOOP

func _process(delta: float) -> void:
	if not is_running:
		return
	t += delta
	_update_cells(delta)
	_move_player(delta)
	invuln = maxf(0.0, invuln - delta)
	triple_time = maxf(0.0, triple_time - delta)
	player.visible = invuln <= 0.0 or int(t * 12.0) % 2 == 0

	fire_timer -= delta
	if fire_timer <= 0.0:
		fire_timer = FIRE_RATE
		_fire()

	_update_germs(delta)
	_update_shots(delta)
	_update_slimes(delta)
	_update_drops(delta)

	meter_fill.size.x = 196.0 * clampf(float(germs.size()) / MAX_COLONY, 0.0, 1.0)
	meter_fill.color = Color8(120, 200, 90) if germs.size() < MAX_COLONY * 0.7 else Color8(230, 80, 90)
	if germs.size() >= MAX_COLONY:
		_show_banner("Infected!", 1.0)
		end_game()
		return
	if germs.is_empty() and not wave_busy:
		add_score(200)
		_next_wave()
	score_label.text = str(score)
	score_label.add_theme_font_size_override("font_size", 36 if str(score).length() <= 5 else 30)

func _update_germs(delta: float) -> void:
	dive_timer -= delta
	var frame := 1 + int(t * 4.0) % 2
	var dividing: Array[Dictionary] = []
	for g in germs:
		var n: Sprite2D = g["node"]
		n.texture = tex["%s_%d" % [g["type"], frame]]
		g["phase"] += delta * 3.0
		match g["state"]:
			"enter":
				g["enter_t"] += delta
				var k := clampf(g["enter_t"] / 1.1, 0.0, 1.0)
				if g["enter_t"] < 0.0:
					k = 0.0
				var target := _slot_pos(g["slot"])
				var ctrl: Vector2 = (g["from"] + target) / 2.0 + Vector2(0, 220)
				var e := 1.0 - pow(1.0 - k, 2.0)
				g["pos"] = g["from"].lerp(ctrl, e).lerp(ctrl.lerp(target, e), e)
				if k >= 1.0:
					g["state"] = "form"
			"form":
				g["pos"] = _slot_pos(g["slot"]) + Vector2(0, sin(g["phase"]) * 4.0)
				g["grow"] += delta / (TYPES[g["type"]]["divide"] * maxf(0.55, 1.0 - wave * 0.05))
				n.modulate = Color(1, 1, 1).lerp(Color(1.4, 1.1, 1.1), clampf(g["grow"] - 0.75, 0.0, 0.25) * 4.0)
				if g["grow"] >= 1.0:
					dividing.append(g)
			"dive":
				g["dive_t"] += delta
				var d: float = g["dive_t"]
				g["pos"] = Vector2(g["dive_x"] + sin(d * 3.2) * 150.0, g["dive_y"] + d * 330.0)
				if rng.randf() < delta * 1.2 and g["pos"].y < PLAYER_Y - 150:
					_spit(g["pos"])
				if g["pos"].y > PLAY_HEIGHT + 40:
					# wraps back in from the top and returns to its slot
					g["state"] = "enter"
					g["from"] = Vector2(g["pos"].x, TOP - 60)
					g["enter_t"] = 0.0
		n.position = g["pos"]
		if g["state"] != "enter" and invuln <= 0.0 and g["pos"].distance_to(Vector2(player_x, PLAYER_Y - 30)) < TYPES[g["type"]]["radius"] + 30:
			_player_hit()
	for g in dividing:                 # (after the loop: dividing adds germs)
		_divide(g)
	# pick a diver now and then
	if dive_timer <= 0.0:
		dive_timer = maxf(0.9, 3.0 - wave * 0.2)
		var formed := germs.filter(func(g): return g["state"] == "form")
		if not formed.is_empty():
			var g: Dictionary = formed[rng.randi() % formed.size()]
			if rng.randf() < TYPES[g["type"]]["dive"] + 0.3:
				g["state"] = "dive"
				g["dive_t"] = 0.0
				g["dive_x"] = g["pos"].x
				g["dive_y"] = g["pos"].y
		# formed germs spit once in a while too
		if not formed.is_empty() and rng.randf() < 0.5:
			_spit(formed[rng.randi() % formed.size()]["pos"])

func _fire() -> void:
	var angles := [0.0] if triple_time <= 0.0 else [-0.18, 0.0, 0.18]
	for a in angles:
		var s := _sprite(tex["soap"], Vector2(player_x, PLAYER_Y - 70))
		world.add_child(s)
		shots.append({ "node": s, "vel": Vector2(0, -SHOT_SPEED).rotated(a) })
	_sfx("res://sounds/fx/click-6.mp3", -24.0)

func _update_shots(delta: float) -> void:
	for i in range(shots.size() - 1, -1, -1):
		var sh: Dictionary = shots[i]
		var n: Sprite2D = sh["node"]
		n.position += sh["vel"] * delta
		var hit := false
		for g in germs:
			if n.position.distance_to(g["pos"]) < TYPES[g["type"]]["radius"]:
				_damage(g)
				hit = true
				break
		if hit or n.position.y < TOP:
			n.queue_free()
			shots.remove_at(i)

func _damage(g: Dictionary) -> void:
	g["hp"] -= 1
	var n: Sprite2D = g["node"]
	if g["hp"] > 0:
		var tw := create_tween()
		tw.tween_property(n, "modulate", Color(3, 3, 3), 0.04)
		tw.tween_property(n, "modulate", Color(1, 1, 1), 0.1)
		_sfx("res://sounds/fx/clack.mp3", -14.0)
		return
	var pts: int = TYPES[g["type"]]["points"] * (2 if g["state"] == "dive" else 1)
	add_score(pts)
	_float_text("+%d" % pts, g["pos"])
	_sfx("res://sounds/fx/click-5.mp3", -8.0)
	germs.erase(g)
	var tw := create_tween()
	tw.tween_property(n, "scale", Vector2(GERM_S * 1.6, GERM_S * 1.6), 0.12)
	tw.parallel().tween_property(n, "modulate", Color(1.5, 1.5, 1.5, 0.0), 0.12)
	tw.tween_callback(n.queue_free)
	if rng.randf() < 0.07:
		var d := _sprite(tex["capsule"], g["pos"])
		world.add_child(d)
		drops.append({ "node": d })

func _spit(from: Vector2) -> void:
	var s := _sprite(tex["slime"], from + Vector2(0, 24))
	world.add_child(s)
	var aim := (Vector2(player_x, PLAYER_Y) - from).normalized()
	slimes.append({ "node": s, "vel": Vector2(aim.x * 0.35, 1.0).normalized() * SLIME_SPEED })

func _update_slimes(delta: float) -> void:
	for i in range(slimes.size() - 1, -1, -1):
		var sl: Dictionary = slimes[i]
		var n: Sprite2D = sl["node"]
		n.position += sl["vel"] * delta
		if invuln <= 0.0 and n.position.distance_to(Vector2(player_x, PLAYER_Y - 30)) < 36:
			n.queue_free()
			slimes.remove_at(i)
			_player_hit()
			continue
		if n.position.y > PLAY_HEIGHT + 20:
			n.queue_free()
			slimes.remove_at(i)

func _update_drops(delta: float) -> void:
	for i in range(drops.size() - 1, -1, -1):
		var n: Sprite2D = drops[i]["node"]
		n.position.y += 220.0 * delta
		if n.position.distance_to(Vector2(player_x, PLAYER_Y - 30)) < 50:
			triple_time = 9.0
			_float_text("SOAP x3!", n.position)
			_sfx("res://sounds/fx/gamecoin.wav", -9.0)
			n.queue_free()
			drops.remove_at(i)
		elif n.position.y > PLAY_HEIGHT + 20:
			n.queue_free()
			drops.remove_at(i)

func _player_hit() -> void:
	if invuln > 0.0 or not is_running:
		return
	lives -= 1
	invuln = INVULN
	_refresh_lives()
	_play_error_sound()
	if lives <= 0:
		end_game()

func _move_player(delta: float) -> void:
	var dir := 0.0
	if left_held or Input.is_key_pressed(KEY_LEFT) or Input.is_key_pressed(KEY_A):
		dir -= 1.0
	if right_held or Input.is_key_pressed(KEY_RIGHT) or Input.is_key_pressed(KEY_D):
		dir += 1.0
	player_v = move_toward(player_v, dir * PLAYER_SPEED, PLAYER_ACCEL * delta)
	player_x = clampf(player_x + player_v * delta, 60.0, PLAY_WIDTH - 60.0)
	player.position = Vector2(player_x, PLAYER_Y)
	player.rotation = lerp_angle(player.rotation, player_v / PLAYER_SPEED * 0.18, minf(1.0, delta * 10.0))

# ================================================================== NODES / HUD

func _update_cells(delta: float) -> void:
	for c in cells:
		var n: Sprite2D = c["node"]
		n.position.y += c["speed"] * delta
		if n.position.y > PLAY_HEIGHT + 80:
			n.position = Vector2(rng.randf_range(0, PLAY_WIDTH), TOP - 60)

func _create_static_nodes() -> void:
	var bg := ColorRect.new()
	bg.color = Color8(110, 44, 66)                 # deep inside the gut
	bg.size = Vector2(PLAY_WIDTH, PLAY_HEIGHT)
	add_child(bg)
	for i in 22:                                    # soft floating cells, parallax
		var s := _sprite(load("res://textures/minigames/splash/bubble_big.png"), Vector2(rng.randf_range(0, PLAY_WIDTH), rng.randf_range(TOP, PLAY_HEIGHT)))
		var k := rng.randf_range(4.0, 12.0)
		s.scale = Vector2(k, k)
		s.modulate = Color(1.0, 0.7, 0.8, 0.10 + 0.01 * k)
		add_child(s)
		cells.append({ "node": s, "speed": 12.0 * k })

	world = Node2D.new()
	add_child(world)

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
	var k := 110.0 / maxf(1.0, used.size.x)
	player.scale = Vector2(k, k)
	player.offset = Vector2(0, -(float(used.position.y + used.size.y) - tex0.get_height() / 2.0))
	add_child(player)

	var band := ColorRect.new()
	band.color = OUTLINE
	band.size = Vector2(PLAY_WIDTH, TOP)
	add_child(band)
	wave_label = _make_label(Vector2(26, 6), Vector2(220, 50), 32, HORIZONTAL_ALIGNMENT_LEFT, Color(0.98, 0.93, 0.84))
	lives_box = HBoxContainer.new()
	lives_box.position = Vector2(250, 14)
	lives_box.add_theme_constant_override("separation", 4)
	add_child(lives_box)
	# infection meter: how full the colony is
	var meter_label := _make_label(Vector2(26, 54), Vector2(120, 36), 22, HORIZONTAL_ALIGNMENT_LEFT, Color(0.98, 0.93, 0.84))
	meter_label.text = "GERMS"
	var meter_bg := ColorRect.new()
	meter_bg.color = Color(0, 0, 0)
	meter_bg.position = Vector2(140, 60)
	meter_bg.size = Vector2(204, 26)
	add_child(meter_bg)
	meter_fill = ColorRect.new()
	meter_fill.position = meter_bg.position + Vector2(4, 4)
	meter_fill.size = Vector2(0, 18)
	add_child(meter_fill)
	var frame := ColorRect.new()
	frame.color = Color(0, 0, 0)
	frame.position = Vector2(PLAY_WIDTH - 245, 14)
	frame.size = Vector2(205, 72)
	add_child(frame)
	var box := ColorRect.new()
	box.color = Color(0.65, 0.72, 0.6)
	box.position = frame.position + Vector2(5, 5)
	box.size = frame.size - Vector2(10, 10)
	add_child(box)
	score_label = _make_label(box.position + Vector2(6, 0), box.size - Vector2(18, 0), 36, HORIZONTAL_ALIGNMENT_RIGHT, Color(0.2, 0.15, 0.05))

	banner = _make_label(Vector2(0, 520), Vector2(PLAY_WIDTH, 120), 54, HORIZONTAL_ALIGNMENT_CENTER, Color(1, 0.97, 0.9))
	banner.add_theme_color_override("font_outline_color", OUTLINE)
	banner.add_theme_constant_override("outline_size", 14)
	banner.modulate.a = 0.0

func _refresh_lives() -> void:
	for n in lives_box.get_children():
		n.queue_free()
	var frames := player.sprite_frames
	var anim := "idle" if frames.has_animation("idle") else "default"
	for i in LIVES:
		var r := TextureRect.new()
		var full := frames.get_frame_texture(anim, 0)
		var icon := AtlasTexture.new()            # crop the empty canvas around the pal
		icon.atlas = full
		var fi := full.get_image()
		icon.region = Rect2(fi.get_used_rect()) if fi else Rect2(0, 0, full.get_width(), full.get_height())
		r.texture = icon
		r.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		r.custom_minimum_size = Vector2(48, 40)
		r.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		r.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		r.modulate = Color(1, 1, 1, 1) if i < lives else Color(0, 0, 0, 0.35)
		lives_box.add_child(r)

func _sprite(tx: Texture2D, pos: Vector2) -> Sprite2D:
	var s := Sprite2D.new()
	s.texture = tx
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
	var tw := create_tween()
	tw.tween_property(banner, "modulate:a", 1.0, 0.15)
	tw.tween_interval(hold)
	tw.tween_property(banner, "modulate:a", 0.0, 0.3)

func _float_text(text: String, at: Vector2) -> void:
	var l := _make_label(at + Vector2(-80, -50), Vector2(160, 40), 26, HORIZONTAL_ALIGNMENT_CENTER, Color(1, 0.95, 0.85))
	l.add_theme_color_override("font_outline_color", OUTLINE)
	l.add_theme_constant_override("outline_size", 10)
	l.text = text
	var tw := create_tween()
	tw.tween_property(l, "position:y", l.position.y - 40, 0.6)
	tw.parallel().tween_property(l, "modulate:a", 0.0, 0.6)
	tw.tween_callback(l.queue_free)

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
