extends Node
## Autoload singleton — cosmetics and collectables the player owns.
## Backgrounds today; stickers, music, etc. can be added as new categories later.
## Not affected by PetState's fresh start: collectables are kept forever.

signal unlocked(category: String, id: String)
signal background_changed(id: String)

const SAVE_PATH := "user://collection.json"

## Every launch starts on the default background (unlocked ones stay unlocked)
const DEFAULT_BACKGROUND := "clouds"
const RESET_BACKGROUND_ON_LAUNCH := true

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

var owned := { "backgrounds": [] }
var equipped_background := DEFAULT_BACKGROUND

func _ready() -> void:
	for id in BACKGROUNDS:
		if BACKGROUNDS[id]["unlocked"] and id not in owned["backgrounds"]:
			owned["backgrounds"].append(id)
	load_data()
	if RESET_BACKGROUND_ON_LAUNCH and equipped_background != DEFAULT_BACKGROUND:
		equipped_background = DEFAULT_BACKGROUND
		save_data()

func is_owned(category: String, id: String) -> bool:
	return id in owned.get(category, [])

func unlock(category: String, id: String) -> void:
	if is_owned(category, id):
		return
	if category not in owned:
		owned[category] = []
	owned[category].append(id)
	save_data()
	unlocked.emit(category, id)

func equip_background(id: String) -> bool:
	if not is_owned("backgrounds", id) or BACKGROUNDS[id]["layers"].is_empty():
		return false
	equipped_background = id
	save_data()
	background_changed.emit(id)
	return true

func save_data() -> void:
	var file = FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify({ "owned": owned, "equipped_background": equipped_background }))

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
