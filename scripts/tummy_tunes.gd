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

## The pilot (docs/tomo_tunes.md, 2026-11-12): a Suno song split in two by tools/audio/tune_chart.py. The lead (the
## toy instrument you play) and the backing play as ONE synchronized stream; a miss silences the lead until the next
## hit, the band plays on. The chart is the lead's own notes, lanes by pitch (low / middle / high).
## (The first prototype's song: "res://sounds/music/Retro Game Console.mp3" + data/charts/retro_game_console.json.)
## THE TEMPORARY SONG MENU (2026-11-13): the shared level menu lists every song made so far, each three times:
## easy, normal, hard (levels 1-3 = TUNES[0], 4-6 = TUNES[1] ...). The real worlds' tables come later.
const TUNES := ["1A", "1B"]
const CHARTS := ["easy", "normal", "hard"]
const STAR_2 := 0.85                  # of the notes hit
const STAR_3 := 0.95
var tune := "1A"
var difficulty := "easy"
var level := 1
const SONG_LEAD := "res://sounds/tunes/%s/lead.ogg"
const SONG_BACKING := "res://sounds/tunes/%s/backing.ogg"
const CHART := "res://data/charts/tunes_%s.json"
const LEAD_MUTED_DB := -60.0
## The lead goes silent the moment a note is due and hasn't been hit (the user, 2026-11-12: after a stop, the next note
## still sounded, because a miss is only judged MISS_AFTER later). A hit, even a late one, brings it back.
const LEAD_ARM := 0.02                 # s before a note's time
var lead_on := true
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
const GROOVE_STRAY := -0.07           # pressing when there's no note at all (was -0.04: the user, 2026-11-13, "it should also accelerate losing")
## A press that is not a hit plays the instrument's WRONG note in that lane's register (the user, 2026-11-13: "a little
## dissonant sound of the instrument being played, low medium or high"; a trial on world 1, then the rule for every
## world). Made by tools/audio/tune_wrong.py.
const WRONG := "res://sounds/tunes/fx/xylophone_wrong_%s.wav"
const WRONG_DB := -11.0               # (was -5: the user, "a bit less loud")
var wrong: Array[AudioStreamPlayer] = []

## World 1's look (2026-11-13): the designer's toy room and xylophone (docs/mockups/tomo_tunes/round1/), made into
## pixel layers by tools/design/tunes_world.py: 1 art pixel = 3 on screen. layout.json holds each layer's box.
## The lanes are the bars' centres; a note is due when it sits on its bar.
const ART := "res://textures/minigames/tunes/xylophone/"
const PX := 3.0
var LANE_X := [264.0, 480.0, 693.0]      # on the bars (read from layout.json)
const LINE_Y := 817.0
const TOP_Y := 96.0
const LANE_NAMES := ["low", "mid", "high"]
const DIMMED := Color(0.66, 0.6, 0.74)     # the room while the instrument is silent (a miss)
const LANE_COLORS := [Color8(246, 150, 180), Color8(250, 206, 110), Color8(150, 220, 190)]
const OUTLINE := Color8(74, 44, 32)
const PAL_POS := Vector2(130, 82)

var notes: Array = []                 # [time, lane]
var next_spawn := 0
var live: Array[Dictionary] = []      # { t, lane, node }
var song: AudioStreamPlayer
var sync: AudioStreamSynchronized     # 0 = the backing, 1 = the lead
var song_length := 0.0
var song_started := false
var played := 0.0                     # seconds since the song started, by the frame clock (the fallback for its end)
var clock := -LEAD_IN                 # song time (negative during the count-in)
## The count-in (the user, 2026-11-13): one bar of metronome before the first note, "tic tac tac tac", at the
## song's own tempo, so the first note can be hit. The fourth beat of that bar IS the song's first note (the
## user: "to flow better"): three clicks, then the note.
const COUNT_BEATS := 3
## Some songs want another count (the user, 2026-11-13, says which, song by song): 1B gets the full
## "tic tac tac tac" and then its first note.
const COUNT_BEATS_OF := { "1B": 4 }
var count_beats := COUNT_BEATS
var count_times: Array[float] = []    # (song time, negative) of each click still to play
var tick: AudioStreamPlayer
var tack: AudioStreamPlayer
var finished := false
var combo := 0
var best_combo := 0
var counts := { "perfect": 0, "good": 0, "miss": 0 }
var groove := GROOVE_START
var groove_fill: ColorRect
var groove_box: ColorRect

