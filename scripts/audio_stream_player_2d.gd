extends AudioStreamPlayer2D

@export var sound_button: TextureButton

# Main pet screen music: soft lo-fi kawaii / bubbly ambient loops (~2 min each), played in a
# random order (never the same one twice in a row). Loaded when they play, not all at once.
const SONGS := [
	"res://sounds/music/Bouncy Toy Groove.mp3",
	"res://sounds/music/Bubbly Menu.mp3",
	"res://sounds/music/Floating Bell.mp3",
	"res://sounds/music/Game Menu Music.mp3",
	"res://sounds/music/Soft Water Plucks.mp3",
	"res://sounds/music/Sunny Groove.mp3",
	"res://sounds/music/Sweet Dreams, Pet.mp3",
	"res://sounds/music/Underwater Pads.mp3",
	"res://sounds/music/Underwater Plucks.mp3",
	"res://sounds/music/Untitled.mp3",
]
## These are ~2 dB louder than the old 8-bit pieces: played a touch lower so the level feels
## the same (the sound button mutes / unmutes around this)
const BASE_DB := -2.0

# This list will be dynamically filled with unlocked songs
var unlocked_songs: Array = SONGS.duplicate()

var current_stream: String = ""

func _ready():
	# TEMP: All songs unlocked for now (can change this later)
	unlocked_songs = SONGS.duplicate()
	pitch_scale = 1.0          # (the old 8-bit pieces were slowed to 0.85; these play as made)
	volume_db = BASE_DB

	# Play a random song on start
	play_random_song()

	# Connect end-of-song logic
	finished.connect(_on_song_finished)

func play_random_song():
	if unlocked_songs.size() <= 1:
		current_stream = unlocked_songs[0]
	else:
		var next_song = unlocked_songs[randi() % unlocked_songs.size()]
		while next_song == current_stream:
			next_song = unlocked_songs[randi() % unlocked_songs.size()]
		current_stream = next_song

	stream = load(current_stream)
	play()

func _on_song_finished():
	play_random_song()

# Called externally by the forward button
func skip_to_next_random_song():
	if sound_button and sound_button.button_pressed:
		sound_button.call("force_enable_sound")

	play_random_song()
