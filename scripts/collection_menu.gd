extends Node2D
## Gear-button menu: a hub of cards, each opening its own view.
##
##   HUB          one big card per menu, exactly like the Games menu (forward = next card,
##                page dots, hold = open). Cards are clones of the Games menu card.
##   PEDIA        grid of pals, 9 per page, many pages; hold a pal to open its card
##   DETAIL       one pal's card: number, name, description / hint, evolution link
##   SHOP         what coins buy besides games (Shop autoload): food types, adult foods, special
##                foods; the same food-menu cards, 3 a page; hold = buy. The coins you have on the
##                top-right corner, like the Games menu.
##   BACKGROUNDS / ACCESSORIES / DECOR  cosmetics lists: hold to use (closes the menu, back to the pet).
##                The cards are the food menu's cards (same frame, icon spot, name font, type tag),
##                3 per page in the same places, so every list in the app looks alike.
##
## Controls, same everywhere: main button TAP = next item, HOLD = open / confirm,
## FORWARD = next page (in a pal card: next pal). Every sub-view has a "Back" item.
## Built in code on top of the existing golden frame (Menu/Sprite2D).

enum View { HUB, PEDIA, DETAIL, BACKGROUNDS, ACCESSORIES, DECOR, SHOP }

const HUB_CARDS := [
	{ "view": View.PEDIA, "logo": "res://textures/menus/palpedia.png", "pattern": "res://textures/menus/pooploopbackground.png" },
	{ "view": View.SHOP, "logo": "res://textures/menus/coinshop.png", "pattern": "res://textures/menus/pattern_coin_caramel.png" },
	{ "view": View.ACCESSORIES, "logo": "res://textures/menus/dressup.png", "pattern": "res://textures/menus/pattern_glasses_cream.png" },
	{ "view": View.DECOR, "logo": "res://textures/menus/gutdecor.png", "pattern": "res://textures/menus/pattern_bulb_caramel.png" },
	{ "view": View.BACKGROUNDS, "logo": "res://textures/menus/backgrounds.png", "pattern": "res://textures/menus/pattern_cloud_sage.png" },
]
## Cosmetic list views: their Collection category
const LISTS := {
	View.BACKGROUNDS: { "category": "backgrounds" },
	View.ACCESSORIES: { "category": "accessories" },
	View.DECOR: { "category": "decor" },
}
## The type tag on backgrounds / gut decor cards (like the food types): word + pastel colour
const KIND_TAGS := {
	"complement": ["Add-on", Color8(180, 208, 226)],
	"color": ["Color", Color8(232, 182, 196)],
}
const PEDIA_PER_PAGE := 9
const LIST_PER_PAGE := 3              # cosmetics lists: forward flips pages, like the Games menu

# Inner (brown) area of the golden frame, in Menu-local coordinates
const INNER := Rect2(695, -1182, 658, 641)

const CREAM := Color8(250, 244, 214)
const CARD_BORDER := Color8(58, 38, 30)
const IN_USE := Color8(104, 128, 72)            # moss green: the item in use / NEW tags
const ICON_BOX := Color8(218, 176, 128)
const TEXT := Color(0.65098, 0.505882, 0.368627)
const TEXT_DARK := Color8(74, 48, 34)
const FRAME_DX := 6.24                  # this menu's frame sits 6 px right of the Food / Games ones

var view := View.HUB
var page := 0
var selection := -1
var items: Array[Control] = []     # selectable things in the current view, in tap order
var detail_id := ""
var return_selection := -1         # where to land when coming back from a pal card
var hub_index := 0                 # which hub card is showing

var hub_root: Node2D
var hub_cards: Array[Node] = []
var hub_dots: Node2D
var hub_hint: Node2D
var list_dots: Node2D              # page dots for the cosmetics lists (like the Games menu)
var _list_dots_x0 := 0.0

var content: Node2D
var title: Label
var status: Label
var page_label: Label
var page_hint: Sprite2D
var legend: MenuLegend
var detail_legend: Node2D          # pal card controls, in the golden band: (o) back   next >>
var font: Font
var coin_tag: PanelContainer       # the coins you have (Shop view and its hub card)
var coin_tag_label: Label

