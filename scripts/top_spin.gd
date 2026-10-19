extends BaseMinigame
## Top Spin (prototype) — your pal rides a spinning top in a bowl stadium. Every match has
## three parts:
##   1. WIND: a needle sweeps round the top; tap MAIN when it's on the gold zone to wind it up.
##      Good pulls wind fast; past 100% the top is over-wound and lands wobbly.
##   2. DROP: tilt to aim, tap MAIN to drop. Landing on a rival gives an opening hit.
##   3. BATTLE: tilt the bowl to steer (it moves the rivals too, less), tap MAIN to DASH (costs
##      spin), hold FORWARD to GUARD (heavy, drains spin). Guarding just as you're hit is a
##      PERFECT guard: the hitter bounces off and you steal some of its spin.
## Spin is your life and your energy. A top is out when it stops spinning or flies out
## through one of the gaps in the rim. Last top spinning wins.
##
## Levels (the level menu): 6 worlds of 9, a match each (no lives: lose and you retry it). Every
## world is its own bowl in its own place, and brings one new thing (from its 7th level the world
## before's joins in):
##   1 Wooden Bowl (a tatami room in the morning sun): the basics · 2 Bumper Bowl (a veranda in a
##   tree's shade): bumpers to bounce off, chargers that flash before they dash (the guard) ·
##   3 Lacquer Tray (a lacquered table by lamplight): wider gaps in the rim, ring-outs · 4 Toilet
##   Bowl (a bathroom in daylight): it FLUSHES halfway, a whirlpool pulling every top to the
##   middle; soap puddles · 5 Clockwork Bowl (a workbench under a hanging lamp): turning gears in
##   the floor carry the tops round · 6 Dragon Festival (a stage at night, lanterns, fireworks):
##   three rivals at once, the phoenix's top.
## Each world's 9th level is its champion. Stars: 1 = win, 2 = win with 40% of your spin left,
## 3 = with 70% left (the band's stars dim as your spin drops). No points.
## Drinks: a SPLASH top comes back once (out of a gap or spun out, it's put back in with some
## spin) · FIZZ: a stronger dash and easier winding · FOCUS: a wider perfect guard, longer
## warnings · STURDY: a heavier top. A world's 6th level hides a golden prize top only the right
## drink can beat (fizzy dashes, focused perfect guards, a sturdy shove out of the rim).
##
## The look (the user, 2026-10-19: the toy games at the race games' quality, one suite; GameFx,
## docs/ideas_roadmap.md "The games' look"): the tops are Beyblade-like, stacked in slices like Pal
## Prix's toys (they lean and wobble), their blade rings turning (slower as the spin runs out, a
## haze behind them when it's strong): the rivals' blades tell how they fight, yours are new in
## every world; ridden by pals (the rivals too: their balls); the bowl is raised (its near rim over the tops), each
## world one place with its own light and something alive in it (TopSpinArt); Pal Prix 2177's
## light and motion for the moments that matter (sparks, shockwaves, light ribbons on a dash,
## glowing guard and warning rings, a shake and a tiny freeze on the big hits); the race games'
## HUD band. Words only for the rare big moments (the chimes and the sparks say the rest).
##
## Desktop: arrows / WASD tilt, Space = MAIN, Shift or X = FORWARD.

const GAME_INDEX := 8

# --- Stadium (play-area coordinates, 950x948; on the 4 px grid) ---
const C_FULL := Vector2(476, 520)     # bowl centre
const R_FULL := 370.0                 # bowl radius (inside the rim; room for the controls below)
const C_TUT := Vector2(476, 620)      # the tutorial's bowl: smaller and lower, so the coach's
const R_TUT := 262.0                  # card above it never covers the action
const PX := 4                         # world px per board pixel
const GAP_HALF := 0.17                # half-width of a rim gap (radians)

# --- Physics ---
const TOP_R := 36.0
const BOWL := 1.3                     # pull towards the centre, px/s² per px
const DRIFT := 140.0                  # tops wander round the bowl on their own
const TILT_ACCEL := 1100.0
const RIVAL_TILT := 0.4               # how much your tilting moves the rivals
const FRICTION := 0.5
const MAX_SPEED := 950.0
const OUT_SPEED := 260.0              # outward speed needed to fly out through a gap
const DECAY := 1.2                    # spin lost per second, always
const BRACE_DRAIN := 3.0
const BRACE_MASS := 3.0
const PERFECT_WINDOW := 0.22
const DASH_SPEED := 700.0
const DASH_COST := 6.0
const DASH_TIME := 0.3
const TILT_GAIN := 2.2
const DEADZONE := 0.04
const INVERT_TILT := false
const WINDUP := 0.5                   # a rival flashes this long before it dashes (time to GUARD)...
const WINDUP_MIN := 0.2               # ...less and less as the levels go up, down to this

# --- Wind-up ---
const WIND_TIME := 6.0
const WIND_START := 20.0
const WIND_MAX := 130.0               # 100+ = over-wound
const WIND_GOOD := 16.0
const WIND_SLIP := 6.0                # a tap off the gold slips the cord: spin lost...
const WIND_JAM := 0.35                # ...and it jams this long (taps do nothing): mashing never pays
const ZONE_HALF := 0.32
const DIAL_R := 172.0                 # the winding dial's radius
const DROP_TIME := 3.5

# --- Look ---
const BG := Color8(58, 66, 84)
const OUTLINE := Color8(40, 30, 40)
const RIM_W := 40.0                   # the rim's width (world px), outside R
const RIM_H := 12.0                   # ...and its height: the far inner wall, the near side face
const BAND := Color8(48, 54, 82)      # the HUD band: Top Spin's indigo lacquer...
const BAND_FOOT := Color8(28, 30, 50) # ...and its foot line
const HUD_TEXT := Color(0.94, 0.95, 1.0)
const GOLD := Color8(240, 196, 80)
const PLAYER_COLOR := Color8(240, 136, 56)
const GUARD_COL := Color8(140, 220, 255)
const WARN_COL := Color8(255, 76, 64)

## Rival styles: how they move and fight (their tops' paint: "color")
const STYLES := {
	"rookie":  { "color": Color8(120, 196, 96), "mass": 0.9, "attack": 0.7, "seek": 0.25, "dash_every": 0.0, "brace": 0.0, "center": 0.0, "size": 1.0 },
	"charger": { "color": Color8(230, 80, 76), "mass": 1.0, "attack": 1.1, "seek": 1.0, "dash_every": 1.8, "brace": 0.0, "center": 0.0, "size": 1.0 },
	"wall":    { "color": Color8(88, 140, 228), "mass": 1.3, "attack": 0.9, "seek": 0.15, "dash_every": 0.0, "brace": 0.6, "center": 1.0, "size": 1.0 },
	"heavy":   { "color": Color8(176, 122, 82), "mass": 1.9, "attack": 1.3, "seek": 0.5, "dash_every": 3.5, "brace": 0.2, "center": 0.3, "size": 1.15 },
	"boss":    { "color": Color8(170, 92, 220), "mass": 1.6, "attack": 1.3, "seek": 0.8, "dash_every": 2.2, "brace": 0.4, "center": 0.2, "size": 1.35 },
}
## Who rides each rival top: pals (their balls, from the pal renderer, at the pal's own scale)
const RIDERS := { "rookie": "kappa", "charger": "karakasa", "wall": "komainu", "heavy": "oo_daruma" }
## Each world's champion (its 9th level), from its place: the moon princess in the tatami room, a
## tengu on the veranda, the nine-tailed fox at the lacquered table, a mermaid in the bathroom, a
## clockwork oni in the workshop, the phoenix at the dragon festival
const CHAMPIONS := ["kaguya", "tengu", "kyubi", "ningyo", "mecha_oni", "hou_ou"]
const SPARE_RIDERS := ["peapod", "daruma", "ramune", "bruin", "nebula_nug"]
## The blade rings (TopSpinArt.BLADES): each rival style's, the same in every world, so its shape
## tells how it fights (light fins, attacking hooks, a round shield, heavy lugs, a champion's
## scythes); yours, new in each world (4 blades, a star, petals, waves, gear teeth, a dragon)
const RIVAL_BLADES := { "rookie": "fins3", "charger": "hooks3", "wall": "shield", "heavy": "lugs4", "boss": "scythe4" }
const PLAYER_BLADES := ["blades4", "star5", "petals6", "wave5", "gear10", "dragon3"]
const PRIZE_BLADES := "petals6"
const SPIN_SHOWN := 7.5               # how fast a top's blades turn at full spin (blades a second: about a frame step every frame)

## The worlds: each its own bowl (floor, grain, rings, rim) in its own place (TopSpinArt's room:
## its surface and its light) and its accent (the band's foot line, the lights in the rim)
const WORLDS := ["Wooden Bowl", "Bumper Bowl", "Lacquer Tray", "Toilet Bowl", "Clockwork Bowl", "Dragon Festival"]
const WORLD_HINTS := ["", "bumpers bounce!", "mind the gaps!", "it flushes!", "the gears turn!", "three at once!"]
const BOWLS := [
	{ # 1 Wooden Bowl: blue-grey turned wood (the prototype's), a tatami room in the morning sun
		"floor": Color8(170, 184, 198), "grain": Color8(154, 170, 188), "light": Color8(186, 198, 210), "lathe": Color8(140, 156, 176),
		"rim": Color8(92, 110, 136), "rim_hi": Color8(128, 146, 172), "rim_dark": Color8(66, 80, 104), "room": "tatami", "menu": Color8(120, 136, 160),
		"accent": Color8(255, 216, 120) },
	{ # 2 Bumper Bowl: honey maple, a red rim, on a veranda in a tree's shade
		"floor": Color8(226, 190, 132), "grain": Color8(208, 168, 112), "light": Color8(240, 210, 156), "lathe": Color8(194, 152, 98),
		"rim": Color8(196, 70, 64), "rim_hi": Color8(232, 112, 96), "rim_dark": Color8(140, 44, 44), "room": "veranda", "menu": Color8(210, 120, 96),
		"accent": Color8(160, 236, 120) },
	{ # 3 Lacquer Tray: black lacquer with gold swirls, a vermilion rim, on a lacquered table by lamplight
		"floor": Color8(52, 44, 52), "grain": Color8(64, 54, 62), "light": Color8(80, 66, 72), "lathe": Color8(112, 90, 54),
		"rim": Color8(196, 60, 52), "rim_hi": Color8(230, 100, 84), "rim_dark": Color8(130, 34, 34), "room": "lacquer", "menu": Color8(110, 52, 56), "swirls": true,
		"accent": Color8(255, 196, 90) },
	{ # 4 Toilet Bowl: white porcelain, pale water in the middle, in a tiled bathroom in daylight
		"floor": Color8(196, 226, 236), "grain": Color8(176, 212, 228), "light": Color8(216, 238, 246), "lathe": Color8(160, 200, 220),
		"rim": Color8(236, 238, 240), "rim_hi": Color8(255, 255, 255), "rim_dark": Color8(186, 194, 206), "room": "bathroom", "menu": Color8(150, 200, 210),
		"accent": Color8(110, 222, 240) },
	{ # 5 Clockwork Bowl: a brass plate, an iron rim with rivets, on a workbench under a hanging lamp
		"floor": Color8(204, 170, 96), "grain": Color8(186, 150, 80), "light": Color8(222, 192, 120), "lathe": Color8(160, 126, 66),
		"rim": Color8(96, 100, 112), "rim_hi": Color8(136, 140, 152), "rim_dark": Color8(64, 66, 78), "room": "workshop", "menu": Color8(160, 130, 80),
		"accent": Color8(255, 170, 70) },
	{ # 6 Dragon Festival: red lacquer and gold scales, a gold rim, on a festival stage at night
		"floor": Color8(124, 36, 44), "grain": Color8(114, 32, 40), "light": Color8(140, 44, 50), "lathe": Color8(156, 58, 56),
		"rim": Color8(226, 178, 70), "rim_hi": Color8(252, 220, 120), "rim_dark": Color8(176, 126, 40), "room": "festival", "menu": Color8(60, 40, 70), "scales": true,
		"accent": Color8(255, 120, 180) },
]
## A world's 9 matches: rivals [style, starting spin], bumpers, puddles, rim gaps. The levels of a
## world follow one pattern (the new thing alone, then pushed, then the world before's joins in,
## then the champion); the spins grow world by world (built in _level_data)
const LINEUPS := [
	[["rookie"], ["rookie"], ["charger"], ["charger"], ["wall"], ["charger"], ["rookie", "charger"], ["charger", "wall"], ["boss"]],
	[["rookie"], ["charger"], ["charger"], ["wall"], ["charger", "rookie"], ["heavy"], ["charger", "charger"], ["heavy", "charger"], ["boss"]],
	[["charger"], ["wall"], ["charger"], ["heavy"], ["charger", "wall"], ["heavy"], ["charger", "heavy"], ["wall", "charger"], ["boss"]],
	[["rookie"], ["charger"], ["wall"], ["heavy"], ["charger", "rookie"], ["charger"], ["heavy", "charger"], ["charger", "wall"], ["boss"]],
	[["charger"], ["wall"], ["heavy"], ["charger", "rookie"], ["charger", "wall"], ["heavy"], ["heavy", "charger"], ["charger", "charger"], ["boss"]],
	[["charger", "rookie"], ["charger", "wall"], ["heavy", "charger"], ["charger", "charger", "rookie"], ["heavy", "wall"], ["charger", "heavy"],
		["charger", "charger", "wall"], ["heavy", "charger", "charger"], ["boss", "charger"]],
]
const STYLE_SPIN := { "rookie": 55.0, "charger": 65.0, "wall": 75.0, "heavy": 85.0, "boss": 120.0 }
## Secrets (a world's 6th level): the golden prize top, and which drink beats it; finales
const SECRETS := {
	15: ["fizzy", "sticker:koma"], 24: ["caffeinated", "decor:koma_lanterns"], 33: ["milky", "sticker:soap"],
	42: ["fizzy", "acc:hachimaki"], 51: ["caffeinated", "sticker:dragon"],
}
const FINALES := { 45: "food:Dragon Oil", 54: "case:spin" }
const FLUSH_EVERY := 16.0             # the Toilet Bowl: seconds between flushes...
const FLUSH_TIME := 4.0               # ...each one this long: a whirlpool to the middle
const GEAR_R := 100.0                 # the Clockwork Bowl: a gear plate's radius...
const GEAR_SPIN := 1.3                # ...and how fast it turns (rad/s), carrying the tops on it

