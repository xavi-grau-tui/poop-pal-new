extends Node
## Autoload "LuckyPinch": the claw machine bonus.
##
## Every now and then after a meal, a claw comes down into the pet cam holding a glowing
## capsule (claw_visit.gd), the LCD shows BONUS! and the Games button blinks until the bonus
## is played. While it is pending the bonus is mandatory: the food and settings menus are
## locked and the Games menu shows only the LUCKY PINCH card (2 tries, up to 2 prizes).
## Prizes are items not unlocked yet (Collection), so the claw never gives a repeat.

signal changed(pending: bool)
signal tries_changed(tries: int)

const GAME_INDEX := 100               # its "page" for GameScreen (not a regular card)
const TRIES := 2
const CHANCE := 0.2                   # after each meal (never two meals in a row)
const VISIT_DELAY := 6.0              # after the meal: the hatch "hi!" / PAL UNLOCKED go first
## Prototype/testing: the first meal after every launch always brings the claw
const TEST_FIRST_MEAL := true

var pending := false
var tries := 0
var prizes: Array[Dictionary] = []    # won in this bonus: { category, id, name }
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
	if not go or prize_pool().is_empty():
		return
	await get_tree().create_timer(VISIT_DELAY).timeout
	if not pending:
		start()

func start() -> void:
	pending = true
	tries = TRIES
	prizes.clear()
	changed.emit(true)
	_play_visit()

func use_try() -> void:
	tries = maxi(0, tries - 1)
	tries_changed.emit(tries)

## Unlocks a random item the player doesn't have yet. {} when there's nothing left.
func win_prize() -> Dictionary:
	var pool := prize_pool()
	if pool.is_empty():
		return {}
	var p: Dictionary = pool[randi() % pool.size()]
	prizes.append(p)
	Collection.unlock(p["category"], p["id"])
	tries_changed.emit(tries)
	return p

func finish() -> void:
	if not pending:
		return
	pending = false
	tries = 0
	changed.emit(false)

func prize_pool() -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for cat in ["backgrounds", "accessories", "decor"]:
		var items := Collection.catalog(cat)
		for id in Collection.order(cat):
			var item: Dictionary = items[id]
			if item.get("name", "???") == "???" or Collection.is_owned(cat, id):
				continue
			out.append({ "category": cat, "id": id, "name": item["name"] })
	return out

func _play_visit() -> void:
	var pet_view := get_node_or_null("/root/PoopPal/Main UI/PetView")
	var poop := get_node_or_null("/root/PoopPal/Main UI/PetView/Poop") as Node2D
	if not pet_view or not poop:
		return
	var visit = load("res://scripts/claw_visit.gd").new()
	pet_view.add_child(visit)
	pet_view.move_child(visit, poop.get_index() + 1)
	visit.play(poop)
