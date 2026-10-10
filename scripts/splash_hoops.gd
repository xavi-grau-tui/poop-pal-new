extends BaseMinigame
## Splash Hoops — the classic water toy. Two pumps at the bottom of a water tank blow jets
## of bubbles; drop a ball into every basket before the timer runs out. A ball that lands
## in a basket lights it up and falls through, and the floor slopes down to the pumps, so
## every ball always rolls back next to a pump. Five stages of baskets in a loop (STAGES), a
## pufferfish from stage 3, a coin for each stage cleared the first time.
##
## Main button: LEFT pump. Forward button: RIGHT pump. Both work the same way:
## hold to keep pumping (a pump runs dry after a moment), release to stop.
##
## How the baskets are reached (mapped with tools/design/splash_sim.py, keep it in sync):
##   100  one pump, on the OUTER ball of the pile (~0.7 s): the jet fans it outwards
##   200  one pump on the INNER ball, or a short push of both pumps
##   300  BOTH pumps held together: the two currents meet in the middle, pull balls to the
##        centre and rise up a column there; let go and the ball drops into the 300.
##        Too short and it doesn't get high enough.
## A ball sitting right on a nozzle goes straight up and back down with one pump only.
## Desktop: also Left/Right arrow keys (or A / D) for the two pumps.

const S := 3.0                          # world px per art pixel (sprites are drawn x3)
# Walls = the edges actually visible through the console's screen window
# (the window shows x 18..945, y 9..936 of the 950x948 play area)
const TANK_L := 18.0
const TANK_R := 945.0
const BAND_Y := 104.0                   # the toy's plastic top band (the HUD sits on it)
const TANK_T := BAND_Y + 2.0

# Funnel floor (matches tools/art/minigame_art.py): lowest at each nozzle
const NOZZLES := [237.0, 713.0]
const FLOOR_Y := 866.0
const FLOOR_SLOPE := 0.42

# --- Water physics ---
const GRAVITY := 380.0                  # things sink slowly
const DRAG := 1.4                       # velocity damping per second
const MAX_SPEED := 800.0
const JET_FORCE := 2600.0
const JET_TOP := 474.0                  # the thrust only acts below mid-screen; above it balls
										# fly on their momentum and just fall back down
const JET_SPREAD := 0.42                # cone widening per px of height
const CENTER_X := 475.0                 # between the two pumps
const MEET_PULL := 20.0                  # both pumps on: the currents pull towards the centre...
const MEET_DAMP := 5.5                  # ...and cancel each other there (no overshoot)
const MEET_MIN_H := 200.0               # (above the pile; baskets can be crossed from below)
const MEET_LIFT := 1900.0               # where they meet the water rises: a column up the middle
const MEET_WIDTH := 110.0
const PUMP_TIME := 0.9                  # held main pump runs dry after this long
const BOUNCE := 0.45
const TILT_PUSH := 140.0                # tilting the phone nudges everything sideways a little
const DIVER_R := 38.0                   # the pal (its own sprite, small), with a diving mask and a snorkel:
                                        # wider than a basket's mouth (64 px between the knobs), it can't go in
# --- Pieces ---
const BALL_R := 16.0
const CUP_W := 90.0
const CUP_H := 78.0
## Basket spots (see the reach map at the top): the 300 in the centre, below where the
## meeting currents lift the balls; the 200s where a single pump drops the inner ball, low
## enough that a ball carried diagonally to the centre passes over them; the 100s low on
## the outer sides (where a single pump throws the outer ball). None in the jet columns,
## none above another.
const CUP_SLOTS := [
	Vector2(325, 470), Vector2(475, 380), Vector2(625, 470),
	Vector2(130, 545), Vector2(820, 545),
]
const CUP_POINTS := [200, 300, 200, 100, 100]
const LEVEL_TIME := 60.0

## Stages (2026-10-10): five basket layouts in a loop. Each lap round the loop the baskets move
## faster and there's less time (see _speed / _level_time).
##   classic   the five spots above, still (swaying from the second lap)
##   triangle  an upside-down triangle: 3 high, 2 in the middle, 1 low in the centre
##   drift     the classic spots, each basket drifting its own way (across, up and down, diagonal)
##   orbit     one in the centre, two circling round it, two on the sides going up and down
##   wheel     five on a slowly turning wheel
const STAGES := ["classic", "triangle", "drift", "orbit", "wheel"]
const STAGE_TITLES := {
	"classic": "Pump the water!", "triangle": "Upside down!", "drift": "Drifting!",
	"orbit": "Round and round!", "wheel": "The wheel!",
}
const LAP_SPEED := 0.35                 # each lap: baskets this much faster...
const LAP_TIME := 8.0                   # ...and this many seconds less (down to MIN_TIME)
const MIN_TIME := 36.0

