extends BaseMinigame
## Paper Sumo (prototype) — tontonzumo, the Japanese paper sumo toy. Two folded paper pals
## stand in a ring drawn on a cardboard box; drumming the box makes them hop and shuffle the
## way they lean. Push the rival out of the ring or make it fall over.
##
##   MAIN     = drum YOUR side: your wrestler hops forward (the way it leans). Tap right as it
##              lands = a strong, steady hop (keep the rhythm!); tapping while it's in the air
##              only makes it wobble.
##   FORWARD  = drum the FAR side: shakes the rival (wobbly if it's in the air, a little hop
##              towards you if it's standing). Risky.
##   TILT     = lean forward (pushes harder, falls easier) or back (steady; a rival leaning on
##              you falls on its face when you back off: the pull-down).
## Best of 3 bouts per rival; 3 lives.
##
## Desktop: Left / Right (A / D) lean, Space = MAIN, Shift or X = FORWARD.

const GAME_INDEX := 9

# --- Ring (play-area coordinates, 950x948) ---
const RING_C := Vector2(475, 690)     # the ring's centre; the wrestlers stand on this line
const RING_RX := 330.0
const RING_RY := 118.0
const RING_HALF := 300.0              # a foot past this (from the centre) = stepped out

# --- Wrestler physics ---
const GRAV := 5.0                     # paper falling over (grows with the lean)
const STIFF := 18.0                   # the folded base pulling it back to its lean
const MAX_HOLD := 4.5                 # ...but only this much
const DAMP := 5.0
const FALL := 1.1                     # lean (radians) = down
const HOP := 380.0
const G := 2400.0
const STEP := 650.0                   # forward speed of a hop per unit of sin(lean)
const LAND_NOISE := 0.8
const GOOD_WINDOW := 0.18             # tap this soon after landing = a good (rhythm) hop
const EARLY := 14.0                   # a tap this close above the box (on the way down) waits for the landing
const PUSH := 190.0                   # shove while leaning on each other
const TILT_GAIN := 2.2
const DEADZONE := 0.04
const INVERT_TILT := false
const LIVES := 3

# --- Palette ---
const WALL := Color8(236, 220, 192)
const WALL_LINE := Color8(222, 202, 170)
const BOX_TOP := Color8(196, 150, 96)
const BOX_LINE := Color8(176, 130, 80)
const BOX_FRONT := Color8(150, 108, 62)
const SAND := Color8(234, 212, 162)
const SAND_DARK := Color8(214, 190, 138)
const ROPE := Color8(206, 176, 96)
const ROPE_DARK := Color8(150, 120, 56)
const OUTLINE := Color8(70, 44, 30)
const PAPER := Color8(250, 248, 240)
const PAPER_SHADE := Color8(226, 222, 210)
const SKIN := Color8(244, 200, 168)
const TEXT := Color(1, 0.97, 0.9)

## Rivals: other pals folded out of paper, each with its own way of fighting
##   lean = how far forward it likes to lean; rhythm = chance a hop is on the beat;
##   tempo = its pause after landing; far = taps on your side per second; pull = pull-down habit
const RIVALS := [
	{ "name": "PEBBLE", "mass": 0.8, "lean": 0.12, "rhythm": 0.4, "tempo": 0.20, "far": 0.0, "pull": 0.0 },
	{ "name": "BRICK", "mass": 1.6, "lean": 0.22, "rhythm": 0.55, "tempo": 0.30, "far": 0.0, "pull": 0.0 },
	{ "name": "SLICK", "mass": 1.0, "lean": 0.18, "rhythm": 0.6, "tempo": 0.16, "far": 0.0, "pull": 0.8 },
	{ "name": "RUMBLER", "mass": 1.1, "lean": 0.2, "rhythm": 0.6, "tempo": 0.18, "far": 1.0, "pull": 0.0 },
	{ "name": "YOKOZUNA", "mass": 1.5, "lean": 0.25, "rhythm": 0.85, "tempo": 0.12, "far": 0.5, "pull": 0.4 },
]

