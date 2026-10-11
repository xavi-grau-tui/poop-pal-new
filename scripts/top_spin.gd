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
## Desktop: arrows / WASD tilt, Space = MAIN, Shift or X = FORWARD.

const GAME_INDEX := 8

# --- Stadium (play-area coordinates, 950x948) ---
const C_FULL := Vector2(475, 500)     # bowl centre
const R_FULL := 370.0                 # bowl radius (inside the rim; room for the controls below)
const C_TUT := Vector2(475, 620)      # the tutorial's bowl: smaller and lower, so the coach's
const R_TUT := 262.0                  # card above it never covers the action
const PX := 4                         # world px per stadium pixel
const DETAIL := 3                     # world px per texture px for the tops
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
const LIVES := 3

# --- Palette (a ceramic bowl, slate blue like the card) ---
const BG := Color8(58, 66, 84)
const OUTLINE := Color8(36, 40, 54)
# --- the bowl: blue-grey turned wood (wood reads by its grain and lathe rings, not by brown) ---
const WOOD := Color8(170, 184, 198)          # the floor
const WOOD_GRAIN := Color8(154, 170, 188)    # grain lines
const WOOD_LIGHT := Color8(186, 198, 210)    # lighter grain / the lit far side
const LATHE := Color8(140, 156, 176)         # the turned rings
const RIM := Color8(92, 110, 136)            # indigo-stained rim
const RIM_HI := Color8(128, 146, 172)        # its lit bevel (top-left)
const RIM_DARK := Color8(66, 80, 104)        # its shaded edge / grain streaks
const RIM_W := 44.0                          # the rim's thickness (world px), outside R
const GAP := Color8(22, 24, 32)
const SLIME := Color8(140, 186, 92)
const SLIME_DARK := Color8(96, 138, 60)
const GOLD := Color8(240, 196, 80)
const PLAYER_COLOR := Color8(232, 140, 64)

## Rival styles: how they move and fight
const STYLES := {
	"rookie":  { "color": Color8(150, 190, 120), "mass": 0.9, "attack": 0.7, "seek": 0.25, "dash_every": 0.0, "brace": 0.0, "center": 0.0, "size": 1.0 },
	"charger": { "color": Color8(214, 92, 92), "mass": 1.0, "attack": 1.1, "seek": 1.0, "dash_every": 1.8, "brace": 0.0, "center": 0.0, "size": 1.0 },
	"wall":    { "color": Color8(120, 150, 210), "mass": 1.3, "attack": 0.9, "seek": 0.15, "dash_every": 0.0, "brace": 0.6, "center": 1.0, "size": 1.0 },
	"heavy":   { "color": Color8(150, 120, 100), "mass": 1.9, "attack": 1.3, "seek": 0.5, "dash_every": 3.5, "brace": 0.2, "center": 0.3, "size": 1.15 },
	"boss":    { "color": Color8(170, 100, 200), "mass": 1.6, "attack": 1.3, "seek": 0.8, "dash_every": 2.2, "brace": 0.4, "center": 0.2, "size": 1.35 },
}

## Levels: rivals [style, starting spin], bumpers and slime puddles (offsets from the centre),
## number of gaps in the rim. After the last one the last four repeat, a bit tougher each time.
const LEVELS := [
	{ "rivals": [["rookie", 60]], "bumpers": [], "slime": [], "gaps": 3 },
	{ "rivals": [["charger", 70]], "bumpers": [], "slime": [], "gaps": 3 },
	{ "rivals": [["wall", 85]], "bumpers": [Vector2(-170, -60), Vector2(170, -60)], "slime": [], "gaps": 3 },
	{ "rivals": [["heavy", 90]], "bumpers": [], "slime": [Vector2(-150, 120), Vector2(160, 90)], "gaps": 4 },
	{ "rivals": [["charger", 70], ["rookie", 60]], "bumpers": [], "slime": [], "gaps": 3 },
	{ "rivals": [["charger", 80], ["wall", 80]], "bumpers": [Vector2(0, -200), Vector2(-190, 130), Vector2(190, 130)], "slime": [], "gaps": 3 },
	{ "rivals": [["heavy", 90], ["charger", 80]], "bumpers": [Vector2(-200, -40), Vector2(200, -40)], "slime": [Vector2(0, 190)], "gaps": 4 },
	{ "rivals": [["boss", 140]], "bumpers": [Vector2(-210, 0), Vector2(210, 0)], "slime": [Vector2(0, -190), Vector2(0, 200)], "gaps": 2 },
]

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
	var trail := PackedVector2Array() # recent positions while dashing
	var wob := 0.0                    # (a random phase for its wobble)
	var root: Node2D
	var body: Sprite2D
	var cap: Sprite2D
	var shadow: Sprite2D

