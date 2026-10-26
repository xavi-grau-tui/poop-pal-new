extends Node
## Drinks. Every drink has a TYPE; a type gives a boost (the last drink counts), and each
## minigame decides what a boost does there (players find out which is best where). One meaning
## per boost everywhere (docs/progression.md, section 4):
##   watery      -> splash  a second chance (the one "extra life" in every game)
##   fizzy       -> fizz    lift / power (hops Tilt Maze's low fences, stronger jets, a jump...)
##   caffeinated -> focus   more time to react (wider timing windows, a slow-motion beat)
##   milky       -> sturdy  weight (heavier: hard to push, rams cracked walls, no slipping)
##   fruity      -> lucky   finding (opens chests, spots hidden prizes)
## The types come with the games (decided 2026-10-09: a drink is on offer only once a game it
## helps is yours): one more type with each game you own, in TYPES order. Watery with the first
## game (Splash Hoops), Fizzy with the 2nd (always Tilt Maze: its low fences), then Energy, Milky,
## Fruity (each helps a game you have by then, whichever you bought; Tilt Maze has a vault kind
## for every boost). Nothing random: the menu lists the types you have, then the rest locked.
##
## LEVELS (Drinks v2): each type has three drinks, level 1-3 (the Shop sells levels 2 and 3 of a
## type, for good). The menu offers each type's drink of the level you have; a stronger drink is
## the same effect, stronger, and opens the gates that ask for its level.

const TYPES := ["watery", "fizzy", "caffeinated", "milky", "fruity"]
const BOOST_OF_TYPE := { "watery": "splash", "fizzy": "fizz", "caffeinated": "focus", "milky": "sturdy", "fruity": "lucky" }

## Every drink, level 1 to 3 per type (the line-up of the drafts, docs/mockups/drink_drafts/)
var all_drinks = [
	{ "name": "Shrine Water", "type": "watery", "level": 1, "icon": preload("res://textures/drinks/water.png"), "color": Color(0.75, 0.85, 1.0, 0.5) },
	{ "name": "Barley Tea", "type": "watery", "level": 2, "icon": preload("res://textures/drinks/barleytea.png"), "color": Color(0.78, 0.55, 0.3, 0.5) },
	{ "name": "Coconut Water", "type": "watery", "level": 3, "icon": preload("res://textures/drinks/coconutwater.png"), "color": Color(0.95, 0.94, 0.9, 0.5) },
	{ "name": "Cola", "type": "fizzy", "level": 1, "icon": preload("res://textures/drinks/soda.png"), "color": Color(0.45, 0.22, 0.22, 0.45) },
	{ "name": "Ramune", "type": "fizzy", "level": 2, "icon": preload("res://textures/drinks/ramune.png"), "color": Color(0.72, 0.9, 1.0, 0.45) },
	{ "name": "Cream Soda", "type": "fizzy", "level": 3, "icon": preload("res://textures/drinks/sodafloat.png"), "color": Color(0.55, 0.92, 0.6, 0.45) },
	{ "name": "Green Tea", "type": "caffeinated", "level": 1, "icon": preload("res://textures/drinks/tea.png"), "color": Color(0.72, 0.5, 0.3, 0.5) },
	{ "name": "Coffee", "type": "caffeinated", "level": 2, "icon": preload("res://textures/drinks/coffee.png"), "color": Color(0.5, 0.32, 0.2, 0.5) },
	{ "name": "Energy Drink", "type": "caffeinated", "level": 3, "icon": preload("res://textures/drinks/energydrink.png"), "color": Color(0.7, 0.95, 0.55, 0.45) },
	{ "name": "Milk", "type": "milky", "level": 1, "icon": preload("res://textures/drinks/milk.png"), "color": Color(0.98, 0.98, 1.0, 0.55) },
	{ "name": "Bubble Tea", "type": "milky", "level": 2, "icon": preload("res://textures/drinks/bubbletea.png"), "color": Color(0.85, 0.72, 0.58, 0.5) },
	{ "name": "Milkshake", "type": "milky", "level": 3, "icon": preload("res://textures/drinks/milkshake.png"), "color": Color(1.0, 0.8, 0.86, 0.5) },
	{ "name": "Mikan Juice", "type": "fruity", "level": 1, "icon": preload("res://textures/drinks/orangejuice.png"), "color": Color(1.0, 0.75, 0.45, 0.45) },
	{ "name": "Peach Juice", "type": "fruity", "level": 2, "icon": preload("res://textures/drinks/peachjuice.png"), "color": Color(1.0, 0.7, 0.62, 0.45) },
	{ "name": "Smoothie", "type": "fruity", "level": 3, "icon": preload("res://textures/drinks/smoothie.png"), "color": Color(0.85, 0.4, 0.6, 0.45) },
]

func _ready() -> void:
	for d in all_drinks:
		var b: String = BOOST_OF_TYPE.get(d["type"], "")
		if b != "":
			d["boost"] = b

## The drink types on offer: one per game you own (at least Watery)
func owned_types() -> Array:
	return TYPES.slice(0, clampi(GameData.owned_launch_games(), 1, TYPES.size()))

## A type's drink of a level (1-3)
func drink_of(type: String, level: int) -> Dictionary:
	for d in all_drinks:
		if d["type"] == type and int(d["level"]) == level:
			return d
	return {}

## The drink menu's cards: each type you have (its drink of the level the Shop gave you), in
## TYPES order, then a locked card for each type still to come ("locked": true; it comes with
## your next game)
func get_menu_set() -> Array:
	var have := owned_types()
	var result := []
	var locked := []
	for t in TYPES:
		if t in have:
			var d := drink_of(t, Shop.drink_level(t))
			if not d.is_empty():
				result.append(d)
		else:
			var lock: Dictionary = drink_of(t, 1).duplicate()
			lock["locked"] = true
			locked.append(lock)
	return result + locked

## The boost a drink type gives ("" = none)
func boost_of(type: String) -> String:
	return BOOST_OF_TYPE.get(type, "")

## The drink type of a boost
func type_of_boost(boost_id: String) -> String:
	for t in BOOST_OF_TYPE:
		if BOOST_OF_TYPE[t] == boost_id:
			return t
	return ""
