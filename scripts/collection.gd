extends Node
## Autoload singleton — cosmetics and collectables the player owns.
## Categories: backgrounds, accessories (worn by the pal), decor (hung on the gut), stickers (for
## the device's back / its case) and cases (the device's shell).
## Not affected by PetState's fresh start: collectables are kept forever.
## The rule (docs/progression.md 5b): what the PAL wears or lives in is only ever WON (gift tracks,
## Pal Pedia milestones, Lucky Pinch, the games' secrets); the device's stickers and cases can be
## won or bought (Shop: a sticker of every pal you've found, plain cases).

signal unlocked(category: String, id: String)
signal background_changed(id: String)
signal equipped_changed(category: String, id: String)

const SAVE_FILE := "collection.json"     # (in SaveSlot.path)

## Every launch starts on the default background (unlocked ones stay unlocked)
const DEFAULT_BACKGROUND := "clouds"
const RESET_BACKGROUND_ON_LAUNCH := true
## Prototype: every launch also starts with no accessory and no gut decor (unlocks are kept)
const RESET_EQUIPPED_ON_LAUNCH := true
## Prototype: every launch forgets earned unlocks (so the unlock flow can be tried again)
const RESET_UNLOCKS_ON_LAUNCH := true

## Gifts for playing (Progression v2: cosmetics are gifts, never sold). Three kinds of source:
##   "game" + "stars"   each game's GIFT TRACK: that game's star total reaches it
##   "pedia"            Pal Pedia milestones: that many pals found
##   "total_stars"      the stars of every game together (the device's own milestones: its cases)
## (game = Games menu page index: 0 Pal Prix, 1 Tilt Maze, 2 Splash Hoops, 8 Top Spin, 9 Paper Sumo)
## (Splash Hoops carries the items that were Pipe Dream's score rewards)
const REWARDS := [
	{ "game": 2, "stars": 5, "category": "backgrounds", "id": "tp_rolls" },
	{ "game": 2, "stars": 15, "category": "decor", "id": "fairy_lights" },
	{ "game": 2, "stars": 30, "category": "accessories", "id": "sunglasses" },
	{ "game": 2, "stars": 60, "category": "decor", "id": "purple_gut" },
	{ "game": 2, "stars": 100, "category": "backgrounds", "id": "pastel_yellow" },
	{ "game": 2, "stars": 150, "category": "stickers", "id": "gold_shell" },
	# the other games' tracks: a scene at 5, an add-on at 15, a dress-up at 30, a gut colour at 60, a
	# sky colour at 100, a gold sticker at 150 (the masters' world)
	{ "game": 1, "stars": 5, "category": "backgrounds", "id": "marbles" },
	{ "game": 1, "stars": 15, "category": "decor", "id": "bead_garland" },
	{ "game": 1, "stars": 30, "category": "accessories", "id": "explorer_hat" },
	{ "game": 1, "stars": 60, "category": "decor", "id": "lime_gut" },
	{ "game": 1, "stars": 100, "category": "backgrounds", "id": "mint_sky" },
	{ "game": 1, "stars": 150, "category": "stickers", "id": "gold_marble" },
	{ "game": 0, "stars": 5, "category": "backgrounds", "id": "balloons" },
	{ "game": 0, "stars": 15, "category": "decor", "id": "checker_bunting" },
	{ "game": 0, "stars": 30, "category": "accessories", "id": "racing_helmet" },
	{ "game": 0, "stars": 60, "category": "decor", "id": "amber_gut" },
	{ "game": 0, "stars": 100, "category": "backgrounds", "id": "peach_sky" },
	{ "game": 0, "stars": 150, "category": "stickers", "id": "gold_car" },
	{ "game": 9, "stars": 5, "category": "backgrounds", "id": "paper_cranes" },
	{ "game": 9, "stars": 15, "category": "decor", "id": "shimenawa" },
	{ "game": 9, "stars": 30, "category": "accessories", "id": "gyoji_hat" },
	{ "game": 9, "stars": 60, "category": "decor", "id": "blue_gut" },
	{ "game": 9, "stars": 100, "category": "backgrounds", "id": "teal_sky" },
	{ "game": 9, "stars": 150, "category": "stickers", "id": "gold_yokozuna" },
	{ "game": 8, "stars": 5, "category": "backgrounds", "id": "spin_tops" },
	{ "game": 8, "stars": 15, "category": "decor", "id": "pinwheels" },
	{ "game": 8, "stars": 30, "category": "accessories", "id": "propeller_cap" },
	{ "game": 8, "stars": 60, "category": "decor", "id": "berry_gut" },
	{ "game": 8, "stars": 100, "category": "backgrounds", "id": "blue_sky" },
	{ "game": 8, "stars": 150, "category": "stickers", "id": "gold_top" },
	# the Pal Pedia: every 10 pals found
	{ "pedia": 10, "category": "accessories", "id": "round_glasses" },
	# the device's own milestone: Melon Soda (its first case, Taro, is Splash Hoops' 1-5)
	{ "total_stars": 100, "category": "cases", "id": "melon" },
]

