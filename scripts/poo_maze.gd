extends BaseMinigame
## Poo Maze — lay the phone flat and tilt it to roll your pal (curled into a ball)
## through a wooden labyrinth. Collect the numbered checkpoints, dodge the holes,
## reach the flush swirl. Every level is generated from a fixed seed, so level 1
## is always the same board and each level adds more holes.
##
## Tilt: gravity sensor on device. Desktop: arrow keys / WASD / hold mouse to pull.
## Main button: set the current phone angle as "flat" (recalibrate).

# --- Board geometry (all logic runs in play-area coordinates, 950x948) ---
const PX := 2                         # world px per board pixel
const TILE := 48                      # world px per tile
const TILE_PX := TILE / PX            # 24 board px per tile
const GRID := 19                      # tiles per side
const CELLS := 6                      # maze cells per side: 2-tile corridors + 1-tile walls
const BOARD_PX := GRID * TILE_PX      # 456
const ORIGIN := Vector2(19, 18)       # board top-left inside the play area

# --- Ball physics ---
const BALL_R := 18.0
const DETAIL := 2                     # world px per texture px for small sprites (coins, swirl)
const ACCEL := 1500.0                 # px/s² at full tilt
const FRICTION := 1.1                 # velocity damping per second
const MAX_SPEED := 720.0
const BOUNCE := 0.35
const TILT_GAIN := 2.2                # sensor tilt (in g) -> input strength
const DEADZONE := 0.04
## Flip if the ball rolls the wrong way on a given device
const INVERT_TILT := false

# --- Board features ---
const HOLE_R := 22.0
const HOLE_FALL_R := 15.0             # ball centre this close to a hole centre = falls in
const HOLE_PULL := 900.0
const CHECK_R := 30.0
const FINISH_R := 26.0
const LIVES := 3

# --- Palette (matches the console) ---
const WOOD := Color8(232, 200, 152)
const WOOD_GRAIN := Color8(214, 176, 126)
const WALL_TOP := Color8(242, 214, 168)
const WALL_MID := Color8(222, 184, 132)
const WALL_SIDE := Color8(176, 124, 78)
const OUTLINE := Color8(74, 44, 32)
const HOLE_DARK := Color8(34, 20, 16)
const HOLE_RIM := Color8(120, 78, 50)
const PATH_INK := Color8(58, 38, 30)
const TEXT_DARK := Color(0.2, 0.12, 0.08)

enum State { PLAY, FALLING, CLEAR }

var state := State.PLAY
var level := 1
var lives := LIVES
var level_time := 0.0

var tiles := PackedByteArray()        # 1 = wall
var open_e := {}                      # Vector2i(cell) -> true if wall to the east is open
var open_s := {}                      # Vector2i(cell) -> true if wall to the south is open
var path_cells: Array[Vector2i] = []
var holes: Array[Vector2] = []
var checkpoints: Array[Dictionary] = []   # { pos, node, taken }
var start_pos := Vector2.ZERO
var finish_pos := Vector2.ZERO
var respawn_pos := Vector2.ZERO

var ball_pos := Vector2.ZERO
var vel := Vector2.ZERO
var calib := Vector2.ZERO
var bump_cooldown := 0.0

var board: Sprite2D
var finish_sprite: Sprite2D
var ball: Sprite2D
var shadow: Sprite2D
var level_nodes: Node2D
var hud_level: Label
var hud_time: Label
var score_label: Label
var lives_box: HBoxContainer
var banner: Label
var ball_texture: Texture2D
var lcd_font: Font

func _ready() -> void:
	game_music_path = "res://sounds/music/Frédéric Chopin - Etude_ Op. 25 No. 02 [8 bits].mp3"
	lcd_font = load("res://fonts/pixChicago.ttf")
	ball_texture = _make_ball_texture()
	_create_static_nodes()
	super._ready()

