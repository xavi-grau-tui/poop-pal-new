extends BaseMinigame
## RC Racer (Pipe Dream's rework, its card for now) — your pal rides a little RC car round a toy
## race track raised on blocks above the floor, seen from above at an angle and close up (Micro
## Machines). The car drives by itself at a fixed speed; hold ORANGE to turn left, FORWARD to turn
## right (all the way round: the circuits wind, double back and hairpin). Drive off the track and
## the car falls to the floor: it's put back on the last checkpoint (the clock keeps going). 3 laps.
## The car is "sprite-stacked": a pile of pixel slices (wheels, body, the lit top), each turned
## with the car and drawn a little higher, so it shows its sides and looks solid as it turns.
##
## Circuits: a random patch of grid squares (grown square by square from a seed), and the road
## runs round its outline, every corner rounded (a quarter circle of half a square: two corners a
## square apart make a hairpin the car can just take). An outline never crosses itself, and any
## two stretches of it are at least a square apart, so the road never touches itself. More
## squares = more turns, U-turns and zig-zags; the best of SEED_TRIES patches (the most corners).
## The mats are always bigger than the screen: the view follows the car and shows only part of
## the circuit (Micro Machines), so you read the road as it comes.
##
## Levels (the level menu, BaseMinigame / LevelMenu): world 1, the Playroom, for now.
## Stars: 1 = finished, +1 = within the par time, +1 = never fell off.
##
## Later (user, 2026-10-15): a rival pal to beat, speed boosts (Mario Kart style), more worlds
## (kitchen tiles, the garden, the pipes, a toy race track), both buttons = drift.
## Desktop: Left / Right arrows (or A / D).

const PX := 4                         # world px per board px (the games' chunky grid)
const CELL := 260.0                   # a grid square, world px
const EDGE := 10                      # the mat's wooden frame, board px
const MARGIN := 24.0                  # road edge -> frame, world px
const SPEED := 270.0                  # mat px/s, always
const TURN := 3.1                     # rad/s while a button is held (a full turn in ~2 s)
const ZOOM := 1.5                     # the view, close up (board px shown 6 px)
const LOOK_AHEAD := 150.0             # the view looks this far ahead of the car (mat px)
const FALL_AT := 6.0                  # past the road's edge by this much: off the track
const CHECKPOINTS := 10               # per lap: where a fallen car is put back
const TRACK_SIDE := 6                 # the raised track's side face, board px (seen from the south)
const LAYERS := 6                     # the car's slices
const LAYER_UP := 2.5                 # each slice this much higher (mat px)
const LAPS := 3
const STEP := 8.0                     # centre-line points, every STEP px
const SEED_TRIES := 30
const PAR_SLACK := 1.15               # par time = a clean drive's time x this, + PAR_PLUS
const PAR_PLUS := 2.0
const COUNTDOWN := 3
## The view under the HUD (play-area px) and the HUD's band above it
const VIEW := Rect2(27, 92, 896, 830)
const HUD_BAND := Rect2(27, 26, 896, 66)

const WORLDS := ["Playroom"]
## The 9 Playroom circuits: [grid columns, rows, squares in the patch, road half-width px]
const LEVELS := [
	[4, 3, 6, 72.0], [4, 4, 8, 72.0], [5, 4, 10, 70.0], [5, 5, 12, 68.0], [6, 5, 14, 66.0],
	[6, 6, 17, 64.0], [7, 6, 20, 62.0], [7, 7, 24, 60.0], [8, 7, 28, 58.0],
]

# --- the Playroom's look (the Tilt Maze rules: hard pixels, a 2 px dark outline, top-left light) ---
const CARPET := [Color8(118, 146, 176), Color8(108, 134, 164), Color8(130, 158, 188)]
const ROAD := [Color8(112, 108, 118), Color8(100, 96, 106)]
const LINE := Color8(244, 240, 226)
const CURB := [Color8(226, 70, 64), Color8(246, 242, 232)]
const OUTLINE := Color8(40, 34, 44)
const SIDE := [Color8(236, 150, 64), Color8(198, 110, 44), Color8(150, 78, 34)]    # the track's orange plastic side
const BLOCK := [Color8(246, 214, 92), Color8(206, 168, 60)]                          # the yellow toy blocks under it
const MAT_EDGE := [Color8(214, 160, 100), Color8(132, 84, 48), Color8(74, 44, 32)]   # a wooden frame