## The pufferfish (from stage PUFFER_FROM): swims back and forth and swallows balls that come near
## its mouth (PUFFER_MAX_EAT at most, so a few always stay). Bump it with the diving pal and it
## puffs up, spits them all back out and darts off for a while.
const PUFFER_FROM := 3
const PUFFER_R := 30.0
const PUFFER_S := 6.0                   # its pixels: twice the game's (a chunkier look)
const PUFFER_MAX_EAT := 3
const PUFFER_SPEED := 70.0
const PUFFER_FLEE := 420.0
const PUFFER_AWAY := 8.0                # seconds gone after a fright
const PUFFER_FIRST := 3.0               # seconds into a stage before it swims in

const BALL_COLORS := ["pink", "yellow", "mint"]
const OUTLINE := Color8(74, 44, 32)

enum State { PLAY, CLEAR }

var state := State.PLAY
var level := 1
var time_left := LEVEL_TIME
var jets := [
	{ "x": NOZZLES[0], "power": 0.0, "held": false, "hold_time": 0.0 },
	{ "x": NOZZLES[1], "power": 0.0, "held": false, "hold_time": 0.0 },
]
var balls: Array[Dictionary] = []       # { pos, vel, node }
var diver := {}                         # the pal: { pos, vel, node, r }: floats about, can't score
var cups: Array[Dictionary] = []        # { pos, home, rim, full, points, net, rim_node, label }
var bubbles: Array[Dictionary] = []
var puffer := {}                        # { node, pos, dir, state: off/away/swim/flee, eaten, timer, base_y, phase }
var coin_label: Label
var _bought := false                    # a game was just bought with coins (for the clear banner)

var tex := {}
var lcd_font: Font
var world: Node2D
var net_layer: Node2D
var diver_layer: Node2D                 # the diver: over the baskets (it rests on them, never in)
var bubble_layer: Node2D
var hud_level: Label
var hud_time: Label
var score_label: Label
var banner: Label
var rng := RandomNumberGenerator.new()
var _key_jets := [false, false]
# Phones: each console button only sees one finger (touch is turned into a single mouse), so
# both pumps read the touches directly: touch index -> pump held by that finger
var _touch_jets := {}

func _ready() -> void:
	game_music_path = "res://sounds/music/Light Through Water.ogg"     # (82 BPM, loops on the beat: 0 → 158.05 s)
	lcd_font = load("res://fonts/pixChicago.ttf")
	# the look, painted in code (SplashArt): a plastic water toy like the other toy games
	var old := "res://textures/minigames/splash/"
	tex["tank"] = SplashArt.tank(317, 316, BAND_Y, TANK_L, TANK_R, floor_at, NOZZLES)
	tex["cup_rim"] = SplashArt.recolour(old + "cup_rim.png", SplashArt.CORAL_LIGHT, SplashArt.CORAL, SplashArt.CORAL_DARK)
	tex["cup_net"] = SplashArt.net(old + "cup_net.png")
	tex["nozzle"] = SplashArt.recolour(old + "nozzle.png", SplashArt.CORAL_LIGHT, SplashArt.CORAL, SplashArt.CORAL_DARK)
	tex["bubble_big"] = SplashArt.bubble(9)
	tex["bubble_small"] = SplashArt.bubble(7)
	for c in BALL_COLORS:
		tex["ball_" + c] = SplashArt.ball(c)
	var pal_art := "res://textures/minigames/balls/classic.png"
	if PetState.has_poop():
		pal_art = PetState.FORMS[PetState.form_id]["frames"][0]
	tex["diver"] = SplashArt.diver(pal_art)
	tex["puffer"] = SplashArt.puffer(false)
	tex["puffer_puffed"] = SplashArt.puffer(true)
	tex["coin"] = SplashArt.coin()
	GameData.game_unlocked.connect(_on_game_unlocked)
	_create_static_nodes()
	super._ready()

func start_game() -> void:
	super.start_game()
	level = 1
	_build_level()
	_show_banner(STAGE_TITLES[_stage()], 1.6)

# ================================================================== LEVEL

func floor_at(x: float) -> float:
	var d := minf(absf(x - NOZZLES[0]), absf(x - NOZZLES[1]))
	return FLOOR_Y - FLOOR_SLOPE * d

