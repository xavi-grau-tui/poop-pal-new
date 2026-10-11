# FoodLibrary.gd
extends Node
## Every food: 5 types x 3 sizes (Sho / Chu / Dai = baby / kid / adult in the code) x 3 = 45
## (Progression v2, the art from docs/mockups/food_drafts/: the first 30, then one more per type
## and size for variety (foods_v3.py, 2026-10-11); the 8 original foods and the glazed donut kept).
##
## Foods grow up with the pal: a pal grows only by eating food of its NEXT size. No pal = baby
## foods (they hatch it), a baby = kid foods, a kid = adult foods, an adult (or more) = any food
## (just eaten; the special page turns it into a mutant or a legend).
## Which types' foods of each size you have: the Shop (3 baby, 2 kid, 1 adult at the start).
## Nothing on the menu is left to chance: it lists every type you have for that size, always in
## the same order, then the ones still in the Shop as locked cards.

const FOODS := [
	# --- green
	{ "name": "Broccoli", "family": "green", "tier": "baby", "icon": "res://textures/food/broccoli.png", "kcal": 35 },
	{ "name": "Avocado", "family": "green", "tier": "baby", "icon": "res://textures/food/avocado.png", "kcal": 160 },
	{ "name": "Edamame", "family": "green", "tier": "baby", "icon": "res://textures/food/edamame.png", "kcal": 120 },
	{ "name": "Rice and Vegs", "family": "green", "tier": "kid", "icon": "res://textures/food/brownricevegs.png", "kcal": 320 },
	{ "name": "Salad Bowl", "family": "green", "tier": "kid", "icon": "res://textures/food/saladbowl.png", "kcal": 160 },
	{ "name": "Avocado Toast", "family": "green", "tier": "kid", "icon": "res://textures/food/avocadotoast.png", "kcal": 280 },
	{ "name": "Cucumber Sushi", "family": "green", "tier": "adult", "icon": "res://textures/food/cucumbersushi.png", "kcal": 250 },
	{ "name": "Dumplings", "family": "green", "tier": "adult", "icon": "res://textures/food/dumplings.png", "kcal": 280 },
	{ "name": "Veggie Bento", "family": "green", "tier": "adult", "icon": "res://textures/food/bento.png", "kcal": 450 },
	# --- sweet (chocolate first)
	{ "name": "Chocolate", "family": "sweet", "tier": "baby", "icon": "res://textures/food/chocolate.png", "kcal": 230 },
	{ "name": "Cookie", "family": "sweet", "tier": "baby", "icon": "res://textures/food/cookie.png", "kcal": 160 },
	{ "name": "Candy", "family": "sweet", "tier": "baby", "icon": "res://textures/food/candy.png", "kcal": 60 },
	{ "name": "Glazed Donut", "family": "sweet", "tier": "kid", "icon": "res://textures/food/donut.png", "kcal": 290 },
	{ "name": "Rainbow Jelly", "family": "sweet", "tier": "kid", "icon": "res://textures/food/rainbowjelly.png", "kcal": 180 },
	{ "name": "Ice Cream", "family": "sweet", "tier": "kid", "icon": "res://textures/food/icecream.png", "kcal": 210 },
	{ "name": "Choco Cake", "family": "sweet", "tier": "adult", "icon": "res://textures/food/chococake.png", "kcal": 420 },
	{ "name": "Purin", "family": "sweet", "tier": "adult", "icon": "res://textures/food/purin.png", "kcal": 260 },
	{ "name": "Pancakes", "family": "sweet", "tier": "adult", "icon": "res://textures/food/pancakes.png", "kcal": 520 },
	# --- greasy
	{ "name": "Fried Egg", "family": "greasy", "tier": "baby", "icon": "res://textures/food/friedegg.png", "kcal": 90 },
	{ "name": "Fries", "family": "greasy", "tier": "baby", "icon": "res://textures/food/fries.png", "kcal": 320 },
	{ "name": "Nugget", "family": "greasy", "tier": "baby", "icon": "res://textures/food/nugget.png", "kcal": 180 },
	{ "name": "Spaghetti", "family": "greasy", "tier": "kid", "icon": "res://textures/food/spaghetthi.png", "kcal": 500 },
	{ "name": "Hot Dog", "family": "greasy", "tier": "kid", "icon": "res://textures/food/hotdog.png", "kcal": 450 },
	{ "name": "Pizza Slice", "family": "greasy", "tier": "kid", "icon": "res://textures/food/pizzaslice.png", "kcal": 300 },
	{ "name": "Club Sandwich", "family": "greasy", "tier": "adult", "icon": "res://textures/food/clubsandwich.png", "kcal": 430 },
	{ "name": "Cheeseburger", "family": "greasy", "tier": "adult", "icon": "res://textures/food/cheeseburger.png", "kcal": 580 },
	{ "name": "Fish and Chips", "family": "greasy", "tier": "adult", "icon": "res://textures/food/fishchips.png", "kcal": 640 },
	# --- spicy
	{ "name": "Chili Pepper", "family": "spicy", "tier": "baby", "icon": "res://textures/food/chili.png", "kcal": 40 },
	{ "name": "Jalapeño", "family": "spicy", "tier": "baby", "icon": "res://textures/food/jalapeno.png", "kcal": 30 },
	{ "name": "Hot Sauce", "family": "spicy", "tier": "baby", "icon": "res://textures/food/hotsauce.png", "kcal": 15 },
	{ "name": "Fire Skewer", "family": "spicy", "tier": "kid", "icon": "res://textures/food/skewer.png", "kcal": 310 },
	{ "name": "Drumstick", "family": "spicy", "tier": "kid", "icon": "res://textures/food/drumstick.png", "kcal": 380 },
	{ "name": "Spicy Taco", "family": "spicy", "tier": "kid", "icon": "res://textures/food/taco.png", "kcal": 260 },
	{ "name": "Fire Ramen", "family": "spicy", "tier": "adult", "icon": "res://textures/food/ramen.png", "kcal": 520 },
	{ "name": "Curry Bowl", "family": "spicy", "tier": "adult", "icon": "res://textures/food/currybowl.png", "kcal": 540 },
	{ "name": "Tteokbokki", "family": "spicy", "tier": "adult", "icon": "res://textures/food/tteokbokki.png", "kcal": 480 },
	# --- sour
	{ "name": "Lemon", "family": "sour", "tier": "baby", "icon": "res://textures/food/lemon.png", "kcal": 30 },
	{ "name": "Pickle", "family": "sour", "tier": "baby", "icon": "res://textures/food/pickle.png", "kcal": 20 },
	{ "name": "Lime", "family": "sour", "tier": "baby", "icon": "res://textures/food/lime.png", "kcal": 20 },
	{ "name": "Kimchi", "family": "sour", "tier": "kid", "icon": "res://textures/food/kimchi.png", "kcal": 90 },
	{ "name": "Umeboshi", "family": "sour", "tier": "kid", "icon": "res://textures/food/umeboshi.png", "kcal": 60 },
	{ "name": "Kiwi", "family": "sour", "tier": "kid", "icon": "res://textures/food/kiwi.png", "kcal": 45 },
	{ "name": "Tom Yum", "family": "sour", "tier": "adult", "icon": "res://textures/food/tomyum.png", "kcal": 220 },
	{ "name": "Pickle Jar", "family": "sour", "tier": "adult", "icon": "res://textures/food/picklejar.png", "kcal": 120 },
	{ "name": "Ceviche", "family": "sour", "tier": "adult", "icon": "res://textures/food/ceviche.png", "kcal": 200 },
]

