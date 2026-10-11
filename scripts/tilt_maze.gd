extends BaseMinigame
## Tilt Maze — lay the phone flat and tilt it to roll your pal (curled into a ball)
## through a wooden labyrinth. Collect the numbered checkpoints, dodge the holes,
## reach the flush swirl. Every level is generated from a fixed seed, so level 1
## is always the same board and each level adds more holes.
##
## Tilt: gravity sensor on device. Desktop: arrow keys / WASD / hold mouse to pull.
## Tilt is measured from how the phone is held when each level starts (any angle works).
## Main button: set the current phone angle as "level" again (recalibrate).

# --- Board geometry (all logic runs in play-area coordinates, 950x948) ---
const PX := 4                         # world px per board pixel (chunky, like the pals' pixels)
const TILE := 56                      # world px per tile
const TILE_PX := TILE / PX            # 14 board px per tile
const GRID := 16                      # tiles per side
const CELLS := 5                      # maze cells per side: 2-tile corridors + 1-tile walls
const BOARD_PX := GRID * TILE_PX      # 224
const ORIGIN := Vector2(27, 26)       # board top-left inside the play area (centred)

# --- Ball physics ---
const BALL_R := 24.0
const DETAIL := 4                     # world px per texture px for small sprites (same grid as the board)
const BALL_SCALE := 3                 # (a finer grid than the board, for the face details)
const ACCEL := 1500.0                 # px/s² at full tilt
const FRICTION := 1.1                 # velocity damping per second
const MAX_SPEED := 720.0
const BOUNCE := 0.35
const TILT_GAIN := 2.2                # sensor tilt (in g) -> input strength
const DEADZONE := 0.04
## Flip if the ball rolls the wrong way on a given device
const INVERT_TILT := false

# --- Board features ---
const HOLE_R := 28.0
const HOLE_FALL_R := 19.0             # ball centre this close to a hole centre = falls in
const HOLE_PULL := 900.0
const CHECK_R := 34.0
const FINISH_R := 34.0
const HATCH_IN := 20                  # trapdoor opening, texture px (x DETAIL)
const LIVES := 3

# --- Palette: a wooden labyrinth toy (light plywood floor, darker wooden walls) ---
const WOOD := Color8(236, 206, 158)          # floor
const WOOD_GRAIN := Color8(216, 180, 128)
const WOOD_KNOT := Color8(196, 156, 104)
const WALL_TOP := Color8(214, 160, 100)      # wall planks
const WALL_MID := Color8(192, 136, 80)
const WALL_GRAIN := Color8(168, 112, 62)
const WALL_SIDE := Color8(132, 84, 48)
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
var bump_cooldown := 0.0

var board: Sprite2D
var finish_sprite: Sprite2D           # the flush swirl, under the trapdoor
var exit_node: Node2D                 # the trapdoor: frame + swirl + two hatch doors
var hatch_l: Sprite2D
var hatch_r: Sprite2D
var exit_open := false
var locked_hint_cd := 0.0
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
	game_music_path = "res://sounds/music/Hidden Passage.mp3"
	lcd_font = load("res://fonts/pixChicago.ttf")
	ball_texture = PalBall.texture()
	_create_static_nodes()
	intro_text = "Tilt to move your pal"
	intro_icon = ball_texture
	super._ready()

func start_game() -> void:
	super.start_game()
	level = 1
	lives = LIVES
	_build_level()

# ================================================================== LEVEL BUILD

func _build_level() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 7919 * level + 17
	_generate_maze(rng)
	_place_features(rng)
	board.texture = ImageTexture.create_from_image(_paint_board())
	_spawn_level_nodes()
	calibrate_tilt()                     # however the phone is held now = level
	ball_pos = start_pos
	respawn_pos = start_pos
	vel = Vector2.ZERO
	level_time = 0.0
	state = State.PLAY
	_refresh_lives()
	# (drawn right away, also while the how-to card waits)
	ball.position = ball_pos
	shadow.position = ball.position + Vector2(8, 20)
	hud_level.text = "LV %d" % level
	hud_time.text = "0:00"
	score_label.text = str(score)

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

	# Knock out a few extra walls (loops and shortcuts); fewer as the levels go up, so the
	# routes get longer and harder
	var extra := maxi(0, 5 - level)
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

