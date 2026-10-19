extends BaseMinigame
## Pal Prix 2177, the Turbo League: the final game, a reward. Winning Pal Prix's Grand Prix (6-9)
## invites the pal to the next league, where its toy is turbo-charged and TRANSFORMS: one craft
## that is a hover car on land, a jet ski on the water and a rocket in the air. Each change
## happens at a gate on the course: the craft spins and unfolds in a puff (the hover pods fold
## away, the hull or the wings come out), a slow-motion beat, a burst of speed, and the view
## pulls back out. Nothing new to learn (each form drives like one of Pal Prix's toys, the same
## two buttons: hold ORANGE to turn left, FORWARD to turn right); the new skill is switching.
##
## FASTER, NOT HARDER (the user, 2026-10-19): wide roads and long bends taken flat out (the
## craft turns on the same circle at any speed), a view that pulls back the faster it goes
## (speed lines, light trails, stars streaking, a shake on a boost), forgiving edges (the walls
## on land are magnetic: you stick to them and slow down), boost chains on a
## good line (plates on the road, currents on the water, rings in the air: each one taken
## straight after the last adds to the chain), a slipstream behind a rival (then a slingshot
## past it), a drift boost (hold a turn through a long bend: sparks, blue, orange, pink; let go:
## a burst). Hearts (the user, 2026-10-19): on the
## land the walls are magnetic, but on the water it's Pal Prix's boat (buoys you push, shallows
## that slow you, the bank past them a crash) and in the air leaving the lane is a crash: a heart,
## back on the last checkpoint; the last one: out of lives.
## Stars: 1 = the 3 laps, 2 = within the par time (with rivals: 1st), 3 = within the turbo time
## (the boosts' time; with rivals: 1st within it). Things in the way (rocks, icebergs, asteroids)
## only bump and spin you: they cost time.
##
## Six worlds of 9 levels, building up the switches (the user's note): 1 Neon City (land + sea:
## splash into the harbour, drive out up a slipway; boost chains, jumps over the gaps between
## the roofs) · 2 Rapids (sea + air: fly off the falls; waterfall steps to jump, rocks) · 3 Canyon
## (land + air: off the cliffs; boost rings, canyon winds) · 4 Ice Fjord (all three in one lap;
## icy roads, icebergs) · 5 Asteroid Belt (all three with rivals; asteroids, gravity wells) ·
## 6 Saturn's Rings (the final: Earth to space and back; slingshots round the moons).
## The ground is painted by shaders (scripts/shaders/pal_prix_2_board / _deep) from the course
## (PalPrix2Course), the craft and the pieces are PalPrix2Art's, the moving things PalPrix2Fx's.
## Desktop: Left / Right arrows (or A / D).

const GAME_INDEX := 11
const PX := 4
const STEP := 8.0
const LAPS := 3
const COUNTDOWN := 3
const VIEW := Rect2(27, 92, 896, 830)
## The ground's shaders cover the whole play area (the user, 2026-10-19: some stages left a black
## frame round the race, effects drawn past it), the camera still centred on VIEW
const FULL := Rect2(0, 0, 950, 948)
const HUD_BAND := Rect2(27, 26, 896, 66)

const LAND := 0
const SEA := 1
const AIR := 2
const FORM_NAMES := ["hover", "jetski", "rocket"]
## Per form (LAND / SEA / AIR): its speed (mat px/s), the circle it turns on at any speed (mat px),
## how fast its way takes up its heading (/s: the jet ski drifts)
const SPEED := [820.0, 760.0, 900.0]
const TURN_R := [205.0, 200.0, 215.0]
const GRIP := [10.0, 8.0, 9.0]
const ICE_GRIP := 2.6                  # (the Ice Fjord's icy roads)
const ACCEL := 950.0                   # speeding up, mat px/s^2
const BRAKE := 1700.0                  # slowing to a lower speed
const LAYER_UP := 2.5                  # each slice this much higher (mat px)
const AIR_H := 48.0                    # the rocket's height over the drop (mat px)
const CRAFT_R := 30.0                  # its size against things in the way
const WALL_IN := 30.0                  # its middle meets a wall this far in from the edge
const WALL_DRAG := 1.5                 # against a wall: slowed this fast
const BOOST_MAX := 0.8                 # the most extra speed (x its speed)
const BOOST_FADE := 0.42               # a boost fades this much a second
const PAD_BOOST := 0.4                 # a plate / a current / a ring...
const CHAIN_STEP := 0.07               # ...and each link of a chain before it
const GATE_BOOST := 0.3                # a transform's burst...
const PERFECT_BOOST := 0.5             # ...through its middle, straight
const HOP_BOOST := 0.3                 # landing a jump straight
const DRIFT_STEPS := [1.2, 2.6, 4.0]   # turned this far holding one button (rad): drift levels 1-3
const DRIFT_BOOST := [0.22, 0.36, 0.5]
const DRIFT_COLS := [Color8(110, 200, 255), Color8(255, 170, 60), Color8(255, 100, 220)]
const SLIP_NEED := 0.6                 # behind a rival this long: its slipstream...
const SLIP_BOOST := 0.32               # ...and the slingshot when you pull out
const TF_TIME := 0.6                   # a transform (game s)...
const TF_SLOW_REAL := 0.32             # ...slowed down this long (real s)...
const TF_SLOW := 0.3                   # ...to this speed
const HOP_TIME := 0.55                 # a jump off a ramp / a waterfall step
const GAP_PTS := 14                    # a jump's gap (points)
const RAMP_PTS := 9                    # the ramp before it
const PAD_HALF := 8                    # a plate's half length (points)
const Z_START := 1.5                   # the view: close at the start...
const Z_NEAR := 1.36                   # ...pulling back with the speed...
const Z_FAR := 1.0                     # ...to this at a big boost
const GUST_PUSH := 240.0
## Water: Pal Prix's boat rules (the user, 2026-10-19): the buoys only mark the lane, the shallows
## past them slow it (its hull SHALLOW_IN inside the buoys), SHORE_AT past them it runs onto the
## bank (painted SHORE_PAINT past them): a crash, a heart. Air: past the lane's edge (AIR_OUT) it
## falls out of the race: a heart. The land keeps its magnetic walls.
const SHALLOW_IN := 10.0
const SHALLOW_SLOW := 0.7
const SHORE_AT := 56.0                # (bank painted 72 past the buoys: the bow reaches it)
const AIR_EDGE := 1.7                 # the air lane's edge: this x its half width from its middle
const AIR_OUT := 10.0
const CHECKPOINTS := 10               # per lap: where a crashed craft is put back
const WELL_PULL := 420.0
const PAR_SLACK := 1.05
const PAR_PLUS := 1.0
const TURBO_K := 0.93                 # the turbo time: the clean drive's time x this (boosts needed)
const ICE_SLACK := 1.07                # (icy roads: the par a little longer, the craft slides)

const WORLDS := ["Neon City", "Rapids", "Canyon", "Ice Fjord", "Asteroid Belt", "Saturn's Rings"]
## Each world's kinds, in lap order (the start's first), and their share of the lap
const PLANS := [["land", "sea"], ["sea", "air"], ["land", "air"], ["land", "sea", "air"], ["land", "sea", "air"], ["land", "sea", "air"]]
const WEIGHTS := [{}, {}, {}, {}, { "sea": 0.8 }, { "air": 2.2 }]
const CELLS := [560.0, 600.0, 600.0, 600.0, 600.0, 620.0]
## Round each stretch (mat px from the course's middle): the water round a sea stretch, the drop
## round a flight, the rock round a land stretch (space; Saturn's Rings: the Earth)
const REGIONS := [
	{ "sea": 520.0 }, { "sea": 250.0, "air": 290.0 }, { "air": 300.0 }, { "sea": 320.0, "air": 280.0 },
	{ "land": 280.0, "sea": 250.0 }, { "land": 1100.0, "sea": 430.0, "air": 300.0 },
]
const FACE_H := [0.0, 26.0, 32.0, 28.0, 16.0, 0.0]          # a cliff's height (board px)
const PARALLAX := [0.5, 0.55, 0.5, 0.55, 0.35, 0.45]       # how fast the deep layer moves
const WORLD_BACKDROPS := [Color8(84, 60, 130), Color8(70, 170, 160), Color8(220, 120, 80), Color8(100, 150, 210), Color8(60, 40, 100), Color8(40, 60, 120)]
const ACCENTS := [Color8(65, 227, 255), Color8(120, 255, 170), Color8(255, 160, 60), Color8(160, 236, 255), Color8(255, 90, 220), Color8(255, 224, 102)]
const WORLD_HINTS := ["splash in, roll out!", "fly off the falls!", "off the cliffs!", "land, sea and air!", "slipstream them!", "to space and back!"]
const LATER_HINTS := [["boost chains!", "jump the gaps!"], ["waterfall jumps!", "rocks ahead!"], ["boost rings!", "canyon winds!"],
	["ice! it slides", "icebergs!"], ["asteroids!", "gravity wells!"], ["slingshot the moons!", "the final!"]]

const OVAL := [Rect2i(0, 0, 6, 2)]
const ELL := [Rect2i(0, 0, 6, 2), Rect2i(0, 2, 2, 2)]
const YOU := [Rect2i(0, 0, 6, 2), Rect2i(0, 2, 2, 2), Rect2i(4, 2, 2, 2)]
## The courses, 9 per world: [grid columns, rows, squares in the patch, road half-width (mat px),
## a fixed shape or null, corners wanted, boost plates (currents / rings), extras]. extras:
## "gates" (a lap's transforms), "jumps" (gaps between roofs), "steps" (waterfall drops on a
## river), "rocks", "bergs" (icebergs), "asteroids", "wells" (gravity), "slings" (moons to swing
## round), "gusts", "ice", "rivals"
const LEVELS := [
	# 1 Neon City (land + sea): boost chains from the 4th, jumps over the roofs' gaps from the 7th
	[6, 2, 0, 150.0, OVAL, 0, 0, { "gates": 2 }],
	[6, 4, 0, 150.0, ELL, 0, 0, { "gates": 2 }],
	[6, 4, 0, 148.0, YOU, 0, 1, { "gates": 2 }],
	[8, 4, 14, 146.0, null, 10, 3, { "gates": 2 }],
	[8, 5, 16, 144.0, null, 12, 3, { "gates": 4 }],
	[9, 5, 18, 142.0, null, 14, 3, { "gates": 2 }],
	[9, 5, 18, 142.0, null, 14, 2, { "gates": 2, "jumps": 1 }],
	[9, 6, 21, 140.0, null, 16, 3, { "gates": 4, "jumps": 2 }],
	[10, 6, 24, 140.0, null, 18, 4, { "gates": 4, "jumps": 2 }],
	# 2 Rapids (sea + air): waterfall steps from the 4th, rocks from the 7th
	[6, 2, 0, 150.0, OVAL, 0, 0, { "gates": 2 }],
	[6, 4, 0, 150.0, ELL, 0, 0, { "gates": 2 }],
	[6, 4, 0, 148.0, YOU, 0, 1, { "gates": 2 }],
	[8, 4, 14, 146.0, null, 10, 2, { "gates": 2, "steps": 1 }],
	[8, 5, 16, 144.0, null, 12, 2, { "gates": 2, "steps": 2 }],
	[9, 5, 18, 142.0, null, 14, 2, { "gates": 2, "steps": 1 }],
	[9, 5, 18, 142.0, null, 14, 2, { "gates": 2, "steps": 1, "rocks": 2 }],
	[9, 6, 21, 140.0, null, 16, 3, { "gates": 4, "steps": 2, "rocks": 3 }],
	[10, 6, 24, 140.0, null, 18, 3, { "gates": 4, "steps": 2, "rocks": 3 }],
	# 3 Canyon (land + air): boost rings from the 4th, canyon winds from the 7th
	[6, 2, 0, 150.0, OVAL, 0, 0, { "gates": 2 }],
	[6, 4, 0, 150.0, ELL, 0, 0, { "gates": 2 }],
	[6, 4, 0, 148.0, YOU, 0, 1, { "gates": 2 }],
	[8, 4, 14, 146.0, null, 10, 3, { "gates": 2 }],
	[8, 5, 16, 144.0, null, 12, 3, { "gates": 4 }],
	[9, 5, 18, 142.0, null, 14, 3, { "gates": 2 }],
	[9, 5, 18, 142.0, null, 14, 3, { "gates": 2, "gusts": 1 }],
	[9, 6, 21, 140.0, null, 16, 4, { "gates": 4, "gusts": 2 }],
	[10, 6, 24, 140.0, null, 18, 4, { "gates": 4, "gusts": 2, "jumps": 1 }],
	# 4 Ice Fjord (all three in a lap): icy roads from the 4th, icebergs from the 7th
	[8, 4, 14, 150.0, null, 10, 0, { "gates": 3 }],
	[8, 5, 16, 148.0, null, 12, 1, { "gates": 3 }],
	[9, 5, 18, 146.0, null, 14, 2, { "gates": 3 }],
	[9, 5, 18, 146.0, null, 14, 2, { "gates": 3, "ice": true }],
	[9, 6, 21, 144.0, null, 16, 3, { "gates": 3, "ice": true }],
	[9, 6, 21, 144.0, null, 16, 3, { "gates": 3, "ice": true }],
	[10, 6, 24, 142.0, null, 18, 3, { "gates": 3, "ice": true, "bergs": 2 }],
	[10, 6, 24, 142.0, null, 18, 3, { "gates": 6, "ice": true, "bergs": 3 }],
	[10, 7, 27, 140.0, null, 20, 4, { "gates": 6, "ice": true, "bergs": 3, "jumps": 1 }],
	# 5 Asteroid Belt (all three with rivals): asteroids from the 4th, gravity wells from the 7th
	[8, 4, 14, 150.0, null, 10, 1, { "gates": 3, "rivals": 1 }],
	[8, 5, 16, 148.0, null, 12, 2, { "gates": 3, "rivals": 1 }],
	[9, 5, 18, 146.0, null, 14, 2, { "gates": 3, "rivals": 2 }],
	[9, 5, 18, 146.0, null, 14, 2, { "gates": 3, "rivals": 2, "asteroids": 3 }],
	[9, 6, 21, 144.0, null, 16, 3, { "gates": 3, "rivals": 2, "asteroids": 4 }],
	[9, 6, 21, 144.0, null, 16, 3, { "gates": 3, "rivals": 2, "asteroids": 3 }],
	[10, 6, 24, 142.0, null, 18, 3, { "gates": 3, "rivals": 3, "asteroids": 3, "wells": 1 }],
	[10, 6, 24, 142.0, null, 18, 3, { "gates": 6, "rivals": 3, "asteroids": 4, "wells": 2 }],
	[10, 7, 27, 140.0, null, 20, 4, { "gates": 6, "rivals": 3, "asteroids": 5, "wells": 2 }],
	# 6 Saturn's Rings (Earth to space and back): slingshots from the 4th, everything from the 7th
	[9, 5, 18, 150.0, null, 14, 2, { "gates": 3, "rivals": 1 }],
	[9, 5, 18, 148.0, null, 14, 2, { "gates": 3, "rivals": 2 }],
	[9, 6, 21, 146.0, null, 16, 2, { "gates": 3, "rivals": 2, "wells": 1 }],
	[9, 6, 21, 146.0, null, 16, 2, { "gates": 3, "rivals": 2, "slings": 1 }],
	[10, 6, 24, 144.0, null, 18, 2, { "gates": 3, "rivals": 3, "slings": 2, "asteroids": 2 }],
	[10, 6, 24, 144.0, null, 18, 2, { "gates": 3, "rivals": 3, "slings": 1, "wells": 1 }],
	[10, 7, 27, 142.0, null, 20, 3, { "gates": 3, "rivals": 3, "slings": 2, "wells": 2, "asteroids": 3 }],
	[10, 7, 27, 142.0, null, 20, 3, { "gates": 3, "rivals": 3, "slings": 2, "wells": 2, "asteroids": 4 }],
	[11, 7, 30, 140.0, null, 22, 4, { "gates": 3, "rivals": 3, "slings": 3, "wells": 2, "asteroids": 5 }],
]
## Secrets (a world's 6th level, from world 2): a gift up over a waterfall step (a fizzy jet ski
## jumps to it), crates across the road with the gift behind (a sturdy craft rams through), a gift
## only a lucky craft sees. The cosmic foods in the space worlds (the user's note).
const SECRETS := {
	15: ["fizzy", "sticker:pal"], 24: ["milky", "coins:15"], 33: ["fruity", "sticker:pal"],
	42: ["milky", "food:Moon Rock"], 51: ["fruity", "food:Stardust Sugar"],
}
const FINALES := { 45: "coins:30", 54: "coins:60" }
## The rivals' tiers (Pal Prix's): pace (x the form's speed), braking in the bends, wandering,
## mistakes (a moment slow, every this many s; 0 never), the green light, steering round things
const RIVAL_TIERS := [
	{ "speed": 0.88, "corner": 0.4, "wander": 0.22, "slip_every": 9.0, "react": 0.5, "dodge": 0.55 },
	{ "speed": 0.94, "corner": 0.25, "wander": 0.13, "slip_every": 15.0, "react": 0.3, "dodge": 0.8 },
	{ "speed": 0.99, "corner": 0.1, "wander": 0.05, "slip_every": 0.0, "react": 0.12, "dodge": 0.97 },
]
const RIVAL_COLS := ["blue", "yellow", "green"]

