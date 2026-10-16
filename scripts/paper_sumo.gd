extends BaseMinigame
## Paper Sumo — tontonzumo, the Japanese paper sumo toy. Two folded paper figures stand in a ring
## drawn on a box; drumming the box makes them hop and shuffle the way they lean. Push the rival
## out of the ring or make it fall over.
##
##   MAIN     = drum YOUR side: your wrestler hops forward (the way it leans). Tap right as it
##              lands = a strong, steady hop (keep the rhythm!); tapping while it's in the air
##              only makes it wobble.
##   FORWARD  = drum the FAR side: shakes the rival (wobbly if it's in the air, a little hop
##              towards you if it's standing). Risky.
##   TILT     = lean forward (pushes harder, falls easier) or back (steady; a rival leaning on
##              you falls on its face when you back off: the pull-down).
## A level = one match, best of 3 bouts (no lives: lose it and you retry the level). Stars: 1 =
## win, 2 = win 2-0, 3 = 2-0 within the par time. No points.
##
## Levels (the level menu): 6 worlds of 9, each its own place (SumoArt) with its own family of
## rivals (critters from the pals' world, drawn by the pal renderer: tools/art/sumo_rivals.py; not
## pals: your pal is the only pal in the ring) and one new trick; from the 7th level the world
## before's trick joins in, the 9th is the world's champion:
##   1 Wooden Box: frogs (the basics; the old scrolls have frogs wrestling) · 2 Pond Garden, on a
##   rock in a spring pond: turtles (heavy: lean in; Minogame, the old one) · 3 Autumn Stream, on a
##   log raft: otters (the tricksters: they pull you down) · 4 Moon Base, on a landing pad: wind-up
##   tin robots (they march on their own beat, drum your side on the off-beat and run down: push
##   while they wind up; the big robot holds the Microchip) · 5 Tree Stump, in a summer forest:
##   beetles, mushi-zumo (the horn lifts you; the beetle king holds the Golden Seed) · 6 Shrine
##   Festival, at night: the sumo ranks up to the yokozuna (all of it; the harvest yokozuna, the
##   Sumo case).
## Drinks: a SPLASH pal springs back from one fall · FOCUS widens the beat window (a ring of
## light at its feet shows it) · STURDY is heavier. A world's 6th level: a mystery challenger
## after the match, for a sturdy or a focused pal (the gate on the level); beat it for its prize.
##
## Desktop: Left / Right (A / D) lean, Space = MAIN, Shift or X = FORWARD.

const GAME_INDEX := 9

# --- Ring (play-area coordinates, 950x948; the stage is painted by SumoArt) ---
const RING_C := SumoArt.RING_C        # the ring's centre; the wrestlers stand on this line
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

# --- Drinks and tricks ---
const FOCUS_WIDEN := 0.4              # a focused pal's beat window: wider by this per drink level
const STURDY_MASS := 0.2              # a sturdy pal: heavier by this per drink level
const WIND_UP := 1.3                  # a run-down robot stands still this long, winding itself up
const HORN_DIG := 0.4                 # a beetle digs in this long before its horn lifts you
const BOUT_MAX := 30.0                # a bout this long: time! whoever held more ground wins it
const TIRING := 0.012                 # a rival tires as a bout drags on: its rhythm slips this much a second...
const TIRING_MAX := 0.4               # ...up to this share of it (no endless stand-offs)

# --- Palette ---
const OUTLINE := SumoArt.OUTLINE
const PAPER := Color8(250, 248, 240)
const PAPER_SHADE := Color8(226, 222, 210)
const SKIN := Color8(244, 200, 168)
const TEXT := Color(1, 0.97, 0.9)
const CARD_SCALE := 2.0               # world px per sprite px, for every card (the pals' and the rivals' art is the same scale)

