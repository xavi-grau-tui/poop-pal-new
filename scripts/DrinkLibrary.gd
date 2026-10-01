extends Node
## Drinks. Every drink has a TYPE; a type gives a boost (the last drink counts), and each
## minigame decides what a boost does there (players find out which is best where).
##   watery  -> splash (a boing and a second chance)        [in Pipe Dream, Pal Dash, Flipper Belly]
##   fizzy, caffeinated, milky, fruity -> boosts to come (fizz, focus, sturdy, lucky)

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

## Three random drinks of three different (random) types, like the foods
func get_menu_set() -> Array:
	var types := TYPES.duplicate()
	types.shuffle()
	var result := []
	for t in types.slice(0, 3):
		var pool = all_drinks.filter(func(d): return d["type"] == t)
		if pool.size() > 0:
			result.append(pool[randi() % pool.size()])
	return result
