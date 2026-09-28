extends TextureButton

@export var click_sound      : AudioStreamPlayer2D
@export var release_sound    : AudioStreamPlayer2D
@export var hold_duration    := 1.0
@export var fill_start_delay := 0.25

var was_pressed        := false
var hold_timer         := 0.0
var filling            := false
var selected_doughnut  : TextureProgressBar = null

func _ready() -> void:
	toggle_mode = false
	set_process(true)

# ------------------------------------------------------------------ INPUT
func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			# Route to active minigame
			if GameScreen.is_active:
				if click_sound:
					click_sound.stop()
					click_sound.play()
				Input.vibrate_handheld(15)
				_route_to_minigame("on_main_button_pressed")
				return

			was_pressed       = true
			hold_timer        = 0.0
			filling           = false
			selected_doughnut = _get_selected_doughnut()

			if click_sound:
				click_sound.stop()
				click_sound.play()
			Input.vibrate_handheld(15)

			await get_tree().create_timer(0.3).timeout
			if was_pressed:
				# Don't start filling for locked games
				if _is_game_menu_active() and not _is_current_game_unlocked():
					_reset_hold()
					return
				filling = true
				if selected_doughnut:
					selected_doughnut.visible = true
					selected_doughnut.value   = 0

		elif was_pressed:
			var mp = get_local_mouse_position()
			if mp.x >= 0 and mp.y >= 0 and mp.x <= size.x and mp.y <= size.y:
				if release_sound:
					release_sound.stop()
					release_sound.play()
				Input.vibrate_handheld(15)

				if not filling:
					_handle_main_button_press()

			_reset_hold()

		elif GameScreen.is_active:
			if release_sound:
				release_sound.stop()
				release_sound.play()
			_route_to_minigame("on_main_button_released")

# ------------------------------------------------------------------ MAIN ROTATE
func _handle_main_button_press() -> void:
	for b in get_tree().get_nodes_in_group("menu_toggle_buttons"):
		if b.button_pressed and b.target_menu and b.target_menu.has_method("select_next"):
			b.target_menu.select_next()
			break

# ------------------------------------------------------------------ PROCESS / HOLD-TO-CONFIRM
func _process(delta: float) -> void:
	if not filling:
		return

	hold_timer += delta

	# Update doughnut visual if we have one (food/drink)
	if selected_doughnut and hold_timer >= fill_start_delay:
		var ratio = (hold_timer - fill_start_delay) / (hold_duration - fill_start_delay)
		var value = clamp(ratio * 100.0, 0, 100.0)

		selected_doughnut.value   = value
		selected_doughnut.visible = true

		if selected_doughnut.has_node("DoughnutBorder"):
			var border : TextureProgressBar = selected_doughnut.get_node("DoughnutBorder")
			border.value   = value
			border.visible = true

	# Hold complete
	if hold_timer >= hold_duration:
		filling = false

		var sel = _get_selected_option_node()
		if sel and sel.has_node("ConfirmSound"):
			var csp : AudioStreamPlayer2D = sel.get_node("ConfirmSound")
			if csp.stream:
				csp.play()
				await csp.finished

		_handle_hold_confirm(sel)
		_reset_hold()

# ------------------------------------------------------------------ HOLD CONFIRM DISPATCH
func _handle_hold_confirm(sel: Node) -> void:
	if not sel:
		return

	if _is_game_menu_active():
		if not _is_current_game_unlocked():
			return
		_launch_game()
		return

	_spawn_food_or_drink_effect(sel)
	_untoggle_current_menu()

# ------------------------------------------------------------------ LAUNCH GAME
func _launch_game() -> void:
	for b in get_tree().get_nodes_in_group("menu_toggle_buttons"):
		if b.button_pressed and b.target_menu and b.target_menu is GameMenuSwitcher:
			var page_index = b.target_menu.get_selected_page()

			var mgr = get_node("../MenuManager")
			if mgr and mgr.game_screen and mgr.game_screen.has_method("is_game_unlocked"):
				if not mgr.game_screen.is_game_unlocked(page_index):
					return

			if mgr and mgr.has_method("transition_to_game_screen"):
				var music = get_node_or_null("/root/PoopPal/MusicController")
				if music:
					music.stop()
				mgr.transition_to_game_screen(page_index)
			break