enum Phase { WIND, DROP, BATTLE, RESULT }
var C := C_FULL                       # (the bowl in use: full size, or the tutorial's)
var R := R_FULL
## First-time tutorial: one step at a time, each waits until you've done it
enum Tut { NONE, WIND, DROP, MOVE, DASH, DASHED, GUARD, GUARDED, FIGHT }

var phase := Phase.WIND
var level := 1
var lives := LIVES
var loop := 0                         # times round the level list (tougher rivals)
var time := 0.0

var tops: Array[Top] = []
var player: Top
var bumpers: Array[Vector2] = []
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

var stadium: Sprite2D
var bumper_nodes: Node2D
var top_nodes: Node2D
var fx: Node2D
var overlay: Node2D
var hud_level: Label
var under: Node2D                     # (dash trails, drawn under the tops)
var banner: Label
var lives_box: HBoxContainer
var lcd_font: Font
var ball_texture: Texture2D
var shadow_tex: Texture2D

func _ready() -> void:
	game_music_path = "res://sounds/music/Pixel Battle.ogg"     # (100 BPM, loops on the beat: 0.163 s → 127.363 s)
	lcd_font = load("res://fonts/pixChicago.ttf")
	ball_texture = PalBall.texture()
	shadow_tex = _make_shadow_texture()
	_create_static_nodes()
	if GameData.intro_seen(GAME_INDEX):
		intro_text = "Wind it up, drop it, knock them out!"
		intro_icon = _make_top_texture(PLAYER_COLOR)
	else:
		tut = Tut.WIND                     # first time: a short tutorial instead of the card
	super._ready()

func start_game() -> void:
	super.start_game()
	level = 1
	lives = LIVES
	loop = 0
	_start_match()

# ================================================================== MATCH SETUP

func _level_data() -> Dictionary:
	var i := level - 1
	if i >= LEVELS.size():
		i = LEVELS.size() - 4 + (i - LEVELS.size()) % 4
	return LEVELS[i]

func _start_match() -> void:
	loop = maxi(0, (level - 1 - LEVELS.size()) / 4 + 1) if level > LEVELS.size() else 0
	C = C_TUT if tut != Tut.NONE else C_FULL         # (the tutorial's bowl is smaller and lower)
	R = R_TUT if tut != Tut.NONE else R_FULL
	stadium.position = C
	var data := _level_data()
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
	stadium.texture = ImageTexture.create_from_image(_paint_stadium())
	for c in bumper_nodes.get_children():
		c.queue_free()
	var btex := _make_bumper_texture()
	for b in bumpers:
		var s := Sprite2D.new()
		s.texture = btex
		s.scale = Vector2(DETAIL, DETAIL)
		s.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		s.position = b
		bumper_nodes.add_child(s)

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

	perfects = 0
	wind_spin = WIND_START
	wind_left = WIND_TIME
	needle = 0.0
	zone = randf() * TAU
	combo = 0
	phase = Phase.WIND
	dropping = false
	forward_held = false
	player.root.position = C
	player.root.scale = Vector2(2.2, 2.2)
	player.shadow.visible = false
	practice = tut != Tut.NONE
	hud_level.text = "TUTORIAL" if practice else "LV %d" % level
	_set_legend("PULL", "DONE")
	_refresh_lives()
	if tut == Tut.WIND:
		show_coach("Tap when the needle is on GOLD", 0, "FORWARD: skip tutorial")

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
	t.root = Node2D.new()
	t.root.scale = Vector2(size, size)
	top_nodes.add_child(t.root)
	t.shadow = Sprite2D.new()
	t.shadow.texture = shadow_tex
	t.shadow.scale = Vector2(DETAIL, DETAIL) * 1.4
	t.shadow.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	t.shadow.position = Vector2(8, 16)
	t.root.add_child(t.shadow)
	t.body = Sprite2D.new()
	t.body.texture = _make_top_texture(color)
	t.body.scale = Vector2(DETAIL, DETAIL)
	t.body.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	t.root.add_child(t.body)
	t.cap = Sprite2D.new()
	t.cap.texture = ball_texture if is_player else _make_rival_face(color)
	t.cap.scale = Vector2(DETAIL, DETAIL) * 0.85
	t.cap.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	t.root.add_child(t.cap)
	return t

