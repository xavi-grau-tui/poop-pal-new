extends Node
class_name MenuTouch
## The screen is touchable while a menu is open (the user, 2026-11-01: simpler for players, the
## buttons stay as they are). On the open menu's frame:
##   touch a card     it's selected (as the orange button's taps would get there)
##   hold on it       the orange button's hold: the ring fills, the choice is made
##   swipe left/right the next / previous page (the forward button)
##   drag up/down     scroll the list (one card or page each SCROLL_STEP)
##   tap              (a pal card: back to the grid, as a tap of the orange button)
## A menu takes part through select_at(pos) -> bool, and optionally flip_back(), scroll(dir) and
## tap_at(pos) (pos: viewport coords, as the event's). Created by the main button.

const SLOP := 24.0             # movement (Main UI px) before a touch is a drag, not a press
const SWIPE := 90.0            # horizontal drag that flips a page
const SCROLL_STEP := 170.0     # vertical drag per scrolled card / page

var main_ui: Node2D
var main_button: Node
var _down := false
var _start := Vector2.ZERO     # Main UI coords
var _axis := ""                # "" (still a press), "x" or "y"
var _scrolled := 0             # scroll steps already done in this drag
var _menu: Node

static func attach(ui: Node2D) -> void:
	var t := MenuTouch.new()
	t.name = "MenuTouch"
	t.main_ui = ui
	t.main_button = ui.get_node_or_null("MainButton")
	ui.add_child(t)

func _input(event: InputEvent) -> void:
	if not (event is InputEventMouseButton or event is InputEventMouseMotion):
		return
	if event is InputEventMouseButton:
		if event.button_index != MOUSE_BUTTON_LEFT:
			return
		if event.pressed:
			_press(event.position)
		elif _down:
			_lift(event.position)
	elif _down and (event.button_mask & MOUSE_BUTTON_MASK_LEFT):
		_move(event.position)

func _press(pos: Vector2) -> void:
	_menu = _open_menu()
	if _menu == null or not _on_frame(_menu, pos):
		return
	_down = true
	_axis = ""
	_scrolled = 0
	_start = _local(pos)
	if _menu.has_method("select_at") and _menu.select_at(pos) and main_button:
		main_button.screen_hold()

func _move(pos: Vector2) -> void:
	var d := _local(pos) - _start
	if _axis == "":
		if d.length() < SLOP:
			return
		_axis = "x" if absf(d.x) > absf(d.y) else "y"
		if main_button:
			main_button.screen_release()      # a drag: no choice made
	if _axis == "y" and _menu.has_method("scroll"):
		var steps := int(-d.y / SCROLL_STEP)  # (finger up = further down the list)
		while _scrolled != steps:
			var dir := signi(steps - _scrolled)
			_menu.scroll(dir)
			_scrolled += dir
			Input.vibrate_handheld(10)

func _lift(pos: Vector2) -> void:
	_down = false
	if main_button:
		main_button.screen_release()          # (a hold let go early does nothing)
	var d := _local(pos) - _start
	if _axis == "" and _menu.has_method("tap_at"):
		_menu.tap_at(pos)
	elif _axis == "x" and absf(d.x) >= SWIPE:
		if d.x < 0.0 or not _menu.has_method("flip_back"):
			_menu.flip_page()
		else:
			_menu.flip_back()
		_click()

## The menu showing, if the screen can take touches now
func _open_menu() -> Node:
	if GameScreen.is_active or Unboxing.waiting():
		return null
	if FoodRainSpawner.is_locked or DrinkWaterfallSpawner.is_locked or LuckyPinch.visiting:
		return null
	var flip := main_ui.get_node_or_null("../DeviceFlip")
	if flip and (flip.turning or flip.progress > 0.0):
		return null
	for b in get_tree().get_nodes_in_group("menu_toggle_buttons"):
		if b.button_pressed and b.target_menu:
			if b.menu_manager and b.menu_manager.get("returning"):
				return null
			return b.target_menu
	return null

## Inside the menu's frame (its first picture: the frame behind the cards)
func _on_frame(menu: Node, pos: Vector2) -> bool:
	for c in menu.get_node("Menu").get_children():
		if c is Sprite2D:
			return touches(c, pos)
	return false

func _local(pos: Vector2) -> Vector2:
	return main_ui.get_global_transform_with_canvas().affine_inverse() * pos

## A sprite's picture or a control's box under the finger (pos: viewport coords)
static func touches(node: CanvasItem, pos: Vector2) -> bool:
	if not node.is_visible_in_tree():
		return false
	var rect: Rect2 = node.get_rect() if node is Sprite2D else Rect2(Vector2.ZERO, (node as Control).size)
	return rect.has_point(node.get_global_transform_with_canvas().affine_inverse() * pos)

func _click() -> void:
	var fwd := main_ui.get_node_or_null("SoundButtons/ForwardButton")
	if fwd and fwd.release_sound:
		fwd.release_sound.stop()
		fwd.release_sound.play()
	Input.vibrate_handheld(25)