func start_game() -> void:
	super.start_game()
	level = 1
	lives = LIVES
	_build_level()
	_show_banner("Tilt to roll!" if _has_tilt_sensor() else "Arrows / drag to roll", 1.8)

# ================================================================== LEVEL BUILD

func _build_level() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 7919 * level + 17
	_generate_maze(rng)
	_place_features(rng)
	board.texture = ImageTexture.create_from_image(_paint_board())
	_spawn_level_nodes()
	ball_pos = start_pos
	respawn_pos = start_pos
	vel = Vector2.ZERO
	level_time = 0.0
	state = State.PLAY
	_refresh_lives()

func _generate_maze(rng: RandomNumberGenerator) -> void:
	tiles.resize(GRID * GRID)
	tiles.fill(1)
	open_e.clear()
	open_s.clear()
	for cy in CELLS:
		for cx in CELLS:
			for dy in 2:
				for dx in 2:
					_set_tile(1 + 3 * cx + dx, 1 + 3 * cy + dy, 0)

	# Recursive backtracker -> a perfect maze (exactly one route between any two cells)
	var visited := {}
	var stack: Array[Vector2i] = [Vector2i(0, 0)]
	visited[Vector2i(0, 0)] = true
	while stack.size() > 0:
		var cur: Vector2i = stack[-1]
		var options: Array[Vector2i] = []
		for d in [Vector2i.RIGHT, Vector2i.LEFT, Vector2i.DOWN, Vector2i.UP]:
			var n: Vector2i = cur + d
			if n.x >= 0 and n.y >= 0 and n.x < CELLS and n.y < CELLS and not visited.has(n):
				options.append(n)
		if options.is_empty():
			stack.pop_back()
			continue
		var nxt: Vector2i = options[rng.randi() % options.size()]
		_open_between(cur, nxt)
		visited[nxt] = true
		stack.append(nxt)

	# Knock out a few extra walls so there are loops and shortcuts
	var extra := 3 + mini(level, 5)
	var tries := 0
	while extra > 0 and tries < 200:
		tries += 1
		var c := Vector2i(rng.randi() % CELLS, rng.randi() % CELLS)
		if rng.randf() < 0.5 and c.x < CELLS - 1 and not open_e.has(c):
			_open_between(c, c + Vector2i.RIGHT)
			extra -= 1
		elif c.y < CELLS - 1 and not open_s.has(c):
			_open_between(c, c + Vector2i.DOWN)
			extra -= 1

func _open_between(a: Vector2i, b: Vector2i) -> void:
	var lo := Vector2i(mini(a.x, b.x), mini(a.y, b.y))
	if a.y == b.y:
		open_e[lo] = true
		for dy in 2:
			_set_tile(3 * lo.x + 3, 1 + 3 * lo.y + dy, 0)
	else:
		open_s[lo] = true
		for dx in 2:
			_set_tile(1 + 3 * lo.x + dx, 3 * lo.y + 3, 0)

func _cell_neighbors(c: Vector2i) -> Array[Vector2i]:
	var out: Array[Vector2i] = []
	if open_e.has(c): out.append(c + Vector2i.RIGHT)
	if open_s.has(c): out.append(c + Vector2i.DOWN)
	if open_e.has(c + Vector2i.LEFT): out.append(c + Vector2i.LEFT)
	if open_s.has(c + Vector2i.UP): out.append(c + Vector2i.UP)
	return out

func _cell_center(c: Vector2i) -> Vector2:
	return ORIGIN + Vector2(3 * c.x + 2, 3 * c.y + 2) * TILE