func _ready() -> void:
	font = load("res://fonts/Pixellari.ttf")
	var menu := get_node("Menu")
	content = Node2D.new()
	content.z_index = 2
	menu.add_child(content)

	title = _label(Vector2(INNER.position.x, INNER.position.y + 8), Vector2(INNER.size.x, 70), 54, CREAM, menu)
	_outline(title, 12)
	status = _label(Vector2(INNER.position.x + 20, INNER.end.y - 78), Vector2(INNER.size.x - 40, 70), 40, CREAM, menu)
	status.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_outline(status, 8)

	# Page indicator in the golden band, like the food menu's dots + forward hint
	page_label = _label(Vector2(1060, -505), Vector2(170, 56), 36, TEXT_DARK, menu)
	page_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	page_hint = Sprite2D.new()
	page_hint.texture = load("res://textures/buttons/logoforward.png")
	page_hint.position = Vector2(MenuLegend.forward_center_x(FRAME_DX), -459.082)   # (the band layout: MenuLegend)
	page_hint.scale = Vector2(1.16715, 1.00655)
	page_hint.z_index = 2
	menu.add_child(page_hint)

	# Pal card legend: a mini main button = back, the forward icon (page_hint) = next
	detail_legend = Node2D.new()
	detail_legend.z_index = 2
	detail_legend.visible = false
	menu.add_child(detail_legend)
	legend = MenuLegend.attach(menu, menu.get_node_or_null("Sprite2D"), FRAME_DX)     # the orange button's controls, left of the bottom band
	var mini := Sprite2D.new()
	mini.texture = load("res://textures/buttons/mainbuttonnormal.png")
	mini.scale = Vector2(0.26, 0.26)
	mini.position = Vector2(1024, -459)         # centre of the frame's bottom band
	detail_legend.add_child(mini)
	var back_l := _label(Vector2(1054, -483), Vector2(90, 48), 32, TEXT_DARK, detail_legend)
	back_l.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	back_l.text = "back"
	var next_l := _label(Vector2(1150, -483), Vector2(90, 48), 32, TEXT_DARK, detail_legend)
	next_l.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	next_l.text = "next"

	_build_hub_cards(menu)
	_build_coin_tag(menu)
	GameData.coins_changed.connect(func(_c): _refresh_coin_tag())
	Shop.changed.connect(func():
		if view == View.SHOP:
			_open(View.SHOP, selection))

	# Always reopen on the card hub: reset as soon as the menu is hidden (not when it's shown,
	# or the last list flashes for a moment while the menu slides in)
	visibility_changed.connect(func():
		if not visible and view != View.HUB:
			page = 0
			_open(View.HUB))
	Collection.background_changed.connect(func(_id): _apply_background())
	_apply_background()
	_open(View.HUB)

# ================================================================== MENU INTERFACE (main / forward buttons)

func select_next() -> void:
	if view == View.HUB:
		return   # like the Games menu: forward flips cards, hold opens
	if view == View.DETAIL:
		_open(View.PEDIA, return_selection)   # tap on a pal card = back to the grid
		return
	if items.is_empty():
		return
	selection = (selection + 1) % items.size()
	_refresh_selection()

func flip_page() -> void:
	match view:
		View.HUB:
			hub_index = (hub_index + 1) % hub_cards.size()
			_open(View.HUB)
		View.PEDIA:
			page = (page + 1) % _pedia_pages()
			_open(View.PEDIA)
		View.BACKGROUNDS, View.ACCESSORIES, View.DECOR:
			page = (page + 1) % _list_pages(view)
			_open(view)
		View.SHOP:
			page = (page + 1) % _shop_pages()
			_open(View.SHOP)
		View.DETAIL:
			var order := PetState.pedia_order()
			var i := (order.find(detail_id) + 1) % order.size()
			return_selection = i % PEDIA_PER_PAGE
			page = i / PEDIA_PER_PAGE
			_show_detail(order[i])

func get_selected_option() -> Node:
	if view == View.HUB:
		return hub_cards[hub_index]
	if selection >= 0 and selection < items.size():
		return items[selection]
	return null

func reset_selection() -> void:
	selection = -1
	_refresh_selection()

func reset_active_options() -> void:
	page = 0
	_open(View.HUB)   # every visit starts at the hub

## Asked by the main button before the OK sound: false = refuse (it plays a soft error)
func can_confirm(sel: Node) -> bool:
	var action: Dictionary = sel.get_meta("action", {}) if sel else {}
	if action.get("type", "") == "open" and action.get("view", -1) == View.ACCESSORIES and not PetState.has_poop():
		_point_to_food()          # nobody to dress yet: feed the pal first
		return false
	return true