## The worlds: each its own box in its own place (SumoArt paints them) and its family of rivals
const WORLDS := ["Wooden Box", "Pond Garden", "Autumn Stream", "Moon Base", "Tree Stump", "Shrine Festival"]
const WORLD_HINTS := ["", "heavy ones: lean in!", "they pull you down!", "push while it winds up!", "the horn lifts you!", "the tournament!"]
## Each world's colour under the level menu's pattern
const WORLD_MENU := [Color8(214, 184, 140), Color8(164, 202, 188), Color8(214, 120, 70), Color8(64, 66, 104), Color8(140, 178, 104), Color8(70, 50, 88)]
## The worlds whose HUD is light on dark (the maples, space, the forest's leaves, the night sky)
const LIGHT_HUD := [2, 3, 4, 5]
## Each world's rivals, one per level: [name, look] (its sprite: textures/minigames/sumo/rivals/
## <figure>_<look>.png; the 9th is the champion: <figure>_champ.png), and how they fight at the world's first level (tougher level by level:
## _rival_data): mass; lean = how far forward it likes to lean; rhythm = the chance a hop is on
## the beat; tempo = its pause after landing when it isn't; far = taps on your side per second;
## pull = its pull-down habit; horn = its lift; march = a wind-up robot's beat (s), spring = how
## long its spring lasts (s); par = a bout's par time (s; the 3rd star: 2-0 within two of them);
## champ = the champion's own numbers, where they differ
const FAMILIES := [
	{ "figure": "frog", "rivals": [["KERO", 0], ["PYON", 1], ["AMA", 2], ["KAJIKA", 3], ["GERO", 4], ["TONO", 5], ["KERO", 0], ["PYON", 1], ["GAMA", 0]],
		"mass": 0.8, "lean": 0.12, "rhythm": 0.3, "tempo": 0.3, "par": 8.0 },
	{ "figure": "turtle", "rivals": [["KAME", 0], ["NONBIRI", 1], ["ISHI", 2], ["MIDORI", 3], ["SUPPON", 4], ["KAME", 0], ["ISHI", 2], ["MIDORI", 3], ["MINOGAME", 0]],
		"mass": 1.25, "lean": 0.2, "rhythm": 0.45, "tempo": 0.28, "par": 11.0 },
	{ "figure": "otter", "rivals": [["KAWA", 0], ["USO", 1], ["NURU", 2], ["SUBE", 3], ["CHORO", 4], ["USO", 1], ["KAWA", 0], ["NURU", 2], ["KAWAUSO", 0]],
		"mass": 1.0, "lean": 0.18, "rhythm": 0.5, "tempo": 0.2, "pull": 0.7, "par": 10.0 },
	{ "figure": "robot", "rivals": [["ROBO", 0], ["TIN", 1], ["BOLT", 2], ["GEAR", 3], ["SPRING", 4], ["SPARKY", 5], ["ROBO", 0], ["TIN", 1], ["BIG ROBO", 0]],
		"mass": 1.25, "lean": 0.2, "rhythm": 1.0, "tempo": 0.2, "far": 0.7, "march": 0.4, "spring": 6.5, "par": 10.0 },
	{ "figure": "beetle", "rivals": [["KABUTO", 0], ["KUWAGATA", 1], ["KANABUN", 2], ["ATLAS", 3], ["KABUTO", 0], ["HERCULES", 4], ["KUWAGATA", 1], ["ATLAS", 3], ["BEETLE KING", 0]],
		"mass": 1.2, "lean": 0.22, "rhythm": 0.5, "tempo": 0.2, "horn": 0.5, "par": 12.0, "champ": { "horn": 0.42, "lean": 0.24 } },
	{ "figure": "sumo", "rivals": [["JONIDAN", 0], ["MAKUSHITA", 1], ["JURYO", 2], ["MAEGASHIRA", 3], ["KOMUSUBI", 4], ["SEKIWAKE", 5], ["OZEKI", 6], ["YOKOZUNA", 7], ["HARVEST YOKOZUNA", 0]],
		"mass": 1.25, "lean": 0.22, "rhythm": 0.62, "tempo": 0.18, "far": 0.3, "pull": 0.3, "horn": 0.25, "par": 13.0, "champ": { "lean": 0.24 } },
]
## Secrets: a mystery challenger after the match on a world's 6th level: [the drink it wants (a
## heavy one: a sturdy pal; a quick one: a focused pal), its prize]. Finales: a level's prize on
## its first win (the big robot's Microchip, the beetle king's Golden Seed, the Sumo case)
const SECRETS := {
	15: ["milky", "sticker:koi"], 24: ["caffeinated", "decor:maple_leaves"], 33: ["milky", "sticker:wind_up_key"],
	42: ["caffeinated", "sticker:kabuto"], 51: ["milky", "acc:sumo_topknot"],
}
const FINALES := { 36: "food:Microchip", 45: "food:Golden Seed", 54: "case:sumo" }

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
	var horn_t := 0.0                 # (a beetle) its next horn lift
	var horn_dig := 0.0               # (a beetle) digging in: the lift comes when this runs out
	var spring := 1.0                 # (a wind-up robot) its spring: 1 = wound up, 0 = run down
	var wind := 0.0                   # (a wind-up robot) winding itself back up: it stands still
	var beat := 0.0                   # (a wind-up robot) where it is in its beat, 0..1
	var key_turn := 0.0
	var key: Sprite2D = null
	var card_scale := Vector2.ONE     # the card's own scale (its squashes tween round it)
	var root: Node2D
	var card: Sprite2D

enum Phase { READY, FIGHT, RESULT }
## First-time tutorial: one step at a time, each waits until you've done it
enum Tut { NONE, HOP, LEAN, PUSH }

var phase := Phase.READY
var level := 1
var world := 0
var wins := 0                         # bouts won in this match
var losses := 0
var time := 0.0
var fight_t := 0.0                    # the match's fighting time so far (the par time: the 3rd star)
var bout_t := 0.0                     # this bout's
var match_stars := 0
var match_id := 0                     # (a new match: what was still to come in the old one is dropped)
var rival_info: Dictionary = {}
var splash_used := false
var focus := 0                        # this match's boosts' levels (0 = none)
var sturdy := 0
var mystery := false                  # the bonus bout against the mystery challenger
var mystery_gate := ""
var qa_autopilot := false             # (tools/qa: your pal drums and leans by itself)
var qa_skill := 1                     # (1: leans in and drums; 2: also shakes it mid-hop and pulls it down)
var qa_wait := 0.05
var qa_shake := 0.0
var qa_back := 0.0

var me: Wrestler
var rival: Wrestler

var painted: Sprite2D
var stage: Node2D
var wrestlers: Node2D
var fx: Node2D
var finger_l: Sprite2D
var finger_r: Sprite2D
var hud_level: Label
var hud_rival: Label
var bouts_box: HBoxContainer
var boost_icon: TextureRect
var banner: Label
var hint_main: HBoxContainer          # control legend: HOP (main) and SHAKE (forward)
var hint_fwd: HBoxContainer
var tut := Tut.NONE
var tut_hops := 0
var tut_lean := 0.0                   # how long you've leant forward while learning
var shake_tip_due := false            # right after the tutorial: explain FORWARD at the next bout
var lcd_font: Font
var _cards := {}                      # path / figure -> its folded paper texture
var _touch_mode := false              # phone: taps come from _input, not the emulated mouse

func _ready() -> void:
	game_music_path = "res://sounds/music/Pixel Sumo.ogg"     # (93.75 BPM, loops on the beat: 0.28 s → 130.84 s)
	lcd_font = load("res://fonts/pixChicago.ttf")
	_create_static_nodes()
	if GameData.intro_seen(GAME_INDEX):
		intro_text = "Drum the box in rhythm. Tilt to lean!"
		intro_icon = _make_card_texture(_my_form_path())
	super._ready()

# --- the level menu (BaseMinigame) ---

func uses_levels() -> bool:
	return true

func world_names() -> Array:
	return WORLDS

func level_count() -> int:
	return WORLDS.size() * GameData.LEVELS_PER_WORLD

func level_pattern() -> Texture2D:
	return load("res://textures/menus/pattern_sumo_vermilion.png")

func level_backdrop() -> Color:
	return WORLD_MENU[0]

