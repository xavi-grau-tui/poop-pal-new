extends BaseMinigame
## Pal Prix (Pipe Dream's rework, on its card) — your pal rides a little RC car round a toy
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
## Levels (the level menu, BaseMinigame / LevelMenu): 6 worlds of 9, each with its own floor, its
## light and one new thing (alone on its first levels; from the 7th the world before's joins in):
##   1 Garden (a morning): the basics · 2 Kitchen: speed pads on the straights · 3 Sky (noon, the
##   fields far below): JUMPS, a ramp before each gap (straight on it or you fall) · 4 Lagoon
##   (sunset, over the water): CROSSOVERS, figure-8 circuits with a bridge · 5 Rain (a park):
##   PUDDLES that spin the car round (wet road, spray off the wheels) · 6 Grand Prix (night, the
##   lamps and your headlights): RIVALS, up to three cars to beat.
## OIL slicks (a spin and a stop) join from world 3's 7th level, more as the game goes on.
## Stars: 1 = finished, +1 = within the par time (Grand Prix: 1st place), +1 = never fell off.
## No points: the race's own clock and the laps say how it goes; the best time is saved.
## Drinks: a SPLASH car is put back where it fell, no time lost (once) · FIZZ: a springboard's
## jump (a secret: a gift on a balloon over the road) · FOCUS: time slows a moment as the car is
## about to fall (once) · STURDY: no spinning on oil or puddles, rivals don't shove it, it breaks
## through crates (a secret) · LUCKY: it sees the gift hidden on the road (a secret).
## Desktop: Left / Right arrows (or A / D).

const PX := 4                         # world px per board px (the games' chunky grid)
const CELL := 300.0                   # a grid square, world px (the road stays a square from itself)
const EDGE := 10                      # the mat's wooden frame, board px
const MARGIN := 24.0                  # road edge -> frame, world px
const SPEED := 580.0                  # mat px/s, always
const TURN := 6.2                     # rad/s while a button is held (a full turn in 1 s; turning
                                      # circle ~94 px, inside the circuits' 150 px corners)
const ZOOM := 1.5                     # the view, close up (board px shown 6 px)
const LOOK_AHEAD := 260.0             # the view looks this far ahead of the car (mat px)
const FALL_AT := 6.0                  # past the road's edge by this much: off the track
const TIP_OUT := 48.0                 # a falling car first tips this far out, clear of the edge
const CHECKPOINTS := 10               # per lap: where a fallen car is put back
const TRACK_SIDE := 6                 # the raised track's side face, board px (seen from the south)
const LAYERS := 6                     # the car's slices
const LAYER_UP := 2.5                 # each slice this much higher (mat px)
const LAPS := 3
const STEP := 8.0                     # centre-line points, every STEP px
const SEED_TRIES := 30
const PAR_SLACK := 1.03               # par time = a clean drive's time x this, + PAR_PLUS: the
const PAR_PLUS := 1.0                 # 2nd star only for a near-perfect run (no curbs, clean lines)
const CURB_TOUCH := 26.0              # the car's body on the curb (this close to the road's edge)...
const CURB_SLOW := 0.72               # ...slows it to this
const BOOST := 0.6                    # a boost pad: this much faster...
const BOOST_TIME := 1.4               # ...fading out over this long
const PAD_LEN := 64.0                 # a pad's length along the road (mat px)
const PAD_SAVES := 0.35               # (par: seconds a pad saves, each lap)
const COUNTDOWN := 3
## The view under the HUD (play-area px) and the HUD's band above it
const VIEW := Rect2(27, 92, 896, 830)
const HUD_BAND := Rect2(27, 26, 896, 66)

const WORLDS := ["Garden", "Kitchen", "Sky", "Lagoon", "Rain", "Grand Prix"]
## What each world brings, said on its first level
const WORLD_HINTS := ["", "speed boosts!", "jumps! ramps straight", "crossovers!", "puddles spin you!", "beat the rivals!"]
## Each world's page in the level menu
const WORLD_BACKDROPS := [Color8(150, 196, 120), Color8(196, 214, 200), Color8(170, 204, 230), Color8(232, 150, 120), Color8(120, 140, 150), Color8(44, 46, 82)]
## The circuits, 9 per world: [grid columns, rows, squares in the patch, road half-width px, a fixed
## shape or null, corners wanted, boost pads, extras]. The first ones are fixed shapes, long straights and few turns:
## an oval, an L, a U (its first hairpin); then grown patches, each level a bigger patch and more
## corners (the patch closest to that many), so the circuits get longer and twistier step by step.
## extras: "jumps" (gaps with a ramp), "oil" (slicks), "puddles", "rivals", "eight" (a figure-8:
## [loop A's width, height, loop B's width, height, notches], in squares, instead of a patch).
const LEVELS := [
	# 1 Garden: the basics
	[6, 2, 0, 100.0, [Rect2i(0, 0, 6, 2)], 0, 0],
	[6, 4, 0, 98.0, [Rect2i(0, 0, 6, 2), Rect2i(0, 2, 2, 2)], 0, 0],
	[6, 4, 0, 96.0, [Rect2i(0, 0, 6, 2), Rect2i(0, 2, 2, 2), Rect2i(4, 2, 2, 2)], 0, 0],
	[8, 4, 14, 94.0, null, 10, 0], [8, 5, 16, 90.0, null, 12, 0], [9, 5, 18, 88.0, null, 14, 0],
	[9, 6, 21, 84.0, null, 16, 0], [10, 6, 24, 80.0, null, 20, 0], [10, 7, 28, 76.0, null, 99, 0],
	# 2 Kitchen: speed boosts on the straights (a boosted car takes the next turn wider: brake by
	# turning early); it starts gentle again, an oval and an L, with pads to learn them
	[7, 2, 0, 96.0, [Rect2i(0, 0, 7, 2)], 0, 2],
	[7, 4, 0, 94.0, [Rect2i(0, 0, 7, 2), Rect2i(0, 2, 2, 2)], 0, 3],
	[8, 4, 14, 92.0, null, 10, 2], [8, 5, 16, 90.0, null, 12, 3], [9, 5, 18, 88.0, null, 14, 3],
	[9, 6, 21, 84.0, null, 16, 3], [10, 6, 24, 82.0, null, 18, 4], [10, 7, 27, 78.0, null, 20, 4],
	[11, 7, 30, 76.0, null, 99, 5],
	# 3 Sky: jumps over gaps (a ramp before each); the Kitchen's pads join from the 7th, oil too
	[7, 2, 0, 98.0, [Rect2i(0, 0, 7, 2)], 0, 0, { "jumps": 1 }],
	[7, 4, 0, 96.0, [Rect2i(0, 0, 7, 2), Rect2i(0, 2, 2, 2)], 0, 0, { "jumps": 2 }],
	[8, 4, 14, 94.0, null, 10, 0, { "jumps": 2 }], [8, 5, 16, 92.0, null, 12, 0, { "jumps": 2 }],
	[9, 5, 18, 90.0, null, 14, 0, { "jumps": 3 }], [9, 6, 21, 86.0, null, 16, 0, { "jumps": 3 }],
	[10, 6, 24, 84.0, null, 18, 2, { "jumps": 3, "oil": 1 }], [10, 7, 27, 80.0, null, 20, 2, { "jumps": 4, "oil": 1 }],
	[11, 7, 30, 78.0, null, 99, 3, { "jumps": 4, "oil": 2 }],
	# 4 Lagoon: figure-8 circuits, the road over itself on a bridge; oil, then the Sky's jumps
	[0, 0, 0, 96.0, null, 0, 0, { "eight": [2, 2, 2, 2, 0] }],
	[0, 0, 0, 94.0, null, 0, 0, { "eight": [3, 2, 2, 2, 0] }],
	[0, 0, 0, 92.0, null, 0, 0, { "eight": [3, 2, 3, 2, 0] }],
	[0, 0, 0, 90.0, null, 0, 0, { "eight": [3, 3, 3, 2, 1], "oil": 1 }],
	[0, 0, 0, 88.0, null, 0, 0, { "eight": [3, 3, 3, 3, 1], "oil": 1 }],
	[0, 0, 0, 86.0, null, 0, 1, { "eight": [4, 3, 3, 3, 2], "oil": 2 }],
	[0, 0, 0, 84.0, null, 0, 1, { "eight": [4, 3, 4, 3, 2], "oil": 2, "jumps": 1 }],
	[0, 0, 0, 82.0, null, 0, 2, { "eight": [4, 4, 4, 3, 3], "oil": 2, "jumps": 2 }],
	[0, 0, 0, 80.0, null, 0, 2, { "eight": [5, 4, 4, 4, 3], "oil": 3, "jumps": 2 }],
	# 5 Rain: puddles that spin the car (the road wet all over); the Lagoon's crossovers from the 7th
	[7, 2, 0, 96.0, [Rect2i(0, 0, 7, 2)], 0, 0, { "puddles": 2 }],
	[7, 4, 0, 94.0, [Rect2i(0, 0, 7, 2), Rect2i(0, 2, 2, 2)], 0, 0, { "puddles": 3 }],
	[8, 4, 14, 92.0, null, 10, 0, { "puddles": 3 }], [8, 5, 16, 90.0, null, 12, 1, { "puddles": 4 }],
	[9, 5, 18, 88.0, null, 14, 1, { "puddles": 4, "oil": 1 }], [9, 6, 21, 86.0, null, 16, 2, { "puddles": 5, "oil": 1 }],
	[0, 0, 0, 84.0, null, 0, 1, { "eight": [3, 3, 3, 3, 1], "puddles": 4 }],
	[0, 0, 0, 82.0, null, 0, 2, { "eight": [4, 3, 3, 3, 2], "puddles": 5, "oil": 1 }],
	[0, 0, 0, 80.0, null, 0, 2, { "eight": [4, 4, 4, 3, 3], "puddles": 6, "oil": 2, "jumps": 1 }],
	# 6 Grand Prix (the masters' world): rivals to beat, everything mixed in by the end
	[7, 2, 0, 96.0, [Rect2i(0, 0, 7, 2)], 0, 1, { "rivals": 1 }],
	[8, 4, 14, 94.0, null, 10, 1, { "rivals": 1 }],
	[8, 5, 16, 92.0, null, 12, 2, { "rivals": 2 }], [9, 5, 18, 90.0, null, 14, 2, { "rivals": 2, "oil": 1 }],
	[9, 6, 21, 88.0, null, 16, 2, { "rivals": 3, "oil": 1 }], [10, 6, 24, 86.0, null, 18, 3, { "rivals": 3, "puddles": 2, "oil": 1 }],
	[0, 0, 0, 86.0, null, 0, 2, { "eight": [4, 3, 3, 3, 2], "rivals": 3, "puddles": 2 }],
	[10, 7, 27, 84.0, null, 20, 3, { "rivals": 3, "jumps": 2, "puddles": 3, "oil": 2 }],
	[0, 0, 0, 82.0, null, 0, 3, { "eight": [5, 4, 4, 4, 3], "rivals": 3, "jumps": 2, "puddles": 3, "oil": 2 }],
]
## Secrets (a world's 6th level; BaseMinigame): a gift up on a balloon over the road (a fizzy car
## jumps the springboard to it), a gift behind a crate wall in a side bay (a sturdy car breaks
## through), a gift on the road only a lucky car sees. Finales: Phoenix Pepper (5-9), the case (6-9).
const SECRETS := {
	15: ["fizzy", "food:Battery"], 24: ["milky", "food:Moon Rock"], 33: ["fruity", "sticker:traffic_cone"],
	42: ["milky", "sticker:rubber_duck"], 51: ["fizzy", "sticker:gold_cup"],
}
const FINALES := { 45: "food:Phoenix Pepper", 54: "case:prix" }
const GAP_LEN := 120.0                # a jump's gap along the road (mat px)
const RAMP_LEN := 72.0                # the ramp before it
const AIR_TIME := 0.42                # a jump (or a springboard) in the air
const SLIP_TIME := 0.7                # oil / a puddle: the spin round and the stop
const SLICK_R := 46.0                 # an oil slick's / a puddle's size on the road