var lcd_font: Font
var note_tex: Array[Texture2D] = []
var glow_tex: Texture2D
var layout := {}
var room: Node2D                      # the room, the wall's lanes, the xylophone's frame and the toys: dims on a miss
var notes_layer: Node2D
var lanes: Array[Sprite2D] = []
var bars: Array[Sprite2D] = []
var bar_tex: Array = []               # [plain, lit] per lane
var toys := {}                        # name -> Sprite2D, pivot at its base
var dim_tween: Tween
var liveliness := 1.0                 # how much the toys move: 1 with the instrument sounding, little without
var bpm := 120.0
var beat_offset := 0.0
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
	var lf := FileAccess.open(ART + "layout.json", FileAccess.READ)
	layout = JSON.parse_string(lf.get_as_text())
	for i in 3:
		LANE_X[i] = layout["lanes_x"][i] * PX
	for c in LANE_NAMES:
		note_tex.append(load(ART + "note_%s.png" % c))
	glow_tex = load(ART + "glow.png")
	for c in LANE_NAMES:
		var wp := AudioStreamPlayer.new()
		wp.stream = load(WRONG % c)
		wp.volume_db = WRONG_DB
		add_child(wp)
		wrong.append(wp)
	tick = _click_player(1760.0)
	tack = _click_player(1175.0)
	# the pet screen's music stops; this game plays its own song in sync
	var mc = get_node_or_null("/root/PoopPal/MusicController")
	if mc:
		mc.stop()
	song = AudioStreamPlayer.new()
	add_child(song)
	_create_static_nodes()
	super._ready()

func uses_levels() -> bool:
	return true

func level_count() -> int:
	return TUNES.size() * CHARTS.size()

func world_names() -> Array:
	return ["Songs (test)"]

func level_backdrop() -> Color:
	return Color8(150, 110, 150)

## A level = a song on one of its three charts: everything from zero
func play_level(n: int) -> void:
	level = clampi(n, 1, level_count())
	tune = TUNES[(level - 1) / CHARTS.size()]
	difficulty = CHARTS[(level - 1) % CHARTS.size()]
	_load_tune()
	start_game()

func _load_tune() -> void:
	song.stop()
	for n in live:
		n["node"].queue_free()
	live.clear()
	notes = []
	var f := FileAccess.open(CHART % tune, FileAccess.READ)
	if f:
		var data = JSON.parse_string(f.get_as_text())
		if data is Dictionary:
			notes = data["charts"][difficulty]
			bpm = data["bpm"]
			beat_offset = data["offset"]
			song_length = data["length"]
	var beat := 60.0 / bpm
	var first_note: float = notes[0][0] if not notes.is_empty() else beat_offset
	count_times.clear()
	count_beats = COUNT_BEATS_OF.get(tune, COUNT_BEATS)
	for k in range(count_beats, 0, -1):
		count_times.append(first_note - k * beat)
	clock = count_times[0] - 0.6          # (a breath, then the bar of clicks)
	next_spawn = 0
	song_started = false
	played = 0.0
	finished = false
	combo = 0
	best_combo = 0
	counts = { "perfect": 0, "good": 0, "miss": 0 }
	groove = GROOVE_START
	_draw_groove()
	combo_label.text = ""
	sync = AudioStreamSynchronized.new()
	sync.stream_count = 2
	sync.set_sync_stream(0, load(SONG_BACKING % tune))
	sync.set_sync_stream(1, load(SONG_LEAD % tune))
	song.stream = sync

