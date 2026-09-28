extends Node2D
## Gear-button menu: a hub of cards, each opening its own view.
##
##   HUB          cards: Poop-Pedia, Backgrounds, (future) Collectables
##   PEDIA        grid of pals, 9 per page, many pages; hold a pal to open its card
##   DETAIL       one pal's card: number, name, description / hint, evolution link
##   BACKGROUNDS  hold to equip (closes the menu, back to the pet)
##
## Controls, same everywhere: main button TAP = next item, HOLD = open / confirm,
## FORWARD = next page (in a pal card: next pal). Every sub-view has a "Back" item.
## Built in code on top of the existing golden frame (Menu/Sprite2D).

enum View { HUB, PEDIA, DETAIL, BACKGROUNDS }

const HUB_CARDS := [
	{ "view": View.PEDIA, "title": "Poop-Pedia", "sub": "Every pal you have met" },
	{ "view": View.BACKGROUNDS, "title": "Backgrounds", "sub": "Change the sky" },
	{ "view": -1, "title": "Collectables", "sub": "Coming soon" },
]
const PEDIA_PER_PAGE := 9

# Inner (brown) area of the golden frame, in Menu-local coordinates
const INNER := Rect2(695, -1182, 658, 641)

const CREAM := Color8(250, 244, 214)
const CARD_BORDER := Color8(58, 38, 30)
const SELECT_BORDER := Color8(214, 86, 128)
const ICON_BOX := Color8(218, 176, 128)
const TEXT := Color(0.65098, 0.505882, 0.368627)
const TEXT_DARK := Color8(74, 48, 34)

var view := View.HUB
var page := 0
var selection := -1
var items: Array[Control] = []     # selectable things in the current view, in tap order
var detail_id := ""
var return_selection := -1         # where to land when coming back from a pal card

var content: Node2D
var title: Label
var status: Label
var page_label: Label
var page_hint: Sprite2D
var font: Font

func _ready() -> void:
	font = load("res://fonts/Pixellari.ttf")
	var menu := get_node("Menu")
	content = Node2D.new()
	content.z_index = 2
	menu.add_child(content)

	title = _label(Vector2(INNER.position.x, INNER.position.y + 8), Vector2(INNER.size.x, 70), 54, CREAM, menu)
	_outline(title, 12)
	status = _label(Vector2(INNER.position.x + 180, INNER.end.y - 74), Vector2(INNER.size.x - 200, 66), 30, CREAM, menu)
	status.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_outline(status, 8)

	# Page indicator in the golden band, like the food menu's dots + forward hint
	page_label = _label(Vector2(1060, -505), Vector2(170, 56), 36, TEXT_DARK, menu)
	page_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	page_hint = Sprite2D.new()
	page_hint.texture = load("res://textures/buttons/logoforward.png")
	page_hint.position = Vector2(1272.61, -476)
	page_hint.scale = Vector2(1.16715, 1.00655)
	page_hint.z_index = 2
	menu.add_child(page_hint)

	Collection.background_changed.connect(func(_id): _apply_background())
	_apply_background()
	_open(View.HUB)

# ================================================================== MENU INTERFACE (main / forward buttons)

func select_next() -> void:
	if view == View.DETAIL:
		_open(View.PEDIA, return_selection)   # tap on a pal card = back to the grid
		return
	if items.is_empty():
		return
	selection = (selection + 1) % items.size()
	_refresh_selection()

func flip_page() -> void:
	match view:
		View.PEDIA:
			page = (page + 1) % _pedia_pages()
			_open(View.PEDIA)
		View.DETAIL:
			var order := PetState.pedia_order()
			var i := (order.find(detail_id) + 1) % order.size()
			return_selection = i % PEDIA_PER_PAGE
			page = i / PEDIA_PER_PAGE
			_show_detail(order[i])

func get_selected_option() -> Node:
	if selection >= 0 and selection < items.size():
		return items[selection]
	return null

func reset_selection() -> void:
	selection = -1
	_refresh_selection()

func reset_active_options() -> void:
	page = 0
	_open(View.HUB)   # every visit starts at the hub

## Hold on the selected item. Returns true when the menu should close (back to the pet).
func confirm_selected(sel: Node) -> bool:
	if sel == null:
		return false
	var action: Dictionary = sel.get_meta("action", {})
	match action.get("type", ""):
		"open":
			_click()
			page = 0
			_open(action["view"])
		"back":
			_click()
			var came_from := view
			_open(View.HUB, 0 if came_from == View.PEDIA else 1)
		"pal":
			_click()
			return_selection = selection
			_show_detail(action["id"])
		"bg":
			if Collection.equip_background(action["id"]):
				_sfx("res://sounds/fx/gamecoin.wav", -8.0)
				return true
			_sfx("res://sounds/fx/error.mp3", -10.0)
		_:
			_sfx("res://sounds/fx/error.mp3", -10.0)
	return false