## Maze distance (in cells) from one cell to every other, and the way back
func _bfs(from: Vector2i) -> Dictionary:
	var dist := { from: 0 }
	var prev := { from: from }
	var queue: Array[Vector2i] = [from]
	while queue.size() > 0:
		var c: Vector2i = queue.pop_front()
		for n in _cell_neighbors(c):
			if not dist.has(n):
				dist[n] = dist[c] + 1
				prev[n] = c
				queue.append(n)
	return { "dist": dist, "prev": prev }

func _path(a: Vector2i, b: Vector2i) -> Array[Vector2i]:
	var prev: Dictionary = _bfs(a)["prev"]
	var out: Array[Vector2i] = []
	var c := b
	while c != a:
		out.push_front(c)
		c = prev[c]
	return out

func _place_features(rng: RandomNumberGenerator) -> void:
	var start := Vector2i(0, 0)
	var all_cells: Array[Vector2i] = []
	for cy in CELLS:
		for cx in CELLS:
			all_cells.append(Vector2i(cx, cy))
	# Checkpoints spread all over the maze: each one as far (in maze distance) as possible
	# from the start and from the ones already picked. One more per level.
	var n_checks := clampi(2 + level, 3, 7)
	var dists := { start: _bfs(start)["dist"] }
	var min_d := {}
	for c in all_cells:
		min_d[c] = dists[start][c]
	var picked: Array[Vector2i] = []
	for i in n_checks + 1:                       # (+1: the finish)
		var best := Vector2i(-1, -1)
		var best_d := -1.0
		for c in all_cells:
			if c == start or c in picked:
				continue
			var d: float = min_d[c] + rng.randf() * 0.5          # (ties broken per level)
			if d > best_d:
				best_d = d
				best = c
		picked.append(best)
		dists[best] = _bfs(best)["dist"]
		for c in all_cells:
			min_d[c] = mini(min_d[c], dists[best][c])
	# Visit them nearest-first from the start; the last one is the finish
	var order: Array[Vector2i] = []
	var cur := start
	while picked.size() > 0:
		var nxt: Vector2i = picked[0]
		for c in picked:
			if dists[cur][c] < dists[cur][nxt]:
				nxt = c
		order.append(nxt)
		picked.erase(nxt)
		cur = nxt
	var last: Vector2i = order.pop_back()
	# the ink route goes through all of them
	path_cells.clear()
	path_cells.append(start)
	cur = start
	for c in order + [last]:
		path_cells.append_array(_path(cur, c))
		cur = c

	start_pos = _cell_center(start)
	finish_pos = _cell_center(last)
	checkpoints.clear()
	var check_cells := {}
	for c in order:
		check_cells[c] = true
		checkpoints.append({ "pos": _cell_center(c), "taken": false })

	# Holes: dead ends first (traps), then beside the route (tension)
	holes.clear()
	# (a gentle ramp: 2, 4, 6, 8... up to 18; early levels keep them spread out)
	var want := mini(level * 2, 18)
	var spacing := 2 if level <= 3 else (1 if level <= 6 else 0)   # free cells between holes
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
	var used: Array[Vector2i] = []
	for c in dead_ends:
		if holes.size() >= (want + 1) / 2:
			break
		if not _hole_room(c, used, spacing):
			continue
		used.append(c)
		holes.append(_cell_center(c))
	for c in others:
		if holes.size() >= want:
			break
		if not _hole_room(c, used, spacing):
			continue
		used.append(c)
		# One hole per cell, in a corner quadrant, so the other side stays passable
		var o := TILE * 0.5
		var q := Vector2(o if rng.randf() < 0.5 else -o, o if rng.randf() < 0.5 else -o)
		holes.append(_cell_center(c) + q)