class Top:
	var pos := Vector2.ZERO
	var vel := Vector2.ZERO
	var spin := 100.0
	var r := 36.0
	var mass := 1.0
	var attack := 1.0
	var color := Color.WHITE
	var is_player := false
	var style := ""
	var dir := 1.0                    # spin direction (visual + drift)
	var alive := true
	var braced := false
	var brace_t := 9.0                # seconds since the guard went up
	var brace_hold := 0.0             # (rivals) how long they keep guarding
	var dash_t := 9.0                 # seconds since the last dash
	var dash_cd := 0.0
	var unsteady := 0.0               # over-wound: wobbly, hard to steer
	var ai_t := 0.0
	var windup := 0.0                 # (rivals) about to dash
	var wob := 0.0                    # (a random phase for its wobble)
	var prize := false                # the golden prize top (a secret): not a rival, it never attacks
	var root: TopView

## A top on screen (TopSpinArt.top_parts): its slices stacked bottom first (the tip, the driver,
## the wheel), the blades' side, then the blade ring on top turning frame by frame (a haze behind
## it when it spins fast, light arcs round its edge), the pal set in its middle. It leans (a wobble
## when slow or over-wound, into a dash), squats while guarding, lies down when it falls. Your top
## has a close-up look too, twice as fine (the user, 2026-10-19: the winding's top was too low a
## resolution): shown while it's wound and dropped, the light gathering round it as it's wound
class TopView extends Node2D:
	var look := {}                    # TopSpinArt.top_parts
	var look_hi := {}                 # (yours) the same, twice as fine
	var hi := false                   # drawn from look_hi, twice the size (the node stays at its scale)
	var rider: Texture2D
	var cap_tex: Texture2D            # (the golden top: its prize instead of a rider)
	var cap_px := 44.0
	var angle := 0.0
	var fast := 0.0                   # 0..1 how fast it spins
	var dir := 1.0
	var lean := Vector2.ZERO          # px: the face off the tip
	var squat := 0.0                  # 0..1 guarding
	var fall := 0.0                   # 0..1 toppled
	var fall_dir := Vector2.RIGHT
	var flash := 0.0                  # a hit's flash
	var aura := 0.0                   # 0..1 the winding's light round it...
	var hot := 0.0                    # ...turning red as it's over-wound
	var t := 0.0
	func _look_now() -> Dictionary:
		return look_hi if hi and not look_hi.is_empty() else look
	func _k() -> float:
		return 2.0 if hi and not look_hi.is_empty() else 1.0
	func face_offset() -> Vector2:
		var k := _k()
		var n: int = (_look_now()["slices"] as Array).size() + 1
		var off := Vector2(0, -n * 4.0 * k * (1.0 - 0.5 * squat)) + lean * k
		if fall > 0.0:
			off = off.lerp((fall_dir * n * 7.0 + Vector2(0, -6)) * k, fall)
		return off.snapped(Vector2(4, 4))
	func _draw() -> void:
		var L := _look_now()
		var k := _k()
		var slices: Array = L["slices"]
		var faces: Array = L["faces"]
		var unders: Array = L["unders"]
		var period: float = L["period"]
		var rf: float = L["rf"]
		var blur: Texture2D = L["blur"]
		var arcs: Array = L["arcs"]
		var n := slices.size() + 1                     # (the static slices and the blades' side; the face on top)
		var step := 4.0 * k * (1.0 - 0.5 * squat)
		var fi := int(fposmod(angle, period) / period * faces.size()) % faces.size()
		var face := face_offset()
		if aura > 0.0:
			# the light gathering round it as it's wound (red-hot when over-wound)
			var ac := Color8(255, 222, 120).lerp(Color8(255, 86, 60), hot)
			GameFx.disc(self, face, rf * 4.0 + 20.0 * k, Color(ac.r, ac.g, ac.b, 0.12 * aura))
			GameFx.light_ring(self, face, rf * 4.0 + 12.0 * k, ac, 30, 4.0 * k, 0.65 * aura, -angle * 0.35)
		for kk in n + 1:
			var f := float(kk) / float(n)
			var off := Vector2(0, -kk * step) + lean * k * f
			if fall > 0.0:
				off = off.lerp((fall_dir * kk * 7.0 + Vector2(0, -kk * 1.5)) * k, fall)
			off = off.snapped(Vector2(4, 4))
			var tex: Texture2D = slices[kk] if kk < slices.size() else (unders[fi] if kk == slices.size() else faces[fi])
			if kk == n and fast > 0.0 and blur and fall == 0.0:
				var bsz := blur.get_size() * 4.0                # (spinning hard: a haze between the blades)
				draw_texture_rect(blur, Rect2(off - bsz / 2.0, bsz), false, Color(1, 1, 1, clampf(fast, 0.0, 1.0)))
			var sz := tex.get_size() * 4.0
			draw_texture_rect(tex, Rect2(off - sz / 2.0, sz), false)
		if fast > 0.25 and fall == 0.0 and not arcs.is_empty():
			var ai := int(t * 40.0) % arcs.size()
			if dir < 0.0:
				ai = arcs.size() - 1 - ai
			var at: Texture2D = arcs[ai]
			var asz := at.get_size() * 4.0
			draw_texture_rect(at, Rect2(face - asz / 2.0, asz), false, Color(1, 1, 1, clampf((fast - 0.25) * 1.6, 0.0, 1.0)))
		if flash > 0.0:
			GameFx.disc(self, face, rf * 4.0 - 10.0 * k, Color(1, 1, 1, 0.55 * flash))
		# the pal set right in the middle, its vehicle round it (its face kept upright: it looks at you)
		if rider:
			draw_texture_rect(rider, Rect2(face - Vector2(24, 24) * k, Vector2(48, 48) * k), false)
		elif cap_tex:
			var s := cap_tex.get_size()
			var k2 := cap_px * k / maxf(s.x, s.y)
			draw_texture_rect(cap_tex, Rect2(face - s * k2 / 2.0, s * k2), false)

## A bumper peg on the floor: its slices, bottom first; it flashes and pops up when hit
class PegView extends Node2D:
	var slices: Array[Texture2D] = []
	var flash := 0.0
	var pop := 0.0
	func _process(delta: float) -> void:
		if flash > 0.0 or pop > 0.0:
			flash = maxf(0.0, flash - delta * 4.0)
			pop = maxf(0.0, pop - delta * 5.0)
			queue_redraw()
	func _draw() -> void:
		for k in slices.size():
			var tex := slices[k]
			var up := 4.0 if k == slices.size() - 1 and pop > 0.0 else 0.0
			var sz := tex.get_size() * 4.0
			draw_texture_rect(tex, Rect2(Vector2(0, -k * 4.0 - up) - sz / 2.0, sz), false)
		if flash > 0.0:
			GameFx.disc(self, Vector2(0, -8), 24.0, Color(1, 1, 1, 0.75 * flash))

## The place's living light (drawn added on, over the bowl and the tops): dust in the morning sun,
## flecks of sun through the leaves, glints in the lacquer, light rippling on the water, a lamp
## swaying on its cord, lanterns flickering and the fireworks' flashes at night
class RoomFx extends Node2D:
	var kind := ""
	var c := Vector2.ZERO
	var r := 370.0
	var t := 0.0
	var motes: Array = []             # [position, velocity, phase]
	var flash := 0.0
	var flash_col := Color(1, 1, 1)
	var flash_at := Vector2.ZERO
	var next_flash := 4.0
	const W := 950.0
	const H := 948.0
	func setup(k: String, centre: Vector2, radius: float) -> void:
		kind = k
		c = centre
		r = radius
		motes.clear()
		var n: int = { "tatami": 30, "veranda": 18, "lacquer": 12, "workshop": 22, "festival": 16 }.get(k, 0)
		for i in n:
			motes.append([Vector2(randf() * W, randf() * H), Vector2(randf_range(-4.0, 10.0), randf_range(-16.0, -4.0)), randf() * TAU])
		flash = 0.0
		next_flash = randf_range(3.0, 6.0)
	func _process(delta: float) -> void:
		t += delta
		for m in motes:
			m[0] += (m[1] as Vector2) * delta + Vector2(sin(t * 0.7 + m[2]) * 6.0, 0) * delta
			if m[0].y < 90.0:
				m[0] = Vector2(randf() * W, H)
			if m[0].x > W:
				m[0].x = 0.0
		if kind == "festival":
			next_flash -= delta
			if next_flash <= 0.0:
				next_flash = randf_range(4.0, 8.0)
				flash = 1.0
				flash_col = [Color8(255, 120, 180), Color8(255, 210, 110), Color8(120, 220, 255), Color8(170, 255, 140)][randi() % 4]
				flash_at = Vector2(randf_range(0.0, W), randf_range(-100.0, 200.0))
			flash = maxf(0.0, flash - delta * 1.6)
		queue_redraw()
	func _draw() -> void:
		match kind:
			"tatami":
				# dust drifting through the slanting sun (only where the sun falls)
				for m in motes:
					var p: Vector2 = m[0]
					var into := clampf(1.0 - absf(p.x + p.y * 0.55 - W * 0.42) / (W * 0.22), 0.0, 1.0)
					if into > 0.2:
						var a := (0.22 + 0.18 * sin(t * 2.0 + m[2])) * into
						draw_rect(Rect2(GameFx.snap(p), Vector2(4, 4)), Color(1, 0.95, 0.8, a))
			"veranda":
				# flecks of sun through the leaves, breathing as the leaves move
				for m in motes:
					var p2: Vector2 = GameFx.snap((m[0] as Vector2) * Vector2(1, 0) + Vector2(0, fposmod(m[2] * 150.0, H)) + Vector2(sin(t * 0.5 + m[2]) * 10.0, 0))
					var a2 := maxf(0.0, sin(t * 1.1 + m[2] * 3.0)) * 0.22
					draw_rect(Rect2(p2 - Vector2(4, 4), Vector2(8, 8)), Color(1, 0.96, 0.75, a2))
					draw_rect(Rect2(p2 - Vector2(8, 0), Vector2(16, 4)), Color(1, 0.96, 0.75, a2 * 0.4))
			"lacquer":
				# the lamp's pool breathing, glints of gold in the lacquer
				var k := 0.03 + 0.012 * sin(t * 1.7) + 0.006 * sin(t * 7.3)
				GameFx.disc(self, c, r * 0.95, Color(1, 0.8, 0.5, k))
				for m in motes:
					var on := sin(t * 1.6 + m[2] * 5.0)
					if on > 0.8:
						var q: Vector2 = GameFx.snap(Vector2(fposmod(m[2] * 977.0, W), fposmod(m[2] * 613.0, H)))
						var a3 := (on - 0.8) * 4.0
						draw_rect(Rect2(q - Vector2(2, 2), Vector2(4, 4)), Color(1, 0.85, 0.45, a3))
						draw_rect(Rect2(q - Vector2(6, 2), Vector2(12, 4)), Color(1, 0.85, 0.45, a3 * 0.4))
						draw_rect(Rect2(q - Vector2(2, 6), Vector2(4, 12)), Color(1, 0.85, 0.45, a3 * 0.4))
			"bathroom":
				# light rippling on the water in the middle of the bowl
				for ring in 4:
					var rr := 40.0 + ring * 28.0
					for k2 in 18:
						var a4 := k2 * TAU / 18.0 + t * (0.4 + ring * 0.12) * (1.0 if ring % 2 == 0 else -1.0)
						var wob := sin(a4 * 3.0 + t * 2.2) * 6.0
						var q2 := GameFx.snap(c + Vector2.from_angle(a4) * (rr + wob))
						var al := 0.1 + 0.08 * sin(a4 * 2.0 + t * 3.0)
						draw_rect(Rect2(q2, Vector2(8, 4)), Color(0.85, 1.0, 1.0, al))
			"workshop":
				# the hanging lamp sways on its cord: its pool of light moves a little; dust in it
				var lc := c + Vector2(sin(t * 0.8) * 26.0, cos(t * 0.8) * 6.0)
				GameFx.disc(self, lc, r * 0.8, Color(1, 0.86, 0.6, 0.035))
				GameFx.disc(self, lc, r * 0.5, Color(1, 0.86, 0.6, 0.03))
				for m in motes:
					var p3: Vector2 = m[0]
					if p3.distance_to(lc) < r * 0.85:
						draw_rect(Rect2(GameFx.snap(p3), Vector2(4, 4)), Color(1, 0.9, 0.7, 0.18 + 0.12 * sin(t * 2.0 + m[2])))
			"festival":
				# the lanterns' warm light flickering round the stage, a firework's flash now and then
				for i in 4:
					var lp := Vector2([90.0, 860.0, 120.0, 830.0][i], [150.0, 170.0, 900.0, 880.0][i])
					var fl := 0.05 + 0.02 * sin(t * 9.0 + i * 1.7) + 0.015 * sin(t * 23.0 + i)
					GameFx.disc(self, lp, 150.0, Color(1, 0.6, 0.3, fl))
					GameFx.disc(self, lp, 70.0, Color(1, 0.7, 0.4, fl))
				if flash > 0.0:
					draw_rect(Rect2(0, 0, W, H), Color(flash_col.r, flash_col.g, flash_col.b, 0.1 * flash))
					GameFx.disc(self, flash_at, 360.0, Color(flash_col.r, flash_col.g, flash_col.b, 0.07 * flash))
				for m in motes:
					var p4: Vector2 = m[0]
					draw_rect(Rect2(GameFx.snap(p4), Vector2(4, 4)), Color(1, 0.6, 0.3, 0.3 + 0.2 * sin(t * 5.0 + m[2])))

