extends Node2D
## Gear-button menu: the player's collection.
##   Page 0  POOP-PEDIA   — every evolution line (baby -> adult); undiscovered pals are silhouettes.
##   Page 1  BACKGROUNDS  — hold the main button to equip; locked ones say how to get them.
## Same controls as the food menu: main button tap = next row, hold = confirm, forward = next page.
## Built in code on top of the existing golden frame (Menu/Sprite2D).

const PAGES := ["POOP-PEDIA", "BACKGROUNDS"]

# Evolution lines shown in the pedia: [baby, adult, hint shown while undiscovered, blurb once found]
const PEDIA_LINES := [
	["sprig", "broccolump", "Feed it greens...", "Grown on salads. Proudly fibrous."],
	["swirlet", "neapoolitan", "Something sweet...", "Three flavours, one cherry, zero regrets."],
	["nugget", "greasy_chonk", "Something greasy...", "Glistening. Content. Do not squeeze."],
]

# Inner (brown) area of the golden frame, in Menu-local coordinates
const INNER := Rect2(695, -1182, 658, 641)

const CREAM := Color8(250, 244, 214)
const CARD_BORDER := Color8(58, 38, 30)
const SELECT_BORDER := Color8(214, 86, 128)
const ICON_BOX := Color8(218, 176, 128)
const TEXT := Color(0.65098, 0.505882, 0.368627)
const TEXT_DARK := Color8(74, 48, 34)

var page := 0
var selection := -1
var rows: Array[Control] = []
var content: Node2D
var title: Label
var status: Label
var dots: Array[TextureRect] = []
var font: Font

func _ready() -> void:
	font = load("res://fonts/Pixellari.ttf")
	var menu := get_node("Menu")
	content = Node2D.new()
	content.z_index = 2
	menu.add_child(content)

	title = _label(Vector2(INNER.position.x, INNER.position.y + 8), Vector2(INNER.size.x, 70), 54, CREAM, menu)
	title.add_theme_color_override("font_outline_color", CARD_BORDER)
	title.add_theme_constant_override("outline_size", 12)
	status = _label(Vector2(INNER.position.x + 20, INNER.end.y - 78), Vector2(INNER.size.x - 40, 70), 32, CREAM, menu)
	status.add_theme_color_override("font_outline_color", CARD_BORDER)
	status.add_theme_constant_override("outline_size", 8)
	status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART

	# Page dots + forward hint, like the food menu
	var dot_tex := load("res://textures/menus/dot1.png")
	for i in PAGES.size():
		var d := TextureRect.new()
		d.texture = dot_tex
		d.position = Vector2(1144.6 + 40 * i, -490)
		d.size = Vector2(27, 27)
		d.z_index = 2
		menu.add_child(d)
		dots.append(d)
	var hint := Sprite2D.new()
	hint.texture = load("res://textures/buttons/logoforward.png")
	hint.position = Vector2(1272.61, -476)
	hint.scale = Vector2(1.16715, 1.00655)
	hint.z_index = 2
	menu.add_child(hint)

	Collection.background_changed.connect(func(_id): _apply_background())
	_apply_background()
	show_page(0)

# ------------------------------------------------------------------ MENU INTERFACE (main/forward buttons)

func show_page(index: int) -> void:
	page = index
	selection = -1
	title.text = PAGES[page]
	for i in dots.size():
		dots[i].modulate = Color(1, 1, 1, 1) if i == page else Color(1, 1, 1, 0.3)
	_build_rows()
	_update_status()

func flip_page() -> void:
	show_page((page + 1) % PAGES.size())

func select_next() -> void:
	if rows.is_empty():
		return
	selection = (selection + 1) % rows.size()
	_update_selection()
	_update_status()

func get_selected_option() -> Node:
	if selection >= 0 and selection < rows.size():
		return rows[selection]
	return null

func reset_selection() -> void:
	selection = -1
	_update_selection()
	_update_status()

func reset_active_options() -> void:
	show_page(page)  # rebuild: discoveries / unlocks may have changed

func confirm_selected(sel: Node) -> void:
	if page != 1 or sel == null:
		return
	var id: String = sel.get_meta("id", "")
	if Collection.equip_background(id):
		_sfx("res://sounds/fx/gamecoin.wav", -8.0)
		var keep := selection
		_build_rows()
		selection = keep
		_update_selection()
		_update_status()
	else:
		_sfx("res://sounds/fx/error.mp3", -10.0)

# ------------------------------------------------------------------ ROWS

func _build_rows() -> void:
	for c in content.get_children():
		c.queue_free()
	rows.clear()
	var count := PEDIA_LINES.size() if page == 0 else Collection.BACKGROUND_ORDER.size()
	for i in count:
		var row := _card(Vector2(INNER.position.x + 29, INNER.position.y + 92 + i * 158), Vector2(600, 142))
		content.add_child(row)
		rows.append(row)
		if page == 0:
			_fill_pedia_row(row, PEDIA_LINES[i])
		else:
			_fill_background_row(row, Collection.BACKGROUND_ORDER[i])
	_update_selection()

