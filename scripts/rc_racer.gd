extends BaseMinigame
## Pal Prix (Pipe Dream's rework, on its card) — your pal rides a little RC toy round a race
## course, seen from above at an angle and close up (Micro Machines): a CAR on a track raised above
## the floor, a BOAT down a buoyed channel on the water, a PLANE through rings in the sky. It goes
## by itself at its own speed; hold ORANGE to turn left, FORWARD to turn right (all the way round:
## the courses wind, double back and hairpin). 3 laps. The toys are "sprite-stacked": a pile of
## pixel slices, each turned with the toy and drawn a little higher, so it shows its sides and looks
## solid as it turns.
##
## Courses: a random patch of grid squares (grown square by square from a seed), and the course
## runs round its outline, every corner rounded (a quarter circle of half a square: two corners a
## square apart make a hairpin). An outline never crosses itself, and any two stretches of it are
## at least a square apart, so the road never touches itself. More squares = more turns, U-turns
## and zig-zags; the best of SEED_TRIES patches (the most corners). The mats are always bigger than
## the screen, with room round the course (the user, 2026-10-17: bigger circuits, the edges not
## too close): the view follows the toy and shows only part of it, so you read the road as it comes.
##
## Levels (the level menu, BaseMinigame / LevelMenu): 6 worlds of 9, two per toy (the user,
## 2026-10-17), in the order car, boat, plane, then each toy's second world (the user, 2026-10-18:
## every toy early on), each with its own place, its light and its own things (alone on their
## first levels, then mixed in):
##   1 Garden (a morning, the car): the basics, guard rails on the corners · boost pads (4th) ·
##     JUMPS, a ramp before each gap (7th: straight on it or you fall)
##   2 Lagoon (sunset, the boat): it drifts (it carries on the way it was going a moment), the
##     buoys mark the channel, the shallows past them slow it, the sandbank beyond is a crash ·
##     CURRENTS that speed it on (4th) · RAMPS over sandbars (7th: straight on them, or it runs aground)
##   3 Sky (noon above the fields, the plane): RINGS to fly through (a ring missed = a crash) ·
##     GUSTS that blow it sideways (4th) · hot-air BALLOONS in the way (7th)
##   4 Night Race (the lamps and your headlights): CROSSOVERS, figure-8s with a bridge · rain,
##     PUDDLES that spin the car, OIL (4th) · RIVALS, up to three cars to beat (7th)
##   5 Reef (noon, the boat): ROCKS and LOGS in the channel (a crash), WHIRLPOOLS (4th) · RIVALS (7th)
##   6 Grand Prix (the masters' world, a sunset over a sea of clouds): rival planes, STORM clouds
##     (a crash), everything of the sky mixed in
## Guard rails (the car, the user 2026-10-17): on the outer side of the Garden's corners (from its
## 5th level only round the hairpins, the tightest), and the Night Race's hairpins up to its 6th.
## Lives (BaseMinigame): 3 hearts. A crash (a car off the track, a boat on a rock or a sandbar, a
## plane missing a ring or into a balloon, a storm) breaks one and puts the toy back on the last
## checkpoint (the clock keeps going); the last one ends the race (Out of lives!: retry from the
## start). A SPLASH pal has a 4th, a water heart: its first crash is undone on the spot.
## Stars: 1 = finished, +1 = within the par time (with rivals: 1st place), +1 = no crash at all.
## No points: the race's own clock and the laps say how it goes; the best time is saved.
## Drinks: SPLASH (above) · FIZZ: a springboard's (a ramp's) jump, a fizzy plane climbs (a secret:
## a gift up on a balloon) · FOCUS: time slows a moment as a crash is coming (once) · STURDY: no
## spinning on oil, puddles or in whirlpools, rivals don't shove it, it breaks through crates, a
## sturdy plane flies through a storm (a secret) · LUCKY: it sees the gift hidden on the course (a
## secret).
## The crowd by the finish line are your own pals (the ones you've found), cheering; a crash near
## them and they scream and scatter (the user, 2026-10-17).
## Desktop: Left / Right arrows (or A / D).

const PX := 4                         # world px per board px (the games' chunky grid)
## A grid square, world px (the road stays a square from itself), per toy: the faster, the roomier
const CELLS := { "car": 360.0, "boat": 380.0, "plane": 440.0 }
const EDGE := 10                      # the mat's wooden frame, board px
const MARGIN := 150.0                 # road edge -> frame, world px (room round the course)
const SPEED := 580.0                  # mat px/s, always
const TURN := 6.2                     # rad/s while a button is held (a full turn in 1 s; turning
                                      # circle ~94 px, inside the circuits' 150 px corners)
const ZOOM := 1.5                     # the view, close up (board px shown 6 px)
const LOOK_AHEAD := 260.0             # the view looks this far ahead of the car (mat px)
const FALL_AT := 6.0                  # past the road's edge by this much: off the track
const TIP_OUT := 48.0                 # a falling car first tips this far out, clear of the edge
const CHECKPOINTS := 10               # per lap: where a fallen car is put back
const TRACK_SIDE := 6                 # the raised track's side face, board px (seen from the south)
const LAYERS := 6                     # the car's slices (the boat 5, the plane 4)
const LAYER_UP := 2.5                 # each slice this much higher (mat px)
const LAPS := 3
const STEP := 8.0                     # centre-line points, every STEP px
const SEED_TRIES := 30
const PAR_SLACK := 1.03               # par time = a clean drive's time x this, + PAR_PLUS: the
const PAR_PLUS := 1.0                 # 2nd star only for a near-perfect run (no curbs, clean lines)
## ...per toy (the boat drifts wide; the plane cuts the corners), and the seconds each
## thing in the way costs a lap (going round it)
const PAR_SLACKS := { "car": 1.03, "boat": 1.2, "plane": 1.06 }
const PAR_PER_THING := { "rock": 0.6, "log": 0.6, "whirl": 0.5, "balloon": 0.4, "storm": 0.5 }
const CURB_TOUCH := 26.0              # the car's body on the curb (this close to the road's edge)...
const CURB_SLOW := 0.72               # ...slows it to this
const BOOST := 0.6                    # a boost pad: this much faster...
const BOOST_TIME := 1.4               # ...fading out over this long
const PAD_LEN := 64.0                 # a pad's length along the road (mat px)
const PAD_SAVES := 0.35               # (par: seconds a pad saves, each lap)
const COUNTDOWN := 3
## The boat: a little slower, a wider turn, and it drifts (BOAT_GRIP: how fast it takes up the way it
## points, per second). The buoys only mark the channel's edge (the user, 2026-10-18: the boat
## could never leave the course nor lose a heart): past them the shallows slow it (SHALLOW_SLOW,
## its hull SHALLOW_IN inside the buoys), and SHORE_AT past them it runs onto the bank (the
## Lagoon's sand, the Reef's coral): a crash. The bank is painted SHORE_PAINT past the buoys (the
## bow reaches it as the boat's middle reaches SHORE_AT).
const BOAT_SPEED := 520.0
const BOAT_TURN := 5.0
const BOAT_GRIP := 3.4
const SHALLOW_IN := 10.0
const BUOY_GAP := 12.0                # a buoy every this far along the channel's edge, board px
const SHALLOW_SLOW := 0.7
const SHORE_AT := 36.0
const SHORE_PAINT := 52.0
## The plane: faster, a wide turn, free in the sky (CORRIDOR: how far from the course's line it may
## stray before it's turned back); its rings (RING_GAP apart along the course)
const PLANE_SPEED := 660.0
const PLANE_TURN := 4.3
const CORRIDOR := 2.3
const RING_GAP := 760.0
const PARALLAX := 0.55                # the plane's ground scrolls this much as fast as the sky (far below)
## The view under the HUD (play-area px) and the HUD's band above it
const VIEW := Rect2(27, 92, 896, 830)
const HUD_BAND := Rect2(27, 26, 896, 66)

const WORLDS := ["Garden", "Lagoon", "Sky", "Night Race", "Reef", "Grand Prix"]
## Each world's toy and its place (the floor, the light: _paint)
const VEHICLES := ["car", "boat", "plane", "car", "boat", "plane"]
const LOOKS := ["garden", "lagoon", "sky", "night", "reef", "sunset"]
## What each world brings, said on its first level
const WORLD_HINTS := ["", "a boat! it drifts", "fly through the rings!", "crossovers!", "rocks: steer clear!", "the Grand Prix!"]
## ...and what joins in later in a world (its 4th and its 7th level)
const LATER_HINTS := [["boost pads!", "jumps! ramps straight"], ["currents!", "ramps! hit them straight"],
	["gusts blow you!", "balloons ahead!"], ["rain! puddles spin you", "beat the rivals!"], ["whirlpools!", "beat the rivals!"], ["", ""]]
## Each world's page in the level menu
const WORLD_BACKDROPS := [Color8(150, 196, 120), Color8(232, 150, 120), Color8(170, 204, 230), Color8(44, 46, 82), Color8(110, 200, 196), Color8(236, 150, 110)]
## The courses, 9 per world: [grid columns, rows, squares in the patch, road half-width px, a fixed
## shape or null, corners wanted, boost pads (a boat: currents), extras]. The first ones of a toy's
## first world are fixed shapes, long straights and few turns: an oval, an L, a U (its first
## hairpin); then grown patches, each level a bigger patch and more corners (the patch closest to
## that many), so the courses get longer and twistier step by step.
## extras: "rails" ("all" corners / "hairpins": the car's guard rails), "jumps" (gaps with a ramp;
## a boat: sandbars), "oil" (slicks), "puddles", "rain", "rivals", "eight" (a figure-8: [loop A's
## width, height, loop B's width, height, notches], in squares, instead of a patch), "rocks", "logs",
## "whirls" (the boat's), "ring_r" (a plane's rings' size), "gusts", "balloons", "storms".
const LEVELS := [
	# 1 Garden (the car): the basics, rails on every corner; pads from the 4th, jumps from the 7th
	[6, 2, 0, 104.0, [Rect2i(0, 0, 6, 2)], 0, 0, { "rails": "all" }],
	[6, 4, 0, 102.0, [Rect2i(0, 0, 6, 2), Rect2i(0, 2, 2, 2)], 0, 0, { "rails": "all" }],
	[6, 4, 0, 100.0, [Rect2i(0, 0, 6, 2), Rect2i(0, 2, 2, 2), Rect2i(4, 2, 2, 2)], 0, 0, { "rails": "all" }],
	[8, 4, 14, 98.0, null, 10, 2, { "rails": "all" }],
	[8, 5, 16, 94.0, null, 12, 2, { "rails": "hairpins" }],
	[9, 5, 18, 92.0, null, 14, 3, { "rails": "hairpins" }],
	[9, 5, 18, 92.0, null, 14, 2, { "rails": "hairpins", "jumps": 1 }],
	[9, 6, 21, 88.0, null, 16, 2, { "rails": "hairpins", "jumps": 2 }],
	[10, 6, 24, 86.0, null, 18, 3, { "rails": "hairpins", "jumps": 2 }],
	# 2 Lagoon (the boat): it drifts; currents from the 4th, ramps over sandbars from the 7th
	[6, 2, 0, 118.0, [Rect2i(0, 0, 6, 2)], 0, 0],
	[6, 4, 0, 116.0, [Rect2i(0, 0, 6, 2), Rect2i(0, 2, 2, 2)], 0, 0],
	[6, 4, 0, 114.0, [Rect2i(0, 0, 6, 2), Rect2i(0, 2, 2, 2), Rect2i(4, 2, 2, 2)], 0, 0],
	[8, 4, 14, 112.0, null, 10, 2],
	[8, 5, 16, 110.0, null, 12, 2],
	[9, 5, 18, 108.0, null, 14, 3],
	[9, 5, 18, 108.0, null, 14, 2, { "jumps": 1 }],
	[9, 6, 21, 104.0, null, 16, 2, { "jumps": 2 }],
	[10, 6, 24, 102.0, null, 18, 3, { "jumps": 2 }],
	# 3 Sky (the plane): rings; gusts from the 4th, balloons from the 7th
	[6, 2, 0, 130.0, [Rect2i(0, 0, 6, 2)], 0, 0, { "ring_r": 124.0 }],
	[6, 4, 0, 130.0, [Rect2i(0, 0, 6, 2), Rect2i(0, 2, 2, 2)], 0, 0, { "ring_r": 120.0 }],
	[6, 4, 0, 130.0, [Rect2i(0, 0, 6, 2), Rect2i(0, 2, 2, 2), Rect2i(4, 2, 2, 2)], 0, 0, { "ring_r": 116.0 }],
	[8, 4, 14, 130.0, null, 10, 0, { "ring_r": 112.0, "gusts": 1 }],
	[8, 5, 16, 130.0, null, 12, 0, { "ring_r": 108.0, "gusts": 2 }],
	[9, 5, 18, 130.0, null, 14, 0, { "ring_r": 104.0, "gusts": 2 }],
	[9, 5, 18, 130.0, null, 14, 0, { "ring_r": 104.0, "gusts": 2, "balloons": 2 }],
	[9, 6, 21, 130.0, null, 16, 0, { "ring_r": 100.0, "gusts": 2, "balloons": 3 }],
	[10, 6, 24, 130.0, null, 18, 0, { "ring_r": 96.0, "gusts": 3, "balloons": 3 }],
	# 4 Night Race (the car): figure-8s; rain, puddles and oil from the 4th; rivals from the 7th
	[0, 0, 0, 100.0, null, 0, 0, { "eight": [2, 2, 2, 2, 0], "rails": "hairpins" }],
	[0, 0, 0, 98.0, null, 0, 0, { "eight": [3, 2, 2, 2, 0], "rails": "hairpins" }],
	[0, 0, 0, 96.0, null, 0, 1, { "eight": [3, 2, 3, 2, 1], "rails": "hairpins" }],
	[9, 5, 18, 92.0, null, 14, 1, { "rain": true, "puddles": 2, "rails": "hairpins" }],
	[9, 6, 21, 90.0, null, 16, 1, { "rain": true, "puddles": 3, "oil": 1, "rails": "hairpins" }],
	[0, 0, 0, 90.0, null, 0, 2, { "eight": [3, 3, 3, 3, 1], "rain": true, "puddles": 3, "oil": 1, "rails": "hairpins" }],
	[9, 6, 21, 88.0, null, 16, 2, { "rivals": 1, "oil": 1 }],
	[0, 0, 0, 86.0, null, 0, 2, { "eight": [4, 3, 3, 3, 2], "rain": true, "rivals": 2, "puddles": 2, "jumps": 1 }],
	[10, 7, 27, 84.0, null, 20, 3, { "rain": true, "rivals": 3, "puddles": 3, "oil": 2, "jumps": 2 }],
	# 5 Reef (the boat): rocks and logs; whirlpools from the 4th; rivals from the 7th
	[8, 4, 14, 112.0, null, 10, 0, { "rocks": 2 }],
	[8, 5, 16, 110.0, null, 12, 1, { "rocks": 3 }],
	[9, 5, 18, 108.0, null, 14, 1, { "rocks": 3, "logs": 1 }],
	[9, 5, 18, 108.0, null, 14, 1, { "rocks": 2, "whirls": 1 }],
	[9, 6, 21, 106.0, null, 16, 2, { "rocks": 3, "logs": 1, "whirls": 2 }],
	[9, 6, 21, 104.0, null, 16, 2, { "rocks": 3, "whirls": 2 }],
	[9, 6, 21, 104.0, null, 16, 2, { "rivals": 1, "rocks": 3 }],
	[10, 6, 24, 102.0, null, 18, 2, { "rivals": 2, "rocks": 3, "logs": 1, "whirls": 2, "jumps": 1 }],
	[10, 7, 27, 100.0, null, 20, 3, { "rivals": 3, "rocks": 4, "logs": 2, "whirls": 2, "jumps": 1 }],
	# 6 Grand Prix (the plane, the masters' world): rival planes, storms, everything
	[8, 5, 16, 130.0, null, 12, 0, { "ring_r": 104.0, "rivals": 1, "gusts": 1 }],
	[9, 5, 18, 130.0, null, 14, 0, { "ring_r": 100.0, "rivals": 1, "storms": 1 }],
	[9, 5, 18, 130.0, null, 14, 0, { "ring_r": 100.0, "rivals": 2, "storms": 2, "gusts": 1 }],
	[0, 0, 0, 130.0, null, 0, 0, { "eight": [3, 3, 3, 3, 1], "ring_r": 96.0, "rivals": 2, "balloons": 2, "gusts": 2 }],
	[9, 6, 21, 130.0, null, 16, 0, { "ring_r": 96.0, "rivals": 3, "storms": 2, "balloons": 2 }],
	[9, 6, 21, 130.0, null, 16, 0, { "ring_r": 92.0, "rivals": 3, "storms": 2, "gusts": 2 }],
	[0, 0, 0, 130.0, null, 0, 0, { "eight": [4, 3, 4, 3, 2], "ring_r": 92.0, "rivals": 3, "storms": 3, "balloons": 3 }],
	[10, 6, 24, 130.0, null, 18, 0, { "ring_r": 88.0, "rivals": 3, "storms": 3, "gusts": 3, "balloons": 3 }],
	[10, 7, 27, 130.0, null, 20, 0, { "ring_r": 86.0, "rivals": 3, "storms": 3, "gusts": 3, "balloons": 4 }],
]
## Secrets (a world's 6th level; BaseMinigame): a gift up on a balloon over the course (a fizzy car
## jumps the springboard to it, a fizzy plane climbs to it), a gift behind a crate wall in a side bay
## (a sturdy boat rams through), a gift inside a storm cloud (a sturdy plane flies through), a gift
## on the water only a lucky boat sees. Finales: Phoenix Pepper (5-9, now the Reef's: every game's
## legendary food is its 5-9 finale), the case (6-9). (The secrets went with their worlds when the
## worlds were reordered, 2026-10-18.)
const SECRETS := {
	15: ["milky", "food:Battery"], 24: ["milky", "food:Moon Rock"], 33: ["fizzy", "sticker:traffic_cone"],
	42: ["fruity", "sticker:rubber_duck"], 51: ["fizzy", "sticker:gold_cup"],
}
const FINALES := { 45: "food:Phoenix Pepper", 54: "case:prix" }
const GAP_LEN := 120.0                # a jump's gap along the road (mat px)
const RAMP_LEN := 72.0                # the ramp before it (RC NEW ART: as long as drawn, _ramp_len)
const AIR_TIME := 0.42                # a jump (or a springboard) in the air
const SLIP_TIME := 0.7                # oil / a puddle: the spin round and the stop
const SLICK_R := 46.0                 # an oil slick's / a puddle's size on the road

# --- the Playroom's look (the Tilt Maze rules: hard pixels, a 2 px dark outline, top-left light) ---
const CARPET := [Color8(118, 146, 176), Color8(108, 134, 164), Color8(130, 158, 188)]
const ROAD := [Color8(112, 108, 118), Color8(100, 96, 106)]
const LINE := Color8(244, 240, 226)
const CURB := [Color8(226, 70, 64), Color8(246, 242, 232)]
## The guard rail: a row of tyres just outside the road's edge (dark rubber, a lit rim, the hole;
## every other one painted red or white, like a race track's tyre wall)
const TYRE := [Color8(40, 34, 44), Color8(62, 58, 70), Color8(96, 92, 104), Color8(24, 20, 28)]
const TYRE_PAINT := [Color8(60, 112, 196), Color8(246, 242, 232)]    # the barrier's belt panels
const TYRE_R := 4.5                   # a tyre's radius, board px (its sprite 9 px across)
const RAIL_BELT := 3.5                # the barrier's belt in front of the tyres, board px
const TYRE_STEP := 8.0                # one every this far along the edge, board px (they touch)
const OUTLINE := Color8(40, 34, 44)
const PAD := [Color8(252, 210, 64), Color8(226, 150, 40), Color8(70, 64, 78)]    # chevrons, their edge, the plate
const SIDE := [Color8(236, 150, 64), Color8(198, 110, 44), Color8(150, 78, 34)]    # the track's orange plastic side
const BLOCK := [Color8(246, 214, 92), Color8(206, 168, 60)]                          # the yellow toy blocks under it
## The track's side face per place: [lit, mid, shade, a support, its shade] (the Garden's orange
## plastic on yellow blocks; the night's dark on red posts)
const SIDES := {
	"garden": [Color8(236, 150, 64), Color8(198, 110, 44), Color8(150, 78, 34), Color8(246, 214, 92), Color8(206, 168, 60)],
	"night": [Color8(92, 96, 132), Color8(70, 72, 104), Color8(48, 50, 76), Color8(236, 96, 84), Color8(170, 60, 56)],
}
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
var qa_hands_off := false              # (tools/qa hands=off: nobody steers)
var world_no := 0                      # which world (0 Garden, 1 Lagoon, 2 Sky...)
var course_seed := 1                   # what this level's course grows from: its number before the worlds were
									   # reordered (2026-10-18), so every course stays the one it was balanced on
const OLD_WORLD := [0, 2, 4, 1, 3, 5]  # (each world's place in the old order: Garden, Night Race, Lagoon, Reef, Sky, Grand Prix)
var vehicle := "car"                   # its toy: "car" / "boat" / "plane" (VEHICLES)
var look := "garden"                   # its place (LOOKS): the floor, the light
var cell := 360.0                      # a grid square for this toy (CELLS)
var rain := false                      # (a wet Night Race)
var vel := Vector2.ZERO                # the boat: where it's really going (it drifts)
var bank := 0.0                        # the plane: its lean in the turns (-1 .. 1)
var _buoy_cd := 0.0                    # (the scrape in the shallows, the bump on a rail)
var rings: Array = []                  # the plane's: { i (centre point), pos, n (across), r, lap (last judged), hit, back, front }
var obstacles: Array = []              # rocks, logs (the boat), balloons, storms (the plane): { kind, i, pos, base, r, (a, b: a log), node }
var gusts: Array = []                  # the plane's: [first centre point, last, the side it blows to]
var _grace_t := 0.0                    # (just put back: nothing hits it for a moment)
var _t := 0.0                          # (the race's own clock for the drifting balloons, the storms' flashes)
var pads: Array = []                   # boost pads: [centre (mat px), direction along the road]
var boost_t := 0.0                     # the boost left (1 = just hit a pad)
var bump_t := 0.0                      # just bounced off a barrier (1), fading
var bounce_t := 0.0                    # (the bounce off a barrier: its time left, the way it turns to, its push)
var bounce_to := 0.0
var knock_v := Vector2.ZERO
var curb_t := 0.0                      # (the rumble's ticks)
var _on_pad := false
var half_w := 70.0
## RC NEW ART (the dev launcher's trial, RcTiles): the Garden from the designer's square pieces
var _tiles := {}                       # grid point -> its piece
var _tile_pad := 0.0                   # grid point (0, 0) on the mat, world px
var _start_square := Vector2i(-1, -1)
var _pad_squares: Array = []           # [grid point, direction]
var _gap_squares: Array = []           # [grid point, direction]
var _rail_squares := {}                # corner squares with a tyre wall
var _tile_shadow: Sprite2D             # the raised track's shadow on the lawn (a dark copy of it)
var _tree_shade: Sprite2D              # the trees' shade over the lawn and the road
var _slice_px := float(PX)             # the toy's slices' pixel size (the designer's car: finer)
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
var more_stands: Array[Crowd] = []     # RC NEW ART: more stands round the course (the user: more than one)
const MORE_STANDS := 2                 # at most this many more
## Every stand showing
func _stands() -> Array:
	return ([crowd] + more_stands).filter(func(c): return c.visible)
var _cheer_cd := 0.0
# (the user, 2026-10-28: the wave wasn't always seen) it starts while the car is still coming along the stand,
# a bit before its end; only from the track right by it (420 all round set it off from other parts of the track)
const CHEER_ACROSS := 40.0            # how far past the road's far edge the car may be (the reach covers the whole road:
                                      # 170 from the stand missed a car on the far side of the wide early roads)
const CHEER_AHEAD := 320.0            # how far before (or past) the stand's ends, along it (was 170)
const CHEER_CD := 2.5
var look_k := 0.0                      # how much the view looks ahead (0 at the start)
var behind: Node2D                     # under the track: where a car falling off its far side goes
var front: Node2D                      # over the track: the car
var canopy: Sprite2D                   # the Garden's branches over everything
var atmosphere: RcAtmosphere            # the Garden's air: clouds' shadows, sun, beams, mist (dev launcher FX)
var ring_back: Node2D                  # the plane's rings: their lower halves (under it)...
var ring_front: Node2D                 # ...and their upper ones (over it)
var gust_fx: GustFx                    # the wind's streaks across the course
var air_fx: AirFx                      # the plane's: the air rushing past it
var sky_dock: SkyDock                  # ...and the deck its race starts from
var guide: FlightGuide                  # the plane's: the sparkles to its next rings
var buoys: FloatingBuoys                # the boat's: the buoys along the channel
var water_fx: WaterFx                   # ...the water's glints, its whirlpools turning
var pointer: RingPointer                # ...and the arrow to the next one off the screen
var sky_shadow: Sprite2D               # the plane's shadow on the ground far below (it moves with the ground)
var car: Node2D
var slices: Array[Sprite2D] = []       # the car, bottom slice first
var driver: Sprite2D
var prop: Sprite2D                     # the plane's propeller, spinning at its nose
var _prop_frame := 0
var shadow: Sprite2D
var car_drop := 0.0                    # how far the car has fallen (screen down, mat px)
var _wrecked := false                  # fallen / sunk and not put back yet: no shadow (the user: out of
                                       # lives, the shadow came back beside the fallen toy)
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
var lettering: RcLettering             # the race messages in the designer's racing font, when it has the letters
var motor: AudioStreamPlayer
var lights: Node2D                     # the start lights over the view (3 red, then all green)
var lamps: Array[Sprite2D] = []
var _ramp_len := RAMP_LEN             # where the car counts as on a ramp, before its gap (world px)
var butterflies: RcButterflies         # RC NEW ART: the Garden's butterflies
var _gantry_box: Array = []            # the drawn gantry (its two rects), hidden when the designer's is in
var _gantry_art: Sprite2D              # RC NEW ART: the designer's gantry (start_gantry.png)
var _art_lights := false               # the lamps are the designer's three states (start_lamp_off/red/green)
var hint_left: HBoxContainer           # the controls along the bottom (shown at the start)
var hint_right: HBoxContainer
var lcd_font: Font
var _stars_shown := 3