## Hold on the selected item. Returns true when the menu should close (back to the pet).
func confirm_selected(sel: Node) -> bool:
	if sel == null:
		return false
	var action: Dictionary = sel.get_meta("action", {})
	match action.get("type", ""):
		"open":
			page = 0              # (the card's own ConfirmSound already played)
			_open(action["view"])
		"back":
			_click()
			_open(View.HUB)
		"pal":
			_click()
			return_selection = selection
			_show_detail(action["id"])
		"equip":
			if Collection.equip(action["category"], action["id"]):
				_sfx("res://sounds/fx/gamecoin.wav", -8.0)
				return true
			_sfx("res://sounds/fx/error.mp3", -10.0)
		"buy":
			if Shop.buy(action["id"]):
				_sfx("res://sounds/fx/claw_prize.wav", -8.0)
				_bought_pop(sel)
			else:
				_sfx("res://sounds/fx/error.mp3", -10.0)
				Input.vibrate_handheld(40)
		_:
			_sfx("res://sounds/fx/error.mp3", -10.0)
	return false

# ================================================================== VIEWS

func _open(v: int, select := -1) -> void:
	view = v
	_clear()
	var in_hub := v == View.HUB
	if legend:
		if in_hub:
			legend.set_lines([["hold", "open"]])
		elif v == View.DETAIL:
			legend.set_lines([])             # (a pal card has its own back / next legend)
		else:
			legend.set_lines([["press", "next"], ["hold", "buy" if v == View.SHOP else "pick"]])
	hub_root.visible = in_hub
	hub_dots.visible = in_hub
	hub_hint.visible = in_hub
	if coin_tag:
		coin_tag.visible = v == View.SHOP or (in_hub and HUB_CARDS[hub_index]["view"] == View.SHOP)
	# (the lists are just cards, like the food menu: no title, no hint line)
	title.visible = v in [View.PEDIA, View.DETAIL]
	status.visible = v in [View.PEDIA, View.DETAIL]
	match v:
		View.HUB:
			_build_hub()
		View.PEDIA:
			_build_pedia()
		View.BACKGROUNDS, View.ACCESSORIES, View.DECOR:
			_build_list(v)
		View.SHOP:
			_build_shop()
	selection = select if select < items.size() else -1
	_refresh_selection()
	_refresh_pager()

func _clear() -> void:
	for c in content.get_children():
		c.queue_free()
	items.clear()

func _build_hub_cards(menu: Node) -> void:
	## Clone the Games menu card (frame, scrolling pattern, logo, info panel, hold ring,
	## confirm sound) and its page dots / forward hint, so both menus look identical.
	var games := get_node("../GameMenu/Menu")
	hub_root = Node2D.new()
	menu.add_child(hub_root)
	var template := games.get_node("VBoxGame1/Game")
	for info in HUB_CARDS:
		var card := template.duplicate()
		card.get_node("TopFrame/Control/GameLogo").texture = load(info["logo"])
		card.get_node("TopFrame/Control/Background").texture = load(info["pattern"])
		card.set_meta("action", { "type": "open", "view": info["view"] })
		# "NEW!" tag on the top-right corner of the picture: something was unlocked inside
		var badge := _new_badge(38)
		badge.position = Vector2(1175, -1190)
		badge.name = "NewBadge"
		card.add_child(badge)
		hub_root.add_child(card)
		hub_cards.append(card)

	hub_hint = games.get_node("ForwardHint").duplicate()
	menu.add_child(hub_hint)
	hub_dots = games.get_node("Dots").duplicate()
	menu.add_child(hub_dots)
	var dots := hub_dots.get_children()
	for i in range(dots.size() - 1, HUB_CARDS.size() - 1, -1):
		dots[i].queue_free()
	# like the Games and Food menus: the last dot sits right before the forward sign
	hub_hint.position.x = MenuLegend.forward_center_x(FRAME_DX)
	MenuLegend.layout_dots(dots, HUB_CARDS.size(), FRAME_DX)
	# a second, full set of dots for the list pages (shown only when a list has 2+ pages)
	list_dots = games.get_node("Dots").duplicate()
	list_dots.visible = false
	menu.add_child(list_dots)
	_list_dots_x0 = list_dots.position.x

func _build_hub() -> void:
	for i in hub_cards.size():
		hub_cards[i].visible = i == hub_index
	var dots := hub_dots.get_children()
	for i in HUB_CARDS.size():
		dots[i].modulate = Color(1, 1, 1, 1) if i == hub_index else Color(1, 1, 1, 0.3)
	_update_hub_card_info()

