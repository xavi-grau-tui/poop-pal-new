extends Node

@export var food_timer_label: Label
@export var drink_timer_label: Label
@export var score_counter_label: Label

var food_duration := 1800  # 30 minutes after each meal
var drink_duration := 900  # 15 minutes after each drink (the first meal starts it too)

# No pal yet: both at 00:00:00 and the food one blinks (it's time to eat)
var food_time_left := 0
var drink_time_left := 0

# Timers only count down while there is a pal (they start with the first meal)
var running := false

var tick_timer := 0.0
var blink_on := true

# Temporary message over the whole LCD ("ITEM UNLOCKED!")
const MESSAGE_TIME := 3.5
var _msg_label: Label
var _msg_tween: Tween
var _msg_hidden: Array[CanvasItem] = []

func _ready():
	_update_score_display()
	PetState.score_changed.connect(func(_total): _update_score_display())
	PetState.fed.connect(_on_fed)
	PetState.drank.connect(_on_drank)
	PetState.form_changed.connect(_on_form_changed)
	_align_timers_to_score()
	running = PetState.has_poop()
	if running:
		food_time_left = food_duration
		drink_time_left = drink_duration
	_update_labels()
	Collection.unlocked.connect(func(_c, _id):
		show_message("ITEM\nUNLOCKED!")
		_ding())
	PetState.pal_discovered.connect(func(_id):
		show_message("PAL\nUNLOCKED!")
		_ding())

func _ding() -> void:
	# a small, soft ding: noticeable, but you keep your focus on the minigame
	var sfx := AudioStreamPlayer.new()
	sfx.stream = load("res://sounds/fx/unlock_ding.wav")
	sfx.volume_db = -14.0
	add_child(sfx)
	sfx.play()
	sfx.finished.connect(sfx.queue_free)

## The timers end where the score ends, so the seconds sit under its last two digits
func _align_timers_to_score() -> void:
	if not score_counter_label:
		return
	var f := score_counter_label.get_theme_font("font")
	var fs := score_counter_label.get_theme_font_size("font_size")
	var right := score_counter_label.position.x + f.get_string_size("000000", HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x
	for l in [food_timer_label, drink_timer_label]:
		if l:
			l.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
			l.position.x = right - l.size.x

func show_message(text: String, secs := MESSAGE_TIME) -> void:
	if not _msg_label:
		_msg_label = Label.new()
		_msg_label.z_index = 3
		_msg_label.position = Vector2(127, -1812)
		_msg_label.size = Vector2(380, 150)
		_msg_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		_msg_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		if score_counter_label:
			_msg_label.add_theme_font_override("font", score_counter_label.get_theme_font("font"))
			_msg_label.add_theme_color_override("font_color", score_counter_label.get_theme_color("font_color"))
		_msg_label.add_theme_font_size_override("font_size", 40)
		add_child(_msg_label)
	if _msg_hidden.is_empty():
		for path in ["StaticLabels", "ScoreCounter", "FoodTimer", "DrinkTimer"]:
			var n := get_node_or_null(path) as CanvasItem
			if n and n.visible:
				n.visible = false
				_msg_hidden.append(n)
	_msg_label.text = text
	_msg_label.visible = true
	if _msg_tween:
		_msg_tween.kill()
	_msg_tween = create_tween()
	var blinks := int(secs / 0.5)
	for i in blinks:
		_msg_tween.tween_callback(func(): _msg_label.modulate.a = 1.0)
		_msg_tween.tween_interval(0.35)
		_msg_tween.tween_callback(func(): _msg_label.modulate.a = 0.25)
		_msg_tween.tween_interval(0.15)
	_msg_tween.tween_callback(_end_message)

func _end_message() -> void:
	_msg_label.visible = false
	_msg_label.modulate.a = 1.0
	for n in _msg_hidden:
		n.visible = true
	_msg_hidden.clear()

func _update_score_display() -> void:
	if score_counter_label:
		score_counter_label.text = "%06d" % PetState.score

func _on_fed(_food: Dictionary) -> void:
	food_time_left = food_duration
	if not running:
		drink_time_left = drink_duration      # the first meal starts the drink countdown too
	running = true
	_update_labels()

func _on_drank(_drink: Dictionary) -> void:
	drink_time_left = drink_duration
	_update_labels()

func _on_form_changed(_form_id: String, reason: String) -> void:
	if reason == "flush":
		running = false                       # back to the start: waiting for a meal
		food_time_left = 0
		drink_time_left = 0
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
		# before the first meal the drink timer is just unlit (faint digits), only food blinks
		if not running:
			drink_timer_label.modulate.a = 0.15
		else:
			drink_timer_label.modulate.a = 1.0 if (drink_time_left > 0 or blink_on) else 0.15

func format_time(seconds: int) -> String:
	# mm:ss (no hours: the countdowns are 30 and 15 minutes)
	return "%02d:%02d" % [seconds / 60, seconds % 60]
