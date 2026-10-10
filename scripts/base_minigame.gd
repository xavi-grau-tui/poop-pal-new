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
	# a game with levels, played before: its level menu first (the first time: straight into level 1)
	if uses_levels() and GameData.last_level(_game_index()) > 0:
		is_running = false
		open_level_menu()
		return
	start_game()
	if intro_text != "" and not GameData.intro_seen(_game_index()):
		is_running = false
		_show_intro()

# --- Levels (Progression v2): worlds of 9 levels, a level menu and a result card (LevelMenu) ---

var level_menu: LevelMenu = null

## Override: true for a game with a level menu
func uses_levels() -> bool:
	return false

func level_count() -> int:
	return GameData.LEVEL_COUNTS.get(_game_index(), 0)

## Override: the worlds' names (one per page of 9 levels)
func world_names() -> Array:
	return []

## Override: the picture behind the level menu (the game card's pattern)
func level_pattern() -> Texture2D:
	return null

## Override: the colour under that pattern
func level_backdrop() -> Color:
	return Color8(214, 196, 160)

## Override: build and start level `n` (from score 0)
func play_level(_n: int) -> void:
	pass

func level_menu_open() -> bool:
	return level_menu != null and level_menu.is_open()

func open_level_menu(focus := -1) -> void:
	is_running = false
	_ensure_level_menu()
	level_menu.show_select(focus)

func _ensure_level_menu() -> void:
	if level_menu:
		return
	level_menu = LevelMenu.new()
	add_child(level_menu)
	level_menu.setup(self, _game_index(), world_names(), level_count(), level_pattern(), level_backdrop())
	level_menu.chosen.connect(_on_level_chosen)

func _on_level_chosen(action: String, level: int) -> void:
	if action == "levels":
		level_menu.show_select(level)
		return
	level_menu.close()
	play_level(level)

## A level is over: `stars` 1-3 = cleared, 0 = not (time's up...). Records the stars (each new
## one is a coin) and shows the result card.
func finish_level(level: int, stars: int) -> void:
	is_running = false
	var idx := _game_index()
	var won := GameData.record_level(idx, level, stars) if stars > 0 else 0
	GameData.set_last_level(idx, level)
	game_ended.emit(score)                       # (the game's best score)
	_ensure_level_menu()
	level_menu.show_result(level, stars, won)

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
	calibrate_tilt()                             # (the pose they're holding now = level)
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

# --- Direct touch (phones) ---
# The device buttons reach a game through the emulated mouse, which follows ONE finger: fast
# drumming or a tap while another finger holds a button gets lost. Games that need every tap
# read the touches themselves (_input) and use this to tell which button a finger is on.

## 0 = main button, 1 = forward button, -1 = neither
func device_button_at(screen_pos: Vector2) -> int:
	var paths := ["/root/PoopPal/Main UI/MainButton", "/root/PoopPal/Main UI/SoundButtons/ForwardButton"]
	for i in paths.size():
		var b := get_node_or_null(paths[i]) as Control
		if b and (b.get_global_transform_with_canvas() * Rect2(Vector2.ZERO, b.size)).grow(20).has_point(screen_pos):
			return i
	return -1

# --- Tilt, in any holding position ---
# Tilt is measured from the way the phone is held when a round starts (calibrate_tilt), not
# from lying flat: held upright, flat or anywhere between, tilting it a little responds the same.
# The reference gravity gives the two axes to measure along: the screen's left-right, and the
# direction "forward" from that pose.

var tilt_ref := Vector3.ZERO           # gravity in the neutral pose (ZERO = not set yet)

func has_tilt_sensor() -> bool:
	return _gravity() != Vector3.ZERO

func _gravity() -> Vector3:
	var g := Input.get_gravity()
	return g if g != Vector3.ZERO else Input.get_accelerometer()

## The way the phone is held right now becomes "level"
func calibrate_tilt() -> void:
	var g := _gravity()
	if g != Vector3.ZERO:
		tilt_ref = g

## Tilt away from the neutral pose: x = right side down, y = top edge down (+ = towards the
## bottom of the screen), roughly the sine of the angle (about -1..1)
func device_tilt() -> Vector2:
	var g := _gravity()
	if g == Vector3.ZERO:
		return Vector2.ZERO
	if tilt_ref == Vector3.ZERO:
		tilt_ref = g
	var n := g.normalized()
	var n0 := tilt_ref.normalized()
	var ex := (Vector3.RIGHT - n0 * n0.x).normalized()      # the screen's left-right, level in this pose
	var ey := n0.cross(ex)                                  # "forward / back" in this pose
	return Vector2(n.dot(ex), n.dot(ey))

# --- Teaching: button hints and the coach (first-time tutorials) ---

const BUTTON_ICONS := ["res://textures/buttons/mainbuttonnormal.png", "res://textures/buttons/forwardbuttonnormal.png"]
var coach: Control = null
var _coach_text: Label = null
var _coach_icon: TextureRect = null
var _coach_small: Label = null