## No other hole within `spacing` cells (so early levels don't bunch them up in one spot)
func _hole_room(c: Vector2i, used: Array[Vector2i], spacing: int) -> bool:
	for u in used:
		if maxi(absi(u.x - c.x), absi(u.y - c.y)) <= spacing:
			return false
	return true

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
	# a few knots in the plywood (fixed per board)
	var knots: Array[Vector2] = []
	for i in 7:
		knots.append(Vector2(noise.randf() * n, noise.randf() * n))
	var k := 0
	for y in n:
		var ty := y / t
		var ly := y % t
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
				# planks: the grain runs along the wall (horizontal unless it's a vertical run)
				var vertical := (up[i] == 0 or dn[i] == 0) and lf[i] + rt[i] > 0
				var along := float(y if vertical else x)
				var across := float(x if vertical else y)
				var grain := sin(across * 1.3 + sin(along * 0.11 + across * 0.7) * 1.6)
				if m <= 1:
					c = OUTLINE                                      # (2 px thick)
				elif d_dn <= 4:
					c = WALL_SIDE.darkened(0.1 * (4 - d_dn))         # front face, darker at the base
				elif d_up <= 2 or d_lf <= 2:
					c = WALL_TOP                                     # lit edges
				elif d_rt <= 2:
					c = WALL_MID.darkened(0.08)
				else:
					c = WALL_MID if grain < 0.35 else WALL_GRAIN
					if grain > 0.85:
						c = WALL_GRAIN.darkened(0.08)
			else:
				# plywood: soft wavy grain bands + a few knots, quantized (pixel art, no gradients)
				var g := sin(y * 0.55 + sin(x * 0.07 + y * 0.02) * 2.4)
				c = WOOD if g < 0.45 else WOOD_GRAIN
				for kp in knots:
					var kd := Vector2((x - kp.x) * 0.6, y - kp.y).length()
					if kd < 2.2:
						c = WOOD_KNOT
					elif kd < 3.4:
						c = WOOD_GRAIN
				# drop shadow of the walls (light from the top-left), two steps
				if _is_wall_px(x - 1, y - 2):
					c = c.darkened(0.2)
				elif _is_wall_px(x - 2, y - 3):
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
	_ink_ring(img, _to_px(start_pos), 7.0)

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
		var x := int(p.x)
		var y := int(p.y)
		if not _is_wall_px(x, y):
			_blend(img, x, y, PATH_INK, 0.55)

func _ink_ring(img: Image, center: Vector2, r: float) -> void:
	for y in range(int(center.y - r - 2), int(center.y + r + 3)):
		for x in range(int(center.x - r - 2), int(center.x + r + 3)):
			var d := Vector2(x + 0.5, y + 0.5).distance_to(center)
			if not _is_wall_px(x, y) and absf(d - r) < 0.6:
				_blend(img, x, y, PATH_INK, 0.6)

## A hole drilled in the board: dark inside, a lit wooden lip at the bottom, a dark rim at
## the top (hard pixels, no blending)
func _paint_hole(img: Image, center: Vector2) -> void:
	var r := HOLE_R / PX
	for y in range(int(center.y - r - 2), int(center.y + r + 3)):
		for x in range(int(center.x - r - 2), int(center.x + r + 3)):
			if x < 0 or y < 0 or x >= BOARD_PX or y >= BOARD_PX:
				continue
			var off := Vector2(x + 0.5, y + 0.5) - center
			var d := off.length()
			if d > r + 0.5:
				continue
			var col := HOLE_DARK
			if d > r - 0.5:
				col = HOLE_RIM.lightened(0.15) if off.y > 0 else OUTLINE
			elif d > r - 1.5 and off.y > 0:
				col = HOLE_RIM
			elif d < r * 0.45:
				col = HOLE_DARK.darkened(0.3)
			img.set_pixel(x, y, col)

func _is_wall_px(x: int, y: int) -> bool:
	if x < 0 or y < 0 or x >= BOARD_PX or y >= BOARD_PX:
		return true
	return tiles[(y / TILE_PX) * GRID + (x / TILE_PX)] == 1

# ================================================================== NODES

