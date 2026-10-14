extends Node2D
## Stickers for the case (CASE mode, on the device's back): a mini sticker book whose pull
## tab peeks in from the case's left edge. Drag the tab out (or press it) and the book opens
## on a page of pal stickers; the tabs on its top turn to another page (one per food family:
## its Sho and its 5 Chu). Drag a sticker out and the book tucks back to the side while you
## stick it anywhere on the case. Drop a sticker on the book's tab to store it again; a stuck
## sticker can be peeled off and moved, or stored, the same way.
##
## Stuck stickers are children of the case's sprite, so they come off with the case and
## are back on it when it goes on again. Created by DeviceFlip (a child of the back, above
## the case); DeviceFlip passes it the touches first while the case is on.

const BOOK := preload("res://textures/cases/book/book.png")   # (tools/art/case_stickers.py)
const FAMILIES := ["green", "sweet", "greasy", "spicy", "sour"]
const TAB := Rect2(476, 200, 84, 272)   # the pull tab, book coordinates (with some slack)
const TOP := -960.0 - 336.0         # the book's top edge (it is centred on the device)
const TUCKED := -476.0              # book x tucked: only its tab shows, at the case's left edge
const OPEN := 36.0                  # ...and open
const HIDDEN := -560.0              # ...and with no case on
const PEEK := 40.0                  # while a sticker is carried it peeks out this much more...
const GAPE := 110.0                 # ...and this much with the sticker over it (let go: stored)
const CELL := Vector2(200, 205)     # the page's slots: 2 columns, 3 rows
const FIRST := Vector2(152, 130)    # the first slot's middle, book coordinates
const PAGE_TAB_X := 40.0            # the page tabs on the book's top: the first's left edge...
const PAGE_TAB_STEP := 88.0         # ...and from one to the next
const PAGE_TAB_Y := -52.0           # ...their top (the page showing: its tab a little higher)
const PAGE_TAB_UP := 14.0
const LIFT := 1.12                  # a carried sticker, bigger (closer to you)
const AREA := Rect2(50, -1870, 980, 1820)    # where a sticker can sit on the case
const TILT := 8.0                   # a new sticker's random tilt, degrees

## (kept for the whole launch: the stickers stay put across scene reloads)
static var stored: Array = []       # the stickers in the book (pal ids)
static var placed: Array = []       # [{id, pos (from the case's middle), rot}]
static var stocked := false
static var page := 0                # the book's page (a family)

var case_sprite: Sprite2D
var book: Sprite2D
var slots: Node2D
var open := false
var mode := ""                      # "" / "book" (dragging it) / "pending" / "sticker" / "swallow"
var carried: Sprite2D
var pending: Sprite2D               # a sticker pressed in the book, not dragged yet
var carried_id := ""
var grab := Vector2.ZERO            # finger -> sticker centre
var press_at := Vector2.ZERO
var book_from := 0.0
var moved := false
var book_tween: Tween
var page_tabs: Array[Sprite2D] = []
var _textures := {}

func _ready() -> void:
	book = Sprite2D.new()
	book.texture = BOOK
	book.centered = false
	book.position = Vector2(HIDDEN, TOP)
	book.visible = false
	add_child(book)
	slots = Node2D.new()
	book.add_child(slots)
	for i in FAMILIES.size():
		var t := Sprite2D.new()
		t.texture = load("res://textures/cases/book/tab_%s.png" % FAMILIES[i])
		t.centered = false
		t.show_behind_parent = true                 # (their bottoms tucked under the book's top)
		book.add_child(t)
		page_tabs.append(t)
	if not stocked:
		stocked = true
		stored = _sorted(PetState.FORMS.keys().filter(func(id): return int(PetState.FORMS[id]["stage"]) <= 2))
	_fill_page()
	for p in placed:
		_stick_sprite(p)

## The case went on (the book's tab slides in) or is coming off (the book goes with it)
func show_book(on: bool) -> void:
	open = false
	if on:
		book.visible = true
		_slide(TUCKED, 0.35)
	else:
		_slide(HIDDEN, 0.25)
	if not on and carried:
		_store(carried_id, false)

func close() -> void:
	if open:
		open = false
		_slide(TUCKED, 0.25)

## A touch on the back while the case is on: true if it was the stickers'
func handle(event: InputEvent) -> bool:
	var mb := event as InputEventMouseButton
	var mm := event as InputEventMouseMotion
	if mb and mb.button_index == MOUSE_BUTTON_LEFT:
		var p := _pos(mb.position)
		if mb.pressed:
			return _press(p)
		if mode == "":
			return false
		_release(p)
		return true
	if mm and mode != "":
		if mm.button_mask & MOUSE_BUTTON_MASK_LEFT:
			_drag(_pos(mm.position))
		return true
	return false