func _update_hub_card_info() -> void:
	# Info panel = the Games card's "Max Score / Progress" lines
	var order := PetState.pedia_order()
	var found := 0
	for id in order:
		if id in PetState.discovered:
			found += 1
	var lines := {
		View.PEDIA: ["Found", "%d/%d" % [found, order.size()], "Progress", "%d%%" % int(100.0 * found / maxf(order.size(), 1))],
	}
	for v in LISTS:
		var cat: String = LISTS[v]["category"]
		var owned := 0
		for id in Collection.order(cat):
			if Collection.is_owned(cat, id):
				owned += 1
		var cat_catalog := Collection.catalog(cat)
		lines[v] = ["Unlocked", "%d/%d" % [owned, Collection.order(cat).size()], "In use", Collection.in_use_label(cat)]
	# the Shop card: what's on sale, and the coins you have
	var on_sale := 0
	for it in Shop.ITEMS:
		if Shop.state(it) in ["ok", "poor"]:
			on_sale += 1
	lines[View.SHOP] = ["On sale", str(on_sale), "Coins", str(GameData.coins)]
	for i in HUB_CARDS.size():
		var v: int = HUB_CARDS[i]["view"]
		var cat_of_card: String = LISTS[v]["category"] if v in LISTS else ("pedia" if v == View.PEDIA else "")
		hub_cards[i].get_node("NewBadge").visible = cat_of_card != "" and Collection.has_new(cat_of_card)
		var t: Array = lines[v]
		var bottom := hub_cards[i].get_node("BottomFrame")
		var pairs := [[bottom.get_node("MaxScore"), bottom.get_node("MaxScore/Score")], [bottom.get_node("Progress"), bottom.get_node("Progress/Progress")]]
		for k in 2:
			for j in 2:
				var l: Label = pairs[k][j]
				l.text = t[k * 2 + j]
				if j == 1:
					# values: right-aligned to where the Games card's "000000" ends
					var score_label: Label = pairs[0][1]
					if not score_label.has_meta("right"):
						# where the Games card's "000000" ends, measured once (the template may already
						# have been right-aligned there by the Games menu: then its own right edge)
						var r: float = score_label.position.x + font.get_string_size("000000", HORIZONTAL_ALIGNMENT_LEFT, -1, 25).x
						if score_label.has_meta("pinned_right"):
							r = score_label.position.x + score_label.size.x
						score_label.set_meta("right", r)
					var right: float = score_label.get_meta("right")
					l.size.x = 150
					l.position.x = right - l.size.x
					l.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
				_fit_one_line(l, 25, 12)

func _build_pedia() -> void:
	title.text = "PAL-PEDIA"
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
		if known and Collection.is_new("pedia", id):
			var tag := _new_badge(20)
			tag.position = Vector2(118, 2)
			c.add_child(tag)
			Collection.mark_seen_item("pedia", id)     # seen now
		_add_item(c)

func _show_detail(id: String) -> void:
	view = View.DETAIL
	detail_id = id
	_clear()
	selection = -1
	var f: Dictionary = PetState.FORMS[id]
	var known: bool = id in PetState.discovered
	title.text = "#%03d" % f["no"]
	status.text = ""                   # the controls are shown in the band below

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
	stage_l.text = (str(f.get("stage_name", "pal")).capitalize() + " - " + str(f["family"]).capitalize()) if known else "Not found yet"
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

func _build_list(v: int) -> void:
	var cat: String = LISTS[v]["category"]
	var cat_catalog := Collection.catalog(cat)
	var ids := Collection.order(cat)
	page = clampi(page, 0, _list_pages(v) - 1)
	for slot in LIST_PER_PAGE:
		var i := page * LIST_PER_PAGE + slot
		if i >= ids.size():
			break
		var id: String = ids[i]
		var item: Dictionary = cat_catalog[id]
		var owned := Collection.is_owned(cat, id)
		var preview: Texture2D = _item_preview(cat, id) if owned else null
		var row := _food_card(slot, preview if preview else load("res://textures/menus/mistery.png"))   # same "?" as locked games
		var name_l: Label = row.get_meta("name_label")
		name_l.text = item["name"] if owned else "???"     # locked items stay a mystery
		var st: Label = row.get_meta("status_label")
		if not owned:
			st.text = "Play to unlock"
		elif Collection.is_in_use(cat, id):
			st.text = "In use"
			st.add_theme_color_override("font_color", IN_USE)
		# backgrounds / gut decor: the kind, on a tag like the food types
		if owned and KIND_TAGS.has(item.get("kind", "")):
			_card_tag(row, KIND_TAGS[item["kind"]])
		row.set_meta("action", { "type": "equip", "category": cat, "id": id } if owned else { "type": "locked" })
		if Collection.is_new(cat, id):
			var tag := _new_badge(26)
			tag.position = Vector2(row.size.x - 128, -6)
			row.add_child(tag)
			Collection.mark_seen_item(cat, id)   # seen now: its NEW tag is gone next time
		_add_item(row)

