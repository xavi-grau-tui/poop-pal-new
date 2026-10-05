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

## Darker when untoggled, brighter when toggled (swaps the two textures set in the scene)
const DARK_WHEN_UNTOGGLED := true

func _ready():
	if DARK_WHEN_UNTOGGLED:
		var bright := normal_texture
		normal_texture = pressed_texture
		pressed_texture = bright
		texture_pressed = pressed_texture   # shown by the button itself while toggled
	texture_normal = normal_texture
	toggle_mode = true
	add_to_group("menu_toggle_buttons")
	set_process(true)
	# The gear (collection) button blinks when something new is unlocked
	if target_menu and target_menu.has_method("confirm_selected"):
		Collection.unlocked.connect(func(_c, _id): blink_hint(6, 0.18))
		PetState.pal_discovered.connect(func(_id): blink_hint(6, 0.18))
	# The Games button keeps blinking while a LUCKY PINCH bonus waits to be played
	# (it starts once the claw has left the pet cam)
	if target_menu is GameMenuSwitcher:
		LuckyPinch.visit_finished.connect(_on_bonus_visit_finished)
		LuckyPinch.changed.connect(_on_bonus_changed)

func _process(_delta):
	self.disabled = FoodRainSpawner.is_locked or DrinkWaterfallSpawner.is_locked

func _gui_input(event):
	if FoodRainSpawner.is_locked or DrinkWaterfallSpawner.is_locked:
		get_viewport().set_input_as_handled()
		return

	# a menu is still sliding back to the pet: a tap now would race with it
	if menu_manager and menu_manager.get("returning"):
		accept_event()
		return

	# LUCKY PINCH: while the claw visits nothing opens; then only Games (it must be played
	# first: food and settings can't be opened or toggled at all)
	if LuckyPinch.visiting or (LuckyPinch.pending and not (target_menu is GameMenuSwitcher)):
		if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			_refuse_for_bonus()
		accept_event()
		return

	# No poop yet: games stay closed until the first meal (a pending bonus can still be played)
	if PetState.needs_first_meal() and not LuckyPinch.pending and not button_pressed and target_menu is GameMenuSwitcher:
		if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
			# it still clicks like a real button, it just doesn't toggle
			var sfx := click_sound if event.pressed else release_sound
			if sfx:
				sfx.stop()
				sfx.play()
			if event.pressed:
				_refuse_until_first_meal()
		accept_event()
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

func _is_food_button(b: Node) -> bool:
	return b.target_menu != null and b.target_menu.has_method("populate_foods")

func _refuse_until_first_meal() -> void:
	# Silent refusal: a short buzz and the food button blinks
	Input.vibrate_handheld(40)
	# Point the player to the food button: it blinks bright/dark 3 times, like an LED
	for b in get_tree().get_nodes_in_group("menu_toggle_buttons"):
		if _is_food_button(b):
			b.blink_hint()
			break

func _on_bonus_visit_finished() -> void:
	if LuckyPinch.pending:
		start_attention()

func _on_bonus_changed(on: bool) -> void:
	if on:
		start_attention()                # blinks with the claw's arrival
	else:
		stop_attention()

## Refused because a LUCKY PINCH bonus is waiting: a soft error blip (the Games button is
## already blinking)
func _refuse_for_bonus() -> void:
	Input.vibrate_handheld(40)
	var sfx := AudioStreamPlayer.new()
	sfx.stream = load("res://sounds/fx/error.mp3")
	sfx.volume_db = -22.0
	sfx.pitch_scale = 1.25
	add_child(sfx)
	sfx.play()
	sfx.finished.connect(sfx.queue_free)

var _attention: Tween

## Blinks until stopped (LUCKY PINCH waiting), also while its menu is open
func start_attention() -> void:
	if _attention:
		_attention.kill()
	_attention = create_tween().set_loops()
	_attention.tween_callback(func(): _show(pressed_texture))
	_attention.tween_interval(0.28)
	# (inside the game it waits for, it just stays lit: no blinking while you play it)
	_attention.tween_callback(func(): _show(pressed_texture if GameScreen.is_active else normal_texture))
	_attention.tween_interval(0.28)

func stop_attention() -> void:
	if _attention:
		_attention.kill()
		_attention = null
	texture_pressed = pressed_texture
	texture_normal = pressed_texture if button_pressed else normal_texture

var _blink_tween: Tween

func blink_hint(times := 3, step := 0.12) -> void:
	if _blink_tween and _blink_tween.is_running():
		return
	_blink_tween = create_tween()
	# Swap both textures, so it also blinks while the button is toggled (food menu open)
	for i in times:
		_blink_tween.tween_callback(func(): _show(pressed_texture))   # bright
		_blink_tween.tween_interval(step)
		_blink_tween.tween_callback(func(): _show(normal_texture))    # dark
		_blink_tween.tween_interval(step)
	# settle on whatever the real toggle state is
	_blink_tween.tween_callback(func():
		texture_pressed = pressed_texture
		texture_normal = pressed_texture if button_pressed else normal_texture)

func is_blinking() -> bool:
	return _blink_tween != null and _blink_tween.is_running()

func _show(tex: Texture2D) -> void:
	texture_normal = tex
	texture_pressed = tex

func deactivate_with_clack():
	button_pressed = false
	texture_normal = normal_texture
	if clack_sound:
		clack_sound.stop()
		clack_sound.play()
