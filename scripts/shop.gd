extends Node
## Autoload "Shop" (Progression v2): what coins buy besides games (games are bought in the
## Games menu). Opened from the gear menu's SHOP card (collection_menu.gd).
##
##   food types     Spicy, Sour: their baby and kid foods (Green, Sweet, Greasy come free)
##   adult foods    per type, both adult foods of that type: a kid only grows up eating them;
##                  20 coins for the first type, then 30, 40, 50, 60
##   special foods  key items, kept in a pantry (each one = one meal): tech and cosmic turn an
##                  adult into its family's mutant, a legendary food turns its ULTRA adult into
##                  a legend. Only offered on the food menu's special page while you have some.
## Cosmetics are never sold here (they are gifts for playing: Collection.REWARDS).

signal changed

const SAVE_PATH := "user://shop.json"
## Prototype/testing: every launch starts with only the free food types and an empty pantry
const RESET_ON_LAUNCH := true

const FREE_TYPES := ["green", "sweet", "greasy"]
const ADULT_FIRST_PRICE := 20
const ADULT_STEP := 10
const TYPE_PRICE := 30

## Everything on sale, in the order the Shop shows it
const ITEMS := [
	{ "id": "adult_green", "kind": "adult", "family": "green", "name": "Adult Green", "icon": "res://textures/food/dumplings.png" },
	{ "id": "adult_sweet", "kind": "adult", "family": "sweet", "name": "Adult Sweet", "icon": "res://textures/food/chococake.png" },
	{ "id": "adult_greasy", "kind": "adult", "family": "greasy", "name": "Adult Greasy", "icon": "res://textures/food/cheeseburger.png" },
	{ "id": "type_spicy", "kind": "type", "family": "spicy", "name": "Spicy foods", "icon": "res://textures/food/chili.png", "price": TYPE_PRICE },
	{ "id": "type_sour", "kind": "type", "family": "sour", "name": "Sour foods", "icon": "res://textures/food/lemon.png", "price": TYPE_PRICE },
	{ "id": "adult_spicy", "kind": "adult", "family": "spicy", "name": "Adult Spicy", "icon": "res://textures/food/ramen.png" },
	{ "id": "adult_sour", "kind": "adult", "family": "sour", "name": "Adult Sour", "icon": "res://textures/food/tomyum.png" },
	{ "id": "microchip", "kind": "special", "food": "Microchip", "name": "Microchip", "icon": "res://textures/food/microchip.png", "price": 15 },
	{ "id": "battery", "kind": "special", "food": "Battery", "name": "Battery", "icon": "res://textures/food/battery.png", "price": 15 },
	{ "id": "aliengoo", "kind": "special", "food": "Alien Goo", "name": "Alien Goo", "icon": "res://textures/food/aliengoo.png", "price": 15 },
	{ "id": "moonrock", "kind": "special", "food": "Moon Rock", "name": "Moon Rock", "icon": "res://textures/food/moonrock.png", "price": 15 },
	{ "id": "goldenseed", "kind": "special", "food": "Golden Seed", "name": "Golden Seed", "icon": "res://textures/food/goldenseed.png", "price": 40 },
	{ "id": "stardustsugar", "kind": "special", "food": "Stardust Sugar", "name": "Stardust Sugar", "icon": "res://textures/food/stardustsugar.png", "price": 40 },
	{ "id": "dragonoil", "kind": "special", "food": "Dragon Oil", "name": "Dragon Oil", "icon": "res://textures/food/dragonoil.png", "price": 40 },
	{ "id": "phoenixpepper", "kind": "special", "food": "Phoenix Pepper", "name": "Phoenix Pepper", "icon": "res://textures/food/phoenixpepper.png", "price": 40 },
	{ "id": "krakenbrine", "kind": "special", "food": "Kraken Brine", "name": "Kraken Brine", "icon": "res://textures/food/krakenbrine.png", "price": 40 },
]

var types: Array = FREE_TYPES.duplicate()     # food types on offer
var adult: Array = []                         # types whose adult foods you have
var pantry := {}                              # special food name -> how many

func _ready() -> void:
	load_data()
	if RESET_ON_LAUNCH:
		types = FREE_TYPES.duplicate()
		adult = []
		pantry = {}
		save_data()

func item(id: String) -> Dictionary:
	for it in ITEMS:
		if it["id"] == id:
			return it
	return {}

func has_type(family: String) -> bool:
	return family in types

func has_adult(family: String) -> bool:
	return family in adult

func pantry_count(food_name: String) -> int:
	return int(pantry.get(food_name, 0))

## What an item costs right now (adult foods: 20, then 10 more for each type you already have)
func price(it: Dictionary) -> int:
	if it.get("kind", "") == "adult":
		return ADULT_FIRST_PRICE + ADULT_STEP * adult.size()
	return int(it.get("price", 0))

## "owned" (a one-time item you have), "needs_type" (adult foods of a type you don't have),
## "ok" (you can buy it), "poor" (not enough coins)
func state(it: Dictionary) -> String:
	match it.get("kind", ""):
		"type":
			if has_type(it["family"]):
				return "owned"
		"adult":
			if has_adult(it["family"]):
				return "owned"
			if not has_type(it["family"]):
				return "needs_type"
	return "ok" if GameData.coins >= price(it) else "poor"

## Buys an item. Returns true if it was bought.
func buy(id: String) -> bool:
	var it := item(id)
	if it.is_empty() or state(it) != "ok":
		return false
	if not GameData.spend_coins(price(it)):
		return false
	match it["kind"]:
		"type":
			types.append(it["family"])
		"adult":
			adult.append(it["family"])
		"special":
			pantry[it["food"]] = pantry_count(it["food"]) + 1
	save_data()
	changed.emit()
	return true

## A special food was eaten: one less in the pantry
func use_special(food_name: String) -> void:
	if pantry_count(food_name) <= 0:
		return
	pantry[food_name] = pantry_count(food_name) - 1
	if pantry[food_name] <= 0:
		pantry.erase(food_name)
	save_data()
	changed.emit()

## A special food given for free (a vault, a daily request...)
func give_special(food_name: String, n := 1) -> void:
	pantry[food_name] = pantry_count(food_name) + n
	save_data()
	changed.emit()

func save_data() -> void:
	var file = FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify({ "types": types, "adult": adult, "pantry": pantry }))

func load_data() -> void:
	if not FileAccess.file_exists(SAVE_PATH):
		return
	var file = FileAccess.open(SAVE_PATH, FileAccess.READ)
	if not file:
		return
	var parsed = JSON.parse_string(file.get_as_text())
	if parsed is Dictionary:
		types = parsed.get("types", FREE_TYPES.duplicate())
		for f in FREE_TYPES:
			if f not in types:
				types.append(f)
		adult = parsed.get("adult", [])
		pantry = {}
		var p = parsed.get("pantry", {})
		if p is Dictionary:
			for k in p:
				pantry[str(k)] = int(p[k])