const FAMILIES := ["green", "sweet", "greasy", "spicy", "sour"]
## What a pal of each stage needs to grow (0 = no pal yet): the food menu shows this size
const TIER_FOR_STAGE := { 0: "baby", 1: "kid", 2: "adult" }

## Exotic and legendary foods: the food menu's third page (they can't start a pal;
## tech / cosmic turn an adult into a mutant, a legendary food turns the right ULTRA adult
## into a legend). They are key items: only the ones in your pantry (Shop) are offered.
const SPECIALS := [
	{ "name": "Microchip", "family": "tech", "icon": "res://textures/food/microchip.png", "kcal": 1 },
	{ "name": "Battery", "family": "tech", "icon": "res://textures/food/battery.png", "kcal": 2 },
	{ "name": "Alien Goo", "family": "cosmic", "icon": "res://textures/food/aliengoo.png", "kcal": 66 },
	{ "name": "Moon Rock", "family": "cosmic", "icon": "res://textures/food/moonrock.png", "kcal": 0 },
	{ "name": "Golden Seed", "family": "legend", "legend_of": "green", "icon": "res://textures/food/goldenseed.png", "kcal": 999 },
	{ "name": "Stardust Sugar", "family": "legend", "legend_of": "sweet", "icon": "res://textures/food/stardustsugar.png", "kcal": 999 },
	{ "name": "Dragon Oil", "family": "legend", "legend_of": "greasy", "icon": "res://textures/food/dragonoil.png", "kcal": 999 },
	{ "name": "Phoenix Pepper", "family": "legend", "legend_of": "spicy", "icon": "res://textures/food/phoenixpepper.png", "kcal": 999 },
	{ "name": "Kraken Brine", "family": "legend", "legend_of": "sour", "icon": "res://textures/food/krakenbrine.png", "kcal": 999 },
]

