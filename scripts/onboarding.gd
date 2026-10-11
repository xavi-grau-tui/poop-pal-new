extends Node2D
class_name Onboarding
## The guided start, on the main screen, for a player who has never had a pal (the very first
## launch; with the testing switches on, every launch). Added by BootSequence when it finishes.
##   1. A card: "Welcome to HaraTomo! Tap [food button] to eat something and meet your new pal."
##      The food button and the EAT sign blink bip-bip … bip-bip, with a short sharp buzz on each
##      bip, and only the food button works (MenuButtons checks Onboarding.active).
##   2. Once the first meal has hatched the pal: "Say hi to <name>! It's a <Type [icon]> pal. What you eat decides how it
##      grows." (a tap, or a few seconds, puts it away). LuckyPinch waits while a card is up.
##   3. If a bonus came with that meal: once the claw has gone back up, "Lucky you! Sometimes a
##      bonus turns up after a meal.", then "Tap [games button] to play the bonus game!" with the
##      games button doing the bip-bip (the other buttons are locked by the bonus anyway).
##      Later bonuses come without cards.
## What comes next (games and stars, the first sticker, drinks, the shop...) is planned in
## docs/ideas_roadmap.md ("Onboarding").

static var active := false             # the welcome step is on: only the food button works
static var showing := false            # a card is up (or about to be): LuckyPinch waits for it

const FOOD_ICON := "res://textures/buttons/logofood.png"      # just the buttons' icons, big and clear
const GAMES_ICON := "res://textures/buttons/logogames.png"
const INK := Color8(92, 60, 44)
## the five types' colours, dark enough to read on the card (the Power Rangers set)
const TYPE_INK := { "green": Color8(46, 128, 60), "sweet": Color8(60, 86, 140), "greasy": Color8(196, 110, 16), "spicy": Color8(196, 46, 40), "sour": Color8(112, 142, 30) }

var food_button: Node
var game_button: Node
var beat_button: Node                  # the button doing the bip-bip right now
var poop: Node
var card: Control
var card_bg: NinePatchRect
var card_text: RichTextLabel
var beat: Tween
var menu_was_open := false
var hatched := false
var food_chosen := false               # a food was picked (it rains in before the pal hatches)
var card_tween: Tween
var card_gen := 0                      # bumped by every hide: a show still on its way gives up

func _ready() -> void:
	if PetState.has_poop() or not PetState.discovered.is_empty():
		queue_free()                     # not a first start: nothing to show
		return
	food_button = get_node_or_null("../MenuButtons/FoodButton")
	game_button = get_node_or_null("../MenuButtons/GameButton")
	poop = get_node_or_null("../PetView/Poop")
	z_index = 50
	active = true
	_build_card()
	await get_tree().create_timer(0.8).timeout     # (a breath after the screen has come on)
	if _gone() or not PetState.needs_first_meal():
		return
	PetState.form_changed.connect(_on_form_changed)
	if food_button and food_button.button_pressed:
		menu_was_open = true                     # (opened that fast: the card waits until it closes)
		return
	_show_card("Welcome to HaraTomo! Tap [img=66x81]%s[/img] to eat something and meet your new pal." % FOOD_ICON)
	_start_beat(food_button)

func _process(_delta: float) -> void:
	if hatched or not food_button:
		return
	# a food was picked: the welcome is done for good (no coming back while it rains in)
	if FoodRainSpawner.is_locked and not food_chosen:
		food_chosen = true
		_stop_beat()
		_hide_card()
	if food_chosen:
		return
	# the food menu open: the hint steps aside; closed again without eating: it comes back
	var open: bool = food_button.button_pressed
	if open == menu_was_open:
		return
	menu_was_open = open
	if open:
		_stop_beat()
		_hide_card()
	elif PetState.needs_first_meal():
		# closed without eating? wait a moment first (a picked food may be just about to rain in)
		await get_tree().create_timer(0.5).timeout
		if _gone() or food_chosen or hatched or menu_was_open or not PetState.needs_first_meal():
			return
		_show_card("Welcome to HaraTomo! Tap [img=66x81]%s[/img] to eat something and meet your new pal." % FOOD_ICON)
		_start_beat(food_button)

func _on_form_changed(id: String, reason: String) -> void:
	if reason != "hatch" or hatched:
		return
	hatched = true
	active = false
	showing = true                       # (the bonus, if any, waits for the next card)
	_stop_beat()
	_hide_card()
	var pal_name: String = PetState.FORMS.get(id, {}).get("name", "your pal")
	# after the hatch and its "hi!" (and while PAL UNLOCKED! is on the LCD)
	await get_tree().create_timer(2.6).timeout
	if _gone():
		return
	# its type (the family of its first meal): the word in the type's colour + the type's icon
	var fam: String = PetState.get_form().get("family", "")
	var info: Array = UiArt.TYPE_TAGS.get(fam, [fam.capitalize(), Color.WHITE])
	var col: Color = TYPE_INK.get(fam, INK)
	var type_txt := "[color=#%s]%s[/color] [img=40]res://textures/menus/tiers/%s.png[/img]" % [col.to_html(false), info[0], fam]
	_show_card("Say hi to %s! It's a %s pal. What you eat decides how it grows." % [pal_name, type_txt])
	await get_tree().create_timer(6.0).timeout
	if _gone():
		return
	_hide_card()
	await get_tree().create_timer(1.0).timeout     # (a breath before anything else happens)
	showing = false
	if LuckyPinch.pending:
		_bonus_steps()
	else:
		queue_free()

