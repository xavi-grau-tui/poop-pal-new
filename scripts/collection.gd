extends Node
## Autoload singleton — cosmetics and collectables the player owns.
## Categories: backgrounds, accessories (worn by the pal), decor (hung on the gut).
## Not affected by PetState's fresh start: collectables are kept forever.

signal unlocked(category: String, id: String)
signal background_changed(id: String)
signal equipped_changed(category: String, id: String)

const SAVE_PATH := "user://collection.json"

## Every launch starts on the default background (unlocked ones stay unlocked)
const DEFAULT_BACKGROUND := "clouds"
const RESET_BACKGROUND_ON_LAUNCH := true
## Prototype: every launch also starts with no accessory and no gut decor (unlocks are kept)
const RESET_EQUIPPED_ON_LAUNCH := true
## Prototype: every launch forgets earned unlocks (so the unlock flow can be tried again)
const RESET_UNLOCKS_ON_LAUNCH := true

## Rewards earned in minigames: reaching `score` in one round of `game` unlocks the item.
## (game = Games menu page index: 0 Pipe Dream, 1 Tilt Maze, 2 Splash Hoops, 3 Pal Dash, 4 Tile Break, 5 Germ Zap)
const REWARDS := [
	# Pipe Dream is the first path: backgrounds, then gut decor, then dress-up
	{ "game": 0, "score": 5, "category": "backgrounds", "id": "tp_rolls" },
	{ "game": 0, "score": 10, "category": "decor", "id": "fairy_lights" },
	{ "game": 0, "score": 15, "category": "accessories", "id": "sunglasses" },
	{ "game": 0, "score": 20, "category": "decor", "id": "purple_gut" },
	{ "game": 0, "score": 30, "category": "backgrounds", "id": "pastel_yellow" },
]

## "layers": [far layer (CloudA), near layer (CloudB)] — drop-in replacements for the cloud textures.
## "unlock": how it is obtained (shown on the locked card). Default unlocked = true/false.
const BACKGROUNDS := {
	# Like the gut decor: one "complement" (the scrolling layers) + one "color" (a hue shift of
	# the pink sky behind them, pastel only for now); a colour in use is taken off by holding it
	"clouds": {
		"name": "Clouds",
		"kind": "complement",
		"layers": ["res://textures/pet-background/clouds3.png", "res://textures/pet-background/clouds2.png"],
		"unlocked": true,
		"unlock": "",
	},
	"tp_rolls": {
		"name": "Toilet Rolls",
		"kind": "complement",
		"layers": ["res://textures/pet-background/tprolls_far.png", "res://textures/pet-background/tprolls_near.png"],
		"unlocked": false,
		"unlock": "Pipe Dream: 5 pts",
	},
	# "?" slots: items still to come (nothing unlocks them yet). A list shows one page more
	# each time its current last page is fully unlocked.
	"pink": { "name": "Pink", "kind": "color", "hue": 0.0, "layers": [], "unlocked": true, "unlock": "" },
	"pastel_yellow": { "name": "Yellow", "kind": "color", "hue": 0.145, "layers": [], "unlocked": false, "unlock": "Pipe Dream: 30 pts" },
	"mystery_1": { "name": "???", "layers": [], "unlocked": false, "unlock": "" },
	"mystery_2": { "name": "???", "layers": [], "unlocked": false, "unlock": "" },
	"mystery_3": { "name": "???", "layers": [], "unlocked": false, "unlock": "" },
	"mystery_4": { "name": "???", "layers": [], "unlocked": false, "unlock": "" },
}
const BACKGROUND_ORDER := ["clouds", "tp_rolls", "pink", "pastel_yellow", "mystery_1", "mystery_2", "mystery_3", "mystery_4"]

## Pal accessories. "dir" holds one texture per form and frame: <form>-1.png, <form>-2.png,
## drawn on the form's own canvas (see tools/art/accessories.py).
const ACCESSORIES := {
	"none": { "name": "Nothing", "dir": "", "unlocked": true, "unlock": "" },
	"sunglasses": { "name": "Sunglasses", "dir": "res://textures/pet/accessories/sunglasses/", "unlocked": false, "unlock": "Pipe Dream: 15 pts" },
	"mystery_acc_1": { "name": "???", "dir": "", "unlocked": false, "unlock": "" },
	"mystery_acc_2": { "name": "???", "dir": "", "unlocked": false, "unlock": "" },
	"mystery_acc_3": { "name": "???", "dir": "", "unlocked": false, "unlock": "" },
	"mystery_acc_4": { "name": "???", "dir": "", "unlocked": false, "unlock": "" },
}
const ACCESSORY_ORDER := ["none", "sunglasses", "mystery_acc_1", "mystery_acc_2", "mystery_acc_3", "mystery_acc_4"]