func _build_level() -> void:
	for b in balls:
		b["node"].queue_free()
	for c in cups:
		for k in ["net", "rim_node", "label"]:
			c[k].queue_free()
	balls.clear()
	cups.clear()
	rng.seed = 4271 * level + 3

	var n_balls := 6                                 # 3 per pump; balls are reused, never used up
	time_left = _level_time()
	_place_cups()
	_reset_puffer()

	for i in n_balls:
		var jx: float = NOZZLES[i % 2]
		var pos := Vector2(jx + (i / 2 - 1) * 40.0, floor_at(jx) - 120.0 - (i / 2) * 30.0)
		var s := _sprite(tex["ball_" + BALL_COLORS[i % BALL_COLORS.size()]], pos)
		world.add_child(s)
		balls.append({ "pos": pos, "vel": Vector2.ZERO, "node": s })
	if diver.is_empty():
		var d := _sprite(tex["diver"], Vector2(CENTER_X, 640))
		diver_layer.add_child(d)
		diver = { "pos": Vector2(CENTER_X, 640), "vel": Vector2.ZERO, "node": d, "r": DIVER_R }
	else:
		diver["pos"] = Vector2(CENTER_X, 640)
		diver["vel"] = Vector2.ZERO
	calibrate_tilt()                                 # (however the phone is held now = level)
	hud_level.text = "LV %d" % level
	state = State.PLAY

## This level's stage, and how many laps round the five stages have been done
func _stage() -> String:
	return STAGES[(level - 1) % STAGES.size()]

func _lap() -> int:
	return (level - 1) / STAGES.size()

func _speed() -> float:
	return 1.0 + LAP_SPEED * _lap()

func _level_time() -> float:
	return maxf(LEVEL_TIME - LAP_TIME * _lap(), MIN_TIME)

## The baskets for this stage. Each one: points, and how it moves:
##   still: home · sway: home + dir * sin(phase) * amp · orbit: centre + radius at angle phase
## (phase grows by speed per second)
func _place_cups() -> void:
	var specs: Array = []
	match _stage():
		"classic":
			for i in CUP_SLOTS.size():
				# from the second lap they sway a little (staying out of the jets)
				specs.append({ "home": CUP_SLOTS[i], "points": CUP_POINTS[i], "mode": "sway" if _lap() > 0 else "still",
					"dir": Vector2.RIGHT, "amp": 24.0, "speed": 0.8, "phase": i * 1.3 })
		"triangle":
			# (the top corners out over the side walls: right above a pump a ball hardly ever
			# comes down from high enough, out at the sides the pumps' throws land easily)
			for p in [[Vector2(140, 450), 300], [Vector2(475, 390), 300], [Vector2(810, 450), 300],
					[Vector2(325, 490), 200], [Vector2(625, 490), 200], [Vector2(475, 585), 100]]:
				specs.append({ "home": p[0], "points": p[1], "mode": "still" if _lap() == 0 else "sway",
					"dir": Vector2.RIGHT, "amp": 16.0, "speed": 0.9, "phase": p[0].x * 0.01 })
		"drift":
			var dirs := [Vector2(1, 0), Vector2(0, 1), Vector2(-1, 0), Vector2(0.7, -0.7), Vector2(0, 1)]
			var amps := [60.0, 50.0, 60.0, 50.0, 50.0]
			var speeds := [0.7, 0.9, 0.8, 0.6, 1.0]
			for i in CUP_SLOTS.size():
				specs.append({ "home": CUP_SLOTS[i], "points": CUP_POINTS[i], "mode": "sway",
					"dir": dirs[i], "amp": amps[i], "speed": speeds[i], "phase": i * 1.7 })
		"orbit":
			var mid := Vector2(475, 410)
			specs.append({ "home": mid, "points": 300, "mode": "still" })
			for k in 2:
				specs.append({ "home": mid, "center": mid, "points": 200, "mode": "orbit",
					"radius": 130.0, "speed": 0.55, "phase": PI * k })
			for k in 2:
				specs.append({ "home": Vector2([130.0, 820.0][k], 500), "points": 100, "mode": "sway",
					"dir": Vector2.DOWN, "amp": 70.0, "speed": 0.8, "phase": PI * k })
		"wheel":
			var hub := Vector2(475, 410)
			for k in 5:
				specs.append({ "home": hub, "center": hub, "points": 200, "mode": "orbit",
					"radius": 160.0, "speed": 0.32, "phase": TAU * k / 5.0 - PI / 2.0 })
	for sp in specs:
		var c := _make_cup(sp["home"], sp["points"])
		c.merge(sp, true)
		cups.append(c)
		_set_cup_pos(c, _cup_pos(c))

func _cup_pos(c: Dictionary) -> Vector2:
	match c["mode"]:
		"sway":
			return c["home"] + c["dir"] * sin(c["phase"]) * c["amp"]
		"orbit":
			return c["center"] + Vector2(cos(c["phase"]), sin(c["phase"])) * c["radius"]
	return c["home"]

func _set_cup_pos(c: Dictionary, p: Vector2) -> void:
	p.x = clampf(p.x, TANK_L + CUP_W / 2.0, TANK_R - CUP_W / 2.0)
	c["pos"] = p
	c["rim"] = p.y - CUP_H / 2.0 + 12.0
	c["net"].position = p
	c["rim_node"].position = p
	c["label"].position = p + Vector2(-45, -CUP_H / 2.0 - 34)

