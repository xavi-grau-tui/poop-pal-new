extends BaseMinigame
## Lucky Pinch — the bonus claw machine (LuckyPinch autoload: it shows up now and then after
## a meal and must be played). Two tries; every capsule holds a prize (LuckyPinch keeps the
## pile between bonuses: what's inside each one and where it lies, also after being knocked).
##
##   hold MAIN     = the claw slides right (let go: it stops; one go only, like the real one)
##   hold FORWARD  = the claw moves to the back (let go: it drops)
## The claw sways a little after moving, so when you let go matters. It grabs firmly when it
## comes down right on a capsule, loosely when it's a bit off (and a loose capsule can slip
## on the way back; if it slips over the chute it still counts).
##
## Front view with depth: a capsule's depth d (0 front .. 1 back) sets how high it sits on
## the pit floor and how big it is; the claw's shadow on the floor shows where it will land.

const K := 3.0                          # world px per cabinet pixel
const RAIL_Y := 118.0
const HUB_Y := 150.0                    # where the claw hangs while it travels
const START_X := 130.0                  # above the prize chute
const X_MAX := 872.0
const MOVE_SPEED := 250.0
const DEPTH_SPEED := 0.6
const DROP_SPEED := 430.0
const LIFT_SPEED := 340.0
const RETURN_SPEED := 400.0
const FLOOR_FRONT := 884.0
const FLOOR_BACK := 694.0
const CHUTE := Rect2(40, 600, 184, 330)  # the prize chute's front panel
const CHUTE_WINDOW := Rect2(62, 790, 140, 110)
const TRIES_LCD := Rect2(24, 8, 210, 62)
const PIT_X := Vector2(300.0, 890.0)
const CLAW_HOLD_Y := 14.0              # (claw pixels) where a held capsule's centre sits
# Grabbing is positional (x in px, depth d 0..1): only a capsule really under the claw
const GRAB_DX := 32.0                   # ...a bit off = a loose grip (may slip on the way)
const GRAB_DD := 0.13
const FIRM_DX := 14.0                   # ...right on top = a firm grip
const FIRM_DD := 0.06
const PUSH_DX := 85.0                   # capsules this close to where it lands get knocked aside
const PUSH_DD := 0.25    # capsules lie between these x

const CAPSULE_COLORS := ["pink", "mint", "yellow", "lilac", "orange"]
const OUTLINE := Color8(74, 44, 32)
const GOLD := Color8(232, 184, 84)
const GOLD_LO := Color8(176, 124, 46)
const BACK := Color8(88, 48, 88)

enum P { READY, MOVE_X, WAIT_D, MOVE_D, DROP, GRAB, LIFT, RETURN, RELEASE, PRIZE, DONE }

var phase := P.READY
var claw_x := START_X
var claw_d := 0.0
var hub_y := HUB_Y
var sway_t := 99.0
var sway_amp := 0.0
var held: Dictionary = {}               # the capsule in the claw ({} = none)
var held_loose := 1.0                   # chance it slips on the way back
var slip_at := 2.0                      # progress (0..2: lift, return) where it slips
var _progress := 0.0
var _wait := 0.0
var main_down := false
var fwd_down := false
var capsules: Array[Dictionary] = []    # LuckyPinch.pit entries still lying in the pit (+ "node")
var _won: Dictionary = {}               # the capsule on its way down the chute
var _clock := 0.0

var lcd_font: Font
var view: SubViewport
var canvas: Node2D
var pit: Node2D
var rig: Node2D
var rig_inner: Node2D
var claw_sprite: Sprite2D
var carriage: Sprite2D
var cable: Line2D
var shadow: Sprite2D
var prize_layer: Node2D
var chute_front: Control
var hint: Label
var tries_label: Label
var banner: Label
var motor: AudioStreamPlayer
var tex := {}

func _ready() -> void:
	lcd_font = load("res://fonts/pixChicago.ttf")
	for n in ["claw_open", "claw_closed", "carriage"] + CAPSULE_COLORS.map(func(c): return "capsule_" + c):
		tex[n] = load("res://textures/minigames/pinch/%s.png" % n)
	_create_nodes()
	_fill_pit()
	super._ready()

func start_game() -> void:
	super.start_game()
	_reset_claw()
	_show_banner("Lucky Pinch!", 1.2)

# ================================================================== DEPTH HELPERS