# ================================================================== LOOP

func _process(delta: float) -> void:
	overlay.queue_redraw()
	under.queue_redraw()
	if not is_running:
		return
	time += delta
	bar_flash = maxf(0.0, bar_flash - delta)
	match phase:
		Phase.WIND:
			_wind_step(delta)
		Phase.DROP:
			_drop_step(delta)
		Phase.BATTLE:
			_battle_step(delta)
	_animate_tops(delta)
	_update_legend()

func _wind_step(delta: float) -> void:
	needle = fposmod(needle + (2.6 + wind_spin * 0.025) * (0.8 if tut == Tut.WIND else 1.0) * delta, TAU)
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
	if off >= ZONE_HALF:
		combo = 0
		wind_jam = WIND_JAM
		wind_spin = maxf(WIND_START, wind_spin - WIND_SLIP)
		_sfx("res://sounds/fx/click-5.mp3", -12.0, 0.0, 0.6)
		_float_text("SLIP!", C + Vector2(0, -230))
		Input.vibrate_handheld(40)
		return                                         # (the gold zone stays put: try again)
	var gain := 0.0
	if off < ZONE_HALF:
		combo += 1
		gain = WIND_GOOD + combo * 2.0
		_sfx("res://sounds/fx/click-6.mp3", -8.0, 0.0, 1.0 + combo * 0.08)
		_float_text("GOOD!" if combo < 3 else "GREAT!", C + Vector2(0, -230))
		if tut == Tut.WIND:
			tut_good += 1
			if tut_good == 1:
				show_coach("Yes! Every gold tap = more spin", 0)
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
	drop_left = 3.5
	aim = C
	calibrate_tilt()
	# it rises smoothly from where it was wound (no jump): lift goes 0 → 1
	lift = 0.0
	create_tween().tween_property(self, "lift", 1.0, 0.35).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	_set_legend("DROP", "")
	if tut == Tut.WIND:
		tut = Tut.DROP
		show_coach("Tilt to aim, then tap to DROP", 0)
	if wind_spin > 100.0:
		_show_banner("OVER-WOUND!", 0.8)

func _drop_step(delta: float) -> void:
	if dropping:
		return
	aim += _read_tilt() * 520.0 * delta
	var off := aim - C
	if off.length() > R - 80.0:
		aim = C + off.limit_length(R - 80.0)
	player.root.position = aim + Vector2(0, -110.0 * lift)
	player.root.scale = Vector2.ONE * lerpf(2.2, 1.8, lift)
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
	t.tween_property(player.root, "position", aim, 0.3).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_QUAD)
	t.parallel().tween_property(player.root, "scale", Vector2.ONE, 0.3).set_ease(Tween.EASE_IN)
	t.tween_callback(_land)

func _land() -> void:
	if not is_running:
		return
	player.pos = aim
	player.vel = Vector2.ZERO
	player.shadow.visible = true
	_sfx("res://sounds/fx/wood_tap.wav", -10.0, 0.0, 0.7)
	Input.vibrate_handheld(40)
	for o in tops:
		if o == player:
			continue
		var d := o.pos - player.pos
		if d.length() < (player.r + o.r) * 1.3:
			o.spin -= 12.0
			o.vel += d.normalized() * 520.0
			_sparks(player.pos + d * 0.5, 10)
			_float_text("OPENING HIT!", player.pos + Vector2(0, -80))
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
	if tut == Tut.MOVE:
		tut_dist += player.vel.length() * delta
		if tut_dist > 700.0:
			tut = Tut.DASH
			show_coach("Tap to DASH into it!", 0)
	for t in tops:
		if not t.alive:
			continue
		t.brace_t += delta
		t.dash_t += delta
		t.dash_cd = maxf(0.0, t.dash_cd - delta)
		t.unsteady = maxf(0.0, t.unsteady - delta)
		if t.dash_t < DASH_TIME + 0.05:
			t.trail.append(t.pos)
		if t.trail.size() > 8 or (t.trail.size() > 0 and t.dash_t >= DASH_TIME + 0.05):
			t.trail.remove_at(0)
		if t.windup > 0.0:                         # the warning's over: here it comes
			t.windup -= delta
			if t.windup <= 0.0 and player.alive:
				_dash(t, player.pos - t.pos + player.vel * 0.15)
		if not t.is_player:
			if tut == Tut.GUARD:
				_tut_attack(t, delta)
			elif not learning:
				_rival_think(t, delta)
		if learning:
			t.spin = maxf(t.spin, 40.0)               # nobody gets knocked out while learning
			continue
		t.spin -= (DECAY + (BRACE_DRAIN if t.braced else 0.0)) * delta
		for s in slimes:
			if t.pos.distance_to(s) < 70.0:
				t.spin -= 7.0 * delta
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

	for b in bumpers:
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