## The first bonus: once the claw has gone back up, two cards; the second points at Games
func _bonus_steps() -> void:
	if LuckyPinch.visiting:
		await LuckyPinch.visit_finished
	if _gone() or not LuckyPinch.pending:
		queue_free()
		return
	showing = true
	_show_card("Lucky you! Sometimes a bonus turns up after a meal.")
	await get_tree().create_timer(3.5).timeout
	if _gone():
		return
	_show_card("Tap [img=99x72]%s[/img] to play the bonus game!" % GAMES_ICON)
	if game_button and game_button.has_method("stop_attention"):
		game_button.stop_attention()     # (its usual bonus blink makes way for the bip-bip)
	_start_beat(game_button)
	# done when Games is opened (or the bonus is over some other way)
	while is_instance_valid(self) and LuckyPinch.pending and not game_button.button_pressed:
		await get_tree().process_frame
	if _gone():
		return
	_stop_beat()
	if LuckyPinch.pending and game_button.has_method("start_attention"):
		game_button.start_attention()    # back to the usual bonus look (lit while you play it)
	_hide_card()
	showing = false
	await get_tree().create_timer(0.3).timeout
	queue_free()

## True once this guide has been freed or taken out of the game (also while the game quits):
## every step checks it after a wait
func _gone() -> bool:
	return not is_instance_valid(self) or not is_inside_tree()

# ------------------------------------------------------------------ THE BLINK (bip-bip … bip-bip)

## The "do this next" signal: `button` blinks bip-bip … bip-bip with a short sharp buzz on each
## bip (the food button also flashes the EAT sign with it)
func _start_beat(button: Node) -> void:
	_stop_beat()
	beat_button = button
	beat = create_tween().set_loops()
	for i in 2:
		beat.tween_callback(func(): _lit(true))
		beat.tween_interval(0.09)
		beat.tween_callback(func(): _lit(false))
		beat.tween_interval(0.09)
	beat.tween_interval(0.62)

func _stop_beat() -> void:
	if beat:
		beat.kill()
		beat = null
	if beat_button and beat_button.has_method("stop_attention"):
		beat_button.stop_attention()            # back to its real look
	if poop and poop.get("mystery"):
		poop.mystery.modulate.a = 1.0
	beat_button = null

## One "bip": the button lights up (the EAT sign flashes with the food button), a short sharp buzz
func _lit(on: bool) -> void:
	if beat_button and beat_button.has_method("_show"):
		beat_button._show(beat_button.pressed_texture if on else beat_button.normal_texture)
	if beat_button == food_button and poop and poop.get("mystery"):
		poop.mystery.modulate.a = 1.0 if not on else 0.35
	if on:
		Input.vibrate_handheld(12)

# ------------------------------------------------------------------ THE CARD

## Same look as the minigames' coach cards (cream face, dark border, brown shadow), across the
## top of the pet screen
func _build_card() -> void:
	var pink: Sprite2D = get_node("../PetBackground/PinkBackground")
	var rect: Rect2 = pink.get_rect()
	var tl := pink.position + rect.position * pink.scale
	var sz := rect.size * pink.scale
	card = Control.new()
	card.size = Vector2(sz.x - 180, 200)                 # (well inside the screen: room on top and the sides)
	card.position = Vector2(tl.x + 90, tl.y + 80)
	card.mouse_filter = Control.MOUSE_FILTER_STOP
	card.gui_input.connect(func(e):
		if e is InputEventMouseButton and e.pressed and hatched:
			_hide_card())                         # (the welcome stays until you've eaten)
	card.visible = false
	add_child(card)
	card_bg = NinePatchRect.new()
	card_bg.texture = BaseMinigame._label_frame_texture()
	card_bg.patch_margin_left = 4
	card_bg.patch_margin_right = 4
	card_bg.patch_margin_top = 4
	card_bg.patch_margin_bottom = 7
	card_bg.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	card_bg.scale = Vector2(3, 3)
	card_bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card.add_child(card_bg)
	card_text = RichTextLabel.new()
	card_text.bbcode_enabled = true
	card_text.fit_content = true
	card_text.scroll_active = false
	card_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	card_text.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card_text.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST     # (the icons stay pixel-sharp)
	card_text.position = Vector2(34, 28)
	card_text.size = Vector2(card.size.x - 68, 10)
	var font = load("res://fonts/pixChicago.ttf")
	if font:
		card_text.add_theme_font_override("normal_font", font)
	card_text.add_theme_font_size_override("normal_font_size", 38)
	card_text.add_theme_color_override("default_color", INK)
	card.add_child(card_text)

func _show_card(bbcode: String) -> void:
	if _gone():
		return
	var gen := card_gen
	card_text.text = "[center]%s[/center]" % bbcode
	card.visible = true
	card.modulate.a = 0.0
	await get_tree().process_frame               # (let the text lay out, then fit the card to it)
	if _gone() or gen != card_gen:
		return                                   # (hidden meanwhile: the food menu opened)
	var h := card_text.get_content_height() + 28 + 40
	card.size.y = h
	card.pivot_offset = card.size / 2.0
	card_bg.size = card.size / 3.0
	card.scale = Vector2(0.9, 0.9)
	if card_tween:
		card_tween.kill()
	var t := card.create_tween()
	card_tween = t
	t.tween_property(card, "scale", Vector2.ONE, 0.18).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	t.parallel().tween_property(card, "modulate:a", 1.0, 0.12)

func _hide_card() -> void:
	card_gen += 1
	if not card or not card.visible:
		return
	if card_tween:
		card_tween.kill()
	var t := card.create_tween()
	card_tween = t
	t.tween_property(card, "modulate:a", 0.0, 0.15)
	t.tween_callback(func(): card.visible = false)
