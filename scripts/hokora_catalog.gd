extends RefCounted
## The hokora's collectables (yokai migration, docs/progression.md section 5b): what the spirit's
## home and its sky can wear, where each piece comes from, and where its art goes. The gut's own
## catalogue (gut decor, gut colours, its sky scenes) stays in collection.gd, untouched: it comes
## back with the gut (the dev launcher's HOME: GUT). Collection reads this one in a shrine home.
##
## HOME DECOR, four slots that combine (one item each):
##   lantern  the pair of paper lanterns under the eaves (never empty: off = the red ones)
##   hanging  something across the front beam (a shimenawa, wind chimes, pennants...)
##   shelf    a pair on the stone slab, one each side of the offering stand
##   colour   the wood and the roof (a recolour by the shader, no new art: hokora_colour.gdshader)
## BACKGROUNDS, two slots:
##   sky      the sky's colours at dawn / day / dusk / night (it follows the real clock by itself)
##   drift    what drifts across it: the cloud layers (CloudA / CloudB) or particles (sky_drift.gd)
##
## Art: a piece is drawn from its own files when they exist, so a designer's PNG dropped in its
## place shows up by itself (docs/kami_collection_art.md lists every file):
##   lantern  ART_DIR/<id>.png (like the red lantern: 108 x 176, its hook at the top middle)
##   hanging  ART_DIR/<id>-1.png, -2.png (the front's 925 x 925 canvas, two frames of a sway)
##   shelf    ART_DIR/<id>.png, or <id>_left.png + <id>_right.png for a pair that differs (the
##            left one mirrored otherwise); standing on the slab, its foot at the bottom middle
##   icons    ART_DIR/icons/<id>.png (96 x 96, the menu card's picture)
## Until then: a lantern is the red one recoloured ("tint"), a colour is a shader preset, a sky
## set is only colours, a drift is a particle kind drawn in code; a hanging or shelf piece without
## its art shows nothing yet (its card says "art soon").

const ART_DIR := "res://textures/pet/shrine_new/decor/"

