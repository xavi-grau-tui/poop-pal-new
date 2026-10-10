extends Node2D

@onready var food_option_1 = $Menu/VBoxFood/FoodOption1
@onready var food_option_2 = $Menu/VBoxFood/FoodOption2
@onready var food_option_3 = $Menu/VBoxFood/FoodOption3

@onready var drink_option_1 = $Menu/VBoxDrink/DrinkOption1
@onready var drink_option_2 = $Menu/VBoxDrink/DrinkOption2
@onready var drink_option_3 = $Menu/VBoxDrink/DrinkOption3

@onready var vbox_food = $Menu/VBoxFood
@onready var vbox_drink = $Menu/VBoxDrink

@onready var nodedots = $Menu/Dots
@onready var dots = nodedots.get_children()

# Third page: special foods (tech / cosmic / legendary). Built from a copy of the food page.
var vbox_special: Node = null
var special_options := []
const PAGES := 3

var current_page := 0
var drinks_populated := false

## Each page lists everything it offers (every food type of the size the pal needs, then the ones
## still locked; every drink type...), more than its 3 cards: the cards are a window on that list.
## Pressing past the last card scrolls it on; the marks on the panel's right edge show where you are.
const VISIBLE := 3
var page_items := [[], [], []]
var page_offset := [0, 0, 0]
var scroll_marks: Node2D

var current_selection := -1                  # in the page's whole list
var legend: MenuLegend                 # the orange button's controls, left of the bottom band

## While the food (or drink) countdown runs, a shutter rolls down over the options with the LCD's
## countdown on it, and eating (drinking) is refused; once it has run out, the next time the menu
## opens the shutter rolls back up. Kept on (2026-10-10) until that menu needs something else
## there: then switch it off or replace it.
const BARRIER_ENABLED := true
const PANEL := Rect2(680.0, -1190.0, 678.0, 660.0)    # the frame's orange options panel, a bit beyond (Main UI coords)
const BARRIER_PX := 3
var barrier_clip: Control
var barrier: Node2D
var barrier_title: Label
var barrier_time: Label
var barrier_down := false
var active_options := []

func show_page(index: int):
	current_page = index
	vbox_food.visible = index == 0
	vbox_drink.visible = index == 1
	if vbox_special:
		vbox_special.visible = index == 2
	match index:
		0: active_options = [food_option_1, food_option_2, food_option_3]
		1: active_options = [drink_option_1, drink_option_2, drink_option_3]
		_: active_options = special_options
	current_selection = -1
	if page_offset[index] != 0:
		page_offset[index] = 0                     # (each page opens at the top of its list)
		_fill_window(index)
	reset_selection()
	update_dots(index)
	_update_scroll_marks()
	_update_barrier()                              # (it also shows / hides the legend)

func select_next():
	var n: int = page_items[current_page].size()
	if n == 0:
		return
	current_selection = (current_selection + 1) % n
	# keep the selected one on screen: the window follows it (and jumps back to the top)
	var off: int = page_offset[current_page]
	if current_selection < off:
		off = current_selection
	elif current_selection >= off + VISIBLE:
		off = current_selection - VISIBLE + 1
	if off != page_offset[current_page]:
		page_offset[current_page] = off
		_fill_window(current_page)
		_update_scroll_marks()
	update_selection()

func update_selection():
	var local: int = current_selection - page_offset[current_page]
	for i in range(active_options.size()):
		var node = active_options[i]
		node.scale = Vector2.ONE * 1.015 if i == local else Vector2.ONE

func reset_selection():
	for node in [food_option_1, food_option_2, food_option_3, drink_option_1, drink_option_2, drink_option_3] + special_options:
		node.scale = Vector2.ONE

func flip_page():
	current_page = (current_page + 1) % PAGES
	show_page(current_page)
	if current_page == 1 and not drinks_populated:
		populate_drinks()
		drinks_populated = true

func _ready():
	legend = MenuLegend.attach($Menu, $Menu/Background)
	_build_barrier()
	$Menu/ForwardHint.position.x = MenuLegend.forward_center_x()
	MenuLegend.layout_dots(dots)
	_build_special_page()
	_build_scroll_marks()
	show_page(0)
	populate_foods()
	populate_special()
	# bought in the Shop: locked cards open up right away (and the pantry's special foods show)
	Shop.changed.connect(func():
		populate_foods()
		populate_special())
	# a new game brings a new drink type
	GameData.game_unlocked.connect(func(_idx):
		if drinks_populated:
			populate_drinks())