func _in_gap(angle: float) -> bool:
	for g in gap_angles:
		if absf(angle_difference(angle, g)) < GAP_HALF:
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
	# PERFECT guard: the guard went up just before the hit
	if a.braced and a.brace_t < PERFECT_WINDOW:
		dmg_a = 0.0
		dmg_b += 10.0
		a.spin += 6.0
		b.vel += n * 520.0
		_perfect(a, b)
	elif b.braced and b.brace_t < PERFECT_WINDOW:
		dmg_b = 0.0
		dmg_a += 10.0
		b.spin += 6.0
		a.vel -= n * 520.0
		_perfect(b, a)
	a.spin -= dmg_a
	b.spin -= dmg_b
	if a.is_player or b.is_player:
		_tut_hit(a.brace_t < PERFECT_WINDOW if a.is_player else b.brace_t < PERFECT_WINDOW)
	if impact > 80.0:
		_sparks(a.pos + n * a.r, int(clampf(impact / 60.0, 3, 12)))
		_sfx("res://sounds/fx/pin_bumper.wav", clampf(-26.0 + impact / 40.0, -24.0, -4.0), 0.0, randf_range(0.9, 1.15))
		if a.is_player or b.is_player:
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
	if guard.is_player:
		perfects += 1
		_float_text("PERFECT!", guard.pos + Vector2(0, -80))
	elif hitter.is_player:
		_float_text("GUARDED!", hitter.pos + Vector2(0, -80))

func _dash(t: Top, dir: Vector2) -> void:
	if t.dash_cd > 0.0 or dir == Vector2.ZERO or t.spin <= DASH_COST:
		return
	dir = dir.normalized()
	t.vel = dir * maxf(t.vel.dot(dir), 0.0) * 0.3 + dir * DASH_SPEED
	t.spin -= DASH_COST
	t.dash_t = 0.0
	t.dash_cd = 0.45
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
	return maxf(WINDUP_MIN, WINDUP - 0.035 * (level - 1))

# ================================================================== OUT / RESULT

func _topple(t: Top) -> void:
	t.alive = false
	t.spin = 0.0
	t.braced = false
	_sfx("res://sounds/fx/clack.mp3", -10.0, 0.0, 0.7)
	var tw := create_tween()
	tw.tween_property(t.root, "rotation", 0.5 * t.dir, 0.25)
	tw.parallel().tween_property(t.root, "scale", t.root.scale * Vector2(1.15, 0.8), 0.25)
	tw.parallel().tween_property(t.root, "modulate", Color(0.55, 0.55, 0.6, 1), 0.25)
	tw.tween_property(t.root, "modulate:a", 0.0, 0.8).set_delay(0.6)
	if not t.is_player:
		add_score(25)
		_float_text("SPUN OUT!", t.pos + Vector2(0, -70))

func _ring_out(t: Top) -> void:
	t.alive = false
	t.braced = false
	_sfx("res://sounds/fx/sfx_sounds_falling4.wav", -12.0, 0.8)
	var out := t.pos + (t.pos - C).normalized() * 120.0
	var tw := create_tween()
	tw.tween_property(t.root, "position", out, 0.45)
	tw.parallel().tween_property(t.root, "scale", t.root.scale * 0.4, 0.45)
	tw.parallel().tween_property(t.root, "modulate:a", 0.0, 0.45)
	if not t.is_player:
		add_score(40)
		_float_text("RING OUT!", t.pos + Vector2(0, -70))

