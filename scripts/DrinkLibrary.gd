extends Node
## Drinks. Every drink has a TYPE; a type gives a boost (the last drink counts), and each
## minigame decides what a boost does there (players find out which is best where).
##   watery  -> splash (a boing and a second chance)        [in Pipe Dream, Pal Dash, Flipper Belly]
##   fizzy, caffeinated, milky, fruity -> boosts to come (fizz, focus, sturdy, lucky)
## The types come with the games (decided 2026-10-09: a drink is on offer only once a game it
## helps is yours): one more type with each game you own, in TYPES order. Watery with the first
## game (Splash Hoops), Fizzy with the 2nd (always Tilt Maze: its low fences), then Energy, Milky,
## Fruity (each helps a game you have by then, whichever you bought: the boost table in
## docs/ideas_roadmap.md). Nothing random: the menu lists the types you have, then the rest locked.

const TYPES := ["watery", "fizzy", "caffeinated", "milky", "fruity"]
const BOOST_OF_TYPE := { "watery": "splash" }       # the others get theirs later

var all_drinks = [
	{ "name": "Water", "type": "watery", "icon": preload("res://textures/drinks/water.png"), "color": Color(0.75, 0.85, 1.0, 0.5) },
	{ "name": "Coconut Water", "type": "watery", "icon": preload("res://textures/drinks/coconutwater.png"), "color": Color(0.95, 0.94, 0.9, 0.5) },
	{ "name": "Cola", "type": "fizzy", "icon": preload("res://textures/drinks/soda.png"), "color": Color(0.45, 0.22, 0.22, 0.45) },
	{ "name": "Lemonade", "type": "fizzy", "icon": preload("res://textures/drinks/lemonade.png"), "color": Color(1.0, 0.95, 0.6, 0.45) },
	{ "name": "Energy Drink", "type": "caffeinated", "icon": preload("res://textures/drinks/energydrink.png"), "color": Color(0.7, 0.95, 0.55, 0.45) },
	{ "name": "Coffee", "type": "caffeinated", "icon": preload("res://textures/drinks/coffee.png"), "color": Color(0.5, 0.32, 0.2, 0.5) },
	{ "name": "Milk", "type": "milky", "icon": preload("res://textures/drinks/milk.png"), "color": Color(0.98, 0.98, 1.0, 0.55) },
	{ "name": "Milkshake", "type": "milky", "icon": preload("res://textures/drinks/milkshake.png"), "color": Color(1.0, 0.8, 0.86, 0.5) },
	{ "name": "Orange Juice", "type": "fruity", "icon": preload("res://textures/drinks/orangejuice.png"), "color": Color(1.0, 0.75, 0.45, 0.45) },
	{ "name": "Smoothie", "type": "fruity", "icon": preload("res://textures/drinks/smoothie.png"), "color": Color(0.85, 0.4, 0.6, 0.45) },
]

func _ready() -> void:
	for d in all_drinks:
		var b: String = BOOST_OF_TYPE.get(d["type"], "")
		if b != "":
			d["boost"] = b

## The drink types on offer: one per game you own (at least Watery)
func owned_types() -> Array:
	return TYPES.slice(0, clampi(GameData.owned_launch_games(), 1, TYPES.size()))

## The drink menu's cards: each type you have (its first drink), in TYPES order, then a locked
## card for each type still to come ("locked": true; it comes with your next game)
func get_menu_set() -> Array:
	var have := owned_types()
	var result := []
	var locked := []
	for t in TYPES:
		var pool = all_drinks.filter(func(d): return d["type"] == t)
		if pool.is_empty():
			continue
		if t in have:
			result.append(pool[0])
		else:
			var lock: Dictionary = pool[0].duplicate()
			lock["locked"] = true
			locked.append(lock)
	return result + locked