func _place_features(rng: RandomNumberGenerator) -> void:
	# Route: BFS from the top-left cell; the finish is the farthest cell
	var start := Vector2i(0, 0)
	var prev := { start: start }
	var queue: Array[Vector2i] = [start]
	var last := start
	while queue.size() > 0:
		var c: Vector2i = queue.pop_front()
		last = c
		for n in _cell_neighbors(c):
			if not prev.has(n):
				prev[n] = c
				queue.append(n)
	path_cells.clear()
	var c2 := last
	while c2 != start:
		path_cells.push_front(c2)
		c2 = prev[c2]
	path_cells.push_front(start)

	start_pos = _cell_center(start)
	finish_pos = _cell_center(last)

	# Checkpoints spread evenly along the route
	checkpoints.clear()
	var n_checks := clampi(path_cells.size() / 4, 2, 6)
	var check_cells := {}
	for i in range(1, n_checks + 1):
		var idx := int(round(float(i) * (path_cells.size() - 1) / float(n_checks + 1)))
		check_cells[path_cells[idx]] = true
		checkpoints.append({ "pos": _cell_center(path_cells[idx]), "taken": false })

	# Holes: dead ends first (traps), then beside the route (tension)
	holes.clear()
	var want := mini(3 + level * 2, 18)
	var on_path := {}
	for c in path_cells:
		on_path[c] = true
	var dead_ends: Array[Vector2i] = []
	var others: Array[Vector2i] = []
	for cy in CELLS:
		for cx in CELLS:
			var c := Vector2i(cx, cy)
			if c == start or c == last or check_cells.has(c) or (c - start).length_squared() <= 1:
				continue
			if _cell_neighbors(c).size() == 1 and not on_path.has(c):
				dead_ends.append(c)
			else:
				others.append(c)
	_shuffle(dead_ends, rng)
	_shuffle(others, rng)
	for c in dead_ends:
		if holes.size() >= want / 2:
			break
		holes.append(_cell_center(c))
	for c in others:
		if holes.size() >= want:
			break
		# One hole per cell, in a corner quadrant, so the other side stays passable
		var q := Vector2(24 if rng.randf() < 0.5 else -24, 24 if rng.randf() < 0.5 else -24)
		holes.append(_cell_center(c) + q)

func _shuffle(arr: Array, rng: RandomNumberGenerator) -> void:
	for i in range(arr.size() - 1, 0, -1):
		var j := rng.randi() % (i + 1)
		var t = arr[i]
		arr[i] = arr[j]
		arr[j] = t

func _set_tile(x: int, y: int, v: int) -> void:
	tiles[y * GRID + x] = v

func _is_wall_tile(x: int, y: int) -> bool:
	if x < 0 or y < 0 or x >= GRID or y >= GRID:
		return true
	return tiles[y * GRID + x] == 1

# ================================================================== BOARD PAINTING