enum Phase { WIND, DROP, BATTLE, RESULT }
var C := C_FULL                       # (the bowl in use: full size, or the tutorial's)
var R := R_FULL
## First-time tutorial: one step at a time, each waits until you've done it
enum Tut { NONE, WIND, DROP, MOVE, DASH, DASHED, GUARD, GUARDED, FIGHT }

var phase := Phase.WIND
var level := 1
var loop := 0                         # (the old endless mode's laps: 0 with the level menu)
var time := 0.0
var world := 0
var bowl: Dictionary = BOWLS[0]
var match_t := 0.0                    # this match's time (the flush's clock, the best time)
var gears: Array = []                 # the Clockwork Bowl: { pos, angle }
var flush_in := 0.0                   # the Toilet Bowl: seconds to the next flush
var flushing := 0.0                   # ...and how long the whirlpool still pulls
var swirl_a := 0.0                    # (the whirlpool's turn)
var backdrop: Sprite2D                # the place round the bowl
var prize_top: Top = null             # the secret's golden top (null = none on this level)
var secret := {}
var splash_used := false
var fizz := 0                         # this match's boosts: their levels (0 = none)
var focus := 0
var sturdy := 0
var boost_icon: TextureRect
var gap_half := GAP_HALF              # (wider in the Lacquer Tray)

var tops: Array[Top] = []
var player: Top
var bumpers: Array[Vector2] = []
var bumper_views: Array[PegView] = []
var slimes: Array[Vector2] = []
var gap_angles: Array[float] = []
var perfects := 0

# wind-up
var wind_spin := WIND_START
var wind_left := WIND_TIME
var needle := 0.0
var zone := 0.0
var combo := 0
var wind_jam := 0.0
var needle_trail: Array[float] = []   # (the needle's last angles: its comet tail)
# drop
var aim := C_FULL
var drop_left := 0.0
var dropping := false
var lift := 1.0                       # 0 → 1: the top rising from the winding spot into the drop pose

var forward_held := false
var _touch_mode := false              # phone: buttons come from _input, not the emulated mouse
var _guard_touch := -1                # the finger holding GUARD
var tut := Tut.NONE
var practice := false                 # this match is the tutorial's (no level, it doesn't count)
var tut_good := 0                     # good pulls while learning to wind
var tut_dist := 0.0                   # how far you've rolled while learning to tilt
var tut_count := 0                    # successes in the current step (two each)
var tut_counted := false              # this dash / attack has been counted
var bar_flash := 0.0                  # your spin bar blinks (the tutorial points at it)
var hint_main: HBoxContainer          # control legend: main button + what it does now
var hint_fwd: HBoxContainer           # ...and the forward button

# the layers (bottom to top): the place, the bowl, the floor's things, scuffs, dash ribbons, the
# tops and pegs (sorted by depth), the near rim, the rim's lights, bursts, the place's light, the
# rings and the dial; all in `scene` (it shakes), then the HUD band over it
var scene: Node2D
var stadium: Sprite2D                 # the bowl's floor (the tops' plane: it stays put)
var stadium_rim: Sprite2D             # the rim's far half (under the tops)...
var stadium_front: Sprite2D           # ...and its near half (over them)
var floor_layer: Node2D
var marks: GameFx.Burst
var trails: GameFx.Burst
var top_nodes: Node2D
var rim_fx: Node2D
var fx: GameFx.Burst
var room_fx: RoomFx
var dim_layer: Node2D                 # (while winding: the bowl dimmed...)
var held: Node2D                      # (...under your top, held up while it's wound and dropped)
var overlay: Node2D
var hud: Node2D
var hud_level: Label
var hud_stars: Array[TextureRect] = []
var _stars_shown := 3
var band_bar: ColorRect
var banner: Label
var lives_box: HBoxContainer
var lcd_font: Font
var ball_texture: Texture2D
var shake := 0.0
var hitstop := 0.0
var whir: AudioStreamPlayer           # your top's whir (tools/audio/top_sounds.py)
var _bowl_cache := {}

func _ready() -> void:
	game_music_path = "res://sounds/music/Pixel Battle.ogg"     # (100 BPM, loops on the beat: 0.163 s → 127.363 s)
	lcd_font = load("res://fonts/pixChicago.ttf")
	ball_texture = PalBall.texture()
	_create_static_nodes()
	if GameData.intro_seen(GAME_INDEX):
		intro_text = "Wind it up, drop it, knock them out!"
		intro_icon = TopSpinArt.top_icon(PLAYER_COLOR, TOP_R / PX + 1.5, PLAYER_BLADES[0], ball_texture)
	else:
		tut = Tut.WIND                     # first time: a short tutorial instead of the card
	super._ready()

# --- the level menu (BaseMinigame) ---

func uses_levels() -> bool:
	return true

func world_names() -> Array:
	return WORLDS

func level_count() -> int:
	return WORLDS.size() * GameData.LEVELS_PER_WORLD

func level_pattern() -> Texture2D:
	return load("res://textures/menus/pattern_top_slate.png")

func level_backdrop() -> Color:
	return BOWLS[0]["menu"]

func world_backdrop(w: int) -> Color:
	return BOWLS[clampi(w, 0, BOWLS.size() - 1)]["menu"]

func secrets() -> Dictionary:
	var out := {}
	for lvl in SECRETS:
		out[lvl] = { "gate": SECRETS[lvl][0], "lvl": 1 + clampi((lvl - 1) / GameData.LEVELS_PER_WORLD, 0, 5) / 2, "prize": SECRETS[lvl][1] }
	return out

func finale_prizes() -> Dictionary:
	return FINALES

func fail_title() -> String:
	return "Knocked out!"

func start_game() -> void:
	super.start_game()
	level = 1
	lives = LIVES
	loop = 0
	_start_match()

## Chosen in the level menu (or NEXT / RETRY): the first time ever, level 1 starts with the
## tutorial's practice match
func play_level(n: int) -> void:
	super.start_game()
	level = clampi(n, 1, level_count())
	loop = 0
	tut = Tut.WIND if (n == 1 and not GameData.intro_seen(GAME_INDEX)) else Tut.NONE
	_start_match()
	var k := (level - 1) % GameData.LEVELS_PER_WORLD
	if not practice:
		if k == 0:
			_show_banner(WORLDS[world], 1.2)
			if WORLD_HINTS[world] != "":
				_after(1.5, func(): _show_banner(WORLD_HINTS[world], 1.0))
		else:
			_show_banner("%d-%d" % [world + 1, k + 1], 0.8)

# ================================================================== MATCH SETUP

## A level's match, from its world and its place in the world (see LINEUPS): the world's new
## thing alone at first, then more of it; from the 7th level the world before's joins in
func _level_data() -> Dictionary:
	var w := clampi((level - 1) / GameData.LEVELS_PER_WORLD, 0, WORLDS.size() - 1)
	var k := (level - 1) % GameData.LEVELS_PER_WORLD
	var mix := k >= 6
	var grow := 1.0 + 0.1 * w + 0.03 * k
	var rivals := []
	for st in LINEUPS[w][k]:
		rivals.append([st, STYLE_SPIN[st] * grow])
	var bumpers := []
	var slime := []
	var gear_at := []
	var gaps := 3
	var wide := false
	var flush := false
	if w == 1 or (w == 2 and mix) or w == 5:
		bumpers = [Vector2(-170, -60), Vector2(170, -60)]
		if k >= 3:
			bumpers.append(Vector2(0, -210))
		if k >= 6:
			bumpers.append_array([Vector2(-190, 140), Vector2(190, 140)])
	if w == 2 or (w == 3 and mix):
		gaps = 4 if k < 4 else 5
		wide = true
	if w == 3 or (w == 4 and mix):
		flush = true
		if k >= 2:
			slime = [Vector2(-150, 120), Vector2(160, 90)]
	if w == 4 or (w == 5 and mix):
		gear_at = [Vector2(-165, -30), Vector2(170, 70)]
		if k >= 4:
			gear_at.append(Vector2(0, 205))
	if k == GameData.LEVELS_PER_WORLD - 1:
		gaps = 2                                      # (the champion's ring: fewer ways out)
	return { "rivals": rivals, "bumpers": bumpers, "slime": slime, "gaps": gaps, "wide": wide, "flush": flush, "gears": gear_at }

func _start_match() -> void:
	loop = 0
	C = C_TUT if tut != Tut.NONE else C_FULL         # (the tutorial's bowl is smaller and lower)
	R = R_TUT if tut != Tut.NONE else R_FULL
	world = clampi((level - 1) / GameData.LEVELS_PER_WORLD, 0, WORLDS.size() - 1)
	bowl = BOWLS[world if tut == Tut.NONE else 0]
	var data := _level_data()
	gap_half = GAP_HALF * (1.3 if data.get("wide", false) else 1.0)
	bumpers.clear()
	for b in data["bumpers"]:
		bumpers.append(C + b)
	slimes.clear()
	for s in data["slime"]:
		slimes.append(C + s)
	gap_angles.clear()
	var n: int = data["gaps"]
	if tut != Tut.NONE:
		n = 0                                        # the tutorial bowl has no gaps: nobody flies out
	for i in n:
		gap_angles.append(PI / 2.0 + i * TAU / n)
	_paint_scene(data)
	# the Clockwork Bowl's gears, the Toilet Bowl's flush
	gears.clear()
	if tut == Tut.NONE:
		for gp in data.get("gears", []):
			gears.append({ "pos": C + gp, "angle": randf() * TAU })
	flush_in = 10.0 if data.get("flush", false) and tut == Tut.NONE else -1.0
	flushing = 0.0
	match_t = 0.0
	for v in bumper_views:
		v.queue_free()
	bumper_views.clear()
	var pegs := TopSpinArt.peg_slices(bowl)
	for b in bumpers:
		var pv := PegView.new()
		pv.slices = pegs
		pv.position = GameFx.snap(b)
		top_nodes.add_child(pv)
		bumper_views.append(pv)

	for t in tops:
		if is_instance_valid(t.root):
			t.root.queue_free()
	tops.clear()
	player = _make_top(true, "", PLAYER_COLOR)
	player.pos = C
	tops.append(player)
	var rivals: Array = data["rivals"]
	for i in rivals.size():
		var st: Dictionary = STYLES[rivals[i][0]]
		var o := _make_top(false, rivals[i][0], st["color"])
		o.spin = float(rivals[i][1]) * (1.0 + 0.15 * loop)
		var a := -PI / 2.0 + 0.5 + i * TAU / maxf(rivals.size(), 2)
		o.pos = C + Vector2.from_angle(a) * R * 0.57
		tops.append(o)

	# this match's boosts (the level of each: a passive boost is used by the match it helped)
	fizz = PetState.boost_power("fizz") if tut == Tut.NONE else 0
	focus = PetState.boost_power("focus") if tut == Tut.NONE else 0
	sturdy = PetState.boost_power("sturdy") if tut == Tut.NONE else 0
	splash_used = false
	if sturdy > 0:
		player.mass *= 1.0 + 0.3 * sturdy
	_refresh_boost_icon()
	# the secret's golden top
	prize_top = null
	secret = secret_of(level) if tut == Tut.NONE else {}
	if not secret.is_empty() and not secret["taken"]:
		prize_top = _make_top(false, "rookie", GOLD)
		prize_top.prize = true
		prize_top.mass = 6.0 if secret["gate"] == "milky" else 2.2
		prize_top.attack = 0.0
		prize_top.spin = 100.0
		prize_top.root.rider = null
		prize_top.root.cap_tex = Collection.prize_icon(secret["prize"])
		prize_top.pos = C + Vector2(0, R * 0.45)
		tops.append(prize_top)
	perfects = 0
	wind_spin = WIND_START
	wind_left = WIND_TIME
	needle = 0.0
	needle_trail.clear()
	zone = randf() * TAU
	combo = 0
	phase = Phase.WIND
	dropping = false
	forward_held = false
	player.root.hi = true                            # (the close-up: twice the size, twice as fine)
	player.root.scale = Vector2.ONE
	player.root.position = C - player.root.face_offset()   # (its face right in the dial's middle: the user)
	practice = tut != Tut.NONE
	calibrate_tilt()                                 # (the 3D tilt's level, until the drop sets the steering's)
	var per := GameData.LEVELS_PER_WORLD
	hud_level.text = "TUTORIAL" if practice else "%d-%d" % [(level - 1) / per + 1, (level - 1) % per + 1]
	hud_level.add_theme_font_size_override("font_size", 22 if practice else 32)
	for i in hud_stars.size():
		hud_stars[i].visible = not practice
		hud_stars[i].texture = UiArt.star(i < 1)    # (what the winding's first spin gives: one)
	_stars_shown = 1
	_set_legend("PULL", "DONE")
	_refresh_lives()
	if tut == Tut.WIND:
		show_coach("Press when the needle is on GOLD", 0, "FORWARD: skip tutorial")