class Wrestler:
	var x := 0.0
	var y := 0.0                      # height above the box (negative = up)
	var vx := 0.0
	var vy := 0.0
	var lean := 0.0                   # radians, + = towards the rival
	var spin := 0.0                   # lean speed
	var target := 0.1                 # the lean it holds itself at
	var facing := 1.0                 # +1 faces right (the player, on the left)
	var mass := 1.0
	var half := 50.0                  # half the card's width at the feet
	var grounded := true
	var ground_t := 0.0               # time since it landed
	var combo := 0
	var down := false
	var supported := false            # leaning on the rival this frame
	var ai: Dictionary = {}
	var ai_wait := -1.0
	var pull_t := 0.0                 # (rival) stepping back for a pull-down
	var buffered := false             # tapped just before landing: hops as it lands
	var root: Node2D
	var card: Sprite2D

enum Phase { READY, FIGHT, RESULT }
## First-time tutorial: one step at a time, each waits until you've done it
enum Tut { NONE, HOP, BEAT, LEAN, PUSH }

var phase := Phase.READY
var level := 1
var lives := LIVES
var wins := 0                         # bouts won against this rival
var losses := 0
var time := 0.0
var calib := Vector2.ZERO

var me: Wrestler
var rival: Wrestler
var rival_form := ""

var stage: Node2D
var wrestlers: Node2D
var fx: Node2D
var finger_l: Sprite2D
var finger_r: Sprite2D
var hud_level: Label
var hud_rival: Label
var bouts_box: HBoxContainer
var lives_box: HBoxContainer
var banner: Label
var hint_main: HBoxContainer          # control legend: HOP (main) and SHAKE (forward)
var hint_fwd: HBoxContainer
var tut := Tut.NONE
var tut_hops := 0
var tut_lean := 0.0                   # how long you've leant forward while learning
var tut_told_shake := false           # (after the tutorial) the forward button explained once
var lcd_font: Font
var ball_texture: Texture2D
var _cards := {}                      # path -> folded paper texture
var _touch_mode := false              # phone: taps come from _input, not the emulated mouse

func _ready() -> void:
	game_music_path = "res://sounds/music/Sunny Groove.mp3"
	lcd_font = load("res://fonts/pixChicago.ttf")
	ball_texture = PalBall.texture()
	_create_static_nodes()
	if GameData.intro_seen(GAME_INDEX):
		intro_text = "Drum the box in rhythm. Tilt to lean!"
		intro_icon = _make_card_texture(_my_form_path())
	else:
		tut = Tut.HOP                      # first time: a short tutorial instead of the card
	super._ready()

func start_game() -> void:
	super.start_game()
	level = 1
	lives = LIVES
	_new_rival()
	_start_bout()

# ================================================================== SETUP

func _my_form_path() -> String:
	if PetState.has_poop():
		return PetState.FORMS[PetState.form_id]["frames"][0]
	return "res://textures/pet/poo1-1.png"

func _rival_data() -> Dictionary:
	var d: Dictionary = RIVALS[mini(level - 1, RIVALS.size() - 1)].duplicate()
	if level > RIVALS.size():                      # past the yokozuna: it only gets tougher
		var extra := level - RIVALS.size()
		d["rhythm"] = minf(0.95, float(d["rhythm"]) + 0.02 * extra)
		d["mass"] = float(d["mass"]) + 0.05 * extra
		d["name"] = "YOKOZUNA %d" % (extra + 1)
	return d

func _new_rival() -> void:
	wins = 0
	losses = 0
	# a random other pal, folded out of paper
	var ids: Array = PetState.FORMS.keys()
	ids.erase(PetState.form_id)
	rival_form = ids[randi() % ids.size()] if ids.size() > 0 else ""
	hud_level.text = "LV %d" % level
	hud_rival.text = "VS " + str(_rival_data()["name"])

func _start_bout() -> void:
	for c in wrestlers.get_children():
		c.queue_free()
	me = _make_wrestler(_my_form_path(), 1.0)
	me.x = RING_C.x - 140.0
	var path := "res://textures/pet/forms/%s-1.png" % rival_form if rival_form != "" else _my_form_path()
	rival = _make_wrestler(path, -1.0)
	rival.x = RING_C.x + 140.0
	rival.ai = _rival_data()
	rival.mass = float(rival.ai["mass"])
	rival.target = float(rival.ai["lean"])
	rival.card.scale *= 0.9 + 0.15 * rival.mass                # heavier = a bigger card
	rival.half *= 0.9 + 0.15 * rival.mass
	calib = _sensor_tilt()
	_refresh_hud()
	phase = Phase.READY
	_show_banner("HAKKEYOI!", 0.7)
	_after(0.9, func():
		phase = Phase.FIGHT
		if tut == Tut.HOP:
			show_coach("Tap to make your pal HOP", 0, "FORWARD: skip tutorial")
		elif tut == Tut.NONE and not tut_told_shake and GameData.intro_seen(GAME_INDEX) and wins + losses == 1:
			tut_told_shake = true          # (the second bout of your first rival)
			show_coach("FORWARD drums ITS side: shake it mid-hop!", 1)
			_after(3.0, hide_coach))