## The device's cases (the shell, front and back: textures/cases/<id>_*.png; tools/art/cases_games.py
## makes them from Melon Soda's, each with its own print: tools/art/case_prints.py), from simple to
## fancy (the user, 2026-10-17): the first one plain and early, then the Shop's prints, the games' own.
## "price": sold in the Shop; the others are only won. "tones": its outline, body and light colours
## (the case's side as the device turns: device_flip.gd)
const FIRST_CASE := "taro"
const CASES := {
	# the first case: plain, early (and it comes with the first sticker, if that comes first)
	"taro": { "name": "Taro", "unlock": "Splash Hoops: 1-5", "tones": ["#62487c", "#c6b0e2", "#ece2fa"] },
	"melon": { "name": "Melon Soda", "unlock": "100 stars in all", "tones": ["#466858", "#b0dec4", "#f0faec"] },
	# the games' own cases: each one the prize of its masters' world finale (6-9)
	"maze": { "name": "Labyrinth", "unlock": "Tilt Maze: 6-9", "tones": ["#623e24", "#d6ac72", "#f6e0b6"] },
	"splash": { "name": "Lagoon", "unlock": "Splash Hoops: 6-9", "tones": ["#1c4e64", "#60b8c8", "#dcf8fa"] },
	"prix": { "name": "Grand Prix", "unlock": "RC Prix: 6-9", "tones": ["#6e2222", "#dc5448", "#fcf0e6"] },
	"sumo": { "name": "Dohyo", "unlock": "Paper Sumo: 6-9", "tones": ["#6e4628", "#dec28a", "#f6e2ba"] },
	"spin": { "name": "Koma", "unlock": "Top Spin: 6-9", "tones": ["#0c0c14", "#222234", "#e2b652"] },
	# the Shop's: a print each (blossoms, lemon slices, clouds, sprinkles)
	"sakura": { "name": "Sakura", "unlock": "The Shop", "price": 40, "tones": ["#82465a", "#f2becc", "#fff6f8"] },
	"lemon": { "name": "Lemon", "unlock": "The Shop", "price": 40, "tones": ["#82641e", "#f6de78", "#fffce6"] },
	"sky": { "name": "Sky", "unlock": "The Shop", "price": 40, "tones": ["#325082", "#a0c8f0", "#f4faff"] },
	"cocoa": { "name": "Cocoa", "unlock": "The Shop", "price": 40, "tones": ["#462a1e", "#96644a", "#ecd2ba"] },
}
const CASE_ORDER := ["taro", "melon", "sakura", "lemon", "sky", "cocoa", "maze", "splash", "prix", "sumo", "spin"]

## Themed stickers (won only: secrets, gift tracks, Lucky Pinch): textures/cases/stickers/<id>.png
## (+ book/<id>.png; tools/art/theme_stickers.py), the sticker book's games page. The pal stickers
## (one per Sho and Chu) are PAL_STICKERS.
const STICKERS := {
	"starfish": { "name": "Starfish", "unlock": "Splash Hoops: 2-6" },
	"pufferfish": { "name": "Pufferfish", "unlock": "Splash Hoops: 4-6" },
	"seashell": { "name": "Seashell", "unlock": "Splash Hoops: 5-6" },
	"anglerfish": { "name": "Anglerfish", "unlock": "Splash Hoops: 6-6" },
	"traffic_cone": { "name": "Traffic Cone", "unlock": "RC Prix: 4-6" },
	"rubber_duck": { "name": "Rubber Duck", "unlock": "RC Prix: 5-6" },
	"gold_cup": { "name": "Gold Cup", "unlock": "RC Prix: 6-6" },
	"koi": { "name": "Koi", "unlock": "Paper Sumo: 2-6" },
	"wind_up_key": { "name": "Wind-up Key", "unlock": "Paper Sumo: 4-6" },
	"kabuto": { "name": "Kabuto", "unlock": "Paper Sumo: 5-6" },
	"koma": { "name": "Koma", "unlock": "Top Spin: 2-6" },
	"soap": { "name": "Soap", "unlock": "Top Spin: 4-6" },
	"dragon": { "name": "Dragon", "unlock": "Top Spin: 6-6" },
	# the gift tracks' gold stickers (150 stars)
	"gold_shell": { "name": "Gold Shell", "unlock": "Splash Hoops: 150 stars" },
	"gold_marble": { "name": "Gold Marble", "unlock": "Tilt Maze: 150 stars" },
	"gold_car": { "name": "Gold Car", "unlock": "RC Prix: 150 stars" },
	"gold_yokozuna": { "name": "Gold Yokozuna", "unlock": "Paper Sumo: 150 stars" },
	"gold_top": { "name": "Gold Top", "unlock": "Top Spin: 150 stars" },
}
const STICKER_ORDER := ["starfish", "pufferfish", "seashell", "anglerfish", "traffic_cone", "rubber_duck", "gold_cup",
	"koi", "wind_up_key", "kabuto", "koma", "soap", "dragon", "gold_shell", "gold_marble", "gold_car", "gold_yokozuna", "gold_top"]