## The place and the bowl for this match (the bowl's pictures kept per world, size and ways out)
func _paint_scene(data: Dictionary) -> void:
	var key := "%d_%s_%d_%s_%s" % [world if tut == Tut.NONE else 0, R, gap_angles.size(), gap_half, data["slime"]]
	if not _bowl_cache.has(key):
		var rel: Array = []
		for s in slimes:
			rel.append(s - C)
		var imgs := TopSpinArt.bowl_images(bowl, R, RIM_W, RIM_H, gap_angles, gap_half, rel)
		# the world's light over the bowl too (like the place under it)
		for img: Image in imgs:
			var half := img.get_width() / 2.0
			for y in img.get_height():
				for x in img.get_width():
					var c: Color = img.get_pixel(x, y)
					if c.a > 0.0:
						var bp := C / PX + Vector2(x - half, y - half)
						img.set_pixel(x, y, TopSpinArt.lit(bowl["room"], c, bp, int(PLAY_WIDTH / PX) + 1, int(PLAY_HEIGHT / PX) + 1))
		_bowl_cache[key] = [ImageTexture.create_from_image(imgs[0]), ImageTexture.create_from_image(imgs[1]), ImageTexture.create_from_image(imgs[2])]
	stadium.texture = _bowl_cache[key][0]
	stadium_rim.texture = _bowl_cache[key][1]
	stadium_front.texture = _bowl_cache[key][2]
	stadium.position = C
	stadium_rim.position = C
	stadium_front.position = C
	var bw := int(PLAY_WIDTH / PX) + 1
	var bh := int(PLAY_HEIGHT / PX) + 1
	backdrop.texture = ImageTexture.create_from_image(TopSpinArt.room_image(bowl["room"], bw, bh, C / PX, (R + RIM_W) / PX))
	room_fx.setup(bowl["room"], C, R)
	band_bar.color = bowl["accent"]

func _make_top(is_player: bool, style: String, color: Color) -> Top:
	var t := Top.new()
	t.is_player = is_player
	t.style = style
	t.color = color
	t.wob = randf() * TAU
	t.dir = 1.0 if randf() < 0.5 else -1.0
	var size := 1.0
	if not is_player:
		var st: Dictionary = STYLES[style]
		t.mass = st["mass"]
		t.attack = st["attack"]
		size = st["size"]
	t.r = TOP_R * size
	var v := TopView.new()
	var rf := t.r / PX + 1.5                         # (the blades' tips a little past its round: the circle is about their mean reach)
	var kind: String = PLAYER_BLADES[world if tut == Tut.NONE else 0] if is_player else (PRIZE_BLADES if color == GOLD else String(RIVAL_BLADES.get(style, "fins3")))
	v.look = TopSpinArt.top_parts(color, rf, kind)
	if is_player:
		v.look_hi = TopSpinArt.top_parts(color, rf * 2.0, kind, TopSpinArt.SEAT_R * 2.0)
	v.rider = ball_texture if is_player else _rider(style)
	v.dir = t.dir
	(held if is_player else top_nodes).add_child(v)
	t.root = v
	return t

## The pal riding a rival's top (a champion: its world's own); never the same as yours
func _rider(style: String) -> Texture2D:
	var id: String = CHAMPIONS[world] if style == "boss" else String(RIDERS.get(style, "classic"))
	if PetState.has_poop() and id == PetState.form_id:
		id = SPARE_RIDERS[(world + style.length()) % SPARE_RIDERS.size()]
	var path := "res://textures/minigames/balls/%s.png" % id
	return load(path) if ResourceLoader.exists(path) else ball_texture

# ================================================================== LOOP

func _process(delta: float) -> void:
	overlay.queue_redraw()
	dim_layer.queue_redraw()
	floor_layer.queue_redraw()
	rim_fx.queue_redraw()
	hud.queue_redraw()
	# a shake on the big hits (the HUD stays put)
	shake = maxf(0.0, shake - delta * 3.0)
	scene.position = Vector2(randi_range(-1, 1), randi_range(-1, 1)) * 4.0 * ceilf(shake * 2.0) if shake > 0.0 else Vector2.ZERO
	_depth_3d()
	_update_whir(delta)
	if not is_running:
		return
	time += delta
	bar_flash = maxf(0.0, bar_flash - delta)
	if hitstop > 0.0:
		hitstop -= delta                             # (a tiny freeze on a big hit: everything holds)
		return
	if qa_autopilot:
		_qa_play(delta)
	match phase:
		Phase.WIND:
			_wind_step(delta)
		Phase.DROP:
			_drop_step(delta)
		Phase.BATTLE:
			_battle_step(delta)
	_animate_tops(delta)
	_update_legend()
	_update_hud()

func _wind_step(delta: float) -> void:
	needle = fposmod(needle + (2.6 + wind_spin * 0.025) * (0.8 if tut == Tut.WIND else 1.0) * delta, TAU)
	needle_trail.push_front(needle)
	if needle_trail.size() > 6:
		needle_trail.pop_back()
	wind_jam = maxf(0.0, wind_jam - delta)
	if tut != Tut.WIND:
		wind_left -= delta
	player.spin = wind_spin
	if wind_left <= 0.0:
		_begin_drop()

func _wind_pull() -> void:
	if wind_jam > 0.0:
		return                                         # (still jammed from a slip)
	var off := absf(angle_difference(needle, zone))
	var tip := C + Vector2.from_angle(needle) * DIAL_R
	if off >= ZONE_HALF:
		combo = 0
		wind_jam = WIND_JAM
		wind_spin = maxf(WIND_START, wind_spin - WIND_SLIP)
		_sfx("res://sounds/fx/click-5.mp3", -12.0, 0.0, 0.6)
		fx.puff(tip, 8, Color8(120, 110, 130), 0.6)      # (the cord slips: a grey puff, the dial goes red)
		fx.flash(tip, 20.0, WARN_COL)
		_kick(0.15)
		Input.vibrate_handheld(40)
		return                                         # (the gold zone stays put: try again)
	var gain := 0.0
	if off < ZONE_HALF:
		combo += 1
		gain = WIND_GOOD + combo * 2.0 + 3.0 * fizz
		_sfx("res://sounds/fx/click-6.mp3", -12.0, 0.0, 1.0 + combo * 0.08)
		_sfx("res://sounds/fx/top_zip.wav", -10.0, 0.0, 0.92 + combo * 0.06)      # (the ripcord zipping out)
		fx.sparks(tip, 8 + mini(combo, 5) * 2, [GOLD, Color(1, 1, 1), Color8(255, 236, 160)], 0.8)
		fx.ring(tip, GOLD, 10.0, 56.0 + combo * 6.0, 0.3, 6.0)
		# the top takes it: a jolt, sparks flung off its blades, a ring of light off it
		player.root.flash = 0.5
		var jolt := create_tween()
		jolt.tween_property(player.root, "scale", Vector2(1.08, 1.08), 0.05)
		jolt.tween_property(player.root, "scale", Vector2.ONE, 0.14)
		for k in 10:
			var a := TAU * k / 10.0 + randf() * 0.3
			fx.spray(C + Vector2.from_angle(a) * 80.0, Vector2.from_angle(a + PI / 2.0 * player.dir), 1, [GOLD, Color(1, 1, 1)], 0.3, 1.2)
		fx.ring(C, Color8(255, 222, 120), 70.0, 150.0 + combo * 8.0, 0.3, 6.0)
		_kick(0.08 + 0.02 * mini(combo, 5))
		if tut == Tut.WIND:
			tut_good += 1
			if tut_good == 1:
				show_coach("Yes! Every gold press = more spin", 0)
			elif tut_good == 3:
				show_coach("Spin is your life. Ready!")
				_after(1.3, func():
					if phase == Phase.WIND:
						_begin_drop())
	wind_spin = minf(WIND_MAX, wind_spin + gain)
	Input.vibrate_handheld(15)
	# the gold zone jumps somewhere else
	zone = fposmod(needle + randf_range(1.4, TAU - 1.4), TAU)

func _begin_drop() -> void:
	phase = Phase.DROP
	player.spin = minf(wind_spin, 100.0)
	player.unsteady = maxf(0.0, wind_spin - 100.0) * 0.06     # over-wound: wobbly landing
	drop_left = DROP_TIME
	aim = C
	calibrate_tilt()
	# it rises smoothly from where it was wound (no jump): lift goes 0 → 1
	lift = 0.0
	create_tween().tween_property(self, "lift", 1.0, 0.35).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	_set_legend("DROP", "")
	if tut == Tut.WIND:
		tut = Tut.DROP
		show_coach("Tilt to aim, then press to DROP", 0)
	if wind_spin > 100.0:
		_show_banner("OVER-WOUND!", 0.8)

func _drop_step(delta: float) -> void:
	if dropping:
		return
	aim += _read_tilt() * 520.0 * delta
	var off := aim - C
	if off.length() > R - 80.0:
		aim = C + off.limit_length(R - 80.0)
	player.root.scale = Vector2.ONE * lerpf(1.0, 0.8, lift)
	# (it rises from the dial's middle, where its face was, into the drop pose over its shadow)
	var centred := -player.root.face_offset() * player.root.scale.x * (1.0 - lift)
	player.root.position = GameFx.snap(aim + Vector2(0, -110.0 * lift) + centred)
	if tut != Tut.DROP:
		drop_left -= delta
	if drop_left <= 0.0:
		_drop()

func _drop() -> void:
	if dropping:
		return
	dropping = true
	_sfx("res://sounds/fx/claw_drop.wav", -12.0)
	var t := create_tween()
	t.tween_property(player.root, "position", GameFx.snap(aim), 0.3).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_QUAD)
	t.parallel().tween_property(player.root, "scale", Vector2(0.5, 0.5), 0.3).set_ease(Tween.EASE_IN)
	t.tween_callback(_land)

func _land() -> void:
	if not is_running:
		return
	player.pos = aim
	player.vel = Vector2.ZERO
	player.root.reparent(top_nodes, false)          # (down among the others, its normal look)
	player.root.hi = false
	player.root.scale = Vector2.ONE
	player.root.aura = 0.0
	_sfx("res://sounds/fx/wood_tap.wav", -10.0, 0.0, 0.7)
	Input.vibrate_handheld(40)
	# it lands: a ring of dust, a shockwave across the floor
	marks.dust(aim, 12, (bowl["floor"] as Color).darkened(0.25), 1.2)
	fx.ring(aim, Color(1, 1, 1), 24.0, 120.0, 0.35, 6.0)
	_kick(0.25)
	for o in tops:
		if o == player:
			continue
		var d := o.pos - player.pos
		if d.length() < (player.r + o.r) * 1.3:
			o.spin -= 12.0
			o.vel += d.normalized() * 520.0
			# an opening hit: a big burst says it
			var at := player.pos + d * 0.5
			fx.sparks(at, 18, [Color(1, 1, 1), GOLD, o.color, PLAYER_COLOR], 1.2)
			fx.ring(at, GOLD, 16.0, 150.0, 0.4, 8.0)
			fx.flash(at, 40.0)
			o.root.flash = 1.0
			_kick(0.5, 0.08)
			_sfx("res://sounds/fx/pin_bumper.wav", -6.0)
	phase = Phase.BATTLE
	_set_legend("DASH", "GUARD")
	if tut == Tut.DROP:
		tut = Tut.MOVE
		tut_dist = 0.0
		show_coach("Tilt the phone to roll around")
	else:
		_show_banner("GO!", 0.5)

# ================================================================== BATTLE

