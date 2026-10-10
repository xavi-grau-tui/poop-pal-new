extends Node2D
class_name GameMenuSwitcher

@onready var pages = [
	$Menu/VBoxGame1,
	$Menu/VBoxGame2,
	$Menu/VBoxGame3,
	$Menu/VBoxGame4,
	$Menu/VBoxGame5,
	$Menu/VBoxGame6,
	$Menu/VBoxGame7,
	$Menu/VBoxGame8
]

@onready var dots = $Menu/Dots.get_children()

var current_page := 0

# Card art for games whose cards are still "?" placeholders in the scene.
# Shown once the game is unlocked.
const CARD_ART := {
	0: { "logo": "res://textures/menus/pipedream.png", "background": "res://textures/menus/pattern_pipe_brown.png" },
	1: { "logo": "res://textures/menus/tiltmaze.png", "background": "res://textures/menus/pattern_ball_moss.png" },
	2: { "logo": "res://textures/menus/splashhoops.png", "background": "res://textures/menus/pattern_drop_sage.png" },
	3: { "logo": "res://textures/menus/paldash.png", "background": "res://textures/menus/pattern_corn_caramel.png" },
	4: { "logo": "res://textures/menus/tilebreak.png", "background": "res://textures/menus/pattern_brick_terracotta.png" },
	5: { "logo": "res://textures/menus/germzap.png", "background": "res://textures/menus/pattern_germ_olive.png" },
	6: { "logo": "res://textures/menus/tummytunes.png", "background": "res://textures/menus/pattern_note_lilac.png" },
	7: { "logo": "res://textures/menus/flipperbelly.png", "background": "res://textures/menus/pattern_flipper_rose.png" },
	8: { "logo": "res://textures/menus/topspin.png", "background": "res://textures/menus/pattern_top_slate.png" },
	9: { "logo": "res://textures/menus/papersumo.png", "background": "res://textures/menus/pattern_sumo_vermilion.png" },
}

## Prototype cards not in the scene yet: copies of the last card (and its dot), added at launch
const EXTRA_PAGES := 2

## The order of the cards (2026-10-10), easy to hard: Splash Hoops, Tilt Maze, Paper Sumo, Pipe
## Dream (to become the RC car), Top Spin, Tummy Tunes, then the four on hold (Pal Dash, Tile
## Break, Germ Zap, Flipper Belly). Only the display order: each game keeps its own number
## (GameScreen.game_scenes, GameData, Collection.REWARDS).
const ORDER := [2, 1, 9, 0, 8, 6, 3, 4, 5, 7]
## The cards in this menu: ORDER, or only the six launch games in BOOT + PROGRESSION (the real
## game: the four on hold aren't there)
var order: Array = ORDER
const LOCKED_LOGO := "res://textures/menus/mistery.png"
var _locked_bg: Texture2D

# LUCKY PINCH bonus pending: the menu shows only its card (2 tries), no paging
const BONUS_ART := { "logo": "res://textures/menus/luckypinch.png", "background": "res://textures/menus/pattern_claw_gold.png" }
var bonus_page: Node = null

## Locked cards (Progression v2): the picture behind the food menu's roll-down shutter, with a small
## "?" label on it; the info panel shows the price. Hold with enough coins = bought.
const PRICE_BLINK := Color(0.85, 0.25, 0.2)
var coin_tag: PanelContainer
var coin_tag_label: Label
var legend: MenuLegend

func _ready():
	var bg0 = pages[1].get_node_or_null("Game/TopFrame/Control/Background")
	_locked_bg = bg0.texture if bg0 else null           # (a "?" card's background, from the scene)
	legend = MenuLegend.attach($Menu, $Menu/Background)
	legend.set_lines([["hold", "play"]])
	$Menu/ForwardHint.position.x = MenuLegend.forward_center_x()    # (tapping does nothing here: forward flips)
	_add_extra_pages()
	if SaveSlot.real():
		_drop_cards_on_hold()
	_build_coin_tag()
	show_page(current_page)
	LuckyPinch.changed.connect(func(_on): show_page(current_page))
	LuckyPinch.tries_changed.connect(_on_bonus_tries)
	GameData.coins_changed.connect(func(_c):
		_refresh_coin_tag()
		if visible:
			_update_game_card_labels(current_page))
	GameData.game_unlocked.connect(_on_game_unlocked)

