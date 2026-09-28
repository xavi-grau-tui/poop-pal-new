extends TextureButton

const FoodRainSpawner = preload("res://scripts/food_rain_spawner.gd")
const DrinkWaterfallSpawner = preload("res://scripts/drink_waterfall_spawner.gd")

@export var normal_texture: Texture2D
@export var pressed_texture: Texture2D
@export var click_sound: AudioStreamPlayer2D
@export var release_sound: AudioStreamPlayer2D
@export var clack_sound: AudioStreamPlayer2D

@export var menu_manager: Node
@export var target_menu: Node

var pending_deactivation_button: TextureButton = null

func _ready():
	texture_normal = normal_texture
	toggle_mode = true
	add_to_group("menu_toggle_buttons")
	set_process(true)

func _process(_delta):
	self.disabled = FoodRainSpawner.is_locked or DrinkWaterfallSpawner.is_locked

func _gui_input(event):
	if FoodRainSpawner.is_locked or DrinkWaterfallSpawner.is_locked:
		get_viewport().set_input_as_handled()
		return

	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			if click_sound:
				click_sound.stop()
				click_sound.play()
			Input.vibrate_handheld(50)

			if menu_manager and target_menu:
				if button_pressed:
					var others_toggled := false
					for b in get_tree().get_nodes_in_group("menu_toggle_buttons"):
						if b != self and b.button_pressed:
							others_toggled = true
							break

					if not others_toggled:
						menu_manager.prepare_pet_return()
				else:
					menu_manager.request_menu_first_half(target_menu)
		else:
			if release_sound:
				release_sound.stop()
				release_sound.play()
			Input.vibrate_handheld(50)

			if menu_manager and target_menu:
				menu_manager.request_menu_second_half(target_menu)

			if pending_deactivation_button:
				pending_deactivation_button.deactivate_with_clack()
				pending_deactivation_button = null

func _toggled(button_pressed):
	texture_normal = pressed_texture if button_pressed else normal_texture

	if button_pressed:
		for b in get_tree().get_nodes_in_group("menu_toggle_buttons"):
			if b != self and b.button_pressed:
				pending_deactivation_button = b
			if target_menu and target_menu.has_method("reset_active_options"):
				target_menu.reset_active_options()
	else:
		if target_menu and target_menu.has_method("reset_selection"):
			target_menu.reset_selection()

		# Stop game and resume music only if game screen was actually active
		if target_menu and target_menu is GameMenuSwitcher:
			if GameScreen.is_active:
				if menu_manager and menu_manager.has_method("exit_game_screen"):
					menu_manager.exit_game_screen()

		var any_other_toggled := false
		for b in get_tree().get_nodes_in_group("menu_toggle_buttons"):
			if b != self and b.button_pressed:
				any_other_toggled = true
				break

		if not any_other_toggled and menu_manager:
			menu_manager.return_to_pet()

	if pending_deactivation_button:
		pending_deactivation_button.deactivate_with_clack()
		pending_deactivation_button = null

func deactivate_with_clack():
	button_pressed = false
	texture_normal = normal_texture
	if clack_sound:
		clack_sound.stop()
		clack_sound.play()
