extends TextureButton

@export var sound_on_texture: Texture2D
@export var sound_off_texture: Texture2D
@export var click_sound: AudioStreamPlayer2D
@export var release_sound: AudioStreamPlayer2D
@export var clack_sound: AudioStreamPlayer2D

@export var music_node: AudioStreamPlayer2D
@export var pal_sounds: Array[AudioStreamPlayer2D] = []

var was_pressed_inside := false

func _ready():
	update_visual()
	update_audio()

func _toggled(button_pressed: bool):
	update_visual()
	update_audio()
	Input.vibrate_handheld(25)
	
	# 🔊 Play release sound ONLY if toggled
	if release_sound:
		release_sound.stop()
		release_sound.play()

func update_visual():
	texture_normal = sound_off_texture if button_pressed else sound_on_texture

func update_audio():
	var volume := 0.0 if button_pressed else 1.0
	if music_node:
		music_node.volume_db = linear_to_db(volume)

	for sfx in pal_sounds:
		if is_instance_valid(sfx):
			sfx.volume_db = linear_to_db(volume)

	# Also mute/unmute active game music
	if GameScreen.is_active:
		var game_screen = get_node_or_null("/root/PoopPal/Main UI/GameScreen")
		if game_screen and game_screen.has_method("set_game_music_volume"):
			game_screen.set_game_music_volume(volume)

func _gui_input(event):
	# In a game that uses this button as a control (Tummy Tunes: the left lane), it plays
	# instead of muting
	if GameScreen.is_active and event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		var gs = get_node_or_null("/root/PoopPal/Main UI/GameScreen")
		if gs and gs.current_game and gs.current_game.has_method("on_sound_button_pressed"):
			if event.pressed:
				gs.current_game.on_sound_button_pressed()
				Input.vibrate_handheld(15)
			accept_event()
			return
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		was_pressed_inside = get_global_rect().has_point(event.position)
		if click_sound:
			click_sound.stop()
			click_sound.play()
		Input.vibrate_handheld(25)

# 🔁 Used by forward button to untoggle sound
func force_enable_sound():
	if button_pressed:
		button_pressed = false
		update_visual()
		update_audio()
		force_clack()

func force_clack():
	if clack_sound:
		clack_sound.stop()
		clack_sound.play()
