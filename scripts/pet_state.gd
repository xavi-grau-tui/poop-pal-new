extends Node
## Autoload singleton — the current poop: which form it is, what it has eaten,
## and which forms have ever been discovered (future gallery / Poop-Pedia).
##
## Cycle: no poop --first meal--> baby --> kid --> adult (--> mutant / legend); the flush
## starts again. What each meal does: data/evolution_tree.json (see feed()).

signal form_changed(form_id: String, reason: String)  # reason: "hatch" | "evolve" | "flush" | "load"
signal fed(food: Dictionary)
signal drank(drink: Dictionary)
signal score_changed(total: int)
signal boost_changed(boost_id: String)                  # "" = no boost
signal pal_discovered(form_id: String)                  # a form reached for the very first time

const SAVE_FILE := "pet_state.json"      # (in SaveSlot.path)

## Prototype/testing: every launch starts from zero — no poop, score 0, empty Poop-Pedia.
const FRESH_START_ON_LAUNCH := true

## Every pal and every evolution come from data/evolution_tree.json (made by
## tools/design/evolution_data.py from the user's sheet 4: docs/mockups/pal_brainstorm/v3/sheet4.png;
## art: tools/art/pals_export.py, pal_balls.py; the rules' picture: docs/evolution_tree_draft.png).
## FORMS[id] = { no, name, stage (1 Sho / baby .. 5 legend), stage_name, family, from, variant,
## foods (the food types that lead here), desc, hint, line (its look, for the art tools), frames }
const TREE_PATH := "res://data/evolution_tree.json"
const BASIC_FAMILIES := ["green", "sweet", "greasy", "spicy", "sour"]
var FORMS := {}
var STARTERS := {}          # food family -> baby
var NEXT := {}              # form -> { food family -> form }   (kids, adults, mutants)
var LEGENDS := {}           # ultra adult -> { food: legendary food name, to: legend }

func _load_tree() -> void:
	var f := FileAccess.open(TREE_PATH, FileAccess.READ)
	if not f:
		push_error("evolution tree missing: " + TREE_PATH)
		return
	var data: Dictionary = JSON.parse_string(f.get_as_text())
	FORMS = data["forms"]
	for id in FORMS:
		FORMS[id]["no"] = int(FORMS[id]["no"])
		FORMS[id]["stage"] = int(FORMS[id]["stage"])
		FORMS[id]["frames"] = ["res://textures/pet/forms/%s-1.png" % id, "res://textures/pet/forms/%s-2.png" % id]
	STARTERS = data["starters"]
	NEXT = data["next"]
	LEGENDS = data["legend"]

## Pedia order (by number)
func pedia_order() -> Array:
	var ids := FORMS.keys()
	ids.sort_custom(func(a, b): return FORMS[a]["no"] < FORMS[b]["no"])
	return ids

var form_id := ""          # "" = no poop yet, waiting for the first meal
var meals: Array = []      # food families eaten this cycle, in order
var discovered: Array = [] # every form ever reached
var score := 0             # main LCD score: every minigame round adds its points
var meals_total := 0       # every meal ever eaten (the food menu's two foods of a size take turns by it)

## Drink boosts: the last drink gives the pal one boost, used up in the next minigame that
## has a use for it (each game decides what a boost does; players find out which is best).
const BOOSTS := {
	"splash": {
		"name": "Splash",
		"desc": "Bounce back once instead of losing",
		# pixel icon: # outline, b fill, w shine
		"icon": ["...#...", "..#b#..", "..#b#..", ".#bbb#.", "#bwbbb#", "#bwbbb#", "#bbbbb#", ".#bbb#.", "..###.."],
		"colors": { "#": Color8(46, 40, 60), "b": Color8(140, 196, 236), "w": Color8(250, 252, 255) },
	},
}
var boost := ""

## When the next meal / drink is allowed (Unix seconds; 0 = now). Saved, so the LCD's countdowns
## keep running while the app is closed (LcdScreen sets them).
var food_ready_at := 0.0
var drink_ready_at := 0.0

## What the food menu's shutter last showed on each page ("0" food, "1" drinks, "2" special foods;
## "" = up, else "upcoming" / "mystery" / "wait"): it rolls only when that changes, never just
## because you flipped pages (it closes once, then stays closed until it opens). Saved.
var shutters := {}

func _ready() -> void:
	_load_tree()
	_start()

## Loads the save again (BOOT + PROGRESSION, once its folder is in use: no fresh start)
func reload() -> void:
	_start()

func _start() -> void:
	form_id = ""
	meals = []
	discovered = []
	score = 0
	meals_total = 0
	boost = ""
	food_ready_at = 0.0
	drink_ready_at = 0.0
	shutters = {}
	load_data()
	if FRESH_START_ON_LAUNCH and not SaveSlot.real():
		form_id = ""
		meals.clear()
		score = 0
		discovered.clear()
		meals_total = 0
		boost = ""
		food_ready_at = 0.0
		drink_ready_at = 0.0
		shutters = {}
		save_data()

func has_poop() -> bool:
	return form_id != ""

func needs_first_meal() -> bool:
	return form_id == ""

func get_form() -> Dictionary:
	return FORMS.get(form_id, {})