func floor_y(d: float) -> float:
	return lerpf(FLOOR_FRONT, FLOOR_BACK, d)

func depth_scale(d: float) -> float:
	return lerpf(5.0, 3.8, d)

func capsule_rest_y(d: float) -> float:
	return floor_y(d) - 7.5 * depth_scale(d)

func _sway() -> float:
	return sway_amp * sin(sway_t * 6.5) * exp(-sway_t * 1.1)

# ================================================================== LOOP

func _process(delta: float) -> void:
	_clock += delta
	canvas.queue_redraw()
	if not is_running:
		return
	sway_t += delta
	match phase:
		P.MOVE_X:
			if main_down and claw_x < X_MAX:
				claw_x = minf(X_MAX, claw_x + MOVE_SPEED * delta)
			else:
				_motor(false)
				sway_amp = 16.0
				sway_t = 0.0
				phase = P.WAIT_D
				hint.text = "now hold forward"
		P.MOVE_D:
			if fwd_down and claw_d < 1.0:
				claw_d = minf(1.0, claw_d + DEPTH_SPEED * delta)
			else:
				_motor(false)
				sway_amp = maxf(absf(_sway()), 7.0)
				sway_t = 0.0
				_start_drop()
		P.DROP:
			var target := capsule_rest_y(claw_d) - CLAW_HOLD_Y * depth_scale(claw_d)
			hub_y = minf(target, hub_y + DROP_SPEED * delta)
			if hub_y >= target:
				phase = P.GRAB
				_wait = 0.35
		P.GRAB:
			_wait -= delta
			if _wait <= 0.0:
				_grab()
				phase = P.LIFT
				_progress = 0.0
		P.LIFT:
			hub_y = maxf(HUB_Y, hub_y - LIFT_SPEED * delta)
			var span := capsule_rest_y(claw_d) - HUB_Y
			_progress = 1.0 - (hub_y - HUB_Y) / maxf(1.0, span)
			_check_slip()
			if hub_y <= HUB_Y:
				phase = P.RETURN
				_motor(true)
		P.RETURN:
			claw_x = move_toward(claw_x, START_X, RETURN_SPEED * delta)
			claw_d = move_toward(claw_d, 0.0, DEPTH_SPEED * 1.4 * delta)
			_progress = 1.0 + 1.0 - (claw_x - START_X) / maxf(1.0, X_MAX - START_X)
			_check_slip()
			if claw_x <= START_X and claw_d <= 0.0:
				_motor(false)
				phase = P.RELEASE
				_release()
		P.PRIZE, P.RELEASE:
			pass
	_place_claw()

func _start_drop() -> void:
	phase = P.DROP
	hint.text = ""
	LuckyPinch.use_try()
	_refresh_tries()
	claw_sprite.texture = tex["claw_open"]
	_sfx("res://sounds/fx/claw_drop.wav", -10.0)

func _place_claw() -> void:
	var sc := depth_scale(claw_d)
	var x := claw_x + _sway()
	var key := capsule_rest_y(claw_d) + 1.0          # y-sort: just in front of its depth row
	rig.position = Vector2(x, key)
	rig_inner.position = Vector2(0, hub_y - key)
	rig_inner.scale = Vector2(sc, sc)
	rig_inner.rotation = -_sway() * 0.006
	carriage.position = Vector2(claw_x, RAIL_Y)
	cable.points = PackedVector2Array([Vector2(claw_x, RAIL_Y + 10), Vector2(x, hub_y + 1)])
	shadow.position = Vector2(x, floor_y(claw_d) - 4)
	shadow.scale = Vector2(sc * 1.1, sc * 0.5)
	shadow.modulate.a = 0.15 + 0.35 * clampf((hub_y - HUB_Y) / 500.0, 0.0, 1.0)

# ================================================================== GRAB / SLIP / PRIZE

