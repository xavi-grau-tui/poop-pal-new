extends Node
## Autoload "Shop" (Progression v2 + the skeleton, docs/progression.md): what coins buy besides
## games (games are bought in the Games menu). Opened from the gear menu's SHOP card
## (collection_menu.gd). Three SECTIONS, each a run of pages:
##
##   FOOD & DRINKS  food packs: one type's foods of one size (baby / kid / adult): a pal grows only
##                  on food of its next size, so each pack opens new pals. At the start (user,
##                  2026-10-10): baby foods of 3 types, kid foods of 2, adult foods of 1, so the first
##                  pal can grow all the way up; the other 9 packs are bought (2 baby, 3 kid, 4 adult).
##                  A pack costs by its size, like its icons: baby 10, kid 15, adult 20 (145 in all).
##                  special foods: key items, kept in a pantry (each one = one meal): tech and cosmic
##                  turn an adult into its family's mutant, a legendary food turns its ULTRA adult into
##                  a legend. On sale once you've FOUND it in a game (its place tells its story first)
##                  or, without that, from a star total (no game is ever required); the shelf holds
##                  one of each kind and restocks every day. A special that can't make a new pal any
##                  more turns into its price in coins (no prize is ever a dead one).
##                  drink levels: level 2 and 3 of a drink type you have, for good (10 / 20).
##   HOME           (the hokora) a few plain pieces for the home and its sky: white and indigo
##                  lanterns, a noren, fairy lights, candles, stone lanterns, a bonsai, plain skies,
##                  two wood colours (HokoraCatalog's items with a "price"); every themed piece is
##                  won. Opens once the first home piece is yours (Splash Hoops' 5 stars).
##   STICKERS       a sticker of every pal you've found (Sho and Chu: the sticker book's pages), 5
##                  each; the themed ones are only won. Opens once the first sticker is won.
##   CASES          plain cases, 40 each; the themed ones are only won. Opens once the first case
##                  arrives (a gift).
## What your spirit WEARS (dress-ups) is never sold: gifts for playing.

signal changed

const SAVE_FILE := "shop.json"           # (in SaveSlot.path)
## Prototype/testing: every launch starts with only the starting foods and an empty pantry
const RESET_ON_LAUNCH := true

const TIERS := ["baby", "kid", "adult"]
## The foods you have from the start: which types, per size
const START_FOODS := { "baby": ["green", "sweet", "greasy"], "kid": ["green", "sweet"], "adult": ["green"] }
const PACK_PRICE := { "baby": 10, "kid": 15, "adult": 20 }
const DRINK_PRICE := { 2: 10, 3: 20 }
const STICKER_PRICE := 5
## Special foods: on sale without having found one, from these star totals
const SPECIAL_STARS := { "tech": 350, "cosmic": 350, "legend": 450 }
## The special shelf: how many of each kind a day
const DAILY_STOCK := { "tech": 1, "cosmic": 1, "legend": 1 }
const SECTIONS := ["food", "home", "stickers", "cases"]
const SECTION_NAMES := { "food": "Food & Drinks", "home": "Home", "stickers": "Stickers", "cases": "Cases" }
const Hokora := preload("res://scripts/hokora_catalog.gd")

## Food packs and special foods, in a fixed order (the Shop shows the packs your pal needs next first)
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
var drink_lvl := {}                           # drink type -> its level (1-3; 1 when not bought)
var met := []                                 # special foods you've had at least once (found in a game, or bought)
var stock := {}                               # special kind -> how many left on today's shelf
var stock_day := ""                           # the day the shelf was last stocked ("2026-10-16")

func _ready() -> void:
	_start()
	PetState.pal_discovered.connect(func(_id): convert_spares())

## Loads the save again (BOOT + PROGRESSION, once its folder is in use: nothing reset)
func reload() -> void:
	_start()

func _start() -> void:
	foods = START_FOODS.duplicate(true)
	pantry = {}
	drink_lvl = {}
	met = []
	stock = {}
	stock_day = ""
	load_data()
	if RESET_ON_LAUNCH and not SaveSlot.real():
		foods = START_FOODS.duplicate(true)
		pantry = {}
		drink_lvl = {}
		met = []
		stock = {}
		stock_day = ""
		save_data()
	_restock()

## Every item for sale: the food and special items, the drink levels, the pal stickers and the
## plain cases (each a Dictionary with id, kind, name, section)
func all_items() -> Array:
	var out := []
	for it in ITEMS:
		var d: Dictionary = it.duplicate()
		d["section"] = "food"
		out.append(d)
	for t in DrinkLibrary.TYPES:
		for lvl in [2, 3]:
			var dr := DrinkLibrary.drink_of(t, lvl)
			out.append({ "id": "drink_%s_%d" % [t, lvl], "kind": "drink", "type": t, "level": lvl, "name": dr.get("name", t), "section": "food" })
	for cat in ["decor", "backgrounds"]:
		var src: Dictionary = Hokora.DECOR if cat == "decor" else Hokora.SKY
		for id in Hokora.order(cat):
			if src[id].has("price"):
				out.append({ "id": "home_" + id, "kind": "home", "piece": id, "category": cat, "name": src[id]["name"], "section": "home" })
	for id in Collection.PAL_STICKERS:
		out.append({ "id": "sticker_" + id, "kind": "sticker", "sticker": id, "name": PetState.FORMS.get(id, {}).get("name", id), "section": "stickers" })
	for id in Collection.CASES:
		if Collection.CASES[id].has("price"):
			out.append({ "id": "case_" + id, "kind": "case", "case": id, "name": Collection.CASES[id]["name"], "section": "cases" })
	return out