## The little grandstand by the finish line and its crowd: pals of every kind (their balls, the
## games' pal balls: a different mix every race, the user 2026-10-18), your own pals often among
## them, in five rows stepping up away from the track. They hop when the car goes
## by (a wave that runs along the stand from the car), at GO, and all together at the finish; a
## crash near them and they scream (a jump, a shake, a "!") and scatter a little, then settle back
## (the user, 2026-10-17). The stand per toy: wooden tiers under an awning (the car), the same on a
## pier over the water (the boat), a cloud (the plane).
class Crowd extends Node2D:
	const OUTLINE := Color8(40, 34, 44)
	const TIERS := 5                      # rows of seats
	const ROW := 24.0                     # a row's depth (px)
	const BACK := 16.0                    # the awning
	const SEAT := 30.0                    # a pal's seat along a row
	const FLAGS := [Color8(226, 70, 64), Color8(252, 210, 64), Color8(90, 160, 230), Color8(120, 196, 110)]   # the little flags some wave
	var rect := Rect2()                  # the stand, mat px (axis-aligned)
	var along_x := true                  # the stand runs left-right (else up-down)
	var dots: Array = []                 # [position, its pal (pals index), when it hops (s), how many hops, scared until (s), its scatter, the hop's height, its own beat, its next idle hop (s), its flag (-1: none)]
	var cheer_cd := 0.0                   # till the car can set off its next wave (s)
	var pier := false                     # RC ART's Lagoon: the stand on a wooden pier, its posts in the water
	var sky := false                      # RC ART's Sky: the stand sitting in a cloud (RcSky), its canopy light blue
	var _legs: Array[Vector2] = []        # ...the stand's own legs' feet (world px), found as it's drawn (the last frame's:
	var _legs_next: Array[Vector2] = []   # a back view's legs are in its top layer, drawn after the pier)
	static var _leg_cache := {}           # a stand piece -> its legs: [x, foot y] in its own px
	var watch := Vector2.ZERO             # where the toy is (mat px): they lean its way, hop more when it's near
	var pals: Array[Texture2D] = []
	var t := 0.0
	var party := false                   # (the finish: everyone keeps bouncing)
	var away := Vector2.UP                # from the track towards the stand's back
	var style := "stand"                  # "stand" / "pier" / "cloud"
	var art := false                      # RC NEW ART: the designer's stand pieces and flags (NOTES_ROUND_13)
	const ART_DEPTH := 107                # the stand pieces' depth, art px (tools/art/rcprix_stand_from_reference.py)
	const ART_SCALE := 1.0                # the course's pixel size (the user: 1.5x was too big, 1x the right call)
	const ART_SEAT := 52.0                # a pal's seat along a bench (world px): one pal each, side by side
	const ART_SIDE_IN := 40.0             # the first and last seats this far in from the stand's ends (world px)
	const ART_SEATS := [30, 47, 64, 81]   # its four benches' tops, art px from its back (the awning)
	const ART_SEATS_BACK := [13, 26, 52]  # from behind: the benches with room for a row (the far one too near the track); the
	                                      # nearest row low enough for the canopy to hide their lower half (the user)
	const ART_CANOPY_BACK := 48           # from behind: the canopy's top, art px
	const ART_ROOF_FLAGS := [6, 43]       # roof flags over the end frame and over each middle's post, art px along
	const ART_ROOF_ENDS := { "back": [6, 6] }   # the end flags, art px in from each end, where its awning reaches
	const ART_ROOF_ENDS_FRONT := [18, 23] # (the front's awning starts on end_a's corner post, ends inside end_b)
	var _backs := {}                      # pal texture -> its back view (seen from behind)
	func setup(r: Rect2, horizontal: bool, seed_n: int, away_dir := Vector2.UP, kind := "stand", air := Color(0.8, 0.88, 0.95)) -> void:
		rect = r
		haze = air
		along_x = horizontal
		away = away_dir
		style = kind
		texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		dots.clear()
		_hue_cache.clear()
		party = false
		pals.clear()
		var rng := RandomNumberGenerator.new()
		rng.seed = seed_n
		# your pals first (a seat in three is one of them), then a dozen others picked at random
		var mine: Array[Texture2D] = []
		for id in PetState.discovered:
			var path := "res://textures/minigames/balls/%s.png" % id
			if ResourceLoader.exists(path):
				mine.append(load(path))
		var others: Array = PetState.FORMS.keys().filter(func(id): return id not in PetState.discovered)
		for i in range(others.size() - 1, 0, -1):
			var j := rng.randi() % (i + 1)
			var tmp = others[i]
			others[i] = others[j]
			others[j] = tmp
		# (the others: the pals whose colours go with this place, the user 2026-10-19: picked from
		# the 24 nearest the world's colours, 14 of them at random)
		var scored: Array = []
		for id in others:
			var path2 := "res://textures/minigames/balls/%s.png" % id
			if ResourceLoader.exists(path2):
				var tx2: Texture2D = load(path2)
				scored.append([_colour_gap(tx2, haze), tx2])
		scored.sort_custom(func(x, y): return x[0] < y[0])
		var pool := scored.slice(0, 24)
		for i2 in range(pool.size() - 1, 0, -1):
			var j2 := rng.randi() % (i2 + 1)
			var tmp2 = pool[i2]
			pool[i2] = pool[j2]
			pool[j2] = tmp2
		var crowd_mix: Array[Texture2D] = []
		for e in pool:
			if crowd_mix.size() >= 14:
				break
			crowd_mix.append(e[1])
		pals.append_array(mine)
		pals.append_array(crowd_mix)
		if pals.is_empty():
			pals.append(PalBall.texture())
		var n_mine := mine.size()
		var long := r.size.x if horizontal else r.size.y
		if art and style == "stand":
			# the designer's stand: each bench filled along its length as people sit (the user, 2026-10-28:
			# more of them, not spread so mathematically): from a different place on each bench, friends
			# squeezed together, others a little apart, now and then a gap, each sitting a touch differently
			for row in _art_rows().size():
				var a := ART_SIDE_IN + rng.randf_range(0.0, ART_SEAT * 0.6)
				while a <= long - ART_SIDE_IN:
					if rng.randf() < 0.06:
						a += ART_SEAT * rng.randf_range(0.6, 1.2)   # (a gap)
						continue
					var at := a
					a += ART_SEAT * (rng.randf_range(0.68, 0.8) if rng.randf() < 0.45 else rng.randf_range(0.82, 1.08))
					var b := _art_seat(row) + rng.randf_range(-2.0, 1.0)
					var p := r.position + (Vector2(at, b) if horizontal else Vector2(b, at))
					var who := rng.randi() % pals.size()
					if n_mine > 0 and (rng.randf() < 0.33 or n_mine == pals.size()):
						who = rng.randi() % n_mine
					elif pals.size() > n_mine:
						who = n_mine + rng.randi() % (pals.size() - n_mine)
					var flag := rng.randi_range(0, FLAGS.size() - 1) if rng.randf() < 0.18 else -1
					dots.append([p.round(), who, -10.0, 1, -10.0, Vector2.ZERO, 20.0, rng.randf() * TAU, rng.randf() * 3.0, flag, _hued(who, 0)])
		for tier in (0 if art and style == "stand" else TIERS):
			var n := int((long - 36.0) / SEAT)
			for k in n:
				if rng.randf() < 0.12:
					continue                  # (a few empty seats)
				var a := 26.0 + k * SEAT + (SEAT / 2.0 if tier % 2 else 0.0)
				if a > long - 18.0:
					continue
				var b := _art_seat(tier) if art and style == "stand" else _tier_at(tier) + 10.0
				var p := r.position + (Vector2(a, b) if horizontal else Vector2(b, a))
				var who := rng.randi() % pals.size()
				if n_mine > 0 and (rng.randf() < 0.33 or n_mine == pals.size()):
					who = rng.randi() % n_mine
				elif pals.size() > n_mine:
					who = n_mine + rng.randi() % (pals.size() - n_mine)
				var flag := rng.randi_range(0, FLAGS.size() - 1) if rng.randf() < 0.22 else -1
				# (the user, 2026-10-18: a little less in the way, more colourful: each pal through a
				# colour filter of its own, a bright hue, a touch softer than the race)
				# (each seat its pal in its own colours: the pal's colours turned round the rainbow, a
				# little brighter; the whole stand a touch see-through, behind the race)
				var hue := 0
				dots.append([p.snapped(Vector2(4, 4)), who, -10.0, 1, -10.0, Vector2.ZERO, 20.0, rng.randf() * TAU, rng.randf() * 3.0, flag, _hued(who, hue)])
		# (drawn back to front: the far rows first)
		dots.sort_custom(func(x, y): return x[0].y < y[0].y)
		queue_redraw()
	## A pal's ball with its colours turned round the rainbow (0 = as it is): its outline and its
	## eyes (the dark and the grey) kept, the rest shifted, a little more saturated
	const HUES := 6
	const HAZE := 0.38                     # how far the crowd fades into the world's air
	var haze := Color(0.8, 0.88, 0.95)
	var _hue_cache := {}
	func _hued(who: int, hue: int) -> Texture2D:
		return pals[who]                         # (their own colours: the user, 2026-10-19)
		var key := Vector2i(who, hue)
		if _hue_cache.has(key):
			return _hue_cache[key]
		var tex: Texture2D = pals[who]
		var img := tex.get_image()
		img.decompress()
		img.convert(Image.FORMAT_RGBA8)
		for y in img.get_height():
			for x in img.get_width():
				var c := img.get_pixel(x, y)
				if c.a < 0.1:
					continue
				# (the user, 2026-10-19: in the tones of the world's air, as if seen from far:
				# every colour, its outline too, faded towards the haze)
				img.set_pixel(x, y, c)
		var out := ImageTexture.create_from_image(img)
		_hue_cache[key] = out
		return out
	## How far a pal's ball is from a place's colour: its main colour (the average of its bright,
	## coloured px) against the place's hue and lightness
	func _colour_gap(tex: Texture2D, place: Color) -> float:
		var img := tex.get_image()
		img.decompress()
		var sum := Color(0, 0, 0, 0)
		var n := 0
		for y in range(0, img.get_height(), 2):
			for x in range(0, img.get_width(), 2):
				var c := img.get_pixel(x, y)
				if c.a > 0.5 and c.v > 0.35:
					sum += c
					n += 1
		if n == 0:
			return 99.0
		var m := Color(sum.r / n, sum.g / n, sum.b / n)
		var dh := absf(wrapf(m.h - place.h, -0.5, 0.5)) * (minf(m.s, place.s) * 2.0 + 0.2)
		return dh * 3.0 + absf(m.v - place.v) + absf(m.s - place.s) * 0.5
	## A wave of hops along the stand, starting from `from` (mat px)
	func cheer(from: Vector2, hops := 1) -> void:
		for d in dots:
			var dist: float = absf((d[0].x - from.x) if along_x else (d[0].y - from.y))
			d[2] = t + dist / 520.0 + randf() * 0.06
			d[3] = hops
			d[6] = 28.0                                   # (was 20: barely above their own idle hops)
	## Everyone at once, a few hops (the race starts: the user, 2026-10-28, the start's crowd all excited, no wave)
	func cheer_all(hops := 3) -> void:
		for d in dots:
			d[2] = t + randf() * 0.08
			d[3] = hops
			d[6] = 28.0
	## A crash near the stand: the pals near it scream and scatter (the farther ones just hop)
	func scream(at: Vector2) -> void:
		if not rect.grow(320.0).has_point(at):
			return
		for d in dots:
			var off: Vector2 = d[0] - at
			if off.length() < 300.0:
				d[4] = t + 1.3 + randf() * 0.3
				d[5] = off.normalized() * randf_range(10.0, 22.0)
				d[2] = t + randf() * 0.1
				d[3] = 3
				d[6] = 30.0
			else:
				d[2] = t + off.length() / 900.0
				d[3] = 1
				d[6] = 20.0
	func _process(delta: float) -> void:
		t += delta
		# never still (the user, 2026-10-18: the crowd didn't seem to move): now and then each one
		# gives a little hop of its own, more often with the toy close by; at the finish they all
		# keep bouncing
		var near_k := clampf(1.0 - (watch.distance_to(rect.get_center()) - 300.0) / 700.0, 0.0, 1.0)
		for d in dots:
			var busy: bool = t < d[2] + 0.36 * d[3]
			if party and not busy:
				d[2] = t + randf() * 0.25
				d[3] = 1
				d[6] = 20.0
			elif not busy and t > d[8]:
				d[2] = t
				d[3] = 2 if near_k > 0.5 and randf() < 0.4 else 1
				d[6] = 8.0 + 8.0 * near_k
				d[8] = t + lerpf(randf_range(2.0, 5.5), randf_range(0.5, 1.4), near_k)
		queue_redraw()
	## Where a tier starts across the stand (px from its top / left): tier 0 next to the track,
	## the awning at the far side
	## The designer's stand: where a pal on a bench sits, from the stand's edge (world px), for its view
	func _art_rows() -> Array:
		return ART_SEATS_BACK if _view() == "back" else ART_SEATS
	## The stand's art px in world px (bigger than the course's)
	static func art_k() -> float:
		return RcTiles.ART_PX * ART_SCALE
	## Where a pal sits on a bench, from the stand's edge across it (world px): its bottom on the
	## bench's top (front / behind), or on the bench turned on its side (the sides)
	func _art_seat(bench: int) -> float:
		var k := art_k()
		var top: float = _art_rows()[bench]
		match _view():
			"side_r":                                # (turned: its back to the right)
				return (ART_DEPTH - top - 5.0) * k
			"side_l":
				return (top + 5.0) * k
			_:
				return (top + 4.0) * k - 20.0
	## Which of the designer's views: "front" (above the track, seats facing you), "back" (below it:
	## seen from behind, an effect on the front), "side_r" / "side_l" (beside it, the front turned)
	func _view() -> String:
		if along_x:
			return "front" if away.y < 0.0 else "back"
		return "side_r" if away.x > 0.0 else "side_l"
	## A pal from behind: its face (the eyes, mouth and shine in its middle rows) painted over with
	## the body round it (the user, 2026-10-27: seen from behind, the pals turned away too)
	func _back_of(tex: Texture2D) -> Texture2D:
		if _backs.has(tex):
			return _backs[tex]
		var im := tex.get_image()
		if im.is_compressed():
			im.decompress()
		im.convert(Image.FORMAT_RGBA8)
		var w := im.get_width()
		var h := im.get_height()
		var lum := func(c: Color) -> float: return c.r * 0.3 + c.g * 0.59 + c.b * 0.11
		var op := func(x: int, y: int) -> bool: return x >= 0 and y >= 0 and x < w and y < h and im.get_pixel(x, y).a > 0.0
		var inner := func(x: int, y: int) -> bool:
			for dy in range(-2, 3):
				for dx in range(-2, 3):
					if not op.call(x + dx, y + dy):
						return false
			return true
		var face := {}
		var y_from := int(h * 0.37)
		var y_to := int(h * 0.8)
		for y in h:
			for x in w:
				if not inner.call(x, y):
					continue
				var around: Array[float] = []
				for dx in range(-3, 4):
					if op.call(x + dx, y):
						around.append(lum.call(im.get_pixel(x + dx, y)))
				around.sort()
				var med: float = around[around.size() / 2]
				var l: float = lum.call(im.get_pixel(x, y))
				if l < med - 0.16 or (y >= y_from and y <= y_to and absf(l - med) > 0.18):
					face[Vector2i(x, y)] = true
		var out := im.duplicate()
		for q in face:
			var near: Array = []
			for d in range(1, 6):
				for o in [Vector2i(d, 0), Vector2i(-d, 0), Vector2i(0, d), Vector2i(0, -d)]:
					var r: Vector2i = q + o
					if not face.has(r) and inner.call(r.x, r.y):
						near.append(im.get_pixelv(r))
				if near.size() >= 2:
					break
			if not near.is_empty():
				var c := Color(0, 0, 0, 0)
				for n in near:
					c += n
				out.set_pixelv(q, c / near.size())
		_backs[tex] = ImageTexture.create_from_image(out)
		return _backs[tex]
	func _tier_at(tier: int) -> float:
		var depth := rect.size.y if along_x else rect.size.x
		var toward_neg := (away.y < 0.0) if along_x else (away.x < 0.0)   # the back is the top / left
		return (depth - ROW * (tier + 1)) if toward_neg else (ROW * tier)
	func _draw() -> void:
		if rect.size == Vector2.ZERO:
			return
		if style == "cloud":
			_draw_cloud()
		else:
			_draw_stand()
		# the crowd: your pals' balls (x2, on the 4 px grid), hopping up the screen; a scared one
		# shakes, its "!" over it, and steps away from the crash a little
		for d in dots:
			var u: float = (t - d[2]) / 0.36
			var up := 0.0
			var scared: bool = t < d[4]
			if u >= 0.0 and u < float(d[3]):
				up = sin(fposmod(u, 1.0) * PI) * float(d[6])
			var p: Vector2 = d[0] - Vector2(0, roundf(up / 4.0) * 4.0)
			# a sway on its own beat, leaning the toy's way when it's about
			var lean := watch.x - (d[0] as Vector2).x
			p.x += 4.0 * (signf(lean) if along_x and absf(lean) > 40.0 and watch != Vector2.ZERO else roundf(sin(t * 1.7 + float(d[7]))))
			if scared:
				var k := clampf((d[4] - t) / 1.3, 0.0, 1.0)
				p += (d[5] as Vector2) * sin(k * PI) + Vector2(4.0 if int(t * 30.0) % 2 == 0 else -4.0, 0) * k
			p = p.snapped(Vector2(4, 4))
			if int(d[9]) >= 0 and art:
				# its flag, the designer's (drawn white: tinted), two waving frames
				var fr := RcTiles.drawn("flag_%d" % (int(t * 4.0 + float(d[7])) % 2))
				draw_texture_rect(fr, Rect2(p + Vector2(14, -48), fr.get_size() * RcTiles.ART_PX), false, FLAGS[d[9]])
			elif int(d[9]) >= 0:
				# its little flag on a stick, flapping
				var flap := 4.0 if int(t * 4.0 + float(d[7])) % 2 == 0 else 0.0
				draw_rect(Rect2(p + Vector2(16, -44), Vector2(4, 32)), OUTLINE)
				draw_rect(Rect2(p + Vector2(20, -44 + flap * 0.5), Vector2(16 - flap, 12)), OUTLINE)
				draw_rect(Rect2(p + Vector2(20, -40 + flap * 0.5), Vector2(12 - flap, 4)), FLAGS[d[9]])
			var face: Texture2D = _back_of(d[10]) if art and style == "stand" and _view() == "back" else d[10]
			draw_texture_rect(face, Rect2(p - Vector2(24, 28), Vector2(48, 48)), false, Color(1, 1, 1, 0.92))
			if scared and int(d[1]) % 2 == 0:
				draw_rect(Rect2(p + Vector2(-2, -46), Vector2(4, 10)), Color8(250, 246, 236))
				draw_rect(Rect2(p + Vector2(-2, -32), Vector2(4, 4)), Color8(250, 246, 236))
		if art and style == "stand":
			_draw_stand_art("over")                 # (the awning over the top row; from behind the posts too)
			if sky:
				_draw_sky_cloud("over")            # (the puffs in front of its feet: it sits in the cloud)
			_legs = _legs_next.duplicate()           # (the legs found this frame: the pier uses them from the next)
	func _draw_stand() -> void:
		if art and style == "stand":
			_legs_next.clear()
			if sky:
				_draw_sky_cloud("under")
			_draw_stand_art("under")
			if pier:
				_draw_pier()
			return
		# the stand: outlined like the track (it's a toy too), five tiers stepping up away from the
		# track (the back ones lighter: higher, nearer the light), lit lips; a pier: on posts
		if style == "pier":
			var posts := 6
			for k in posts:
				var f := (k + 0.5) / posts
				var at := rect.position + (Vector2(rect.size.x * f, rect.size.y) if along_x else Vector2(rect.size.x, rect.size.y * f))
				draw_rect(Rect2(at + Vector2(-6, 0), Vector2(12, 20)), OUTLINE)
				draw_rect(Rect2(at + Vector2(-4, 0), Vector2(8, 16)), Color8(120, 78, 46))
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
	## The designer's stand (one layer: "under" the pals or "over" them): its end, its middle repeated
	## (the last one cut), its other end, in its view; over the awning, the roof flags waving
	## A stand piece (the Lagoon's: its canopy recoloured, RcLagoon.stand_tex)
	func _stand_tex(name: String) -> Texture2D:
		return RcLagoon.stand_tex(name) if pier else (RcSky.stand_tex(name) if sky else RcTiles.drawn(name))
	## RC ART's Sky: the designer's cloud under the stand (one layer, "under" it or "over" its feet), cut where
	## the stand's pieces meet like the stand itself: its end, its middle repeated (the last one cut), its other
	## end; it reaches CLOUD_MARGIN art px past the stand all round
	func _draw_sky_cloud(layer: String) -> void:
		var v := _view()
		var k0 := art_k()
		var whole := RcSky.stand_cloud(v, layer, roundi((rect.size.x if along_x else rect.size.y) / k0))
		if whole:                                    # (round 2: the whole cloud for this length)
			draw_texture_rect(whole, Rect2(rect.position - Vector2.ONE * RcSky.CLOUD_MARGIN * k0, whole.get_size() * k0), false)
			return
		var tx := RcSky.tex("stand_cloud_%s_%s" % [v, layer])
		if tx == null:
			return
		var set_name := ("front" if v == "front" else "back") if along_x else v
		var k := art_k()
		var a := _stand_tex("stand_%s_under_end_a" % set_name)
		var m := _stand_tex("stand_%s_under_mid" % set_name)
		var b := _stand_tex("stand_%s_under_end_b" % set_name)
		var len_of := func(t: Texture2D) -> float: return float(t.get_width() if along_x else t.get_height())
		var mg := float(RcSky.CLOUD_MARGIN)
		var ea: float = len_of.call(a)
		var mid: float = len_of.call(m)
		var eb: float = len_of.call(b)
		var total := float(tx.get_width() if along_x else tx.get_height())
		var across := float(tx.get_height() if along_x else tx.get_width())
		var long := rect.size.x if along_x else rect.size.y
		var origin := rect.position - Vector2(mg, mg) * k
		var axis := Vector2.RIGHT if along_x else Vector2.DOWN
		# one stretch of the cloud: from `src` art px along it, `n` art px long, drawn `at` world px along
		var part := func(src: float, n: float, at: float) -> void:
			var sr := Rect2(src, 0, n, across) if along_x else Rect2(0, src, across, n)
			draw_texture_rect_region(tx, Rect2(origin + axis * at, sr.size * k), sr)
		part.call(0.0, mg + ea, 0.0)
		var at := ea * k
		while at < long - eb * k - 0.5:
			var piece := minf(mid * k, long - eb * k - at)
			part.call(mg + ea, piece / k, mg * k + at)
			at += piece
		part.call(total - eb - mg, eb + mg, mg * k + long - eb * k)
	## A stand piece's legs, its separate short runs on its lowest row (the stand's own posts), drawn at `at`
	## scaled by k, only those within its px [from, to) along x
	func _add_legs(name: String, at: Vector2, k: float, from: float, to: float) -> void:
		if not pier:
			return
		if not _leg_cache.has(name):
			var found: Array = []
			var im := RcTiles.img(name)
			if im:
				var bottom := -1
				for y in range(im.get_height() - 1, -1, -1):
					for x in im.get_width():
						if im.get_pixel(x, y).a > 0.5:
							bottom = y
							break
					if bottom >= 0:
						break
				var run := 0
				for x in im.get_width() + 1:
					var solid := x < im.get_width() and bottom >= 0 and im.get_pixel(x, bottom).a > 0.5
					if solid:
						run += 1
					elif run > 0:
						if run <= 14:                     # (a leg: a short run, 9-10 px on the Garden stand; a long one is its base)
							found.append(Vector2(x - run / 2.0, bottom + 1))
						run = 0
			_leg_cache[name] = found
		for l in _leg_cache[name]:
			if l.x >= from and l.x < to:
				_legs_next.append(at + l * k)
	## The pier under the stand (RC ART's Lagoon): wooden posts along its lower edge, down into the water, a
	## ring of foam round each (drawn before the stand: it covers their tops)
	func _draw_pier() -> void:
		var post := RcLagoon.pier_tex("pier_post")
		if post:                                     # (the designer's post and foam, round 2)
			var s := RcLagoon.ART_PX
			# the stand's own legs: a ring of foam where each touches the water (the user)
			for i in _legs.size():
				var foot: Vector2 = _legs[i]
				var lf := RcLagoon.pier_tex("pier_foam_%d" % (int(t * 2.5 + i + 1) % 2))
				if lf:
					draw_texture_rect(lf, Rect2(Vector2(roundf(foot.x / 2.0) * 2.0 - lf.get_width() * s / 2.0, foot.y - lf.get_height() * s / 2.0), lf.get_size() * s), false)
			# the pier's own posts along its lower edge, never on a leg (the user: they mustn't coincide)
			var py := rect.end.y - 6.0
			var px0 := rect.position.x + 14.0
			var px1 := rect.end.x - 14.0
			var pn := maxi(2, int((px1 - px0) / 64.0) + 1)
			for i in pn:
				var x := roundf(lerpf(px0, px1, float(i) / float(pn - 1)) / 2.0) * 2.0
				if _legs.any(func(l): return absf(l.x - x) < 26.0):
					continue
				var foam := RcLagoon.pier_tex("pier_foam_%d" % (int(t * 2.5 + i) % 2))
				draw_texture_rect(post, Rect2(Vector2(x - post.get_width() * s / 2.0, py), post.get_size() * s), false)
				if foam:
					draw_texture_rect(foam, Rect2(Vector2(x - foam.get_width() * s / 2.0, py + post.get_height() * s - foam.get_height() * s), foam.get_size() * s), false)
			return
		var wood := Color8(138, 90, 60)
		var lit := Color8(176, 122, 82)
		var foam := Color8(252, 226, 202)
		var y := rect.end.y - 6.0
		var x0 := rect.position.x + 14.0
		var x1 := rect.end.x - 14.0
		var n := maxi(2, int((x1 - x0) / 64.0) + 1)
		for i in n:
			var x := roundf(lerpf(x0, x1, float(i) / float(n - 1)) / 2.0) * 2.0
			var bob := 2.0 if sin(t * 1.6 + i) > 0.6 else 0.0
			draw_rect(Rect2(x - 12, y + 26 + bob, 24, 2), foam)
			draw_rect(Rect2(x - 8, y + 28 + bob, 16, 2), Color(foam, 0.6))
			draw_rect(Rect2(x - 6, y, 12, 30), OUTLINE)
			draw_rect(Rect2(x - 4, y, 8, 28), wood)
			draw_rect(Rect2(x - 4, y, 2, 28), lit)
	func _draw_stand_art(layer: String) -> void:
		var v := _view()
		var set_name := ("front" if v == "front" else "back") if along_x else v
		var k := art_k()
		var a := _stand_tex("stand_%s_%s_end_a" % [set_name, layer])
		var m := _stand_tex("stand_%s_%s_mid" % [set_name, layer])
		var b := _stand_tex("stand_%s_%s_end_b" % [set_name, layer])
		var axis := Vector2.RIGHT if along_x else Vector2.DOWN
		var long := rect.size.x if along_x else rect.size.y
		var end_a := (a.get_width() if along_x else a.get_height()) * k
		var end_b := (b.get_width() if along_x else b.get_height()) * k
		var mid_len := (m.get_width() if along_x else m.get_height()) * k
		draw_texture_rect(a, Rect2(rect.position, a.get_size() * k), false)
		var legs_here := (layer == "over") == (set_name == "back")   # (the legs: a back view's in its top layer, others' below)
		if legs_here and along_x:
			_add_legs("stand_%s_%s_end_a" % [set_name, layer], rect.position, k, 0.0, INF)
		var at := end_a
		var ends: Array = ART_ROOF_ENDS.get(set_name, ART_ROOF_ENDS_FRONT)
		var posts: Array[float] = [ends[0] * k]
		while at < long - end_b - 0.5:
			var piece := minf(mid_len, long - end_b - at)
			var src := Rect2(Vector2.ZERO, Vector2(piece / k, m.get_height()) if along_x else Vector2(m.get_width(), piece / k))
			draw_texture_rect_region(m, Rect2(rect.position + axis * at, src.size * k), src)
			if legs_here and along_x:
				_add_legs("stand_%s_%s_mid" % [set_name, layer], rect.position + axis * at, k, 0.0, piece / k)
			if piece >= ART_ROOF_FLAGS[1] * k:
				posts.append(at + ART_ROOF_FLAGS[1] * k)
			at += piece
		draw_texture_rect(b, Rect2(rect.position + axis * (long - end_b), b.get_size() * k), false)
		if legs_here:                                # (a side view: only its bottom piece stands on the water)
			_add_legs("stand_%s_%s_end_b" % [set_name, layer], rect.position + axis * (long - end_b), k, 0.0, INF)
		posts.append(long - ends[1] * k)
		if layer != "over" or not ResourceLoader.exists(RcTiles.DIR + "stand_flag_0.png"):
			return
		# the roof flags: on the awning's back edge, each waving on its own beat
		var depth := ART_DEPTH * k
		for i in posts.size():
			var fr := RcTiles.drawn("stand_flag_%d" % (int(t * 6.0 + i * 1.7) % 3))
			var size := fr.get_size() * k
			var along: float = posts[i]
			var p: Vector2
			match v:
				"side_r":
					p = rect.position + Vector2(depth - size.x * 0.5, along - size.y)
				"side_l":
					p = rect.position + Vector2(-size.x * 0.5, along - size.y)
				"back":                              # (on the canopy, nearest to us)
					p = rect.position + Vector2(along - size.x * 0.5, ART_CANOPY_BACK * k - size.y + 4.0)
				_:
					p = rect.position + Vector2(along - size.x * 0.5, -size.y + 6.0)
			draw_texture_rect(fr, Rect2(p.round(), size), false, FLAGS[i % FLAGS.size()])
	func _draw_cloud() -> void:
		# a fluffy cloud for the pals to sit on: lumps along its edge, lit top left, its shade below
		var lumps: Array = []
		var long := rect.size.x if along_x else rect.size.y
		var n := int(long / 46.0) + 1
		for k in n:
			var f := (k + 0.5) / n
			for side in [0.2, 0.8]:
				var c := rect.position + (Vector2(rect.size.x * f, rect.size.y * side) if along_x else Vector2(rect.size.x * side, rect.size.y * f))
				lumps.append([c, 44.0 + 10.0 * sin(k * 2.3 + side * 5.0)])
		for pass_n in 3:
			for lp in lumps:
				var c: Vector2 = lp[0]
				var r: float = lp[1]
				var col: Color = [OUTLINE, Color8(206, 220, 240), Color8(250, 252, 255)][pass_n]
				var rr := r + (4.0 if pass_n == 0 else (0.0 if pass_n == 1 else -6.0))
				var off := Vector2(0, 0) if pass_n < 2 else Vector2(-4, -6)
				_disc(c + off, rr, col)
	func _disc(c: Vector2, r: float, col: Color) -> void:
		var y := -r
		while y <= r:
			var half := sqrt(maxf(0.0, r * r - y * y))
			draw_rect(Rect2((c + Vector2(-half, y)).snapped(Vector2(4, 4)), Vector2(half * 2.0, 4).snapped(Vector2(4, 4))), col)
			y += 4.0


## Speed: short light streaks left on the road by the rear wheels, fading fast, and puffs from the
## exhaust; both on the 4 px grid
class Trail extends Node2D:
	var marks: Array = []             # [position, age, kind]
	var fine := false                 # RC ART's Lagoon: the wake's foam on the 2 px grid, warm, breaking up as it fades
	const FINE_FOAM := [[Vector2i(0, 0), Vector2i(1, 0), Vector2i(0, 1), Vector2i(1, 1)],
		[Vector2i(0, 0), Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1), Vector2i(1, 1), Vector2i(-1, 1), Vector2i(1, -1)],
		[Vector2i(0, 0), Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1), Vector2i(2, 0), Vector2i(-2, 1), Vector2i(1, 2), Vector2i(-1, -2), Vector2i(2, -1)],
		[Vector2i(-2, 0), Vector2i(2, 1), Vector2i(0, -2), Vector2i(1, 2), Vector2i(-1, -1), Vector2i(3, -1), Vector2i(-3, 2)]]   # (a clump, a blob, a bigger blob, specks: the user, "more noticeable")
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
	## The boat's wake (the user, 2026-10-18: more marked): a V of foam from its stern spreading
	## out to both sides, the churned water right behind it, spray off its bow; it lingers
	func wake(p: Vector2, heading: float, delta: float, k: float) -> void:
		puff_t -= delta
		if puff_t > 0.0:
			return
		puff_t = 0.03
		var fwd := Vector2.from_angle(heading)
		var back := fwd * -48.0
		var side := Vector2.from_angle(heading + PI / 2.0)
		for sd in [-1.0, 1.0]:
			marks.append([p + back + side * sd * 16.0, 0.0, 3, (side * sd * randf_range(70.0, 110.0) - fwd * 30.0) * k])
		marks.append([p + back * 1.1 + side * randf_range(-6.0, 6.0), 0.0, 3, -fwd * 20.0 * k])
		if randf() < 0.5 * k:
			var sd2 := 1.0 if randf() < 0.5 else -1.0
			marks.append([p + fwd * 40.0 + side * sd2 * 14.0, 0.0, 2, side * sd2 * randf_range(80.0, 160.0)])
	## The plane's contrail: two thin white puffs off its wing tips, lingering a little
	func contrail(p: Vector2, heading: float, delta: float) -> void:
		puff_t -= delta
		if puff_t > 0.0:
			return
		puff_t = 0.05
		var side := Vector2.from_angle(heading + PI / 2.0) * 44.0
		var back := Vector2.from_angle(heading) * -8.0
		marks.append([p + back + side, 0.0, 4])
		marks.append([p + back - side, 0.0, 4])
	## A ring flown through: a burst of little stars
	func sparkle(p: Vector2) -> void:
		for k in 10:
			var a := TAU * k / 10.0
			marks.append([p, 0.0, 5, Vector2.from_angle(a) * randf_range(160.0, 260.0)])
	func _life(kind: int) -> float:
		return [LIFE, 0.45, 0.35, 2.0 if fine else 1.5, 0.6, 0.5][kind]
	func _process(delta: float) -> void:
		for m in marks:
			m[1] += delta
			if m[2] == 2 or m[2] == 3 or m[2] == 5:
				m[0] += (m[3] as Vector2) * delta
				if m[2] == 3:
					m[3] = (m[3] as Vector2) * maxf(0.0, 1.0 - delta * 2.0)
		marks = marks.filter(func(m): return m[1] < _life(m[2]))
		queue_redraw()
	func _draw() -> void:
		for m in marks:
			var p: Vector2 = (m[0] as Vector2).snapped(Vector2(4, 4))
			if m[2] == 3 and fine:
				var ff: float = m[1] / _life(3)
				var shape: Array = FINE_FOAM[0 if ff < 0.1 else (1 if ff < 0.3 else (2 if ff < 0.6 else 3))]
				var fp: Vector2 = (m[0] as Vector2).snapped(Vector2(2, 2))
				for cell in shape:
					draw_rect(Rect2(fp + Vector2(cell) * 2.0 + Vector2(2, 2), Vector2(2, 2)), Color(0.45, 0.2, 0.3, 0.24 * (1.0 - ff)))
					draw_rect(Rect2(fp + Vector2(cell) * 2.0, Vector2(2, 2)), Color(1.0, 0.975, 0.94, 1.0 - ff * ff))
				continue
			if m[2] == 3:
				# (foam: a little shadow under it so it stands out on light water, growing as it spreads)
				var f3: float = m[1] / 1.5
				var sz3 := 4.0 if f3 < 0.15 else (8.0 if f3 < 0.55 else 12.0)
				draw_rect(Rect2(p - Vector2(sz3, sz3) / 2.0 + Vector2(4, 4), Vector2(sz3, sz3)), Color(0.1, 0.2, 0.35, 0.18 * (1.0 - f3)))
				draw_rect(Rect2(p - Vector2(sz3, sz3) / 2.0, Vector2(sz3, sz3)), Color(0.97, 0.99, 1.0, 0.9 * (1.0 - f3)))
				continue
			if m[2] == 4:
				var f4: float = m[1] / 0.6
				draw_rect(Rect2(p - Vector2(4, 4), Vector2(8, 8)), Color(1, 1, 1, 0.5 * (1.0 - f4)))
				continue
			if m[2] == 5:
				var f5: float = m[1] / 0.5
				draw_rect(Rect2(p - Vector2(4, 4), Vector2(8, 8)), Color(1.0, 0.95, 0.6, 1.0 - f5))
				continue
			if m[2] == 2:
				if fine:
					draw_rect(Rect2((m[0] as Vector2).snapped(Vector2(2, 2)), Vector2(2, 2)), Color(1.0, 0.97, 0.94, 0.8 * (1.0 - m[1] / 0.35)))
				else:
					draw_rect(Rect2(p - Vector2(2, 2), Vector2(4, 4)), Color(0.8, 0.9, 1.0, 0.8 * (1.0 - m[1] / 0.35)))
			elif m[2] == 0:
				draw_rect(Rect2(p - Vector2(2, 2), Vector2(4, 4)), Color(1, 1, 1, 0.35 * (1.0 - m[1] / LIFE)))
			else:
				var f: float = m[1] / 0.45
				var sz := 4.0 + 8.0 * f
				draw_rect(Rect2(p - Vector2(sz, sz) / 2.0 + Vector2(0, -f * 10.0), Vector2(sz, sz)).abs(), Color(0.85, 0.85, 0.9, 0.5 * (1.0 - f)))