## Each extra card is a copy of the last one; the dots row grows by one and stays centred
func _add_extra_pages() -> void:
	var step: float = dots[1].position.x - dots[0].position.x
	for i in EXTRA_PAGES:
		var page: Node = pages[-1].duplicate()
		page.name = "VBoxGame%d" % (pages.size() + 1)
		$Menu.add_child(page)
		pages.append(page)
		var dot: Control = dots[-1].duplicate()
		dot.name = "Dot%d" % (dots.size() + 1)
		dot.position.x += step
		$Menu/Dots.add_child(dot)
		dots.append(dot)
	MenuLegend.layout_dots(dots)                       # (two staggered rows when there are many)

## The real game: only the launch games' cards (and their dots)
func _drop_cards_on_hold() -> void:
	var keep := []
	for i in range(pages.size() - 1, -1, -1):
		if ORDER[i] in GameData.LAUNCH_GAMES:
			keep.push_front(ORDER[i])
			continue
		for n in [pages[i], dots[i]]:
			n.get_parent().remove_child(n)
			n.queue_free()
		pages.remove_at(i)
		dots.remove_at(i)
	order = keep
	MenuLegend.layout_dots(dots)

func show_page(index: int) -> void:
	var bonus := LuckyPinch.pending
	$Menu/Dots.visible = not bonus
	$Menu/ForwardHint.visible = not bonus
	if bonus:
		_ensure_bonus_page()
		for p in pages:
			p.visible = false
		bonus_page.visible = true
		_update_bonus_card()
		return
	if bonus_page:
		bonus_page.visible = false
	for i in range(pages.size()):
		pages[i].visible = (i == index)
	for i in range(dots.size()):
		dots[i].modulate = (Color(1, 1, 1, 1) if i == index else Color(1, 1, 1, 0.3))
	_update_game_card_labels(index)

func flip_page() -> void:
	if LuckyPinch.pending:
		return                     # the bonus card is the only one
	current_page = (current_page + 1) % pages.size()
	show_page(current_page)

func get_selected_page() -> int:
	return LuckyPinch.GAME_INDEX if LuckyPinch.pending else order[current_page]

# --- Interface expected by main_button / menu_buttons ---

func select_next() -> void:
	# Short-press does nothing on game menu — forward button handles page flipping
	pass

func get_selected_option() -> Node:
	if LuckyPinch.pending and bonus_page:
		return bonus_page.get_node_or_null("Game")
	# Return the Game child inside the current page (where Doughnut lives)
	if current_page >= 0 and current_page < pages.size():
		var page = pages[current_page]
		return page.get_node_or_null("Game")
	return null

func reset_selection() -> void:
	pass

func reset_active_options() -> void:
	show_page(current_page)