## "tint": [hue shift (turns), saturation x, value x] for the placeholder lantern; "glow": the candle
## through its paper. Colours: "wood", "roof", "moss", each [hue shift, saturation x, value x].
const DECOR := {
	# --- lanterns
	"lantern_red": { "name": "Red Lanterns", "kind": "lantern", "unlocked": true, "unlock": "", "glow": "#ffc270" },
	"lantern_goldfish": { "name": "Goldfish Lanterns", "kind": "lantern", "unlock": "Splash Hoops: 5 stars", "tint": [0.055, 1.0, 1.05], "glow": "#ffb060" },
	"lantern_white": { "name": "White Lanterns", "kind": "lantern", "unlock": "The Shop", "price": 20, "tint": [0.0, 0.1, 1.12], "glow": "#fff0d0" },
	"lantern_indigo": { "name": "Indigo Lanterns", "kind": "lantern", "unlock": "The Shop", "price": 20, "tint": [0.64, 0.6, 0.72], "glow": "#a8b8ff" },
	"lantern_festival": { "name": "Festival Lanterns", "kind": "lantern", "unlock": "Top Spin: 3-6", "tint": [0.97, 0.8, 1.0], "glow": "#ffb07a" },
	"lantern_jellyfish": { "name": "Jellyfish Lanterns", "kind": "lantern", "unlock": "Splash Hoops: 6-6", "tint": [0.75, 0.5, 1.12], "glow": "#d8b0ff" },
	"lantern_moon": { "name": "Moon Rabbit Lanterns", "kind": "lantern", "unlock": "Paper Sumo: 4-6", "tint": [0.56, 0.15, 1.08], "glow": "#e0e8ff" },
	"lantern_hozuki": { "name": "Hozuki Lanterns", "kind": "lantern", "unlock": "30 spirits found", "tint": [0.07, 1.2, 1.0], "glow": "#ff9a40" },
	"lantern_fox": { "name": "Fox-fire Lanterns", "kind": "lantern", "unlock": "70 spirits found", "tint": [0.53, 0.6, 1.1], "glow": "#90d8ff" },
	"lantern_daruma": { "name": "Daruma Lanterns", "kind": "lantern", "unlock": "Lucky Pinch", "tint": [0.985, 1.2, 0.9], "glow": "#ffb080" },
	"lantern_neon": { "name": "Neon Lanterns", "kind": "lantern", "unlock": "RC Prix 2177: 5 stars", "tint": [0.83, 1.3, 1.15], "glow": "#ff60e0" },
	"lantern_gold": { "name": "Gold Lanterns", "kind": "lantern", "unlock": "100 spirits found", "tint": [0.11, 0.9, 1.1], "glow": "#ffe080" },
	# --- hanging (across the front beam)
	"hang_none": { "name": "Nothing", "kind": "hanging", "unlocked": true, "unlock": "" },
	"hang_furin": { "name": "Wind Chimes", "kind": "hanging", "unlock": "Splash Hoops: 15 stars" },
	"hang_beads": { "name": "Glass Beads", "kind": "hanging", "unlock": "Tilt Maze: 15 stars" },
	"hang_pennants": { "name": "Racing Pennants", "kind": "hanging", "unlock": "RC Prix: 15 stars" },
	"hang_shimenawa": { "name": "Shimenawa", "kind": "hanging", "unlock": "Paper Sumo: 15 stars" },
	"hang_pinwheels": { "name": "Pinwheels", "kind": "hanging", "unlock": "Top Spin: 15 stars" },
	"hang_shells": { "name": "Shell Chimes", "kind": "hanging", "unlock": "Splash Hoops: 2-6" },
	"hang_teru": { "name": "Teru-teru Bozu", "kind": "hanging", "unlock": "Splash Hoops: 5-6" },
	"hang_glow": { "name": "Glow Spores", "kind": "hanging", "unlock": "Tilt Maze: 3-8" },
	"hang_cogs": { "name": "Cog Garland", "kind": "hanging", "unlock": "Tilt Maze: 5-6" },
	"hang_koinobori": { "name": "Carp Streamers", "kind": "hanging", "unlock": "RC Prix: 5-6" },
	"hang_cranes": { "name": "Thousand Cranes", "kind": "hanging", "unlock": "40 spirits found" },
	"hang_led": { "name": "LED Strip", "kind": "hanging", "unlock": "RC Prix 2177: 15 stars" },
	"hang_bunting": { "name": "Festival Flags", "kind": "hanging", "unlock": "Lucky Pinch" },
	"hang_noren": { "name": "Noren Curtain", "kind": "hanging", "unlock": "The Shop", "price": 25 },
	"hang_fairy": { "name": "Fairy Lights", "kind": "hanging", "unlock": "The Shop", "price": 25 },
	# --- shelf (a pair on the slab)
	"shelf_none": { "name": "Nothing", "kind": "shelf", "unlocked": true, "unlock": "" },
	"shelf_goldfish": { "name": "Goldfish Bowls", "kind": "shelf", "unlock": "Splash Hoops: 60 stars" },
	"shelf_puzzle": { "name": "Puzzle Boxes", "kind": "shelf", "unlock": "Tilt Maze: 60 stars" },
	"shelf_ema": { "name": "Ema Plaques", "kind": "shelf", "unlock": "RC Prix: 60 stars" },
	"shelf_origami": { "name": "Origami Cranes", "kind": "shelf", "unlock": "Paper Sumo: 60 stars" },
	"shelf_koma": { "name": "Koma Tops", "kind": "shelf", "unlock": "Top Spin: 60 stars" },
	"shelf_kappa": { "name": "Kappa Statues", "kind": "shelf", "unlock": "Tilt Maze: 4-6" },
	"shelf_sakaki": { "name": "Sakaki Vases", "kind": "shelf", "unlock": "20 spirits found" },
	"shelf_kitsune": { "name": "Fox Statues", "kind": "shelf", "unlock": "50 spirits found" },
	"shelf_komainu": { "name": "Komainu", "kind": "shelf", "unlock": "80 spirits found" },
	"shelf_tsukimi": { "name": "Moon-viewing Set", "kind": "shelf", "unlock": "110 spirits found" },
	"shelf_maneki": { "name": "Maneki-neko", "kind": "shelf", "unlock": "Lucky Pinch" },
	"shelf_neon_cat": { "name": "Neon Lucky Cats", "kind": "shelf", "unlock": "RC Prix 2177: 60 stars" },
	"shelf_candles": { "name": "Candles", "kind": "shelf", "unlock": "The Shop", "price": 15 },
	"shelf_stone": { "name": "Stone Lanterns", "kind": "shelf", "unlock": "The Shop", "price": 30 },
	"shelf_bonsai": { "name": "Bonsai", "kind": "shelf", "unlock": "The Shop", "price": 30 },
	# --- colours (the wood and the roof): the realms' colours come with their spirits
	"colour_cedar": { "name": "Weathered Cedar", "kind": "colour", "unlocked": true, "unlock": "" },
	"colour_moss": { "name": "Moss", "kind": "colour", "unlock": "10 Mountain spirits",
		"wood": [0.0, 0.85, 0.86], "roof": [0.22, 0.55, 0.78], "moss": [0.0, 1.1, 1.0] },
	"colour_vermilion": { "name": "Vermilion", "kind": "colour", "unlock": "10 Fox spirits",
		"wood": [-0.06, 1.55, 0.95], "roof": [0.58, 0.22, 0.62], "moss": [0.0, 0.9, 1.0] },
	"colour_lacquer": { "name": "Black Lacquer", "kind": "colour", "unlock": "10 Fire spirits",
		"wood": [0.0, 0.45, 0.36], "roof": [-0.01, 1.15, 0.72], "moss": [0.0, 0.8, 0.85] },
	"colour_copper": { "name": "Copper Roof", "kind": "colour", "unlock": "10 River spirits",
		"wood": [0.0, 0.62, 0.9], "roof": [0.44, 0.5, 0.86], "moss": [0.0, 1.0, 1.0] },
	"colour_moonwhite": { "name": "Moon White", "kind": "colour", "unlock": "10 Moon spirits",
		"wood": [0.0, 0.16, 1.06], "roof": [0.58, 0.32, 0.76], "moss": [0.0, 0.8, 1.05] },
	"colour_sakura": { "name": "Sakura Wood", "kind": "colour", "unlock": "Lucky Pinch",
		"wood": [-0.11, 0.62, 1.03], "roof": [-0.08, 0.7, 0.82], "moss": [0.0, 1.0, 1.0] },
	"colour_whitewash": { "name": "White-washed", "kind": "colour", "unlock": "The Shop", "price": 40,
		"wood": [0.0, 0.22, 1.07], "roof": [0.0, 1.0, 1.0], "moss": [0.0, 1.0, 1.0] },
	"colour_indigo": { "name": "Indigo", "kind": "colour", "unlock": "The Shop", "price": 40,
		"wood": [0.56, 0.55, 0.7], "roof": [0.56, 0.5, 0.74], "moss": [0.0, 0.9, 0.95] },
	"colour_gold": { "name": "Gold Leaf", "kind": "colour", "unlock": "All 120 spirits",
		"wood": [0.04, 1.45, 1.06], "roof": [0.1, 1.1, 1.0], "moss": [0.0, 1.0, 1.0] },
}
const DECOR_SECTIONS := ["lantern", "hanging", "shelf", "colour"]
const SECTION_NAMES := { "lantern": "Lanterns", "hanging": "Hanging", "shelf": "Shelf", "colour": "Colours", "sky": "Sky", "drift": "Clouds" }
## Each slot's item when nothing else is picked (picking the one in use goes back to it)
const DEFAULTS := { "lantern": "lantern_red", "hanging": "hang_none", "shelf": "shelf_none", "colour": "colour_cedar",
	"sky": "sky_shrine", "drift": "clouds" }