func _create_static_nodes() -> void:
	var bg := ColorRect.new()
	bg.color = OUTLINE
	bg.size = Vector2(PLAY_WIDTH, PLAY_HEIGHT)
	add_child(bg)

	board = Sprite2D.new()
	board.centered = false
	board.position = ORIGIN
	board.scale = Vector2(PX, PX)
	board.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	add_child(board)

	level_nodes = Node2D.new()
	add_child(level_nodes)

	# The exit: a trapdoor in the floor; it opens once every pink ball is collected
	exit_node = Node2D.new()
	add_child(exit_node)
	var frame_s := Sprite2D.new()
	frame_s.texture = _make_hatch_frame_texture()
	frame_s.scale = Vector2(DETAIL, DETAIL)
	frame_s.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	exit_node.add_child(frame_s)
	finish_sprite = Sprite2D.new()
	finish_sprite.texture = _make_swirl_texture()
	finish_sprite.scale = Vector2(DETAIL, DETAIL)
	finish_sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	exit_node.add_child(finish_sprite)
	var leaf := _make_hatch_leaf_texture()
	hatch_l = Sprite2D.new()
	hatch_r = Sprite2D.new()
	for h in [hatch_l, hatch_r]:
		h.texture = leaf
		h.centered = false
		h.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		exit_node.add_child(h)
	# hinged on the outer edges; the right one is mirrored
	hatch_l.position = Vector2(-HATCH_IN / 2.0, -HATCH_IN / 2.0) * DETAIL
	hatch_r.position = Vector2(HATCH_IN / 2.0, -HATCH_IN / 2.0) * DETAIL

	shadow = Sprite2D.new()
	shadow.texture = _make_shadow_texture()
	shadow.scale = Vector2(DETAIL, DETAIL)
	shadow.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	add_child(shadow)

	ball = Sprite2D.new()
	ball.texture = ball_texture
	ball.scale = Vector2(BALL_SCALE, BALL_SCALE)
	ball.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	add_child(ball)

	# HUD lives on the top wall strip
	# (all on the top wooden rail, clear of the frame's edges)
	hud_level = _make_label(Vector2(ORIGIN.x + 22, ORIGIN.y + 2), Vector2(130, 52), 36, HORIZONTAL_ALIGNMENT_LEFT, Color(0.98, 0.93, 0.84))
	hud_time = _make_label(Vector2(PLAY_WIDTH / 2 - 85, ORIGIN.y + 2), Vector2(170, 52), 36, HORIZONTAL_ALIGNMENT_CENTER, Color(0.98, 0.93, 0.84))

	lives_box = HBoxContainer.new()
	lives_box.position = Vector2(ORIGIN.x + 150, ORIGIN.y + 8)
	lives_box.add_theme_constant_override("separation", 6)
	add_child(lives_box)

	var frame := ColorRect.new()
	frame.color = Color(0, 0, 0)
	frame.size = Vector2(176, 66)                 # (taller downwards so the digits sit comfortably)
	frame.position = Vector2(ORIGIN.x + BOARD_PX * PX - 20 - frame.size.x, ORIGIN.y + 3)
	add_child(frame)
	var box := ColorRect.new()
	box.color = Color(0.65, 0.72, 0.6)   # LCD green, like Pipe Dream
	box.position = frame.position + Vector2(5, 5)
	box.size = frame.size - Vector2(10, 10)
	add_child(box)
	score_label = _make_label(box.position + Vector2(6, 0), box.size - Vector2(14, 0), 32, HORIZONTAL_ALIGNMENT_RIGHT, Color(0.2, 0.15, 0.05))

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
	add_child(l)
	return l

func _spawn_level_nodes() -> void:
	for n in level_nodes.get_children():
		n.queue_free()
	exit_node.position = finish_pos
	_set_exit_open(false)
	var coin := _make_coin_texture()
	for cp in checkpoints:
		var s := Sprite2D.new()
		s.texture = coin
		s.scale = Vector2(DETAIL, DETAIL)
		s.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		s.position = cp["pos"]
		level_nodes.add_child(s)
		cp["node"] = s

func _refresh_lives() -> void:
	for n in lives_box.get_children():
		n.queue_free()
	for i in LIVES:
		var t := TextureRect.new()
		t.texture = ball_texture
		t.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		t.custom_minimum_size = Vector2(43, 43)          # (the 16 px ball inside a 24 px texture)
		t.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		t.modulate = Color(1, 1, 1, 1) if i < lives else Color(0, 0, 0, 0.35)
		lives_box.add_child(t)

# ================================================================== GENERATED TEXTURES