func _update_game_card_labels(page_index: int) -> void:
	var page = pages[page_index]
	var index: int = order[page_index]                   # the game on this card
	var game_node = page.get_node_or_null("Game")
	if not game_node:
		return
	var unlocked := GameData.is_unlocked(index)
	if legend:
		legend.set_lines([["hold", "play"]] if unlocked else ([["hold", "buy"]] if GameData.can_buy_game(index) else []))
	_lock_overlay(page).visible = not unlocked
	var logo = game_node.get_node_or_null("TopFrame/Control/GameLogo")
	var bg = game_node.get_node_or_null("TopFrame/Control/Background")
	if index in CARD_ART and unlocked:
		var art: Dictionary = CARD_ART[index]
		if logo:
			logo.texture = load(art["logo"])
		if bg:
			bg.texture = load(art["background"])
	else:                                                # locked: a "?" card
		if logo:
			logo.texture = load(LOCKED_LOGO)
		if bg and _locked_bg:
			bg.texture = _locked_bg
	var bottom = game_node.get_node_or_null("BottomFrame")
	if not bottom:
		return
	var head1: Label = bottom.get_node_or_null("MaxScore")
	var head2: Label = bottom.get_node_or_null("Progress")
	var score_label: Label = bottom.get_node_or_null("MaxScore/Score")
	var progress_label: Label = bottom.get_node_or_null("Progress/Progress")
	if not (head1 and head2 and score_label and progress_label):
		return
	_pin_right(score_label, "000000")
	_pin_percent_sign(progress_label)
	_value_coin(score_label, false)
	_value_coin(progress_label, false)
	if not unlocked:
		if GameData.can_buy_game(index):
			# the price, and what you have
			head1.text = "Price"
			score_label.text = str(GameData.game_price(index))
			head2.text = "You have"
			progress_label.text = str(GameData.coins)
			_value_coin(score_label, true)
			_value_coin(progress_label, true)
		else:
			head1.text = "Coming soon"
			score_label.text = ""
			head2.text = ""
			progress_label.text = ""
		return
	if index in GameData.LEVEL_COUNTS:
		# a game with levels: its stars and levels instead of a best score
		var n: int = GameData.LEVEL_COUNTS[index]
		head1.text = "Stars"
		score_label.text = "%d/%d" % [GameData.game_stars(index), n * 3]
		head2.text = "Levels"
		progress_label.text = "%d/%d" % [GameData.levels_cleared(index), n]
		return
	head1.text = "Max Score"
	head2.text = "Progress"
	score_label.text = "%06d" % GameData.get_max_score(index)
	progress_label.text = "%d%%" % int(GameData.get_progress(index))

# --- Buying a game (hold on its locked card; main_button asks can_confirm, then buy_selected) ---

## Asked by the main button before the OK sound: a locked card can only be bought with enough coins
func can_confirm(_sel: Node) -> bool:
	var index := get_selected_page()
	if GameData.is_unlocked(index) or index == LuckyPinch.GAME_INDEX:
		return true
	if GameData.can_buy_game(index) and GameData.coins >= GameData.game_price(index):
		return true
	_blink_price()
	return false

## A locked card the main button may fill its ring on (buyable, even without the coins yet)
func can_try_buy() -> bool:
	return GameData.can_buy_game(get_selected_page())

func buy_selected() -> void:
	GameData.buy_game(get_selected_page())        # (GameData.game_unlocked -> _on_game_unlocked)

## Not enough coins: the price blinks red, with a soft buzz
func _blink_price() -> void:
	Input.vibrate_handheld(40)
	var l: Label = pages[current_page].get_node_or_null("Game/BottomFrame/MaxScore/Score")
	if not l:
		return
	if not l.has_meta("color"):
		l.set_meta("color", l.get_theme_color("font_color"))     # (the card's own brown, from the scene)
	var normal: Color = l.get_meta("color")
	var t := l.create_tween()
	for i in 3:
		t.tween_callback(func(): l.add_theme_color_override("font_color", PRICE_BLINK))
		t.tween_interval(0.12)
		t.tween_callback(func(): l.add_theme_color_override("font_color", normal))
		t.tween_interval(0.12)