var all_foods: Array = []
var special_foods: Array = []

func _ready() -> void:
	for f in FOODS:
		var d: Dictionary = f.duplicate()
		d["icon"] = load(f["icon"])
		all_foods.append(d)
	for f in SPECIALS:
		var d: Dictionary = f.duplicate()
		d["icon"] = load(f["icon"])
		special_foods.append(d)

## The size of food the current pal needs ("adult" for an adult or more: just eaten)
func tier_now() -> String:
	var stage := int(PetState.get_form().get("stage", 0)) if PetState.has_poop() else 0
	return TIER_FOR_STAGE.get(stage, "adult")

## The type's foods of a size take turns, meal after meal (the first one listed first: a
## first-ever sweet meal is the chocolate)
func _pick(family: String, tier: String) -> Dictionary:
	var pool := all_foods.filter(func(f): return f["family"] == family and f["tier"] == tier)
	if pool.is_empty():
		return {}
	return pool[PetState.meals_total % pool.size()]

## The food menu's cards: every type whose foods of the size the pal needs you have, in the
## types' order (FAMILIES), then a locked card ("locked": true, a silhouette) for each type still
## in the Shop. An adult (or more) no longer grows on basic food: every type you have, its biggest
## size, and no locked cards.
func get_menu_set() -> Array:
	var stage := int(PetState.get_form().get("stage", 0)) if PetState.has_poop() else 0
	var result := []
	if stage >= 3:
		for fam in FAMILIES:
			for tier in ["adult", "kid", "baby"]:
				if Shop.has_food(fam, tier):
					result.append(_pick(fam, tier))
					break
		return result
	var tier := tier_now()
	var locked := []
	for fam in FAMILIES:
		var f := _pick(fam, tier)
		if f.is_empty():
			continue
		if Shop.has_food(fam, tier):
			result.append(f)
		else:
			var lock: Dictionary = f.duplicate()
			lock["locked"] = true
			locked.append(lock)
	return result + locked

## The special page: a tech, a cosmic and a legendary card, each the first one in your pantry
## (the legendary one: the current pal's own if you have it). None of a kind = a locked card.
func get_special_set() -> Array:
	var result := []
	var lg: Dictionary = PetState.LEGENDS.get(PetState.form_id, {})
	for kind in ["tech", "cosmic", "legend"]:
		var owned := special_foods.filter(func(f): return f["family"] == kind and Shop.pantry_count(f["name"]) > 0)
		if kind == "legend" and lg.get("to") != null and lg.has("family"):
			var own := owned.filter(func(f): return f["legend_of"] == lg["family"])
			if not own.is_empty():
				owned = own
		if owned.is_empty():
			result.append({ "name": "???", "family": kind, "icon": UiArt.question(), "locked": true, "special_locked": true })
		else:
			result.append(owned[0])
	return result

## Can the current pal use this special food right now? (so a key item is never wasted)
func special_useful(food: Dictionary) -> bool:
	if not PetState.has_poop():
		return false
	return PetState.evolution_for(food) != ""