## The sky: "day", "dusk" (dawn too) and "night" colours (the sky picture's own colour is the
## default's day, #e5a5a6; the default's dusk and night are that pink under today's light).
## The drifting layer: "layers" (CloudA / CloudB, as the gut's sky scenes) or "particles".
const SKY := {
	"sky_shrine": { "name": "Shrine Pink", "kind": "sky", "unlocked": true, "unlock": "", "day": "#e5a5a6", "dusk": "#e58e7e", "night": "#856690" },
	"sky_lagoon": { "name": "Lagoon", "kind": "sky", "unlock": "Splash Hoops: 100 stars", "day": "#9fd3cf", "dusk": "#e8a48a", "night": "#3f5a7a" },
	"sky_mint": { "name": "Mint", "kind": "sky", "unlock": "Tilt Maze: 100 stars", "day": "#b5dcc0", "dusk": "#e6c79a", "night": "#4a6a68" },
	"sky_peach": { "name": "Peach", "kind": "sky", "unlock": "RC Prix: 100 stars", "day": "#f2c2a0", "dusk": "#ec9a78", "night": "#6e5878" },
	"sky_teal": { "name": "Teal", "kind": "sky", "unlock": "Paper Sumo: 100 stars", "day": "#8fc4c4", "dusk": "#d8a090", "night": "#2f5560" },
	"sky_blue": { "name": "Summer Blue", "kind": "sky", "unlock": "Top Spin: 100 stars", "day": "#a8c8ec", "dusk": "#f0b090", "night": "#34407a" },
	"sky_golden": { "name": "Golden Hour", "kind": "sky", "unlock": "RC Prix: 6-6", "day": "#f0d090", "dusk": "#f09858", "night": "#5a4060" },
	"sky_aurora": { "name": "Aurora", "kind": "sky", "unlock": "RC Prix 2177: 4-6", "day": "#b8d8e0", "dusk": "#c0a8c8", "night": "#1e3848" },
	"sky_synth": { "name": "Neon Dusk", "kind": "sky", "unlock": "RC Prix 2177: 100 stars", "day": "#e0a8d0", "dusk": "#f070a0", "night": "#2a1e50" },
	"sky_redmoon": { "name": "Red Moon", "kind": "sky", "unlock": "90 spirits found", "day": "#d8a8a0", "dusk": "#d06050", "night": "#3a1820" },
	"sky_lilac": { "name": "Lilac", "kind": "sky", "unlock": "Lucky Pinch", "day": "#c8b4e0", "dusk": "#e8a8b8", "night": "#4a3e72" },
	"sky_amber": { "name": "Amber", "kind": "sky", "unlock": "The Shop", "price": 20, "day": "#f0c890", "dusk": "#e09060", "night": "#604838" },
	"sky_silver": { "name": "Silver", "kind": "sky", "unlock": "The Shop", "price": 20, "day": "#c8ccd8", "dusk": "#d8b8b8", "night": "#3a4050" },
	"sky_sakura": { "name": "Sakura", "kind": "sky", "unlock": "The Shop", "price": 20, "day": "#f4c8d4", "dusk": "#f0a0a8", "night": "#6a4a6a" },
	# --- drifting: the cloud layers (the same ids as the gut's sky scenes, so either home has them)
	"clouds": { "name": "Clouds", "kind": "drift", "unlocked": true, "unlock": "",
		"layers": ["res://textures/pet-background/clouds3.png", "res://textures/pet-background/clouds2.png"] },
	"marbles": { "name": "Marbles", "kind": "drift", "unlock": "Tilt Maze: 5 stars",
		"layers": ["res://textures/pet-background/marbles_far.png", "res://textures/pet-background/marbles_near.png"] },
	"balloons": { "name": "Balloons", "kind": "drift", "unlock": "RC Prix: 5 stars",
		"layers": ["res://textures/pet-background/balloons_far.png", "res://textures/pet-background/balloons_near.png"] },
	"paper_cranes": { "name": "Paper Cranes", "kind": "drift", "unlock": "Paper Sumo: 5 stars",
		"layers": ["res://textures/pet-background/paper_cranes_far.png", "res://textures/pet-background/paper_cranes_near.png"] },
	"spin_tops": { "name": "Spinning Tops", "kind": "drift", "unlock": "Top Spin: 5 stars",
		"layers": ["res://textures/pet-background/spin_tops_far.png", "res://textures/pet-background/spin_tops_near.png"] },
	"bubbles": { "name": "Bubbles", "kind": "drift", "unlock": "Lucky Pinch",
		"layers": ["res://textures/pet-background/bubbles_far.png", "res://textures/pet-background/bubbles_near.png"] },
	"starfield": { "name": "Starfield", "kind": "drift", "unlock": "Tilt Maze: 6-6",
		"layers": ["res://textures/pet-background/starfield_far.png", "res://textures/pet-background/starfield_near.png"] },
	# --- drifting: particles over the clouds (sky_drift.gd); the four seasons are Paper Sumo's
	"petals": { "name": "Cherry Petals", "kind": "drift", "particles": "petals", "unlock": "Paper Sumo: 2-6" },
	"maple": { "name": "Maple Leaves", "kind": "drift", "particles": "maple", "unlock": "Paper Sumo: 3-6" },
	"fireflies": { "name": "Fireflies", "kind": "drift", "particles": "fireflies", "unlock": "Paper Sumo: 5-6" },
	"snow": { "name": "Snow", "kind": "drift", "particles": "snow", "unlock": "Paper Sumo: 6-6" },
	"seasons": { "name": "Seasons", "kind": "drift", "particles": "seasons", "unlock": "All four seasons" },
	"sky_fish": { "name": "Sky Goldfish", "kind": "drift", "particles": "sky_fish", "unlock": "Splash Hoops: 3-6" },
	"sky_lanterns": { "name": "Sky Lanterns", "kind": "drift", "particles": "sky_lanterns", "unlock": "Splash Hoops: 4-6" },
	"fireworks": { "name": "Fireworks", "kind": "drift", "particles": "fireworks", "unlock": "RC Prix: 4-6" },
	"wisps": { "name": "Spirit Wisps", "kind": "drift", "particles": "wisps", "unlock": "60 spirits found" },
	"dragon": { "name": "Cloud Dragon", "kind": "drift", "particles": "dragon", "unlock": "Top Spin: 6-6" },
}
const SKY_SECTIONS := ["sky", "drift"]
const SEASONS := ["petals", "fireflies", "maple", "snow"]   # (owning all four brings "seasons")

