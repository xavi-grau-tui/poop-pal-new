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

var current_selection := -1
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
	reset_selection()
	update_dots(index)

func select_next():
	if active_options.size() == 0:
		return
	current_selection = (current_selection + 1) % active_options.size()
	update_selection()

func update_selection():
	for i in range(active_options.size()):
		var node = active_options[i]
		node.scale = Vector2.ONE * 1.015 if i == current_selection else Vector2.ONE

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
	_build_special_page()
	show_page(0)
	populate_foods()
	populate_special()

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

## Special foods: one tech, one cosmic, one legendary (FoodLibrary.get_special_set)
func populate_special():
	var pool = FoodLibrary.get_special_set()
	for i in range(mini(special_options.size(), pool.size())):
		var food_data = pool[i]
		var option_node = special_options[i]
		option_node.get_node("Icon").texture = food_data.icon
		option_node.get_node("Name").text = food_data.name
		_set_type_tag(option_node, food_data.family)
		option_node.set_meta("food", food_data)
		option_node.set_meta("special", true)

func populate_foods():
	# One food per family (green / sweet / greasy) — the family drives poop evolution
	var food_pool = FoodLibrary.get_menu_set()
	var options = [food_option_1, food_option_2, food_option_3]

	for i in range(options.size()):
		var food_data = food_pool[i]
		var option_node = options[i]
		option_node.get_node("Icon").texture = food_data.icon
		option_node.get_node("Name").text = food_data.name
		_set_type_tag(option_node, food_data.family)
		option_node.set_meta("food", food_data)

func populate_drinks():
	var healthy = DrinkLibrary.all_drinks.filter(func(d): return "healthy" in d.tags)
	var neutral = DrinkLibrary.all_drinks.filter(func(d): return "neutral" in d.tags)
	var unhealthy = DrinkLibrary.all_drinks.filter(func(d): return "unhealthy" in d.tags)

	var drink_pool = []
	if healthy.size() > 0: drink_pool.append(healthy[randi() % healthy.size()])
	if neutral.size() > 0: drink_pool.append(neutral[randi() % neutral.size()])
	if unhealthy.size() > 0: drink_pool.append(unhealthy[randi() % unhealthy.size()])

	drink_pool.shuffle()
	var options = [drink_option_1, drink_option_2, drink_option_3]

	for i in range(options.size()):
		var drink_data = drink_pool[i]
		var option_node = options[i]

		option_node.get_node("Icon").texture = drink_data.icon
		option_node.get_node("Name").text = drink_data.name
		option_node.get_node("Kcal").text = str(drink_data.kcal) + " kcal"
		option_node.set_meta("is_drink", true)
		option_node.set_meta("drink", drink_data)

		var col: Color = drink_data.color if drink_data.has("color") else Color(1, 1, 1, 0.3)
		option_node.set_meta("color", col)

# The food's type (what shapes the evolution) instead of its kcal: a little coloured tag,
# the same colours as the evolution tree (docs/evolution_tree_draft.png)
# (muted pastels, so they sit with the menu's creams and browns)
const TYPE_TAGS := {
	"green": ["Green", Color8(176, 200, 150)], "sweet": ["Sweet", Color8(232, 182, 196)],
	"greasy": ["Greasy", Color8(222, 186, 144)], "spicy": ["Spicy", Color8(226, 160, 144)],
	"sour": ["Sour", Color8(226, 214, 150)], "tech": ["Tech", Color8(170, 186, 200)],
	"cosmic": ["Cosmic", Color8(196, 178, 214)], "legend": ["Rare", Color8(236, 208, 140)],
}

func _set_type_tag(option_node: Node, family: String) -> void:
	var kcal: Label = option_node.get_node("Kcal")
	kcal.visible = false
	var tag: Panel = option_node.get_node_or_null("TypeTag")
	if not tag:
		tag = Panel.new()
		tag.name = "TypeTag"
		tag.z_index = kcal.z_index
		# in the lower part of the beige box (where the kcal was), clear of the food's name
		tag.position = Vector2(kcal.position.x + 2, kcal.position.y - 4)
		tag.size = Vector2(142, 48)
		var l := Label.new()
		l.name = "Text"
		l.set_anchors_preset(Control.PRESET_FULL_RECT)
		l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		l.add_theme_font_override("font", kcal.get_theme_font("font"))
		l.add_theme_font_size_override("font_size", 28)
		l.add_theme_color_override("font_color", Color8(92, 60, 44))
		tag.add_child(l)
		option_node.add_child(tag)
	var info: Array = TYPE_TAGS.get(family, [family.capitalize(), Color8(166, 129, 94)])
	var box := StyleBoxFlat.new()
	box.bg_color = info[1]
	box.border_color = Color8(120, 86, 62)
	box.set_border_width_all(3)
	box.set_corner_radius_all(8)
	tag.add_theme_stylebox_override("panel", box)
	tag.get_node("Text").text = info[0]

func update_dots(index: int):
	for i in range(dots.size()):
		dots[i].modulate = Color(1, 1, 1, 1) if i == index else Color(1, 1, 1, 0.3)

func reset_active_options():
	populate_special()          # (the legendary one follows the pal you have now)
	show_page(current_page)

## Asked by the main button before the OK sound: no pal yet = the first thing must be food,
## so a drink is refused (soft error + the Food button blinks)
func can_confirm(sel: Node) -> bool:
	var special_first: bool = sel != null and sel.has_meta("special") and not PetState.can_start_with(sel.get_meta("food", {}))
	if sel and (sel.has_meta("drink") or special_first) and PetState.needs_first_meal():
		Input.vibrate_handheld(40)
		for b in get_tree().get_nodes_in_group("menu_toggle_buttons"):
			if b.target_menu == self:
				b.blink_hint()
				break
		return false
	return true

func get_selected_option():
	if current_selection >= 0 and current_selection < active_options.size():
		return active_options[current_selection]
	return null