## Every pal with a sticker (the Sho and the Chu: the sticker book's family pages), set at start
var PAL_STICKERS: Array = []

## "layers": [far layer (CloudA), near layer (CloudB)] — drop-in replacements for the cloud textures.
## "unlock": how it is obtained (shown on the locked card). Default unlocked = true/false.
const BACKGROUNDS := {
	# Like the gut decor: one "complement" (the scrolling layers) + one "color" (a hue shift of
	# the pink sky behind them, pastel only for now); a colour in use is taken off by holding it
	"clouds": {
		"name": "Clouds",
		"kind": "complement",
		"layers": ["res://textures/pet-background/clouds3.png", "res://textures/pet-background/clouds2.png"],
		"unlocked": true,
		"unlock": "",
	},
	"tp_rolls": {
		"name": "Toilet Rolls",
		"kind": "complement",
		"layers": ["res://textures/pet-background/tprolls_far.png", "res://textures/pet-background/tprolls_near.png"],
		"unlocked": false,
		"unlock": "Splash Hoops: 5 stars",
	},
	# "?" slots: items still to come (nothing unlocks them yet). A list shows one page more
	# each time its current last page is fully unlocked.
	"bubbles": {
		"name": "Bubbles",
		"kind": "complement",
		"layers": ["res://textures/pet-background/bubbles_far.png", "res://textures/pet-background/bubbles_near.png"],
		"unlocked": false,
		"unlock": "Lucky Pinch",
	},
	# won in the games' secrets (tools/art/bg_games.py; "icon": the prize card's picture)
	"sewer_pipes": {
		"name": "Sewer Pipes",
		"kind": "complement",
		"layers": ["res://textures/pet-background/sewer_pipes_far.png", "res://textures/pet-background/sewer_pipes_near.png"],
		"icon": "res://textures/pet-background/icons/sewer_pipes.png",
		"unlocked": false,
		"unlock": "Tilt Maze: 4-6",
	},
	"starfield": {
		"name": "Starfield",
		"kind": "complement",
		"layers": ["res://textures/pet-background/starfield_far.png", "res://textures/pet-background/starfield_near.png"],
		"icon": "res://textures/pet-background/icons/starfield.png",
		"unlocked": false,
		"unlock": "Tilt Maze: 6-6",
	},
	# the gift tracks' (5 stars: a scene; 100: a sky colour)
	"marbles": {
		"name": "Marbles",
		"kind": "complement",
		"layers": ["res://textures/pet-background/marbles_far.png", "res://textures/pet-background/marbles_near.png"],
		"icon": "res://textures/pet-background/icons/marbles.png",
		"unlocked": false,
		"unlock": "Tilt Maze: 5 stars",
	},
	"balloons": {
		"name": "Balloons",
		"kind": "complement",
		"layers": ["res://textures/pet-background/balloons_far.png", "res://textures/pet-background/balloons_near.png"],
		"icon": "res://textures/pet-background/icons/balloons.png",
		"unlocked": false,
		"unlock": "RC Prix: 5 stars",
	},
	"paper_cranes": {
		"name": "Paper Cranes",
		"kind": "complement",
		"layers": ["res://textures/pet-background/paper_cranes_far.png", "res://textures/pet-background/paper_cranes_near.png"],
		"icon": "res://textures/pet-background/icons/paper_cranes.png",
		"unlocked": false,
		"unlock": "Paper Sumo: 5 stars",
	},
	"spin_tops": {
		"name": "Spinning Tops",
		"kind": "complement",
		"layers": ["res://textures/pet-background/spin_tops_far.png", "res://textures/pet-background/spin_tops_near.png"],
		"icon": "res://textures/pet-background/icons/spin_tops.png",
		"unlocked": false,
		"unlock": "Top Spin: 5 stars",
	},
	"mint_sky": { "name": "Mint", "kind": "color", "hue": 0.36, "layers": [], "unlocked": false, "unlock": "Tilt Maze: 100 stars" },
	"peach_sky": { "name": "Peach", "kind": "color", "hue": 0.05, "layers": [], "unlocked": false, "unlock": "RC Prix: 100 stars" },
	"teal_sky": { "name": "Teal", "kind": "color", "hue": 0.5, "layers": [], "unlocked": false, "unlock": "Paper Sumo: 100 stars" },
	"blue_sky": { "name": "Blue", "kind": "color", "hue": 0.58, "layers": [], "unlocked": false, "unlock": "Top Spin: 100 stars" },
	"pink": { "name": "Pink", "kind": "color", "hue": 0.0, "layers": [], "unlocked": true, "unlock": "" },
	"pastel_yellow": { "name": "Yellow", "kind": "color", "hue": 0.145, "layers": [], "unlocked": false, "unlock": "Splash Hoops: 100 stars" },
	"lilac": { "name": "Lilac", "kind": "color", "hue": -0.12, "layers": [], "unlocked": false, "unlock": "Lucky Pinch" },
	"mystery_3": { "name": "???", "layers": [], "unlocked": false, "unlock": "" },
	"mystery_4": { "name": "???", "layers": [], "unlocked": false, "unlock": "" },
}
const BACKGROUND_ORDER := ["clouds", "pink", "tp_rolls", "pastel_yellow", "bubbles", "lilac", "sewer_pipes", "starfield",
	"marbles", "mint_sky", "balloons", "peach_sky", "paper_cranes", "teal_sky", "spin_tops", "blue_sky", "mystery_3", "mystery_4"]