## A plane's ring: a hoop standing across the course, seen from above at an angle (an ellipse: its
## width across the course, its depth foreshortened). Drawn in two halves split across the course:
## the one the plane flies in by over it, the one it leaves by under it, so it flies through
## whichever way the course goes (the user, 2026-10-18: it was split along the screen, right for a
## course going down it, wrong for one going sideways, which cut the plane in two). A round tube (the user, 2026-10-18:
## the rings should be more beautiful): candy red and white bands, lit from the top left, a dark
## outline, painted once per look on the 4 px grid. The next one is gold, pulsing, sparkles running
## round it; the one after it plain; the farther ones faint (the way reads ring
## by ring); flown through it pops (bigger, fading) once the plane is out of it, a missed one goes grey.
class Ring extends Node2D:
	var n := Vector2.RIGHT
	var r := 100.0
	var upper := true                     # the half the plane flies in through (over it), else the half it leaves by (under it)
	var d := Vector2.DOWN                 # the way the course goes through it
	var state := 0                        # 0 farther on, 1 the next one, 2 flown through, 3 missed, 4 the one after the next,
	                                      # 5 flown through with the plane still in it (RINGS: GOLD PASS: gold with the chime)
	var t := 0.0
	var _shown := -1
	var _pop: Tween
	var _tex := {}                         # its look -> [texture, top left (px), scale]
	var art := false                      # RC ART's Sky: the designer's ring (RcSky.ring_half)
	const OUT := Color8(40, 30, 40)
	const TUBE := 14.0                    # the tube's half thickness (px)
	const LOOKS := {
		"candy": [[Color8(168, 40, 48), Color8(226, 70, 64), Color8(255, 150, 130)], [Color8(190, 180, 196), Color8(246, 242, 232), Color8(255, 255, 255)]],
		"gold": [[Color8(200, 96, 40), Color8(244, 146, 52), Color8(255, 196, 110)], [Color8(206, 150, 30), Color8(252, 210, 70), Color8(255, 244, 170)]],
		"grey": [[Color8(110, 104, 116), Color8(150, 144, 156), Color8(190, 184, 194)], [Color8(130, 124, 136), Color8(176, 170, 180), Color8(206, 200, 210)]],
	}
	func _process(delta: float) -> void:
		t += delta
		if state == 1:
			modulate = Color(1, 1, 1).lerp(Color(1.25, 1.2, 1.05), 0.5 + 0.5 * sin(t * 7.0))
			queue_redraw()
	## Its new state: the look, and the pop when it's flown through
	func show_state(st: int) -> void:
		if st == _shown:
			return
		var was := _shown
		_shown = st
		state = st
		if _pop:
			_pop.kill()
		scale = Vector2.ONE
		match st:
			0:
				modulate = Color(1, 1, 1, 0.32)
			4:
				modulate = Color(1, 1, 1, 0.9)
			1:
				modulate = Color(1, 1, 1)
			5:
				modulate = Color(1.15, 1.1, 1.0)
			2:
				if was == 1 or was == 4 or was == 0 or was == 5:
					modulate = Color(1.15, 1.1, 1.0) if DevLaunch.rc_gold_pass else Color(1.4, 1.3, 1.0)   # (gold already: less flash)
					var pop_t := 0.6 if DevLaunch.rc_gold_pass else 0.4   # (long enough to see it turn gold)
					_pop = create_tween()
					_pop.tween_property(self, "scale", Vector2.ONE * 1.3, pop_t).set_ease(Tween.EASE_OUT)
					_pop.parallel().tween_property(self, "modulate", Color(1.4, 1.3, 1.0, 0.0), pop_t)
				else:
					modulate.a = 0.0
			3:
				modulate = Color(1, 1, 1, 0.55)
		queue_redraw()
	func _point(a: float) -> Vector2:
		# its width across the course (n), its depth foreshortened square to that
		return n * r * cos(a) + Vector2(-n.y, n.x) * r * 0.42 * sin(a)
	## Its half, painted: per 4 px cell, where it is on the tube (across: its shade, round: its band)
	func _paint(look: String) -> Array:
		var m := Vector2(-n.y, n.x)
		var ext := ceilf((r + TUBE + 4.0) / 4.0) * 4.0
		var cells := int(ext * 2.0 / 4.0)
		var img := Image.create(cells, cells, false, Image.FORMAT_RGBA8)
		var pal: Array = LOOKS[look]
		var light := Vector2(-0.6, -0.8)
		for cy in cells:
			for cx in cells:
				var q := Vector2(cx * 4.0 + 2.0 - ext, cy * 4.0 + 2.0 - ext)
				if (q.dot(d) <= 0.0) != upper:
					continue
				var a := q.dot(n) / r
				var b := q.dot(m) / (r * 0.42)
				var rho := sqrt(a * a + b * b)
				# (across the tube: on screen its depth is squashed, so measure along the ellipse's normal)
				var g := Vector2(q.dot(n) / (r * r), q.dot(m) / (r * r * 0.1764))
				var across := (rho - 1.0) / maxf(0.0001, g.length() / maxf(0.0001, rho))
				var k := across / TUBE
				if absf(k) > 1.0:
					continue
				var col: Color
				if absf(k) > 0.7:
					col = OUT
				else:
					var band := int(floorf((atan2(b, a) + PI) / TAU * 18.0)) % 2
					var outward := q.normalized() * signf(k if k != 0.0 else 1.0)
					var lit := (1.0 - absf(k) * 1.1) * 0.6 + outward.dot(light) * absf(k) * 0.9 + (0.25 if q.y < 0.0 else -0.05)
					var shade := 2 if lit > 0.55 else (1 if lit > 0.1 else 0)
					col = pal[band][shade]
				img.set_pixel(cx, cy, col)
		return [ImageTexture.create_from_image(img), Vector2(-ext, -ext), 4.0]
	func _draw() -> void:
		# (the dev launcher's RINGS: gold once flown through, the next one red and pulsing; else the next one gold)
		var look := "gold" if (state == 2 or state == 5 if DevLaunch.rc_gold_pass else state == 1) else ("grey" if state == 3 else "candy")
		if not _tex.has(look):
			_tex[look] = RcSky.ring_half(r, look, n, d, upper) if art else _paint(look)
		var tx: Array = _tex[look]
		var tex: Texture2D = tx[0]
		draw_texture_rect(tex, Rect2(tx[1], tex.get_size() * float(tx[2])), false)
		if state != 1:
			return
		# the next one: sparkles running round it
		for k2 in 4:
			var a2 := t * 1.6 + k2 * TAU / 4.0
			var sp := _point(a2)
			if (sp.dot(d) <= 0.0) != upper:
				continue
			sp = sp.snapped(Vector2(4, 4))
			var tw := 1.0 if int(t * 10.0 + k2) % 2 == 0 else 0.0
			draw_rect(Rect2(sp - Vector2(2, 2), Vector2(4, 4)), Color(1, 1, 1))
			draw_rect(Rect2(sp - Vector2(2, 6 + 4 * tw), Vector2(4, 4)), Color(1, 1, 0.85, 0.85))
			draw_rect(Rect2(sp - Vector2(2, -2 - 4 * tw), Vector2(4, 4)), Color(1, 1, 0.85, 0.85))
			draw_rect(Rect2(sp - Vector2(6 + 4 * tw, 2), Vector2(4, 4)), Color(1, 1, 0.85, 0.85))
			draw_rect(Rect2(sp - Vector2(-2 - 4 * tw, 2), Vector2(4, 4)), Color(1, 1, 0.85, 0.85))

## The plane's way to fly (the user, 2026-10-18: hard to see how to follow the rings): a trail of
## little sparkles from the plane along the course to the next ring (gold), and on to the one after
## it (white, fainter), marching ahead; on the 4 px grid, under the plane
class FlightGuide extends Node2D:
	var pts := PackedVector2Array()       # the way, mat px (every few course points)
	var to_next := 0                      # how many of them lead to the next ring
	var t := 0.0
	func _process(delta: float) -> void:
		t += delta
		queue_redraw()
	func _draw() -> void:
		var march := fposmod(t * 2.5, 1.0)
		for k in range(pts.size() - 1):
			var p: Vector2 = pts[k].lerp(pts[k + 1], march)
			var gold := k < to_next
			var a := clampf(1.2 - float(k) / float(maxi(1, pts.size())), 0.35, 1.0) * (1.0 if gold else 0.6)
			var c := Color8(255, 220, 90) if gold else Color8(255, 255, 255)
			c.a = a
			var o := Color8(120, 60, 40) if gold else Color8(90, 90, 130)
			o.a = a * 0.8
			p = p.snapped(Vector2(4, 4))
			# a little four-point sparkle, a bigger one every third, outlined
			var arm := 8.0 if k % 3 == 0 else 4.0
			draw_rect(Rect2(p - Vector2(6, 6 + arm), Vector2(12, 12 + arm * 2.0)), o)
			draw_rect(Rect2(p - Vector2(6 + arm, 6), Vector2(12 + arm * 2.0, 12)), o)
			draw_rect(Rect2(p - Vector2(2, 2 + arm), Vector2(4, 4 + arm * 2.0)), c)
			draw_rect(Rect2(p - Vector2(2 + arm, 2), Vector2(4 + arm * 2.0, 4)), c)
			draw_rect(Rect2(p - Vector2(2, 2), Vector2(4, 4)), Color(1, 1, 1, a))

## The next ring off the screen: a gold arrow at the view's edge pointing to it, bobbing that way
class RingPointer extends Node2D:
	var view := Rect2()
	var target := Vector2.ZERO            # the ring, play-area px
	var on := false
	var t := 0.0
	func _process(delta: float) -> void:
		t += delta
		queue_redraw()
	func _draw() -> void:
		if not on:
			return
		var inner := view.grow(-44.0)
		if view.has_point(target):
			return
		var c := inner.get_center()
		var dir := (target - c).normalized()
		# where the line to it leaves the inner box
		var k := INF
		if dir.x != 0.0:
			k = minf(k, ((inner.end.x if dir.x > 0.0 else inner.position.x) - c.x) / dir.x)
		if dir.y != 0.0:
			k = minf(k, ((inner.end.y if dir.y > 0.0 else inner.position.y) - c.y) / dir.y)
		var at := c + dir * k + dir * 6.0 * sin(t * 8.0)
		var side := Vector2(-dir.y, dir.x)
		var tip := at + dir * 26.0
		var l := at - dir * 10.0 + side * 22.0
		var r := at - dir * 10.0 - side * 22.0
		var notch := at
		var out := PackedVector2Array([tip + dir * 6.0, l + side * 6.0 - dir * 4.0, notch - dir * 6.0, r - side * 6.0 - dir * 4.0])
		draw_colored_polygon(out, Color8(40, 30, 40))
		draw_colored_polygon(PackedVector2Array([tip, l, notch, r]), Color8(255, 210, 70))
		draw_colored_polygon(PackedVector2Array([tip, l.lerp(tip, 0.35), notch.lerp(tip, 0.4)]), Color8(255, 244, 180))

## The buoys along the boat's channel, floating (the user, 2026-10-18: they should react to the
## boat, little 3D pixel pieces that move with it and come back once it's passed, telling you
## you're about to leave the course): each a stack of slices standing up out of the water. A hull
## touching one carries it along at its edge (it leans away, bobs, a soft bonk); once the boat has
## gone it swings back to its place on a spring, wobbling, a ring of ripples round it while it moves
## RC ART's Lagoon: the start pontoon's flags, the stands' own waving flags (the user, 2026-10-28: the drawn
## ones were "too static and square"), one at each end of the pontoon
class FinishFlags extends Node2D:
	var spots: Array[Vector2] = []
	var t := 0.0
	func _process(delta: float) -> void:
		t += delta
		queue_redraw()
	func _draw() -> void:
		var k := RcLagoon.ART_PX * 1.5                # (a little bigger than on the stands: they mark the finish)
		for i in spots.size():
			var fr := RcTiles.drawn("stand_flag_%d" % (int(t * 6.0 + i * 1.7) % 3))
			if fr:                                       # (tinted like the stands' flags: red one end, yellow the other)
				draw_texture_rect(fr, Rect2(spots[i] - Vector2(fr.get_width() * k * 0.5, fr.get_height() * k), fr.get_size() * k), false, Crowd.FLAGS[i % 2])

## RC ART's Lagoon: crabs on the banks (the user, 2026-10-28: "crabs that move when passing", the designer's
## crab_idle_0..1 and crab_walk_0..3): they wave their claws on the sand; the boat near, they scuttle sideways
## into the shallows and are gone with a little splash; a while later one comes back elsewhere, away from the boat
class BeachCrabs extends Node2D:
	const NEAR := 240.0                   # the boat this close: they run (world px)
	const RUN := 90.0                     # their scuttle (world px/s)
	const BACK := Vector2(7.0, 13.0)      # gone this long before one comes back (s)
	var rc: Node
	var spots: Array = []                 # where crabs may sit: [where (world px), toward the water (unit)]
	var crabs: Array = []                 # [where, toward the water, state (0 sitting, 1 running, 2 gone), its clock, its own beat]
	var splashes: Array = []              # [where, age]
	var idle: Array[Texture2D] = []
	var walk: Array[Texture2D] = []
	var t := 0.0
	func setup(race: Node, at: Array, n: int) -> void:
		rc = race
		spots = at
		crabs.clear()
		splashes.clear()
		idle.clear()
		walk.clear()
		for i in 2:
			var im := RcLagoon._decor_tex("crab_idle_%d" % i)
			if im:
				idle.append(ImageTexture.create_from_image(im))
		for i in 4:
			var im := RcLagoon._decor_tex("crab_walk_%d" % i)
			if im:
				walk.append(ImageTexture.create_from_image(im))
		var order := range(spots.size())
		order.shuffle()
		for i in mini(n, order.size()):
			var sp: Array = spots[order[i]]
			crabs.append([sp[0], sp[1], 0, 0.0, randf() * 10.0])
		visible = idle.size() == 2 and walk.size() == 4 and not crabs.is_empty()
	func _process(delta: float) -> void:
		if not visible:
			return
		t += delta
		var boat: Vector2 = rc.car_pos
		for c in crabs:
			c[3] += delta
			match int(c[2]):
				0:
					if (c[0] as Vector2).distance_to(boat) < NEAR:
						c[2] = 1
						c[3] = 0.0
				1:
					c[0] += (c[1] as Vector2) * RUN * delta
					if c[3] > 0.55:                  # (into the shallows: gone)
						splashes.append([c[0], 0.0])
						c[2] = 2
						c[3] = -randf_range(BACK.x, BACK.y)
				2:
					if c[3] > 0.0:                   # (back, at a spot away from the boat)
						for tries in 8:
							var sp: Array = spots[randi() % spots.size()]
							if (sp[0] as Vector2).distance_to(boat) > NEAR * 2.5:
								c[0] = sp[0]
								c[1] = sp[1]
								c[2] = 0
								c[3] = 0.0
								break
		for sp in splashes:
			sp[1] += delta
		splashes = splashes.filter(func(sp): return sp[1] < 0.5)
		queue_redraw()
	func _draw() -> void:
		var k := RcLagoon.ART_PX
		for c in crabs:
			if int(c[2]) == 2:
				continue
			var fr: Texture2D = walk[int(t * 12.0 + float(c[4])) % 4] if int(c[2]) == 1 else idle[int(t * 2.0 + float(c[4])) % 2]
			var p: Vector2 = ((c[0] as Vector2) - fr.get_size() * k * 0.5).snapped(Vector2(2, 2))
			draw_texture_rect(fr, Rect2(p, fr.get_size() * k), false)
		for sp in splashes:                          # (a ring of foam opening out and fading)
			var f: float = sp[1] / 0.5
			var r := 6.0 + 14.0 * f
			var col := Color(1.0, 0.96, 0.92, 0.8 * (1.0 - f))
			for a in 10:
				var q := ((sp[0] as Vector2) + Vector2.from_angle(a * TAU / 10.0) * Vector2(r, r * 0.6)).snapped(Vector2(2, 2))
				draw_rect(Rect2(q, Vector2(2, 2)), col)

class FloatingBuoys extends Node2D:
	const REACH := 36.0                   # a hull this close carries a buoy (mat px)
	const SPRING := 22.0                  # its pull back to its place, per s^2
	const DAMP := 4.0
	const MAX_OFF := 48.0                 # never farther than this from its place (then the hull rides over it)
	const UP := 3.0                       # each slice this much higher (mat px)
	var rest := PackedVector2Array()
	var off := PackedVector2Array()
	var vel := PackedVector2Array()
	var lean := PackedVector2Array()
	var touched: Array[bool] = []
	var red: Array[bool] = []
	var slices := {}
	var slice_px := 4.0                    # world px per slice px (the designer's: 2)
	var t := 0.0
	func setup(spots: Array) -> void:
		texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		rest.clear()
		off.clear()
		vel.clear()
		lean.clear()
		touched.clear()
		red.clear()
		for sp in spots:
			rest.append(sp[0])
			off.append(Vector2.ZERO)
			vel.append(Vector2.ZERO)
			lean.append(Vector2.ZERO)
			touched.append(false)
			red.append(bool(sp[1]))
		slices = { true: PalPrixArt.buoy_slices(true), false: PalPrixArt.buoy_slices(false) }
		slice_px = 4.0
		var art := RcLagoon.buoy_slices(get_parent().get_parent().look) if get_parent() and get_parent().get_parent() else {}
		if not art.is_empty():                      # (RC ART's Lagoon: the designer's, at twice the detail; the same behaviour)
			slices = art
			slice_px = RcLagoon.ART_PX
		visible = not rest.is_empty()
		queue_redraw()
	## Moves them; returns how many the boat has just bumped into (for the bonk)
	func update(delta: float, boat: Vector2, boat_vel: Vector2, rivals: Array) -> int:
		if rest.is_empty():
			return 0
		t += delta
		var hulls: Array = [[boat, boat_vel, true]]
		for r in rivals:
			hulls.append([r["pos"], Vector2.from_angle(float(r["heading"])) * 400.0, false])
		var bumps := 0
		for i in rest.size():
			var p := rest[i] + off[i]
			var held := false
			for hl in hulls:
				var to: Vector2 = p - (hl[0] as Vector2)
				var dd := to.length()
				if dd < REACH and off[i].length() < MAX_OFF:
					var away := to / dd if dd > 0.01 else Vector2.RIGHT
					p = (hl[0] as Vector2) + away * REACH          # (carried at the hull's edge)
					vel[i] = (hl[1] as Vector2) * 0.5 + away * 60.0
					lean[i] = lean[i].lerp(away * 7.0, minf(1.0, delta * 14.0))
					held = true
					if hl[2] and not touched[i] and (hl[1] as Vector2).length() > 120.0:
						bumps += 1
					if hl[2]:
						touched[i] = true
			if held:
				off[i] = p - rest[i]
			else:
				touched[i] = touched[i] and off[i].length() > 6.0
				vel[i] += -off[i] * SPRING * delta
				vel[i] *= exp(-DAMP * delta)
				off[i] += vel[i] * delta
				# (it rocks the way it's swinging back, then settles upright)
				lean[i] = lean[i].lerp(-vel[i] * 0.04, minf(1.0, delta * 8.0)).limit_length(7.0)
			if off[i].length() > MAX_OFF:
				off[i] = off[i].normalized() * MAX_OFF
		queue_redraw()
		return bumps
	func _draw() -> void:
		for i in rest.size():
			var moving := vel[i].length() > 10.0 or off[i].length() > 3.0
			var p := (rest[i] + off[i]).snapped(Vector2(4, 4))
			if moving:
				var ring := 4.0 * (4.0 + roundf(fposmod(t * 6.0 + i, 3.0)))
				for a in 10:
					var q := (p + Vector2.from_angle(a * TAU / 10.0) * ring).snapped(Vector2(4, 4))
					draw_rect(Rect2(q - Vector2(2, 2), Vector2(4, 4)), Color(1, 1, 1, 0.45))
			# a light swell (the user, 2026-10-18: they should move a little by default): each bobs a
			# px up and down, the beat a little later buoy after buoy along the line (a ripple
			# running along it), and now and then one rocks to a side as a wave goes under it;
			# more while it's been knocked about
			var ph := t * 1.7 - float(i) * 0.45
			var sw := sin(ph)
			var bob := (-4.0 if sw > 0.45 else (4.0 if sw < -0.55 else 0.0)) * (1.5 if moving else 1.0)
			var rock := Vector2.ZERO
			if not moving and sin(t * 0.7 + float(i) * 2.3) > 0.93:
				rock = Vector2(4.0 if sin(t * 5.0 + float(i)) > 0.0 else -4.0, 0)
			var sl: Array = slices[red[i]]
			for k in sl.size():
				var tx: Texture2D = sl[k]
				var f := float(k) / float(sl.size() - 1)
				var at := p + Vector2(0, bob * f - k * UP) + (lean[i] + rock) * f
				draw_texture_rect(tx, Rect2(at.round() - Vector2(14, 14), tx.get_size() * slice_px), false)

## The water moving (the user, 2026-10-18): glints drifting on it, short light strokes on the
## 4 px grid that come and go across the view (never on the sand or the islands); and the
## whirlpools turning, foam arms spiralling in to a dark eye that pulses
class WaterFx extends Node2D:
	var rc: Node                          # the race (where the water is, what the view shows)
	var glints: Array = []                # [position, age, life, length]
	var whirls: Array = []                # whirlpools' middles (mat px)
	var currents: Array = []              # boost currents: [middle, the way it flows]
	var fish: Array = []                  # fish shadows: [position, heading, speed, how seen (0-1), fleeing]
	const FISH_NEAR := 150.0              # the boat this close: they dart away and fade (mat px)
	const FISH_BODY := [[1, 0], [0, 0], [-1, 0], [0, -1], [0, 1], [-1, -1], [-1, 1], [-2, -1], [-2, 1]]
	var fine_fish := false                # RC ART's Lagoon: a real fish silhouette on the art's 2 px grid
	var art_currents := {}                # RC ART's Lagoon: the designer's current frames, "e"/"n"/"w"/"s" -> 4 textures
	## A fish shadow on the 2 px grid: an oval body, side fins, a forked tail that wags (the same size as the old)
	func _fine_fish(at: Vector2, fwd: Vector2, sd: Vector2, wag: float, shade: Color) -> void:
		var c := at.snapped(Vector2(2, 2))
		for gy in range(-22, 23, 2):
			for gx in range(-22, 23, 2):
				var o := Vector2(gx, gy)
				var u := o.dot(fwd)                      # along the fish (its head forward)
				var v := o.dot(sd) - (wag * 2.0 - 1.0) * clampf(-u - 6.0, 0.0, 12.0) * 0.25   # (the tail swings)
				var inside := (u / 11.0) * (u / 11.0) + (v / 5.5) * (v / 5.5) <= 1.0              # the body
				inside = inside or (u < -9.0 and u > -19.0 and absf(v) < (-u - 9.0) * 0.75 and absf(v) > (-u - 15.0) * 0.9)   # the forked tail
				inside = inside or (absf(u + 1.0) < 2.5 and absf(v) < 8.0 and absf(v) > 4.5)        # the side fins
				if inside:
					draw_rect(Rect2(c + o, Vector2(2, 2)), shade)
	var cur_len := 64.0
	var cur_w := 60.0
	var t := 0.0
	var tint := Color(1, 1, 1)
	func setup(race: Node, whirl_at: Array, light: Color, pads: Array = [], pad_len := 64.0, width := 60.0) -> void:
		rc = race
		whirls = whirl_at
		currents = pads
		cur_len = pad_len
		cur_w = width
		glints.clear()
		tint = light
	func _process(delta: float) -> void:
		if not visible or rc == null:
			return
		t += delta
		var view: Rect2 = rc.view_rect()
		for k in 3:
			if randf() < delta * 30.0 and glints.size() < 70:
				var p := Vector2(randf_range(view.position.x, view.end.x), randf_range(view.position.y, view.end.y))
				if rc.is_open_water(p):
					glints.append([p.snapped(Vector2(4, 4)), 0.0, randf_range(0.8, 1.6), 4 * randi_range(2, 4)])
		for g in glints:
			g[1] += delta
			g[0] += Vector2(6.0 * delta, 0)                # (a slow drift)
		glints = glints.filter(func(g): return g[1] < g[2])
		# fish shadows in the water (the user, 2026-10-18: fish shades that go away when you pass):
		# a few wander slowly about the view; the boat coming near sends them darting off, fading
		var boat: Vector2 = rc.car_pos
		if fish.size() < 12 and randf() < delta * 4.0:
			var fp := Vector2(randf_range(view.position.x, view.end.x), randf_range(view.position.y, view.end.y))
			if fp.distance_to(boat) > FISH_NEAR * 1.6 and rc.is_open_water(fp):
				fish.append([fp, randf() * TAU, randf_range(18.0, 34.0), 0.0, false])
		for f in fish:
			var fp2: Vector2 = f[0]
			if not f[4] and fp2.distance_to(boat) < FISH_NEAR:
				f[4] = true
				f[1] = (fp2 - boat).angle() + randf_range(-0.5, 0.5)
				f[2] = randf_range(200.0, 280.0)
			if f[4]:
				f[3] = maxf(0.0, f[3] - delta * 2.2)
			else:
				f[3] = minf(1.0, f[3] + delta * 1.5)
				f[1] += randf_range(-1.5, 1.5) * delta
				if not rc.is_open_water(fp2 + Vector2.from_angle(f[1]) * 24.0):
					f[1] += PI * 0.6                        # (turns away from the sand)
			f[0] = fp2 + Vector2.from_angle(f[1]) * float(f[2]) * delta
		fish = fish.filter(func(f): return not (f[4] and f[3] <= 0.0) and view.grow(200.0).has_point(f[0]))
		queue_redraw()
	func _draw() -> void:
		for f in fish:
			var fwd := Vector2.from_angle(f[1])
			var sd := Vector2(-fwd.y, fwd.x)
			var shade := Color(0.1, 0.05, 0.14, 0.5 * float(f[3]))
			var wag := 1.0 if int(t * 6.0 + float(f[2])) % 2 == 0 else 0.0
			if fine_fish:                            # (RC ART's Lagoon: the same fish on the 2 px grid, the user: "smaller pixels")
				_fine_fish(f[0], fwd, sd, wag, Color(shade, minf(0.85, shade.a * 1.35)))   # (a bit darker: the user)
				continue
			for cell in FISH_BODY:
				var off: Vector2 = fwd * float(cell[0]) * 7.0 + sd * float(cell[1]) * (6.0 + (wag * 3.0 if cell[0] <= -2 else 0.0))
				draw_rect(Rect2(((f[0] as Vector2) + off).snapped(Vector2(4, 4)) - Vector2(4, 4), Vector2(8, 8)), shade)
		for g in glints:
			var f: float = g[1] / g[2]
			var c := tint
			c.a = sin(f * PI) * 0.55
			var p: Vector2 = (g[0] as Vector2).snapped(Vector2(4, 4))
			var ln := float(g[3]) * (0.5 + 0.5 * sin(f * PI))
			draw_rect(Rect2(p - Vector2(roundf(ln / 8.0) * 4.0, 0), Vector2(maxf(4.0, roundf(ln / 4.0) * 4.0), 4)), c)
		# the boost currents (the user, 2026-10-18: another colour): yellow chevrons like the car's
		# boost pads, outlined dark, flowing down the channel, fading in and out at the ends
		for cu in currents:
			var c0: Vector2 = cu[0]
			var dv: Vector2 = cu[1]
			if not art_currents.is_empty():          # (RC ART's Lagoon: the designer's foam arrows, 4 frames a direction)
				var key := ("e" if dv.x > 0.0 else "w") if absf(dv.x) > absf(dv.y) else ("s" if dv.y > 0.0 else "n")
				var frames: Array = art_currents.get(key, [])
				if frames.size() == 4:                 # (three lanes across the current, each a little out of step: one
					var side_v := Vector2(-dv.y, dv.x)   # line down the middle was too narrow, the user)
					for lane in [-1, 0, 1]:
						var fr: Texture2D = frames[(int(t * 8.0) + lane + 1) % 4]
						var sz := fr.get_size() * RcLagoon.ART_PX
						var at := c0 + side_v * float(lane) * cur_w * 0.6 - dv * float(absi(lane)) * 10.0
						draw_texture_rect(fr, Rect2((at - sz / 2.0).snapped(Vector2(2, 2)), sz), false)
				continue
			var side := Vector2(-dv.y, dv.x)
			var shift := fposmod(t * 140.0, 32.0)
			var u := -cur_len - 32.0 + shift
			while u < cur_len:
				var fade := clampf(1.0 - absf(u) / cur_len, 0.0, 1.0)
				var vv := -cur_w
				while vv <= cur_w:
					var q := (c0 + dv * (u - absf(vv) * 0.6) + side * vv).snapped(Vector2(4, 4))
					draw_rect(Rect2(q - Vector2(4, 4) + Vector2(0, 4), Vector2(8, 8)), Color(0.16, 0.1, 0.12, 0.45 * fade))
					draw_rect(Rect2(q - Vector2(4, 4), Vector2(8, 8)), Color(1.0, 0.82, 0.25, 0.95 * fade))
					draw_rect(Rect2(q - Vector2(4, 4), Vector2(4, 4)), Color(1.0, 0.95, 0.6, 0.95 * fade))
					vv += 4.0
				u += 32.0
		for wc in whirls:
			var cen: Vector2 = wc
			# (the user: more visible, with an animation) the water darker down its funnel, rings of
			# it deeper and deeper to a dark eye that pulses
			for ring in 4:
				var rr := 64.0 - ring * 14.0
				var yy := -rr
				while yy <= rr:
					var half := sqrt(maxf(0.0, rr * rr - yy * yy))
					draw_rect(Rect2((cen + Vector2(-half, yy)).snapped(Vector2(4, 4)), Vector2(half * 2.0, 4).snapped(Vector2(4, 4))), Color(0.02, 0.1, 0.2, 0.13))
					yy += 4.0
			var eye := 8.0 + 4.0 * roundf(sin(t * 3.0))
			draw_rect(Rect2((cen - Vector2(eye, eye)).snapped(Vector2(4, 4)), Vector2(eye, eye) * 2.0), Color(0.02, 0.08, 0.16, 0.6))
			# three thick foam arms spiralling in, turning fast
			for arm in 3:
				for k in 18:
					var r := 12.0 + k * 3.0
					var ang := -t * 3.2 + arm * TAU / 3.0 + r * 0.07
					var q := (cen + Vector2.from_angle(ang) * r).snapped(Vector2(4, 4))
					var a2 := 0.45 + 0.55 * (float(k) / 18.0)
					var sz := 8.0 if k > 9 else 4.0
					draw_rect(Rect2(q - Vector2(sz, sz) / 2.0, Vector2(sz, sz)), Color(1, 1, 1, a2))
			# its rim of foam, turning slower
			for k2 in 20:
				if k2 % 2 == 0:
					var ang2 := -t * 1.2 + k2 * TAU / 20.0
					var q2 := (cen + Vector2.from_angle(ang2) * 68.0).snapped(Vector2(4, 4))
					draw_rect(Rect2(q2 - Vector2(4, 2), Vector2(8, 4)), Color(1, 1, 1, 0.6))

## The wind (the user, 2026-10-18: a whole layer over the screen, like the traces on the sea but
## wind, a bit more visible): thin light strokes everywhere in the view, drifting the way the air
## goes past the plane (against its nose), each coming and going like the water's glints; the
## race still the picture
class AirFx extends Node2D:
	var rc: Node
	var streaks: Array = []               # [position, age, life, length]
	var flow := Vector2.LEFT              # the way the air goes past (screen: against the plane's heading)
	func _process(delta: float) -> void:
		if not visible or rc == null:
			return
		var heading_v := Vector2.from_angle(float(rc.heading))
		flow = flow.lerp(-heading_v, minf(1.0, delta * 3.0)).normalized()
		var view: Rect2 = rc.view_rect().grow(60.0)
		var racing: bool = rc.state == 1
		var rate := 90.0 if racing else 20.0
		if streaks.size() < 110 and randf() < delta * rate:
			var p := Vector2(randf_range(view.position.x, view.end.x), randf_range(view.position.y, view.end.y))
			streaks.append([p, 0.0, randf_range(0.6, 1.2), randf_range(36.0, 84.0)])
		var speed := 520.0 if racing else 90.0
		for st in streaks:
			st[0] += flow * speed * delta
			st[1] += delta
		streaks = streaks.filter(func(st): return st[1] < st[2])
		queue_redraw()
	func _draw() -> void:
		for st in streaks:
			var f: float = st[1] / st[2]
			var a := sin(f * PI) * 0.55
			var ln: float = float(st[3]) * (0.6 + 0.4 * sin(f * PI))
			var k := 0.0
			while k < ln:
				var q := ((st[0] as Vector2) - flow * k).snapped(Vector2(4, 4))
				var fade := 1.0 - k / ln * 0.75
				draw_rect(Rect2(q - Vector2(4, 4) + Vector2(4, 4), Vector2(8, 8)), Color(0.35, 0.4, 0.55, a * fade * 0.25))   # (a faint shade, so it shows on white clouds)
				draw_rect(Rect2(q - Vector2(4, 4), Vector2(8, 8)), Color(1, 1, 1, a * fade))
				k += 4.0

## EXPERIMENT (the user, 2026-10-18: "like the iPhone's 3D photos"): tilting the phone shifts
## the layers by their depth, the toys and the track still: the far ones (the floor under the
## raised track, the plane's ground far below) one way, the near ones (the Garden's branches, the
## air rushing past) the other; measured from the pose at the race's start, smoothed; off with
## DEPTH_3D. Pixels per full tilt, on the screen:
const DEPTH_3D := true
const DEPTH_FAR := { "car": 18.0, "boat": 8.0, "plane": 46.0 }
const DEPTH_NEAR := { "car": 16.0, "boat": 0.0, "plane": 10.0 }
var _depth_tilt := Vector2.ZERO
var qa_depth_tilt := Vector2.ZERO      # (tools/qa depth=x,y: a pretend tilt, the Mac has no sensor)
func _depth_3d() -> void:
	var want := qa_depth_tilt
	if DEPTH_3D and has_tilt_sensor() and state != State.DONE:
		want = -device_tilt().limit_length(0.6) / 0.6     # (the same axis as Tilt Maze and Top Spin: tilt up = see the upper side)
	_depth_tilt = _depth_tilt.lerp(want, 0.12)
	var far := (_depth_tilt * float(DEPTH_FAR[vehicle]) / ZOOM).round()
	var near := (-_depth_tilt * float(DEPTH_NEAR[vehicle]) / ZOOM).round()
	if vehicle == "plane":
		board.position += far
		sky_shadow.position += far
	else:
		board.position = far
		behind.position = far
		water_fx.position = far
		if vehicle == "car":
			for st in [crowd] + more_stands:
				st.position = far                   # (the stand stands on the floor)
	canopy.position = near
	air_fx.position = near