enum State { WAIT, DRIVE, FALL, DONE }

var state := State.WAIT
var level := 1
var world_no := 0
var extras := {}
var course: PalPrix2Course
var form := LAND                       # the craft's form now (its kind)
var car_pos := Vector2.ZERO            # mat px
var heading := 0.0
var vel := Vector2.ZERO
var speed := 0.0
var near := 0                          # the nearest point of the course
var progress := 0.0                    # points passed (laps x count)
var lap := 1
var race_time := 0.0
var countdown := 0.0
var boost := 0.0                       # extra speed now (x its speed), fading
var chain := 0                         # boosts taken in a row
var drift_ang := 0.0                   # turned this far holding one button
var drift_dir := 0.0
var drift_level := 0
var wall_t := 0.0                      # touching a wall (fading)
var bump_t := 0.0                      # just hit something (fading): slowed
var spin_t := 0.0                      # ...spinning round
var slip_charge := 0.0                 # behind a rival this long
var last_cp := 0.0                     # progress at the last checkpoint passed
var falls := 0                         # crashes this race (hearts lost)
var splash_used := false               # (a splashy pal's water heart: its first crash undone)
var _grace_t := 0.0                    # (just put back: nothing crashes it for a moment)
var hop_t := 0.0                       # in the air off a ramp / a step: time left
var hop_len := 0.0
var hop_good := false
var car_h := 0.0                       # its height over the ground (mat px)
var tf_t := 0.0                        # a transform: time left
var tf_from := LAND
var tf_to := LAND
var slow_t := 0.0                      # the slow-motion beat left (real s)
var bank := 0.0                        # the rocket's lean in the turns
var place := 1
var bumps := 0
var par := 30.0
var turbo := 27.0
var ice := false
var held := [false, false]
var _touch := {}
var qa_autopilot := false              # (tools/qa: it drives itself)
var qa_hands_off := false              # (tools/qa hands=off: nobody steers)
var _passed_gates := 0
var _last_turn := 0.0
var _sfx_cd := 0.0
var _crowd_cd := 0.0
var _t := 0.0

var pads: Array = []                   # { i, half, lat, w, kind, lap (hit on), node }
var jumps: Array = []                  # { a, b, kind } (a: the gap's first point; land: the ramp before it)
var obstacles: Array = []              # { kind, i, pos, base, r, node, k }
var wells: Array = []                  # { pos, r, node }
var gusts: Array = []                  # [first point, last, side]
var secret := {}
var rivals: Array = []
var _rival_things: Array = []

# --- nodes ---
var deep: ColorRect
var deep_mat: ShaderMaterial
var board: ColorRect
var board_mat: ShaderMaterial
var deep_shadow: Sprite2D              # the rocket's shadow, far below on the deep layer
var world: Node2D                      # everything on the mat (moved and scaled by the view)
var under: Node2D                      # on the ground / the water: currents, buoys, ring backs
var things: Node2D                     # rocks, icebergs, asteroids, wells, moons
var crowd: PalPrix2Fx.Crowd
var trail: PalPrix2Fx.Trail
var buoys: PalPrix2Fx.Buoys
var beacons: PalPrix2Fx.Beacons
var front: Node2D                      # the craft and the rivals
var craft: Node2D
var slices: Array[Sprite2D] = []
var driver: Sprite2D
var canopy: Sprite2D                   # the glass cabin over the pal
var shadow: Sprite2D
var glow: Sprite2D
var flames: Flames
var antenna: Line2D
var antenna_tip: Sprite2D
var ring_front: Node2D                 # the rings' near halves (over the craft)
var gates_layer: Node2D                # the transform gates' arches (over everything)
var pops: PalPrix2Fx.Pops
var speed_lines: PalPrix2Fx.SpeedLines
var aurora: PalPrix2Fx.Aurora
var gust_fx: PalPrix2Fx.Gusts
var hud_lap: Label
var hud_time: Label
var hud_place: Label
var hud_chain: Label
var hud_stars: Array[TextureRect] = []
var boost_icon: TextureRect
var boost_bar: ColorRect
var lights: Node2D
var lamps: Array[Sprite2D] = []
var hint_left: HBoxContainer
var hint_right: HBoxContainer
var banner: Label
var motor: AudioStreamPlayer
var lcd_font: Font
var cam := Vector2.ZERO                # the mat px at the view's middle
var zoom := Z_START
var punch := 1.0                       # (a transform: the view leans in a moment)
var shake := 0.0
var look_k := 0.0
var _stars_shown := 3
var _form_shown := -1
var _unfold := 1.0

## The thrusters' jets behind the craft: the hover car's two cyan jets, the rocket's flames
## (longer on a boost), flickering; on the 4 px grid
class Flames extends Node2D:
	var on := true
	var pos := Vector2.ZERO
	var heading := 0.0
	var kind := 0
	var power := 0.0
	var lift := Vector2.ZERO
	var t := 0.0
	func _process(delta: float) -> void:
		t += delta
		queue_redraw()
	func _draw() -> void:
		if not on or kind == 1:
			return
		var back := Vector2.from_angle(heading)
		var side := Vector2(-back.y, back.x)
		var spread := 40.0 if kind == 0 else 18.0
		var tail := (28.0 if kind == 0 else 44.0) * (1.0 + power * 1.2)
		var c0 := Color8(255, 250, 220) if kind == 2 else Color8(230, 255, 255)
		var c1 := Color8(255, 170, 70) if kind == 2 else Color8(110, 240, 255)
		var c2 := Color8(230, 80, 60) if kind == 2 else Color8(40, 150, 220)
		for sd in [-1.0, 1.0]:
			var base: Vector2 = pos + lift - back * (56.0 if kind == 2 else 58.0) + side * sd * spread
			var flick := 0.8 + 0.2 * sin(t * 40.0 + sd * 3.0)
			var n := int(tail * flick / 4.0)
			for k in n:
				var f := float(k) / float(maxi(n, 1))
				var p := PalPrix2Fx.snap(base - back * k * 4.0)
				var w := (8.0 if f < 0.3 else 4.0)
				var c := c0 if f < 0.2 else (c1 if f < 0.6 else c2)
				c.a = 1.0 - f * 0.7
				draw_rect(Rect2(p - Vector2(w, w) / 2.0, Vector2(w, w)), c)

func _ready() -> void:
	game_music_path = _song_for(GameData.last_level(GAME_INDEX))
	lcd_font = load("res://fonts/pixChicago.ttf")
	_create_nodes()
	intro_text = "Race your turbo craft"
	intro_controls = [[0, "LEFT"], [1, "RIGHT"]]
	intro_icon = PalPrix2Art.icon("hover")
	super._ready()

# --- the level menu (BaseMinigame) ---

func uses_levels() -> bool:
	return true

func world_names() -> Array:
	return WORLDS

func level_count() -> int:
	return LEVELS.size()

func level_pattern() -> Texture2D:
	var p := "res://textures/menus/pattern_rocket_navy.png"
	return load(p) if ResourceLoader.exists(p) else load("res://textures/menus/pattern_trophy_terracotta.png")

func level_backdrop() -> Color:
	return WORLD_BACKDROPS[0]

func world_backdrop(w: int) -> Color:
	return WORLD_BACKDROPS[clampi(w, 0, WORLD_BACKDROPS.size() - 1)]

func secrets() -> Dictionary:
	var out := {}
	for lvl in SECRETS:
		out[lvl] = { "gate": SECRETS[lvl][0], "lvl": 1 + clampi((lvl - 1) / GameData.LEVELS_PER_WORLD, 0, 5) / 2, "prize": SECRETS[lvl][1] }
	return out

func finale_prizes() -> Dictionary:
	return FINALES

func start_game() -> void:
	super.start_game()
	_begin(1)

func play_level(n: int) -> void:
	super.start_game()
	_begin(n)

# ================================================================== A LEVEL

func _begin(n: int) -> void:
	level = clampi(n, 1, LEVELS.size())
	world_no = (level - 1) / GameData.LEVELS_PER_WORLD
	var spec: Array = LEVELS[level - 1]
	extras = spec[7] if spec.size() > 7 else {}
	ice = bool(extras.get("ice", false))
	_play_song()
	var t0 := Time.get_ticks_msec()
	course = PalPrix2Course.new()
	course.margin = 340.0
	course.build(spec, PLANS[world_no], int(extras.get("gates", 2)), WEIGHTS[world_no], level, CELLS[world_no])
	_place_features()
	course.make_fields()
	_setup_shaders()
	_spawn_course_things()
	_place_crowd()
	_spawn_rivals()
	if qa_autopilot:
		print("QA build %d: %d ms, %d points, %d gates" % [level, Time.get_ticks_msec() - t0, course.count, course.gates.size()])
		print("QA things %d: wells %s obstacles %s slings %s" % [level, str(wells.map(func(w): return w["i"])), str(obstacles.map(func(o): return [o["i"], o["kind"]])), str(pads.filter(func(p): return p["sling"]).map(func(p): return p["i"]))])
	# the craft on the line
	car_pos = course.centre[0]
	heading = course.direction(0).angle()
	vel = Vector2.ZERO
	speed = 0.0
	near = 0
	progress = 0.0
	lap = 1
	race_time = 0.0
	form = course.kind_at(0)
	_set_form(form, 1.0)
	car_h = AIR_H if form == AIR else 0.0
	boost = 0.0
	chain = 0
	drift_ang = 0.0
	drift_level = 0
	wall_t = 0.0
	bump_t = 0.0
	spin_t = 0.0
	slip_charge = 0.0
	hop_t = 0.0
	tf_t = 0.0
	slow_t = 0.0
	bank = 0.0
	bumps = 0
	place = 1
	falls = 0
	last_cp = 0.0
	splash_used = false
	_grace_t = 0.0
	craft.modulate = Color(1, 1, 1)
	craft.scale = Vector2.ONE
	reset_lives()
	_passed_gates = 0
	held = [false, false]
	_touch.clear()
	_stars_shown = 3
	for s in hud_stars:
		s.texture = UiArt.star(true)
	trail.marks.clear()
	_par_times()
	state = State.WAIT
	countdown = COUNTDOWN + 0.6
	lights.visible = true
	lights.modulate.a = 1.0
	lights.position.y = HUD_BAND.end.y + 64
	_set_lamps(0, false)
	for h in [hint_left, hint_right]:
		h.visible = true
		h.modulate.a = 1.0
	look_k = 0.0
	zoom = Z_START
	altitude = 0.0
	cam = car_pos
	intro_text = "Race your turbo craft"
	intro_icon = PalPrix2Art.icon(FORM_NAMES[form])
	aurora.visible = world_no == 3
	speed_lines.tint = Color8(220, 230, 255) if world_no >= 4 else Color(1, 1, 1)
	_qa_start_at()
	_place_craft()
	_follow(1.0)
	_refresh_hud()
	var k := (level - 1) % GameData.LEVELS_PER_WORLD
	var hint: String = WORLD_HINTS[world_no] if k == 0 else (LATER_HINTS[world_no][0] if k == 3 else (LATER_HINTS[world_no][1] if k == 6 else ""))
	_show_banner(WORLDS[world_no] if k == 0 else "%d-%d" % [world_no + 1, k + 1], 1.2 if k == 0 else 0.8)
	if hint != "":
		get_tree().create_timer(1.4 if k == 0 else 1.0).timeout.connect(func():
			if is_running and level == n:
				_show_banner(hint, 1.2))