## Pal accessories. "dir" holds one texture per form and frame: <form>-1.png, <form>-2.png,
## drawn on the form's own canvas (see tools/art/accessories.py).
const ACCESSORIES := {
	"none": { "name": "Nothing", "dir": "", "unlocked": true, "unlock": "" },
	"sunglasses": { "name": "Sunglasses", "dir": "res://textures/pet/accessories/sunglasses/", "unlocked": false, "unlock": "Splash Hoops: 30 stars" },
	"scarf": { "name": "Scarf", "dir": "res://textures/pet/accessories/scarf/", "unlocked": false, "unlock": "Lucky Pinch" },
	"headphones": { "name": "Headphones", "dir": "res://textures/pet/accessories/headphones/", "unlocked": false, "unlock": "Lucky Pinch" },
	"round_glasses": { "name": "Round Glasses", "dir": "res://textures/pet/accessories/round_glasses/", "unlocked": false, "unlock": "10 pals found" },
	# won in the games' secrets (tools/art/hats.py)
	"snorkel": { "name": "Snorkel", "dir": "res://textures/pet/accessories/snorkel/", "unlocked": false, "unlock": "Tilt Maze: 2-8" },
	"headlamp": { "name": "Headlamp", "dir": "res://textures/pet/accessories/headlamp/", "unlocked": false, "unlock": "Tilt Maze: 4-8" },
	"hard_hat": { "name": "Hard Hat", "dir": "res://textures/pet/accessories/hard_hat/", "unlocked": false, "unlock": "Tilt Maze: 5-8" },
	"hachimaki": { "name": "Hachimaki", "dir": "res://textures/pet/accessories/hachimaki/", "unlocked": false, "unlock": "Top Spin: 5-6" },
	"sumo_topknot": { "name": "Sumo Topknot", "dir": "res://textures/pet/accessories/sumo_topknot/", "unlocked": false, "unlock": "Paper Sumo: 6-6" },
	# the gift tracks' (30 stars)
	"explorer_hat": { "name": "Explorer Hat", "dir": "res://textures/pet/accessories/explorer_hat/", "unlocked": false, "unlock": "Tilt Maze: 30 stars" },
	"racing_helmet": { "name": "Racing Helmet", "dir": "res://textures/pet/accessories/racing_helmet/", "unlocked": false, "unlock": "RC Prix: 30 stars" },
	"gyoji_hat": { "name": "Gyoji Hat", "dir": "res://textures/pet/accessories/gyoji_hat/", "unlocked": false, "unlock": "Paper Sumo: 30 stars" },
	"propeller_cap": { "name": "Propeller Cap", "dir": "res://textures/pet/accessories/propeller_cap/", "unlocked": false, "unlock": "Top Spin: 30 stars" },
	"mystery_acc_4": { "name": "???", "dir": "", "unlocked": false, "unlock": "" },
}
const ACCESSORY_ORDER := ["none", "sunglasses", "round_glasses", "scarf", "headphones", "snorkel", "headlamp", "hard_hat",
	"hachimaki", "sumo_topknot", "explorer_hat", "racing_helmet", "gyoji_hat", "propeller_cap", "mystery_acc_4"]

