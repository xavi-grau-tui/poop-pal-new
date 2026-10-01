extends BaseMinigame
## Tummy Tunes — a rhythm game. Notes fall down three lanes in time with the song; press the
## lane's button as a note reaches the line at the bottom.
##
##   left lane   = the speaker (mute) button   (in this game it doesn't mute: it plays)
##   middle lane = the main (orange) button
##   right lane  = the forward button
## Groove meter: hits fill it, misses and stray presses drain it; empty = the song stops (fail).
## Phones: every finger is read directly, so two buttons can be pressed together (chords).
## Desktop: Left/A, Down/S/Space, Right/D.
##
## Charts come from tools/design/rhythm_chart.py (made from the song's audio, no MIDI).
## Sync: notes follow the song's real playback position (corrected for output latency).

const SONG := "res://sounds/music/Retro Game Console.mp3"
const CHART := "res://data/charts/retro_game_console.json"
const DIFFICULTY := "normal"
const LEAD_IN := 2.0                  # silence before the song starts (count-in)
const FALL_TIME := 1.5                # seconds a note takes from the top to the line

# Hit windows (seconds from the note's time)
const PERFECT := 0.06
const GOOD := 0.13
const MISS_AFTER := 0.16
const POINTS := { "perfect": 10, "good": 5 }
const SLOPPY := 0.25                  # a press this close to a note (but outside GOOD) misses it

# Groove meter (0..1). Starts at 80%; empty = fail.
const GROOVE_START := 0.8
const GROOVE_GAIN := { "perfect": 0.03, "good": 0.015, "miss": -0.08 }
const GROOVE_STRAY := -0.04           # pressing when there's no note at all

const LANE_X := [215.0, 475.0, 735.0]
const LANE_W := 190.0
const LINE_Y := 820.0
const TOP_Y := 120.0
const LANE_COLORS := [Color8(246, 150, 180), Color8(250, 206, 110), Color8(150, 220, 190)]
const OUTLINE := Color8(74, 44, 32)
const PAL_POS := Vector2(130, 82)

var notes: Array = []                 # [time, lane]
var next_spawn := 0
var live: Array[Dictionary] = []      # { t, lane, node }
var song: AudioStreamPlayer
var song_started := false
var clock := -LEAD_IN                 # song time (negative during the count-in)
var finished := false
var combo := 0
var best_combo := 0
var counts := { "perfect": 0, "good": 0, "miss": 0 }
var groove := GROOVE_START
var groove_fill: ColorRect
var groove_box: ColorRect

var lcd_font: Font
var note_tex: Array[Texture2D] = []
var targets: Array[Sprite2D] = []
var bpm := 120.0
var beat_offset := 0.0
var lane_flash: Array[ColorRect] = []
var score_label: Label
var combo_label: Label
var judge_label: Label
var banner: Label
var pal: AnimatedSprite2D
var headphones: Sprite2D
var _keys := {}
var _touch_mode := false              # phone: ignore the emulated single-mouse button presses
var _touch_lane := {}                 # touch index -> lane

func _ready() -> void:
	lcd_font = load("res://fonts/pixChicago.ttf")
	for c in ["pink", "yellow", "mint"]:
		note_tex.append(load("res://textures/minigames/splash/ball_%s.png" % c))
	var f := FileAccess.open(CHART, FileAccess.READ)
	if f:
		var data = JSON.parse_string(f.get_as_text())
		if data is Dictionary:
			notes = data["charts"][DIFFICULTY]
			bpm = data["bpm"]
			beat_offset = data["offset"]
	# the pet screen's music stops; this game plays its own song in sync
	var mc = get_node_or_null("/root/PoopPal/MusicController")
	if mc:
		mc.stop()
	song = AudioStreamPlayer.new()
	song.stream = load(SONG)
	song.finished.connect(_on_song_finished)
	add_child(song)
	_create_static_nodes()
	super._ready()

