extends TextureButton

@export var click_sound      : AudioStreamPlayer2D
@export var release_sound    : AudioStreamPlayer2D
@export var hold_duration    := 1.0
@export var fill_start_delay := 0.25
@export var flush_hold_duration := 2.0  # hold on the pet view (no menu open) to flush
@export var flush_sound_db := -8.5      # flush whoosh volume
@export var flush_fade_time := 1.4      # whoosh fades out (runs a bit past the 0.9 s spin)...
@export var cling_delay := 0.12         # ...then a short silence before the cling

var was_pressed        := false
var hold_timer         := 0.0
var filling            := false
var selected_doughnut  : TextureProgressBar = null
var _flushing          := false
var _confirming        := false   # a choice was just confirmed: ignore taps until the menu has closed
var _press_id          := 0       # each press gets its own id, so a quick tap's timer can't hijack the next press

func _ready() -> void:
	ConsoleLayout.apply.call_deferred(get_parent())      # (the bottom buttons' layout on trial)
	ButtonTouchLook.attach_all.call_deferred(get_parent())   # (pressed look under every finger)
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

			if _confirming:
				return
			was_pressed       = true
			_press_id        += 1
			var my_press      := _press_id
			hold_timer        = 0.0
			filling           = false
			selected_doughnut = _get_selected_doughnut()

			if click_sound:
				click_sound.stop()
				click_sound.play()
			Input.vibrate_handheld(15)

			await get_tree().create_timer(0.3).timeout
			if was_pressed and my_press == _press_id:
				# Don't start filling for locked games
				# (a locked game never fills; letting go still moves to the next card)
				if _is_game_menu_active() and not _is_current_game_unlocked():
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

				# in a menu, letting go before the selection ring shows is still a tap (next
				# option); once the ring is filling, letting go early keeps the same option.
				# On the pet screen a half-done flush hold just cancels.
				if not filling or (_any_menu_toggled() and hold_timer < fill_start_delay):
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
			return
	# Pet screen, no menu open: a tap pokes the pal (a long press flushes it)
	if not _flushing:
		var poop = get_node_or_null("../PetView/Poop")
		if poop and poop.has_method("poke"):
			poop.poke()

# ------------------------------------------------------------------ PROCESS / HOLD-TO-CONFIRM
func _process(delta: float) -> void:
	if not filling:
		return

	hold_timer += delta

	# Pet view, no menu open: hold to flush the poop
	if not _any_menu_toggled():
		if not PetState.has_poop() or _flushing or FoodRainSpawner.is_locked or DrinkWaterfallSpawner.is_locked or LuckyPinch.pending:
			return                       # (no flushing while a LUCKY PINCH bonus waits)
		var poop = get_node_or_null("../PetView/Poop")
		var charge = clamp((hold_timer - fill_start_delay) / (flush_hold_duration - fill_start_delay), 0.0, 1.0)
		if poop and poop.has_method("set_flush_charge"):
			poop.set_flush_charge(charge)
		if hold_timer >= flush_hold_duration:
			filling = false
			_reset_hold()
			_flush_poop()
		return

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

		# this press is used up: letting go now must not also count as a tap (= next option)
		was_pressed = false
		_confirming = true
		var sel = _get_selected_option_node()
		# LUCKY PINCH waiting: nothing else can be chosen (a menu was already open)
		if LuckyPinch.pending and _any_menu_toggled() and not _is_game_menu_active():
			_play_sfx("res://sounds/fx/error.mp3", -22.0, 1.25)
			_reset_hold()
			_confirming = false
			return
		# A menu can refuse before anything plays (e.g. DRESS UP with no pal yet):
		# a very soft error blip instead of the OK sound
		var menu = _get_active_menu()
		if sel and menu and menu.has_method("can_confirm") and not menu.can_confirm(sel):
			_play_sfx("res://sounds/fx/error.mp3", -22.0, 1.25)
			_reset_hold()
			_confirming = false
			return
		if sel and sel.has_node("ConfirmSound"):
			var csp : AudioStreamPlayer2D = sel.get_node("ConfirmSound")
			if csp.stream:
				csp.play()
				# (a timer, not csp.finished: if the sound were cut off the button would stay locked)
				await get_tree().create_timer(csp.stream.get_length()).timeout

		_handle_hold_confirm(sel)
		_reset_hold()
		_confirming = false