## Gut decor, two kinds that combine: one "complement" (an overlay hung on the gut; "frames"
## are the size of intestine-front.png, cycled to animate) and one "color" (a hue shift of
## the whole gut). "Nothing" takes both off.
const DECOR := {
	"none": { "name": "Nothing", "kind": "", "frames": [], "unlocked": true, "unlock": "" },
	"fairy_lights": { "name": "Fairy Lights", "kind": "complement", "frames": ["res://textures/pet/decor/fairy_lights-1.png", "res://textures/pet/decor/fairy_lights-2.png"], "unlocked": false, "unlock": "Splash Hoops: 15 stars" },
	"purple_gut": { "name": "Purple Gut", "kind": "color", "hue": -0.235, "frames": [], "unlocked": false, "unlock": "Splash Hoops: 60 stars" },
	"bunting": { "name": "Bunting", "kind": "complement", "frames": ["res://textures/pet/decor/bunting-1.png", "res://textures/pet/decor/bunting-2.png"], "unlocked": false, "unlock": "Lucky Pinch" },
	"golden_gut": { "name": "Golden Gut", "kind": "color", "hue": 0.13, "frames": [], "unlocked": false, "unlock": "Lucky Pinch" },
	"mint_gut": { "name": "Mint Gut", "kind": "color", "hue": 0.44, "frames": [], "unlocked": false, "unlock": "Lucky Pinch" },
	# won in the games' secrets (tools/art/decor_games.py; "icon": the prize card's picture)
	"glow_spores": { "name": "Glow Spores", "kind": "complement", "frames": ["res://textures/pet/decor/glow_spores-1.png", "res://textures/pet/decor/glow_spores-2.png"], "icon": "res://textures/pet/decor/icons/glow_spores.png", "unlocked": false, "unlock": "Tilt Maze: 3-8" },
	"cog_garland": { "name": "Cog Garland", "kind": "complement", "frames": ["res://textures/pet/decor/cog_garland-1.png", "res://textures/pet/decor/cog_garland-2.png"], "icon": "res://textures/pet/decor/icons/cog_garland.png", "unlocked": false, "unlock": "Tilt Maze: 5-6" },
	"seaweed": { "name": "Seaweed", "kind": "complement", "frames": ["res://textures/pet/decor/seaweed-1.png", "res://textures/pet/decor/seaweed-2.png"], "icon": "res://textures/pet/decor/icons/seaweed.png", "unlocked": false, "unlock": "Splash Hoops: 3-6" },
	"koma_lanterns": { "name": "Lanterns", "kind": "complement", "frames": ["res://textures/pet/decor/koma_lanterns-1.png", "res://textures/pet/decor/koma_lanterns-2.png"], "icon": "res://textures/pet/decor/icons/koma_lanterns.png", "unlocked": false, "unlock": "Top Spin: 3-6" },
	"maple_leaves": { "name": "Maple Leaves", "kind": "complement", "frames": ["res://textures/pet/decor/maple_leaves-1.png", "res://textures/pet/decor/maple_leaves-2.png"], "icon": "res://textures/pet/decor/icons/maple_leaves.png", "unlocked": false, "unlock": "Paper Sumo: 3-6" },
	# the gift tracks' (15 stars: an add-on; 60: a gut colour)
	"bead_garland": { "name": "Bead Garland", "kind": "complement", "frames": ["res://textures/pet/decor/bead_garland-1.png", "res://textures/pet/decor/bead_garland-2.png"], "icon": "res://textures/pet/decor/icons/bead_garland.png", "unlocked": false, "unlock": "Tilt Maze: 15 stars" },
	"checker_bunting": { "name": "Checker Flags", "kind": "complement", "frames": ["res://textures/pet/decor/checker_bunting-1.png", "res://textures/pet/decor/checker_bunting-2.png"], "icon": "res://textures/pet/decor/icons/checker_bunting.png", "unlocked": false, "unlock": "RC Prix: 15 stars" },
	"shimenawa": { "name": "Shimenawa", "kind": "complement", "frames": ["res://textures/pet/decor/shimenawa-1.png", "res://textures/pet/decor/shimenawa-2.png"], "icon": "res://textures/pet/decor/icons/shimenawa.png", "unlocked": false, "unlock": "Paper Sumo: 15 stars" },
	"pinwheels": { "name": "Pinwheels", "kind": "complement", "frames": ["res://textures/pet/decor/pinwheels-1.png", "res://textures/pet/decor/pinwheels-2.png"], "icon": "res://textures/pet/decor/icons/pinwheels.png", "unlocked": false, "unlock": "Top Spin: 15 stars" },
	"lime_gut": { "name": "Lime Gut", "kind": "color", "hue": 0.25, "frames": [], "unlocked": false, "unlock": "Tilt Maze: 60 stars" },
	"amber_gut": { "name": "Amber Gut", "kind": "color", "hue": 0.07, "frames": [], "unlocked": false, "unlock": "RC Prix: 60 stars" },
	"blue_gut": { "name": "Blue Gut", "kind": "color", "hue": 0.6, "frames": [], "unlocked": false, "unlock": "Paper Sumo: 60 stars" },
	"berry_gut": { "name": "Berry Gut", "kind": "color", "hue": -0.06, "frames": [], "unlocked": false, "unlock": "Top Spin: 60 stars" },
	"mystery_decor_3": { "name": "???", "frames": [], "unlocked": false, "unlock": "" },
	"mystery_decor_4": { "name": "???", "frames": [], "unlocked": false, "unlock": "" },
}
const DECOR_ORDER := ["none", "fairy_lights", "purple_gut", "bunting", "golden_gut", "mint_gut", "glow_spores", "cog_garland",
	"seaweed", "koma_lanterns", "maple_leaves", "bead_garland", "lime_gut", "checker_bunting", "amber_gut", "shimenawa", "blue_gut",
	"pinwheels", "berry_gut", "mystery_decor_3", "mystery_decor_4"]

## Only won from the LUCKY PINCH claw machine: one capsule each
const LUCKY_ITEMS := [
	["accessories", "scarf"], ["accessories", "headphones"],
	["backgrounds", "bubbles"], ["backgrounds", "lilac"],
	["decor", "bunting"], ["decor", "golden_gut"], ["decor", "mint_gut"],
]