func _make_wrestler(path: String, facing: float) -> Wrestler:
	var w := Wrestler.new()
	w.facing = facing
	w.lean = 0.1
	w.root = Node2D.new()
	wrestlers.add_child(w.root)
	var tex := _make_card_texture(path)
	w.card = Sprite2D.new()
	w.card.texture = tex
	w.card.centered = false
	w.card.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	var sz := tex.get_size()
	var s := clampf(150.0 / sz.y, 0.8, 3.0)                    # cards about the same height
	w.card.scale = Vector2(s * facing, s)                       # (the rival's is flipped)
	w.card.offset = Vector2(-sz.x / 2.0, -sz.y)                 # pivot at the feet
	w.half = minf(sz.x * s * 0.4, 80.0)
	w.root.add_child(w.card)
	return w

# ================================================================== LOOP

func _process(delta: float) -> void:
	stage.queue_redraw()
	if not is_running:
		return
	time += delta
	if phase == Phase.FIGHT:
		me.target = 0.12 + _read_tilt().x * me.facing * 0.32
		if tut == Tut.NONE:
			_rival_think(delta)
		const STEPS := 4
		for i in STEPS:
			_physics(delta / STEPS)
		_tut_step(delta)
		_check_bout()
	for w in [me, rival]:
		if w and is_instance_valid(w.root):
			w.root.position = Vector2(w.x, RING_C.y + w.y)
			if not w.down:
				w.root.rotation = w.lean * w.facing

func _physics(dt: float) -> void:
	# leaning on each other: the lean pushes, the pair slides towards the weaker push
	var gap := (rival.x - me.x) - (me.half + rival.half)
	var touching := gap <= 0.0
	me.supported = touching and me.lean > 0.0 and rival.lean > 0.0
	rival.supported = me.supported
	if touching:
		var f_me := me.mass * sin(me.lean) + (0.4 if not me.grounded else 0.0)
		var f_rv := rival.mass * sin(rival.lean) + (0.4 if not rival.grounded else 0.0)
		var shove := (f_me - f_rv) * PUSH / (me.mass + rival.mass)
		me.x += shove * dt
		rival.x += shove * dt
		# the harder push props the other one up (and back)
		me.spin -= maxf(0.0, f_rv - f_me) * 1.5 * dt
		rival.spin -= maxf(0.0, f_me - f_rv) * 1.5 * dt
		# no walking through each other: the lighter one gives way
		var sum := me.mass + rival.mass
		me.x += gap * rival.mass / sum
		rival.x -= gap * me.mass / sum
		if me.vx - rival.vx > 0.0:
			var v := (me.vx * me.mass + rival.vx * rival.mass) / sum
			me.vx = v
			rival.vx = v
	for w in [me, rival]:
		_step(w, dt)

func _step(w: Wrestler, dt: float) -> void:
	if w.down:
		return
	if w.grounded:
		w.ground_t += dt
		var hold := clampf(STIFF * (w.target - w.lean), -MAX_HOLD, MAX_HOLD)
		var grav := GRAV * sin(w.lean) * (0.4 if w.supported else 1.0)
		w.spin += (grav + hold - DAMP * w.spin) * dt
	else:
		w.spin += (STIFF * 0.3 * (w.target - w.lean) - DAMP * 0.5 * w.spin) * dt
		w.vy += G * dt
		w.y += w.vy * dt
		w.x += w.vx * dt
		if w.y >= 0.0:
			_land(w)
	w.lean += w.spin * dt