func _make_cup(center: Vector2, points: int) -> Dictionary:
	# see-through net + solid rim, drawn over the balls (net_layer comes after world) so a
	# ball is seen falling through the basket and dropping out of the bottom of the net.
	# (Layering by tree order only: a z_index would escape the game screen's clip.)
	var net := _sprite(tex["cup_net"], center)
	net_layer.add_child(net)
	var rim := _sprite(tex["cup_rim"], center)
	net_layer.add_child(rim)
	var label := _make_label(center + Vector2(-45, -CUP_H / 2.0 - 34), Vector2(90, 30), 22, HORIZONTAL_ALIGNMENT_CENTER, OUTLINE)
	label.text = str(points)
	return { "pos": center, "rim": center.y - CUP_H / 2.0 + 12.0, "full": false, "points": points, "net": net, "rim_node": rim, "label": label }

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
		_update_puffer(delta)
		# the baskets move in the same small steps as the balls (a basket rising past a ball in
		# one big jump would miss the ball dropping in: see _collide_cups)
		const STEPS := 4
		for i in STEPS:
			_move_cups(delta / STEPS)
			_physics(delta / STEPS)
	for b in balls:
		b["node"].position = b["pos"]
		b["node"].rotation += b["vel"].x * delta / BALL_R
	if not diver.is_empty():
		# the pal doesn't roll: it stays upright, leaning a little the way it drifts
		diver["node"].position = diver["pos"]
		var lean := clampf(diver["vel"].x / 600.0, -0.25, 0.25)
		diver["node"].rotation = lerpf(diver["node"].rotation, lean, minf(1.0, delta * 6.0))
	_refresh_hud()

## Everything that floats: the balls, and the diving pal
func _bodies() -> Array:
	return balls + ([diver] if not diver.is_empty() else [])

func _move_cups(delta: float) -> void:
	for c in cups:
		c["prev_pos"] = c["pos"]                     # (where it was when the balls' "prev" was taken)
		if c["mode"] == "still":
			continue
		c["phase"] += delta * c["speed"] * _speed()
		_set_cup_pos(c, _cup_pos(c))

func _update_jets(delta: float) -> void:
	_key_jets = [Input.is_key_pressed(KEY_LEFT) or Input.is_key_pressed(KEY_A), Input.is_key_pressed(KEY_RIGHT) or Input.is_key_pressed(KEY_D)]
	for i in 2:
		var j: Dictionary = jets[i]
		var want := 0.0
		if j["held"] or _key_jets[i] or i in _touch_jets.values():
			j["hold_time"] += delta
			want = clampf(1.0 - (j["hold_time"] - PUMP_TIME) / 0.4, 0.0, 1.0)   # pump runs dry
		else:
			j["hold_time"] = 0.0
		var rate := 14.0 if want > j["power"] else 5.0
		j["power"] = move_toward(j["power"], want, rate * delta)
		if j["power"] > 0.05 and rng.randf() < j["power"] * delta * 40.0:
			_spawn_bubble(Vector2(j["x"] + rng.randf_range(-10, 10), FLOOR_Y - 20))
	# both pumps on: bubbles swirl in from both sides towards the middle
	var both: float = minf(jets[0]["power"], jets[1]["power"])
	if both > 0.2 and rng.randf() < both * delta * 30.0:
		var side := -1.0 if rng.randf() < 0.5 else 1.0
		_spawn_bubble(Vector2(CENTER_X + side * rng.randf_range(160, 260), rng.randf_range(420, 640)), -side * rng.randf_range(160, 260))

func _jet_force(p: Vector2, v: Vector2) -> Vector2:
	var f := Vector2.ZERO
	var h := FLOOR_Y - p.y
	# both pumps at once: the two currents meet in the middle of the tank
	var both: float = minf(jets[0]["power"], jets[1]["power"])
	if both > 0.01 and h > MEET_MIN_H:
		f.x += both * (MEET_PULL * (CENTER_X - p.x) - MEET_DAMP * v.x)
		var cx := (p.x - CENTER_X) / MEET_WIDTH
		f.y -= both * MEET_LIFT * exp(-cx * cx)
	if p.y < JET_TOP:
		return f
	var fade := clampf((p.y - JET_TOP) / 60.0, 0.0, 1.0)     # soft edge at mid-screen
	for j in jets:
		if j["power"] <= 0.01:
			continue
		var dx: float = p.x - j["x"]
		var w := 40.0 + h * JET_SPREAD
		var k: float = j["power"] * exp(-(dx / w) * (dx / w)) * fade
		# straight up at the nozzle, fanning out a little higher up
		var fan := clampf((h - 120.0) / 250.0, 0.0, 1.0)
		fan *= 1.0 - both                                       # meeting currents cancel the fan
		f += Vector2((signf(dx) * 0.3 + randf_range(-0.2, 0.2)) * fan, -1.0) * JET_FORCE * k
	return f