# --- the Playroom's look (the Tilt Maze rules: hard pixels, a 2 px dark outline, top-left light) ---
const CARPET := [Color8(118, 146, 176), Color8(108, 134, 164), Color8(130, 158, 188)]
const ROAD := [Color8(112, 108, 118), Color8(100, 96, 106)]
const LINE := Color8(244, 240, 226)
const CURB := [Color8(226, 70, 64), Color8(246, 242, 232)]
const OUTLINE := Color8(40, 34, 44)
const PAD := [Color8(252, 210, 64), Color8(226, 150, 40), Color8(70, 64, 78)]    # chevrons, their edge, the plate
const SIDE := [Color8(236, 150, 64), Color8(198, 110, 44), Color8(150, 78, 34)]    # the track's orange plastic side
const BLOCK := [Color8(246, 214, 92), Color8(206, 168, 60)]                          # the yellow toy blocks under it
## The track's side face per world: [lit, mid, shade, a support, its shade] (the Garden's orange plastic
## on yellow blocks; the sky's white on blue; the lagoon's wooden posts; wet grey; night's dark)
const SIDES := [
	[Color8(236, 150, 64), Color8(198, 110, 44), Color8(150, 78, 34), Color8(246, 214, 92), Color8(206, 168, 60)],
	[Color8(236, 150, 64), Color8(198, 110, 44), Color8(150, 78, 34), Color8(246, 214, 92), Color8(206, 168, 60)],
	[Color8(244, 246, 250), Color8(206, 216, 232), Color8(150, 166, 196), Color8(120, 170, 236), Color8(86, 130, 200)],
	[Color8(206, 150, 96), Color8(168, 112, 68), Color8(120, 76, 46), Color8(140, 96, 60), Color8(104, 68, 42)],
	[Color8(170, 176, 186), Color8(132, 138, 150), Color8(96, 100, 112), Color8(226, 186, 72), Color8(180, 140, 50)],
	[Color8(92, 96, 132), Color8(70, 72, 104), Color8(48, 50, 76), Color8(236, 96, 84), Color8(170, 60, 56)],
]
const MAT_EDGE := [Color8(214, 160, 100), Color8(132, 84, 48), Color8(74, 44, 32)]   # a wooden frame

enum State { WAIT, DRIVE, FALL, DONE }

var state := State.WAIT
var level := 1
var extras := {}                       # this level's extras (LEVELS' 8th column)
var gaps: Array = []                   # jumps: [first centre index of the gap, last], the ramp is before it
var slicks: Array = []                 # oil and puddles: [centre (mat px), kind "oil" / "puddle"]
var bridge_range := Vector2i(-1, -1)   # a figure-8: the centre indices on the bridge (over the other road)
var bridge: Sprite2D                   # its deck, drawn over the road below (and over the car under it)
var air_t := 0.0                       # in the air (a jump, a springboard): time left
var slip_t := 0.0                      # spinning on oil / a puddle: time left
var slip_heading := 0.0
var rivals: Array = []                 # { node, progress, speed, lane, pos, heading, slices }
var secret := {}                       # this level's secret: { gate, lvl, prize, taken, at (index), pos, node }
var splash_used := false               # the second chance (a fall undone), once a level
var focus_used := false                # the slow beat before a fall, once a level
var slow_t := 0.0                      # (focus: the slow-motion left)
var place := 1                         # the race's position (Grand Prix)
var qa_autopilot := false              # (tools/qa: the car drives itself, for screenshots)
var world_no := 0                      # which world (0 Playroom, 1 Kitchen...)
var pads: Array = []                   # boost pads: [centre (mat px), direction along the road]
var boost_t := 0.0                     # the boost left (1 = just hit a pad)
var curb_t := 0.0                      # (the rumble's ticks)
var _on_pad := false
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
var board: Sprite2D                    # the floor
var track: Sprite2D                    # the raised track, over it
var track_image: Image
var trail: Trail                       # the speed streaks behind the wheels and the exhaust puffs
var crowd: Crowd                       # the little grandstand by the finish line
var _cheer_cd := 0.0
var look_k := 0.0                      # how much the view looks ahead (0 at the start)
var behind: Node2D                     # under the track: where a car falling off its far side goes
var front: Node2D                      # over the track: the car
var canopy: Sprite2D                   # the Garden's branches over everything
var car: Node2D
var slices: Array[Sprite2D] = []       # the car, bottom slice first
var driver: Sprite2D
var shadow: Sprite2D
var car_drop := 0.0                    # how far the car has fallen (screen down, mat px)
var antenna: Line2D                    # a thin wire at the car's back, a ball on its tip
var antenna_tip: Sprite2D
var sway := 0.0                        # the antenna's lean (it swings out in the turns)
var sway_v := 0.0
var _last_heading := 0.0
var hud_lap: Label
var hud_time: Label
var hud_stars: Array[TextureRect] = []
var _lamp_nodes: Array = []
var hud_place: Label
var boost_icon: TextureRect
var rain_fx: RainFx
var headlight: Sprite2D
var banner: Label
var motor: AudioStreamPlayer
var lights: Node2D                     # the start lights over the view (3 red, then all green)
var lamps: Array[Sprite2D] = []
var hint_left: HBoxContainer           # the controls along the bottom (shown at the start)
var hint_right: HBoxContainer
var lcd_font: Font
var _stars_shown := 3

## The little grandstand by the finish line: three wooden tiers and the crowd, tiny coloured dots
## that hop when the car goes by (a wave that runs along the stand from the car), at GO, and
## all together at the finish. Drawn on the floor, beside the start straight.
class Crowd extends Node2D:
	const DOT_COLS := [Color8(236, 96, 84), Color8(250, 210, 84), Color8(110, 170, 236), Color8(250, 250, 244),
		Color8(186, 130, 226), Color8(120, 206, 130), Color8(250, 160, 190)]
	const OUTLINE := Color8(40, 34, 44)
	const TIERS := 5                      # rows of seats
	const ROW := 24.0                     # a row's depth (px)
	const BACK := 16.0                    # the awning
	var rect := Rect2()                  # the stand, mat px (axis-aligned)
	var along_x := true                  # the stand runs left-right (else up-down)
	var dots: Array = []                 # [position, colour, when it hops (s), how many hops]
	var t := 0.0
	var party := false                   # (the finish: everyone keeps bouncing)
	var away := Vector2.UP                # from the track towards the stand's back
	func setup(r: Rect2, horizontal: bool, seed_n: int, away_dir := Vector2.UP) -> void:
		rect = r
		along_x = horizontal
		away = away_dir
		dots.clear()
		party = false
		var rng := RandomNumberGenerator.new()
		rng.seed = seed_n
		var long := r.size.x if horizontal else r.size.y
		for tier in TIERS:
			var n := int((long - 36.0) / 24.0)
			for k in n:
				if rng.randf() < 0.1:
					continue                  # (a few empty seats)
				var a := 22.0 + k * 24.0 + (12.0 if tier % 2 else 0.0)
				var b := _tier_at(tier) + 12.0
				var p := r.position + (Vector2(a, b) if horizontal else Vector2(b, a))
				dots.append([p.snapped(Vector2(4, 4)), DOT_COLS[rng.randi() % DOT_COLS.size()], -10.0, 1])
		queue_redraw()
	## A wave of hops along the stand, starting from `from` (mat px)
	func cheer(from: Vector2, hops := 1) -> void:
		for d in dots:
			var dist: float = absf((d[0].x - from.x) if along_x else (d[0].y - from.y))
			d[2] = t + dist / 520.0 + randf() * 0.06
			d[3] = hops
	func _process(delta: float) -> void:
		t += delta
		if party:
			for d in dots:
				if t > d[2] + 0.36 * d[3]:
					d[2] = t + randf() * 0.25
					d[3] = 1
		queue_redraw()
	## Where a tier starts across the stand (px from its top / left): tier 0 next to the track,
	## the awning at the far side
	func _tier_at(tier: int) -> float:
		var depth := rect.size.y if along_x else rect.size.x
		var toward_neg := (away.y < 0.0) if along_x else (away.x < 0.0)   # the back is the top / left
		return (depth - ROW * (tier + 1)) if toward_neg else (ROW * tier)
	func _draw() -> void:
		if rect.size == Vector2.ZERO:
			return
		# the stand: outlined like the track (it's a toy too), three tiers stepping up away from
		# the track (the back ones lighter: higher, nearer the light), lit lips
		draw_rect(rect.grow(4), OUTLINE)
		draw_rect(rect, Color8(150, 106, 72))
		var wood := [Color8(164, 116, 76), Color8(178, 130, 86), Color8(192, 144, 96), Color8(206, 158, 108), Color8(218, 172, 120)]
		for tier in TIERS:
			var at := _tier_at(tier)
			var r: Rect2
			if along_x:
				r = Rect2(rect.position + Vector2(0, at), Vector2(rect.size.x, ROW))
			else:
				r = Rect2(rect.position + Vector2(at, 0), Vector2(ROW, rect.size.y))
			draw_rect(r, wood[tier])
			var lip := Rect2(r.position, Vector2(r.size.x, 4)) if along_x else Rect2(r.position, Vector2(4, r.size.y))
			draw_rect(lip, wood[tier].lightened(0.15))
		# the awning along the back: red and white stripes, a scalloped edge towards the crowd
		var back := BACK
		var toward_neg := (away.y < 0.0) if along_x else (away.x < 0.0)
		var aw: Rect2
		if along_x:
			aw = Rect2(Vector2(rect.position.x, rect.position.y if toward_neg else rect.end.y - back), Vector2(rect.size.x, back))
		else:
			aw = Rect2(Vector2(rect.position.x if toward_neg else rect.end.x - back, rect.position.y), Vector2(back, rect.size.y))
		var long := aw.size.x if along_x else aw.size.y
		var k := 0
		var a := 0.0
		while a < long:
			var col := Color8(226, 70, 64) if k % 2 == 0 else Color8(246, 242, 232)
			var piece := Rect2(aw.position + Vector2(a, 0), Vector2(minf(20.0, long - a), back)) if along_x else Rect2(aw.position + Vector2(0, a), Vector2(back, minf(20.0, long - a)))
			draw_rect(piece, col)
			# the scallop: each stripe ends in a little rounded tab towards the seats
			var tab := Rect2(piece.position + (Vector2(4, back if toward_neg else -4) if along_x else Vector2(back if toward_neg else -4, 4)), Vector2(12, 4) if along_x else Vector2(4, 12))
			draw_rect(tab, col)
			a += 20.0
			k += 1
		# the crowd: 16 px round dots (on the 4 px grid), a darker lower half, a shine; they hop
		# up the screen
		for d in dots:
			var u: float = (t - d[2]) / 0.36
			var up := 0.0
			if u >= 0.0 and u < float(d[3]):
				up = sin(fposmod(u, 1.0) * PI) * 20.0
			var p: Vector2 = d[0] - Vector2(0, roundf(up / 4.0) * 4.0)
			var c: Color = d[1]
			# a 20 px round dot on the 4 px grid: a darker lower half, a shine top-left
			draw_rect(Rect2(p + Vector2(-10, -6), Vector2(20, 12)), c)
			draw_rect(Rect2(p + Vector2(-6, -10), Vector2(12, 20)), c)
			draw_rect(Rect2(p + Vector2(-10, 2), Vector2(20, 4)), c.darkened(0.18))
			draw_rect(Rect2(p + Vector2(-6, 6), Vector2(12, 4)), c.darkened(0.18))
			draw_rect(Rect2(p + Vector2(-6, -6), Vector2(4, 4)), c.lightened(0.45))     # its shine


## Speed: short light streaks left on the road by the rear wheels, fading fast, and puffs from the
## exhaust; both on the 4 px grid
class Trail extends Node2D:
	var marks: Array = []             # [position, age, kind]
	var puff_t := 0.0
	const LIFE := 0.28
	func add(p: Vector2, heading: float, delta: float) -> void:
		var back := Vector2.from_angle(heading) * -34.0
		var side := Vector2.from_angle(heading + PI / 2.0) * 24.0
		marks.append([p + back + side, 0.0, 0])
		marks.append([p + back - side, 0.0, 0])
		puff_t -= delta
		if puff_t <= 0.0:
			puff_t = 0.07
			marks.append([p + back * 1.35 + side * randf_range(-0.3, 0.3), 0.0, 1])
	## Spray off the wheels (a puddle, the rain): drops flying out sideways, falling back
	func spray(p: Vector2, heading: float, n: int) -> void:
		for k in n:
			var side := Vector2.from_angle(heading + PI / 2.0) * (1.0 if k % 2 == 0 else -1.0)
			var back := Vector2.from_angle(heading) * -30.0
			marks.append([p + back + side * 22.0, 0.0, 2, side * randf_range(90, 220) + Vector2.from_angle(heading) * -randf_range(40, 120)])
	func _process(delta: float) -> void:
		for m in marks:
			m[1] += delta
			if m[2] == 2:
				m[0] += (m[3] as Vector2) * delta
		marks = marks.filter(func(m): return m[1] < (LIFE if m[2] == 0 else (0.45 if m[2] == 1 else 0.35)))
		queue_redraw()
	func _draw() -> void:
		for m in marks:
			var p: Vector2 = (m[0] as Vector2).snapped(Vector2(4, 4))
			if m[2] == 2:
				draw_rect(Rect2(p - Vector2(2, 2), Vector2(4, 4)), Color(0.8, 0.9, 1.0, 0.8 * (1.0 - m[1] / 0.35)))
			elif m[2] == 0:
				draw_rect(Rect2(p - Vector2(2, 2), Vector2(4, 4)), Color(1, 1, 1, 0.35 * (1.0 - m[1] / LIFE)))
			else:
				var f: float = m[1] / 0.45
				var sz := 4.0 + 8.0 * f
				draw_rect(Rect2(p - Vector2(sz, sz) / 2.0 + Vector2(0, -f * 10.0), Vector2(sz, sz)).abs(), Color(0.85, 0.85, 0.9, 0.5 * (1.0 - f)))

