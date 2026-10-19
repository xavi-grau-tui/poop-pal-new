extends Node
## QA (development only): runs an art preview script from anywhere (a scratch file), with the
## game's autoloads (a --script run can't see them), then saves the screen and quits. Run windowed:
##
##   Godot --path . --windowed --resolution 1100x900 --audio-driver Dummy res://tools/qa/preview.tscn -- script=/path/to/preview.gd out=/path/to/shot.png
##
## The preview script extends Node2D and builds what it wants to show in _ready (it can await).

func _ready() -> void:
	var args := {}
	for a in OS.get_cmdline_user_args():
		var kv := a.split("=", true, 1)
		if kv.size() == 2:
			args[kv[0]] = kv[1]
	var s = load(str(args.get("script", "")))
	if s == null:
		print("QA preview: no script")
		get_tree().quit(1)
		return
	var n: Node = s.new()
	add_child(n)
	await get_tree().create_timer(float(args.get("wait", "0.5"))).timeout
	await RenderingServer.frame_post_draw
	var out := str(args.get("out", "user://preview.png"))
	get_viewport().get_texture().get_image().save_png(out)
	print("QA preview saved ", out)
	get_tree().quit()
