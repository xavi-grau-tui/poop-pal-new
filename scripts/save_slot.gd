class_name SaveSlot
## Where the save files live.
##   user://           the testing starts (the dev launcher's FULL BOOT / STRAIGHT TO GAMES / 999
##                     COINS, and release builds for now): the testing switches wipe it every launch
##   user://progress/  the dev launcher's BOOT + PROGRESSION: the real game as a player gets it,
##                     kept between launches, with every testing switch off (nothing reset, no
##                     unlocks for testing, the unboxing only the first time)
## The autoloads load the testing save at launch; picking BOOT + PROGRESSION switches the folder
## and calls their reload() before the main scene loads.

const PROGRESS := "progress/"
const FILES := ["game_data.json", "pet_state.json", "collection.json", "shop.json", "device.json"]

static var folder := ""

static func path(file: String) -> String:
	return "user://" + folder + file

## True in BOOT + PROGRESSION: the testing switches are off
static func real() -> bool:
	return folder != ""

static func use_progress() -> void:
	folder = PROGRESS
	DirAccess.make_dir_recursive_absolute("user://" + PROGRESS)

## The progression save, read straight from its files (for the dev launcher's summary)
static func progress_file(file: String) -> Dictionary:
	var f := FileAccess.open("user://" + PROGRESS + file, FileAccess.READ)
	if not f:
		return {}
	var data = JSON.parse_string(f.get_as_text())
	return data if data is Dictionary else {}

## Deletes the progression save (the dev launcher's START OVER)
static func wipe_progress() -> void:
	for file in FILES:
		var p: String = "user://" + PROGRESS + file
		if FileAccess.file_exists(p):
			DirAccess.remove_absolute(p)