func _build_special_page() -> void:
	vbox_special = vbox_food.duplicate()
	vbox_special.name = "VBoxSpecial"
	vbox_food.get_parent().add_child(vbox_special)
	vbox_special.visible = false
	special_options = vbox_special.get_children().filter(func(n): return n.name.begins_with("FoodOption"))
	# a third dot; the row still ends right before the forward sign
	var extra: Control = dots[dots.size() - 1].duplicate()
	nodedots.add_child(extra)
	for d in dots:
		d.position.x -= 40.0
	dots = nodedots.get_children()

## Special foods: a tech, a cosmic and a legendary card, from the pantry (FoodLibrary.get_special_set);
## the tag says how many you have; none of a kind = a "?" card (get them in the Shop)
func populate_special():
	_set_items(2, FoodLibrary.get_special_set())

func _fill_special(option_node: Node, food_data: Dictionary) -> void:
	var locked: bool = food_data.get("locked", false)
	option_node.get_node("Icon").texture = food_data.icon
	option_node.get_node("Icon").modulate = Color.WHITE
	option_node.get_node("Name").text = food_data.name
	_set_type_tag(option_node, food_data.family)
	var n := Shop.pantry_count(food_data.name)
	if not locked and n > 1:
		option_node.get_node("TypeText").text += " x%d" % n
	_set_lock(option_node, false)
	option_node.set_meta("food", food_data)
	option_node.set_meta("special", true)

## The foods of the size the pal needs to grow (FoodLibrary.get_menu_set): every type you have,
## then the types still in the Shop as locked cards
func populate_foods():
	_set_items(0, FoodLibrary.get_menu_set())

const LOCKED_FOOD_NAME := { "baby": "Sho food", "kid": "Chu food", "adult": "Dai food" }

func _fill_food(option_node: Node, food_data: Dictionary) -> void:
	var locked: bool = food_data.get("locked", false)
	option_node.get_node("Icon").texture = food_data.icon
	# a locked food: its silhouette (like a pal not found yet), a padlock, "Kid food"
	option_node.get_node("Icon").modulate = Color(0.1, 0.06, 0.05, 0.85) if locked else Color.WHITE
	option_node.get_node("Name").text = LOCKED_FOOD_NAME.get(food_data.get("tier", ""), "Food") if locked else food_data.name
	_set_type_tag(option_node, food_data.family, TIER_LEVEL.get(food_data.get("tier", ""), 0))
	_set_lock(option_node, locked)
	option_node.set_meta("food", food_data)

## A page's list changed: the window goes back to the top, nothing selected
func _set_items(page: int, items: Array) -> void:
	page_items[page] = items
	page_offset[page] = 0
	if page == current_page:
		current_selection = -1
		reset_selection()
	_fill_window(page)
	if page == current_page:
		_update_scroll_marks()

func _page_nodes(page: int) -> Array:
	match page:
		0: return [food_option_1, food_option_2, food_option_3]
		1: return [drink_option_1, drink_option_2, drink_option_3]
	return special_options

## The page's 3 cards show its list from page_offset on
func _fill_window(page: int) -> void:
	var nodes := _page_nodes(page)
	var items: Array = page_items[page]
	for i in nodes.size():
		var idx: int = page_offset[page] + i
		nodes[i].visible = idx < items.size()
		if idx >= items.size():
			continue
		match page:
			0: _fill_food(nodes[i], items[idx])
			1: _fill_drink(nodes[i], items[idx])
			_: _fill_special(nodes[i], items[idx])

## A padlock over a food card's icon (locked adult foods)
func _set_lock(option_node: Node, on: bool) -> void:
	var lock: Sprite2D = option_node.get_node_or_null("LockIcon")
	if not lock:
		if not on:
			return
		var icon: Sprite2D = option_node.get_node("Icon")
		lock = Sprite2D.new()
		lock.name = "LockIcon"
		lock.texture = UiArt.lock()
		lock.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		lock.scale = Vector2(5, 5)
		lock.position = icon.position + Vector2(0, 6)
		lock.z_index = icon.z_index + 1
		option_node.add_child(lock)
	lock.visible = on