func _physics(dt: float) -> void:
	var tilt := device_tilt().x if has_tilt_sensor() else 0.0
	tilt += (float(Input.is_key_pressed(KEY_E)) - float(Input.is_key_pressed(KEY_Q))) * 0.5   # (desktop: Q / E)
	var bodies := _bodies()
	for b in bodies:
		var v: Vector2 = b["vel"]
		v.y += GRAVITY * dt
		v.x += clampf(tilt * 2.0, -1.0, 1.0) * TILT_PUSH * dt
		v += _jet_force(b["pos"], v) * dt
		v *= maxf(0.0, 1.0 - DRAG * dt)
		v = v.limit_length(MAX_SPEED)
		b["prev"] = b["pos"]
		b["pos"] += v * dt
		b["vel"] = v
		_collide_tank(b, dt)
		_collide_cups(b)
	# balls (and the diver) bump into each other
	for a in bodies.size():
		for c in range(a + 1, bodies.size()):
			var pa: Dictionary = bodies[a]
			var pb: Dictionary = bodies[c]
			var d: Vector2 = pb["pos"] - pa["pos"]
			var min_d: float = pa.get("r", BALL_R) + pb.get("r", BALL_R)
			if d.length_squared() < min_d * min_d and d.length_squared() > 0.01:
				var n := d.normalized()
				var push := (min_d - d.length()) / 2.0
				pa["pos"] -= n * push
				pb["pos"] += n * push
				var rel: float = (pb["vel"] - pa["vel"]).dot(n)
				if rel < 0:
					pa["vel"] += n * rel * 0.5
					pb["vel"] -= n * rel * 0.5

func _collide_tank(b: Dictionary, dt: float) -> void:
	var pos: Vector2 = b["pos"]
	var v: Vector2 = b["vel"]
	var br: float = b.get("r", BALL_R)              # (the diver is bigger)
	if pos.x < TANK_L + br:
		pos.x = TANK_L + br; v.x = absf(v.x) * BOUNCE
	elif pos.x > TANK_R - br:
		pos.x = TANK_R - br; v.x = -absf(v.x) * BOUNCE
	if pos.y < TANK_T + br:
		pos.y = TANK_T + br; v.y = absf(v.y) * 0.3
	# sloped floor: everything rolls down to the nearest pump
	var fy := floor_at(pos.x)
	if pos.y > fy - br:
		pos.y = fy - br
		var near: float = NOZZLES[0] if absf(pos.x - NOZZLES[0]) < absf(pos.x - NOZZLES[1]) else NOZZLES[1]
		var side := signf(pos.x - near)
		# the floor rises away from the pump: dy/dx = -side * slope, so its upward normal is:
		var n := Vector2(-side * FLOOR_SLOPE, -1.0).normalized()
		var into := v.dot(n)
		if into < 0.0:
			v -= n * into * (1.0 + BOUNCE * 0.3)
		v.x -= side * 420.0 * dt                                  # roll down the slope
		if absf(pos.x - near) < 8.0:
			v.x *= 0.85                                           # settle right over the nozzle
	b["pos"] = pos
	b["vel"] = v

## Basket colliders, relative to the basket centre (from the basket art, x3):
## the two ends of the rim are round knobs; the net's slanted sides are solid walls (both
## sides: outside they push balls away, inside they guide a ball down through the net);
## the bottom of the net is an open hole both ways: balls fall out of it, and a ball pushed
## up from below can pass through the basket (it only scores coming down over the rim).
const RIM_KNOB_L := Vector2(-40, -22)
const RIM_KNOB_R := Vector2(40, -22)
const RIM_KNOB_R_SIZE := 8.0
const NET_WALL_L := [Vector2(-38, -12), Vector2(-27, 36)]
const NET_WALL_R := [Vector2(38, -12), Vector2(27, 36)]
const NET_WALL_THICK := 3.0
const RIM_LINE_Y := -16.0                # crossing this line downward between the knobs = in

