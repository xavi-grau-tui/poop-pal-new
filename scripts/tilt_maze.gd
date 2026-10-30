extends BaseMinigame
## Tilt Maze — lay the phone flat and tilt it to roll your pal (curled into a ball)
## through a labyrinth toy. Collect every marble (they open the trapdoor), dodge the holes,
## roll into the flush swirl.
##
## Levels: 6 worlds of 9 (WORLDS), picked in the level menu (BaseMinigame / LevelMenu). Every
## world has its own look (TiltMazeArt.THEMES) and brings in one new thing, shown alone on its
## first levels, then mixed with what came before:
##   1 Wooden Toy (the basics: tilt, walls, then holes) · 2 Bath Tiles (a slippery floor) ·
##   3 The Gut (bouncy walls, holes that drift) · 4 Sewer (currents that push the ball) ·
##   5 Factory (magnets that pull it) · 6 Space (low gravity, goo that slows it)
## Each level is made by the maze generator from a seed, the best of SEED_TRIES for the route
## length that level should have (so difficulty climbs smoothly, the same board every time).
##
## Lives (BaseMinigame, the user 2026-10-17): 3 hearts. A fall into a hole puts the pal back on the
## last marble collected (the time keeps running) and breaks a heart; the third ends the level (Out
## of lives!: retry starts it again). Stars: 1 = cleared, +1 = within the par time (from the route's
## length), +1 = no fall at all. Speed against care: going fast is how you fall. A SPLASH pal (a
## watery drink) has a fourth, a water heart: it bounces straight back out of its first fall (the
## boost is spent).
##
## The marbles are the level's progress: each one fills a slot of the tray on the HUD with a
## higher note (a little scale), and the last one rings out as the trapdoor opens.
##
## BLOCKERS (from a world's 4th level, more as it goes on; the finale adds the world before's):
## one kind per world, each telegraphed before it bites: 1 wooden pegs that pop up in a doorway ·
## 2 a rubber duck crossing a corridor (it rests against a wall between crossings) · 3 gut valves
## that squeeze shut · 4 a sewer rat that pops out of its grate, runs up the route and back in · 5
## fire jets that flare up in a doorway · 6 meteors that land on the route (a shadow first).
## The pegs and the valves are doors (wait for them); the duck, the rat, a flame and a meteor are
## ENEMIES (the user, 2026-10-18): touching one knocks the ball back in a little hop (over any hole),
## it blinks a moment (nothing hurts it meanwhile, so it gets past) and a heart breaks.
##
## Vaults (VAULTS): a dead end off the route holds a prize, visible from the first visit, behind
## a gate only the right boost opens (at least the gate's level: worlds 1-2 = 1, 3-4 = 2, 5-6 = 3;
## the sign on it shows the drink and the level). Every boost has its own gate (the boost is spent
## opening it, never on a level without one):
##   fizzy        a low fence across its door: a fizzy pal hops it (the fence falls flat)
##   milky        a cracked wall: a sturdy pal rams through it
##   watery       a deep channel: a splashy pal skims across it
##   caffeinated  a shutter that snaps open for an instant: a focused pal times it
##   fruity       a locked chest holds the prize: a lucky pal finds the key
##   skill        no gate, but two holes guard its door: a steady hand gets through
## Prizes: stickers of your own pals, special foods, world dress-ups (snorkel, headlamp, hard hat), gut decor,
## backgrounds. Taken once (BaseMinigame.take_secret). The finale of world 6 holds the game's case.
##
## The look (the user, 2026-10-19: the toy games at the race games' quality, one suite; GameFx,
## docs/ideas_roadmap.md "The games' look"): the 3D tilt (the walls and the frame stand up off the
## floor, solid; the tops held still on the screen, the floor and all on it sliding under them as the
## phone tilts, the walls' sides showing: TOPS_FIXED), the pal really rolling (tilt_ball.gdshader),
## the marbles, the blockers and the vault's pieces standing up off the floor (_raise), each world's light over the board and something alive in it (GameFx.Ambience:
## dust in the window's light, soap bubbles, glowing spores, drips, a weld's sparks, twinkling
## stars), Pal Prix 2177's bursts for the moments (a marble taken, the trapdoor opening, a fall,
## an enemy's hit, a hard bump), a shake on the big ones, the race games' banner.
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

# --- Ball physics (each world scales them: WORLD_PHYSICS) ---
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
const DRIFT_R := 16.0                 # The Gut: a drifting hole's circle
const DRIFT_SPEED := 0.9              # ...radians per second
const CURRENT_PUSH := 1100.0          # Sewer: px/s² along a current
const MAGNET_R := 190.0               # Factory: a magnet's reach
const MAGNET_PULL := 1700.0           # ...and its pull at the magnet
const GOO_R := 30.0                   # Space: a goo puddle's radius
const GOO_DRAG := 6.0                 # ...extra damping per second inside it
const PRIZE_R := 40.0

## The worlds (one per page of the level menu) and what each brings, said on its first level
const WORLDS := ["Wooden Toy", "Bath Tiles", "The Gut", "Sewer", "Factory", "Space"]
const WORLD_HINTS := ["", "slippery floor!", "bouncy walls!", "currents push you!", "magnets pull you!", "low gravity!"]
## Per world: [accel, friction, bounce, max speed] multipliers of the constants above
const WORLD_PHYSICS := [
	[1.0, 1.0, 1.0, 1.0],
	[1.0, 0.28, 1.0, 1.05],      # tiles: the ball keeps sliding
	[1.0, 1.0, 2.5, 1.0],        # the gut: walls bounce it back
	[1.0, 1.0, 1.0, 1.0],
	[1.0, 1.0, 1.0, 1.0],
	[0.5, 0.42, 1.4, 0.72],      # space: floaty, slow to start and slow to stop
]
## Par time: seconds per maze cell of the route (+ PAR_BASE), per world (tune on the phone)
const PAR_BASE := 4.0
const PAR_PER_CELL := [1.25, 1.45, 1.35, 1.5, 1.5, 1.9]
## The levels of a world, 1st to 9th: marbles, holes, the world's things (currents, magnets...)
const MARBLES := [2, 2, 3, 3, 3, 4, 4, 5, 5]
const HOLES := [0, 1, 2, 3, 4, 5, 6, 7, 8]
const THINGS := [1, 2, 2, 3, 3, 3, 4, 4, 5]
## From the 7th level of a world, the world before's thing joins in
const MIX_FROM := 6
const SEED_TRIES := 24

## Vaults: level -> [gate (a drink type, or "skill"), prize] (Collection.give_prize's prizes)
## ("sticker:pal": a sticker of one of your own pals, never one you haven't met: Collection.give_prize)
const VAULTS := {
	3: ["fizzy", "sticker:pal"], 6: ["skill", "sticker:pal"], 8: ["fizzy", "sticker:pal"],
	12: ["fizzy", "sticker:pal"], 15: ["skill", "sticker:pal"], 17: ["milky", "acc:snorkel"],
	21: ["fizzy", "sticker:pal"], 24: ["skill", "sticker:pal"], 26: ["watery", "decor:hang_glow"],
	30: ["fizzy", "food:Microchip"], 33: ["caffeinated", "decor:shelf_kappa"], 35: ["milky", "acc:headlamp"],
	39: ["fizzy", "food:Battery"], 42: ["caffeinated", "decor:hang_cogs"], 44: ["milky", "acc:hard_hat"],
	48: ["fruity", "food:Moon Rock"], 51: ["watery", "bg:starfield"], 53: ["fruity", "food:Alien Goo"],
}
## The finale of the masters' world (6-9): the game's own case
const FINALES := { 54: "case:maze" }

## Blockers: one kind per world (see above), how many on each level of a world (from the 4th)
const BLOCKER_KIND := ["peg", "duck", "valve", "rat", "fire", "meteor"]
const BLOCKERS := [0, 0, 0, 1, 1, 2, 2, 2, 3]
const BLOCKER_HINTS := ["pegs pop up!", "watch the duck!", "valves squeeze!", "a rat!", "fire jets!", "meteors!"]
const PEG_R := 30.0                   # a peg / a valve / a fire jet: its round footprint in a doorway
const MOVER_R := 26.0                 # the duck, the rat: their round body
const METEOR_R := 34.0                # a meteor's impact

const TEXT_DARK := Color(0.2, 0.12, 0.08)

enum State { PLAY, FALLING, HOP, CLEAR }

var state := State.PLAY
var level := 1
var world := 0
var theme: Dictionary = TiltMazeArt.THEMES[0]
var level_time := 0.0
var falls := 0
var par := 30.0

# this level's physics (the world's, with its mixes)
var accel := ACCEL
var friction := FRICTION
var bounce := BOUNCE
var max_speed := MAX_SPEED
var drifting := false
var bouncy := false

var tiles := PackedByteArray()        # 1 = wall
var open_e := {}                      # Vector2i(cell) -> true if wall to the east is open
var open_s := {}                      # Vector2i(cell) -> true if wall to the south is open
var path_cells: Array[Vector2i] = []
var holes: Array[Dictionary] = []     # { pos, base, phase, node }
var checkpoints: Array[Dictionary] = []   # { pos, node, taken }
var currents: Array[Dictionary] = []  # { rect, dir }
var magnets: Array[Vector2] = []
var goos: Array[Vector2] = []
var vault := {}                       # { kind (its gate), lvl, prize, cell, door (Rect2), flat (gate open), prize_pos, taken, node }
var blockers: Array[Dictionary] = []  # { kind, pos, a, b, t (its clock), period, offset, node, ... } (see _place_blockers)
var tray: Array[TextureRect] = []     # the HUD's marble tray: one slot per marble
var marbles_taken := 0
var splash_used := false              # (a splashy pal's one bounce out of a fall, this level)
var start_pos := Vector2.ZERO
var finish_pos := Vector2.ZERO
var respawn_pos := Vector2.ZERO

var ball_pos := Vector2.ZERO
var vel := Vector2.ZERO
var bump_cooldown := 0.0
var hit_t := 0.0                      # after an enemy's hit: the hop back (in the air), then the blink
var qa_autopilot := false             # (tools/qa: the ball rolls itself along the route, for screenshots)
var _qa_step := 0
const HIT_HOP := 0.35                 # the hop: over any hole
const HIT_BLINK := 1.2                # ...then a blink: no enemy hurts it
const KNOCK := 560.0                  # how hard it's knocked back, px/s

var scene: Node2D                     # the board and everything on it (it shakes; the HUD stays put)
var board: Sprite2D                   # the floor and the frame (still)
var walls: Sprite2D                   # the walls' tops, the frame too (they rise off the floor: the 3D tilt)
var wall_sides: Array[Sprite2D] = []  # ...their sides, copies stacked under the tops, bottom first
var in_walls: Node2D                  # what's set in the walls (the magnets): it rises with them
var fx: GameFx.Burst
var ambience: GameFx.Ambience
var shake := 0.0
var finish_sprite: Sprite2D           # the flush swirl, under the trapdoor
var exit_node: Node2D                 # the trapdoor: frame + swirl + two hatch doors
var hatch_l: Sprite2D
var hatch_r: Sprite2D
var hatch_frame: Sprite2D
var exit_open := false
var locked_hint_cd := 0.0
var fence_hint_cd := 0.0
var ball: Sprite2D
var shadow: Sprite2D
var roll := Basis.IDENTITY            # the ball's turn (its art on a sphere: tilt_ball.gdshader)
var raised: Array[Dictionary] = []    # what stands up off the floor: { n (its top), base, h, sides } (_raise)
var depth_up := Vector2.ZERO          # the 3D tilt's lean of a wall's top, px (things lean by their height)
var pick_t := 0.0                     # the marbles' bob and spin
var level_nodes: Node2D
var current_layer: CurrentLayer
var hud_level: Label
var hud_time: Label
var hud_stars: Array[TextureRect] = []
var blocker_layer: Node2D
var banner: Label
var ball_texture: Texture2D
var lcd_font: Font
var _stars_shown := 3

