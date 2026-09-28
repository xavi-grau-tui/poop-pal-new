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

func _ready():
	show_page(current_page)

func show_page(index: int) -> void:
	for i in range(pages.size()):
		pages[i].visible = (i == index)
	for i in range(dots.size()):
		dots[i].modulate = (Color(1, 1, 1, 1) if i == index else Color(1, 1, 1, 0.3))
	_update_game_card_labels(index)

func flip_page() -> void:
	current_page = (current_page + 1) % pages.size()
	show_page(current_page)

func get_selected_page() -> int:
	return current_page

# --- Interface expected by main_button / menu_buttons ---

func select_next() -> void:
	# Short-press does nothing on game menu — forward button handles page flipping
	pass

func get_selected_option() -> Node:
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
		progress_label.text = "%d%%" % int(GameData.get_progress(index))