func _is_game_menu_active() -> bool:
	for b in get_tree().get_nodes_in_group("menu_toggle_buttons"):
		if b.button_pressed and b.target_menu and b.target_menu is GameMenuSwitcher:
			return true
	return false

# ------------------------------------------------------------------ FOOD / DRINK EFFECTS
func _spawn_food_or_drink_effect(sel: Node) -> void:
	if not sel:
		return

	var pet_view = get_node("/root/PoopPal/Main UI/PetView")

	var vbox_food = get_node_or_null("/root/PoopPal/Main UI/Menus/FoodMenu/Menu/VBoxFood")
	if vbox_food and sel.get_parent() == vbox_food and sel.has_node("Icon"):
		var icon = sel.get_node("Icon")
		if icon.texture:
			pet_view.get_node("FoodRainSpawner").spawn_food_chunks(icon.texture)
		return

	var vbox_drink = get_node_or_null("/root/PoopPal/Main UI/Menus/FoodMenu/Menu/VBoxDrink")
	if vbox_drink and sel.get_parent() == vbox_drink:
		var drink_spawner = pet_view.get_node("DrinkWaterfallSpawner")
		if drink_spawner:
			var col := Color(1, 1, 1, 1)
			if sel.has_meta("color"):
				col = sel.get_meta("color")
				col.a = 1.0
			drink_spawner.stream_color = col
			drink_spawner.spawn_drink_stream()

# ------------------------------------------------------------------ RESET
func _reset_hold() -> void:
	filling     = false
	hold_timer  = 0.0
	was_pressed = false

	if selected_doughnut:
		selected_doughnut.visible = false
		selected_doughnut.value   = 0

		if selected_doughnut.has_node("DoughnutBorder"):
			var border = selected_doughnut.get_node("DoughnutBorder")
			border.visible = false
			border.value   = 0

	selected_doughnut = null

# ------------------------------------------------------------------ QUERY HELPERS
func _route_to_minigame(method: String) -> void:
	var gs = get_node_or_null("../MenuManager")
	if gs and gs.game_screen and gs.game_screen.current_game and gs.game_screen.current_game.has_method(method):
		gs.game_screen.current_game.call(method)

func _get_selected_doughnut() -> TextureProgressBar:
	var sel = _get_selected_option_node()
	if not sel or not sel.has_node("Doughnut"):
		return null
	# Don't show doughnut for locked games
	if _is_game_menu_active() and not _is_current_game_unlocked():
		return null
	return sel.get_node("Doughnut")

func _is_current_game_unlocked() -> bool:
	for b in get_tree().get_nodes_in_group("menu_toggle_buttons"):
		if b.button_pressed and b.target_menu and b.target_menu is GameMenuSwitcher:
			var page_index = b.target_menu.get_selected_page()
			var mgr = get_node("../MenuManager")
			if mgr and mgr.game_screen and mgr.game_screen.has_method("is_game_unlocked"):
				return mgr.game_screen.is_game_unlocked(page_index)
	return false

func _get_selected_option_node() -> Node:
	for b in get_tree().get_nodes_in_group("menu_toggle_buttons"):
		if b.button_pressed and b.target_menu and b.target_menu.has_method("get_selected_option"):
			return b.target_menu.get_selected_option()
	return null

# ------------------------------------------------------------------ UNTOGGLE / RETURN PET
func _untoggle_current_menu() -> void:
	for b in get_tree().get_nodes_in_group("menu_toggle_buttons"):
		if b.button_pressed and b.target_menu:
			var anim  = b.target_menu.get_node_or_null("AnimationPlayer")
			var pet_v = get_node("../PetView")
			var pet_a : AnimationPlayer = pet_v.get_node("AnimationPlayer") if pet_v else null
			var mgr   = get_node("../MenuManager")

			b.deactivate_with_clack()

			if anim and anim.has_animation("menu_slide_out_left_quick"):
				anim.play("menu_slide_out_left_quick")

			if pet_v and pet_a and pet_a.has_animation("slide_in_right_quick") and not mgr.pet_view_back:
				pet_v.visible = true
				pet_a.play("slide_in_right_quick")
				mgr.pet_view_back = true
			break