enum State { WAIT, DRIVE, FALL, DONE }

var state := State.WAIT
var level := 1
var half_w := 70.0
var centre := PackedVector2Array()     # the circuit's centre line, mat px, closed, every ~STEP px
var count := 0                         # its points
var lap_length := 0.0
var par := 30.0
var mat_size := Vector2.ZERO           # mat px

var car_pos := Vector2.ZERO            # mat px
var heading := 0.0
var near := 0                          # the nearest centre-line point
var progress := 0.0                    # centre-line points passed (laps x count)
var lap := 1
var race_time := 0.0
var countdown := 0.0
var falls := 0
var last_cp := 0.0                     # progress at the last checkpoint passed
var held := [false, false]             # the device buttons (main = left, forward = right)
var _touch := {}                       # touch index -> button

var world: Node2D                      # the mat and the car (moved by the view)
var board: Sprite2D
var car: Node2D
var slices: Array[Sprite2D] = []       # the car, bottom slice first
var driver: Sprite2D
var shadow: Sprite2D
var car_drop := 0.0                    # how far the car has fallen (screen down, mat px)
var hud_lap: Label
var hud_time: Label
var hud_stars: Array[TextureRect] = []
var coin_label: Label
var banner: Label
var motor: AudioStreamPlayer
var lcd_font: Font
var _stars_shown := 3

func _ready() -> void:
	# (no game music: the main screen's songs go on playing)
	lcd_font = load("res://fonts/pixChicago.ttf")
	_create_nodes()
	intro_text = "Hold the orange button to turn left, forward to turn right"
	intro_icon = car_texture()
	super._ready()

# --- the level menu (BaseMinigame) ---

func uses_levels() -> bool:
	return true

func world_names() -> Array:
	return WORLDS

func level_count() -> int:
	return LEVELS.size()

func level_pattern() -> Texture2D:
	return load("res://textures/menus/pattern_pipe_brown.png")

func level_backdrop() -> Color:
	return Color8(168, 140, 110)

func start_game() -> void:
	super.start_game()
	_begin(1)

func play_level(n: int) -> void:
	super.start_game()
	_begin(n)

func _begin(n: int) -> void:
	level = clampi(n, 1, LEVELS.size())
	_build_circuit()
	board.texture = ImageTexture.create_from_image(_paint())
	car_pos = centre[0]
	heading = (centre[2] - centre[0]).angle()
	near = 0
	progress = 0.0
	lap = 1
	race_time = 0.0
	falls = 0
	last_cp = 0.0
	car_drop = 0.0
	held = [false, false]
	_touch.clear()
	_stars_shown = 3
	for s in hud_stars:
		s.texture = UiArt.star(true)
	state = State.WAIT
	countdown = COUNTDOWN + 0.6
	_place_car()
	_follow(1.0)
	_refresh_hud()
	_show_banner("1-%d" % level, 0.8)

# ================================================================== THE CIRCUIT

func _build_circuit() -> void:
	var spec: Array = LEVELS[level - 1]
	half_w = spec[3]
	var pad := EDGE * PX + half_w + MARGIN
	mat_size = Vector2(spec[0], spec[1]) * CELL + Vector2(pad, pad) * 2.0
	var best: Array = []
	var best_corners := -1
	for i in SEED_TRIES:
		var rng := RandomNumberGenerator.new()
		rng.seed = 6151 * level + 92821 * i + 3
		var corners := _patch_outline(rng, spec[0], spec[1], spec[2])
		if corners.size() > best_corners:
			best_corners = corners.size()
			best = corners
	# the outline's corners (grid points) -> mat px, the corners rounded, evenly spaced points
	var pts: Array[Vector2] = []
	for c in best:
		pts.append(Vector2(c) * CELL + Vector2(pad, pad))
	centre = _resample(_rounded(pts))
	count = centre.size()
	lap_length = count * STEP
	par = ceilf(lap_length * LAPS / SPEED * PAR_SLACK + PAR_PLUS)
	# start on the longest straight, a little after its start (drive clockwise on screen)
	var area := 0.0
	for i in count:
		area += centre[i].cross(centre[(i + 1) % count])
	if area < 0.0:
		centre.reverse()
	var best_i := 0
	var best_run := 0
	var run := 0
	for i in count * 2:
		var a := centre[i % count]
		var b := centre[(i + 1) % count]
		var c := centre[(i + 2) % count]
		if absf((b - a).angle_to(c - b)) < 0.01:
			run += 1
			if run > best_run:
				best_run = run
				best_i = (i - run / 2 + count) % count
		else:
			run = 0
	var rolled := PackedVector2Array()
	for i in count:
		rolled.append(centre[(best_i + i) % count])
	centre = rolled