# ================================================================== VIEWS

func _open(v: int, select := -1) -> void:
	view = v
	_clear()
	match v:
		View.HUB:
			_build_hub()
		View.PEDIA:
			_build_pedia()
		View.BACKGROUNDS:
			_build_backgrounds()
	selection = select if select < items.size() else -1
	_refresh_selection()
	_refresh_pager()

func _clear() -> void:
	for c in content.get_children():
		c.queue_free()
	items.clear()

func _build_hub() -> void:
	title.text = "MENU"
	status.text = "Tap to choose, hold to open"
	for i in HUB_CARDS.size():
		var info: Dictionary = HUB_CARDS[i]
		var row := _card(Vector2(INNER.position.x + 29, INNER.position.y + 92 + i * 158), Vector2(600, 142))
		var box := _icon_box(row, Vector2(14, 14), Vector2(114, 114))
		var locked: bool = info["view"] == -1
		var icon := _icon(box, _hub_icon(info["view"]), Vector2(102, 102))
		if locked:
			icon.texture = load("res://textures/menus/mistery_pink.png")
		_add_doughnut(row, box)
		var t := _label(Vector2(140, 14), Vector2(440, 60), 44, TEXT, row)
		t.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
		t.text = info["title"]
		_fit_one_line(t, 44)
		var sub := _label(Vector2(140, 70), Vector2(440, 50), 30, TEXT_DARK, row)
		sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
		sub.text = info["sub"]
		row.set_meta("action", { "type": "locked" } if locked else { "type": "open", "view": info["view"] })
		_add_item(row)

func _build_pedia() -> void:
	title.text = "POOP-PEDIA"
	var order := PetState.pedia_order()
	page = clampi(page, 0, _pedia_pages() - 1)
	var found := 0
	for id in order:
		if id in PetState.discovered:
			found += 1
	status.text = "Found %d / %d" % [found, order.size()]

	var cell := Vector2(196, 150)
	var gap := Vector2(10, 12)
	var origin := Vector2(INNER.position.x + (INNER.size.x - (3 * cell.x + 2 * gap.x)) / 2.0, INNER.position.y + 86)
	for slot in PEDIA_PER_PAGE:
		var i := page * PEDIA_PER_PAGE + slot
		if i >= order.size():
			break
		var id: String = order[i]
		var known: bool = id in PetState.discovered
		var pos := origin + Vector2(slot % 3, slot / 3) * (cell + gap)
		var c := _card(pos, cell)
		var box := _icon_box(c, Vector2((cell.x - 104) / 2.0, 10), Vector2(104, 92))
		var icon := _icon(box, _form_icon(id), Vector2(92, 82))
		if not known:
			icon.modulate = Color(0.1, 0.06, 0.05, 0.85)   # silhouette
		_add_doughnut(c, box)
		var n := _label(Vector2(6, 104), Vector2(cell.x - 12, 36), 26, TEXT, c)
		n.text = "%03d %s" % [PetState.FORMS[id]["no"], PetState.FORMS[id]["name"] if known else "???"]
		_fit_one_line(n, 26)
		c.set_meta("action", { "type": "pal", "id": id })
		_add_item(c)
	_add_back()

func _show_detail(id: String) -> void:
	view = View.DETAIL
	detail_id = id
	_clear()
	selection = -1
	var f: Dictionary = PetState.FORMS[id]
	var known: bool = id in PetState.discovered
	title.text = "#%03d" % f["no"]
	status.text = "Tap: back   >> next"

	var card := _card(Vector2(INNER.position.x + 24, INNER.position.y + 86), Vector2(INNER.size.x - 48, 470))
	content.add_child(card)
	var box := _icon_box(card, Vector2(24, 24), Vector2(220, 200))
	var icon := _icon(box, _form_icon(id), Vector2(196, 176))
	if not known:
		icon.modulate = Color(0.1, 0.06, 0.05, 0.85)

	var name_l := _label(Vector2(262, 30), Vector2(330, 70), 52, TEXT, card)
	name_l.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	name_l.text = f["name"] if known else "???"
	_fit_one_line(name_l, 52)
	var stage_l := _label(Vector2(262, 100), Vector2(330, 44), 30, TEXT_DARK, card)
	stage_l.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	stage_l.text = (("Baby" if f["stage"] == 1 else "Evolved") + " - " + str(f["family"]).capitalize()) if known else "Not found yet"
	_fit_one_line(stage_l, 30)
	var link := _label(Vector2(262, 150), Vector2(330, 74), 28, TEXT_DARK, card)
	link.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	link.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	link.text = _evolution_link(id) if known else ""

	var desc := _label(Vector2(24, 244), Vector2(card.size.x - 48, 200), 34, TEXT, card)
	desc.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	desc.vertical_alignment = VERTICAL_ALIGNMENT_TOP
	desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	desc.text = f["desc"] if known else f["hint"]
	_refresh_pager()