func _check_match_end() -> void:
	if not player.alive or tops.all(func(t): return t == player or not t.alive):
		if tut != Tut.NONE:
			_finish_tutorial()
	if not player.alive:
		phase = Phase.RESULT
		lives -= 1
		_refresh_lives()
		_show_banner("KNOCKED OUT", 1.2)
		_after(1.8, func():
			if lives <= 0:
				end_game()
			else:
				_start_match())
		return
	for t in tops:
		if t != player and t.alive:
			return
	phase = Phase.RESULT
	player.braced = false
	if practice:                                  # the tutorial's done: now the real level 1
		_sfx("res://sounds/fx/unlock_ding.wav", -8.0)
		_show_banner("TUTORIAL DONE!", 1.2)
		_after(1.8, func():
			_start_match()
			_show_banner("LEVEL %d" % level, 0.8))
		return
	var bonus := 100 + int(player.spin) + 30 * perfects
	add_score(bonus)
	_sfx("res://sounds/fx/unlock_ding.wav", -8.0)
	Input.vibrate_handheld(60)
	_show_banner("LEVEL %d CLEAR!\n+%d" % [level, bonus], 1.4)
	_after(2.0, func():
		level += 1
		_start_match()
		_show_banner("LEVEL %d" % level, 0.8))

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

func _animate_tops(delta: float) -> void:
	for t in tops:
		if not is_instance_valid(t.root):
			continue
		var spinning := t.alive or phase == Phase.WIND
		if spinning:
			t.body.rotation += (4.0 + maxf(t.spin, 0.0) * 0.18) * delta * t.dir
		if t.alive and (phase == Phase.BATTLE or (t != player and phase != Phase.RESULT)):
			t.root.position = t.pos
		# a slow or over-wound top wobbles (the pal riding it rocks about)
		var w := clampf((25.0 - t.spin) / 25.0, 0.0, 1.0) + minf(t.unsteady, 1.0)
		if not t.alive:
			w = 0.0
		t.cap.position = Vector2(sin(time * 17.0 + t.wob) * 5.0, cos(time * 13.0 + t.wob) * 3.0) * w
		t.body.position = t.cap.position * 0.4
		# guarding: the top squats down (darker, a touch smaller)
		var target := Color(0.72, 0.76, 0.9) if t.braced else Color.WHITE
		t.body.modulate = t.body.modulate.lerp(target, minf(1.0, delta * 20.0))

## Dash trails: fading copies of the top's outline behind it
func _draw_under() -> void:
	for t in tops:
		var n := t.trail.size()
		for i in n:
			var k := float(i + 1) / (n + 1)
			under.draw_circle(t.trail[i], t.r * (0.5 + 0.5 * k), Color(t.color, 0.35 * k))

func _draw_overlay() -> void:
	if not is_running and not is_game_over and not intro_active():
		return
	_draw_hud()
	if phase == Phase.WIND:
		overlay.draw_rect(Rect2(0, 100, PLAY_WIDTH, PLAY_HEIGHT - 100), Color(0, 0, 0, 0.35))
		var rr := 170.0
		overlay.draw_arc(C, rr, 0, TAU, 64, OUTLINE, 22)
		overlay.draw_arc(C, rr, 0, TAU, 64, RIM, 14)
		overlay.draw_arc(C, rr, zone - ZONE_HALF, zone + ZONE_HALF, 16, GOLD, 16)
		var tip := C + Vector2.from_angle(needle) * (rr + 22)
		overlay.draw_line(C + Vector2.from_angle(needle) * (rr - 30), tip, OUTLINE, 14)
		overlay.draw_line(C + Vector2.from_angle(needle) * (rr - 26), tip - Vector2.from_angle(needle) * 3, Color8(240, 80, 70) if wind_jam > 0.0 else Color.WHITE, 8)
		_draw_gauge()
		var l := Rect2(C.x - 60, C.y + 220, 120, 12)
		overlay.draw_rect(l, OUTLINE)
		overlay.draw_rect(Rect2(l.position, Vector2(l.size.x * maxf(wind_left, 0.0) / WIND_TIME, l.size.y)), Color8(250, 240, 210))
	elif phase == Phase.BATTLE:
		for t in tops:
			if not t.alive:
				continue
			if t.braced:                              # GUARD: a shield ring (white = PERFECT window)
				var fresh := t.brace_t < PERFECT_WINDOW
				overlay.draw_arc(t.pos, t.r + 10, 0, TAU, 40, OUTLINE, 12)
				overlay.draw_arc(t.pos, t.r + 10, 0, TAU, 40, Color.WHITE if fresh else Color8(150, 200, 255), 7)
			if t.windup > 0.0:                        # about to DASH: a flashing red ring and "!"
				var on := fmod(t.windup, 0.16) < 0.08
				overlay.draw_arc(t.pos, t.r + 16, 0, TAU, 40, Color8(240, 70, 60) if on else Color8(255, 200, 80), 6)
				if lcd_font:
					overlay.draw_string(lcd_font, t.pos + Vector2(-10, -t.r - 22), "!", HORIZONTAL_ALIGNMENT_LEFT, -1, 44, Color8(240, 70, 60))
	elif phase == Phase.DROP and not dropping:
		var p := 0.5 + 0.5 * sin(time * 10.0)
		overlay.draw_arc(aim, TOP_R + 6 + p * 6, 0, TAU, 32, OUTLINE, 6)
		overlay.draw_arc(aim, TOP_R + 6 + p * 6, 0, TAU, 32, GOLD, 3)