func _collide_cups(b: Dictionary) -> void:
	for c in cups:
		var cp: Vector2 = c["pos"]
		var d: Vector2 = b["pos"] - cp
		if absf(d.x) > 80.0 or absf(d.y) > 80.0:
			continue
		# scoring: dropped in over the rim, between the knobs. Measured against the basket as it was
		# a step ago and as it is now, so a moving basket (rising, circling) catches balls too.
		var prev_d: Vector2 = b.get("prev", b["pos"]) - c.get("prev_pos", cp)
		if not c["full"] and not b.has("r") and prev_d.y <= RIM_LINE_Y and d.y > RIM_LINE_Y and absf(d.x) < RIM_KNOB_R.x - RIM_KNOB_R_SIZE:
			_fill_cup(b, c)
		# rim knobs (for the diver the whole rim is solid: it sits on top of a basket, never in)
		if b.has("r"):
			_bounce_off_point(b, Geometry2D.get_closest_point_to_segment(b["pos"], cp + RIM_KNOB_L, cp + RIM_KNOB_R), RIM_KNOB_R_SIZE)
		for k in [RIM_KNOB_L, RIM_KNOB_R]:
			_bounce_off_point(b, cp + k, RIM_KNOB_R_SIZE)
		# net walls
		for w in [NET_WALL_L, NET_WALL_R]:
			var a: Vector2 = cp + w[0]
			var e: Vector2 = cp + w[1]
			var q := Geometry2D.get_closest_point_to_segment(b["pos"], a, e)
			_bounce_off_point(b, q, NET_WALL_THICK)

func _bounce_off_point(b: Dictionary, q: Vector2, r: float) -> void:
	var d: Vector2 = b["pos"] - q
	var min_d: float = b.get("r", BALL_R) + r
	if d.length_squared() >= min_d * min_d:
		return
	var n := d.normalized() if d.length_squared() > 0.01 else Vector2.UP
	b["pos"] = q + n * min_d
	var v: Vector2 = b["vel"]
	var into := v.dot(n)
	if into < 0.0:
		v -= n * into * (1.0 + BOUNCE)
	if n.y < -0.9 and absf(v.x) < 40.0:
		# sitting right on top of a knob: tip it off, in or out
		v.x += (1.0 if randf() < 0.5 else -1.0) * 90.0
	b["vel"] = v

func _fill_cup(_b: Dictionary, c: Dictionary) -> void:
	c["full"] = true
	c["net"].modulate = Color(1.7, 1.3, 0.55)        # a filled basket lights up gold
	var tw := create_tween()
	tw.tween_property(c["rim_node"], "scale", Vector2(S * 1.15, S * 0.85), 0.08)
	tw.tween_property(c["rim_node"], "scale", Vector2(S, S), 0.2).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	c["label"].modulate.a = 0.3
	add_score(c["points"])
	_float_text("+%d" % c["points"], c["pos"])
	_sfx("res://sounds/fx/gamecoin.wav", -9.0)
	for q in cups:
		if not q["full"]:
			return
	_level_clear()

func _level_clear() -> void:
	state = State.CLEAR
	var bonus := int(time_left) * 5
	if bonus > 0:
		add_score(bonus)
	_show_banner("Clear! +%d" % bonus, 1.4)
	# the first time this stage is cleared: a coin (and 5 coins buy the next game)
	_bought = false
	if GameData.clear_stage(_game_index(), level):
		_coin_pop()
	await get_tree().create_timer(1.8).timeout
	if not is_running:
		return
	if _bought:
		_show_banner("New game!", 1.2)
		await get_tree().create_timer(1.6).timeout
		if not is_running:
			return
	level += 1
	_build_level()
	_show_banner(STAGE_TITLES[_stage()], 1.2)

func _on_game_unlocked(_idx: int) -> void:
	_bought = true

## +1 coin: a coin pops up in the middle and flies into the counter
func _coin_pop() -> void:
	_refresh_coins()
	_sfx("res://sounds/fx/claw_prize.wav", -10.0)
	var c := _sprite(tex["coin"], Vector2(PLAY_WIDTH / 2.0, PLAY_HEIGHT / 2.0 + 70))
	c.scale = Vector2(S * 1.6, S * 1.6)
	add_child(c)
	var t := create_tween()
	t.tween_property(c, "position:y", c.position.y - 30, 0.35).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	t.tween_interval(0.4)
	t.tween_property(c, "position", Vector2(214, 52), 0.45).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	t.parallel().tween_property(c, "scale", Vector2(S, S), 0.45)
	t.tween_callback(c.queue_free)
	_float_text("+1 coin", Vector2(PLAY_WIDTH / 2.0, PLAY_HEIGHT / 2.0 + 150))

## The coin counter: "coins/price" while there's a game left to buy
func _refresh_coins() -> void:
	if coin_label:
		coin_label.text = "%d/%d" % [GameData.coins, GameData.GAME_PRICE] if GameData.next_locked_game() >= 0 else str(GameData.coins)

# ================================================================== THE PUFFERFISH

func _reset_puffer() -> void:
	for b in puffer.get("eaten", []):
		b["node"].queue_free()
	puffer["eaten"] = []
	puffer["node"].visible = false
	puffer["state"] = "away" if level >= PUFFER_FROM else "off"
	puffer["timer"] = PUFFER_FIRST