## Gut decor, two kinds that combine: one "complement" (an overlay hung on the gut; "frames"
## are the size of intestine-front.png, cycled to animate) and one "color" (a hue shift of
## the whole gut). "Nothing" takes both off.
const DECOR := {
	"none": { "name": "Nothing", "kind": "", "frames": [], "unlocked": true, "unlock": "" },
	"fairy_lights": { "name": "Fairy Lights", "kind": "complement", "frames": ["res://textures/pet/decor/fairy_lights-1.png", "res://textures/pet/decor/fairy_lights-2.png"], "unlocked": false, "unlock": "Pipe Dream: 10 pts" },
	"purple_gut": { "name": "Purple Gut", "kind": "color", "hue": -0.235, "frames": [], "unlocked": false, "unlock": "Pipe Dream: 20 pts" },
	"mystery_decor_1": { "name": "???", "frames": [], "unlocked": false, "unlock": "" },
	"mystery_decor_2": { "name": "???", "frames": [], "unlocked": false, "unlock": "" },
	"mystery_decor_3": { "name": "???", "frames": [], "unlocked": false, "unlock": "" },
	"mystery_decor_4": { "name": "???", "frames": [], "unlocked": false, "unlock": "" },
}
const DECOR_ORDER := ["none", "fairy_lights", "purple_gut", "mystery_decor_1", "mystery_decor_2", "mystery_decor_3", "mystery_decor_4"]

var owned := { "backgrounds": [], "accessories": [], "decor": [] }
var equipped_background := DEFAULT_BACKGROUND
const DEFAULT_BG_COLOR := "pink"
var equipped_bg_color := DEFAULT_BG_COLOR   # sky colour in use (pink = the natural sky)
var equipped_accessory := "none"
var equipped_decor := "none"          # the complement in use
var equipped_gut_color := ""           # the gut colour in use ("" = the natural pink)
var new_items := {}                     # "category/id" -> true: unlocked but not looked at yet

func _ready() -> void:
	for cat in ["backgrounds", "accessories", "decor"]:
		var cat_catalog := catalog(cat)
		for id in cat_catalog:
			if cat_catalog[id]["unlocked"] and id not in owned[cat]:
				owned[cat].append(id)
	if not RESET_UNLOCKS_ON_LAUNCH:
		load_data()
	# what the pal wears goes down the drain with it
	PetState.form_changed.connect(func(_id, reason):
		if reason == "flush" and equipped_accessory != "none":
			equip("accessories", "none"))
	if RESET_BACKGROUND_ON_LAUNCH and (equipped_background != DEFAULT_BACKGROUND or equipped_bg_color != DEFAULT_BG_COLOR):
		equipped_background = DEFAULT_BACKGROUND
		equipped_bg_color = DEFAULT_BG_COLOR
		save_data()
	if RESET_EQUIPPED_ON_LAUNCH and (equipped_accessory != "none" or equipped_decor != "none" or equipped_gut_color != ""):
		equipped_accessory = "none"
		equipped_decor = "none"
		equipped_gut_color = ""
		save_data()

func is_owned(category: String, id: String) -> bool:
	return id in owned.get(category, [])

func unlock(category: String, id: String) -> void:
	if is_owned(category, id):
		return
	if category not in owned:
		owned[category] = []
	owned[category].append(id)
	new_items["%s/%s" % [category, id]] = true
	save_data()
	unlocked.emit(category, id)

## Called by every minigame as points come in (live, mid-round)
func report_game_score(game: int, score: int) -> void:
	for r in REWARDS:
		if r["game"] == game and score >= r["score"] and not is_owned(r["category"], r["id"]):
			unlock(r["category"], r["id"])

func has_new(category: String) -> bool:
	for k in new_items:
		if k.begins_with(category + "/"):
			return true
	return false

func is_new(category: String, id: String) -> bool:
	return new_items.has("%s/%s" % [category, id])

func mark_seen_item(category: String, id: String) -> void:
	if new_items.erase("%s/%s" % [category, id]):
		save_data()

## The player has seen this category's list: its NEW badges go away
func mark_seen(category: String) -> void:
	for k in new_items.keys():
		if k.begins_with(category + "/"):
			new_items.erase(k)
	save_data()