func _land(w: Wrestler) -> void:
	w.y = 0.0
	w.vy = 0.0
	w.vx = 0.0
	w.grounded = true
	w.ground_t = 0.0
	w.spin += randf_range(-1.0, 1.0) * LAND_NOISE * (1.0 if w.combo > 0 else 1.6)
	if w.buffered:                                       # a tap a moment early counts as on the beat
		w.buffered = false
		_drum(w, 1.0)
		return
	# paper squash
	var base := w.card.scale
	var t := create_tween()
	t.tween_property(w.card, "scale", base * Vector2(1.06, 0.92), 0.04)
	t.tween_property(w.card, "scale", base, 0.08)
	if w == me:
		_sfx("res://sounds/fx/wood_tap.wav", -24.0, 0.0, 1.5)        # the beat to tap on

## A tap on the box under `w`: a hop the way it leans (strong when right on the beat)
func _drum(w: Wrestler, power: float) -> void:
	if w.down:
		return
	if not w.grounded:
		if w.vy > 0.0 and w.y > -EARLY:
			w.buffered = true                                           # nearly down: hop on landing
			return
		w.spin += randf_range(-1.5, 1.5) * power                        # off the beat: wobble
		w.combo = 0
		return
	if w.ground_t < GOOD_WINDOW:
		w.combo = mini(w.combo + 1, 4)
		power *= 1.0 + w.combo * 0.08
	else:
		w.combo = 0
		power *= 0.85
	if w == me and tut == Tut.HOP:
		tut_hops += 1
	w.grounded = false
	w.vy = -HOP * power
	w.vx = w.facing * sin(w.lean) * STEP * power

# ================================================================== TUTORIAL

func _tut_step(delta: float) -> void:
	match tut:
		Tut.HOP:
			if tut_hops >= 2:
				tut = Tut.BEAT
				show_coach("Now tap right AS IT LANDS (listen for the tick)", 0)
		Tut.BEAT:
			if me.combo >= 3:
				tut = Tut.LEAN
				show_coach("Great rhythm = strong hops! Now TILT to lean forward")
		Tut.LEAN:
			if me.target > 0.28:
				tut_lean += delta
			if tut_lean > 0.5:
				tut = Tut.PUSH
				show_coach("Leaning pushes harder. Push it out!", 0)
				_after(2.5, hide_coach)
	# nobody loses while learning (the rival just stands there until the last step)
	if tut in [Tut.HOP, Tut.BEAT, Tut.LEAN]:
		for w in [me, rival]:
			w.lean = clampf(w.lean, -0.8, 0.8)
			w.x = clampf(w.x, RING_C.x - RING_HALF + 40.0, RING_C.x + RING_HALF - 40.0)

func _finish_tutorial() -> void:
	tut = Tut.NONE
	GameData.mark_intro_seen(GAME_INDEX)
	hide_coach()

func _check_bout() -> void:
	var lost: Wrestler = null
	for w in [me, rival]:
		if absf(w.lean) > FALL and not w.down:
			_fall_over(w)
			lost = w
		elif absf(w.x - RING_C.x) > RING_HALF + 10.0:
			lost = w
	if lost:
		_end_bout(lost != me, "FELL OVER" if lost.down else "OUT OF THE RING")

func _fall_over(w: Wrestler) -> void:
	w.down = true
	var flat := (PI / 2.0) * signf(w.lean) * w.facing
	var t := create_tween()
	t.tween_property(w.root, "rotation", flat, 0.25).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_QUAD)
	_sfx("res://sounds/fx/clack.mp3", -10.0, 0.0, 0.8)
	Input.vibrate_handheld(40)

func _end_bout(won: bool, how: String) -> void:
	phase = Phase.RESULT
	if tut != Tut.NONE:
		_finish_tutorial()
	if won:
		wins += 1
		add_score(50)
		_sfx("res://sounds/fx/gamecoin.wav", -8.0)
	else:
		losses += 1
		_sfx("res://sounds/fx/error.mp3", -14.0)
	_refresh_hud()
	var who := "YOU WIN" if won else "YOU LOSE"
	_show_banner("%s\n%s" % [how, who], 1.2)
	_after(1.8, func():
		if wins >= 2:
			var bonus := 100 * level
			add_score(bonus)
			_sfx("res://sounds/fx/unlock_ding.wav", -8.0)
			_show_banner("LEVEL %d CLEAR!\n+%d" % [level, bonus], 1.2)
			_after(1.6, func():
				level += 1
				_new_rival()
				_start_bout())
		elif losses >= 2:
			lives -= 1
			_refresh_hud()
			if lives <= 0:
				end_game()
			else:
				wins = 0
				losses = 0
				_show_banner("AGAIN!", 0.6)
				_after(0.8, _start_bout)
		else:
			_start_bout())