## The drinks (DrinkLibrary.get_menu_set): every type you have, then the ones still to come
## (one comes with each new game) as locked cards
func populate_drinks():
	_set_items(1, DrinkLibrary.get_menu_set())

func _fill_drink(option_node: Node, drink_data: Dictionary) -> void:
	var locked: bool = drink_data.get("locked", false)
	option_node.get_node("Icon").texture = drink_data.icon
	option_node.get_node("Icon").modulate = Color(0.1, 0.06, 0.05, 0.85) if locked else Color.WHITE
	option_node.get_node("Name").text = "New drink" if locked else drink_data.name
	_set_type_tag(option_node, drink_data.type, int(drink_data.get("level", 1)))
	_set_lock(option_node, locked)
	option_node.set_meta("is_drink", true)
	option_node.set_meta("drink", drink_data)
	var col: Color = drink_data.color if drink_data.has("color") else Color(1, 1, 1, 0.3)
	option_node.set_meta("color", col)

## Where the page's window is in its list: a small mark per item on the panel's right edge (the
## ones on screen filled in), only when the list is longer than the 3 cards
func _build_scroll_marks() -> void:
	scroll_marks = Node2D.new()
	scroll_marks.name = "ScrollMarks"
	scroll_marks.z_index = 3
	$Menu.add_child(scroll_marks)

func _update_scroll_marks() -> void:
	if not scroll_marks:
		return
	for c in scroll_marks.get_children():
		c.queue_free()
	var n: int = page_items[current_page].size()
	scroll_marks.visible = n > VISIBLE and not barrier_down
	if n <= VISIBLE:
		return
	var step := 34.0
	var x := PANEL.position.x + PANEL.size.x - 19.0          # (on the panel's wooden edge)
	var y0 := PANEL.position.y + PANEL.size.y / 2.0 - step * (n - 1) / 2.0
	for i in n:
		var on: bool = i >= page_offset[current_page] and i < page_offset[current_page] + VISIBLE
		var m := Sprite2D.new()
		m.texture = UiArt.scroll_mark(on)
		m.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		m.scale = Vector2(4, 4)
		m.position = Vector2(x, y0 + step * i)
		scroll_marks.add_child(m)

# The food's type (what shapes the evolution) instead of its kcal: a little coloured tag,
# the same colours as the evolution tree (docs/evolution_tree_draft.png)
# (muted pastels, so they sit with the menu's creams and browns)
const TYPE_TAGS := UiArt.TYPE_TAGS

const FRAME_FOOD := preload("res://textures/menus/foodmenulabel_food.png")   # frame without the kcal box
const TAG_TEX := preload("res://textures/menus/foodtag.png")                   # that box, pale (tools/art/food_tag.py)
const TAG_AT := Vector2(274, 55)     # where the box goes in the frame's pixels (6 px lower than the old one)
const TAG_SCALE := 0.84

## A food's size (Sho 1 / Chu 2 / Dai 3) or a drink's power, as 1-3 icons on the tag's corner
const TIER_LEVEL := { "baby": 1, "kid": 2, "adult": 3 }

func _set_type_tag(option_node: Node, family: String, level := 0) -> void:
	var kcal: Label = option_node.get_node("Kcal")
	kcal.visible = false
	var tag: Sprite2D = option_node.get_node_or_null("TypeTag")
	if not tag:
		var frame: Sprite2D = option_node.get_node("Frame")
		frame.texture = FRAME_FOOD
		var top_left := frame.position - frame.texture.get_size() * frame.scale / 2.0
		tag = Sprite2D.new()
		tag.name = "TypeTag"
		tag.texture = TAG_TEX
		tag.centered = false
		tag.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		# a bit smaller than the old box, centred where it was
		tag.scale = frame.scale * TAG_SCALE
		tag.position = top_left + (TAG_AT + TAG_TEX.get_size() / 2.0) * frame.scale - TAG_TEX.get_size() * tag.scale / 2.0
		tag.z_index = frame.z_index
		option_node.add_child(tag)
		var l := Label.new()
		l.name = "TypeText"
		l.position = tag.position
		l.size = TAG_TEX.get_size() * tag.scale
		l.z_index = frame.z_index
		l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		l.add_theme_font_override("font", kcal.get_theme_font("font"))
		l.add_theme_font_size_override("font_size", 36)
		l.add_theme_color_override("font_color", Color8(92, 60, 44))
		option_node.add_child(l)
	var info: Array = TYPE_TAGS.get(family, [family.capitalize(), Color8(220, 196, 150)])
	tag.modulate = info[1] * Color(1.06, 1.06, 1.06)   # (the box art is a little under white)
	option_node.get_node("TypeText").text = info[0]
	UiArt.place_tier_icons(option_node, tag, family, level)