## The Sewer's currents, drawn under the ball: water lanes with ripples that run with the flow
class CurrentLayer extends Node2D:
	var lanes: Array = []             # the game's currents
	var t := 0.0
	func _process(delta: float) -> void:
		t += delta
		queue_redraw()
	func _draw() -> void:
		for c in lanes:
			var r: Rect2 = c["rect"]
			var d: Vector2 = c["dir"]
			draw_rect(r, Color8(92, 150, 156, 150))
			# ripples: short light dashes on the 4 px grid, moving along the flow
			var along := r.size.x if d.x != 0.0 else r.size.y
			var across := r.size.y if d.x != 0.0 else r.size.x
			var step := 28.0
			var shift := fposmod(t * 90.0, step)
			var k := 0
			for a in range(0, int(along / step) + 1):
				for b in range(0, int(across / 24.0)):
					var pa := fposmod(a * step + (shift if (d.x + d.y) > 0.0 else -shift) + (b % 2) * 14.0, along)
					var pb := 12.0 + b * 24.0
					var p := Vector2(pa, pb) if d.x != 0.0 else Vector2(pb, pa)
					var sz := Vector2(12, 4) if d.x != 0.0 else Vector2(4, 12)
					p = (r.position + p).snapped(Vector2(4, 4))
					if r.has_point(p) and r.has_point(p + sz - Vector2.ONE):
						draw_rect(Rect2(p, sz), Color8(196, 232, 226, 200))
					k += 1

func _ready() -> void:
	game_music_path = "res://sounds/music/Hidden Passage.mp3"
	lcd_font = load("res://fonts/pixChicago.ttf")
	ball_texture = PalBall.texture()
	_create_static_nodes()
	intro_text = "Tilt to move your pal"
	intro_icon = ball_texture
	super._ready()

# --- the level menu (BaseMinigame) ---

func uses_levels() -> bool:
	return true

func world_names() -> Array:
	return WORLDS

func level_count() -> int:
	return WORLDS.size() * GameData.LEVELS_PER_WORLD

func level_pattern() -> Texture2D:
	return load("res://textures/menus/pattern_ball_moss.png")

func level_backdrop() -> Color:
	return TiltMazeArt.THEMES[0]["menu"]

func world_backdrop(w: int) -> Color:
	return TiltMazeArt.THEMES[clampi(w, 0, TiltMazeArt.THEMES.size() - 1)]["menu"]

## The vaults as BaseMinigame secrets (the level menu shows their gates), and the finale's prize
func secrets() -> Dictionary:
	var out := {}
	for lvl in VAULTS:
		out[lvl] = { "gate": VAULTS[lvl][0], "lvl": _gate_level((lvl - 1) / GameData.LEVELS_PER_WORLD), "prize": VAULTS[lvl][1] }
	return out

func finale_prizes() -> Dictionary:
	return FINALES

## A gate's level by world: worlds 1-2 = 1, 3-4 = 2, 5-6 = 3
func _gate_level(w: int) -> int:
	return 1 + clampi(w, 0, 5) / 2

func start_game() -> void:
	super.start_game()
	_begin(1)

## Chosen in the level menu (or NEXT / RETRY on the result card)
func play_level(n: int) -> void:
	super.start_game()                        # (score from 0, running)
	_begin(n)

func _begin(n: int) -> void:
	level = clampi(n, 1, level_count())
	_build_level()
	var k := (level - 1) % GameData.LEVELS_PER_WORLD
	if k == 0:
		_show_banner(WORLDS[world], 1.8)
		if WORLD_HINTS[world] != "":
			get_tree().create_timer(2.0).timeout.connect(func():
				if is_running and level == n:
					_show_banner(WORLD_HINTS[world], 1.4))
	elif k == 3:
		_show_banner("%d-%d" % [world + 1, k + 1], 1.0)
		get_tree().create_timer(1.3).timeout.connect(func():
			if is_running and level == n:
				_show_banner(BLOCKER_HINTS[world], 1.4))
	else:
		_show_banner("%d-%d" % [world + 1, k + 1], 1.0)

# ================================================================== LEVEL BUILD

func _build_level() -> void:
	world = clampi((level - 1) / GameData.LEVELS_PER_WORLD, 0, WORLDS.size() - 1)
	theme = TiltMazeArt.THEMES[world]
	var k := (level - 1) % GameData.LEVELS_PER_WORLD
	_set_physics(k)
	# the best of SEED_TRIES boards for this level's route length (the same pick every time)
	var target := 8 + k * 2 + world
	var best_seed := 0
	var best_err := 1 << 20
	for i in SEED_TRIES:
		var s := 7919 * level + 104729 * i + 17
		var rng := RandomNumberGenerator.new()
		rng.seed = s
		_generate_maze(rng, k)
		_place_route(rng, k)
		var err := absi(path_cells.size() - target)
		if level in VAULTS and _vault_cell().x < 0:
			err += 100                                   # (a vault level needs a free dead end)
		if err < best_err:
			best_err = err
			best_seed = s
		if err == 0:
			break
	var rng2 := RandomNumberGenerator.new()
	rng2.seed = best_seed
	_generate_maze(rng2, k)
	_place_route(rng2, k)
	_place_vault()
	_place_holes(rng2, k)
	_place_things(rng2, k)
	_place_blockers(rng2, k)
	par = ceilf(PAR_BASE + path_cells.size() * PAR_PER_CELL[world])
	var imgs := _paint_board()
	board.texture = ImageTexture.create_from_image(imgs[0])
	walls.texture = ImageTexture.create_from_image(imgs[1])
	var sides := ImageTexture.create_from_image(imgs[2])
	for sp in wall_sides:
		sp.texture = sides
	ambience.setup(theme["kind"], ORIGIN + Vector2(BOARD_PX, BOARD_PX) * PX / 2.0, BOARD_PX * PX / 2.0, Rect2(ORIGIN, Vector2(BOARD_PX, BOARD_PX) * PX))
	bg_rect.color = theme["outline"]
	_spawn_level_nodes()
	calibrate_tilt()                     # however the phone is held now = level
	ball_pos = start_pos
	respawn_pos = start_pos
	vel = Vector2.ZERO
	level_time = 0.0
	falls = 0
	hit_t = 0.0
	_qa_step = 0
	reset_lives()
	marbles_taken = 0
	splash_used = false
	state = State.PLAY
	# (drawn right away, also while the how-to card waits)
	ball.position = ball_pos
	ball.scale = Vector2(BALL_SCALE, BALL_SCALE)
	ball.modulate = Color(1, 1, 1, 1)
	ball.rotation = 0.0
	roll = Basis.IDENTITY
	_roll(0.0)
	shadow.position = ball.position + Vector2(6, 14)
	hud_level.text = "%d-%d" % [world + 1, k + 1]
	_build_tray()
	_stars_shown = 3
	for s in hud_stars:
		s.texture = UiArt.star(true)
	_refresh_hud()

## This level's physics: the world's own, plus the world before's thing from MIX_FROM on
func _set_physics(k: int) -> void:
	var ph: Array = WORLD_PHYSICS[world]
	accel = ACCEL * ph[0]
	friction = FRICTION * ph[1]
	bounce = BOUNCE * ph[2]
	max_speed = MAX_SPEED * ph[3]
	bouncy = world == 2 or (world == 3 and k >= MIX_FROM)
	if world == 3 and k >= MIX_FROM:
		bounce = BOUNCE * WORLD_PHYSICS[2][2]
	if world == 2 and k >= MIX_FROM:
		friction = FRICTION * 0.6                        # the gut gets slippery too
	drifting = world == 2 and k >= 1

func _generate_maze(rng: RandomNumberGenerator, k: int) -> void:
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

	# Knock out a few extra walls (loops and shortcuts); fewer as a world goes on, so the
	# routes get longer and harder
	var extra := maxi(0, 4 - k)
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

## The two floor tiles between two neighbouring cells (the gap in the wall), world px
func _door_rect(a: Vector2i, b: Vector2i) -> Rect2:
	var lo := Vector2i(mini(a.x, b.x), mini(a.y, b.y))
	if a.y == b.y:
		return Rect2(ORIGIN + Vector2(3 * lo.x + 3, 1 + 3 * lo.y) * TILE, Vector2(TILE, TILE * 2))
	return Rect2(ORIGIN + Vector2(1 + 3 * lo.x, 3 * lo.y + 3) * TILE, Vector2(TILE * 2, TILE))

func _cell_neighbors(c: Vector2i) -> Array[Vector2i]:
	var out: Array[Vector2i] = []
	if open_e.has(c): out.append(c + Vector2i.RIGHT)
	if open_s.has(c): out.append(c + Vector2i.DOWN)
	if open_e.has(c + Vector2i.LEFT): out.append(c + Vector2i.LEFT)
	if open_s.has(c + Vector2i.UP): out.append(c + Vector2i.UP)
	return out

func _cell_center(c: Vector2i) -> Vector2:
	return ORIGIN + Vector2(3 * c.x + 2, 3 * c.y + 2) * TILE

func _cell_of(p: Vector2) -> Vector2i:
	var t := (p - ORIGIN) / TILE
	return Vector2i(clampi(int(t.x) / 3, 0, CELLS - 1), clampi(int(t.y) / 3, 0, CELLS - 1))

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

var _check_cells := {}
var _finish_cell := Vector2i.ZERO

## The marbles (spread over the maze, visited nearest-first), the finish, the ink route
func _place_route(rng: RandomNumberGenerator, k: int) -> void:
	var start := Vector2i(0, 0)
	var all_cells: Array[Vector2i] = []
	for cy in CELLS:
		for cx in CELLS:
			all_cells.append(Vector2i(cx, cy))
	var n_checks: int = MARBLES[k]
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
	_finish_cell = order.pop_back()
	path_cells.clear()
	path_cells.append(start)
	cur = start
	for c in order + [_finish_cell]:
		path_cells.append_array(_path(cur, c))
		cur = c
	start_pos = _cell_center(start)
	finish_pos = _cell_center(_finish_cell)
	checkpoints.clear()
	_check_cells.clear()
	for c in order:
		_check_cells[c] = true
		checkpoints.append({ "pos": _cell_center(c), "taken": false })

## The vault's cell: a dead end off the route, its door right off the route if possible (the
## prize is seen on the way); (-1, -1) if the board has none
func _vault_cell() -> Vector2i:
	var on_path := {}
	for c in path_cells:
		on_path[c] = true
	var best := Vector2i(-1, -1)
	var best_score := -1
	for cy in CELLS:
		for cx in CELLS:
			var c := Vector2i(cx, cy)
			var nb := _cell_neighbors(c)
			if nb.size() != 1 or on_path.has(c) or c == Vector2i(0, 0):
				continue
			var sc := 10 if on_path.has(nb[0]) else 1
			if sc > best_score:
				best_score = sc
				best = c
	return best

## This level's vault, if it has one: a dead end off the route (next to it if possible)
func _place_vault() -> void:
	vault = {}
	if level not in VAULTS:
		return
	var best := _vault_cell()
	if best.x < 0:
		return
	var door_cell: Vector2i = _cell_neighbors(best)[0]
	var v: Array = VAULTS[level]
	var dir := Vector2(door_cell - best)
	vault = { "kind": v[0], "lvl": _gate_level(world), "prize": v[1], "cell": best, "dir": dir, "door": _door_rect(best, door_cell),
		"flat": false, "taken": GameData.vault_taken(_game_index(), level), "open": false,
		"prize_pos": _cell_center(best) - dir * TILE * 0.45 }