func _make_swirl_texture() -> Texture2D:
	## The goal: a little flush swirl (fills the trapdoor's opening).
	const S := HATCH_IN
	var img := Image.create(S, S, false, Image.FORMAT_RGBA8)
	var c := Vector2(S / 2.0, S / 2.0)
	for y in S:
		for x in S:
			var off := Vector2(x + 0.5, y + 0.5) - c
			var d := off.length()
			if d > S / 2.0:
				continue
			var col := Color8(84, 150, 206) if d > S * 0.25 else Color8(54, 110, 170)
			if d > S / 2.0 - 1.2:
				col = OUTLINE
			else:
				var arm := fposmod(off.angle() * 3.0 / TAU + d * 0.4, 1.0)
				if arm < 0.3:
					col = Color8(214, 240, 252)
				elif d < 2.5:
					col = Color8(30, 70, 120)
			img.set_pixel(x, y, col)
	return ImageTexture.create_from_image(img)

## Trapdoor shut (open = false) or fully open, without animation (a new level)
func _set_exit_open(open: bool) -> void:
	exit_open = open
	var sx := 0.0 if open else float(DETAIL)
	hatch_l.scale = Vector2(sx, DETAIL)
	hatch_r.scale = Vector2(-sx, DETAIL)
	hatch_l.visible = not open
	hatch_r.visible = not open
	hatch_l.modulate = Color(1, 1, 1)
	hatch_r.modulate = Color(1, 1, 1)
	finish_sprite.visible = open

## Every pink ball collected: the two hatch doors swing up (seen from above they get
## narrower and darker towards their hinges) and the flush swirl shows underneath.
func _open_exit() -> void:
	exit_open = true
	finish_sprite.visible = true
	hatch_l.visible = true
	hatch_r.visible = true
	_sfx("res://sounds/fx/unlock_ding.wav", -10.0)
	Input.vibrate_handheld(40)
	var t := create_tween().set_parallel(true)
	# a little rattle first...
	var rt := create_tween()
	rt.tween_property(exit_node, "position", finish_pos + Vector2(3, 0), 0.05)
	rt.tween_property(exit_node, "position", finish_pos + Vector2(-3, 0), 0.05)
	rt.tween_property(exit_node, "position", finish_pos, 0.05)
	# ...then the doors swing open
	t.tween_property(hatch_l, "scale:x", DETAIL * 0.4, 0.45).set_delay(0.15).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	t.tween_property(hatch_r, "scale:x", -DETAIL * 0.4, 0.45).set_delay(0.15).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	t.tween_property(hatch_l, "modulate", Color(0.62, 0.55, 0.5), 0.45).set_delay(0.15)
	t.tween_property(hatch_r, "modulate", Color(0.62, 0.55, 0.5), 0.45).set_delay(0.15)
	t.tween_callback(func(): _sfx("res://sounds/fx/clack.mp3", -12.0)).set_delay(0.3)

func _make_hatch_frame_texture() -> Texture2D:
	## The trapdoor's frame: a dark wooden rim round a deep opening (seen when it opens)
	const S := HATCH_IN + 4
	var img := Image.create(S, S, false, Image.FORMAT_RGBA8)
	for y in S:
		for x in S:
			var e := mini(mini(x, y), mini(S - 1 - x, S - 1 - y))
			var col: Color
			if e == 0:
				col = OUTLINE
			elif e == 1:
				col = WALL_SIDE if (x + y) % 5 != 0 else WALL_SIDE.darkened(0.15)
			elif e == 2 and (y == 2 or x == 2):
				col = OUTLINE.darkened(0.2)                  # the opening's shadowed inner lip
			else:
				col = Color8(36, 62, 96)                     # deep water down there
			img.set_pixel(x, y, col)
	# iron corner bolts
	for p in [Vector2i(1, 1), Vector2i(S - 2, 1), Vector2i(1, S - 2), Vector2i(S - 2, S - 2)]:
		img.set_pixel(p.x, p.y, Color8(70, 70, 76))
	return ImageTexture.create_from_image(img)