## Gifts for playing in the hokora (Collection.REWARDS has the gut's; both are given, so either home
## is complete whichever one you play in). Game ids: 2 Splash Hoops, 1 Tilt Maze, 0 RC Prix,
## 9 Paper Sumo, 8 Top Spin, 11 RC Prix 2177. Each gift track, one stall's festival prizes:
## 5 stars a sky drift (or the first lanterns), 15 a hanging piece, 30 a dress-up, 60 a shelf pair,
## 100 a sky, 150 the gold sticker (the masters' world).
const REWARDS := [
	{ "game": 2, "stars": 5, "category": "decor", "id": "lantern_goldfish" },
	{ "game": 2, "stars": 15, "category": "decor", "id": "hang_furin" },
	{ "game": 2, "stars": 30, "category": "accessories", "id": "sunglasses" },
	{ "game": 2, "stars": 60, "category": "decor", "id": "shelf_goldfish" },
	{ "game": 2, "stars": 100, "category": "backgrounds", "id": "sky_lagoon" },
	{ "game": 2, "stars": 150, "category": "stickers", "id": "gold_shell" },
	{ "game": 1, "stars": 5, "category": "backgrounds", "id": "marbles" },
	{ "game": 1, "stars": 15, "category": "decor", "id": "hang_beads" },
	{ "game": 1, "stars": 30, "category": "accessories", "id": "explorer_hat" },
	{ "game": 1, "stars": 60, "category": "decor", "id": "shelf_puzzle" },
	{ "game": 1, "stars": 100, "category": "backgrounds", "id": "sky_mint" },
	{ "game": 1, "stars": 150, "category": "stickers", "id": "gold_marble" },
	{ "game": 0, "stars": 5, "category": "backgrounds", "id": "balloons" },
	{ "game": 0, "stars": 15, "category": "decor", "id": "hang_pennants" },
	{ "game": 0, "stars": 30, "category": "accessories", "id": "racing_helmet" },
	{ "game": 0, "stars": 60, "category": "decor", "id": "shelf_ema" },
	{ "game": 0, "stars": 100, "category": "backgrounds", "id": "sky_peach" },
	{ "game": 0, "stars": 150, "category": "stickers", "id": "gold_car" },
	{ "game": 9, "stars": 5, "category": "backgrounds", "id": "paper_cranes" },
	{ "game": 9, "stars": 15, "category": "decor", "id": "hang_shimenawa" },
	{ "game": 9, "stars": 30, "category": "accessories", "id": "gyoji_hat" },
	{ "game": 9, "stars": 60, "category": "decor", "id": "shelf_origami" },
	{ "game": 9, "stars": 100, "category": "backgrounds", "id": "sky_teal" },
	{ "game": 9, "stars": 150, "category": "stickers", "id": "gold_yokozuna" },
	{ "game": 8, "stars": 5, "category": "backgrounds", "id": "spin_tops" },
	{ "game": 8, "stars": 15, "category": "decor", "id": "hang_pinwheels" },
	{ "game": 8, "stars": 30, "category": "accessories", "id": "propeller_cap" },
	{ "game": 8, "stars": 60, "category": "decor", "id": "shelf_koma" },
	{ "game": 8, "stars": 100, "category": "backgrounds", "id": "sky_blue" },
	{ "game": 8, "stars": 150, "category": "stickers", "id": "gold_top" },
	# RC Prix 2177 (the Turbo League's neon pieces; its 30-star dress-up and 150-star sticker wait for art)
	{ "game": 11, "stars": 5, "category": "decor", "id": "lantern_neon" },
	{ "game": 11, "stars": 15, "category": "decor", "id": "hang_led" },
	{ "game": 11, "stars": 60, "category": "decor", "id": "shelf_neon_cat" },
	{ "game": 11, "stars": 100, "category": "backgrounds", "id": "sky_synth" },
	# the Tomopedia: every 10 spirits, the long goal pays the home's grandest pieces
	{ "pedia": 10, "category": "accessories", "id": "round_glasses" },
	{ "pedia": 20, "category": "decor", "id": "shelf_sakaki" },
	{ "pedia": 30, "category": "decor", "id": "lantern_hozuki" },
	{ "pedia": 40, "category": "decor", "id": "hang_cranes" },
	{ "pedia": 50, "category": "decor", "id": "shelf_kitsune" },
	{ "pedia": 60, "category": "backgrounds", "id": "wisps" },
	{ "pedia": 70, "category": "decor", "id": "lantern_fox" },
	{ "pedia": 80, "category": "decor", "id": "shelf_komainu" },
	{ "pedia": 90, "category": "backgrounds", "id": "sky_redmoon" },
	{ "pedia": 100, "category": "decor", "id": "lantern_gold" },
	{ "pedia": 110, "category": "decor", "id": "shelf_tsukimi" },
	{ "pedia": 120, "category": "decor", "id": "colour_gold" },
	# each realm (food family) gives the hokora its colour at 10 of its spirits
	{ "realm": "green", "count": 10, "category": "decor", "id": "colour_moss" },
	{ "realm": "greasy", "count": 10, "category": "decor", "id": "colour_vermilion" },
	{ "realm": "spicy", "count": 10, "category": "decor", "id": "colour_lacquer" },
	{ "realm": "sour", "count": 10, "category": "decor", "id": "colour_copper" },
	{ "realm": "sweet", "count": 10, "category": "decor", "id": "colour_moonwhite" },
	# the device's own milestone (as in the gut)
	{ "total_stars": 100, "category": "cases", "id": "melon" },
]
const REALM_NAMES := { "green": "Mountain", "greasy": "Fox", "spicy": "Fire", "sour": "River", "sweet": "Moon" }