func start_game() -> void:
	super.start_game()
	lead_on = false
	_set_lead(true)
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
		if not count_times.is_empty() and clock >= count_times[0]:
			(tick if count_times.size() == count_beats else tack).play()
			count_times.pop_front()
		if clock >= 0.0:
			song_started = true
			song.play()
	var t := _song_time()
	# The song is over when its time is up OR when the player has stopped on its own. (The user, 2026-11-13: "when
	# song is finished menu doesn't appear": a take played whole ends exactly at song_length, the player stops, its
	# position reads 0 again, and the time was never "up".)
	if song_started:
		played += delta
		if not finished and (t > song_length + 0.3 or (played > 1.0 and not song.playing) or played > song_length + 1.5):
			_on_song_finished()
		if not song.playing:
			t = maxf(t, played)                         # (so the last notes still pass and are judged)
	# spawn notes FALL_TIME before they're due
	while next_spawn < notes.size() and notes[next_spawn][0] - t <= FALL_TIME:
		_spawn(notes[next_spawn][0], int(notes[next_spawn][1]))
		next_spawn += 1
	# move, and miss the ones that went past the line
	for i in range(live.size() - 1, -1, -1):
		var n: Dictionary = live[i]
		if lead_on and t >= n["t"] - LEAD_ARM:          # due and not hit: silent before its sound starts
			_set_lead(false)
		var k: float = 1.0 - (n["t"] - t) / FALL_TIME
		n["node"].position.y = lerpf(TOP_Y, LINE_Y, k)   # straight down onto its bar (the user)
		if t - n["t"] > MISS_AFTER:
			_judge("miss", n["lane"])
			n["node"].queue_free()
			live.remove_at(i)
	_dance(t)
	score_label.text = str(score)

func _spawn(time: float, lane: int) -> void:
	var s := Node2D.new()                           # a wooden bead on a soft glow: the brightest thing on screen
	s.position = Vector2(LANE_X[lane], TOP_Y)
	for tex in [glow_tex, note_tex[lane]]:
		var sp := Sprite2D.new()
		sp.texture = tex
		sp.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		sp.scale = Vector2(PX, PX)
		s.add_child(sp)
	notes_layer.add_child(s)
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
			wrong[lane].play()
			_judge("stray", lane)                    # (no penalty during the count-in)                        # no note there: mashing costs groove
		return
	var n: Dictionary = live[best]
	live.remove_at(best)
	var node: Node2D = n["node"]
	if best_d > GOOD:                                # too early / too late: that note is lost
		wrong[lane].play()
		_judge("miss", lane)
		var tf := create_tween()
		tf.tween_property(node, "modulate", Color(0.4, 0.3, 0.35, 0.0), 0.2)
		tf.tween_callback(node.queue_free)
		return
	_judge("perfect" if best_d <= PERFECT else "good", lane)
	_strike(lane)
	var tw := create_tween()
	tw.tween_property(node, "scale", Vector2(1.6, 1.6), 0.1)
	tw.parallel().tween_property(node, "modulate:a", 0.0, 0.12)
	tw.tween_callback(node.queue_free)

func _judge(kind: String, lane: int) -> void:
	if kind == "stray":
		combo = 0
		_add_groove(GROOVE_STRAY)
		combo_label.text = ""
		return
	counts[kind] += 1
	_set_lead(kind != "miss")                        # a miss: the instrument stays silent until the next hit
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

## A short wooden click at a pitch (the metronome's tic and tac), made here: no file
func _click_player(hz: float) -> AudioStreamPlayer:
	var rate := 22050
	var n := int(rate * 0.05)
	var data := PackedByteArray()
	data.resize(n * 2)
	for i in n:
		var e := exp(-float(i) / (rate * 0.012))
		data.encode_s16(i * 2, int(clampf(sin(TAU * hz * i / rate) * e, -1.0, 1.0) * 14000.0))
	var w := AudioStreamWAV.new()
	w.format = AudioStreamWAV.FORMAT_16_BITS
	w.mix_rate = rate
	w.data = data
	var pl := AudioStreamPlayer.new()
	pl.stream = w
	add_child(pl)
	return pl

func _set_lead(on: bool) -> void:
	if on == lead_on or not sync:
		return
	lead_on = on
	sync.set_sync_stream_volume(1, 0.0 if on else LEAD_MUTED_DB)
	if room:                                         # the room dims while the instrument is silent
		if dim_tween:
			dim_tween.kill()
		dim_tween = create_tween()
		if not on:
			dim_tween.tween_interval(0.14)               # (the lead is cut a moment before every note: only a real miss dims)
		dim_tween.tween_property(room, "modulate", Color.WHITE if on else DIMMED, 0.1 if on else 0.3)

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
	finish_level(level, 0)                           # (the result card: RETRY / LEVELS)