## A patch of `n` grid squares grown from the middle, and its outline as corner points (grid
## coordinates, clockwise). No two squares may touch only at a corner (the outline would pinch)
func _patch_outline(rng: RandomNumberGenerator, cols: int, rows: int, n: int) -> Array:
	var cells := {}
	var first := Vector2i(cols / 2, rows / 2)
	cells[first] = true
	var tries := 0
	while cells.size() < n and tries < 400:
		tries += 1
		var from: Vector2i = cells.keys()[rng.randi() % cells.size()]
		var d: Vector2i = [Vector2i.RIGHT, Vector2i.LEFT, Vector2i.DOWN, Vector2i.UP][rng.randi() % 4]
		var c := from + d
		if c.x < 0 or c.y < 0 or c.x >= cols or c.y >= rows or cells.has(c):
			continue
		cells[c] = true
		if _pinched(cells) or _holed(cells, cols, rows):
			cells.erase(c)
	# the outline: each square's sides that face outside, as directed edges (clockwise round the
	# patch), linked end to start
	var nxt := {}
	for c in cells:
		var x: int = c.x
		var y: int = c.y
		if not cells.has(Vector2i(x, y - 1)): nxt[Vector2i(x, y)] = Vector2i(x + 1, y)
		if not cells.has(Vector2i(x + 1, y)): nxt[Vector2i(x + 1, y)] = Vector2i(x + 1, y + 1)
		if not cells.has(Vector2i(x, y + 1)): nxt[Vector2i(x + 1, y + 1)] = Vector2i(x, y + 1)
		if not cells.has(Vector2i(x - 1, y)): nxt[Vector2i(x, y + 1)] = Vector2i(x, y)
	var start: Vector2i = nxt.keys()[0]
	var loop: Array[Vector2i] = [start]
	var p: Vector2i = nxt[start]
	var guard := 0
	while p != start and guard < 1000:
		loop.append(p)
		p = nxt[p]
		guard += 1
	# keep only the corners (drop points along a straight side)
	var corners: Array = []
	for i in loop.size():
		var a: Vector2i = loop[(i - 1 + loop.size()) % loop.size()]
		var b: Vector2i = loop[i]
		var c: Vector2i = loop[(i + 1) % loop.size()]
		if (b - a) != (c - b):
			corners.append(b)
	return corners

func _pinched(cells: Dictionary) -> bool:
	for c in cells:
		for d in [Vector2i(1, 1), Vector2i(1, -1)]:
			var o: Vector2i = c + d
			if cells.has(o) and not cells.has(Vector2i(o.x, c.y)) and not cells.has(Vector2i(c.x, o.y)):
				return true
	return false

## An empty square closed in by the patch (a hole would make a second, inner outline)
func _holed(cells: Dictionary, cols: int, rows: int) -> bool:
	var seen := {}
	var queue: Array[Vector2i] = []
	for x in range(-1, cols + 1):
		for y in range(-1, rows + 1):
			if x == -1 or y == -1 or x == cols or y == rows:
				queue.append(Vector2i(x, y))
				seen[Vector2i(x, y)] = true
	while queue.size() > 0:
		var c: Vector2i = queue.pop_back()
		for d in [Vector2i.RIGHT, Vector2i.LEFT, Vector2i.DOWN, Vector2i.UP]:
			var o: Vector2i = c + d
			if o.x < -1 or o.y < -1 or o.x > cols or o.y > rows or seen.has(o) or cells.has(o):
				continue
			seen[o] = true
			queue.append(o)
	return seen.size() + cells.size() < (cols + 2) * (rows + 2)