func _battle_step(delta: float) -> void:
	var tilt := _read_tilt()
	var learning := _learning()
	match_t += delta
	# the Toilet Bowl: now and then it flushes (a whirlpool pulls every top to the middle)
	if flush_in > 0.0:
		flush_in -= delta
		if flush_in <= 0.0:
			flushing = FLUSH_TIME
			flush_in = FLUSH_EVERY
			_show_banner("FLUSH!", 0.6)
			_sfx("res://sounds/fx/water-pouring-98795.mp3", -10.0, 1.6)
			Input.vibrate_handheld(40)
	if flushing > 0.0:
		flushing = maxf(0.0, flushing - delta)
		swirl_a -= delta * 4.0
	for g in gears:
		g["angle"] = float(g["angle"]) + GEAR_SPIN * delta
	if tut == Tut.MOVE:
		tut_dist += player.vel.length() * delta
		if tut_dist > 700.0:
			tut = Tut.DASH
			show_coach("Press to DASH into it!", 0)
	for t in tops:
		if not t.alive:
			continue
		t.brace_t += delta
		t.dash_t += delta
		t.dash_cd = maxf(0.0, t.dash_cd - delta)
		t.unsteady = maxf(0.0, t.unsteady - delta)
		if t.dash_t < DASH_TIME + 0.05:
			# a dash: a light ribbon behind it, its tip scoring the floor
			trails.ribbon(t.pos + Vector2(0, -12), t.color, 0.3, 16.0)
			marks.scuff(t.pos, Color(0.12, 0.06, 0.14, 0.22), 2.2)
		if t.windup > 0.0:                         # the warning's over: here it comes
			t.windup -= delta
			if t.windup <= 0.0 and player.alive:
				_dash(t, player.pos - t.pos + player.vel * 0.15)
		if t.prize:
			_prize_think(t, delta)
		elif not t.is_player:
			if tut == Tut.GUARD:
				_tut_attack(t, delta)
			elif not learning:
				_rival_think(t, delta)
		if learning:
			t.spin = maxf(t.spin, 40.0)               # nobody gets knocked out while learning
			continue
		if not t.prize:
			t.spin -= (DECAY + (BRACE_DRAIN if t.braced else 0.0)) * delta
		for s in slimes:
			if t.pos.distance_to(s) < 70.0:
				t.spin -= 7.0 * delta
		if t.spin < 18.0 and randf() < delta * 4.0:
			fx.spray(t.pos, Vector2.from_angle(randf() * TAU), 3, [GOLD, Color(1, 1, 1)], 0.6, 0.5)   # (a slow top scrapes its tip)
	const STEPS := 3
	var dt := delta / STEPS
	for i in STEPS:
		for t in tops:
			if t.alive:
				_move_top(t, tilt, dt)
		for a in tops.size():
			for b in range(a + 1, tops.size()):
				if tops[a].alive and tops[b].alive:
					_collide(tops[a], tops[b])
	for t in tops:
		if tut != Tut.NONE and (t.is_player or _learning()):
			t.spin = maxf(t.spin, 25.0)               # nobody loses while learning; you never do in the tutorial
		if t.alive and t.spin <= 0.0:
			_topple(t)
	_check_match_end()

func _move_top(t: Top, tilt: Vector2, dt: float) -> void:
	var m := t.mass * (BRACE_MASS if t.braced else 1.0)
	var off := t.pos - C
	var acc := -off * BOWL
	if off.length() > 1.0:
		acc += Vector2(-off.y, off.x).normalized() * DRIFT * t.dir * clampf(t.spin / 100.0, 0.2, 1.0)
	var steer := TILT_ACCEL * (1.0 if t.is_player else RIVAL_TILT)
	if tut == Tut.GUARD or tut == Tut.GUARDED:
		steer = 0.0                                  # (learning to guard: you hold still, it comes to you)
	if t.is_player and t.unsteady > 0.0:
		steer *= 0.3
	acc += tilt * steer / m
	if not t.is_player:
		if tut == Tut.GUARD:
			# keeps a short run-up away from you, then the attack
			var to := player.pos - t.pos
			if t.windup <= 0.0 and t.dash_t > DASH_TIME:
				var want := 210.0 - to.length()
				acc += -to.normalized() * clampf(want * 6.0, -500.0, 500.0) / m
		elif not _learning():
			acc += _rival_accel(t) / m
	if t.unsteady > 0.0 or t.spin < 20.0:
		acc += Vector2.from_angle(time * 9.0 + t.wob) * 600.0          # wobbling about
	if flushing > 0.0 and off.length() > 1.0:
		# the whirlpool: in towards the middle and round with the water
		acc += -off.normalized() * 520.0 + Vector2(off.y, -off.x).normalized() * 380.0
	for g in gears:
		var go: Vector2 = t.pos - g["pos"]
		if go.length() < GEAR_R:
			# on a gear plate: carried round with it
			t.vel += Vector2(-go.y, go.x) * GEAR_SPIN * 2.2 * dt
	if t.prize:
		acc += (C - t.pos) * 0.8                        # (the golden top keeps to the middle)
	t.vel += acc * dt
	t.vel *= maxf(0.0, 1.0 - (FRICTION + (2.5 if t.braced else 0.0)) * dt)
	for s in slimes:
		if t.pos.distance_to(s) < 70.0:
			t.vel *= maxf(0.0, 1.0 - 2.5 * dt)
	t.vel = t.vel.limit_length(MAX_SPEED)
	t.pos += t.vel * dt

	# the rim: bounce, or fly out through a gap if fast enough
	off = t.pos - C
	var r_lim := R - 6.0 - t.r
	if off.length() > r_lim:
		var n := off.normalized()
		var vn := t.vel.dot(n)
		if _in_gap(n.angle()) and vn > OUT_SPEED:
			_ring_out(t)
			return
		t.pos = C + n * r_lim
		if vn > 0.0:
			t.vel -= 1.55 * vn * n
			if vn > 150.0:
				_sfx("res://sounds/fx/wood_tap.wav", -18.0, 0.0, 1.3)
				# off the rim: chips of light, a scrape on the floor
				fx.spray(t.pos + n * t.r, -n, int(clampf(vn / 90.0, 3, 8)), [Color(1, 1, 1), bowl["rim_hi"]], 0.8, 0.7)
				marks.scuff(t.pos, Color(0.12, 0.06, 0.14, 0.2), 1.6)

	for i in bumpers.size():
		var b := bumpers[i]
		var d := t.pos - b
		var l := d.length()
		var lim := t.r + 28.0
		if l < lim and l > 0.001:
			var bn := d / l
			t.pos = b + bn * lim
			var bvn := t.vel.dot(bn)
			if bvn < 0.0:
				t.vel -= 2.0 * bvn * bn
				t.vel += bn * 260.0
				_sfx("res://sounds/fx/pin_bumper.wav", -14.0)
				# the peg lights up and pops, a ring of light off it
				if i < bumper_views.size():
					bumper_views[i].flash = 1.0
					bumper_views[i].pop = 1.0
				fx.ring(b + Vector2(0, -8), bowl["accent"], 24.0, 70.0, 0.25, 6.0)
				fx.spray(b + bn * 28.0, bn, 5, [Color(1, 1, 1), bowl["accent"]], 0.7, 0.8)

func _in_gap(angle: float) -> bool:
	for g in gap_angles:
		if absf(angle_difference(angle, g)) < gap_half:
			return true
	return false

func _collide(a: Top, b: Top) -> void:
	var d := b.pos - a.pos
	var dist := d.length()
	var lim := a.r + b.r
	if dist >= lim or dist < 0.001:
		return
	var n := d / dist
	var ma := a.mass * (BRACE_MASS if a.braced else 1.0)
	var mb := b.mass * (BRACE_MASS if b.braced else 1.0)
	var inv := 1.0 / ma + 1.0 / mb
	var overlap := lim - dist
	a.pos -= n * overlap * (1.0 / ma) / inv
	b.pos += n * overlap * (1.0 / mb) / inv
	var vrel := (b.vel - a.vel).dot(n)
	if vrel >= 0.0:
		return
	var j := -1.95 * vrel / inv
	a.vel -= n * j / ma
	b.vel += n * j / mb
	var impact := -vrel
	var dmg_a := _damage(impact, b, a)
	var dmg_b := _damage(impact, a, b)
	# the golden prize top: only the right drink's way hurts it (and it never hurts you)
	if a.prize or b.prize:
		var pz := a if a.prize else b
		var other := b if a.prize else a
		if pz == a:
			dmg_b = 0.0
		else:
			dmg_a = 0.0
		var hurt := 0.0
		if other.is_player and secret.get("gate", "") == "fizzy" and other.dash_t < DASH_TIME:
			hurt = 36.0 if gate_open("fizzy", secret["lvl"]) else 0.0
			if hurt == 0.0:
				_float_text("a fizzy dash would hurt it!", pz.pos + Vector2(0, -80))
		if pz == a:
			dmg_a = hurt
		else:
			dmg_b = hurt
	# PERFECT guard: the guard went up just before the hit (a focused top: a wider window)
	var window := PERFECT_WINDOW * (1.0 + 0.6 * focus)
	var was_perfect := false
	if a.braced and a.brace_t < window:
		dmg_a = 0.0
		dmg_b += 10.0
		a.spin += 6.0
		b.vel += n * 520.0
		_perfect(a, b)
		was_perfect = true
	elif b.braced and b.brace_t < window:
		dmg_b = 0.0
		dmg_a += 10.0
		b.spin += 6.0
		a.vel -= n * 520.0
		_perfect(b, a)
		was_perfect = true
	a.spin -= dmg_a
	b.spin -= dmg_b
	if a.is_player or b.is_player:
		_tut_hit(a.brace_t < PERFECT_WINDOW if a.is_player else b.brace_t < PERFECT_WINDOW)
	if impact > 80.0:
		# the clash: sparks both ways along the hit, a ring of light, the tops flash; a big one
		# shakes the bowl and holds the moment
		var at := a.pos + n * a.r
		var k := clampf(impact / 600.0, 0.2, 1.0)
		var cols := [Color(1, 1, 1), GOLD, a.color.lightened(0.3), b.color.lightened(0.3)]
		var tang := Vector2(-n.y, n.x)
		fx.spray(at, tang, int(4 + 8 * k), cols, 0.7, 0.8 + 0.6 * k)
		fx.spray(at, -tang, int(4 + 8 * k), cols, 0.7, 0.8 + 0.6 * k)
		fx.ring(at, Color(1, 1, 1), 10.0, 40.0 + 70.0 * k, 0.25, 6.0)
		a.root.flash = maxf(a.root.flash, k)
		b.root.flash = maxf(b.root.flash, k)
		var involved := a.is_player or b.is_player
		if not was_perfect:
			_kick(0.12 + 0.4 * k * (1.0 if involved else 0.5), 0.05 if k > 0.6 and involved else 0.0)
		_sfx("res://sounds/fx/pin_bumper.wav", clampf(-26.0 + impact / 40.0, -24.0, -4.0), 0.0, randf_range(0.9, 1.15))
		if involved:
			Input.vibrate_handheld(int(clampf(impact / 15.0, 10, 60)))

## Spin the `to` top loses when `from` hits it: harder hits, dashes and stronger spin hurt
## more; guarding takes most of it
func _damage(impact: float, from: Top, to: Top) -> float:
	var dmg := impact * 0.012 * from.attack
	if from.dash_t < DASH_TIME:
		dmg *= 1.8
	if to.braced:
		dmg *= 0.45
	return dmg * clampf(from.spin / maxf(to.spin, 1.0), 0.6, 1.6)

func _perfect(guard: Top, hitter: Top) -> void:
	_sfx("res://sounds/fx/gamecoin.wav", -8.0)
	# the golden top (focus): a PERFECT guard against it is what wears it down
	if hitter.prize and guard.is_player and secret.get("gate", "") == "caffeinated":
		if gate_open("caffeinated", secret["lvl"]):
			hitter.spin -= 50.0
		else:
			_float_text("too quick! a focused top could!", hitter.pos + Vector2(0, -80))
	# a perfect guard says itself: a white shockwave off the shield, gold sparkles, the moment held
	var at := guard.pos + Vector2(0, -12)
	fx.ring(at, Color(1, 1, 1), guard.r + 10.0, guard.r + 130.0, 0.4, 8.0)
	fx.ring(at, GUARD_COL, guard.r + 4.0, guard.r + 70.0, 0.3, 6.0)
	fx.sparkle(at, 12, Color8(255, 236, 150), 1.1)
	guard.root.flash = 1.0
	if guard.is_player:
		perfects += 1
		_kick(0.3, 0.09)
	elif hitter.is_player:
		_kick(0.2, 0.05)

func _dash(t: Top, dir: Vector2) -> void:
	if t.dash_cd > 0.0 or dir == Vector2.ZERO or t.spin <= DASH_COST:
		return
	dir = dir.normalized()
	var sp := DASH_SPEED * ((1.0 + 0.15 * fizz) if t.is_player else 1.0)
	t.vel = dir * maxf(t.vel.dot(dir), 0.0) * 0.3 + dir * sp
	t.spin -= DASH_COST
	t.dash_t = 0.0
	t.dash_cd = 0.45
	fx.puff(t.pos - dir * t.r, 6, Color(1, 1, 1), 0.5)       # (a push off the floor)
	if t.is_player:
		tut_counted = false
		_sfx("res://sounds/fx/pin_flipper.wav", -10.0)
		Input.vibrate_handheld(20)

func _player_dash() -> void:
	var tilt := _read_tilt()
	if tilt.length() > 0.35:
		_dash(player, tilt)                            # dash where you lean...
		return
	var best: Top = null
	for o in tops:                                     # ...or at the nearest rival
		if o != player and o.alive and (best == null or o.pos.distance_to(player.pos) < best.pos.distance_to(player.pos)):
			best = o
	if best:
		_dash(player, best.pos - player.pos)

# ================================================================== RIVALS

func _rival_accel(t: Top) -> Vector2:
	var st: Dictionary = STYLES[t.style]
	var acc := Vector2.ZERO
	if player.alive:
		acc += (player.pos - t.pos).normalized() * 520.0 * float(st["seek"]) * (1.0 + 0.15 * loop)
	acc += (C - t.pos) * 1.2 * float(st["center"])
	if t.style == "rookie":
		acc += Vector2.from_angle(time * 0.7 + t.wob) * 200.0
	return acc

