extends Node
## Autoload "LuckyPinch": the claw machine bonus.
##
## Every now and then after a meal, a claw comes down into the pet cam holding a glowing
## capsule (claw_visit.gd), the LCD shows BONUS! and the Games button blinks until the bonus
## is played. While it is pending the bonus is mandatory: the food and settings menus are
## locked and the Games menu shows only the LUCKY PINCH card (2 tries).
##
## The machine keeps its pile: every capsule (where it lies, its colour, the prize inside)
## stays as it is between bonuses, also the ones knocked aside; won capsules are gone. Only
## when it is empty does it get refilled. The prizes are Collection.LUCKY_ITEMS, items you
## can only get here; once all are won it is refilled with points capsules (for now).

signal changed(pending: bool)
signal tries_changed(tries: int)
signal visit_finished                 # the claw has gone back up: Games can be opened

const GAME_INDEX := 100               # its "page" for GameScreen (not a regular card)
const TRIES := 2
const CHANCE := 0.2                   # after each meal (never two meals in a row)
const VISIT_DELAY := 2.2              # (by then a new pal's PAL UNLOCKED! has started; it plays out first)
## Prototype/testing: the first meal after every launch always brings the claw
const TEST_FIRST_MEAL := true

# The pit: 3 depth rows x 4 slots (x in the game's px, d = depth 0 front .. 1 back)
const ROWS := [0.1, 0.5, 0.9]
const SLOT_X := [320.0, 485.0, 650.0, 815.0]
const ROW_SHIFT := 55.0               # the middle row sits between the others
const COLORS := ["pink", "mint", "yellow", "lilac", "orange"]
const POINTS_CAPSULES := 6            # when no item is left: capsules with points
const POINTS := [200, 300, 500]

var pending := false
var visiting := false                 # the claw is in the pet cam right now
var tries := 0
var prizes: Array[Dictionary] = []    # won in this bonus: { category, id, name } or { points }
var pit: Array[Dictionary] = []       # { x, d, color, rot, prize }
var _last_meal_bonus := false
var _test_done := false

func _ready() -> void:
	PetState.fed.connect(_on_fed)

func _on_fed(_food: Dictionary) -> void:
	if pending:
		return
	var go := false
	if TEST_FIRST_MEAL and not _test_done:
		go = true
		_test_done = true
	elif not _last_meal_bonus:
		go = randf() < CHANCE
	_last_meal_bonus = go
	if go:
		start()

func _can_start_now() -> bool:
	if GameScreen.is_active or FoodRainSpawner.is_locked or DrinkWaterfallSpawner.is_locked:
		return false
	var mgr = get_node_or_null("/root/PoopPal/Main UI/MenuManager")
	if mgr and (mgr.pending_menu != null or mgr.get("returning")):
		return false
	return true

## An open menu (food, drinks, settings, games) closes the normal way, like after eating
func _close_open_menu() -> bool:
	for b in get_tree().get_nodes_in_group("menu_toggle_buttons"):
		if b.button_pressed:
			var mb = get_node_or_null("/root/PoopPal/Main UI/MainButton")
			if mb and mb.has_method("_untoggle_current_menu"):
				mb._reset_hold()             # (a hold on an option is cancelled)
				mb._untoggle_current_menu()
				return true
	return false

## The bonus begins. From this moment every button is locked. Once the pal is done (its
## hatch / evolve and a PAL UNLOCKED! with the gear blink, if any, all play out first) the
## BONUS! comes all at once: the claw drops in, the LCD says BONUS!, the Games button blinks.
## Buttons stay locked until the claw has gone back up; then only Games works.
func start() -> void:
	if pit.is_empty():
		refill()
	pending = true
	visiting = true                   # (every button is locked from now on)
	tries = TRIES
	prizes.clear()
	await get_tree().create_timer(VISIT_DELAY).timeout
	# waits for a moment it can't break (a menu sliding, food going down, a game) and for
	# the pal's own show to end (transforming, an LCD message, a button blinking)
	var quiet := 0.0
	while quiet < 0.3:
		await get_tree().create_timer(0.1).timeout
		quiet = quiet + 0.1 if (_can_start_now() and _pal_show_over()) else 0.0
	if _close_open_menu():
		await get_tree().create_timer(0.45).timeout     # the menu slides away first
	changed.emit(true)                # the Games button starts blinking, with the claw
	_play_visit()

