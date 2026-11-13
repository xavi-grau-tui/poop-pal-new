extends Node2D
var g
var t0 := 0.0
func _ready() -> void:
	DevLaunch.all_open = true
	g = load("res://scenes/minigames/tummy_tunes.tscn").instantiate()
	add_child(g)
	await get_tree().create_timer(0.4).timeout
	g.on_main_button_pressed()
	await get_tree().create_timer(1.6).timeout
	g.on_main_button_released()
func _process(_d: float) -> void:
	if not g or not g.song_started:
		return
	if t0 == 0.0 and g.song.playing:
		g.song.seek(g.song_length - 4.0)
		g.next_spawn = g.notes.size()
		t0 = 1.0
		print("QA seek to ", g.song_length - 4.0)
	if t0 == 1.0 and g.finished:
		t0 = 2.0
		print("QA finished, playing=", g.song.playing, " played=", snappedf(g.played, 0.01))
		await get_tree().create_timer(2.0).timeout
		print("QA 2 s later: running=", g.is_running, " result/menu open=", g.level_menu_open())
		get_tree().quit()