## The planes' start (the user, 2026-10-18: not just floating; then: smaller, in the game's
## style, cool, clear of the crowd): a launch pad hanging in the sky under the grid, outlined like
## the track (a solid dark line), its top lit from the top left, its side face below it, a red
## and white striped rim like the curbs, the checkered line across it, landing lights blinking
## along it, and a drone's four rotors at its corners spinning (that's what keeps it up)
class SkyDock extends Node2D:
	var tex: Texture2D
	var top_left := Vector2.ZERO
	var lights: Array = []                # the landing lights (mat px)
	var fans: Array = []                  # the rotors: [its corner (mat px), the way its arm goes]
	var t := 0.0
	var art := false                      # RC ART's Sky: the designer's deck, line, lights and rotor pieces (RcSky)
	var _deck := ""                       # ...its deck: pad_east (a course going sideways) / pad_north
	var _line_at := Vector2.ZERO          # ...the start line's middle (mat px)
	var _deck_at := Vector2.ZERO          # ...the deck picture's top left (mat px)
	var _plat := ""                       # ...the cloud runway (the user picked it): the way the race starts, e / w / n / s
	func build(c0: Vector2, dir: Vector2, back: float, ahead: float, half: float, with_art := false) -> void:
		var side := Vector2(-dir.y, dir.x)
		var corners := [c0 - dir * back - side * half, c0 - dir * back + side * half, c0 + dir * ahead - side * half, c0 + dir * ahead + side * half]
		var lo: Vector2 = corners[0]
		var hi: Vector2 = corners[0]
		for q in corners:
			lo = lo.min(q)
			hi = hi.max(q)
		art = with_art
		if art:
			# the designer's deck: its picture reaches PAD_MARGIN art px past the deck all round (the rotors)
			_deck = "pad_east" if absf(dir.x) > absf(dir.y) else "pad_north"
			_plat = ("e" if dir.x > 0.0 else "w") if absf(dir.x) > absf(dir.y) else ("s" if dir.y > 0.0 else "n")
			_deck_at = (lo - Vector2.ONE * RcSky.PAD_MARGIN * RcSky.ART_PX).round()
			_line_at = c0
		hi += Vector2(0, 28)
		lo = (lo / 4.0).floor() * 4.0
		var w := int((hi.x - lo.x) / 4.0) + 2
		var h := int((hi.y - lo.y) / 4.0) + 2
		var img := Image.create(w, h, false, Image.FORMAT_RGBA8)
		var out := Color8(40, 30, 40)
		var deck := [Color8(92, 98, 120), Color8(112, 120, 144), Color8(150, 160, 184)]   # (painted steel: shade, mid, lit)
		var rim := [Color8(226, 70, 64), Color8(246, 242, 232)]
		var side_col := Color8(64, 66, 86)
		var uvf := func(q: Vector2) -> Vector2:
			var o: Vector2 = q - c0
			return Vector2(o.dot(dir), o.dot(side))
		var inside := func(uv: Vector2) -> bool:
			return uv.x > -back and uv.x < ahead and absf(uv.y) < half
		for y in h:
			for x in w:
				var q := lo + Vector2(x * 4 + 2, y * 4 + 2)
				var uv: Vector2 = uvf.call(q)
				if inside.call(uv):
					var dx := minf(uv.x + back, ahead - uv.x)
					var dy := half - absf(uv.y)
					var d := minf(dx, dy)
					var col: Color
					if d < 4.0:
						col = out
					elif d < 12.0:
						# the striped rim, like the curbs
						var along := uv.y if dx < dy else uv.x
						col = rim[int(floorf(along / 16.0)) % 2 if along >= 0.0 else (int(floorf(-along / 16.0)) + 1) % 2]
					elif d < 16.0:
						col = out
					elif absf(uv.x) < 12.0:
						col = Color8(30, 30, 34) if (int(floorf((uv.x + 12.0) / 8.0)) + int(floorf((uv.y + 400.0) / 8.0))) % 2 == 0 else Color8(244, 240, 226)
					else:
						var lit := (uv.y < -half + 30.0) or (uv.x < -back + 30.0)
						var shade := (uv.y > half - 30.0)
						col = deck[2] if lit else (deck[0] if shade else deck[1])
						if int(floorf((uv.x + back) / 48.0)) % 2 == 0 and absf(uv.y) < 6.0:
							col = Color8(252, 210, 64)               # (the centre line, dashed)
					img.set_pixel(x, y, col)
				else:
					# its side face, under it on the screen, then its outline
					for dy2 in [6.0, 14.0, 20.0]:
						if inside.call(uvf.call(q - Vector2(0, dy2))):
							img.set_pixel(x, y, out if dy2 > 18.0 else side_col)
							break
		tex = ImageTexture.create_from_image(img)
		top_left = lo
		texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		lights.clear()
		var n := 5
		for k in n:
			var f := float(k) / float(n - 1)
			for sd in [-1.0, 1.0]:
				lights.append(c0 + dir * lerpf(-back + 20.0, ahead - 20.0, f) + side * sd * (half - 8.0))
		fans.clear()
		for cu in [-back, ahead]:
			for sd2 in [-1.0, 1.0]:
				fans.append([c0 + dir * cu + side * sd2 * half, (dir * signf(cu) + side * sd2).normalized()])
		queue_redraw()
	func _process(delta: float) -> void:
		if not visible:
			return
		t += delta
		queue_redraw()
	func _draw() -> void:
		if art:
			_draw_art()
			return
		if tex:
			draw_texture_rect(tex, Rect2(top_left, tex.get_size() * 4.0), false)
		# a drone's rotors at its four corners (the user, 2026-10-18): an arm out from the corner,
		# the motor, the blades spinning (a blur, a blade flicking across it)
		for fp in fans:
			var corner: Vector2 = fp[0]
			var out_dir: Vector2 = fp[1]
			var hub := (corner + out_dir * 30.0).snapped(Vector2(4, 4))
			var k3 := 0.0
			while k3 <= 30.0:
				var q := (corner + out_dir * k3).snapped(Vector2(4, 4))
				draw_rect(Rect2(q - Vector2(4, 4), Vector2(8, 8)), Color8(40, 30, 40))
				k3 += 4.0
			var yy := -30.0
			while yy <= 30.0:
				var half_x := sqrt(maxf(0.0, 30.0 * 30.0 - yy * yy))
				draw_rect(Rect2((hub + Vector2(-half_x, yy * 0.55)).snapped(Vector2(4, 4)), Vector2(half_x * 2.0, 4).snapped(Vector2(4, 4))), Color(1, 1, 1, 0.22))
				yy += 4.0
			# (its guard ring: a dark rim round the blur, so it reads on any sky)
			for ka in 24:
				var rq := (hub + Vector2(cos(ka * TAU / 24.0) * 32.0, sin(ka * TAU / 24.0) * 32.0 * 0.55)).snapped(Vector2(4, 4))
				draw_rect(Rect2(rq - Vector2(2, 2), Vector2(4, 4)), Color(1, 1, 1, 0.55))
			var ang := t * 22.0 + corner.x * 0.01
			for sgn in [-1.0, 1.0]:
				for j in 5:
					var bq: Vector2 = (hub + Vector2(cos(ang), sin(ang) * 0.55) * sgn * (6.0 + j * 5.0)).snapped(Vector2(4, 4))
					draw_rect(Rect2(bq - Vector2(4, 2), Vector2(8, 4)), Color(1, 1, 1, 0.9))
				# (a fainter blade a moment behind it: the sweep)
				for sgn2 in [-1.0, 1.0]:
					for j3 in 5:
						var bq2: Vector2 = (hub + Vector2(cos(ang - 0.6), sin(ang - 0.6) * 0.55) * sgn2 * (6.0 + j3 * 5.0)).snapped(Vector2(4, 4))
						draw_rect(Rect2(bq2 - Vector2(2, 2), Vector2(4, 4)), Color(1, 1, 1, 0.4))
			draw_rect(Rect2(hub - Vector2(6, 6), Vector2(12, 12)), Color8(40, 30, 40))
			draw_rect(Rect2(hub - Vector2(2, 2), Vector2(4, 4)), Color8(226, 70, 64))
		for k in lights.size():
			var on := int(t * 4.0 - float(k / 2) * 0.5) % 4 == 0
			var lp: Vector2 = (lights[k] as Vector2).snapped(Vector2(4, 4))
			draw_rect(Rect2(lp - Vector2(4, 4), Vector2(8, 8)), Color8(40, 30, 40))
			draw_rect(Rect2(lp - Vector2(2, 2), Vector2(4, 4)), Color8(255, 236, 120) if on else Color8(150, 120, 60))

	## RC ART's Sky: the rotors' arms (under the deck: its corner covers their inner end), the deck, the start
	## line, the landing lights blinking along its rim, then each rotor: its blur, its blades spinning (the
	## designer's 4 frames), the guard ring round them, the motor
	func _draw_art() -> void:
		var px := RcSky.ART_PX
		var plat := RcSky.tex("platform_" + _plat)
		if plat:
			# the cloud runway, its checkered line on the start line; an orange windsock on its far corner, swaying
			var ps := plat.get_size() * px
			draw_texture_rect(plat, Rect2((_line_at - ps * 0.5).round(), ps), false)
			# the orange windsock on the deck's back corner the plane starts from, flapping (the designer's 4 frames;
			# mirrored with the deck for a race going left)
			var left := _plat == "w"
			# (blown the other way from the painting's, the user: away from where the plane flies)
			var sock := RcSky.tex("windsock_%d" % (int(t * 14.0) % 4), not left)   # (fast: slow it looked like a bad gif, the user)
			if sock:
				var ss := sock.get_size() * px
				var foot := _line_at + RcSky.SOCK_FOOT * px * Vector2(-1.0 if left else 1.0, 1.0)
				draw_texture_rect(sock, Rect2((foot - Vector2(3.0 * px if left else ss.x - 3.0 * px, ss.y)).round(), ss), false)
			return
		var put := func(name: String, centre: Vector2, fx := false, fy := false) -> void:
			var tx := RcSky.tex(name, fx, fy)
			if tx:
				var size := tx.get_size() * px
				draw_texture_rect(tx, Rect2((centre - size * 0.5).round(), size), false)
		for fp in fans:
			var out_dir: Vector2 = fp[1]
			var arm := RcSky.tex("rotor_arm", out_dir.x > 0.0, out_dir.y > 0.0)   # (painted for the top left corner)
			if arm:
				var size := arm.get_size() * px
				var corner: Vector2 = fp[0]
				draw_texture_rect(arm, Rect2((corner - size * 0.5 + out_dir.sign() * size * 0.5).round(), size), false)
		var deck := RcSky.tex(_deck)
		if deck:
			draw_texture_rect(deck, Rect2(_deck_at, deck.get_size() * px), false)
		put.call("pad_line_v" if _deck == "pad_east" else "pad_line_h", _line_at)
		for k in lights.size():
			var on := int(t * 4.0 - float(k / 2) * 0.5) % 4 == 0
			put.call("light_on" if on else "light_off", lights[k])
		for fp in fans:
			var corner: Vector2 = fp[0]
			var hub: Vector2 = corner + (fp[1] as Vector2) * 30.0
			put.call("rotor_blur", hub)
			put.call("rotor_blades_%d" % (int(t * 24.0 + corner.x * 0.01) % 4), hub)
			put.call("rotor_ring", hub)
			put.call("rotor_hub", hub)

## RC ART's Sky: the drifting clouds' layers made (once) and filled for this course: each over the area its depth
## shows (as the ground's image: its share of the mat plus the rest of the view), about one cloud per square of
## CLOUD_EVERY world px; their shadows on the board, a little off them (the sun)
const CLOUD_EVERY := [720.0, 900.0]
func _sky_clouds_start() -> void:
	if _clouds_low == null:
		_clouds_low = SkyClouds.new()
		_clouds_high = SkyClouds.new()
		_cloud_shadows = SkyClouds.new()
		world.add_child(_clouds_low)
		world.move_child(_clouds_low, sky_shadow.get_index() + 1)    # (over the plane's shadow, under the course)
		world.add_child(_clouds_high)
		world.move_child(_clouds_high, _clouds_low.get_index() + 1)
	if _cloud_shadows.get_parent() != board:
		board.add_child(_cloud_shadows)                 # (on the ground: it moves with it)
	var view := VIEW.size / ZOOM
	for i in 2:
		var f: float = CLOUD_DEPTH[i]
		var a := Rect2(Vector2.ZERO, f * mat_size + (1.0 - f) * view)
		var n := int(a.get_area() / (CLOUD_EVERY[i] * CLOUD_EVERY[i])) + 2
		var layer: SkyClouds = [_clouds_low, _clouds_high][i]
		layer.setup(RcSky.CLOUDS_LOW if i == 0 else RcSky.CLOUDS_HIGH, a, n, CLOUD_WIND * (1.0 + 0.4 * i), course_seed * 17 + i, RcSky.ART_PX * CLOUD_SIZE[i], Color(1, 1, 1, CLOUD_ALPHA[i]))
		layer.visible = true
	var ga := Rect2(Vector2.ZERO, Vector2(_sky_ground * 2))
	_cloud_shadows.setup(RcSky.CLOUDS_LOW, ga, int(ga.get_area() / (360.0 * 360.0)) + 2, CLOUD_WIND / RcSky.ART_PX, course_seed * 17 + 5, 1.0, CLOUD_SHADOW)
	_cloud_shadows.visible = true

## RC ART's Sky: the designer's clouds drifting with the wind, nearly see-through (the user: "subtly displayed"),
## over an area wrapping round (a layer's own coordinates: its depth is its parallax, rc_racer _follow); or, as
## `shadow`, their shadows on the ground (the board's coordinates, one art px a unit)
class SkyClouds extends Node2D:
	var clouds: Array = []                # [texture, position, its drift (px/s)]
	var area := Rect2()
	var k := 2.0                          # world px per art px (1 on the board)
	var tint := Color(1, 1, 1, 0.3)
	func setup(names: Array, a: Rect2, n: int, wind: Vector2, seed_n: int, scale_k: float, col: Color) -> void:
		area = a
		k = scale_k
		tint = col
		clouds.clear()
		var rng := RandomNumberGenerator.new()
		rng.seed = seed_n
		for i in n:
			var tx := RcSky.tex(names[rng.randi() % names.size()])
			if tx == null:
				continue
			clouds.append([tx, Vector2(rng.randf_range(a.position.x, a.end.x), rng.randf_range(a.position.y, a.end.y)), wind * rng.randf_range(0.8, 1.2)])
		texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		queue_redraw()
	func _process(delta: float) -> void:
		if not visible or clouds.is_empty():
			return
		for c in clouds:
			var tx: Texture2D = c[0]
			var size := tx.get_size() * k
			c[1] += (c[2] as Vector2) * delta
			# (wrapping round: out past one side, back in past the other)
			var p: Vector2 = c[1]
			if p.x - size.x * 0.5 > area.end.x:
				p.x = area.position.x - size.x * 0.5
			if p.y - size.y * 0.5 > area.end.y:
				p.y = area.position.y - size.y * 0.5
			c[1] = p
		queue_redraw()
	func _draw() -> void:
		# (each cut to the area: past it is the dark frame round the course, the user)
		for c in clouds:
			var tx: Texture2D = c[0]
			var size := tx.get_size() * k
			var r := Rect2(((c[1] as Vector2) - size * 0.5).round(), size)
			var cut := r.intersection(area)
			if cut.size.x <= 0.0 or cut.size.y <= 0.0:
				continue
			var src := Rect2((cut.position - r.position) / k, cut.size / k)
			draw_texture_rect_region(tx, cut, src, tint)

## RC ART's Sky: a windmill's sails far below, turning slowly round their hub
class MillSails extends Sprite2D:
	func _process(delta: float) -> void:
		rotation += delta * 0.9

## The wind across the course in a gust: short white streaks blowing over it (on the 4 px grid)
class GustFx extends Node2D:
	var zones: Array = []                 # [points (the course there), the way it blows]
	var bits: Array = []                  # [position, velocity, age]
	func setup(z: Array) -> void:
		zones = z
		bits.clear()
	func _process(delta: float) -> void:
		if zones.is_empty():
			return
		for z in zones:
			if randf() < delta * 26.0:
				var pts: PackedVector2Array = z[0]
				var at := pts[randi() % pts.size()]
				var way: Vector2 = z[1]
				bits.append([at - way * 260.0 + Vector2(randf_range(-60, 60), randf_range(-60, 60)), way * randf_range(380.0, 520.0), 0.0])
		for b in bits:
			b[0] += (b[1] as Vector2) * delta
			b[2] += delta
		bits = bits.filter(func(b): return b[2] < 1.1)
		queue_redraw()
	func _draw() -> void:
		for b in bits:
			var p: Vector2 = (b[0] as Vector2).snapped(Vector2(4, 4))
			var v: Vector2 = (b[1] as Vector2).normalized()
			var a := 0.55 * sin(b[2] / 1.1 * PI)
			for k in 4:
				draw_rect(Rect2((p - v * k * 6.0).snapped(Vector2(4, 4)), Vector2(4, 4)), Color(1, 1, 1, a))

func _ready() -> void:
	game_music_path = "res://sounds/music/Pixel Chase.ogg"     # (107.22 BPM, looped on bar lines: tools/audio/loop_track.py)
	game_music_playlist = ["res://sounds/music/Pixel Chase (1).mp3"]   # (then this one, in turn: the user, 2026-10-28, less repetitive)
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
	course_seed = OLD_WORLD[world_no] * GameData.LEVELS_PER_WORLD + (level - 1) % GameData.LEVELS_PER_WORLD + 1
	vehicle = VEHICLES[world_no]
	look = LOOKS[world_no]
	cell = CELLS[vehicle]
	var spec0: Array = LEVELS[level - 1]
	extras = spec0[7] if spec0.size() > 7 else {}
	rain = bool(extras.get("rain", false))
	_set_vehicle()
	# (the how-to card names this level's toy: the first level played may be a boat's or a plane's)
	intro_text = { "car": "Steer your car", "boat": "Sail your boat", "plane": "Fly your plane" }[vehicle]   # (one line each)
	intro_icon = car_texture() if vehicle == "car" else _toy_icon(vehicle, 3)
	_build_circuit()
	_place_crowd()
	_place_features()
	_ramp_len = RAMP_LEN
	if not _tiles.is_empty():
		_snap_gaps()
	_buoy_spots.clear()
	board.texture = ImageTexture.create_from_image(_paint())
	track.texture = ImageTexture.create_from_image(track_image)
	buoys.setup(_buoy_spots)
	air_fx.visible = vehicle == "plane"
	air_fx.streaks.clear()
	calibrate_tilt()                                 # (the 3D layers: the pose now is "level")
	_depth_tilt = Vector2.ZERO
	for st in [crowd] + more_stands:
		st.position = Vector2.ZERO
	sky_dock.visible = vehicle == "plane"
	if vehicle == "plane":
		var d0 := (centre[2] - centre[0]).normalized()
		sky_dock.build(centre[0], d0, 20.0 * STEP, 6.0 * STEP, half_w * 0.72, RcSky.on(look))
	water_fx.visible = vehicle == "boat"
	water_fx.fine_fish = RcLagoon.on(look)
	water_fx.art_currents = RcLagoon.current_frames() if RcLagoon.on(look) else {}
	trail.fine = RcLagoon.on(look)
	water_fx.setup(self, slicks.filter(func(sl): return sl[1] == "whirl").map(func(sl): return sl[0]), Color8(255, 236, 214) if look == "lagoon" else Color8(236, 255, 252), pads if vehicle == "boat" else [], PAD_LEN, half_w - 34.0)
	canopy.visible = look == "garden" and not _trees.is_empty()
	if canopy.visible:
		canopy.texture = ImageTexture.create_from_image(_paint_canopy(int(mat_size.x / PX), int(mat_size.y / PX)))
	_tile_art()
	car_pos = centre[0]
	heading = (centre[2] - centre[0]).angle()
	near = 0
	progress = 0.0
	lap = 1
	race_time = 0.0
	falls = 0
	reset_lives()
	vel = Vector2.from_angle(heading) * _speed()
	bank = 0.0
	trail.marks.clear()
	last_cp = 0.0
	car_drop = 0.0
	# (a race lost on its last heart left the toy faded out, shrunk, under the track: put it back,
	# the user 2026-10-18: after a storm cloud the next race's plane was invisible)
	car.modulate = Color(1, 1, 1)
	car.scale = Vector2.ONE
	_wrecked = false
	for nd in [car, antenna, antenna_tip, driver]:
		if nd.get_parent() != front:
			nd.reparent(front, false)
	front.move_child(shadow, 0)
	front.move_child(prop, -1)                      # (the propeller over the plane's nose)
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
	var hint: String = WORLD_HINTS[world_no] if k == 0 else (LATER_HINTS[world_no][0] if k == 3 else (LATER_HINTS[world_no][1] if k == 6 else ""))
	_show_banner(WORLDS[world_no] if k == 0 else "%d-%d" % [world_no + 1, k + 1], 1.2 if k == 0 else 0.8)
	if hint != "":
		get_tree().create_timer(1.4 if k == 0 else 1.0).timeout.connect(func():
			if is_running and level == n:
				_show_banner(hint, 1.2))
	boost_t = 0.0
	bump_t = 0.0
	bounce_t = 0.0
	knock_v = Vector2.ZERO
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
	half_w = RcTiles.half_width(level) if RcTiles.on(look) else (RcLagoon.half_width(level) if RcLagoon.on(look) else spec[3])
	var pad := EDGE * PX + half_w + MARGIN
	var best: Array = []
	var best_err := 1 << 40
	if extras.has("eight"):
		best = _eight_corners(extras["eight"])
		best_err = 0
	for i in (0 if extras.has("eight") else SEED_TRIES):
		var rng := RandomNumberGenerator.new()
		rng.seed = 6151 * course_seed + 92821 * i + 3
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
	mat_size = Vector2(hi - lo) * cell + Vector2(pad, pad) * 2.0
	var pts: Array[Vector2] = []
	for c in best:
		pts.append(Vector2(c - lo) * cell + Vector2(pad, pad))
	_cross_pos = Vector2(_cross_grid - lo) * cell + Vector2(pad, pad)
	_tile_pad = pad
	_tiles = RcTiles.pieces(best.map(func(c): return Vector2i(c) - lo)) if RcTiles.on(look) else {}
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
	if not _tiles.is_empty():
		# (the start line on a whole straight square: the pieces draw it in its middle)
		_start_square = RcTiles.nearest_straight(_tiles, centre[0], pad, cell)
		if RcTiles.on(look) and vehicle == "car" and ResourceLoader.exists(RcTiles.DIR + "stand_front_under_mid.png"):
			var fs := _front_start(pad)
			if fs.x >= 0:
				_start_square = fs
		var k0 := RcTiles.nearest(centre, RcTiles.at(_start_square, pad, cell))
		rolled = PackedVector2Array()
		for i in count:
			rolled.append(centre[(k0 + i) % count])
		centre = rolled
	bridge_range = _find_bridge() if extras.has("eight") and vehicle == "car" else Vector2i(-1, -1)
	_find_rails(str(extras.get("rails", "")) if vehicle == "car" else "")
	if vehicle == "plane" and RcSky.on(look) and ResourceLoader.exists(RcTiles.DIR + "stand_front_under_mid.png"):
		var k1 := _sky_front_start()
		if k1 > 0:
			rolled = PackedVector2Array()
			for i in count:
				rolled.append(centre[(k1 + i) % count])
			centre = rolled
	_place_pads(spec[6])
	if not _tiles.is_empty():
		_snap_to_squares()
	par = ceilf(lap_length * LAPS / _speed() * PAR_SLACKS[vehicle] + PAR_PLUS - pads.size() * LAPS * PAD_SAVES)
	for kind in PAR_PER_THING:
		par += ceilf(int(extras.get(kind + "s", 0)) * PAR_PER_THING[kind] * LAPS)

## The car's guard rails (the user, 2026-10-17): on the outer side of the corners ("all") or of
## the hairpins only, the tightest ("hairpins": two corners the same way, a short straight between)
var _rail := PackedInt32Array()       # per centre point: 0, or the side its rail is on (+1 / -1: along the left normal or against it)
const RAIL_IN := 34.0                 # the car's middle meets the barrier this far inside the road's edge
const RAIL_KNOCK_V := 240.0           # ...and pushed back in at this (mat px/s), the push fading fast
const RAIL_BOUNCE := 1.0              # how much of its heading into the barrier bounces back out...
const RAIL_INWARD := 0.9              # ...and turned this much more towards the road's other side
const BOUNCE_TIME := 0.28             # ...easing round to it over this long
const BUMP_SLOW := 0.45               # a bump off a barrier: this much slower, fading over BUMP_TIME
const BUMP_TIME := 0.7

func _find_rails(kind: String) -> void:
	_rail = PackedInt32Array()
	_rail.resize(count)
	if kind == "":
		return
	# the corners: runs of points where the line turns (each its first and last point, its way)
	var corners: Array = []           # [first, last, turn's sign]
	var on := false
	for i in count:
		var a := centre[(i - 3 + count) % count]
		var b := centre[i]
		var c := centre[(i + 3) % count]
		var t := (b - a).angle_to(c - b)
		if absf(t) > 0.02:
			if not on:
				corners.append([i, i, signf(t)])
				on = true
			else:
				corners[-1][1] = i
		else:
			on = false
	if corners.size() > 1 and corners[0][0] == 0 and corners[-1][1] == count - 1 and corners[0][2] == corners[-1][2]:
		corners[0][0] = corners[-1][0] - count                # (a corner across the start: one corner)
		corners.pop_back()
	for ci in corners.size():
		var cr: Array = corners[ci]
		var want := kind == "all"
		if not want:
			# a hairpin: the next corner (or the one before) turns the same way, close by
			for o in [-1, 1]:
				var other: Array = corners[(ci + o + corners.size()) % corners.size()]
				var gap: int = (other[0] - cr[1]) if o == 1 else (cr[0] - other[1])
				gap = posmod(gap, count)
				if other[2] == cr[2] and gap * STEP < cell * 1.2:
					want = true
		if not want:
			continue
		# the outer side: a turn to the right (clockwise on screen) has it on the left
		var outer := -int(cr[2])
		for j in range(cr[0] - 6, cr[1] + 7):
			_rail[posmod(j, count)] = outer

## Is the course straight round point i (a little either side)?
func _straight(i: int, reach := 10) -> bool:
	for o in range(-reach, reach + 1, 5):
		var a := centre[posmod(i + o - 4, count)]
		var b := centre[posmod(i + o, count)]
		var c := centre[posmod(i + o + 4, count)]
		if absf((b - a).angle_to(c - b)) > 0.01:
			return false
	return true

## The left normal of the centre line at point i (screen: to the right when facing along it)
func _normal(i: int) -> Vector2:
	var d := (centre[(i + 1) % count] - centre[i]).normalized()
	return Vector2(-d.y, d.x)

## The tyre wall's px for the painter: 1 a tyre's dark rim, 2 its rubber, 3 its lit side, 4 its
## hole, 5 / 6 a painted (red / white) tyre's band; just outside the road's edge on a rail's side
func _rail_mask() -> PackedByteArray:
	# a racing barrier (the user, 2026-10-18: "more pro", "whole round pixelated tyres, actual tyre
	# barriers"): a belt along the road's edge in long blue and white panels, outlined; the tyres
	# behind it are whole round sprites stamped on afterwards (_stamp_tyres)
	var m := PackedByteArray()
	m.resize(_bw * _bh)
	if _rail.is_empty() or not _rail.has(1) and not _rail.has(-1):
		return m
	var hw := half_w / PX
	for i in m.size():
		var d := _dist[i]
		if d <= hw or d > hw + RAIL_BELT:
			continue
		var c := _idx[i]
		if _rail[c] == 0:
			continue
		var p := Vector2(i % _bw + 0.5, i / _bw + 0.5) * PX
		var n := _normal(c)
		if signf((p - centre[c]).dot(n)) != float(_rail[c]):
			continue
		var along := (c * STEP + (p - centre[c]).dot(Vector2(n.y, -n.x))) / PX
		if d > hw + RAIL_BELT - 0.9:
			m[i] = 1
		else:
			m[i] = 5 if int(floorf(along * (d / hw) / 7.0)) % 2 == 0 else 6
	return m

## The tyre barrier behind the belt: two rows of whole tyres (the back row staggered half a tyre,
## the front one over it), each a round pixel sprite (TYRE_ROWS), lit like the track
const TYRE_ROWS := [
	"...ooo...",
	".ooLLLoo.",
	".oLLLMMo.",
	"oLLoooMDo",
	"oLMohoDDo",
	"oLMoooDDo",
	".oMMDDDo.",
	".ooDDDoo.",
	"...ooo...",
]
func _stamp_tyres(top: PackedByteArray, w: int, h: int) -> void:
	if _rail.is_empty():
		return
	var hw := half_w / PX
	var cols := { "o": TYRE[3], "L": TYRE[2], "M": TYRE[1], "D": Color8(48, 44, 54), "h": Color8(14, 12, 18) }
	var front: Array = []                    # [middle (board px), outward]
	var back: Array = []
	var last := Vector2(-1e9, -1e9)
	var prev: Array = []
	for c in count:
		if _rail[c] == 0:
			last = Vector2(-1e9, -1e9)
			prev = []
			continue
		var out := _normal(c) * float(_rail[c])
		var at: Vector2 = centre[c] / PX + out * (hw + RAIL_BELT + TYRE_R - 2.0)   # (snug against the belt)
		if at.distance_to(last) < TYRE_STEP:
			continue
		front.append([at, out])
		if not prev.is_empty():
			var o2: Vector2 = ((prev[1] as Vector2) + out).normalized()
			back.append([((prev[0] as Vector2) + at) / 2.0 + o2 * TYRE_R * 1.35, o2])
		prev = [at, out]
		last = at
	for spot in back + front:
		var tl := Vector2i(((spot[0] as Vector2) - Vector2(4, 4)).round())
		for yy in TYRE_ROWS.size():
			var row: String = TYRE_ROWS[yy]
			for xx in row.length():
				var ch := row[xx]
				if ch == ".":
					continue
				var x := tl.x + xx
				var y := tl.y + yy
				if x < 0 or y < 0 or x >= w or y >= h:
					continue
				var col: Color = _lit(cols[ch], x, y)
				var kk := (y * w + x) * 4
				top[kk] = col.r8
				top[kk + 1] = col.g8
				top[kk + 2] = col.b8
				top[kk + 3] = 255

## The stand beside the start straight, on whichever side has room (never near the road)
func _place_crowd() -> void:
	var dir := (centre[4] - centre[0]).normalized()
	var horizontal := absf(dir.x) > absf(dir.y)
	var normal := Vector2(-dir.y, dir.x)
	for st in more_stands:
		st.visible = false
		st.art = false
	crowd.art = (vehicle == "car" and RcTiles.on(look) or vehicle == "boat" and RcLagoon.on(look) or vehicle == "plane" and RcSky.on(look)) and ResourceLoader.exists(RcTiles.DIR + "stand_front_under_mid.png")
	if crowd.art:
		_place_art_stands()
		return
	# the biggest stand that fits beside the finish line (tight circuits get a smaller one)
	for long in [440.0, 340.0, 260.0, 200.0]:
		if _try_crowd(dir, horizontal, normal, long):
			return
	crowd.visible = false

## RC NEW ART: the designer's stands (the user, 2026-10-27): one seen from the front beside the start
## line (the start is put where it fits, _front_start), and up to MORE_STANDS more seen from behind
## (or the side) round the course, each as long as there's room (the whole picture's 4 bays at most),
## close to the road
const STAND_LONGS := [816.0, 656.0, 496.0]   # end + 4 / 3 / 2 middles, world px
const SUNSET_STAND := Color(1.0, 0.92, 0.86)   # RC ART's Lagoon: the Garden's stand in the sunset's light (the user: "slightly changed")
const STAND_GAP := 8.0                 # from the road's edge (a stand below it: past its side face too)
const SKY_STAND_GAP := 60.0            # RC ART's Sky: from the course's edge (a ring reaches 22 past it, the cloud 44 more)
const SKY_START_NEAR := 700.0          # ...a stand this near the start counts as at the start line
func _stand_gap(away: Vector2) -> float:
	if vehicle == "boat":
		return SHORE_PAINT                           # (RC ART's Lagoon: its front on the sand bank, on a pier past it)
	if vehicle == "plane":
		return SKY_STAND_GAP                         # (RC ART's Sky: clear of the rings' ends, its cloud too)
	return STAND_GAP + (RcTiles.FACE_ROWS * RcTiles.ART_PX if away.y > 0.5 else 0.0)

func _place_art_stands() -> void:
	var deep := Crowd.ART_DEPTH * Crowd.art_k()
	var stands := [crowd] + more_stands
	var chosen: Array[Rect2] = []
	var put := func(r: Rect2, horizontal: bool, away: Vector2) -> void:
		var st: Crowd = stands[chosen.size()]
		st.art = true
		st.setup(r, horizontal, course_seed * 13 + 1 + chosen.size() * 7, away, "stand", CROWD_HAZE[look])
		st.pier = vehicle == "boat"
		st.sky = vehicle == "plane"
		st.modulate = SUNSET_STAND if vehicle == "boat" else Color.WHITE
		st.visible = true
		chosen.append(r)
	# by the start line, seen from the front
	var d0 := (centre[4] - centre[0]).normalized()
	if absf(d0.y) < 0.05:
		for long in STAND_LONGS:
			var r := _stand_rect(centre[0], true, Vector2.UP, long, deep)
			if _stand_fits(r, _stand_gap(Vector2.UP)):
				put.call(r, true, Vector2.UP)
				break
	# more round the course: from behind first, then from the side, then the front
	var spots: Array = []                            # [score, rect, horizontal, away]
	for i in range(0, count, 6):
		var d := (centre[(i + 6) % count] - centre[i]).normalized()
		if absf(d.x) > 0.02 and absf(d.y) > 0.02:
			continue                                 # (straights only)
		var horizontal := absf(d.x) > absf(d.y)
		var normal := Vector2(-d.y, d.x)
		for long in STAND_LONGS:
			for side in [1.0, -1.0]:
				var away: Vector2 = normal * side
				var score := (3.0 if away.y > 0.0 else 1.0) if horizontal else 2.0
				if vehicle == "plane":
					# (the Sky: seen from the front first, then the side, behind last; at the start line
					# before anywhere else, the user 2026-10-28: two from the front and one from behind there)
					score = ((1.0 if away.y > 0.0 else 3.0) if horizontal else 2.0) + (2.0 if centre[i].distance_to(centre[0]) < SKY_START_NEAR else 0.0)
				spots.append([score + long / 1000.0, _stand_rect(centre[i], horizontal, away, long, deep), horizontal, away])
	spots.sort_custom(func(x, y): return x[0] > y[0])
	for sp in spots:
		if chosen.size() >= stands.size():
			break
		var r: Rect2 = sp[1]
		if chosen.any(func(q): return q.grow(140.0).intersects(r)) or not _stand_fits(r, _stand_gap(sp[3])):
			continue
		put.call(r, sp[2], sp[3])
	crowd.visible = not chosen.is_empty()

## RC ART's Sky: the start moved along the course to a straight going across the screen where a stand seen
## from the front fits above it (the user, 2026-10-28: the audience at the start line, from the front), the
## pad's deck on the straight too; the course, its laps and par stay the same. -1: none fits
func _sky_front_start() -> int:
	var deep := Crowd.ART_DEPTH * Crowd.art_k()
	var best := -1
	var best_score := -INF
	for i in count:
		var d := (centre[(i + 1) % count] - centre[i]).normalized()
		if absf(d.y) > 0.02 or not _straight(i, 20) or not _straight(posmod(i - 14, count), 10):
			continue                                 # (the deck reaches 20 points back, 6 ahead)
		for long in STAND_LONGS:
			if _stand_fits(_stand_rect(centre[i], true, Vector2.UP, long, deep), SKY_STAND_GAP):
				var score: float = long - mini(i, count - i) * 2.0   # (the biggest stand, near the old start)
				if score > best_score:
					best_score = score
					best = i
				break
	return best

