extends Node
## Autoload singleton — the current poop: which form it is, what it has eaten,
## and which forms have ever been discovered (future gallery / Poop-Pedia).
##
## Cycle (prototype):
##   no poop  --first meal-->  stage 1 baby (family of that food)
##   stage 1  --next meal-->   stage 2 evolution (dominant family across meals, ties -> latest meal)
##   any      --flush-->       no poop

signal form_changed(form_id: String, reason: String)  # reason: "hatch" | "evolve" | "flush" | "load"
signal fed(food: Dictionary)
signal drank(drink: Dictionary)
signal score_changed(total: int)
signal boost_changed(boost_id: String)                  # "" = no boost

const SAVE_PATH := "user://pet_state.json"

## Prototype/testing: every launch starts from zero — no poop, score 0, empty Poop-Pedia.
const FRESH_START_ON_LAUNCH := true

## Every pal. "no" = Poop-Pedia number, "from" = what it evolves from,
## "desc" = shown once discovered, "hint" = shown while it is still "???".
const FORMS := {
	"sprig":        { "no": 1, "name": "Sprig",        "stage": 1, "family": "green",  "from": "",
		"desc": "Hatched from a salad. Photosynthesises when nobody is looking.",
		"hint": "Start a pal with something green.",
		"frames": ["res://textures/pet/forms/sprig-1.png", "res://textures/pet/forms/sprig-2.png"] },
	"broccolump":   { "no": 2, "name": "Broccolump",   "stage": 2, "family": "green",  "from": "sprig",
		"desc": "Grown on greens. Proudly fibrous, faintly smug.",
		"hint": "A Sprig that keeps eating its greens...",
		"frames": ["res://textures/pet/forms/broccolump-1.png", "res://textures/pet/forms/broccolump-2.png"] },
	"swirlet":      { "no": 3, "name": "Swirlet",      "stage": 1, "family": "sweet",  "from": "",
		"desc": "Born from sugar. Hums when it is happy, which is always.",
		"hint": "Start a pal with something sweet.",
		"frames": ["res://textures/pet/forms/swirlet-1.png", "res://textures/pet/forms/swirlet-2.png"] },
	"neapoolitan":  { "no": 4, "name": "Neapoolitan",  "stage": 2, "family": "sweet",  "from": "swirlet",
		"desc": "Three flavours, one cherry, zero regrets.",
		"hint": "Something sweet, then something sweeter...",
		"frames": ["res://textures/pet/forms/neapoolitan-1.png", "res://textures/pet/forms/neapoolitan-2.png"] },
	"nugget":       { "no": 5, "name": "Nugget",       "stage": 1, "family": "greasy", "from": "",
		"desc": "Deep-fried at birth. Squeaks when poked.",
		"hint": "Start a pal with something greasy.",
		"frames": ["res://textures/pet/forms/nugget-1.png", "res://textures/pet/forms/nugget-2.png"] },
	"greasy_chonk": { "no": 6, "name": "Greasy Chonk", "stage": 2, "family": "greasy", "from": "nugget",
		"desc": "Glistening. Content. Do not squeeze.",
		"hint": "What happens if a Nugget never stops eating junk?",
		"frames": ["res://textures/pet/forms/greasy_chonk-1.png", "res://textures/pet/forms/greasy_chonk-2.png"] },
}

## Pedia order (by number)
func pedia_order() -> Array:
	var ids := FORMS.keys()
	ids.sort_custom(func(a, b): return FORMS[a]["no"] < FORMS[b]["no"])
	return ids

const STARTERS := { "green": "sprig", "sweet": "swirlet", "greasy": "nugget" }
const EVOLUTIONS := { "green": "broccolump", "sweet": "neapoolitan", "greasy": "greasy_chonk" }

var form_id := ""          # "" = no poop yet, waiting for the first meal
var meals: Array = []      # food families eaten this cycle, in order
var discovered: Array = [] # every form ever reached
var score := 0             # main LCD score: every minigame round adds its points

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

func _ready() -> void:
	load_data()
	if FRESH_START_ON_LAUNCH:
		form_id = ""
		meals.clear()
		score = 0
		discovered.clear()
		boost = ""
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

func feed(food: Dictionary) -> void:
	var family: String = food.get("family", "")
	if family == "":
		return
	meals.append(family)
	fed.emit(food)

	if form_id == "":
		_set_form(STARTERS[family], "hatch")
	elif FORMS[form_id]["stage"] == 1:
		_set_form(EVOLUTIONS[_dominant_family()], "evolve")
	else:
		save_data()

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
	save_data()
	form_changed.emit("", "flush")
	boost_changed.emit("")

func _dominant_family() -> String:
	var counts := {}
	for f in meals:
		counts[f] = counts.get(f, 0) + 1
	var best: String = meals[-1]  # ties go to the latest meal
	for f in counts:
		if counts[f] > counts[best]:
			best = f
	return best

func _set_form(id: String, reason: String) -> void:
	form_id = id
	if id not in discovered:
		discovered.append(id)
	save_data()
	form_changed.emit(id, reason)

# --- Save / Load ---

func save_data() -> void:
	var file = FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify({ "form_id": form_id, "meals": meals, "discovered": discovered, "score": score, "boost": boost }))

func load_data() -> void:
	if not FileAccess.file_exists(SAVE_PATH):
		return
	var file = FileAccess.open(SAVE_PATH, FileAccess.READ)
	if not file:
		return
	var parsed = JSON.parse_string(file.get_as_text())
	if parsed is Dictionary:
		form_id = str(parsed.get("form_id", ""))
		if form_id not in FORMS:
			form_id = ""
		meals = parsed.get("meals", [])
		discovered = parsed.get("discovered", [])
		score = int(parsed.get("score", 0))
		boost = str(parsed.get("boost", ""))