func _place_holes(rng: RandomNumberGenerator, k: int) -> void:
	holes.clear()
	var want: int = HOLES[k] + (1 if world >= 2 and k >= 2 else 0)
	var spacing := 2 if k <= 2 else (1 if k <= 5 else 0)   # free cells between holes
	var on_path := {}
	for c in path_cells:
		on_path[c] = true
	var keep_clear := {}
	if not vault.is_empty():
		keep_clear[vault["cell"]] = true
		var outside := _cell_of(_cell_center(vault["cell"]) + vault["dir"] * TILE * 3)
		keep_clear[outside] = true
		if vault["kind"] == "skill":                    # (its guard holes stand alone)
			for d in [Vector2i.RIGHT, Vector2i.LEFT, Vector2i.DOWN, Vector2i.UP]:
				keep_clear[outside + d] = true
	var dead_ends: Array[Vector2i] = []
	var others: Array[Vector2i] = []
	var start := Vector2i(0, 0)
	for cy in CELLS:
		for cx in CELLS:
			var c := Vector2i(cx, cy)
			if c == start or c == _finish_cell or _check_cells.has(c) or (c - start).length_squared() <= 1 or keep_clear.has(c):
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
		_add_hole(_cell_center(c), rng)
	for c in others:
		if holes.size() >= want:
			break
		if not _hole_room(c, used, spacing):
			continue
		used.append(c)
		# One hole per cell, in a corner quadrant, so the other side stays passable
		var o := TILE * 0.5
		var q := Vector2(o if rng.randf() < 0.5 else -o, o if rng.randf() < 0.5 else -o)
		_add_hole(_cell_center(c) + q, rng)
	# a skill vault: two holes guard its door (pass between them, in the middle)
	if not vault.is_empty() and vault["kind"] == "skill":
		var c := _cell_center(vault["cell"])
		var d: Vector2 = vault["dir"]
		var side := Vector2(d.y, d.x)
		for s in [-1.0, 1.0]:
			holes.append({ "pos": c + d * TILE * 0.5 + side * TILE * 0.5 * s, "base": c + d * TILE * 0.5 + side * TILE * 0.5 * s, "phase": 0.0, "drift": false })

func _add_hole(p: Vector2, rng: RandomNumberGenerator) -> void:
	holes.append({ "pos": p, "base": p, "phase": rng.randf() * TAU, "drift": drifting })

## No other hole within `spacing` cells (so early levels don't bunch them up in one spot)
func _hole_room(c: Vector2i, used: Array[Vector2i], spacing: int) -> bool:
	for u in used:
		if maxi(absi(u.x - c.x), absi(u.y - c.y)) <= spacing:
			return false
	return true

## The world's things: Sewer currents, Factory magnets, Space goo (and the mixes)
func _place_things(rng: RandomNumberGenerator, k: int) -> void:
	currents.clear()
	magnets.clear()
	goos.clear()
	var n: int = THINGS[k]
	var mix := k >= MIX_FROM
	if world == 3 or (world == 4 and mix):
		_place_currents(rng, n if world == 3 else 2)
	if world == 4 or (world == 5 and mix):
		_place_magnets(rng, n if world == 4 else 2)
	if world == 5:
		_place_goo(rng, n)

## Currents run along the route (with it or against it), between two cells, over their door
func _place_currents(rng: RandomNumberGenerator, n: int) -> void:
	var spans: Array[int] = []
	for i in range(1, path_cells.size() - 1):
		if path_cells[i] != path_cells[i + 1] and (path_cells[i] - path_cells[i + 1]).length_squared() == 1:
			spans.append(i)
	_shuffle(spans, rng)
	var used := {}
	for i in spans:
		if currents.size() >= n:
			break
		var a: Vector2i = path_cells[i]
		var b: Vector2i = path_cells[i + 1]
		if used.has(a) or used.has(b) or _check_cells.has(a) or _check_cells.has(b) or b == _finish_cell:
			continue
		used[a] = true
		used[b] = true
		var ra := Rect2(_cell_center(a) - Vector2(TILE, TILE), Vector2(TILE * 2, TILE * 2))
		var rb := Rect2(_cell_center(b) - Vector2(TILE, TILE), Vector2(TILE * 2, TILE * 2))
		var dir := Vector2(b - a)
		if rng.randf() < 0.4:
			dir = -dir                                   # some push against you
		currents.append({ "rect": ra.merge(rb), "dir": dir })

## Magnets sit in a wall beside the route, never next to the start
func _place_magnets(rng: RandomNumberGenerator, n: int) -> void:
	var spots: Array[Vector2] = []
	for i in range(2, path_cells.size()):
		var c: Vector2i = path_cells[i]
		for d in [Vector2i.RIGHT, Vector2i.LEFT, Vector2i.DOWN, Vector2i.UP]:
			var nb: Vector2i = c + d
			# (an inner wall only: the frame's own wall is half hidden by the screen's edge)
			var inside := nb.x >= 0 and nb.y >= 0 and nb.x < CELLS and nb.y < CELLS
			if inside and not (nb in _cell_neighbors(c)):
				spots.append(_cell_center(c) + Vector2(d) * TILE * 1.5)
	_shuffle(spots, rng)
	for p in spots:
		if magnets.size() >= n:
			break
		var ok := true
		for m in magnets:
			if m.distance_to(p) < TILE * 4:
				ok = false
		for h in holes:
			if h["pos"].distance_to(p) < TILE * 1.2:
				ok = false
		if ok:
			magnets.append(p)

## Goo puddles on the route's cells (not on a marble or the finish)
func _place_goo(rng: RandomNumberGenerator, n: int) -> void:
	var cells := path_cells.slice(2)
	_shuffle(cells, rng)
	for c in cells:
		if goos.size() >= n:
			break
		if _check_cells.has(c) or c == _finish_cell:
			continue
		var p := _cell_center(c) + Vector2(rng.randf_range(-12, 12), rng.randf_range(-12, 12))
		var ok := true
		for g in goos:
			if g.distance_to(p) < TILE * 2:
				ok = false
		for h in holes:
			if h["pos"].distance_to(p) < TILE:
				ok = false
		if ok:
			goos.append(p)

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

func _paint_board() -> Array:
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
	var wdata := PackedByteArray()                 # (the walls' tops, apart: clear elsewhere)
	wdata.resize(n * n * 4)
	var sdata := PackedByteArray()                 # (their sides: the copies stacked under the tops)
	sdata.resize(n * n * 4)
	var side: Color = (theme["wall"][3] as Color).darkened(0.3)
	var noise := RandomNumberGenerator.new()
	noise.seed = 99
	# a few knots in the plywood (fixed per board)
	var knots: Array = []
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
				# (the grain runs along the wall: horizontal unless it's a vertical run)
				var vertical := (up[i] == 0 or dn[i] == 0) and lf[i] + rt[i] > 0
				c = TiltMazeArt.wall_px(theme, x, y, m, d_up, d_dn, d_lf, d_rt, vertical)
				c = _lit(c, x, y)
				wdata[k] = c.r8
				wdata[k + 1] = c.g8
				wdata[k + 2] = c.b8
				wdata[k + 3] = 255
				c = _lit(side, x, y)                        # (under it: its side, seen as it rises)
				sdata[k] = c.r8
				sdata[k + 1] = c.g8
				sdata[k + 2] = c.b8
				sdata[k + 3] = 255
			else:
				c = TiltMazeArt.floor_px(theme, x, y, knots)
				# drop shadow of the walls (light from the top-left), two steps
				if _is_wall_px(x - 1, y - 2):
					c = c.darkened(0.2)
				elif _is_wall_px(x - 2, y - 3):
					c = c.darkened(0.09)
				c = _lit(c, x, y)
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
	return [img, Image.create_from_data(n, n, false, Image.FORMAT_RGBA8, wdata), Image.create_from_data(n, n, false, Image.FORMAT_RGBA8, sdata)]

## The world's light over the board (board px; the race games' way: dithered steps, subtle): the
## window's slanting light on the wooden toy, a soft bright corner on the tiles, the gut's lining
## darker at its edges, a shaft of light down the sewer, a lamp's pool in the factory, a nebula's
## glow in a corner of space
func _lit(c: Color, x: int, y: int) -> Color:
	var n := float(BOARD_PX)
	match theme["kind"]:
		"wood":
			var into := clampf(1.0 - absf(x + y * 0.6 - n * 0.45) / (n * 0.24), 0.0, 1.0)
			if into > 0.3 or (into > 0.15 and GameFx.dithered((into - 0.15) / 0.15, x, y)):
				return Color(minf(1.0, c.r * 1.06 + 0.03), minf(1.0, c.g * 1.05 + 0.02), c.b)
			return c.lerp(Color8(90, 70, 70), 0.05)
		"tiles":
			var k := clampf(1.0 - (x + y) / (n * 1.1), 0.0, 1.0)
			if k > 0.45 or (k > 0.35 and GameFx.dithered((k - 0.35) / 0.1, x, y)):
				return c.lightened(0.05)
		"gut":
			var e := Vector2(x, y).distance_to(Vector2(n, n) / 2.0) / (n * 0.5)
			if e > 0.95 or (e > 0.85 and GameFx.dithered((e - 0.85) / 0.1, x, y)):
				return c.darkened(0.08)
		"sewer":
			var shaft := absf(x - n * 0.5 + (y - n * 0.5) * 0.2) / (n * 0.16)
			if shaft < 0.7 or (shaft < 1.0 and GameFx.dithered((1.0 - shaft) / 0.3, x, y)):
				return c.lightened(0.06)
			return c.darkened(0.04)
		"factory":
			var d := Vector2(x, y).distance_to(Vector2(n * 0.5, n * 0.42)) / (n * 0.5)
			if d > 1.0 or (d > 0.88 and GameFx.dithered((d - 0.88) / 0.12, x, y)):
				return c.darkened(0.07)
		"space":
			var g := Vector2(x, y).distance_to(Vector2(n * 0.82, n * 0.2)) / (n * 0.34)
			if g < 0.6 or (g < 1.0 and GameFx.dithered((1.0 - g) / 0.4, x, y)):
				return c.lerp(Color8(150, 90, 200), 0.1)
	return c

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
			_blend(img, x, y, theme["ink"], 0.55)

func _ink_ring(img: Image, center: Vector2, r: float) -> void:
	for y in range(int(center.y - r - 2), int(center.y + r + 3)):
		for x in range(int(center.x - r - 2), int(center.x + r + 3)):
			var d := Vector2(x + 0.5, y + 0.5).distance_to(center)
			if not _is_wall_px(x, y) and absf(d - r) < 0.6:
				_blend(img, x, y, theme["ink"], 0.6)

func _is_wall_px(x: int, y: int) -> bool:
	if x < 0 or y < 0 or x >= BOARD_PX or y >= BOARD_PX:
		return true
	return tiles[(y / TILE_PX) * GRID + (x / TILE_PX)] == 1

# ================================================================== NODES

var bg_rect: ColorRect