## Every corner rounded: a quarter circle of up to half a square
func _rounded(pts: Array[Vector2]) -> PackedVector2Array:
	var out := PackedVector2Array()
	var n := pts.size()
	for i in n:
		var p := pts[(i - 1 + n) % n]
		var v := pts[i]
		var q := pts[(i + 1) % n]
		var r := minf(CELL * 0.5, minf(v.distance_to(p), v.distance_to(q)) * 0.5)
		var dp := (p - v).normalized()
		var dq := (q - v).normalized()
		var centre_pt := v + (dp + dq) * r
		var a0 := (v + dp * r - centre_pt).angle()
		var a1 := (v + dq * r - centre_pt).angle()
		var da := wrapf(a1 - a0, -PI, PI)
		for k in 9:
			out.append(centre_pt + Vector2.from_angle(a0 + da * k / 8.0) * r)
	return out

## Points every STEP px along the closed line
func _resample(line: PackedVector2Array) -> PackedVector2Array:
	var n := line.size()
	var total := 0.0
	for i in n:
		total += line[i].distance_to(line[(i + 1) % n])
	var m := int(total / STEP)
	var step := total / m
	var out := PackedVector2Array()
	var i := 0
	var at := 0.0
	for k in m:
		var want := k * step
		while i < n - 1 and at + line[i].distance_to(line[(i + 1) % n]) < want:
			at += line[i].distance_to(line[(i + 1) % n])
			i += 1
		var seg := line[i].distance_to(line[(i + 1) % n])
		out.append(line[i].lerp(line[(i + 1) % n], clampf((want - at) / maxf(seg, 0.001), 0.0, 1.0)))
	return out

# ================================================================== PAINTING

func _paint() -> Image:
	var w := int(mat_size.x / PX)
	var h := int(mat_size.y / PX)
	# the distance from each board px to the centre line (stamped round every other point), and
	# which point is nearest (for the curbs' stripes and the dashes)
	var dist := PackedFloat32Array()
	dist.resize(w * h)
	dist.fill(1e9)
	var idx := PackedInt32Array()
	idx.resize(w * h)
	var hw := half_w / PX
	var reach := hw + 4.0
	for s in range(0, count, 2):                     # (points 16 px apart: the discs overlap)
		var c := centre[s] / PX
		for y in range(maxi(0, int(c.y - reach)), mini(h, int(c.y + reach) + 1)):
			for x in range(maxi(0, int(c.x - reach)), mini(w, int(c.x + reach) + 1)):
				var d := Vector2(x + 0.5, y + 0.5).distance_to(c)
				var i := y * w + x
				if d < dist[i]:
					dist[i] = d
					idx[i] = s
	var data := PackedByteArray()
	data.resize(w * h * 4)
	var k := 0
	var curb := 3.0
	for y in h:
		for x in w:
			var i := y * w + x
			var d := dist[i]
			var col: Color
			var e := mini(mini(x, y), mini(w - 1 - x, h - 1 - y))
			if e < EDGE:
				# the mat's wooden frame: outlined both sides, lit top / left, shaded bottom / right
				if e <= 1 or e >= EDGE - 2:
					col = MAT_EDGE[2]
				elif (y < h / 2 and y == e) or (x < w / 2 and x == e) or (y < x and y < h - 1 - x and y < h / 2) or (x <= y and x < w - 1 - y and x < w / 2):
					col = MAT_EDGE[0]
				else:
					col = MAT_EDGE[1]
			elif d <= hw - curb:
				col = ROAD[0] if (x * 3 + y * 5) % 7 else ROAD[1]
				if d < 0.8 and (idx[i] / 6) % 2 == 0:
					col = LINE                                   # the dashed centre line
				if idx[i] <= 2 or idx[i] >= count - 2:
					col = Color8(30, 30, 34) if ((x / 2) + (y / 2)) % 2 else LINE   # the start / finish
			elif d <= hw:
				col = CURB[(idx[i] / 4) % 2]                     # red-and-white curbs
			elif d <= hw + 2.0:
				col = OUTLINE
			else:
				# below the road's south edge: the raised track's side (seen at an angle), on toy
				# blocks every so often; then the floor, the carpet, in the track's shadow
				var up_t := -1
				for t in range(1, TRACK_SIDE + 2):
					if y - t >= 0 and dist[(y - t) * w + x] <= hw + 2.0:
						up_t = t
						break
				if up_t >= 1 and up_t <= TRACK_SIDE:
					col = SIDE[0] if up_t <= 2 else (SIDE[1] if up_t < TRACK_SIDE else SIDE[2])
					if up_t > 2 and (idx[(y - up_t) * w + x] / 10) % 3 == 0:
						col = BLOCK[0] if up_t < TRACK_SIDE else BLOCK[1]          # a block holding it up
				elif up_t == TRACK_SIDE + 1:
					col = OUTLINE
				else:
					col = CARPET[0] if (x + y * 2) % 5 else CARPET[1]
					if (x * 7 + y * 3) % 23 == 0:
						col = CARPET[2]
					var sx := x - 3
					var sy := y - TRACK_SIDE - 3
					if sx >= 0 and sy >= 0 and dist[sy * w + sx] <= hw + 2.0:
						col = col.darkened(0.22)
			data[k] = col.r8
			data[k + 1] = col.g8
			data[k + 2] = col.b8
			data[k + 3] = 255
			k += 4
	return Image.create_from_data(w, h, false, Image.FORMAT_RGBA8, data)