func _ready() -> void:
	game_music_path = "res://sounds/music/Pixel Chase.ogg"     # (107.22 BPM, looped on bar lines: tools/audio/loop_track.py)
	lcd_font = load("res://fonts/pixChicago.ttf")
	_create_nodes()
	intro_text = "Steer your car"
	intro_controls = [[0, "LEFT"], [1, "RIGHT"]]       # (the buttons on the card: hold one to turn)
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
	return load("res://textures/menus/pattern_trophy_terracotta.png")

func level_backdrop() -> Color:
	return WORLD_BACKDROPS[0]

func world_backdrop(w: int) -> Color:
	return WORLD_BACKDROPS[clampi(w, 0, WORLD_BACKDROPS.size() - 1)]

## The secrets as BaseMinigame secrets (the level menu shows them), the finales' prizes
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

func _begin(n: int) -> void:
	level = clampi(n, 1, LEVELS.size())
	world_no = (level - 1) / GameData.LEVELS_PER_WORLD
	var spec0: Array = LEVELS[level - 1]
	extras = spec0[7] if spec0.size() > 7 else {}
	_build_circuit()
	_place_crowd()
	_place_features()
	board.texture = ImageTexture.create_from_image(_paint())
	track.texture = ImageTexture.create_from_image(track_image)
	canopy.visible = world_no == 0 and not _trees.is_empty()
	if canopy.visible:
		canopy.texture = ImageTexture.create_from_image(_paint_canopy(int(mat_size.x / PX), int(mat_size.y / PX)))
	car_pos = centre[0]
	heading = (centre[2] - centre[0]).angle()
	near = 0
	progress = 0.0
	lap = 1
	race_time = 0.0
	falls = 0
	trail.marks.clear()
	last_cp = 0.0
	car_drop = 0.0
	held = [false, false]
	_touch.clear()
	_stars_shown = 3
	for s in hud_stars:
		s.texture = UiArt.star(true)
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
	_place_car()
	_follow(1.0)
	_refresh_hud()
	var k := (level - 1) % GameData.LEVELS_PER_WORLD
	if k == 0:
		_show_banner(WORLDS[world_no], 1.2)
		if WORLD_HINTS[world_no] != "":
			get_tree().create_timer(1.4).timeout.connect(func():
				if is_running and level == n:
					_show_banner(WORLD_HINTS[world_no], 1.2))
	else:
		_show_banner("%d-%d" % [world_no + 1, k + 1], 0.8)
	boost_t = 0.0
	curb_t = 0.0
	air_t = 0.0
	slip_t = 0.0
	slow_t = 0.0
	splash_used = false
	focus_used = false
	place = 1
	_spawn_features()

# ================================================================== THE CIRCUIT

func _build_circuit() -> void:
	var spec: Array = LEVELS[level - 1]
	half_w = spec[3]
	var pad := EDGE * PX + half_w + MARGIN
	var best: Array = []
	var best_err := 1 << 40
	if extras.has("eight"):
		best = _eight_corners(extras["eight"])
		best_err = 0
	for i in (0 if extras.has("eight") else SEED_TRIES):
		var rng := RandomNumberGenerator.new()
		rng.seed = 6151 * level + 92821 * i + 3
		var corners := _patch_outline(rng, spec[0], spec[1], spec[2], spec[4])
		# the corners wanted first, then the longest (so every level is longer than the last)
		var err: int = absi(corners.size() - spec[5]) * 100000 - _perimeter(corners)
		if err < best_err:
			best_err = err
			best = corners
		if spec[4] != null:
			break                                        # (a fixed shape: one is enough)
	# the outline's corners (grid points) -> mat px (the mat cut to the circuit), the corners
	# rounded, evenly spaced points
	var lo := Vector2i(1 << 20, 1 << 20)
	var hi := Vector2i(-(1 << 20), -(1 << 20))
	for c in best:
		lo = Vector2i(mini(lo.x, c.x), mini(lo.y, c.y))
		hi = Vector2i(maxi(hi.x, c.x), maxi(hi.y, c.y))
	mat_size = Vector2(hi - lo) * CELL + Vector2(pad, pad) * 2.0
	var pts: Array[Vector2] = []
	for c in best:
		pts.append(Vector2(c - lo) * CELL + Vector2(pad, pad))
	_cross_pos = Vector2(_cross_grid - lo) * CELL + Vector2(pad, pad)
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
	bridge_range = _find_bridge() if extras.has("eight") else Vector2i(-1, -1)
	_place_pads(spec[6])
	par = ceilf(lap_length * LAPS / SPEED * PAR_SLACK + PAR_PLUS - pads.size() * LAPS * PAD_SAVES)

## The stand beside the start straight, on whichever side has room (never near the road)
func _place_crowd() -> void:
	var dir := (centre[4] - centre[0]).normalized()
	var horizontal := absf(dir.x) > absf(dir.y)
	var normal := Vector2(-dir.y, dir.x)
	# the biggest stand that fits beside the finish line (tight circuits get a smaller one)
	for long in [440.0, 340.0, 260.0, 200.0]:
		if _try_crowd(dir, horizontal, normal, long):
			return
	crowd.visible = false

func _try_crowd(dir: Vector2, horizontal: bool, normal: Vector2, long: float) -> bool:
	var size := Vector2(long, 136) if horizontal else Vector2(136, long)
	for side in [1.0, -1.0]:
		var c: Vector2 = centre[0] + normal * side * (half_w + 30.0 + 68.0)   # (on the finish line)
		var r := Rect2(c - size / 2.0, size)
		var ok := r.position.x > EDGE * PX + 8 and r.position.y > EDGE * PX + 8 and r.end.x < mat_size.x - EDGE * PX - 8 and r.end.y < mat_size.y - EDGE * PX - 8
		if ok:
			for p in centre:
				var q := p.clamp(r.position, r.end)
				if p.distance_to(q) < half_w + 24.0:
					ok = false
					break
		if ok:
			crowd.setup(r, horizontal, level * 13 + 1, normal * side)
			crowd.visible = true
			return true
	return false

## Boost pads in the middle of the longest straights (never on the start line)
func _place_pads(n: int) -> void:
	pads.clear()
	if n <= 0:
		return
	var runs: Array = []                 # [length, middle index]
	var run := 0
	for i in range(1, count + 1):
		var a := centre[(i - 1) % count]
		var b := centre[i % count]
		var c := centre[(i + 1) % count]
		if absf((b - a).angle_to(c - b)) < 0.01:
			run += 1
		else:
			if run >= 30:
				runs.append([run, (i - run / 2) % count])
			run = 0
	runs.sort_custom(func(x, y): return x[0] > y[0])
	for r in runs:
		if pads.size() >= n:
			break
		var mid: int = r[1]
		if mid < 20 or mid > count - 20:
			mid = (mid + r[0] / 4) % count             # (off the start line)
		var dir := (centre[(mid + 1) % count] - centre[mid]).normalized()
		pads.append([centre[mid], dir])

## A figure-8: two loops crossing once (a vertical stretch over a horizontal one), in squares:
## [loop A's width, height, loop B's width, height, notches]; notches put square bumps on the
## outer sides (more corners, longer laps). Corner points in grid coordinates, in driving order.
func _eight_corners(e: Array) -> Array:
	var aw: int = e[0]
	var ah: int = e[1]
	var bw: int = e[2]
	var bh: int = e[3]
	var notches: int = e[4] if e.size() > 4 else 0
	var pts: Array = []
	# (0,0) -> (aw,0) -> (aw, ah+bh) -> (aw+bw, ah+bh) -> (aw+bw, ah) -> (0, ah) -> back up the left
	pts.append(Vector2i(0, 0))
	if notches >= 1 and aw >= 3:
		pts.append_array([Vector2i(1, 0), Vector2i(1, -1), Vector2i(2, -1), Vector2i(2, 0)])   # a bump on top
	pts.append(Vector2i(aw, 0))
	pts.append(Vector2i(aw, ah + bh))
	if notches >= 2 and bw >= 3:
		pts.append_array([Vector2i(aw + 1, ah + bh), Vector2i(aw + 1, ah + bh + 1), Vector2i(aw + 2, ah + bh + 1), Vector2i(aw + 2, ah + bh)])
	pts.append(Vector2i(aw + bw, ah + bh))
	if notches >= 3 and bh >= 3:
		pts.append_array([Vector2i(aw + bw, ah + bh - 1), Vector2i(aw + bw + 1, ah + bh - 1), Vector2i(aw + bw + 1, ah + 1), Vector2i(aw + bw, ah + 1)])
	pts.append(Vector2i(aw + bw, ah))
	pts.append(Vector2i(0, ah))
	# (shift so no corner is negative)
	var lo := Vector2i(0, 0)
	for p in pts:
		lo = Vector2i(mini(lo.x, p.x), mini(lo.y, p.y))
	var out: Array = []
	for p in pts:
		out.append(p - lo)
	_cross_grid = Vector2i(aw, ah) - lo                 # (where the two stretches cross)
	return out

var _cross_grid := Vector2i.ZERO
var _cross_pos := Vector2.ZERO                         # the crossing, mat px

## A figure-8's bridge: of the two stretches through the crossing, the one going down the middle
## (the vertical one) is the deck; [first index, last] on the bridge
func _find_bridge() -> Vector2i:
	var best := -1
	var best_d := 1e9
	for i in count:
		var d := centre[i].distance_to(_cross_pos)
		if d > STEP * 2.0:
			continue
		var di := (centre[(i + 1) % count] - centre[i]).normalized()
		if absf(di.y) > absf(di.x) and d < best_d:
			best_d = d
			best = i
	if best < 0:
		return Vector2i(-1, -1)
	var reach := int((half_w + 60.0) / STEP)
	return Vector2i((best - reach + count) % count, (best + reach) % count)

## Is centre index i on the bridge's deck?
func _on_bridge(i: int) -> bool:
	if bridge_range.x < 0:
		return false
	if bridge_range.x <= bridge_range.y:
		return i >= bridge_range.x and i <= bridge_range.y
	return i >= bridge_range.x or i <= bridge_range.y

## The features along the road (after the start is rolled into place): jumps' gaps on straights,
## oil slicks and puddles off the start, never on a pad, the bridge or each other; the secret
func _place_features() -> void:
	gaps.clear()
	slicks.clear()
	var rng := RandomNumberGenerator.new()
	rng.seed = 4409 * level + 11
	var used: Array = []                       # [first, last] index ranges taken
	var free_at := func(a: int, b: int) -> bool:
		if a < 30 or b > count - 30:
			return false                         # (not near the start / finish line)
		for u in used:
			if b >= u[0] - 24 and a <= u[1] + 24:
				return false
		for i in range(a, b + 1):
			if _on_bridge(i % count):
				return false
		for pd in pads:
			for i in [a, b]:
				if centre[i % count].distance_to(pd[0]) < PAD_LEN + 60.0:
					return false
		return true
	# jumps: on straights (the ramp and the gap both straight), spread round the lap
	var straights: Array = []
	var run := 0
	for i in range(1, count + 1):
		var a := centre[(i - 1) % count]
		var b := centre[i % count]
		var c := centre[(i + 1) % count]
		if absf((b - a).angle_to(c - b)) < 0.01:
			run += 1
		else:
			if run * STEP >= RAMP_LEN + GAP_LEN + 70.0:
				straights.append([i - run, i - 1])
			run = 0
	_shuffle_arr(straights, rng)
	var ramp_n := int(RAMP_LEN / STEP)
	var gap_n := int(GAP_LEN / STEP)
	for st in straights:
		if gaps.size() >= int(extras.get("jumps", 0)):
			break
		var mid: int = (st[0] + st[1]) / 2
		var g0: int = mid - gap_n / 2 + ramp_n / 2
		var r0: int = g0 - ramp_n
		var g1: int = g0 + gap_n
		if r0 < st[0] + 2 or g1 > st[1] - 4 or not free_at.call(r0, g1):
			continue
		gaps.append([g0, g1])
		used.append([r0, g1])
	# oil slicks, then puddles: anywhere on the road, a little off the middle
	for kind in ["oil", "puddle"]:
		var want := int(extras.get("oil" if kind == "oil" else "puddles", 0))
		var tries := 0
		var placed := 0
		while placed < want and tries < 200:
			tries += 1
			var i := rng.randi_range(40, count - 40)
			if not free_at.call(i - 6, i + 6):
				continue
			var dir := (centre[(i + 1) % count] - centre[i]).normalized()
			var side := Vector2(-dir.y, dir.x) * rng.randf_range(-half_w * 0.35, half_w * 0.35)
			slicks.append([centre[i] + side, kind])
			used.append([i - 6, i + 6])
			placed += 1
	# the secret, if this level has one: a spot on a straight (or anywhere free)
	secret = secret_of(level)
	if not secret.is_empty():
		var spot := -1
		for st in straights:
			var m: int = (st[0] + st[1]) / 2
			if free_at.call(m - 10, m + 10):
				spot = m
				break
		if spot < 0:
			for k in 60:
				var i := rng.randi_range(50, count - 50)
				if free_at.call(i - 10, i + 10):
					spot = i
					break
		if spot < 0:
			secret = {}
		else:
			secret["at"] = spot
			secret["pos"] = centre[spot]
			used.append([spot - 10, spot + 10])