func _grab() -> void:
	claw_sprite.texture = tex["claw_closed"]
	_sfx("res://sounds/fx/claw_grab.wav", -10.0)
	var x := claw_x + _sway()
	# only a capsule that's really between the prongs: close in x AND at the same depth
	var best := -1
	var best_score := 9999.0
	for i in capsules.size():
		var c: Dictionary = capsules[i]
		var dx: float = absf(c["x"] - x)
		var dd: float = absf(c["d"] - claw_d)
		if dx <= GRAB_DX and dd <= GRAB_DD and dx + dd * 200.0 < best_score:
			best_score = dx + dd * 200.0
			best = i
	_push_neighbours(x, best)
	if best < 0:
		return                                         # closed on nothing
	held = capsules[best]
	capsules.remove_at(best)
	var firm: bool = absf(held["x"] - x) <= FIRM_DX and absf(held["d"] - claw_d) <= FIRM_DD
	held_loose = 0.05 if firm else 0.6
	slip_at = randf_range(0.2, 1.9) if randf() < held_loose else 9.0
	var node: Sprite2D = held["node"]
	node.get_parent().remove_child(node)
	rig_inner.add_child(node)
	rig_inner.move_child(node, 0)                       # behind the prongs
	node.scale = Vector2.ONE
	node.rotation = 0.0
	node.position = Vector2(0, CLAW_HOLD_Y)

## The prongs knock the capsules they land next to: they roll a little to the side
func _push_neighbours(x: float, except: int) -> void:
	for i in capsules.size():
		if i == except:
			continue
		var c: Dictionary = capsules[i]
		var dx: float = c["x"] - x
		if absf(dx) > PUSH_DX or absf(c["d"] - claw_d) > PUSH_DD:
			continue
		var side := signf(dx) if dx != 0.0 else (1.0 if randf() < 0.5 else -1.0)
		c["x"] = clampf(c["x"] + side * randf_range(26.0, 46.0), PIT_X.x, PIT_X.y)
		var node: Sprite2D = c["node"]
		var t := create_tween()
		t.tween_property(node, "position:x", c["x"], 0.35).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		c["rot"] = node.rotation + side * 1.2
		t.parallel().tween_property(node, "rotation", c["rot"], 0.35)

func _check_slip() -> void:
	if held.is_empty() or _progress < slip_at:
		return
	var node: Sprite2D = held["node"]
	var from := node.global_position - global_position
	rig_inner.remove_child(node)
	var x := claw_x + _sway()
	var c: Dictionary = held
	held = {}
	if x < CHUTE.end.x - 10.0:
		# slipped right over the chute: lucky!
		add_child(node)
		move_child(node, chute_front.get_index())       # behind the chute's front panel
		node.position = from
		node.scale = Vector2.ONE * depth_scale(0.0)
		_won = c
		_drop_into_chute(node)
		return
	# back into the pit, where it fell (and it stays there for the next bonus)
	var d := claw_d
	c["x"] = clampf(x, PIT_X.x, PIT_X.y)
	c["d"] = d
	c["rot"] = randf_range(-0.6, 0.6)
	pit.add_child(node)
	node.position = from
	node.scale = Vector2.ONE * depth_scale(d)
	capsules.append(c)
	var t := create_tween()
	t.tween_property(node, "position", Vector2(c["x"], capsule_rest_y(d)), 0.45).set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)
	t.parallel().tween_property(node, "rotation", c["rot"], 0.45)
	_sfx("res://sounds/fx/claw_miss.wav", -12.0)
	_float_text("oops!", Vector2(c["x"], capsule_rest_y(d) - 40))

func _release() -> void:
	claw_sprite.texture = tex["claw_open"]
	if held.is_empty():
		_sfx("res://sounds/fx/claw_miss.wav", -12.0)
		_show_banner("No luck...", 0.9)
		get_tree().create_timer(1.4).timeout.connect(_next_try)
		return
	var node: Sprite2D = held["node"]
	var at := node.global_position - global_position
	rig_inner.remove_child(node)
	_won = held
	held = {}
	add_child(node)
	move_child(node, chute_front.get_index())           # behind the chute's front panel
	node.position = at
	node.scale = Vector2.ONE * depth_scale(0.0)
	_drop_into_chute(node)

func _drop_into_chute(node: Sprite2D) -> void:
	phase = P.PRIZE
	var t := create_tween()
	t.tween_property(node, "position:y", CHUTE.position.y + 120.0, 0.35).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_QUAD)
	t.tween_callback(func():
		node.queue_free()
		_reveal_prize(node.texture))

## The capsule rolls out into the chute window and pops open: the prize!
func _reveal_prize(capsule_tex: Texture2D) -> void:
	var cap := Sprite2D.new()
	cap.texture = capsule_tex
	cap.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	cap.scale = Vector2(5, 5)
	cap.position = CHUTE_WINDOW.get_center() + Vector2(0, -60)
	prize_layer.add_child(cap)
	var t := create_tween()
	t.tween_property(cap, "position:y", CHUTE_WINDOW.get_center().y + 10, 0.4).set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)
	t.tween_interval(0.3)
	t.tween_property(cap, "scale", Vector2(6.4, 6.4), 0.12)
	t.tween_callback(func():
		cap.queue_free()
		_open_prize())