# ================================================================== RIVAL

func _rival_think(delta: float) -> void:
	var ai := rival.ai
	if rival.down:
		return
	# hop on its own rhythm: right on the beat, or a beat late
	if rival.grounded:
		if rival.ai_wait < 0.0:
			var on_beat := randf() < float(ai["rhythm"])
			rival.ai_wait = randf_range(0.02, GOOD_WINDOW - 0.02) if on_beat else float(ai["tempo"]) + randf_range(0.1, 0.35)
		elif rival.ground_t >= rival.ai_wait:
			_drum(rival, 1.0)
			_tap_finger(finger_r)
			rival.ai_wait = -1.0
	# drums your side while you're in the air
	if float(ai["far"]) > 0.0 and not me.grounded and randf() < float(ai["far"]) * delta:
		_far_tap(me)
		_tap_finger(finger_l)
	# the pull-down: you're leaning on it hard, so it steps back for a moment
	rival.pull_t = maxf(0.0, rival.pull_t - delta)
	if float(ai["pull"]) > 0.0 and rival.pull_t <= 0.0 and me.supported and me.lean > 0.45 \
			and randf() < float(ai["pull"]) * delta * 3.0:
		rival.pull_t = 0.5
	rival.target = -0.25 if rival.pull_t > 0.0 else float(ai["lean"])

## Drumming the far side: whoever's over there gets shaken
func _far_tap(w: Wrestler) -> void:
	if w.down:
		return
	if w.grounded:
		_drum(w, 0.55)
	else:
		w.spin += randf_range(-2.2, 2.2)

# ================================================================== DRAWING

func _create_static_nodes() -> void:
	stage = Node2D.new()
	stage.draw.connect(_draw_stage)
	add_child(stage)
	wrestlers = Node2D.new()
	add_child(wrestlers)
	fx = Node2D.new()
	add_child(fx)
	var ftex := _make_finger_texture()
	finger_l = _make_finger(ftex, Vector2(80, 900))
	finger_r = _make_finger(ftex, Vector2(PLAY_WIDTH - 80, 900))

	hud_level = _make_label(Vector2(30, 20), Vector2(200, 50), 36, HORIZONTAL_ALIGNMENT_LEFT, OUTLINE)
	hud_rival = _make_label(Vector2(PLAY_WIDTH - 430, 20), Vector2(400, 50), 32, HORIZONTAL_ALIGNMENT_RIGHT, OUTLINE)
	lives_box = HBoxContainer.new()
	lives_box.position = Vector2(30, 76)
	lives_box.add_theme_constant_override("separation", 6)
	add_child(lives_box)
	bouts_box = HBoxContainer.new()
	bouts_box.position = Vector2(PLAY_WIDTH - 160, 80)
	bouts_box.add_theme_constant_override("separation", 10)
	add_child(bouts_box)
	# the control legend on the box's front: what each finger does
	hint_main = make_button_hint(0, "HOP")
	hint_main.position = Vector2(120, PLAY_HEIGHT - 54)
	hint_fwd = make_button_hint(1, "SHAKE")
	hint_fwd.size = hint_fwd.get_combined_minimum_size()
	hint_fwd.position = Vector2(PLAY_WIDTH - 120 - hint_fwd.size.x, PLAY_HEIGHT - 54)
	banner = _make_label(Vector2(0, 300), Vector2(PLAY_WIDTH, 140), 50, HORIZONTAL_ALIGNMENT_CENTER, TEXT)
	banner.add_theme_color_override("font_outline_color", OUTLINE)
	banner.add_theme_constant_override("outline_size", 14)
	banner.modulate.a = 0.0

func _make_finger(tex: Texture2D, at: Vector2) -> Sprite2D:
	var f := Sprite2D.new()
	f.texture = tex
	f.scale = Vector2(4, 4)
	f.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	f.position = at
	add_child(f)
	return f