var owned := { "backgrounds": [], "accessories": [], "decor": [], "stickers": [], "cases": [] }
var equipped_case := ""                 # the case on the device ("" = none, the bare device)
var equipped_background := DEFAULT_BACKGROUND
const DEFAULT_BG_COLOR := "pink"
var equipped_bg_color := DEFAULT_BG_COLOR   # sky colour in use (pink = the natural sky)
var equipped_accessory := "none"
var equipped_decor := "none"          # the complement in use
var equipped_gut_color := ""           # the gut colour in use ("" = the natural pink)
var new_items := {}                     # "category/id" -> true: unlocked but not looked at yet

func _ready() -> void:
	for id in PetState.FORMS:
		if int(PetState.FORMS[id]["stage"]) <= 2 and ResourceLoader.exists("res://textures/cases/stickers/%s.png" % id):
			PAL_STICKERS.append(id)
	PAL_STICKERS.sort_custom(func(a, b): return PetState.FORMS[a]["no"] < PetState.FORMS[b]["no"])
	_start()
	PetState.pal_discovered.connect(func(_id): _check_pedia())
	# what the pal wears goes down the drain with it
	PetState.form_changed.connect(func(_id, reason):
		if reason == "flush" and equipped_accessory != "none":
			equip("accessories", "none"))

## Loads the save again (BOOT + PROGRESSION, once its folder is in use: nothing reset)
func reload() -> void:
	_start()

func _start() -> void:
	owned = { "backgrounds": [], "accessories": [], "decor": [], "stickers": [], "cases": [] }
	equipped_case = ""
	equipped_background = DEFAULT_BACKGROUND
	equipped_bg_color = DEFAULT_BG_COLOR
	equipped_accessory = "none"
	equipped_decor = "none"
	equipped_gut_color = ""
	new_items = {}
	for cat in ["backgrounds", "accessories", "decor"]:
		var cat_catalog := catalog(cat)
		for id in cat_catalog:
			if cat_catalog[id]["unlocked"] and id not in owned[cat]:
				owned[cat].append(id)
	if SaveSlot.real():
		load_data()
		return
	if not RESET_UNLOCKS_ON_LAUNCH:
		load_data()
	if RESET_BACKGROUND_ON_LAUNCH and (equipped_background != DEFAULT_BACKGROUND or equipped_bg_color != DEFAULT_BG_COLOR):
		equipped_background = DEFAULT_BACKGROUND
		equipped_bg_color = DEFAULT_BG_COLOR
		save_data()
	if RESET_EQUIPPED_ON_LAUNCH and (equipped_accessory != "none" or equipped_decor != "none" or equipped_gut_color != ""):
		equipped_accessory = "none"
		equipped_decor = "none"
		equipped_gut_color = ""
		save_data()

func is_owned(category: String, id: String) -> bool:
	return id in owned.get(category, [])

func unlock(category: String, id: String) -> void:
	if is_owned(category, id):
		return
	if category not in owned:
		owned[category] = []
	owned[category].append(id)
	new_items["%s/%s" % [category, id]] = true
	save_data()
	unlocked.emit(category, id)
	# a sticker needs somewhere to go: the first one brings the first case along, if none yet
	if category == "stickers" and owned.get("cases", []).is_empty():
		unlock("cases", FIRST_CASE)

## Called by every minigame as points come in (live, mid-round)
func report_game_score(game: int, score: int) -> void:
	for r in REWARDS:
		if r.get("game", -1) == game and r.has("score") and score >= r["score"] and not is_owned(r["category"], r["id"]):
			unlock(r["category"], r["id"])

## A game's star total changed (GameData.record_level): its gift track, and the device's own
## milestones (every game's stars together)
func report_game_stars(game: int, stars: int) -> void:
	var total := 0
	for idx in GameData.games:
		total += GameData.game_stars(idx)
	for r in REWARDS:
		if is_owned(r["category"], r["id"]):
			continue
		if r.get("game", -1) == game and r.has("stars") and stars >= r["stars"]:
			unlock(r["category"], r["id"])
		elif r.has("total_stars") and total >= r["total_stars"]:
			unlock(r["category"], r["id"])

## A new pal was found: the Pal Pedia's milestones
func _check_pedia() -> void:
	var found := PetState.discovered.size()
	for r in REWARDS:
		if r.has("pedia") and found >= r["pedia"] and not is_owned(r["category"], r["id"]):
			unlock(r["category"], r["id"])

## Where an item comes from, for its locked card ("Tilt Maze: 30 stars", "40 pals found"...)
func source_text(category: String, id: String) -> String:
	for r in REWARDS:
		if r["category"] == category and r["id"] == id:
			if r.has("pedia"):
				return "%d spirits found" % r["pedia"]
			if r.has("total_stars"):
				return "%d stars in all" % r["total_stars"]
			return "%s: %d stars" % [GAME_NAMES.get(r.get("game", -1), "A game"), r["stars"]]
	return catalog(category).get(id, {}).get("unlock", "")

const GAME_NAMES := { 0: "RC Prix", 1: "Tilt Maze", 2: "Splash Hoops", 6: "Tummy Tunes", 8: "Top Spin", 9: "Paper Sumo" }