func update_dots(index: int):
	for i in range(dots.size()):
		dots[i].modulate = Color(1, 1, 1, 1) if i == index else Color(1, 1, 1, 0.3)

func reset_active_options():
	populate_special()          # (the legendary one follows the pal you have now)
	show_page(current_page)

## Asked by the main button before the OK sound: no pal yet = the first thing must be food,
## so a drink is refused (soft error + the Food button blinks)
func can_confirm(sel: Node) -> bool:
	if barrier_down:
		Input.vibrate_handheld(20)                   # the shutter is down: not yet
		return false
	var food: Dictionary = sel.get_meta("food", {}) if sel else {}
	# a drink type still to come: it comes with a new game (the Games button blinks)
	if sel and sel.get_meta("drink", {}).get("locked", false):
		Input.vibrate_handheld(40)
		for b in get_tree().get_nodes_in_group("menu_toggle_buttons"):
			if b.target_menu is GameMenuSwitcher:
				b.blink_hint()
				break
		return false
	# a locked card (foods of a size you don't have, special foods you don't have): they're in the
	# Shop, behind the gear button, which blinks
	if food.get("locked", false):
		Input.vibrate_handheld(40)
		for b in get_tree().get_nodes_in_group("menu_toggle_buttons"):
			if b.target_menu and b.target_menu.has_method("open_shop"):
				b.blink_hint()
				break
		return false
	# a special food only when it would do something (a key item is never wasted)
	if sel and sel.has_meta("special") and PetState.has_poop() and not FoodLibrary.special_useful(food):
		Input.vibrate_handheld(40)
		return false
	var special_first: bool = sel != null and sel.has_meta("special") and not PetState.can_start_with(sel.get_meta("food", {}))
	if sel and (sel.has_meta("drink") or special_first) and PetState.needs_first_meal():
		Input.vibrate_handheld(40)
		for b in get_tree().get_nodes_in_group("menu_toggle_buttons"):
			if b.target_menu == self:
				b.blink_hint()
				break
		return false
	return true

# ------------------------------------------------------------------ THE SHUTTER (on trial)

func _lcd() -> Node:
	return get_node_or_null("/root/PoopPal/Main UI/LCD Screen")

## Seconds left on the countdown this page waits for (food / special: the meal one; drinks: the
## drink one); 0 when it isn't running
func _wait_left() -> int:
	var lcd := _lcd()
	if not lcd or not lcd.get("running"):
		return 0
	return lcd.drink_time_left if current_page == 1 else lcd.food_time_left

func _update_barrier() -> void:
	if not barrier:
		if legend:
			legend.set_lines([["press", "next"], ["hold", "drink" if current_page == 1 else "eat"]])
		return
	var left := _wait_left()
	barrier_title.text = "NEXT DRINK IN" if current_page == 1 else "NEXT MEAL IN"
	if BARRIER_ENABLED and left > 0 and not barrier_down:
		_roll(true)
	elif (left <= 0 or not BARRIER_ENABLED) and barrier_down:
		_roll(false)
	_refresh_barrier_time()
	# the orange button's legend only while there's something to pick and eat (not behind the shutter)
	if legend:
		legend.set_lines([] if barrier_down else [["press", "next"], ["hold", "drink" if current_page == 1 else "eat"]])

func _refresh_barrier_time() -> void:
	var lcd := _lcd()
	if lcd and lcd.has_method("format_time"):
		barrier_time.text = lcd.format_time(_wait_left())

func _process(_delta: float) -> void:
	if barrier_down and visible:
		_refresh_barrier_time()               # (it stays down at 00:00 until the menu reopens)