## Its two songs (the user, 2026-10-19): "Turbo Circuit" for the first three worlds, "Racer X"
## for the last three (looped on bar lines: tools/audio/loop_track.py)
const SONGS := ["res://sounds/music/Turbo Circuit.ogg", "res://sounds/music/Racer X.ogg"]
func _song_for(lvl: int) -> String:
	return SONGS[0] if (maxi(lvl, 1) - 1) / GameData.LEVELS_PER_WORLD < 3 else SONGS[1]

## A level's world has its song: switched on the game screen if it isn't the one playing
func _play_song() -> void:
	var want := _song_for(level)
	if want == game_music_path:
		return
	game_music_path = want
	var gs = get_node_or_null("/root/PoopPal/Main UI/GameScreen")
	if gs and gs.has_method("_start_music_for_game"):
		gs._start_music_for_game()

## The par time (a clean drive, a little slack: no boosts needed) and the turbo time (the boosts'
## time: plates, drifts, perfect transforms)
func _par_times() -> void:
	var lap_t := 0.0
	for i in course.count:
		lap_t += STEP / float(SPEED[course.kinds[i]])
	var clean := lap_t * LAPS + 0.6                     # (+ getting going off the line)
	var slack := ICE_SLACK if ice else 1.0
	par = ceilf(clean * PAR_SLACK * slack + PAR_PLUS)
	turbo = floorf(clean * TURBO_K * slack)

# ================================================================== THE COURSE'S THINGS

## Plates (currents, rings), jumps, things in the way, wells, gusts and the secret: on straights,
## clear of the start, the gates and each other
func _place_features() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 4409 * level + 11
	var count := course.count
	var used: Array = []                      # [first, last] points taken
	for g in course.gates:
		used.append([int(g["i"]) - 34, int(g["i"]) + 30])
	var free_at := func(a: int, b: int) -> bool:
		if a < 36 or b > count - 30:
			return false
		for u in used:
			if b >= u[0] - 12 and a <= u[1] + 12:
				return false
		return true
	var spots := func(room: int) -> Array:
		var out: Array = []
		for i in range(40, count - 40, 6):
			if course.straight(i, room, room):
				out.append(i)
		return out
	# jumps (land: a ramp and a gap between roofs; sea: a waterfall step)
	jumps.clear()
	for kind_name in ["jumps", "steps"]:
		var want := int(extras.get(kind_name, 0))
		var kind := LAND if kind_name == "jumps" else SEA
		var cand: Array = spots.call(16)
		_shuffle(cand, rng)
		for i in cand:
			if jumps.filter(func(j): return j["kind"] == kind).size() >= want:
				break
			if course.kind_at(i) != kind or course.kind_at(i + GAP_PTS) != kind or course.kind_at(i - RAMP_PTS - 4) != kind:
				continue
			var a: int = i - (RAMP_PTS if kind == LAND else 2)
			var b: int = i + (GAP_PTS if kind == LAND else 4)
			if not free_at.call(a, b):
				continue
			jumps.append({ "a": i, "b": i + (GAP_PTS if kind == LAND else 2), "kind": kind })
			used.append([a, b])
	# boost plates (land), currents (sea), rings (air): spread round the lap, on its line
	pads.clear()
	var n_pads := int(LEVELS[level - 1][6])
	var at := 0.0
	var tries := 0
	var side := 1.0
	while pads.size() < n_pads and tries < 400:
		tries += 1
		var want_i := int(fposmod(0.12 + float(pads.size()) / maxf(n_pads, 1) + at, 1.0) * count)
		var found := -1
		for o in range(0, count / 3, 3):
			for sg in [1, -1]:
				var i: int = want_i + o * sg
				if i < 40 or i > count - 40:
					continue
				if course.straight(i, PAD_HALF + 4, PAD_HALF + 4) and free_at.call(i - PAD_HALF - 4, i + PAD_HALF + 4):
					found = i
					break
			if found >= 0:
				break
		if found < 0:
			at += 0.07
			continue
		var kind := course.kind_at(found)
		var lat := side * course.half_w * (0.3 if kind != AIR else 0.32)
		side = -side
		pads.append({ "i": found, "half": PAD_HALF, "lat": lat, "w": course.half_w * 0.42, "kind": kind, "lap": 0, "sling": false })
		used.append([found - PAD_HALF - 4, found + PAD_HALF + 4])
	# slingshots: a moon beside the air lane, its orbit across it (a ring that boosts more)
	for s in int(extras.get("slings", 0)):
		var cand2: Array = spots.call(12)
		_shuffle(cand2, rng)
		for i in cand2:
			if course.kind_at(i) == AIR and free_at.call(i - 14, i + 14):
				pads.append({ "i": i, "half": PAD_HALF, "lat": 0.0, "w": course.half_w * 0.6, "kind": AIR, "lap": 0, "sling": true, "side": -1.0 if rng.randf() < 0.5 else 1.0 })
				used.append([i - 14, i + 14])
				break
	pads.sort_custom(func(x, y): return x["i"] < y["i"])
	# things in the way: rocks (the river), icebergs (the fjord), asteroids (space): each to one
	# side of the lane, room to go round the other way
	obstacles.clear()
	for kind_name in ["rocks", "bergs", "asteroids"]:
		var want2 := int(extras.get(kind_name, 0))
		var on_kind := SEA if kind_name != "asteroids" else AIR
		var placed := 0
		var t2 := 0
		while placed < want2 and t2 < 300:
			t2 += 1
			var i := rng.randi_range(45, count - 40)
			if course.kind_at(i) != on_kind or not course.straight(i, 10, 10) or not free_at.call(i - 8, i + 8):
				continue
			# (room to straighten up between two: never a quick slalom at these speeds)
			var crowded := false
			for o2 in obstacles:
				if absi(posmod(int(o2["i"]) - i + count / 2, count) - count / 2) < 80:
					crowded = true
			if crowded and t2 < 250:
				continue
			var sd := -1.0 if rng.randf() < 0.5 else 1.0
			var r: float = { "rocks": 30.0, "bergs": 46.0, "asteroids": 46.0 }[kind_name]
			var pos: Vector2 = course.centre[i] + course.normal(i) * sd * rng.randf_range(0.36, 0.5) * course.half_w
			obstacles.append({ "kind": kind_name, "i": i, "pos": pos, "base": pos, "r": r, "k": placed + level, "side": sd })
			used.append([i - 8, i + 8])
			placed += 1
	# gravity wells: beside the air lane, pulling across it
	wells.clear()
	for s2 in int(extras.get("wells", 0)):
		for t3 in 120:
			var i := rng.randi_range(45, count - 40)
			if course.kind_at(i) != AIR or not free_at.call(i - 10, i + 10) or not course.straight(i, 24, 24):
				continue
			var sd2 := -1.0 if rng.randf() < 0.5 else 1.0
			wells.append({ "pos": course.centre[i] + course.normal(i) * sd2 * (course.half_w + 70.0), "r": 260.0, "i": i })
			used.append([i - 10, i + 10])
			break
	# the canyon's winds: stretches of the flight where it blows across
	gusts.clear()
	for s3 in int(extras.get("gusts", 0)):
		for t4 in 80:
			var i := rng.randi_range(45, count - 100)
			var ln := int(480.0 / STEP)
			if course.kind_at(i) != AIR or course.kind_at(i + ln) != AIR:
				continue
			var clash := false
			for g in gusts:
				if i < g[1] + 30 and i + ln > g[0] - 30:
					clash = true
			if not clash:
				gusts.append([i, i + ln, -1.0 if rng.randf() < 0.5 else 1.0])
				break
	# the secret: a spot on a straight (a fizzy one by a waterfall step)
	secret = secret_of(level)
	if not secret.is_empty():
		var spot := -1
		if secret["gate"] == "fizzy":
			for j in jumps:
				spot = int(j["b"]) + 6
				break
		if secret["gate"] == "milky":
			for i in spots.call(14):
				if course.kind_at(i) == LAND and free_at.call(i - 12, i + 12):
					spot = i
					break
		if spot < 0:
			for i in spots.call(10):
				if free_at.call(i - 10, i + 10):
					spot = i
					break
		if spot < 0:
			secret = {}
		else:
			secret["at"] = spot
			used.append([spot - 12, spot + 12])

func _shuffle(arr: Array, rng: RandomNumberGenerator) -> void:
	for i in range(arr.size() - 1, 0, -1):
		var j := rng.randi() % (i + 1)
		var tmp = arr[i]
		arr[i] = arr[j]
		arr[j] = tmp

## The shaders: the course's textures, its regions, its gates, plates and jumps
func _setup_shaders() -> void:
	var reg: Dictionary = REGIONS[world_no]
	var hw := course.half_w
	board_mat.set_shader_parameter("world", world_no)
	board_mat.set_shader_parameter("count", course.count)
	board_mat.set_shader_parameter("hw", hw / PX)
	board_mat.set_shader_parameter("cs", float(PalPrix2Course.CS))
	board_mat.set_shader_parameter("field_size", Vector2(course.gw, course.gh))
	board_mat.set_shader_parameter("pts_tex", course.pts_tex)
	board_mat.set_shader_parameter("near_tex", course.near_tex)
	board_mat.set_shader_parameter("r_sea", float(reg.get("sea", 0.0)) / PX)
	board_mat.set_shader_parameter("r_air", float(reg.get("air", 0.0)) / PX)
	board_mat.set_shader_parameter("r_land", float(reg.get("land", 0.0)) / PX)
	board_mat.set_shader_parameter("has_land", course.kinds.has(LAND))
	board_mat.set_shader_parameter("has_sea", course.kinds.has(SEA))
	board_mat.set_shader_parameter("has_air", course.kinds.has(AIR))
	board_mat.set_shader_parameter("face_h", float(FACE_H[world_no]))
	board_mat.set_shader_parameter("icy", ice)
	var gv: Array = []
	for g in course.gates:
		gv.append(Vector4(float(g["i"]), float(g["from"]), float(g["to"]), 0.0))
	while gv.size() < 8:
		gv.append(Vector4(-1000.0, -1.0, -1.0, 0.0))
	board_mat.set_shader_parameter("gates", gv)
	board_mat.set_shader_parameter("n_gates", course.gates.size())
	var pv: Array = []
	for p in pads:
		if p["kind"] == LAND:
			pv.append(Vector4(float(p["i"]), float(p["half"]), float(p["lat"]) / PX, float(p["w"]) / PX))
	var n_land := pv.size()
	while pv.size() < 12:
		pv.append(Vector4(-1000.0, 0.0, 0.0, 0.0))
	board_mat.set_shader_parameter("pads", pv)
	board_mat.set_shader_parameter("n_pads", n_land)
	var jv: Array = []
	for j in jumps:
		jv.append(Vector4(float(j["a"]), float(j["b"]), float(RAMP_PTS), float(j["kind"])))
	var n_j := jv.size()
	while jv.size() < 8:
		jv.append(Vector4(-1000.0, -1000.0, 0.0, -1.0))
	board_mat.set_shader_parameter("gaps", jv)
	board_mat.set_shader_parameter("n_gaps", n_j)
	deep_mat.set_shader_parameter("world", world_no)
	deep_mat.set_shader_parameter("parallax", PARALLAX[world_no])
	deep_mat.set_shader_parameter("view_size", FULL.size)
	# (Saturn's Rings: where the Earth is, and the planet far out past the flight)
	var land_mid := Vector2.ZERO
	var nl := 0
	var air_mid := Vector2.ZERO
	var na := 0
	for i in range(0, course.count, 4):
		if course.kinds[i] == AIR:
			air_mid += course.centre[i]
			na += 1
		else:
			land_mid += course.centre[i]
			nl += 1
	land_mid /= maxf(nl, 1)
	air_mid = air_mid / maxf(na, 1) if na > 0 else course.mat_size * 0.5
	var out := (air_mid - land_mid).normalized() if air_mid != land_mid else Vector2.RIGHT
	deep_mat.set_shader_parameter("planet", air_mid * 0.12 + (out + Vector2(-out.y, out.x) * 0.6).normalized() * (560.0 if world_no == 5 else 480.0))
	deep.visible = course.kinds.has(AIR) or not jumps.is_empty() or world_no >= 4

