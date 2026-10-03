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

# "How to play" card, shown the first time a game is played: a game sets these in its
# _ready() before calling super._ready(). The game waits behind the card (paused) until the
# main button is pressed ("OK").
var intro_text := ""
var intro_icon: Texture2D = null
var intro_card: Control = null

func _ready() -> void:
	start_game()
	if intro_text != "" and not GameData.intro_seen(_game_index()):
		is_running = false
		_show_intro()

func _game_index() -> int:
	var gs = get_node_or_null("/root/PoopPal/Main UI/GameScreen")
	return gs.current_game_index if gs else -1

func intro_active() -> bool:
	return intro_card != null

## OK: the card goes away and the game starts
func dismiss_intro() -> void:
	if not intro_card:
		return
	GameData.mark_intro_seen(_game_index())
	var card := intro_card
	intro_card = null
	var t := create_tween()
	t.tween_property(card, "scale", Vector2(0.85, 0.85), 0.12)
	t.parallel().tween_property(card, "modulate:a", 0.0, 0.12)
	t.tween_callback(card.queue_free)
	_play_clack()
	is_running = true

## A square card in the food menu labels' style (dark border, cream face, brown shadow)
func _show_intro() -> void:
	var font = load("res://fonts/pixChicago.ttf")
	var card := Control.new()
	card.size = Vector2(600, 470)
	card.position = Vector2((PLAY_WIDTH - card.size.x) / 2.0, (PLAY_HEIGHT - card.size.y) / 2.0)
	card.pivot_offset = card.size / 2.0
	add_child(card)
	var dim := ColorRect.new()                   # the game shows dimmed behind it
	dim.color = Color(0, 0, 0, 0.35)
	dim.position = -card.position
	dim.size = Vector2(PLAY_WIDTH, PLAY_HEIGHT)
	card.add_child(dim)
	var bg := NinePatchRect.new()
	bg.texture = _label_frame_texture()
	bg.patch_margin_left = 4
	bg.patch_margin_right = 4
	bg.patch_margin_top = 4
	bg.patch_margin_bottom = 7
	bg.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	bg.scale = Vector2(3, 3)
	bg.size = card.size / 3.0
	card.add_child(bg)
	var text := Label.new()
	text.text = intro_text
	text.position = Vector2(40, 40)
	text.size = Vector2(card.size.x - 80, 150)
	text.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	text.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	if font:
		text.add_theme_font_override("font", font)
	text.add_theme_font_size_override("font_size", 46)
	text.add_theme_color_override("font_color", Color8(92, 60, 44))
	card.add_child(text)
	if intro_icon:                                 # e.g. the pal's ball, rolling side to side
		var icon := TextureRect.new()
		icon.texture = intro_icon
		icon.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon.size = Vector2(96, 96)
		icon.pivot_offset = icon.size / 2.0
		icon.position = Vector2((card.size.x - icon.size.x) / 2.0, 200)
		card.add_child(icon)
		var roll := icon.create_tween().set_loops()
		roll.tween_property(icon, "position:x", icon.position.x + 90, 0.9).set_trans(Tween.TRANS_SINE)
		roll.parallel().tween_property(icon, "rotation", TAU / 3.0, 0.9).set_trans(Tween.TRANS_SINE)
		roll.tween_property(icon, "position:x", icon.position.x - 90, 1.8).set_trans(Tween.TRANS_SINE)
		roll.parallel().tween_property(icon, "rotation", -TAU / 3.0, 1.8).set_trans(Tween.TRANS_SINE)
		roll.tween_property(icon, "position:x", icon.position.x, 0.9).set_trans(Tween.TRANS_SINE)
		roll.parallel().tween_property(icon, "rotation", 0.0, 0.9).set_trans(Tween.TRANS_SINE)
	# the orange button + "OK"
	var btn := TextureRect.new()
	btn.texture = load("res://textures/buttons/mainbuttonnormal.png")
	btn.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	btn.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	btn.size = Vector2(74, 70)
	btn.position = Vector2(card.size.x / 2.0 - 90, 340)
	card.add_child(btn)
	var ok := Label.new()
	ok.text = "OK"
	ok.position = Vector2(btn.position.x + btn.size.x + 18, btn.position.y)
	ok.size = Vector2(120, btn.size.y)
	ok.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	if font:
		ok.add_theme_font_override("font", font)
	ok.add_theme_font_size_override("font_size", 44)
	ok.add_theme_color_override("font_color", Color8(92, 60, 44))
	card.add_child(ok)
	var pulse := btn.create_tween().set_loops()
	pulse.tween_property(btn, "modulate", Color(1.15, 1.1, 1.0), 0.5)
	pulse.tween_property(btn, "modulate", Color.WHITE, 0.5)
	card.scale = Vector2(0.6, 0.6)
	card.modulate.a = 0.0
	var t := create_tween()
	t.tween_property(card, "scale", Vector2.ONE, 0.22).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	t.parallel().tween_property(card, "modulate:a", 1.0, 0.15)
	intro_card = card