func _rival_think(t: Top, delta: float) -> void:
	var st: Dictionary = STYLES[t.style]
	if not player.alive:
		return
	var to := player.pos - t.pos
	var d := to.length()
	t.ai_t += delta
	var every: float = st["dash_every"]
	if every > 0.0 and t.ai_t >= every / (1.0 + 0.15 * loop) and d < 320.0:
		t.windup = _windup_time()                    # flashes first, then dashes
		t.ai_t = randf() * 0.6
	# guard when the player comes in fast
	if t.braced:
		t.brace_hold -= delta
		if t.brace_hold <= 0.0:
			t.braced = false
	elif float(st["brace"]) > 0.0 and d < 170.0:
		var approach := (player.vel - t.vel).dot(-to / maxf(d, 1.0))
		if approach > 200.0 and randf() < float(st["brace"]) * delta * 8.0:
			t.braced = true
			t.brace_t = 0.0
			t.brace_hold = 0.5

# ================================================================== TUTORIAL

## The steps where nobody can lose yet (the rival waits for you)
func _learning() -> bool:
	return tut in [Tut.MOVE, Tut.DASH, Tut.DASHED, Tut.GUARD, Tut.GUARDED]

## (Learning to guard) the rival comes for you every couple of seconds, with its warning
func _tut_attack(t: Top, delta: float) -> void:
	t.ai_t += delta
	var d := t.pos.distance_to(player.pos)
	if t.windup <= 0.0 and t.dash_t > 0.8 and t.ai_t > 1.4 and d > 130.0 and d < 330.0:
		t.windup = WINDUP + 0.25                     # (a longer warning while learning)
		t.ai_t = 0.0
		tut_counted = false

## A hit between you and the rival, during the tutorial. Each step wants it TWICE (a dash or an
## attack counts once, however many times it bumps)
func _tut_hit(perfect: bool) -> void:
	if tut == Tut.DASH and player.dash_t < DASH_TIME and not tut_counted:
		tut_counted = true
		tut_count += 1
		if tut_count == 1:
			show_coach("Nice hit! Do it again", 0)
		else:
			tut = Tut.DASHED
			bar_flash = 2.5
			show_coach("Cool! But each dash costs spin: watch your bar")
			_after(2.6, func():
				tut = Tut.GUARD
				tut_count = 0
				show_coach("Its turn! When it flashes, HOLD to GUARD", 1))
	elif tut == Tut.GUARD and not tut_counted and tops[1].dash_t < DASH_TIME + 0.1:
		tut_counted = true
		if not player.braced:
			show_coach("Too late! HOLD GUARD before it hits you", 1)
			return
		tut_count += 1
		if tut_count == 1:
			show_coach("PERFECT! Once more" if perfect else "Blocked! Again (guard right AS it hits = PERFECT)", 1)
		else:
			tut = Tut.GUARDED
			show_coach("PERFECT GUARD! It bounced off" if perfect else "Great guarding!")
			_after(2.2, func():
				tut = Tut.FIGHT
				player.spin = maxf(player.spin, 80.0)         # a fresh, short real fight
				for o in tops:
					if o != player:
						o.spin = 55.0
				show_coach("Now knock it out!", 0)
				_after(2.0, hide_coach))

func _finish_tutorial() -> void:
	tut = Tut.NONE
	GameData.mark_intro_seen(GAME_INDEX)
	hide_coach()

## How long a rival's warning flash lasts: long at first, shorter as the levels go up
func _windup_time() -> float:
	var k := (level - 1) % GameData.LEVELS_PER_WORLD + clampi((level - 1) / GameData.LEVELS_PER_WORLD, 0, 5) * 2
	return maxf(WINDUP_MIN, WINDUP - 0.03 * k) + 0.12 * focus

# ================================================================== OUT / RESULT

func _topple(t: Top) -> void:
	if t.is_player and _splash_save():
		return
	t.alive = false
	t.spin = 0.0
	t.braced = false
	_sfx("res://sounds/fx/clack.mp3", -10.0, 0.0, 0.7)
	# it tips over and lies down (its slices fanning out), a puff of dust; it greys and fades
	var v := t.root
	v.fall_dir = t.vel.normalized() if t.vel.length() > 20.0 else Vector2.from_angle(randf() * TAU)
	v.squat = 0.0
	var tw := create_tween()
	tw.tween_property(v, "fall", 1.0, 0.3).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tw.parallel().tween_property(v, "modulate", Color(0.6, 0.6, 0.66, 1), 0.3)
	tw.tween_property(v, "modulate:a", 0.0, 0.8).set_delay(0.6)
	_after(0.3, func():
		marks.dust(t.pos + v.fall_dir * 20.0, 10, (bowl["floor"] as Color).darkened(0.3), 1.0)
		_kick(0.15))
	if t.prize:
		_win_prize(t)
	elif not t.is_player:
		_float_text("SPUN OUT!", t.pos + Vector2(0, -70))

func _ring_out(t: Top) -> void:
	if t.is_player and _splash_save():
		return
	t.alive = false
	t.braced = false
	_sfx("res://sounds/fx/sfx_sounds_falling4.wav", -12.0, 0.8)
	# out through the gap: off the bowl's edge, tumbling down to the floor, a puff at the gap
	var out := t.pos + (t.pos - C).normalized() * 140.0
	var v := t.root
	v.fall_dir = (t.pos - C).normalized()
	fx.puff(t.pos + (t.pos - C).normalized() * t.r, 10, Color(1, 1, 1), 0.8)
	fx.ring(t.pos, bowl["accent"], 20.0, 90.0, 0.3, 6.0)
	_kick(0.3)
	var tw := create_tween()
	tw.tween_property(v, "position", GameFx.snap(out), 0.45)
	tw.parallel().tween_property(v, "scale", Vector2(0.5, 0.5), 0.45)
	tw.parallel().tween_property(v, "fall", 0.7, 0.45)
	tw.parallel().tween_property(v, "modulate:a", 0.0, 0.45)
	if t.prize:
		_win_prize(t)
	elif not t.is_player:
		_float_text("RING OUT!", t.pos + Vector2(0, -70))

func _check_match_end() -> void:
	var rivals_left := tops.filter(func(t): return t != player and not t.prize and t.alive)
	if not player.alive or rivals_left.is_empty():
		if tut != Tut.NONE:
			_finish_tutorial()
	if not player.alive:
		phase = Phase.RESULT
		_show_banner("KNOCKED OUT", 1.2)
		_after(1.6, func():
			_spend_boosts()
			finish_level(level, 0))                     # (the result card: RETRY / LEVELS)
		return
	if not rivals_left.is_empty():
		return
	phase = Phase.RESULT
	player.braced = false
	if practice:                                  # the tutorial's done: now the real level 1
		_sfx("res://sounds/fx/unlock_ding.wav", -8.0)
		_show_banner("TUTORIAL DONE!", 1.2)
		_after(1.8, func():
			_start_match()
			_show_banner("1-1", 0.8))
		return
	var spin_left := player.spin
	var stars := 1 + (1 if spin_left >= 40.0 else 0) + (1 if spin_left >= 70.0 else 0)
	_sfx("res://sounds/fx/unlock_ding.wav", -8.0)
	Input.vibrate_handheld(60)
	_show_banner("WIN!", 1.0)
	# the last one standing: confetti over the bowl, sparkles round your top
	fx.sparkle(player.pos + Vector2(0, -16), 16, Color8(255, 236, 150), 1.4)
	fx.ring(player.pos + Vector2(0, -16), bowl["accent"], 30.0, 180.0, 0.5, 8.0)
	for i in 3:
		fx.confetti(Vector2(160.0 + i * 316.0, 140.0), 14, [bowl["accent"], GOLD, Color(1, 1, 1), PLAYER_COLOR])
	_after(1.6, func():
		_spend_boosts()
		finish_level(level, stars, match_t))

## A splashy top's comeback: back in the bowl with some spin (once a match; the boost is spent)
func _splash_save() -> bool:
	if splash_used or PetState.boost_power("splash") <= 0 or practice:
		return false
	splash_used = true
	PetState.use_boost()
	_refresh_boost_icon()
	player.pos = C + (player.pos - C).limit_length(R * 0.3)
	player.vel = Vector2.ZERO
	player.spin = maxf(player.spin, 30.0 + 10.0 * PetState.boost_level)
	player.root.position = GameFx.snap(player.pos)
	_show_banner("SPLASH!", 0.6)
	fx.puff(player.pos, 14, Color8(170, 220, 255), 1.0)
	fx.ring(player.pos, Color8(110, 200, 255), 20.0, 140.0, 0.4, 8.0)
	fx.sparkle(player.pos, 10, Color8(200, 240, 255))
	_sfx("res://sounds/fx/water_boing.wav", -8.0)
	return true

## The golden top is beaten: its prize (a secret, once)
func _win_prize(t: Top) -> void:
	_float_text("THE GOLDEN TOP!", t.pos + Vector2(0, -70))
	fx.sparkle(t.pos, 18, GOLD, 1.3)
	if not secret.is_empty() and not secret.get("taken", false):
		secret["taken"] = true
		if secret["gate"] in ["fizzy", "caffeinated", "milky"] and PetState.boost == DrinkLibrary.boost_of(secret["gate"]):
			PetState.use_boost()
		take_secret(level)
	_refresh_boost_icon()

## The golden top: it keeps to the middle and, for a focus secret, comes at you now and then
## (a perfect guard wears it down)
func _prize_think(t: Top, delta: float) -> void:
	t.spin = minf(t.spin, 100.0)
	if secret.get("gate", "") == "caffeinated" and player.alive:
		t.ai_t += delta
		if t.ai_t > 2.4 and t.windup <= 0.0:
			t.windup = _windup_time() + 0.2
			t.ai_t = 0.0

## The passive boosts (fizz, focus, sturdy) did their job this match: used up
func _spend_boosts() -> void:
	var b := PetState.boost
	if (b == "fizz" and fizz > 0) or (b == "focus" and focus > 0) or (b == "sturdy" and sturdy > 0):
		PetState.use_boost()
	fizz = 0
	focus = 0
	sturdy = 0
	_refresh_boost_icon()

func _refresh_boost_icon() -> void:
	if not boost_icon:
		return
	var b := PetState.boost
	boost_icon.visible = b in ["splash", "fizz", "focus", "sturdy"]
	if boost_icon.visible:
		boost_icon.texture = PetState.boost_icon(b)

## (a tween, so it goes away with the game if it's closed in the meantime). While the game
## is paused (the how-to card is up) it waits, instead of being lost
func _after(secs: float, f: Callable) -> void:
	var t := create_tween()
	t.tween_interval(secs)
	t.tween_callback(func():
		if is_game_over:
			return
		if not is_running:
			_after(0.1, f)
			return
		f.call())

# ================================================================== VISUALS

## What the two buttons do right now ("" = nothing: hidden)
func _set_legend(main_text: String, fwd_text: String) -> void:
	for pair in [[hint_main, main_text], [hint_fwd, fwd_text]]:
		var box: HBoxContainer = pair[0]
		(box.get_child(1) as Label).text = pair[1]
		box.visible = pair[1] != ""
		box.size = box.get_combined_minimum_size()
	hint_fwd.position.x = PLAY_WIDTH - 72 - hint_fwd.size.x          # (clear of the rounded corners)

## DASH dims while it recharges (or you're too low on spin); GUARD lights up while held
func _update_legend() -> void:
	if phase != Phase.BATTLE or not player:
		hint_main.modulate = Color.WHITE
		hint_fwd.modulate = Color.WHITE
		return
	var can_dash := player.dash_cd <= 0.0 and player.spin > DASH_COST
	hint_main.modulate = Color(1, 1, 1, 1.0 if can_dash else 0.35)
	hint_fwd.modulate = Color(0.75, 0.9, 1.4) if player.braced else Color.WHITE

## Your top's whir (a seamless loop, the race toys' motors' way): it climbs as you wind and sinks
## as the spin runs down, quiet, under the music; it fades out when the top's out or the match is
## over (the user, 2026-10-19: more sense of intensity)
func _update_whir(delta: float) -> void:
	var on := is_running and player != null and player.alive and phase != Phase.RESULT
	if not on:
		if whir.playing:
			whir.volume_db = move_toward(whir.volume_db, -60.0, delta * 90.0)
			if whir.volume_db <= -59.0:
				whir.stop()
		return
	if not whir.playing:
		whir.volume_db = -44.0
		whir.pitch_scale = 0.6
		whir.play()
	var k := clampf(player.spin / 100.0, 0.0, 1.3)
	whir.pitch_scale = lerpf(whir.pitch_scale, 0.55 + 0.8 * k, minf(1.0, delta * 8.0))
	whir.volume_db = lerpf(whir.volume_db, lerpf(-38.0, -22.0, minf(k, 1.0)), minf(1.0, delta * 6.0))

## The 3D tilt (the user, 2026-10-19: like the iPhone's 3D photos, as in Pal Prix): tilting the
## phone shifts the layers by their depth, the floor and the tops still (so what you see is where
## they are): the place below the bowl one way, the raised rim (and the dust in the air, the
## lights on the rim) the other; measured from the pose at the match's start and again at the
## drop (the steering's), smoothed; off with DEPTH_3D. Pixels per full tilt, on the screen:
const DEPTH_3D := true
const DEPTH_FAR := 16.0
const DEPTH_NEAR := 8.0
var _depth_tilt := Vector2.ZERO
var qa_depth_tilt := Vector2.ZERO      # (tools/qa depth=x,y: a pretend tilt, the Mac has no sensor)
func _depth_3d() -> void:
	var want := qa_depth_tilt
	if DEPTH_3D and has_tilt_sensor() and phase != Phase.RESULT:
		want = device_tilt().limit_length(0.6) / 0.6
	_depth_tilt = _depth_tilt.lerp(want, 0.12)
	var far := (_depth_tilt * DEPTH_FAR).round()
	var near := (-_depth_tilt * DEPTH_NEAR).round()
	backdrop.position = far
	stadium_rim.position = C + near
	stadium_front.position = C + near
	rim_fx.position = near
	room_fx.position = near

