extends Node2D
## QA: Tomo Tunes' look in the real game. Starts song 1 through the level menu, hits every note for 8 s, then stops
## pressing (so the miss and the dimmed room show), and saves four screens (950 x 948) as look_<name>.png.
##
##   Godot --path . --windowed --always-on-top --resolution 1000x1000 --audio-driver Dummy res://tools/qa/preview.tscn -- script=res://tools/qa/tunes_look.gd dir=/abs/folder wait=40
func _dir() -> String:
	for a in OS.get_cmdline_user_args():
		if a.begins_with("dir="):
			return a.substr(4)
	return OS.get_user_data_dir()
var g
var shots := [[4.0, "a_play"], [6.03, "b_play"], [9.4, "c_missing"], [10.2, "d_dim"]]
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
	var t: float = g._song_time()
	if t < 8.2:
		for n in g.live.duplicate():
			if t >= n["t"] - 0.01:
				g._press(n["lane"])
	if not shots.is_empty() and t >= shots[0][0]:
		var name: String = shots[0][1]
		shots.pop_front()
		await RenderingServer.frame_post_draw
		get_viewport().get_texture().get_image().get_region(Rect2i(0, 0, 950, 948)).save_png("%s/look_%s.png" % [_dir(), name])
		print("QA shot ", name, " t=", snappedf(t, 0.01), " lead_on=", g.lead_on, " groove=", snappedf(g.groove, 0.01))
		if shots.is_empty():
			get_tree().quit()