func _paint_board() -> Image:
	var n := BOARD_PX
	var t := TILE_PX
	# Per-tile: which sides face open floor (for bevels / outlines)
	var up := PackedByteArray(); up.resize(GRID * GRID)
	var dn := PackedByteArray(); dn.resize(GRID * GRID)
	var lf := PackedByteArray(); lf.resize(GRID * GRID)
	var rt := PackedByteArray(); rt.resize(GRID * GRID)
	for ty in GRID:
		for tx in GRID:
			var i := ty * GRID + tx
			up[i] = int(not _is_wall_tile(tx, ty - 1))
			dn[i] = int(not _is_wall_tile(tx, ty + 1))
			lf[i] = int(not _is_wall_tile(tx - 1, ty))
			rt[i] = int(not _is_wall_tile(tx + 1, ty))

	var data := PackedByteArray()
	data.resize(n * n * 4)
	var noise := RandomNumberGenerator.new()
	noise.seed = 99
	var k := 0
	for y in n:
		var ty := y / t
		var ly := y % t
		var grain_row := sin(y * 0.45)
		for x in n:
			var tx := x / t
			var lx := x % t
			var i := ty * GRID + tx
			var c: Color
			if tiles[i] == 1:
				var d_up := ly if up[i] else 99
				var d_dn := (t - 1 - ly) if dn[i] else 99
				var d_lf := lx if lf[i] else 99
				var d_rt := (t - 1 - lx) if rt[i] else 99
				var m := mini(mini(d_up, d_dn), mini(d_lf, d_rt))
				if m == 0:
					c = OUTLINE
				elif d_dn <= 6:
					c = WALL_SIDE.darkened(0.12 * (6 - d_dn) / 6.0)      # front face, darker at the base
				elif d_up <= 2 or d_lf <= 2:
					c = WALL_TOP
				elif d_rt <= 2:
					c = WALL_MID.darkened(0.08)
				else:
					c = WALL_MID.lerp(WALL_TOP, 0.25 + 0.15 * sin(x * 0.2 + y * 0.05))
			else:
				var g := 0.5 + 0.5 * sin(grain_row + sin(x * 0.035 + y * 0.006) * 3.0)
				c = WOOD.lerp(WOOD_GRAIN, g * 0.5 + noise.randf() * 0.08)
				# Soft two-step drop shadow (light from the top-left)
				var sx := x - 3
				var sy := y - 6
				if sx < 0 or sy < 0 or tiles[(sy / t) * GRID + sx / t] == 1:
					c = c.darkened(0.2)
				else:
					sx = x - 6
					sy = y - 11
					if sx < 0 or sy < 0 or tiles[(sy / t) * GRID + sx / t] == 1:
						c = c.darkened(0.09)
			data[k] = c.r8
			data[k + 1] = c.g8
			data[k + 2] = c.b8
			data[k + 3] = 255
			k += 4
	var img := Image.create_from_data(n, n, false, Image.FORMAT_RGBA8, data)

	# Route line, like the ink line on a real labyrinth board
	for j in range(path_cells.size() - 1):
		_ink_line(img, _to_px(_cell_center(path_cells[j])), _to_px(_cell_center(path_cells[j + 1])))
	_ink_ring(img, _to_px(start_pos), 13.0)

	for h in holes:
		_paint_hole(img, _to_px(h))
	return img

func _to_px(p: Vector2) -> Vector2:
	return (p - ORIGIN) / PX

func _blend(img: Image, x: int, y: int, col: Color, amount: float) -> void:
	if x < 0 or y < 0 or x >= BOARD_PX or y >= BOARD_PX or amount <= 0.0:
		return
	img.set_pixel(x, y, img.get_pixel(x, y).lerp(col, clampf(amount, 0.0, 1.0)))

func _ink_line(img: Image, a: Vector2, b: Vector2) -> void:
	var steps := int(maxf(absf(b.x - a.x), absf(b.y - a.y)))
	for i in steps + 1:
		var p := a.lerp(b, float(i) / maxf(steps, 1))
		for o: Vector2i in [Vector2i(0, 0), Vector2i(1, 0), Vector2i(0, 1), Vector2i(1, 1)]:
			var x := int(p.x) + o.x
			var y := int(p.y) + o.y
			if not _is_wall_px(x, y):
				_blend(img, x, y, PATH_INK, 0.7)

func _ink_ring(img: Image, center: Vector2, r: float) -> void:
	for y in range(int(center.y - r - 2), int(center.y + r + 3)):
		for x in range(int(center.x - r - 2), int(center.x + r + 3)):
			var d := Vector2(x + 0.5, y + 0.5).distance_to(center)
			if not _is_wall_px(x, y):
				_blend(img, x, y, PATH_INK, 0.75 * (1.0 - clampf(absf(d - r) - 0.5, 0.0, 1.0)))

func _paint_hole(img: Image, center: Vector2) -> void:
	var r := HOLE_R / PX
	for y in range(int(center.y - r - 3), int(center.y + r + 4)):
		for x in range(int(center.x - r - 3), int(center.x + r + 4)):
			var off := Vector2(x + 0.5, y + 0.5) - center
			var d := off.length()
			# darker toward the centre, lip lit on the far (lower) edge
			var depth := clampf(d / r, 0.0, 1.0)
			var col := HOLE_DARK.lerp(HOLE_DARK.lightened(0.25), depth * depth)
			if d > r - 2.0 and off.y > 0:
				col = HOLE_RIM
			_blend(img, x, y, col, r + 0.5 - d)                  # anti-aliased edge
			if d > r - 0.5 and d < r + 2.0 and off.y < 0:
				_blend(img, x, y, OUTLINE, 0.35 * (1.0 - absf(d - r - 0.5) / 1.5))

