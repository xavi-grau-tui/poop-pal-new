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
## (game = Games menu page index: 0 Super Puff, 1 Poo Maze, 2 Poo Splash, 3 Poo Dash, ...)
const REWARDS := [
	{ "game": 0, "score": 5, "category": "decor", "id": "fairy_lights" },
]

## "layers": [far layer (CloudA), near layer (CloudB)] — drop-in replacements for the cloud textures.
## "unlock": how it is obtained (shown on the locked card). Default unlocked = true/false.
const BACKGROUNDS := {
	"clouds": {
		"name": "Clouds",
		"layers": ["res://textures/pet-background/clouds3.png", "res://textures/pet-background/clouds2.png"],
		"unlocked": true,
		"unlock": "",
	},
	"tp_rolls": {
		"name": "Toilet Rolls",
		"layers": ["res://textures/pet-background/tprolls_far.png", "res://textures/pet-background/tprolls_near.png"],
		"unlocked": true,  # prototype: free; later e.g. a Poo Maze reward
		"unlock": "",
	},
	"mystery_1": {
		"name": "???",
		"layers": [],
		"unlocked": false,
		"unlock": "Coming soon",
	},
}
const BACKGROUND_ORDER := ["clouds", "tp_rolls", "mystery_1"]

## Pal accessories. "dir" holds one texture per form and frame: <form>-1.png, <form>-2.png,
## drawn on the form's own canvas (see tools/art/accessories.py).
const ACCESSORIES := {
	"none": { "name": "Nothing", "dir": "", "unlocked": true, "unlock": "" },
	"round_glasses": { "name": "Round Glasses", "dir": "res://textures/pet/accessories/round_glasses/", "unlocked": true, "unlock": "" },
	"mystery_acc": { "name": "???", "dir": "", "unlocked": false, "unlock": "Coming soon" },
}
const ACCESSORY_ORDER := ["none", "round_glasses", "mystery_acc"]

## Gut decor. "frames": overlays the size of intestine-front.png, cycled to animate.
const DECOR := {
	"none": { "name": "Nothing", "frames": [], "unlocked": true, "unlock": "" },
	"fairy_lights": { "name": "Fairy Lights", "frames": ["res://textures/pet/decor/fairy_lights-1.png", "res://textures/pet/decor/fairy_lights-2.png"], "unlocked": false, "unlock": "Super Puff: 5 pts" },
	"mystery_decor": { "name": "???", "frames": [], "unlocked": false, "unlock": "Coming soon" },
}
const DECOR_ORDER := ["none", "fairy_lights", "mystery_decor"]

var owned := { "backgrounds": [], "accessories": [], "decor": [] }
var equipped_background := DEFAULT_BACKGROUND
var equipped_accessory := "none"
var equipped_decor := "none"
var new_items := {}                     # "category/id" -> true: unlocked but not looked at yet

func _ready() -> void:
	for cat in ["backgrounds", "accessories", "decor"]:
		var cat_catalog := catalog(cat)
		for id in cat_catalog:
			if cat_catalog[id]["unlocked"] and id not in owned[cat]:
				owned[cat].append(id)
	if not RESET_UNLOCKS_ON_LAUNCH:
		load_data()
	if RESET_BACKGROUND_ON_LAUNCH and equipped_background != DEFAULT_BACKGROUND:
		equipped_background = DEFAULT_BACKGROUND
		save_data()
	if RESET_EQUIPPED_ON_LAUNCH and (equipped_accessory != "none" or equipped_decor != "none"):
		equipped_accessory = "none"
		equipped_decor = "none"
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
		equipped_decor = id
	save_data()
	equipped_changed.emit(category, id)
	return true

func equip_background(id: String) -> bool:
	if not is_owned("backgrounds", id) or BACKGROUNDS[id]["layers"].is_empty():
		return false
	equipped_background = id
	save_data()
	background_changed.emit(id)
	equipped_changed.emit("backgrounds", id)
	return true

func save_data() -> void:
	var file = FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify({ "owned": owned, "equipped_background": equipped_background,
			"equipped_accessory": equipped_accessory, "equipped_decor": equipped_decor, "new_items": new_items.keys() }))

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
		var eq := str(parsed.get("equipped_background", "clouds"))
		if eq in BACKGROUNDS and is_owned("backgrounds", eq):
			equipped_background = eq
		for k in parsed.get("new_items", []):
			new_items[str(k)] = true
		var acc := str(parsed.get("equipped_accessory", "none"))
		if acc in ACCESSORIES and is_owned("accessories", acc):
			equipped_accessory = acc
		var dec := str(parsed.get("equipped_decor", "none"))
		if dec in DECOR and is_owned("decor", dec):
			equipped_decor = dec