func world_backdrop(w: int) -> Color:
	return WORLD_MENU[clampi(w, 0, WORLD_MENU.size() - 1)]

func secrets() -> Dictionary:
	var out := {}
	for lvl in SECRETS:
		out[lvl] = { "gate": SECRETS[lvl][0], "lvl": 1 + clampi((lvl - 1) / GameData.LEVELS_PER_WORLD, 0, 5) / 2, "prize": SECRETS[lvl][1] }
	return out

func finale_prizes() -> Dictionary:
	return FINALES

func fail_title() -> String:
	return "Match lost!"

func start_game() -> void:
	play_level(1)

## Chosen in the level menu (or NEXT / RETRY): the first time ever, level 1 starts with the
## tutorial's practice bout
func play_level(n: int) -> void:
	super.start_game()
	level = clampi(n, 1, level_count())
	tut = Tut.HOP if (level == 1 and not GameData.intro_seen(GAME_INDEX)) else Tut.NONE
	shake_tip_due = false
	_new_match()

# ================================================================== SETUP

func _my_form_path() -> String:
	if PetState.has_poop():
		return PetState.FORMS[PetState.form_id]["frames"][0]
	return "res://textures/pet/poo1-1.png"

## A level's rival: its world's family (FAMILIES), a little tougher level by level; from the 7th
## level the world before's trick joins in; the 9th, the champion, is bigger and steadier
func _rival_data(k := -1) -> Dictionary:
	if k < 0:
		k = (level - 1) % GameData.LEVELS_PER_WORLD
	var f: Dictionary = FAMILIES[world]
	var who: Array = f["rivals"][k]
	var grow := 0.6 + 0.06 * k
	var d := {
		"name": who[0], "figure": f["figure"], "look": who[1], "champ": k == GameData.LEVELS_PER_WORLD - 1,
		"mass": float(f["mass"]) + 0.02 * k,
		"lean": float(f["lean"]) + 0.005 * k,
		"rhythm": minf(0.97, float(f["rhythm"]) + 0.035 * k),
		"tempo": maxf(0.08, float(f["tempo"]) - 0.012 * k),
		"far": float(f.get("far", 0.0)) * grow,
		"pull": float(f.get("pull", 0.0)) * grow,
		"horn": float(f.get("horn", 0.0)) * grow,
		"march": float(f.get("march", 0.0)),
		"spring": float(f.get("spring", 0.0)) + 0.3 * k,
		"par": float(f["par"]) * (1.0 + 0.03 * k),
	}
	if k >= 6:
		match world:                                          # the world before's trick joins in
			1: d["tempo"] = maxf(0.08, float(d["tempo"]) - 0.06)    # (the dolls': quick feet)
			2: d["mass"] = float(d["mass"]) + 0.35                  # (the cereal mascots': weight)
			3: d["pull"] = 0.45                                     # (the cranes': the pull-down)
			4: d["far"] = 0.35                                      # (the robots': drumming your side)
			5: d["horn"] = maxf(float(d["horn"]), 0.35)             # (the beetles': the lift)
	if d["champ"]:
		d["mass"] = float(d["mass"]) + 0.08 + 0.015 * world
		d["rhythm"] = minf(0.97, float(d["rhythm"]) + 0.04 + 0.01 * world)
		d.merge(f.get("champ", {}), true)
	return d

## The mystery challenger: one of the world's family in shadow (the 6th level's tricks), much
## heavier (it wants a sturdy pal) or much quicker (a focused one)
func _mystery_data() -> Dictionary:
	var d := _rival_data(5)
	var f: Dictionary = FAMILIES[world]
	d["name"] = "???"
	d["look"] = f["rivals"][0][1]
	d["champ"] = false
	d["shadow"] = true
	var lvl := int(secret_of(level).get("lvl", 1))
	if mystery_gate == "milky":
		d["mass"] = 1.45 + 0.2 * lvl
	else:
		d["mass"] = float(f["mass"])
		d["rhythm"] = 0.95
		d["tempo"] = 0.08
		d["far"] = maxf(float(d["far"]), 0.35)
	return d

## A level's match: its world's stage and rival, the drinks for this match, the first bout
func _new_match() -> void:
	match_id += 1
	world = clampi((level - 1) / GameData.LEVELS_PER_WORLD, 0, WORLDS.size() - 1)
	painted.texture = ImageTexture.create_from_image(SumoArt.stage(world))
	_style_hud()
	wins = 0
	losses = 0
	fight_t = 0.0
	splash_used = false
	mystery = false
	focus = PetState.boost_power("focus") if tut == Tut.NONE else 0
	sturdy = PetState.boost_power("sturdy") if tut == Tut.NONE else 0
	rival_info = _rival_data()
	hud_level.text = "TUTORIAL" if tut != Tut.NONE else "%d-%d" % [world + 1, (level - 1) % GameData.LEVELS_PER_WORLD + 1]
	_set_rival_name(str(rival_info["name"]))
	_refresh_boost_icon()
	_start_bout(true)

## A bout: both wrestlers back on their lines (a new rival drops onto the box, under the title)
func _start_bout(first := false) -> void:
	for c in wrestlers.get_children():
		c.queue_free()
	me = _make_wrestler(_make_card_texture(_my_form_path()), 1.0)
	me.x = RING_C.x - 140.0
	me.mass = 1.0 + STURDY_MASS * sturdy
	rival = _make_wrestler(_rival_card(rival_info), -1.0)
	rival.x = RING_C.x + 140.0
	rival.ai = rival_info
	rival.mass = float(rival_info["mass"])
	rival.target = float(rival_info["lean"])
	rival.horn_t = 1.5
	bout_t = 0.0
	if float(rival_info["march"]) > 0.0:
		_add_key(rival)
	calibrate_tilt()
	_refresh_hud()
	phase = Phase.READY
	if not first:
		_hakkeyoi()
		return
	rival.y = -560.0
	var t := create_tween()
	t.tween_property(rival, "y", 0.0, 0.5).set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)
	var title := _bout_title()
	if title == "":
		_hakkeyoi()
	else:
		_show_banner(title, 1.1)
		_after(1.6, _hakkeyoi)

