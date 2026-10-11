extends Control
class_name LevelMenu
## A game's level menu and its result card (Progression v2), built in code over the play area.
## Any BaseMinigame with levels uses it (see BaseMinigame.uses_levels).
##
##   SELECT  the game's worlds, 9 levels a page (3 x 3, like the Pal Pedia): main button
##           PRESS = next level, HOLD = play it; FORWARD = next world. Each level shows its best
##           stars; a locked one shows a padlock. The Games button leaves, as in any game.
##   RESULT  after a level: the stars fill in one by one, new stars fly into the coin counter,
##           then NEXT / RETRY / LEVELS (time's up: RETRY / LEVELS), like the game over screen:
##           FORWARD = change, MAIN = OK.

signal chosen(action: String, level: int)        # "play" / "next" / "retry" / "levels"

const W := 950.0
const H := 948.0
const HOLD := 0.6                                # seconds to hold the main button to play
const CELL := Vector2(240, 196)
const GAP := Vector2(32, 26)
const GRID_TOP := 200.0
const INK := Color8(74, 44, 32)
const CREAM := Color8(250, 244, 214)
const CARD_BORDER := Color8(58, 38, 30)
const TEXT := Color8(92, 60, 44)
const HILITE := Color(1, 1, 0.4)

enum Mode { HIDDEN, SELECT, RESULT }

var mode := Mode.HIDDEN
var game: BaseMinigame
var game_index := -1
var world_names: Array = []
var base: ColorRect                              # the colour under the pattern (each world's own)
var levels := 0
var page := 0
var selection := 0                                # index on the page (0..8)
var focus_level := 1
var font: Font

# select view
var select_root: Control
var bg: TextureRect
var shade: ColorRect
var title: Label
var subtitle: Label
var coin_label: Label
var stars_label: Label
var grid: Control
var cells: Array[Control] = []
var dots: HBoxContainer
var ring: HoldFrame
var legend: HBoxContainer

# result view
var card: Control
var r_title: Label
var r_stars: Array[TextureRect] = []
var r_coins: Label
var r_options: Array[Label] = []
var r_actions: Array[String] = []
var r_sel := 0
var r_level := 1
var _result_ready := false                       # (input waits until the stars have filled in)

var _scroll := 0.0

# hold to play
var _held := false
var _hold_t := 0.0
var _used := false

