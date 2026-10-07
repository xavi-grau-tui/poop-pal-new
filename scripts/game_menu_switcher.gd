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

# LUCKY PINCH bonus pending: the menu shows only its card (2 tries), no paging
const BONUS_ART := { "logo": "res://textures/menus/luckypinch.png", "background": "res://textures/menus/pattern_claw_gold.png" }
var bonus_page: Node = null

func _ready():
	_add_extra_pages()
	show_page(current_page)
	LuckyPinch.changed.connect(func(_on): show_page(current_page))
	LuckyPinch.tries_changed.connect(_on_bonus_tries)

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
		for d in dots:
			d.position.x -= step / 2.0

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
	return LuckyPinch.GAME_INDEX if LuckyPinch.pending else current_page

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

func _update_game_card_labels(index: int) -> void:
	var page = pages[index]
	var game_node = page.get_node_or_null("Game")
	if not game_node:
		return
	if index in CARD_ART and GameData.is_unlocked(index):
		var art: Dictionary = CARD_ART[index]
		var logo = game_node.get_node_or_null("TopFrame/Control/GameLogo")
		var bg = game_node.get_node_or_null("TopFrame/Control/Background")
		if logo:
			logo.texture = load(art["logo"])
		if bg:
			bg.texture = load(art["background"])
	var bottom = game_node.get_node_or_null("BottomFrame")
	if not bottom:
		return
	# Update max score
	var score_label = bottom.get_node_or_null("MaxScore/Score")
	if score_label:
		score_label.text = "%06d" % GameData.get_max_score(index)
	# Update progress
	var progress_label = bottom.get_node_or_null("Progress/Progress")
	if progress_label:
		_pin_percent_sign(progress_label)
		progress_label.text = "%d%%" % int(GameData.get_progress(index))

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