func _is_wall_px(x: int, y: int) -> bool:
	if x < 0 or y < 0 or x >= BOARD_PX or y >= BOARD_PX:
		return true
	return tiles[(y / TILE_PX) * GRID + (x / TILE_PX)] == 1

# ================================================================== NODES

func _create_static_nodes() -> void:
	var bg := ColorRect.new()
	bg.color = OUTLINE
	bg.size = Vector2(PLAY_WIDTH, PLAY_HEIGHT)
	bg.z_index = -10
	add_child(bg)

	board = Sprite2D.new()
	board.centered = false
	board.position = ORIGIN
	board.scale = Vector2(PX, PX)
	board.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	add_child(board)

	level_nodes = Node2D.new()
	add_child(level_nodes)

	finish_sprite = Sprite2D.new()
	finish_sprite.texture = _make_swirl_texture()
	finish_sprite.scale = Vector2(DETAIL, DETAIL)
	finish_sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	add_child(finish_sprite)

	shadow = Sprite2D.new()
	shadow.texture = _make_shadow_texture()
	shadow.scale = Vector2(DETAIL, DETAIL)
	shadow.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	add_child(shadow)

	ball = Sprite2D.new()
	ball.texture = ball_texture
	ball.scale = Vector2.ONE
	ball.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	add_child(ball)

	# HUD lives on the top wall strip
	hud_level = _make_label(Vector2(30, 18), Vector2(150, 52), 38, HORIZONTAL_ALIGNMENT_LEFT, Color(0.98, 0.93, 0.84))
	hud_time = _make_label(Vector2(PLAY_WIDTH / 2 - 60, 18), Vector2(170, 52), 38, HORIZONTAL_ALIGNMENT_CENTER, Color(0.98, 0.93, 0.84))

	lives_box = HBoxContainer.new()
	lives_box.position = Vector2(160, 24)
	lives_box.add_theme_constant_override("separation", 6)
	lives_box.z_index = 20
	add_child(lives_box)

	var frame := ColorRect.new()
	frame.color = Color(0, 0, 0)
	frame.position = Vector2(PLAY_WIDTH - 230, 12)
	frame.size = Vector2(205, 78)
	frame.z_index = 19
	add_child(frame)
	var box := ColorRect.new()
	box.color = Color(0.65, 0.72, 0.6)   # LCD green, like Super Puff
	box.position = frame.position + Vector2(5, 5)
	box.size = frame.size - Vector2(10, 10)
	box.z_index = 19
	add_child(box)
	score_label = _make_label(box.position + Vector2(6, 0), box.size - Vector2(18, 0), 38, HORIZONTAL_ALIGNMENT_RIGHT, Color(0.2, 0.15, 0.05))

	banner = _make_label(Vector2(0, PLAY_HEIGHT / 2 - 60), Vector2(PLAY_WIDTH, 120), 54, HORIZONTAL_ALIGNMENT_CENTER, Color(1, 0.97, 0.9))
	banner.add_theme_color_override("font_outline_color", OUTLINE)
	banner.add_theme_constant_override("outline_size", 14)
	banner.modulate.a = 0.0

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
	l.z_index = 20
	add_child(l)
	return l

