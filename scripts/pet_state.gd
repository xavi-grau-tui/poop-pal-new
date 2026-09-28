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

const SAVE_PATH := "user://pet_state.json"

## Prototype/testing: every launch starts from zero (no poop). Discovered forms are kept.
const FRESH_START_ON_LAUNCH := true

const FORMS := {
	"sprig":        { "name": "Sprig",        "stage": 1, "family": "green",  "frames": ["res://textures/pet/forms/sprig-1.png", "res://textures/pet/forms/sprig-2.png"] },
	"swirlet":      { "name": "Swirlet",      "stage": 1, "family": "sweet",  "frames": ["res://textures/pet/forms/swirlet-1.png", "res://textures/pet/forms/swirlet-2.png"] },
	"nugget":       { "name": "Nugget",       "stage": 1, "family": "greasy", "frames": ["res://textures/pet/forms/nugget-1.png", "res://textures/pet/forms/nugget-2.png"] },
	"broccolump":   { "name": "Broccolump",   "stage": 2, "family": "green",  "frames": ["res://textures/pet/forms/broccolump-1.png", "res://textures/pet/forms/broccolump-2.png"] },
	"neapoolitan":  { "name": "Neapoolitan",  "stage": 2, "family": "sweet",  "frames": ["res://textures/pet/forms/neapoolitan-1.png", "res://textures/pet/forms/neapoolitan-2.png"] },
	"greasy_chonk": { "name": "Greasy Chonk", "stage": 2, "family": "greasy", "frames": ["res://textures/pet/forms/greasy_chonk-1.png", "res://textures/pet/forms/greasy_chonk-2.png"] },
}

const STARTERS := { "green": "sprig", "sweet": "swirlet", "greasy": "nugget" }
const EVOLUTIONS := { "green": "broccolump", "sweet": "neapoolitan", "greasy": "greasy_chonk" }

var form_id := ""          # "" = no poop yet, waiting for the first meal
var meals: Array = []      # food families eaten this cycle, in order
var discovered: Array = [] # every form ever reached

func _ready() -> void:
	load_data()
	if FRESH_START_ON_LAUNCH:
		form_id = ""
		meals.clear()
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

func flush() -> void:
	if form_id == "":
		return
	form_id = ""
	meals.clear()
	save_data()
	form_changed.emit("", "flush")

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
		file.store_string(JSON.stringify({ "form_id": form_id, "meals": meals, "discovered": discovered }))

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