## 16x16 pixel frame like foodmenulabel.png: 3 px dark border, cream face, a brown shadow under
## the bottom border, cut corners (stretched as a nine-patch)
static func _label_frame_texture() -> Texture2D:
	var img := Image.create(16, 16, false, Image.FORMAT_RGBA8)
	var dark := Color8(43, 33, 26)
	var cream := Color8(250, 245, 201)
	var shadow := Color8(146, 98, 52)
	for y in 16:
		for x in 16:
			var col := cream
			if y >= 14:
				col = shadow if x >= 1 and x <= 14 else Color(0, 0, 0, 0)
			elif x < 2 or x > 13 or y < 2 or y > 11:
				col = dark
			# cut corners
			if (x == 0 or x == 15) and (y == 0 or y == 13):
				col = Color(0, 0, 0, 0)
			img.set_pixel(x, y, col)
	return ImageTexture.create_from_image(img)

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
	# Points flow into the main LCD score as they are earned (not lost if the player quits mid-round)
	PetState.add_score(points)
	# ...and can unlock rewards right away (Collection.REWARDS)
	var gs = get_node_or_null("/root/PoopPal/Main UI/GameScreen")
	if gs and gs.current_game_index >= 0:
		Collection.report_game_score(gs.current_game_index, score)

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
	# long messages wrap inside the screen instead of running off it
	score_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	score_text.position.x = 50
	score_text.size.x = PLAY_WIDTH - 100
	# (games often rewrite the title/message right after end_game: lay out once they have)
	_layout_game_over.call_deferred()

## Stacks the end screen with even gaps, measured from the real text (so a long title or a
## two-line message never touches the next line): title, message, then Restart / Exit.
func _layout_game_over() -> void:
	if not game_over_overlay:
		return
	var title: Label = game_over_overlay.get_meta("title")
	var score_text: Label = game_over_overlay.get_meta("score_text")
	var restart_label: Label = game_over_overlay.get_meta("restart_label")
	var exit_label: Label = game_over_overlay.get_meta("exit_label")
	var options: Array[Label] = []
	for l in [restart_label, exit_label]:
		if l.visible:
			options.append(l)
	var has_msg := score_text.visible and score_text.text != ""
	const GAP_TITLE := 34.0          # title -> message
	const GAP_OPTIONS := 70.0        # message -> options
	const OPTION_H := 66.0
	var th := title.get_minimum_size().y
	var sh := score_text.get_minimum_size().y if has_msg else 0.0
	var total := th + (GAP_TITLE + sh if has_msg else 0.0) + GAP_OPTIONS + OPTION_H * options.size()
	var y := roundf(PLAY_HEIGHT * 0.48 - total / 2.0)
	title.position.y = y
	title.size.y = th
	y += th
	if has_msg:
		y += GAP_TITLE
		score_text.position.y = y
		score_text.size.y = sh
		y += sh
	y += GAP_OPTIONS
	for l in options:
		l.position.y = y
		l.size.y = OPTION_H
		y += OPTION_H

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