## Only won from the Lucky Pinch claw machine (8 capsules, then coins)
const LUCKY_ITEMS := [
	["accessories", "scarf"], ["accessories", "headphones"],
	["backgrounds", "bubbles"], ["backgrounds", "sky_lilac"],
	["decor", "lantern_daruma"], ["decor", "hang_bunting"], ["decor", "shelf_maneki"], ["decor", "colour_sakura"],
]

## A hokora piece that took the place of a gut piece as a game's prize: winning it gives the gut's
## too, so the gut stays complete (HOME: GUT)
const GUT_TWIN := {
	"sky_fish": ["decor", "seaweed"],              # Splash Hoops 3-6
	"hang_glow": ["decor", "glow_spores"],         # Tilt Maze 3-8
	"shelf_kappa": ["backgrounds", "sewer_pipes"], # Tilt Maze 4-6
	"hang_cogs": ["decor", "cog_garland"],         # Tilt Maze 5-6
	"maple": ["decor", "maple_leaves"],            # Paper Sumo 3-6
	"lantern_festival": ["decor", "koma_lanterns"],# Top Spin 3-6
	"sky_lilac": ["backgrounds", "lilac"],         # Lucky Pinch
	"hang_bunting": ["decor", "bunting"],
	"shelf_maneki": ["decor", "golden_gut"],
	"colour_sakura": ["decor", "mint_gut"],
}

