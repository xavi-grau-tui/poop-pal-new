extends Node2D
class_name Unboxing
## First launch, straight out of the box: the device has no power, its two screens wear
## protective films (the big one prints the instructions) and a plastic strip pokes out
## of the battery lid on the back. Peel the films from their corner tabs, double-tap the
## logo to turn it over, pull the strip: the device powers on, turns itself back round
## and the normal boot sequence (BootSequence waits on waiting()) starts.
##
## Created at runtime by MenuManager as a sibling of "Main UI", after DeviceFlip, so it
## sees input first. Art: tools/design/unboxing_art.py -> textures/unboxing/.

## TESTING: show the unboxing on every launch. Turn off before release (then it shows
## only once, remembered in SAVE_PATH).
const SHOW_EVERY_LAUNCH := true
const SAVE_PATH := "user://device.json"

# Screen-space rects on the front at rest (match tools/design/unboxing_art.py)
const SCREEN := Rect2(76, 623, 926, 926)
const SCREEN_FILM := Rect2(63, 607, 953, 958)
const LCD_FILM := Rect2(92, 77, 445, 201)
# The battery strip on the back, in back-art pixels: it comes out of the lid's top edge
# (pulled upwards, where there's room for a finger), a little right of the lid's screw
const LID_TOP := 1316.0
const STRIP_X := 620.0
const STRIP_OUT := 170.0            # how much of it pokes out above the lid
const STRIP_PULL := 300.0           # pulled this far it comes free

const BUZZ_MS := 30

static var _state := -1             # -1 not decided yet, 1 waiting for power, 0 powered

## True until the battery strip is pulled (BootSequence waits on this).
static func waiting() -> bool:
	if _state == -1:
		_state = 1 if SHOW_EVERY_LAUNCH or not _saved_unboxed() else 0
	return _state == 1

static func _saved_unboxed() -> bool:
	var f := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if not f:
		return false
	var data = JSON.parse_string(f.get_as_text())
	return data is Dictionary and data.get("unboxed", false)

static func _save_unboxed() -> void:
	var f := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if f:
		f.store_string(JSON.stringify({"unboxed": true}))

var front: Node2D
var flip: Node                       # DeviceFlip
var screen_off: Sprite2D
var films: Array[Film] = []
var strip: Strip
var dragging: Node = null            # the film or strip under the finger
var held_button: TextureButton = null   # pushed while unpowered: it goes down, does nothing
var held_texture: Texture2D

func _ready() -> void:
	if not waiting():
		queue_free()
		return
	front = get_parent().get_node("Main UI")
	flip = get_parent().get_node("DeviceFlip")
	# front pieces are children of Main UI (so they turn with the device), placed so their
	# local pixels line up with the screen at rest
	var to_front := front.get_global_transform_with_canvas().affine_inverse()

	screen_off = Sprite2D.new()
	screen_off.texture = preload("res://textures/unboxing/screen_off.png")
	screen_off.centered = false
	screen_off.transform = to_front * Transform2D(0.0, SCREEN.position)
	screen_off.z_index = 2           # over the boot's black screen, under the console frame
	front.add_child(screen_off)

	for spec in [[SCREEN_FILM, preload("res://textures/unboxing/film_screen.png"), 0.8, 70.0],
			[LCD_FILM, preload("res://textures/unboxing/film_lcd.png"), 0.55, 46.0]]:
		var film := Film.new()
		film.tex = spec[1]
		film.size = spec[0].size
		film.tab_scale = spec[2]
		film.d_rest = spec[3]
		film.d = spec[3]
		film.transform = to_front * Transform2D(0.0, spec[0].position)
		film.z_index = 60            # above the console and every menu
		film.peeled.connect(func(): films.erase(film); _maybe_done())
		front.add_child(film)
		films.append(film)

	strip = Strip.new()
	strip.position = Vector2(STRIP_X, LID_TOP - 1920.0 - STRIP_OUT)   # back-local, its free end
	var back: Node2D = flip.back
	back.add_child(strip)
	back.move_child(strip, back.get_node("BatteryLid").get_index())    # under the lid
	strip.pulled.connect(_power_on)

