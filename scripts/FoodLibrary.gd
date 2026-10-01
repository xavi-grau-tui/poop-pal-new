# FoodLibrary.gd
extends Node

var all_foods = [
	{
		"name": "Salad Bowl",
		"family": "green",
		"icon": preload("res://textures/food/saladbowl.png"),
		"kcal": 160,
		"tags": ["healthy"]
	},
	{
		"name": "Club Sandwich",
		"family": "greasy",
		"icon": preload("res://textures/food/clubsandwich.png"),
		"kcal": 430,
		"tags": ["neutral"]
	},
	{
		"name": "Cheeseburger",
		"family": "greasy",
		"icon": preload("res://textures/food/cheeseburger.png"),
		"kcal": 580,
		"tags": ["unhealthy"]
	},
	{
		"name": "Cucumber Sushi",
		"family": "green",
		"icon": preload("res://textures/food/cucumbersushi.png"),
		"kcal": 250,
		"tags": ["healthy"]
	},
	{
		"name": "Spaghetti",
		"family": "greasy",
		"icon": preload("res://textures/food/spaghetthi.png"),
		"kcal": 500,
		"tags": ["neutral"]
	},
	{
		"name": "Hot Dog",
		"family": "greasy",
		"icon": preload("res://textures/food/hotdog.png"),
		"kcal": 450,
		"tags": ["unhealthy"]
	},
	{
		"name": "Rice and Vegs",
		"family": "green",
		"icon": preload("res://textures/food/brownricevegs.png"),
		"kcal": 320,
		"tags": ["healthy"]
	},
	{
		"name": "Glazed Donut",
		"family": "sweet",
		"icon": preload("res://textures/food/donut.png"),
		"kcal": 290,
		"tags": ["unhealthy", "sugary"]
	},
	{
		"name": "Rainbow Jelly",
		"family": "sweet",
		"icon": preload("res://textures/food/rainbowjelly.png"),
		"kcal": 180,
		"tags": ["unhealthy", "sugary"]
	},
	# --- spicy
	{ "name": "Chili Pepper", "family": "spicy", "icon": preload("res://textures/food/chilipepper.png"), "kcal": 40, "tags": ["healthy"] },
	{ "name": "Hot Wings", "family": "spicy", "icon": preload("res://textures/food/hotwings.png"), "kcal": 480, "tags": ["unhealthy"] },
	{ "name": "Curry", "family": "spicy", "icon": preload("res://textures/food/curry.png"), "kcal": 520, "tags": ["neutral"] },
	# --- sour
	{ "name": "Pickle", "family": "sour", "icon": preload("res://textures/food/pickle.png"), "kcal": 20, "tags": ["healthy"] },
	{ "name": "Lemon", "family": "sour", "icon": preload("res://textures/food/lemon.png"), "kcal": 30, "tags": ["healthy"] },
	{ "name": "Kimchi", "family": "sour", "icon": preload("res://textures/food/kimchi.png"), "kcal": 90, "tags": ["neutral"] },
]

const FAMILIES := ["green", "sweet", "greasy", "spicy", "sour"]

## Exotic and legendary foods: the food menu's third page (they can't start a pal;
## tech / cosmic turn an adult into a mutant, a legendary food turns the right ULTRA adult
## into a legend)
var special_foods = [
	{ "name": "Microchip", "family": "tech", "icon": preload("res://textures/food/microchip.png"), "kcal": 1, "tags": ["exotic"] },
	{ "name": "Battery", "family": "tech", "icon": preload("res://textures/food/battery.png"), "kcal": 2, "tags": ["exotic"] },
	{ "name": "Alien Goo", "family": "cosmic", "icon": preload("res://textures/food/aliengoo.png"), "kcal": 66, "tags": ["exotic"] },
	{ "name": "Moon Rock", "family": "cosmic", "icon": preload("res://textures/food/moonrock.png"), "kcal": 0, "tags": ["exotic"] },
	{ "name": "Golden Seed", "family": "legend", "legend_of": "green", "icon": preload("res://textures/food/goldenseed.png"), "kcal": 999, "tags": ["legendary"] },
	{ "name": "Stardust Sugar", "family": "legend", "legend_of": "sweet", "icon": preload("res://textures/food/stardustsugar.png"), "kcal": 999, "tags": ["legendary"] },
	{ "name": "Dragon Oil", "family": "legend", "legend_of": "greasy", "icon": preload("res://textures/food/dragonoil.png"), "kcal": 999, "tags": ["legendary"] },
	{ "name": "Phoenix Pepper", "family": "legend", "legend_of": "spicy", "icon": preload("res://textures/food/phoenixpepper.png"), "kcal": 999, "tags": ["legendary"] },
	{ "name": "Kraken Brine", "family": "legend", "legend_of": "sour", "icon": preload("res://textures/food/krakenbrine.png"), "kcal": 999, "tags": ["legendary"] },
]

## Three random foods of three different (random) basic types, for now. Over a few meals
## you see every type; flushing restarts a pal anytime, so no path stays out of reach.
func get_menu_set() -> Array:
	var fams := FAMILIES.duplicate()
	fams.shuffle()
	var result := []
	for fam in fams.slice(0, 3):
		var pool = all_foods.filter(func(f): return f.get("family", "") == fam)
		if pool.size() > 0:
			result.append(pool[randi() % pool.size()])
	return result

## The special page: one tech, one cosmic, one legendary food. The legendary one is the
## current pal's own when it can use it (its ULTRA adult), otherwise a random one.
func get_special_set() -> Array:
	var tech = special_foods.filter(func(f): return f["family"] == "tech")
	var cosmic = special_foods.filter(func(f): return f["family"] == "cosmic")
	var legends = special_foods.filter(func(f): return f["family"] == "legend")
	var legend = legends[randi() % legends.size()]
	var lg: Dictionary = PetState.LEGENDS.get(PetState.form_id, {})
	if lg.get("to") != null and lg.has("family"):
		for f in legends:
			if f["legend_of"] == lg["family"]:
				legend = f
	return [tech[randi() % tech.size()], cosmic[randi() % cosmic.size()], legend]

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
 
