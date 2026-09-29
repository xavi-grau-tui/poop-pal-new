extends Node2D
class_name GameScreen

## Blank "portable" screen where minigames run.
## Follows the same Menu/AnimationPlayer pattern as other menus
## so MenuManager can slide it in/out with the diapositive system.

static var is_active := false

var current_game: Node = null
var current_game_index := -1
var game_music_player: AudioStreamPlayer2D = null

# Map page indices to minigame scene paths.
var game_scenes := {
	0: "res://scenes/minigames/super_puff.tscn",
	1: "res://scenes/minigames/poo_maze.tscn",
	2: "res://scenes/minigames/poo_splash.tscn",
	3: "res://scenes/minigames/poo_dash.tscn",
	4: "res://scenes/minigames/poo_break.tscn",
	5: "res://scenes/minigames/germ_zap.tscn",
}

func _ready() -> void:
	visible = false
	is_active = false

func is_game_unlocked(page_index: int) -> bool:
	return GameData.is_unlocked(page_index)

func start_game(page_index: int) -> void:
	stop_game_internal()
	current_game_index = page_index
	is_active = true

	var game_container = get_node_or_null("Menu/GameContainer")
	var scene_path: String = game_scenes.get(page_index, "")
	if scene_path == "" or not ResourceLoader.exists(scene_path):
		return

	var scene = load(scene_path) as PackedScene
	if scene and game_container:
		current_game = scene.instantiate()
		game_container.add_child(current_game)
		if current_game.has_signal("game_ended"):
			current_game.game_ended.connect(_on_game_ended)
		if current_game.has_signal("restart_requested"):
			current_game.restart_requested.connect(_on_restart_requested)
		# Start music if the game defines one and we don't already have it playing
		_start_music_for_game()

func _start_music_for_game() -> void:
	if not current_game or current_game.game_music_path == "":
		return
	# Already playing the right song — do nothing
	if game_music_player and game_music_player.stream \
		and game_music_player.stream.resource_path == current_game.game_music_path:
		return
	# Stop any existing game music
	_stop_game_music()
	# Stop main music
	var music_controller = get_node_or_null("/root/PoopPal/MusicController")
	if music_controller:
		music_controller.stop()
	# Create new player owned by GameScreen
	game_music_player = AudioStreamPlayer2D.new()
	var stream = load(current_game.game_music_path) as AudioStream
	if stream:
		game_music_player.stream = stream
		game_music_player.autoplay = true
		add_child(game_music_player)
		game_music_player.finished.connect(_on_game_music_finished)
		var sound_btn = get_node_or_null("/root/PoopPal/Main UI/SoundButtons/SoundButton")
		if sound_btn and sound_btn.button_pressed:
			game_music_player.volume_db = linear_to_db(0.0)

func _on_game_music_finished() -> void:
	if game_music_player and game_music_player.stream:
		game_music_player.play()

func _stop_game_music() -> void:
	if game_music_player:
		game_music_player.stop()
		game_music_player.queue_free()
		game_music_player = null

func set_game_music_volume(volume: float) -> void:
	if game_music_player:
		game_music_player.volume_db = linear_to_db(volume)

func _on_game_ended(final_score: int) -> void:
	# Per-game best score + progress/unlocks (game cards).
	# (The main LCD score already received these points live, via BaseMinigame.add_score.)
	GameData.report_score(current_game_index, final_score)

func _on_restart_requested() -> void:
	var page = current_game_index
	# Just destroy old game and create new one — music stays on GameScreen
	if current_game:
		current_game.queue_free()
		current_game = null
	current_game_index = -1

	current_game_index = page
	is_active = true
	var game_container = get_node_or_null("Menu/GameContainer")
	var scene_path: String = game_scenes.get(page, "")
	if scene_path == "" or not ResourceLoader.exists(scene_path):
		return
	var scene = load(scene_path) as PackedScene
	if scene and game_container:
		current_game = scene.instantiate()
		game_container.add_child(current_game)
		if current_game.has_signal("game_ended"):
			current_game.game_ended.connect(_on_game_ended)
		if current_game.has_signal("restart_requested"):
			current_game.restart_requested.connect(_on_restart_requested)
		# Don't call _start_music_for_game — music is already playing

func stop_game() -> void:
	stop_game_internal()
	is_active = false
	visible = false

func stop_game_internal() -> void:
	# Quitting mid-round still counts towards the game's best score
	if current_game and current_game_index >= 0 and not current_game.is_game_over and current_game.score > 0:
		GameData.report_score(current_game_index, current_game.score)
	if current_game:
		if current_game.has_method("freeze"):
			current_game.freeze()
		current_game.queue_free()
		current_game = null
	current_game_index = -1
	_stop_game_music()

func reset_selection() -> void:
	pass

func reset_active_options() -> void:
	pass