## The title over a match's first bout: a world's name (and its trick) on its first level, else
## the level and the rival
func _bout_title() -> String:
	if tut != Tut.NONE:
		return ""
	if mystery:
		return "???"
	var k := (level - 1) % GameData.LEVELS_PER_WORLD
	if k == 0:
		var hint: String = WORLD_HINTS[world]
		return str(WORLDS[world]).to_upper() + ("\n" + hint if hint != "" else "")
	if rival_info.get("champ", false):
		return "%d-%d\nTHE CHAMPION!" % [world + 1, k + 1]
	return "%d-%d\nVS %s" % [world + 1, k + 1, rival_info["name"]]

func _hakkeyoi() -> void:
	_show_banner("HAKKEYOI!", 0.7)
	_after(0.9, func():
		phase = Phase.FIGHT
		if tut == Tut.HOP:
			show_coach("Press to make your pal HOP", 0, "FORWARD: skip tutorial")
		elif shake_tip_due:
			shake_tip_due = false
			show_coach("FORWARD drums ITS side: shake it mid-hop!", 1)
			_after(3.0, hide_coach))

func _make_wrestler(tex: Texture2D, facing: float) -> Wrestler:
	var w := Wrestler.new()
	w.facing = facing
	w.lean = 0.1
	w.root = Node2D.new()
	wrestlers.add_child(w.root)
	w.card = Sprite2D.new()
	w.card.texture = tex
	w.card.centered = false
	w.card.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	var sz := tex.get_size()
	var s := CARD_SCALE                                         # (a bigger figure: a bigger card)
	w.card_scale = Vector2(s * facing, s)                       # (the rival's is flipped)
	w.card.scale = w.card_scale
	w.card.offset = Vector2(-sz.x / 2.0, -sz.y)                 # pivot at the feet
	w.half = minf(sz.x * s * 0.4, 80.0)
	w.root.add_child(w.card)
	return w

## A wind-up robot's key, stuck in its back: it turns as the robot marches (slower as the spring
## runs down, fast while it winds itself up)
func _add_key(w: Wrestler) -> void:
	var k := Sprite2D.new()
	k.texture = load("res://textures/minigames/sumo/key_gold.png" if bool(w.ai["champ"]) else "res://textures/minigames/sumo/key.png")
	k.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	k.centered = false
	k.offset = Vector2(0, -k.texture.get_size().y / 2.0)         # (the stem's middle on its pivot)
	var s := CARD_SCALE * 0.55
	k.scale = Vector2(s, s)
	var sz := w.card.texture.get_size() * CARD_SCALE
	k.position = Vector2(sz.x * 0.5 - 12.0, -sz.y * 0.5)         # (its back: away from your pal)
	w.root.add_child(k)
	w.root.move_child(k, 0)                                      # (behind the card)
	w.key = k

# ================================================================== LOOP

func _process(delta: float) -> void:
	stage.queue_redraw()
	if not is_running:
		return
	time += delta
	if phase == Phase.FIGHT:
		bout_t += delta
		if tut == Tut.NONE and not mystery:
			fight_t += delta
		me.target = 0.12 + _read_tilt().x * me.facing * 0.32
		if qa_autopilot:
			_qa_drive(delta)
		if tut == Tut.NONE:
			_rival_think(delta)
		const STEPS := 4
		for i in STEPS:
			_physics(delta / STEPS)
		_tut_step(delta)
		_check_bout()
		if phase == Phase.FIGHT and bout_t > BOUT_MAX and tut == Tut.NONE:
			_end_bout(absf(me.x - RING_C.x) <= absf(rival.x - RING_C.x), "TIME!")
	for w in [me, rival]:
		if w and is_instance_valid(w.root):
			w.root.position = Vector2(w.x, RING_C.y + w.y)
			if not w.down:
				w.root.rotation = w.lean * w.facing
	if rival and is_instance_valid(rival.key):
		rival.key_turn += delta * (16.0 if rival.wind > 0.0 else 1.5 + 6.0 * rival.spring)
		rival.key.scale.y = absf(rival.key.scale.x) * maxf(0.15, absf(cos(rival.key_turn)))

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
	var t := create_tween()
	t.tween_property(w.card, "scale", w.card_scale * Vector2(1.06, 0.92), 0.04)
	t.tween_property(w.card, "scale", w.card_scale, 0.08)
	if w == me:
		_sfx("res://sounds/fx/wood_tap.wav", -24.0, 0.0, 1.5)        # the beat to tap on

## The beat window after a landing (wider for a focused pal)
func _window(w: Wrestler) -> float:
	return GOOD_WINDOW * (1.0 + FOCUS_WIDEN * focus) if w == me else GOOD_WINDOW

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
	if w.ground_t < _window(w):
		w.combo = mini(w.combo + 1, 4)
		power *= 1.0 + w.combo * 0.08
		if w == me:
			_good_hop_sparks(w)                                   # (good timing shows, nothing to read)
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
				tut = Tut.LEAN
				show_coach("Now TILT the phone to lean forward")
		Tut.LEAN:
			if me.target > 0.28:
				tut_lean += delta
			if tut_lean > 0.5:
				tut = Tut.PUSH
				show_coach("Leaning pushes harder. Push it out!", 0)
				_after(2.5, hide_coach)
	# nobody loses while learning (the rival just stands there until the last step)
	if tut in [Tut.HOP, Tut.LEAN]:
		for w in [me, rival]:
			w.lean = clampf(w.lean, -0.8, 0.8)
			w.x = clampf(w.x, RING_C.x - RING_HALF + 40.0, RING_C.x + RING_HALF - 40.0)

func _finish_tutorial() -> void:
	tut = Tut.NONE
	shake_tip_due = true
	GameData.mark_intro_seen(GAME_INDEX)
	hide_coach()