func _build_backgrounds() -> void:
	title.text = "BACKGROUNDS"
	status.text = "Hold to use"
	for i in Collection.BACKGROUND_ORDER.size():
		var id: String = Collection.BACKGROUND_ORDER[i]
		var bg: Dictionary = Collection.BACKGROUNDS[id]
		var owned := Collection.is_owned("backgrounds", id)
		var row := _card(Vector2(INNER.position.x + 29, INNER.position.y + 88 + i * 150), Vector2(600, 138))
		var box := _icon_box(row, Vector2(14, 12), Vector2(114, 110))
		var icon := _icon(box, null, Vector2(102, 98))
		icon.texture = _background_preview(bg["layers"]) if owned and not bg["layers"].is_empty() else load("res://textures/menus/mistery_pink.png")
		_add_doughnut(row, box)
		var t := _label(Vector2(140, 12), Vector2(440, 60), 44, TEXT, row)
		t.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
		t.text = bg["name"]
		_fit_one_line(t, 44)
		var st := _label(Vector2(140, 68), Vector2(440, 50), 30, TEXT_DARK, row)
		st.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
		if not owned:
			st.text = "Locked - " + bg["unlock"]
		elif Collection.equipped_background == id:
			st.text = "In use"
			st.add_theme_color_override("font_color", SELECT_BORDER)
		else:
			st.text = "Hold to use"
		row.set_meta("action", { "type": "bg", "id": id } if owned else { "type": "locked" })
		_add_item(row)
	_add_back()

func _add_back() -> void:
	var b := _card(Vector2(INNER.position.x + 24, INNER.end.y - 76), Vector2(150, 64))
	var l := _label(Vector2(0, 0), b.size, 32, TEXT, b)
	l.text = "< Back"
	# ring hugging the button for hold feedback
	var ring_anchor := Control.new()
	ring_anchor.position = Vector2(-4, -8)
	ring_anchor.size = Vector2(80, 80)
	ring_anchor.mouse_filter = Control.MOUSE_FILTER_IGNORE
	b.add_child(ring_anchor)
	_add_doughnut(b, ring_anchor)
	b.set_meta("action", { "type": "back" })
	_add_item(b)

func _add_item(c: Control) -> void:
	content.add_child(c)
	items.append(c)

func _refresh_selection() -> void:
	for i in items.size():
		var sel := i == selection
		items[i].scale = Vector2.ONE * (1.03 if sel else 1.0)
		(items[i].get_theme_stylebox("panel") as StyleBoxFlat).border_color = SELECT_BORDER if sel else CARD_BORDER

func _refresh_pager() -> void:
	var pages := _pedia_pages() if view in [View.PEDIA, View.DETAIL] else 1
	var many := view == View.PEDIA and pages > 1
	page_label.visible = many
	page_hint.visible = many or view == View.DETAIL
	page_label.text = "%d/%d" % [page + 1, pages]

func _pedia_pages() -> int:
	return maxi(1, ceili(PetState.FORMS.size() / float(PEDIA_PER_PAGE)))

func _evolution_link(id: String) -> String:
	var from: String = PetState.FORMS[id]["from"]
	if from != "":
		return "Evolves from " + (PetState.FORMS[from]["name"] if from in PetState.discovered else "???")
	for other in PetState.FORMS:
		if PetState.FORMS[other]["from"] == id:
			return "Evolves into " + (PetState.FORMS[other]["name"] if other in PetState.discovered else "???")
	return ""

func _hub_icon(v: int) -> Texture2D:
	match v:
		View.PEDIA:
			return _form_icon(PetState.form_id if PetState.has_poop() else "sprig")
		View.BACKGROUNDS:
			return _background_preview(Collection.BACKGROUNDS[Collection.equipped_background]["layers"])
	return null

# ================================================================== BACKGROUND APPLY

func _apply_background() -> void:
	var layers: Array = Collection.BACKGROUNDS[Collection.equipped_background]["layers"]
	var far = get_node_or_null("../../PetBackground/CloudA")
	var near = get_node_or_null("../../PetBackground/CloudB")
	if far and layers.size() > 0:
		far.texture = load(layers[0])
	if near and layers.size() > 1:
		near.texture = load(layers[1])

# ================================================================== BUILDERS

func _card(pos: Vector2, sz: Vector2) -> Panel:
	var p := Panel.new()
	p.position = pos
	p.size = sz
	p.pivot_offset = sz / 2.0
	p.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var sb := StyleBoxFlat.new()
	sb.bg_color = CREAM
	sb.border_color = CARD_BORDER
	sb.set_border_width_all(6)
	sb.border_width_bottom = 10     # thicker base, like the pixel cards
	sb.set_corner_radius_all(10)
	sb.anti_aliasing = false
	p.add_theme_stylebox_override("panel", sb)
	return p