## The pieces on the course: the gates' arches, the sea lanes' buoys, the air lanes' beacons,
## the currents and rings, things in the way, wells, moons, the secret
var _thing_nodes: Array = []
func _spawn_course_things() -> void:
	for nd in _thing_nodes:
		if is_instance_valid(nd):
			nd.queue_free()
	_thing_nodes.clear()
	var hw := course.half_w
	var count := course.count
	var accent: Color = ACCENTS[world_no]
	# the gates
	for g in course.gates:
		var i := int(g["i"])
		var arch := PalPrix2Fx.Gate.new()
		var nrm := course.normal(i)
		arch.a = course.centre[i] - nrm * (hw + 18.0)
		arch.b = course.centre[i] + nrm * (hw + 18.0)
		arch.dir = course.direction(i)
		arch.to = int(g["to"])
		gates_layer.add_child(arch)
		g["node"] = arch
		_thing_nodes.append(arch)
	# the sea lanes' buoys: both edges, one every so often
	var bspots: Array = []
	for sd in [-1.0, 1.0]:
		var last := Vector2(-1e9, -1e9)
		var nb := 0
		for i in count:
			if course.kinds[i] != SEA:
				continue
			var p: Vector2 = course.centre[i] + course.normal(i) * sd * hw
			if p.distance_to(last) < 48.0:
				continue
			bspots.append([p, nb % 2 == 0])
			last = p
			nb += 1
	buoys.setup(bspots, accent, ACCENTS[(world_no + 2) % 6])
	# the air lanes' beacons
	var aspots: Array = []
	for i in range(0, count, 3):
		if course.kinds[i] != AIR:
			continue
		for sd2 in [-1.0, 1.0]:
			aspots.append([course.centre[i] + course.normal(i) * sd2 * hw * AIR_EDGE - Vector2(0, AIR_H), i, sd2])
	beacons.setup(aspots, accent)
	# currents and rings
	for p2 in pads:
		var i2 := int(p2["i"])
		match int(p2["kind"]):
			SEA:
				var cu := PalPrix2Fx.Current.new()
				cu.position = course.centre[i2] + course.normal(i2) * float(p2["lat"])
				cu.dir = course.direction(i2)
				cu.width = float(p2["w"]) - 8.0
				under.add_child(cu)
				p2["node"] = cu
				_thing_nodes.append(cu)
			AIR:
				var halves: Array = []
				for upper in [false, true]:
					var rg := PalPrix2Fx.Ring.new()
					rg.position = course.centre[i2] + course.normal(i2) * float(p2["lat"]) - Vector2(0, AIR_H)
					rg.n = course.normal(i2)
					rg.r = float(p2["w"])
					rg.upper = upper
					rg.d = course.direction(i2)
					rg.col = Color8(255, 214, 90) if p2["sling"] else accent.lerp(Color8(255, 110, 220), 0.5)
					(ring_front if upper else under).add_child(rg)
					halves.append(rg)
					_thing_nodes.append(rg)
				p2["rings"] = halves
				if p2["sling"]:
					var moon := _px_sprite(PalPrix2Art.moon(level + i2), course.centre[i2] + course.normal(i2) * float(p2["side"]) * (hw + 150.0))
					things.add_child(moon)
					_thing_nodes.append(moon)
	# things in the way
	for ob in obstacles:
		var tex: Texture2D
		match String(ob["kind"]):
			"rocks":
				tex = PalPrixArt.rock(int(ob["k"]))
			"bergs":
				tex = PalPrix2Art.iceberg(int(ob["k"]))
			_:
				tex = PalPrix2Art.asteroid(int(ob["k"]))
		var spr := _px_sprite(tex, ob["pos"])
		things.add_child(spr)
		ob["node"] = spr
		_thing_nodes.append(spr)
	var zones := []
	for g2 in gusts:
		var pts := PackedVector2Array()
		for i3 in range(int(g2[0]), int(g2[1]), 4):
			pts.append(course.centre[i3 % count] - Vector2(0, AIR_H))
		zones.append([pts, course.normal((int(g2[0]) + int(g2[1])) / 2) * float(g2[2])])
	gust_fx.setup(zones)
	for w in wells:
		var wl := PalPrix2Fx.Well.new()
		wl.position = w["pos"]
		wl.r = float(w["r"])
		things.add_child(wl)
		w["node"] = wl
		_thing_nodes.append(wl)
	_spawn_secret()

## The grandstand beside the start, on whichever side has room
func _place_crowd() -> void:
	var dir := course.direction(0)
	var horizontal := absf(dir.x) > absf(dir.y)
	var normal := Vector2(-dir.y, dir.x)
	var reg: Dictionary = REGIONS[world_no]
	var gap := 40.0
	if course.kind_at(0) == SEA:
		gap = float(reg.get("sea", 200.0)) - course.half_w + 30.0
	for long in [440.0, 340.0, 260.0]:
		var size := Vector2(long, 136) if horizontal else Vector2(136, long)
		for sd in [1.0, -1.0]:
			var c: Vector2 = course.centre[0] + normal * sd * (course.half_w + gap + 68.0)
			var r := Rect2(c - size / 2.0, size)
			var ok := true
			for j in range(0, course.count, 2):
				var p := course.centre[j]
				if p.distance_to(p.clamp(r.position, r.end)) < course.half_w + gap - 6.0:
					ok = false
					break
			if ok:
				crowd.setup(r, horizontal, level * 13 + 1, normal * sd, ACCENTS[world_no])
				crowd.visible = true
				return
	crowd.visible = false

# ================================================================== THE CRAFT

## The craft's form: its slices (unfolded `k` of the way), its jets, its glow, its motor's voice
func _set_form(f: int, k: float) -> void:
	var layers := PalPrix2Art.slices(FORM_NAMES[f], "red", k)
	if slices.size() != layers.size():
		for sl in slices:
			sl.queue_free()
		slices.clear()
		for i in layers.size():
			var sp := Sprite2D.new()
			sp.scale = Vector2(PX, PX)
			sp.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
			craft.add_child(sp)
			slices.append(sp)
	for i in layers.size():
		slices[i].texture = layers[i]
	shadow.texture = layers[1]
	flames.kind = f
	_unfold = k
	if _form_shown != f:
		_form_shown = f
		var path: String = ["res://sounds/fx/rc_motor.wav", "res://sounds/fx/boat_motor.wav", "res://sounds/fx/plane_motor.wav"][f]
		var was_playing := motor.playing
		var hum: AudioStreamWAV = load(path).duplicate()
		hum.loop_mode = AudioStreamWAV.LOOP_FORWARD
		hum.loop_end = hum.get_length() * hum.mix_rate
		motor.stream = hum
		motor.volume_db = [-23.0, -21.0, -24.0][f]
		if was_playing:
			motor.play()

func _place_craft() -> void:
	var lift := Vector2(0, -car_h)
	craft.position = (car_pos + lift).round()
	var n := slices.size()
	var yaw := heading
	if drift_level > 0 or drift_ang > 0.6:
		yaw += drift_dir * 0.32 * clampf(drift_ang / DRIFT_STEPS[0], 0.0, 1.0)
	if spin_t > 0.0:
		yaw += (1.0 - spin_t / 0.5) * TAU
	if tf_t > 0.0:
		var f := 1.0 - tf_t / TF_TIME
		yaw += f * f * (3.0 - 2.0 * f) * TAU
	var tilt := Vector2.from_angle(heading + PI / 2.0) * bank * 12.0 if form == AIR else Vector2.ZERO
	var squash := 1.0 - 0.35 * absf(bank) if form == AIR else 1.0
	for i in n:
		slices[i].rotation = yaw
		slices[i].position = (Vector2(0, -i * LAYER_UP) + tilt * float(i) / maxf(1.0, n - 1)).round()
		slices[i].scale = Vector2(PX, PX * squash)
	# the pal in its seat (its face kept upright)
	var seat := Vector2.from_angle(yaw) * PalPrix2Art.SEAT * PX
	driver.position = craft.position + seat + Vector2(0, -n * LAYER_UP - 4.0) + tilt
	canopy.position = (craft.position + Vector2.from_angle(yaw) * (PalPrix2Art.SEAT + 1.5) * PX + Vector2(0, -n * LAYER_UP - 2.0) + tilt).round()
	canopy.rotation = yaw
	canopy.scale = Vector2(PX, PX * squash)
	canopy.modulate = craft.modulate
	driver.scale = Vector2(2, 2) * craft.scale.x
	driver.modulate = craft.modulate
	# its shadow: on the ground under it, or far below on the deep layer when it flies
	var grounded := car_h < AIR_H * 0.5
	shadow.visible = grounded
	shadow.position = car_pos.round() + Vector2(6, 10)
	shadow.rotation = yaw
	glow.visible = form == LAND and grounded
	glow.position = car_pos.round() + Vector2(0, 6)
	glow.rotation = yaw
	glow.modulate.a = 0.35 + 0.15 * sin(_t * 9.0) + 0.3 * boost
	deep_shadow.visible = not grounded and deep.visible
	if deep_shadow.visible:
		var mid := FULL.get_center()                  # (the deep layer's parallax turns about the ground's middle)
		var on_screen := world.position + car_pos * zoom
		deep_shadow.position = (mid + (on_screen - mid) * PARALLAX[world_no] + Vector2(40, 66)).round()
		deep_shadow.rotation = yaw
		deep_shadow.texture = slices[1].texture
		deep_shadow.scale = Vector2(3, 3) * zoom * 0.8
	# the jets
	flames.pos = car_pos
	flames.lift = lift + Vector2(0, -2.0 * LAYER_UP)
	flames.heading = yaw
	flames.power = boost
	flames.on = state == State.DRIVE or (state == State.WAIT and form == AIR)
	# the antenna: a wire up from its back left, leaning back and out; a ball on its tip
	var corner := Vector2(-44, -24)
	var base := craft.position + corner.rotated(yaw) + Vector2(0, -n * LAYER_UP)
	var lean := Vector2.from_angle(heading) * -12.0 * (0.5 + speed / 1600.0) + Vector2.from_angle(heading + PI / 2.0) * -_last_turn * 14.0
	var top := base + Vector2(0, -46) + lean
	antenna.points = PackedVector2Array([base.round(), (base.lerp(top, 0.5) + lean * 0.15).round(), top.round()])
	antenna_tip.position = top.round()
	antenna.visible = state != State.FALL
	antenna_tip.visible = antenna.visible

# ================================================================== NODES

func _create_nodes() -> void:
	var bg := ColorRect.new()
	bg.color = Color8(12, 10, 22)
	bg.size = Vector2(PLAY_WIDTH, PLAY_HEIGHT)
	add_child(bg)
	deep = ColorRect.new()
	deep.position = FULL.position
	deep.size = FULL.size
	deep_mat = ShaderMaterial.new()
	deep_mat.shader = load("res://scripts/shaders/pal_prix_2_deep.gdshader")
	deep.material = deep_mat
	add_child(deep)
	deep_shadow = Sprite2D.new()
	deep_shadow.modulate = Color(0.05, 0.03, 0.12, 0.3)
	deep_shadow.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	add_child(deep_shadow)
	board = ColorRect.new()
	board.position = FULL.position
	board.size = FULL.size
	board_mat = ShaderMaterial.new()
	board_mat.shader = load("res://scripts/shaders/pal_prix_2_board.gdshader")
	board.material = board_mat
	add_child(board)
	world = Node2D.new()
	add_child(world)
	under = Node2D.new()
	world.add_child(under)
	buoys = PalPrix2Fx.Buoys.new()
	world.add_child(buoys)
	beacons = PalPrix2Fx.Beacons.new()
	world.add_child(beacons)
	things = Node2D.new()
	world.add_child(things)
	crowd = PalPrix2Fx.Crowd.new()
	world.add_child(crowd)
	trail = PalPrix2Fx.Trail.new()
	world.add_child(trail)
	front = Node2D.new()
	world.add_child(front)
	shadow = Sprite2D.new()
	shadow.scale = Vector2(PX, PX)
	shadow.modulate = Color(0.04, 0.02, 0.1, 0.38)
	shadow.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	front.add_child(shadow)
	glow = Sprite2D.new()
	glow.texture = PalPrix2Art.hover_glow()
	glow.scale = Vector2(PX, PX)
	glow.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	var add := CanvasItemMaterial.new()
	add.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	glow.material = add
	front.add_child(glow)
	flames = Flames.new()
	front.add_child(flames)
	craft = Node2D.new()
	front.add_child(craft)
	antenna = Line2D.new()
	antenna.width = 4.0
	antenna.default_color = Color8(40, 30, 40)
	antenna.antialiased = false
	front.add_child(antenna)
	var tip := Image.create(3, 3, false, Image.FORMAT_RGBA8)
	for p in [Vector2i(1, 0), Vector2i(0, 1), Vector2i(1, 1), Vector2i(2, 1), Vector2i(1, 2)]:
		tip.set_pixel(p.x, p.y, Color8(110, 240, 255))
	tip.set_pixel(1, 1, Color8(230, 255, 255))
	antenna_tip = _px_sprite(ImageTexture.create_from_image(tip), Vector2.ZERO)
	front.add_child(antenna_tip)
	driver = Sprite2D.new()
	driver.texture = PalBall.texture()
	driver.scale = Vector2(2, 2)
	driver.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	front.add_child(driver)
	canopy = _px_sprite(PalPrix2Art.canopy(), Vector2.ZERO)
	front.add_child(canopy)
	ring_front = Node2D.new()
	world.add_child(ring_front)
	gust_fx = PalPrix2Fx.Gusts.new()
	world.add_child(gust_fx)
	gates_layer = Node2D.new()
	world.add_child(gates_layer)
	pops = PalPrix2Fx.Pops.new()
	pops.font = lcd_font
	world.add_child(pops)
	speed_lines = PalPrix2Fx.SpeedLines.new()
	speed_lines.view = FULL
	add_child(speed_lines)
	aurora = PalPrix2Fx.Aurora.new()
	aurora.view = FULL
	aurora.visible = false
	add_child(aurora)

	# the HUD on a dark band above the view: the lap, the clock / its target, the stars, the
	# chain, the place (with rivals), the pal's boost; a bar along its foot fills with the boost
	var band := ColorRect.new()
	band.color = Color8(28, 30, 50)
	band.position = HUD_BAND.position
	band.size = HUD_BAND.size
	add_child(band)
	var line := ColorRect.new()
	line.color = Color8(16, 16, 30)
	line.position = Vector2(HUD_BAND.position.x, HUD_BAND.end.y - 8)
	line.size = Vector2(HUD_BAND.size.x, 8)
	add_child(line)
	boost_bar = ColorRect.new()
	boost_bar.color = Color8(110, 240, 255)
	boost_bar.position = Vector2(HUD_BAND.position.x, HUD_BAND.end.y - 8)
	boost_bar.size = Vector2(0, 8)
	add_child(boost_bar)
	var light := Color(0.92, 0.96, 1.0)
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
	build_lives(Vector2(HUD_BAND.position.x + 566, HUD_BAND.position.y + 15), 30.0, 33.0)
	hud_chain = _label(Vector2(HUD_BAND.position.x + 700, HUD_BAND.position.y + 2), Vector2(70, 52), 32, HORIZONTAL_ALIGNMENT_LEFT, Color8(255, 214, 90))
	hud_place = _label(Vector2(HUD_BAND.end.x - 150, HUD_BAND.position.y + 2), Vector2(90, 52), 32, HORIZONTAL_ALIGNMENT_RIGHT, light)
	boost_icon = TextureRect.new()
	boost_icon.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	boost_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	boost_icon.size = Vector2(28, 36)
	boost_icon.position = Vector2(HUD_BAND.end.x - 52, HUD_BAND.position.y + 10)
	add_child(boost_icon)
	# the start lights: a dark gantry with a neon frame, three lamps
	lights = Node2D.new()
	lights.position = Vector2(PLAY_WIDTH / 2.0, HUD_BAND.end.y + 64)
	add_child(lights)
	var gantry := ColorRect.new()
	gantry.color = Color8(110, 240, 255)
	gantry.size = Vector2(272, 104)
	gantry.position = -gantry.size / 2.0
	lights.add_child(gantry)
	var g2 := ColorRect.new()
	g2.color = Color8(24, 24, 40)
	g2.size = Vector2(264, 96)
	g2.position = -g2.size / 2.0
	lights.add_child(g2)
	var inner := ColorRect.new()
	inner.color = Color8(46, 48, 72)
	inner.size = g2.size - Vector2(12, 12)
	inner.position = g2.position + Vector2(6, 6)
	lights.add_child(inner)
	for i in 3:
		var lamp := Sprite2D.new()
		lamp.texture = _lamp_texture()
		lamp.scale = Vector2(PX, PX)
		lamp.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		lamp.position = Vector2((i - 1) * 80, 0)
		lights.add_child(lamp)
		lamps.append(lamp)
	hint_left = make_button_hint(0, "LEFT")
	hint_left.position = Vector2(72, PLAY_HEIGHT - 86)
	hint_right = make_button_hint(1, "RIGHT")
	hint_right.position = Vector2(PLAY_WIDTH - 250, PLAY_HEIGHT - 86)
	banner = _label(Vector2(0, PLAY_HEIGHT / 2 - 70), Vector2(PLAY_WIDTH, 140), 72, HORIZONTAL_ALIGNMENT_CENTER, Color(1, 0.97, 0.9))
	banner.add_theme_color_override("font_outline_color", Color8(20, 18, 36))
	banner.add_theme_constant_override("outline_size", 16)
	banner.modulate.a = 0.0
	motor = AudioStreamPlayer.new()
	add_child(motor)