func _spawn_level_nodes() -> void:
	for n in level_nodes.get_children():
		n.queue_free()
	finish_sprite.position = finish_pos
	var coin := _make_coin_texture()
	for i in checkpoints.size():
		var cp: Dictionary = checkpoints[i]
		var s := Sprite2D.new()
		s.texture = coin
		s.scale = Vector2(DETAIL, DETAIL)
		s.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		s.position = cp["pos"]
		level_nodes.add_child(s)
		var num := Label.new()
		num.text = str(i + 1)
		if lcd_font:
			num.add_theme_font_override("font", lcd_font)
		num.add_theme_font_size_override("font_size", 26)
		num.add_theme_color_override("font_color", TEXT_DARK)
		num.position = cp["pos"] + Vector2(18, -44)
		level_nodes.add_child(num)
		cp["node"] = s
		cp["label"] = num

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

# ================================================================== GENERATED TEXTURES

func _make_ball_texture() -> Texture2D:
	## The current pal curled into a ball (pre-rendered per form in textures/minigames/balls/).
	var id := PetState.form_id if PetState.has_poop() else "classic"
	var path := "res://textures/minigames/balls/%s.png" % id
	if not ResourceLoader.exists(path):
		path = "res://textures/minigames/balls/classic.png"
	return load(path)

func _make_swirl_texture() -> Texture2D:
	## The goal: a little flush swirl.
	const S := 32
	var img := Image.create(S, S, false, Image.FORMAT_RGBA8)
	var c := Vector2(S / 2.0, S / 2.0)
	for y in S:
		for x in S:
			var off := Vector2(x + 0.5, y + 0.5) - c
			var d := off.length()
			if d > S / 2.0:
				continue
			var col := Color8(84, 150, 206).lerp(Color8(40, 90, 150), 1.0 - d / (S / 2.0))
			if d > S / 2.0 - 1.6:
				col = OUTLINE
			else:
				var arm := fposmod(off.angle() * 3.0 / TAU + d * 0.28, 1.0)
				if arm < 0.3:
					col = Color8(214, 240, 252)
				elif d < 3.5:
					col = Color8(30, 70, 120)
			img.set_pixel(x, y, col)
	return ImageTexture.create_from_image(img)

func _make_coin_texture() -> Texture2D:
	const S := 22
	var img := Image.create(S, S, false, Image.FORMAT_RGBA8)
	var c := Vector2(S / 2.0, S / 2.0)
	for y in S:
		for x in S:
			var off := Vector2(x + 0.5, y + 0.5) - c
			var d := off.length()
			if d > S / 2.0:
				continue
			var shade := clampf(0.5 - (off.x + off.y) / S, 0.0, 1.0)
			var col := Color8(196, 76, 118).lerp(Color8(248, 150, 182), shade)
			if d > S / 2.0 - 1.6:
				col = Color8(110, 36, 70)
			elif Vector2(off.x + 3.5, off.y + 3.5).length() < 2.6:
				col = Color8(255, 222, 232)
			img.set_pixel(x, y, col)
	return ImageTexture.create_from_image(img)

func _make_shadow_texture() -> Texture2D:
	var img := Image.create(20, 12, false, Image.FORMAT_RGBA8)
	for y in 12:
		for x in 20:
			var off := Vector2((x + 0.5 - 10.0) / 10.0, (y + 0.5 - 6.0) / 6.0)
			var l := off.length()
			if l <= 1.0:
				img.set_pixel(x, y, Color(0.2, 0.1, 0.05, 0.4 * (1.0 - l * l)))
	return ImageTexture.create_from_image(img)

# ================================================================== LOOP

