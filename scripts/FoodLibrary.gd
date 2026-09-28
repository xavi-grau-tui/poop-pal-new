# FoodLibrary.gd
extends Node

var all_foods = [
	{
		"name": "Salad Bowl",
		"icon": preload("res://textures/food/saladbowl.png"),
		"kcal": 160,
		"tags": ["healthy"]
	},
	{
		"name": "Club Sandwich",
		"icon": preload("res://textures/food/clubsandwich.png"),
		"kcal": 430,
		"tags": ["neutral"]
	},
	{
		"name": "Cheeseburger",
		"icon": preload("res://textures/food/cheeseburger.png"),
		"kcal": 580,
		"tags": ["unhealthy"]
	},
	{
		"name": "Cucumber Sushi",
		"icon": preload("res://textures/food/cucumbersushi.png"),
		"kcal": 250,
		"tags": ["healthy"]
	},
	{
		"name": "Spaghetti",
		"icon": preload("res://textures/food/spaghetthi.png"),
		"kcal": 500,
		"tags": ["neutral"]
	},
	{
		"name": "Hot Dog",
		"icon": preload("res://textures/food/hotdog.png"),
		"kcal": 450,
		"tags": ["unhealthy"]
	}
]

func get_random_food_set() -> Array:
	var result = []
	var selected_names = {}

	# Ensure we don't get duplicates even if tags are mixed
	var healthy = FoodLibrary.all_foods.filter(func(f): return "healthy" in f.tags and not selected_names.has(f.name))
	var neutral = FoodLibrary.all_foods.filter(func(f): return "neutral" in f.tags and not selected_names.has(f.name))
	var unhealthy = FoodLibrary.all_foods.filter(func(f): return "unhealthy" in f.tags and not selected_names.has(f.name))

	if healthy.size() > 0:
		var h = healthy[randi() % healthy.size()]
		result.append(h)
		selected_names[h.name] = true

	if neutral.size() > 0:
		var n = neutral[randi() % neutral.size()]
		result.append(n)
		selected_names[n.name] = true

	if unhealthy.size() > 0:
		var u = unhealthy[randi() % unhealthy.size()]
		result.append(u)
		selected_names[u.name] = true

	return result
 