## The spin gauge while winding (gold up to 100%, red above: over-wound)
func _draw_gauge() -> void:
	var r := Rect2(70, 330, 44, 360)
	overlay.draw_rect(r.grow(5), OUTLINE)
	overlay.draw_rect(r, Color8(70, 78, 96))
	var f := wind_spin / WIND_MAX
	var h := r.size.y * f
	var col := GOLD if wind_spin <= 100.0 else Color8(232, 86, 70)
	overlay.draw_rect(Rect2(r.position.x, r.end.y - h, r.size.x, h), col)
	var y100 := r.end.y - r.size.y * 100.0 / WIND_MAX
	overlay.draw_line(Vector2(r.position.x - 8, y100), Vector2(r.end.x + 8, y100), Color.WHITE, 4)

## Spin bars: yours on the left, the rivals' on the right
func _draw_hud() -> void:
	_spin_bar(Rect2(30, 30, 300, 26), player)
	var y := 26.0
	for t in tops:
		if t == player:
			continue
		_spin_bar(Rect2(PLAY_WIDTH - 260, y, 230, 16), t)
		y += 24.0

func _spin_bar(r: Rect2, t: Top) -> void:
	if t == null:
		return
	overlay.draw_rect(r.grow(4), OUTLINE)
	overlay.draw_rect(r, Color8(70, 78, 96))
	var f := clampf(t.spin / 100.0, 0.0, 1.0)
	var col := t.color
	if t.spin < 25.0 and t.alive and fmod(time, 0.4) < 0.2:
		col = Color8(240, 80, 70)
	if not t.alive:
		col = Color8(90, 90, 100)
	overlay.draw_rect(Rect2(r.position, Vector2(r.size.x * f, r.size.y)), col)
	if t.braced:
		overlay.draw_rect(r.grow(4), Color8(160, 200, 255), false, 3)
	if t == player and bar_flash > 0.0 and fmod(bar_flash, 0.3) < 0.15:
		overlay.draw_rect(r.grow(8), Color.WHITE, false, 5)        # (the tutorial points at it)

func _sparks(at: Vector2, n: int) -> void:
	for i in n:
		var s := ColorRect.new()
		s.size = Vector2(8, 8)
		s.color = Color8(255, 236, 160) if i % 2 == 0 else Color.WHITE
		s.position = at - s.size / 2.0
		fx.add_child(s)
		var to := s.position + Vector2.from_angle(randf() * TAU) * randf_range(30, 90)
		var tw := create_tween()
		tw.tween_property(s, "position", to, 0.25).set_ease(Tween.EASE_OUT)
		tw.parallel().tween_property(s, "modulate:a", 0.0, 0.25)
		tw.tween_callback(s.queue_free)

# ================================================================== NODES / TEXTURES