## Bought: the shutter rolls up and the game's picture shows (the LCD says GAME UNLOCKED!)
func _on_game_unlocked(index: int) -> void:
	var i := order.find(index)
	if i < 0:
		return
	var ov := _lock_overlay(pages[i])
	if not visible or i != current_page or not ov.visible:
		_update_game_card_labels(current_page)
		return
	# the real picture goes in behind the shutter first
	var art: Dictionary = CARD_ART.get(index, {})
	var game_node = pages[i].get_node("Game")
	if not art.is_empty():
		game_node.get_node("TopFrame/Control/GameLogo").texture = load(art["logo"])
		game_node.get_node("TopFrame/Control/Background").texture = load(art["background"])
	var h: float = ov.size.y
	var t := ov.create_tween()
	t.tween_interval(0.15)
	t.tween_property(ov.get_node("Mini"), "modulate:a", 0.0, 0.15)
	t.tween_property(ov.get_node("Shutter"), "position:y", -h, 0.55).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	t.tween_callback(func():
		ov.visible = false
		ov.get_node("Shutter").position.y = 0.0
		ov.get_node("Mini").modulate.a = 1.0
		_update_game_card_labels(current_page))

## The shutter and its small "?" label over a card's picture (made once per card)
func _lock_overlay(page: Node) -> Control:
	var top: TextureRect = page.get_node("Game/TopFrame")
	var ov: Control = top.get_node_or_null("LockOverlay")
	if ov:
		return ov
	var inner_src: Control = top.get_node("Control")             # the picture area (pattern + logo)
	ov = Control.new()
	ov.name = "LockOverlay"
	ov.position = inner_src.position
	ov.size = inner_src.size
	ov.clip_contents = true
	ov.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var shutter := TextureRect.new()
	shutter.name = "Shutter"
	shutter.texture = UiArt.shutter(int(ov.size.x / 1.4), int(ov.size.y / 1.4))   # (~3 screen px a pixel, like the food menu's)
	shutter.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	shutter.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	shutter.size = ov.size
	shutter.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ov.add_child(shutter)
	# the reduced label: this card's frame at half size, with the "?" logo on the "?" pattern
	var mini := TextureRect.new()
	mini.name = "Mini"
	mini.texture = top.texture
	mini.size = top.size
	mini.scale = Vector2(0.5, 0.5)
	mini.position = (ov.size - top.size * 0.5) / 2.0 - Vector2(0, 6)
	mini.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var inner: Control = inner_src.duplicate()
	inner.get_node("GameLogo").texture = load(LOCKED_LOGO)
	if _locked_bg:
		inner.get_node("Background").texture = _locked_bg
	mini.add_child(inner)
	ov.add_child(mini)
	top.add_child(ov)
	return ov