func _open_prize() -> void:
	var p := LuckyPinch.win(_won)
	_won = {}
	if p.has("points"):
		add_score(p["points"])
	_sfx("res://sounds/fx/claw_prize.wav", -8.0)
	for i in 10:
		_spark(CHUTE_WINDOW.get_center())
	_show_prize_card(p)
	_refresh_tries()
	get_tree().create_timer(2.9).timeout.connect(_next_try)

## The prize card: a picture of the item, its name and what kind of item it is
func _show_prize_card(p: Dictionary) -> void:
	var card := Control.new()
	card.size = Vector2(540, 400)
	card.position = Vector2((PLAY_WIDTH - card.size.x) / 2.0 + 60.0, 230)
	card.pivot_offset = card.size / 2.0
	add_child(card)
	var border := ColorRect.new()
	border.color = OUTLINE
	border.size = card.size
	card.add_child(border)
	var face := ColorRect.new()
	face.color = Color8(250, 238, 208)
	face.position = Vector2(8, 8)
	face.size = card.size - Vector2(16, 16)
	card.add_child(face)
	var band := ColorRect.new()
	band.color = GOLD
	band.position = Vector2(8, 8)
	band.size = Vector2(card.size.x - 16, 52)
	card.add_child(band)
	var head := _card_label(card, Vector2(0, 10), Vector2(card.size.x, 48), 30, OUTLINE)
	head.text = "YOU GOT"
	# picture (the same previews as the settings menus)
	var box := ColorRect.new()
	box.color = OUTLINE
	box.position = Vector2((card.size.x - 170) / 2.0, 74)
	box.size = Vector2(170, 170)
	card.add_child(box)
	var inner := ColorRect.new()
	inner.color = Color8(232, 214, 176)
	inner.position = box.position + Vector2(6, 6)
	inner.size = box.size - Vector2(12, 12)
	card.add_child(inner)
	var pic := TextureRect.new()
	pic.position = inner.position + Vector2(6, 6)
	pic.size = inner.size - Vector2(12, 12)
	pic.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	pic.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	pic.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	card.add_child(pic)
	var name_l := _card_label(card, Vector2(0, 262), Vector2(card.size.x, 52), 38, OUTLINE)
	var kind_l := _card_label(card, Vector2(0, 322), Vector2(card.size.x, 44), 26, Color8(104, 128, 72))
	if p.has("category"):
		var menu := get_node_or_null("/root/PoopPal/Main UI/Menus/Settings Menu")
		if menu and menu.has_method("_item_preview"):
			pic.texture = menu._item_preview(p["category"], p["id"])
		name_l.text = p["name"]
		kind_l.text = LuckyPinch.kind_label(p["category"], p["id"])
	else:
		name_l.text = "+%d pts" % p.get("points", 0)
		kind_l.text = "Bonus points"
		pic.texture = tex["capsule_yellow"]
	card.scale = Vector2(0.2, 0.2)
	var t := create_tween()
	t.tween_property(card, "scale", Vector2.ONE, 0.3).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	t.tween_interval(2.2)
	t.tween_property(card, "modulate:a", 0.0, 0.3)
	t.tween_callback(card.queue_free)

func _card_label(parent: Control, pos: Vector2, sz: Vector2, font_size: int, color: Color) -> Label:
	var l := Label.new()
	l.position = pos
	l.size = sz
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	if lcd_font:
		l.add_theme_font_override("font", lcd_font)
	l.add_theme_font_size_override("font_size", font_size)
	l.add_theme_color_override("font_color", color)
	parent.add_child(l)
	return l

func _next_try() -> void:
	if not is_running:
		return
	if LuckyPinch.tries > 0:
		_reset_claw()
		_show_banner("Last try!", 0.9)
	else:
		phase = P.DONE
		_finish()