func _create_static_nodes() -> void:
	var bg := ColorRect.new()
	bg.color = BG
	bg.size = Vector2(PLAY_WIDTH, PLAY_HEIGHT)
	add_child(bg)
	stadium = Sprite2D.new()
	stadium.position = C
	stadium.scale = Vector2(PX, PX)
	stadium.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	add_child(stadium)
	bumper_nodes = Node2D.new()
	add_child(bumper_nodes)
	under = Node2D.new()
	under.draw.connect(_draw_under)
	add_child(under)
	top_nodes = Node2D.new()
	add_child(top_nodes)
	fx = Node2D.new()
	add_child(fx)
	overlay = Node2D.new()
	overlay.draw.connect(_draw_overlay)
	add_child(overlay)

	hud_level = _make_label(Vector2(PLAY_WIDTH / 2 - 100, 18), Vector2(200, 50), 36, HORIZONTAL_ALIGNMENT_CENTER, Color(0.95, 0.96, 1.0))
	lives_box = HBoxContainer.new()
	lives_box.position = Vector2(30, 66)
	lives_box.add_theme_constant_override("separation", 6)
	add_child(lives_box)
	# the control legend along the bottom (what each button does right now)
	hint_main = make_button_hint(0, "PULL")
	hint_main.position = Vector2(72, PLAY_HEIGHT - 86)             # (clear of the screen's rounded corners)
	hint_fwd = make_button_hint(1, "DONE")
	hint_fwd.position = Vector2(PLAY_WIDTH - 250, PLAY_HEIGHT - 86)
	banner = _make_label(Vector2(0, C.y - 60), Vector2(PLAY_WIDTH, 120), 54, HORIZONTAL_ALIGNMENT_CENTER, Color(1, 0.97, 0.9))
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

func _refresh_lives() -> void:
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

## The bowl seen from above: an even, flat floor of blue-grey turned wood (wavy grain, lathe
## rings; no shading, it read as dirt), a thick indigo rim with its grain running round and a lit
## bevel, gaps cut through it (ring-outs), and slime puddles (hard pixels, no blending)
func _paint_stadium() -> Image:
	var n := int(ceil((R + RIM_W + 4.0) * 2.0 / PX))
	var img := Image.create(n, n, false, Image.FORMAT_RGBA8)
	var half := n / 2.0
	for y in n:
		for x in n:
			var d := (Vector2(x + 0.5, y + 0.5) - Vector2(half, half)) * PX
			var r := d.length()
			var ang := d.angle()
			var lit := d.x + d.y < -r * 0.25           # the top-left side
			var col := Color(0, 0, 0, 0)
			if r > R + RIM_W:
				pass
			elif r > R - 8.0:
				# --- the rim (its dark outlines two pixels thick) ---
				if _in_gap(ang):
					col = GAP
					var edge := absf(absf(angle_difference(ang, _nearest_gap(ang))) - GAP_HALF) * r
					if edge < 6.0 and r > R:
						col = RIM_DARK                   # the gap's cut side walls
				elif r < R or r > R + RIM_W - 8.0:
					col = OUTLINE
				else:
					var g := sin(r * 0.35 + sin(ang * 9.0 + r * 0.02) * 1.8)
					col = RIM_DARK if g > 0.75 else RIM
					if r > R + RIM_W - 16.0:
						col = RIM_HI if lit else RIM_DARK    # outer bevel: lit top-left, shaded bottom-right
					elif r < R + 8.0 and not lit:
						col = RIM_HI                         # inner lip catches the light on the far side
			else:
				# --- the floor ---
				var g := sin(d.y * 0.11 + sin(d.x * 0.012 + d.y * 0.004) * 2.6 + sin(d.x * 0.031) * 0.6)
				col = WOOD
				if g > 0.72:
					col = WOOD_GRAIN
				elif g < -0.9:
					col = WOOD_LIGHT
				if r > 40.0 and fposmod(r, 52.0) < float(PX):      # (one whole pixel wide: no broken ticks)
					col = LATHE                              # the turned rings
				if r < 16.0 and r > 9.0:
					col = LATHE                              # the lathe's centre mark
				if r > R - 40.0 and _in_gap(ang):
					col = col.darkened(0.12)                 # a faint strip leading into each gap (the way out)
			for s in slimes:
				var sd := (C + d).distance_to(s) + sin(ang * 5.0 + s.x) * 6.0
				if sd < 70.0:
					col = SLIME if sd < 64.0 else SLIME_DARK
			img.set_pixel(x, y, col)
	return img

func _nearest_gap(ang: float) -> float:
	var best := 0.0
	var bd := 99.0
	for g in gap_angles:
		var dd := absf(angle_difference(ang, g))
		if dd < bd:
			bd = dd
			best = g
	return best