## The box (top + front), the ring drawn on it (sand, straw rope, the two start lines)
func _draw_stage() -> void:
	stage.draw_rect(Rect2(0, 0, PLAY_WIDTH, PLAY_HEIGHT), WALL)
	for i in range(0, int(PLAY_WIDTH), 90):
		stage.draw_rect(Rect2(i, 0, 4, 470), WALL_LINE)
	var top := PackedVector2Array([Vector2(110, 470), Vector2(PLAY_WIDTH - 110, 470), Vector2(PLAY_WIDTH - 20, 880), Vector2(20, 880)])
	stage.draw_colored_polygon(top, BOX_TOP)
	for i in 9:                                                  # corrugation showing through
		var f := float(i + 1) / 10.0
		var y := lerpf(470.0, 880.0, f * f)
		stage.draw_line(Vector2(lerpf(110, 20, f * f), y), Vector2(lerpf(PLAY_WIDTH - 110, PLAY_WIDTH - 20, f * f), y), BOX_LINE, 2)
	stage.draw_rect(Rect2(20, 880, PLAY_WIDTH - 40, 68), BOX_FRONT)
	stage.draw_polyline(top + PackedVector2Array([top[0]]), OUTLINE, 4)
	stage.draw_rect(Rect2(20, 880, PLAY_WIDTH - 40, 68), OUTLINE, false, 4)
	# the ring
	stage.draw_colored_polygon(_ellipse(RING_C, RING_RX + 16, RING_RY + 8, 48), SAND_DARK)
	stage.draw_colored_polygon(_ellipse(RING_C, RING_RX, RING_RY, 48), SAND)
	var rope := _ellipse(RING_C, RING_RX, RING_RY, 48)
	rope.append(rope[0])
	stage.draw_polyline(rope, ROPE_DARK, 16)
	stage.draw_polyline(rope, ROPE, 10)
	for sx in [-1.0, 1.0]:
		var x: float = RING_C.x + sx * 40.0
		stage.draw_line(Vector2(x, RING_C.y - 14), Vector2(x, RING_C.y + 14), Color.WHITE, 5)
	# a soft shadow under each wrestler (smaller while hopping)
	for w in [me, rival]:
		if w and not w.down:
			var k := clampf(1.0 + w.y / 120.0, 0.4, 1.0)
			stage.draw_colored_polygon(_ellipse(Vector2(w.x, RING_C.y + 4), w.half * k, 8 * k, 16), Color(0.3, 0.2, 0.1, 0.25))

func _ellipse(c: Vector2, rx: float, ry: float, n: int) -> PackedVector2Array:
	var pts := PackedVector2Array()
	for i in n:
		var a := TAU * i / n
		pts.append(c + Vector2(cos(a) * rx, sin(a) * ry))
	return pts

func _refresh_hud() -> void:
	for n in lives_box.get_children():
		n.queue_free()
	for i in LIVES:
		var t := TextureRect.new()
		t.texture = ball_texture
		t.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		t.custom_minimum_size = Vector2(30, 30)
		t.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		t.modulate = Color(1, 1, 1, 1) if i < lives else Color(0, 0, 0, 0.35)
		lives_box.add_child(t)
	# bouts: filled = won, red = lost, empty = to go (best of 3)
	for n in bouts_box.get_children():
		n.queue_free()
	for i in 3:
		var r := ColorRect.new()
		r.custom_minimum_size = Vector2(28, 28)
		r.color = Color8(250, 210, 90) if i < wins else (Color8(206, 74, 52) if i < wins + losses else Color(0, 0, 0, 0.18))
		bouts_box.add_child(r)