func _input(event: InputEvent) -> void:
	var tap := event as InputEventMouseButton
	var motion := event as InputEventMouseMotion
	if not tap and not motion:
		return
	if tap and tap.button_index != MOUSE_BUTTON_LEFT:
		return
	if flip.turning:
		return
	var pos: Vector2 = event.position
	if held_button:
		get_viewport().set_input_as_handled()
		if tap and not tap.pressed:
			_unpush()
		return
	if dragging:
		get_viewport().set_input_as_handled()
		if motion:
			dragging.drag_to(_local_to(dragging, pos))
		elif not tap.pressed:
			dragging.release()
			dragging = null
		return
	if not tap or not tap.pressed:
		if waiting() and flip.progress == 0.0 and not flip._on_logo(pos):
			get_viewport().set_input_as_handled()
		return
	if flip.progress == 1.0:
		if strip and is_instance_valid(strip) and strip.grabs(_local_to(strip, pos)):
			dragging = strip
	elif flip.progress == 0.0:
		for film in films:
			if film.grabs(_local_to(film, pos)):
				dragging = film
				break
	if dragging:
		get_viewport().set_input_as_handled()
		dragging.press(_local_to(dragging, pos))
	elif waiting() and flip.progress == 0.0 and not flip._on_logo(pos):
		get_viewport().set_input_as_handled()   # no power: nothing reaches the buttons...
		var b := _button_at(pos)
		if b:
			_push(b)                     # ...but they still click down like real ones

## The console's buttons (menu, sound, forward, main)
func _buttons() -> Array:
	var out := []
	for path in ["MenuButtons", "SoundButtons", "MainButton"]:
		var n := front.get_node_or_null(path)
		if n is TextureButton:
			out.append(n)
		elif n:
			out.append_array(n.get_children().filter(func(c): return c is TextureButton))
	return out

func _button_at(screen_pos: Vector2) -> TextureButton:
	for b in _buttons():
		if b.is_visible_in_tree() and Rect2(Vector2.ZERO, b.size).has_point(_local_to(b, screen_pos)):
			return b
	return null

## Pushed with no power: clicks (and shows its pressed face), but never gets the tap.
## The top menu buttons' pressed face is their LED lit, so with no power they only click.
func _push(b: TextureButton) -> void:
	held_button = b
	held_texture = b.texture_normal
	if b.texture_pressed and not b.is_in_group("menu_toggle_buttons"):
		b.texture_normal = b.texture_pressed
	var click := b.get_node_or_null("ClickSound") as AudioStreamPlayer2D
	if click:
		click.play()

func _unpush() -> void:
	held_button.texture_normal = held_texture
	var rel := held_button.get_node_or_null("ReleaseSound") as AudioStreamPlayer2D
	if rel:
		rel.play()
	held_button = null

func _local_to(node: CanvasItem, screen_pos: Vector2) -> Vector2:
	return node.get_global_transform_with_canvas().affine_inverse() * screen_pos

func _power_on() -> void:
	strip = null
	Input.vibrate_handheld(BUZZ_MS)
	_save_unboxed()
	await get_tree().create_timer(0.6).timeout
	if flip.progress > 0.0:
		flip._turn(0.0)
		while flip.turning:
			await get_tree().process_frame
	await get_tree().create_timer(0.25).timeout
	# (the fade belongs to the screen: this node may be gone before it ends)
	var t := screen_off.create_tween()
	t.tween_property(screen_off, "modulate:a", 0.0, 0.2)
	t.tween_callback(screen_off.queue_free)
	_state = 0                       # BootSequence starts now
	_maybe_done()

func _maybe_done() -> void:
	if _state == 0 and films.is_empty():
		queue_free()