func _finish() -> void:
	var won: Array = LuckyPinch.prizes.map(func(p): return p["name"] if p.has("name") else "+%d pts" % p.get("points", 0))
	LuckyPinch.finish()
	end_game()
	if game_over_overlay:
		var title: Label = game_over_overlay.get_meta("title")
		title.text = "Lucky Pinch!"
		var st: Label = game_over_overlay.get_meta("score_text")
		st.text = ("You got: " + ", ".join(PackedStringArray(won))) if not won.is_empty() else "No luck this time!"
		st.add_theme_font_size_override("font_size", 30)
		# no second go: only Exit
		var restart: Label = game_over_overlay.get_meta("restart_label")
		restart.visible = false
		game_over_selection = 1
		_update_game_over_selection()

func _reset_claw() -> void:
	phase = P.READY
	claw_x = START_X
	claw_d = 0.0
	hub_y = HUB_Y
	sway_amp = 0.0
	held = {}
	claw_sprite.texture = tex["claw_closed"]
	hint.text = "hold the orange button"
	_refresh_tries()

# ================================================================== NODES

func _fill_pit() -> void:
	for c in LuckyPinch.pit:
		var s := Sprite2D.new()
		s.texture = tex["capsule_" + str(c["color"])]
		s.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		s.scale = Vector2.ONE * depth_scale(c["d"])
		s.position = Vector2(c["x"], capsule_rest_y(c["d"]))
		s.rotation = c["rot"]
		pit.add_child(s)
		c["node"] = s
		capsules.append(c)

func _create_nodes() -> void:
	var bg := ColorRect.new()
	bg.color = BACK
	bg.size = Vector2(PLAY_WIDTH, PLAY_HEIGHT)
	add_child(bg)
	view = SubViewport.new()
	view.size = Vector2i(int(ceil(PLAY_WIDTH / K)), int(ceil(PLAY_HEIGHT / K)))
	view.transparent_bg = true
	view.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	add_child(view)
	canvas = Node2D.new()
	canvas.scale = Vector2.ONE / K
	canvas.draw.connect(_draw_cabinet)
	view.add_child(canvas)
	var cab := Sprite2D.new()
	cab.centered = false
	cab.texture = view.get_texture()
	cab.scale = Vector2(K, K)
	cab.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	add_child(cab)
	# claw shadow on the pit floor
	shadow = Sprite2D.new()
	shadow.texture = _oval_texture()
	shadow.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	shadow.modulate = Color(0, 0, 0, 0.3)
	add_child(shadow)
	cable = Line2D.new()
	cable.width = 6
	cable.default_color = Color8(150, 148, 166)
	add_child(cable)
	carriage = Sprite2D.new()
	carriage.texture = tex["carriage"]
	carriage.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	carriage.scale = Vector2(1.5, 1.5)            # (drawn on a 2x finer grid)
	add_child(carriage)
	pit = Node2D.new()
	pit.y_sort_enabled = true
	add_child(pit)
	rig = Node2D.new()
	pit.add_child(rig)
	rig_inner = Node2D.new()
	rig.add_child(rig_inner)
	claw_sprite = Sprite2D.new()
	claw_sprite.texture = tex["claw_closed"]
	claw_sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	claw_sprite.centered = false
	claw_sprite.scale = Vector2(0.5, 0.5)         # (drawn on a 2x finer grid, for the detail)
	claw_sprite.position = Vector2(-15.5, 0)
	rig_inner.add_child(claw_sprite)
	# the prize box (capsules fall in behind it): a solid gold cabinet, see-through only at
	# the little glass flap at the bottom where the prize comes out
	chute_front = Control.new()
	chute_front.position = CHUTE.position - Vector2(6, 6)
	chute_front.size = CHUTE.size + Vector2(12, 12)
	chute_front.mouse_filter = Control.MOUSE_FILTER_IGNORE
	chute_front.draw.connect(_draw_prize_box.bind(chute_front))
	add_child(chute_front)
	prize_layer = Node2D.new()
	add_child(prize_layer)
	# the glass flap, over the prize
	var glass := Control.new()
	glass.position = CHUTE_WINDOW.position
	glass.size = CHUTE_WINDOW.size
	glass.mouse_filter = Control.MOUSE_FILTER_IGNORE
	glass.draw.connect(_draw_flap_glass.bind(glass))
	add_child(glass)
	# HUD
	# tries: a little LCD, like the games' score screens
	var lcd_frame := ColorRect.new()
	lcd_frame.color = Color(0, 0, 0)
	lcd_frame.position = TRIES_LCD.position
	lcd_frame.size = TRIES_LCD.size
	add_child(lcd_frame)
	var lcd := ColorRect.new()
	lcd.color = Color(0.65, 0.72, 0.6)
	lcd.position = TRIES_LCD.position + Vector2(5, 5)
	lcd.size = TRIES_LCD.size - Vector2(10, 10)
	add_child(lcd)
	tries_label = _make_label(lcd.position + Vector2(10, 0), lcd.size - Vector2(20, 0), 30, HORIZONTAL_ALIGNMENT_CENTER, Color(0.2, 0.15, 0.05))
	hint = _make_label(Vector2(250, 170), Vector2(680, 50), 30, HORIZONTAL_ALIGNMENT_CENTER, Color8(250, 228, 180))
	hint.add_theme_color_override("font_outline_color", OUTLINE)
	hint.add_theme_constant_override("outline_size", 10)
	banner = _make_label(Vector2(0, 340), Vector2(PLAY_WIDTH, 120), 56, HORIZONTAL_ALIGNMENT_CENTER, Color(1, 0.97, 0.9))
	banner.add_theme_color_override("font_outline_color", OUTLINE)
	banner.add_theme_constant_override("outline_size", 14)
	banner.modulate.a = 0.0