## A card exactly like the food menu's card in the same slot (0..2): its frame, the icon in the
## frame's square, the name in the same font and size, the hold ring. The pieces are read
## from the food menu itself, so both menus stay identical.
func _food_card(slot: int, icon_tex: Texture2D) -> Control:
	var food_menu := get_parent().get_node("FoodMenu/Menu")
	var opt: Node2D = food_menu.get_node("VBoxFood/FoodOption%d" % (slot + 1))
	var f_frame: Sprite2D = opt.get_node("Frame")
	var f_icon: Sprite2D = opt.get_node("Icon")
	var f_name: Label = opt.get_node("Name")
	var f_ring: Control = opt.get_node("Doughnut")
	# the two menus' backgrounds sit a few px apart: line the card up with this one's frame
	var shift: Vector2 = get_node("Menu/Sprite2D").position - food_menu.get_node("Background").position
	var frame_tex: Texture2D = load("res://textures/menus/foodmenulabel_food.png")
	var frame_size := frame_tex.get_size() * f_frame.scale
	var top_left := opt.position + f_frame.position - frame_size / 2.0 + shift
	var row := Control.new()
	row.position = top_left
	row.size = frame_size
	row.pivot_offset = frame_size / 2.0
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var origin := opt.position + shift - top_left            # option space -> row space
	var frame := Sprite2D.new()
	frame.texture = frame_tex
	frame.scale = f_frame.scale
	frame.position = f_frame.position + origin
	frame.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	row.add_child(frame)
	# the icon: in the frame's square, as big as a food icon (any picture, aspect kept)
	var box := Vector2(32, 32) * f_icon.scale
	var icon := TextureRect.new()
	icon.texture = icon_tex
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	icon.size = box
	icon.position = f_icon.position + origin - box / 2.0
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(icon)
	# the name: the food name's own label (font, size, colour)
	var name_l: Label = f_name.duplicate()
	name_l.z_index = 0
	name_l.position = f_name.position + origin
	name_l.autowrap_mode = TextServer.AUTOWRAP_OFF
	row.add_child(name_l)
	row.set_meta("name_label", name_l)
	# "In use" / "Play to unlock", under the name
	var st := _label(Vector2(name_l.position.x + 6, frame_size.y * 0.56), Vector2(frame_size.x * 0.5, 44), 30, TEXT_DARK, row)
	st.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	st.z_index = 0
	row.set_meta("status_label", st)
	# hold ring round the icon square, where the food menu has it
	_add_doughnut(row, Rect2(f_ring.position + origin, f_ring.size))
	return row

## The coloured type tag of a food card (foodtag.png at the same spot), with its word
func _card_tag(row: Control, info: Array) -> void:
	var tag_tex: Texture2D = load("res://textures/menus/foodtag.png")
	var frame: Sprite2D = row.get_child(0)
	var top_left := frame.position - frame.texture.get_size() * frame.scale / 2.0
	var tag := Sprite2D.new()
	tag.texture = tag_tex
	tag.centered = false
	tag.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	tag.scale = frame.scale * 0.84                 # (the food menu's TAG_SCALE / TAG_AT)
	tag.position = top_left + (Vector2(274, 55) + tag_tex.get_size() / 2.0) * frame.scale - tag_tex.get_size() * tag.scale / 2.0
	tag.modulate = info[1] * Color(1.06, 1.06, 1.06)
	row.add_child(tag)
	var l := Label.new()
	l.position = tag.position
	l.size = tag_tex.get_size() * tag.scale
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	l.add_theme_font_override("font", (row.get_meta("name_label") as Label).get_theme_font("font"))
	l.add_theme_font_size_override("font_size", 36)
	l.add_theme_color_override("font_color", Color8(92, 60, 44))
	l.text = info[0]
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(l)

func _new_badge(font_size: int) -> Label:
	var l := Label.new()
	l.text = "NEW!"
	l.add_theme_font_override("font", font)
	l.add_theme_font_size_override("font_size", font_size)
	l.add_theme_color_override("font_color", CREAM)
	l.add_theme_color_override("font_outline_color", CARD_BORDER)
	l.add_theme_constant_override("outline_size", 8)
	var sb := StyleBoxFlat.new()
	sb.bg_color = IN_USE
	sb.border_color = CARD_BORDER
	sb.set_border_width_all(4)
	sb.set_corner_radius_all(6)
	sb.content_margin_left = 10
	sb.content_margin_right = 10
	sb.content_margin_top = 2
	sb.content_margin_bottom = 2
	sb.anti_aliasing = false
	l.add_theme_stylebox_override("normal", sb)
	l.rotation = -0.18
	l.z_index = 3
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	l.pivot_offset = Vector2(40, 20)
	var t := l.create_tween().set_loops()
	t.tween_property(l, "scale", Vector2(1.1, 1.1), 0.45).set_trans(Tween.TRANS_SINE)
	t.tween_property(l, "scale", Vector2(1.0, 1.0), 0.45).set_trans(Tween.TRANS_SINE)
	return l