## `backdrop`: the colour under the pattern (the pattern itself is see-through, like on the card)
func setup(owner_game: BaseMinigame, index: int, names: Array, level_count: int, pattern: Texture2D, backdrop := Color8(214, 196, 160)) -> void:
	game = owner_game
	game_index = index
	world_names = names
	levels = level_count
	font = load("res://fonts/pixChicago.ttf")
	size = Vector2(W, H)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	z_index = 20
	visible = false

	# everything of the level grid lives in select_root (hidden under the result card)
	select_root = Control.new()
	select_root.size = Vector2(W, H)
	select_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(select_root)
	base = ColorRect.new()
	base.color = backdrop
	base.size = Vector2(W, H)
	base.mouse_filter = Control.MOUSE_FILTER_IGNORE
	select_root.add_child(base)
	bg = TextureRect.new()
	bg.texture = pattern
	bg.stretch_mode = TextureRect.STRETCH_TILE
	bg.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	# (tiled one pattern-width past the screen on each axis, so it can scroll by a whole tile)
	bg.scale = Vector2.ONE
	bg.size = Vector2(W, H) + (pattern.get_size() if pattern else Vector2.ZERO)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	select_root.add_child(bg)
	shade = ColorRect.new()
	shade.color = Color(0.16, 0.1, 0.07, 0.12)
	shade.size = Vector2(W, H)
	shade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	select_root.add_child(shade)

	title = _label(Vector2(0, 16), Vector2(W, 64), 50, CREAM, select_root)
	_outline(title, 14)
	subtitle = _label(Vector2(0, 84), Vector2(W, 44), 30, CREAM, select_root)
	_outline(subtitle, 10)
	# world stars (left) and coins (right), in the header
	var star_icon := _icon(UiArt.star(true), Vector2(46, 44), 4.0)
	select_root.add_child(star_icon)
	stars_label = _label(Vector2(104, 34), Vector2(200, 56), 34, CREAM, select_root)
	stars_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	_outline(stars_label, 10)
	var coin_icon := _icon(UiArt.coin(), Vector2(W - 210, 46), 4.0)
	select_root.add_child(coin_icon)
	coin_label = _label(Vector2(W - 158, 34), Vector2(140, 56), 34, CREAM, select_root)
	coin_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	_outline(coin_label, 10)

	dots = HBoxContainer.new()
	dots.add_theme_constant_override("separation", 14)
	dots.position = Vector2(0, 140)
	dots.size = Vector2(W, 30)
	dots.alignment = BoxContainer.ALIGNMENT_CENTER
	dots.mouse_filter = Control.MOUSE_FILTER_IGNORE
	select_root.add_child(dots)

	grid = Control.new()
	grid.mouse_filter = Control.MOUSE_FILTER_IGNORE
	select_root.add_child(grid)

	ring = HoldFrame.new()
	ring.visible = false
	ring.z_index = 3                                # (over the selected level, which is raised)
	ring.mouse_filter = Control.MOUSE_FILTER_IGNORE
	select_root.add_child(ring)

	legend = HBoxContainer.new()
	legend.add_theme_constant_override("separation", 26)
	legend.alignment = BoxContainer.ALIGNMENT_CENTER
	legend.position = Vector2(0, H - 82)
	legend.size = Vector2(W, 60)
	legend.mouse_filter = Control.MOUSE_FILTER_IGNORE
	select_root.add_child(legend)
	_hint(0, "next  ·  hold: play")
	_hint(1, "world")

	_build_card()
	GameData.coins_changed.connect(func(_c): _refresh_header())

func is_open() -> bool:
	return mode != Mode.HIDDEN

func close() -> void:
	mode = Mode.HIDDEN
	visible = false
	_held = false
	ring.visible = false

# ================================================================== SELECT

func show_select(level := -1) -> void:
	mode = Mode.SELECT
	visible = true
	card.visible = false
	select_root.visible = true
	focus_level = clampi(level if level > 0 else _first_unfinished(), 1, maxi(levels, 1))
	page = (focus_level - 1) / GameData.LEVELS_PER_WORLD
	selection = (focus_level - 1) % GameData.LEVELS_PER_WORLD
	_build_page()

## The first level still missing stars (or the last one open)
func _first_unfinished() -> int:
	for lvl in range(1, levels + 1):
		if not GameData.level_open(game_index, lvl):
			return maxi(1, lvl - 1)
		if GameData.level_stars(game_index, lvl) < 3:
			return lvl
	return levels

func _build_page() -> void:
	for c in grid.get_children():
		c.queue_free()
	cells.clear()
	var per := GameData.LEVELS_PER_WORLD
	title.text = "WORLD %d" % (page + 1)
	subtitle.text = world_names[page] if page < world_names.size() else ""
	if game:
		base.color = game.world_backdrop(page)
	var origin := Vector2((W - (3 * CELL.x + 2 * GAP.x)) / 2.0, GRID_TOP)
	for slot in per:
		var lvl := page * per + slot + 1
		if lvl > levels:
			break
		var pos := origin + Vector2(slot % 3, slot / 3) * (CELL + GAP)
		cells.append(_cell(pos, lvl))
	selection = clampi(selection, 0, maxi(cells.size() - 1, 0))
	# world dots
	for d in dots.get_children():
		d.queue_free()
	for i in _pages():
		var dot := ColorRect.new()
		dot.custom_minimum_size = Vector2(16, 16)
		dot.color = CREAM if i == page else Color(CREAM, 0.35)
		dot.mouse_filter = Control.MOUSE_FILTER_IGNORE
		dots.add_child(dot)
	_refresh_header()
	_refresh_selection()