## A stand's place beside the road at a point, its back away from the road
func _stand_rect(at: Vector2, horizontal: bool, away: Vector2, long: float, deep: float) -> Rect2:
	var size := Vector2(long, deep) if horizontal else Vector2(deep, long)
	return Rect2(at + away * (half_w + _stand_gap(away) + deep / 2.0) - size / 2.0, size)

## RC NEW ART: the start on the straight square nearest the course's own start where a stand seen from
## the front fits above the road (the user: an audience on the start line, seen from the front); the
## course, its laps and par are the same, only where the line is moves. (-1, -1): none fits
func _front_start(pad: float) -> Vector2i:
	var deep := Crowd.ART_DEPTH * Crowd.art_k()
	var best := Vector2i(-1, -1)
	var best_d := INF
	for g in _tiles:
		if String(_tiles[g]) != "straight_h":
			continue
		var p := RcTiles.at(g, pad, cell)
		var r := _stand_rect(p, true, Vector2.UP, STAND_LONGS[-1], deep)
		if r.position.x < EDGE * PX + 8 or r.position.y < EDGE * PX + 8 or r.end.x > mat_size.x - EDGE * PX - 8:
			continue
		var clear := true
		for j in count:                              # (no rails known yet: a tyre wall's width all round)
			var q := centre[j]
			if q.distance_to(q.clamp(r.position, r.end)) < half_w + STAND_GAP - 6.0 + (60.0 if (centre[(j + 2) % count] - q).normalized().dot((q - centre[(j - 2 + count) % count]).normalized()) < 0.99 else 0.0):
				clear = false
				break
		if not clear:
			continue
		var d := p.distance_to(centre[0])
		if d < best_d:
			best_d = d
			best = g
	return best

## Is a stand's place on the mat and clear of the track (its tyre walls too)?
func _stand_fits(r: Rect2, gap: float) -> bool:
	if r.position.x < EDGE * PX + 8 or r.position.y < EDGE * PX + 8 or r.end.x > mat_size.x - EDGE * PX - 8 or r.end.y > mat_size.y - EDGE * PX - 8:
		return false
	for j in count:
		var p := centre[j]
		if p.distance_to(p.clamp(r.position, r.end)) < half_w + gap - 6.0 + (60.0 if _rail_at(j) else 0.0):
			return false
	return true

func _try_crowd(dir: Vector2, horizontal: bool, normal: Vector2, long: float) -> bool:
	var size := Vector2(long, 136) if horizontal else Vector2(136, long)
	var gap := SHORE_PAINT + 10.0 if vehicle == "boat" else 30.0        # (the boat's pier: past the shallows)
	for side in [1.0, -1.0]:
		var c: Vector2 = centre[0] + normal * side * (half_w + gap + 68.0)   # (on the finish line)
		var r := Rect2(c - size / 2.0, size)
		var ok := r.position.x > EDGE * PX + 8 and r.position.y > EDGE * PX + 8 and r.end.x < mat_size.x - EDGE * PX - 8 and r.end.y < mat_size.y - EDGE * PX - 8
		if ok:
			for j in count:
				var p := centre[j]
				var q := p.clamp(r.position, r.end)
				var clear := half_w + gap - 6.0 + (60.0 if _rail_at(j) else 0.0)   # (a tyre wall there: its width too)
				if p.distance_to(q) < clear:
					ok = false
					break
		if ok:
			crowd.setup(r, horizontal, course_seed * 13 + 1, normal * side, { "car": "stand", "boat": "pier", "plane": "cloud" }[vehicle], CROWD_HAZE[look])
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

## RC NEW ART: the boost pads onto whole straight squares (the pieces draw them in the middle), and
## which corner squares have a tyre wall
func _snap_to_squares() -> void:
	_pad_squares.clear()
	var taken: Array = [_start_square]
	for pd in pads:
		var g := RcTiles.nearest_straight(_tiles, pd[0], _tile_pad, cell, taken)
		if g.x < 0:
			continue
		taken.append(g)
		var p := RcTiles.at(g, _tile_pad, cell)
		var i := RcTiles.nearest(centre, p)
		var dir := (centre[(i + 1) % count] - centre[i]).normalized()
		pd[0] = p
		pd[1] = dir
		_pad_squares.append([g, dir])
	_rail_squares.clear()
	for i in _rail.size():
		if _rail[i] != 0:
			var g := Vector2i(((centre[i] - Vector2(_tile_pad, _tile_pad)) / cell).round())
			if String(_tiles.get(g, "")).begins_with("corner"):
				_rail_squares[g] = true

## RC NEW ART: each jump onto a whole straight square, its hole in the square's middle (as the gap
## pieces draw it, HOLE_AHEAD on), the long ramp right before it in the same square
func _snap_gaps() -> void:
	_gap_squares.clear()
	_ramp_len = RcTiles.ramp_length()
	var taken: Array = [_start_square]
	for pq in _pad_squares:
		taken.append(pq[0])
	for gi in gaps.size():
		var mid: int = (gaps[gi][0] + gaps[gi][1]) / 2
		var g := RcTiles.nearest_straight(_tiles, centre[mid], _tile_pad, cell, taken)
		if g.x < 0:
			gaps[gi] = []                                 # (no straight left: this jump goes)
			continue
		taken.append(g)
		var i := RcTiles.nearest(centre, RcTiles.at(g, _tile_pad, cell))
		var dir := (centre[(i + 1) % count] - centre[i]).normalized()
		var p := RcTiles.hole_at(g, _tile_pad, cell, dir)
		gaps[gi] = [RcTiles.nearest(centre, p - dir * RcTiles.GAP_HOLE), RcTiles.nearest(centre, p + dir * RcTiles.GAP_HOLE)]
		_gap_squares.append([g, dir])
	gaps = gaps.filter(func(gp): return not gp.is_empty())

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
	rng.seed = 4409 * course_seed + 11
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
	# the plane's rings first (the rest keeps clear of them): every RING_GAP along the course, each
	# moved onto the nearest straight bit (not just out of a bend)
	rings.clear()
	if vehicle == "plane":
		var gap_pts := int(RING_GAP / STEP)
		var i := 40
		while i < count - 30:
			var at := i
			for o in 25:
				if _straight(i + o):
					at = i + o
					break
				if _straight(i - o) and i - o > 30:
					at = i - o
					break
			at = clampi(at, 30, count - 30)
			rings.append({ "i": at, "pos": centre[at], "n": _normal(at), "r": float(extras.get("ring_r", 110.0)), "lap": 0, "hit": false })
			used.append([at - 10, at + 10])
			i += gap_pts
	# oil slicks, puddles (the car), whirlpools (the boat): to one side of the road, never across it
	# all (the user, 2026-10-17: there's always room to go round)
	for kind in ["oil", "puddle", "whirl"]:
		var want := int(extras.get({ "oil": "oil", "puddle": "puddles", "whirl": "whirls" }[kind], 0))
		var tries := 0
		var placed := 0
		while placed < want and tries < 200:
			tries += 1
			var i := rng.randi_range(40, count - 40)
			if not free_at.call(i - 6, i + 6) or not _straight(i, 12 if tries < 120 else 8):
				continue
			var side := -1.0 if rng.randf() < 0.5 else 1.0
			slicks.append([centre[i] + _normal(i) * side * rng.randf_range(0.42, 0.52) * half_w, kind])
			used.append([i - 6, i + 6])
			placed += 1
	# the boat's rocks and logs, the plane's balloons and storm clouds: each to one side, room to
	# go round the other way (a log reaches in from the buoys, under half way across)
	obstacles.clear()
	for kind in ["rock", "log", "balloon", "storm"]:
		var want := int(extras.get(kind + "s", 0))
		var tries := 0
		var placed := 0
		while placed < want and tries < 300:
			tries += 1
			var i := rng.randi_range(45, count - 40)
			# (on a straight, the longer the better, never in a bend where a toy swings out: none left,
			# one fewer), with room to straighten up between two (a boat drifts)
			if not free_at.call(i - 8, i + 8) or not _straight(i, 16 if tries < 150 else 9):
				continue
			var crowded := false
			for o2 in obstacles:
				if absi(posmod(int(o2["i"]) - i + count / 2, count) - count / 2) < (70 if vehicle == "boat" else 40):
					crowded = true
			if crowded and tries < 250:
				continue
			var side := -1.0 if rng.randf() < 0.5 else 1.0
			var n := _normal(i)
			var ob := { "kind": kind, "i": i, "side": side, "k": placed + level }
			match kind:
				"rock":
					ob["r"] = rng.randf_range(28.0, 34.0)
					ob["pos"] = centre[i] + n * side * rng.randf_range(0.38, 0.5) * half_w
				"log":
					var a := centre[i] + n * side * (half_w - 4.0)
					ob["a"] = a
					ob["b"] = a - (n * side).rotated(rng.randf_range(-0.25, 0.25)) * half_w * 0.85
					ob["pos"] = (a + ob["b"]) / 2.0
					ob["r"] = 13.0
				"balloon":
					ob["r"] = 34.0
					ob["pos"] = centre[i] + n * side * rng.randf_range(0.35, 0.8) * half_w
				"storm":
					ob["r"] = 56.0
					ob["pos"] = centre[i] + n * side * rng.randf_range(0.45, 0.7) * half_w
			ob["base"] = ob["pos"]
			obstacles.append(ob)
			used.append([i - 8, i + 8])
			placed += 1
	# the plane's gusts: stretches of the course where the wind blows across it, one way
	gusts.clear()
	for k in int(extras.get("gusts", 0)):
		for tries in 60:
			var i := rng.randi_range(45, count - 100)
			var len := int(520.0 / STEP)
			var clash := false
			for g in gusts:
				if i < g[1] + 30 and i + len > g[0] - 30:
					clash = true
			if not clash:
				gusts.append([i, i + len, -1.0 if rng.randf() < 0.5 else 1.0])
				break
	# the secret, if this level has one: a spot on a straight (or anywhere free); the last
	# level's gift goes first (it stayed behind in the next race when that one had none)
	if secret.has("node") and is_instance_valid(secret["node"]):
		(secret["node"] as Node).queue_free()
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
	var ramp_n := int(_ramp_len / STEP)
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
		var r := minf(cell * 0.5, minf(v.distance_to(p), v.distance_to(q)) * 0.5)
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
	_bw = w
	_bh = h
	if not _grass_noise:
		_grass_noise = FastNoiseLite.new()
		_grass_noise.frequency = 0.022
		_grass_noise.fractal_octaves = 3
		_cloud_noise = FastNoiseLite.new()
		_cloud_noise.frequency = 0.006
	_grass_noise.seed = course_seed
	_cloud_noise.seed = course_seed * 7 + 1
	_distance_field(w, h)
	match vehicle:
		"boat":
			return _paint_water(w, h)
		"plane":
			return _paint_sky(w, h)
	return _paint_track(w, h)

var _dist := PackedFloat32Array()      # every board px: its distance to the course's centre line
var _idx := PackedInt32Array()         # ...and the centre point nearest it (the curbs' stripes, the dashes)

## The distance from each board px to the centre line (stamped round every other point)
func _distance_field(w: int, h: int) -> void:
	_dist = PackedFloat32Array()
	_dist.resize(w * h)
	_dist.fill(1e9)
	_idx = PackedInt32Array()
	_idx.resize(w * h)
	var hw := half_w / PX
	# (the boat's: out past its bank, the shallows and the bank are painted from it: it stopped
	# just past the bank's edge, so on the straights the bank came out a thin line)
	var reach := hw + (SHORE_PAINT / PX + 16.0 if vehicle == "boat" else 4.0)
	for s in range(0, count, 3):                     # (points 24 px apart: the discs overlap)
		var c := centre[s] / PX
		for y in range(maxi(0, int(c.y - reach)), mini(h, int(c.y + reach) + 1)):
			for x in range(maxi(0, int(c.x - reach)), mini(w, int(c.x + reach) + 1)):
				var d := Vector2(x + 0.5, y + 0.5).distance_to(c)
				var i := y * w + x
				if d < _dist[i]:
					_dist[i] = d
					_idx[i] = s

## The car's world: two layers, the floor (the carpet, the frame, the track's shadow) and the raised
## track (the road, its curbs, its rails, its side face): a car falling off drops between them
func _paint_track(w: int, h: int) -> Image:
	var dist := _dist
	var idx := _idx
	var hw := half_w / PX
	_garden_decor(w, h, dist, hw)
	_lamps.clear()
	if look == "night":
		# a lamp every ~160 board px round the circuit, just off the road's outer side
		for s2 in range(0, count, int(640.0 / STEP)):
			var c2 := centre[s2] / PX
			var dirv := (centre[(s2 + 1) % count] - centre[s2]).normalized()
			var out := Vector2(-dirv.y, dirv.x)
			_lamps.append(c2 + out * (hw + 16.0))
			_lamps.append(c2 - out * (hw + 16.0))
	_lamp_light = PackedFloat32Array()
	if look == "night":
		_lamp_light.resize(w * h)
		_lamp_light.fill(0.0)
		const LR := 58.0
		for lp in _lamps:
			for yy in range(maxi(0, int(lp.y - LR)), mini(h, int(lp.y + LR) + 1)):
				for xx in range(maxi(0, int(lp.x - LR)), mini(w, int(lp.x + LR) + 1)):
					var v2 := 1.0 - Vector2(xx, yy).distance_to(lp) / LR
					if v2 > _lamp_light[yy * w + xx]:
						_lamp_light[yy * w + xx] = v2
	# below the road's south edge, column by column: how many rows down from the road (its side
	# face, then its outline), and which road px it hangs from
	var below := PackedByteArray()
	below.resize(w * h)
	var below_i := PackedInt32Array()
	below_i.resize(w * h)
	for x in w:
		var run := 255
		var from := 0
		for y in h:
			var i := y * w + x
			if dist[i] <= hw + 2.0:
				run = 0
				from = idx[i]
			elif run < 255:
				run += 1
			below[i] = run
			below_i[i] = from
	var rails := _rail_mask()
	var data := PackedByteArray()
	data.resize(w * h * 4)
	var top := PackedByteArray()
	top.resize(w * h * 4)
	var k := 0
	var curb := 3.0
	var dark_road := look == "night"
	var sd: Array = SIDES[look]
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
			elif d <= hw + 2.0 and _in_gap(idx[i]):
				# a jump's gap: no road, the ground far below (its cut edges outlined)
				on_track = false
				col = _floor_px(x, y).darkened(0.12)
				if _in_gap(idx[i] - 1) == false or _in_gap(idx[i] + 1) == false:
					col = OUTLINE
			elif d <= hw - curb:
				col = ROAD[0] if (x * 3 + y * 5) % 7 else ROAD[1]
				if dark_road:
					col = col.darkened(0.18)                     # (night asphalt, wet or not)
				if d < 0.8 and (idx[i] / 6) % 2 == 0:
					col = LINE                                   # the dashed centre line
				if _on_ramp(idx[i]):
					# a ramp: yellow and dark chevrons, lighter as it rises towards the gap
					var rise := float(idx[i] % int(RAMP_LEN / STEP)) / (RAMP_LEN / STEP)
					col = (PAD[0] if ((idx[i] / 2) + int(d)) % 3 != 0 else PAD[2]).lightened(0.25 * rise)
				if not slicks.is_empty():
					var wp := Vector2(x + 0.5, y + 0.5) * PX
					for sl in slicks:
						var off: Vector2 = wp - sl[0]
						if off.length_squared() > SLICK_R * SLICK_R * 1.5:
							continue
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
					if absf(u) >= PAD_LEN / 2.0:
						continue
					var v := loc.dot(Vector2(-pd[1].y, pd[1].x))
					if absf(v) < half_w - 14.0:
						# a boost pad: yellow chevrons pointing down the road on a dark plate
						var ch := fposmod(u / PX - absf(v) / PX * 0.8, 8.0)
						col = PAD[0] if ch < 3.0 else (PAD[1] if ch < 4.0 else PAD[2])
						if absf(u) > PAD_LEN / 2.0 - PX or absf(v) > half_w - 14.0 - PX:
							col = OUTLINE
			elif d <= hw:
				col = CURB[(idx[i] / 4) % 2]                     # red-and-white curbs
			elif rails[i] != 0:
				# the guard rail: a tyre wall along the edge
				var tc := rails[i]
				col = TYRE_PAINT[tc - 5] if tc >= 5 else TYRE[[0, 0, 1, 2, 3][tc]]
			elif d <= hw + 2.0:
				col = OUTLINE
			else:
				# below the road's south edge: the raised track's side (seen at an angle), on toy
				# blocks every so often; then the floor, in the track's shadow
				var up_t := int(below[i])
				if up_t >= 1 and up_t <= TRACK_SIDE and _in_gap(below_i[i]):
					up_t = -1                                    # (no side under a gap)
				if up_t >= 1 and up_t <= TRACK_SIDE:
					col = sd[0] if up_t <= 2 else (sd[1] if up_t < TRACK_SIDE else sd[2])
					if up_t > 2 and (below_i[i] / 10) % 3 == 0:
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
				# (under the track, the floor is never seen: left dark)
				data[k + 3] = 255
			else:
				data[k] = col.r8
				data[k + 1] = col.g8
				data[k + 2] = col.b8
				data[k + 3] = 255
			k += 4
	_stamp_tyres(top, w, h)
	track_image = Image.create_from_data(w, h, false, Image.FORMAT_RGBA8, top)
	return Image.create_from_data(w, h, false, Image.FORMAT_RGBA8, data)

## The mat's wooden frame round the edge: outlined both sides, lit top / left, shaded bottom / right
func _frame_px(x: int, y: int, w: int, h: int, e: int) -> Color:
	if e <= 1 or e >= EDGE - 2:
		return MAT_EDGE[2]
	if (y < h / 2 and y == e) or (x < w / 2 and x == e) or (y < x and y < h - 1 - x and y < h / 2) or (x <= y and x < w - 1 - y and x < w / 2):
		return MAT_EDGE[0]
	return MAT_EDGE[1]

## Puts a small image into a layer's bytes (its clear px left as they are), board px
static func _blit(dst: PackedByteArray, w: int, h: int, img: Image, at: Vector2i) -> void:
	for yy in img.get_height():
		for xx in img.get_width():
			var c := img.get_pixel(xx, yy)
			if c.a < 0.5:
				continue
			var x := at.x + xx
			var y := at.y + yy
			if x < 0 or y < 0 or x >= w or y >= h:
				continue
			var k := (y * w + x) * 4
			dst[k] = c.r8
			dst[k + 1] = c.g8
			dst[k + 2] = c.b8
			dst[k + 3] = 255

## The boat's worlds: water all over (the Lagoon at sunset, the Reef at noon), the channel the boat
## keeps to a little deeper between its two lines of buoys; shallows outside, sand, an island here
## and there; on the channel the currents' foam arrows, the sandbars (a ramp's gap), the foam round
## the rocks, the whirlpools. The buoys on their rope, the ramps and the start line float on the
## track layer.
func _paint_water(w: int, h: int) -> Image:
	var dist := _dist
	var idx := _idx
	var hw := half_w / PX
	var rng := RandomNumberGenerator.new()
	rng.seed = 77 * course_seed + 5
	_sandbars.clear()
	_palms.clear()
	_sea = PackedFloat32Array()
	_clear = PackedFloat32Array()
	if RcLagoon.on(look):
		_sea_fields(w, h, hw)
	for k in int(w * h / 16000) + 3:
		var p := Vector2(rng.randi_range(EDGE + 30, w - EDGE - 30), rng.randi_range(EDGE + 20, h - EDGE - 20))
		var sc := rng.randf_range(0.7, 1.15)
		# (clear of the channel, its shallows and its bank: never land where the boat may go)
		var apart := true
		# (never under the stand: the pier with the crowd sat on an island, the user 2026-10-18)
		for st in _stands():
			if Rect2(st.rect.position / PX, st.rect.size / PX).grow(30.0 * sc * 1.4 + 6.0).has_point(p):
				apart = false
		for other in _sandbars:
			if Vector2(((other[0] as Vector2) - p).x / 1.9, ((other[0] as Vector2) - p).y).length() < 22.0 * (sc + float(other[1])):
				apart = false                            # (never two islands in one another)
		var sc_i := _sea_cell(Vector2i(p))
		if sc_i >= 0 and (_sea[sc_i] < 10.0 or _clear[sc_i] < 36.0 * sc * PX):   # (_sea tops out at 1.5 cells: _sea_fields)
			apart = false                                # (RC ART: only in water wide enough, never on the sand)
		if apart and dist[int(p.y) * w + int(p.x)] > hw + SHORE_PAINT / PX + 16.0 + 40.0 * sc:
			_sandbars.append([p, sc])
	# the islands, stamped once (the user, 2026-10-18: more beautiful, like the car's tracks, the
	# Retry look): a beach outlined dark against the water and lit from the top left, a raised
	# grass top (its own outline, an earthy side face below it), its shadow on the water to the
	# bottom right, the shallows round it; palm trees on the bigger ones (_paint_palm)
	_island = PackedByteArray()
	_island.resize(w * h)
	for sbi in _sandbars:
		var sb: Vector2 = sbi[0]
		var sc: float = sbi[1]
		var ax := 30.0 * sc
		var by := 16.0 * sc
		for yy in range(maxi(0, int(sb.y - by * 1.4 - 4)), mini(h, int(sb.y + by * 1.4 + 6))):
			for xx in range(maxi(0, int(sb.x - ax * 1.4 - 4)), mini(w, int(sb.x + ax * 1.4 + 6))):
				var o := Vector2((xx + 0.5 - sb.x) / ax, (yy + 0.5 - sb.y) / by)
				var dd := o.length()
				var v := 0
				if dd < 1.0:
					var g := Vector2((xx + 0.5 - sb.x) / (ax * 0.62), (yy + 0.5 - sb.y + 2.0) / (by * 0.62)).length()
					var g_low := Vector2((xx + 0.5 - sb.x) / (ax * 0.62), (yy + 0.5 - sb.y) / (by * 0.62)).length()
					var lean := o.x + o.y
					if g < 1.0:
						v = ISLE_GRASS_RIM if g > 0.88 else (ISLE_GRASS_LIT if lean < -0.45 else (ISLE_GRASS_DARK if lean > 0.5 or (xx * 7 + yy * 3) % 23 == 0 else ISLE_GRASS))
					elif g_low < 1.0 and yy + 0.5 > sb.y - 2.0:
						v = ISLE_GRASS_RIM if g_low > 0.86 else ISLE_CLIFF          # (the grass top's side)
					elif dd > 0.93:
						v = ISLE_RIM
					elif dd > 0.84:
						v = ISLE_WET
					else:
						v = ISLE_SAND_LIT if lean < -0.7 else (ISLE_SAND_DARK if lean > 0.7 and DITHER[yy % 2][xx % 2] < 0.5 else ISLE_SAND)
				else:
					var sh := Vector2((xx + 0.5 - sb.x - 3.0) / ax, (yy + 0.5 - sb.y - 3.0) / by).length()
					if sh < 1.0:
						v = ISLE_SHADOW
					elif dd < 1.3 and DITHER[yy % 2][xx % 2] < 0.5:
						v = ISLE_SHALLOW
				var ii := yy * w + xx
				if v != 0 and ISLE_PRIO[v] > ISLE_PRIO[_island[ii]]:
					_island[ii] = v
		if sc > 0.85:
			_palms.append(Vector2i(sb.round()) + Vector2i(rng.randi_range(-4, 4), -3))
		if sc > 1.05:
			_palms.append(Vector2i(sb.round()) + Vector2i(rng.randi_range(5, 9), -1))
	# the reef's coral in the shallows: clusters of round lumps (pink, orange, lilac), lit top left;
	# per board px its colour (1-3) x 4 + its shade (1 light, 2 mid, 3 dark)
	_coral = PackedByteArray()
	_coral.resize(w * h)
	if look == "reef":
		# the bank along the channel: coral packed tight just past the shallows (a crash)
		var bank := SHORE_PAINT / PX
		for s0 in range(0, count, 2):
			var c0 := centre[s0] / PX
			var n0 := _normal(s0)
			for sd in [-1.0, 1.0]:
				_coral_clump(c0 + n0 * sd * (hw + bank + rng.randf_range(2.0, 7.0)), rng, w, h, 2, 4)
		for k in int(w * h / 900):
			var cc := Vector2(rng.randi_range(EDGE + 8, w - EDGE - 8), rng.randi_range(EDGE + 8, h - EDGE - 8))
			if dist[int(cc.y) * w + int(cc.x)] < hw + SHORE_PAINT / PX or _island[int(cc.y) * w + int(cc.x)] != 0:
				continue
			_coral_clump(cc, rng, w, h, 3, 6)
	var data := PackedByteArray()
	data.resize(w * h * 4)
	_keep = PackedByteArray()
	_keep.resize(w * h)
	var lagoon_isles := RcLagoon.on(look) and RcLagoon.has_islands()
	var lagoon_jumps := RcLagoon.on(look) and RcLagoon.has_jumps()   # (the designer's jumps: RcLagoon._jumps draws them)
	var k := 0
	for y in h:
		for x in w:
			var i := y * w + x
			var d := dist[i]
			var e := mini(mini(x, y), mini(w - 1 - x, h - 1 - y))
			var col: Color
			if e < EDGE:
				col = _frame_px(x, y, w, h, e)
				_keep[i] = 1
			else:
				if _island[i] != 0 and not lagoon_isles:
					_keep[i] = 1
				col = _water_px(x, y, d, hw)
				if d <= hw + 2.0 and _in_gap(idx[i]) and not lagoon_jumps:
					_keep[i] = 1
					# a sandbar across the channel: the boat must jump it (wet at its edges)
					col = Color8(240, 210, 150) if _in_gap(idx[i] - 1) and _in_gap(idx[i] + 1) else Color8(206, 176, 120)
			col = _lit(col, x, y)
			data[k] = col.r8
			data[k + 1] = col.g8
			data[k + 2] = col.b8
			data[k + 3] = 255
			k += 4
	if not lagoon_isles:                             # (RC ART with the designer's islands: they and their palms are RcLagoon.decor's)
		for pf in _palms:
			_paint_palm(data, w, h, pf)
	if look == "lagoon":
		_lagoon_bank_decor(data, w, h, rng)
	# then the channel's own things, each over its own patch: a current's foam arrows down the
	# channel, a whirlpool (water spiralling in, darker to its eye), the foam round a rock or a log
	for pd in pads:
		var c0: Vector2 = pd[0]
		var dv: Vector2 = pd[1]
		for q in _patch(c0, PAD_LEN + half_w, w, h):
			var i2 := q.y * w + q.x
			if dist[i2] > hw + 2.0 or _in_gap(idx[i2]):
				continue
			var loc := (Vector2(q) + Vector2(0.5, 0.5)) * PX - c0
			var u := loc.dot(dv)
			var v := absf(loc.dot(Vector2(-dv.y, dv.x)))
			if absf(u) < PAD_LEN and v < half_w - 30.0:
				_tint(data, i2, Color8(255, 236, 160), 0.1 * clampf(1.0 - absf(u) / PAD_LEN, 0.0, 1.0) * 2.0)   # (a faint warm glow, fading to its ends: its arrows flow over it, WaterFx)
	for sl in slicks:
		var c1: Vector2 = sl[0]
		for q in _patch(c1, SLICK_R, w, h):
			var off := (Vector2(q) + Vector2(0.5, 0.5)) * PX - c1
			var r := off.length()
			if r >= SLICK_R:
				continue
			var i3 := q.y * w + q.x
			_tint(data, i3, Color8(10, 40, 60), 0.25 * (1.0 - r / SLICK_R))
			if fposmod(off.angle() * 3.0 + r * 0.16, TAU) < 0.9:
				_tint(data, i3, Color8(240, 250, 255), 0.45 * (r / SLICK_R))
	for ob in obstacles:
		if ob["kind"] != "rock" and ob["kind"] != "log":
			continue
		var c2: Vector2 = ob["pos"]
		var reach := float(ob["r"]) + 22.0 + (half_w * 0.45 if ob["kind"] == "log" else 0.0)
		for q in _patch(c2, reach, w, h):
			var wp := (Vector2(q) + Vector2(0.5, 0.5)) * PX
			var dd: float
			if ob["kind"] == "log":
				dd = Geometry2D.get_closest_point_to_segment(wp, ob["a"], ob["b"]).distance_to(wp) - float(ob["r"])
			else:
				dd = wp.distance_to(c2) - float(ob["r"])
			if dd > 0.0 and dd < 22.0 and ((q.x + q.y) % 2 == 0 or dd < 10.0):
				_tint(data, q.y * w + q.x, Color8(250, 252, 255), 0.75 - dd / 40.0)
	# the track layer: the floating ramps, the start line; the buoys marking both edges of the
	# channel float on their own (FloatingBuoys: the boat pushes them aside)
	_buoy_spots.clear()
	var top := PackedByteArray()
	top.resize(w * h * 4)
	# (one every BUOY_GAP along each edge itself: spaced by the course's middle they bunched up on
	# the inside of the bends, the user 2026-10-18)
	for sd in [-1.0, 1.0]:
		var placed := PackedVector2Array()
		var first: Vector2 = centre[0] / PX + _normal(0) * sd * hw
		var nb := 0
		for s3 in count:
			var at: Vector2 = centre[s3] / PX + _normal(s3) * sd * hw
			if not placed.is_empty() and at.distance_to(placed[placed.size() - 1]) < BUOY_GAP:
				continue
			if s3 > count - 8 and at.distance_to(first) < BUOY_GAP:
				continue                                         # (the lap closing on the first one)
			placed.append(at)
			_buoy_spots.append([(at.round() + Vector2(0.5, 0.5)) * PX, nb % 2 == 0])
			nb += 1
	for i3 in count:
		if (_on_ramp(i3) and not (RcLagoon.on(look) and RcLagoon.has_jumps())) or ((i3 <= 2 or i3 >= count - 2) and not RcLagoon.on(look)):   # (RC ART: its own start and jumps, RcLagoon)
			var c4 := centre[i3] / PX
			var n4 := _normal(i3)
			for o in range(-int(hw) + 5, int(hw) - 4):
				var q4 := (c4 + n4 * o).round()
				if q4.x < 0 or q4.y < 0 or q4.x >= w or q4.y >= h:
					continue
				var col4: Color
				if _on_ramp(i3):
					var rise := float(i3 % int(RAMP_LEN / STEP)) / (RAMP_LEN / STEP)
					col4 = (PAD[0] if ((i3 / 2) + absi(o)) % 3 != 0 else PAD[2]).lightened(0.2 * rise)
					if absi(o) >= int(hw) - 7:
						col4 = Color8(176, 122, 74)                # (its wooden sides)
				else:
					col4 = Color8(30, 30, 34) if ((o / 2) + (i3 / 2)) % 2 else LINE   # the start line's floats
				var k4 := (int(q4.y) * w + int(q4.x)) * 4
				top[k4] = col4.r8
				top[k4 + 1] = col4.g8
				top[k4 + 2] = col4.b8
				top[k4 + 3] = 255
	track_image = Image.create_from_data(w, h, false, Image.FORMAT_RGBA8, top)
	return Image.create_from_data(w, h, false, Image.FORMAT_RGBA8, data)

## RC ART's Lagoon (the user, 2026-10-28: sand in the narrow gaps between curves, the thin necks widened or
## joined softly, but the big closed waters kept, with their islands): the open water "opened" like a
## picture: only what a disc of SEA_R fits in stays water, the rest is sand, its edges rounded. On a coarse
## grid (SEA_CELL board px), as fields the shader reads smoothly: _clear, how far each cell is from the
## course's banks (world px), and _sea, how far inside the kept water (world px, <= 0: sand)
const SEA_CELL := 2                    # board px per cell
const SEA_R := 72.0                    # water narrower than about twice this becomes sand (world px)
const POND_MIN := 2.0                  # closed-in water smaller than this many course squares becomes sand too
const SAND_ROUND := 90.0               # the sand's corners poking into the water rounded this much (world px: the user,
                                       # the inside of 90-degree turns was "too squarey")
func _sea_fields(w: int, h: int, hw: float) -> void:
	_sea_w = (w + SEA_CELL - 1) / SEA_CELL
	_sea_h = (h + SEA_CELL - 1) / SEA_CELL
	var n := _sea_w * _sea_h
	var land_at := hw + SHORE_PAINT / PX + RcLagoon.BANK_W / PX      # (past the bank: open water)
	var cell := float(SEA_CELL * PX)                                  # world px per cell
	var src := PackedByteArray()
	src.resize(n)
	for cy in _sea_h:
		for cx in _sea_w:
			var d := 1e9
			for oy in SEA_CELL:
				for ox in SEA_CELL:
					var x := mini(cx * SEA_CELL + ox, w - 1)
					var y := mini(cy * SEA_CELL + oy, h - 1)
					d = minf(d, _dist[y * w + x])
			src[cy * _sea_w + cx] = 1 if d <= land_at else 0
	_clear = _chamfer(src, _sea_w, _sea_h)
	var core := PackedByteArray()
	core.resize(n)
	for i in n:
		_clear[i] *= cell
		core[i] = 1 if _clear[i] >= SEA_R else 0
	_sea = _chamfer(core, _sea_w, _sea_h)
	for i in n:
		_sea[i] = SEA_R - _sea[i] * cell
	# a small pond closed in by the course (cut off from the open sea, the board's edge): sand as well
	var seen := PackedByteArray()
	seen.resize(n)
	var small := POND_MIN * self.cell * self.cell / (cell * cell)            # (in cells)
	for start in n:
		if seen[start] != 0 or _sea[start] <= 0.0:
			continue
		var part := PackedInt32Array([start])
		seen[start] = 1
		var open := false
		var head := 0
		while head < part.size():
			var i := part[head]
			head += 1
			var x := i % _sea_w
			var y := i / _sea_w
			if x == 0 or y == 0 or x == _sea_w - 1 or y == _sea_h - 1:
				open = true
			for j in [i - 1 if x > 0 else -1, i + 1 if x < _sea_w - 1 else -1, i - _sea_w if y > 0 else -1, i + _sea_w if y < _sea_h - 1 else -1]:
				if j >= 0 and seen[j] == 0 and _sea[j] > 0.0:
					seen[j] = 1
					part.append(j)
		if not open and part.size() < small:
			for i in part:
				_sea[i] = -SEA_R
	# the sand's corners rounded: the water "closed" (grown out, then back), so where the sand pokes into it
	# at a square corner the water takes the corner off; the bank by the channel is kept (RcLagoon's bank_min)
	var water := PackedByteArray()
	water.resize(n)
	for i in n:
		water[i] = 1 if _sea[i] > 0.0 else 0
	var to_wet := _chamfer(water, _sea_w, _sea_h)
	var grown := PackedByteArray()
	grown.resize(n)
	for i in n:
		grown[i] = 0 if to_wet[i] * cell <= SAND_ROUND else 1             # (1: land after growing the water)
	var to_dry := _chamfer(grown, _sea_w, _sea_h)
	for i in n:
		_sea[i] = maxf(_sea[i], minf(to_dry[i] * cell - SAND_ROUND, 1.5 * cell))
	# only edges by the water left draw a beach: away from it the sand goes on down (no traces of a filled pond)
	for i in n:
		water[i] = 1 if _sea[i] > 0.0 else 0
	var to_water := _chamfer(water, _sea_w, _sea_h)
	for i in n:
		_sea[i] = minf(_sea[i], (1.5 - to_water[i]) * cell)