func _create_static_nodes() -> void:
	bg_rect = ColorRect.new()
	bg_rect.color = theme["outline"]
	bg_rect.size = Vector2(PLAY_WIDTH, PLAY_HEIGHT)
	add_child(bg_rect)

	scene = Node2D.new()                         # (the board and all on it: it shakes, its walls tilt in 3D)
	add_child(scene)
	board = Sprite2D.new()
	board.centered = false
	board.position = ORIGIN
	board.scale = Vector2(PX, PX)
	board.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	scene.add_child(board)
	current_layer = CurrentLayer.new()
	current_layer.lanes = currents
	scene.add_child(current_layer)

	level_nodes = Node2D.new()
	scene.add_child(level_nodes)

	# The exit: a trapdoor in the floor; it opens once every marble is collected
	exit_node = Node2D.new()
	scene.add_child(exit_node)
	hatch_frame = Sprite2D.new()
	var frame_s := hatch_frame
	frame_s.scale = Vector2(DETAIL, DETAIL)
	frame_s.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	exit_node.add_child(frame_s)
	finish_sprite = Sprite2D.new()
	finish_sprite.texture = _make_swirl_texture()
	finish_sprite.scale = Vector2(DETAIL, DETAIL)
	finish_sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	exit_node.add_child(finish_sprite)
	hatch_l = Sprite2D.new()
	hatch_r = Sprite2D.new()
	for h in [hatch_l, hatch_r]:
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
	scene.add_child(shadow)

	ball = Sprite2D.new()
	ball.texture = ball_texture
	ball.scale = Vector2(BALL_SCALE, BALL_SCALE)
	ball.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	ball.material = _ball_material()
	scene.add_child(ball)
	# the walls, the frame too, standing up off the floor (the 3D tilt): their sides (copies stacked
	# from the floor up, darker the lower), their tops, what's set in them (the magnets); over the
	# ball, so a wall leaning over it hides it a little, as a real one would
	wall_sides.clear()
	for j in WALL_SIDES:
		var sp := Sprite2D.new()
		sp.centered = false
		sp.position = ORIGIN
		sp.scale = Vector2(PX, PX)
		sp.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		sp.modulate = Color(1, 1, 1).darkened(0.3 - 0.3 * float(j) / float(WALL_SIDES))
		scene.add_child(sp)
		wall_sides.append(sp)
	walls = Sprite2D.new()
	walls.centered = false
	walls.position = ORIGIN
	walls.scale = Vector2(PX, PX)
	walls.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	scene.add_child(walls)
	in_walls = Node2D.new()
	scene.add_child(in_walls)
	fx = GameFx.Burst.new()                      # sparks, rings, puffs, confetti
	scene.add_child(fx)
	ambience = GameFx.Ambience.new()             # the world's living light, added on
	var add := CanvasItemMaterial.new()
	add.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	ambience.material = add
	scene.add_child(ambience)

	# The HUD, on the top rail (clear of the frame's edges): the level, the clock / par, the
	# three stars still possible, the coins
	var light := Color(0.98, 0.93, 0.84)
	hud_level = _make_label(Vector2(ORIGIN.x + 22, ORIGIN.y + 2), Vector2(110, 52), 32, HORIZONTAL_ALIGNMENT_LEFT, light)
	hud_time = _make_label(Vector2(ORIGIN.x + 128, ORIGIN.y + 2), Vector2(250, 52), 32, HORIZONTAL_ALIGNMENT_CENTER, light)
	for i in 3:
		var st := TextureRect.new()
		st.texture = UiArt.star(true)
		st.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		st.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		st.size = Vector2(36, 36)
		st.pivot_offset = st.size / 2.0
		st.position = Vector2(ORIGIN.x + 392 + i * 42, ORIGIN.y + 10)
		add_child(st)
		hud_stars.append(st)
	# the lives, between the stars and the marble tray
	build_lives(Vector2(ORIGIN.x + 532, ORIGIN.y + 15), 30.0, 33.0)

	# (the marble tray goes on the rail's right: _build_tray, per level)
	blocker_layer = Node2D.new()
	scene.add_child(blocker_layer)
	scene.move_child(blocker_layer, level_nodes.get_index() + 1)

	banner = GameFx.banner(self, lcd_font, Color8(74, 44, 32), PLAY_HEIGHT / 2.0)

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

func _sprite(tex: Texture2D, pos: Vector2, parent: Node = null) -> Sprite2D:
	var s := Sprite2D.new()
	s.texture = tex
	s.scale = Vector2(DETAIL, DETAIL)
	s.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	s.position = pos
	(parent if parent else level_nodes).add_child(s)
	return s

func _spawn_level_nodes() -> void:
	for n in level_nodes.get_children():
		n.queue_free()
	raised.clear()
	exit_node.position = finish_pos
	# the trapdoor in the world's material (wooden planks, a chrome drain cover, flaps...)
	hatch_frame.texture = TiltMazeArt.hatch_frame(world, HATCH_IN + 4)
	var leaf := TiltMazeArt.hatch_leaf(world, HATCH_IN / 2, HATCH_IN)
	hatch_l.texture = leaf
	hatch_r.texture = leaf
	_set_exit_open(false)
	current_layer.lanes = currents
	current_layer.visible = not currents.is_empty()
	for g in goos:
		_sprite(TiltMazeArt.goo(int(GOO_R / DETAIL)), g)
	for h in holes:
		h["node"] = _sprite(TiltMazeArt.hole(world), h["pos"])
	for n in in_walls.get_children():
		n.queue_free()
	for m in magnets:
		_sprite(TiltMazeArt.magnet(), m, in_walls)
	# the marbles float over the floor, bobbing, their shadows below; the flat ones (a ring, a nut,
	# a star) spin like thick coins (_update_pickups)
	var pick := TiltMazeArt.pickup(world)
	for cp in checkpoints:
		var top := _raise(level_nodes, pick, cp["pos"], PICK_LIFT, 0, 1.0)
		var edge: Array = []
		if world in COIN_WORLDS:
			for j in 2:
				var e := _sprite(pick, cp["pos"])
				e.modulate = Color(1, 1, 1).darkened(0.3 + 0.15 * j)
				level_nodes.move_child(e, (edge[0] as Node).get_index() if j > 0 else top.get_index())   # (under the face, the far one first)
				edge.append(e)
		cp["node"] = top
		cp["raise"] = raised[-1]
		cp["edge"] = edge
	if not vault.is_empty():
		_spawn_vault()
	_spawn_blockers()

## A vault: its gate (the drink's own: fence, cracked wall, channel, shutter; a chest holds the
## prize) with the drink's sign and level, its prize glinting inside
func _spawn_vault() -> void:
	var door: Rect2 = vault["door"]
	var dir: Vector2 = vault["dir"]
	var vertical := dir.x != 0.0
	var long := int((door.size.y if vertical else door.size.x) / DETAIL)
	var kind: String = vault["kind"]
	var gate: Sprite2D = null
	match kind:
		"fizzy":
			gate = _sprite(TiltMazeArt.fence(long, vertical, world, vault["lvl"]), door.get_center())
		"milky":
			gate = _sprite(TiltMazeArt.cracked_wall(long, vertical, world), door.get_center())
		"watery":
			gate = _sprite(TiltMazeArt.channel(long, vertical), door.get_center())
		"caffeinated":
			gate = _sprite(TiltMazeArt.shutter(long, vertical, world), door.get_center())
	if gate:
		vault["fence_node"] = gate
		# (stood up off the floor, solid: a fence, a block of wall, a shutter; the channel is in the floor)
		var hs := {"fizzy": [0.45, 3], "milky": [0.9, 5], "caffeinated": [0.6, 4]}
		if kind in hs:
			gate.queue_free()
			gate = _raise(level_nodes, gate.texture, door.get_center(), hs[kind][0], hs[kind][1])
			vault["fence_node"] = gate
			vault["fence_raise"] = raised[-1]
	if kind != "skill":
		# the sign: which drink opens it, and its level (outside the gate)
		var sign := _raise(level_nodes, TiltMazeArt.sign_card(), door.get_center() + dir * TILE * 0.66, 0.5, 3, 1.0)
		var icon := Sprite2D.new()
		icon.texture = gate_icon(kind, vault["lvl"])
		icon.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		sign.add_child(icon)
		vault["sign_node"] = sign
	if vault["taken"]:
		if kind == "fruity":
			_raise(level_nodes, TiltMazeArt.chest(true), vault["prize_pos"], 0.4, 3, 1.2)      # (opened and emptied)
		return
	var prize := Node2D.new()
	prize.position = vault["prize_pos"]
	var under := _sprite(shadow.texture, prize.position + Vector2(6, 12), level_nodes)
	under.scale = Vector2(DETAIL, DETAIL) * 1.3
	level_nodes.add_child(prize)
	raised.append({"n": prize, "base": prize.position, "h": 0.55, "sides": []})
	var p: String = vault["prize"]
	var art := Sprite2D.new()
	art.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	art.texture = Collection.prize_icon(p)
	if art.texture:
		var big := maxf(art.texture.get_width(), art.texture.get_height())
		art.scale = Vector2.ONE * ((76.0 if p.begins_with("sticker:") else 64.0) / big)
	prize.add_child(art)
	if kind == "fruity":
		# locked in a chest: the prize shows only once it's open
		art.visible = false
		# (the chest stands on the floor, solid; the prize inside floats up out of it)
		var ch := _raise(level_nodes, TiltMazeArt.chest(false), vault["prize_pos"], 0.4, 3)
		vault["chest_node"] = ch
		vault["art_node"] = art
	var bob := art.create_tween().set_loops()       # (dies with the prize)
	bob.tween_property(art, "position:y", -6.0, 0.6).set_trans(Tween.TRANS_SINE)
	bob.tween_property(art, "position:y", 0.0, 0.6).set_trans(Tween.TRANS_SINE)
	for i in 2:
		var tw := Sprite2D.new()
		tw.texture = TiltMazeArt.twinkle()
		tw.scale = Vector2(DETAIL, DETAIL)
		tw.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		tw.position = Vector2(-30, -26) if i == 0 else Vector2(28, 18)
		prize.add_child(tw)
		var tt := tw.create_tween().set_loops()
		tt.tween_property(tw, "modulate:a", 0.0, 0.5).set_delay(0.4 * i)
		tt.tween_property(tw, "modulate:a", 1.0, 0.5)
	vault["node"] = prize

func _special(food_name: String) -> Dictionary:
	for f in FoodLibrary.SPECIALS:
		if f["name"] == food_name:
			return f
	return {}

func _refresh_hud() -> void:
	var tm := "%d:%02d" % [int(level_time) / 60, int(level_time) % 60]
	var pt := "%d:%02d" % [int(par) / 60, int(par) % 60]
	hud_time.text = "%s/%s" % [tm, pt]
	hud_time.add_theme_color_override("font_color", Color(0.98, 0.93, 0.84) if level_time <= par else Color(0.95, 0.55, 0.45))
	var now := _stars_now()
	if now < _stars_shown:
		for i in range(now, _stars_shown):
			var st := hud_stars[i]
			st.texture = UiArt.star(false)
			var t := create_tween()
			t.tween_property(st, "scale", Vector2(1.4, 1.4), 0.08)
			t.tween_property(st, "scale", Vector2.ONE, 0.2)
		_stars_shown = now

## Stars if the level ended now: 1 + within the par time + no fall
func _stars_now() -> int:
	return 1 + (1 if level_time <= par else 0) + (1 if falls == 0 else 0)

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
				col = Color8(74, 44, 32)
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

## Every marble collected: the two hatch doors swing up (seen from above they get
## narrower and darker towards their hinges) and the flush swirl shows underneath.
func _open_exit() -> void:
	exit_open = true
	finish_sprite.visible = true
	hatch_l.visible = true
	hatch_r.visible = true
	_sfx("res://sounds/fx/unlock_ding.wav", -10.0)
	Input.vibrate_handheld(40)
	# it opens: light bursting out of it, a ring across the board, sparkles
	fx.flash(finish_pos, 44.0, Color8(200, 236, 255))
	fx.ring(finish_pos, Color8(170, 220, 255), 30.0, 220.0, 0.5, 8.0)
	fx.sparkle(finish_pos, 14, Color8(220, 244, 255), 1.2)
	_kick(0.15)
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