func _shuffle_arr(arr: Array, rng: RandomNumberGenerator) -> void:
	for i in range(arr.size() - 1, 0, -1):
		var j := rng.randi() % (i + 1)
		var t = arr[i]
		arr[i] = arr[j]
		arr[j] = t

## Is centre index i over a jump's gap (no road there)?
func _in_gap(i: int) -> bool:
	for g in gaps:
		if i >= g[0] and i <= g[1]:
			return true
	return false

## On a jump's ramp (the last RAMP_LEN before a gap)?
func _on_ramp(i: int) -> bool:
	var ramp_n := int(RAMP_LEN / STEP)
	for g in gaps:
		if i >= g[0] - ramp_n and i < g[0]:
			return true
	return false

## A patch of `n` grid squares grown from the middle, and its outline as corner points (grid
## coordinates, clockwise). No two squares may touch only at a corner (the outline would pinch)
func _patch_outline(rng: RandomNumberGenerator, cols: int, rows: int, n: int, shape) -> Array:
	var cells := {}
	if shape != null:
		for r in shape:
			for x in range(r.position.x, r.end.x):
				for y in range(r.position.y, r.end.y):
					cells[Vector2i(x, y)] = true
	else:
		cells[Vector2i(cols / 2, rows / 2)] = true
	var tries := 0
	while shape == null and cells.size() < n and tries < 400:
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

func _perimeter(corners: Array) -> int:
	var l := 0
	for i in corners.size():
		var d: Vector2i = corners[(i + 1) % corners.size()] - corners[i]
		l += absi(d.x) + absi(d.y)
	return l

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
	for s in range(0, count, 3):                     # (points 24 px apart: the discs overlap)
		var c := centre[s] / PX
		for y in range(maxi(0, int(c.y - reach)), mini(h, int(c.y + reach) + 1)):
			for x in range(maxi(0, int(c.x - reach)), mini(w, int(c.x + reach) + 1)):
				var d := Vector2(x + 0.5, y + 0.5).distance_to(c)
				var i := y * w + x
				if d < dist[i]:
					dist[i] = d
					idx[i] = s
	# two layers: the floor (the carpet, the frame, the track's shadow) and the raised track (the
	# road, its curbs, its side face): a car falling off the far side drops between them
	_bw = w
	_bh = h
	if not _grass_noise:
		_grass_noise = FastNoiseLite.new()
		_grass_noise.frequency = 0.022
		_grass_noise.fractal_octaves = 3
		_cloud_noise = FastNoiseLite.new()
		_cloud_noise.frequency = 0.006
	_grass_noise.seed = level
	_cloud_noise.seed = level * 7 + 1
	_garden_decor(w, h, dist, hw)
	_sandbars.clear()
	_lamps.clear()
	var frng := RandomNumberGenerator.new()
	frng.seed = 77 * level + 5
	if world_no == 3:
		for k in int(w * h / 26000) + 2:
			var p := Vector2(frng.randi_range(EDGE + 40, w - EDGE - 40), frng.randi_range(EDGE + 20, h - EDGE - 20))
			if dist[int(p.y) * w + int(p.x)] > hw + 30.0:
				_sandbars.append(p)
	if world_no == 5:
		# a lamp every ~160 board px round the circuit, just off the road's outer side
		for s2 in range(0, count, int(640.0 / STEP)):
			var c2 := centre[s2] / PX
			var dirv := (centre[(s2 + 1) % count] - centre[s2]).normalized()
			var out := Vector2(-dirv.y, dirv.x)
			_lamps.append(c2 + out * (hw + 16.0))
			_lamps.append(c2 - out * (hw + 16.0))
	_lamp_light = PackedFloat32Array()
	if world_no == 5:
		_lamp_light.resize(w * h)
		_lamp_light.fill(0.0)
		const LR := 58.0
		for lp in _lamps:
			for yy in range(maxi(0, int(lp.y - LR)), mini(h, int(lp.y + LR) + 1)):
				for xx in range(maxi(0, int(lp.x - LR)), mini(w, int(lp.x + LR) + 1)):
					var v2 := 1.0 - Vector2(xx, yy).distance_to(lp) / LR
					if v2 > _lamp_light[yy * w + xx]:
						_lamp_light[yy * w + xx] = v2
	var data := PackedByteArray()
	data.resize(w * h * 4)
	var top := PackedByteArray()
	top.resize(w * h * 4)
	var k := 0
	var curb := 3.0
	for y in h:
		for x in w:
			var i := y * w + x
			var d := dist[i]
			var col: Color
			var on_track := true
			var e := mini(mini(x, y), mini(w - 1 - x, h - 1 - y))
			if e < EDGE:
				on_track = false
				# the mat's wooden frame: outlined both sides, lit top / left, shaded bottom / right
				if e <= 1 or e >= EDGE - 2:
					col = MAT_EDGE[2]
				elif (y < h / 2 and y == e) or (x < w / 2 and x == e) or (y < x and y < h - 1 - x and y < h / 2) or (x <= y and x < w - 1 - y and x < w / 2):
					col = MAT_EDGE[0]
				else:
					col = MAT_EDGE[1]
			elif _in_gap(idx[i]) and d <= hw + 2.0:
				# a jump's gap: no road, the ground far below (its cut edges outlined)
				on_track = false
				col = _floor_px(x, y).darkened(0.12)
				if _in_gap(idx[i] - 1) == false or _in_gap(idx[i] + 1) == false:
					col = OUTLINE
			elif d <= hw - curb:
				col = ROAD[0] if (x * 3 + y * 5) % 7 else ROAD[1]
				if world_no == 4 or world_no == 5:
					col = col.darkened(0.18)                     # (wet / night asphalt)
				if d < 0.8 and (idx[i] / 6) % 2 == 0:
					col = LINE                                   # the dashed centre line
				if _on_ramp(idx[i]):
					# a ramp: yellow and dark chevrons, lighter as it rises towards the gap
					var rise := float(idx[i] % int(RAMP_LEN / STEP)) / (RAMP_LEN / STEP)
					col = (PAD[0] if ((idx[i] / 2) + int(d)) % 3 != 0 else PAD[2]).lightened(0.25 * rise)
				var wp := Vector2(x + 0.5, y + 0.5) * PX
				for sl in slicks:
					var off: Vector2 = wp - sl[0]
					var r := SLICK_R * (1.0 + 0.18 * sin(off.angle() * 3.0 + sl[0].x))
					if off.length() < r:
						if sl[1] == "oil":
							# oil: a black glossy blob, a rainbow sheen at its top-left
							col = Color8(30, 28, 36)
							if off.length() > r - PX * 1.5:
								col = Color8(20, 18, 24)
							elif off.x + off.y < -r * 0.35 and off.x + off.y > -r * 0.6:
								col = [Color8(120, 90, 180), Color8(80, 160, 170), Color8(190, 170, 90)][int(off.length() / 6.0) % 3]
						else:
							# a puddle: grey-blue water, the sky in it, a ripple ring
							col = Color8(110, 132, 150)
							if absf(off.length() - r * 0.55) < PX * 0.8:
								col = Color8(170, 190, 204)
							elif off.x + off.y < -r * 0.5:
								col = Color8(150, 172, 188)
				if idx[i] <= 2 or idx[i] >= count - 2:
					col = Color8(30, 30, 34) if ((x / 2) + (y / 2)) % 2 else LINE   # the start / finish
				for pd in pads:
					var loc := Vector2(x + 0.5, y + 0.5) * PX - (pd[0] as Vector2)
					var u := loc.dot(pd[1])
					var v := loc.dot(Vector2(-pd[1].y, pd[1].x))
					if absf(u) < PAD_LEN / 2.0 and absf(v) < half_w - 14.0:
						# a boost pad: yellow chevrons pointing down the road on a dark plate
						var ch := fposmod(u / PX - absf(v) / PX * 0.8, 8.0)
						col = PAD[0] if ch < 3.0 else (PAD[1] if ch < 4.0 else PAD[2])
						if absf(u) > PAD_LEN / 2.0 - PX or absf(v) > half_w - 14.0 - PX:
							col = OUTLINE
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
				if up_t >= 1 and up_t <= TRACK_SIDE and _in_gap(idx[(y - up_t) * w + x]):
					up_t = -1                                    # (no side under a gap)
				if up_t >= 1 and up_t <= TRACK_SIDE:
					var sd: Array = SIDES[world_no]
					col = sd[0] if up_t <= 2 else (sd[1] if up_t < TRACK_SIDE else sd[2])
					if up_t > 2 and (idx[(y - up_t) * w + x] / 10) % 3 == 0:
						col = sd[3] if up_t < TRACK_SIDE else sd[4]          # a block / post holding it up
				elif up_t == TRACK_SIDE + 1:
					col = OUTLINE
				else:
					on_track = false
					col = _floor_px(x, y)
					var sx := x - 3
					var sy := y - TRACK_SIDE - 3
					if sx >= 0 and sy >= 0 and dist[sy * w + sx] <= hw + 2.0:
						col = col.darkened(0.22)
			col = _lit(col, x, y)
			if on_track:
				top[k] = col.r8
				top[k + 1] = col.g8
				top[k + 2] = col.b8
				top[k + 3] = 255
				# (under the track the floor is just floor)
				col = _lit(_floor_px(x, y), x, y)
			data[k] = col.r8
			data[k + 1] = col.g8
			data[k + 2] = col.b8
			data[k + 3] = 255
			k += 4
	track_image = Image.create_from_data(w, h, false, Image.FORMAT_RGBA8, top)
	return Image.create_from_data(w, h, false, Image.FORMAT_RGBA8, data)

## The floors, in the worlds' style (the user's Retry references, docs/mockups/palprix_worlds/v2):
## no outlines, few colours in steps with a 2x2 dither between them. The Garden (a morning): soft
## grass, flower clusters, chunky bushes, soft cloud shadows; the Kitchen: cream and mint tiles in
## the morning sun through the window
const DITHER := [[0.125, 0.625], [0.875, 0.375]]
const GRASS := [Color8(116, 172, 82), Color8(130, 186, 90), Color8(146, 200, 98), Color8(162, 212, 110)]
const BUSH := [Color8(60, 116, 56), Color8(80, 140, 62), Color8(104, 164, 72), Color8(132, 188, 86)]
const FLOWERS := [Color8(250, 246, 232), Color8(248, 196, 206), Color8(252, 226, 140)]
const KITCHEN := [Color8(240, 232, 214), Color8(214, 230, 218), Color8(206, 198, 184)]
var _bw := 1                           # the mat being painted, board px
var _bh := 1
var _grass_noise: FastNoiseLite
var _cloud_noise: FastNoiseLite
var _decor := {}                       # board px index -> colour: the Garden's flowers and bushes
var _trees: Array = []                 # the Garden's overhanging branches: [centre (board px), radius]
var _tree_light := PackedByteArray()   # under them: 0 open, 1 shade, 2 a fleck of sun through the leaves
const CANOPY := [Color8(34, 78, 44), Color8(48, 98, 50), Color8(66, 120, 58), Color8(88, 142, 66)]

func _floor_px(x: int, y: int) -> Color:
	if _decor.has(y * _bw + x):
		return _decor[y * _bw + x]
	match world_no:
		2:
			return _sky_floor(x, y)
		3:
			return _lagoon_floor(x, y)
		4:
			return _rain_floor(x, y)
		5:
			return _night_floor(x, y)
	if world_no == 1:
		var lx := x % 16
		var ly := y % 16
		if lx == 0 or ly == 0:
			return KITCHEN[2]                                # soft grout
		return KITCHEN[0] if ((x / 16) + (y / 16)) % 2 == 0 else KITCHEN[1]
	# the Garden: soft patches of grass in four greens, light mowing stripes over them
	var v := (_grass_noise.get_noise_2d(x, y) + 1.0) * 0.5 * 0.85 + 0.08
	var f := clampf(v, 0.0, 0.999) * GRASS.size()
	var band := int(f)
	if f - band > 0.75 and DITHER[y % 2][x % 2] < (f - band - 0.75) * 4.0:
		band += 1
	var c: Color = GRASS[clampi(band, 0, GRASS.size() - 1)]
	if ((x + y / 2) / 20) % 2 == 0:
		c = c.lerp(Color8(172, 220, 120), 0.1)
	return c

## The Sky: patchwork fields far below, hazy: wheat, greens, a ploughed brown, hedges between
## them dotted with trees, a pale river winding through
const FIELDS := [Color8(196, 214, 150), Color8(170, 200, 140), Color8(222, 210, 150), Color8(188, 180, 140), Color8(150, 190, 132)]
func _sky_floor(x: int, y: int) -> Color:
	var u := x * 0.86 + y * 0.32
	var v := y * 0.9 - x * 0.24
	var fx := int(floorf(u / 46.0))
	var fy := int(floorf(v / 38.0))
	var h := ((fx * 73856093) ^ (fy * 19349663)) & 0xffff
	var c: Color = FIELDS[h % FIELDS.size()]
	if (h / 7) % 3 == 0 and int(u) % 6 < 2:
		c = c.darkened(0.06)                              # furrows in some fields
	var eu := fposmod(u, 46.0)
	var ev := fposmod(v, 38.0)
	if eu < 1.4 or ev < 1.4:
		c = Color8(120, 160, 110)                         # a hedge
		if ((x / 3 * 31) ^ (y / 3 * 17)) % 5 == 0:
			c = Color8(96, 140, 96)                       # a tree on it
	var river := y + 60.0 * sin(x * 0.012) - _bh * 0.6
	if absf(river) < 4.0:
		c = Color8(176, 210, 230)
	# the clouds' shadows on the fields, then the haze (it's a long way down), then the clouds
	# themselves drifting between the track and the ground
	var ns := _cloud_noise.get_noise_2d(x * 0.8 - 14.0, y * 0.8 - 22.0)
	if ns > 0.28:
		c = c.darkened(0.12)
	c = c.lerp(Color8(200, 224, 244), 0.42)
	var n := _cloud_noise.get_noise_2d(x * 0.8, y * 0.8)
	if n > 0.28 or (n > 0.22 and DITHER[y % 2][x % 2] < 0.5):
		c = c.lerp(Color8(250, 252, 255), 0.6)
	return c

