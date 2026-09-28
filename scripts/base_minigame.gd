extends Node2D
class_name BaseMinigame
## Base class for all minigames.
## Extend this and override the input/logic methods.
## The game screen calls on_main_button_pressed/released and on_forward_button_pressed.

signal game_ended(score: int)
signal restart_requested

var score := 0
var is_running := false
var is_paused := false
var is_game_over := false

# Optional game-specific music path
var game_music_path: String = ""
var music_player: AudioStreamPlayer2D = null
var previous_music_was_playing := false

# Error sound path — override per game or leave default
var error_sound_path: String = "res://sounds/fx/error.mp3"

# Game Over UI
var game_over_overlay: ColorRect = null
var game_over_selection := 0  # 0 = Restart, 1 = Exit

# Play area in GameContainer local coords.
const PLAY_LEFT   := 0.0
const PLAY_TOP    := 0.0
const PLAY_RIGHT  := 950.0
const PLAY_BOTTOM := 948.0
const PLAY_WIDTH  := 950.0
const PLAY_HEIGHT := 948.0

func _ready() -> void:
	start_game()

func _start_game_music() -> void:
	pass  # Music is now managed by GameScreen

func _on_game_music_finished() -> void:
	pass

func _stop_game_music() -> void:
	pass

func set_music_volume(volume: float) -> void:
	# Delegate to GameScreen
	var gs = get_node_or_null("/root/PoopPal/Main UI/GameScreen")
	if gs and gs.has_method("set_game_music_volume"):
		gs.set_game_music_volume(volume)

func start_game() -> void:
	score = 0
	is_running = true
	is_paused = false
	is_game_over = false

func end_game() -> void:
	if not is_running:
		return
	is_running = false
	_play_error_sound()
	_show_game_over()
	game_ended.emit(score)

func freeze() -> void:
	is_paused = true
	is_running = false
	# Don't hide game over — keep the screen looking exactly as it is
	# so the slide-out animation shows the game over state

func add_score(points: int) -> void:
	score += points

# --- Error sound ---

func _play_error_sound() -> void:
	var stream = load(error_sound_path) as AudioStream
	if not stream:
		return
	# Play from GameContainer so it persists even if minigame restarts
	var container = get_parent()
	if not container:
		container = self
	var sfx = AudioStreamPlayer2D.new()
	sfx.stream = stream
	sfx.volume_db = -10.0
	sfx.autoplay = true
	container.add_child(sfx)
	# Respect mute state
	var sound_btn = get_node_or_null("/root/PoopPal/Main UI/SoundButtons/SoundButton")
	if sound_btn and sound_btn.button_pressed:
		sfx.volume_db = linear_to_db(0.0)
	sfx.finished.connect(sfx.queue_free)

func _play_clack() -> void:
	var stream = load("res://sounds/fx/clack.mp3") as AudioStream
	if not stream:
		return
	var sfx = AudioStreamPlayer2D.new()
	sfx.stream = stream
	sfx.volume_db = -7.0
	sfx.autoplay = true
	add_child(sfx)
	var sound_btn = get_node_or_null("/root/PoopPal/Main UI/SoundButtons/SoundButton")
	if sound_btn and sound_btn.button_pressed:
		sfx.volume_db = linear_to_db(0.0)
	sfx.finished.connect(sfx.queue_free)

# --- Game Over UI ---