## The distance from every cell to the nearest source cell (in cells), two passes
static func _chamfer(src: PackedByteArray, w: int, h: int) -> PackedFloat32Array:
	const D := 1.4142
	var f := PackedFloat32Array()
	f.resize(w * h)
	for i in w * h:
		f[i] = 0.0 if src[i] != 0 else 1e6
	for y in h:
		for x in w:
			var i := y * w + x
			var v := f[i]
			if x > 0: v = minf(v, f[i - 1] + 1.0)
			if y > 0:
				v = minf(v, f[i - w] + 1.0)
				if x > 0: v = minf(v, f[i - w - 1] + D)
				if x < w - 1: v = minf(v, f[i - w + 1] + D)
			f[i] = v
	for y in range(h - 1, -1, -1):
		for x in range(w - 1, -1, -1):
			var i := y * w + x
			var v := f[i]
			if x < w - 1: v = minf(v, f[i + 1] + 1.0)
			if y < h - 1:
				v = minf(v, f[i + w] + 1.0)
				if x < w - 1: v = minf(v, f[i + w + 1] + D)
				if x > 0: v = minf(v, f[i + w - 1] + D)
			f[i] = v
	return f

## A board px's cell in the fields above (-1: none)
func _sea_cell(b: Vector2i) -> int:
	if _sea.is_empty() or b.x < 0 or b.y < 0 or b.x >= _bw or b.y >= _bh:
		return -1
	return (b.y / SEA_CELL) * _sea_w + b.x / SEA_CELL

## The Lagoon's bank, dressed (the user, 2026-10-18): pebbles, starfish and shells on the sand,
## tufts of seagrass in the shallows beside it, all outlined like the rest
const PEBBLE := [".##.", "#lm#", "#md#", ".##."]
const STARFISH := ["..#..", ".#s#.", "#sSs#", ".#s#.", ".#.#."]
const SHELL := [".#.", "#w#", "#p#"]
const SEAGRASS := ["g.g", "g.g", ".gG", ".G."]
func _lagoon_bank_decor(data: PackedByteArray, w: int, h: int, rng: RandomNumberGenerator) -> void:
	var hw := half_w / PX
	var bank := hw + SHORE_PAINT / PX
	var cols := { "#": Color8(118, 82, 58), "l": Color8(214, 208, 200), "m": Color8(170, 162, 160), "d": Color8(130, 122, 124),
		"s": Color8(250, 140, 90), "S": Color8(255, 196, 140), "w": Color8(255, 246, 236), "p": Color8(248, 196, 206),
		"g": Color8(110, 150, 96), "G": Color8(80, 120, 78) }
	var stamp := func(rows: Array, at: Vector2i) -> void:
		for yy in rows.size():
			var row: String = rows[yy]
			for xx in row.length():
				var ch := row[xx]
				if ch == ".":
					continue
				var q := at + Vector2i(xx - row.length() / 2, yy - rows.size() / 2)
				if q.x < EDGE or q.y < EDGE or q.x >= w - EDGE or q.y >= h - EDGE:
					continue
				var c: Color = _lit(cols[ch], q.x, q.y)
				var j := (q.y * w + q.x) * 4
				data[j] = c.r8
				data[j + 1] = c.g8
				data[j + 2] = c.b8
	for s0 in range(0, count, 3):
		for sd in [-1.0, 1.0]:
			var c0: Vector2 = centre[s0] / PX + _normal(s0) * sd * (bank + 5.0)
			var ci := Vector2i(c0.round())
			if ci.x < 0 or ci.y < 0 or ci.x >= w or ci.y >= h or absf(_dist[ci.y * w + ci.x] - bank - 5.0) > 2.5:
				continue                                  # (another stretch of the course is nearer here)
			var roll := rng.randf()
			if roll < 0.16:
				stamp.call(PEBBLE, ci + Vector2i(rng.randi_range(-1, 1), 0))
			elif roll < 0.24:
				stamp.call(STARFISH, ci)
			elif roll < 0.34:
				stamp.call(SHELL, ci)
			# and seagrass just past the bank, in the open shallows
			if rng.randf() < 0.3:
				var g0 := Vector2i((centre[s0] / PX + _normal(s0) * sd * (bank + 14.0 + rng.randf_range(0.0, 6.0))).round())
				if g0.x >= 0 and g0.y >= 0 and g0.x < w and g0.y < h and _dist[g0.y * w + g0.x] > bank + 11.0 and _island[g0.y * w + g0.x] == 0:
					stamp.call(SEAGRASS, g0)

## A palm tree on an island (foot: board px): its shadow on the sand, a curved trunk with rings,
## five fronds drooping out from its top, outlined, two coconuts
func _paint_palm(data: PackedByteArray, w: int, h: int, foot: Vector2i) -> void:
	var put := func(q: Vector2i, c: Color) -> void:
		if q.x >= 0 and q.y >= 0 and q.x < w and q.y < h:
			if _keep.size() == w * h:
				_keep[q.y * w + q.x] = 1
			var cc := _lit(c, q.x, q.y)
			var j := (q.y * w + q.x) * 4
			data[j] = cc.r8
			data[j + 1] = cc.g8
			data[j + 2] = cc.b8
	var top := foot + Vector2i(2, -7)
	# its shadow first
	for sy in range(-2, 3):
		for sx in range(-4, 5):
			if Vector2(sx / 4.0, sy / 2.0).length() <= 1.0:
				var q := top + Vector2i(sx + 4, sy + 8)
				if q.x >= 0 and q.y >= 0 and q.x < w and q.y < h:
					_tint(data, q.y * w + q.x, Color8(60, 50, 40), 0.35)
	var trunk: Array[Vector2i] = []
	for k in 8:
		trunk.append(foot + Vector2i(int(roundf(sin(k * 0.28) * 2.0)), -k))
	for q in trunk:
		for o in [Vector2i(-1, 0), Vector2i(1, 0), Vector2i(0, 1)]:
			put.call(q + o, OUTLINE)
	for k in trunk.size():
		put.call(trunk[k], Color8(196, 140, 86) if k % 2 == 0 else Color8(160, 108, 66))
	# the fronds: two px thick (a lit upper side, a shaded lower one), outlined round the outside
	var fronds: Array = []
	for ang in [-2.95, -2.15, -1.25, -0.3, 0.6]:
		var pts: Array = []
		for j in range(1, 8):
			var fp := Vector2(trunk[trunk.size() - 1]) + Vector2.from_angle(ang) * j * 1.1 + Vector2(0, j * j * 0.08)
			var q := Vector2i(fp.round())
			pts.append([q, 0, j])
			if j < 6:
				pts.append([q + Vector2i(0, 1), 1, j])
		fronds.append(pts)
	for pts in fronds:
		for e in pts:
			for o in [Vector2i(-1, 0), Vector2i(1, 0), Vector2i(0, -1), Vector2i(0, 1)]:
				put.call((e[0] as Vector2i) + o, OUTLINE)
	for pts in fronds:
		for e in pts:
			var tip: bool = int(e[2]) >= 6
			put.call(e[0], Color8(84, 150, 70) if tip else (Color8(172, 226, 112) if int(e[1]) == 0 else Color8(108, 182, 82)))
	var crown := trunk[trunk.size() - 1]
	put.call(crown, Color8(110, 176, 80))
	put.call(crown + Vector2i(-1, 1), Color8(120, 78, 46))
	put.call(crown + Vector2i(1, 1), Color8(120, 78, 46))

## The board px round a point (mat px) within `reach` mat px, inside the mat
func _patch(c: Vector2, reach: float, w: int, h: int) -> Array[Vector2i]:
	var out: Array[Vector2i] = []
	var a := ((c - Vector2(reach, reach)) / PX).floor()
	var b := ((c + Vector2(reach, reach)) / PX).ceil()
	for y in range(maxi(0, int(a.y)), mini(h, int(b.y) + 1)):
		for x in range(maxi(0, int(a.x)), mini(w, int(b.x) + 1)):
			out.append(Vector2i(x, y))
	return out

## A clump of coral (the Reef): a few round lumps of one colour round `cc` (board px), lit top
## left, into _coral (its colour 1-3 x 4 + its shade: 1 light, 2 mid, 3 dark)
func _coral_clump(cc: Vector2, rng: RandomNumberGenerator, w: int, h: int, lo: int, hi: int) -> void:
	var kind := rng.randi_range(1, 3)
	for lump in rng.randi_range(lo, hi):
		var lc := cc + Vector2(rng.randf_range(-5, 5), rng.randf_range(-4, 4))
		var r := rng.randf_range(1.8, 3.6)
		for yy in range(int(lc.y - r - 1), int(lc.y + r + 2)):
			for xx in range(int(lc.x - r - 1), int(lc.x + r + 2)):
				if xx < 0 or yy < 0 or xx >= w or yy >= h:
					continue
				var o := Vector2(xx + 0.5, yy + 0.5) - lc
				if o.length() > r:
					continue
				var shade := 2
				if o.x + o.y < -r * 0.5:
					shade = 1
				elif o.x + o.y > r * 0.45 or o.length() > r - 0.8:
					shade = 3
				var ii2 := yy * w + xx
				if _coral[ii2] == 0 or (_coral[ii2] & 3) > shade:
					_coral[ii2] = kind * 4 + shade

## A painted px blended towards a colour
static func _tint(data: PackedByteArray, i: int, col: Color, k: float) -> void:
	var j := i * 4
	data[j] = int(lerpf(data[j], col.r8, k))
	data[j + 1] = int(lerpf(data[j + 1], col.g8, k))
	data[j + 2] = int(lerpf(data[j + 2], col.b8, k))

## The water at a board px (d: its distance to the course's line, board px): deeper in the channel,
## lighter in the shallows outside, sand and islands farther out; the Lagoon's warm sunset, the
## Reef's turquoise over coral
var _island := PackedByteArray()       # the boat's worlds: the islands, per board px (_paint_water: ISLE_*)
var _palms: Array[Vector2i] = []       # ...their palm trees' feet (board px)
var _keep := PackedByteArray()         # ...and RC ART's Lagoon: 1 where the old board's pixel stays (islands, palms, sandbars, frame: RcLagoon)
var _lagoon_decor: Sprite2D           # RC ART's Lagoon: starfish, shells, pebbles, seagrass (RcLagoon.decor)
var _finish_flags: FinishFlags         # RC ART's Lagoon: the start pontoon's waving flags
var _crabs: BeachCrabs                 # RC ART's Lagoon: crabs on the banks, scuttling off as the boat comes
var _clear := PackedFloat32Array()     # ...and per coarse cell, how far from the course's banks (world px: _sea_fields)
var _sea := PackedFloat32Array()       # ...and how far inside the water kept open (world px, <= 0: sand)
var _sea_w := 0
var _sea_h := 0
const ISLE_GRASS := 1
const ISLE_SAND := 2
const ISLE_WET := 3
const ISLE_SHALLOW := 4
const ISLE_GRASS_LIT := 5
const ISLE_GRASS_DARK := 6
const ISLE_GRASS_RIM := 7
const ISLE_CLIFF := 8
const ISLE_RIM := 9
const ISLE_SAND_LIT := 10
const ISLE_SAND_DARK := 11
const ISLE_SHADOW := 12
const ISLE_PRIO := [0, 3, 3, 3, 1, 3, 3, 3, 3, 3, 3, 3, 2]
var _buoy_spots: Array = []            # ...and where its buoys float: [mat px, red]
var _coral := PackedByteArray()        # ...and the reef's coral
const REEF := [Color8(30, 142, 178), Color8(62, 190, 200), Color8(132, 222, 214)]   # deep, the shallows, near the sand
const CORAL := [Color8(236, 128, 150), Color8(250, 176, 104), Color8(184, 132, 214)]
func _water_px(x: int, y: int, d: float, hw: float) -> Color:
	var reef := look == "reef"
	match _island[y * _bw + x]:
		ISLE_GRASS:
			return Color8(120, 180, 92) if reef else Color8(140, 186, 96)       # an island's grass top
		ISLE_GRASS_LIT:
			return Color8(158, 208, 106) if reef else Color8(178, 212, 114)
		ISLE_GRASS_DARK:
			return Color8(88, 144, 74) if reef else Color8(106, 152, 78)
		ISLE_GRASS_RIM:
			return Color8(52, 92, 56)
		ISLE_CLIFF:
			return Color8(170, 124, 80) if reef else Color8(176, 122, 82)       # (its earthy side)
		ISLE_SAND:
			return Color8(246, 222, 168)
		ISLE_SAND_LIT:
			return Color8(254, 240, 200)
		ISLE_SAND_DARK:
			return Color8(226, 196, 142)
		ISLE_WET:
			return Color8(214, 180, 126)
		ISLE_RIM:
			return Color8(118, 82, 58)                                          # (the beach's dark outline)
		ISLE_SHALLOW:
			return Color8(170, 230, 220) if reef else Color8(250, 196, 150)     # the shallows round it
		ISLE_SHADOW:
			_island[y * _bw + x] = 0
			var under := _water_px(x, y, d, hw)                                 # (the water, in the island's shadow)
			_island[y * _bw + x] = ISLE_SHADOW
			return under.darkened(0.16)
	var shallow := clampf((d - hw - 2.0) / 12.0, 0.0, 1.0)
	var in_channel := d <= hw + 2.0
	# past the buoys: the shallows (lighter, foam breaking at their far side), then the bank (the
	# Lagoon's sand, the Reef's coral: a crash), then the open shallows beyond
	var bank := hw + SHORE_PAINT / PX + _grass_noise.get_noise_2d(x * 3.0, y * 3.0) * 1.5
	var bank_w := (10.0 if look != "reef" else 7.0) + clampf(_cloud_noise.get_noise_2d(x * 2.0, y * 2.0), -0.6, 0.6) * 3.0   # (the noise can run past 1: never a thin bank)
	var in_shallows := not in_channel and d < bank
	var on_bank := d >= bank and d < bank + bank_w
	if on_bank and look != "reef":
		# (the user, 2026-10-18: as pretty as the Reef's) outlined dark on both sides like the
		# islands, a wet edge inside each outline, the sand lit in soft patches; its pebbles,
		# starfish and shells are stamped on after (_lagoon_bank_decor)
		var into := d - bank
		var out_of := bank + bank_w - d
		if into < 0.9 or out_of < 0.9:
			return Color8(118, 82, 58)                                    # (its outline)
		if into < 1.9 or out_of < 1.9:
			return Color8(214, 180, 126)                                  # (its wet edge)
		if _grass_noise.get_noise_2d(x * 4.0, y * 4.0) > 0.25:
			return Color8(254, 238, 196) if DITHER[y % 2][x % 2] < 0.75 else Color8(244, 220, 166)
		return Color8(244, 220, 166)
	if look == "reef":
		var water: Color = REEF[0] if in_channel else (REEF[1] as Color).lerp(REEF[2], shallow)
		if in_channel and d > hw - 4.0:
			water = (REEF[0] as Color).lerp(REEF[1], 0.35)               # the channel's slope, its edge
		if in_shallows:
			water = (REEF[1] as Color).lerp(REEF[2], 0.3 + 0.5 * (d - hw) / (bank - hw))
			if d > bank - 2.0 and (x + y) % 2 == 0:
				return Color8(244, 252, 250)                              # (the foam on the reef's edge)
		elif on_bank and _coral[y * _bw + x] == 0:
			water = Color8(196, 230, 210)                                 # (between the coral: the reef flat)
		var cr := _coral[y * _bw + x]
		if cr != 0:
			var base: Color = CORAL[cr / 4 - 1]
			var sh: Color = [base.lightened(0.18), base, base.darkened(0.22)][(cr & 3) - 1]
			return sh.lerp(water, 0.3)                                     # (seen through the water)
		# soft sand ripples on the bottom, broken up; glints on the surface
		if sin(x * 0.35 + sin(y * 0.15) * 2.5 + y * 0.12) > 0.93 and _grass_noise.get_noise_2d(x, y) > -0.1:
			water = water.lerp(Color8(220, 250, 246), 0.2)
		if (x + y * 3) % 5 < 2 and _cloud_noise.get_noise_2d(x * 3.0, y * 3.0) > 0.5:
			water = water.lerp(Color8(250, 255, 255), 0.6)
		return water
	var lagoon := _lagoon_water(x, y)
	if in_channel:
		return lagoon.lerp(Color8(150, 90, 130), 0.28)                    # the channel: deeper
	if in_shallows:
		if d > bank - 2.0 and (x + y) % 2 == 0:
			return Color8(255, 240, 226)                                  # (the foam at the sand)
		return lagoon.lerp(Color8(255, 214, 170), 0.18 + 0.32 * (d - hw) / (bank - hw))
	return lagoon.lerp(lagoon.lightened(0.12), shallow)

## The plane's worlds: the ground far below (the fields at noon; at sunset, a sea of clouds), its
## own smaller image (it scrolls slower: PARALLAX); the course itself is just the sky: faint guide
## arrows along it and a few clouds at the plane's height (the track layer)
func _paint_sky(w: int, h: int) -> Image:
	var view := VIEW.size / ZOOM
	var gw := int((PARALLAX * mat_size.x + (1.0 - PARALLAX) * view.x) / PX) + 4
	var gh := int((PARALLAX * mat_size.y + (1.0 - PARALLAX) * view.y) / PX) + 4
	_sky_ground = Vector2i(gw, gh)
	_bw = gw
	_bh = gh
	_sandbars.clear()
	var data := PackedByteArray()
	data.resize(gw * gh * 4)
	var k := 0
	for y in gh:
		for x in gw:
			var col := _sky_floor(x, y) if look == "sky" else _cloudsea_px(x, y)
			col = _lit(col, x, y)
			data[k] = col.r8
			data[k + 1] = col.g8
			data[k + 2] = col.b8
			data[k + 3] = 255
			k += 4
	_bw = w
	_bh = h
	var top := PackedByteArray()
	top.resize(w * h * 4)
	# the guide: a faint arrow every ~150 px along the course, pointing the way
	var arrow := Color(1, 1, 1, 0.3) if look == "sky" else Color(1.0, 0.94, 0.82, 0.3)
	for s2 in range(10, count, int(150.0 / STEP)):
		var c := centre[s2] / PX
		var dv := (centre[(s2 + 1) % count] - centre[s2]).normalized()
		var nv := Vector2(-dv.y, dv.x)
		for o in range(-4, 5):
			var q := (c + nv * o - dv * absf(o) * 0.8).round()
			for t in 2:
				var q2 := q - dv * t
				if q2.x < 0 or q2.y < 0 or q2.x >= w or q2.y >= h:
					continue
				var kk := (int(q2.y) * w + int(q2.x)) * 4
				top[kk] = arrow.r8
				top[kk + 1] = arrow.g8
				top[kk + 2] = arrow.b8
				top[kk + 3] = arrow.a8
	# a few clouds at the plane's height, off the course (it flies past them: they show its speed; RC ART's
	# Sky: the designer's drifting clouds instead, SkyClouds)
	var rng := RandomNumberGenerator.new()
	rng.seed = 313 * course_seed + 1
	for c2 in (0 if RcSky.on(look) and RcSky.has_clouds() else int(w * h / 30000) + 3):
		var p := Vector2i(rng.randi_range(EDGE, w - EDGE - 40), rng.randi_range(EDGE, h - EDGE - 30))
		if _dist[p.y * w + p.x] < half_w / PX * 1.6:
			continue
		var img := PalPrixArt.cloud(rng.randi_range(8, 14), c2, false).get_image()
		if look == "sunset":
			img.adjust_bcs(1.0, 1.0, 1.0)
		_blit(top, w, h, img, p)
	track_image = Image.create_from_data(w, h, false, Image.FORMAT_RGBA8, top)
	return Image.create_from_data(gw, gh, false, Image.FORMAT_RGBA8, data)

## The Grand Prix's sea of clouds far below at sunset: soft billows lit warm by the low sun, violet
## in the hollows, a gap here and there down to the dusk land
const CLOUDSEA := [Color8(126, 100, 156), Color8(186, 128, 168), Color8(232, 160, 160), Color8(250, 198, 164), Color8(255, 230, 196)]
func _cloudsea_px(x: int, y: int) -> Color:
	var n := _cloud_noise.get_noise_2d(x * 2.2, y * 2.2)
	var n2 := _grass_noise.get_noise_2d(x * 0.8, y * 0.8)
	if n < -0.5:
		# a gap: the dusk land far below, a town's lights here and there
		if ((x * 73856093) ^ (y * 19349663)) & 255 < 3 and n2 > -0.2:
			return Color8(255, 214, 140)
		return Color8(96, 82, 124).lerp(Color8(120, 100, 140), clampf(n2 + 0.5, 0.0, 1.0))
	if n < -0.44:
		return Color8(160, 118, 164) if DITHER[y % 2][x % 2] < 0.5 else Color8(186, 128, 168)   # (its misty edge)
	var v := clampf((n * 0.75 + n2 * 0.35 + 0.9) / 1.8, 0.0, 0.999)
	v = clampf(v + (1.0 - float(y) / maxf(_bh, 1)) * 0.18 - float(x) / maxf(_bw, 1) * 0.1, 0.0, 0.999)   # (the sun up and to the left)
	var f := v * CLOUDSEA.size()
	var band := int(f)
	if f - band > 0.7 and DITHER[y % 2][x % 2] < (f - band - 0.7) * 3.3:
		band += 1
	return CLOUDSEA[clampi(band, 0, CLOUDSEA.size() - 1)]

## The floors, in the worlds' style (the user's Retry references, docs/mockups/palprix_worlds/v2):
## no outlines, few colours in steps with a 2x2 dither between them. The Garden (a morning): soft
## grass, flower clusters, chunky bushes, soft cloud shadows
const DITHER := [[0.125, 0.625], [0.875, 0.375]]
const GRASS := [Color8(116, 172, 82), Color8(130, 186, 90), Color8(146, 200, 98), Color8(162, 212, 110)]
const BUSH := [Color8(60, 116, 56), Color8(80, 140, 62), Color8(104, 164, 72), Color8(132, 188, 86)]
const FLOWERS := [Color8(250, 246, 232), Color8(248, 196, 206), Color8(252, 226, 140)]
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
	if look == "night":
		return _rain_floor(x, y) if rain else _night_floor(x, y)
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

## The Lagoon at sunset: warm water, gentle waves catching the light (its islands: _water_px)
func _lagoon_water(x: int, y: int) -> Color:
	var t := clampf(float(y) / maxf(_bh, 1), 0.0, 1.0)
	var water := Color8(236, 150, 116).lerp(Color8(176, 104, 140), t)
	# short wave crests catching the low sun (little arcs here and there)
	var wave := sin(x * 0.24 + sin(y * 0.14 + x * 0.05) * 2.0) * sin(y * 0.42 + x * 0.05)
	if wave > 0.86:
		water = water.lerp(Color8(255, 214, 160), 0.55)
	elif wave < -0.9 and DITHER[y % 2][x % 2] < 0.5:
		water = water.darkened(0.07)
	# the sun's road of light across the water
	var glit := absf((x - _bw * 0.25) - (y - _bh * 0.1) * 0.35)
	if glit < 26.0 and ((x * 7 + y * 3) % 9 == 0):
		water = water.lerp(Color8(255, 240, 190), 0.55)
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
var _sky_ground := Vector2i.ZERO       # the plane's ground image, board px (_paint_sky)
var _mill_sails: Array = []            # RC ART's Sky: the windmills' sails turning on the ground (RcSky.mills)
var _clouds_low: SkyClouds             # ...the designer's clouds drifting between the plane and the ground, the big ones lower,
var _clouds_high: SkyClouds            # the small ones higher (nearer: faster past, a little less see-through)
var _cloud_shadows: SkyClouds          # ...and their shadows on the fields (on the board)
const CLOUD_DEPTH := [0.72, 0.86]      # their parallax (the ground's is PARALLAX)
const CLOUD_SIZE := [1.0, 1.1]        # (the nearer row 10% bigger, the user)
const CLOUD_ALPHA := [0.65, 0.65]      # (the user: nearly transparent, then "less transparent", then 75%, then 10% less)
const CLOUD_SHADOW := Color(0.45, 0.52, 0.62, 0.1)   # (paler: merging with the hazy ground, the user)
const CLOUD_WIND := Vector2(14, 5)     # world px/s
var _lamps: Array = []                 # Grand Prix: the lamp posts (board px) round the track
var _lamp_light := PackedFloat32Array() # ...and their light on every board px (0 dark .. 1 right under one)

## The world's light over everything, the track too
func _lit(c: Color, x: int, y: int) -> Color:
	if look == "garden":
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
	match look:
		"sky", "reef":
			# noon: bright, a touch of blue (in the sky the clouds are below: _sky_floor)
			return Color(minf(1.0, c.r * 1.03 + 0.01), minf(1.0, c.g * 1.03 + 0.01), minf(1.0, c.b * 1.04 + 0.02))
		"lagoon", "sunset":
			# sunset: everything warm, the light low from the left
			return c.lerp(Color8(255, 170, 110), 0.12)
		"night":
			# night: dark, but for the lamps' warm pools along the track (_lamp_light, stamped once);
			# the rain makes it greyer, bluer
			var best: float = _lamp_light[y * _bw + x] if _lamp_light.size() == _bw * _bh else 0.0
			var k := clampf(best * 1.25, 0.0, 1.0)
			var steps := k * 3.0
			k = (floorf(steps) + (1.0 if steps - floorf(steps) > DITHER[y % 2][x % 2] else 0.0)) / 3.0
			if rain:
				c = c.lerp(Color8(84, 100, 120), 0.18)
			return c.darkened(0.62 * (1.0 - k)).lerp(Color8(255, 220, 140), 0.12 * k)
	return c

## The Garden's trees, just outside the mat: their branches hang over its edges (drawn in front of
## the car), and under them the shade, with flecks of sun through the leaves
func _plant_trees(w: int, h: int) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 53 * course_seed + 9
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
	rng.seed = 17 * course_seed + 2
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
	if look != "garden":
		return
	_plant_trees(w, h)
	var rng := RandomNumberGenerator.new()
	rng.seed = 91 * course_seed + 3
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
## A life (the user, 2026-10-18: three little cars, boats or planes instead of hearts): the
## world's toy, 13 x 11 px, outlined like the hearts; red when it's there, blue for the splashy
## pal's extra one, a faded grey one lost
const LIFE_TOYS := {
	"car": [
		"....#####....",
		"...#gg#gg#...",
		"..#lllllll#..",
		".#lllllllll#.",
		"#lmmmmmmmmmd#",
		"#mmmmmmmmmmd#",
		"#dd###d###dd#",
		".##www#www##.",
		"..#www#www#..",
		"...###.###...",
		".............",
	],
	"boat": [
		"....#........",
		"...#l#.......",
		"...#####.....",
		"...#ggg#.....",
		"#############",
		"#lllllllllll#",
		".#mmmmmmmmd#.",
		"..#ddddddd#..",
		"...#######...",
		".w..ww..ww..w",
		"w.ww..ww..ww.",
	],
	"plane": [
		"......#......",
		".....#l#.....",
		"....#lmd#....",
		"#############",
		"#llllllmmmmd#",
		"#mmmmmmmmmdd#",
		"#############",
		".....#m#.....",
		"...##lmd##...",
		"...#lmmmmd#..",
		"...#######...",
	],
}
func life_icon(kind: String) -> Texture2D:
	var key := "%s_%s" % [vehicle, kind]
	if _life_icons.has(key):
		return _life_icons[key]
	var tone: Array = {
		"full": [Color8(255, 150, 130), Color8(226, 70, 64), Color8(170, 44, 48)],
		"water": [Color8(214, 240, 255), Color8(110, 178, 236), Color8(56, 116, 196)],
		"empty": [UiArt.EMPTY.lightened(0.12), UiArt.EMPTY, UiArt.EMPTY_DARK],
	}[kind]
	var cols := { "#": UiArt.OUTLINE, "l": tone[0], "m": tone[1], "d": tone[2],
		"g": Color8(180, 226, 250) if kind != "empty" else UiArt.EMPTY.lightened(0.2),
		"w": Color8(60, 56, 70) if vehicle == "car" else (Color8(150, 210, 240) if kind != "empty" else UiArt.EMPTY) }
	var tex := _rows_texture(LIFE_TOYS[vehicle], cols)
	_life_icons[key] = tex
	return tex
var _life_icons := {}