static func order(category: String) -> Array:
	var src: Dictionary = DECOR if category == "decor" else SKY
	var sections: Array = DECOR_SECTIONS if category == "decor" else SKY_SECTIONS
	var out := []
	for s in sections:
		for id in src:
			if src[id]["kind"] == s:
				out.append(id)
	return out

static func section_ids(category: String, section: String) -> Array:
	var src: Dictionary = DECOR if category == "decor" else SKY
	return src.keys().filter(func(id): return src[id]["kind"] == section)

## A piece's file in the art folder ("" = not drawn yet)
static func art(id: String, suffix := "") -> String:
	var p := ART_DIR + id + suffix + ".png"
	return p if ResourceLoader.exists(p) else ""

static func icon_path(id: String) -> String:
	var p := ART_DIR + "icons/" + id + ".png"
	return p if ResourceLoader.exists(p) else ""

## Is it drawn yet? (lanterns, colours, skies and particle drifts always show something)
static func has_art(id: String) -> bool:
	var item: Dictionary = DECOR.get(id, SKY.get(id, {}))
	match item.get("kind", ""):
		"hanging":
			return id == "hang_none" or art(id, "-1") != ""
		"shelf":
			return id == "shelf_none" or art(id) != "" or art(id, "_left") != ""
		"drift":
			return item.get("particles", "") != "dragon" or art("dragon") != ""
	return true