func _cell(pos: Vector2, lvl: int) -> Control:
	var open := GameData.level_open(game_index, lvl)
	var stars := GameData.level_stars(game_index, lvl)
	var p := Panel.new()
	p.position = pos
	p.size = CELL
	p.pivot_offset = CELL / 2.0
	p.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var sb := StyleBoxFlat.new()
	sb.bg_color = CREAM if open else Color8(196, 180, 156)
	sb.border_color = CARD_BORDER
	sb.set_border_width_all(6)
	sb.border_width_bottom = 10
	sb.set_corner_radius_all(10)
	sb.anti_aliasing = false
	p.add_theme_stylebox_override("panel", sb)
	grid.add_child(p)
	var per := GameData.LEVELS_PER_WORLD
	var num := _label(Vector2(0, 18), Vector2(CELL.x, 90), 64, TEXT if open else Color(TEXT, 0.45), p)
	num.text = "%d-%d" % [(lvl - 1) / per + 1, (lvl - 1) % per + 1]
	if open:
		for k in 3:
			var s := _icon(UiArt.star(k < stars), Vector2(CELL.x / 2.0 + (k - 1) * 62, 140), 4.0)
			p.add_child(s)
	else:
		p.add_child(_icon(UiArt.lock(), Vector2(CELL.x / 2.0, 142), 4.0))
	p.set_meta("level", lvl)
	p.set_meta("open", open)
	return p

func _pages() -> int:
	return maxi(1, ceili(levels / float(GameData.LEVELS_PER_WORLD)))

func _refresh_header() -> void:
	coin_label.text = str(GameData.coins)
	var per := GameData.LEVELS_PER_WORLD
	var got := 0
	for lvl in range(page * per + 1, mini(levels, (page + 1) * per) + 1):
		got += GameData.level_stars(game_index, lvl)
	stars_label.text = "%d/%d" % [got, mini(per, levels - page * per) * 3]

func _refresh_selection() -> void:
	for i in cells.size():
		cells[i].scale = Vector2.ONE * (1.07 if i == selection else 1.0)
		cells[i].z_index = 1 if i == selection else 0
	if selection < cells.size():
		var c := cells[selection]
		ring.position = c.position - Vector2(22, 22)      # (round the raised card, not under it)
		ring.size = c.size + Vector2(44, 44)

# ================================================================== RESULT

func _build_card() -> void:
	card = Control.new()
	card.size = Vector2(640, 600)
	card.position = Vector2((W - card.size.x) / 2.0, (H - card.size.y) / 2.0)
	card.pivot_offset = card.size / 2.0
	card.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card.visible = false
	add_child(card)
	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.45)
	dim.position = -card.position
	dim.size = Vector2(W, H)
	dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card.add_child(dim)
	var frame := NinePatchRect.new()
	frame.texture = BaseMinigame._label_frame_texture()
	frame.patch_margin_left = 4
	frame.patch_margin_right = 4
	frame.patch_margin_top = 4
	frame.patch_margin_bottom = 7
	frame.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	frame.scale = Vector2(3, 3)
	frame.size = card.size / 3.0
	card.add_child(frame)
	r_title = _label(Vector2(20, 36), Vector2(card.size.x - 40, 70), 50, TEXT, card)
	for k in 3:
		var s := TextureRect.new()
		s.texture = UiArt.star(false)
		s.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		s.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		s.size = Vector2(110, 110)
		s.pivot_offset = s.size / 2.0
		s.position = Vector2(card.size.x / 2.0 + (k - 1) * 140 - 55, 124 + (0 if k == 1 else 18))
		s.mouse_filter = Control.MOUSE_FILTER_IGNORE
		card.add_child(s)
		r_stars.append(s)
	r_coins = _label(Vector2(20, 262), Vector2(card.size.x - 40, 50), 36, TEXT, card)
	for i in 3:
		var o := _label(Vector2(0, 330 + i * 62), Vector2(card.size.x, 60), 44, Color(0.55, 0.5, 0.45), card)
		r_options.append(o)