func _update_puffer(delta: float) -> void:
	var n: Sprite2D = puffer["node"]
	match puffer["state"]:
		"away":
			puffer["timer"] -= delta
			if puffer["timer"] <= 0.0:
				# swims in from one side, at some depth in the middle of the tank
				puffer["dir"] = 1.0 if rng.randf() < 0.5 else -1.0
				puffer["base_y"] = rng.randf_range(300, 600)
				puffer["pos"] = Vector2(-40.0 if puffer["dir"] > 0 else PLAY_WIDTH + 40.0, puffer["base_y"])
				puffer["phase"] = 0.0
				puffer["state"] = "swim"
				n.texture = tex["puffer"]
				n.visible = true
				if level == PUFFER_FROM and not puffer.get("met", false):
					puffer["met"] = true
					_show_banner("Pufferfish!", 1.0)
					_float_text("bump it with your pal!", Vector2(PLAY_WIDTH / 2.0, PLAY_HEIGHT / 2.0 + 120), 340)
		"swim":
			puffer["phase"] += delta
			var p: Vector2 = puffer["pos"]
			p.x += puffer["dir"] * PUFFER_SPEED * _speed() * delta
			p.y = puffer["base_y"] + sin(puffer["phase"] * 1.6) * 14.0
			if (p.x < TANK_L + 50 and puffer["dir"] < 0) or (p.x > TANK_R - 50 and puffer["dir"] > 0):
				puffer["dir"] *= -1.0                                  # turns at the walls...
				puffer["base_y"] = clampf(puffer["base_y"] + rng.randf_range(-120, 120), 300, 620)   # ...at a new depth
			puffer["pos"] = p
			n.flip_h = puffer["dir"] > 0                               # (the art faces left)
			# a ball near its mouth: gulp
			if puffer["eaten"].size() < PUFFER_MAX_EAT:
				var mouth: Vector2 = p + Vector2(puffer["dir"] * 40.0, 6.0)
				for b in balls:
					if b["pos"].distance_to(mouth) < 28.0:
						_puffer_eat(b)
						break
			# bumped by the diving pal: a fright
			if not diver.is_empty() and diver["pos"].distance_to(p) < DIVER_R + PUFFER_R:
				_puffer_scare()
		"flee":
			var p: Vector2 = puffer["pos"]
			p.x += puffer["dir"] * PUFFER_FLEE * delta
			p.y -= 40.0 * delta
			puffer["pos"] = p
			if p.x < -80 or p.x > PLAY_WIDTH + 80:
				n.visible = false
				puffer["state"] = "away"
				puffer["timer"] = PUFFER_AWAY
	n.position = puffer.get("pos", Vector2(-100, 0))

func _puffer_eat(b: Dictionary) -> void:
	balls.erase(b)
	b["node"].visible = false
	puffer["eaten"].append(b)
	_sfx("res://sounds/fx/pin_gulp.wav", -8.0)
	_float_text("gulp!", puffer["pos"])
	var n: Sprite2D = puffer["node"]
	var t := create_tween()
	t.tween_property(n, "scale", Vector2(PUFFER_S * 1.25, PUFFER_S * 0.85), 0.08)
	t.tween_property(n, "scale", Vector2(PUFFER_S, PUFFER_S), 0.25).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

## The pal bumped it: it puffs up, spits out every ball it swallowed and darts off
func _puffer_scare() -> void:
	var p: Vector2 = puffer["pos"]
	puffer["state"] = "flee"
	if absf(p.x - diver["pos"].x) > 4.0:
		puffer["dir"] = signf(p.x - diver["pos"].x)              # away from the pal
	var n: Sprite2D = puffer["node"]
	n.texture = tex["puffer_puffed"]
	n.flip_h = puffer["dir"] > 0
	for b in puffer["eaten"]:
		b["pos"] = p + Vector2(rng.randf_range(-12, 12), rng.randf_range(-12, 12))
		b["vel"] = Vector2(rng.randf_range(-220, 220), rng.randf_range(-320, -140))
		b["node"].position = b["pos"]
		b["node"].visible = true
		balls.append(b)
	puffer["eaten"] = []
	diver["vel"] += (diver["pos"] - p).normalized() * 260.0    # (the pal bounces off its spines)
	_sfx("res://sounds/fx/water_boing.wav", -8.0)
	_float_text("shoo!", p)
	var t := create_tween()
	t.tween_property(n, "scale", Vector2(PUFFER_S * 1.3, PUFFER_S * 1.3), 0.1)
	t.tween_property(n, "scale", Vector2(PUFFER_S, PUFFER_S), 0.3)

# ================================================================== BUBBLES