## A piece's card picture: its icon when drawn; until then a lantern recoloured, a corner of the
## hokora in a colour, a sky's day / dusk / night, a drift's layers or particles; null = not drawn
## yet (a hanging or shelf piece: the card's "?")
static var _previews := {}
static func preview(id: String) -> Texture2D:
	if _previews.has(id):
		return _previews[id]
	var tex: Texture2D = null
	var item: Dictionary = DECOR.get(id, SKY.get(id, {}))
	var ip := icon_path(id)
	if ip != "":
		tex = load(ip)
	else:
		match item.get("kind", ""):
			"lantern":
				tex = lantern_texture(id)
			"colour":
				tex = _colour_preview(item)
			"sky":
				tex = _sky_preview(id)
			"drift":
				# (a cloud layer: null, the menu draws its pattern; particles: a few on a sky swatch)
				if item.has("particles"):
					tex = preload("res://scripts/sky_drift.gd").preview(item["particles"], Color.html(SKY["sky_shrine"]["day"]))
			"hanging", "shelf":
				if has_art(id) and not id.ends_with("_none"):
					var p := art(id, "-1") if item["kind"] == "hanging" else (art(id) if art(id) != "" else art(id, "_left"))
					tex = load(p)
	_previews[id] = tex
	return tex

## A lantern's picture: its own drawing, or the red one recoloured by its "tint"
static var _lanterns := {}
static func lantern_texture(id: String) -> Texture2D:
	if _lanterns.has(id):
		return _lanterns[id]
	var own := art(id)
	var tex: Texture2D = load(own) if own != "" else load("res://textures/pet/shrine_new/lantern.png")
	var item: Dictionary = DECOR.get(id, {})
	if own == "" and item.has("tint"):
		var img := tex.get_image()
		if img.is_compressed():
			img.decompress()
		img.convert(Image.FORMAT_RGBA8)
		var t: Array = item["tint"]
		for y in img.get_height():
			for x in img.get_width():
				var c := img.get_pixel(x, y)
				if c.a > 0.0:
					img.set_pixel(x, y, _shift(c, t))
		tex = ImageTexture.create_from_image(img)
	_lanterns[id] = tex
	return tex