## A hop timed right as the wrestler landed (a bit stronger): a little burst of sparks at its feet
func _good_hop_sparks(w: Wrestler) -> void:
	for i in 5:
		var sp := ColorRect.new()
		sp.size = Vector2(8, 8)
		sp.color = Color8(255, 236, 150) if i % 2 == 0 else Color.WHITE
		sp.position = Vector2(w.x, RING_C.y) - sp.size / 2.0
		fx.add_child(sp)
		var dir := Vector2.from_angle(PI + (i + 0.5) * PI / 5.0)       # (a fan, upwards)
		var t := create_tween()
		t.tween_property(sp, "position", sp.position + dir * randf_range(30.0, 50.0), 0.22).set_ease(Tween.EASE_OUT)
		t.parallel().tween_property(sp, "modulate:a", 0.0, 0.22)
		t.tween_callback(sp.queue_free)

# ================================================================== BOUTS

func _check_bout() -> void:
	var lost: Wrestler = null
	for w in [me, rival]:
		if absf(w.lean) > FALL and not w.down:
			if _splash_save(w):
				continue
			_fall_over(w)
			lost = w
		elif absf(w.x - RING_C.x) > RING_HALF + 10.0:
			if _splash_save(w):
				continue
			lost = w
	if lost:
		_end_bout(lost != me, "FELL OVER" if lost.down else "OUT OF THE RING")

## A splashy pal springs back once a match: back on its feet (and pulled back into the ring, more
## with a stronger drink) instead of the bout lost; the boost is spent
func _splash_save(w: Wrestler) -> bool:
	if w != me or splash_used or tut != Tut.NONE or PetState.boost_power("splash") <= 0:
		return false
	splash_used = true
	var lvl := PetState.boost_level
	PetState.use_boost()
	_refresh_boost_icon()
	me.lean = 0.1
	me.spin = 0.0
	me.vx = 0.0
	var inner := RING_HALF - 70.0 - 30.0 * lvl
	me.x = clampf(me.x, RING_C.x - inner, RING_C.x + inner)
	_show_banner("SPLASH!", 0.6)
	_sfx("res://sounds/fx/water_boing.wav", -8.0)
	_good_hop_sparks(me)
	return true

func _fall_over(w: Wrestler) -> void:
	w.down = true
	var flat := (PI / 2.0) * signf(w.lean) * w.facing
	var t := create_tween()
	t.tween_property(w.root, "rotation", flat, 0.25).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_QUAD)
	_sfx("res://sounds/fx/clack.mp3", -10.0, 0.0, 0.8)
	Input.vibrate_handheld(40)

func _end_bout(won: bool, how: String) -> void:
	phase = Phase.RESULT
	if tut != Tut.NONE:                       # the tutorial's bout doesn't count: now the real level 1
		_finish_tutorial()
		_sfx("res://sounds/fx/unlock_ding.wav", -8.0)
		_show_banner("%s\nTUTORIAL DONE!" % how, 1.2)
		_after(1.8, _new_match)
		return
	if qa_autopilot:
		print("QA bout %s %s %.1fs" % ["won" if won else "lost", how, bout_t])
	if mystery:
		_end_mystery(won, how)
		return
	if won:
		wins += 1
		_sfx("res://sounds/fx/gamecoin.wav", -8.0)
	else:
		losses += 1
		_sfx("res://sounds/fx/error.mp3", -14.0)
	_refresh_hud()
	var who := "YOU WIN" if won else "YOU LOSE"
	_show_banner("%s\n%s" % [how, who], 1.2)
	_after(1.8, func():
		if wins >= 2:
			_match_won()
		elif losses >= 2:
			_qa_log(false)
			_spend_boosts()
			if rival_info.get("champ", false) and world >= 3 and PetState.boost_power("sturdy") <= 0:
				_show_banner("TOO HEAVY!\na sturdy pal holds its ground", 1.6)      # (the champions: a hint)
				_after(2.2, func(): finish_level(level, 0))
			else:
				finish_level(level, 0)                     # (the result card: RETRY / LEVELS)
		else:
			_start_bout())

## The match is won: its stars (2-0, within the par time), then a world's 6th level's challenger
func _match_won() -> void:
	match_stars = 1 + (1 if losses == 0 else 0) + (1 if losses == 0 and fight_t <= _par() else 0)
	_qa_log(true)
	_sfx("res://sounds/fx/unlock_ding.wav", -8.0)
	Input.vibrate_handheld(60)
	_show_banner("MATCH WON!", 1.0)
	var sc := secret_of(level)
	if not sc.is_empty() and not sc["taken"]:
		_after(1.5, func(): _challenger(sc))
		return
	_after(1.6, _finish_match)

func _finish_match() -> void:
	_spend_boosts()
	finish_level(level, match_stars, fight_t)              # (the result card; its time = the record)

## The match's par time (the 3rd star: 2-0 within it): two of its rival's bouts
func _par() -> float:
	return 2.0 * float(rival_info.get("par", 10.0))

## A world's 6th level, won: the mystery challenger steps up for a pal whose drink opens its gate
## (one bout, for its prize); the others only see it watching, and what it wants
func _challenger(sc: Dictionary) -> void:
	mystery_gate = sc["gate"]
	if not gate_open(sc["gate"], int(sc["lvl"])):
		var b := DrinkLibrary.boost_of(sc["gate"])
		var note := "it wants a stronger drink" if PetState.boost == b else "only for a %s pal" % ("STURDY" if b == "sturdy" else "FOCUSED")
		_peek_challenger()
		_show_banner("A CHALLENGER WATCHES...\n" + note, 1.8)
		_after(2.6, _finish_match)
		return
	mystery = true
	wins = 0
	losses = 0
	_show_banner("A CHALLENGER!", 1.0)
	_sfx("res://sounds/fx/clack.mp3", -8.0, 0.0, 0.6)
	_after(1.4, func():
		rival_info = _mystery_data()
		_set_rival_name("???")
		_start_bout(true))