## A little red RC car seen from above, nose to the right: 22 x 16 px (x4), a seat in the middle
static func car_texture() -> Texture2D:
	var rows := [
		"..####........####....",
		".#WWWW#......#WWWW#...",
		".#WWWW##########WWWW#.",
		"..###RRRRRRRRRRRR###..",
		"...#RRrrrrrrrrrrRRG#..",
		"..#RRrSSSSSSSSrrRRGG#.",
		"..#RrSS......SSrrRRGG#",
		"..#RrS........SrrRRYY#",
		"..#RrS........SrrRRYY#",
		"..#RrSS......SSrrRRGG#",
		"..#RRrSSSSSSSSrrRRGG#.",
		"...#RRrrrrrrrrrrRRG#..",
		"..###RRRRRRRRRRRR###..",
		".#WWWW##########WWWW#.",
		".#WWWW#......#WWWW#...",
		"..####........####....",
	]
	var cols := {
		"#": Color8(40, 30, 40), "W": Color8(52, 50, 58), "R": Color8(226, 70, 64), "r": Color8(190, 46, 50),
		"S": Color8(70, 56, 64), "G": Color8(150, 206, 236), "Y": Color8(250, 230, 120),
	}
	var img := Image.create(22, 16, false, Image.FORMAT_RGBA8)
	for y in 16:
		for x in 22:
			var ch: String = rows[y][x]
			if ch in cols:
				img.set_pixel(x, y, cols[ch])
	# the seat's floor (where the pal sits) and a white racing stripe over the nose
	for y in range(7, 9):
		for x in range(7, 14):
			img.set_pixel(x, y, Color8(96, 80, 88))
	for x in range(16, 19):
		img.set_pixel(x, 7, Color8(250, 246, 236))
		img.set_pixel(x, 8, Color8(250, 246, 236))
	return ImageTexture.create_from_image(img)

## The car as slices, bottom first (the same 22 x 16 footprint as car_texture): wheels, the
## body, the body with its cockpit and windscreen, its lit top rim
static func car_slices() -> Array[Texture2D]:
	var top := car_texture().get_image()
	var out: Array[Texture2D] = []
	var wheel := Color8(52, 50, 58)
	for layer in LAYERS:
		var img := Image.create(22, 16, false, Image.FORMAT_RGBA8)
		for y in 16:
			for x in 22:
				var c := top.get_pixel(x, y)
				if c.a == 0.0:
					continue
				var is_wheel := c.is_equal_approx(wheel) or (c.is_equal_approx(Color8(40, 30, 40)) and (y <= 2 or y >= 13))
				var col := Color(0, 0, 0, 0)
				if layer <= 1:
					col = c if is_wheel else (Color8(40, 30, 40) if x > 2 and x < 20 and y > 3 and y < 12 else col)
				elif layer == 2:
					col = c if is_wheel else (Color8(190, 46, 50) if not c.is_equal_approx(Color8(40, 30, 40)) else c)
				elif layer == 3:
					col = Color(0, 0, 0, 0) if is_wheel else (Color8(190, 46, 50) if not c.is_equal_approx(Color8(40, 30, 40)) else c)
				elif layer == 4:
					col = Color(0, 0, 0, 0) if is_wheel else c
				else:
					# the top rim: the body's lit edge round the open cockpit
					if is_wheel:
						continue
					col = c.lightened(0.18) if c.is_equal_approx(Color8(226, 70, 64)) else c
					if c.is_equal_approx(Color8(96, 80, 88)) or c.is_equal_approx(Color8(70, 56, 64)):
						col = Color(0, 0, 0, 0)                       # (the cockpit is open)
				if col.a > 0.0:
					img.set_pixel(x, y, col)
		out.append(ImageTexture.create_from_image(img))
	return out

