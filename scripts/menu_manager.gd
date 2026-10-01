extends Node2D

@export var menus_root: Node
@export var pet_view: Node
@export var pet_view_animation_player: AnimationPlayer
@export var food_rain_spawner: Node
@export var game_screen: Node

var current_menu: Node = null
var pending_menu: Node = null
var pet_view_back := true

func _ready():
	for menu in menus_root.get_children():
		menu.visible = false

	pet_view.visible = true
	pet_view.position = Vector2.ZERO
	current_menu = pet_view

	if game_screen:
		game_screen.visible = false
	# 3D wallpaper effect: the sky and clouds slide behind the gut when the phone tilts
	var tilt := preload("res://scripts/tilt_parallax.gd").new()
	tilt.name = "TiltParallax"
	get_parent().add_child.call_deferred(tilt)

func get_animation_player(node: Node) -> AnimationPlayer:
	var anim = node.get_node_or_null("AnimationPlayer")
	if anim:
		return anim
	for child in node.get_children():
		if child.has_node("AnimationPlayer"):
			return child.get_node("AnimationPlayer")
	return null

# --- Two-phase diapositive transitions ---

func request_menu_first_half(target: Node):
	if target == current_menu:
		return

	if current_menu and current_menu != pet_view and current_menu.has_method("reset_selection"):
		current_menu.reset_selection()

	pending_menu = target

	# Slide current out (first half)
	if current_menu == pet_view:
		pet_view_back = false
		pet_view_animation_player.play("slide_out_left_1")
	elif current_menu:
		var anim = get_animation_player(current_menu)
		if anim:
			anim.play("menu_slide_out_left_1")
		# Freeze the minigame immediately when starting to leave
		if current_menu == game_screen and game_screen.current_game and game_screen.current_game.has_method("freeze"):
			game_screen.current_game.freeze()

	# Slide target in (first half)
	if target == pet_view:
		if not pet_view_back:
			pet_view.visible = true
			pet_view_animation_player.play("slide_in_right_1")
	else:
		target.visible = true
		var anim = get_animation_player(target)
		if anim:
			anim.play("menu_slide_in_right_1")

func request_menu_second_half(target: Node):
	if not pending_menu:
		return

	var was_game_screen := (current_menu == game_screen)

	if current_menu == pet_view:
		pet_view_animation_player.play("slide_out_left_2")
	elif current_menu:
		var anim = get_animation_player(current_menu)
		if anim:
			anim.play("menu_slide_out_left_2")

	if pending_menu == pet_view:
		pet_view_back = true
		pet_view_animation_player.play("slide_in_right_2")
	else:
		var anim = get_animation_player(pending_menu)
		if anim:
			anim.play("menu_slide_in_right_2")

	current_menu = pending_menu
	pending_menu = null

	# Clean up game screen after the full diapositive completes
	if was_game_screen:
		_stop_game_and_resume_music()

func return_to_pet():
	if current_menu != pet_view:
		if current_menu:
			var anim = get_animation_player(current_menu)
			if anim:
				anim.play("menu_slide_out_left_1")
				await anim.animation_finished
			if current_menu == game_screen:
				_stop_game_and_resume_music()
			else:
				current_menu.visible = false

		if not pet_view_back:
			pet_view.visible = true
			pet_view_animation_player.play("slide_in_right_2")
			pet_view_back = true

		current_menu = pet_view

func prepare_pet_return():
	if current_menu != pet_view:
		pending_menu = pet_view
		pet_view.visible = true

		if not pet_view_back:
			pet_view_animation_player.play("slide_in_right_1")

		if current_menu == pet_view:
			pet_view_back = false
			pet_view_animation_player.play("slide_out_left_1")
		elif current_menu:
			var anim = get_animation_player(current_menu)
			if anim:
				anim.play("menu_slide_out_left_1")
			if current_menu == game_screen and game_screen.current_game and game_screen.current_game.has_method("freeze"):
				game_screen.current_game.freeze()

# --- Game screen transition (called after hold-confirm on a game) ---

func transition_to_game_screen(game_page_index: int) -> void:
	if not game_screen:
		return

	# Slide game menu out and game screen in simultaneously
	if current_menu and current_menu != pet_view:
		var anim = get_animation_player(current_menu)
		if anim and anim.has_animation("menu_slide_out_left_quick"):
			anim.play("menu_slide_out_left_quick")

	# Position Menu off-screen before making visible to prevent blink
	var menu_node = game_screen.get_node_or_null("Menu")
	if menu_node:
		menu_node.position = Vector2(950, 0)

	# Show and start game screen with quick slide-in
	game_screen.visible = true
	game_screen.start_game(game_page_index)

	var gs_anim = get_animation_player(game_screen)
	if gs_anim and gs_anim.has_animation("menu_slide_in_right_quick"):
		gs_anim.play("menu_slide_in_right_quick")
	else:
		# Fallback: place directly at resting position
		if menu_node:
			menu_node.position = Vector2(-475, 0)

	# Game screen is now the current menu
	current_menu = game_screen

func exit_game_screen() -> void:
	if not game_screen:
		return
	var was_active := GameScreen.is_active
	# Freeze but keep visuals
	if game_screen.current_game and game_screen.current_game.has_method("freeze"):
		game_screen.current_game.freeze()
	GameScreen.is_active = false
	if game_screen.has_method("_stop_game_music"):
		game_screen._stop_game_music()
	if was_active:
		var music = get_node_or_null("/root/PoopPal/MusicController")
		if music and music.has_method("play_random_song"):
			music.play_random_song()
	
	# Quick slide: game screen out left, pet view in from right
	var gs_anim = get_animation_player(game_screen)
	if gs_anim and gs_anim.has_animation("menu_slide_out_left_quick"):
		gs_anim.play("menu_slide_out_left_quick")
	
	pet_view.visible = true
	pet_view_back = true
	pet_view_animation_player.play("slide_in_right_quick")
	
	current_menu = pet_view
	pending_menu = null
	
	# Destroy game and hide after slide finishes
	_cleanup_game_after_slide()

func _stop_game_and_resume_music() -> void:
	var was_active := GameScreen.is_active
	# Freeze the game but don't destroy it yet — keep visuals intact during slide
	if game_screen and game_screen.current_game and game_screen.current_game.has_method("freeze"):
		game_screen.current_game.freeze()
	GameScreen.is_active = false
	# Stop game music
	if game_screen and game_screen.has_method("_stop_game_music"):
		game_screen._stop_game_music()
	# Only resume music if the game screen was actually active
	if was_active:
		var music = get_node_or_null("/root/PoopPal/MusicController")
		if music and music.has_method("play_random_song"):
			music.play_random_song()
	# Wait for slide to finish, then destroy the game and hide
	_cleanup_game_after_slide()

func _cleanup_game_after_slide() -> void:
	var anim = get_animation_player(game_screen)
	if anim and anim.is_playing():
		await anim.animation_finished
	if game_screen and game_screen.has_method("stop_game_internal"):
		game_screen.stop_game_internal()
	game_screen.visible = false
