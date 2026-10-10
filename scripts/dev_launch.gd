extends Control
class_name DevLaunch
## DEVELOPMENT ONLY: the first scene of debug builds (the editor and debug installs on the phone),
## set with the feature override `application/run/main_scene.debug` in project.godot. Release
## builds start the real main scene directly and never see this (skip_boot stays false there,
## so the unboxing and the boot run untouched).
##
##   FULL BOOT          the real start: unboxing, logo, welcome, as in the final game
##   STRAIGHT TO GAMES  no unboxing or boot; the pal is already the sour baby (Picklet) and the
##                      Games menu opens by itself
##   ... + 999 COINS    the same, with 999 coins to try buying games and Shop items
##   BOOT + PROGRESSION the real game as a player gets it, KEPT between launches (its own save,
##                      user://progress/, see SaveSlot): every testing switch off, only the six
##                      launch games, the unboxing only the first time, the meal and drink clocks
##                      running in real time. START OVER (two taps) wipes that save.
## The last choice is remembered and shown highlighted. The three testing starts never touch the
## progression save.

const MAIN_SCENE := "res://scenes/main.tscn"
const PREFS := "user://dev_launch.json"
const QUICK_PAL := "picklet"           # the sour baby

## Read by Unboxing and BootSequence: true only after STRAIGHT TO GAMES was picked here
static var skip_boot := false

func _ready() -> void:
	var bg := ColorRect.new()
	bg.color = Color(0.06, 0.06, 0.07)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg)
	set_anchors_preset(Control.PRESET_FULL_RECT)
	var font = load("res://fonts/pixChicago.ttf")
	var title := Label.new()
	title.text = "DEV LAUNCH"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.position = Vector2(0, 560)
	title.size = Vector2(1080, 80)
	title.add_theme_font_override("font", font)
	title.add_theme_font_size_override("font_size", 52)
	title.add_theme_color_override("font_color", Color(0.6, 0.6, 0.65))
	add_child(title)
	var last := _last_choice()
	_button("FULL BOOT", "unboxing + boot", 680, last == "full", _full)
	_button("STRAIGHT TO GAMES", "Picklet, Games menu", 930, last == "games", _games)
	_button("GAMES + 999 COINS", "to try the Shop and buying games", 1180, last == "rich", _rich)
	_button("BOOT + PROGRESSION", _progress_summary(), 1430, last == "progress", _progress)
	_start_over_button(1690)

func _button(text: String, sub: String, y: float, highlighted: bool, action: Callable) -> void:
	var font = load("res://fonts/pixChicago.ttf")
	var b := Button.new()
	b.position = Vector2(140, y)
	b.size = Vector2(800, 220)
	# the name big, what it does under it (smaller, so a long line still fits)
	for line in [[text, 46, 38.0, Color.WHITE], [sub, 30, 128.0, Color(1, 1, 1, 0.75)]]:
		var l := Label.new()
		l.text = line[0]
		l.position = Vector2(20, line[2])
		l.size = Vector2(760, 60)
		l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		l.clip_text = true
		l.mouse_filter = Control.MOUSE_FILTER_IGNORE
		l.add_theme_font_override("font", font)
		l.add_theme_font_size_override("font_size", line[1])
		l.add_theme_color_override("font_color", line[3])
		b.add_child(l)
	var box := StyleBoxFlat.new()
	box.bg_color = Color(0.93, 0.55, 0.25) if highlighted else Color(0.22, 0.22, 0.26)
	box.set_corner_radius_all(24)
	box.set_border_width_all(6)
	box.border_color = Color(1, 0.85, 0.6) if highlighted else Color(0.35, 0.35, 0.4)
	for state in ["normal", "hover", "pressed", "focus"]:
		b.add_theme_stylebox_override(state, box)
	b.add_theme_color_override("font_color", Color.WHITE)
	b.add_theme_color_override("font_pressed_color", Color.WHITE)
	b.add_theme_color_override("font_hover_color", Color.WHITE)
	b.pressed.connect(action)
	add_child(b)

func _full() -> void:
	_save_choice("full")
	skip_boot = false
	get_tree().change_scene_to_file(MAIN_SCENE)