## The Lagoon at sunset: warm water, gentle waves catching the light, sandbars with a palm
func _lagoon_floor(x: int, y: int) -> Color:
	var t := clampf(float(y) / maxf(_bh, 1), 0.0, 1.0)
	var water := Color8(236, 150, 116).lerp(Color8(176, 104, 140), t)
	var wave := sin(x * 0.11 + sin(y * 0.05) * 2.0 + y * 0.31)
	if wave > 0.93:
		water = water.lerp(Color8(255, 214, 160), 0.6)    # a wave's lit crest
	elif wave < -0.95 and DITHER[y % 2][x % 2] < 0.5:
		water = water.darkened(0.08)
	# the sun's road of light across the water
	var glit := absf((x - _bw * 0.25) - (y - _bh * 0.1) * 0.35)
	if glit < 26.0 and ((x * 7 + y * 3) % 9 == 0):
		water = water.lerp(Color8(255, 240, 190), 0.55)
	for sb in _sandbars:
		var d := Vector2((x - sb.x) / 34.0, (y - sb.y) / 16.0).length()
		if d < 1.0:
			return Color8(240, 206, 150) if d < 0.82 else Color8(206, 160, 110)
	return water

## Rain over a park: wet grass gone dark and blue-grey, puddles on it with the sky in them
func _rain_floor(x: int, y: int) -> Color:
	var v := (_grass_noise.get_noise_2d(x, y) + 1.0) * 0.5
	var c := Color8(70, 108, 82).lerp(Color8(96, 132, 100), clampf(v, 0.0, 1.0))
	if DITHER[y % 2][x % 2] < 0.3 and v > 0.6:
		c = c.lightened(0.05)
	var n := _cloud_noise.get_noise_2d(x * 1.6, y * 1.6)
	if n > 0.42:
		c = Color8(132, 150, 166)                         # a puddle on the grass
		if n > 0.47 and n < 0.49:
			c = Color8(176, 190, 202)                     # its ripple
	return c

## Night: dark grass round the circuit (the lamps light it)
func _night_floor(x: int, y: int) -> Color:
	var v := (_grass_noise.get_noise_2d(x, y) + 1.0) * 0.5
	return Color8(60, 92, 70).lerp(Color8(78, 112, 84), clampf(v, 0.0, 1.0))

var _sandbars: Array = []              # the Lagoon's sandbars (board px)
var _lamps: Array = []                 # Grand Prix: the lamp posts (board px) round the track
var _lamp_light := PackedFloat32Array() # ...and their light on every board px (0 dark .. 1 right under one)

## The world's light over everything, the track too
func _lit(c: Color, x: int, y: int) -> Color:
	if world_no == 0:
		# a bright morning: the trees' shade with flecks of sun through the leaves, a few soft sun
		# shafts across, soft cloud shadows drifting over the garden (dithered edges)
		var t := _tree_light[y * _bw + x] if _tree_light.size() == _bw * _bh else 0
		if t == 2:
			return Color(minf(1.0, c.r * 1.12 + 0.06), minf(1.0, c.g * 1.12 + 0.05), minf(1.0, c.b * 1.05 + 0.01))
		if t == 1:
			return c.lerp(Color8(34, 62, 62), 0.2)
		var sh := fposmod(x + y * 0.7 + _cloud_noise.seed * 37.0, 520.0)
		if (sh > 40.0 and sh < 150.0) or (sh > 32.0 and sh < 158.0 and DITHER[y % 2][x % 2] < 0.5):
			c = Color(minf(1.0, c.r * 1.09 + 0.045), minf(1.0, c.g * 1.09 + 0.035), minf(1.0, c.b * 1.04))
		var n := _cloud_noise.get_noise_2d(x, y)
		var shade: bool = n > 0.32 or (n > 0.26 and DITHER[y % 2][x % 2] < 0.5)
		if shade:
			return c.lerp(Color8(56, 86, 110), 0.16)
		return Color(minf(1.0, c.r * 1.02 + 0.015), minf(1.0, c.g * 1.02 + 0.01), c.b)
	match world_no:
		2:
			# noon up in the sky: bright, a touch of blue (the clouds are below the track: _sky_floor)
			return Color(minf(1.0, c.r * 1.03 + 0.01), minf(1.0, c.g * 1.03 + 0.01), minf(1.0, c.b * 1.04 + 0.02))
		3:
			# sunset: everything warm, the light low from the left
			return c.lerp(Color8(255, 170, 110), 0.12)
		4:
			# rain: grey-blue and dim, a wet sheen on the lit side of things
			return c.lerp(Color8(84, 100, 120), 0.22)
		5:
			# night: dark, but for the lamps' warm pools along the track (_lamp_light, stamped once)
			var best: float = _lamp_light[y * _bw + x] if _lamp_light.size() == _bw * _bh else 0.0
			var k := clampf(best * 1.25, 0.0, 1.0)
			var steps := k * 3.0
			k = (floorf(steps) + (1.0 if steps - floorf(steps) > DITHER[y % 2][x % 2] else 0.0)) / 3.0
			return c.darkened(0.62 * (1.0 - k)).lerp(Color8(255, 220, 140), 0.12 * k)
	# the Kitchen's morning: the window's slanted beams on pale tiles, the rest in shade
	var s := x - y * 0.6
	var ph := fposmod(s, 300.0)
	var lit := ph > 20.0 and ph < 150.0 and absf(ph - 85.0) >= 2.5
	if not lit and ((ph > 12.0 and ph <= 20.0) or (ph >= 150.0 and ph < 158.0)):
		lit = DITHER[y % 2][x % 2] < 0.5
	if lit:
		return Color(minf(1.0, c.r * 1.03 + 0.02), minf(1.0, c.g * 1.03 + 0.02), minf(1.0, c.b * 1.03 + 0.01))
	return c.lerp(Color8(96, 108, 140), 0.12)

## The Garden's trees, just outside the mat: their branches hang over its edges (drawn in front of
## the car), and under them the shade, with flecks of sun through the leaves
func _plant_trees(w: int, h: int) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 53 * level + 9
	var spots: Array = []
	var x := rng.randi_range(20, 120)
	while x < w - 20:
		spots.append(Vector2(x, rng.randi_range(-10, 2)))                 # along the top
		spots.append(Vector2(x + rng.randi_range(-60, 60), h - 1 + rng.randi_range(-2, 10)))   # the bottom
		x += rng.randi_range(170, 300)
	var y := rng.randi_range(40, 140)
	while y < h - 40:
		spots.append(Vector2(rng.randi_range(-10, 2), y))                  # the left
		spots.append(Vector2(w - 1 + rng.randi_range(-2, 10), y + rng.randi_range(-50, 50)))   # the right
		y += rng.randi_range(170, 300)
	for p in spots:
		if rng.randf() < 0.25:
			continue                                       # (gaps between the trees)
		_trees.append([p, float(rng.randi_range(30, 48))])
	_tree_light.resize(w * h)
	_tree_light.fill(0)
	for tr in _trees:
		var c: Vector2 = tr[0]
		var r: float = tr[1]
		var reach := r + 34.0
		for yy in range(maxi(0, int(c.y - reach)), mini(h, int(c.y + reach) + 1)):
			for xx in range(maxi(0, int(c.x - reach)), mini(w, int(c.x + reach) + 1)):
				var d := Vector2(xx - c.x, yy - c.y).length()
				if d > reach or (d > reach - 4.0 and DITHER[yy % 2][xx % 2] < 0.5):
					continue
				var i := yy * w + xx
				# flecks of sun: little 2 px spots, more of them towards the shade's edge
				var fleck := ((xx / 2 * 73856093) ^ (yy / 2 * 19349663)) & 63
				_tree_light[i] = 2 if fleck < (3 + int(6.0 * d / reach)) else 1

## The overhanging branches, in front of everything: chunky clusters in four dark greens, lit
## top-left, a few light sparkles; no outlines
func _paint_canopy(w: int, h: int) -> Image:
	var img := Image.create(w, h, false, Image.FORMAT_RGBA8)
	var rng := RandomNumberGenerator.new()
	rng.seed = 17 * level + 2
	for tr in _trees:
		var c: Vector2 = tr[0]
		var r: float = tr[1]
		# a few clumps per tree, overlapping
		for k in 4:
			var cc := c + Vector2(rng.randf_range(-r * 0.6, r * 0.6), rng.randf_range(-r * 0.6, r * 0.6))
			var rr := r * rng.randf_range(0.55, 0.85)
			var ph := rng.randf() * TAU
			for yy in range(maxi(0, int(cc.y - rr - 3)), mini(h, int(cc.y + rr + 4))):
				for xx in range(maxi(0, int(cc.x - rr - 3)), mini(w, int(cc.x + rr + 4))):
					var a := atan2(yy - cc.y, xx - cc.x)
					var d := Vector2(xx - cc.x, yy - cc.y).length()
					var lump := rr * (1.0 + 0.22 * sin(a * 6.0 + ph) + 0.12 * sin(a * 11.0 + ph * 2.0))
					if d > lump or (d > lump - 2.0 and (xx / 2 + yy / 2) % 3 == 0):
						continue
					var light := (-(xx - cc.x) - (yy - cc.y)) / (rr * 1.6)
					var v := clampf(0.45 + light * 0.6, 0.0, 0.999) * CANOPY.size()
					var b := int(v)
					if v - b > 0.75 and DITHER[yy % 2][xx % 2] < (v - b - 0.75) * 4.0:
						b += 1
					var col: Color = CANOPY[clampi(b, 0, CANOPY.size() - 1)]
					if light > 0.0 and rng.randf() < 0.01:
						col = Color8(150, 200, 120)                 # a leaf catching the sun
					img.set_pixel(xx, yy, col)
	return img