func _show_game_over() -> void:
	is_game_over = true
	game_over_selection = 0
	
	# Semi-transparent dark overlay
	game_over_overlay = ColorRect.new()
	game_over_overlay.position = Vector2(PLAY_LEFT, PLAY_TOP)
	game_over_overlay.size = Vector2(PLAY_WIDTH, PLAY_HEIGHT)
	game_over_overlay.color = Color(0, 0, 0, 0.5)
	add_child(game_over_overlay)
	
	var lcd_font = load("res://fonts/pixChicago.ttf")
	
	# "Game Over!" title
	var title = Label.new()
	title.text = "Game Over!"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.position = Vector2(0, 280)
	title.size = Vector2(PLAY_WIDTH, 80)
	if lcd_font:
		title.add_theme_font_override("font", lcd_font)
	title.add_theme_font_size_override("font_size", 64)
	title.add_theme_color_override("font_color", Color(1, 1, 1))
	add_child(title)
	game_over_overlay.set_meta("title", title)
	
	# Score display
	var score_text = Label.new()
	score_text.text = "Score: %d" % score
	score_text.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	score_text.position = Vector2(0, 370)
	score_text.size = Vector2(PLAY_WIDTH, 60)
	if lcd_font:
		score_text.add_theme_font_override("font", lcd_font)
	score_text.add_theme_font_size_override("font_size", 40)
	score_text.add_theme_color_override("font_color", Color(0.9, 0.9, 0.7))
	add_child(score_text)
	game_over_overlay.set_meta("score_text", score_text)
	
	# Restart option
	var restart_label = Label.new()
	restart_label.name = "RestartLabel"
	restart_label.text = "Restart"
	restart_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	restart_label.position = Vector2(0, 480)
	restart_label.size = Vector2(PLAY_WIDTH, 60)
	if lcd_font:
		restart_label.add_theme_font_override("font", lcd_font)
	restart_label.add_theme_font_size_override("font_size", 44)
	restart_label.add_theme_color_override("font_color", Color(1, 1, 0.4))
	add_child(restart_label)
	game_over_overlay.set_meta("restart_label", restart_label)
	
	# Exit option
	var exit_label = Label.new()
	exit_label.name = "ExitLabel"
	exit_label.text = "Exit"
	exit_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	exit_label.position = Vector2(0, 550)
	exit_label.size = Vector2(PLAY_WIDTH, 60)
	if lcd_font:
		exit_label.add_theme_font_override("font", lcd_font)
	exit_label.add_theme_font_size_override("font_size", 44)
	exit_label.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7))
	add_child(exit_label)
	game_over_overlay.set_meta("exit_label", exit_label)

func _update_game_over_selection() -> void:
	if not game_over_overlay:
		return
	var restart_label: Label = game_over_overlay.get_meta("restart_label")
	var exit_label: Label = game_over_overlay.get_meta("exit_label")
	if game_over_selection == 0:
		restart_label.text = "Restart"
		restart_label.add_theme_color_override("font_color", Color(1, 1, 0.4))
		exit_label.text = "Exit"
		exit_label.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7))
	else:
		restart_label.text = "Restart"
		restart_label.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7))
		exit_label.text = "Exit"
		exit_label.add_theme_color_override("font_color", Color(1, 1, 0.4))

func _hide_game_over() -> void:
	is_game_over = false
	if game_over_overlay:
		var title = game_over_overlay.get_meta("title") as Node
		var score_text = game_over_overlay.get_meta("score_text") as Node
		var restart_label = game_over_overlay.get_meta("restart_label") as Node
		var exit_label = game_over_overlay.get_meta("exit_label") as Node
		for n in [title, score_text, restart_label, exit_label]:
			if is_instance_valid(n):
				n.queue_free()
		game_over_overlay.queue_free()
		game_over_overlay = null

# --- Input hooks (called by main_button / forward_button) ---

func on_main_button_pressed() -> void:
	if is_game_over:
		if game_over_selection == 0:
			# Restart
			restart_requested.emit()
		else:
			# Exit — play clack and quick-slide back to pet view
			var game_btn = get_node_or_null("/root/PoopPal/Main UI/MenuButtons/GameButton")
			if game_btn:
				if game_btn.has_node("ClackSound"):
					var clack = game_btn.get_node("ClackSound") as AudioStreamPlayer2D
					clack.stop()
					clack.play()
				game_btn.button_pressed = false
				game_btn.texture_normal = game_btn.normal_texture
			var menu_mgr = get_node_or_null("/root/PoopPal/Main UI/MenuManager")
			if menu_mgr and menu_mgr.has_method("exit_game_screen"):
				menu_mgr.exit_game_screen()

func on_main_button_released() -> void:
	pass

func on_forward_button_pressed() -> void:
	if is_game_over:
		# Toggle between Restart and Exit
		game_over_selection = 1 - game_over_selection
		_update_game_over_selection()