func _lamp_texture() -> Texture2D:
	var img := Image.create(16, 16, false, Image.FORMAT_RGBA8)
	var c := Vector2(8, 8)
	for y in 16:
		for x in 16:
			var d := Vector2(x + 0.5, y + 0.5).distance_to(c)
			if d > 7.5:
				continue
			var col := Color8(255, 255, 255)
			if d > 6.3:
				col = Color8(30, 26, 34)
			elif Vector2(x + 0.5, y + 0.5).distance_to(Vector2(5.5, 5.5)) < 1.8:
				col = Color8(255, 255, 255)
			elif d > 4.5:
				col = Color8(200, 200, 200)
			img.set_pixel(x, y, col)
	return ImageTexture.create_from_image(img)

const LAMP_OFF := Color(0.32, 0.3, 0.36)
const LAMP_RED := Color(1.0, 0.28, 0.24)
const LAMP_GREEN := Color(0.36, 1.0, 0.44)

func _set_lamps(lit: int, green: bool) -> void:
	for i in lamps.size():
		lamps[i].modulate = LAMP_GREEN if green else (LAMP_RED if i < lit else LAMP_OFF)

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

func _px_sprite(t: Texture2D, pos: Vector2, k := PX) -> Sprite2D:
	var sp := Sprite2D.new()
	sp.texture = t
	sp.position = pos
	sp.scale = Vector2(k, k)
	sp.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	return sp

# ================================================================== THE VIEW

## The view follows the craft, looking ahead the faster it goes, pulling back with its speed
## (and leaning in a moment at a transform); a shake on a boost
func _follow(amount: float) -> void:
	look_k = move_toward(look_k, 1.0 if state == State.DRIVE else 0.0, 0.03)
	var z_want := Z_START
	if state != State.WAIT:
		z_want = lerpf(Z_NEAR, Z_FAR, clampf((speed - 600.0) / 700.0, 0.0, 1.0))
	zoom = lerpf(zoom, z_want * punch, minf(1.0, amount * 0.45))
	var aim := car_pos + Vector2.from_angle(heading) * speed * 0.3 * look_k + Vector2(0, -car_h * 0.5)
	cam = cam.lerp(aim, amount)
	world.scale = Vector2(zoom, zoom)
	var pos := (VIEW.get_center() - cam * zoom).round()
	if shake > 0.0:
		pos += Vector2(randi_range(-1, 1), randi_range(-1, 1)) * 4.0 * ceilf(shake * 2.0)
	world.position = pos
	var origin := world.position - FULL.position
	board_mat.set_shader_parameter("origin", origin)
	board_mat.set_shader_parameter("zoom", zoom)
	board_mat.set_shader_parameter("t", _t)
	deep_mat.set_shader_parameter("cam", (FULL.get_center() - world.position) / zoom)
	if world_no == 5:
		altitude = lerpf(altitude, _altitude(), minf(1.0, amount * 0.3))
		deep_mat.set_shader_parameter("altitude", altitude)
	deep_mat.set_shader_parameter("zoom", zoom)
	deep_mat.set_shader_parameter("t", _t)
	pops.view = view_rect()
	beacons.craft = car_pos - Vector2(0, car_h)
	speed_lines.k = clampf((speed - 700.0) / 600.0, 0.0, 1.0) * (0.6 if state == State.DRIVE else 0.0) + boost * 0.6
	speed_lines.dir = Vector2.from_angle(heading)

## (Saturn's Rings) how far into its flight the craft is: 0 at the launch and the splashdown, 1 half
## way (deep space)
var altitude := 0.0
func _altitude() -> float:
	if course == null or course.kind_at(near) != AIR:
		return 0.0
	var a := near
	var guard := 0
	while course.kind_at(a - 1) == AIR and guard < course.count:
		a -= 1
		guard += 1
	var b := near
	guard = 0
	while course.kind_at(b + 1) == AIR and guard < course.count:
		b += 1
		guard += 1
	var f := float(near - a) / maxf(1.0, float(b - a))
	return sin(f * PI)

func view_rect() -> Rect2:
	return Rect2((VIEW.position - world.position) / zoom, VIEW.size / zoom)

# ================================================================== THE HUD

func _refresh_hud() -> void:
	hud_lap.text = "LAP %d/%d" % [mini(lap, LAPS), LAPS]
	var target := turbo if race_time <= turbo else par
	hud_time.text = "%d:%02d/%d:%02d" % [int(race_time) / 60, int(race_time) % 60, int(target) / 60, int(target) % 60]
	hud_time.add_theme_color_override("font_color", Color8(255, 224, 102) if target == turbo else (Color(0.92, 0.96, 1.0) if race_time <= par else Color(0.95, 0.55, 0.45)))
	hud_place.visible = not rivals.is_empty()
	hud_place.text = "P%d/%d" % [place, rivals.size() + 1]
	hud_chain.visible = chain >= 2
	hud_chain.text = "x%d" % chain
	boost_bar.size.x = HUD_BAND.size.x * clampf(boost / BOOST_MAX, 0.0, 1.0)
	boost_bar.color = ACCENTS[world_no] if drift_level == 0 else DRIFT_COLS[drift_level - 1]
	var b := PetState.boost
	boost_icon.visible = b in ["splash", "fizz", "focus", "sturdy", "lucky"]
	if boost_icon.visible:
		boost_icon.texture = PetState.boost_icon(b)
	var now := _stars_now()
	if now < _stars_shown:
		for i in range(now, _stars_shown):
			var st := hud_stars[i]
			st.texture = UiArt.star(false)
			var tw := create_tween()
			tw.tween_property(st, "scale", Vector2(1.4, 1.4), 0.08)
			tw.tween_property(st, "scale", Vector2.ONE, 0.2)
		_stars_shown = now
	elif now > _stars_shown:
		for i in range(_stars_shown, now):
			hud_stars[i].texture = UiArt.star(true)
		_stars_shown = now

## 1 + within par (with rivals: 1st) + within the turbo time (with rivals: and 1st)
func _stars_now() -> int:
	var first := place == 1
	if rivals.is_empty():
		return 1 + (1 if race_time <= par else 0) + (1 if race_time <= turbo else 0)
	return 1 + (1 if first else 0) + (1 if first and race_time <= turbo else 0)

# ================================================================== THE LOOP

func _process(frame_delta: float) -> void:
	if not is_running:
		if motor.playing:
			motor.stop()
		return
	var delta := minf(frame_delta, 0.05)
	_t += delta
	crowd.watch = car_pos
	var hulls: Array = [[car_pos, vel, true]] if form == SEA else []
	for r in rivals:
		if r["kind"] == SEA:
			hulls.append([r["pos"], Vector2.from_angle(float(r["heading"])) * 500.0, false])
	if buoys.update(delta, hulls) > 0 and state == State.DRIVE and _sfx_cd <= 0.0:
		_sfx_cd = 0.15
		_sfx("res://sounds/fx/water_boing.wav", -15.0, randf_range(1.5, 1.8))
	shake = maxf(0.0, shake - delta * 3.0)
	punch = lerpf(punch, 1.0, minf(1.0, delta * 5.0))
	_update_things(delta)
	match state:
		State.WAIT:
			var before := ceili(countdown - 0.6)
			countdown -= delta
			var now := ceili(countdown - 0.6)
			if now != before and now >= 1 and now <= COUNTDOWN:
				_set_lamps(COUNTDOWN - now + 1, false)
				_sfx("res://sounds/fx/rc_beep.wav", -10.0)
				Input.vibrate_handheld(15)
			if countdown <= 0.6:
				_go()
		State.DRIVE:
			_drive(delta)
		State.FALL:
			pass                                         # (the crash plays out: _crash's tween)
		State.DONE:
			# (over the line: it coasts on and slows down)
			speed = move_toward(speed, 0.0, BRAKE * 0.4 * delta)
			car_pos += Vector2.from_angle(heading) * speed * delta
			_find_near()
	_place_craft()
	_follow(minf(1.0, delta * 6.0))

func _go() -> void:
	state = State.DRIVE
	_set_lamps(COUNTDOWN, true)
	crowd.cheer(car_pos)
	_show_banner("GO!", 0.5)
	_sfx("res://sounds/fx/rc_go.wav", -8.0)
	Input.vibrate_handheld(40)
	motor.play()
	shake = 0.4
	var t := create_tween()
	t.tween_interval(0.7)
	t.tween_property(lights, "position:y", HUD_BAND.end.y - 80.0, 0.35).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
	t.parallel().tween_property(lights, "modulate:a", 0.0, 0.35)
	t.tween_callback(func(): lights.visible = false)
	var h := create_tween()
	h.tween_interval(3.5)
	h.tween_property(hint_left, "modulate:a", 0.0, 0.4)
	h.parallel().tween_property(hint_right, "modulate:a", 0.0, 0.4)

func _drive(delta_real: float) -> void:
	var delta := delta_real * (TF_SLOW if slow_t > 0.0 else 1.0)
	slow_t = maxf(0.0, slow_t - delta_real)
	race_time += delta
	_sfx_cd = maxf(0.0, _sfx_cd - delta)
	_crowd_cd = maxf(0.0, _crowd_cd - delta)
	var turn := (1.0 if _held(1) else 0.0) - (1.0 if _held(0) else 0.0)
	if qa_autopilot:
		turn = 0.0 if qa_hands_off else _autopilot()
	_last_turn = turn
	# the speed it wants: its form's, the boost on top; a wall, a bump hold it back
	var grip: float = GRIP[form]
	if form == LAND and ice:
		grip = ICE_GRIP
	var target: float = SPEED[form] * (1.0 + boost)
	if slip_charge >= SLIP_NEED:
		target *= 1.08
	if bump_t > 0.0:
		target *= 1.0 - 0.55 * bump_t
	var lat_now := (car_pos - course.centre[near]).dot(course.normal(near))
	if form == SEA and absf(lat_now) > course.half_w - SHALLOW_IN and hop_t <= 0.0 and tf_t <= 0.0:
		# past the buoys: the shallows, slowed, its hull scraping (a spray, a rumble)
		target *= SHALLOW_SLOW
		if _sfx_cd <= 0.0:
			_sfx_cd = 0.12
			Input.vibrate_handheld(6)
			trail.spray(car_pos + course.normal(near) * signf(lat_now) * 18.0, heading, 2)
	_grace_t = maxf(0.0, _grace_t - delta)
	speed = move_toward(speed, target, (ACCEL if speed < target else BRAKE) * delta)
	if wall_t > 0.0:
		speed *= exp(-WALL_DRAG * delta)
	boost = maxf(0.0, boost - BOOST_FADE * delta)
	bump_t = maxf(0.0, bump_t - delta / 0.8)
	spin_t = maxf(0.0, spin_t - delta)
	wall_t = maxf(0.0, wall_t - delta)
	# turning: the same circle at any speed (faster, not harder); not while spun round
	var rate := speed / float(TURN_R[form])
	if spin_t <= 0.0:
		heading += turn * rate * delta
	bank = move_toward(bank, turn if form == AIR else 0.0, delta * 4.0)
	_drift(turn, rate, delta)
	# its way takes up its heading (the jet ski slides, ice slides more)
	var want := Vector2.from_angle(heading) * speed
	vel = vel.lerp(want, 1.0 - exp(-(grip * (0.55 if drift_level > 0 else 1.0)) * delta))
	if vel.length() > speed * 1.02 and speed > 0.0:
		vel = vel.normalized() * speed
	# the air's forces: gusts across the flight, wells pulling
	if form == AIR:
		for g in gusts:
			if near >= int(g[0]) and near <= int(g[1]):
				vel += course.normal(near) * float(g[2]) * GUST_PUSH * 2.0 * delta
		for w in wells:
			var to: Vector2 = (w["pos"] as Vector2) - car_pos
			var d := to.length()
			if d < float(w["r"]) and d > 1.0:
				var k := 1.0 - d / float(w["r"])
				vel += to / d * WELL_PULL * k * k * delta
	car_pos += vel * delta
	if hop_t > 0.0:
		hop_t -= delta
		var f := 1.0 - hop_t / hop_len
		car_h = sin(f * PI) * (54.0 if not _fizzy_hop else 110.0)
		if hop_t <= 0.0:
			_land_hop()
	elif tf_t <= 0.0:
		car_h = move_toward(car_h, AIR_H if form == AIR else 0.0, 160.0 * delta)
	var was := progress
	var was_near := near
	_find_near()
	if progress >= last_cp + course.count / CHECKPOINTS:
		last_cp = floorf(progress / (course.count / CHECKPOINTS)) * (course.count / CHECKPOINTS)
	var crash := _walls(delta)
	if crash != "":
		_crash(crash)
		return
	_transforms(was, delta)
	_pads(was)
	_jumps(was_near)
	_bumps()
	_slipstream(delta)
	_update_secret(was_near)
	_update_rivals(delta)
	_fx(delta)
	if crowd.visible and _crowd_cd <= 0.0 and crowd.rect.grow(200.0).has_point(car_pos):
		_crowd_cd = 2.5
		crowd.cheer(car_pos)
	if motor.playing:
		motor.pitch_scale = lerpf(motor.pitch_scale, (1.0 + 0.35 * boost) * (1.12 if form == LAND else 1.0) * (1.0 - absf(turn) * 0.05), minf(1.0, delta * 5.0))
	if progress >= course.count * lap and lap <= LAPS:
		lap += 1
		if lap > LAPS:
			_finish()
			return
		_show_banner("LAP %d" % lap if lap < LAPS else "FINAL LAP!", 0.7)
		_sfx("res://sounds/fx/gamecoin.wav", -10.0)
		for p in pads:
			p["lap"] = 0
	_refresh_hud()