func _pal_show_over() -> bool:
	var lcd = get_node_or_null("/root/PoopPal/Main UI/LCD Screen")
	if lcd and lcd.has_method("is_showing_message") and lcd.is_showing_message():
		return false
	for b in get_tree().get_nodes_in_group("menu_toggle_buttons"):
		if b.has_method("is_blinking") and b.is_blinking():
			return false
	var poop = get_node_or_null("/root/PoopPal/Main UI/PetView/Poop")
	if poop and poop.get("_transforming"):
		return false
	return true

func use_try() -> void:
	tries = maxi(0, tries - 1)
	tries_changed.emit(tries)

## A capsule reached the chute: it leaves the machine and its prize is yours
func win(capsule: Dictionary) -> Dictionary:
	pit.erase(capsule)
	var prize: Dictionary = capsule.get("prize", {})
	if prize.has("category"):
		var item: Dictionary = Collection.catalog(prize["category"]).get(prize["id"], {})
		prize = { "category": prize["category"], "id": prize["id"], "name": item.get("name", "?") }
		Collection.unlock(prize["category"], prize["id"])
	prizes.append(prize)
	tries_changed.emit(tries)
	return prize

func finish() -> void:
	if not pending:
		return
	pending = false
	visiting = false
	tries = 0
	changed.emit(false)

func end_visit() -> void:
	if not visiting:
		return
	visiting = false
	visit_finished.emit()

## A new pile: one capsule per Lucky Pinch item you don't have yet (points when none left),
## spread over random slots
func refill() -> void:
	pit.clear()
	var contents: Array = []
	for it in Collection.LUCKY_ITEMS:
		if not Collection.is_owned(it[0], it[1]):
			contents.append({ "category": it[0], "id": it[1] })
	if contents.is_empty():
		for i in POINTS_CAPSULES:
			contents.append({ "points": POINTS[i % POINTS.size()] })
	var slots: Array = []
	for r in ROWS.size():
		for c in SLOT_X.size():
			slots.append(Vector2i(c, r))
	slots.shuffle()
	for i in mini(contents.size(), slots.size()):
		var sl: Vector2i = slots[i]
		var x: float = SLOT_X[sl.x] + (ROW_SHIFT if sl.y == 1 else 0.0) + randf_range(-14, 14)
		pit.append({
			"x": minf(x, 885.0),
			"d": ROWS[sl.y] + randf_range(-0.04, 0.04),
			"color": COLORS[randi() % COLORS.size()],
			"rot": randf_range(-0.5, 0.5),
			"prize": contents[i],
		})

## "Dress up", "Background · complement", "Gut decor · color"... for the prize card
static func kind_label(category: String, id: String) -> String:
	var item: Dictionary = Collection.catalog(category).get(id, {})
	var kind: String = item.get("kind", "")
	match category:
		"accessories":
			return "Dress up"
		"backgrounds":
			return "Background - " + (kind if kind != "" else "complement")
		"decor":
			return "Gut decor - " + (kind if kind != "" else "complement")
	return ""

func _play_visit() -> void:
	var pet_view := get_node_or_null("/root/PoopPal/Main UI/PetView")
	var poop := get_node_or_null("/root/PoopPal/Main UI/PetView/Poop") as Node2D
	if not pet_view or not poop:
		end_visit()
		return
	var visit = load("res://scripts/claw_visit.gd").new()
	pet_view.add_child(visit)
	pet_view.move_child(visit, poop.get_index() + 1)
	visit.tree_exited.connect(end_visit)
	visit.play(poop)