## The Garden's flowers and bushes, away from the track (and the stand): chunky, no outlines
func _garden_decor(w: int, h: int, dist: PackedFloat32Array, hw: float) -> void:
	_decor.clear()
	_trees.clear()
	_tree_light = PackedByteArray()
	if world_no != 0:
		return
	_plant_trees(w, h)
	var rng := RandomNumberGenerator.new()
	rng.seed = 91 * level + 3
	var stand := Rect2(crowd.rect.position / PX, crowd.rect.size / PX).grow(4.0) if crowd.visible else Rect2()
	var clear := func(x: int, y: int, room: float) -> bool:
		return x >= EDGE and y >= EDGE and x < w - EDGE and y < h - EDGE and dist[y * w + x] > hw + room and not stand.has_point(Vector2(x, y))
	# bushes: lumpy discs lit from the top-left, a few sparkles, a soft shadow down-right
	for k in int(w * h / 9000):
		var r := rng.randi_range(9, 16)
		var cx := rng.randi_range(EDGE + r, w - EDGE - r)
		var cy := rng.randi_range(EDGE + r, h - EDGE - r)
		if not clear.call(cx, cy, r + 10.0):
			continue
		var ph := rng.randf() * TAU
		for y in range(cy - r - 3, cy + r + 4):
			for x in range(cx - r - 3, cx + r + 4):
				if x < 0 or y < 0 or x >= w or y >= h:
					continue
				var a := atan2(y - cy, x - cx)
				var d := Vector2(x - cx, y - cy).length()
				var lump := r * (1.0 + 0.22 * sin(a * 5.0 + ph) + 0.1 * sin(a * 9.0 + ph * 2.0))
				var i := y * w + x
				if d <= lump and ((x / 2 + y / 2) % 3 != 0 or d <= lump - 2.0):
					var light := (-(x - cx) - (y - cy)) / (r * 1.6)
					var v := clampf(0.5 + light * 0.6, 0.0, 0.999) * BUSH.size()
					var b := int(v)
					if v - b > 0.75 and DITHER[y % 2][x % 2] < (v - b - 0.75) * 4.0:
						b += 1
					var col: Color = BUSH[clampi(b, 0, BUSH.size() - 1)]
					if light > -0.1 and rng.randf() < 0.012:
						col = Color8(206, 240, 160)               # a sparkle
					_decor[i] = col
				elif d <= lump + 2.5 and y > cy and x > cx - r * 0.3 and not _decor.has(i):
					_decor[i] = Color8(0, 0, 0, 0)                 # (its shadow: marked, painted below)
	# flower clusters: small soft dots in groups of one colour, a stem dot under each
	for k in int(w * h / 2600):
		var cx := rng.randi_range(EDGE + 10, w - EDGE - 10)
		var cy := rng.randi_range(EDGE + 8, h - EDGE - 8)
		var col: Color = FLOWERS[rng.randi() % FLOWERS.size()]
		for j in 8:
			var fx := cx + rng.randi_range(-9, 9)
			var fy := cy + rng.randi_range(-6, 6)
			if not clear.call(fx, fy, 6.0) or not clear.call(fx + 1, fy + 2, 6.0):
				continue
			for p in [Vector2i(0, 0), Vector2i(1, 0), Vector2i(0, 1), Vector2i(1, 1)]:
				_decor[(fy + p.y) * w + fx + p.x] = col
			if not _decor.has((fy + 2) * w + fx):
				_decor[(fy + 2) * w + fx] = Color8(92, 150, 70)
	# the bushes' shadows: the grass under them, darker
	for i in _decor.keys():
		if _decor[i].a == 0.0:
			_decor.erase(i)
			_decor[i] = _floor_px(i % w, i / w).darkened(0.22)

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
	crowd = Crowd.new()
	world.add_child(crowd)                          # (on the floor, beside the track)
	# drawn in this order: the floor, a car falling behind the track, the raised track, the car
	behind = Node2D.new()
	world.add_child(behind)
	track = Sprite2D.new()
	track.centered = false
	track.scale = Vector2(PX, PX)
	track.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	world.add_child(track)
	trail = Trail.new()
	world.add_child(trail)
	front = Node2D.new()
	world.add_child(front)
	canopy = Sprite2D.new()
	canopy.centered = false
	canopy.scale = Vector2(PX, PX)
	canopy.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	world.add_child(canopy)                         # (over the car: the branches hang above it)
	world.scale = Vector2(ZOOM, ZOOM)
	var layers := car_slices()
	shadow = Sprite2D.new()
	shadow.texture = layers[2]
	shadow.scale = Vector2(PX, PX)
	shadow.modulate = Color(0.05, 0.04, 0.1, 0.35)
	shadow.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	front.add_child(shadow)
	car = Node2D.new()
	front.add_child(car)
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
	# the antenna: a thin dark wire (4 mat px) with a red ball on top
	antenna = Line2D.new()
	antenna.width = 4.0
	antenna.default_color = Color8(40, 30, 40)
	antenna.antialiased = false
	front.add_child(antenna)
	var tip := Image.create(3, 3, false, Image.FORMAT_RGBA8)
	for p in [Vector2i(1, 0), Vector2i(0, 1), Vector2i(1, 1), Vector2i(2, 1), Vector2i(1, 2)]:
		tip.set_pixel(p.x, p.y, Color8(226, 70, 64))
	tip.set_pixel(1, 1, Color8(255, 170, 160))
	antenna_tip = Sprite2D.new()
	antenna_tip.texture = ImageTexture.create_from_image(tip)
	antenna_tip.scale = Vector2(PX, PX)
	antenna_tip.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	front.add_child(antenna_tip)
	# the pal, curled up in the seat (its face kept upright: it looks at you, not at the road)
	driver = Sprite2D.new()
	driver.texture = PalBall.texture()
	driver.scale = Vector2(2, 2)
	driver.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	front.add_child(driver)

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
	# the race's position (Grand Prix) and the pal's boost, on the band's right
	hud_place = _label(Vector2(HUD_BAND.end.x - 190, HUD_BAND.position.y + 2), Vector2(120, 52), 32, HORIZONTAL_ALIGNMENT_RIGHT, light)
	boost_icon = TextureRect.new()
	boost_icon.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	boost_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	boost_icon.size = Vector2(28, 36)
	boost_icon.position = Vector2(HUD_BAND.end.x - 52, HUD_BAND.position.y + 10)
	add_child(boost_icon)
	# the rain over the view (Rain): streaks falling across the screen, under the HUD
	rain_fx = RainFx.new()
	rain_fx.view = VIEW
	rain_fx.visible = false
	add_child(rain_fx)
	move_child(rain_fx, world.get_index() + 1)

	# the start lights: a dark gantry with three lamps, hanging under the HUD
	lights = Node2D.new()
	lights.position = Vector2(PLAY_WIDTH / 2.0, HUD_BAND.end.y + 64)
	add_child(lights)
	var gantry := ColorRect.new()
	gantry.color = Color8(40, 34, 44)
	gantry.size = Vector2(264, 96)
	gantry.position = -gantry.size / 2.0
	lights.add_child(gantry)
	var inner := ColorRect.new()
	inner.color = Color8(70, 62, 76)
	inner.size = gantry.size - Vector2(12, 12)
	inner.position = gantry.position + Vector2(6, 6)
	lights.add_child(inner)
	for i in 3:
		var lamp := Sprite2D.new()
		lamp.texture = _lamp_texture()
		lamp.scale = Vector2(PX, PX)
		lamp.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		lamp.position = Vector2((i - 1) * 80, 0)
		lights.add_child(lamp)
		lamps.append(lamp)
	# what the two buttons do, along the bottom (from the countdown to a few seconds in)
	hint_left = make_button_hint(0, "LEFT")
	hint_left.position = Vector2(72, PLAY_HEIGHT - 86)
	hint_right = make_button_hint(1, "RIGHT")
	hint_right.position = Vector2(PLAY_WIDTH - 250, PLAY_HEIGHT - 86)

	banner = _label(Vector2(0, PLAY_HEIGHT / 2 - 70), Vector2(PLAY_WIDTH, 140), 72, HORIZONTAL_ALIGNMENT_CENTER, Color(1, 0.97, 0.9))
	banner.add_theme_color_override("font_outline_color", MAT_EDGE[2])
	banner.add_theme_constant_override("outline_size", 16)
	banner.modulate.a = 0.0

	motor = AudioStreamPlayer.new()
	var hum: AudioStreamWAV = load("res://sounds/fx/rc_motor.wav").duplicate()
	hum.loop_mode = AudioStreamWAV.LOOP_FORWARD      # (the motor hums the whole race: a seamless 1 s loop)
	hum.loop_end = hum.get_length() * hum.mix_rate
	motor.stream = hum
	motor.volume_db = -30.0                           # (in the background, under the music)
	add_child(motor)

## A start lamp, 16 x 16 px (x4): a round glass in a dark rim, its glint top-left; the colour
## is set with modulate (off = grey, red, green)
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
				col = Color8(255, 255, 255).lerp(Color8(255, 255, 255), 1.0)
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

func _place_car() -> void:
	car.position = car_pos.round() + Vector2(0, car_drop)
	for i in slices.size():
		slices[i].rotation = heading
		slices[i].position = Vector2(0, -i * LAYER_UP)          # (lifted on screen, not turned)
	shadow.position = car_pos.round() + Vector2(5, 8 + car_drop * 0.3)
	shadow.rotation = heading
	shadow.visible = state != State.FALL
	driver.position = car.position + Vector2.from_angle(heading) * -5.0 + Vector2(0, -LAYERS * LAYER_UP - 4.0)
	# the antenna stands up from the car's back left corner, leaning back and out in the turns
	var base := car.position + Vector2(-30, -22).rotated(heading) + Vector2(0, -LAYERS * LAYER_UP)
	var lean := Vector2.from_angle(heading) * -10.0 + Vector2.from_angle(heading + PI / 2.0) * sway * 26.0
	var top := base + Vector2(0, -46) + lean
	antenna.points = PackedVector2Array([base.round(), (base.lerp(top, 0.5) + lean * 0.15).round(), top.round()])
	antenna_tip.position = top.round()
	antenna.visible = state != State.FALL
	antenna_tip.visible = antenna.visible
	if headlight:
		headlight.rotation = heading
		headlight.position = car.position + Vector2.from_angle(heading) * 92.0
		headlight.visible = world_no == 5 and state != State.FALL
	# (in the air: the car up, its shadow left behind on the road)
	if car_drop < 0.0:
		shadow.position = car_pos.round() + Vector2(5, 8)
		shadow.modulate.a = 0.35 * (1.0 + car_drop / 120.0)

## The view follows the car (a small mat just sits in the middle of it)
func _follow(amount: float) -> void:
	# (at the start the view is on the car, the stand beside it; it looks ahead once racing)
	look_k = move_toward(look_k, 1.0 if state == State.DRIVE else 0.0, 0.02)
	var aim := car_pos + Vector2.from_angle(heading) * LOOK_AHEAD * look_k
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
	hud_place.visible = not rivals.is_empty()
	hud_place.text = "P%d/%d" % [place, rivals.size() + 1]
	var b := PetState.boost
	boost_icon.visible = b in ["splash", "fizz", "focus", "sturdy", "lucky"]
	if boost_icon.visible:
		boost_icon.texture = PetState.boost_icon(b)
	var now := _stars_now()
	if now < _stars_shown:
		for i in range(now, _stars_shown):
			var st := hud_stars[i]
			st.texture = UiArt.star(false)
			var t := create_tween()
			t.tween_property(st, "scale", Vector2(1.4, 1.4), 0.08)
			t.tween_property(st, "scale", Vector2.ONE, 0.2)
		_stars_shown = now

## 1 + within the par time (with rivals: in 1st place) + never fell off
func _stars_now() -> int:
	var second := (place == 1) if not rivals.is_empty() else (race_time <= par)
	return 1 + (1 if second else 0) + (1 if falls == 0 else 0)

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
				_set_lamps(COUNTDOWN - now + 1, false)          # 3, 2, 1: one more red light
				_sfx("res://sounds/fx/rc_beep.wav", -10.0)
				Input.vibrate_handheld(15)
			if countdown <= 0.6:
				state = State.DRIVE
				_set_lamps(COUNTDOWN, true)                    # all green: GO
				crowd.cheer(car_pos)
				_show_banner("GO!", 0.5)
				_sfx("res://sounds/fx/rc_go.wav", -8.0)
				Input.vibrate_handheld(40)
				motor.play()
				var t := create_tween()
				t.tween_interval(0.7)
				t.tween_property(lights, "position:y", HUD_BAND.end.y - 80.0, 0.35).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
				t.parallel().tween_property(lights, "modulate:a", 0.0, 0.35)
				t.tween_callback(func(): lights.visible = false)
				var h := create_tween()
				h.tween_interval(3.5)                           # (the controls: gone a few seconds in)
				h.tween_property(hint_left, "modulate:a", 0.0, 0.4)
				h.parallel().tween_property(hint_right, "modulate:a", 0.0, 0.4)
		State.DRIVE:
			_drive(delta)
	# the antenna's swing: a spring pushed by how fast the car turns
	var turn_rate := wrapf(heading - _last_heading, -PI, PI) / maxf(delta, 0.001)
	_last_heading = heading
	sway_v += (-turn_rate * 0.18 - sway * 40.0 - sway_v * 6.0) * delta
	sway = clampf(sway + sway_v * delta, -1.0, 1.0)
	_place_car()
	_follow(minf(1.0, delta * 6.0))