## The boat's or the plane's top view as one picture (its slices stacked), for the how-to card
func _toy_icon(kind: String, _k: int) -> Texture2D:
	var layers: Array[Texture2D] = PalPrixArt.boat_slices() if kind == "boat" else PalPrixArt.plane_slices(Color8(226, 70, 64), Color8(250, 210, 84), true)
	var first := layers[0].get_image()
	var img := Image.create(first.get_width(), first.get_height() + layers.size(), false, Image.FORMAT_RGBA8)
	for li in layers.size():
		var src := layers[li].get_image()
		img.blend_rect(src, Rect2i(Vector2i.ZERO, src.get_size()), Vector2i(0, layers.size() - li))
	# (the card's picture is laid out for the car's: wide and flat; these are about as tall as they
	# are wide, so they get room round them, smaller, clear of the words as they swing: the user)
	var used := img.get_used_rect()
	var cw := int(ceilf(maxf(used.size.x, used.size.y * 1.2)))
	var ch := int(ceilf(cw / 1.375))
	var out := Image.create(cw, ch, false, Image.FORMAT_RGBA8)
	out.blend_rect(img, used, Vector2i((cw - used.size.x) / 2, (ch - used.size.y) / 2))
	return ImageTexture.create_from_image(out)

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
	water_fx = WaterFx.new()
	world.add_child(water_fx)                       # (on the water, under everything)
	sky_shadow = Sprite2D.new()
	sky_shadow.scale = Vector2(PX, PX)
	sky_shadow.modulate = Color(0.1, 0.08, 0.2, 0.28)
	sky_shadow.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	world.add_child(sky_shadow)                      # (the plane's shadow, on the ground far below)
	# drawn in this order: the floor, a car falling behind the track, the raised track, the car
	behind = Node2D.new()
	world.add_child(behind)
	track = Sprite2D.new()
	track.centered = false
	track.scale = Vector2(PX, PX)
	track.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	world.add_child(track)
	# the stand beside the track, drawn over it: its front row is nearer you than the track's side
	# (the user, 2026-10-18: a stand south of the road had its pals hop up under the track)
	crowd = Crowd.new()
	world.add_child(crowd)
	for i in MORE_STANDS:
		var st := Crowd.new()
		st.visible = false
		world.add_child(st)
		more_stands.append(st)
	buoys = FloatingBuoys.new()
	world.add_child(buoys)                          # (on the water, under the boat)
	sky_dock = SkyDock.new()
	world.add_child(sky_dock)                       # (the planes' start deck, under them)
	trail = Trail.new()
	world.add_child(trail)
	guide = FlightGuide.new()
	world.add_child(guide)                          # (the plane's way, under it)
	ring_back = Node2D.new()
	world.add_child(ring_back)                      # (a ring's lower half: under the plane)
	front = Node2D.new()
	world.add_child(front)
	ring_front = Node2D.new()
	world.add_child(ring_front)                     # (its upper half: over it, the plane goes through)
	gust_fx = GustFx.new()
	world.add_child(gust_fx)
	air_fx = AirFx.new()
	air_fx.rc = self
	world.add_child(air_fx)                         # (over the plane: the air between it and you)
	canopy = Sprite2D.new()
	canopy.centered = false
	canopy.scale = Vector2(PX, PX)
	canopy.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	world.add_child(canopy)                         # (over the car: the branches hang above it)
	world.scale = Vector2(ZOOM, ZOOM)
	shadow = Sprite2D.new()
	shadow.scale = Vector2(PX, PX)
	shadow.modulate = Color(0.05, 0.04, 0.1, 0.35)
	shadow.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	front.add_child(shadow)
	car = Node2D.new()
	front.add_child(car)                            # (its slices: _set_vehicle, per world)
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
	prop = Sprite2D.new()
	prop.scale = Vector2(PX, PX)
	prop.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	front.add_child(prop)

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
	# the lives, after the stars
	build_lives(Vector2(HUD_BAND.position.x + 566, HUD_BAND.position.y + 15), 30.0, 33.0)
	# the race's position (with rivals) and the pal's boost, on the band's right
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
	pointer = RingPointer.new()
	pointer.view = VIEW
	add_child(pointer)
	move_child(pointer, world.get_index() + 1)

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
	_gantry_box = [gantry, inner]
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
	lettering = RcLettering.new()
	lettering.position = Vector2(PLAY_WIDTH / 2.0, PLAY_HEIGHT / 2.0)
	lettering.max_width = PLAY_WIDTH - 60.0       # (with its pop-in overshoot, still on the screen)
	add_child(lettering)
	banner.modulate.a = 0.0

	motor = AudioStreamPlayer.new()
	add_child(motor)                                  # (its sound per toy: _set_vehicle)

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
		if _art_lights:
			lamps[i].texture = RcTiles.tex("start_lamp_green" if green else ("start_lamp_red" if i < lit else "start_lamp_off"))
			lamps[i].modulate = Color.WHITE
		else:
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
	var n := slices.size()
	# (the plane rolls into the turns: its wings foreshortened, the stack leaning into the turn,
	# the lower wing in shade and the raised one in the light: you see which way it banks)
	var tilt := Vector2.from_angle(heading + PI / 2.0) * bank * 14.0 if vehicle == "plane" else Vector2.ZERO
	if vehicle == "plane" and n > 1:
		var dip := 0 if absf(bank) < 0.3 else int(signf(bank))
		slices[1].texture = PalPrixArt.plane_wings(Color8(226, 70, 64), Color8(250, 210, 84), dip) if dip != 0 else _plane_layers[1]
	for i in n:
		slices[i].rotation = heading
		slices[i].position = (Vector2(0, -i * LAYER_UP) + tilt * float(i) / maxf(1.0, n - 1)).round()   # (lifted on screen, not turned)
		slices[i].scale = Vector2(PX, PX * (1.0 - 0.42 * absf(bank))) if vehicle == "plane" else Vector2(_slice_px, _slice_px)
	shadow.position = car_pos.round() + Vector2(5, 8 + car_drop * 0.3)
	shadow.rotation = heading
	shadow.visible = not _wrecked and vehicle != "plane"
	var seat := -5.0
	match vehicle:
		"boat":
			seat = PalPrixArt.BOAT_SEAT * PX
		"plane":
			seat = PalPrixArt.PLANE_SEAT * PX
	# (the pal goes with its toy: smaller and fading as it falls or sinks)
	driver.position = car.position + (Vector2.from_angle(heading) * seat + Vector2(0, -n * LAYER_UP - 4.0) + tilt) * car.scale.x
	driver.scale = Vector2(2, 2) * car.scale.x
	driver.modulate = car.modulate
	prop.visible = vehicle == "plane" and state != State.FALL
	if prop.visible:
		_prop_frame = (_prop_frame + 1) % 12                # (a new one every frame: a fast spin)
		prop.texture = PalPrixArt.propeller(_prop_frame)
		prop.rotation = heading
		prop.scale = Vector2(PX, PX * (1.0 - 0.42 * absf(bank)))
		prop.position = (car.position + Vector2.from_angle(heading) * 46.0 + Vector2(0, -2.0 * LAYER_UP) + tilt * 0.66).round()
	# the antenna stands up from the toy's back left corner, leaning back and out in the turns; the
	# plane's is a wire from its back, behind the wings, to the top of its tail fin, the ball on the fin's tip
	if vehicle == "plane":
		var up := Vector2(0, -(n - 1) * LAYER_UP)
		var from_pt := car.position + Vector2.from_angle(heading) * -26.0 + up + tilt
		var fin_top := car.position + Vector2.from_angle(heading) * -46.0 + up + tilt * 1.4 + Vector2(0, -20)
		antenna.points = PackedVector2Array([from_pt.round(), fin_top.round()])
		antenna_tip.position = fin_top.round()
	else:
		var corner := Vector2(-30, -22) if vehicle == "car" else Vector2(-46, -18)
		var base := car.position + corner.rotated(heading) + Vector2(0, -n * LAYER_UP)
		var lean := Vector2.from_angle(heading) * -10.0 + Vector2.from_angle(heading + PI / 2.0) * sway * 26.0
		var top := base + Vector2(0, -46) + lean
		antenna.points = PackedVector2Array([base.round(), (base.lerp(top, 0.5) + lean * 0.15).round(), top.round()])
		antenna_tip.position = top.round()
	antenna.visible = state != State.FALL
	antenna_tip.visible = antenna.visible
	if headlight:
		headlight.rotation = heading
		headlight.position = car.position + Vector2.from_angle(heading) * 92.0
		headlight.visible = look == "night" and state != State.FALL
	# the plane's shadow far below: where the point under it is on the ground (the ground nearer the
	# middle of the view the farther down it is), a little off it (the sun), smaller
	sky_shadow.visible = vehicle == "plane" and not _wrecked
	if sky_shadow.visible:
		var mid := VIEW.get_center()
		var on_screen := world.position + car.position * ZOOM
		var under := mid + (on_screen - mid) * PARALLAX + Vector2(34, 58)
		sky_shadow.position = ((under - world.position) / ZOOM).round()
		sky_shadow.rotation = heading
		sky_shadow.texture = slices[1].texture
		var sk := 2.0 if RcSky.on(look) else 3.0      # (RC ART: half the plane, it's far below; the user)
		sky_shadow.scale = Vector2(sk, sk * (1.0 - 0.42 * absf(bank)))
	# (in the air: the car up, its shadow left behind on the road)
	if car_drop < 0.0:
		shadow.position = car_pos.round() + Vector2(5, 8)
		shadow.modulate.a = 0.35 * (1.0 + car_drop / 120.0)

## RC NEW ART: the floor, the track and the branches from the designer's pieces (finer: their pixels
## RcTiles.ART_PX world px), the track's shadow a dark copy of it on the floor; otherwise the code's
func _tile_art() -> void:
	var grade := RcTiles.grade_material(DevLaunch.rc_grade) if not _tiles.is_empty() else null   # (the scenery, not the car)
	for sp in [board, track, canopy]:
		sp.material = grade
	for st in [crowd] + more_stands:
		st.material = RcTiles.grade_material(1) if not _tiles.is_empty() else null          # (the stands: SOFT)
		st.queue_redraw()
	if butterflies == null:
		butterflies = RcButterflies.new()
		world.add_child(butterflies)                 # (over everything on the mat, the branches too)
	butterflies.start(null)                         # (started over the lawn once it's painted, below)
	var k := RcTiles.ART_PX if not _tiles.is_empty() else float(PX)
	for sp in [board, track, canopy]:
		sp.scale = Vector2(k, k)
	if _tile_shadow == null:
		_tile_shadow = Sprite2D.new()
		_tile_shadow.centered = false
		_tile_shadow.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		_tile_shadow.modulate = RcTiles.SHADE_COL
		board.add_child(_tile_shadow)                 # (on the floor: it moves with it in the 3D tilt)
	_tile_shadow.visible = not _tiles.is_empty()
	if _tree_shade == null:
		_tree_shade = Sprite2D.new()
		_tree_shade.centered = false
		_tree_shade.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		_tree_shade.modulate = RcTiles.TREE_SHADE_COL
		world.add_child(_tree_shade)
		world.move_child(_tree_shade, track.get_index() + 1)     # (over the track, under the car)
	_tree_shade.visible = not _tiles.is_empty()
	# the start lights: the designer's gantry and lamps (NOTES_ROUND_10) once drawn, on the screen at
	# the playfield's scale (an art px = ART_PX x ZOOM screen px), else the drawn gantry
	_art_lights = (not _tiles.is_empty() or RcLagoon.on(look) or RcSky.on(look)) and ResourceLoader.exists(RcTiles.DIR + "start_gantry.png")   # (the Lagoon: the Garden's gantry too, the user)
	var lpx := RcTiles.ART_PX * ZOOM
	for r in _gantry_box:
		r.visible = not _art_lights
	if _art_lights and _gantry_art == null:
		_gantry_art = Sprite2D.new()
		_gantry_art.texture = RcTiles.tex("start_gantry")
		_gantry_art.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		_gantry_art.scale = Vector2(lpx, lpx)
		lights.add_child(_gantry_art)
		lights.move_child(_gantry_art, 0)
	if _gantry_art:
		_gantry_art.visible = _art_lights
	for i in lamps.size():
		var lamp := lamps[i]
		if _art_lights:
			lamp.texture = RcTiles.tex("start_lamp_off")
			lamp.scale = Vector2(lpx, lpx)
			lamp.position = Vector2((RcTiles.LAMP_X[i] - 45) * lpx, 0)
		else:
			lamp.texture = RcTiles.tex("start_lamp") if not _tiles.is_empty() else _lamp_texture()
			lamp.scale = Vector2(k, k)
			lamp.position = Vector2((i - 1) * 80, 0)
	if atmosphere == null:
		atmosphere = RcAtmosphere.new()
		add_child(atmosphere)
	atmosphere.stop()
	if RcLagoon.on(look):                            # (RC ART's Lagoon: the board drawn again from the designer's squares)
		board.material = RcLagoon.material(self)
		if _lagoon_decor == null:
			_lagoon_decor = Sprite2D.new()
			_lagoon_decor.centered = false
			_lagoon_decor.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
			board.add_child(_lagoon_decor)             # (on the board: it moves with it in the 3D tilt)
		_lagoon_decor.texture = ImageTexture.create_from_image(RcLagoon.decor(self))
		_lagoon_decor.scale = Vector2.ONE * RcLagoon.ART_PX / PX
	if _lagoon_decor:
		_lagoon_decor.visible = RcLagoon.on(look)
	for sail in _mill_sails:
		if is_instance_valid(sail):
			sail.queue_free()
	_mill_sails.clear()
	for layer in [_clouds_low, _clouds_high, _cloud_shadows]:
		if layer:
			layer.visible = false
	if RcSky.on(look) and RcSky.has_ground() and _sky_ground != Vector2i.ZERO:
		# (RC ART's Sky: the ground far below from the designer's fields, twice as fine; its haze and clouds in a shader)
		board.texture = ImageTexture.create_from_image(RcSky.ground(_sky_ground))
		board.scale = Vector2.ONE * RcSky.ART_PX
		board.material = RcSky.ground_material(_cloud_noise, _sky_ground)
		if RcSky.has_clouds():
			_sky_clouds_start()
		for hub in RcSky.mills:
			var sail := MillSails.new()
			sail.texture = RcSky.sails()
			sail.position = hub
			sail.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
			board.add_child(sail)                    # (on the ground: it moves with it; freed with the next ground)
			_mill_sails.append(sail)
	if _finish_flags == null:
		_finish_flags = FinishFlags.new()
		_finish_flags.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		world.add_child(_finish_flags)
		world.move_child(_finish_flags, track.get_index() + 1)   # (over the water, under the boat)
	_finish_flags.visible = RcLagoon.on(look) and ResourceLoader.exists(RcTiles.DIR + "stand_flag_0.png")
	_finish_flags.spots.clear()
	if _finish_flags.visible:
		var d0 := (centre[2] - centre[0]).normalized()
		var n0 := Vector2(-d0.y, d0.x)
		for sd in [-1.0, 1.0]:
			_finish_flags.spots.append((centre[0] + n0 * sd * (half_w + 16.0)).round())
	if _crabs == null:
		_crabs = BeachCrabs.new()
		_crabs.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		world.add_child(_crabs)
		world.move_child(_crabs, track.get_index() + 1)   # (on the sand, under the boat)
	var crab_spots: Array = []
	if RcLagoon.on(look):
		var on_sand := half_w + SHORE_PAINT + RcLagoon.BANK_W * 0.5
		for s0 in range(0, count, 6):
			for sd in [-1.0, 1.0]:
				var nn: Vector2 = _normal(s0) * sd
				var p: Vector2 = centre[s0] + nn * on_sand
				var b := Vector2i(p / PX)
				if b.x < EDGE or b.y < EDGE or b.x >= _bw - EDGE or b.y >= _bh - EDGE:
					continue
				if absf(_dist[b.y * _bw + b.x] * PX - on_sand) > 12.0 or _keep[b.y * _bw + b.x] != 0:
					continue                         # (another stretch of the course nearer, or an island, a sandbar)
				if _stands().any(func(st): return st.rect.grow(20.0).has_point(p)):
					continue
				crab_spots.append([p, -nn])
	_crabs.setup(self, crab_spots, 5 if RcLagoon.on(look) else 0)   # (the user: half of 10)
	if RcLagoon.on(look) and DevLaunch.rc_fx:
		atmosphere.start(world, board, mat_size, RcLagoon.ART_PX, level, "lagoon")
	if _tiles.is_empty():
		return
	var art := RcTiles.paint(self)
	board.texture = ImageTexture.create_from_image(art[0])
	track.texture = ImageTexture.create_from_image(art[1])
	butterflies.start(self, art[1])
	canopy.texture = ImageTexture.create_from_image(art[2])
	canopy.visible = true
	_tile_shadow.texture = track.texture
	_tile_shadow.position = RcTiles.SHADE
	_tree_shade.texture = canopy.texture
	if DevLaunch.rc_fx:
		atmosphere.start(world, board, mat_size, RcTiles.ART_PX, level)
	_tree_shade.scale = Vector2(k, k)
	_tree_shade.position = RcTiles.TREE_SHADE * k

## The world's toy: its slices (made again on the car's node, the lower ones darker: its sides in
## shade, its top in the light), its shadow, the motor's voice (a boat's lower, a plane's buzzier)
func _set_vehicle() -> void:
	var layers: Array[Texture2D] = RcTiles.car_slices(car_slices()) if RcTiles.on(look) else car_slices()
	_slice_px = RcTiles.ART_PX if RcTiles.on(look) else float(PX)
	shadow.scale = Vector2(_slice_px, _slice_px)
	match vehicle:
		"boat":
			layers = PalPrixArt.boat_slices()
		"plane":
			layers = PalPrixArt.plane_slices(Color8(226, 70, 64), Color8(250, 210, 84), false)
	for sl in slices:
		sl.queue_free()
	slices.clear()
	for i in layers.size():
		var sl := Sprite2D.new()
		sl.texture = layers[i]
		sl.scale = Vector2(_slice_px, _slice_px)
		sl.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		var k := (0.85 if vehicle == "plane" else 0.62) + (0.15 if vehicle == "plane" else 0.38) * float(i) / (layers.size() - 1)
		sl.modulate = Color(k, k, k)
		car.add_child(sl)
		slices.append(sl)
	shadow.texture = layers[2 if vehicle == "car" else 1]
	_plane_layers = layers
	# each toy its own engine (the user, 2026-10-18: they should sound a little different, not too
	# loud): the car's electric buzz, the boat's putt-putt outboard, the plane's propeller drone;
	# each a seamless 1 s loop humming the whole race, under the music
	var was_playing := motor.playing
	var hum: AudioStreamWAV = load(MOTORS[vehicle][0]).duplicate()
	hum.loop_mode = AudioStreamWAV.LOOP_FORWARD
	hum.loop_end = hum.get_length() * hum.mix_rate
	motor.stream = hum
	motor.volume_db = MOTORS[vehicle][1]
	if was_playing:
		motor.play()
	_motor_pitch = 1.0
	motor.pitch_scale = _motor_pitch

var _motor_pitch := 1.0
const MOTORS := {
	"car": ["res://sounds/fx/rc_motor.wav", -24.0],
	"boat": ["res://sounds/fx/boat_motor.wav", -21.0],
	"plane": ["res://sounds/fx/plane_motor.wav", -25.0],
}
var _plane_layers: Array[Texture2D] = []   # (the toy's own slices: the plane's level wings)

## The toy's speed and how fast it turns (a full turn: the car in 1 s, the boat and the plane wider)
func _speed() -> float:
	return { "car": SPEED, "boat": BOAT_SPEED, "plane": PLANE_SPEED }[vehicle]

func _turn_rate() -> float:
	return { "car": TURN, "boat": BOAT_TURN, "plane": PLANE_TURN }[vehicle]

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
	if vehicle == "plane":
		board.position = ((world.position - VIEW.position) * (PARALLAX - 1.0)).round() / ZOOM
		if _clouds_low and _clouds_low.visible:
			_clouds_low.position = ((world.position - VIEW.position) * (CLOUD_DEPTH[0] - 1.0)).round() / ZOOM
			_clouds_high.position = ((world.position - VIEW.position) * (CLOUD_DEPTH[1] - 1.0)).round() / ZOOM
	_depth_3d()

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

func _process(frame_delta: float) -> void:
	if not is_running:
		if motor.playing:
			motor.stop()
		return
	# (one long frame, the app coming back from the background, never jumps the race on)
	var delta := minf(frame_delta, 0.05)
	_update_course_things(delta)
	for st in _stands():
		st.watch = car_pos
	# (the buoys float the whole time, the countdown too; the bonk only while racing)
	if vehicle == "boat":
		if buoys.update(delta, car_pos, vel, rivals) > 0 and state == State.DRIVE and _buoy_cd <= 0.0:
			_buoy_cd = 0.12                                # (a soft bonk: you're at the channel's edge)
			_sfx("res://sounds/fx/water_boing.wav", -14.0, randf_range(1.5, 1.8))
			Input.vibrate_handheld(10)
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
				for st in _stands():
					st.cheer_all()
					st.cheer_cd = CHEER_CD + 1.0         # (no wave from the car still sitting by them)
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
	# a focused toy on the brink: time slows a moment (the clock too: no time lost for it)
	var delta := delta_real * (0.35 if slow_t > 0.0 else 1.0)
	slow_t = maxf(0.0, slow_t - delta_real)
	race_time += delta
	var turn := (1.0 if _held(1) else 0.0) - (1.0 if _held(0) else 0.0)
	if qa_autopilot:
		turn = 0.0 if qa_hands_off else _autopilot()
	var grip := 0.88 if rain else 1.0                                # (the rain: a wet road)
	if air_t > 0.0:
		grip *= 0.3                                                  # (in the air: hardly any steering)
	if slip_t <= 0.0:
		heading += turn * _turn_rate() * grip * delta
	bank = move_toward(bank, turn if vehicle == "plane" else 0.0, delta * 4.0)
	# the car on the curb: slowed down, rumbling; on a pad (the boat: a current): a boost that fades
	var from_mid := car_pos.distance_to(centre[near])
	var v := _speed() * (1.0 + BOOST * boost_t) * (1.0 - BUMP_SLOW * bump_t)
	bump_t = maxf(0.0, bump_t - delta / BUMP_TIME)
	if vehicle == "car" and from_mid > half_w - CURB_TOUCH and air_t <= 0.0:
		v *= CURB_SLOW
		curb_t -= delta
		if curb_t <= 0.0:
			curb_t = 0.09
			Input.vibrate_handheld(6)
	# the boat past the buoys: in the shallows, slowed, its hull scraping the sand (a spray, a rumble)
	if vehicle == "boat" and from_mid > half_w - SHALLOW_IN and air_t <= 0.0:
		v *= SHALLOW_SLOW
		curb_t -= delta
		if curb_t <= 0.0:
			curb_t = 0.11
			Input.vibrate_handheld(6)
			trail.spray(car_pos + (car_pos - centre[near]).normalized() * 18.0, heading, 2)
	var on := false
	for pd in pads:
		var loc: Vector2 = car_pos - pd[0]
		if absf(loc.dot(pd[1])) < PAD_LEN / 2.0 + 6.0 and absf(loc.dot(Vector2(-pd[1].y, pd[1].x))) < half_w:
			on = true
	if on and not _on_pad and air_t <= 0.0:
		boost_t = 1.0
		_sfx("res://sounds/fx/rc_boost.wav", -8.0, 0.8 if vehicle == "boat" else 1.0)
		Input.vibrate_handheld(30)
	_on_pad = on
	boost_t = maxf(0.0, boost_t - delta / BOOST_TIME)
	# oil / a puddle / a whirlpool: the toy spins round once and stops a moment, then goes on
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
	# the move: the car and the plane go where they point; the boat drifts (it takes up the way it
	# points over a moment)
	var dir := Vector2.from_angle(move_heading)
	if vehicle == "boat":
		vel = dir * v if slip_t > 0.0 else vel.lerp(dir * v, 1.0 - exp(-BOAT_GRIP * delta))
		car_pos += vel * delta
	else:
		car_pos += dir * v * delta
	# (a bounce off a barrier: the push back in fading, the heading easing round)
	if knock_v != Vector2.ZERO:
		car_pos += knock_v * delta
		knock_v *= exp(-9.0 * delta)
		if knock_v.length() < 4.0:
			knock_v = Vector2.ZERO
	if bounce_t > 0.0:
		bounce_t -= delta
		heading = lerp_angle(heading, bounce_to, minf(1.0, delta * 12.0))
	if vehicle == "plane":
		_blow(delta)
	if air_t > 0.0:
		air_t -= delta
		if air_t <= 0.0:
			_land()
	else:
		match vehicle:
			"car":
				trail.add(car_pos, heading, delta)
				if rain and randf() < delta * 14.0:
					trail.spray(car_pos, heading, 1)                   # (the wet road: a fine spray)
			"boat":
				trail.wake(car_pos, heading, delta, v / BOAT_SPEED)
			"plane":
				trail.contrail(car_pos + Vector2(0, -slices.size() * LAYER_UP), heading, delta)
	_cheer_cd = maxf(0.0, _cheer_cd - delta)
	_buoy_cd = maxf(0.0, _buoy_cd - delta)
	_grace_t = maxf(0.0, _grace_t - delta)
	for st in _stands():                                 # every stand by the car (two can face the same stretch), each its own wait
		var across := 2.0 * half_w + _stand_gap(st.away) + CHEER_ACROSS   # (only on the road's side: never behind it)
		var zone: Rect2 = st.rect.grow_individual(
			CHEER_AHEAD if st.along_x else (across if st.away.x > 0.0 else 0.0),
			CHEER_AHEAD if not st.along_x else (across if st.away.y > 0.0 else 0.0),
			CHEER_AHEAD if st.along_x else (across if st.away.x < 0.0 else 0.0),
			CHEER_AHEAD if not st.along_x else (across if st.away.y < 0.0 else 0.0))
		st.cheer_cd = maxf(0.0, st.cheer_cd - delta)
		if st.cheer_cd <= 0.0 and zone.has_point(car_pos):
			st.cheer_cd = CHEER_CD
			_cheer_cd = CHEER_CD
			st.cheer(car_pos, 2)                         # (the wave runs from where the car is)
	if boost_t > 0.3 and vehicle == "car":
		trail.add(car_pos, heading, delta)                  # (more streaks while boosted)
	var was_near := near
	_find_near()
	_update_bridge_order()
	if progress >= last_cp + count / CHECKPOINTS:
		last_cp = floorf(progress / (count / CHECKPOINTS)) * (count / CHECKPOINTS)
	# a jump: off the end of a ramp, straight and on the road, the toy flies over the gap (a boat:
	# over the sandbar)
	if air_t <= 0.0 and _on_ramp(was_near) and not _on_ramp(near):
		var road_dir := (centre[(near + 1) % count] - centre[near]).angle()
		if absf(wrapf(heading - road_dir, -PI, PI)) < 0.5 and car_pos.distance_to(centre[near]) < half_w * 0.85:
			_jump(AIR_TIME)
	_update_secret(was_near)
	_update_rivals(delta)
	# the course's edges: the car's guard rails, the boat's buoys, the plane's corridor
	match vehicle:
		"car":
			_rail_hold()
		"plane":
			_corridor(delta)
	var crash := _crash_now()
	if crash == "" and not focus_used and PetState.boost_power("focus") > 0 and _brink():
		focus_used = true
		slow_t = 0.9                                    # (on the brink: a moment to steer back)
		PetState.use_boost()
		_show_banner("focus!", 0.4)
	if crash != "":
		_crash(crash)
		if state != State.DRIVE:
			return
	if motor.playing:
		# (it strains a little in the turns)
		motor.pitch_scale = lerpf(motor.pitch_scale, _motor_pitch * (1.0 - absf(turn) * 0.07), minf(1.0, delta * 5.0))
	if progress >= count * lap and lap <= LAPS:
		lap += 1
		if lap > LAPS:
			_finish()
			return
		_show_banner("LAP %d" % lap if lap < LAPS else "FINAL LAP!", 0.7)
		_sfx("res://sounds/fx/gamecoin.wav", -10.0)
		_new_lap()
	_refresh_hud()

const RING_PAST := 16.0                # course points past a ring's middle: the plane is out of it
const RING_TOL := 0.86                # through a ring: within this much of its size from its middle
const GUST_PUSH := 230.0              # px/s across the course (a sturdy plane: half)
const TOY_R := { "car": 26.0, "boat": 24.0, "plane": 24.0 }

## Does the toy touch this obstacle? (a log: anywhere along it)
func _hits(ob: Dictionary) -> bool:
	if _grace_t > 0.0:
		return false
	var reach: float = ob["r"] + TOY_R[vehicle]
	if ob["kind"] == "log":
		return Geometry2D.get_closest_point_to_segment(car_pos, ob["a"], ob["b"]).distance_to(car_pos) < reach
	return car_pos.distance_to(ob["pos"]) < reach

func _clear_obstacle_hit() -> void:
	_grace_t = 1.2

## The plane's next ring this lap (or {})
func _next_ring() -> Dictionary:
	for rg in rings:
		if int(rg["lap"]) != lap:
			return rg
	return {}

## The rings the plane has just gone past: through one (a ding, a sparkle) or beside it (true:
## missed, a crash). Each is judged once a lap (a toy put back behind one doesn't fly it again).
func _check_rings() -> bool:
	var missed := false
	for rg in rings:
		if int(rg["lap"]) == lap:
			continue
		if progress < float((lap - 1) * count + int(rg["i"])):
			break
		rg["lap"] = lap
		var off := absf((car_pos - (rg["pos"] as Vector2)).dot(rg["n"]))
		if off < float(rg["r"]) * RING_TOL:
			rg["hit"] = true
			_sfx("res://sounds/fx/ring_chime.wav", -10.0, _ring_pitch(rings.find(rg)))
			Input.vibrate_handheld(15)
			trail.sparkle(rg["pos"])
			_ring_fx_refresh()                       # (its look changes on the chime's own frame: the user)
		else:
			missed = true
			_ring_fx_refresh()
	return missed

## Each ring of a lap its own note (the user, 2026-10-18: the climb topped out and repeated its
## highest note): up a major scale from the lap's first ring to its last, the last one an octave
## over the chime's own note (a long lap starts lower to fit them all); every lap starts again
const SCALE := [0, 2, 4, 5, 7, 9, 11]
func _ring_pitch(k: int) -> float:
	var steps := func(j: int) -> int: return 12 * (j / 7) + int(SCALE[j % 7])
	var top: int = steps.call(rings.size() - 1)
	return pow(2.0, float(steps.call(k) - top + 12) / 12.0)

## The plane in a gust: blown across the course (a sturdy one only half as much)
func _blow(delta: float) -> void:
	for g in gusts:
		if near >= int(g[0]) and near <= int(g[1]):
			var k := 0.5 if PetState.boost_power("sturdy") > 0 else 1.0
			car_pos += _normal(near) * float(g[2]) * GUST_PUSH * k * delta

## QA only: the toy drives itself like a careful driver (steering at the course a little ahead,
## onto a safe line beside whatever is coming up; a plane at its next ring)
func _autopilot() -> float:
	var ahead := 14 if vehicle == "car" else (18 if vehicle == "boat" else 20)
	var ai := (near + ahead) % count
	var aim := centre[ai]
	var lat := 0.0                                   # where across the course it wants to be
	var first := 1 << 20
	for ob in obstacles:
		var oi := int(ob["i"])
		var di := posmod(oi - near, count)
		if di <= 0 or di >= 75 or di >= first:
			continue
		first = di
		var n := _normal(oi)
		var at: Vector2 = ob["pos"]
		if ob["kind"] == "log":
			at = ob["b"]                             # (its inner end: the way past is beyond it)
		var ob_lat := (at - centre[oi]).dot(n)
		var room: float = float(ob["r"]) + float(TOY_R[vehicle]) + 28.0 + (34.0 if ob["kind"] == "balloon" else 0.0)
		lat = ob_lat - signf(ob_lat if ob_lat != 0.0 else 1.0) * room
	var round_these: Array = slicks.map(func(sl): return sl[0])
	if not gate_open("milky", int(secret.get("lvl", 1))):
		for cr in secret.get("crates", []):
			if is_instance_valid(cr):
				round_these.append((cr as Sprite2D).position)
	for at2 in round_these:
		var to: Vector2 = (at2 as Vector2) - car_pos
		var ahead_px := to.dot(Vector2.from_angle(heading))
		if to.length() < 420.0 and ahead_px > 0.0 and ahead_px / STEP < first:
			first = int(ahead_px / STEP)                  # (the nearest thing first)
			var sl_lat := ((at2 as Vector2) - centre[near]).dot(_normal(near))
			lat = sl_lat - signf(sl_lat if sl_lat != 0.0 else 1.0) * (SLICK_R + float(TOY_R[vehicle]) + 16.0)
	if vehicle == "plane":
		var rg := _next_ring()
		if not rg.is_empty() and (rg["pos"] as Vector2).distance_to(car_pos) < 320.0 and posmod(int(rg["i"]) - near, count) < first:
			aim = rg["pos"]
			lat = 0.0                                # (the ring first)
	var limit: float = half_w * (CORRIDOR - 0.4) if vehicle == "plane" else half_w - (SHALLOW_IN + 34.0 if vehicle == "boat" else 36.0)
	aim += _normal(ai) * clampf(lat, -limit, limit)
	var want := (aim - car_pos).angle()
	if vehicle == "boat":
		want -= wrapf(vel.angle() - heading, -PI, PI) * 0.8            # (against its drift)
	var diff := wrapf(want - heading, -PI, PI)
	return clampf(diff * 3.0, -1.0, 1.0) if absf(diff) > 0.03 else 0.0

## What crashed the toy just now ("" = nothing): the car off the road or into a gap; the boat
## aground on a sandbar or the bank, on a rock or a log; the plane past a ring outside it, into a balloon or a
## storm cloud
func _crash_now() -> String:
	if air_t > 0.0:
		return ""
	match vehicle:
		"car":
			if car_pos.distance_to(centre[near]) > half_w + FALL_AT or _in_gap(near):
				return "fall"
		"boat":
			if _in_gap(near) and car_pos.distance_to(centre[near]) < half_w:
				return "aground"
			if car_pos.distance_to(centre[near]) > half_w + SHORE_AT:
				return "shore"
			for ob in obstacles:
				if _hits(ob):
					return "rock"
		"plane":
			var missed := _check_rings()
			if missed:
				return "ring"
			for ob in obstacles:
				if _hits(ob):
					return ob["kind"]
	return ""

## About to crash (a focused pal gets a slow moment): the car at the road's very edge, the boat
## heading into a rock close ahead, the plane coming up to a ring off to the side
func _brink() -> bool:
	match vehicle:
		"car":
			return air_t <= 0.0 and car_pos.distance_to(centre[near]) > half_w + FALL_AT * 0.2 and not _rail_at(near)
		"boat":
			var ahead := car_pos + vel.normalized() * 70.0
			if car_pos.distance_to(centre[near]) > half_w + SHORE_AT * 0.5 and vel.dot(car_pos - centre[near]) > 0.0:
				return true
			for ob in obstacles:
				if ahead.distance_to(ob["pos"]) < float(ob["r"]) + 24.0:
					return true
		"plane":
			var rg := _next_ring()
			if not rg.is_empty():
				var to: Vector2 = rg["pos"] - car_pos
				var dirv := Vector2.from_angle(heading)
				if to.dot(dirv) > 0.0 and to.dot(dirv) < 110.0 and absf(to.dot(rg["n"])) > float(rg["r"]) * RING_TOL * 0.9:
					return true
	return false

## The car against a guard rail: a rubbery "boing" off the tyres (the user, 2026-10-18: holding
## it on the road and turning it along made it drive itself round the corners): it's pushed back
## onto the road, its heading bounced off the barrier (the part going into it turned back out),
## both over a moment (bounce_t, knock_v), and it loses a little speed (bump_t); it never steers
## it for you
func _rail_hold() -> void:
	if air_t > 0.0 or not _rail_at(near):
		return
	var n := _normal(near)
	var lat := (car_pos - centre[near]).dot(n)
	if signf(lat) != float(_rail[near]) or absf(lat) <= half_w - RAIL_IN:
		return
	var out := n * signf(lat)
	car_pos -= out * (absf(lat) - (half_w - RAIL_IN))          # (held at the tyres this frame)
	# the bounce plays out over a moment (the user, 2026-10-18: it was too sudden): a push back in
	# that fades, the heading easing round to its bounced way, a gentle slow-down
	var dir := Vector2.from_angle(heading)
	var into := dir.dot(out)
	if into > 0.0 and bounce_t <= 0.0:
		# (bounced back in across the road, not along the barrier: the user, 2026-10-18, a mirror
		# off the tyres still carried a car nobody steered round the corners)
		bounce_to = ((dir - out * into * (1.0 + RAIL_BOUNCE)).normalized() - out * RAIL_INWARD).angle()
		bounce_t = BOUNCE_TIME
		knock_v = -out * RAIL_KNOCK_V
		bump_t = 1.0
	boost_t = 0.0
	if _buoy_cd <= 0.0:
		_buoy_cd = 0.22
		_sfx("res://sounds/fx/water_boing.wav", -9.0, 1.15)
		_sfx("res://sounds/fx/wood_tap.wav", -14.0, 0.9)
		Input.vibrate_handheld(25)
		trail.spray(car_pos + out * 28.0, heading, 4)

func _rail_at(i: int) -> bool:
	return not _rail.is_empty() and _rail[i] != 0