func build_sprite_frames(id: String = form_id) -> SpriteFrames:
	var form: Dictionary = FORMS.get(id, {})
	if form.is_empty():
		return null
	var frames := SpriteFrames.new()
	frames.set_animation_speed("default", 1.0)
	frames.set_animation_loop("default", true)
	frames.rename_animation("default", "idle")
	for path in form["frames"]:
		var tex := load(path) as Texture2D
		if tex:
			frames.add_frame("idle", tex)
	return frames

# --- Cycle ---

## What a food does (path-dependent: the result depends on the pal you have AND the food):
##   no pal       basic food -> its baby (special foods can't start a pal)
##   baby / kid   basic food -> the next stage (data NEXT)
##   adult        tech / cosmic -> the family's mutant; the ULTRA adult + its legendary food
##                -> its legend; basic foods are just eaten
##   mutant/legend nothing changes any more (until the flush)
func feed(food: Dictionary) -> void:
	var family: String = food.get("family", "")
	if family == "":
		return
	meals.append(family)
	meals_total += 1
	fed.emit(food)
	var to := evolution_for(food)
	if to == "":
		save_data()
	elif form_id == "":
		_set_form(to, "hatch")
	else:
		_set_form(to, "evolve")

## The form this food would turn the current pal into ("" = no change)
func evolution_for(food: Dictionary, from: String = form_id) -> String:
	var family: String = food.get("family", "")
	if from == "":
		return STARTERS.get(family, "")
	# foods grow up with the pal (FoodLibrary): a baby grows only on kid food, a kid only on adult food
	var tier: String = food.get("tier", "")
	var need: String = { 1: "kid", 2: "adult" }.get(int(FORMS.get(from, {}).get("stage", 0)), "")
	if tier != "" and need != "" and tier != need:
		return ""
	if family == "legend":
		var lg: Dictionary = LEGENDS.get(from, {})
		if lg.get("to") != null and lg.get("family", "") == food.get("legend_of", ""):
			return lg["to"]
		return ""
	return NEXT.get(from, {}).get(family, "")

## Special foods (tech / cosmic / legendary) can't be a pal's first meal
func can_start_with(food: Dictionary) -> bool:
	return food.get("family", "") in BASIC_FAMILIES

func drink(drink_data: Dictionary) -> void:
	drank.emit(drink_data)
	var b: String = drink_data.get("boost", "")
	if b != "" and b in BOOSTS:
		boost = b                         # one boost at a time: the last drink counts
		save_data()
		boost_changed.emit(boost)

func use_boost() -> void:
	if boost == "":
		return
	boost = ""
	save_data()
	boost_changed.emit("")

## Pixel icon of a boost (for the pet cam and the minigame HUDs)
func boost_icon(id: String) -> Texture2D:
	var info: Dictionary = BOOSTS.get(id, {})
	if info.is_empty():
		return null
	var rows: Array = info["icon"]
	var img := Image.create(rows[0].length(), rows.size(), false, Image.FORMAT_RGBA8)
	for y in rows.size():
		for x in rows[y].length():
			var ch: String = rows[y][x]
			if info["colors"].has(ch):
				img.set_pixel(x, y, info["colors"][ch])
	return ImageTexture.create_from_image(img)

func add_score(points: int) -> void:
	if points <= 0:
		return
	score += points
	save_data()
	score_changed.emit(score)

func flush() -> void:
	if form_id == "":
		return
	form_id = ""
	meals.clear()
	boost = ""                            # the boost goes down with the pal
	food_ready_at = 0.0
	drink_ready_at = 0.0
	save_data()
	form_changed.emit("", "flush")
	boost_changed.emit("")

func _set_form(id: String, reason: String) -> void:
	form_id = id
	var first_time := id not in discovered
	if first_time:
		discovered.append(id)
	save_data()
	form_changed.emit(id, reason)
	if first_time:
		Collection.new_items["pedia/" + id] = true     # NEW tag in the Pal-Pedia
		Collection.save_data()
		# announce it once the pal has appeared: after its "hi!" when it hatches,
		# after the evolve animation otherwise
		var delay := 2.0 if reason == "hatch" else 1.6
		get_tree().create_timer(delay).timeout.connect(func(): pal_discovered.emit(id))

# --- Save / Load ---

func save_data() -> void:
	var file = FileAccess.open(SaveSlot.path(SAVE_FILE), FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify({ "form_id": form_id, "meals": meals, "discovered": discovered, "score": score, "boost": boost,
			"meals_total": meals_total, "food_ready_at": food_ready_at, "drink_ready_at": drink_ready_at, "shutters": shutters }))

func load_data() -> void:
	if not FileAccess.file_exists(SaveSlot.path(SAVE_FILE)):
		return
	var file = FileAccess.open(SaveSlot.path(SAVE_FILE), FileAccess.READ)
	if not file:
		return
	var parsed = JSON.parse_string(file.get_as_text())
	if parsed is Dictionary:
		form_id = str(parsed.get("form_id", ""))
		if form_id not in FORMS:
			form_id = ""
		meals = parsed.get("meals", [])
		discovered = (parsed.get("discovered", []) as Array).filter(func(i): return i in FORMS)   # (pals of an older tree dropped)
		score = int(parsed.get("score", 0))
		meals_total = int(parsed.get("meals_total", 0))
		boost = str(parsed.get("boost", ""))
		food_ready_at = float(parsed.get("food_ready_at", 0.0))
		drink_ready_at = float(parsed.get("drink_ready_at", 0.0))
		shutters = parsed.get("shutters", {})