func _draw_cabinet() -> void:
	var c := canvas
	# back panel with soft stripes
	for i in 12:
		c.draw_rect(Rect2(i * 80, 80, 40, 860), Color8(96, 54, 96))
	# glass glints
	c.draw_line(Vector2(270, 240), Vector2(390, 120), Color8(140, 100, 140), 9)
	c.draw_line(Vector2(300, 270), Vector2(360, 210), Color8(140, 100, 140), 6)
	# marquee: chasing bulbs all along it (except behind the tries screen)
	c.draw_rect(Rect2(0, 0, PLAY_WIDTH, 80), GOLD)
	c.draw_rect(Rect2(0, 0, PLAY_WIDTH, 12), Color8(255, 228, 150))
	c.draw_rect(Rect2(0, 66, PLAY_WIDTH, 9), GOLD_LO)
	c.draw_rect(Rect2(0, 74, PLAY_WIDTH, 9), OUTLINE)
	var step := int(_clock * 5.0)
	var x0 := TRIES_LCD.end.x + 30.0
	var n := int((PLAY_WIDTH - 24.0 - x0) / 30.0) + 1
	for i in n:
		var on := (i + step) % 3 == 0
		var p := Vector2(x0 + i * 30, 39)
		c.draw_circle(p, 9, OUTLINE)
		c.draw_circle(p, 6, Color8(255, 250, 220) if on else Color8(200, 120, 70))
		if on:
			c.draw_rect(Rect2(p - Vector2(3, 3), Vector2(3, 3)), Color.WHITE)
	# rail
	c.draw_rect(Rect2(36, RAIL_Y - 9, 880, 18), OUTLINE)
	c.draw_rect(Rect2(39, RAIL_Y - 6, 874, 12), Color8(196, 196, 210))
	c.draw_rect(Rect2(39, RAIL_Y - 6, 874, 3), Color8(240, 240, 250))
	# pit floor (perspective: the back edge is higher and narrower)
	var floor_poly := PackedVector2Array([Vector2(258, FLOOR_BACK - 24), Vector2(918, FLOOR_BACK - 24), Vector2(945, 940), Vector2(234, 940)])
	c.draw_colored_polygon(floor_poly, Color8(104, 66, 106))
	# soft felt rows, closer together towards the back (depth)
	for r in 6:
		var t := float(r + 1) / 7.0
		var y := lerpf(FLOOR_BACK - 24, 906, t * t)
		c.draw_line(Vector2(lerpf(258, 234, t * t) + 6, y), Vector2(lerpf(918, 945, t * t) - 6, y), Color8(116, 76, 118), 3)
	c.draw_line(Vector2(258, FLOOR_BACK - 24), Vector2(918, FLOOR_BACK - 24), Color8(156, 114, 156), 6)
	# front glass lip
	c.draw_rect(Rect2(234, 906, 716, 36), GOLD_LO)
	c.draw_rect(Rect2(234, 906, 716, 6), GOLD)