func _make_hatch_leaf_texture() -> Texture2D:
	## One hatch door (the left one; the right is mirrored). Hinge on the left edge,
	## the seam on the right edge, with half of the ring handle.
	const W := HATCH_IN / 2
	const H := HATCH_IN
	var img := Image.create(W, H, false, Image.FORMAT_RGBA8)
	var plank := Color8(176, 112, 64)
	var plank_lo := Color8(150, 92, 50)
	var iron := Color8(78, 74, 80)
	var iron_hi := Color8(132, 128, 136)
	for y in H:
		for x in W:
			var col := plank if (y / 3) % 2 == 0 else plank_lo
			if y % 3 == 2:
				col = col.darkened(0.18)                     # gaps between the boards
			if (x * 7 + y * 3) % 11 == 0:
				col = col.darkened(0.08)                     # grain specks
			if y == 3 or y == H - 4:
				col = iron if x > 0 else iron_hi             # iron straps from the hinge
			if x == W - 1:
				col = OUTLINE                                # the seam
			elif x == 0 and y % 6 == 1:
				col = iron_hi                                # hinge pins
			img.set_pixel(x, y, col)
	# half of the ring handle, at the seam
	for p in [Vector2i(W - 3, 8), Vector2i(W - 4, 9), Vector2i(W - 3, 10), Vector2i(W - 2, 11)]:
		img.set_pixel(p.x, p.y, Color8(206, 176, 92))
	img.set_pixel(W - 2, 8, Color8(110, 86, 40))
	return ImageTexture.create_from_image(img)

func _make_coin_texture() -> Texture2D:
	const S := 15
	var img := Image.create(S, S, false, Image.FORMAT_RGBA8)
	var c := Vector2(S / 2.0, S / 2.0)
	for y in S:
		for x in S:
			var off := Vector2(x + 0.5, y + 0.5) - c
			var d := off.length()
			if d > S / 2.0:
				continue
			var col := Color8(248, 150, 182) if off.x + off.y < 0 else Color8(214, 96, 136)
			if d > S / 2.0 - 1.1:
				col = Color8(110, 36, 70)
			elif Vector2(off.x + 2.5, off.y + 2.5).length() < 1.6:
				col = Color8(255, 222, 232)
			img.set_pixel(x, y, col)
	return ImageTexture.create_from_image(img)

func _make_shadow_texture() -> Texture2D:
	var img := Image.create(13, 7, false, Image.FORMAT_RGBA8)
	for y in 7:
		for x in 13:
			var off := Vector2((x + 0.5 - 6.5) / 6.5, (y + 0.5 - 3.5) / 3.5)
			var l := off.length()
			if l <= 1.0:
				img.set_pixel(x, y, Color(0.2, 0.1, 0.05, 0.32 if l < 0.7 else 0.18))
	return ImageTexture.create_from_image(img)

# ================================================================== LOOP

func _process(delta: float) -> void:
	if not is_running:
		return
	finish_sprite.rotation -= delta * 2.5
	locked_hint_cd = maxf(0.0, locked_hint_cd - delta)
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

	if state == State.PLAY:                 # (falling / flushed: the tweens move the ball)
		ball.position = ball_pos
	shadow.position = ball.position + Vector2(8, 20) * (ball.scale.x / BALL_SCALE)
	shadow.visible = state != State.FALLING
	hud_level.text = "LV %d" % level
	hud_time.text = "%d:%02d" % [int(level_time) / 60, int(level_time) % 60]
	score_label.text = str(score)
	# Shrink long numbers so they always fit the LCD box
	score_label.add_theme_font_size_override("font_size", 32 if score < 10000 else (27 if score < 100000 else 23))

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
					_sfx("res://sounds/fx/wood_tap.wav", clampf(-34.0 + (-vn) / 50.0, -30.0, -16.0), 0.0, randf_range(0.92, 1.08))
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
		_float_text("+10", cp["pos"])
		if not exit_open and checkpoints.all(func(c): return c["taken"]):
			_open_exit()