## The 3D tilt (the user, 2026-10-19: like the iPhone's 3D photos, as in Pal Prix; then: make it
## obvious, the sides too): tilting the phone shows the maze from that side. The walls and the
## frame stand up off the floor, solid (copies stacked from the floor up to their tops, darker
## the lower), and lean away from the way you tilt it, their sides showing; the HUD printed on the
## frame's top rail and the magnets set in the walls go with them; the floor, the ball and all on
## the floor stay still (what you see is where it is), the world's dust and spores drift the walls'
## way, a little more; measured from the pose at the level's start (and MAIN's re-levelling),
## smoothed; off with DEPTH_3D. Px per full tilt (DEPTH_FULL: its sine, ~27 degrees):
const DEPTH_3D := true
const DEPTH_FULL := 0.45
const DEPTH_NEAR := 24.0              # the walls' tops (the frame's, at most, just inside the screen)
const WALL_SIDES := 5                 # the copies under the tops (every DEPTH_NEAR / 6 px)
## The tops held still on the screen (the glass of the box: your eye is on them), the floor and all
## on it sliding under them the other way, the rail's HUD still (the user, 2026-10-19: to try);
## false = the floor still, the tops leaning
const TOPS_FIXED := true
var floor_shift := Vector2.ZERO       # (the board's slide, with TOPS_FIXED; the shake goes on top)
var _depth_tilt := Vector2.ZERO
var qa_depth_tilt := Vector2.ZERO      # (tools/qa depth=x,y: a pretend tilt, the Mac has no sensor)
func _depth_3d() -> void:
	var want := qa_depth_tilt
	if DEPTH_3D and has_tilt_sensor() and state != State.CLEAR:
		want = -device_tilt().limit_length(DEPTH_FULL) / DEPTH_FULL     # (the user: it was inverted; tilt up = see the upper walls)
	_depth_tilt = _depth_tilt.lerp(want, 0.12)
	var up := -_depth_tilt * DEPTH_NEAR
	depth_up = up
	var near := up.round()
	floor_shift = -near if TOPS_FIXED else Vector2.ZERO
	for j in wall_sides.size():
		wall_sides[j].position = ORIGIN + (up * float(j + 1) / float(WALL_SIDES + 1)).round()
	walls.position = ORIGIN + near
	in_walls.position = near
	ambience.position = (up * 1.25).round()
	# what stands on the floor, by its height (its sides stacked under its top, like the walls')
	for r in raised:
		var top: Node2D = r["n"]
		if not is_instance_valid(top):
			continue
		var h: float = r["h"]
		top.position = r["base"] + (up * h).round()
		var sides: Array = r["sides"]
		for j in sides.size():
			var sd: Sprite2D = sides[j]
			sd.position = r["base"] + (up * h * float(j + 1) / float(sides.size() + 1)).round()
			sd.visible = h > 0.0 and top.visible
			sd.texture = (top as Sprite2D).texture
			sd.rotation = top.rotation
			sd.scale = top.scale
			sd.modulate = Color(1, 1, 1).darkened(0.42 - 0.27 * float(j) / float(sides.size())) * top.modulate
	# the rail's HUD (each piece kept where it was made, plus the rail's lift)
	var rail: Array = [hud_level, hud_time]
	rail.append_array(hud_stars)
	rail.append_array(life_hearts)
	rail.append_array(tray)
	for c: Control in rail:
		if not c.has_meta("rail_at"):
			c.set_meta("rail_at", c.position)
		c.position = c.get_meta("rail_at") + near + floor_shift

## Things standing on the floor lean by their height (a wall's top = 1.0): the ball's middle, a
## floating marble, a peg up, the duck, a vault's gate...
const BALL_LIFT := 0.5
const PICK_LIFT := 0.55               # (+- PICK_BOB as it bobs)
const PICK_BOB := 0.12
const PEG_LIFT := 0.55
const COIN_WORLDS := [3, 4, 5]        # the ring, the nut, the star: flat, they spin like coins

## Something standing up off the floor (the 3D tilt): its top leans by its height h, `sides` copies
## of it stacked under the top, darker the lower (solid, like the walls: _depth_3d), and with
## shade > 0 its shadow on the floor (that size). Returns the top.
func _raise(parent: Node, tex: Texture2D, pos: Vector2, h: float, sides := 0, shade := 0.0) -> Sprite2D:
	var sh: Sprite2D = null
	if shade > 0.0:
		sh = _sprite(shadow.texture, pos + Vector2(6, 12) * shade, parent)
		sh.scale = Vector2(DETAIL, DETAIL) * shade
	var side_nodes: Array = []
	for j in sides:
		side_nodes.append(_sprite(tex, pos, parent))
	var top := _sprite(tex, pos, parent)
	raised.append({"n": top, "base": pos, "h": h, "sides": side_nodes, "shadow": sh})
	return top

## The marbles bob over their shadows (the shadow smaller as one rises); a ring, a nut, a star spin
## like thick coins, their edge showing as they turn; taken, the ghost settles on the floor
func _update_pickups(delta: float) -> void:
	pick_t += delta
	for i in checkpoints.size():
		var cp: Dictionary = checkpoints[i]
		if not cp.has("raise"):
			continue
		var r: Dictionary = cp["raise"]
		var top: Sprite2D = cp["node"]
		var sh: Sprite2D = r["shadow"]
		if cp["taken"]:
			r["h"] = move_toward(r["h"], 0.0, delta * 3.0)
			sh.visible = false
			top.scale.x = absf(top.scale.y)
			for e: Sprite2D in cp["edge"]:
				e.visible = false
			continue
		var ph := pick_t * 2.4 + i * 1.3
		r["h"] = PICK_LIFT + PICK_BOB * sin(ph)
		sh.scale = Vector2(DETAIL, DETAIL) * (1.0 - 0.12 * sin(ph))
		var edge: Array = cp["edge"]
		if edge.is_empty():
			continue
		var c := cos(pick_t * 2.8 + i * 0.9)
		var face := 1.0 if c >= 0.0 else -1.0
		top.scale.x = DETAIL * maxf(absf(c), 0.14) * face
		var thick := sqrt(maxf(0.0, 1.0 - c * c))
		for j in edge.size():
			var e: Sprite2D = edge[j]
			e.visible = true
			e.scale = top.scale
			e.position = top.position + Vector2(-face * thick * DETAIL * (j + 1), 0).round()

## The ball's material: its art on a turning sphere, lit from the top-left (tilt_ball.gdshader);
## its back the body's colour, its outline the art's own
func _ball_material() -> ShaderMaterial:
	var m := ShaderMaterial.new()
	m.shader = load("res://scripts/shaders/tilt_ball.gdshader")
	var img := ball_texture.get_image()
	if img.is_compressed():
		img.decompress()
	var art := img.get_width()
	var back := PalBall._main_colour(img, Rect2i(art / 2 - 5, art / 2 + 1, 10, 5))
	var ink := img.get_pixel(art / 2, art / 2 + PalBall.SIZE / 2 - 1)
	if ink.a < 0.5 or ink.get_luminance() > 0.35:
		ink = back.darkened(0.65)
	m.set_shader_parameter("back_col", back)
	m.set_shader_parameter("ink", ink)
	m.set_shader_parameter("art", float(art))
	m.set_shader_parameter("rad", PalBall.SIZE / 2.0)
	return m

## The ball rolls for real (its top going the way it goes, BALL_R round); slow, it turns back
## face up (the pal looking out), its ears and leaves popping back out
func _roll(delta: float) -> void:
	var speed := vel.length()
	if speed > 40.0:
		var axis := Vector3(-vel.y, vel.x, 0.0) / speed
		roll = (Basis(axis, speed * delta / BALL_R) * roll).orthonormalized()
	else:
		roll = roll.slerp(Basis.IDENTITY, minf(1.0, delta * 5.0)).orthonormalized()
	var m := ball.material as ShaderMaterial
	m.set_shader_parameter("roll", roll)
	m.set_shader_parameter("extras", smoothstep(0.9, 0.99, roll.z.z) if speed < 160.0 else 0.0)

## A small shake for a big moment (the HUD stays put)
func _kick(amount: float) -> void:
	shake = maxf(shake, amount)

func _process(delta: float) -> void:
	_depth_3d()
	shake = maxf(0.0, shake - delta * 3.0)
	scene.position = floor_shift + (Vector2(randi_range(-1, 1), randi_range(-1, 1)) * 4.0 * ceilf(shake * 2.0) if shake > 0.0 else Vector2.ZERO)
	if not is_running:
		return
	finish_sprite.rotation -= delta * 2.5
	locked_hint_cd = maxf(0.0, locked_hint_cd - delta)
	fence_hint_cd = maxf(0.0, fence_hint_cd - delta)
	bump_cooldown = maxf(0.0, bump_cooldown - delta)
	hit_t = maxf(0.0, hit_t - delta)
	_move_holes(delta)
	_update_blockers(delta)
	_update_gate(delta)

	if state == State.PLAY:
		level_time += delta
		var tilt := _read_tilt()
		const STEPS := 4
		var dt := delta / STEPS
		for i in STEPS:
			vel += tilt * accel * dt
			_apply_forces(dt)
			var drag := friction + (GOO_DRAG if _in_goo() else 0.0)
			vel *= maxf(0.0, 1.0 - drag * dt)
			vel = vel.limit_length(max_speed)
			ball_pos += vel * dt
			_collide_walls()
			_collide_blockers()
			_collide_gate()
			if state != State.PLAY:
				break
		_roll(delta)
		if state == State.PLAY:
			_check_checkpoints()
			_check_prize()
			_check_finish()
			if hit_t <= HIT_BLINK:
				_check_holes()                  # (in the air after a hit: over the holes)
			_check_hazards()
		_refresh_hud()

	if state == State.PLAY:                 # (falling / hopping / flushed: the tweens move the ball)
		ball.position = ball_pos
		if hit_t > 0.0:
			# the hop back (bigger: up in the air, its shadow left below), then the blink
			var hop := clampf((hit_t - HIT_BLINK) / HIT_HOP, 0.0, 1.0)
			ball.scale = Vector2(BALL_SCALE, BALL_SCALE) * (1.0 + 0.32 * sin(hop * PI))
			ball.modulate.a = 1.0 if hop > 0.0 or int(hit_t * 12.0) % 2 == 0 else 0.3
		elif ball.modulate.a < 1.0 and state == State.PLAY:
			ball.modulate.a = 1.0
	# the ball's middle is up off the floor: it leans with the 3D tilt, its shadow stays below
	var lift := depth_up * BALL_LIFT if state != State.FALLING else Vector2.ZERO
	ball.offset = (lift / ball.scale.x).round() if ball.scale.x > 0.01 else Vector2.ZERO
	shadow.position = ball.position + Vector2(6, 14) * (ball.scale.x / BALL_SCALE)
	shadow.visible = state != State.FALLING
	_update_pickups(delta)

## The Gut: drifting holes go round their little circles
func _move_holes(delta: float) -> void:
	for h in holes:
		if not h["drift"]:
			continue
		h["phase"] += delta * DRIFT_SPEED
		h["pos"] = h["base"] + Vector2(cos(h["phase"]), sin(h["phase"])) * DRIFT_R
		if h.has("node"):
			h["node"].position = (h["pos"] as Vector2).snapped(Vector2(DETAIL, DETAIL))

## The holes' pull, the currents' push, the magnets' pull
func _apply_forces(dt: float) -> void:
	for h in holes:
		var d: Vector2 = h["pos"] - ball_pos
		var l := d.length()
		if l < HOLE_R + 6.0 and l > 0.001:
			vel += d / l * HOLE_PULL * (1.0 - l / (HOLE_R + 6.0)) * dt
	for c in currents:
		if (c["rect"] as Rect2).has_point(ball_pos):
			vel += (c["dir"] as Vector2) * CURRENT_PUSH * dt
	for m in magnets:
		var d2 := m - ball_pos
		var l2 := d2.length()
		if l2 < MAGNET_R and l2 > 0.001:
			vel += d2 / l2 * MAGNET_PULL * (1.0 - l2 / MAGNET_R) * dt

func _in_goo() -> bool:
	for g in goos:
		if ball_pos.distance_to(g) < GOO_R:
			return true
	return false