## A prize from a game (a vault, a secret, a finale): "sticker:<id>", "food:<special food>",
## "acc:<id>", "bg:<id>", "decor:<id>", "case:<id>" or "coins:<n>". Gives it and says what it was:
## { "name", "icon" (Texture2D), "kind" } (the game shows it as it's taken).
## "sticker:pal": a sticker of one of YOUR pals (one you've met and haven't a sticker of: the pal you
## have now if it can be; none left: coins) - never a pal you don't know yet (the user, 2026-10-17)
func give_prize(prize: String) -> Dictionary:
	var kind := prize.get_slice(":", 0)
	var id := prize.get_slice(":", 1)
	if prize == "sticker:pal":
		id = pal_sticker_prize()
		if id == "":
			GameData.add_coins(PAL_STICKER_COINS)
			return { "name": "+%d coins" % PAL_STICKER_COINS, "icon": UiArt.coin(), "kind": "coins" }
		prize = "sticker:" + id
	match kind:
		"food":
			var coins := Shop.give_special(id)
			var icon: Texture2D = null
			for f in FoodLibrary.SPECIALS:
				if f["name"] == id:
					icon = load(f["icon"])
			return { "name": id if coins == 0 else "+%d coins" % coins, "icon": icon, "kind": "food" }
		"coins":
			GameData.add_coins(int(id))
			return { "name": "+%s coins" % id, "icon": UiArt.coin(), "kind": "coins" }
	var cat: String = { "sticker": "stickers", "acc": "accessories", "bg": "backgrounds", "decor": "decor", "case": "cases" }.get(kind, "")
	if cat == "":
		return {}
	var had_case: bool = not owned.get("cases", []).is_empty()
	unlock(cat, id)
	var name := item_name(cat, id)
	if cat == "stickers" and not had_case and is_owned("cases", FIRST_CASE):
		name += " + a case"                              # (the first case came with it)
	return { "name": name, "icon": prize_icon(prize), "kind": cat }

## "sticker:pal": which pal's sticker it gives right now ("" = none left: coins instead)
const PAL_STICKER_COINS := 10
func pal_sticker_prize() -> String:
	var mine: Array = PAL_STICKERS.filter(func(p): return p in PetState.discovered and not is_owned("stickers", p))
	if mine.is_empty():
		return ""
	return PetState.form_id if PetState.form_id in mine else mine[0]

## An item's name, any category (a pal sticker: the pal's name)
func item_name(category: String, id: String) -> String:
	if category == "stickers" and id in PetState.FORMS:
		return PetState.FORMS[id]["name"]
	return catalog(category).get(id, {}).get("name", id)

## A prize's picture (for the game's prize reveal and the vault's window)
func prize_icon(prize: String) -> Texture2D:
	if prize == "sticker:pal":
		var who := pal_sticker_prize()                  # (the one it would give now; none: coins)
		if who == "":
			return UiArt.coin()
		prize = "sticker:" + who
	var kind := prize.get_slice(":", 0)
	var id := prize.get_slice(":", 1)
	var path := ""
	match kind:
		"sticker":
			path = "res://textures/cases/stickers/book/%s.png" % id
		"food":
			for f in FoodLibrary.SPECIALS:
				if f["name"] == id:
					path = f["icon"]
		"acc":
			path = "res://textures/pet/accessories/icons/%s.png" % id
		"case":
			path = "res://textures/cases/icons/%s.png" % id
		"bg", "decor":
			path = catalog("backgrounds" if kind == "bg" else "decor").get(id, {}).get("icon", "")
	if path != "" and ResourceLoader.exists(path):
		return load(path)
	return UiArt.question()

## Level-based rewards (Tilt Maze): `levels` = levels cleared in this run
func report_game_levels(game: int, levels: int) -> void:
	for r in REWARDS:
		if r.get("game", -1) == game and r.has("levels") and levels >= r["levels"] and not is_owned(r["category"], r["id"]):
			unlock(r["category"], r["id"])

func has_new(category: String) -> bool:
	for k in new_items:
		if k.begins_with(category + "/"):
			return true
	return false

func is_new(category: String, id: String) -> bool:
	return new_items.has("%s/%s" % [category, id])

func mark_seen_item(category: String, id: String) -> void:
	if new_items.erase("%s/%s" % [category, id]):
		save_data()

## The player has seen this category's list: its NEW badges go away
func mark_seen(category: String) -> void:
	for k in new_items.keys():
		if k.begins_with(category + "/"):
			new_items.erase(k)
	save_data()

func catalog(category: String) -> Dictionary:
	match category:
		"accessories": return ACCESSORIES
		"decor": return DECOR
		"cases": return CASES
		"stickers": return STICKERS
	return BACKGROUNDS

func order(category: String) -> Array:
	match category:
		"accessories": return ACCESSORY_ORDER
		"decor": return DECOR_ORDER
		"cases": return CASE_ORDER
		"stickers": return PAL_STICKERS + STICKER_ORDER
	return BACKGROUND_ORDER

