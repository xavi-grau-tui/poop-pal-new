extends Node
## Autoload singleton — persists game scores, progress, and unlocks.
## Access via GameData.get_max_score(0), GameData.report_score(0, 150), etc.

signal score_changed(game_index: int)
signal progress_changed(game_index: int)
signal game_unlocked(game_index: int)

const SAVE_PATH := "user://game_data.json"

# Per-game data: { game_index: { "max_score": int, "progress": float, "unlocked": bool } }
var games := {}

# Progress thresholds: when a game hits X%, unlock game Y
var unlock_thresholds := {
	0: { 50.0: 1 },  # Pipe Dream at 50% unlocks game 2
}

# Target score for 100% progress per game
var progress_target := {
	0: 300,  # Pipe Dream: 300 pipes = 100%
	1: 1500, # Tilt Maze: 1500 points = 100%
	2: 2000, # Splash Hoops
	3: 3000, # Pal Dash
	4: 5000, # Tile Break
	5: 8000, # Germ Zap
	6: 6000, # Tummy Tunes
	7: 10000, # Flipper Belly
}

## Prototype/testing: games unlocked regardless of progress
const DEBUG_UNLOCKED := [1, 2, 3, 4, 5, 6, 7]
## Prototype/testing: every launch starts with no best scores and no progress (fresh start)
const RESET_SCORES_ON_LAUNCH := true

func _ready() -> void:
	_init_game(0, true)   # Pipe Dream — unlocked by default
	_init_game(1, false)
	_init_game(2, false)
	_init_game(3, false)
	_init_game(4, false)
	_init_game(5, false)
	_init_game(6, false)
	_init_game(7, false)
	load_data()
	if RESET_SCORES_ON_LAUNCH:
		for idx in games:
			games[idx]["max_score"] = 0
			games[idx]["progress"] = 0.0
			games[idx]["unlocked"] = idx == 0         # only the first game, as on a new install
			games[idx]["intro"] = false               # (and the how-to cards show again)
		save_data()
	for idx in DEBUG_UNLOCKED:
		games[idx]["unlocked"] = true

func _init_game(index: int, unlocked: bool) -> void:
	if index not in games:
		games[index] = { "max_score": 0, "progress": 0.0, "unlocked": unlocked, "intro": false }

## The "how to play" card is shown the first time a game is played
func intro_seen(game_index: int) -> bool:
	return game_index in games and games[game_index].get("intro", false)

func mark_intro_seen(game_index: int) -> void:
	if game_index in games:
		games[game_index]["intro"] = true
		save_data()

# --- Score reporting (called when a minigame round ends) ---

func report_score(game_index: int, score: int) -> int:
	"""Reports a score. Returns the delta added to the LCD total (0 if no new record)."""
	if game_index not in games:
		return 0

	var data = games[game_index]
	var old_max: int = data["max_score"]
	var delta := 0

	if score > old_max:
		delta = score - old_max
		data["max_score"] = score
		score_changed.emit(game_index)

	# Progress = max_score / target * 100, capped at 100%
	var target: int = progress_target.get(game_index, 300)
	data["progress"] = minf(float(data["max_score"]) / float(target) * 100.0, 100.0)
	progress_changed.emit(game_index)

	_check_unlocks(game_index)
	save_data()
	return delta

func get_max_score(game_index: int) -> int:
	if game_index in games:
		return games[game_index]["max_score"]
	return 0

func get_progress(game_index: int) -> float:
	if game_index in games:
		return games[game_index]["progress"]
	return 0.0

func is_unlocked(game_index: int) -> bool:
	if game_index in games:
		return games[game_index]["unlocked"]
	return false

func get_total_score() -> int:
	var total := 0
	for data in games.values():
		total += data["max_score"]
	return total

# --- Unlock checks ---

func _check_unlocks(source_game: int) -> void:
	if source_game not in unlock_thresholds:
		return
	var thresholds = unlock_thresholds[source_game]
	var progress = games[source_game]["progress"]
	for threshold in thresholds:
		var target_game: int = thresholds[threshold]
		if progress >= threshold and target_game in games and not games[target_game]["unlocked"]:
			games[target_game]["unlocked"] = true
			game_unlocked.emit(target_game)

# --- Save / Load ---

func save_data() -> void:
	var file = FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(games))

func load_data() -> void:
	if not FileAccess.file_exists(SAVE_PATH):
		return
	var file = FileAccess.open(SAVE_PATH, FileAccess.READ)
	if not file:
		return
	var parsed = JSON.parse_string(file.get_as_text())
	if parsed is Dictionary:
		for key in parsed:
			var idx = int(key)
			if idx in games:
				games[idx]["max_score"] = int(parsed[key].get("max_score", 0))
				games[idx]["progress"] = float(parsed[key].get("progress", 0.0))
				games[idx]["unlocked"] = bool(parsed[key].get("unlocked", false))
				games[idx]["intro"] = bool(parsed[key].get("intro", false))
		# Pipe Dream always unlocked
		games[0]["unlocked"] = true