## The nearest point, searched near the last one; progress counts the points passed (driving the
## wrong way takes it back)
func _find_near() -> void:
	var best := near
	var best_d := car_pos.distance_squared_to(course.centre[near])
	for o in range(-40, 41):
		var j := posmod(near + o, course.count)
		var d := car_pos.distance_squared_to(course.centre[j])
		if d < best_d:
			best_d = d
			best = j
	var stp := best - near
	if stp > course.count / 2:
		stp -= course.count
	elif stp < -course.count / 2:
		stp += course.count
	progress += stp
	near = best

## The lane's edges: on land the magnetic walls (you stick to them and slow down, never fall off):
## pushed back in, the way into the wall taken off its speed, sparks, a soft buzz. On the water
## the bank past the shallows, in the air the lane's edge: a crash (returned: "shore" / "air")
func _walls(_delta: float) -> String:
	var n := course.normal(near)
	var lat := (car_pos - course.centre[near]).dot(n)
	if form != LAND and tf_t <= 0.0 and hop_t <= 0.0 and _grace_t <= 0.0:
		if form == SEA and absf(lat) > course.half_w + SHORE_AT:
			return "shore"
		if form == AIR and absf(lat) > course.half_w * AIR_EDGE + AIR_OUT:
			if bump_t > 0.2 or spin_t > 0.0:
				# (just knocked by something in the way: the edge holds it in, one penalty is enough)
				car_pos -= n * signf(lat) * (absf(lat) - course.half_w * AIR_EDGE - AIR_OUT)
				vel -= n * signf(lat) * maxf(0.0, vel.dot(n * signf(lat)))
				return ""
			return "air"
	if form != LAND:
		return ""
	var lim := course.half_w - WALL_IN
	if absf(lat) <= lim:
		return ""
	var out := n * signf(lat)
	car_pos -= out * (absf(lat) - lim)
	var into := vel.dot(out)
	if into > 0.0:
		vel -= out * into * 1.15
	if wall_t <= 0.0 and into > 160.0:
		shake = maxf(shake, 0.15)
	wall_t = 0.25
	drift_ang = 0.0
	drift_level = 0
	if _sfx_cd <= 0.0:
		_sfx_cd = 0.18
		_sfx("res://sounds/fx/water_boing.wav" if form == SEA else "res://sounds/fx/wood_tap.wav", -14.0, 1.4 if form != SEA else 1.1)
		Input.vibrate_handheld(12)
	trail.sparks(car_pos + out * 26.0 - Vector2(0, car_h), heading, 2, ACCENTS[world_no])
	return ""

## A crash (the bank, out of the air lane): a heart breaks (a splashy pal's water heart first: that
## one undoes it on the spot) and the crowd near it screams; the jet ski runs up onto the bank and
## stops, the rocket spins down into the depth; then it's back on the last checkpoint (the clock
## goes on). The last heart: out (retry from the start)
func _crash(kind: String) -> void:
	if not splash_used and PetState.boost_power("splash") > 0:
		splash_used = true
		PetState.use_boost()
		spend_water_heart()
		car_pos = course.centre[near]
		heading = course.direction(near).angle()
		vel = Vector2.from_angle(heading) * speed * 0.6
		_grace_t = 1.0
		trail.spray(car_pos, heading, 14)
		_sfx("res://sounds/fx/water_boing.wav", -8.0)
		_show_banner("splash!", 0.5)
		Input.vibrate_handheld(40)
		return
	falls += 1
	var last := lose_life()
	if qa_autopilot:
		print("QA crash %d: %s at %.1f s near %d/%d lat %.0f speed %.0f gates %s straight %s" % [level, kind, race_time, near, course.count, (car_pos - course.centre[near]).dot(course.normal(near)), speed, str(course.gates.map(func(g): return [g["i"], g["from"], g["to"]])), course.straight(near, 6, 6)])
	if crowd.visible:
		crowd.scream(car_pos)
	state = State.FALL
	motor.stop()
	drift_ang = 0.0
	drift_level = 0
	boost = 0.0
	chain = 0
	Input.vibrate_handheld(80)
	var from := car_pos
	var out := (car_pos - course.centre[near]).normalized()
	var h0 := heading
	var t := create_tween()
	if kind == "shore":
		_sfx("res://sounds/fx/wood_tap.wav", -6.0, 0.5)
		_sfx("res://sounds/fx/rc_land.wav", -10.0, 0.8)
		trail.spray(car_pos, heading, 10)
		t.tween_method(func(f: float):
			car_pos = from + out * 30.0 * (1.0 - pow(1.0 - minf(1.0, f * 3.0), 2.0))
			heading = h0 + sin(f * TAU * 2.0) * 0.35 * (1.0 - f)
			craft.modulate = Color(1, 1, 1).lerp(Color(1, 1, 1, 0.0), maxf(0.0, f - 0.6) / 0.4), 0.0, 1.0, 0.75)
	else:
		_sfx("res://sounds/fx/sfx_sounds_falling4.wav", -10.0)
		var h1 := car_h
		t.tween_method(func(f: float):
			heading = h0 + f * TAU * 2.0
			car_h = h1 - f * f * 150.0
			craft.modulate = Color(1, 1, 1).lerp(Color(0.5, 0.5, 0.6, 0.0), f * f)
			craft.scale = Vector2.ONE * (1.0 - 0.6 * f), 0.0, 1.0, 0.8)
	t.tween_interval(0.35)
	t.tween_callback(_out_of_lives if last else _respawn)

## Back on the last checkpoint, in that stretch's form, pointing down the course, blinking
func _respawn() -> void:
	var i := int(fposmod(last_cp, course.count))
	car_pos = course.centre[i]
	heading = course.direction(i).angle()
	speed = SPEED[course.kind_at(i)] * 0.5
	vel = Vector2.from_angle(heading) * speed
	near = i
	progress = last_cp
	form = course.kind_at(i)
	tf_t = 0.0
	hop_t = 0.0
	_set_form(form, 1.0)
	car_h = AIR_H if form == AIR else 0.0
	craft.modulate = Color(1, 1, 1)
	craft.scale = Vector2.ONE
	trail.marks.clear()
	held = [false, false]
	_grace_t = 1.2
	state = State.DRIVE
	motor.play()
	var blink := create_tween()
	for k in 3:
		blink.tween_property(craft, "modulate:a", 0.25, 0.08)
		blink.tween_property(craft, "modulate:a", 1.0, 0.08)

## The last heart broke: the race is over (its result card: Out of lives!, retry from the start)
func _out_of_lives() -> void:
	state = State.DONE
	motor.stop()
	if qa_autopilot:
		print("QA race %d (%s) OUT OF LIVES at %.1f lap %d" % [level, WORLDS[world_no], race_time, lap])
	_show_banner("Out of lives!", 0.9)
	_sfx("res://sounds/fx/error.mp3", -10.0)
	get_tree().create_timer(1.4).timeout.connect(func():
		if is_running:
			finish_level(level, 0, race_time))

func fail_title() -> String:
	return "Out of lives!"

## A life on the HUD: a little turbo craft, red when it's there, blue for the splashy pal's extra,
## a faded grey one lost (13 x 11 px, outlined like the hearts)
const LIFE_ROWS := [
	"....####.....",
	"...#llll#....",
	"..#lmmmmm##..",
	"#####mmmmmm#.",
	"#ll#ggmmmmmd#",
	"#mm#ggmmmmmd#",
	"#####mmmmmd#.",
	"..#mmmmmdd#..",
	"...#dddd#....",
	"....####.....",
	".............",
]
var _life_icons := {}
func life_icon(kind: String) -> Texture2D:
	if _life_icons.has(kind):
		return _life_icons[kind]
	var tone: Array = {
		"full": [Color8(255, 150, 130), Color8(226, 70, 64), Color8(170, 44, 48)],
		"water": [Color8(214, 240, 255), Color8(110, 178, 236), Color8(56, 116, 196)],
		"empty": [UiArt.EMPTY.lightened(0.12), UiArt.EMPTY, UiArt.EMPTY_DARK],
	}[kind]
	var tex := PalPrix2Art.rows_texture(LIFE_ROWS, { "#": UiArt.OUTLINE, "l": tone[0], "m": tone[1], "d": tone[2],
		"g": Color8(150, 230, 255) if kind != "empty" else UiArt.EMPTY.lightened(0.2) })
	_life_icons[kind] = tex
	return tex

## The drift boost: holding one button through a long bend charges it (blue, orange, pink sparks
## off its back), letting go fires it. A wall breaks it.
func _drift(turn: float, rate: float, delta: float) -> void:
	var held_dir := signf(turn) if absf(turn) >= 0.45 else 0.0
	if held_dir != 0.0 and held_dir == drift_dir and hop_t <= 0.0 and tf_t <= 0.0:
		drift_ang += absf(turn) * rate * delta
	else:
		if drift_level > 0:
			_add_boost(DRIFT_BOOST[drift_level - 1], false)
			# (no word: the user found DRIFT / PERFECT pop-ups annoying; the sparks, the burst and the sound say it)
			_sfx("res://sounds/fx/rc_boost.wav", -10.0, 1.1 + 0.1 * drift_level)
		drift_ang = 0.0
		drift_dir = held_dir
	var lv := 0
	for s in DRIFT_STEPS.size():
		if drift_ang >= DRIFT_STEPS[s]:
			lv = s + 1
	if lv > drift_level:
		Input.vibrate_handheld(8)
	drift_level = lv

func _add_boost(amount: float, chained: bool) -> void:
	boost = minf(BOOST_MAX, maxf(boost, amount) + 0.08)
	shake = maxf(shake, 0.25 + amount * 0.4)
	if chained:
		chain += 1

## The gates: crossing one, the craft turns into the next form
func _transforms(was: float, _delta: float) -> void:
	for g in course.gates:
		var gi := float(g["i"])
		var c := course.count
		if floorf((progress - gi) / c) > floorf((was - gi) / c):
			_transform(g)
		elif floorf((progress - gi) / c) < floorf((was - gi) / c) and tf_t <= 0.0:
			# (turned round and back through a gate: the form it had before it, no fanfare)
			form = int(g["from"])
			_set_form(form, 1.0)

func _transform(g: Dictionary) -> void:
	var i := int(g["i"])
	tf_from = int(g["from"])
	tf_to = int(g["to"])
	var lat := (car_pos - course.centre[i]).dot(course.normal(i))
	var straight_on := absf(wrapf(heading - course.direction(i).angle(), -PI, PI)) < 0.38
	var perfect := absf(lat) < course.half_w * 0.34 and straight_on
	tf_t = TF_TIME
	slow_t = TF_SLOW_REAL + (0.25 if PetState.boost_power("focus") > 0 else 0.0)
	punch = 1.16
	shake = 0.35
	if g.has("node") and is_instance_valid(g["node"]):
		(g["node"] as PalPrix2Fx.Gate).flash = 1.0
	trail.puff(car_pos - Vector2(0, car_h))
	match tf_to:
		SEA:
			trail.splash(car_pos)
			_sfx("res://sounds/fx/water_boing.wav", -6.0, 0.7)
			pops.say("SPLASHDOWN!" if tf_from == AIR else "SPLASH!", car_pos + Vector2(0, -90), Color8(140, 230, 255))
		AIR:
			_sfx("res://sounds/fx/rc_boost.wav", -6.0, 0.7)
			pops.say("LIFT OFF!", car_pos + Vector2(0, -90), Color8(255, 150, 230))
		_:
			trail.sparks(car_pos, heading, 10, Color8(255, 220, 120))
			_sfx("res://sounds/fx/rc_land.wav", -8.0, 1.2)
			pops.say("TOUCHDOWN!" if tf_from == AIR else "ROLL OUT!", car_pos + Vector2(0, -90), Color8(255, 224, 102))
	_sfx("res://sounds/fx/sticker_peel.wav", -12.0, 1.6)
	Input.vibrate_handheld(50)
	if perfect:
		_add_boost(PERFECT_BOOST, true)
		_sfx("res://sounds/fx/ring_chime.wav", -10.0, 1.2)
	else:
		_add_boost(GATE_BOOST, false)
		chain = 0
	_passed_gates += 1

## The transform playing out: the spin (in _place_craft), the parts folding away and the new
## ones unfolding (the swap at the middle, hidden in the puff), the height to its new place
func _update_transform(delta: float) -> void:
	if tf_t <= 0.0:
		return
	tf_t = maxf(0.0, tf_t - delta)
	var f := 1.0 - tf_t / TF_TIME
	if f < 0.5:
		_set_form(tf_from, snappedf(1.0 - f * 1.6, 0.25))
	else:
		form = tf_to
		_set_form(tf_to, clampf(snappedf((f - 0.5) * 2.2, 0.25), 0.25, 1.0))
	var h0 := AIR_H if tf_from == AIR else 0.0
	var h1 := AIR_H if tf_to == AIR else 0.0
	car_h = lerpf(h0, h1, f * f * (3.0 - 2.0 * f)) + sin(f * PI) * 26.0
	if tf_t <= 0.0:
		form = tf_to
		_set_form(form, 1.0)