func item(id: String) -> Dictionary:
	for it in all_items():
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

## A drink type's level (1 = the drink it comes with)
func drink_level(type: String) -> int:
	return int(drink_lvl.get(type, 1))

func pantry_count(food_name: String) -> int:
	return int(pantry.get(food_name, 0))

func price(it: Dictionary) -> int:
	match it.get("kind", ""):
		"food":
			return food_price(it["tier"])
		"drink":
			return int(DRINK_PRICE.get(int(it["level"]), 0))
		"sticker":
			return STICKER_PRICE
		"case":
			return int(Collection.CASES.get(it["case"], {}).get("price", 0))
		"home":
			return int(Collection.find_item(it["category"], it["piece"]).get("price", 0))
	return int(it.get("price", 0))

## "owned" (you have it for good), "ok" (you can buy it), "poor" (not enough coins), "out" (a
## special: the day's shelf is empty, more tomorrow)
func state(it: Dictionary) -> String:
	match it.get("kind", ""):
		"food":
			if has_food(it["family"], it["tier"]):
				return "owned"
		"drink":
			if drink_level(it["type"]) >= int(it["level"]):
				return "owned"
		"sticker":
			if Collection.is_owned("stickers", it["sticker"]):
				return "owned"
		"case":
			if Collection.is_owned("cases", it["case"]):
				return "owned"
		"home":
			if Collection.is_owned(it["category"], it["piece"]):
				return "owned"
		"special":
			if int(stock.get(special_kind(it["food"]), 0)) <= 0:
				return "out"
	return "ok" if GameData.coins >= price(it) else "poor"

## How far the player has got: the biggest size any pal has reached (0 = none yet, 1 Sho, 2 Chu,
## 3 Dai or more). The Shop grows with it.
func stage_reached() -> int:
	var best := 0
	for id in PetState.discovered:
		best = maxi(best, mini(3, int(PetState.FORMS.get(id, {}).get("stage", 0))))
	return best

func total_stars() -> int:
	var n := 0
	for idx in GameData.games:
		n += GameData.game_stars(idx)
	return n

## A special food's kind: "tech", "cosmic" or "legend"
func special_kind(food_name: String) -> String:
	for f in FoodLibrary.SPECIALS:
		if f["name"] == food_name:
			return f["family"]
	return ""

func _special(food_name: String) -> Dictionary:
	for f in FoodLibrary.SPECIALS:
		if f["name"] == food_name:
			return f
	return {}

## A section is open (HOME once a home piece is yours, in a shrine; STICKERS once a sticker is won,
## CASES once a case is yours)
func section_open(section: String) -> bool:
	match section:
		"home":
			return Collection.in_shrine() and Collection.home_pieces_won() > 0
		"stickers":
			return not Collection.owned.get("stickers", []).is_empty()
		"cases":
			return not Collection.owned.get("cases", []).is_empty()
	return true

## Is it on sale yet? (progressive: only what the player can use soon)
##   food packs   a size once a pal is about to need it (Sho from the start, Chu once a Sho pal
##                has existed, Dai once a Chu has); packs you have are not shown
##   tech/cosmic  once a pal has reached Dai (they only work on a Dai), and you've found it in a
##                game (or have the stars); legendary: once its family's ULTRA Dai has been found
##   drink levels the next level of a drink type you have
##   stickers     the pals you've found (their sticker); cases: the plain ones
func on_sale(it: Dictionary) -> bool:
	if DevLaunch.all_open:
		return true                               # (ALL UNLOCKED: the whole Shop, to look through)
	if not section_open(it.get("section", "food")):
		return false
	match it.get("kind", ""):
		"food":
			return not has_food(it["family"], it["tier"]) and TIERS.find(it["tier"]) <= stage_reached()
		"special":
			var sp := _special(it["food"])
			var kind: String = sp.get("family", "")
			if it["food"] not in met and total_stars() < int(SPECIAL_STARS.get(kind, 9999)):
				return false
			if not special_useful(it["food"]):
				return false                      # (everyone it makes is found: nothing left to buy it for)
			if kind != "legend":
				return stage_reached() >= 3
			for ultra in PetState.LEGENDS:
				if ultra in PetState.discovered and PetState.LEGENDS[ultra].get("family", "") == sp.get("legend_of", ""):
					return true
			return false
		"drink":
			var t: String = it["type"]
			return t in DrinkLibrary.owned_types() and drink_level(t) == int(it["level"]) - 1
		"sticker":
			return it["sticker"] in PetState.discovered and not Collection.is_owned("stickers", it["sticker"])
		"case":
			return not Collection.is_owned("cases", it["case"])
		"home":
			return not Collection.is_owned(it["category"], it["piece"])
	return true

