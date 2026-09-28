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

var current_page := 0
var drinks_populated := false

var current_selection := -1
var active_options := []

func show_page(index: int):
	current_page = index
	vbox_food.visible = index == 0
	vbox_drink.visible = index == 1
	active_options = [food_option_1, food_option_2, food_option_3] if index == 0 else [drink_option_1, drink_option_2, drink_option_3]
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
	for node in [food_option_1, food_option_2, food_option_3, drink_option_1, drink_option_2, drink_option_3]:
		node.scale = Vector2.ONE

func flip_page():
	current_page = (current_page + 1) % 2
	show_page(current_page)
	if current_page == 1 and not drinks_populated:
		populate_drinks()
		drinks_populated = true

func _ready():
	show_page(0)
	populate_foods()

func populate_foods():
	# One food per family (green / sweet / greasy) — the family drives poop evolution
	var food_pool = FoodLibrary.get_menu_set()
	var options = [food_option_1, food_option_2, food_option_3]

	for i in range(options.size()):
		var food_data = food_pool[i]
		var option_node = options[i]
		option_node.get_node("Icon").texture = food_data.icon
		option_node.get_node("Name").text = food_data.name
		option_node.get_node("Kcal").text = str(food_data.kcal) + " kcal"
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

		var col: Color = drink_data.color if drink_data.has("color") else Color(1, 1, 1, 0.3)
		option_node.set_meta("color", col)

func update_dots(index: int):
	for i in range(dots.size()):
		dots[i].modulate = Color(1, 1, 1, 1) if i == index else Color(1, 1, 1, 0.3)

func reset_active_options():
	show_page(current_page)

func get_selected_option():
	if current_selection >= 0 and current_selection < active_options.size():
		return active_options[current_selection]
	return null
