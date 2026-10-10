extends Node
## Autoload "Shop" (Progression v2): what coins buy besides games (games are bought in the
## Games menu). Opened from the gear menu's SHOP card (collection_menu.gd).
##
##   food packs     one type's foods of one size (baby / kid / adult): a pal grows only on food of
##                  its next size, so each pack opens new pals. At the start (user, 2026-10-10):
##                  baby foods of 3 types, kid foods of 2, adult foods of 1, so the first pal can
##                  grow all the way up; the other 9 packs are bought (2 baby, 3 kid, 4 adult).
##                  A pack costs by its size, like its icons: baby 10, kid 15, adult 20 (145 in all).
##   special foods  key items, kept in a pantry (each one = one meal): tech and cosmic turn an
##                  adult into its family's mutant, a legendary food turns its ULTRA adult into
##                  a legend. Only offered on the food menu's special page while you have some.
## Cosmetics are never sold here (they are gifts for playing: Collection.REWARDS).

signal changed

const SAVE_FILE := "shop.json"           # (in SaveSlot.path)
## Prototype/testing: every launch starts with only the starting foods and an empty pantry
const RESET_ON_LAUNCH := true

const TIERS := ["baby", "kid", "adult"]
## The foods you have from the start: which types, per size
const START_FOODS := { "baby": ["green", "sweet", "greasy"], "kid": ["green", "sweet"], "adult": ["green"] }
const PACK_PRICE := { "baby": 10, "kid": 15, "adult": 20 }

