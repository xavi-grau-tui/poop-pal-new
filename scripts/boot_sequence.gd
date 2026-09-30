extends Node2D
## Power-on sequence: black screen + blank LCD -> developer logo -> welcome text
## -> screen turns on, LCD populates, music starts. Tap anywhere to skip.
##
## Lives under "Main UI" so the black screen sits above the pet view but below
## the console frame (z_index), and uses the same coordinates as PinkBackground.

signal finished

@export var logo_texture: Texture2D = preload("res://textures/boot/kobaya_logo.png")
@export var welcome_text := "Welcome to Poop Pal!\n\nFeed it, raise it and watch it evolve through its natural cycle.\n\nPlay to unlock items and pals."
@export var start_delay := 0.8
@export var logo_fade_in := 1.3
@export var logo_hold := 1.4
@export var logo_fade_out := 1.3
@export var text_type_time := 2.4
@export var text_hold := 3.0
@export var screen_on_time := 0.8

const SCREEN_COLOR := Color(0.078, 0.078, 0.078)  # matches the logo's background
const TEXT_COLOR := Color(0.98, 0.94, 0.86)

var screen: ColorRect
var logo: Sprite2D
var text: Label
var blocker: CanvasLayer
var tween: Tween
var done := false

func _ready() -> void:
	z_index = 1  # above pet view / mystery, below console frame & LCD
	_music_off()
	_set_lcd_visible(false)
	_build()
	_run()

func _build() -> void:
	var pink: Sprite2D = get_node("../PetBackground/PinkBackground")
	var rect: Rect2 = pink.get_rect()
	var tl := pink.position + rect.position * pink.scale
	var sz := rect.size * pink.scale
	var center := tl + sz / 2.0

	screen = ColorRect.new()
	screen.color = SCREEN_COLOR
	screen.position = tl
	screen.size = sz
	screen.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(screen)

	logo = Sprite2D.new()
	logo.texture = logo_texture
	logo.position = center
	logo.modulate.a = 0.0
	add_child(logo)

	text = Label.new()
	text.text = welcome_text
	text.add_theme_font_override("font", load("res://fonts/pixChicago.ttf"))
	text.add_theme_font_size_override("font_size", 40)
	text.add_theme_color_override("font_color", TEXT_COLOR)
	text.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	text.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	text.size = Vector2(sz.x * 0.74, sz.y * 0.8)      # tall enough for all the lines
	text.position = center - text.size / 2.0 - Vector2(0, sz.y * 0.03)
	text.visible_ratio = 0.0
	text.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(text)

	# Swallow all input during boot; a tap skips it
	blocker = CanvasLayer.new()
	blocker.layer = 100
	var catcher := Control.new()
	catcher.set_anchors_preset(Control.PRESET_FULL_RECT)
	catcher.mouse_filter = Control.MOUSE_FILTER_STOP
	catcher.gui_input.connect(_on_blocker_input)
	blocker.add_child(catcher)
	add_child(blocker)

func _run() -> void:
	tween = create_tween()
	tween.tween_interval(start_delay)
	# Developer logo
	tween.tween_property(logo, "modulate:a", 1.0, logo_fade_in).set_trans(Tween.TRANS_SINE)
	tween.tween_interval(logo_hold)
	tween.tween_property(logo, "modulate:a", 0.0, logo_fade_out).set_trans(Tween.TRANS_SINE)
	tween.tween_interval(0.5)
	# Welcome text, typed out
	tween.tween_property(text, "visible_ratio", 1.0, text_type_time)
	tween.tween_interval(text_hold)
	tween.tween_property(text, "modulate:a", 0.0, 0.6)
	# Screen on
	tween.tween_property(screen, "modulate:a", 0.0, screen_on_time).set_trans(Tween.TRANS_SINE)
	tween.tween_callback(_finish)

func _on_blocker_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and not done:
		if tween:
			tween.kill()
		var t := create_tween()
		t.tween_property(self, "modulate:a", 0.0, 0.25)
		t.tween_callback(_finish)

func _finish() -> void:
	if done:
		return
	done = true
	_music_on()
	_lcd_power_on()
	blocker.queue_free()
	finished.emit()
	queue_free.call_deferred()

# ------------------------------------------------------------------ LCD / MUSIC

const LCD_PARTS := ["StaticLabels", "ScoreCounter", "FoodTimer", "DrinkTimer"]

func _set_lcd_visible(on: bool) -> void:
	var lcd = get_node_or_null("../LCD Screen")
	if not lcd:
		return
	for part in LCD_PARTS:
		var n = lcd.get_node_or_null(part)
		if n:
			n.visible = on

func _lcd_power_on() -> void:
	# Quick flicker, like an LCD waking up; runs on the LCD so it survives our queue_free
	var lcd = get_node_or_null("../LCD Screen")
	if not lcd:
		return
	var nodes := []
	for part in LCD_PARTS:
		var n = lcd.get_node_or_null(part)
		if n:
			nodes.append(n)
	var t = lcd.create_tween()
	for on in [true, false, true, false, true]:
		t.tween_callback(func():
			for n in nodes:
				n.visible = on)
		t.tween_interval(0.07)

func _music_off() -> void:
	var music = get_node_or_null("/root/PoopPal/MusicController")
	if music:
		music.stop()

func _music_on() -> void:
	var music = get_node_or_null("/root/PoopPal/MusicController")
	if music and music.has_method("play_random_song"):
		music.play_random_song()
