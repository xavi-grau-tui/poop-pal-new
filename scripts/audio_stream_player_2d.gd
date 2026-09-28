extends AudioStreamPlayer2D

@export var sound_button: TextureButton

# List of all possible songs (full playlist)
var all_songs = [
	preload("res://sounds/music/Frédéric Chopin - Nocturne： Op. 9 No. 2 [8 bits].mp3"),
	preload("res://sounds/music/Johann Sebastian Bach - Prelude 1_ BWV 846 [Well Tempered Clavier] [8 bits].mp3"),
	preload("res://sounds/music/Franz Liszt - La Campanella [8 bits].mp3"),
	preload("res://sounds/music/M.T. - Hoffnungslos [8 bits].mp3"),
]

# This list will be dynamically filled with unlocked songs
var unlocked_songs := all_songs.duplicate()

var current_stream: AudioStream = null

func _ready():
	# TEMP: All songs unlocked for now (can change this later)
	unlocked_songs = all_songs.duplicate()

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

	stream = current_stream
	play()

func _on_song_finished():
	play_random_song()

# Called externally by the forward button
func skip_to_next_random_song():
	if sound_button and sound_button.button_pressed:
		sound_button.call("force_enable_sound")

	play_random_song()