func _press(p: Vector2) -> bool:
	press_at = p
	moved = false
	var lp := p - book.position
	if open:
		for i in page_tabs.size():
			if Rect2(page_tabs[i].position, page_tabs[i].texture.get_size()).has_point(lp) and lp.y < 8.0:
				if page != i:
					page = i
					_fill_page()
					_sound("res://sounds/fx/film_peel.wav", -16.0, 1.8)
				mode = "swallow"
				return true
	if open and Rect2(Vector2.ZERO, BOOK.get_size()).has_point(lp):
		for s in slots.get_children():
			if _hit(s, p):
				pending = s                                 # (it comes out once the finger moves)
				mode = "pending"
				return true
		_start_book_drag()
		return true
	if not open and TAB.has_point(lp):
		_start_book_drag()
		return true
	if open:
		close()                                         # (a press anywhere else: put it away)
		mode = "swallow"
		return true
	var stuck := case_sprite.get_children()
	for i in range(stuck.size() - 1, -1, -1):           # (the top one first)
		var s: Sprite2D = stuck[i]
		if s.has_meta("data") and _hit(s, p):
			placed.erase(s.get_meta("data"))
			var gp: Vector2 = s.global_position
			case_sprite.remove_child(s)
			_carry(s, gp, p, s.rotation_degrees)
			_sound("res://sounds/fx/film_peel.wav", -10.0, 1.3)
			_slide(TUCKED + PEEK, 0.2)
			return true
	return false

func _start_book_drag() -> void:
	mode = "book"
	book_from = book.position.x
	if book_tween:
		book_tween.kill()

func _drag(p: Vector2) -> void:
	if p.distance_to(press_at) > 14.0:
		moved = true
	if mode == "pending" and moved:
		_take_out(pending, p)
	if mode == "book":
		book.position.x = clampf(book_from + p.x - press_at.x, TUCKED, OPEN)
	elif mode == "sticker":
		carried.position = p + grab
		var over := _over_book(p)
		var x := TUCKED + (GAPE if over else PEEK)
		if absf(book.position.x - x) > 1.0 and (book_tween == null or not book_tween.is_running()):
			_slide(x, 0.12)

func _release(p: Vector2) -> void:
	var m := mode
	mode = ""
	pending = null
	if m == "book":
		var go_open := not open if not moved else book.position.x > (TUCKED + OPEN) * 0.5 + (60.0 if open else -160.0)
		open = go_open
		_slide(OPEN if open else TUCKED, 0.25)
	elif m == "sticker":
		if _over_book(p) or not AREA.has_point(carried.position):
			_store(carried_id, true)
		else:
			_place()
		_slide(TUCKED, 0.25)

## A sticker dragged out of the book: the book tucks back to the side, out of the way
func _take_out(s: Sprite2D, p: Vector2) -> void:
	pending = null
	var gp: Vector2 = s.global_position
	slots.remove_child(s)
	stored.erase(s.get_meta("id"))
	_carry(s, gp, press_at, randf_range(-TILT, TILT))
	carried.position = p + grab
	open = false
	_slide(TUCKED + PEEK, 0.25)
	_fill_page()

## Carry a sticker sprite with the finger (from the book or peeled off the case)
func _carry(s: Sprite2D, from: Vector2, p: Vector2, rot: float) -> void:
	add_child(s)
	s.global_position = from
	s.rotation_degrees = rot
	s.z_index = 5
	carried = s
	carried_id = s.get_meta("id")
	if s.texture != _tex(carried_id):                   # (out of the book: it grows to its stuck size)
		s.scale = Vector2.ONE * s.texture.get_size().x / _tex(carried_id).get_size().x
		s.texture = _tex(carried_id)
	grab = s.position - p
	mode = "sticker"
	var t := create_tween()
	t.tween_property(s, "scale", Vector2.ONE * LIFT, 0.12).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_shadow(s, true)

func _place() -> void:
	var s := carried
	carried = null
	var d := {"id": carried_id, "pos": (s.position - case_sprite.position).round(), "rot": s.rotation_degrees}
	placed.append(d)
	s.queue_free()
	var stuck := _stick_sprite(d)
	stuck.scale = Vector2.ONE * LIFT
	var t := create_tween()
	t.tween_property(stuck, "scale", Vector2.ONE * 0.96, 0.08)
	t.tween_property(stuck, "scale", Vector2.ONE, 0.1)
	_sound("res://sounds/fx/click-5.mp3", -12.0, 1.2)
	Input.vibrate_handheld(12)