func equipped(category: String) -> String:
	match category:
		"accessories": return equipped_accessory
		"decor": return equipped_decor
		"cases": return equipped_case
	return equipped_background

## Equip any owned item of a category. Returns false if it can't be used.
func equip(category: String, id: String) -> bool:
	if category == "backgrounds":
		return equip_background(id)
	if category == "cases":
		if id != "" and not is_owned("cases", id):
			return false
		equipped_case = id
		save_data()
		equipped_changed.emit(category, id)
		return true
	if not is_owned(category, id) or id not in catalog(category):
		return false
	if category == "accessories":
		equipped_accessory = id
	else:
		# decor: one complement + one colour; "none" clears both; picking the one already in
		# use takes it off again
		match DECOR[id].get("kind", ""):
			"color":
				equipped_gut_color = "" if equipped_gut_color == id else id
			"complement":
				equipped_decor = "none" if equipped_decor == id else id
			_:
				equipped_decor = "none"
				equipped_gut_color = ""
	save_data()
	equipped_changed.emit(category, id)
	return true

func is_in_use(category: String, id: String) -> bool:
	if category == "backgrounds":
		return equipped_background == id or equipped_bg_color == id
	if category == "decor" and id != "none":
		return equipped_decor == id or equipped_gut_color == id
	if category == "decor":
		return equipped_decor == "none" and equipped_gut_color == ""
	return equipped(category) == id

## Short 'In use' text for a category's card
func in_use_label(category: String) -> String:
	if category == "backgrounds":
		return "2 items" if equipped_bg_color != DEFAULT_BG_COLOR else BACKGROUNDS[equipped_background]["name"]
	if category == "decor":
		var names := []
		if equipped_gut_color != "":
			names.append(DECOR[equipped_gut_color]["name"].replace(" Gut", ""))
		if equipped_decor != "none":
			names.append(DECOR[equipped_decor]["name"])
		if names.size() == 2:
			return "2 items"                  # (both would not fit on the card)
		return names[0] if not names.is_empty() else "Nothing"
	if category == "cases":
		return CASES[equipped_case]["name"] if equipped_case in CASES else "No case"
	return catalog(category)[equipped(category)]["name"]

## A case's colours for its side: [outline, body, light] (Melon Soda's for one without)
func case_tones(id: String) -> Array:
	var t: Array = CASES.get(id, {}).get("tones", CASES["melon"]["tones"])
	return [Color.html(t[0]), Color.html(t[1]), Color.html(t[2])]

func equip_background(id: String) -> bool:
	if not is_owned("backgrounds", id) or id not in BACKGROUNDS:
		return false
	if BACKGROUNDS[id].get("kind", "") == "color":
		equipped_bg_color = id                  # always one sky colour (pink by default)
	elif BACKGROUNDS[id]["layers"].is_empty():
		return false
	else:
		equipped_background = id
	save_data()
	background_changed.emit(id)
	equipped_changed.emit("backgrounds", id)
	return true

func save_data() -> void:
	var file = FileAccess.open(SaveSlot.path(SAVE_FILE), FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify({ "owned": owned, "equipped_background": equipped_background, "equipped_bg_color": equipped_bg_color,
			"equipped_accessory": equipped_accessory, "equipped_decor": equipped_decor, "equipped_gut_color": equipped_gut_color, "new_items": new_items.keys(),
			"equipped_case": equipped_case }))

func load_data() -> void:
	if not FileAccess.file_exists(SaveSlot.path(SAVE_FILE)):
		return
	var file = FileAccess.open(SaveSlot.path(SAVE_FILE), FileAccess.READ)
	if not file:
		return
	var parsed = JSON.parse_string(file.get_as_text())
	if parsed is Dictionary:
		var saved: Dictionary = parsed.get("owned", {})
		for cat in saved:
			for id in saved[cat]:
				if cat not in owned:
					owned[cat] = []
				if id not in owned[cat]:
					owned[cat].append(id)
		var bgc := str(parsed.get("equipped_bg_color", DEFAULT_BG_COLOR))
		if bgc in BACKGROUNDS and is_owned("backgrounds", bgc):
			equipped_bg_color = bgc
		var eq := str(parsed.get("equipped_background", "clouds"))
		if eq in BACKGROUNDS and is_owned("backgrounds", eq):
			equipped_background = eq
		for k in parsed.get("new_items", []):
			new_items[str(k)] = true
		var acc := str(parsed.get("equipped_accessory", "none"))
		if acc in ACCESSORIES and is_owned("accessories", acc):
			equipped_accessory = acc
		var col := str(parsed.get("equipped_gut_color", ""))
		if col in DECOR and is_owned("decor", col):
			equipped_gut_color = col
		var dec := str(parsed.get("equipped_decor", "none"))
		if dec in DECOR and is_owned("decor", dec):
			equipped_decor = dec
		var cs := str(parsed.get("equipped_case", ""))
		if cs in CASES and is_owned("cases", cs):
			equipped_case = cs