## A protector film that peels from its bottom-right corner: a fold line moves in from
## the corner as you pull the tab, the folded part shows the film's (mirrored) back.
class Film extends Node2D:
	signal peeled

	const TAB := preload("res://textures/unboxing/pull_tab.png")
	const PEEL_SOUND := preload("res://sounds/fx/film_peel.wav")
	const PEEL_LOUD_AT := 900.0      # fold speed (px/s) at which the crackle is at full volume
	const PEEL_DB := -19.0           # ...and that full volume (kept subtle)
	const LET_GO := 0.28             # pulled past this share of the diagonal it comes off...
	const LET_GO_MAX := 190.0        # ...or past this fold depth, so the big film needs no huge drag

	var tex: Texture2D
	var size: Vector2
	var tab_scale := 0.8
	var d_rest := 70.0               # the corner sits a little lifted, its PULL tab showing
	var d := 70.0                    # fold line's distance in from the corner
	var grab_offset := Vector2.ZERO
	var tw: Tween
	var gone := false
	var v := Vector2.ONE.normalized()   # diagonal, towards the corner
	var crackle: AudioStreamPlayer
	var last_d := 0.0
	var speed := 0.0                 # how fast the fold is moving in (smoothed), px/s

	func _ready() -> void:
		# the adhesive crackle: one looping player, silent until the film is peeling
		var stream: AudioStreamWAV = PEEL_SOUND.duplicate()
		stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
		stream.loop_begin = 0
		stream.loop_end = int(stream.get_length() * stream.mix_rate)
		crackle = AudioStreamPlayer.new()
		crackle.stream = stream
		crackle.volume_db = -80.0
		add_child(crackle)
		last_d = d

	## Peeling speed drives the crackle: sustained while you pull slowly, louder and
	## higher when fast, silent when the finger stops or the film springs back.
	func _process(delta: float) -> void:
		if gone:
			return                   # flying off: the crackle just fades (see release)
		var inst := maxf(d - last_d, 0.0) / maxf(delta, 0.001)
		last_d = d
		speed = lerpf(speed, inst, 0.35 if inst > speed else 0.06)
		var amount := clampf(speed / PEEL_LOUD_AT, 0.0, 1.0) * modulate.a
		# (the smoothed speed decays gradually, so slowing down trails off rather than cutting)
		if amount > 0.003:
			if not crackle.playing:
				crackle.play(randf() * 0.8)
			crackle.volume_db = PEEL_DB + linear_to_db(sqrt(amount))
			crackle.pitch_scale = 1.35 + 0.35 * amount
		elif crackle.playing:
			crackle.stop()

	func corner() -> Vector2:
		return size

	func tip() -> Vector2:            # where the folded-back corner is now
		return corner() - 2.0 * d * v

	func d_max() -> float:
		return (size.x + size.y) / sqrt(2.0)

	func grabs(p: Vector2) -> bool:
		return not gone and (p.distance_to(tip()) < 140.0 * tab_scale or _side(p) > 0.0 and Rect2(Vector2.ZERO, size).has_point(p))

	func press(p: Vector2) -> void:
		if tw:
			tw.kill()
		grab_offset = p - tip()

	func drag_to(p: Vector2) -> void:
		var t := p - grab_offset
		d = clampf((corner() - t).dot(v) / 2.0, d_rest, d_max())
		queue_redraw()

	func release() -> void:
		if d > minf(d_max() * LET_GO, LET_GO_MAX):
			gone = true
			Input.vibrate_handheld(12)
			# the fly-off is fast; don't let that speed spike the crackle, just let it die away.
			# It moves to the parent first: this film is freed before the fade would end.
			if crackle.playing:
				crackle.reparent(get_parent())
				var fade := crackle.create_tween()
				fade.tween_property(crackle, "volume_db", -60.0, 0.5).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
				fade.tween_callback(crackle.queue_free)
			tw = create_tween().set_parallel(true)
			tw.tween_method(_set_d, d, d_max() * 1.15, 0.35).set_ease(Tween.EASE_OUT)
			tw.tween_property(self, "position", position - v * 260.0, 0.35).set_ease(Tween.EASE_IN)
			tw.tween_property(self, "modulate:a", 0.0, 0.35).set_delay(0.1)
			tw.chain().tween_callback(func(): peeled.emit(); queue_free())
		else:
			tw = create_tween()
			tw.tween_method(_set_d, d, d_rest, 0.2).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

	func _set_d(x: float) -> void:
		d = x
		queue_redraw()

	func _side(p: Vector2) -> float:  # > 0 on the folded (corner) side of the fold line
		return (p - corner()).dot(v) + d

	func _reflect(p: Vector2) -> Vector2:
		return p - 2.0 * _side(p) * v

	func _clip(poly: PackedVector2Array, keep_folded: bool) -> PackedVector2Array:
		var out := PackedVector2Array()
		for i in poly.size():
			var a := poly[i]
			var b := poly[(i + 1) % poly.size()]
			var fa := _side(a) * (-1.0 if keep_folded else 1.0)
			var fb := _side(b) * (-1.0 if keep_folded else 1.0)
			if fa <= 0.0:
				out.append(a)
			if fa * fb < 0.0:
				out.append(a.lerp(b, fa / (fa - fb)))
		return out

	func _uvs(pts: PackedVector2Array) -> PackedVector2Array:
		var uv := PackedVector2Array()
		for p in pts:
			uv.append(p / size)
		return uv

	func _draw() -> void:
		var rect := PackedVector2Array([Vector2.ZERO, Vector2(size.x, 0), size, Vector2(0, size.y)])
		var flat := _clip(rect, false)
		if flat.size() >= 3:
			draw_polygon(flat, PackedColorArray([Color.WHITE]), _uvs(flat), tex)
		var src := _clip(rect, true)
		if src.size() < 3:
			return
		var flap := PackedVector2Array()
		for p in src:
			flap.append(_reflect(p))
		var shadow := PackedVector2Array()
		for p in flap:
			shadow.append(p + Vector2(8, 10))
		draw_colored_polygon(shadow, Color(0.16, 0.11, 0.07, 0.22))
		# the film's back: whitish plastic, the print showing through mirrored
		draw_colored_polygon(flap, Color(0.93, 0.95, 0.98, 0.9))
		draw_polygon(flap, PackedColorArray([Color(1, 1, 1, 0.45)]), _uvs(src), tex)
		var edge := PackedVector2Array(flap)
		edge.append(flap[0])
		draw_polyline(edge, Color(0.55, 0.62, 0.7, 0.9), 2.0)
		# the red tab rides on the folded corner, pointing back towards the fold
		var t := tip()
		draw_set_transform(t, v.angle(), Vector2(tab_scale, tab_scale))
		draw_texture(TAB, Vector2(-6, -TAB.get_height() / 2.0))
		draw_set_transform(Vector2.ZERO)


