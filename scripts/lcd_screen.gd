extends Node

@export var food_timer_label: Label
@export var drink_timer_label: Label
@export var score_counter_label: Label

var food_duration := 5400  # 1 hour 30 minutes
var drink_duration := 1200 # 20 minutes

var food_time_left := food_duration
var drink_time_left := drink_duration

var tick_timer := 0.0

func _ready():
	_update_score_display()
	GameData.score_changed.connect(_on_score_changed)

func _on_score_changed(_game_index: int) -> void:
	_update_score_display()

func _update_score_display() -> void:
	if score_counter_label:
		score_counter_label.text = "%06d" % GameData.get_total_score()

func _process(delta):
	tick_timer += delta
	if tick_timer >= 1.0:
		tick_timer = 0.0
		update_timers()

func update_timers():
	if food_time_left > 0:
		food_time_left -= 1
	else:
		food_time_left = food_duration  # reset for now

	if drink_time_left > 0:
		drink_time_left -= 1
	else:
		drink_time_left = drink_duration  # reset for now

	# Update labels
	food_timer_label.text = format_time(food_time_left)
	drink_timer_label.text = format_time(drink_time_left)

func format_time(seconds: int) -> String:
	var h := seconds / 3600
	var m := (seconds % 3600) / 60
	var s := seconds % 60
	return "%02d:%02d:%02d" % [h, m, s]