## One device button's icon (0 = main, 1 = forward) with a word next to it, for a game's
## control legend ("DASH", "GUARD"...)
func make_button_hint(which: int, text: String) -> HBoxContainer:
	var box := HBoxContainer.new()
	box.add_theme_constant_override("separation", 10)
	var icon := TextureRect.new()
	icon.texture = load(BUTTON_ICONS[which])
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.custom_minimum_size = Vector2(56 if which == 1 else 42, 40)
	box.add_child(icon)
	var l := Label.new()
	l.text = text
	l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	var font = load("res://fonts/pixChicago.ttf")
	if font:
		l.add_theme_font_override("font", font)
	l.add_theme_font_size_override("font_size", 30)
	l.add_theme_color_override("font_color", Color(1, 0.97, 0.9))
	l.add_theme_color_override("font_outline_color", Color8(43, 33, 26))
	l.add_theme_constant_override("outline_size", 10)
	box.add_child(l)
	add_child(box)
	return box

## The coach: a little card at the top of the screen with ONE short line and the button to
## press (pulsing); `small` is an optional second line (e.g. how to skip). which = -1: no icon.
func show_coach(text: String, which := -1, small := "") -> void:
	if not coach:
		var font = load("res://fonts/pixChicago.ttf")
		coach = Control.new()
		coach.size = Vector2(820, 150)
		coach.position = Vector2((PLAY_WIDTH - coach.size.x) / 2.0, 96)
		coach.pivot_offset = coach.size / 2.0
		coach.z_index = 10
		add_child(coach)
		var bg := NinePatchRect.new()
		bg.texture = _label_frame_texture()
		bg.patch_margin_left = 4
		bg.patch_margin_right = 4
		bg.patch_margin_top = 4
		bg.patch_margin_bottom = 7
		bg.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		bg.scale = Vector2(3, 3)
		bg.size = coach.size / 3.0
		coach.add_child(bg)
		_coach_icon = TextureRect.new()
		_coach_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		_coach_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		_coach_icon.position = Vector2(30, 30)
		_coach_icon.size = Vector2(90, 76)
		_coach_icon.pivot_offset = _coach_icon.size / 2.0
		coach.add_child(_coach_icon)
		var pulse := _coach_icon.create_tween().set_loops()
		pulse.tween_property(_coach_icon, "scale", Vector2(1.12, 1.12), 0.35).set_trans(Tween.TRANS_SINE)
		pulse.tween_property(_coach_icon, "scale", Vector2.ONE, 0.35).set_trans(Tween.TRANS_SINE)
		_coach_text = Label.new()
		_coach_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		_coach_text.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		_coach_small = Label.new()
		for l in [_coach_text, _coach_small]:
			if font:
				l.add_theme_font_override("font", font)
			l.add_theme_color_override("font_color", Color8(92, 60, 44))
			coach.add_child(l)
		_coach_text.add_theme_font_size_override("font_size", 36)
		_coach_small.add_theme_font_size_override("font_size", 22)
		_coach_small.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		_coach_small.position = Vector2(30, 104)
		_coach_small.size = Vector2(coach.size.x - 60, 26)
	var has_icon := which >= 0
	_coach_icon.visible = has_icon
	if has_icon:
		_coach_icon.texture = load(BUTTON_ICONS[which])
	# (width first: a label laid out at 0 px wide would think it needs one letter per line)
	var text_w := coach.size.x - (140.0 if has_icon else 34.0) - 34.0
	_coach_text.position = Vector2(140 if has_icon else 34, 26)
	_coach_text.size = Vector2(text_w, 76)
	_coach_text.text = text
	# the card grows to fit the text (and the small line under it)
	var font: Font = _coach_text.get_theme_font("font")
	var text_h := maxf(font.get_multiline_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, text_w, 36).y, 76.0)
	_coach_text.size = Vector2(text_w, text_h)
	_coach_small.text = small
	_coach_small.position.y = 26.0 + text_h + 6.0
	var h := _coach_small.position.y + (30.0 if small != "" else 0.0) + 26.0
	coach.size.y = h
	coach.pivot_offset = coach.size / 2.0
	(coach.get_child(0) as NinePatchRect).size = coach.size / 3.0
	_coach_icon.position.y = (h - _coach_icon.size.y) / 2.0
	coach.visible = true
	coach.scale = Vector2(0.9, 0.9)
	coach.modulate.a = 0.0
	var t := coach.create_tween()
	t.tween_property(coach, "scale", Vector2.ONE, 0.18).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	t.parallel().tween_property(coach, "modulate:a", 1.0, 0.12)
	_play_clack()

func hide_coach() -> void:
	if coach and coach.visible:
		var t := coach.create_tween()
		t.tween_property(coach, "modulate:a", 0.0, 0.15)
		t.tween_callback(func(): coach.visible = false)

# --- Input hooks (called by main_button / forward_button) ---

func on_main_button_pressed() -> void:
	if level_menu_open():
		level_menu.press()
		return
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
	if level_menu_open():
		level_menu.release()

func on_forward_button_pressed() -> void:
	if level_menu_open():
		level_menu.forward()
		return
	if is_game_over:
		# Toggle between Restart and Exit
		game_over_selection = 1 - game_over_selection
		_update_game_over_selection()