## The plastic strip between the cells: drag it up out of the battery bay.
class Strip extends Node2D:
	signal pulled

	const TEX := preload("res://textures/unboxing/battery_strip.png")
	var pull := 0.0                  # how far it has been drawn out (upwards)
	var press_y := 0.0
	var tw: Tween
	var gone := false

	func _draw() -> void:
		# local origin = the strip's free end at rest; the rest runs down under the lid
		draw_texture(TEX, Vector2(-TEX.get_width() / 2.0, -pull))

	func grabs(p: Vector2) -> bool:
		var w := TEX.get_width()
		return not gone and Rect2(-w / 2.0 - 30, -pull - 40, w + 60, Unboxing.STRIP_OUT + 60).has_point(p)

	func press(p: Vector2) -> void:
		if tw:
			tw.kill()
		press_y = p.y + pull

	func drag_to(p: Vector2) -> void:
		pull = clampf(press_y - p.y, 0.0, Unboxing.STRIP_PULL + 60.0)
		queue_redraw()

	func release() -> void:
		if pull >= Unboxing.STRIP_PULL:
			gone = true
			tw = create_tween().set_parallel(true)
			tw.tween_method(_set_pull, pull, pull + 420.0, 0.35).set_ease(Tween.EASE_IN)
			tw.tween_property(self, "rotation", -0.25, 0.35)
			tw.tween_property(self, "modulate:a", 0.0, 0.3).set_delay(0.1)
			tw.chain().tween_callback(func(): pulled.emit(); queue_free())
		else:
			tw = create_tween()
			tw.tween_method(_set_pull, pull, 0.0, 0.25).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

	func _set_pull(x: float) -> void:
		pull = x
		queue_redraw()