func start_game() -> void:
	super.start_game()
	_show_banner("Get ready!", 1.4)

# ================================================================== CLOCK / NOTES

func _song_time() -> float:
	if not song_started:
		return clock
	return song.get_playback_position() + AudioServer.get_time_since_last_mix() - AudioServer.get_output_latency()

func _process(delta: float) -> void:
	if not is_running:
		return
	_read_keys()
	if finished and groove <= 0.0:
		return
	if not song_started:
		clock += delta
		if clock >= 0.0:
			song_started = true
			song.play()
	var t := _song_time()
	# spawn notes FALL_TIME before they're due
	while next_spawn < notes.size() and notes[next_spawn][0] - t <= FALL_TIME:
		_spawn(notes[next_spawn][0], int(notes[next_spawn][1]))
		next_spawn += 1
	# move, and miss the ones that went past the line
	for i in range(live.size() - 1, -1, -1):
		var n: Dictionary = live[i]
		var k: float = 1.0 - (n["t"] - t) / FALL_TIME
		n["node"].position.y = lerpf(TOP_Y, LINE_Y, k)
		if t - n["t"] > MISS_AFTER:
			_judge("miss", n["lane"])
			n["node"].queue_free()
			live.remove_at(i)
	_dance(t)
	score_label.text = str(score)

func _spawn(time: float, lane: int) -> void:
	var s := Sprite2D.new()
	s.texture = note_tex[lane]
	s.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	s.scale = Vector2(5, 5)
	s.position = Vector2(LANE_X[lane], TOP_Y)
	add_child(s)
	move_child(s, targets[0].get_index())          # under the targets / HUD
	live.append({ "t": time, "lane": lane, "node": s })

# ================================================================== HITS

func _press(lane: int) -> void:
	if not is_running or finished:
		return
	_flash(lane)
	var t := _song_time()
	var best := -1
	var best_d := 99.0
	for i in live.size():
		var n: Dictionary = live[i]
		if n["lane"] != lane:
			continue
		var d: float = absf(n["t"] - t)
		if d < best_d:
			best_d = d
			best = i
	if best < 0 or best_d > SLOPPY:
		if next_spawn > 0:
			_judge("stray", lane)                    # (no penalty during the count-in)                        # no note there: mashing costs groove
		return
	var n: Dictionary = live[best]
	live.remove_at(best)
	var node: Sprite2D = n["node"]
	if best_d > GOOD:                                # too early / too late: that note is lost
		_judge("miss", lane)
		var tf := create_tween()
		tf.tween_property(node, "modulate", Color(0.4, 0.3, 0.35, 0.0), 0.2)
		tf.tween_callback(node.queue_free)
		return
	_judge("perfect" if best_d <= PERFECT else "good", lane)
	var tw := create_tween()
	tw.tween_property(node, "scale", Vector2(8, 8), 0.1)
	tw.parallel().tween_property(node, "modulate:a", 0.0, 0.12)
	tw.tween_callback(node.queue_free)

func _judge(kind: String, lane: int) -> void:
	if kind == "stray":
		combo = 0
		_add_groove(GROOVE_STRAY)
		combo_label.text = ""
		return
	counts[kind] += 1
	_add_groove(GROOVE_GAIN[kind])
	if kind == "miss":
		combo = 0
	else:
		combo += 1
		best_combo = maxi(best_combo, combo)
		var mult := 1 + mini(combo / 10, 3)            # x1 .. x4
		add_score(POINTS[kind] * mult)
	judge_label.text = { "perfect": "PERFECT!", "good": "GOOD", "miss": "MISS" }[kind]
	judge_label.add_theme_color_override("font_color", { "perfect": Color8(255, 236, 140), "good": Color8(250, 244, 214), "miss": Color8(214, 120, 130) }[kind])
	judge_label.position.x = LANE_X[lane] - judge_label.size.x / 2.0
	judge_label.modulate.a = 1.0
	var tw := create_tween()
	tw.tween_interval(0.25)
	tw.tween_property(judge_label, "modulate:a", 0.0, 0.25)
	combo_label.text = ("x%d  combo %d" % [1 + mini(combo / 10, 3), combo]) if combo >= 5 else ""

