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
##   boost=B:L     the pal has boost B (splash, fizz, focus, sturdy, lucky) at level L before each level
##   skill=N       the autopilot's skill, where a game has one (Paper Sumo: 1 or 2)
##   shrine=1      the existing shrine art; new_shrine=1 the new forest frame; hour=H its sky's time
##   unlock=all    start like ALL UNLOCKED (every item owned, a random pal)
##   case=ID       the device wears that case (with unlock=all)
##   menutest=N    drive the game's level menu: FORWARD N times, tap, hold; print what plays
##   bonus=1       a Lucky Pinch bonus right away, a screenshot `wait` s later
##   until=done    on to the next level as soon as this one is over (at most `wait` s)
##   hands=off     (Pal Prix) the toy isn't steered at all: can it finish by itself?
##   intro=1       the game's how-to card over each level
##   diapos=F,f;G,g;S,s  the menus' slides (diapositive1-3) recoloured for a look test: each menu's
##                 frame and inner panel colours (#hex), food;games;settings
##   extra=PATH    (game=pet) a scratch GDScript (extends Node, func run(cap)) run on the pet screen:
##                 it can change what it likes and take pictures with cap._shot(name)
##   depth=x,y     a pretend phone tilt for the 3D layers (the games', the pet screen's), -1..1 each
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
	if args.has("unlock"):
		DevLaunch.unlock_everything()
	DevLaunch.new_shrine = args.has("new_shrine")
	DevLaunch.rc_new_art = args.has("rc_new_art")             # (RC Prix's Garden from the designer's pieces)
	DevLaunch.rc_grade = int(args.get("rc_grade", "0"))      # (its colour grade, 0 as drawn)
	DevLaunch.rc_fx = args.get("rc_fx", "0") == "1"         # (its air: clouds' shadows, sun, beams, mist)
	DevLaunch.shrine = args.has("shrine") or DevLaunch.new_shrine
	if args.has("hour"):
		Shrine.qa_hour = float(args["hour"])            # (hour=H: the shrine's sky at a pretend time)                       # (ALL UNLOCKED: every item, a random pal)
	if args.has("rain"):
		Shrine.rain_now = int(args["rain"])             # (rain=1 light, 2 heavy: the shrine's rain)
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
	if args.has("bonus"):
		LuckyPinch.start()                                   # (a Lucky Pinch bonus now: bonus=1)
		await _wait(float(args.get("wait", "9")))
		await _shot("bonus")
		_quit()
		return
	if args.has("case"):
		Collection.equip("cases", str(args["case"]))       # (the device wears it: case=<id>, with unlock=all)
		await _wait(0.5)
	if args.has("diapos"):
		_recolour_diapos(str(args["diapos"]))
	var game: String = args.get("game", "pet")
	if args.has("menu"):
		if args.has("depth"):                              # (a pretend tilt: the slides' 3D)
			var tp0 := get_tree().root.find_child("TiltParallax", true, false)
			if tp0:
				tp0.qa_tilt = Vector2(float(str(args["depth"]).get_slice(",", 0)), float(str(args["depth"]).get_slice(",", 1)))
		await _open_menu(str(args["menu"]))
		_quit()
		return
	if game == "pet":
		for btn in get_tree().get_nodes_in_group("menu_toggle_buttons"):
			if btn.button_pressed:
				btn.button_pressed = false                     # (the games menu open: closed, the pet screen shows)
		await _wait(1.0)
		if args.has("depth"):                              # (the pet screen's 3D wallpaper: a pretend tilt)
			var tp := get_tree().root.find_child("TiltParallax", true, false)
			if tp:
				tp.qa_tilt = Vector2(float(str(args["depth"]).get_slice(",", 0)), float(str(args["depth"]).get_slice(",", 1)))
				await get_tree().create_timer(1.0).timeout
		if args.has("extra"):                              # (extra=/path/x.gd: a scratch script's run(capture) on the pet screen)
			var ex: Node = load(str(args["extra"])).new()
			get_tree().root.add_child(ex)
			await ex.run(self)
			_quit()
			return
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
	if args.has("menutest"):
		await _menu_test(gs, int(args["menutest"]))
		_quit()
		return
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
		if args.has("boost"):
			PetState.boost = str(args["boost"]).get_slice(":", 0)
			PetState.boost_level = int(str(args["boost"]).get_slice(":", 1)) if ":" in str(args["boost"]) else 1
		if g.has_method("uses_levels") and g.uses_levels():
			if g.level_menu:
				g.level_menu.close()
			var t0 := Time.get_ticks_msec()
			g.play_level(lvl)
			print("QA level %d built in %d ms" % [lvl, Time.get_ticks_msec() - t0])
			g.is_running = true
			if "qa_autopilot" in g:
				g.qa_autopilot = true
			if "qa_hands_off" in g and args.get("hands", "") == "off":
				g.qa_hands_off = true                          # (hands=off: nobody steers)
			if "qa_skill" in g and args.has("skill"):
				g.qa_skill = int(args["skill"])
			if "qa_depth_tilt" in g and args.has("depth"):
				g.qa_depth_tilt = Vector2(float(str(args["depth"]).get_slice(",", 0)), float(str(args["depth"]).get_slice(",", 1)))   # (depth=x,y: a pretend tilt)
			if args.get("intro", "") == "1" and g.has_method("_show_intro"):
				g.is_running = false
				g._show_intro()                                  # (intro=1: its how-to card)
		for k in shots:
			if args.has("until"):
				# (until=done: on as soon as the level is over, at most `wait` s)
				var waited := 0.0
				while waited < wait and g.is_running:
					await _wait(0.5)
					waited += 0.5
			else:
				await _wait(wait)
			await _shot("g%s_l%02d%s" % [game, lvl, "" if shots == 1 else "_%d" % k])
	_quit()