func _collide_walls() -> void:
	var tx0 := int(floor((ball_pos.x - BALL_R - ORIGIN.x) / TILE))
	var tx1 := int(floor((ball_pos.x + BALL_R - ORIGIN.x) / TILE))
	var ty0 := int(floor((ball_pos.y - BALL_R - ORIGIN.y) / TILE))
	var ty1 := int(floor((ball_pos.y + BALL_R - ORIGIN.y) / TILE))
	for ty in range(ty0, ty1 + 1):
		for tx in range(tx0, tx1 + 1):
			if not _is_wall_tile(tx, ty):
				continue
			_push_out(Rect2(ORIGIN + Vector2(tx, ty) * TILE, Vector2(TILE, TILE)), bounce)

## Pushes the ball out of a rectangle and bounces it; true if they touched
func _push_out(rect: Rect2, b: float) -> bool:
	var closest := ball_pos.clamp(rect.position, rect.end)
	var d := ball_pos - closest
	var dist := d.length()
	if dist >= BALL_R or dist <= 0.0001:
		return false
	var n := d / dist
	ball_pos += n * (BALL_R - dist)
	var vn := vel.dot(n)
	if vn < 0.0:
		vel -= (1.0 + b) * vn * n
		if -vn > 220.0 and bump_cooldown <= 0.0:
			bump_cooldown = 0.12
			if bouncy:
				_sfx("res://sounds/fx/water_boing.wav", clampf(-36.0 + (-vn) / 60.0, -32.0, -20.0), 0.0, randf_range(1.2, 1.4))
			else:
				_sfx("res://sounds/fx/wood_tap.wav", clampf(-34.0 + (-vn) / 50.0, -30.0, -16.0), 0.0, randf_range(0.92, 1.08))
			Input.vibrate_handheld(12)
			# off the wall: a puff of its dust, chips flying back off it; a hard one shakes the board
			var k := clampf((-vn - 220.0) / 400.0, 0.0, 1.0)
			fx.spray(closest, n, int(3 + 5 * k), [Color(1, 1, 1), (theme["wall"][0] as Color).lightened(0.2)], 0.9, 0.5 + 0.5 * k)
			fx.ring(closest, Color(1, 1, 1), 6.0, 26.0 + 30.0 * k, 0.2, 4.0)
			if k > 0.5:
				_kick(0.12 * k)
	return true

## The gate's solid part in the vault's door: a thin bar across it (the fence) or a thicker one
## (the cracked wall, the channel, the shutter)
func _gate_bar() -> Rect2:
	var door: Rect2 = vault["door"]
	var k := 0.32 if vault["kind"] == "fizzy" else 0.26
	if vault["dir"].x != 0.0:
		return door.grow_individual(-door.size.x * k, 0, -door.size.x * k, 0)
	return door.grow_individual(0, -door.size.y * k, 0, -door.size.y * k)

## A vault's gate: solid until the right boost opens it (fence hopped, wall broken, channel
## skimmed, shutter timed); the chest is the prize's own (see _check_prize)
func _collide_gate() -> void:
	if vault.is_empty() or vault["flat"] or vault["kind"] in ["skill", "fruity"]:
		return
	if vault["kind"] == "caffeinated" and _shutter_open():
		return                                         # (open this instant: a way through)
	var hit_speed := vel.length()
	var bar := _gate_bar()
	if not _push_out(bar, BOUNCE):
		return
	var lvl: int = vault["lvl"]
	var kind: String = vault["kind"]
	var ok := gate_open(kind, lvl)
	match kind:
		"fizzy":
			if ok:
				_hop(bar)
			else:
				_gate_hint("A fizzy pal could hop it!" if PetState.boost_power("fizz") == 0 else "A higher fence: a stronger fizzy drink!")
		"milky":
			if ok and hit_speed > 180.0:
				_break_wall()
			elif ok:
				_gate_hint("Ram it harder!")
			else:
				_gate_hint("A sturdy pal could break it!" if PetState.boost_power("sturdy") == 0 else "Too thick: a stronger milky drink!")
		"watery":
			if ok:
				_skim()
			else:
				_gate_hint("Too deep! A splashy pal could skim it." if PetState.boost_power("splash") == 0 else "Too wide: a stronger watery drink!")
		"caffeinated":
			_gate_hint("Wait for it..." if ok else ("Too quick! A focused pal could time it." if PetState.boost_power("focus") == 0 else "Too quick: a stronger energy drink!"))

func _gate_hint(text: String) -> void:
	if fence_hint_cd > 0.0:
		return
	fence_hint_cd = 2.5
	var sign: Node2D = vault.get("sign_node")
	if sign:
		var t := create_tween()
		t.tween_property(sign, "scale", Vector2(DETAIL, DETAIL) * 1.35, 0.1)
		t.tween_property(sign, "scale", Vector2(DETAIL, DETAIL), 0.2)
	_float_text(text, vault["door"].get_center())

## The shutter's clock: it snaps open for an instant every SHUTTER_PERIOD (a focused pal sees it
## open long enough to roll through)
const SHUTTER_PERIOD := 2.6
var _gate_t := 0.0

func _shutter_open() -> bool:
	var window := 1.3 if gate_open("caffeinated", vault.get("lvl", 1)) else 0.14
	return fposmod(_gate_t, SHUTTER_PERIOD) < window

func _update_gate(delta: float) -> void:
	_gate_t += delta
	if vault.is_empty() or vault["kind"] != "caffeinated":
		return
	var f: Sprite2D = vault.get("fence_node")
	if not f:
		return
	var open: bool = vault["flat"] or _shutter_open()
	f.visible = not open
	# a focused pal: the shutter stays open behind it once through (the boost is spent)
	if not vault["flat"] and gate_open("caffeinated", vault["lvl"]) and _cell_of(ball_pos) == vault["cell"]:
		vault["flat"] = true
		PetState.use_boost()
		_sfx("res://sounds/fx/clack.mp3", -10.0, 0.0, 1.3)
		var sign: Node2D = vault.get("sign_node")
		if sign:
			sign.visible = false

## The sturdy ram: the cracked wall crumbles (the boost is spent)
func _break_wall() -> void:
	vault["flat"] = true
	PetState.use_boost()
	_sfx("res://sounds/fx/wood_tap.wav", -6.0, 0.0, 0.6)
	_sfx("res://sounds/fx/clack.mp3", -8.0, 0.0, 0.7)
	Input.vibrate_handheld(60)
	var f: Sprite2D = vault.get("fence_node")
	if f:
		var t := create_tween()
		t.tween_property(f, "modulate", Color(1, 1, 1, 0.0), 0.35)
	_debris(vault["door"].get_center(), TiltMazeArt.THEMES[world]["wall"][1])
	var sign: Node2D = vault.get("sign_node")
	if sign:
		sign.visible = false

## The splashy skim: across the deep channel with a splash (the boost is spent; the water stays)
func _skim() -> void:
	vault["flat"] = true
	PetState.use_boost()
	_sfx("res://sounds/fx/water_boing.wav", -10.0, 0.0, 1.2)
	Input.vibrate_handheld(30)
	_debris(vault["door"].get_center(), Color8(196, 232, 250))
	var sign: Node2D = vault.get("sign_node")
	if sign:
		sign.visible = false

## A burst of crumbs (of wall, drops of water): a puff of them and a few flying off with tails
func _debris(at: Vector2, col: Color) -> void:
	fx.puff(at, 10, col, 0.7)
	fx.sparks(at, 8, [col, col.lightened(0.3), Color(1, 1, 1)], 0.6)

## The fizzy hop: up and over the fence, which falls flat behind; the boost is spent
func _hop(bar: Rect2) -> void:
	state = State.HOP
	PetState.use_boost()
	vault["flat"] = true
	var c := bar.get_center()
	var side := (ball_pos - c)
	var axis := Vector2(signf(side.x), 0) if vault["dir"].x != 0.0 else Vector2(0, signf(side.y))
	var to := c - axis * (BALL_R + 30.0)
	vel = Vector2.ZERO
	_sfx("res://sounds/fx/water_boing.wav", -12.0, 0.0, 1.5)
	Input.vibrate_handheld(30)
	var t := create_tween()
	t.tween_method(func(f: float):
		ball.position = ball_pos.lerp(to, f)
		ball.scale = Vector2.ONE * BALL_SCALE * (1.0 + sin(f * PI) * 0.45), 0.0, 1.0, 0.45)
	t.tween_callback(func():
		ball_pos = to
		ball.scale = Vector2(BALL_SCALE, BALL_SCALE)
		state = State.PLAY
		_sfx("res://sounds/fx/clack.mp3", -14.0))
	var f: Sprite2D = vault.get("fence_node")
	if vault.has("fence_raise"):
		vault["fence_raise"]["h"] = 0.0
	if f:
		var ft := create_tween()
		ft.tween_property(f, "modulate", Color(0.6, 0.55, 0.5, 0.7), 0.3).set_delay(0.25)
	var sign: Node2D = vault.get("sign_node")
	if sign:
		sign.visible = false

func _check_holes() -> void:
	for h in holes:
		if ball_pos.distance_to(h["pos"]) < HOLE_FALL_R:
			_fall_into(h["pos"])
			return

func _check_checkpoints() -> void:
	for cp in checkpoints:
		if cp["taken"] or ball_pos.distance_to(cp["pos"]) > CHECK_R:
			continue
		cp["taken"] = true
		respawn_pos = cp["pos"]
		# each marble a note higher (a little scale), into its slot on the tray
		const SCALE := [1.0, 1.12, 1.26, 1.33, 1.5, 1.68]
		_sfx("res://sounds/fx/gamecoin.wav", -10.0, 0.0, SCALE[mini(marbles_taken, SCALE.size() - 1)])
		_fill_tray_slot(marbles_taken)
		marbles_taken += 1
		Input.vibrate_handheld(20)
		var s: Sprite2D = cp["node"]
		var t := create_tween()
		t.tween_property(s, "scale", Vector2(DETAIL, DETAIL) * 1.6, 0.12)
		t.tween_property(s, "scale", Vector2(DETAIL, DETAIL), 0.15)
		s.texture = TiltMazeArt.pickup(world, true)
		# taken: sparkles off it, a ring of light (bigger as the tray fills)
		fx.sparkle(cp["pos"], 8 + marbles_taken * 2, Color8(255, 236, 160), 0.9)
		fx.ring(cp["pos"], Color8(255, 226, 140), 14.0, 60.0 + marbles_taken * 10.0, 0.3, 6.0)
		if not exit_open and checkpoints.all(func(c): return c["taken"]):
			_open_exit()

## A vault's prize (a sticker, a special food, a dress-up...): taken once; a chest opens for a
## lucky pal only (its boost is spent on it)
func _check_prize() -> void:
	if vault.is_empty() or vault["taken"] or not vault.has("node"):
		return
	if ball_pos.distance_to(vault["prize_pos"]) > PRIZE_R:
		return
	if vault["kind"] == "fruity" and not vault["open"]:
		if not gate_open("fruity", vault["lvl"]):
			_gate_hint("Locked! A lucky pal would find the key." if PetState.boost_power("lucky") == 0 else "A tricky lock: a stronger fruity drink!")
			return
		vault["open"] = true
		PetState.use_boost()
		(vault["chest_node"] as Sprite2D).texture = TiltMazeArt.chest(true)
		(vault["art_node"] as Sprite2D).visible = true
	vault["taken"] = true
	take_secret(level)
	var node: Node2D = vault["node"]
	var art: Node2D = vault.get("art_node", node)
	var t := create_tween()
	t.tween_property(art, "scale", art.scale * 1.6, 0.15)
	t.tween_property(art, "scale", Vector2.ZERO, 0.25).set_ease(Tween.EASE_IN)
	t.tween_callback(art.queue_free)