func fail_title() -> String:
	return "Lost the groove!"

func _on_song_finished() -> void:
	if finished:
		return
	finished = true
	await get_tree().create_timer(0.6).timeout
	if not is_running:
		return
	song.stop()
	var hit: float = float(counts["perfect"] + counts["good"]) / maxi(1, notes.size())
	var stars := 3 if hit >= STAR_3 else (2 if hit >= STAR_2 else 1)
	# the applause with the result, bigger with every star (the user, 2026-11-13); tools/audio/applause.py makes it
	var clap := AudioStreamPlayer.new()
	clap.stream = load("res://sounds/fx/applause_%d.wav" % stars)
	add_child(clap)
	clap.play()
	clap.finished.connect(clap.queue_free)
	finish_level(level, stars, 100.0 * hit, false)

func freeze() -> void:
	super.freeze()
	if song:
		song.stop()

func _exit_tree() -> void:
	_show_speaker_held(false)

func end_game() -> void:
	if song and not finished:
		song.stop()
	super.end_game()

# ================================================================== INPUT

## The lanes follow the bottom buttons from left to right: speaker · orange · forward, or with the
## new layout on trial (ConsoleLayout) orange · speaker · forward
const SPEAKER_LANE := 1 if ConsoleLayout.NEW_BUTTONS else 0
const MAIN_LANE := 0 if ConsoleLayout.NEW_BUTTONS else 1

func on_main_button_pressed() -> void:
	if intro_active():
		dismiss_intro()
		return
	if is_game_over or level_menu_open():
		super.on_main_button_pressed()             # (the level menu and its result card)
		return
	if not _touch_mode:
		_press(MAIN_LANE)

func on_forward_button_down() -> void:
	if not is_game_over and not _touch_mode and not level_menu_open():
		_press(2)

func on_forward_button_pressed() -> void:
	if is_game_over or level_menu_open():
		super.on_forward_button_pressed()          # (the level menu's next world)

## The speaker button is a lane in this game (sound_button.gd routes it here instead of muting)
func on_sound_button_pressed() -> void:
	if not is_game_over and not _touch_mode and not level_menu_open():
		_press(SPEAKER_LANE)

func _input(event: InputEvent) -> void:
	if not (event is InputEventScreenTouch):
		return
	_touch_mode = true
	if is_game_over or level_menu_open() or not is_running:
		return                                       # (menus: the buttons work as buttons)
	if event.pressed:
		var lane := _lane_at(event.position)
		if lane >= 0:
			_touch_lane[event.index] = lane
			_press(lane)
			if lane == SPEAKER_LANE:
				_show_speaker_held(true)
	else:
		if _touch_lane.get(event.index, -1) == SPEAKER_LANE:
			_show_speaker_held(false)
		_touch_lane.erase(event.index)

## The speaker button looks pressed while its lane is held (any finger, or the A / Left key)
func _show_speaker_held(held: bool) -> void:
	var b = get_node_or_null("/root/PoopPal/Main UI/SoundButtons/SoundButton")
	if b and b.has_method("show_held"):
		b.show_held(held)

func _lane_at(screen_pos: Vector2) -> int:
	var buttons := {"/root/PoopPal/Main UI/SoundButtons/SoundButton": SPEAKER_LANE, "/root/PoopPal/Main UI/MainButton": MAIN_LANE, "/root/PoopPal/Main UI/SoundButtons/ForwardButton": 2}
	for path in buttons:
		var b := get_node_or_null(path) as Control
		if b and (b.get_global_transform_with_canvas() * Rect2(Vector2.ZERO, b.size)).grow(20).has_point(screen_pos):
			return buttons[path]
	return -1

func _read_keys() -> void:
	var map := { KEY_LEFT: 0, KEY_A: 0, KEY_DOWN: 1, KEY_S: 1, KEY_SPACE: 1, KEY_RIGHT: 2, KEY_D: 2 }
	for k in map:
		var down := Input.is_key_pressed(k)
		if down and not _keys.get(k, false):
			_press(map[k])
		if map[k] == SPEAKER_LANE and down != _keys.get(k, false):
			_show_speaker_held(down)
		_keys[k] = down

# ================================================================== NODES / FX