func _icon_box(parent: Control, at: Vector2, sz: Vector2) -> Panel:
	var p := Panel.new()
	p.position = at
	p.size = sz
	p.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var sb := StyleBoxFlat.new()
	sb.bg_color = ICON_BOX
	sb.set_corner_radius_all(8)
	sb.anti_aliasing = false
	p.add_theme_stylebox_override("panel", sb)
	parent.add_child(p)
	return p

func _icon(box: Control, tex: Texture2D, sz: Vector2) -> TextureRect:
	var icon := TextureRect.new()
	icon.texture = tex
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	icon.size = sz
	icon.position = (box.size - sz) / 2.0
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_child(icon)
	return icon

func _add_doughnut(parent: Control, around: Control) -> void:
	# Hold-to-confirm ring (main_button looks for a "Doughnut" child on the selected item)
	var d := TextureProgressBar.new()
	d.name = "Doughnut"
	d.fill_mode = TextureProgressBar.FILL_CLOCKWISE
	d.nine_patch_stretch = true
	d.texture_progress = load("res://textures/menus/circle.png")
	d.tint_under = Color(1, 1, 1, 0.56)
	d.tint_over = Color(1, 1, 1, 0.31)
	d.tint_progress = Color(0.894118, 0.576471, 0.376471, 1)
	d.position = around.position - Vector2(6, 6)
	d.size = around.size + Vector2(12, 12)
	d.visible = false
	d.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var border := TextureProgressBar.new()
	border.name = "DoughnutBorder"
	border.fill_mode = TextureProgressBar.FILL_CLOCKWISE
	border.nine_patch_stretch = true
	border.texture_progress = load("res://textures/menus/circleborder.png")
	border.tint_progress = Color(0.290196, 0.184314, 0.121569, 1)
	border.set_anchors_preset(Control.PRESET_FULL_RECT)
	border.show_behind_parent = true
	border.mouse_filter = Control.MOUSE_FILTER_IGNORE
	d.add_child(border)
	parent.add_child(d)

func _label(pos: Vector2, sz: Vector2, font_size: int, color: Color, parent: Node) -> Label:
	var l := Label.new()
	l.position = pos
	l.size = sz
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	l.add_theme_font_override("font", font)
	l.add_theme_font_size_override("font_size", font_size)
	l.add_theme_color_override("font_color", color)
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if parent is Node2D:
		l.z_index = 2
	parent.add_child(l)
	return l

func _outline(l: Label, px: int) -> void:
	l.add_theme_color_override("font_outline_color", CARD_BORDER)
	l.add_theme_constant_override("outline_size", px)

## Keeps a label on one line: if the text is too wide, shrink the font until it fits.
func _fit_one_line(l: Label, max_size: int, min_size := 16) -> void:
	var size := max_size
	while size > min_size and font.get_string_size(l.text, HORIZONTAL_ALIGNMENT_LEFT, -1, size).x > l.size.x:
		size -= 1
	l.add_theme_font_size_override("font_size", size)

func _form_icon(id: String) -> Texture2D:
	var frames := PetState.build_sprite_frames(id)
	if not frames:
		return null
	var tex := frames.get_frame_texture("idle", 0)
	var img := tex.get_image()
	if img == null:
		return tex
	var atlas := AtlasTexture.new()
	atlas.atlas = tex
	atlas.region = Rect2(img.get_used_rect())
	return atlas

func _background_preview(layers: Array) -> Texture2D:
	var img := Image.create(200, 200, false, Image.FORMAT_RGBA8)
	img.fill(Color8(236, 170, 170))
	for path in layers:
		var layer_img: Image = (load(path) as Texture2D).get_image()
		if layer_img.is_compressed():
			layer_img.decompress()
		layer_img.convert(Image.FORMAT_RGBA8)
		img.blend_rect(layer_img, Rect2i(180, 90, 200, 200), Vector2i.ZERO)
	return ImageTexture.create_from_image(img)

func _click() -> void:
	_sfx("res://sounds/fx/click-5.mp3", -6.0)

func _sfx(path: String, volume_db: float) -> void:
	var stream = load(path) as AudioStream
	if not stream:
		return
	var sfx := AudioStreamPlayer.new()
	sfx.stream = stream
	sfx.volume_db = volume_db
	var sound_btn = get_node_or_null("/root/PoopPal/Main UI/SoundButtons/SoundButton")
	if sound_btn and sound_btn.button_pressed:
		sfx.volume_db = linear_to_db(0.0)
	add_child(sfx)
	sfx.play()
	sfx.finished.connect(sfx.queue_free)