func _process(delta: float) -> void:
	if not is_running:
		return
	finish_sprite.rotation -= delta * 2.5
	bump_cooldown = maxf(0.0, bump_cooldown - delta)

	if state == State.PLAY:
		level_time += delta
		var tilt := _read_tilt()
		const STEPS := 4
		var dt := delta / STEPS
		for i in STEPS:
			vel += tilt * ACCEL * dt
			_apply_hole_pull(dt)
			vel *= maxf(0.0, 1.0 - FRICTION * dt)
			vel = vel.limit_length(MAX_SPEED)
			ball_pos += vel * dt
			_collide_walls()
		var speed := vel.length()
		if speed > 60.0:
			ball.rotation += vel.x * delta / BALL_R
		else:
			ball.rotation = lerp_angle(ball.rotation, 0.0, minf(1.0, delta * 6.0))
		_check_checkpoints()
		_check_finish()
		_check_holes()

	if state != State.FALLING:
		ball.position = ball_pos
	shadow.position = ball.position + Vector2(5, 14) * ball.scale.x
	shadow.visible = state != State.FALLING
	hud_level.text = "LV %d" % level
	hud_time.text = "%d:%02d" % [int(level_time) / 60, int(level_time) % 60]
	score_label.text = str(score)
	# Shrink long numbers so they always fit the LCD box
	score_label.add_theme_font_size_override("font_size", 38 if score < 10000 else (32 if score < 100000 else 27))

func _collide_walls() -> void:
	var tx0 := int(floor((ball_pos.x - BALL_R - ORIGIN.x) / TILE))
	var tx1 := int(floor((ball_pos.x + BALL_R - ORIGIN.x) / TILE))
	var ty0 := int(floor((ball_pos.y - BALL_R - ORIGIN.y) / TILE))
	var ty1 := int(floor((ball_pos.y + BALL_R - ORIGIN.y) / TILE))
	for ty in range(ty0, ty1 + 1):
		for tx in range(tx0, tx1 + 1):
			if not _is_wall_tile(tx, ty):
				continue
			var rect := Rect2(ORIGIN + Vector2(tx, ty) * TILE, Vector2(TILE, TILE))
			var closest := ball_pos.clamp(rect.position, rect.end)
			var d := ball_pos - closest
			var dist := d.length()
			if dist >= BALL_R or dist <= 0.0001:
				continue
			var n := d / dist
			ball_pos += n * (BALL_R - dist)
			var vn := vel.dot(n)
			if vn < 0.0:
				vel -= (1.0 + BOUNCE) * vn * n
				if -vn > 220.0 and bump_cooldown <= 0.0:
					bump_cooldown = 0.12
					_sfx("res://sounds/fx/clack.mp3", clampf(-26.0 + (-vn) / 40.0, -24.0, -8.0))
					Input.vibrate_handheld(12)

func _apply_hole_pull(dt: float) -> void:
	for h in holes:
		var d := h - ball_pos
		var l := d.length()
		if l < HOLE_R + 6.0 and l > 0.001:
			vel += d / l * HOLE_PULL * (1.0 - l / (HOLE_R + 6.0)) * dt

func _check_holes() -> void:
	for h in holes:
		if ball_pos.distance_to(h) < HOLE_FALL_R:
			_fall_into(h)
			return

func _check_checkpoints() -> void:
	for cp in checkpoints:
		if cp["taken"] or ball_pos.distance_to(cp["pos"]) > CHECK_R:
			continue
		cp["taken"] = true
		respawn_pos = cp["pos"]
		add_score(10)
		_sfx("res://sounds/fx/gamecoin.wav", -10.0)
		Input.vibrate_handheld(20)
		var s: Sprite2D = cp["node"]
		var t := create_tween()
		t.tween_property(s, "scale", Vector2(DETAIL, DETAIL) * 1.6, 0.12)
		t.tween_property(s, "scale", Vector2(DETAIL, DETAIL), 0.15)
		t.parallel().tween_property(s, "modulate", Color(0.45, 0.35, 0.3, 0.55), 0.3)
		(cp["label"] as Label).modulate.a = 0.4
		_float_text("+10", cp["pos"])