func _add_groove(d: float) -> void:
	if finished:
		return
	groove = clampf(groove + d, 0.0, 1.0)
	_draw_groove()
	if groove <= 0.0:
		_fail()

func _draw_groove() -> void:
	if not groove_fill:
		return
	groove_fill.size.x = (groove_box.size.x - 8) * groove
	groove_fill.color = Color8(214, 120, 130) if groove < 0.3 else (Color8(250, 206, 110) if groove < 0.6 else Color8(150, 200, 120))

## The groove ran out: the record scratches to a stop and the game ends.
func _fail() -> void:
	finished = true
	song.stop()
	for n in live:
		n["node"].queue_free()
	live.clear()
	await get_tree().create_timer(0.5).timeout
	if not is_running:
		return
	end_game()
	if game_over_overlay:
		var title: Label = game_over_overlay.get_meta("title")
		title.text = "Lost the groove!"
		var st: Label = game_over_overlay.get_meta("score_text")
		st.text = "Score %d   best combo %d" % [score, best_combo]
		st.add_theme_font_size_override("font_size", 30)

func _on_song_finished() -> void:
	if finished:
		return
	finished = true
	await get_tree().create_timer(0.6).timeout
	if not is_running:
		return
	var total := maxi(1, counts["perfect"] + counts["good"] + counts["miss"])
	var acc: float = 100.0 * (counts["perfect"] + 0.5 * counts["good"]) / total
	end_game()
	if game_over_overlay:
		var title: Label = game_over_overlay.get_meta("title")
		title.text = "Song clear!"
		var st: Label = game_over_overlay.get_meta("score_text")
		st.text = "Score %d   %d%%   best combo %d" % [score, int(acc), best_combo]
		st.add_theme_font_size_override("font_size", 30)

func freeze() -> void:
	super.freeze()
	if song:
		song.stop()

func end_game() -> void:
	if song and not finished:
		song.stop()
	super.end_game()

# ================================================================== INPUT

func on_main_button_pressed() -> void:
	if is_game_over:
		super.on_main_button_pressed()
		return
	if not _touch_mode:
		_press(1)

func on_forward_button_down() -> void:
	if not is_game_over and not _touch_mode:
		_press(2)

func on_forward_button_pressed() -> void:
	if is_game_over:
		super.on_forward_button_pressed()

## The speaker button is a lane in this game (sound_button.gd routes it here instead of muting)
func on_sound_button_pressed() -> void:
	if not is_game_over and not _touch_mode:
		_press(0)

func _input(event: InputEvent) -> void:
	if not (event is InputEventScreenTouch):
		return
	_touch_mode = true
	if is_game_over:
		return
	if event.pressed:
		var lane := _lane_at(event.position)
		if lane >= 0:
			_touch_lane[event.index] = lane
			_press(lane)
	else:
		_touch_lane.erase(event.index)

func _lane_at(screen_pos: Vector2) -> int:
	var paths := ["/root/PoopPal/Main UI/SoundButtons/SoundButton", "/root/PoopPal/Main UI/MainButton", "/root/PoopPal/Main UI/SoundButtons/ForwardButton"]
	for i in paths.size():
		var b := get_node_or_null(paths[i]) as Control
		if b and (b.get_global_transform_with_canvas() * Rect2(Vector2.ZERO, b.size)).grow(20).has_point(screen_pos):
			return i
	return -1