func _drive(delta_real: float) -> void:
	# a focused car on the brink: time slows a moment (the clock too: no time lost for it)
	var delta := delta_real * (0.35 if slow_t > 0.0 else 1.0)
	slow_t = maxf(0.0, slow_t - delta_real)
	race_time += delta
	var turn := (1.0 if _held(1) else 0.0) - (1.0 if _held(0) else 0.0)
	if qa_autopilot:
		# (QA only: steer at the road a little ahead, like a careful driver)
		var aim := centre[(near + 14) % count] - car_pos
		var diff := wrapf(aim.angle() - heading, -PI, PI)
		turn = clampf(diff * 3.0, -1.0, 1.0) if absf(diff) > 0.03 else 0.0
	var grip := 0.88 if world_no == 4 else 1.0                       # (the rain: a wet road)
	if air_t > 0.0:
		grip *= 0.3                                                  # (in the air: hardly any steering)
	if slip_t <= 0.0:
		heading += turn * TURN * grip * delta
	# on the curb: slowed down, rumbling; on a pad: a boost that fades
	var from_mid := car_pos.distance_to(centre[near])
	var v := SPEED * (1.0 + BOOST * boost_t)
	if from_mid > half_w - CURB_TOUCH and air_t <= 0.0:
		v *= CURB_SLOW
		curb_t -= delta
		if curb_t <= 0.0:
			curb_t = 0.09
			Input.vibrate_handheld(6)
	var on := false
	for pd in pads:
		var loc: Vector2 = car_pos - pd[0]
		if absf(loc.dot(pd[1])) < PAD_LEN / 2.0 + 6.0 and absf(loc.dot(Vector2(-pd[1].y, pd[1].x))) < half_w:
			on = true
	if on and not _on_pad and air_t <= 0.0:
		boost_t = 1.0
		_sfx("res://sounds/fx/rc_boost.wav", -8.0)
		Input.vibrate_handheld(30)
	_on_pad = on
	boost_t = maxf(0.0, boost_t - delta / BOOST_TIME)
	# oil / a puddle: the car spins round once and stops for a moment, then goes on down the road
	var move_heading := heading
	if slip_t > 0.0:
		slip_t -= delta
		var f := 1.0 - slip_t / SLIP_TIME
		heading = slip_heading + TAU * f
		move_heading = slip_heading
		v *= maxf(0.0, 1.0 - f * 1.6)
		if slip_t <= 0.0:
			heading = (centre[(near + 2) % count] - centre[near]).angle()
	elif air_t <= 0.0:
		_check_slicks()
	car_pos += Vector2.from_angle(move_heading) * v * delta
	if air_t > 0.0:
		air_t -= delta
		if air_t <= 0.0:
			_land()
	else:
		trail.add(car_pos, heading, delta)
		if world_no == 4 and randf() < delta * 14.0:
			trail.spray(car_pos, heading, 1)                       # (the wet road: a fine spray)
	_cheer_cd = maxf(0.0, _cheer_cd - delta)
	if crowd.visible and _cheer_cd <= 0.0 and crowd.rect.grow(170.0).has_point(car_pos):
		_cheer_cd = 2.5
		crowd.cheer(car_pos)                             # (the wave runs from where the car is)
	if boost_t > 0.3:
		trail.add(car_pos, heading, delta)                  # (more streaks while boosted)
	var was_near := near
	_find_near()
	_update_bridge_order()
	if progress >= last_cp + count / CHECKPOINTS:
		last_cp = floorf(progress / (count / CHECKPOINTS)) * (count / CHECKPOINTS)
	# a jump: off the end of a ramp, straight and on the road, the car flies over the gap
	if air_t <= 0.0 and _on_ramp(was_near) and not _on_ramp(near):
		var road_dir := (centre[(near + 1) % count] - centre[near]).angle()
		if absf(wrapf(heading - road_dir, -PI, PI)) < 0.5 and car_pos.distance_to(centre[near]) < half_w * 0.85:
			_jump(AIR_TIME)
	_update_secret(was_near)
	_update_rivals(delta)
	var off_road := car_pos.distance_to(centre[near]) > half_w + FALL_AT or (_in_gap(near) and air_t <= 0.0)
	if not off_road and air_t <= 0.0 and car_pos.distance_to(centre[near]) > half_w + FALL_AT * 0.2 and not focus_used and PetState.boost_power("focus") > 0:
		focus_used = true
		slow_t = 0.9                                    # (on the brink: a moment to steer back)
		PetState.use_boost()
		_show_banner("focus!", 0.4)
	if off_road and air_t <= 0.0:
		_fall()
		return
	if motor.playing:
		# (it strains a little in the turns)
		motor.pitch_scale = lerpf(motor.pitch_scale, 1.0 - absf(turn) * 0.07, minf(1.0, delta * 5.0))
	if progress >= count * lap and lap <= LAPS:
		lap += 1
		if lap > LAPS:
			_finish()
			return
		_show_banner("LAP %d" % lap if lap < LAPS else "FINAL LAP!", 0.7)
		_sfx("res://sounds/fx/gamecoin.wav", -10.0)
	_refresh_hud()

## Off a ramp (or a springboard): up in the air for `t` (the car lifts, its shadow drops away)
func _jump(t: float) -> void:
	air_t = t
	_sfx("res://sounds/fx/water_boing.wav", -12.0, 1.4)
	Input.vibrate_handheld(20)
	var tw := create_tween()
	tw.tween_method(func(f: float):
		car_drop = -sin(f * PI) * 46.0, 0.0, 1.0, t)

## Back on the road after a jump (off the road there: a fall, below)
func _land() -> void:
	car_drop = 0.0
	_sfx("res://sounds/fx/rc_land.wav", -14.0)
	Input.vibrate_handheld(25)
	trail.add(car_pos, heading, 0.05)

## Oil and puddles: a spin round and a stop (a sturdy car rumbles straight through)
func _check_slicks() -> void:
	for sl in slicks:
		if car_pos.distance_to(sl[0]) < SLICK_R * 0.85:
			if PetState.boost_power("sturdy") > 0:
				if sl.size() < 3:
					sl.append(true)                       # (rumbled through once: say so once)
					_show_banner("sturdy!", 0.4)
				return
			slip_t = SLIP_TIME
			slip_heading = heading
			_sfx("res://sounds/fx/water_boing.wav" if sl[1] == "puddle" else "res://sounds/fx/rc_fall.wav", -12.0, 0.8)
			Input.vibrate_handheld(40)
			if sl[1] == "puddle":
				trail.spray(car_pos, heading, 12)
			return

## The bridge's deck: over the car while the car is on the road beneath it, under it on the deck
func _update_bridge_order() -> void:
	if not bridge or not bridge.visible:
		return
	var on := _on_bridge(near)
	var want := front.get_index() - 1 if on else front.get_index() + 1
	if bridge.get_index() != want:
		world.move_child(bridge, clampi(want, 0, world.get_child_count() - 1))