func _end_mystery(won: bool, how: String) -> void:
	if qa_autopilot:
		print("QA sumo %d-%d MYSTERY %s (%s %d)" % [world + 1, (level - 1) % GameData.LEVELS_PER_WORLD + 1, "WON" if won else "LOST", PetState.boost, PetState.boost_level])
	_show_banner("%s\n%s" % [how, "YOU WIN" if won else "IT GOT AWAY..."], 1.2)
	if not won:
		_sfx("res://sounds/fx/error.mp3", -14.0)
		_after(1.8, _finish_match)
		return
	wins = 1
	_refresh_hud()
	_sfx("res://sounds/fx/gamecoin.wav", -8.0)
	_after(1.6, func():
		take_secret(level)                                  # (its prize card)
		_after(2.6, _finish_match))

## The challenger only watches: its shadow fades in at the back of the box for a moment
func _peek_challenger() -> void:
	var s := Sprite2D.new()
	s.texture = _rival_card(_mystery_data())
	s.centered = false
	s.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	var sz := s.texture.get_size()
	var k := 110.0 / sz.y
	s.scale = Vector2(-k, k)                                     # (facing your pal)
	s.offset = Vector2(-sz.x / 2.0, -sz.y)
	s.position = Vector2(770, 600 if world == 4 else 540)
	s.modulate.a = 0.0
	add_child(s)
	move_child(s, painted.get_index() + 1)                       # (behind the wrestlers)
	var t := create_tween()
	t.tween_property(s, "modulate:a", 1.0, 0.4)
	t.tween_interval(1.4)
	t.tween_property(s, "modulate:a", 0.0, 0.5)
	t.tween_callback(s.queue_free)

# ================================================================== RIVAL

func _rival_think(delta: float) -> void:
	var ai := rival.ai
	if rival.down:
		return
	var marching := float(ai["march"]) > 0.0
	if marching:
		_march(delta)
	elif rival.grounded:
		# hop on its own rhythm: right on the beat, or a beat late
		if rival.ai_wait < 0.0:
			var on_beat := randf() < float(ai["rhythm"]) * (1.0 - minf(TIRING_MAX, bout_t * TIRING))
			rival.ai_wait = randf_range(0.02, GOOD_WINDOW - 0.02) if on_beat else float(ai["tempo"]) + randf_range(0.1, 0.35)
		elif rival.ground_t >= rival.ai_wait:
			_drum(rival, 1.0)
			_tap_finger(finger_r)
			rival.ai_wait = -1.0
	# drums your side while you're in the air (a robot does it on its off-beat: _march)
	if not marching and float(ai["far"]) > 0.0 and not me.grounded and randf() < float(ai["far"]) * delta:
		_far_tap(me)
		_tap_finger(finger_l)
	# the pull-down: you're leaning on it hard, so it steps back for a moment
	rival.pull_t = maxf(0.0, rival.pull_t - delta)
	if float(ai["pull"]) > 0.0 and rival.pull_t <= 0.0 and me.supported and me.lean > 0.45 \
			and randf() < float(ai["pull"]) * delta * 3.0:
		rival.pull_t = 0.5
	rival.target = -0.25 if rival.pull_t > 0.0 else float(ai["lean"])
	if rival.wind > 0.0:
		rival.target = 0.0                                   # (winding itself up: it stands up straight)
	if float(ai["horn"]) > 0.0:
		_horn(delta)

## A wind-up robot: it hops on its own beat (and drums your side on the off-beat), slower as its
## spring runs down; then it stops to wind itself up (push it now!)
func _march(delta: float) -> void:
	var ai := rival.ai
	if rival.wind > 0.0:
		rival.wind -= delta
		if rival.wind <= 0.0:
			rival.spring = 1.0
			rival.beat = 0.0
		return
	rival.spring -= delta / maxf(1.0, float(ai["spring"]))
	if rival.spring <= 0.0:
		rival.wind = WIND_UP
		_pop_text("WIND UP!", Vector2(rival.x, RING_C.y - 190.0))
		_sfx("res://sounds/fx/click-5.mp3", -10.0)
		return
	var before := rival.beat
	rival.beat += delta / (float(ai["march"]) / (0.45 + 0.55 * rival.spring))
	if rival.beat >= 1.0:
		rival.beat -= 1.0
		if rival.grounded:
			_drum(rival, 1.0)
			_tap_finger(finger_r)
	elif before < 0.5 and rival.beat >= 0.5 and float(ai["far"]) > 0.0 and not me.grounded and randf() < float(ai["far"]):
		_far_tap(me)
		_tap_finger(finger_l)

## A beetle's horn: standing against you, it digs in (a moment's warning), then lifts you off your
## feet and back (a sturdy pal is lifted less; one already in the air isn't)
func _horn(delta: float) -> void:
	var ai := rival.ai
	var touching := (rival.x - me.x) - (me.half + rival.half) <= 6.0
	if rival.horn_dig > 0.0:
		rival.horn_dig -= delta
		if rival.horn_dig > 0.0:
			return
		if touching and me.grounded and not me.down:
			var power := float(ai["horn"])
			me.grounded = false
			me.vy = -HOP * (0.5 + 0.4 * power) / sqrt(me.mass)
			me.vx = -me.facing * 120.0 / me.mass
			me.spin -= (1.4 + power) / me.mass
			me.combo = 0
			_sfx("res://sounds/fx/clack.mp3", -12.0, 0.0, 1.3)
		var t := create_tween()
		t.tween_property(rival.card, "rotation", -0.25 * rival.facing, 0.08)
		t.tween_property(rival.card, "rotation", 0.0, 0.2)
		rival.horn_t = randf_range(2.0, 3.4) / maxf(0.3, float(ai["horn"]))
		return
	rival.horn_t -= delta
	if rival.horn_t <= 0.0 and touching and rival.grounded:
		rival.horn_dig = HORN_DIG
		var t := create_tween()
		t.tween_property(rival.card, "scale", rival.card_scale * Vector2(1.06, 0.88), 0.12)
		t.tween_interval(HORN_DIG - 0.2)
		t.tween_property(rival.card, "scale", rival.card_scale, 0.08)