## Plates, currents, rings: taken (a boost, the chain grows), or passed by (the chain breaks)
func _pads(was: float) -> void:
	var c := course.count
	for p in pads:
		if int(p["lap"]) == lap:
			continue
		var i := int(p["i"])
		var lat := (car_pos - course.centre[near]).dot(course.normal(near))
		var a := float(posmod(near - i + c / 2, c) - c / 2)
		var hit := false
		match int(p["kind"]):
			AIR:
				# a ring: judged as it's flown through
				if floorf((progress - i) / c) > floorf((was - i) / c):
					p["lap"] = lap
					if absf(lat - float(p["lat"])) < float(p["w"]) * 0.86:
						hit = true
					else:
						chain = 0
						continue
			_:
				if absf(a) <= float(p["half"]) and absf(lat - float(p["lat"])) < float(p["w"]) and hop_t <= 0.0:
					p["lap"] = lap
					hit = true
				elif a > float(p["half"]) and a < float(p["half"]) + 6.0:
					p["lap"] = lap
					chain = 0
					continue
		if hit:
			var amount := PAD_BOOST + CHAIN_STEP * mini(chain, 5) + (0.15 if p["sling"] else 0.0)
			_add_boost(amount, true)
			_sfx("res://sounds/fx/rc_boost.wav", -9.0, 1.0 + 0.06 * mini(chain, 6))
			if int(p["kind"]) == AIR:
				_sfx("res://sounds/fx/ring_chime.wav", -11.0, 1.0 + 0.08 * mini(chain, 6))
				for rg in p.get("rings", []):
					(rg as PalPrix2Fx.Ring).state = 2
					var tw := (rg as Node2D).create_tween()
					tw.tween_property(rg, "scale", Vector2(1.3, 1.3), 0.3)
					tw.parallel().tween_property(rg, "modulate:a", 0.0, 0.3)
					tw.tween_interval(1.5)
					tw.tween_callback(func():
						(rg as PalPrix2Fx.Ring).state = 0
						(rg as Node2D).scale = Vector2.ONE)
					tw.tween_property(rg, "modulate:a", 1.0, 0.4)
			Input.vibrate_handheld(25)
			if chain >= 2:
				pops.say("x%d" % chain, car_pos + Vector2(0, -90 - car_h), Color8(255, 214, 90))
			if p["sling"]:
				pops.say("SLINGSHOT!", car_pos + Vector2(0, -120 - car_h), Color8(255, 224, 102), 34)

## Off a ramp (a gap between roofs) or a waterfall step: up in the air, the shadow falling away;
## taken straight, a boost on landing
var _fizzy_hop := false
func _jumps(was_near: int) -> void:
	if hop_t > 0.0 or tf_t > 0.0:
		return
	for j in jumps:
		var a := int(j["a"])
		if posmod(a - was_near, course.count) <= 2 and posmod(near - a, course.count) < 8 and near != was_near:
			var road := course.direction(near).angle()
			var lat := (car_pos - course.centre[near]).dot(course.normal(near))
			hop_good = absf(wrapf(heading - road, -PI, PI)) < 0.4 and absf(lat) < course.half_w * 0.6
			var gap_len := float(int(j["b"]) - a) * STEP + 120.0
			hop_len = maxf(HOP_TIME, gap_len / maxf(speed, 400.0))
			_fizzy_hop = secret.get("gate", "") == "fizzy" and gate_open("fizzy", int(secret.get("lvl", 1))) and not secret.get("taken", true) and int(secret.get("at", -1000)) > a and int(secret.get("at", -1000)) - a < 30
			if _fizzy_hop:
				hop_len *= 1.5
			hop_t = hop_len
			_sfx("res://sounds/fx/water_boing.wav", -12.0, 1.4)
			Input.vibrate_handheld(20)
			return

func _land_hop() -> void:
	car_h = 0.0
	_sfx("res://sounds/fx/rc_land.wav", -12.0)
	Input.vibrate_handheld(25)
	if form == SEA:
		trail.splash(car_pos)
	else:
		trail.sparks(car_pos, heading, 6, Color8(255, 220, 120))
	if hop_good:
		_add_boost(HOP_BOOST, true)
		pops.say("NICE!", car_pos + Vector2(0, -90), Color8(255, 255, 255))

## Things in the way: a bump, spun round, slowed (a sturdy craft only slows); the crowd screams
## if it's near
func _bumps() -> void:
	if spin_t > 0.0 or hop_t > 0.0 or tf_t > 0.0:
		return
	for ob in obstacles:
		var reach := float(ob["r"]) + CRAFT_R
		var to: Vector2 = car_pos - (ob["pos"] as Vector2)
		if to.length() < reach:
			var away := to.normalized() if to.length() > 0.1 else Vector2.RIGHT
			car_pos = (ob["pos"] as Vector2) + away * reach
			vel = vel.bounce(away) * 0.5 if vel.dot(away) < 0.0 else vel * 0.5
			bump_t = 1.0
			boost = 0.0
			chain = 0
			bumps += 1
			if PetState.boost_power("sturdy") <= 0:
				spin_t = 0.5
			shake = 0.6
			_sfx("res://sounds/fx/wood_tap.wav", -6.0, 0.6)
			_sfx("res://sounds/fx/rc_fall.wav", -12.0, 1.3)
			Input.vibrate_handheld(60)
			pops.say("BONK!", car_pos + Vector2(0, -90), Color8(255, 120, 100))
			if crowd.visible:
				crowd.scream(car_pos)
			if qa_autopilot:
				print("QA bump %d: %s at %.1f s" % [level, ob["kind"], race_time])
			return

## The slipstream: tucked in behind a rival a moment, the air pulls you along (streaks wrap round
## you); pull out of it and you slingshot past
func _slipstream(delta: float) -> void:
	var behind := false
	var dir := Vector2.from_angle(heading)
	for r in rivals:
		if r["done"] or int(r["kind"]) != form:
			continue
		var to: Vector2 = (r["pos"] as Vector2) - car_pos
		var along := to.dot(dir)
		if along > 50.0 and along < 280.0 and absf(to.cross(dir)) < 50.0:
			behind = true
	if behind:
		slip_charge = minf(slip_charge + delta, 1.5)
		if slip_charge >= SLIP_NEED and randf() < delta * 30.0:
			trail.contrail(car_pos + dir * 30.0, heading, Color(1, 1, 1))
	else:
		if slip_charge >= SLIP_NEED:
			_add_boost(SLIP_BOOST, false)
			pops.say("SLINGSHOT!", car_pos + Vector2(0, -90 - car_h), Color8(200, 240, 255))
			_sfx("res://sounds/fx/rc_boost.wav", -8.0, 1.3)
		slip_charge = 0.0

## The craft's trails: light ribbons from its jets, drift sparks, the jet ski's wake and spray,
## the rocket's contrails
func _fx(delta: float) -> void:
	_update_transform(delta)
	var p := car_pos - Vector2(0, car_h)
	match form:
		LAND:
			trail.ribbon(p, heading, 36.0, ACCENTS[world_no] if boost < 0.2 else Color8(255, 255, 255))
		SEA:
			if car_h < 8.0:
				trail.wake(car_pos, heading)
				if randf() < delta * (12.0 + 30.0 * boost):
					trail.spray(car_pos, heading, 1)
		AIR:
			trail.contrail(p, heading, Color(1, 1, 1))
	if drift_level > 0 and randf() < delta * 40.0:
		if form == SEA:
			trail.spray(car_pos, heading, 2, 1.3)
		trail.sparks(p, heading, 1, DRIFT_COLS[drift_level - 1])

# ================================================================== THINGS MOVING

func _update_things(delta: float) -> void:
	for ob in obstacles:
		if not ob.has("node") or not is_instance_valid(ob["node"]):
			continue
		var spr: Sprite2D = ob["node"]
		match String(ob["kind"]):
			"asteroids":
				# drifting slowly across the lane and back, turning
				ob["pos"] = (ob["base"] as Vector2) + course.normal(int(ob["i"])) * sin(_t * 0.5 + float(ob["k"])) * 40.0
				spr.position = (ob["pos"] as Vector2).round()
				spr.rotation = snappedf(_t * (0.4 + 0.1 * float(int(ob["k"]) % 3)), PI / 8.0)
			"bergs":
				spr.position = ((ob["base"] as Vector2) + Vector2(0, sin(_t * 1.2 + float(ob["k"])) * 4.0)).round()

# ================================================================== THE AUTOPILOT (QA)

## QA only: a careful driver (like a player: a button or none): at the course a little ahead, on
## the line through the next plate, round whatever is coming up, through the gates' middles
func _autopilot() -> float:
	var ahead := 16
	var ai := (near + ahead) % course.count
	var aim := course.centre[ai]
	var lat := 0.0
	var first := 1 << 20
	for p in pads:
		var di := posmod(int(p["i"]) - near, course.count)
		if di > 0 and di < 60 and di < first and int(p["lap"]) != lap:
			first = di
			lat = float(p["lat"])
	for ob in obstacles:
		var oi := int(ob["i"])
		var di2 := posmod(oi - near, course.count)
		if di2 > 0 and di2 < 70 and di2 <= first + 10:
			first = di2
			var ob_lat := ((ob["pos"] as Vector2) - course.centre[oi]).dot(course.normal(oi))
			lat = ob_lat - signf(ob_lat if ob_lat != 0.0 else 1.0) * (float(ob["r"]) + CRAFT_R + 40.0)
	for w in wells:
		var to_w: Vector2 = (w["pos"] as Vector2) - car_pos
		if to_w.length() < float(w["r"]) + 200.0:
			lat -= signf(to_w.dot(course.normal(near))) * 90.0      # (leaning away from its pull)
	for g in course.gates:
		var dg := posmod(int(g["i"]) - near, course.count)
		if dg > 0 and dg < 40:
			lat = 0.0
	var limit := course.half_w - (SHALLOW_IN + 40.0 if form == SEA else WALL_IN + 20.0)
	aim += course.normal(ai) * clampf(lat, -limit, limit)
	var want := (aim - car_pos).angle()
	if form == SEA:
		want -= wrapf(vel.angle() - heading, -PI, PI) * 0.6
	var diff := wrapf(want - heading, -PI, PI)
	if absf(diff) < 0.06:
		return 0.0
	return signf(diff)

## QA only (tools/qa/shoot.sh ... at=jump): the race starts a little before the first of this
## level's things of that kind (jump, step, pad, ring, rock, berg, asteroid, well, sling, gust,
## gate, secret), so a screenshot shows it
func _qa_start_at() -> void:
	var want := ""
	for a in OS.get_cmdline_user_args():
		if a.begins_with("at="):
			want = a.substr(3)
	if want == "":
		return
	var at := -1
	match want:
		"jump", "step":
			for j in jumps:
				if (j["kind"] == LAND) == (want == "jump"):
					at = int(j["a"])
					break
		"pad", "ring", "sling":
			for p in pads:
				if (want == "pad" and p["kind"] != AIR) or (want == "ring" and p["kind"] == AIR and not p["sling"]) or (want == "sling" and p["sling"]):
					at = int(p["i"])
					break
		"rock", "berg", "asteroid":
			for ob in obstacles:
				if String(ob["kind"]).begins_with(want):
					at = int(ob["i"])
					break
		"well":
			if not wells.is_empty():
				at = int(wells[0]["i"])
		"gust":
			if not gusts.is_empty():
				at = int(gusts[0][0]) + 10
		"gate":
			if not course.gates.is_empty():
				at = int(course.gates[0]["i"])
		"gate2":
			if course.gates.size() > 1:
				at = int(course.gates[1]["i"])
		"secret":
			at = int(secret.get("at", -1))
		_:
			if want.is_valid_int():
				at = int(want)
	if at < 0:
		print("QA at=%s: none on level %d" % [want, level])
		return
	var i := posmod(at - 110, course.count)
	car_pos = course.centre[i]
	heading = course.direction(i).angle()
	near = i
	progress = float(i)
	form = course.kind_at(i)
	_set_form(form, 1.0)
	car_h = AIR_H if form == AIR else 0.0
	cam = car_pos

# ================================================================== FINISH

func _finish() -> void:
	state = State.DONE
	crowd.party = true
	motor.stop()
	var stars := _stars_now()
	if qa_autopilot:
		print("QA race %d (%s) stars %d time %.1f par %.0f turbo %.0f bumps %d place %d" % [level, WORLDS[world_no], stars, race_time, par, turbo, bumps, place])
	_show_banner("FINISH!", 1.0)
	_sfx("res://sounds/fx/unlock_ding.wav", -8.0)
	Input.vibrate_handheld(60)
	_refresh_hud()
	get_tree().create_timer(1.4).timeout.connect(func():
		if is_running:
			finish_level(level, stars, race_time))

# ================================================================== RIVALS