# ================================================================== NODES

func _create_nodes() -> void:
	var bg := ColorRect.new()
	bg.color = MAT_EDGE[2]
	bg.size = Vector2(PLAY_WIDTH, PLAY_HEIGHT)
	add_child(bg)
	world = Node2D.new()
	add_child(world)
	board = Sprite2D.new()
	board.centered = false
	board.scale = Vector2(PX, PX)
	board.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	world.add_child(board)
	world.scale = Vector2(ZOOM, ZOOM)
	var layers := car_slices()
	shadow = Sprite2D.new()
	shadow.texture = layers[2]
	shadow.scale = Vector2(PX, PX)
	shadow.modulate = Color(0.05, 0.04, 0.1, 0.35)
	shadow.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	world.add_child(shadow)
	car = Node2D.new()
	world.add_child(car)
	for i in layers.size():
		var sl := Sprite2D.new()
		sl.texture = layers[i]
		sl.scale = Vector2(PX, PX)
		sl.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		# the lower slices darker: the car's sides in shade, its top in the light
		var k := 0.62 + 0.38 * float(i) / (layers.size() - 1)
		sl.modulate = Color(k, k, k)
		car.add_child(sl)
		slices.append(sl)
	# the pal, curled up in the seat (its face kept upright: it looks at you, not at the road)
	driver = Sprite2D.new()
	driver.texture = PalBall.texture()
	driver.scale = Vector2(2, 2)
	driver.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	world.add_child(driver)

	# the HUD on a wooden band above the view: the lap, the clock / par, the stars, the coins
	var band := ColorRect.new()
	band.color = MAT_EDGE[1]
	band.position = HUD_BAND.position
	band.size = HUD_BAND.size
	add_child(band)
	var line := ColorRect.new()
	line.color = MAT_EDGE[2]
	line.position = Vector2(HUD_BAND.position.x, HUD_BAND.end.y - 8)
	line.size = Vector2(HUD_BAND.size.x, 8)
	add_child(line)
	var light := Color(0.98, 0.93, 0.84)
	hud_lap = _label(Vector2(HUD_BAND.position.x + 18, HUD_BAND.position.y + 2), Vector2(190, 52), 32, HORIZONTAL_ALIGNMENT_LEFT, light)
	hud_time = _label(Vector2(HUD_BAND.position.x + 200, HUD_BAND.position.y + 2), Vector2(220, 52), 32, HORIZONTAL_ALIGNMENT_CENTER, light)
	for i in 3:
		var st := TextureRect.new()
		st.texture = UiArt.star(true)
		st.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		st.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		st.size = Vector2(36, 36)
		st.pivot_offset = st.size / 2.0
		st.position = Vector2(HUD_BAND.position.x + 432 + i * 40, HUD_BAND.position.y + 10)
		add_child(st)
		hud_stars.append(st)
	var frame := ColorRect.new()
	frame.color = Color(0, 0, 0)
	frame.size = Vector2(170, 52)
	frame.position = Vector2(HUD_BAND.end.x - 14 - frame.size.x, HUD_BAND.position.y + 4)
	add_child(frame)
	var box := ColorRect.new()
	box.color = Color(0.65, 0.72, 0.6)
	box.position = frame.position + Vector2(5, 5)
	box.size = frame.size - Vector2(10, 10)
	add_child(box)
	var coin := TextureRect.new()
	coin.texture = UiArt.coin()
	coin.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	coin.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	coin.size = Vector2(32, 32)
	coin.position = box.position + Vector2(8, (box.size.y - 32) / 2.0)
	add_child(coin)
	coin_label = _label(box.position + Vector2(44, 0), box.size - Vector2(54, 0), 28, HORIZONTAL_ALIGNMENT_RIGHT, Color(0.2, 0.15, 0.05))

	banner = _label(Vector2(0, PLAY_HEIGHT / 2 - 70), Vector2(PLAY_WIDTH, 140), 72, HORIZONTAL_ALIGNMENT_CENTER, Color(1, 0.97, 0.9))
	banner.add_theme_color_override("font_outline_color", MAT_EDGE[2])
	banner.add_theme_constant_override("outline_size", 16)
	banner.modulate.a = 0.0

	motor = AudioStreamPlayer.new()
	var hum: AudioStream = load("res://sounds/fx/Retro-Vehicle-Motor-02.mp3").duplicate()
	if hum is AudioStreamMP3:
		hum.loop = true                              # (the motor hums the whole race)
	motor.stream = hum
	motor.volume_db = -26.0
	add_child(motor)