## Drumming the far side: whoever's over there gets shaken (the heavy ones less)
func _far_tap(w: Wrestler) -> void:
	if w.down:
		return
	if w.grounded:
		_drum(w, 0.55 / sqrt(w.mass))
	else:
		w.spin += randf_range(-2.2, 2.2) / sqrt(w.mass)

# ================================================================== BOOSTS

## The match is over: a focus or sturdy boost it used is spent (a splash one, when it fires)
func _spend_boosts() -> void:
	var b := PetState.boost
	if (b == "focus" and focus > 0) or (b == "sturdy" and sturdy > 0):
		PetState.use_boost()
	focus = 0
	sturdy = 0
	_refresh_boost_icon()

func _refresh_boost_icon() -> void:
	if not boost_icon:
		return
	var b := PetState.boost
	boost_icon.visible = b in ["splash", "focus", "sturdy"] and tut == Tut.NONE
	if boost_icon.visible:
		boost_icon.texture = PetState.boost_icon(b)

# ================================================================== QA

## (tools/qa) A decent player: leans in (harder when it's losing ground), drums on the beat most
## of the time, leans back when it's about to fall over. Skill 2 also shakes the rival at the top
## of its hop now and then, steps back when the rival leans on it hard (the pull-down) and hops
## when a beetle digs in (its horn misses a pal in the air)
func _qa_drive(delta: float) -> void:
	var tilt := 0.6
	var touching := (rival.x - me.x) - (me.half + rival.half) <= 2.0
	if touching and rival.mass * sin(rival.lean) > me.mass * sin(me.lean):
		tilt = 0.95                                          # losing ground: lean in harder
	if qa_skill >= 2:
		qa_shake -= delta
		if not rival.grounded and absf(rival.vy) < 90.0 and qa_shake <= 0.0:
			qa_shake = 0.5
			if randf() < 0.5:
				_forward_tap()
		if touching and rival.lean > 0.42 and me.lean < 0.5 and qa_back <= -0.6:
			qa_back = 0.3
		qa_back -= delta
		if qa_back > 0.0:
			tilt = -0.8
		if rival.horn_dig > 0.0 and rival.horn_dig < HORN_DIG * 0.6 and me.grounded:
			_main_tap()
	if me.lean > 0.7:
		tilt = -0.8
	me.target = 0.12 + tilt * 0.32
	if me.grounded and not me.down and me.ground_t >= qa_wait:
		_main_tap()
		qa_wait = randf_range(0.03, 0.12) if randf() < 0.8 else randf_range(0.25, 0.45)

func _qa_log(won: bool) -> void:
	if qa_autopilot:
		print("QA sumo %d-%d %s %d-%d fight %.1fs par %.1fs stars %d" % [world + 1, (level - 1) % GameData.LEVELS_PER_WORLD + 1,
			"WON" if won else "LOST", wins, losses, fight_t, _par(), match_stars if won else 0])

# ================================================================== DRAWING

func _create_static_nodes() -> void:
	painted = Sprite2D.new()
	painted.texture = ImageTexture.create_from_image(SumoArt.stage(0))
	painted.centered = false
	painted.scale = Vector2(SumoArt.PX, SumoArt.PX)
	painted.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	add_child(painted)
	stage = Node2D.new()
	stage.draw.connect(_draw_stage)
	add_child(stage)
	wrestlers = Node2D.new()
	add_child(wrestlers)
	fx = Node2D.new()
	add_child(fx)
	var ftex := _make_finger_texture()
	finger_l = _make_finger(ftex, Vector2(82, 892))
	finger_r = _make_finger(ftex, Vector2(PLAY_WIDTH - 82, 892))

	hud_level = _make_label(Vector2(30, 20), Vector2(200, 50), 36, HORIZONTAL_ALIGNMENT_LEFT, OUTLINE)
	hud_rival = _make_label(Vector2(PLAY_WIDTH - 430, 20), Vector2(400, 50), 32, HORIZONTAL_ALIGNMENT_RIGHT, OUTLINE)
	boost_icon = TextureRect.new()
	boost_icon.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	boost_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	boost_icon.size = Vector2(28, 36)
	boost_icon.position = Vector2(34, 76)
	boost_icon.visible = false
	add_child(boost_icon)
	bouts_box = HBoxContainer.new()
	bouts_box.alignment = BoxContainer.ALIGNMENT_END
	bouts_box.position = Vector2(PLAY_WIDTH - 160, 80)
	bouts_box.size = Vector2(130, 28)
	bouts_box.add_theme_constant_override("separation", 10)
	add_child(bouts_box)
	# the control legend on the box's front: what each finger does
	hint_main = make_button_hint(0, "HOP")
	hint_main.position = Vector2(134, PLAY_HEIGHT - 90)            # (on the box's front, clear of the screen's rounded corners)
	hint_fwd = make_button_hint(1, "SHAKE")
	hint_fwd.size = hint_fwd.get_combined_minimum_size()
	hint_fwd.position = Vector2(PLAY_WIDTH - 134 - hint_fwd.size.x, PLAY_HEIGHT - 90)
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

## The HUD's ink: dark on the light walls, light with a dark edge on the forest and the night
func _style_hud() -> void:
	var light := world in LIGHT_HUD
	for l in [hud_level, hud_rival]:
		l.add_theme_color_override("font_color", TEXT if light else OUTLINE)
		l.add_theme_color_override("font_outline_color", OUTLINE)
		l.add_theme_constant_override("outline_size", 10 if light else 0)

func _set_rival_name(n: String) -> void:
	hud_rival.text = "VS " + n
	hud_rival.add_theme_font_size_override("font_size", 32 if n.length() <= 12 else 25)