func _add_item(c: Control) -> void:
	content.add_child(c)
	items.append(c)

func _refresh_selection() -> void:
	if view == View.HUB:
		return
	# like the food and drink cards: the selected card just grows a little (no coloured frame)
	for i in items.size():
		items[i].scale = Vector2.ONE * (1.04 if i == selection else 1.0)

func _refresh_pager() -> void:
	var pages := 1
	if view in [View.PEDIA, View.DETAIL]:
		pages = _pedia_pages()
	elif view in LISTS:
		pages = _list_pages(view)
	elif view == View.SHOP:
		pages = _shop_pages()
	var many := view != View.DETAIL and view != View.HUB and pages > 1
	var is_list := view in LISTS or view == View.SHOP
	list_dots.visible = is_list and pages > 1
	if list_dots.visible:
		var dots := list_dots.get_children()
		for i in dots.size():
			dots[i].visible = i < pages
			dots[i].modulate = Color(1, 1, 1, 1) if i == page else Color(1, 1, 1, 0.3)
		MenuLegend.layout_dots(dots, pages, FRAME_DX)    # (ending before the forward sign, 2 rows if many)
	page_label.visible = many and not is_list
	detail_legend.visible = view == View.DETAIL
	page_hint.visible = (many or view == View.DETAIL) and view != View.HUB
	page_label.text = "%d/%d" % [page + 1, pages]

## A list shows its first page, plus one more page each time the last one shown is fully
## unlocked (so a fresh page of '?' appears as a promise of more to unlock).
func _list_pages(v: int) -> int:
	var cat: String = LISTS[v]["category"]
	var ids := Collection.order(cat)
	var total := maxi(1, ceili(ids.size() / float(LIST_PER_PAGE)))
	# every page with something you own is shown (wherever it was won)...
	var shown := 1
	for i in ids.size():
		if Collection.is_owned(cat, ids[i]):
			shown = maxi(shown, i / LIST_PER_PAGE + 1)
	# ...plus one more page of "???" once the last one is complete
	if shown < total:
		var full := true
		for i in range((shown - 1) * LIST_PER_PAGE, mini(shown * LIST_PER_PAGE, ids.size())):
			if not Collection.is_owned(cat, ids[i]):
				full = false
				break
		if full:
			shown += 1
	return shown

# ================================================================== SHOP

const SHOP_PER_PAGE := 3

func _shop_pages() -> int:
	return maxi(1, ceili(Shop.ITEMS.size() / float(SHOP_PER_PAGE)))

## The Shop: the food menu's cards, 3 a page: the item, its price on the tag (a coin + the
## number), and under the name what holding it does (or why it can't be bought yet)
func _build_shop() -> void:
	page = clampi(page, 0, _shop_pages() - 1)
	for slot in SHOP_PER_PAGE:
		var i := page * SHOP_PER_PAGE + slot
		if i >= Shop.ITEMS.size():
			break
		var it: Dictionary = Shop.ITEMS[i]
		var row := _food_card(slot, load(it["icon"]))
		var name_l: Label = row.get_meta("name_label")
		name_l.text = it["name"]
		var st: Label = row.get_meta("status_label")
		var state := Shop.state(it)
		match state:
			"owned":
				st.text = "Yours"
				st.add_theme_color_override("font_color", IN_USE)
			"needs_type":
				st.text = "%s foods first" % str(it["family"]).capitalize()
			"poor":
				st.text = "Need %d more" % (Shop.price(it) - GameData.coins)
			_:
				var have := Shop.pantry_count(it.get("food", ""))
				st.text = "Have %d · hold: buy" % have if it["kind"] == "special" and have > 0 else "Hold: buy"
		if state != "owned":
			_price_tag(row, Shop.price(it), state == "ok")
		row.set_meta("action", { "type": "buy", "id": it["id"] } if state == "ok" else { "type": "locked" })
		_add_item(row)