func _check_finish() -> void:
	if ball_pos.distance_to(finish_pos) > FINISH_R:
		return
	state = State.CLEAR
	vel = Vector2.ZERO
	var bonus := 50 + maxi(0, 60 - int(level_time)) * 2
	add_score(bonus)
	_sfx("res://sounds/fx/water-pouring-98795.mp3", -12.0, 1.4)
	Input.vibrate_handheld(60)
	# Flushed! Spiral into the swirl
	var t := create_tween()
	t.tween_property(ball, "position", finish_pos, 0.25)
	t.parallel().tween_property(ball, "rotation", ball.rotation + TAU * 3.0, 1.0)
	t.parallel().tween_property(ball, "scale", Vector2(0.1, 0.1), 1.0).set_ease(Tween.EASE_IN)
	_show_banner("LEVEL %d CLEAR!\n+%d" % [level, bonus], 1.6)
	t.tween_interval(1.0)
	t.tween_callback(func():
		if not is_running:
			return
		level += 1
		ball.scale = Vector2.ONE
		_build_level()
		_show_banner("LEVEL %d" % level, 1.0))

func _fall_into(h: Vector2) -> void:
	state = State.FALLING
	vel = Vector2.ZERO
	lives -= 1
	_refresh_lives()
	_sfx("res://sounds/fx/sfx_sounds_falling4.wav", -8.0)
	Input.vibrate_handheld(90)
	var t := create_tween()
	t.tween_property(ball, "position", h, 0.12)
	t.tween_property(ball, "scale", Vector2(0.15, 0.15), 0.45).set_ease(Tween.EASE_IN)
	t.parallel().tween_property(ball, "modulate", Color(0.2, 0.15, 0.1, 1), 0.45)
	t.tween_callback(func():
		if lives <= 0:
			end_game()
			return
		ball_pos = respawn_pos
		ball.position = ball_pos
		ball.scale = Vector2.ONE
		ball.modulate = Color(1, 1, 1, 1)
		state = State.PLAY
		var blink := create_tween()
		for i in 4:
			blink.tween_property(ball, "modulate:a", 0.2, 0.08)
			blink.tween_property(ball, "modulate:a", 1.0, 0.08))

# ================================================================== INPUT

func _has_tilt_sensor() -> bool:
	return Input.get_gravity() != Vector3.ZERO or Input.get_accelerometer() != Vector3.ZERO

func _sensor_tilt() -> Vector2:
	var g := Input.get_gravity()
	if g == Vector3.ZERO:
		g = Input.get_accelerometer()
	if g == Vector3.ZERO:
		return Vector2.ZERO
	var v := Vector2(g.x, -g.y) / 9.81
	return -v if INVERT_TILT else v

func _read_tilt() -> Vector2:
	var t := Vector2.ZERO
	if _has_tilt_sensor():
		t = (_sensor_tilt() - calib) * TILT_GAIN
	# Desktop fallbacks
	var k := Vector2(
		float(Input.is_key_pressed(KEY_RIGHT) or Input.is_key_pressed(KEY_D)) - float(Input.is_key_pressed(KEY_LEFT) or Input.is_key_pressed(KEY_A)),
		float(Input.is_key_pressed(KEY_DOWN) or Input.is_key_pressed(KEY_S)) - float(Input.is_key_pressed(KEY_UP) or Input.is_key_pressed(KEY_W)))
	t += k * 0.8
	if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT) and not _has_tilt_sensor():
		var m := get_local_mouse_position()
		if Rect2(Vector2.ZERO, Vector2(PLAY_WIDTH, PLAY_HEIGHT)).has_point(m):
			t += (m - ball_pos) / 220.0
	if t.length() < DEADZONE:
		return Vector2.ZERO
	return t.limit_length(1.0)

func on_main_button_pressed() -> void:
	if is_game_over:
		super.on_main_button_pressed()
		return
	# Current phone angle becomes "flat"
	calib = _sensor_tilt()
	_show_banner("Calibrated", 0.7)

func on_main_button_released() -> void:
	pass

func on_forward_button_pressed() -> void:
	if is_game_over:
		super.on_forward_button_pressed()

func end_game() -> void:
	state = State.FALLING
	banner.visible = false
	super.end_game()

# ================================================================== FX HELPERS

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