# ------------------------------------------------------------------ HOLD CONFIRM DISPATCH
func _handle_hold_confirm(sel: Node) -> void:
	if not sel:
		return

	if _is_game_menu_active():
		if not _is_current_game_unlocked():
			return
		_launch_game()
		return

	var menu = _get_active_menu()
	if menu and menu.has_method("confirm_selected"):
		if menu.confirm_selected(sel):
			_untoggle_current_menu()  # back to the pet, like after eating
		return

	# No poop yet: the first thing it gets must be food
	if PetState.needs_first_meal() and not _is_food_option(sel):
		_play_sfx("res://sounds/fx/error.mp3", -10.0)
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
				# (the Lucky Pinch bonus has no music of its own: the pet screen's song goes on)
				var music = get_node_or_null("/root/PoopPal/MusicController")
				if music and page_index != LuckyPinch.GAME_INDEX:
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

	if _is_food_option(sel) and sel.has_node("Icon"):
		var icon = sel.get_node("Icon")
		if icon.texture:
			_feed_after_fall(pet_view.get_node("FoodRainSpawner"), icon.texture, sel.get_meta("food", {}))
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
			_drink_after_pour(drink_spawner, sel.get_meta("drink", {}))

# ------------------------------------------------------------------ PET CYCLE
func _feed_after_fall(spawner: Node, texture: Texture2D, food: Dictionary) -> void:
	# Let the food fall and digest first, then hatch / evolve the poop
	await spawner.spawn_food_chunks(texture)
	if not food.is_empty():
		PetState.feed(food)
	var food_menu = get_node_or_null("../Menus/FoodMenu")
	if food_menu and food_menu.has_method("populate_foods"):
		food_menu.populate_foods()  # fresh menu for the next meal
		food_menu.populate_special()

func _drink_after_pour(spawner: Node, drink: Dictionary) -> void:
	await spawner.spawn_drink_stream()
	PetState.drink(drink)
	var food_menu = get_node_or_null("../Menus/FoodMenu")
	if food_menu and food_menu.has_method("populate_drinks"):
		food_menu.populate_drinks()  # fresh drinks for next time

func _flush_poop() -> void:
	_flushing = true
	var poop = get_node_or_null("../PetView/Poop")
	# the pal says bye first, then the whoosh and the spin
	if poop and poop.has_method("say_bye"):
		poop.set_flush_charge(0.0)
		poop.say_bye()
		await get_tree().create_timer(0.55).timeout
	var flush_sfx := _play_sfx("res://sounds/fx/sfx_sounds_falling8.mp3", flush_sound_db)
	Input.vibrate_handheld(80)
	var whoosh_end := Time.get_ticks_msec() + int(flush_fade_time * 1000.0)
	# the flush sound is longer than the spin: fade it out so it's gone before the cling
	if flush_sfx and flush_sfx.volume_db > -50.0:   # (muted = -inf, leave it)
		var fade := create_tween()
		fade.tween_property(flush_sfx, "volume_db", -50.0, flush_fade_time).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_QUAD)
		fade.tween_callback(flush_sfx.queue_free)
	if poop and poop.has_method("play_flush"):
		await poop.play_flush()
	# wait for the whoosh to die out, then the cling
	var remaining := maxf(0.0, (whoosh_end - Time.get_ticks_msec()) / 1000.0)
	await get_tree().create_timer(remaining + cling_delay).timeout
	# ...and out it comes: a little sparkle + cling at the end of the gut
	var gut = get_node_or_null("../PetView/Intestine-front")
	if gut and gut.has_method("play_flush_sparkle"):
		_play_sfx("res://sounds/fx/flush_cling.wav", -12.0)
		gut.play_flush_sparkle()
	PetState.flush()
	_flushing = false

func _is_food_option(sel: Node) -> bool:
	# the food page or the special-food page
	return sel != null and sel.get_parent() != null and sel.get_parent().name in ["VBoxFood", "VBoxSpecial"]

func _get_active_menu() -> Node:
	for b in get_tree().get_nodes_in_group("menu_toggle_buttons"):
		if b.button_pressed and b.target_menu:
			return b.target_menu
	return null

func _any_menu_toggled() -> bool:
	for b in get_tree().get_nodes_in_group("menu_toggle_buttons"):
		if b.button_pressed:
			return true
	return false

func _play_sfx(path: String, volume_db: float, pitch := 1.0) -> AudioStreamPlayer:
	var stream = load(path) as AudioStream
	if not stream:
		return null
	var sfx = AudioStreamPlayer.new()
	sfx.stream = stream
	sfx.volume_db = volume_db
	sfx.pitch_scale = pitch
	add_child(sfx)
	sfx.play()
	sfx.finished.connect(sfx.queue_free)
	return sfx

# ------------------------------------------------------------------ RESET
func _reset_hold() -> void:
	filling     = false
	hold_timer  = 0.0
	was_pressed = false

	var poop = get_node_or_null("../PetView/Poop")
	if poop and poop.has_method("set_flush_charge"):
		poop.set_flush_charge(0.0)

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