## Back into the book: shrinks into its tab (animated) or straight away
func _store(id: String, animated: bool) -> void:
	var s := carried
	carried = null
	mode = ""
	stored.append(id)
	stored = _sorted(stored)
	page = maxi(0, FAMILIES.find(PetState.FORMS[id]["family"]))     # (the book on its page)
	if animated and s:
		var to := book.position + TAB.get_center()
		var t := create_tween().set_parallel(true)
		t.tween_property(s, "position", to, 0.18).set_ease(Tween.EASE_IN)
		t.tween_property(s, "scale", Vector2.ONE * 0.2, 0.18).set_ease(Tween.EASE_IN)
		t.chain().tween_callback(s.queue_free)
		_sound("res://sounds/fx/click-6.mp3", -12.0, 0.9)
	elif s:
		s.queue_free()
	_fill_page()

func _stick_sprite(d: Dictionary) -> Sprite2D:
	var s := _sticker(d.id)
	s.position = d.pos
	s.rotation_degrees = d.rot
	s.set_meta("data", d)
	case_sprite.add_child(s)
	_shadow(s, false)
	return s

func _sticker(id: String, small := false) -> Sprite2D:
	var s := Sprite2D.new()
	s.texture = _tex(("book/" if small else "") + id)
	s.set_meta("id", id)
	return s

## A soft shadow under a sticker: a little lower and wider when it is lifted
func _shadow(s: Sprite2D, lifted: bool) -> void:
	var sh := s.get_node_or_null("Shadow") as Sprite2D
	if not sh:
		sh = Sprite2D.new()
		sh.name = "Shadow"
		sh.texture = s.texture
		sh.show_behind_parent = true
		s.add_child(sh)
	sh.modulate = Color(0.1, 0.18, 0.15, 0.32 if lifted else 0.22)
	sh.position = Vector2(6, 14) if lifted else Vector2(3, 5)

func _fill_page() -> void:
	for c in slots.get_children():
		c.queue_free()
	var here := stored.filter(func(id): return PetState.FORMS[id]["family"] == FAMILIES[page])
	for i in here.size():
		var s := _sticker(here[i], true)
		s.position = FIRST + Vector2(i % 2, i / 2) * CELL
		slots.add_child(s)
	for i in page_tabs.size():
		page_tabs[i].position = Vector2(PAGE_TAB_X + i * PAGE_TAB_STEP, PAGE_TAB_Y - (PAGE_TAB_UP if i == page else 0.0))
		page_tabs[i].modulate = Color.WHITE if i == page else Color(0.86, 0.86, 0.86)

## Pal ids in the Pal-Pedia's order
func _sorted(ids: Array) -> Array:
	var out := ids.duplicate()
	out.sort_custom(func(a, b): return int(PetState.FORMS[a]["no"]) < int(PetState.FORMS[b]["no"]))
	return out

func _hit(s: Sprite2D, p: Vector2) -> bool:
	var local := s.get_global_transform_with_canvas().affine_inverse() * (get_global_transform_with_canvas() * p)
	var r := Rect2(-s.texture.get_size() * 0.5, s.texture.get_size())
	if not r.has_point(local):
		return false
	var img: Image = s.texture.get_image()
	var px := Vector2i(local - r.position)
	return img.get_pixelv(px.clamp(Vector2i.ZERO, img.get_size() - Vector2i.ONE)).a > 0.1 or r.grow(-24).has_point(local)

## The finger over the book's tab (with room to spare): letting go there stores the sticker
func _over_book(p: Vector2) -> bool:
	return p.x < book.position.x + TAB.end.x + 40.0 and absf(p.y - (TOP + TAB.get_center().y)) < 240.0

func _slide(x: float, time: float) -> void:
	if book_tween:
		book_tween.kill()
	book_tween = create_tween()
	book_tween.tween_property(book, "position:x", x, time).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	if x == HIDDEN:
		book_tween.tween_callback(func(): book.visible = false)

func _pos(screen: Vector2) -> Vector2:
	return get_global_transform_with_canvas().affine_inverse() * screen

func _tex(id: String) -> Texture2D:
	if not _textures.has(id):
		_textures[id] = load("res://textures/cases/stickers/%s.png" % id)
	return _textures[id]

func _sound(path: String, db: float, pitch: float) -> void:
	var a := AudioStreamPlayer.new()
	a.stream = load(path)
	a.volume_db = db
	a.pitch_scale = pitch
	add_child(a)
	a.play()
	a.finished.connect(a.queue_free)