## The pal printed on paper and folded down the middle: a white paper margin round its
## shape, the right half a touch shaded (the fold), two tabs at the bottom as feet
func _make_card_texture(path: String) -> Texture2D:
	if _cards.has(path):
		return _cards[path]
	var src: Image = (load(path) as Texture2D).get_image()
	if src.is_compressed():
		src.decompress()
	src.convert(Image.FORMAT_RGBA8)
	var used := src.get_used_rect()
	const M := 4                                       # paper margin
	const TAB := 6
	var w := used.size.x + M * 2
	var h := used.size.y + M * 2 + TAB
	var img := Image.create(w, h, false, Image.FORMAT_RGBA8)
	# paper: a disc of M px stamped round every pixel of the pal
	for y in used.size.y:
		for x in used.size.x:
			if src.get_pixel(used.position.x + x, used.position.y + y).a <= 0.5:
				continue
			for dy in range(-M, M + 1):
				for dx in range(-M, M + 1):
					if dx * dx + dy * dy <= M * M:
						img.set_pixel(x + M + dx, y + M + dy, PAPER)
	# straight bottom edge, then the two feet tabs
	var bottom := h - TAB - 1
	for x in range(M, w - M):
		for y in range(bottom - M, bottom + 1):
			img.set_pixel(x, y, PAPER)
	for x in range(M + 2, M + 2 + w / 5):
		for y in range(bottom, h):
			img.set_pixel(x, y, PAPER)
			img.set_pixel(w - 1 - x, y, PAPER)
	# the pal on top
	for y in used.size.y:
		for x in used.size.x:
			var c := src.get_pixel(used.position.x + x, used.position.y + y)
			if c.a > 0.5:
				img.set_pixel(x + M, y + M, c)
	# the fold: right half shaded, a crease down the middle; dark outline round the paper
	var out := img.duplicate() as Image
	for y in h:
		for x in w:
			var c := img.get_pixel(x, y)
			if c.a == 0.0:
				for d in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
					var nx: int = x + d.x
					var ny: int = y + d.y
					if nx >= 0 and ny >= 0 and nx < w and ny < h and img.get_pixel(nx, ny).a > 0.0:
						out.set_pixel(x, y, OUTLINE)
						break
				continue
			if x > w / 2:
				c = c.darkened(0.1)
			if x == w / 2 and c.is_equal_approx(PAPER):
				c = PAPER_SHADE
			out.set_pixel(x, y, c)
	_cards[path] = ImageTexture.create_from_image(out)
	return _cards[path]

## A fingertip seen from the front of the box (pointing down at it)
func _make_finger_texture() -> Texture2D:
	var img := Image.create(9, 16, false, Image.FORMAT_RGBA8)
	for y in 16:
		for x in 9:
			var edge := x == 0 or x == 8 or (y == 15 and x > 0 and x < 8)
			var c := OUTLINE if edge else SKIN
			if y > 10 and not edge and x > 1 and x < 7:
				c = Color8(250, 228, 214)                      # the nail
			if y == 15 and (x == 1 or x == 7):
				c = Color(0, 0, 0, 0)
			img.set_pixel(x, y, c)
	return ImageTexture.create_from_image(img)

func _tap_finger(f: Sprite2D) -> void:
	var t := create_tween()
	t.tween_property(f, "position:y", 868.0, 0.04)
	t.tween_property(f, "position:y", 900.0, 0.08)
	_sfx("res://sounds/fx/wood_tap.wav", -12.0, 0.0, 0.75)

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
	t.x += (float(Input.is_key_pressed(KEY_RIGHT) or Input.is_key_pressed(KEY_D)) - float(Input.is_key_pressed(KEY_LEFT) or Input.is_key_pressed(KEY_A))) * 0.8
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

func on_main_button_released() -> void:
	pass

func on_forward_button_down() -> void:
	if not is_running or is_game_over or _touch_mode:
		return
	_forward_tap()

func _main_tap() -> void:
	_tap_finger(finger_l)
	if is_running and phase == Phase.FIGHT:
		_drum(me, 1.0)

func _forward_tap() -> void:
	if tut == Tut.HOP:
		_finish_tutorial()                             # skip the tutorial
		return
	_tap_finger(finger_r)
	if phase == Phase.FIGHT:
		_far_tap(rival)

## Phones: every finger counts (fast drumming, both thumbs at once)
func _input(event: InputEvent) -> void:
	if not (event is InputEventScreenTouch) or not event.pressed:
		return
	_touch_mode = true
	if intro_active() or is_game_over or not is_running:
		return                                           # (the buttons' own taps handle those)
	match device_button_at(event.position):
		0:
			_main_tap()
		1:
			_forward_tap()

func on_forward_button_up() -> void:
	pass

func on_forward_button_pressed() -> void:
	if is_game_over:
		super.on_forward_button_pressed()

func _unhandled_input(event: InputEvent) -> void:
	if not (event is InputEventKey) or event.echo or not event.pressed:
		return
	var k := (event as InputEventKey).keycode
	if k == KEY_SPACE:
		on_main_button_pressed()
	elif k == KEY_SHIFT or k == KEY_X:
		on_forward_button_down()
		on_forward_button_pressed()

func end_game() -> void:
	phase = Phase.RESULT
	banner.visible = false
	hint_main.visible = false
	hint_fwd.visible = false
	super.end_game()

# ================================================================== HELPERS

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