## Everything on sale, in a fixed order (the Shop shows the packs your pal needs next first)
const ITEMS := [
	{ "id": "baby_spicy", "kind": "food", "family": "spicy", "tier": "baby", "name": "Spicy Baby", "icon": "res://textures/food/chili.png" },
	{ "id": "baby_sour", "kind": "food", "family": "sour", "tier": "baby", "name": "Sour Baby", "icon": "res://textures/food/lemon.png" },
	{ "id": "kid_greasy", "kind": "food", "family": "greasy", "tier": "kid", "name": "Greasy Kid", "icon": "res://textures/food/hotdog.png" },
	{ "id": "kid_spicy", "kind": "food", "family": "spicy", "tier": "kid", "name": "Spicy Kid", "icon": "res://textures/food/skewer.png" },
	{ "id": "kid_sour", "kind": "food", "family": "sour", "tier": "kid", "name": "Sour Kid", "icon": "res://textures/food/umeboshi.png" },
	{ "id": "adult_sweet", "kind": "food", "family": "sweet", "tier": "adult", "name": "Sweet Adult", "icon": "res://textures/food/chococake.png" },
	{ "id": "adult_greasy", "kind": "food", "family": "greasy", "tier": "adult", "name": "Greasy Adult", "icon": "res://textures/food/cheeseburger.png" },
	{ "id": "adult_spicy", "kind": "food", "family": "spicy", "tier": "adult", "name": "Spicy Adult", "icon": "res://textures/food/ramen.png" },
	{ "id": "adult_sour", "kind": "food", "family": "sour", "tier": "adult", "name": "Sour Adult", "icon": "res://textures/food/tomyum.png" },
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

var foods := {}                               # size -> the types whose foods of that size you have
var pantry := {}                              # special food name -> how many

func _ready() -> void:
	_start()

## Loads the save again (BOOT + PROGRESSION, once its folder is in use: nothing reset)
func reload() -> void:
	_start()

func _start() -> void:
	foods = START_FOODS.duplicate(true)
	pantry = {}
	load_data()
	if RESET_ON_LAUNCH and not SaveSlot.real():
		foods = START_FOODS.duplicate(true)
		pantry = {}
		save_data()

func item(id: String) -> Dictionary:
	for it in ITEMS:
		if it["id"] == id:
			return it
	return {}

## Do you have this type's foods of this size?
func has_food(family: String, tier: String) -> bool:
	return family in foods.get(tier, [])

## Food packs bought so far (the starting foods don't count)
func packs_bought() -> int:
	var n := 0
	for tier in TIERS:
		for fam in foods.get(tier, []):
			if fam not in START_FOODS[tier]:
				n += 1
	return n

## What a food pack of this size costs
func food_price(tier: String) -> int:
	return int(PACK_PRICE.get(tier, 0))

func pantry_count(food_name: String) -> int:
	return int(pantry.get(food_name, 0))

func price(it: Dictionary) -> int:
	if it.get("kind", "") == "food":
		return food_price(it["tier"])
	return int(it.get("price", 0))

## "owned" (a food pack you have), "ok" (you can buy it), "poor" (not enough coins)
func state(it: Dictionary) -> String:
	if it.get("kind", "") == "food" and has_food(it["family"], it["tier"]):
		return "owned"
	return "ok" if GameData.coins >= price(it) else "poor"

## How far the player has got: the biggest size any pal has reached (0 = none yet, 1 Sho, 2 Chu,
## 3 Dai or more). The Shop grows with it.
func stage_reached() -> int:
	var best := 0
	for id in PetState.discovered:
		best = maxi(best, mini(3, int(PetState.FORMS.get(id, {}).get("stage", 0))))
	return best

## Is it on sale yet? (progressive: only what the player can use soon)
##   food packs   a size once a pal is about to need it (Sho from the start, Chu once a Sho pal
##                has existed, Dai once a Chu has); packs you have are not shown
##   tech/cosmic  once a pal has reached Dai (they only work on a Dai)
##   legendary    once its family's ULTRA Dai has been found
func on_sale(it: Dictionary) -> bool:
	match it.get("kind", ""):
		"food":
			return not has_food(it["family"], it["tier"]) and TIERS.find(it["tier"]) <= stage_reached()
		"special":
			var sp: Dictionary = {}
			for f in FoodLibrary.SPECIALS:
				if f["name"] == it["food"]:
					sp = f
			if sp.get("family", "") != "legend":
				return stage_reached() >= 3
			for ultra in PetState.LEGENDS:
				if ultra in PetState.discovered and PetState.LEGENDS[ultra].get("family", "") == sp.get("legend_of", ""):
					return true
			return false
	return true

## A food type you have no food of yet (its pack is a NEW type for the player)
func new_type(family: String) -> bool:
	for tier in TIERS:
		if has_food(family, tier):
			return false
	return true

## The items in the order the Shop shows them: the food packs for the size your pal needs next
## first (then the next size, then the rest), the ones you have last; the special foods after
func shop_order() -> Array:
	var need := FoodLibrary.tier_now()
	var rank := func(it: Dictionary) -> int:
		if it["kind"] != "food":
			return 50
		if state(it) == "owned":
			return 90
		var t := TIERS.find(it["tier"]) - TIERS.find(need)
		return t if t >= 0 else 10 + t + 3
	var order := ITEMS.filter(func(it): return on_sale(it))
	var idx := {}
	for i in ITEMS.size():
		idx[ITEMS[i]["id"]] = i
	order.sort_custom(func(a, b):
		var ra: int = rank.call(a)
		var rb: int = rank.call(b)
		return ra < rb if ra != rb else idx[a["id"]] < idx[b["id"]])
	return order

## Buys an item. Returns true if it was bought.
func buy(id: String) -> bool:
	var it := item(id)
	if it.is_empty() or state(it) != "ok":
		return false
	if not GameData.spend_coins(price(it)):
		return false
	match it["kind"]:
		"food":
			foods[it["tier"]].append(it["family"])
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
	var file = FileAccess.open(SaveSlot.path(SAVE_FILE), FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify({ "foods": foods, "pantry": pantry }))

func load_data() -> void:
	if not FileAccess.file_exists(SaveSlot.path(SAVE_FILE)):
		return
	var file = FileAccess.open(SaveSlot.path(SAVE_FILE), FileAccess.READ)
	if not file:
		return
	var parsed = JSON.parse_string(file.get_as_text())
	if parsed is Dictionary:
		foods = START_FOODS.duplicate(true)
		var f = parsed.get("foods", {})
		if f is Dictionary:
			for tier in TIERS:
				for fam in f.get(tier, []):
					if str(fam) not in foods[tier]:
						foods[tier].append(str(fam))
		pantry = {}
		var p = parsed.get("pantry", {})
		if p is Dictionary:
			for k in p:
				pantry[str(k)] = int(p[k])