## The prize box: gold cabinet with a dark funnel mouth on top, bevels, rivets, a star and
## the frame of the glass flap (the flap's inside stays open for the prize to show)
func _draw_prize_box(cv: Control) -> void:
	var w := cv.size.x
	var h := cv.size.y
	var win := Rect2(CHUTE_WINDOW.position - cv.position, CHUTE_WINDOW.size)
	var hi := Color8(255, 228, 150)
	# body (around the flap: four pieces, so the window stays see-through)
	var body := [Rect2(0, 0, w, win.position.y), Rect2(0, win.end.y, w, h - win.end.y),
		Rect2(0, win.position.y, win.position.x, win.size.y), Rect2(win.end.x, win.position.y, w - win.end.x, win.size.y)]
	for r in body:
		cv.draw_rect(r, OUTLINE)
	for r in body:
		cv.draw_rect(r.intersection(Rect2(6, 6, w - 12, h - 12)), GOLD)
	cv.draw_rect(Rect2(6, 6, 9, h - 12), hi)                         # lit left side
	cv.draw_rect(Rect2(w - 15, 6, 9, h - 12), GOLD_LO)               # shaded right side
	# the funnel mouth on top: a dark opening with a steel rim
	cv.draw_rect(Rect2(6, 6, w - 12, 30), Color8(150, 148, 166))
	cv.draw_rect(Rect2(6, 6, w - 12, 6), Color8(220, 220, 232))
	cv.draw_rect(Rect2(18, 15, w - 36, 15), Color8(30, 16, 30))
	cv.draw_rect(Rect2(6, 36, w - 12, 6), OUTLINE)
	# a big star on the front, with its shadow
	var star_c := Vector2(w / 2.0, 120)
	_draw_star(cv, star_c + Vector2(6, 6), 46, GOLD_LO)
	_draw_star(cv, star_c, 46, OUTLINE)
	_draw_star(cv, star_c, 36, Color8(246, 150, 180))
	_draw_star(cv, star_c + Vector2(-6, -6), 15, Color8(255, 206, 220))
	# rivets
	for p in [Vector2(24, 54), Vector2(w - 30, 54), Vector2(24, h - 30), Vector2(w - 30, h - 30)]:
		cv.draw_rect(Rect2(p, Vector2(9, 9)), GOLD_LO)
		cv.draw_rect(Rect2(p, Vector2(3, 3)), hi)
	# the flap's frame: a dark rim, a lip below to grab it
	cv.draw_rect(Rect2(win.position - Vector2(9, 9), win.size + Vector2(18, 18)), OUTLINE, false, 6.0)
	cv.draw_rect(Rect2(win.position.x - 6, win.position.y - 12, win.size.x + 12, 6), GOLD_LO)
	cv.draw_rect(Rect2(win.position.x + win.size.x / 2.0 - 24, win.end.y + 9, 48, 9), Color8(150, 148, 166))
	cv.draw_rect(Rect2(win.position.x + win.size.x / 2.0 - 24, win.end.y + 9, 48, 3), Color8(220, 220, 232))
	# the dark space inside, behind the prize
	cv.draw_rect(win, Color8(46, 26, 46))
	cv.draw_rect(Rect2(win.position, Vector2(win.size.x, 12)), Color8(30, 16, 30))

func _draw_star(cv: Control, c: Vector2, r: float, col: Color) -> void:
	var pts := PackedVector2Array()
	for i in 10:
		var a := -PI / 2.0 + i * PI / 5.0
		pts.append(c + Vector2.from_angle(a) * (r if i % 2 == 0 else r * 0.45))
	cv.draw_colored_polygon(pts, col)

## The glass flap over the prize: a light tint and two glints (see-through)
func _draw_flap_glass(cv: Control) -> void:
	var w := cv.size.x
	var h := cv.size.y
	cv.draw_rect(Rect2(0, 0, w, h), Color(0.8, 0.9, 1.0, 0.12))
	cv.draw_colored_polygon(PackedVector2Array([Vector2(18, h), Vector2(48, h), Vector2(96, 0), Vector2(66, 0)]), Color(1, 1, 1, 0.16))
	cv.draw_colored_polygon(PackedVector2Array([Vector2(60, h), Vector2(72, h), Vector2(120, 0), Vector2(108, 0)]), Color(1, 1, 1, 0.12))
	cv.draw_rect(Rect2(0, 0, w, 6), Color(1, 1, 1, 0.25))
	# hinges at the top
	for x in [12.0, w - 30.0]:
		cv.draw_rect(Rect2(x, -6, 18, 9), Color8(150, 148, 166))
		cv.draw_rect(Rect2(x, -6, 18, 3), Color8(220, 220, 232))