## The shutter rolls down over the options (or back up), with a clack as it lands
func _roll(down: bool) -> void:
	barrier_down = down
	_update_scroll_marks()
	var h := PANEL.size.y
	var t := create_tween()
	t.tween_property(barrier, "position:y", 0.0 if down else -h, 0.45).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN if down else Tween.EASE_OUT)
	if down:
		t.tween_callback(func():
			var sfx := AudioStreamPlayer.new()
			sfx.stream = load("res://sounds/fx/clack.mp3")
			sfx.volume_db = -10.0
			add_child(sfx)
			sfx.play()
			sfx.finished.connect(sfx.queue_free)
			Input.vibrate_handheld(25))

func _build_barrier() -> void:
	barrier_clip = Control.new()
	barrier_clip.position = PANEL.position
	barrier_clip.size = PANEL.size
	barrier_clip.clip_contents = true
	barrier_clip.mouse_filter = Control.MOUSE_FILTER_IGNORE
	barrier_clip.z_index = 4                       # over the food cards (2) and their rings (3)...
	$Menu.add_child(barrier_clip)
	barrier = Node2D.new()
	barrier.position.y = -PANEL.size.y          # rolled up (out of sight)
	barrier_clip.add_child(barrier)
	var shutter := Sprite2D.new()
	shutter.texture = _shutter_texture(int(ceil(PANEL.size.x / BARRIER_PX)), int(ceil(PANEL.size.y / BARRIER_PX)))
	shutter.centered = false
	shutter.scale = Vector2(BARRIER_PX, BARRIER_PX)
	shutter.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	barrier.add_child(shutter)
	var font = load("res://fonts/pixChicago.ttf")
	for l in [Label.new(), Label.new()]:
		l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		l.size = Vector2(PANEL.size.x, 80)
		if font:
			l.add_theme_font_override("font", font)
		l.add_theme_color_override("font_color", Color8(84, 66, 50))
		l.add_theme_color_override("font_outline_color", Color8(240, 210, 160))
		l.add_theme_constant_override("outline_size", 12)
		l.mouse_filter = Control.MOUSE_FILTER_IGNORE
		barrier.add_child(l)
	barrier_title = barrier.get_child(1)
	barrier_time = barrier.get_child(2)
	barrier_title.add_theme_font_size_override("font_size", 40)
	barrier_time.add_theme_font_size_override("font_size", 96)
	barrier_title.position = Vector2(0, PANEL.size.y / 2.0 - 110)
	barrier_time.position = Vector2(0, PANEL.size.y / 2.0 - 30)
	# ...but under the frame's inner border: that ring of the frame (tools/art/frame_ring.py) is
	# laid on top, so the shutter slides in behind the frame's border and rounded corners
	var bg: Sprite2D = $Menu/Background
	var ring := Sprite2D.new()
	ring.texture = load("res://textures/menus/diapositive1_ring.png")
	ring.position = bg.position
	ring.scale = bg.scale
	ring.texture_filter = bg.texture_filter
	ring.z_index = 5
	ring.visible = BARRIER_ENABLED
	$Menu.add_child(ring)

## A roll-down shutter in the panel's own orange (pixel art): slats with light top edges, a
## darker grid over them, a dark bottom bar with a little handle
static func _shutter_texture(w: int, h: int) -> Texture2D:
	var img := Image.create(w, h, false, Image.FORMAT_RGBA8)
	var base := Color8(215, 160, 96)
	var light := Color8(232, 190, 132)
	var dark := Color8(186, 132, 76)
	var ink := Color8(84, 66, 50)
	for y in h:
		for x in w:
			var col := base
			var slat := y % 12
			if slat == 0:
				col = light                     # each slat's lit top edge
			elif slat == 11:
				col = dark                      # and its shaded underside
			if x % 10 == 0 and slat > 0 and slat < 11:
				col = dark                      # the grid
			if y >= h - 6:
				col = ink if y >= h - 2 or y == h - 6 else dark      # the bottom bar
			if x < 2 or x >= w - 2:
				col = ink                       # the side rails
			img.set_pixel(x, y, col)
	# the handle on the bottom bar
	for x in range(w / 2 - 8, w / 2 + 8):
		for y in range(h - 12, h - 7):
			img.set_pixel(x, y, ink if (y == h - 12 or x == w / 2 - 8 or x == w / 2 + 7) else light)
	return ImageTexture.create_from_image(img)

func get_selected_option():
	var local: int = current_selection - page_offset[current_page]
	if current_selection >= 0 and local >= 0 and local < active_options.size():
		return active_options[local]
	return null