## The rivals on the grid behind the line: the same craft in their colours, a helmeted driver,
## an antenna like yours; each a driver of its own tier (one: average; two: rookie, ace; three:
## one of each); they transform at the gates like you
func _spawn_rivals() -> void:
	for r in rivals:
		(r["node"] as Node).queue_free()
	rivals.clear()
	_rival_things.clear()
	for ob in obstacles:
		var oi := int(ob["i"])
		var lat := ((ob["pos"] as Vector2) - course.centre[oi]).dot(course.normal(oi)) / course.half_w
		_rival_things.append([oi, lat, (float(ob["r"]) + 50.0) / course.half_w, ob["pos"], float(ob["r"]) + 24.0])
	var n := int(extras.get("rivals", 0))
	var k := (level - 1) % GameData.LEVELS_PER_WORLD
	for j in n:
		var node := Node2D.new()
		front.add_child(node)
		front.move_child(node, 0)
		var sl: Array = []
		for li in PalPrix2Art.LAYERS:
			var spr := Sprite2D.new()
			spr.scale = Vector2(PX, PX)
			spr.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
			node.add_child(spr)
			sl.append(spr)
		var helmet := _px_sprite(_helmet_texture(PalPrix2Art.BODY_COLS[RIVAL_COLS[j]][0]), Vector2.ZERO, 2)
		node.add_child(helmet)
		var cab := _px_sprite(PalPrix2Art.canopy(), Vector2.ZERO)
		node.add_child(cab)
		var ant := Line2D.new()
		ant.width = 4.0
		ant.default_color = Color8(40, 30, 40)
		ant.antialiased = false
		node.add_child(ant)
		var ant_tip := _px_sprite(antenna_tip.texture, Vector2.ZERO)
		ant_tip.modulate = (PalPrix2Art.BODY_COLS[RIVAL_COLS[j]][0] as Color).lightened(0.3)
		node.add_child(ant_tip)
		var lane: float = [-0.42, 0.42, 0.0][j]
		var tier: int = [[1], [0, 2], [0, 1, 2]][clampi(n, 1, 3) - 1][j]
		var tr: Dictionary = RIVAL_TIERS[tier]
		rivals.append({ "node": node, "slices": sl, "helmet": helmet, "ant": ant, "ant_tip": ant_tip, "col": RIVAL_COLS[j],
			"progress": -float(8 + j * 7), "lane": lane, "lane_now": lane, "tier": tier, "speed_k": float(tr["speed"]) * (1.0 + 0.004 * k),
			"heading": 0.0, "pos": Vector2.ZERO, "done": false, "kind": -1, "dodge": {}, "spin": 0.0, "cab": cab, "phase": randf() * TAU,
			"wander_hz": randf_range(0.25, 0.5), "slip_t": 0.0, "react": float(tr["react"]) + randf_range(0.0, 0.15),
			"next_slip": randf_range(float(tr["slip_every"]) * 0.5, float(tr["slip_every"]) * 1.5), "h": 0.0, "v": 0.0 })
	_place_rivals()

func _place_rivals() -> void:
	var c := course.count
	for r in rivals:
		var pr: float = r["progress"]
		var i := int(floorf(pr))
		var f := pr - i
		var a := course.centre[posmod(i, c)]
		var b := course.centre[posmod(i + 1, c)]
		var dir := (b - a).normalized()
		var kind := course.kind_at(posmod(i, c))
		var p := a.lerp(b, f) + Vector2(-dir.y, dir.x) * course.half_w * float(r["lane_now"])
		r["pos"] = p
		if int(r["kind"]) != kind:
			if int(r["kind"]) >= 0:
				trail.puff(p - Vector2(0, float(r["h"])), 8)
			r["kind"] = kind
			var layers := PalPrix2Art.slices(FORM_NAMES[kind], r["col"])
			for li in layers.size():
				(r["slices"][li] as Sprite2D).texture = layers[li]
		r["h"] = move_toward(float(r["h"]), AIR_H if kind == AIR else 0.0, 4.0)
		var hd := lerp_angle(float(r["heading"]), dir.angle(), 0.2)
		r["heading"] = hd
		var node: Node2D = r["node"]
		node.position = (p - Vector2(0, float(r["h"]))).round()
		var spin_a := 0.0
		if float(r["spin"]) > 0.0:
			spin_a = (1.0 - float(r["spin"]) / 0.5) * TAU
		var n_sl: int = r["slices"].size()
		for li in n_sl:
			var spr: Sprite2D = r["slices"][li]
			spr.rotation = hd + spin_a
			spr.position = Vector2(0, -li * LAYER_UP).round()
		(r["helmet"] as Sprite2D).position = Vector2.from_angle(hd + spin_a) * PalPrix2Art.SEAT * PX + Vector2(0, -n_sl * LAYER_UP - 4.0)
		(r["cab"] as Sprite2D).position = (Vector2.from_angle(hd + spin_a) * (PalPrix2Art.SEAT + 1.5) * PX + Vector2(0, -n_sl * LAYER_UP - 2.0)).round()
		(r["cab"] as Sprite2D).rotation = hd + spin_a
		var corner := Vector2(-44, -24)
		var base := corner.rotated(hd + spin_a) + Vector2(0, -n_sl * LAYER_UP)
		var top := base + Vector2(0, -46) + Vector2.from_angle(hd) * -12.0
		(r["ant"] as Line2D).points = PackedVector2Array([base.round(), base.lerp(top, 0.5).round(), top.round()])
		(r["ant_tip"] as Sprite2D).position = top.round()

## The rivals drive their lanes at their pace (faster when behind you, slower well ahead: close
## races), slower in the bends, wandering, making mistakes, steering round things (or hitting
## them like you); they shove you a little; your place
func _update_rivals(delta: float) -> void:
	if rivals.is_empty():
		return
	var c := course.count
	var ahead := 0
	for r in rivals:
		var tr: Dictionary = RIVAL_TIERS[int(r["tier"])]
		if not r["done"] and race_time >= float(r["react"]):
			var gap: float = float(r["progress"]) - progress
			var k := 1.0
			if gap > c * 0.12:
				k = 0.92
			elif gap < -c * 0.12:
				k = 1.06
			var ri := posmod(int(r["progress"]), c)
			var bend := absf(wrapf(course.direction(ri + 7).angle() - course.direction(ri).angle(), -PI, PI))
			k *= 1.0 - float(tr["corner"]) * clampf(bend, 0.0, 1.0)
			if float(tr["slip_every"]) > 0.0:
				r["next_slip"] = float(r["next_slip"]) - delta
				if float(r["next_slip"]) <= 0.0:
					r["slip_t"] = 0.8
					r["next_slip"] = randf_range(float(tr["slip_every"]) * 0.6, float(tr["slip_every"]) * 1.4)
			if float(r["slip_t"]) > 0.0:
				r["slip_t"] = float(r["slip_t"]) - delta
				k *= 0.55
			if float(r["spin"]) > 0.0:
				k *= 0.45
			var v: float = float(SPEED[course.kind_at(ri)]) * float(r["speed_k"]) * k
			r["v"] = lerpf(float(r["v"]), v, minf(1.0, delta * 2.0))
			r["progress"] = float(r["progress"]) + float(r["v"]) * delta / STEP
			if float(r["progress"]) >= c * LAPS:
				r["done"] = true
				var fade := (r["node"] as Node2D).create_tween()
				fade.tween_interval(0.6)
				fade.tween_property(r["node"], "modulate:a", 0.0, 0.5)
		var wob := sin(race_time * TAU * float(r["wander_hz"]) + float(r["phase"])) * float(tr["wander"])
		var want := float(r["lane"]) + wob
		var rp := float(r["progress"])
		for oi in _rival_things.size():
			var th: Array = _rival_things[oi]
			var ahead_pts := posmod(int(th[0]) - posmod(int(rp), c), c)
			if ahead_pts > 0 and ahead_pts < 40:
				if not (r["dodge"] as Dictionary).has(oi):
					r["dodge"][oi] = randf() < float(tr["dodge"])
				if r["dodge"][oi]:
					want = float(th[1]) - signf(float(th[1]) if float(th[1]) != 0.0 else 1.0) * float(th[2])
		r["lane_now"] = lerpf(float(r["lane_now"]), clampf(want, -0.62, 0.62), minf(1.0, delta * 4.0))
		if not r["done"] and float(r["spin"]) <= 0.0:
			for oi2 in _rival_things.size():
				var th2: Array = _rival_things[oi2]
				if (r["pos"] as Vector2).distance_to(th2[3]) < float(th2[4]):
					r["spin"] = 0.5
					r["dodge"].erase(oi2)
					break
		if float(r["spin"]) > 0.0:
			r["spin"] = float(r["spin"]) - delta
		if float(r["progress"]) > progress:
			ahead += 1
		# a shove (on the ground and the water; a sturdy craft isn't moved)
		var d: Vector2 = car_pos - (r["pos"] as Vector2)
		if form != AIR and not r["done"] and d.length() < 52.0 and d.length() > 0.1 and int(r["kind"]) == form:
			var push := d.normalized() * (52.0 - d.length())
			if PetState.boost_power("sturdy") <= 0:
				car_pos += push * 0.8
				if _sfx_cd <= 0.0:
					_sfx_cd = 0.3
					_sfx("res://sounds/fx/wood_tap.wav", -10.0, 0.9)
					Input.vibrate_handheld(20)
	place = ahead + 1
	_place_rivals()

func _helmet_texture(c: Color) -> Texture2D:
	return PalPrix2Art.rows_texture([
		"..####..",
		".#cccc#.",
		"#cwcccc#",
		"#cccccc#",
		"#vvvvvv#",
		".#vvvv#.",
		"..####..",
	], { "#": Color8(40, 30, 40), "c": c, "w": c.lightened(0.5), "v": Color8(40, 50, 70) })

# ================================================================== THE SECRET

## A fizzy gift floating up over a waterfall step (a fizzy jet ski's jump reaches it), crates
## across the road with the gift behind them (a sturdy craft rams through), a gift only a lucky
## craft sees; the drink's sign by the lane
func _spawn_secret() -> void:
	if secret.is_empty():
		return
	var node := Node2D.new()
	things.add_child(node)
	_thing_nodes.append(node)
	secret["node"] = node
	var at: int = secret["at"]
	var dir := course.direction(at)
	var side := Vector2(-dir.y, dir.x)
	var taken: bool = secret["taken"]
	match String(secret["gate"]):
		"fizzy":
			if not taken:
				var g := Node2D.new()
				g.position = course.centre[at] + Vector2(0, -110)
				node.add_child(g)
				g.add_child(_px_sprite(Collection.prize_icon(secret["prize"]), Vector2.ZERO, 2))
				var bob := g.create_tween().set_loops()
				bob.tween_property(g, "position:y", g.position.y - 10.0, 0.7).set_trans(Tween.TRANS_SINE)
				bob.tween_property(g, "position:y", g.position.y, 0.7).set_trans(Tween.TRANS_SINE)
				secret["gift"] = g
		"milky":
			var crates: Array = []
			if not taken:
				for k in 3:
					var cr := _px_sprite(PalPrix2Art.crate(), course.centre[at] + side * (course.half_w * 0.15 + k * 40.0))
					node.add_child(cr)
					crates.append(cr)
				var g2 := _px_sprite(Collection.prize_icon(secret["prize"]), course.centre[(at + 5) % course.count] + side * course.half_w * 0.45, 2)
				node.add_child(g2)
				secret["gift"] = g2
			secret["crates"] = crates
		"fruity":
			if not taken:
				var sp := _px_sprite(PalPrix2Art.sparkle(), course.centre[at])
				node.add_child(sp)
				var tw := sp.create_tween().set_loops()
				tw.tween_property(sp, "modulate:a", 0.25, 0.5)
				tw.tween_property(sp, "modulate:a", 1.0, 0.5)
				var g3 := _px_sprite(Collection.prize_icon(secret["prize"]), course.centre[at], 2)
				g3.visible = gate_open("fruity", secret["lvl"])
				node.add_child(g3)
				secret["gift"] = g3
	var sign := _px_sprite(TiltMazeArt.sign_card(), course.centre[at] + side * (course.half_w + 50.0))
	var icon := Sprite2D.new()
	icon.texture = gate_icon(secret["gate"], secret["lvl"])
	icon.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	sign.add_child(icon)
	sign.visible = not taken
	node.add_child(sign)

func _update_secret(_was_near: int) -> void:
	if secret.is_empty() or secret["taken"]:
		return
	var lvl: int = secret["lvl"]
	var at: int = secret["at"]
	match String(secret["gate"]):
		"fizzy":
			if hop_t > 0.0 and car_h > 70.0 and car_pos.distance_to(course.centre[at]) < 90.0 and gate_open("fizzy", lvl):
				_take_secret()
			elif car_pos.distance_to(course.centre[at]) < 60.0 and not secret.get("hinted", false) and not gate_open("fizzy", lvl):
				secret["hinted"] = true
				_show_banner("fizzy crafts jump higher!", 0.8)
		"milky":
			var hit := false
			for cr in secret.get("crates", []):
				if is_instance_valid(cr) and car_pos.distance_to((cr as Sprite2D).position) < 50.0:
					hit = true
			if hit:
				if gate_open("milky", lvl):
					for cr in secret["crates"]:
						var t := (cr as Sprite2D).create_tween()
						t.tween_property(cr, "modulate:a", 0.0, 0.25)
						t.tween_callback((cr as Sprite2D).queue_free)
					secret["crates"] = []
					_sfx("res://sounds/fx/rc_fall.wav", -10.0, 0.7)
					Input.vibrate_handheld(50)
					PetState.use_boost()
					secret["broken"] = true
				elif spin_t <= 0.0:
					spin_t = 0.4
					bump_t = 1.0
					boost = 0.0
					_show_banner("sturdy crafts smash!", 0.8)
			if secret.get("broken", false) and secret.has("gift") and is_instance_valid(secret["gift"]) and car_pos.distance_to((secret["gift"] as Sprite2D).position) < 60.0:
				_take_secret()
		"fruity":
			if car_pos.distance_to(course.centre[at]) < 60.0:
				if gate_open("fruity", lvl):
					PetState.use_boost()
					_take_secret()
				elif not secret.get("hinted", false):
					secret["hinted"] = true
					_show_banner("a lucky find?", 0.8)

func _take_secret() -> void:
	secret["taken"] = true
	if secret.has("gift") and is_instance_valid(secret["gift"]):
		var g: Node2D = secret["gift"]
		var t := g.create_tween()
		t.tween_property(g, "scale", g.scale * 1.6, 0.12)
		t.tween_property(g, "scale", Vector2.ZERO, 0.2)
		t.tween_callback(g.queue_free)
	if secret.get("gate", "") == "fizzy" and PetState.boost == "fizz":
		PetState.use_boost()
	take_secret(level)

# ================================================================== INPUT

func _held(i: int) -> bool:
	if held[i] or i in _touch.values():
		return true
	if i == 0:
		return Input.is_key_pressed(KEY_LEFT) or Input.is_key_pressed(KEY_A)
	return Input.is_key_pressed(KEY_RIGHT) or Input.is_key_pressed(KEY_D)

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
	# (a long line shrinks to fit the view)
	var fs := 72
	if lcd_font:
		while fs > 40 and lcd_font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x > PLAY_WIDTH - 80:
			fs -= 4
	banner.add_theme_font_size_override("font_size", fs)
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
