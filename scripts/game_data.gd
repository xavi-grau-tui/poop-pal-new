extends Node
## Autoload singleton — persists game scores, progress, and unlocks.
## Access via GameData.get_max_score(0), GameData.report_score(0, 150), etc.

signal score_changed(game_index: int)
signal progress_changed(game_index: int)
signal game_unlocked(game_index: int)
signal coins_changed(coins: int)

const SAVE_PATH := "user://game_data.json"

# Per-game data: { game_index: { "max_score": int, "progress": float, "unlocked": bool } }
var games := {}

# Progress thresholds: when a game hits X%, unlock game Y (none now: coins buy the games)
var unlock_thresholds := {}

## Coins (2026-10-10): a game's stage cleared for the first time gives 1 coin; GAME_PRICE coins
## buy the next locked game (in the Games menu's order) on their own, until there's a shop
const GAME_PRICE := 5
var coins := 0

## The game everyone starts with (the Games menu's first card: GameMenuSwitcher.ORDER)
const FIRST_GAME := 2   # Splash Hoops

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
	8: 3000, # Top Spin (prototype)
	9: 3000, # Paper Sumo (prototype)
}

## Prototype/testing: games unlocked regardless of progress
const DEBUG_UNLOCKED := [0, 1, 3, 4, 5, 6, 7, 8, 9]
## Prototype/testing: every launch starts with no best scores and no progress (fresh start)
const RESET_SCORES_ON_LAUNCH := true

func _ready() -> void:
	_init_game(0, false)
	_init_game(1, false)
	_init_game(2, true)   # Splash Hoops — unlocked by default (FIRST_GAME)
	_init_game(3, false)
	_init_game(4, false)
	_init_game(5, false)
	_init_game(6, false)
	_init_game(7, false)
	_init_game(8, false)
	_init_game(9, false)
	load_data()
	if RESET_SCORES_ON_LAUNCH:
		for idx in games:
			games[idx]["max_score"] = 0
			games[idx]["progress"] = 0.0
			games[idx]["unlocked"] = idx == FIRST_GAME   # only the first game, as on a new install
			games[idx]["intro"] = false               # (and the how-to cards show again)
			games[idx]["stages"] = 0
		coins = 0
		save_data()
	for idx in DEBUG_UNLOCKED:
		games[idx]["unlocked"] = true

func _init_game(index: int, unlocked: bool) -> void:
	if index not in games:
		games[index] = { "max_score": 0, "progress": 0.0, "unlocked": unlocked, "intro": false, "stages": 0 }

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

# --- Stages and coins ---

## A game's stage `stage` (1, 2, ...) was cleared. The first time: +1 coin (returns true), and
## once there are GAME_PRICE coins they buy the next locked game.
func clear_stage(game_index: int, stage: int) -> bool:
	if game_index not in games or stage <= games[game_index].get("stages", 0):
		return false
	games[game_index]["stages"] = stage
	coins += 1
	coins_changed.emit(coins)
	_buy_next_game()
	save_data()
	return true

func stages_cleared(game_index: int) -> int:
	return games[game_index].get("stages", 0) if game_index in games else 0

## The next locked game in the Games menu's order, or -1
func next_locked_game() -> int:
	for idx in GameMenuSwitcher.ORDER:
		if idx in games and not games[idx]["unlocked"]:
			return idx
	return -1

func _buy_next_game() -> void:
	var idx := next_locked_game()
	if coins < GAME_PRICE or idx < 0:
		return
	coins -= GAME_PRICE
	games[idx]["unlocked"] = true
	coins_changed.emit(coins)
	game_unlocked.emit(idx)

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
		file.store_string(JSON.stringify({ "games": games, "coins": coins }))

func load_data() -> void:
	if not FileAccess.file_exists(SAVE_PATH):
		return
	var file = FileAccess.open(SAVE_PATH, FileAccess.READ)
	if not file:
		return
	var parsed = JSON.parse_string(file.get_as_text())
	if parsed is Dictionary:
		# { "games": {...}, "coins": n } (older saves: just the games)
		var saved: Dictionary = parsed.get("games", parsed)
		coins = int(parsed.get("coins", 0))
		for key in saved:
			if not str(key).is_valid_int():
				continue
			var idx = int(key)
			if idx in games:
				games[idx]["max_score"] = int(saved[key].get("max_score", 0))
				games[idx]["progress"] = float(saved[key].get("progress", 0.0))
				games[idx]["unlocked"] = bool(saved[key].get("unlocked", false))
				games[idx]["intro"] = bool(saved[key].get("intro", false))
				games[idx]["stages"] = int(saved[key].get("stages", 0))
		# the first game is always unlocked
		games[FIRST_GAME]["unlocked"] = true
