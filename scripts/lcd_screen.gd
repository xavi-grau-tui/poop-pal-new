extends Node

@export var food_timer_label: Label
@export var drink_timer_label: Label
@export var score_counter_label: Label

var food_duration := 5400  # 1 hour 30 minutes
var drink_duration := 1200 # 20 minutes

var food_time_left := food_duration
var drink_time_left := drink_duration

# Timers only count down while there is a pal (they start with the first meal)
var running := false

var tick_timer := 0.0
var blink_on := true

func _ready():
	_update_score_display()
	PetState.score_changed.connect(func(_total): _update_score_display())
	PetState.fed.connect(_on_fed)
	PetState.drank.connect(_on_drank)
	PetState.form_changed.connect(_on_form_changed)
	running = PetState.has_poop()
	_update_labels()

func _update_score_display() -> void:
	if score_counter_label:
		score_counter_label.text = "%06d" % PetState.score

func _on_fed(_food: Dictionary) -> void:
	food_time_left = food_duration
	running = true
	_update_labels()

func _on_drank(_drink: Dictionary) -> void:
	drink_time_left = drink_duration
	_update_labels()

func _on_form_changed(_form_id: String, reason: String) -> void:
	if reason == "flush":
		running = false
		food_time_left = food_duration
		drink_time_left = drink_duration
		_update_labels()

func _process(delta):
	tick_timer += delta
	if tick_timer >= 0.5:
		tick_timer = 0.0
		blink_on = not blink_on
		if blink_on:
			update_timers()
		_update_labels()

func update_timers():
	if not running:
		return
	food_time_left = maxi(0, food_time_left - 1)
	drink_time_left = maxi(0, drink_time_left - 1)

func _update_labels() -> void:
	# A timer that ran out blinks at 00:00:00 (the pal is hungry / thirsty)
	if food_timer_label:
		food_timer_label.text = format_time(food_time_left)
		food_timer_label.modulate.a = 1.0 if (food_time_left > 0 or blink_on) else 0.15
	if drink_timer_label:
		drink_timer_label.text = format_time(drink_time_left)
		drink_timer_label.modulate.a = 1.0 if (drink_time_left > 0 or blink_on) else 0.15

func format_time(seconds: int) -> String:
	var h := seconds / 3600
	var m := (seconds % 3600) / 60
	var s := seconds % 60
	return "%02d:%02d:%02d" % [h, m, s]