func catalog(category: String) -> Dictionary:
	match category:
		"accessories": return ACCESSORIES
		"decor": return DECOR
	return BACKGROUNDS

func order(category: String) -> Array:
	match category:
		"accessories": return ACCESSORY_ORDER
		"decor": return DECOR_ORDER
	return BACKGROUND_ORDER

func equipped(category: String) -> String:
	match category:
		"accessories": return equipped_accessory
		"decor": return equipped_decor
	return equipped_background

## Equip any owned item of a category. Returns false if it can't be used.
func equip(category: String, id: String) -> bool:
	if category == "backgrounds":
		return equip_background(id)
	if not is_owned(category, id) or id not in catalog(category):
		return false
	if category == "accessories":
		equipped_accessory = id
	else:
		# decor: one complement + one colour; "none" clears both; picking the one already in
		# use takes it off again
		match DECOR[id].get("kind", ""):
			"color":
				equipped_gut_color = "" if equipped_gut_color == id else id
			"complement":
				equipped_decor = "none" if equipped_decor == id else id
			_:
				equipped_decor = "none"
				equipped_gut_color = ""
	save_data()
	equipped_changed.emit(category, id)
	return true

func is_in_use(category: String, id: String) -> bool:
	if category == "backgrounds":
		return equipped_background == id or equipped_bg_color == id
	if category == "decor" and id != "none":
		return equipped_decor == id or equipped_gut_color == id
	if category == "decor":
		return equipped_decor == "none" and equipped_gut_color == ""
	return equipped(category) == id

## Short 'In use' text for a category's card
func in_use_label(category: String) -> String:
	if category == "backgrounds":
		return "2 items" if equipped_bg_color != DEFAULT_BG_COLOR else BACKGROUNDS[equipped_background]["name"]
	if category == "decor":
		var names := []
		if equipped_gut_color != "":
			names.append(DECOR[equipped_gut_color]["name"].replace(" Gut", ""))
		if equipped_decor != "none":
			names.append(DECOR[equipped_decor]["name"])
		if names.size() == 2:
			return "2 items"                  # (both would not fit on the card)
		return names[0] if not names.is_empty() else "Nothing"
	return catalog(category)[equipped(category)]["name"]

func equip_background(id: String) -> bool:
	if not is_owned("backgrounds", id) or id not in BACKGROUNDS:
		return false
	if BACKGROUNDS[id].get("kind", "") == "color":
		equipped_bg_color = id                  # always one sky colour (pink by default)
	elif BACKGROUNDS[id]["layers"].is_empty():
		return false
	else:
		equipped_background = id
	save_data()
	background_changed.emit(id)
	equipped_changed.emit("backgrounds", id)
	return true

func save_data() -> void:
	var file = FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify({ "owned": owned, "equipped_background": equipped_background, "equipped_bg_color": equipped_bg_color,
			"equipped_accessory": equipped_accessory, "equipped_decor": equipped_decor, "equipped_gut_color": equipped_gut_color, "new_items": new_items.keys() }))

func load_data() -> void:
	if not FileAccess.file_exists(SAVE_PATH):
		return
	var file = FileAccess.open(SAVE_PATH, FileAccess.READ)
	if not file:
		return
	var parsed = JSON.parse_string(file.get_as_text())
	if parsed is Dictionary:
		var saved: Dictionary = parsed.get("owned", {})
		for cat in saved:
			for id in saved[cat]:
				if cat not in owned:
					owned[cat] = []
				if id not in owned[cat]:
					owned[cat].append(id)
		var bgc := str(parsed.get("equipped_bg_color", DEFAULT_BG_COLOR))
		if bgc in BACKGROUNDS and is_owned("backgrounds", bgc):
			equipped_bg_color = bgc
		var eq := str(parsed.get("equipped_background", "clouds"))
		if eq in BACKGROUNDS and is_owned("backgrounds", eq):
			equipped_background = eq
		for k in parsed.get("new_items", []):
			new_items[str(k)] = true
		var acc := str(parsed.get("equipped_accessory", "none"))
		if acc in ACCESSORIES and is_owned("accessories", acc):
			equipped_accessory = acc
		var col := str(parsed.get("equipped_gut_color", ""))
		if col in DECOR and is_owned("decor", col):
			equipped_gut_color = col
		var dec := str(parsed.get("equipped_decor", "none"))
		if dec in DECOR and is_owned("decor", dec):
			equipped_decor = dec
