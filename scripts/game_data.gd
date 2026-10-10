extends Node
## Autoload singleton — persists game scores, progress, levels, stars, coins and unlocks.
## Access via GameData.get_max_score(0), GameData.report_score(0, 150), etc.
##
## Progression v2 (docs/ideas_roadmap.md, "Progression v2"): every game is worlds of 9 levels;
## a level gives 1-3 stars; each NEW star gives 1 coin; coins buy the next games (here, in the
## Games menu) and foods / key items (Shop). Each game you own makes the next one cost double.

signal score_changed(game_index: int)
signal progress_changed(game_index: int)
signal game_unlocked(game_index: int)
signal coins_changed(coins: int)
signal stars_changed(game_index: int)

const SAVE_PATH := "user://game_data.json"

# Per-game data: { game_index: { "max_score", "progress", "unlocked", "intro", "levels", "last" } }
#   levels: { level number: best stars (1-3) }   last: the last level played
var games := {}

# Progress thresholds: when a game hits X%, unlock game Y (none now: coins buy the games)
var unlock_thresholds := {}

## The game everyone starts with (the Games menu's first card: GameMenuSwitcher.ORDER)
const FIRST_GAME := 2   # Splash Hoops

## The six launch games, in the Games menu's order (the four others are on hold)
const LAUNCH_GAMES := [2, 1, 9, 0, 8, 6]
## The 2nd game is always Tilt Maze (it teaches tilt); after it any locked game can be bought
const SECOND_GAME := 1
## Each game costs double the last one bought: 5, 10, 20, 40, 80 coins
const FIRST_PRICE := 5

## Every game: worlds of LEVELS_PER_WORLD levels (one page of its level menu)
const LEVELS_PER_WORLD := 9
## The games that already have their level menu, and how many levels (5 worlds = 45 at launch)
const LEVEL_COUNTS := { 2: 45 }

var coins := 0

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

## Prototype/testing: games unlocked regardless of coins (now only the four on hold: the six
## launch games are bought with coins, see the dev launcher's 999 COINS start)
const DEBUG_UNLOCKED := [3, 4, 5, 7]
## Prototype/testing: every launch starts with no best scores, stars, coins or bought games
const RESET_SCORES_ON_LAUNCH := true

func _ready() -> void:
	for idx in 10:
		_init_game(idx, idx == FIRST_GAME)   # Splash Hoops — unlocked by default (FIRST_GAME)
	load_data()
	if RESET_SCORES_ON_LAUNCH:
		for idx in games:
			games[idx]["max_score"] = 0
			games[idx]["progress"] = 0.0
			games[idx]["unlocked"] = idx == FIRST_GAME   # only the first game, as on a new install
			games[idx]["intro"] = false               # (and the how-to cards show again)
			games[idx]["levels"] = {}
			games[idx]["last"] = 0
		coins = 0
		save_data()
	for idx in DEBUG_UNLOCKED:
		games[idx]["unlocked"] = true

func _init_game(index: int, unlocked: bool) -> void:
	if index not in games:
		games[index] = { "max_score": 0, "progress": 0.0, "unlocked": unlocked, "intro": false, "levels": {}, "last": 0 }

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

# --- Levels and stars ---

## Best stars on a level (0 = not cleared yet)
func level_stars(game_index: int, level: int) -> int:
	if game_index not in games:
		return 0
	return int(games[game_index]["levels"].get(level, 0))

## Level 1 is always open; any other once the one before it is cleared
func level_open(game_index: int, level: int) -> bool:
	return level <= 1 or level_stars(game_index, level - 1) > 0

## A level was cleared with `stars` (1-3). Keeps the best, and each NEW star is a coin.
## Returns the coins earned (0 if no new star).
func record_level(game_index: int, level: int, stars: int) -> int:
	if game_index not in games:
		return 0
	stars = clampi(stars, 0, 3)
	var before := level_stars(game_index, level)
	games[game_index]["last"] = level
	if stars <= before:
		save_data()
		return 0
	games[game_index]["levels"][level] = stars
	var earned := stars - before
	coins += earned
	coins_changed.emit(coins)
	stars_changed.emit(game_index)
	Collection.report_game_stars(game_index, game_stars(game_index))    # (each game's gift track)
	save_data()
	return earned

## A level was played to its end (cleared or not): the game opens on its level menu from now on
func set_last_level(game_index: int, level: int) -> void:
	if game_index in games:
		games[game_index]["last"] = level
		save_data()

## The last level played (0 = none yet)
func last_level(game_index: int) -> int:
	return int(games[game_index].get("last", 0)) if game_index in games else 0

func game_stars(game_index: int) -> int:
	var total := 0
	if game_index in games:
		for lvl in games[game_index]["levels"]:
			total += int(games[game_index]["levels"][lvl])
	return total

func levels_cleared(game_index: int) -> int:
	return games[game_index]["levels"].size() if game_index in games else 0

# --- Coins and buying games ---

func add_coins(n: int) -> void:
	if n <= 0:
		return
	coins += n
	coins_changed.emit(coins)
	save_data()

## Pays `n` coins if there are enough (true), otherwise nothing happens (false)
func spend_coins(n: int) -> bool:
	if n < 0 or coins < n:
		return false
	coins -= n
	coins_changed.emit(coins)
	save_data()
	return true

## How many of the launch games are open (the first one is free)
func owned_launch_games() -> int:
	var n := 0
	for idx in LAUNCH_GAMES:
		if is_unlocked(idx):
			n += 1
	return n

## What the next game costs: double the last one (5, 10, 20, 40, 80)
func game_price() -> int:
	return FIRST_PRICE * (1 << maxi(0, owned_launch_games() - 1))

## A locked launch game that can be bought now (the 2nd is always Tilt Maze)
func can_buy_game(game_index: int) -> bool:
	if game_index not in LAUNCH_GAMES or is_unlocked(game_index):
		return false
	return game_index == SECOND_GAME or is_unlocked(SECOND_GAME)

## Buys a game with coins. Returns true if it was bought.
func buy_game(game_index: int) -> bool:
	if not can_buy_game(game_index):
		return false
	if not spend_coins(game_price()):
		return false
	games[game_index]["unlocked"] = true
	save_data()
	game_unlocked.emit(game_index)
	return true

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
				var g: Dictionary = saved[key]
				games[idx]["max_score"] = int(g.get("max_score", 0))
				games[idx]["progress"] = float(g.get("progress", 0.0))
				games[idx]["unlocked"] = bool(g.get("unlocked", false))
				games[idx]["intro"] = bool(g.get("intro", false))
				games[idx]["last"] = int(g.get("last", 0))
				# (JSON keys come back as text: level numbers again)
				var lv := {}
				var saved_levels = g.get("levels", {})
				if saved_levels is Dictionary:
					for k in saved_levels:
						if str(k).is_valid_int():
							lv[int(k)] = int(saved_levels[k])
				games[idx]["levels"] = lv
		# the first game is always unlocked
		games[FIRST_GAME]["unlocked"] = true