func _check_finish() -> void:
	if ball_pos.distance_to(finish_pos) > FINISH_R:
		return
	if not exit_open:
		# shut: it's just floor, but say why once in a while
		if locked_hint_cd <= 0.0:
			locked_hint_cd = 2.5
			_float_text("Get all the marbles!", finish_pos)
		return
	state = State.CLEAR
	vel = Vector2.ZERO
	var stars := _stars_now()
	_sfx("res://sounds/fx/water-pouring-98795.mp3", -12.0, 1.4)
	Input.vibrate_handheld(60)
	# flushed: a splash of light out of the swirl, confetti over the board
	fx.ring(finish_pos, Color8(170, 220, 255), 20.0, 140.0, 0.4, 8.0)
	fx.sparkle(finish_pos, 16, Color8(220, 244, 255), 1.3)
	for i in 3:
		fx.confetti(Vector2(ORIGIN.x + 140.0 + i * 310.0, ORIGIN.y + 120.0), 12, [Color8(255, 214, 90), Color8(250, 140, 170), Color8(140, 220, 255), Color(1, 1, 1)])
	# Flushed! Spiral into the swirl, then the result card
	var t := create_tween()
	ball_pos = finish_pos
	t.tween_property(ball, "position", finish_pos, 0.25).set_ease(Tween.EASE_OUT)
	t.parallel().tween_property(ball, "rotation", ball.rotation + TAU * 3.0, 1.0)
	t.parallel().tween_property(ball, "scale", Vector2(0.1, 0.1) * BALL_SCALE, 1.0).set_ease(Tween.EASE_IN)
	t.tween_interval(0.3)
	t.tween_callback(func():
		if is_running:
			finish_level(level, stars, level_time))

## Into a hole: a heart breaks, back on the last marble taken (the clock keeps going, the no-fall
## star is gone); the last heart: the level is over
func _fall_into(h: Vector2) -> void:
	if _splash_save(h):
		return
	state = State.FALLING
	vel = Vector2.ZERO
	falls += 1
	var last := lose_life()
	_sfx("res://sounds/fx/hole_plop.wav", -16.0)
	Input.vibrate_handheld(90)
	# down the hole: a puff of dust round its rim, the board jolts
	fx.dust(h, 12, (theme["floor"][1] as Color).darkened(0.2), 0.9)
	fx.ring(h, Color(0, 0, 0, 0.5), HOLE_R + 4.0, HOLE_R + 40.0, 0.3, 6.0)
	_kick(0.2)
	var t := create_tween()
	t.tween_property(ball, "position", h, 0.12)
	t.tween_property(ball, "scale", Vector2(0.15, 0.15) * BALL_SCALE, 0.45).set_ease(Tween.EASE_IN)
	t.parallel().tween_property(ball, "modulate", Color(0.2, 0.15, 0.1, 1), 0.45)
	t.tween_callback(_out_of_lives if last else _respawn)

# ================================================================== BLOCKERS

## The level's blockers: on the route's doorways (pegs, valves, fire jets), across a corridor (the
## duck), along the route (the rat), on a route cell (meteors); spread out, away from the start,
## the marbles, the finish and the holes. Their clocks are offset per level (the same every time).
func _place_blockers(rng: RandomNumberGenerator, k: int) -> void:
	blockers.clear()
	var n: int = BLOCKERS[k]
	if n == 0:
		return
	var kinds: Array[String] = []
	for i in n:
		kinds.append(BLOCKER_KIND[world])
	if k == GameData.LEVELS_PER_WORLD - 1 and world > 0:
		kinds.append(BLOCKER_KIND[world - 1])            # the finale: the world before's too
	var steps: Array[int] = []
	for i in range(2, path_cells.size() - 2):
		var a: Vector2i = path_cells[i]
		var b: Vector2i = path_cells[i + 1]
		if a == b or (a - b).length_squared() != 1 or _check_cells.has(a) or _check_cells.has(b) or b == _finish_cell:
			continue
		var c := _door_rect(a, b).get_center()
		var clear := true
		for h in holes:
			if (h["pos"] as Vector2).distance_to(c) < TILE * 1.4:
				clear = false
		if not vault.is_empty() and (vault["door"] as Rect2).get_center().distance_to(c) < TILE * 2.0:
			clear = false
		if clear:
			steps.append(i)
	_shuffle(steps, rng)
	var used: Array[int] = []
	for kind in kinds:
		var pick := -1
		for i in steps:
			var ok := true
			for u in used:
				if absi(u - i) < 3:
					ok = false
			if ok:
				pick = i
				break
		if pick < 0:
			break
		used.append(pick)
		var a: Vector2i = path_cells[pick]
		var b: Vector2i = path_cells[pick + 1]
		var door := _door_rect(a, b)
		var dir := Vector2(b - a)
		var bl := { "kind": kind, "door": door, "pos": door.get_center(), "dir": dir, "t": rng.randf() * 3.0, "solid": false, "hot": false }
		match kind:
			"duck":                                     # crosses the corridor of cell b, wall to wall
				var side := Vector2(dir.y, dir.x)
				var c := _cell_center(b)
				bl["a"] = c - side * (TILE - MOVER_R * 0.8)
				bl["b"] = c + side * (TILE - MOVER_R * 0.8)
				bl["pos"] = bl["a"]
			"rat":                                      # runs along the route, up to 2 cells
				var to: Vector2i = b
				if pick + 2 < path_cells.size() and path_cells[pick + 2] - b == b - a and not _check_cells.has(path_cells[pick + 2]):
					to = path_cells[pick + 2]
				bl["a"] = _cell_center(a)
				bl["b"] = _cell_center(to)
				bl["pos"] = bl["a"]
			"meteor":                                   # lands on cell b
				bl["pos"] = _cell_center(b)
		blockers.append(bl)

func _spawn_blockers() -> void:
	for n in blocker_layer.get_children():
		n.queue_free()
	for bl in blockers:
		var node := Node2D.new()
		node.position = bl["pos"]
		blocker_layer.add_child(node)
		bl["node"] = node
		match bl["kind"]:
			"peg":
				bl["sprite"] = _raise(node, TiltMazeArt.peg(false), Vector2.ZERO, 0.0, 4)
				bl["raise"] = raised[-1]
			"duck":
				var sh := _sprite(shadow.texture, Vector2(6, 16), node)
				sh.modulate = Color(1, 1, 1, 0.8)
				bl["sprite"] = _raise(node, TiltMazeArt.duck(), Vector2.ZERO, 0.4)
			"valve":
				var vertical: bool = (bl["dir"] as Vector2).x != 0.0      # the door runs along y
				var lips: Array = []
				for side in [-1.0, 1.0]:
					var lip := _sprite(TiltMazeArt.valve_lip(), Vector2.ZERO, node)
					lip.scale = Vector2(DETAIL * -side, DETAIL)
					lip.rotation = PI / 2.0 if vertical else 0.0
					lips.append(lip)
				bl["lips"] = lips
			"rat":
				var den := _sprite(TiltMazeArt.rat_den(), Vector2.ZERO, blocker_layer)
				den.position = (bl["a"] as Vector2).snapped(Vector2(DETAIL, DETAIL))
				blocker_layer.move_child(den, 0)
				bl["den"] = den
				bl["sprite"] = _raise(node, TiltMazeArt.rat(0), Vector2.ZERO, 0.3)
			"fire":
				_sprite(TiltMazeArt.burner(), Vector2.ZERO, node)
				var f := _raise(node, TiltMazeArt.flame(0, true), Vector2(0, -24), 0.6)
				f.visible = false
				bl["sprite"] = f
			"meteor":
				var ring := _sprite(TiltMazeArt.target_ring(), Vector2.ZERO, node)
				ring.visible = false
				bl["ring"] = ring
				var m := _sprite(TiltMazeArt.meteor(), Vector2.ZERO, node)
				m.visible = false
				bl["sprite"] = m
				var crater := _sprite(TiltMazeArt.hole(world), Vector2.ZERO, node)
				crater.visible = false
				crater.modulate = Color(1, 1, 1, 0.7)
				bl["crater"] = crater

## Each blocker's clock: what it does at this moment (telegraphed before it bites)
const PEG_CYCLE := 3.2                # up for 1.2 s, then down; it wobbles 0.4 s before popping up
const VALVE_CYCLE := 3.0              # closing 0.3, shut 1.2, opening 0.3, open 1.2 (pulses before)
const FIRE_CYCLE := 3.4               # pilot flame 0.6 s (the warning), flame 1.0 s, off
const DUCK_REST := 1.1                # the duck against a wall (the way past it, on its other side)...
const DUCK_CROSS := 1.0               # ...and its waddle across
const DUCK_CYCLE := (DUCK_REST + DUCK_CROSS) * 2.0
const RAT_HIDE := 1.8                 # the rat in its grate between runs
const METEOR_CYCLE := 3.6             # the shadow and the ring 0.9 s, the hit 0.25 s, the crater