func _spawn_bubble(at: Vector2, vx := 0.0) -> void:
	var big := randf() < 0.35
	var s := _sprite(tex["bubble_big" if big else "bubble_small"], at)
	bubble_layer.add_child(s)
	bubbles.append({ "node": s, "vy": -randf_range(260, 420), "vx": vx, "phase": randf() * TAU, "x": at.x })

func _update_bubbles(delta: float) -> void:
	for i in range(bubbles.size() - 1, -1, -1):
		var b: Dictionary = bubbles[i]
		var n: Sprite2D = b["node"]
		b["phase"] += delta * 9.0
		n.position.y += b["vy"] * delta
		b["x"] += b["vx"] * delta
		b["vx"] *= maxf(0.0, 1.0 - 1.5 * delta)
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

	for x in NOZZLES:
		add_child(_sprite(tex["nozzle"], Vector2(x, FLOOR_Y - 12)))

	world = Node2D.new()
	add_child(world)
	net_layer = Node2D.new()
	add_child(net_layer)
	diver_layer = Node2D.new()
	add_child(diver_layer)
	puffer = { "node": _sprite(tex["puffer"], Vector2(-100, 0)), "state": "off", "eaten": [] }
	puffer["node"].scale = Vector2(PUFFER_S, PUFFER_S)
	puffer["node"].visible = false
	diver_layer.add_child(puffer["node"])           # (under the diver, added later)
	bubble_layer = Node2D.new()
	add_child(bubble_layer)

	hud_level = _make_label(Vector2(40, 26), Vector2(160, 52), 38, HORIZONTAL_ALIGNMENT_LEFT, OUTLINE)
	var coin_icon := _sprite(tex["coin"], Vector2(214, 52))
	add_child(coin_icon)
	coin_label = _make_label(Vector2(236, 26), Vector2(120, 52), 30, HORIZONTAL_ALIGNMENT_LEFT, OUTLINE)
	_refresh_coins()
	hud_time = _make_label(Vector2(PLAY_WIDTH / 2 - 85, 26), Vector2(170, 52), 38, HORIZONTAL_ALIGNMENT_CENTER, OUTLINE)
	var frame := ColorRect.new()
	frame.color = Color(0, 0, 0)
	frame.position = Vector2(PLAY_WIDTH - 245, 18)
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

func _refresh_hud() -> void:
	hud_time.text = "%d" % ceili(time_left)
	hud_time.add_theme_color_override("font_color", Color(0.75, 0.15, 0.2) if time_left < 10.0 else OUTLINE)
	score_label.add_theme_font_size_override("font_size", 36 if str(score).length() <= 5 else 30)
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

func _float_text(text: String, at: Vector2, width := 120.0) -> void:
	var l := _make_label(at + Vector2(-width / 2.0, -70), Vector2(width, 40), 28, HORIZONTAL_ALIGNMENT_CENTER, Color(1, 0.95, 0.85))
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
	_pump(0, true)

func on_main_button_released() -> void:
	_pump(0, false)

func on_forward_button_down() -> void:
	if not is_game_over:
		_pump(1, true)

func on_forward_button_up() -> void:
	_pump(1, false)

func on_forward_button_pressed() -> void:
	# (fires on release, after on_forward_button_up) only used on the game over screen
	if is_game_over:
		super.on_forward_button_pressed()

func _input(event: InputEvent) -> void:
	if not (event is InputEventScreenTouch) or not is_running or is_game_over:
		return
	if event.pressed:
		var j := _pump_at(event.position)
		if j >= 0:
			if not _pump_active(j):
				_sfx("res://sounds/fx/underwater-247531.mp3", -14.0, 0.6)
			_touch_jets[event.index] = j
	else:
		_touch_jets.erase(event.index)

## Which pump button a screen position is on (0 = main, 1 = forward, -1 = neither)
func _pump_at(screen_pos: Vector2) -> int:
	var paths := ["/root/PoopPal/Main UI/MainButton", "/root/PoopPal/Main UI/SoundButtons/ForwardButton"]
	for i in paths.size():
		var b := get_node_or_null(paths[i]) as Control
		if b and (b.get_global_transform_with_canvas() * Rect2(Vector2.ZERO, b.size)).grow(20).has_point(screen_pos):
			return i
	return -1

func _pump_active(i: int) -> bool:
	return jets[i]["held"] or i in _touch_jets.values()

func _pump(i: int, down: bool) -> void:
	var was := _pump_active(i)
	jets[i]["held"] = down
	if down and not was:
		_sfx("res://sounds/fx/underwater-247531.mp3", -14.0, 0.6)

func end_game() -> void:
	jets[0]["held"] = false
	jets[1]["held"] = false
	super.end_game()        # (its overlay is added last, so it covers the baskets)