func _progress() -> void:
	_save_choice("progress")
	skip_boot = false
	SaveSlot.use_progress()
	# the autoloads loaded (and wiped) the testing save at launch: now the progression one
	for n in [GameData, PetState, Collection, Shop]:
		n.reload()
	get_tree().change_scene_to_file(MAIN_SCENE)

## What the progression save holds, in one line (read from its files)
func _progress_summary() -> String:
	var game := SaveSlot.progress_file("game_data.json")
	var pet := SaveSlot.progress_file("pet_state.json")
	if game.is_empty() and pet.is_empty():
		return "new game, kept between launches"
	var games: Dictionary = game.get("games", {})
	var owned := 0
	var stars := 0
	for k in games:
		var g: Dictionary = games[k]
		if str(k).is_valid_int() and int(k) in GameData.LAUNCH_GAMES and g.get("unlocked", false):
			owned += 1
		for lv in g.get("levels", {}).values():
			stars += int(lv)
	var pal: String = PetState.FORMS.get(str(pet.get("form_id", "")), {}).get("name", "no pal")
	return "%s · %d coins · %d games · %d stars" % [pal, int(game.get("coins", 0)), maxi(owned, 1), stars]

## START OVER: the first tap asks, the second wipes the progression save
func _start_over_button(y: float) -> void:
	var font = load("res://fonts/pixChicago.ttf")
	var b := Button.new()
	b.text = "START OVER"
	b.position = Vector2(340, y)
	b.size = Vector2(400, 100)
	b.add_theme_font_override("font", font)
	b.add_theme_font_size_override("font_size", 34)
	var box := StyleBoxFlat.new()
	box.bg_color = Color(0.14, 0.14, 0.17)
	box.set_corner_radius_all(18)
	box.set_border_width_all(4)
	box.border_color = Color(0.35, 0.35, 0.4)
	for state in ["normal", "hover", "pressed", "focus"]:
		b.add_theme_stylebox_override(state, box)
	b.add_theme_color_override("font_color", Color(0.75, 0.75, 0.8))
	b.add_theme_color_override("font_pressed_color", Color(0.75, 0.75, 0.8))
	b.add_theme_color_override("font_hover_color", Color(0.75, 0.75, 0.8))
	var armed := [false]
	b.pressed.connect(func():
		if not armed[0]:
			armed[0] = true
			b.text = "TAP AGAIN: WIPE"
			box.border_color = Color(0.85, 0.3, 0.25)
			return
		SaveSlot.wipe_progress()
		get_tree().reload_current_scene())
	add_child(b)

func _rich() -> void:
	GameData.add_coins(999 - GameData.coins)
	_games("rich")

func _games(choice := "games") -> void:
	_save_choice(choice)
	skip_boot = true
	# the pal is already there (as if its first meal was a sour one), before the scene loads
	if not PetState.has_poop():
		PetState.form_id = QUICK_PAL
		PetState.meals = [PetState.FORMS[QUICK_PAL]["family"]]
		if QUICK_PAL not in PetState.discovered:
			PetState.discovered.append(QUICK_PAL)
		PetState.save_data()
	get_tree().change_scene_to_file(MAIN_SCENE)

## Called by BootSequence when it's skipped: open the Games menu like a tap on its button
static func open_games(tree: SceneTree) -> void:
	var btn = tree.root.get_node_or_null("PoopPal/Main UI/MenuButtons/GameButton")
	if not btn or not btn.menu_manager or not btn.target_menu:
		return
	await tree.create_timer(0.3).timeout
	btn.menu_manager.request_menu_first_half(btn.target_menu)
	await tree.create_timer(0.15).timeout
	btn.button_pressed = true
	btn.menu_manager.request_menu_second_half(btn.target_menu)

func _last_choice() -> String:
	var f := FileAccess.open(PREFS, FileAccess.READ)
	if not f:
		return "games"
	var data = JSON.parse_string(f.get_as_text())
	return data.get("choice", "games") if data is Dictionary else "games"

func _save_choice(choice: String) -> void:
	var f := FileAccess.open(PREFS, FileAccess.WRITE)
	if f:
		f.store_string(JSON.stringify({ "choice": choice }))