func _create_static_nodes() -> void:
	room = Node2D.new()
	add_child(room)
	_layer("room", room)
	for c in LANE_NAMES:
		lanes.append(_layer("lane_" + c, room))
	_layer("xylophone", room)
	_layer("toy_kokeshi_bench", room)
	for t in ["toy_kokeshi", "toy_daruma", "toy_ball", "toy_maneki", "toy_maneki_paw", "toy_top"]:
		toys[t] = _layer(t, room, true)
	for c in LANE_NAMES:
		bar_tex.append([load(ART + "bar_%s.png" % c), load(ART + "bar_%s_lit.png" % c)])
		bars.append(_layer("bar_" + c, self))
	notes_layer = Node2D.new()
	add_child(notes_layer)
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

## A layer of the world's art at its place. based: its pivot at the middle of its base (a toy that rocks or squashes).
func _layer(layer: String, parent: Node, based := false) -> Sprite2D:
	var box: Array = layout[layer]
	var sp := Sprite2D.new()
	sp.texture = load(ART + layer + ".png")
	sp.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	sp.centered = false
	sp.scale = Vector2(PX, PX)
	sp.position = Vector2(box[0], box[1]) * PX
	if based:
		sp.offset = Vector2(-box[2] / 2.0, -box[3])
		sp.position = Vector2(box[0] + box[2] / 2.0, box[1] + box[3]) * PX
	sp.set_meta("home", sp.position)
	parent.add_child(sp)
	return sp

## A press: the lane's light jumps and the bar dips, hit or not
func _flash(lane: int) -> void:
	var l := lanes[lane]
	l.modulate = Color(1.7, 1.7, 1.7)
	create_tween().tween_property(l, "modulate", Color.WHITE, 0.2)
	var b := bars[lane]
	var home: Vector2 = b.get_meta("home")
	var tw := create_tween()
	tw.tween_property(b, "position:y", home.y + 6.0, 0.04)
	tw.tween_property(b, "position:y", home.y, 0.1)

## A note hit: its bar lights up for a moment
func _strike(lane: int) -> void:
	var b := bars[lane]
	b.texture = bar_tex[lane][1]
	var stamp := Time.get_ticks_msec()
	b.set_meta("lit", stamp)
	await get_tree().create_timer(0.16).timeout
	if is_instance_valid(b) and b.get_meta("lit") == stamp:
		b.texture = bar_tex[lane][0]

## Dance: hop on every beat, sway left/right on alternate beats, squash on landing.
## The bigger the combo, the wilder the moves.
func _dance(t: float) -> void:
	var x := (t - beat_offset) * bpm / 60.0       # in beats
	var ph := x - floorf(x)
	_toys(x, ph)
	if not pal:
		if groove_box:
			groove_box.modulate.a = 1.0 if groove >= 0.3 or ph < 0.5 else 0.45
		return
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

## The toys keep the beat: the kokeshi and the cat bob, the daruma rocks, the ball hops, the paw waves, the top leans.
## With the instrument silent (a miss) they nearly stop; they stand still before the song and after it.
func _toys(x: float, ph: float) -> void:
	var want := 0.0 if (finished or not song_started) else (1.0 if lead_on else 0.2)
	liveliness = lerpf(liveliness, want, 0.15)
	var a := liveliness
	var side := sin(PI * x)                        # flips every beat
	var land := pow(1.0 - ph, 3.0)                 # 1 on the beat, gone before the next
	var sq := land * 0.07 * a
	toys["toy_kokeshi"].scale = Vector2(1.0 + sq, 1.0 - sq) * PX
	toys["toy_maneki"].scale = Vector2(1.0 + sq * 0.6, 1.0 - sq * 0.6) * PX
	toys["toy_daruma"].rotation = side * 0.1 * a
	toys["toy_ball"].position.y = toys["toy_ball"].get_meta("home").y - sin(PI * ph) * 12.0 * a
	toys["toy_maneki_paw"].rotation = side * 0.22 * a
	toys["toy_top"].rotation = sin(PI * x * 0.5) * 0.12 * a

func _sync_headphones() -> void:
	var path := "res://textures/pet/accessories/headphones/%s-%d.png" % [PetState.form_id, pal.frame + 1]
	headphones.texture = load(path) if ResourceLoader.exists(path) else null

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