## A coin before a value in the info panel (price, coins you have)
func _value_coin(label: Label, on: bool) -> void:
	var icon: TextureRect = label.get_node_or_null("Coin")
	if not icon:
		if not on:
			return
		icon = TextureRect.new()
		icon.name = "Coin"
		icon.texture = UiArt.coin()
		icon.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon.size = Vector2(16, 16)
		icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
		label.add_child(icon)
	icon.visible = on
	if on:
		var font: Font = label.get_theme_font("font")
		var fs := label.get_theme_font_size("font_size")
		var w := font.get_string_size(label.text, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x
		# (the label's text sits at its top: centre the coin on the line of text)
		icon.position = Vector2(label.size.x - w - icon.size.x - 4, (font.get_height(fs) - icon.size.y) / 2.0)

## The coin balance, on the top-right corner of the card (like the gear menu's NEW tags)
func _build_coin_tag() -> void:
	coin_tag = PanelContainer.new()
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color8(250, 244, 214)
	sb.border_color = Color8(58, 38, 30)
	sb.set_border_width_all(4)
	sb.set_corner_radius_all(8)
	sb.content_margin_left = 12
	sb.content_margin_right = 16
	sb.content_margin_top = 2
	sb.content_margin_bottom = 2
	sb.anti_aliasing = false
	coin_tag.add_theme_stylebox_override("panel", sb)
	coin_tag.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	coin_tag.add_child(row)
	var icon := TextureRect.new()
	icon.texture = UiArt.coin()
	icon.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.custom_minimum_size = Vector2(36, 36)
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(icon)
	coin_tag_label = Label.new()
	coin_tag_label.add_theme_font_override("font", load("res://fonts/Pixellari.ttf"))
	coin_tag_label.add_theme_font_size_override("font_size", 36)
	coin_tag_label.add_theme_color_override("font_color", Color8(74, 48, 34))
	coin_tag_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	coin_tag_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(coin_tag_label)
	coin_tag.position = Vector2(1180, -1206)
	coin_tag.z_index = 6
	$Menu.add_child(coin_tag)
	_refresh_coin_tag()

func _refresh_coin_tag() -> void:
	if coin_tag_label:
		coin_tag_label.text = str(GameData.coins)
		coin_tag.reset_size()

## The % sign stays exactly where it is for "0%"; longer numbers grow to its left
func _pin_percent_sign(label: Label) -> void:
	_pin_right(label, "0%")

## Right-aligns a label so its text always ends where `sample` (as laid out in the scene,
## left-aligned) ends; longer or shorter text grows to the left
func _pin_right(label: Label, sample: String) -> void:
	if label.has_meta("pinned_right"):
		return
	var font: Font = label.get_theme_font("font")
	var fs: int = label.get_theme_font_size("font_size")
	var right: float = label.position.x + font.get_string_size(sample, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x
	label.set_meta("pinned_right", true)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	label.size.x = 200.0
	label.position.x = right - label.size.x

func _on_bonus_tries(_t: int) -> void:
	if bonus_page:
		_update_bonus_card()

## The bonus card: a copy of a game card with the LUCKY PINCH art, tries and prizes
func _ensure_bonus_page() -> void:
	if bonus_page:
		return
	bonus_page = pages[pages.size() - 1].duplicate()
	bonus_page.name = "VBoxBonus"
	$Menu.add_child(bonus_page)
	var game_node = bonus_page.get_node_or_null("Game")
	if not game_node:
		return
	# (a copy of a card: no shutter, no coins on it)
	var ov = game_node.get_node_or_null("TopFrame/LockOverlay")
	if ov:
		ov.queue_free()
	for path in ["BottomFrame/MaxScore/Score/Coin", "BottomFrame/Progress/Progress/Coin"]:
		var c = game_node.get_node_or_null(path)
		if c:
			c.queue_free()
	var logo = game_node.get_node_or_null("TopFrame/Control/GameLogo")
	var bg = game_node.get_node_or_null("TopFrame/Control/Background")
	if logo:
		logo.texture = load(BONUS_ART["logo"])
		# the title flashes like arcade marquee lights: bright, normal, bright, a little pause
		var t: Tween = logo.create_tween().set_loops()
		for i in 2:
			t.tween_callback(func(): logo.modulate = Color(1.45, 1.35, 1.1))
			t.tween_interval(0.16)
			t.tween_callback(func(): logo.modulate = Color.WHITE)
			t.tween_interval(0.16)
		t.tween_interval(0.5)
		t.parallel().tween_property(logo, "scale", logo.scale * 1.06, 0.25).set_trans(Tween.TRANS_SINE)
		t.tween_property(logo, "scale", logo.scale, 0.25).set_trans(Tween.TRANS_SINE)
	if bg:
		bg.texture = load(BONUS_ART["background"])

func _update_bonus_card() -> void:
	var bottom = bonus_page.get_node_or_null("Game/BottomFrame")
	if not bottom:
		return
	var a = bottom.get_node_or_null("MaxScore")
	var b = bottom.get_node_or_null("MaxScore/Score")
	var c = bottom.get_node_or_null("Progress")
	var d = bottom.get_node_or_null("Progress/Progress")
	# values end where the other cards' digits end ("000000" and "0%"), however short they are
	if a: a.text = "Tries"
	if b:
		_pin_right(b, "000000")
		b.text = str(LuckyPinch.tries)
	# how many prize capsules are still in the machine (it refills when they run out)
	if c: c.text = "Capsules"
	if d:
		_pin_right(d, "0%")
		d.text = str(LuckyPinch.pit.size())