func _read_keys() -> void:
	var map := { KEY_LEFT: 0, KEY_A: 0, KEY_DOWN: 1, KEY_S: 1, KEY_SPACE: 1, KEY_RIGHT: 2, KEY_D: 2 }
	for k in map:
		var down := Input.is_key_pressed(k)
		if down and not _keys.get(k, false):
			_press(map[k])
		_keys[k] = down

# ================================================================== NODES / FX

func _create_static_nodes() -> void:
	var bg := ColorRect.new()
	bg.color = Color8(120, 70, 110)                  # a dim, cosy stage
	bg.size = Vector2(PLAY_WIDTH, PLAY_HEIGHT)
	add_child(bg)
	for i in 3:
		var lane := ColorRect.new()
		lane.color = Color(LANE_COLORS[i].r, LANE_COLORS[i].g, LANE_COLORS[i].b, 0.12)
		lane.position = Vector2(LANE_X[i] - LANE_W / 2.0, 0)
		lane.size = Vector2(LANE_W, PLAY_HEIGHT)
		add_child(lane)
		var flash := ColorRect.new()
		flash.color = Color(LANE_COLORS[i].r, LANE_COLORS[i].g, LANE_COLORS[i].b, 0.0)
		flash.position = lane.position
		flash.size = lane.size
		add_child(flash)
		lane_flash.append(flash)
	var line := ColorRect.new()
	line.color = Color8(250, 244, 214, 140)
	line.position = Vector2(LANE_X[0] - LANE_W / 2.0, LINE_Y - 3)
	line.size = Vector2(LANE_X[2] - LANE_X[0] + LANE_W, 6)
	add_child(line)
	# targets: hollow rings on the line, one per lane
	for i in 3:
		var r := Sprite2D.new()
		r.texture = _ring_texture(LANE_COLORS[i])
		r.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		r.scale = Vector2(5, 5)
		r.position = Vector2(LANE_X[i], LINE_Y)
		add_child(r)
		targets.append(r)
	# the pal with headphones on, dancing to the beat in the top-left corner
	var frames: SpriteFrames = PetState.build_sprite_frames() if PetState.has_poop() else null
	if frames:
		pal = AnimatedSprite2D.new()
		pal.sprite_frames = frames
		pal.play("idle")
		pal.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		pal.scale = Vector2(2.3, 2.3)
		pal.set_meta("base", pal.scale)
		pal.position = PAL_POS
		add_child(pal)
		headphones = Sprite2D.new()
		pal.add_child(headphones)
		pal.frame_changed.connect(_sync_headphones)
		_sync_headphones()
	var frame := ColorRect.new()
	frame.color = Color(0, 0, 0)
	frame.position = Vector2(PLAY_WIDTH - 245, 24)
	frame.size = Vector2(205, 70)
	add_child(frame)
	var box := ColorRect.new()
	box.color = Color(0.65, 0.72, 0.6)
	box.position = frame.position + Vector2(5, 5)
	box.size = frame.size - Vector2(10, 10)
	add_child(box)
	# groove meter under the score
	groove_box = ColorRect.new()
	groove_box.color = Color(0, 0, 0)
	groove_box.position = Vector2(frame.position.x, frame.position.y + frame.size.y + 10)
	groove_box.size = Vector2(frame.size.x, 26)
	add_child(groove_box)
	var groove_bg := ColorRect.new()
	groove_bg.color = Color(0.3, 0.2, 0.28)
	groove_bg.position = Vector2(4, 4)
	groove_bg.size = groove_box.size - Vector2(8, 8)
	groove_box.add_child(groove_bg)
	groove_fill = ColorRect.new()
	groove_fill.position = Vector2(4, 4)
	groove_fill.size = Vector2(0, groove_box.size.y - 8)
	groove_box.add_child(groove_fill)
	_draw_groove()
	score_label = _make_label(box.position + Vector2(6, 0), box.size - Vector2(18, 0), 36, HORIZONTAL_ALIGNMENT_RIGHT, Color(0.2, 0.15, 0.05))
	combo_label = _make_label(Vector2(0, 110), Vector2(PLAY_WIDTH, 50), 30, HORIZONTAL_ALIGNMENT_CENTER, Color8(255, 236, 140))
	judge_label = _make_label(Vector2(0, LINE_Y - 110), Vector2(220, 50), 32, HORIZONTAL_ALIGNMENT_CENTER, Color.WHITE)
	judge_label.add_theme_color_override("font_outline_color", OUTLINE)
	judge_label.add_theme_constant_override("outline_size", 10)
	judge_label.modulate.a = 0.0
	banner = _make_label(Vector2(0, 380), Vector2(PLAY_WIDTH, 120), 54, HORIZONTAL_ALIGNMENT_CENTER, Color(1, 0.97, 0.9))
	banner.add_theme_color_override("font_outline_color", OUTLINE)
	banner.add_theme_constant_override("outline_size", 14)
	banner.modulate.a = 0.0