## The price on a card's tag spot: a coin and the number (dimmed while you can't afford it)
func _price_tag(row: Control, price: int, affordable: bool) -> void:
	_card_tag(row, [str(price), Color8(236, 208, 140) if affordable else Color8(200, 186, 160)])
	var l: Label = row.get_child(row.get_child_count() - 1)
	var tag: Sprite2D = row.get_child(row.get_child_count() - 2)
	l.text = "   " + str(price)
	var coin := TextureRect.new()
	coin.texture = UiArt.coin()
	coin.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	coin.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	coin.size = Vector2(33, 33)
	var w := l.get_theme_font("font").get_string_size(l.text, HORIZONTAL_ALIGNMENT_LEFT, -1, 36).x
	coin.position = tag.position + Vector2((l.size.x - w) / 2.0 - 4, (l.size.y - coin.size.y) / 2.0)
	coin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	coin.modulate = Color.WHITE if affordable else Color(1, 1, 1, 0.6)
	row.add_child(coin)

## Bought: the card hops
func _bought_pop(sel: Node) -> void:
	if sel is Control:
		var c := sel as Control
		var t := c.create_tween()
		t.tween_property(c, "scale", Vector2(1.12, 1.12), 0.08)
		t.tween_property(c, "scale", Vector2(1.04, 1.04), 0.18).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

## The coins you have, on the top-right corner (like the Games menu)
func _build_coin_tag(menu: Node) -> void:
	coin_tag = PanelContainer.new()
	var sb := StyleBoxFlat.new()
	sb.bg_color = CREAM
	sb.border_color = CARD_BORDER
	sb.set_border_width_all(4)
	sb.set_corner_radius_all(8)
	sb.content_margin_left = 12
	sb.content_margin_right = 16
	sb.content_margin_top = 2
	sb.content_margin_bottom = 2
	sb.anti_aliasing = false
	coin_tag.add_theme_stylebox_override("panel", sb)
	coin_tag.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	coin_tag.add_child(row)
	var icon := TextureRect.new()
	icon.texture = UiArt.coin()
	icon.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.custom_minimum_size = Vector2(36, 36)
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(icon)
	coin_tag_label = Label.new()
	coin_tag_label.add_theme_font_override("font", font)
	coin_tag_label.add_theme_font_size_override("font_size", 36)
	coin_tag_label.add_theme_color_override("font_color", TEXT_DARK)
	coin_tag_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	coin_tag_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(coin_tag_label)
	coin_tag.position = Vector2(1180 + FRAME_DX, -1206)
	coin_tag.z_index = 6
	coin_tag.visible = false
	menu.add_child(coin_tag)
	_refresh_coin_tag()

func _refresh_coin_tag() -> void:
	if coin_tag_label:
		coin_tag_label.text = str(GameData.coins)
		coin_tag.reset_size()
	if view == View.HUB:
		_update_hub_card_info()

## The food menu's locked cards point here (the gear button blinks)
func open_shop() -> void:
	pass

func _pedia_pages() -> int:
	return maxi(1, ceili(PetState.FORMS.size() / float(PEDIA_PER_PAGE)))

func _evolution_link(id: String) -> String:
	var from: String = PetState.FORMS[id]["from"]
	if from in PetState.FORMS:
		return "Evolves from " + (PetState.FORMS[from]["name"] if from in PetState.discovered else "???")
	if from != "":
		return "Evolves from " + from                # mutants: "any adult"
	# a baby: how many of its kids you've found
	var kids := PetState.FORMS.keys().filter(func(o): return PetState.FORMS[o]["from"] == id)
	var found := kids.filter(func(o): return o in PetState.discovered).size()
	return "Evolves into %d pals (%d found)" % [kids.size(), found]

# ================================================================== BACKGROUND APPLY

func _apply_background() -> void:
	var layers: Array = Collection.BACKGROUNDS[Collection.equipped_background]["layers"]
	var far = get_node_or_null("../../PetBackground/CloudA")
	var near = get_node_or_null("../../PetBackground/CloudB")
	if far and layers.size() > 0:
		far.texture = load(layers[0])
	if near and layers.size() > 1:
		near.texture = load(layers[1])
	# sky colour: the same hue shift as the gut colours, on the pink sky behind the layers
	var sky = get_node_or_null("../../PetBackground/PinkBackground")
	if sky:
		var hue: float = Collection.BACKGROUNDS.get(Collection.equipped_bg_color, {}).get("hue", 0.0)
		if hue == 0.0:
			sky.material = null
		else:
			var m := ShaderMaterial.new()
			m.shader = preload("res://scripts/shaders/hue_shift.gdshader")
			m.set_shader_parameter("hue_shift", hue)
			sky.material = m

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