## menu=food / drinks / special / games / gear / shop[:page] / dress / decor / backgrounds / pedia / cases:
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
			"shop", "dress", "decor", "backgrounds", "pedia", "cases":
				var v: int = { "shop": t.View.SHOP, "dress": t.View.ACCESSORIES, "decor": t.View.DECOR, "backgrounds": t.View.BACKGROUNDS, "pedia": t.View.PEDIA, "cases": t.View.CASES }[name]
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

## diapos=...: each menu's slide recoloured (a look test, never saved): the outline kept, the frame
## and the inner panel (found by filling from the middle) each in its new colour, their own light
## and grain kept (the new colour scaled by each pixel's brightness against its area's mean)
func _recolour_diapos(spec: String) -> void:
	var paths := ["Main UI/Menus/FoodMenu/Menu/Background", "Main UI/Menus/GameMenu/Menu/Background", "Main UI/Menus/Settings Menu/Menu/Sprite2D"]
	var sets := spec.split(";")
	for i in mini(3, sets.size()):
		var sp := get_tree().root.get_node_or_null("PoopPal/" + paths[i]) as Sprite2D
		var cols := sets[i].split(",")
		if sp and cols.size() == 2:
			sp.texture = _recolour_slide(sp.texture, Color.html(cols[0]), Color.html(cols[1]))

func _recolour_slide(tex: Texture2D, frame: Color, inner: Color) -> Texture2D:
	var img := tex.get_image()
	if img.is_compressed():
		img.decompress()
	img.convert(Image.FORMAT_RGBA8)
	var w := img.get_width()
	var h := img.get_height()
	var dark := func(c: Color) -> bool: return c.a < 0.5 or c.get_luminance() < 0.3
	var in_set := {}
	var stack: Array[Vector2i] = [Vector2i(w / 2, h / 2)]
	while not stack.is_empty():
		var q: Vector2i = stack.pop_back()
		if q.x < 0 or q.y < 0 or q.x >= w or q.y >= h or in_set.has(q) or dark.call(img.get_pixelv(q)):
			continue
		in_set[q] = true
		stack.append_array([q + Vector2i(1, 0), q - Vector2i(1, 0), q + Vector2i(0, 1), q - Vector2i(0, 1)])
	var sums := [0.0, 0.0]
	var counts := [0, 0]
	for y in h:
		for x in w:
			var c := img.get_pixel(x, y)
			if dark.call(c):
				continue
			var k := 1 if in_set.has(Vector2i(x, y)) else 0
			sums[k] += c.get_luminance()
			counts[k] += 1
	for y in h:
		for x in w:
			var c := img.get_pixel(x, y)
			if dark.call(c):
				continue
			var k := 1 if in_set.has(Vector2i(x, y)) else 0
			var f: float = c.get_luminance() / maxf(0.01, sums[k] / maxf(1.0, counts[k]))
			var t: Color = inner if k == 1 else frame
			img.set_pixel(x, y, Color(clampf(t.r * f, 0, 1), clampf(t.g * f, 0, 1), clampf(t.b * f, 0, 1), c.a))
	return ImageTexture.create_from_image(img)

## menutest=N: drives the game's level menu with the device buttons' own calls (what a player
## does): FORWARD N times (the next world), then a HOLD on the selected level; prints what plays
func _menu_test(gs, pages: int) -> void:
	var g = gs.current_game
	print("QA menu open: ", g.level_menu_open())
	for i in pages:
		g.on_forward_button_pressed()
		await _wait(0.4)
	await _shot("menutest_page")
	g.on_main_button_pressed()
	await _wait(0.2)
	g.on_main_button_released()                          # (a tap: the next level)
	await _wait(0.3)
	g.on_main_button_pressed()
	await _wait(0.9)                                     # (a hold: play it)
	g.on_main_button_released()
	await _wait(1.5)
	print("QA menu open after: ", g.level_menu_open(), "  running: ", g.is_running, "  level: ", g.get("level"))
	await _shot("menutest_play")

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