## On top of the painted stage: a small shadow under each wrestler (smaller while hopping), and a
## focused pal's beat: a ring of light at its feet while the window is open
func _draw_stage() -> void:
	for w in [me, rival]:
		if w and not w.down:
			var k := clampf(1.0 + w.y / 120.0, 0.4, 1.0)
			stage.draw_colored_polygon(_ellipse(Vector2(w.x, RING_C.y + 4), w.half * k, 8 * k, 16), Color(0.3, 0.2, 0.1, 0.25))
	if focus > 0 and me and phase == Phase.FIGHT and me.grounded and not me.down and me.ground_t < _window(me):
		var pts := _ellipse(Vector2(me.x, RING_C.y + 4), me.half + 10.0, 14.0, 24)
		pts.append(pts[0])
		stage.draw_polyline(pts, Color(1.0, 0.94, 0.55, 0.85 * (1.0 - me.ground_t / _window(me))), 4.0)

func _ellipse(c: Vector2, rx: float, ry: float, n: int) -> PackedVector2Array:
	var pts := PackedVector2Array()
	for i in n:
		var a := TAU * i / n
		pts.append(c + Vector2(cos(a) * rx, sin(a) * ry))
	return pts

func _refresh_hud() -> void:
	# bouts: filled = won, red = lost, empty = to go (best of 3; the mystery challenger: one)
	for n in bouts_box.get_children():
		n.queue_free()
	var empty := Color(1, 1, 1, 0.25) if world in LIGHT_HUD else Color(0, 0, 0, 0.18)
	for i in (1 if mystery else 3):
		var r := ColorRect.new()
		r.custom_minimum_size = Vector2(28, 28)
		r.color = Color8(250, 210, 90) if i < wins else (Color8(206, 74, 52) if i < wins + losses else empty)
		bouts_box.add_child(r)

## Your pal's card: its picture printed on paper and folded (_card_from_image)
func _make_card_texture(path: String) -> Texture2D:
	if _cards.has(path):
		return _cards[path]
	var src: Image = (load(path) as Texture2D).get_image()
	if src.is_compressed():
		src.decompress()
	src.convert(Image.FORMAT_RGBA8)
	_cards[path] = _card_from_image(src)
	return _cards[path]

## A rival's card: its picture (tools/art/sumo_rivals.py), or the mystery challenger's shadow on
## black paper
func _rival_card(d: Dictionary) -> Texture2D:
	var dark: bool = d.get("shadow", false)
	var which := "shadow" if dark else ("champ" if bool(d["champ"]) else str(int(d["look"])))
	var path := "res://textures/minigames/sumo/rivals/%s_%s.png" % [d["figure"], which]
	if not _cards.has(path):
		var src: Image = (load(path) as Texture2D).get_image()
		if src.is_compressed():
			src.decompress()
		src.convert(Image.FORMAT_RGBA8)
		_cards[path] = _card_from_image(src, dark)
	return _cards[path]

## A figure printed on paper and folded down the middle: a white paper margin round its shape,
## the right half a touch shaded (the fold), two tabs at the bottom as feet (dark: black paper)
func _card_from_image(src: Image, dark := false) -> Texture2D:
	var paper := Color8(58, 48, 82) if dark else PAPER
	var paper_shade := Color8(48, 40, 70) if dark else PAPER_SHADE
	var used := src.get_used_rect()
	const M := 4                                       # paper margin
	const TAB := 6
	var w := used.size.x + M * 2
	var h := used.size.y + M * 2 + TAB
	var img := Image.create(w, h, false, Image.FORMAT_RGBA8)
	# paper: a disc of M px stamped round every pixel of the figure
	for y in used.size.y:
		for x in used.size.x:
			if src.get_pixel(used.position.x + x, used.position.y + y).a <= 0.5:
				continue
			for dy in range(-M, M + 1):
				for dx in range(-M, M + 1):
					if dx * dx + dy * dy <= M * M:
						img.set_pixel(x + M + dx, y + M + dy, paper)
	# straight bottom edge, then the two feet tabs
	var bottom := h - TAB - 1
	for x in range(M, w - M):
		for y in range(bottom - M, bottom + 1):
			img.set_pixel(x, y, paper)
	for x in range(M + 2, M + 2 + w / 5):
		for y in range(bottom, h):
			img.set_pixel(x, y, paper)
			img.set_pixel(w - 1 - x, y, paper)
	# the figure on top
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
			if x == w / 2 and c.is_equal_approx(paper):
				c = paper_shade
			out.set_pixel(x, y, c)
	return ImageTexture.create_from_image(out)

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
	t.tween_property(f, "position:y", 860.0, 0.04)
	t.tween_property(f, "position:y", 892.0, 0.08)
	_sfx("res://sounds/fx/wood_tap.wav", -12.0, 0.0, 0.75)

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
	t.x += (float(Input.is_key_pressed(KEY_RIGHT) or Input.is_key_pressed(KEY_D)) - float(Input.is_key_pressed(KEY_LEFT) or Input.is_key_pressed(KEY_A))) * 0.8
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

func on_main_button_released() -> void:
	if level_menu_open():
		super.on_main_button_released()                # (the level menu's hold)

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
		_finish_tutorial()                             # skip the tutorial: the real level 1 now
		_new_match()
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
	if is_game_over or level_menu_open():
		super.on_forward_button_pressed()              # (the level menu's next world)

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
## is paused (the how-to card, the level menu) it waits, instead of being lost; a new match drops
## what the old one still had to come
func _after(secs: float, f: Callable, id := -1) -> void:
	if id < 0:
		id = match_id
	var t := create_tween()
	t.tween_interval(secs)
	t.tween_callback(func():
		if is_game_over or id != match_id:
			return
		if not is_running:
			_after(0.1, f, id)
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

## A word that pops up over the ring for a moment ("WIND UP!")
func _pop_text(text: String, at: Vector2) -> void:
	var l := _make_label(at - Vector2(150, 25), Vector2(300, 50), 30, HORIZONTAL_ALIGNMENT_CENTER, TEXT)
	l.text = text
	l.add_theme_color_override("font_outline_color", OUTLINE)
	l.add_theme_constant_override("outline_size", 10)
	var t := create_tween()
	t.tween_property(l, "position:y", l.position.y - 40.0, 0.8)
	t.parallel().tween_property(l, "modulate:a", 0.0, 0.5).set_delay(0.3)
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