func _add_doughnut(parent: Control, around) -> void:
	# Hold-to-confirm ring (main_button looks for a "Doughnut" child on the selected item)
	var d := TextureProgressBar.new()
	d.name = "Doughnut"
	d.fill_mode = TextureProgressBar.FILL_CLOCKWISE
	d.nine_patch_stretch = true
	d.texture_progress = load("res://textures/menus/circle.png")
	d.tint_under = Color(1, 1, 1, 0.56)
	d.tint_over = Color(1, 1, 1, 0.31)
	d.tint_progress = Color8(243, 182, 126)   # pastel apricot, like every hold ring
	if around is Rect2:                       # (a food-card ring: exactly that rect)
		d.position = around.position
		d.size = around.size
	else:
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

func _item_preview(cat: String, id: String) -> Texture2D:
	match cat:
		"backgrounds":
			var bg: Dictionary = Collection.BACKGROUNDS[id]
			if bg.get("kind", "") == "color":        # a swatch of the sky colour
				return _background_preview([], bg.get("hue", 0.0))
			var layers: Array = bg["layers"]           # patterns: on the card's beige
			return _background_preview(layers, 0.0, false) if not layers.is_empty() else null
		"accessories":
			return _accessory_preview(id)
		"decor":
			return _decor_preview(id)
	return null

## The accessory's own icon (food-icon style); the pal wearing it only as a fallback
func _accessory_preview(id: String) -> Texture2D:
	var icon_path := "res://textures/pet/accessories/icons/%s.png" % id
	if ResourceLoader.exists(icon_path):
		return load(icon_path)
	var form := PetState.form_id if PetState.has_poop() else String(PetState.pedia_order()[0])
	var body := _image("res://textures/pet/forms/%s-1.png" % form)
	if body == null:
		return null
	var dir: String = Collection.ACCESSORIES[id]["dir"]
	var over := _image("%s%s-1.png" % [dir, form]) if dir != "" else null
	if over:
		body.blend_rect(over, Rect2i(Vector2i.ZERO, over.get_size()), Vector2i.ZERO)
	var used := body.get_used_rect().grow(4)
	return ImageTexture.create_from_image(body.get_region(used))

## A corner of the colon with the decor on it (a colour item shows the gut recoloured)
func _decor_preview(id: String) -> Texture2D:
	var gut := _image("res://textures/pet-background/intestine-front.png")
	if gut == null:
		return null

	var frames: Array = Collection.DECOR[id]["frames"]
	if not frames.is_empty():
		var over := _image(frames[0])
		gut.blend_rect(over, Rect2i(Vector2i.ZERO, over.get_size()), Vector2i.ZERO)
	var crop := gut.get_region(Rect2i(60, 90, 380, 360))
	var hue: float = Collection.DECOR[id].get("hue", 0.0)
	if hue != 0.0:                               # only the small crop gets recoloured
		for y in crop.get_height():
			for x in crop.get_width():
				var c := crop.get_pixel(x, y)
				if c.a > 0.0:
					c.h = fposmod(c.h + hue, 1.0)
					crop.set_pixel(x, y, c)
	var img := Image.create(crop.get_width(), crop.get_height(), false, Image.FORMAT_RGBA8)
	img.fill(Color8(236, 170, 170))
	img.blend_rect(crop, Rect2i(Vector2i.ZERO, crop.get_size()), Vector2i.ZERO)
	return ImageTexture.create_from_image(img)

func _image(path: String) -> Image:
	if not ResourceLoader.exists(path):
		return null
	var img: Image = (load(path) as Texture2D).get_image()
	if img == null:
		return null
	if img.is_compressed():
		img.decompress()
	img.convert(Image.FORMAT_RGBA8)
	return img

func _background_preview(layers: Array, hue := 0.0, with_sky := true) -> Texture2D:
	var img := Image.create(200, 200, false, Image.FORMAT_RGBA8)
	if with_sky:
		var sky := Color8(229, 165, 166)
		sky.h = fposmod(sky.h + hue, 1.0)
		img.fill(sky)
	for path in layers:
		var layer_img: Image = (load(path) as Texture2D).get_image()
		if layer_img.is_compressed():
			layer_img.decompress()
		layer_img.convert(Image.FORMAT_RGBA8)
		img.blend_rect(layer_img, Rect2i(180, 90, 200, 200), Vector2i.ZERO)
	return ImageTexture.create_from_image(img)

## No pal yet: a short buzz and the Food button blinks (like the Games button does)
func _point_to_food() -> void:
	Input.vibrate_handheld(40)
	for b in get_tree().get_nodes_in_group("menu_toggle_buttons"):
		if b.target_menu and b.target_menu.has_method("populate_foods"):
			b.blink_hint()
			break

func _click() -> void:
	_sfx("res://sounds/fx/click-5.mp3", -6.0)

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
