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
@export var bunny_volume_db := -24.0     # the rabbit's sniff-sniff-hop as the logo shows: barely there

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
	# straight out of the box the device has no power yet: wait for the battery strip
	while Unboxing.waiting():
		await get_tree().process_frame
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
	_setup_nose()

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
	tween.tween_callback(_bunny)
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
	if event is InputEventMouseButton and event.pressed and not done and not Unboxing.waiting():
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

## The rabbit's nose (logo texture px): the triangle above the mouth line, and the point
## on its base it grows from (where the mouth line starts)
const NOSE_RECT := Rect2(80, 199, 54, 17)
const NOSE_BASE := Vector2(107, 216)
const NOSE_PUFF := Vector2(0.12, 0.35)   # extra width / height at the peak of a twitch

## The twitch is a shader on the logo itself (no cut-out pieces, so no seams): at twitch 0
## it draws the logo untouched; above 0 it enlarges just the nose around its base.
const NOSE_SHADER := """
shader_type canvas_item;
uniform float twitch = 0.0;
uniform vec4 nose_rect;     // x, y, w, h in UV
uniform vec2 nose_base;     // UV
uniform vec2 puff;
bool in_nose(vec2 uv) {
	return uv.x >= nose_rect.x && uv.x <= nose_rect.x + nose_rect.z
		&& uv.y >= nose_rect.y && uv.y <= nose_rect.y + nose_rect.w;
}
void fragment() {
	if (twitch <= 0.0) {
		COLOR = texture(TEXTURE, UV);
	} else {
		vec2 s = vec2(1.0) + puff * twitch;
		vec2 src = nose_base + (UV - nose_base) / s;
		if (in_nose(src)) {
			COLOR = texture(TEXTURE, src);
		} else if (in_nose(UV)) {
			COLOR = vec4(0.0);           // where the nose was before it grew
		} else {
			COLOR = texture(TEXTURE, UV);
		}
	}
}
"""

func _setup_nose() -> void:
	var size := logo_texture.get_size()
	var mat := ShaderMaterial.new()
	mat.shader = Shader.new()
	mat.shader.code = NOSE_SHADER
	mat.set_shader_parameter("nose_rect", Vector4(NOSE_RECT.position.x / size.x, NOSE_RECT.position.y / size.y,
			NOSE_RECT.size.x / size.x, NOSE_RECT.size.y / size.y))
	mat.set_shader_parameter("nose_base", NOSE_BASE / size)
	mat.set_shader_parameter("puff", NOSE_PUFF)
	logo.material = mat

## A sniff: the nose puffs up and settles (timed with the sound's sniffs)
func _twitch_nose() -> void:
	var mat := logo.material as ShaderMaterial
	var t := logo.create_tween()
	t.tween_method(func(v): mat.set_shader_parameter("twitch", v), 0.0, 1.0, 0.04).set_ease(Tween.EASE_OUT)
	t.tween_method(func(v): mat.set_shader_parameter("twitch", v), 1.0, 0.0, 0.07).set_ease(Tween.EASE_IN)

## The Kobaya Tech rabbit: two tiny sniffs and a soft hop (tools/design/boot_sfx.py)
func _bunny() -> void:
	_twitch_nose()
	get_tree().create_timer(0.075).timeout.connect(_twitch_nose)   # the second sniff
	var sfx := AudioStreamPlayer.new()
	sfx.stream = preload("res://sounds/fx/kobaya_bunny.wav")
	sfx.volume_db = bunny_volume_db
	add_child(sfx)
	sfx.finished.connect(sfx.queue_free)
	sfx.play()

func _music_off() -> void:
	var music = get_node_or_null("/root/PoopPal/MusicController")
	if music:
		music.stop()

func _music_on() -> void:
	var music = get_node_or_null("/root/PoopPal/MusicController")
	if music and music.has_method("play_random_song"):
		music.play_random_song()
