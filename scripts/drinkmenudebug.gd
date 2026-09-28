extends Node2D

@onready var drink_option_1 = $Menu/VBoxContainer/DrinkOption1
@onready var drink_option_2 = $Menu/VBoxContainer/DrinkOption2
@onready var drink_option_3 = $Menu/VBoxContainer/DrinkOption3

func _ready():
	var healthy = DrinkLibrary.all_drinks.filter(func(d): return "healthy" in d.tags)
	var neutral = DrinkLibrary.all_drinks.filter(func(d): return "neutral" in d.tags)
	var unhealthy = DrinkLibrary.all_drinks.filter(func(d): return "unhealthy" in d.tags)

	var drink_pool = []
	if healthy.size() > 0:
		drink_pool.append(healthy[randi() % healthy.size()])
	if neutral.size() > 0:
		drink_pool.append(neutral[randi() % neutral.size()])
	if unhealthy.size() > 0:
		drink_pool.append(unhealthy[randi() % unhealthy.size()])

	drink_pool.shuffle() # Shuffle display order

	var options = [drink_option_1, drink_option_2, drink_option_3]

	for i in range(options.size()):
		var drink_data = drink_pool[i]
		var option_node = options[i]

		option_node.get_node("Icon").texture = drink_data.icon
		option_node.get_node("Name").text = drink_data.name
		option_node.get_node("Kcal").text = str(drink_data.kcal) + " kcal"
		
		# ── NEW ▶ tag as drink and choose its stream colour ──
		option_node.set_meta("is_drink", true)

		var col := Color(1, 1, 1, 1)  # fallback (white)
		if "healthy" in drink_data.tags:
			col = Color(0.20, 0.80, 1.00, 0.45)  # blue-ish
		elif "neutral" in drink_data.tags:
			col = Color(1.00, 0.65, 0.25, 0.45)  # orange
		elif "unhealthy" in drink_data.tags:
			col = Color(0.90, 0.15, 0.30, 0.45)  # red-pink

		print("Assigned color:", col)  # 🔍 ADD THIS LINE
		option_node.set_meta("color", col)