## The plane strays too far from the course: the sky's edge turns it back towards it
func _corridor(delta: float) -> void:
	var n := _normal(near)
	var lat := (car_pos - centre[near]).dot(n)
	var limit := half_w * CORRIDOR
	if absf(lat) <= limit:
		return
	car_pos -= n * signf(lat) * minf(absf(lat) - limit, 240.0 * delta)
	var road := (centre[(near + 6) % count] - car_pos).angle()
	heading = lerp_angle(heading, road, minf(1.0, delta * 2.5))

## The course's next lap: the plane's rings stand ready again
func _new_lap() -> void:
	for rg in rings:
		rg["hit"] = false
		rg["popped"] = false
	_ring_fx_refresh()

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

## A crash (_crash_now): a heart breaks (a splashy pal's water heart first: that one undoes it on
## the spot, no time lost) and the crowd near it screams. The car tips over the edge and drops to the
## floor (always under the track: never drawn over a road, the user 2026-10-17), the boat flips and
## sinks, the plane spins down to the ground; then it's back on the last checkpoint, pointing down
## the course (the clock goes on). A missed ring: the plane just flies on. The last heart: out.
func _crash(kind: String) -> void:
	if not splash_used and PetState.boost_power("splash") > 0:
		splash_used = true
		PetState.use_boost()
		spend_water_heart()
		if kind != "ring":
			var i := near
			car_pos = centre[i]
			heading = (centre[(i + 2) % count] - centre[i]).angle()
			vel = Vector2.from_angle(heading) * _speed() * 0.6
			slip_t = 0.0
			_clear_obstacle_hit()
		trail.spray(car_pos, heading, 14)
		_sfx("res://sounds/fx/water_boing.wav", -8.0)
		_show_banner("splash!", 0.5)
		Input.vibrate_handheld(40)
		return
	falls += 1
	var last := lose_life()
	if qa_autopilot:
		print("QA crash %d: %s at %.1f s" % [level, kind, race_time])
	for st in _stands():
		st.scream(car_pos)
	if _stands().any(func(st): return st.rect.grow(320.0).has_point(car_pos)):
		if true:
			_sfx("res://sounds/fx/crowd_gasp.wav", -8.0, randf_range(0.95, 1.1))
	if kind == "ring":
		_show_banner("missed!", 0.5)
		_sfx("res://sounds/fx/claw_miss.wav", -8.0)
		Input.vibrate_handheld(60)
		if last:
			_out_of_lives()
		return
	state = State.FALL
	_wrecked = true
	var from := car_pos
	var out := (car_pos - centre[near]).normalized()
	# off the far side (an edge facing up the screen) it goes behind the raised track; off a near or
	# side edge it stays in front and drops onto the floor below (the user: it went under the track's
	# near edge, as if the border were see-through)
	var far_side := out.y < -0.35
	if far_side:
		for n in [car, antenna, antenna_tip, driver]:
			n.reparent(behind, false)
	var drop := TRACK_SIDE * PX * 3.0
	if not _tiles.is_empty() and not far_side:
		drop = RcTiles.FACE_ROWS * RcTiles.ART_PX + 16.0   # (the new track's side face, then onto the floor)
	motor.stop()
	Input.vibrate_handheld(80)
	var t := create_tween()
	match vehicle:
		"car":
			# it tips out over the edge it left, then drops
			_sfx("res://sounds/fx/rc_fall.wav", -12.0)
			t.tween_method(func(f: float):
				car_pos = from + out * TIP_OUT * (1.0 - pow(1.0 - minf(1.0, f * 2.5), 2.0))
				car_drop = f * f * drop
				car.modulate = Color(1, 1, 1).lerp(Color(0.4, 0.38, 0.45), f)
				car.scale = Vector2.ONE * (1.0 - 0.15 * f), 0.0, 1.0, 0.45)
			t.tween_callback(func(): _sfx("res://sounds/fx/rc_land.wav", -10.0))
		"boat" when kind == "shore":
			# it runs up onto the bank: a lurch out of the water, a rock side to side, a puff of sand
			_sfx("res://sounds/fx/wood_tap.wav", -6.0, 0.5)
			_sfx("res://sounds/fx/rc_land.wav", -10.0, 0.8)
			trail.spray(car_pos, heading, 10)
			var h2 := heading
			t.tween_method(func(f: float):
				car_pos = from + out * 30.0 * (1.0 - pow(1.0 - minf(1.0, f * 3.0), 2.0))
				heading = h2 + sin(f * TAU * 2.0) * 0.35 * (1.0 - f)
				car.modulate = Color(1, 1, 1).lerp(Color(1, 1, 1, 0.0), maxf(0.0, f - 0.6) / 0.4), 0.0, 1.0, 0.75)
		"boat":
			# a bump, it flips round and sinks a little (the water closes over it)
			_sfx("res://sounds/fx/wood_tap.wav", -6.0, 0.6)
			trail.spray(car_pos, heading, 16)
			var h0 := heading
			t.tween_method(func(f: float):
				heading = h0 + f * TAU * 1.5
				car.modulate = Color(1, 1, 1).lerp(Color(0.45, 0.6, 0.7, 0.0), f * f)
				car.scale = Vector2.ONE * (1.0 - 0.3 * f), 0.0, 1.0, 0.6)
			t.tween_callback(func(): _sfx("res://sounds/fx/water_boing.wav", -10.0, 0.6))
		"plane":
			# it spins down to the ground far below, smaller and smaller
			_sfx("res://sounds/fx/sfx_sounds_falling4.wav", -10.0)
			var h1 := heading
			t.tween_method(func(f: float):
				heading = h1 + f * TAU * 2.0
				car_drop = f * f * 160.0
				car.modulate = Color(1, 1, 1).lerp(Color(0.5, 0.5, 0.6, 0.0), f * f)
				car.scale = Vector2.ONE * (1.0 - 0.6 * f), 0.0, 1.0, 0.8)
	t.tween_interval(0.35)
	t.tween_callback(_out_of_lives if last else _respawn)

## Back on the last checkpoint, pointing down the course, blinking
func _respawn() -> void:
	_wrecked = false
	var i := int(fposmod(last_cp, count))
	car_pos = centre[i]
	heading = (centre[(i + 2) % count] - centre[i]).angle()
	vel = Vector2.from_angle(heading) * _speed() * 0.5
	near = i
	progress = last_cp
	car_drop = 0.0
	bank = 0.0
	for n in [car, antenna, antenna_tip, driver]:
		if n.get_parent() != front:
			n.reparent(front, false)
	front.move_child(shadow, 0)
	front.move_child(prop, -1)                      # (the propeller over the plane's nose)
	trail.marks.clear()
	car.modulate = Color(1, 1, 1)
	car.scale = Vector2.ONE
	held = [false, false]
	_clear_obstacle_hit()
	state = State.DRIVE
	motor.play()
	var blink := create_tween()
	for k in 3:
		blink.tween_property(car, "modulate:a", 0.25, 0.08)
		blink.tween_property(car, "modulate:a", 1.0, 0.08)

## The last heart broke: the race is over (its result card: Out of lives!, retry from the start)
func _out_of_lives() -> void:
	state = State.DONE
	motor.stop()
	if qa_autopilot:
		print("QA race %d (%s) OUT OF LIVES at %.1f lap %d" % [level, vehicle, race_time, lap])
	_show_banner("Out of lives!", 0.9)
	_sfx("res://sounds/fx/error.mp3", -10.0)
	get_tree().create_timer(1.4).timeout.connect(func():
		if is_running:
			finish_level(level, 0, race_time))

func fail_title() -> String:
	return "Out of lives!"

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
	for st in _stands():
		st.party = true
	motor.stop()
	var stars := _stars_now()
	if qa_autopilot:
		print("QA race %d (%s) stars %d time %.1f par %.0f crashes %d place %d" % [level, vehicle, stars, race_time, par, falls, place])
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
	_spawn_course_things()
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
	headlight.visible = look == "night"
	rain_fx.visible = rain
	for n in _lamp_nodes:
		n.queue_free()
	_lamp_nodes.clear()
	if look == "night":
		var tex := _lamp_post_texture()
		for lp in _lamps:
			var post := _px_sprite(tex, (lp as Vector2) * PX + Vector2(0, -20))
			world.add_child(post)
			world.move_child(post, track.get_index())        # (on the floor, under the track's level)
			_lamp_nodes.append(post)
	_refresh_hud()

## The plane's rings (two halves each, round the plane), the obstacles' pieces (under the toy: a
## rock, a log, a balloon, a storm cloud), the gusts' streaks
var _thing_nodes: Array = []
func _spawn_course_things() -> void:
	for nd in _thing_nodes:
		if is_instance_valid(nd):
			nd.queue_free()
	_thing_nodes.clear()
	for rg in rings:
		var i := int(rg["i"])
		for upper in [false, true]:
			var ring := Ring.new()
			ring.position = rg["pos"]
			ring.n = rg["n"]
			ring.r = rg["r"]
			ring.upper = upper
			ring.art = RcSky.on(look)
			ring.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST   # (crisp: smoothed, the cut between its halves showed a dark hairline)
			ring.d = (centre[(i + 1) % count] - centre[i]).normalized()
			(ring_front if upper else ring_back).add_child(ring)
			rg["front" if upper else "back"] = ring
			_thing_nodes.append(ring)
	_ring_fx_refresh()
	for ob in obstacles:
		var spr: Sprite2D
		match ob["kind"]:
			"rock":
				spr = _px_sprite(PalPrixArt.rock(int(ob["k"])), ob["pos"])
			"log":
				spr = _px_sprite(PalPrixArt.log_texture(), ob["pos"])
				spr.rotation = ((ob["b"] as Vector2) - (ob["a"] as Vector2)).angle()
			"balloon":
				var art_b := RcSky.balloon(int(ob["k"])) if RcSky.on(look) else null   # (RC ART: the designer's, blue and pink)
				spr = _px_sprite(art_b, (ob["pos"] as Vector2) + Vector2(0, -20), RcSky.ART_PX) if art_b else _px_sprite(PalPrixArt.balloon(int(ob["k"])), (ob["pos"] as Vector2) + Vector2(0, -20))
			_:
				spr = _px_sprite(PalPrixArt.cloud(16, int(ob["k"]), true), ob["pos"])
		front.add_child(spr)
		front.move_child(spr, 0)                     # (under the toy)
		ob["node"] = spr
		_thing_nodes.append(spr)
	var zones := []
	for g in gusts:
		var pts := PackedVector2Array()
		for i in range(int(g[0]), int(g[1]), 4):
			pts.append(centre[i % count])
		zones.append([pts, _normal((int(g[0]) + int(g[1])) / 2) * float(g[2])])
	gust_fx.setup(zones)

## Which ring is next (gold, it glows), the one after it, the farther ones (faint), which were
## flown through (they pop) or missed (grey) this lap
func _ring_fx_refresh() -> void:
	var nxt := _next_ring()
	var after := {}
	if not nxt.is_empty():
		var at := rings.find(nxt)
		if at + 1 < rings.size():
			after = rings[at + 1]
	for rg in rings:
		var st := 0
		if int(rg["lap"]) == lap:
			st = 2 if rg["hit"] else 3
			if rg["hit"] and not rg.get("popped", false):
				if progress < float((lap - 1) * count + int(rg["i"])) + RING_PAST:
					st = 5 if DevLaunch.rc_gold_pass else 1   # (the plane still in it: gold with the chime, it pops once it's out)
				else:
					rg["popped"] = true                  # (and once popped it stays gone this lap, even
														 # flying back past it: the user, 2026-10-18)
		elif is_same(rg, nxt):
			st = 1
		elif is_same(rg, after):
			st = 4
		for key in ["back", "front"]:
			if rg.has(key) and is_instance_valid(rg[key]):
				rg[key].show_state(st)

## What the view shows now (mat px)
func view_rect() -> Rect2:
	return Rect2((VIEW.position - world.position) / ZOOM, VIEW.size / ZOOM)

## Open water at a point (mat px): the boat's worlds, not on an island or the bank
func is_open_water(p: Vector2) -> bool:
	var b := Vector2i(p / PX)
	if b.x < EDGE or b.y < EDGE or b.x >= _bw - EDGE or b.y >= _bh - EDGE or _island.size() != _bw * _bh:
		return false
	var i := b.y * _bw + b.x
	if _island[i] != 0 and _island[i] != ISLE_SHALLOW and _island[i] != ISLE_SHADOW:
		return false
	var d := _dist[i]
	var bank := half_w / PX + SHORE_PAINT / PX
	var sc_i := _sea_cell(b)
	if sc_i >= 0 and _sea[sc_i] <= 8.0 and d > bank:
		return false                                 # (RC ART: the sand in the narrow gaps)
	return d < bank - 1.0 or d > bank + 13.0

## The plane's guide: the course from the plane to the next ring and on to the one after (the
## sparkles start where the plane is and join the course's line over a few steps), and the arrow
## when that ring is off the screen
func _update_guide() -> void:
	if vehicle == "plane":
		_ring_fx_refresh()                              # (a ring flown through pops once the plane is out)
	var nxt := _next_ring() if vehicle == "plane" and state == State.DRIVE else {}
	guide.visible = not nxt.is_empty()
	pointer.on = guide.visible
	if nxt.is_empty():
		return
	var at := rings.find(nxt)
	var i1 := int(nxt["i"])
	var i2 := int(rings[at + 1]["i"]) if at + 1 < rings.size() else i1
	var to1 := posmod(i1 - near, count)
	var to2 := posmod(i2 - near, count) if i2 != i1 else to1
	var off := car_pos - centre[near]
	var p := PackedVector2Array()
	var first := 0
	var step := 6
	var k := 4
	while k <= mini(to2, 260):
		var f := clampf(1.0 - float(k) / 40.0, 0.0, 1.0)
		p.append(centre[(near + k) % count] + off * f)
		if k <= to1:
			first = p.size()
		k += step
	guide.pts = p
	guide.to_next = first
	pointer.target = world.position + (nxt["pos"] as Vector2) * ZOOM

## The sky's things move: the balloons drift from side to side, the storm clouds flash
func _update_course_things(delta: float) -> void:
	_t += delta
	_update_guide()
	for ob in obstacles:
		if not ob.has("node") or not is_instance_valid(ob["node"]):
			continue
		match ob["kind"]:
			"balloon":
				ob["pos"] = (ob["base"] as Vector2) + _normal(int(ob["i"])) * sin(_t * 0.7 + float(ob["k"])) * 34.0
				(ob["node"] as Sprite2D).position = ((ob["pos"] as Vector2) + Vector2(0, -20)).round()
			"storm":
				var ph := fposmod(_t + float(ob["k"]) * 0.9, 2.6)
				var flash := ph < 0.07 or (ph > 0.15 and ph < 0.2)
				(ob["node"] as Sprite2D).modulate = Color(2.0, 2.0, 2.4) if flash else Color(1, 1, 1)

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
			if look == "lagoon":
				# the Lagoon's bridge: a wooden deck, planks across it (a pier over the water)
				var plank := int(t * axis.length() / 5.0)
				col = Color8(196, 140, 88) if plank % 2 == 0 else Color8(176, 122, 74)
				if int(t * axis.length()) % 5 == 0:
					col = Color8(120, 78, 46)
			elif look == "night":
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
			if vehicle != "plane":
				var spring := _px_sprite(_spring_texture(), centre[(at - 9 + count) % count])
				spring.rotation = dir.angle()
				node.add_child(spring)
			secret["spring"] = (at - 9 + count) % count
			if not taken:
				var g := Node2D.new()
				g.position = centre[at] + Vector2(0, -70)
				node.add_child(g)
				g.add_child(_px_sprite(_balloon_texture(), Vector2(0, -40)))
				g.add_child(_gift_sprite(secret["prize"], Vector2.ZERO))
				var bob := g.create_tween().set_loops()
				bob.tween_property(g, "position:y", g.position.y - 10.0, 0.7).set_trans(Tween.TRANS_SINE)
				bob.tween_property(g, "position:y", g.position.y, 0.7).set_trans(Tween.TRANS_SINE)
				secret["gift"] = g
		"milky" when vehicle == "plane":
			# a storm cloud on the course, the gift inside: a sturdy plane flies through it
			if not taken:
				var cl := _px_sprite(PalPrixArt.cloud(16, 7, true), centre[at])
				node.add_child(cl)
				secret["cloud"] = cl
				var g4 := _gift_sprite(secret["prize"], centre[at])
				node.add_child(g4)
				secret["gift"] = g4
		"milky":
			var crates: Array = []
			if not taken:
				for k in 3:
					var cr := _px_sprite(_crate_texture(), centre[at] + side * (half_w * 0.28 + k * 34.0 - 34.0) * 1.0 + side * half_w * 0.2)
					node.add_child(cr)
					crates.append(cr)
				var g2 := _gift_sprite(secret["prize"], centre[(at + 4) % count] + side * half_w * 0.45)
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
				var g3 := _gift_sprite(secret["prize"], centre[at])
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
		"fizzy" when vehicle == "plane":
			# under the balloon: a fizzy plane climbs up to it
			if car_pos.distance_to(centre[secret["at"]]) < 80.0:
				if gate_open("fizzy", lvl):
					_jump(AIR_TIME * 1.2)
					_take_secret()
				elif not secret.get("hinted", false):
					secret["hinted"] = true
					_show_banner("fizzy planes climb!", 0.8)
		"milky" when vehicle == "plane":
			if car_pos.distance_to(centre[secret["at"]]) < 70.0 and not secret.get("bounced", false):
				if gate_open("milky", lvl):
					PetState.use_boost()
					if secret.has("cloud") and is_instance_valid(secret["cloud"]):
						var cl: Sprite2D = secret["cloud"]
						var tw := cl.create_tween()
						tw.tween_property(cl, "modulate:a", 0.0, 0.3)
						tw.tween_callback(cl.queue_free)
					_take_secret()
				else:
					secret["bounced"] = true
					heading += PI * 0.5 * (1.0 if randf() < 0.5 else -1.0)    # (thrown off the cloud's edge)
					_sfx("res://sounds/fx/thunder.wav", -14.0, 1.4)
					_show_banner("sturdy planes fly through!", 0.8)
			elif car_pos.distance_to(centre[secret["at"]]) > 200.0:
				secret["bounced"] = false
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
				elif vehicle == "boat" and _buoy_cd <= 0.0:
					vel = -vel * 0.5                            # (a bump back off the crates)
					_buoy_cd = 0.4
					_sfx("res://sounds/fx/wood_tap.wav", -8.0, 0.7)
					_show_banner("sturdy boats smash!", 0.8)
				elif vehicle != "boat" and slip_t <= 0.0:
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
## The rivals' tiers: their pace (x the toy's speed), how much they brake in the bends, how far
## they wander off their line, how often they make a mistake (a moment slow, off the line; s, 0 =
## never), and how long they take to go at the green light (s)
const RIVAL_TIERS := [
	{ "name": "rookie", "speed": 0.9, "corner": 0.55, "wander": 0.24, "slip_every": 9.0, "react": 0.5, "dodge": 0.55 },
	{ "name": "average", "speed": 0.95, "corner": 0.35, "wander": 0.14, "slip_every": 16.0, "react": 0.3, "dodge": 0.8 },
	{ "name": "ace", "speed": 1.0, "corner": 0.15, "wander": 0.05, "slip_every": 0.0, "react": 0.12, "dodge": 0.97 },
]
## Each world's colour: the crowd's other pals are the ones that go with it
const CROWD_HAZE := { "garden": Color8(120, 190, 90), "night": Color8(90, 100, 170), "lagoon": Color8(236, 140, 110),
	"reef": Color8(70, 190, 200), "sky": Color8(150, 200, 240), "sunset": Color8(240, 150, 110) }
const PLANE_BODY := Color8(250, 210, 84)          # (every plane's yellow body: yours and the rivals')
const RIVAL_PLANE_COLS := [Color8(70, 130, 220), Color8(150, 100, 210), Color8(110, 190, 110)]   # the rival planes' wings: blue, purple, green
const RIVAL_COLS := [[Color8(70, 130, 220), Color8(46, 92, 170)], [Color8(240, 200, 70), Color8(196, 150, 40)], [Color8(110, 190, 110), Color8(70, 140, 76)]]
var _rival_things: Array = []          # what's in the rivals' way: [course point, lane (-1..1 across), room to pass (lane), where (mat px), how close is a hit (px)]
func _spawn_rivals() -> void:
	for r in rivals:
		(r["node"] as Node).queue_free()
	rivals.clear()
	_rival_things.clear()
	for ob in obstacles:
		var oi := int(ob["i"])
		var at: Vector2 = ob["b"] if ob["kind"] == "log" else ob["pos"]
		var lat := (at - centre[oi]).dot(_normal(oi)) / half_w
		_rival_things.append([oi, lat, (float(ob["r"]) + 50.0) / half_w, ob["pos"], float(ob["r"]) + 22.0])
	for sl2 in slicks:
		var p2: Vector2 = sl2[0]
		var best := 0
		var bd := INF
		for ci in range(0, count, 2):
			var dd := centre[ci].distance_squared_to(p2)
			if dd < bd:
				bd = dd
				best = ci
		_rival_things.append([best, (p2 - centre[best]).dot(_normal(best)) / half_w, (SLICK_R + 40.0) / half_w, p2, SLICK_R * 0.8])
	var n := int(extras.get("rivals", 0))
	var k := (level - 1) % GameData.LEVELS_PER_WORLD
	for j in n:
		var node := Node2D.new()
		front.add_child(node)
		var sl: Array = []
		var layers: Array[Texture2D]
		match vehicle:
			"boat":
				layers = PalPrixArt.boat_slices(RIVAL_COLS[j][0], RIVAL_COLS[j][1])
			"plane":
				# (the user, 2026-10-18: the same plane as yours, only its colour: the same yellow
				# body, its own spinning propeller, banking into the turns like yours)
				layers = PalPrixArt.plane_slices(RIVAL_PLANE_COLS[j], PLANE_BODY, false)
			_:
				layers = _tinted_slices(RIVAL_COLS[j][0], RIVAL_COLS[j][1])
		for li in layers.size():
			var spr := Sprite2D.new()
			spr.texture = layers[li]
			spr.scale = Vector2(PX, PX)
			spr.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
			var kk := (0.85 + 0.15 * float(li) / (layers.size() - 1)) if vehicle == "plane" else (0.62 + 0.38 * float(li) / (layers.size() - 1))
			spr.modulate = Color(kk, kk, kk)
			node.add_child(spr)
			sl.append(spr)
		var helmet := _px_sprite(_helmet_texture(RIVAL_COLS[j][0] if vehicle != "plane" else RIVAL_PLANE_COLS[j]), Vector2(0, -layers.size() * LAYER_UP - 4.0), 2)
		node.add_child(helmet)
		# its antenna, like yours (the user, 2026-10-18): a thin wire with its ball, the ball in its colour
		var ant := Line2D.new()
		ant.width = 4.0
		ant.default_color = Color8(40, 30, 40)
		ant.antialiased = false
		node.add_child(ant)
		var ant_tip := _px_sprite(antenna_tip.texture, Vector2.ZERO, PX)
		ant_tip.modulate = RIVAL_PLANE_COLS[j].lightened(0.2)
		node.add_child(ant_tip)
		var rprop: Sprite2D = null
		if vehicle == "plane":
			rprop = Sprite2D.new()
			rprop.scale = Vector2(PX, PX)
			rprop.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
			node.add_child(rprop)
		var light := Sprite2D.new()
		light.texture = headlight.texture if headlight else _cone_texture()
		light.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		var m := CanvasItemMaterial.new()
		m.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
		light.material = m
		light.scale = Vector2(PX, PX)
		light.visible = look == "night"
		node.add_child(light)
		# on the grid: just behind the line, the lanes either side of the middle
		var lane: float = [-0.42, 0.42, 0.0][j]
		var back_pts := 8 + j * 7
		# each rival a driver of its own (the user, 2026-10-18: they all drove the same, perfectly,
		# in step): a rookie, an average one, an ace (RIVAL_TIERS); one rival: an average one, two:
		# a rookie and an ace, three: one of each
		var tier: int = [[1], [0, 2], [0, 1, 2]][clampi(n, 1, 3) - 1][j]
		var tr: Dictionary = RIVAL_TIERS[tier]
		rivals.append({ "node": node, "slices": sl, "light": light, "helmet": helmet, "prop": rprop, "layers": layers, "bank": 0.0, "col": RIVAL_PLANE_COLS[j], "progress": -float(back_pts), "lane": lane,
			"speed": _speed() * float(tr["speed"]) * (1.0 + 0.004 * k) * (0.88 if vehicle == "boat" else 1.0), "heading": 0.0, "pos": Vector2.ZERO, "done": false,
			"ant": ant, "ant_tip": ant_tip, "dodge": {}, "spin": 0.0,
			"tier": tier, "lane_now": lane, "phase": randf() * TAU, "wander_hz": randf_range(0.25, 0.5), "slip_t": 0.0,
			"next_slip": randf_range(float(tr["slip_every"]) * 0.5, float(tr["slip_every"]) * 1.5), "react": float(tr["react"]) + randf_range(0.0, 0.15), "gone": false })
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
		var p := a.lerp(b, f) + Vector2(-dir.y, dir.x) * half_w * float(r.get("lane_now", r["lane"]))
		r["pos"] = p
		var node: Node2D = r["node"]
		node.position = p.round()
		var air := _in_gap((i % count + count) % count)
		if vehicle == "plane":
			# a plane like yours: it eases round (no snapping from one bit of the course to the
			# next), rolls into the turn (its wings foreshortened and shaded, the stack leaning in),
			# its propeller spinning
			if not r.get("placed", false):
				r["placed"] = true
				r["heading"] = dir.angle()                 # (on the grid: facing down the course)
			var was: float = r["heading"]
			var to := lerp_angle(was, dir.angle(), 0.18)
			r["heading"] = to
			r["bank"] = lerpf(float(r["bank"]), clampf(wrapf(to - was, -PI, PI) * 40.0, -1.0, 1.0), 0.12)
			var bk: float = r["bank"]
			var n_sl: int = r["slices"].size()
			var tilt := Vector2.from_angle(to + PI / 2.0) * bk * 14.0
			var dip := 0 if absf(bk) < 0.3 else int(signf(bk))
			for li in n_sl:
				var spr: Sprite2D = r["slices"][li]
				spr.rotation = to
				spr.position = (Vector2(0, -li * LAYER_UP) + tilt * float(li) / maxf(1.0, n_sl - 1)).round()
				spr.scale = Vector2(PX, PX * (1.0 - 0.42 * absf(bk)))
			(r["slices"][1] as Sprite2D).texture = PalPrixArt.plane_wings(r["col"], PLANE_BODY, dip) if dip != 0 else (r["layers"] as Array)[1]
			(r["helmet"] as Sprite2D).position = Vector2.from_angle(to) * PalPrixArt.PLANE_SEAT * PX + Vector2(0, -n_sl * LAYER_UP - 4.0) + tilt
			var pr2: Sprite2D = r["prop"]
			pr2.texture = PalPrixArt.propeller(_prop_frame)
			pr2.rotation = to
			pr2.scale = Vector2(PX, PX * (1.0 - 0.42 * absf(bk)))
			pr2.position = (Vector2.from_angle(to) * 46.0 + Vector2(0, -2.0 * LAYER_UP) + tilt * 0.66).round()
		else:
			r["heading"] = dir.angle()
		for li in r["slices"].size():
			if vehicle == "plane":
				break
			(r["slices"][li] as Sprite2D).rotation = r["heading"]
			(r["slices"][li] as Sprite2D).position = Vector2(0, -li * LAYER_UP - (40.0 if air else 0.0))
		# (spun round by a thing it hit)
		var spin_a := 0.0
		if float(r.get("spin", 0.0)) > 0.0:
			spin_a = (1.0 - float(r["spin"]) / 0.9) * TAU
			for sp2 in r["slices"]:
				(sp2 as Sprite2D).rotation = float(r["heading"]) + spin_a
		var hd := float(r["heading"]) + spin_a
		var n_l: int = r["slices"].size()
		var ant: Line2D = r["ant"]
		if vehicle == "plane":
			var up := Vector2(0, -(n_l - 1) * LAYER_UP)
			var a0 := Vector2.from_angle(hd) * -26.0 + up
			var a1 := Vector2.from_angle(hd) * -46.0 + up + Vector2(0, -20)
			ant.points = PackedVector2Array([a0.round(), a1.round()])
			(r["ant_tip"] as Sprite2D).position = a1.round()
		else:
			var corner := Vector2(-30, -22) if vehicle == "car" else Vector2(-46, -18)
			var base := corner.rotated(hd) + Vector2(0, -n_l * LAYER_UP)
			var top := base + Vector2(0, -46) + Vector2.from_angle(hd) * -10.0
			ant.points = PackedVector2Array([base.round(), (base.lerp(top, 0.5)).round(), top.round()])
			(r["ant_tip"] as Sprite2D).position = top.round()
		(r["light"] as Sprite2D).rotation = r["heading"]
		(r["light"] as Sprite2D).position = Vector2.from_angle(r["heading"]) * 92.0

## The rivals drive the racing line (a lane each), a little faster when behind you, a little slower
## when well ahead (close races); they bump into you (a sturdy car isn't shoved); your place
func _update_rivals(delta: float) -> void:
	if rivals.is_empty():
		return
	var ahead := 0
	for r in rivals:
		var tr: Dictionary = RIVAL_TIERS[int(r["tier"])]
		if not r["done"] and race_time >= float(r["react"]):
			var gap: float = r["progress"] - progress
			var k := 1.0
			if gap > count * 0.12:
				k = 0.94
			elif gap < -count * 0.12:
				k = 1.06
			# slower through the bends (a rookie much more), and its mistakes: now and then a
			# moment slow, off its line
			var ri := posmod(int(r["progress"]), count)
			var bend := absf(wrapf((centre[(ri + 7) % count] - centre[(ri + 6) % count]).angle() - (centre[(ri + 1) % count] - centre[ri]).angle(), -PI, PI))
			k *= 1.0 - float(tr["corner"]) * clampf(bend, 0.0, 1.0)
			if float(tr["slip_every"]) > 0.0:
				r["next_slip"] = float(r["next_slip"]) - delta
				if float(r["next_slip"]) <= 0.0:
					r["slip_t"] = 0.8
					r["next_slip"] = randf_range(float(tr["slip_every"]) * 0.6, float(tr["slip_every"]) * 1.4)
			if float(r["slip_t"]) > 0.0:
				r["slip_t"] = float(r["slip_t"]) - delta
				k *= 0.55
			r["progress"] += r["speed"] * k * delta / STEP
			if r["progress"] >= count * LAPS:
				r["done"] = true
				# (over the line: it fades away, never parked in your way at the finish)
				var fade := (r["node"] as Node2D).create_tween()
				fade.tween_interval(0.6)
				fade.tween_property(r["node"], "modulate:a", 0.0, 0.5)
				fade.tween_callback(func(): r["gone"] = true)
		# its own line: wandering about its lane on its own rhythm, jolted aside by a mistake
		var wob := sin(race_time * TAU * float(r["wander_hz"]) + float(r["phase"])) * float(tr["wander"])
		var jolt := sin(float(r["slip_t"]) / 0.8 * PI) * 0.25 * (1.0 if int(r["phase"] * 10.0) % 2 == 0 else -1.0) if float(r["slip_t"]) > 0.0 else 0.0
		var want := float(r["lane"]) + wob + jolt
		# the things in the way (the user, 2026-10-18: rivals went straight through the rocks): as
		# one comes up it decides once whether it sees it in time (its tier's dodge); if so it
		# steers to its far side, else it hits it like you would: a bump, slowed, spun round
		var rp := float(r["progress"])
		for oi in _rival_things.size():
			var th: Array = _rival_things[oi]
			var ahead_pts := posmod(int(th[0]) - posmod(int(rp), count), count)
			if ahead_pts > 0 and ahead_pts < 34:
				if not (r["dodge"] as Dictionary).has(oi):
					r["dodge"][oi] = randf() < float(tr["dodge"])
				if r["dodge"][oi]:
					var th_lane: float = th[1]
					var room: float = th[2]
					want = th_lane - signf(th_lane if th_lane != 0.0 else 1.0) * room
		r["lane_now"] = lerpf(float(r["lane_now"]), clampf(want, -0.62, 0.62), minf(1.0, delta * 4.0))
		if not r["done"] and float(r["spin"]) <= 0.0:
			for oi2 in _rival_things.size():
				var th2: Array = _rival_things[oi2]
				if (r["pos"] as Vector2).distance_to(th2[3]) < float(th2[4]):
					r["spin"] = 0.9
					r["slip_t"] = 1.0
					r["dodge"].erase(oi2)
					if (r["pos"] as Vector2).distance_to(car_pos) < 700.0:
						_sfx("res://sounds/fx/wood_tap.wav", -14.0, 0.7)
					break
		if float(r["spin"]) > 0.0:
			r["spin"] = float(r["spin"]) - delta
		if r["progress"] > progress:
			ahead += 1
		# a bump (the cars, the boats; planes keep apart; a finished one is out of the way)
		var d: Vector2 = car_pos - r["pos"]
		if vehicle != "plane" and not r["done"] and d.length() < 46.0 and d.length() > 0.1 and air_t <= 0.0:
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

## A secret's gift on the course, its picture sized to GIFT_SIZE whatever it is (the user,
## 2026-10-18: the stickers showed very big; their pictures aren't all the same size)
const GIFT_SIZE := 64.0
func _gift_sprite(prize: String, pos: Vector2) -> Sprite2D:
	var t: Texture2D = Collection.prize_icon(prize)
	var sp := _px_sprite(t, pos, 2)
	if t:
		var big := maxf(t.get_width(), t.get_height())
		sp.scale = Vector2.ONE * (GIFT_SIZE / maxf(1.0, big))
	return sp

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
	if lettering.say(text, hold):                    # (the racing font, letter by letter)
		banner.modulate.a = 0.0
		return
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