## A special food could still make a pal you haven't found (a tech one: any family's tech mutant;
## a legendary one: its own legend)
func special_useful(food_name: String) -> bool:
	var sp := _special(food_name)
	var kind: String = sp.get("family", "")
	if kind == "legend":
		for ultra in PetState.LEGENDS:
			var lg: Dictionary = PetState.LEGENDS[ultra]
			if lg.get("family", "") == sp.get("legend_of", "") and lg.get("to", "") not in PetState.discovered:
				return true
		return false
	for from in PetState.NEXT:
		var to: String = PetState.NEXT[from].get(kind, "")
		if to != "" and to not in PetState.discovered:
			return true
	return false

## A food type you have no food of yet (its pack is a NEW type for the player)
func new_type(family: String) -> bool:
	for tier in TIERS:
		if has_food(family, tier):
			return false
	return true

## The items on sale, section by section; in FOOD & DRINKS the packs for the size your pal needs
## next first (then the next size, then the rest), the special foods, the drink levels
func shop_order() -> Array:
	var need := FoodLibrary.tier_now()
	var rank := func(it: Dictionary) -> int:
		match it["kind"]:
			"food":
				if state(it) == "owned":
					return 90
				var t := TIERS.find(it["tier"]) - TIERS.find(need)
				return t if t >= 0 else 10 + t + 3
			"special":
				return 50
			"drink":
				return 60
		return 0
	var order := all_items().filter(func(it): return on_sale(it))
	var idx := {}
	var all := all_items()
	for i in all.size():
		idx[all[i]["id"]] = i
	order.sort_custom(func(a, b):
		var sa := SECTIONS.find(a["section"])
		var sb := SECTIONS.find(b["section"])
		if sa != sb:
			return sa < sb
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
			if it["food"] not in met:
				met.append(it["food"])
			var kind := special_kind(it["food"])
			stock[kind] = maxi(0, int(stock.get(kind, 0)) - 1)
		"drink":
			drink_lvl[it["type"]] = int(it["level"])
		"sticker":
			Collection.unlock("stickers", it["sticker"])
		"case":
			Collection.unlock("cases", it["case"])
		"home":
			Collection.unlock(it["category"], it["piece"])
	save_data()
	changed.emit()
	return true

## Has a special food ever been yours (found in a game, or bought)? The food menu's specials page
## is only there from then on (the user, 2026-10-17)
func specials_found() -> bool:
	return not met.is_empty() or not pantry.is_empty()

## A special food was eaten: one less in the pantry
func use_special(food_name: String) -> void:
	if pantry_count(food_name) <= 0:
		return
	pantry[food_name] = pantry_count(food_name) - 1
	if pantry[food_name] <= 0:
		pantry.erase(food_name)
	save_data()
	changed.emit()

## A special food given for free (found in a game: a vault, a boss, a finale; a daily request...).
## Returns the coins it turned into if it can't make anyone new any more (0 = it's in the pantry).
func give_special(food_name: String, n := 1) -> int:
	if food_name not in met:
		met.append(food_name)
	if not special_useful(food_name):
		var coins := n * int(item_for_food(food_name).get("price", 15))
		GameData.add_coins(coins)
		save_data()
		changed.emit()
		return coins
	pantry[food_name] = pantry_count(food_name) + n
	save_data()
	changed.emit()
	return 0

func item_for_food(food_name: String) -> Dictionary:
	for it in ITEMS:
		if it.get("food", "") == food_name:
			return it
	return {}

## Specials in the pantry that can't make a new pal any more turn into their price in coins
func convert_spares() -> void:
	var gained := 0
	for food_name in pantry.keys():
		if not special_useful(food_name):
			gained += pantry_count(food_name) * int(item_for_food(food_name).get("price", 15))
			pantry.erase(food_name)
	if gained > 0:
		GameData.add_coins(gained)
		save_data()
		changed.emit()

## The special shelf restocks once a day
func _restock() -> void:
	var today := Time.get_date_string_from_system()
	if stock_day == today and not stock.is_empty():
		return
	stock_day = today
	stock = DAILY_STOCK.duplicate()
	save_data()

func save_data() -> void:
	var file = FileAccess.open(SaveSlot.path(SAVE_FILE), FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify({ "foods": foods, "pantry": pantry, "drink_lvl": drink_lvl, "met": met,
			"stock": stock, "stock_day": stock_day }))

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
		drink_lvl = {}
		var dl = parsed.get("drink_lvl", {})
		if dl is Dictionary:
			for k in dl:
				drink_lvl[str(k)] = clampi(int(dl[k]), 1, 3)
		met = []
		for m in parsed.get("met", []):
			met.append(str(m))
		stock = {}
		var st = parsed.get("stock", {})
		if st is Dictionary:
			for k in st:
				stock[str(k)] = int(st[k])
		stock_day = str(parsed.get("stock_day", ""))
