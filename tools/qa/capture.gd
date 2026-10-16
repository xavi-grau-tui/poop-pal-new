extends Node
## QA (development only): starts the game like STRAIGHT TO GAMES (the testing save), then opens a
## game, plays the levels asked for and saves a screenshot of each, to check art and levels on
## the computer. Run windowed (headless renders nothing):
##
##   Godot --path . --audio-driver Dummy res://tools/qa/capture.tscn -- game=1 levels=1,10,19 wait=2.5 out=/tmp/shots
##
##   game=N        a Games menu index (GameScreen.game_scenes); game=pet: the pet screen only
##   levels=a,b    levels to play (default 1); each one starts fresh
##   wait=S        seconds of play before each screenshot (default 2)
##   shots=K       screenshots per level, `wait` seconds apart (default 1)
##   out=DIR       where the PNGs go (default user://qa)
## Prints "QA DONE" and quits when finished. The testing save is wiped at every launch anyway.

var args := {}
var out_dir := "user://qa"

func _ready() -> void:
	for a in OS.get_cmdline_user_args():
		var kv := a.split("=", true, 1)
		if kv.size() == 2:
			args[kv[0]] = kv[1]
	out_dir = args.get("out", out_dir)
	# a safety net: never hang (a script error can stop the run half way)
	get_tree().create_timer(float(args.get("timeout", "90"))).timeout.connect(func():
		print("QA TIMEOUT")
		get_tree().quit(1))
	DirAccess.make_dir_recursive_absolute(out_dir)
	# the STRAIGHT TO GAMES start, without the dev launcher's buttons
	DevLaunch.skip_boot = true
	DevLaunch.all_open = true
	for idx in GameData.games:
		GameData.games[idx]["unlocked"] = true
		GameData.games[idx]["intro"] = true             # (no how-to cards in the way)
	for size in ["baby", "kid", "adult"]:
		Shop.foods[size] = FoodLibrary.FAMILIES.duplicate()
	if not PetState.has_poop():
		PetState.form_id = "picklet"
		PetState.meals = ["sour"]
		if "picklet" not in PetState.discovered:
			PetState.discovered.append("picklet")
	get_parent().remove_child.call_deferred(self)
	get_tree().root.add_child.call_deferred(self)
	_run.call_deferred()

func _run() -> void:
	await get_tree().process_frame
	get_tree().change_scene_to_file(DevLaunch.MAIN_SCENE)
	await _wait(2.5)
	var game: String = args.get("game", "pet")
	if args.has("menu"):
		await _open_menu(str(args["menu"]))
		_quit()
		return
	if game == "pet":
		await _shot("pet")
		_quit()
		return
	var mgr = get_tree().root.get_node_or_null("PoopPal/Main UI/MenuManager")
	var gs = get_tree().root.get_node_or_null("PoopPal/Main UI/GameScreen")
	if not mgr or not gs:
		push_error("QA: no MenuManager / GameScreen")
		_quit()
		return
	mgr.transition_to_game_screen(int(game))
	await _wait(1.2)
	var levels: Array = []
	for s in str(args.get("levels", "1")).split(","):
		if s.strip_edges() != "":
			levels.append(int(s))
	var wait := float(args.get("wait", "2"))
	var shots := int(args.get("shots", "1"))
	for lvl in levels:
		var g = gs.current_game
		if not g:
			break
		if g.has_method("uses_levels") and g.uses_levels():
			if g.level_menu:
				g.level_menu.close()
			g.play_level(lvl)
			g.is_running = true
		for k in shots:
			await _wait(wait)
			await _shot("g%s_l%02d%s" % [game, lvl, "" if shots == 1 else "_%d" % k])
	_quit()

## menu=food / drinks / special / games / gear / shop[:page] / dress / decor / backgrounds / pedia:
## opens it like a tap on its button, then a screenshot (shop:2 = its 3rd page)
func _open_menu(which: String) -> void:
	var mgr = get_tree().root.get_node_or_null("PoopPal/Main UI/MenuManager")
	var name := which.get_slice(":", 0)
	var page := int(which.get_slice(":", 1)) if ":" in which else 0
	var want := "food" if name in ["food", "drinks", "special"] else ("games" if name == "games" else "gear")
	for b in get_tree().get_nodes_in_group("menu_toggle_buttons"):
		var t = b.target_menu
		if not t:
			continue
		var kind := "food" if t.has_method("populate_foods") else ("games" if t is GameMenuSwitcher else ("gear" if t.has_method("open_shop") else ""))
		if kind != want:
			continue
		mgr.request_menu_first_half(t)
		await _wait(0.2)
		b.button_pressed = true
		mgr.request_menu_second_half(t)
		await _wait(1.0)
		match name:
			"drinks":
				t.show_page(1)
			"special":
				t.show_page(2)
			"shop", "dress", "decor", "backgrounds", "pedia":
				var v: int = { "shop": t.View.SHOP, "dress": t.View.ACCESSORIES, "decor": t.View.DECOR, "backgrounds": t.View.BACKGROUNDS, "pedia": t.View.PEDIA }[name]
				if name == "shop":
					t.shop_items = Shop.shop_order()
				t.page = page
				t._open(v)
			"games":
				for i in page:
					t.show_page((t.current_page + 1) % t.pages.size())
		await _wait(0.8)
		await _shot("menu_" + which.replace(":", "_"))
		return
	print("QA: no such menu ", which)

func _wait(s: float) -> void:
	await get_tree().create_timer(s).timeout

func _shot(name: String) -> void:
	if DisplayServer.get_name() == "headless":
		print("QA (headless: no picture) ", name)
		return
	await RenderingServer.frame_post_draw
	var img := get_viewport().get_texture().get_image()
	var path := out_dir.path_join(name + ".png")
	img.save_png(path)
	print("QA shot ", path)

func _quit() -> void:
	print("QA DONE")
	get_tree().quit()