## A level is over: `stars` 1-3 = cleared (0 = time's up), `coins_won` = new coins
func show_result(level: int, stars: int, coins_won: int) -> void:
	mode = Mode.RESULT
	visible = true
	select_root.visible = false
	ring.visible = false
	card.visible = true
	r_level = level
	_result_ready = false
	var per := GameData.LEVELS_PER_WORLD
	var lvl_name := "%d-%d" % [(level - 1) / per + 1, (level - 1) % per + 1]
	r_title.text = ("Level %s clear!" % lvl_name) if stars > 0 else "Time's up!"
	r_actions.assign(["next", "retry", "levels"] if stars > 0 and level < levels else ["retry", "levels"])
	for i in r_options.size():
		r_options[i].visible = i < r_actions.size()
	r_sel = 0
	_refresh_options()
	r_coins.text = ""
	for s in r_stars:
		s.texture = UiArt.star(false)
		s.scale = Vector2.ONE
	card.scale = Vector2(0.7, 0.7)
	card.modulate.a = 0.0
	var t := create_tween()
	t.tween_property(card, "scale", Vector2.ONE, 0.22).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	t.parallel().tween_property(card, "modulate:a", 1.0, 0.15)
	# the stars fill in one by one
	for k in stars:
		t.tween_interval(0.28)
		t.tween_callback(func():
			r_stars[k].texture = UiArt.star(true)
			_sfx("res://sounds/fx/gamecoin.wav", -8.0 + k * 1.5))
		t.tween_property(r_stars[k], "scale", Vector2(1.3, 1.3), 0.08)
		t.tween_property(r_stars[k], "scale", Vector2.ONE, 0.18).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	if coins_won > 0:
		t.tween_interval(0.25)
		t.tween_callback(func():
			r_coins.text = "+%d coin%s" % [coins_won, "" if coins_won == 1 else "s"]
			_sfx("res://sounds/fx/claw_prize.wav", -10.0))
	elif stars > 0:
		t.tween_callback(func(): r_coins.text = "")
	t.tween_callback(func(): _result_ready = true)

func _refresh_options() -> void:
	for i in r_actions.size():
		r_options[i].add_theme_color_override("font_color", Color8(196, 120, 40) if i == r_sel else Color(0.55, 0.5, 0.45))
		r_options[i].text = ("> %s <" if i == r_sel else "%s") % _option_name(r_actions[i])

func _option_name(a: String) -> String:
	return { "next": "Next level", "retry": "Retry", "levels": "Levels" }[a]

# ================================================================== INPUT (from the game)

func press() -> void:
	match mode:
		Mode.SELECT:
			_held = true
			_hold_t = 0.0
			_used = false
		Mode.RESULT:
			if not _result_ready:
				return
			_click()
			var a := r_actions[r_sel]
			var lvl := r_level + 1 if a == "next" else r_level
			chosen.emit(a, lvl)

func release() -> void:
	if mode != Mode.SELECT or not _held:
		return
	_held = false
	ring.visible = false
	if not _used:
		# a tap: the next level on this page
		if not cells.is_empty():
			selection = (selection + 1) % cells.size()
			_refresh_selection()
			_click()

func forward() -> void:
	match mode:
		Mode.SELECT:
			page = (page + 1) % _pages()
			selection = 0
			_build_page()
			_click()
		Mode.RESULT:
			if not _result_ready:
				return
			r_sel = (r_sel + 1) % r_actions.size()
			_refresh_options()
			_click()

func _process(delta: float) -> void:
	if mode == Mode.SELECT and bg.texture:
		# the game's pattern drifts slowly behind the levels, like on its card
		_scroll += delta
		var tile := bg.texture.get_size() * bg.scale
		bg.position = Vector2(-fposmod(_scroll * 20.0, tile.x), -fposmod(_scroll * 20.0, tile.y))
	if not _held or _used:
		return
	_hold_t += delta
	if _hold_t < 0.15:
		return
	ring.visible = true
	ring.set_value(clampf((_hold_t - 0.15) / (HOLD - 0.15), 0.0, 1.0))
	if _hold_t >= HOLD:
		_used = true
		ring.visible = false
		var c := cells[selection] if selection < cells.size() else null
		if c and c.get_meta("open"):
			_sfx("res://sounds/fx/clack.mp3", -6.0)
			chosen.emit("play", c.get_meta("level"))
		else:
			_sfx("res://sounds/fx/error.mp3", -14.0)
			Input.vibrate_handheld(30)