static func _oval_texture() -> Texture2D:
	var img := Image.create(24, 10, false, Image.FORMAT_RGBA8)
	for y in 10:
		for x in 24:
			var dx := (x + 0.5 - 12.0) / 12.0
			var dy := (y + 0.5 - 5.0) / 5.0
			if dx * dx + dy * dy <= 1.0:
				img.set_pixel(x, y, Color.WHITE)
	return ImageTexture.create_from_image(img)

# ================================================================== HUD / FX

func _refresh_tries() -> void:
	tries_label.text = "TRIES %d" % LuckyPinch.tries

func _make_label(pos: Vector2, sz: Vector2, font_size: int, align: int, color: Color) -> Label:
	var l := Label.new()
	l.position = pos
	l.size = sz
	l.horizontal_alignment = align
	l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	if lcd_font:
		l.add_theme_font_override("font", lcd_font)
	l.add_theme_font_size_override("font_size", font_size)
	l.add_theme_color_override("font_color", color)
	add_child(l)
	return l

func _show_banner(text: String, hold: float) -> void:
	banner.text = text
	move_child(banner, get_child_count() - 1)
	var t := create_tween()
	t.tween_property(banner, "modulate:a", 1.0, 0.12)
	t.tween_interval(hold)
	t.tween_property(banner, "modulate:a", 0.0, 0.3)

func _float_text(text: String, at: Vector2) -> void:
	var l := _make_label(at + Vector2(-80, -20), Vector2(160, 40), 28, HORIZONTAL_ALIGNMENT_CENTER, Color(1, 0.95, 0.85))
	l.add_theme_color_override("font_outline_color", OUTLINE)
	l.add_theme_constant_override("outline_size", 10)
	l.text = text
	var t := create_tween()
	t.tween_property(l, "position:y", l.position.y - 40, 0.7)
	t.parallel().tween_property(l, "modulate:a", 0.0, 0.7)
	t.tween_callback(l.queue_free)

func _spark(at: Vector2) -> void:
	var s := ColorRect.new()
	s.color = [Color8(255, 236, 150), Color8(255, 255, 255), Color8(246, 150, 180)][randi() % 3]
	s.size = Vector2(9, 9)
	s.position = at
	prize_layer.add_child(s)
	var dir := Vector2.from_angle(randf_range(-PI, 0)) * randf_range(80, 170)
	var t := s.create_tween()
	t.tween_property(s, "position", at + dir, 0.6).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)
	t.parallel().tween_property(s, "modulate:a", 0.0, 0.6)
	t.tween_callback(s.queue_free)

func _sfx(path: String, volume_db: float) -> void:
	var stream = load(path) as AudioStream
	if not stream:
		return
	var sfx := AudioStreamPlayer.new()
	sfx.stream = stream
	sfx.volume_db = volume_db
	add_child(sfx)
	sfx.play()
	sfx.finished.connect(sfx.queue_free)

func _motor(on: bool) -> void:
	if on:
		if not motor:
			motor = AudioStreamPlayer.new()
			motor.stream = load("res://sounds/fx/Retro-Vehicle-Motor-02.mp3")
			motor.volume_db = -20.0
			motor.pitch_scale = 1.6
			add_child(motor)
		if not motor.playing:
			motor.play()
	elif motor:
		motor.stop()

# ================================================================== INPUT

func on_main_button_pressed() -> void:
	if is_game_over:
		super.on_main_button_pressed()
		return
	main_down = true
	if phase == P.READY and is_running:
		phase = P.MOVE_X
		hint.text = ""
		_motor(true)

func on_main_button_released() -> void:
	main_down = false

func on_forward_button_down() -> void:
	fwd_down = true
	if phase == P.WAIT_D and is_running:
		phase = P.MOVE_D
		hint.text = ""
		_motor(true)

func on_forward_button_up() -> void:
	fwd_down = false

func on_forward_button_pressed() -> void:
	pass                                # (the game over screen has only Exit)

func freeze() -> void:
	super.freeze()
	_motor(false)

func _play_error_sound() -> void:
	pass                                # (the end of a bonus is no failure)

func _exit_tree() -> void:
	for c in LuckyPinch.pit:
		c.erase("node")                     # (the pile itself stays in LuckyPinch)
	# left halfway through the last try: the bonus is used up anyway
	if LuckyPinch.pending and LuckyPinch.tries <= 0 and phase != P.DONE:
		LuckyPinch.finish()