func _label(pos: Vector2, sz: Vector2, font_size: int, align: int, color: Color) -> Label:
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

func _place_car() -> void:
	car.position = car_pos.round() + Vector2(0, car_drop)
	for i in slices.size():
		slices[i].rotation = heading
		slices[i].position = Vector2(0, -i * LAYER_UP)          # (lifted on screen, not turned)
	shadow.position = car_pos.round() + Vector2(5, 8 + car_drop * 0.3)
	shadow.rotation = heading
	shadow.visible = state != State.FALL
	driver.position = car.position + Vector2.from_angle(heading) * -5.0 + Vector2(0, -LAYERS * LAYER_UP - 4.0)

## The view follows the car (a small mat just sits in the middle of it)
func _follow(amount: float) -> void:
	var aim := car_pos + Vector2.from_angle(heading) * LOOK_AHEAD
	var want := VIEW.get_center() - aim * ZOOM
	var shown := mat_size * ZOOM
	var pos := Vector2.ZERO
	for ax in 2:
		var view_len := VIEW.size[ax]
		if shown[ax] <= view_len:
			pos[ax] = VIEW.position[ax] + (view_len - shown[ax]) / 2.0
		else:
			pos[ax] = clampf(want[ax], VIEW.end[ax] - shown[ax], VIEW.position[ax])
	world.position = world.position.lerp(pos, amount).round()

func _refresh_hud() -> void:
	hud_lap.text = "LAP %d/%d" % [mini(lap, LAPS), LAPS]
	var tm := "%d:%02d" % [int(race_time) / 60, int(race_time) % 60]
	var pt := "%d:%02d" % [int(par) / 60, int(par) % 60]
	hud_time.text = "%s/%s" % [tm, pt]
	hud_time.add_theme_color_override("font_color", Color(0.98, 0.93, 0.84) if race_time <= par else Color(0.95, 0.55, 0.45))
	coin_label.text = str(GameData.coins)
	var now := _stars_now()
	if now < _stars_shown:
		for i in range(now, _stars_shown):
			var st := hud_stars[i]
			st.texture = UiArt.star(false)
			var t := create_tween()
			t.tween_property(st, "scale", Vector2(1.4, 1.4), 0.08)
			t.tween_property(st, "scale", Vector2.ONE, 0.2)
		_stars_shown = now

## 1 + within the par time + never fell off
func _stars_now() -> int:
	return 1 + (1 if race_time <= par else 0) + (1 if falls == 0 else 0)

# ================================================================== LOOP

func _process(delta: float) -> void:
	if not is_running:
		if motor.playing:
			motor.stop()
		return
	match state:
		State.WAIT:
			var before := ceili(countdown - 0.6)
			countdown -= delta
			var now := ceili(countdown - 0.6)
			if now != before and now >= 1 and now <= COUNTDOWN:
				_show_banner(str(now), 0.35)
				_sfx("res://sounds/fx/click-5.mp3", -10.0, 0.9)
			if countdown <= 0.6:
				state = State.DRIVE
				_show_banner("GO!", 0.5)
				_sfx("res://sounds/fx/click-5.mp3", -6.0, 1.4)
				motor.play()
		State.DRIVE:
			_drive(delta)
	_place_car()
	_follow(minf(1.0, delta * 6.0))

func _drive(delta: float) -> void:
	race_time += delta
	var turn := (1.0 if _held(1) else 0.0) - (1.0 if _held(0) else 0.0)
	heading += turn * TURN * delta
	car_pos += Vector2.from_angle(heading) * SPEED * delta
	_find_near()
	if progress >= last_cp + count / CHECKPOINTS:
		last_cp = floorf(progress / (count / CHECKPOINTS)) * (count / CHECKPOINTS)
	if car_pos.distance_to(centre[near]) > half_w + FALL_AT:
		_fall()
		return
	if motor.playing:
		motor.pitch_scale = lerpf(motor.pitch_scale, 1.0 + absf(turn) * 0.08, minf(1.0, delta * 6.0))
	if progress >= count * lap and lap <= LAPS:
		lap += 1
		if lap > LAPS:
			_finish()
			return
		_show_banner("LAP %d" % lap if lap < LAPS else "FINAL LAP!", 0.7)
		_sfx("res://sounds/fx/gamecoin.wav", -10.0)
	_refresh_hud()