## A spinning top from above: four blades round a dark hub (so you can see it turn)
func _make_top_texture(color: Color) -> Texture2D:
	const S := 26
	var img := Image.create(S, S, false, Image.FORMAT_RGBA8)
	var c := Vector2(S / 2.0, S / 2.0)
	for y in S:
		for x in S:
			var off := Vector2(x + 0.5, y + 0.5) - c
			var d := off.length()
			var a := fposmod(off.angle() * 4.0 / TAU, 1.0)        # 0..1 across each blade
			var edge := 12.5 - (2.0 if a > 0.7 else 0.0)            # notches between the blades
			if d > edge:
				continue
			var col := color
			if d > edge - 1.2:
				col = OUTLINE
			elif d < 7.0:
				col = color.darkened(0.45)                          # the hub (the pal sits here)
			elif a < 0.18:
				col = color.lightened(0.35)                         # leading edge of a blade
			elif a > 0.55:
				col = color.darkened(0.2)
			img.set_pixel(x, y, col)
	return ImageTexture.create_from_image(img)

## A rival's face on top of its top: a ball in its colour, angry brows
func _make_rival_face(color: Color) -> Texture2D:
	const S := 20
	var img := Image.create(S, S, false, Image.FORMAT_RGBA8)
	var c := Vector2(S / 2.0, S / 2.0)
	var face := color.lightened(0.3)
	for y in S:
		for x in S:
			var off := Vector2(x + 0.5, y + 0.5) - c
			var d := off.length()
			if d > 8.0:
				continue
			var col := face if off.x + off.y < 2.0 else face.darkened(0.15)
			if d > 7.0:
				col = OUTLINE
			img.set_pixel(x, y, col)
	img.set_pixel(7, 7, Color.WHITE)
	for p in [Vector2i(7, 10), Vector2i(7, 11), Vector2i(12, 10), Vector2i(12, 11)]:
		img.set_pixel(p.x, p.y, OUTLINE)                            # eyes
	for p in [Vector2i(6, 8), Vector2i(7, 9), Vector2i(13, 8), Vector2i(12, 9)]:
		img.set_pixel(p.x, p.y, OUTLINE)                            # angry brows
	for p in [Vector2i(9, 13), Vector2i(10, 13)]:
		img.set_pixel(p.x, p.y, OUTLINE)                            # mouth
	return ImageTexture.create_from_image(img)

## A bouncer: a turned wooden peg in the rim's indigo, seen from above (lighter top, a lathe
## ring, a little brass dot in the middle), so it belongs to the same toy
func _make_bumper_texture() -> Texture2D:
	const S := 20
	var img := Image.create(S, S, false, Image.FORMAT_RGBA8)
	var c := Vector2(S / 2.0, S / 2.0)
	for y in S:
		for x in S:
			var off := Vector2(x + 0.5, y + 0.5) - c
			var d := off.length()
			if d > 9.5:
				continue
			var col := RIM
			if d > 8.5:
				col = OUTLINE
			elif d > 7.0:
				col = RIM_HI if off.x + off.y < 0 else RIM_DARK      # the peg's edge: lit top-left
			elif d > 5.6 and d < 6.6:
				col = RIM_DARK                                       # a lathe ring on its top
			elif d < 2.2:
				col = Color8(226, 190, 104) if off.x + off.y < 0 else Color8(176, 136, 64)   # brass dot
			elif off.x + off.y < -2.0:
				col = RIM_HI
			img.set_pixel(x, y, col)
	return ImageTexture.create_from_image(img)

func _make_shadow_texture() -> Texture2D:
	var img := Image.create(13, 7, false, Image.FORMAT_RGBA8)
	for y in 7:
		for x in 13:
			var off := Vector2((x + 0.5 - 6.5) / 6.5, (y + 0.5 - 3.5) / 3.5)
			var l := off.length()
			if l <= 1.0:
				img.set_pixel(x, y, Color(0.1, 0.1, 0.2, 0.3 if l < 0.7 else 0.16))
	return ImageTexture.create_from_image(img)

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
	if is_game_over:
		super.on_main_button_pressed()
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
	pass

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
	if is_game_over:
		super.on_forward_button_pressed()

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
	banner.text = text
	var t := create_tween()
	t.tween_property(banner, "modulate:a", 1.0, 0.15)
	t.tween_interval(hold)
	t.tween_property(banner, "modulate:a", 0.0, 0.3)

func _float_text(text: String, at: Vector2) -> void:
	var lx := clampf(at.x - 200, 30, PLAY_WIDTH - 430)
	var l := _make_label(Vector2(lx, at.y - 40), Vector2(400, 40), 28, HORIZONTAL_ALIGNMENT_CENTER, Color(1, 0.95, 0.85))
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