func _flash(lane: int) -> void:
	var f := lane_flash[lane]
	f.color.a = 0.35
	create_tween().tween_property(f, "color:a", 0.0, 0.18)
	var r := targets[lane]
	var tw := create_tween()
	tw.tween_property(r, "scale", Vector2(6, 6), 0.05)
	tw.tween_property(r, "scale", Vector2(5, 5), 0.1)

## Dance: hop on every beat, sway left/right on alternate beats, squash on landing.
## The bigger the combo, the wilder the moves.
func _dance(t: float) -> void:
	if not pal:
		return
	var x := (t - beat_offset) * bpm / 60.0       # in beats
	var ph := x - floorf(x)
	var amp := (0.6 + 0.2 * mini(combo / 10, 3)) * (0.4 + 0.6 * minf(1.0, groove / 0.5))   # combo up = wilder, groove low = sluggish
	if finished:
		amp = 0.0
	if groove_box:
		groove_box.modulate.a = 1.0 if groove >= 0.3 or ph < 0.5 else 0.45    # low: blinks on the beat
	var sway := sin(PI * x)                       # flips side every beat
	var hop := sin(PI * ph) * 18.0 * amp
	var squash := pow(1.0 - ph, 3.0) * 0.14
	pal.position = PAL_POS + Vector2(sway * 10.0 * amp, -hop)
	pal.rotation = sway * 0.16 * amp
	pal.scale = pal.get_meta("base") * Vector2(1.0 + squash, 1.0 - squash)

func _sync_headphones() -> void:
	var path := "res://textures/pet/accessories/headphones/%s-%d.png" % [PetState.form_id, pal.frame + 1]
	headphones.texture = load(path) if ResourceLoader.exists(path) else null

static func _ring_texture(col: Color) -> Texture2D:
	var n := 15
	var img := Image.create(n, n, false, Image.FORMAT_RGBA8)
	for y in n:
		for x in n:
			var d := Vector2(x + 0.5 - n / 2.0, y + 0.5 - n / 2.0).length()
			if d <= 7.0 and d >= 5.4:
				img.set_pixel(x, y, Color8(46, 30, 40))
			elif d < 5.4 and d >= 4.0:
				img.set_pixel(x, y, col)
	return ImageTexture.create_from_image(img)

func _make_label(pos: Vector2, sz: Vector2, font_size: int, align: int, color: Color) -> Label:
	var l := Label.new()
	l.position = pos
	l.size = sz
	l.horizontal_alignment = align
	l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	if lcd_font:
		l.add_theme_font_override("font", lcd_font)
	l.add_theme_font_size_override("font_size", font_size)
	l.add_theme_color_override("font_color", color)
	add_child(l)
	return l

func _show_banner(text: String, hold: float) -> void:
	banner.text = text
	var t := create_tween()
	t.tween_property(banner, "modulate:a", 1.0, 0.15)
	t.tween_interval(hold)
	t.tween_property(banner, "modulate:a", 0.0, 0.3)