## Off the track: the car tips over the edge and drops to the floor, then it's back on the last
## checkpoint, pointing down the road (the clock goes on; the no-fall star is gone)
func _fall() -> void:
	state = State.FALL
	falls += 1
	motor.stop()
	_sfx("res://sounds/fx/sfx_sounds_falling4.wav", -12.0)
	Input.vibrate_handheld(80)
	var t := create_tween()
	t.tween_method(func(f: float):
		car_drop = f * f * TRACK_SIDE * PX * 3.0
		car.modulate = Color(1, 1, 1).lerp(Color(0.4, 0.38, 0.45), f)
		car.scale = Vector2.ONE * (1.0 - 0.15 * f), 0.0, 1.0, 0.45)
	t.tween_callback(func(): _sfx("res://sounds/fx/hole_plop.wav", -14.0, 1.3))
	t.tween_interval(0.35)
	t.tween_callback(func():
		var i := int(fposmod(last_cp, count))
		car_pos = centre[i]
		heading = (centre[(i + 2) % count] - centre[i]).angle()
		near = i
		progress = last_cp
		car_drop = 0.0
		car.modulate = Color(1, 1, 1)
		car.scale = Vector2.ONE
		held = [false, false]
		state = State.DRIVE
		motor.play()
		var blink := create_tween()
		for k in 3:
			blink.tween_property(car, "modulate:a", 0.25, 0.08)
			blink.tween_property(car, "modulate:a", 1.0, 0.08))

## The nearest centre-line point, searched near the last one; progress counts the points passed
## (forwards only adds up: driving the wrong way takes it back)
func _find_near() -> void:
	var best := near
	var best_d := car_pos.distance_squared_to(centre[near])
	for o in range(-30, 31):
		var j := (near + o + count) % count
		var d := car_pos.distance_squared_to(centre[j])
		if d < best_d:
			best_d = d
			best = j
	var step := best - near
	if step > count / 2:
		step -= count
	elif step < -count / 2:
		step += count
	progress += step
	near = best

func _finish() -> void:
	state = State.DONE
	motor.stop()
	var stars := _stars_now()
	_show_banner("FINISH!", 1.0)
	_sfx("res://sounds/fx/unlock_ding.wav", -8.0)
	Input.vibrate_handheld(60)
	_refresh_hud()
	get_tree().create_timer(1.4).timeout.connect(func():
		if is_running:
			finish_level(level, stars))

# ================================================================== INPUT

func _held(i: int) -> bool:
	if held[i] or i in _touch.values():
		return true
	if i == 0:
		return Input.is_key_pressed(KEY_LEFT) or Input.is_key_pressed(KEY_A)
	return Input.is_key_pressed(KEY_RIGHT) or Input.is_key_pressed(KEY_D)

## Two thumbs on the device's two buttons at once: read the touches directly (the emulated mouse
## follows one finger only)
func _input(event: InputEvent) -> void:
	if not (event is InputEventScreenTouch) or not is_running:
		return
	if event.pressed:
		var b := device_button_at(event.position)
		if b >= 0:
			_touch[event.index] = b
	else:
		_touch.erase(event.index)

func on_main_button_pressed() -> void:
	if intro_active():
		dismiss_intro()
		return
	if is_game_over or level_menu_open():
		super.on_main_button_pressed()
		return
	held[0] = true

func on_main_button_released() -> void:
	if level_menu_open():
		super.on_main_button_released()
		return
	held[0] = false

func on_forward_button_down() -> void:
	if not is_game_over and not level_menu_open() and is_running:
		held[1] = true

func on_forward_button_up() -> void:
	held[1] = false

func on_forward_button_pressed() -> void:
	if is_game_over or level_menu_open():
		super.on_forward_button_pressed()

# ================================================================== FX

func _show_banner(text: String, hold: float) -> void:
	banner.text = text
	var t := create_tween()
	t.tween_property(banner, "modulate:a", 1.0, 0.1)
	t.tween_interval(hold)
	t.tween_property(banner, "modulate:a", 0.0, 0.2)

func _sfx(path: String, volume_db: float, pitch := 1.0) -> void:
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