func _fill_pedia_row(row: Control, line: Array) -> void:
	_pal_slot(row, line[0], Vector2(14, 14))
	var arrow := _label(Vector2(262, 40), Vector2(60, 60), 44, TEXT, row)
	arrow.text = ">"
	_pal_slot(row, line[1], Vector2(318, 14))

func _pal_slot(row: Control, id: String, at: Vector2) -> void:
	var found: bool = id in PetState.discovered
	var box := _icon_box(row, at)
	var tex := _form_icon(id)
	if tex:
		var icon := TextureRect.new()
		icon.texture = tex
		icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icon.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		icon.position = Vector2(8, 8)
		icon.size = Vector2(98, 98)
		icon.modulate = Color(1, 1, 1) if found else Color(0.1, 0.06, 0.05, 0.85)  # silhouette
		box.add_child(icon)
	var name_label := _label(at + Vector2(118, 0), Vector2(150, 114), 32, TEXT, row)
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	name_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	name_label.text = PetState.FORMS[id]["name"] if found else "???"

func _fill_background_row(row: Control, id: String) -> void:
	var bg: Dictionary = Collection.BACKGROUNDS[id]
	var owned := Collection.is_owned("backgrounds", id)
	row.set_meta("id", id)
	var box := _icon_box(row, Vector2(14, 14))
	var icon := TextureRect.new()
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	icon.position = Vector2(6, 6)
	icon.size = Vector2(102, 102)
	icon.texture = _background_preview(bg["layers"]) if owned and not bg["layers"].is_empty() else load("res://textures/menus/mistery_pink.png")
	box.add_child(icon)
	_add_doughnut(row, box)

	var name_label := _label(Vector2(140, 14), Vector2(440, 60), 44, TEXT, row)
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	name_label.text = bg["name"]
	var state := _label(Vector2(140, 70), Vector2(440, 50), 32, TEXT_DARK, row)
	state.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	if not owned:
		state.text = "Locked - " + bg["unlock"]
	elif Collection.equipped_background == id:
		state.text = "In use"
		state.add_theme_color_override("font_color", SELECT_BORDER)
	else:
		state.text = "Hold to use"

func _update_selection() -> void:
	for i in rows.size():
		var sel := i == selection
		rows[i].scale = Vector2.ONE * (1.015 if sel else 1.0)
		(rows[i].get_theme_stylebox("panel") as StyleBoxFlat).border_color = SELECT_BORDER if sel else CARD_BORDER

func _update_status() -> void:
	if page == 0:
		var found := 0
		for line in PEDIA_LINES:
			for id in [line[0], line[1]]:
				if id in PetState.discovered:
					found += 1
		if selection < 0:
			status.text = "Discovered %d / %d" % [found, PEDIA_LINES.size() * 2]
		else:
			var line: Array = PEDIA_LINES[selection]
			status.text = line[3] if line[1] in PetState.discovered else line[2]
	else:
		status.text = "Tap to choose, hold to use"

# ------------------------------------------------------------------ BACKGROUND APPLY

func _apply_background() -> void:
	var layers: Array = Collection.BACKGROUNDS[Collection.equipped_background]["layers"]
	var far = get_node_or_null("../../PetBackground/CloudA")
	var near = get_node_or_null("../../PetBackground/CloudB")
	if far and layers.size() > 0:
		far.texture = load(layers[0])
	if near and layers.size() > 1:
		near.texture = load(layers[1])

# ------------------------------------------------------------------ BUILDERS

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

func _icon_box(row: Control, at: Vector2) -> Panel:
	var p := Panel.new()
	p.position = at
	p.size = Vector2(114, 114)
	p.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var sb := StyleBoxFlat.new()
	sb.bg_color = ICON_BOX
	sb.set_corner_radius_all(8)
	sb.anti_aliasing = false
	p.add_theme_stylebox_override("panel", sb)
	row.add_child(p)
	return p

func _add_doughnut(row: Control, box: Control) -> void:
	# Hold-to-confirm ring (main_button looks for a "Doughnut" child on the selected row)
	var d := TextureProgressBar.new()
	d.name = "Doughnut"
	d.fill_mode = TextureProgressBar.FILL_CLOCKWISE
	d.nine_patch_stretch = true
	d.texture_progress = load("res://textures/menus/circle.png")
	d.tint_under = Color(1, 1, 1, 0.56)
	d.tint_over = Color(1, 1, 1, 0.31)
	d.tint_progress = Color(0.894118, 0.576471, 0.376471, 1)
	d.position = box.position - Vector2(4, 2)
	d.size = Vector2(123, 119)
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
	row.add_child(d)

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