## QA only (tools/qa sets it): plays by itself to check the levels and the effects: winds on the
## gold, drops on a rival, dashes at the nearest one now and then, guards when one flashes
var qa_autopilot := false
var _qa_t := 0.0
func _qa_play(delta: float) -> void:
	_qa_t -= delta
	match phase:
		Phase.WIND:
			if wind_jam <= 0.0 and absf(angle_difference(needle, zone)) < ZONE_HALF * 0.5:
				_wind_pull()
			if wind_spin >= 96.0:
				_forward_down()
				_forward_up()
		Phase.DROP:
			if not dropping:
				var best: Top = null
				for o in tops:
					if o != player and o.alive and (best == null or o.pos.distance_to(C) < best.pos.distance_to(C)):
						best = o
				if best:
					aim = C + (best.pos - C).limit_length(R - 80.0)
				_drop()
		Phase.BATTLE:
			if not player.alive:
				return
			var threat := false
			for o in tops:
				if o != player and o.alive and o.windup > 0.0 and o.windup < 0.22:
					threat = true
			if threat and not player.braced:
				player.braced = true
				player.brace_t = 0.0
			elif not threat and player.braced and player.brace_t > 0.35:
				player.braced = false
			if not player.braced and _qa_t <= 0.0 and player.spin > 20.0:
				_player_dash()
				_qa_t = randf_range(0.7, 1.2)

## A small shake (and a tiny freeze) for a big moment
func _kick(amount: float, freeze := 0.0) -> void:
	shake = maxf(shake, amount)
	hitstop = maxf(hitstop, freeze)

## The tops on screen: turning, leaning (a wobble when slow or over-wound, into a dash), squatting
## while guarding, lit by the place where they are
func _animate_tops(delta: float) -> void:
	var bw := PLAY_WIDTH / PX
	var bh := PLAY_HEIGHT / PX
	for t in tops:
		if not is_instance_valid(t.root):
			continue
		var v := t.root
		var spinning := t.alive or phase == Phase.WIND
		v.t += delta
		if spinning:
			v.angle += float(v.look["period"]) * SPIN_SHOWN * clampf(t.spin / 90.0, 0.07, 1.0) * delta * t.dir
		v.fast = clampf((t.spin - 30.0) / 50.0, 0.0, 1.0) * 0.65 if spinning else 0.0
		if t == player and phase == Phase.WIND:
			v.aura = clampf(wind_spin / 100.0, 0.0, 1.0)
			v.hot = clampf((wind_spin - 100.0) / 30.0, 0.0, 1.0)
		v.flash = maxf(0.0, v.flash - delta * 5.0)
		if t.alive and (phase == Phase.BATTLE or (t != player and phase != Phase.RESULT)):
			v.position = GameFx.snap(t.pos)
		# a slow or over-wound top wobbles round (it precesses), the pal riding it rocking
		var w := clampf((25.0 - t.spin) / 25.0, 0.0, 1.0) + minf(t.unsteady, 1.0)
		if not t.alive:
			w = 0.0
		var want := Vector2.from_angle(time * (5.0 + 5.0 * w) * t.dir + t.wob) * 16.0 * minf(w, 1.0)
		if t.alive and t.dash_t < DASH_TIME and t.vel.length() > 10.0:
			want += t.vel.normalized() * 8.0                                  # (leaning into a dash)
		if t == player and phase == Phase.WIND and wind_spin > 100.0:
			want = Vector2(randf_range(-1, 1), randf_range(-1, 1)) * 4.0 * v.hot   # (over-wound: it rattles)
		v.lean = v.lean.lerp(want, minf(1.0, delta * 14.0))
		v.squat = move_toward(v.squat, 1.0 if t.braced else 0.0, delta * 10.0)
		v.self_modulate = TopSpinArt.light_at(bowl["room"], t.pos / PX, int(bw), int(bh))
		v.queue_redraw()

## Under the tops: their shadows (and the pegs'), the gears turning, the flush's whirlpool, the
## soap's bubbles, the drop's target
func _draw_floor() -> void:
	var f := floor_layer
	for g in gears:
		var a: float = g["angle"]
		var tex := TopSpinArt.gear(GEAR_R, int(fposmod(a, TAU / 12.0) / (TAU / 12.0) * 6.0) % 6)
		var sz := tex.get_size() * PX
		f.draw_texture_rect(tex, Rect2(GameFx.snap(g["pos"]) - sz / 2.0, sz), false)
	for s in slimes:
		for k in 5:
			var ph := fposmod(time * 0.6 + k * 0.37, 1.0)
			var q := GameFx.snap(s + Vector2.from_angle(k * 2.4 + 0.7) * (16.0 + k * 9.0))
			var br := 4.0 + roundf(ph * 3.0) * 4.0
			if ph < 0.92:
				f.draw_rect(Rect2(q - Vector2(br, br) / 2.0, Vector2(br, br)), Color(1, 1, 1, 0.5))
				f.draw_rect(Rect2(q - Vector2(br, br) / 2.0, Vector2(4, 4)), Color(1, 1, 1, 0.9))
			else:
				GameFx.light_ring(f, q, br, Color(1, 1, 1), 6, 4.0, 0.6)
	if flushing > 0.0:
		_draw_whirlpool(f, clampf(flushing, 0.0, 1.0))
	for b in bumpers:
		_shadow(f, b, 26.0, 0.3)
	for t in tops:
		if not t.alive or not is_instance_valid(t.root):
			continue
		if phase == Phase.WIND and t == player:
			continue
		var at := t.pos
		var k := 1.0
		if t == player and phase == Phase.DROP:
			at = aim
			k = 1.0 - 0.55 * clampf((aim.y - t.root.position.y) / 110.0, 0.0, 1.0)
		_shadow(f, at, t.r * k, 0.32 * k)
	if phase == Phase.DROP and not dropping:
		# where it will land: a ring of light on the floor
		var p := 0.5 + 0.5 * sin(time * 8.0)
		GameFx.light_ring(f, aim, TOP_R + 10.0 + p * 8.0, GOLD, 20, 6.0, 0.9, time)
		f.draw_rect(Rect2(GameFx.snap(aim) - Vector2(4, 4), Vector2(8, 8)), Color(GOLD, 0.8))

## A soft shadow on the floor, down and right of a thing (the light is top-left): an oval in rows
func _shadow(ci: CanvasItem, at: Vector2, r: float, a: float) -> void:
	var c := at + Vector2(8, 10)
	var y := -r * 0.62
	while y <= r * 0.62:
		var half := r * 1.05 * sqrt(maxf(0.0, 1.0 - (y / (r * 0.62)) * (y / (r * 0.62))))
		ci.draw_rect(Rect2(GameFx.snap(c + Vector2(-half, y)), Vector2(maxf(4.0, roundf(half * 2.0 / 4.0) * 4.0), 4)), Color(0.06, 0.03, 0.12, a))
		y += 4.0

## The flush (the Toilet Bowl): the water turning, foam arms spiralling in to a pulsing eye
func _draw_whirlpool(ci: CanvasItem, a: float) -> void:
	var rr := R * 0.8
	GameFx.disc(ci, C, rr * 0.6, Color(0.2, 0.42, 0.56, 0.12 * a))
	GameFx.disc(ci, C, rr * 0.3, Color(0.12, 0.3, 0.44, 0.18 * a))
	for arm in 4:
		for k in 30:
			var rad := 20.0 + k * (rr / 30.0)
			var ang := swirl_a + arm * TAU / 4.0 + rad * 0.012
			var q := GameFx.snap(C + Vector2.from_angle(ang) * rad)
			var al := a * (1.0 - float(k) / 30.0) * 0.8
			ci.draw_rect(Rect2(q - Vector2(6, 6), Vector2(12, 12)), Color(0.9, 0.97, 1.0, al * 0.5))
			ci.draw_rect(Rect2(q - Vector2(4, 4), Vector2(8, 8)), Color(0.95, 1.0, 1.0, al))
	var eye := 12.0 + 4.0 * roundf(sin(time * 6.0))
	GameFx.disc(ci, C, eye + 4.0, Color(0.06, 0.16, 0.26, 0.6 * a))

## The lights in the rim at each way out (the world's accent, gently pulsing; red and blinking
## while a top is close to it: careful!)
func _draw_rim_fx() -> void:
	var lip := C - Vector2(0, RIM_H)
	for g in gap_angles:
		var mouth := C + Vector2.from_angle(g) * R
		var near := false
		for t in tops:
			if t.alive and t.pos.distance_to(mouth) < 150.0:
				near = true
		for sd in [-1.0, 1.0]:
			var p := lip + Vector2.from_angle(g + sd * gap_half * 1.2) * (R + RIM_W * 0.5)
			var col: Color = WARN_COL if near else bowl["accent"]
			var a := (0.55 + 0.45 * sin(time * 2.5 + g)) if not near else (1.0 if int(time * 8.0) % 2 == 0 else 0.4)
			GameFx.glow(rim_fx, p, 8.0, col, a)

func _draw_overlay() -> void:
	if not is_running and not is_game_over and not intro_active():
		return
	if phase == Phase.WIND:
		_draw_dial()
	elif phase == Phase.BATTLE:
		for t in tops:
			if not t.alive:
				continue
			var at := t.pos + Vector2(0, -14)
			if t.braced:                              # GUARD: a shield of light (white = the PERFECT window)
				var fresh := t.brace_t < PERFECT_WINDOW * (1.0 + 0.6 * focus)
				var col := Color(1, 1, 1) if fresh else GUARD_COL
				GameFx.light_ring(overlay, at, t.r + 14.0, col, 22, 8.0 if fresh else 6.0, 0.7 + 0.3 * sin(time * 12.0), time * 2.0 * t.dir)
			if t.windup > 0.0:                        # about to DASH: a ring of red light and its "!"
				var on := fmod(t.windup, 0.16) < 0.08
				GameFx.light_ring(overlay, at, t.r + 22.0, WARN_COL if on else Color8(255, 200, 80), 22, 8.0, 1.0, -time * 3.0)
				GameFx.outlined_text(overlay, lcd_font, at + Vector2(0, -t.r - 58 + (4 if on else 0)), "!", 48, WARN_COL)

## While winding: the bowl and the rivals dimmed, your top held up bright over them
func _draw_dim() -> void:
	if phase != Phase.WIND or (not is_running and not is_game_over and not intro_active()):
		return
	dim_layer.draw_rect(Rect2(0, GameFx.HUD_BAND.end.y, PLAY_WIDTH, PLAY_HEIGHT - GameFx.HUD_BAND.end.y), Color(0.04, 0.03, 0.1, 0.42))

## The winding dial round your top: a dark track, the gold zone glowing, the needle a comet; red
## while the cord is jammed, hot as it gets over-wound; the pulls in a row as pips under it
func _draw_dial() -> void:
	var o := overlay
	var jam := wind_jam > 0.0
	var hot := clampf((wind_spin - 100.0) / 30.0, 0.0, 1.0)
	var track := Color8(64, 70, 104).lerp(Color8(150, 70, 60), hot)
	if jam:
		track = Color8(170, 50, 50)
	const N := 120
	for k in N:
		var p := GameFx.snap(C + Vector2.from_angle(k * TAU / N) * DIAL_R)
		o.draw_rect(Rect2(p - Vector2(10, 10), Vector2(20, 20)), OUTLINE)
	for k in N:
		var a := k * TAU / N
		var p := GameFx.snap(C + Vector2.from_angle(a) * DIAL_R)
		var col := track
		if absf(angle_difference(a, zone)) < ZONE_HALF and not jam:
			col = GOLD.lerp(Color(1, 1, 1), 0.25 + 0.25 * sin(time * 10.0))
		o.draw_rect(Rect2(p - Vector2(6, 6), Vector2(12, 12)), col)
		if k % 6 == 0:
			var q := GameFx.snap(C + Vector2.from_angle(a) * (DIAL_R + 24.0))
			o.draw_rect(Rect2(q - Vector2(2, 2), Vector2(4, 4)), Color(1, 1, 1, 0.5))
	# the gold zone's glow
	if not jam:
		for k in 7:
			var a2 := zone + (k - 3) * ZONE_HALF / 3.0
			var q2 := GameFx.snap(C + Vector2.from_angle(a2) * DIAL_R)
			o.draw_rect(Rect2(q2 - Vector2(16, 16), Vector2(32, 32)), Color(GOLD.r, GOLD.g, GOLD.b, 0.16))
	# the needle: its comet tail, then the head (a bar across the track)
	for i in range(needle_trail.size() - 1, 0, -1):
		var qa := GameFx.snap(C + Vector2.from_angle(needle_trail[i]) * DIAL_R)
		var al := 0.6 * (1.0 - float(i) / needle_trail.size())
		o.draw_rect(Rect2(qa - Vector2(6, 6), Vector2(12, 12)), Color(1, 1, 1, al) if not jam else Color(1, 0.4, 0.3, al))
	var head := Color(1, 1, 1) if not jam else WARN_COL
	for k2 in range(-6, 7):
		var q3 := GameFx.snap(C + Vector2.from_angle(needle) * (DIAL_R + k2 * 4.0))
		o.draw_rect(Rect2(q3 - Vector2(6, 6), Vector2(12, 12)), OUTLINE)
	for k3 in range(-5, 6):
		var q4 := GameFx.snap(C + Vector2.from_angle(needle) * (DIAL_R + k3 * 4.0))
		o.draw_rect(Rect2(q4 - Vector2(4, 4), Vector2(8, 8)), head)
	GameFx.glow(o, C + Vector2.from_angle(needle) * (DIAL_R + 28.0), 12.0, head)
	# the pulls in a row
	for i2 in mini(combo, 8):
		var pp := GameFx.snap(C + Vector2((i2 - (mini(combo, 8) - 1) / 2.0) * 20.0, DIAL_R + 52.0))
		GameFx.glow(o, pp, 8.0, GOLD)