# ================================================================== BUILDERS

func _label(pos: Vector2, sz: Vector2, font_size: int, color: Color, parent: Node) -> Label:
	var l := Label.new()
	l.position = pos
	l.size = sz
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	if font:
		l.add_theme_font_override("font", font)
	l.add_theme_font_size_override("font_size", font_size)
	l.add_theme_color_override("font_color", color)
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(l)
	return l

func _outline(l: Label, px: int) -> void:
	l.add_theme_color_override("font_outline_color", INK)
	l.add_theme_constant_override("outline_size", px)

## A pixel icon centred on `center`, `px` screen pixels per art pixel
func _icon(tex: Texture2D, center: Vector2, px: float) -> TextureRect:
	var r := TextureRect.new()
	r.texture = tex
	r.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	r.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	r.size = tex.get_size() * px
	r.position = center - r.size / 2.0
	r.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return r

## One device button's icon (0 = main, 1 = forward) and a word, in the legend row
func _hint(which: int, text: String) -> void:
	var box := HBoxContainer.new()
	box.add_theme_constant_override("separation", 10)
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var icon := TextureRect.new()
	icon.texture = load(BaseMinigame.BUTTON_ICONS[which])
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.custom_minimum_size = Vector2(56 if which == 1 else 42, 40)
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_child(icon)
	var l := Label.new()
	l.text = text
	l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	if font:
		l.add_theme_font_override("font", font)
	l.add_theme_font_size_override("font_size", 30)
	l.add_theme_color_override("font_color", CREAM)
	l.add_theme_color_override("font_outline_color", INK)
	l.add_theme_constant_override("outline_size", 10)
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_child(l)
	legend.add_child(box)

func _click() -> void:
	_sfx("res://sounds/fx/click-5.mp3", -8.0)

func _sfx(path: String, volume_db: float) -> void:
	var stream = load(path) as AudioStream
	if not stream:
		return
	var p := AudioStreamPlayer.new()
	p.stream = stream
	p.volume_db = volume_db
	add_child(p)
	p.play()
	p.finished.connect(p.queue_free)

## The hold-to-play progress round the selected level: a rounded frame filling clockwise from the
## top middle, apricot on a dark edge (like the menus' round hold rings, but the card's shape)
class HoldFrame extends Control:
	var value := 0.0
	const R := 18.0                               # corner radius
	const W_DARK := 14.0
	const W_FILL := 8.0

	func set_value(v: float) -> void:
		value = v
		queue_redraw()

	func _path() -> PackedVector2Array:
		# the rounded rectangle's outline, clockwise from the middle of the top edge
		var w := size.x
		var h := size.y
		var pts := PackedVector2Array()
		pts.append(Vector2(w / 2.0, 0))
		var corners := [[Vector2(w - R, R), -PI / 2.0], [Vector2(w - R, h - R), 0.0], [Vector2(R, h - R), PI / 2.0], [Vector2(R, R), PI]]
		for c in corners:
			var centre: Vector2 = c[0]
			var a0: float = c[1]
			for k in 7:
				var a := a0 + k * (PI / 2.0) / 6.0
				pts.append(centre + Vector2(cos(a), sin(a)) * R)
		pts.append(Vector2(w / 2.0, 0))
		return pts

	func _draw() -> void:
		if value <= 0.0:
			return
		var pts := _path()
		var total := 0.0
		for i in range(1, pts.size()):
			total += pts[i].distance_to(pts[i - 1])
		var want := total * value
		var part := PackedVector2Array([pts[0]])
		var run := 0.0
		for i in range(1, pts.size()):
			var seg := pts[i].distance_to(pts[i - 1])
			if run + seg >= want:
				part.append(pts[i - 1].lerp(pts[i], (want - run) / maxf(seg, 0.001)))
				break
			part.append(pts[i])
			run += seg
		if part.size() < 2:
			return
		draw_polyline(part, Color(0.290196, 0.184314, 0.121569, 1), W_DARK)
		draw_polyline(part, Color8(243, 182, 126), W_FILL)