func _update_blockers(delta: float) -> void:
	for bl in blockers:
		bl["t"] += delta
		var t: float = bl["t"]
		match bl["kind"]:
			"peg":
				var ph := fposmod(t, PEG_CYCLE)
				var up := ph < 1.2
				bl["solid"] = up
				var sp: Sprite2D = bl["sprite"]
				sp.texture = TiltMazeArt.peg(up)
				bl["raise"]["h"] = PEG_LIFT if up else 0.0
				sp.rotation = sin(t * 40.0) * 0.12 if ph > PEG_CYCLE - 0.4 else 0.0
				sp.scale = Vector2(DETAIL, DETAIL) * (1.12 if up and ph < 0.08 else 1.0)
				if up and ph < delta * 1.5:
					_sfx("res://sounds/fx/wood_tap.wav", -24.0, 0.0, 1.5)
			"duck":
				# rests against one wall, waddles across, rests against the other (room to pass it)
				var ph := fposmod(t, DUCK_CYCLE)
				var f := 0.0
				var going := 0.0
				if ph < DUCK_REST:
					f = 0.0
				elif ph < DUCK_REST + DUCK_CROSS:
					f = smoothstep(0.0, 1.0, (ph - DUCK_REST) / DUCK_CROSS)
					going = 1.0
				elif ph < DUCK_REST * 2.0 + DUCK_CROSS:
					f = 1.0
				else:
					f = 1.0 - smoothstep(0.0, 1.0, (ph - DUCK_REST * 2.0 - DUCK_CROSS) / DUCK_CROSS)
					going = -1.0
				var p: Vector2 = (bl["a"] as Vector2).lerp(bl["b"], f)
				bl["vel"] = ((bl["b"] as Vector2) - (bl["a"] as Vector2)).normalized() * going
				bl["pos"] = p
				bl["node"].position = p.snapped(Vector2(DETAIL, DETAIL))
				var sp_d: Sprite2D = bl["sprite"]
				if going != 0.0:
					sp_d.scale.x = DETAIL * (1.0 if (bl["vel"] as Vector2).dot(Vector2(1, 1)) >= 0.0 else -1.0)
					sp_d.rotation = sin(t * 18.0) * 0.08              # (a waddle)
				else:
					sp_d.rotation = 0.0
			"valve":
				var ph := fposmod(t, VALVE_CYCLE)
				var shut := 0.0                           # 0 = open, 1 = shut
				if ph < 0.3:
					shut = ph / 0.3
				elif ph < 1.5:
					shut = 1.0
				elif ph < 1.8:
					shut = 1.0 - (ph - 1.5) / 0.3
				var pulse := 0.06 * sin(t * 20.0) if ph > VALVE_CYCLE - 0.4 else 0.0
				bl["solid"] = shut > 0.6
				var door: Rect2 = bl["door"]
				var vertical: bool = (bl["dir"] as Vector2).x != 0.0
				var half := (door.size.y if vertical else door.size.x) / 2.0
				var lips: Array = bl["lips"]
				for i in 2:
					var side := -1.0 if i == 0 else 1.0
					var off := side * (half - 4.0 * DETAIL * (shut + pulse) - 2.0 * DETAIL)
					(lips[i] as Sprite2D).position = (Vector2(0, off) if vertical else Vector2(off, 0)).snapped(Vector2(DETAIL, DETAIL))
			"rat":
				# in its grate a while (its eyes in the dark before it pops out), out up the route,
				# a sniff at the end, back and in again
				var a: Vector2 = bl["a"]
				var b: Vector2 = bl["b"]
				var run := a.distance_to(b)
				var leg := run / 170.0                   # seconds a way
				var cyc := fposmod(t, RAT_HIDE + (leg + 0.4) * 2.0)
				var f := 0.0
				var dir_sign := 1.0
				var out := cyc >= RAT_HIDE
				var c2 := cyc - RAT_HIDE
				if not out:
					f = 0.0
				elif c2 < leg:
					f = c2 / leg
				elif c2 < leg + 0.4:
					f = 1.0                              # (a sniff at the end)
				else:
					f = 1.0 - (c2 - leg - 0.4) / leg
					dir_sign = -1.0
				var p := a.lerp(b, clampf(f, 0.0, 1.0))
				bl["vel"] = (b - a).normalized() * 170.0 * dir_sign if (out and f > 0.0 and f < 1.0) else Vector2.ZERO
				bl["pos"] = p
				bl["out"] = out
				bl["node"].position = p.snapped(Vector2(DETAIL, DETAIL))
				var sp: Sprite2D = bl["sprite"]
				sp.texture = TiltMazeArt.rat(int(t * 8.0) % 2)
				var face := (b - a) * dir_sign
				sp.rotation = snappedf(face.angle(), PI / 2.0)
				sp.visible = out or cyc > RAT_HIDE - 0.5
				sp.modulate = Color(1, 1, 1, 1) if out else Color(0.2, 0.2, 0.25, 0.85)   # (in the dark of its grate)
			"fire":
				var ph := fposmod(t, FIRE_CYCLE)
				var sp: Sprite2D = bl["sprite"]
				var frame := int(t * 10.0) % 2
				if ph < 0.6:
					sp.visible = true
					sp.texture = TiltMazeArt.flame(frame, true)
					bl["hot"] = false
				elif ph < 1.6:
					sp.visible = true
					sp.texture = TiltMazeArt.flame(frame, false)
					bl["hot"] = true
					if ph - delta < 0.6:
						_sfx("res://sounds/fx/water-pouring-98795.mp3", -26.0, 0.35, 0.5)
				else:
					sp.visible = false
					bl["hot"] = false
			"meteor":
				var ph := fposmod(t, METEOR_CYCLE)
				var ring: Sprite2D = bl["ring"]
				var m: Sprite2D = bl["sprite"]
				var crater: Sprite2D = bl["crater"]
				ring.visible = ph < 0.9
				ring.modulate.a = 0.5 + 0.5 * sin(t * 14.0)
				ring.scale = Vector2(DETAIL, DETAIL) * (0.7 + 0.3 * minf(1.0, ph / 0.9))
				m.visible = ph > 0.55 and ph < 0.95
				if m.visible:
					var f := (ph - 0.55) / 0.4
					m.position = (Vector2(220, -260) * (1.0 - f)).snapped(Vector2(DETAIL, DETAIL))
				bl["hot"] = ph >= 0.9 and ph < 1.15
				crater.visible = ph >= 0.9 and ph < 1.9
				if ph >= 0.9 and ph - delta < 0.9:
					_sfx("res://sounds/fx/hole_plop.wav", -14.0, 0.0, 0.6)
					Input.vibrate_handheld(20)

## The solid ones push the ball (pegs up, valves shut, the duck, the rat); the moving ones shove it
func _collide_blockers() -> void:
	for bl in blockers:
		if not bl["solid"]:
			continue
		match bl["kind"]:
			"peg":
				_push_out_circle(bl["pos"], PEG_R, BOUNCE)
			"valve":
				var door: Rect2 = bl["door"]
				var k := 0.3
				var bar := door.grow_individual(-door.size.x * k, 0, -door.size.x * k, 0) if (bl["dir"] as Vector2).x != 0.0 else door.grow_individual(0, -door.size.y * k, 0, -door.size.y * k)
				_push_out(bar, BOUNCE * 1.6)

## The enemies: the duck and the rat (when it's out of its grate) touched, a flame or a meteor at
## its moment: a hit (_hit)
func _check_hazards() -> void:
	if hit_t > 0.0:
		return
	for bl in blockers:
		match bl["kind"]:
			"duck", "rat":
				if bl.get("out", true) and ball_pos.distance_to(bl["pos"]) < MOVER_R * 0.75 + BALL_R * 0.7:
					_hit(bl["pos"])
					return
			"fire", "meteor":
				if bl["hot"] and ball_pos.distance_to(bl["pos"]) < (PEG_R if bl["kind"] == "fire" else METEOR_R) + BALL_R * 0.4:
					_hit(bl["pos"])
					return

## An enemy's hit: the ball is knocked back and hops (over any hole), blinks a moment (nothing hurts
## it meanwhile, so it can get past) and a heart breaks (a splashy pal's water heart first); the no-
## fall star is gone; the last heart: the level is over
func _hit(from: Vector2) -> void:
	var away := ball_pos - from
	if away.length() < 1.0:
		away = -vel if vel.length() > 1.0 else Vector2.UP
	vel = away.normalized() * KNOCK
	hit_t = HIT_HOP + HIT_BLINK
	_sfx("res://sounds/fx/water_boing.wav", -10.0, 0.0, 0.8)
	Input.vibrate_handheld(70)
	_debris(ball_pos, Color8(250, 226, 160))
	# the hit: sparks off it, a ring of light, the board shakes
	fx.sparks(ball_pos, 12, [Color(1, 1, 1), Color8(255, 214, 90), Color8(255, 120, 90)], 1.0)
	fx.ring(ball_pos, Color8(255, 150, 110), 16.0, 90.0, 0.3, 6.0)
	_kick(0.3)
	if not splash_used and PetState.boost_power("splash") > 0:
		splash_used = true
		PetState.use_boost()
		spend_water_heart()
		_float_text("Splash!", ball_pos)
		return
	falls += 1
	if lose_life():
		state = State.FALLING
		vel = Vector2.ZERO
		get_tree().create_timer(0.4).timeout.connect(_out_of_lives)

## Pushes the ball out of a circle (a peg, the duck...); true if they touched
func _push_out_circle(c: Vector2, r: float, b: float) -> bool:
	var d := ball_pos - c
	var dist := d.length()
	if dist >= BALL_R + r or dist <= 0.0001:
		return false
	var n := d / dist
	ball_pos += n * (BALL_R + r - dist)
	var vn := vel.dot(n)
	if vn < 0.0:
		vel -= (1.0 + b) * vn * n
		if -vn > 220.0 and bump_cooldown <= 0.0:
			bump_cooldown = 0.12
			_sfx("res://sounds/fx/wood_tap.wav", clampf(-34.0 + (-vn) / 50.0, -30.0, -16.0), 0.0, randf_range(0.92, 1.08))
			Input.vibrate_handheld(12)
	return true

## A splashy pal's one bounce back out of a fall (a hole, a fire jet, a meteor): no fall counted,
## the boost is spent. True if it saved the pal.
func _splash_save(at: Vector2) -> bool:
	if splash_used or PetState.boost_power("splash") <= 0:
		return false
	splash_used = true
	PetState.use_boost()
	spend_water_heart()
	var away := (ball_pos - at)
	if away.length() < 1.0:
		away = -vel if vel.length() > 1.0 else Vector2.UP
	ball_pos = at + away.normalized() * (HOLE_R + BALL_R + 6.0)
	vel = away.normalized() * 260.0
	_sfx("res://sounds/fx/water_boing.wav", -8.0, 0.0, 1.0)
	Input.vibrate_handheld(40)
	_debris(at, Color8(150, 210, 250))
	fx.ring(at, Color8(110, 200, 255), 20.0, 120.0, 0.4, 8.0)
	_float_text("Splash!", at)
	return true

## The last heart broke: the level is over (its result card: Out of lives!, retry from the start)
func _out_of_lives() -> void:
	_show_banner("Out of lives!", 0.9)
	_sfx("res://sounds/fx/error.mp3", -10.0)
	get_tree().create_timer(1.3).timeout.connect(func():
		if is_running:
			finish_level(level, 0, level_time))

func fail_title() -> String:
	return "Out of lives!"

## Back on the last marble taken, blinking
func _respawn() -> void:
	ball_pos = respawn_pos
	roll = Basis.IDENTITY
	ball.position = ball_pos
	ball.scale = Vector2(BALL_SCALE, BALL_SCALE)
	ball.modulate = Color(1, 1, 1, 1)
	vel = Vector2.ZERO
	state = State.PLAY
	var blink := create_tween()
	for i in 4:
		blink.tween_property(ball, "modulate:a", 0.2, 0.08)
		blink.tween_property(ball, "modulate:a", 1.0, 0.08)

# ================================================================== THE MARBLE TRAY

## The HUD's tray, on the rail's right: an empty socket per marble of the level
func _build_tray() -> void:
	for t in tray:
		t.queue_free()
	tray.clear()
	var n := checkpoints.size()
	var step := 40.0
	var right := ORIGIN.x + BOARD_PX * PX - 26.0
	for i in n:
		var r := TextureRect.new()
		r.texture = TiltMazeArt.socket()
		r.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		r.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		r.size = Vector2(36, 36)
		r.pivot_offset = r.size / 2.0
		r.position = Vector2(right - (n - i) * step, ORIGIN.y + 9)
		add_child(r)
		tray.append(r)

## A marble lands in its slot (a little pop)
func _fill_tray_slot(i: int) -> void:
	if i >= tray.size():
		return
	var r := tray[i]
	r.texture = TiltMazeArt.pickup(world)
	var t := create_tween()
	t.tween_property(r, "scale", Vector2(1.5, 1.5), 0.08)
	t.tween_property(r, "scale", Vector2.ONE, 0.2).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

# ================================================================== INPUT

func _has_tilt_sensor() -> bool:
	return has_tilt_sensor()

func _sensor_tilt() -> Vector2:
	var v := device_tilt()                       # (measured from the pose at the round's start)
	return -v if INVERT_TILT else v

func _read_tilt() -> Vector2:
	if qa_autopilot and not path_cells.is_empty():
		# (QA only: towards the next cell of the route, gently)
		var best := _qa_step
		for i in range(maxi(0, _qa_step - 2), mini(path_cells.size(), _qa_step + 4)):
			if _cell_center(path_cells[i]).distance_to(ball_pos) < _cell_center(path_cells[best]).distance_to(ball_pos):
				best = i
		_qa_step = best
		var target := _cell_center(path_cells[mini(best + 1, path_cells.size() - 1)])
		var want := (target - ball_pos).limit_length(120.0) / 120.0 * 0.55
		return (want - vel / 900.0).limit_length(1.0)
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
	if is_game_over or level_menu_open():
		super.on_main_button_pressed()
		return
	# Current phone angle becomes "flat"
	calibrate_tilt()
	_show_banner("Calibrated", 0.7)

func on_main_button_released() -> void:
	if level_menu_open():
		super.on_main_button_released()

func on_forward_button_pressed() -> void:
	if is_game_over or level_menu_open():
		super.on_forward_button_pressed()

func end_game() -> void:
	state = State.FALLING
	banner.visible = false
	super.end_game()

# ================================================================== FX HELPERS

func _show_banner(text: String, hold: float) -> void:
	GameFx.show_banner(banner, text, hold)

func _float_text(text: String, at: Vector2) -> void:
	var lx := clampf(at.x - 200, 30, PLAY_WIDTH - 430)          # (kept inside the board)
	var l := _make_label(Vector2(lx, at.y - 60), Vector2(400, 40), 28, HORIZONTAL_ALIGNMENT_CENTER, Color(1, 0.95, 0.85))
	l.add_theme_color_override("font_outline_color", Color8(74, 44, 32))
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
