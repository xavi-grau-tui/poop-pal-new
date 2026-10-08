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
## The last choice is remembered and shown highlighted.

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
	_button("FULL BOOT", "unboxing + boot", 720, last == "full", _full)
	_button("STRAIGHT TO GAMES", "Picklet, Games menu", 1000, last == "games", _games)

func _button(text: String, sub: String, y: float, highlighted: bool, action: Callable) -> void:
	var font = load("res://fonts/pixChicago.ttf")
	var b := Button.new()
	b.text = text + "\n" + sub
	b.position = Vector2(140, y)
	b.size = Vector2(800, 220)
	b.add_theme_font_override("font", font)
	b.add_theme_font_size_override("font_size", 46)
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

func _games() -> void:
	_save_choice("games")
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