## The band's live parts: your spin (your pal, a chunky bar), the rivals' spins on the right; the
## stars dim as your spin drops below 70% and 40% (what you'd win now); the foot line is the
## winding's (and the drop's) clock
func _update_hud() -> void:
	if not player:
		return
	var now := 1 + (1 if player.spin >= 40.0 else 0) + (1 if player.spin >= 70.0 else 0)
	if not player.alive:
		now = 0
	if not practice:
		_stars_shown = GameFx.set_stars(hud_stars, _stars_shown, now)
	var band := GameFx.HUD_BAND
	match phase:
		Phase.WIND:
			band_bar.size.x = band.size.x * clampf(wind_left / WIND_TIME, 0.0, 1.0) if tut != Tut.WIND else band.size.x
			band_bar.color = GOLD
		Phase.DROP:
			band_bar.size.x = band.size.x * clampf(drop_left / DROP_TIME, 0.0, 1.0) if tut != Tut.DROP else band.size.x
			band_bar.color = GOLD
		_:
			band_bar.size.x = band.size.x
			band_bar.color = Color(bowl["accent"], 0.45)

func _draw_hud() -> void:
	if not player:
		return
	var band := GameFx.HUD_BAND
	var h := hud
	# your pal and your spin
	h.draw_texture_rect(ball_texture, Rect2(Vector2(band.position.x + 176, band.position.y + 7), Vector2(48, 48)), false)
	var r := Rect2(band.position.x + 228, band.position.y + 18, 192, 24)
	var fill := player.color
	if player.spin > 100.0:
		fill = Color8(255, 110, 70).lerp(Color(1, 1, 1), 0.3 * (0.5 + 0.5 * sin(time * 14.0)))   # over-wound
	elif player.spin < 25.0 and player.alive and fmod(time, 0.4) < 0.2:
		fill = WARN_COL
	if not player.alive:
		fill = Color8(90, 90, 100)
	_bar(h, r, clampf(player.spin / 100.0, 0.0, 1.0), fill, player.braced, bar_flash > 0.0 and fmod(bar_flash, 0.3) < 0.15)
	# the rivals (and the golden top), a row each: their pal and their spin
	var rows: Array[Top] = []
	for t in tops:
		if t != player:
			rows.append(t)
	var y0 := band.position.y + 29.0 - (rows.size() - 1) * 9.0
	for i in rows.size():
		var t := rows[i]
		var ry := y0 + i * 18.0
		var icon: Texture2D = t.root.rider if t.root.rider else null
		if icon:
			h.draw_texture_rect(icon, Rect2(Vector2(band.position.x + 586, ry - 12), Vector2(24, 24)), false, Color(1, 1, 1, 1.0 if t.alive else 0.4))
		else:
			GameFx.glow(h, Vector2(band.position.x + 598, ry), 8.0, GOLD, 1.0 if t.alive else 0.4)
		var col := t.color
		if t.spin < 25.0 and t.alive and fmod(time, 0.4) < 0.2:
			col = WARN_COL
		if not t.alive:
			col = Color8(90, 90, 100)
		_bar(h, Rect2(band.position.x + 616, ry - 4, 220, 8), clampf(t.spin / 100.0, 0.0, 1.0), col, t.braced, false)

## A chunky bar on the band: outlined, its empty part dark, filled in its colour with a lit top
## edge; a blue edge while guarding, a white one when the tutorial points at it
func _bar(ci: CanvasItem, r: Rect2, f: float, col: Color, guard: bool, point: bool) -> void:
	ci.draw_rect(r.grow(4), OUTLINE)
	ci.draw_rect(r, Color8(30, 32, 50))
	if f > 0.0:
		var w := maxf(4.0, roundf(r.size.x * f / 4.0) * 4.0)
		ci.draw_rect(Rect2(r.position, Vector2(w, r.size.y)), col)
		ci.draw_rect(Rect2(r.position, Vector2(w, 4)), col.lightened(0.35))
	if guard:
		ci.draw_rect(r.grow(4), GUARD_COL, false, 4)
	if point:
		ci.draw_rect(r.grow(8), Color.WHITE, false, 4)

# ================================================================== NODES / TEXTURES

func _create_static_nodes() -> void:
	var bg := ColorRect.new()
	bg.color = BG
	bg.size = Vector2(PLAY_WIDTH, PLAY_HEIGHT)
	add_child(bg)
	scene = Node2D.new()                           # (everything in the bowl's world: it shakes)
	add_child(scene)
	backdrop = Sprite2D.new()                       # the place round the bowl (each world's own)
	backdrop.centered = false
	backdrop.scale = Vector2(PX, PX)
	backdrop.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	scene.add_child(backdrop)
	stadium = Sprite2D.new()
	stadium.scale = Vector2(PX, PX)
	stadium.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	scene.add_child(stadium)
	stadium_rim = Sprite2D.new()                    # the rim's far half and inner wall (under the tops)
	stadium_rim.scale = Vector2(PX, PX)
	stadium_rim.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	scene.add_child(stadium_rim)
	floor_layer = Node2D.new()                      # shadows, gears, the whirlpool, the drop's target
	floor_layer.draw.connect(_draw_floor)
	scene.add_child(floor_layer)
	marks = GameFx.Burst.new()                      # scuffs and dust on the floor
	scene.add_child(marks)
	trails = GameFx.Burst.new()                     # the dashes' light ribbons (under the tops)
	scene.add_child(trails)
	top_nodes = Node2D.new()                        # the tops and the pegs, the nearer in front
	top_nodes.y_sort_enabled = true
	scene.add_child(top_nodes)
	stadium_front = Sprite2D.new()                  # the near rim, over the tops
	stadium_front.scale = Vector2(PX, PX)
	stadium_front.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	scene.add_child(stadium_front)
	rim_fx = Node2D.new()                           # the lights at the ways out
	rim_fx.draw.connect(_draw_rim_fx)
	scene.add_child(rim_fx)
	fx = GameFx.Burst.new()                         # sparks, rings, puffs, confetti
	scene.add_child(fx)
	room_fx = RoomFx.new()                          # the place's living light, added on
	var add := CanvasItemMaterial.new()
	add.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	room_fx.material = add
	scene.add_child(room_fx)
	dim_layer = Node2D.new()                        # while winding, everything but your top dimmed
	dim_layer.draw.connect(_draw_dim)
	scene.add_child(dim_layer)
	held = Node2D.new()                             # your top while it's wound and dropped (over the rest)
	scene.add_child(held)
	overlay = Node2D.new()                          # the guard and warning rings, the dial
	overlay.draw.connect(_draw_overlay)
	scene.add_child(overlay)

	# the HUD on the race games' band: the level, your pal and spin, the stars, the rivals, the boost
	var band := GameFx.build_band(self, BAND, BAND_FOOT)
	band_bar = band["bar"]
	var b := GameFx.HUD_BAND
	hud_level = GameFx.label(self, lcd_font, Vector2(b.position.x + 18, b.position.y + 2), Vector2(160, 52), 32, HORIZONTAL_ALIGNMENT_LEFT, HUD_TEXT)
	hud = Node2D.new()
	hud.draw.connect(_draw_hud)
	add_child(hud)
	hud_stars = GameFx.build_stars(self, Vector2(b.position.x + 432, b.position.y + 10))
	lives_box = HBoxContainer.new()                 # (no lives with the level menu: kept hidden)
	lives_box.visible = false
	add_child(lives_box)
	boost_icon = TextureRect.new()
	boost_icon.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	boost_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	boost_icon.size = Vector2(28, 36)
	boost_icon.position = Vector2(b.end.x - 52, b.position.y + 10)
	boost_icon.visible = false
	add_child(boost_icon)
	# the control legend along the bottom (what each button does right now)
	hint_main = make_button_hint(0, "PULL")
	hint_main.position = Vector2(72, PLAY_HEIGHT - 86)             # (clear of the screen's rounded corners)
	hint_fwd = make_button_hint(1, "DONE")
	hint_fwd.position = Vector2(PLAY_WIDTH - 250, PLAY_HEIGHT - 86)
	banner = GameFx.banner(self, lcd_font, BAND_FOOT, 470.0)
	whir = AudioStreamPlayer.new()
	var wav: AudioStreamWAV = (load("res://sounds/fx/top_whir.wav") as AudioStreamWAV).duplicate()
	wav.loop_mode = AudioStreamWAV.LOOP_FORWARD
	wav.loop_end = int(wav.get_length() * wav.mix_rate)
	whir.stream = wav
	add_child(whir)

func _refresh_lives() -> void:
	if not lives_box.visible:
		return
	for n in lives_box.get_children():
		n.queue_free()
	for i in LIVES:
		var t := TextureRect.new()
		t.texture = ball_texture
		t.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		t.custom_minimum_size = Vector2(36, 36)          # (the 16 px ball inside a 24 px texture)
		t.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		t.modulate = Color(1, 1, 1, 1) if i < lives else Color(0, 0, 0, 0.35)
		lives_box.add_child(t)

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
	var k := Vector2(
		float(Input.is_key_pressed(KEY_RIGHT) or Input.is_key_pressed(KEY_D)) - float(Input.is_key_pressed(KEY_LEFT) or Input.is_key_pressed(KEY_A)),
		float(Input.is_key_pressed(KEY_DOWN) or Input.is_key_pressed(KEY_S)) - float(Input.is_key_pressed(KEY_UP) or Input.is_key_pressed(KEY_W)))
	t += k * 0.8
	if t.length() < DEADZONE:
		return Vector2.ZERO
	return t.limit_length(1.0)

func on_main_button_pressed() -> void:
	if intro_active():
		dismiss_intro()
		return
	if is_game_over or level_menu_open():
		super.on_main_button_pressed()                 # (the level menu and its result card)
		return
	if not _touch_mode:
		_main_tap()

func _main_tap() -> void:
	if not is_running:
		return
	match phase:
		Phase.WIND:
			_wind_pull()
		Phase.DROP:
			_drop()
		Phase.BATTLE:
			if player.alive:
				_player_dash()

func on_main_button_released() -> void:
	if level_menu_open():
		super.on_main_button_released()                # (the level menu's hold)

func on_forward_button_down() -> void:
	if not _touch_mode:
		_forward_down()

func on_forward_button_up() -> void:
	if not _touch_mode:
		_forward_up()

func _forward_down() -> void:
	if not is_running or is_game_over:
		return
	if tut == Tut.WIND:
		_finish_tutorial()                             # skip the tutorial: a fresh, real level 1
		_start_match()
		return
	forward_held = true
	if phase == Phase.WIND:
		_begin_drop()                                  # done winding
	elif phase == Phase.BATTLE and player.alive:
		player.braced = true
		player.brace_t = 0.0

func _forward_up() -> void:
	forward_held = false
	if player:
		player.braced = false

func on_forward_button_pressed() -> void:
	if is_game_over or level_menu_open():
		super.on_forward_button_pressed()              # (the level menu's next world)

## Phones: every finger counts (hold GUARD with one thumb, DASH with the other)
func _input(event: InputEvent) -> void:
	if not (event is InputEventScreenTouch):
		return
	_touch_mode = true
	if event.pressed:
		if intro_active() or is_game_over:
			return                                       # (the buttons' own taps handle those)
		var b := device_button_at(event.position)
		if b == 0:
			_main_tap()
		elif b == 1:
			_guard_touch = event.index
			_forward_down()
	elif event.index == _guard_touch:
		_guard_touch = -1
		_forward_up()

func _unhandled_input(event: InputEvent) -> void:
	if not (event is InputEventKey) or event.echo:
		return
	var k := (event as InputEventKey).keycode
	if k == KEY_SPACE and event.pressed:
		on_main_button_pressed()
	elif k == KEY_SHIFT or k == KEY_X:
		if event.pressed:
			on_forward_button_down()
		else:
			on_forward_button_up()
			on_forward_button_pressed()

func end_game() -> void:
	phase = Phase.RESULT
	banner.visible = false
	_set_legend("", "")
	super.end_game()

# ================================================================== FX HELPERS

func _show_banner(text: String, hold: float) -> void:
	GameFx.show_banner(banner, text, hold)

## A rare word over the bowl (a rival out, a secret's hint), in the pixel font with its dark edge
func _float_text(text: String, at: Vector2) -> void:
	var lx := clampf(at.x - 200, 30, PLAY_WIDTH - 430)
	var l := GameFx.label(self, lcd_font, Vector2(lx, at.y - 40), Vector2(400, 40), 28, HORIZONTAL_ALIGNMENT_CENTER, Color(1, 0.95, 0.85))
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