func _check_finish() -> void:
	if ball_pos.distance_to(finish_pos) > FINISH_R:
		return
	if not exit_open:
		# shut: it's just floor, but say why once in a while
		if locked_hint_cd <= 0.0:
			locked_hint_cd = 2.5
			_float_text("Get all the balls!", finish_pos)
		return
	state = State.CLEAR
	vel = Vector2.ZERO
	var bonus := 50 + maxi(0, 60 - int(level_time)) * 2
	add_score(bonus)
	Collection.report_game_levels(1, level)          # (levels cleared so far this run)
	_sfx("res://sounds/fx/water-pouring-98795.mp3", -12.0, 1.4)
	Input.vibrate_handheld(60)
	# Flushed! Spiral into the swirl
	var t := create_tween()
	ball_pos = finish_pos
	t.tween_property(ball, "position", finish_pos, 0.25).set_ease(Tween.EASE_OUT)
	t.parallel().tween_property(ball, "rotation", ball.rotation + TAU * 3.0, 1.0)
	t.parallel().tween_property(ball, "scale", Vector2(0.1, 0.1) * BALL_SCALE, 1.0).set_ease(Tween.EASE_IN)
	_show_banner("LEVEL %d CLEAR!\n+%d" % [level, bonus], 1.6)
	t.tween_interval(1.0)
	t.tween_callback(func():
		if not is_running:
			return
		level += 1
		ball.scale = Vector2(BALL_SCALE, BALL_SCALE)
		_build_level()
		_show_banner("LEVEL %d" % level, 1.0))

func _fall_into(h: Vector2) -> void:
	state = State.FALLING
	vel = Vector2.ZERO
	lives -= 1
	_refresh_lives()
	_sfx("res://sounds/fx/hole_plop.wav", -16.0)
	Input.vibrate_handheld(90)
	var t := create_tween()
	t.tween_property(ball, "position", h, 0.12)
	t.tween_property(ball, "scale", Vector2(0.15, 0.15) * BALL_SCALE, 0.45).set_ease(Tween.EASE_IN)
	t.parallel().tween_property(ball, "modulate", Color(0.2, 0.15, 0.1, 1), 0.45)
	t.tween_callback(func():
		if lives <= 0:
			end_game()
			return
		ball_pos = respawn_pos
		ball.position = ball_pos
		ball.scale = Vector2(BALL_SCALE, BALL_SCALE)
		ball.modulate = Color(1, 1, 1, 1)
		state = State.PLAY
		var blink := create_tween()
		for i in 4:
			blink.tween_property(ball, "modulate:a", 0.2, 0.08)
			blink.tween_property(ball, "modulate:a", 1.0, 0.08))

# ================================================================== INPUT

func _has_tilt_sensor() -> bool:
	return has_tilt_sensor()

func _sensor_tilt() -> Vector2:
	var v := device_tilt()                       # (measured from the pose at the round's start)
	return -v if INVERT_TILT else v

func _read_tilt() -> Vector2:
	var t := Vector2.ZERO
	if _has_tilt_sensor():
		t = _sensor_tilt() * TILT_GAIN
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
	if intro_active():
		dismiss_intro()
		return
	if is_game_over:
		super.on_main_button_pressed()
		return
	# Current phone angle becomes "flat"
	calibrate_tilt()
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
	var lx := clampf(at.x - 200, 30, PLAY_WIDTH - 430)          # (kept inside the board)
	var l := _make_label(Vector2(lx, at.y - 60), Vector2(400, 40), 28, HORIZONTAL_ALIGNMENT_CENTER, Color(1, 0.95, 0.85))
	l.add_theme_color_override("font_outline_color", OUTLINE)
	l.add_theme_constant_override("outline_size", 10)
	l.text = text
	var t := create_tween()
	t.tween_property(l, "position:y", l.position.y - 40, 0.6)
	t.parallel().tween_property(l, "modulate:a", 0.0, 0.6)
	t.tween_callback(l.queue_free)

func _sfx(path: String, volume_db: float, max_time := 0.0, pitch := 1.0) -> void:
	var stream = load(path) as AudioStream
	if not stream:
		return
	var sfx := AudioStreamPlayer.new()
	sfx.stream = stream
	sfx.volume_db = volume_db
	sfx.pitch_scale = pitch
	add_child(sfx)
	sfx.play()
	sfx.finished.connect(sfx.queue_free)
	if max_time > 0.0:
		get_tree().create_timer(max_time).timeout.connect(func():
			if is_instance_valid(sfx):
				sfx.queue_free())