## Off the track: the car tips over the edge and drops to the floor, then it's back on the last
## checkpoint, pointing down the road (the clock goes on; the no-fall star is gone)
func _fall() -> void:
	# a splashy car: put back on the road where it left it, no time lost (once a level)
	if not splash_used and PetState.boost_power("splash") > 0:
		splash_used = true
		PetState.use_boost()
		var i := near
		car_pos = centre[i]
		heading = (centre[(i + 2) % count] - centre[i]).angle()
		slip_t = 0.0
		trail.spray(car_pos, heading, 14)
		_sfx("res://sounds/fx/water_boing.wav", -8.0)
		_show_banner("splash!", 0.5)
		Input.vibrate_handheld(40)
		return
	state = State.FALL
	falls += 1
	# the car tips out over the edge it left, then drops to the floor, always UNDER the raised
	# track: whichever side it went off, it's never drawn over a road (the user, 2026-10-17)
	for n in [car, antenna, antenna_tip, driver]:
		n.reparent(behind, false)
	var from := car_pos
	var out := (car_pos - centre[near]).normalized()
	motor.stop()
	_sfx("res://sounds/fx/rc_fall.wav", -12.0)
	Input.vibrate_handheld(80)
	var t := create_tween()
	t.tween_method(func(f: float):
		car_pos = from + out * TIP_OUT * (1.0 - pow(1.0 - minf(1.0, f * 2.5), 2.0))
		car_drop = f * f * TRACK_SIDE * PX * 3.0
		car.modulate = Color(1, 1, 1).lerp(Color(0.4, 0.38, 0.45), f)
		car.scale = Vector2.ONE * (1.0 - 0.15 * f), 0.0, 1.0, 0.45)
	t.tween_callback(func(): _sfx("res://sounds/fx/rc_land.wav", -10.0))
	t.tween_interval(0.35)
	t.tween_callback(func():
		var i := int(fposmod(last_cp, count))
		car_pos = centre[i]
		heading = (centre[(i + 2) % count] - centre[i]).angle()
		near = i
		progress = last_cp
		car_drop = 0.0
		for n in [car, antenna, antenna_tip, driver]:
			if n.get_parent() != front:
				n.reparent(front, false)
		front.move_child(shadow, 0)
		trail.marks.clear()
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
	crowd.party = true
	motor.stop()
	var stars := _stars_now()
	_show_banner("FINISH!", 1.0)
	_sfx("res://sounds/fx/unlock_ding.wav", -8.0)
	Input.vibrate_handheld(60)
	_refresh_hud()
	get_tree().create_timer(1.4).timeout.connect(func():
		if is_running:
			finish_level(level, stars, race_time))

# ================================================================== FEATURES: THE BRIDGE, SECRETS, RIVALS

## Built once the circuit and its paint are ready: the bridge's deck, the secret's pieces, the
## rivals on the grid, the headlights (night), the rain (Rain)
func _spawn_features() -> void:
	if not bridge:
		bridge = Sprite2D.new()
		bridge.centered = false
		bridge.scale = Vector2(PX, PX)
		bridge.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		world.add_child(bridge)
	bridge.visible = bridge_range.x >= 0
	if bridge.visible:
		bridge.texture = ImageTexture.create_from_image(_paint_bridge())
		track.texture = ImageTexture.create_from_image(track_image)    # (the deck's shadow is on it now)
	_spawn_secret()
	_spawn_rivals()
	if not headlight:
		headlight = Sprite2D.new()
		headlight.texture = _cone_texture()
		headlight.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		var m := CanvasItemMaterial.new()
		m.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
		headlight.material = m
		headlight.scale = Vector2(PX, PX)
		front.add_child(headlight)
	headlight.visible = world_no == 5
	rain_fx.visible = world_no == 4
	for n in _lamp_nodes:
		n.queue_free()
	_lamp_nodes.clear()
	if world_no == 5:
		var tex := _lamp_post_texture()
		for lp in _lamps:
			var post := _px_sprite(tex, (lp as Vector2) * PX + Vector2(0, -20))
			world.add_child(post)
			world.move_child(post, track.get_index())        # (on the floor, under the track's level)
			_lamp_nodes.append(post)
	_refresh_hud()

## The deck over the crossing: the road of the bridge's stretch with white rails along it; its
## shadow darkens the road beneath (on the track's image)
func _paint_bridge() -> Image:
	var w := int(mat_size.x / PX)
	var h := int(mat_size.y / PX)
	var img := Image.create(w, h, false, Image.FORMAT_RGBA8)
	var hw := half_w / PX
	# the distance from each board px to the deck's stretch of the centre line, then each px once
	var dist := {}
	var i := bridge_range.x
	var guard := 0
	while guard < count:
		var c := centre[i] / PX
		for y in range(maxi(0, int(c.y - hw - 3)), mini(h, int(c.y + hw + 4))):
			for x in range(maxi(0, int(c.x - hw - 3)), mini(w, int(c.x + hw + 4))):
				var d := Vector2(x + 0.5, y + 0.5).distance_to(c)
				var k := y * w + x
				if d < dist.get(k, 1e9):
					dist[k] = d
		if i == bridge_range.y:
			break
		i = (i + 1) % count
		guard += 1
	# (square ends: only between the deck's two ends along the road)
	var a_end := centre[bridge_range.x] / PX
	var b_end := centre[bridge_range.y] / PX
	var axis := b_end - a_end
	for k in dist:
		var d: float = dist[k]
		var x: int = k % w
		var y: int = k / w
		var t := (Vector2(x + 0.5, y + 0.5) - a_end).dot(axis) / maxf(axis.length_squared(), 1.0)
		if t < 0.0 or t > 1.0:
			continue
		var col: Color
		if d <= hw - 3.0:
			col = ROAD[0] if (x * 3 + y * 5) % 7 else ROAD[1]
			if world_no == 3:
				# the Lagoon's bridge: a wooden deck, planks across it (a pier over the water)
				var plank := int(t * axis.length() / 5.0)
				col = Color8(196, 140, 88) if plank % 2 == 0 else Color8(176, 122, 74)
				if int(t * axis.length()) % 5 == 0:
					col = Color8(120, 78, 46)
			elif world_no == 4 or world_no == 5:
				col = col.darkened(0.18)
		elif d <= hw - 1.0:
			col = Color8(244, 240, 232) if ((x + y) / 3) % 2 == 0 else Color8(196, 190, 186)   # the rails
		elif d <= hw + 1.0:
			col = OUTLINE
		else:
			continue
		img.set_pixel(x, y, _lit(col, x, y))
		# its shadow on the road below, down and to the right
		var sx := x + 3
		var sy := y + 6
		if d <= hw and sx < w and sy < h and track_image.get_pixel(sx, sy).a > 0.0 and not dist.has(sy * w + sx):
			track_image.set_pixel(sx, sy, track_image.get_pixel(sx, sy).darkened(0.3))
	return img

## The secret's pieces on the road: a springboard and a gift on a balloon over the road (fizzy),
## crates across half the road with the gift behind them (milky), a sparkle where the hidden gift
## is (fruity); the drink's sign by the road
func _spawn_secret() -> void:
	if secret.has("node") and is_instance_valid(secret["node"]):
		(secret["node"] as Node).queue_free()
	if secret.is_empty():
		return
	var node := Node2D.new()
	front.add_child(node)
	front.move_child(node, 0)                           # (under the car)
	secret["node"] = node
	var at: int = secret["at"]
	var dir := (centre[(at + 1) % count] - centre[at]).normalized()
	var side := Vector2(-dir.y, dir.x)
	var taken: bool = secret["taken"]
	match secret["gate"]:
		"fizzy":
			var spring := _px_sprite(_spring_texture(), centre[(at - 9 + count) % count])
			spring.rotation = dir.angle()
			node.add_child(spring)
			secret["spring"] = (at - 9 + count) % count
			if not taken:
				var g := Node2D.new()
				g.position = centre[at] + Vector2(0, -70)
				node.add_child(g)
				g.add_child(_px_sprite(_balloon_texture(), Vector2(0, -40)))
				g.add_child(_px_sprite(Collection.prize_icon(secret["prize"]), Vector2.ZERO, 2))
				var bob := g.create_tween().set_loops()
				bob.tween_property(g, "position:y", g.position.y - 10.0, 0.7).set_trans(Tween.TRANS_SINE)
				bob.tween_property(g, "position:y", g.position.y, 0.7).set_trans(Tween.TRANS_SINE)
				secret["gift"] = g
		"milky":
			var crates: Array = []
			if not taken:
				for k in 3:
					var cr := _px_sprite(_crate_texture(), centre[at] + side * (half_w * 0.28 + k * 34.0 - 34.0) * 1.0 + side * half_w * 0.2)
					node.add_child(cr)
					crates.append(cr)
				var g2 := _px_sprite(Collection.prize_icon(secret["prize"]), centre[(at + 4) % count] + side * half_w * 0.45, 2)
				node.add_child(g2)
				secret["gift"] = g2
			secret["crates"] = crates
			secret["side"] = side
		"fruity":
			if not taken:
				var sp := _px_sprite(_sparkle_texture(), centre[at])
				node.add_child(sp)
				var tw := sp.create_tween().set_loops()
				tw.tween_property(sp, "modulate:a", 0.25, 0.5)
				tw.tween_property(sp, "modulate:a", 1.0, 0.5)
				secret["sparkle"] = sp
				var g3 := _px_sprite(Collection.prize_icon(secret["prize"]), centre[at], 2)
				g3.visible = gate_open("fruity", secret["lvl"])      # (only a lucky car sees it)
				node.add_child(g3)
				secret["gift"] = g3
	# the sign by the road: which drink, which level
	var sign := _px_sprite(TiltMazeArt.sign_card(), centre[at] + side * (half_w + 40.0))
	sign.scale = Vector2(PX, PX)
	var icon := Sprite2D.new()
	icon.texture = gate_icon(secret["gate"], secret["lvl"])
	icon.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	sign.add_child(icon)
	sign.visible = not taken
	node.add_child(sign)

## The secret as the car comes by
func _update_secret(was_near: int) -> void:
	if secret.is_empty() or secret["taken"]:
		return
	var lvl: int = secret["lvl"]
	match secret["gate"]:
		"fizzy":
			var sp: int = secret["spring"]
			if was_near < sp and near >= sp and air_t <= 0.0 and car_pos.distance_to(centre[sp]) < half_w * 0.7:
				if gate_open("fizzy", lvl):
					_jump(AIR_TIME * 1.6)                     # (a big hop: up to the balloon)
				else:
					_jump(AIR_TIME * 0.35)
					_show_banner("fizzy cars fly!", 0.8)
			if air_t > 0.2 and secret.has("gift") and car_pos.distance_to(centre[secret["at"]]) < 70.0 and gate_open("fizzy", lvl):
				_take_secret()
		"milky":
			var hit := false
			for cr in secret.get("crates", []):
				if is_instance_valid(cr) and car_pos.distance_to((cr as Sprite2D).position) < 44.0:
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
				elif slip_t <= 0.0:
					slip_t = SLIP_TIME * 0.6                   # (bounced off the crates)
					slip_heading = heading + PI
					_show_banner("sturdy cars smash!", 0.8)
			if secret.get("broken", false) and car_pos.distance_to((secret["gift"] as Sprite2D).position) < 50.0:
				_take_secret()
		"fruity":
			if car_pos.distance_to(centre[secret["at"]]) < 50.0:
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

## The rivals on the grid (behind the start line, side by side): toy cars in their own colours,
## a little helmeted driver each
const RIVAL_COLS := [[Color8(70, 130, 220), Color8(46, 92, 170)], [Color8(240, 200, 70), Color8(196, 150, 40)], [Color8(110, 190, 110), Color8(70, 140, 76)]]
func _spawn_rivals() -> void:
	for r in rivals:
		(r["node"] as Node).queue_free()
	rivals.clear()
	var n := int(extras.get("rivals", 0))
	var k := (level - 1) % GameData.LEVELS_PER_WORLD
	for j in n:
		var node := Node2D.new()
		front.add_child(node)
		var sl: Array = []
		var layers := _tinted_slices(RIVAL_COLS[j][0], RIVAL_COLS[j][1])
		for li in layers.size():
			var spr := Sprite2D.new()
			spr.texture = layers[li]
			spr.scale = Vector2(PX, PX)
			spr.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
			var kk := 0.62 + 0.38 * float(li) / (layers.size() - 1)
			spr.modulate = Color(kk, kk, kk)
			node.add_child(spr)
			sl.append(spr)
		var helmet := _px_sprite(_helmet_texture(RIVAL_COLS[j][0]), Vector2(0, -LAYERS * LAYER_UP - 4.0), 2)
		node.add_child(helmet)
		var light := Sprite2D.new()
		light.texture = headlight.texture if headlight else _cone_texture()
		light.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		var m := CanvasItemMaterial.new()
		m.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
		light.material = m
		light.scale = Vector2(PX, PX)
		light.visible = world_no == 5
		node.add_child(light)
		# on the grid: just behind the line, the lanes either side of the middle
		var lane: float = [-0.42, 0.42, 0.0][j]
		var back_pts := 8 + j * 7
		rivals.append({ "node": node, "slices": sl, "light": light, "progress": -float(back_pts), "lane": lane,
			"speed": SPEED * (0.95 + 0.02 * j + 0.005 * k), "heading": 0.0, "pos": Vector2.ZERO, "done": false })
	_place_rivals()

## A rival's place on the road from its progress (points along the centre line, laps included)
func _place_rivals() -> void:
	for r in rivals:
		var pr: float = r["progress"]
		var i := int(floorf(pr))
		var f := pr - i
		var a := centre[(i % count + count) % count]
		var b := centre[((i + 1) % count + count) % count]
		var dir := (b - a).normalized()
		var p := a.lerp(b, f) + Vector2(-dir.y, dir.x) * half_w * float(r["lane"])
		r["pos"] = p
		r["heading"] = dir.angle()
		var node: Node2D = r["node"]
		node.position = p.round()
		var air := _in_gap((i % count + count) % count)
		for li in r["slices"].size():
			(r["slices"][li] as Sprite2D).rotation = r["heading"]
			(r["slices"][li] as Sprite2D).position = Vector2(0, -li * LAYER_UP - (40.0 if air else 0.0))
		(r["light"] as Sprite2D).rotation = r["heading"]
		(r["light"] as Sprite2D).position = Vector2.from_angle(r["heading"]) * 92.0

## The rivals drive the racing line (a lane each), a little faster when behind you, a little slower
## when well ahead (close races); they bump into you (a sturdy car isn't shoved); your place
func _update_rivals(delta: float) -> void:
	if rivals.is_empty():
		return
	var ahead := 0
	for r in rivals:
		if not r["done"]:
			var gap: float = r["progress"] - progress
			var k := 1.0
			if gap > count * 0.12:
				k = 0.94
			elif gap < -count * 0.12:
				k = 1.06
			r["progress"] += r["speed"] * k * delta / STEP
			if r["progress"] >= count * LAPS:
				r["done"] = true
		if r["progress"] > progress:
			ahead += 1
		# a bump
		var d: Vector2 = car_pos - r["pos"]
		if d.length() < 46.0 and d.length() > 0.1 and air_t <= 0.0:
			var push := d.normalized() * (46.0 - d.length())
			if PetState.boost_power("sturdy") > 0:
				r["lane"] = clampf(r["lane"] - signf(push.dot(Vector2(-sin(r["heading"]), cos(r["heading"])))) * 0.08, -0.6, 0.6)
			else:
				car_pos += push * 0.9
				if _cheer_cd < 2.4:
					_sfx("res://sounds/fx/wood_tap.wav", -10.0, 0.8)
					Input.vibrate_handheld(20)
	place = ahead + 1
	_place_rivals()

## The rivals' cars: the red car's slices in another colour
func _tinted_slices(main: Color, dark: Color) -> Array[Texture2D]:
	var out: Array[Texture2D] = []
	for t in car_slices():
		var img: Image = t.get_image()
		for y in img.get_height():
			for x in img.get_width():
				var c := img.get_pixel(x, y)
				if c.a == 0.0:
					continue
				if c.is_equal_approx(Color8(226, 70, 64)):
					img.set_pixel(x, y, main)
				elif c.is_equal_approx(Color8(190, 46, 50)):
					img.set_pixel(x, y, dark)
				elif c.is_equal_approx(Color8(226, 70, 64).lightened(0.18)):
					img.set_pixel(x, y, main.lightened(0.18))
		out.append(ImageTexture.create_from_image(img))
	return out

func _px_sprite(t: Texture2D, pos: Vector2, k := PX) -> Sprite2D:
	var sp := Sprite2D.new()
	sp.texture = t
	sp.position = pos
	sp.scale = Vector2(k, k)
	sp.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	return sp

## Small pixel pieces (board px, x4): a springboard, a balloon, a crate, a sparkle, a helmet, the
## headlights' cone
func _rows_texture(rows: Array, cols: Dictionary) -> Texture2D:
	var img := Image.create(String(rows[0]).length(), rows.size(), false, Image.FORMAT_RGBA8)
	for y in rows.size():
		for x in String(rows[y]).length():
			var ch: String = rows[y][x]
			if cols.has(ch):
				img.set_pixel(x, y, cols[ch])
	return ImageTexture.create_from_image(img)

func _spring_texture() -> Texture2D:
	return _rows_texture([
		"############",
		"#rrrrrrrrrr#",
		"#RRRRRRRRRR#",
		"############",
		".#s#s#s#s#s.",
		".s#s#s#s#s#.",
		"############",
	], { "#": OUTLINE, "r": Color8(250, 140, 130), "R": Color8(226, 70, 64), "s": Color8(200, 204, 214) })

func _balloon_texture() -> Texture2D:
	return _rows_texture([
		"..#####..",
		".#wrrrr#.",
		"#wrrrrrr#",
		"#rrrrrrr#",
		"#rrrrrrd#",
		".#rrrdd#.",
		"..#ddd#..",
		"...###...",
		"....#....",
		"....#....",
		"...#.....",
		"...#.....",
		"....#....",
	], { "#": OUTLINE, "w": Color8(255, 220, 220), "r": Color8(236, 96, 120), "d": Color8(186, 60, 90) })

func _crate_texture() -> Texture2D:
	return _rows_texture([
		"##########",
		"#WWWWWWWW#",
		"#W#bbbb#d#",
		"#Wb#bb#bd#",
		"#Wbb##bbd#",
		"#Wbb##bbd#",
		"#Wb#bb#bd#",
		"#W#bbbb#d#",
		"#dddddddd#",
		"##########",
	], { "#": OUTLINE, "W": Color8(236, 196, 132), "b": Color8(206, 160, 98), "d": Color8(160, 116, 64) })

func _sparkle_texture() -> Texture2D:
	return _rows_texture([
		"....#....",
		"...#w#...",
		"..#wyw#..",
		"##wyyyw##",
		"#wyyyyyw#",
		"##wyyyw##",
		"..#wyw#..",
		"...#w#...",
		"....#....",
	], { "#": Color8(120, 80, 30), "w": Color8(255, 250, 220), "y": Color8(255, 220, 110) })

func _helmet_texture(c: Color) -> Texture2D:
	return _rows_texture([
		"..####..",
		".#cccc#.",
		"#cwcccc#",
		"#cccccc#",
		"#vvvvvv#",
		".#vvvv#.",
		"..####..",
	], { "#": OUTLINE, "c": c, "w": c.lightened(0.5), "v": Color8(40, 50, 70) })

## The headlights' light on the road: a soft cone in front of the car (added on; night only)
## A lamp post by the track (night): a dark pole, its lamp glowing warm
func _lamp_post_texture() -> Texture2D:
	return _rows_texture([
		".###.",
		"#yWy#",
		"#yyy#",
		".###.",
		"..#..",
		"..#..",
		"..#..",
		"..#..",
		".###.",
	], { "#": Color8(30, 30, 40), "y": Color8(255, 220, 130), "W": Color8(255, 252, 230) })

func _cone_texture() -> Texture2D:
	var img := Image.create(40, 26, false, Image.FORMAT_RGBA8)
	for y in 26:
		for x in 40:
			var u := float(x) / 40.0
			var v := absf(y - 12.5) / 12.5
			if v > u * 1.05 + 0.08:
				continue
			var a := (1.0 - u) * 0.5 * (1.0 - v * 0.6)
			a = floorf(a * 6.0) / 6.0
			if a > 0.0:
				img.set_pixel(x, y, Color(1.0, 0.92, 0.7, a))
	return ImageTexture.create_from_image(img)

## The rain over the view (Rain): streaks slanting down, a ripple now and then
class RainFx extends Node2D:
	var view := Rect2()
	var drops: Array = []
	func _ready() -> void:
		for i in 60:
			drops.append([randf_range(0, 950), randf_range(0, 948), randf_range(700, 980)])
	func _process(delta: float) -> void:
		if not visible:
			return
		for d in drops:
			d[1] += d[2] * delta
			d[0] -= d[2] * 0.18 * delta
			if d[1] > view.end.y:
				d[1] = view.position.y - randf_range(0, 60)
				d[0] = randf_range(view.position.x, view.end.x + 120)
		queue_redraw()
	func _draw() -> void:
		for d in drops:
			var p := Vector2(d[0], d[1]).snapped(Vector2(4, 4))
			if view.has_point(p):
				draw_rect(Rect2(p, Vector2(4, 20)), Color(0.82, 0.88, 0.94, 0.45))

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