## The shader's recolour (hokora_colour.gdshader) on one colour: [hue shift, saturation x, value x]
static func _shift(c: Color, t: Array) -> Color:
	if c.v <= 0.22 or c.s <= 0.08:
		return c
	return Color.from_hsv(fposmod(c.h + float(t[0]), 1.0), clampf(c.s * float(t[1]), 0.0, 1.0), clampf(c.v * float(t[2]), 0.0, 1.0), c.a)

## Which of a colour item's sets moves this colour (the shader's rule: roof tiles, wood, moss)
static func _material(c: Color, item: Dictionary) -> Array:
	var h := c.h * 360.0
	if h >= 45.0 and h < 170.0:
		return item.get("moss", [0.0, 1.0, 1.0])
	if c.s > 0.35 and (h < 19.0 or h >= 330.0):
		return item.get("roof", [0.0, 1.0, 1.0])
	return item.get("wood", [0.0, 1.0, 1.0])

## The hokora's left eave and pillar in a colour (a small crop, recoloured once)
static func _colour_preview(item: Dictionary) -> Texture2D:
	var img: Image = (load("res://textures/pet/shrine_new/front.png") as Texture2D).get_image()
	if img.is_compressed():
		img.decompress()
	img = img.get_region(Rect2i(60, 120, 330, 330))
	img.convert(Image.FORMAT_RGBA8)
	img.resize(110, 110, Image.INTERPOLATE_NEAREST)
	for y in img.get_height():
		for x in img.get_width():
			var c := img.get_pixel(x, y)
			if c.a > 0.0:
				img.set_pixel(x, y, _shift(c, _material(c, item)))
	return ImageTexture.create_from_image(img)

## A sky set: its day on top, its dusk, its night at the bottom
static func _sky_preview(id: String) -> Texture2D:
	var cols := sky_colours(id)
	var img := Image.create(48, 48, false, Image.FORMAT_RGBA8)
	img.fill_rect(Rect2i(0, 0, 48, 20), cols["day"])
	img.fill_rect(Rect2i(0, 20, 48, 12), cols["dusk"])
	img.fill_rect(Rect2i(0, 32, 48, 16), cols["night"])
	for p in [Vector2i(8, 6), Vector2i(26, 4), Vector2i(38, 9)]:      # (a few stars in the night, a cloud by day)
		img.fill_rect(Rect2i(p.x, p.y, 8, 3), Color(1, 1, 1, 0.85))
	for p in [Vector2i(9, 38), Vector2i(30, 41), Vector2i(41, 36)]:
		img.set_pixelv(p, Color(1, 1, 0.9))
	return ImageTexture.create_from_image(img)

## A sky set's colours by the time of day: { "night", "dusk" (dawn too), "day" } (the shrine's
## clock moves between them as it moves the light: Shrine._sky)
static func sky_colours(id: String) -> Dictionary:
	var s: Dictionary = SKY.get(id, SKY["sky_shrine"])
	if not s.has("day"):
		s = SKY["sky_shrine"]
	return { "night": Color.html(s["night"]), "dusk": Color.html(s["dusk"]), "day": Color.html(s["day"]) }
