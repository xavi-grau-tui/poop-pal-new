extends TextureButton

@export var music_controller: Node
@export var click_sound: AudioStreamPlayer2D
@export var release_sound: AudioStreamPlayer2D

var was_pressed := false

func _gui_input(event):
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			was_pressed = true
			if click_sound:
				click_sound.stop()
				click_sound.play()
			Input.vibrate_handheld(25)
		elif event.is_released() and was_pressed:
			var mouse_pos = get_local_mouse_position()
			if mouse_pos.x >= 0 and mouse_pos.y >= 0 and mouse_pos.x <= size.x and mouse_pos.y <= size.y:
				if release_sound:
					release_sound.stop()
					release_sound.play()
				Input.vibrate_handheld(25)

				if _is_menu_toggled_and_flippable():
					flip_current_menu_page()
				elif GameScreen.is_active:
					_route_to_minigame("on_forward_button_pressed")
				elif music_controller and not GameScreen.is_active:
					music_controller.skip_to_next_random_song()

			was_pressed = false


func _is_menu_toggled_and_flippable() -> bool:
	if GameScreen.is_active:
		return false
	for button in get_tree().get_nodes_in_group("menu_toggle_buttons"):
		if button.button_pressed and button.target_menu and button.target_menu.has_method("flip_page"):
			return true
	return false


func flip_current_menu_page():
	for button in get_tree().get_nodes_in_group("menu_toggle_buttons"):
		if button.button_pressed and button.target_menu and button.target_menu.has_method("flip_page"):
			button.target_menu.flip_page()
			break

func _route_to_minigame(method: String) -> void:
	var gs_nodes = get_tree().get_nodes_in_group("menu_toggle_buttons")
	var mgr = get_node_or_null("/root/PoopPal/Main UI/MenuManager")
	if mgr and mgr.game_screen and mgr.game_screen.current_game and mgr.game_screen.current_game.has_method(method):
		mgr.game_screen.current_game.call(method)
