extends Node2D
## A spirit's animation, in the drink aura's style (the user, 2026-11-06): every frame is rebuilt on
## the spirit's own pixel grid (its 56 x 56 art, 1 art px = 2 of the pal's texels) and played stepped
## at 11 fps. Nothing is redrawn: a frame is one of the spirit's faces (the approved sprite with only
## its face swapped, drawn by the designer), its moving parts set back on where they move, then the
## whole stretched, squashed, lifted or leant by whole rows and columns, with its little effects.
##
## The frames: tools/art/spirit_anim_cut.py (the faces) and tools/art/spirit_parts.py (the parts),
## in docs/mockups/spirits/anim_frames/<id>/:
##   base, closed, open, happy, sad .png    the faces, parts at rest (base = the approved sprite)
##   <face>_body.png                        the same without the parts
##   part_<name>.png, part_<name>_<i>.png   each part at rest, and its poses or frames
##   rig.json                               each spirit's parts (kind, box, pivot...), flags and effects
##
## States (play(state)):
##   idle    breathing, blinks, now and then a hop (or a rock, for the wobbly ones) or its own move
##   poke    (the orange button's tap) a squeeze, then a happy little hop
##   eat     chomps (the mouth open and shut), then pleased
##   happy   the happy face, two hops, sparkles; the parts join in
##   sleep   eyes shut, slow deep breaths, Zs drifting up; flames low, clockwork stopped (stays)
##   sad     the sad face, shallow breaths, a sigh now and then; things droop (stays)
## Parts by kind:
##   flame    flickers (its own pixels stretched and swayed, the core dimming), flares when happy,
##            low when asleep; embers rise off it
##   bolt     strikes white-hot with a glow and a rumble (hidden between, or dimmed if nothing is
##            drawn behind it)
##   bend     bent from its joint, whole pixels (style: sway a sprout or leaf, twitch ears, wag a
##            tail, flap wings or fins, swing a tassel or tentacles, beat drumsticks)
##   swing, slip, flap, flick   the pilot's tassel, cap, tufts and tongue
##   glow     a lamp's light flickering; cycle  a wind-up key and cogs turning
##   twinkle  a star flashing white-hot now and then; drift  a floating bit bobbing a pixel
##   fall     a petal, rain or a drip falling, fading, forming again; rise  smoke rising
##   lag      sits on top and follows a pixel behind on hops (a crown, a cap, a marble)
## Effects (rig "fx"): bubbles rising in a drink, glints on water or gold, drips forming at an edge.
## Every part that just sits on the body lags a pixel behind on hops (follow-through).
##
##   var a := preload("res://scripts/spirit_anim.gd").new(); pal.add_child(a)
##   a.setup("tengu", "res://textures/spirits", 62.0, "res://data/spirit_rig.json")   # in the game
##   a.setup("tengu", "res://docs/mockups/spirits/anim_frames")   # (QA, from the working frames)
## The game's copy: tools/art/spirits_install.py (frames -> textures/spirits/, rig -> data/).

const FPS := 11.0
const S := 56                          # the art canvas
const W := 72                          # the working canvas (room for hops, Zs, sparkles, embers)
const H := 72
const OFF := Vector2i(8, 14)           # where the 56 canvas sits in it
const BASE := 54                       # the art canvas row the spirit stands on
const OUTLINE := Color8(34, 16, 26)
const BREATH := [0, 0, 1, 1, 1, 1, 1, 0, 0, 0, 0, -1, -1, -1, -1, -1, 0, 0, 0, 0]
const FACES := ["base", "closed", "open", "happy", "sad"]
const SWAY := {1: [0, 1, 1, 0, 0, -1, -1, 0], 2: [0, 1, 2, 1, 0, -1, -2, -1]}
const DRIFT := [0, 0, -1, -1, 0, 0, 1, 1]
const WATER := Color8(150, 205, 245)

var manual := false                    # (QA: step() by hand)
var demo := false                      # (QA: everything happens soon)
var sprite := Sprite2D.new()
var state := "idle"

var _faces := {}                       # face -> PackedByteArray (S*S RGBA), parts at rest
var _bodies := {}                      # face -> the same without the parts
var _parts := {}                       # name -> the part (see setup)
var _order: Array = []                 # the parts in drawing order
var _wobbly := false
var _fx: Array = []
var _tex: ImageTexture
var _img: Image
var _top := 0
var _bottom := 0
var _x0 := 0
var _x1 := 0
var _cx := 28
var _t := 0.0
var _tick := 0
var _queue: Array = []                 # frames queued by a move: {face, level, lift, shear, parts}
var _next_blink := 30
var _next_move := 60
var _next_bolt := 20
var _bolt_seq: Array = []
var _flick_seq: Array = []
var _next_flick := 40
var _slip := 0                         # the cap's slide: 0 on, 1-2 slipping, held while > 0
var _slip_hold := 0
var _swing := 0.0                      # the tassel's pendulum
var _swing_v := 0.0
var _roll := 0                         # the drumsticks' roll: frames left
var _next_roll := 60
var _prev_lift := 0
var _flame_i := 0
var _zs: Array = []                    # sleep's Zs: [x, y, age]
var _sparks: Array = []                # happy's sparkles: [x, y, age]
var _embers: Array = []                # [x, y, age, tones]
var _splashes: Array = []              # [x, y, age, colour]
var _drops: Array = []                 # fx drips falling: [x, y, v, colour]
var _bubbles: Array = []               # [x, y]  (art canvas)
var _glints: Array = []                # [x, y, age]  (art canvas)
var _next_glint := 40
var _next_drip := 30
var _rng := RandomNumberGenerator.new()

# ------------------------------------------------------------------ SETUP
func setup(id: String, dir: String, baseline_y := 62.0, rig_path := "") -> void:
	var rigs: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(rig_path if rig_path != "" else dir.path_join("rig.json")))
	var rig: Dictionary = rigs[id]
	var d := dir.path_join(id)
	_faces["base"] = _load(d.path_join("base.png"))
	for f in FACES:
		var path := d.path_join(f + ".png")
		_faces[f] = _load(path) if _exists(path) else _faces["base"]
	_wobbly = rig.get("wobbly", false)
	_fx = rig.get("fx", [])
	var parts: Dictionary = rig.get("parts", {})
	var i := 0
	for nm in parts:
		var p: Dictionary = parts[nm]
		var piv: Array = p["pivot"]
		var bx: Array = p["box"]
		var px := _load(d.path_join("part_" + nm + ".png"))
		var e := {"px": px, "kind": p["kind"], "pivot": Vector2i(int(piv[0]), int(piv[1])),
			"box": Rect2i(int(bx[0]), int(bx[1]), int(bx[2]) - int(bx[0]) + 1, int(bx[3]) - int(bx[1]) + 1),
			"style": p.get("style", ""), "amp": int(p.get("amp", 1)), "side": "r", "dir": 1,
			"axis": p.get("axis", "y"), "phase": i * 5 + _rng.randi_range(0, 4), "t": 0, "seq": [],
			"next": _rng.randi_range(10, 60), "embers": p.get("embers", false), "nohide": p.get("nohide", false),
			"floor": int(p.get("floor", BASE)), "rate": int(p.get("rate", 2)), "fstyle": p.get("style", ""),
			"flutter": nm.begins_with("fin") or nm.begins_with("gills") or nm.begins_with("tentacles"),
			"hot": PackedByteArray(), "dim": PackedByteArray(), "frames": []}
		var side = p.get("side", "r")
		if typeof(side) == TYPE_STRING:
			e["side"] = side
		else:
			e["dir"] = int(side)
		var fr := []
		for k in int(p.get("frames", 0)):
			fr.append(_load(d.path_join("part_%s_%d.png" % [nm, k])))
		e["frames"] = fr
		if p["kind"] in ["bolt", "twinkle"]:
			e["hot"] = _hot(px)
			e["dim"] = _dim(px)
		if p["kind"] == "flame":
			e["flames"] = _build_flames(px, e["box"])
		if p["kind"] in ["fall", "rise"]:
			e["t"] = _rng.randi_range(0, 24)
		_parts[nm] = e
		_order.append(nm)
		i += 1
	if not _parts.is_empty():
		for f in FACES:
			var path := d.path_join(f + "_body.png")
			_bodies[f] = _load(path) if _exists(path) else _faces[f]
	_bounds()
	if demo:
		_next_blink = 8
		_next_move = 16
		_next_bolt = 6
		_next_flick = 10
		_next_roll = 10
		_next_glint = 6
		_next_drip = 8
	sprite.centered = false
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	sprite.scale = Vector2(2, 2)
	# (the art canvas's baseline row lands on the old pals' baseline, its centre on the pal's centre)
	sprite.position = Vector2(-(OFF.x + S / 2) * 2, baseline_y - (OFF.y + BASE + 1) * 2)
	add_child(sprite)
	_draw_frame({"face": "base", "level": 0, "lift": 0, "shear": 0, "parts": {}})

## (in the game the frames are imported textures, in the exported pack too; the QA working frames
## under docs/ aren't imported, so they're read as files)
func _load(path: String) -> PackedByteArray:
	var img: Image
	if ResourceLoader.exists(path):
		img = (load(path) as Texture2D).get_image()
		if img.is_compressed():
			img.decompress()
	else:
		img = Image.load_from_file(ProjectSettings.globalize_path(path))
	img.convert(Image.FORMAT_RGBA8)
	return img.get_data()

func _exists(path: String) -> bool:
	return ResourceLoader.exists(path) or FileAccess.file_exists(path)

func _bounds() -> void:
	var px: PackedByteArray = _faces["base"]
	_top = S
	_bottom = 0
	_x0 = S
	_x1 = 0
	for y in S:
		for x in S:
			if px[(y * S + x) * 4 + 3] > 0:
				_top = mini(_top, y)
				_bottom = maxi(_bottom, y)
				_x0 = mini(_x0, x)
				_x1 = maxi(_x1, x)
	_cx = (_x0 + _x1) / 2

func _has(kind: String) -> String:
	for nm in _order:
		if _parts[nm]["kind"] == kind:
			return nm
	return ""

# ------------------------------------------------------------------ STATES
## Switch state. poke, eat and happy play once and go back to idle; sleep and sad stay.
func play(s: String) -> void:
	state = s
	_queue.clear()
	_zs.clear()
	_slip = 0
	_slip_hold = 0
	match s:
		"poke":
			_queue = _poke_seq()
		"eat":
			_queue = _eat_seq()
		"happy":
			_queue = _happy_seq()
		"sleep":
			_slip = 2 if _has("slip") != "" else 0      # (the cap slides over its eyes for the night)
			_slip_hold = 1 << 20

func _process(delta: float) -> void:
	if manual:
		return
	_t += delta
	while _t >= 1.0 / FPS:
		_t -= 1.0 / FPS
		step()

## One frame (11 a second).
func step() -> void:
	_tick += 1
	var fr: Dictionary
	if not _queue.is_empty():
		fr = _queue.pop_front()
		if _queue.is_empty() and state in ["poke", "eat", "happy"]:
			state = "idle"
	else:
		fr = _idle_frame()
	if not fr.has("parts"):
		fr["parts"] = {}
	_part_motion(fr)
	_draw_frame(fr)
	_prev_lift = int(fr.get("lift", 0))

func _idle_frame() -> Dictionary:
	var fr := {"face": "base", "level": 0, "lift": 0, "shear": 0, "parts": {}}
	match state:
		"sleep":
			fr["face"] = "closed"
			fr["level"] = BREATH[(_tick / 2) % BREATH.size()]       # slow, the same depth
			if _tick % 15 == 0:
				_zs.append([_x1 + OFF.x - 4, _top + OFF.y - 1, 0])
			return fr
		"sad":
			fr["face"] = "sad"
			var b: int = BREATH[(_tick * 2 / 3) % BREATH.size()]
			fr["level"] = mini(b, 0)                                  # shallow: never stretches up
			_next_move -= 1
			if _next_move <= 0:
				_next_move = _rng.randi_range(20, 30) if demo else _rng.randi_range(60, 110)
				_queue = _sigh_seq()
			if _blink():
				fr["face"] = "closed"
			return fr
	fr["level"] = BREATH[_tick % BREATH.size()]
	if _blink():
		fr["face"] = "closed"
	_next_move -= 1
	if _next_move <= 0:
		_next_move = _rng.randi_range(26, 40) if demo else _rng.randi_range(80, 150)
		var r := _rng.randf()
		if _has("slip") != "" and r < 0.45:
			_slip = 1
			_slip_hold = 16                        # (slides down, stays a moment, then hops back)
		elif _wobbly:
			_queue = _wobble_seq() if r < 0.75 else _hop_seq("base", 5)
		elif r < 0.75:
			_queue = _hop_seq()
		else:
			_queue = _wobble_seq()
	return fr

var _blinks: Array = []
func _blink() -> bool:
	if not _blinks.is_empty():
		return _blinks.pop_front()
	_next_blink -= 1
	if _next_blink <= 0:
		_next_blink = _rng.randi_range(18, 34) if demo else _rng.randi_range(28, 60)
		_blinks = [true, true] if _rng.randf() > 0.25 else [true, true, false, true, true]
		return _blinks.pop_front()
	return false

func _f(face: String, level: int, lift := 0, shear := 0) -> Dictionary:
	return {"face": face, "level": level, "lift": lift, "shear": shear, "parts": {}}

func _hop_seq(face := "base", high := 8) -> Array:
	var k := high / 8.0
	var out := []
	for a in [[-1, 0], [-2, 0], [2, 2], [1, 5], [0, 7], [0, 8], [0, 7], [1, 5], [1, 2], [-2, 0], [-1, 0], [0, 0]]:
		out.append(_f(face, a[0], int(round(a[1] * k))))
	return out

func _wobble_seq() -> Array:
	var out := []
	for s in [2, 4, 5, 4, 2, 0, -3, -4, -3, -1, 1, 2, 1, 0, -1, 0]:
		out.append(_f("base", 0, 0, s))
	return out

func _poke_seq() -> Array:
	var out := [_f("closed", -1), _f("closed", -2), _f("closed", -2), _f("closed", -1)]
	out += _hop_seq("happy", 5)
	out += [_f("happy", 0), _f("happy", 0), _f("happy", 0), _f("base", 0)]
	_swing_v += 1.4
	_roll = 8
	return out

func _eat_seq() -> Array:
	var out := []
	for i in 3:
		out += [_f("open", 1), _f("open", 1), _f("open", 0), _f("base", -1), _f("base", -1), _f("base", 0)]
	out += [_f("happy", 0), _f("happy", 1), _f("happy", 1), _f("happy", 0), _f("happy", 0), _f("happy", 0)]
	return out

func _happy_seq() -> Array:
	var out := [_f("happy", 0), _f("happy", 0)]
	out += _hop_seq("happy", 6)
	out += _hop_seq("happy", 8)
	out += [_f("happy", 0), _f("happy", 0), _f("happy", 0), _f("happy", 0)]
	for fr in out:
		fr["happy"] = true
	_swing_v += 1.8
	return out

func _sigh_seq() -> Array:
	return [_f("sad", 1), _f("sad", 1), _f("sad", 1), _f("closed", 0), _f("closed", -1), _f("closed", -2),
		_f("closed", -2), _f("sad", -2), _f("sad", -1), _f("sad", -1), _f("sad", 0)]

# ------------------------------------------------------------------ PARTS
## Each part's move this frame: {frame} (a pose or frame), or {dx, dy, hide, hot, dim, swing,
## flame, dither}.
func _part_motion(fr: Dictionary) -> void:
	var lift: int = fr.get("lift", 0)
	var lag := clampi(lift - _prev_lift, -1, 1)       # (follow-through: a pixel behind the body)
	var landed := lift == 0 and _prev_lift > 0
	var happy: bool = fr.get("happy", false)
	var sleepy := state == "sleep"
	var sad := state == "sad"
	# the tassel's pendulum: kicked by hops, landing and leans, settling
	_swing_v += -_swing * 0.32 - float(fr.get("shear", 0)) * 0.06
	if lag != 0:
		_swing_v += 0.35 * float(lag)
	_swing_v *= 0.82
	_swing += _swing_v
	# the cap's slide
	if _slip > 0 and _slip_hold > 0:
		_slip_hold -= 1
		if _slip_hold % 6 == 0 and _slip < 2:
			_slip += 1
		if _slip_hold == 0:
			_slip = 0
			_queue = _hop_seq("base", 4)
	# the bolt's strike
	var bolt := 1
	if _has("bolt") != "":
		if sleepy:
			bolt = 0
		elif not _bolt_seq.is_empty():
			bolt = _bolt_seq.pop_front()
		else:
			_next_bolt -= 1
			if _next_bolt <= 0 or (happy and _tick % 9 == 0):
				_next_bolt = _rng.randi_range(12, 26) if demo else _rng.randi_range(16, 40)
				_bolt_seq = [2, 2, 1, 0, 0, 2, 1, 1, 0, 1, 1]
			elif sad:
				bolt = 0 if _rng.randf() < 0.6 else 1      # (weak, mostly out)
			elif _rng.randf() < 0.04:
				bolt = 0
		if bolt == 2:
			fr["shear"] = int(fr.get("shear", 0)) + (1 if _tick % 2 == 0 else -1)   # (the rumble)
	# the tongue's flick
	var tongue := true
	if _has("flick") != "":
		if sleepy or fr["face"] == "open":
			tongue = fr["face"] == "open"
		elif not _flick_seq.is_empty():
			tongue = _flick_seq.pop_front()
		else:
			_next_flick -= 1
			if _next_flick <= 0:
				_next_flick = _rng.randi_range(14, 24) if demo else _rng.randi_range(30, 70)
				_flick_seq = [false, false, true, true, false, true, false, false, true]
	# the drumsticks' roll
	if _roll > 0:
		_roll -= 1
	elif not sleepy:
		_next_roll -= 1
		if _next_roll <= 0 or happy:
			_next_roll = _rng.randi_range(20, 40) if demo else _rng.randi_range(60, 140)
			_roll = 8
	for nm in _order:
		var p: Dictionary = _parts[nm]
		var kind: String = p["kind"]
		var m := {"dx": 0, "dy": lag}
		match kind:
			"flame":
				m = {"flame": "big" if happy else ("small" if sleepy or sad else "normal")}
				if p["embers"]:
					_spawn_ember(p, happy, sleepy or sad, lift, int(fr.get("shear", 0)))
			"bolt":
				m["hide"] = bolt == 0 and not p["nohide"]
				m["dim"] = bolt == 0 and p["nohide"]
				m["hot"] = bolt == 2
			"swing":
				m["dy"] = 0
				m["swing"] = clampi(int(round(_swing)), -2, 2)
			"slip":
				m["dy"] = lag + _slip
				m["dx"] = 1 if _slip >= 2 else 0
			"flap":
				var side := -1 if p["pivot"].x < _cx else 1
				if happy or (fr["face"] == "happy" and lift > 0):
					var up := (_tick / 2) % 2 == 0
					m["dy"] = -1 if up else 0
					m["dx"] = side if up else 0
				elif sad or sleepy:
					m["dy"] = 1
			"flick":
				m = {"hide": not tongue}
			"bend":
				m = {"frame": _bend_pose(p, lift, landed, happy, sleepy, sad)}
			"glow":
				m = {"frame": _glow_frame(p, happy, sleepy)}
			"cycle":
				m = {"frame": _cycle_frame(p, happy, sleepy, sad)}
			"twinkle":
				m = _twinkle(p, happy, sleepy)
			"drift":
				m = _drift(p, sleepy)
			"fall":
				m = _fall(p)
			"rise":
				m = _rise(p)
			"lag":
				m = {"dx": 0, "dy": lag}
		fr["parts"][nm] = m
	if not _parts.is_empty():
		_flame_i = (_flame_i + 1) % 8
	if happy and _tick % 3 == 0:
		_sparks.append([_rng.randi_range(_x0 - 2, _x1 + 2) + OFF.x, _rng.randi_range(_top - 4, _top + 10) + OFF.y, 0])
	_fx_motion(happy, sleepy)

## A bent part's pose this frame: an index into its poses (amp = at rest; beat: 0 at rest).
func _bend_pose(p: Dictionary, lift: int, landed: bool, happy: bool, sleepy: bool, sad: bool) -> int:
	var amp: int = p["amp"]
	var style: String = p["style"]
	var out := -1 if p["side"] == "l" else 1           # (outward, for ears)
	var seq: Array = p["seq"]
	if style == "beat":
		if _roll <= 0:
			return 0
		var pat := [2, 1, 0, 0] if p["side"] == "l" else [0, 0, 2, 1]
		return pat[_tick % 4]
	var k := 0
	if not seq.is_empty():
		k = seq.pop_front()
	else:
		match style:
			"sway":
				if not (sleepy or sad):
					var pat: Array = SWAY[mini(amp, 2)]
					k = pat[((_tick + int(p["phase"])) / (2 if happy else 4)) % pat.size()]
				if landed:
					p["seq"] = [amp, amp, 0, -amp, 0]           # (a bob on landing)
			"twitch":
				if sleepy or sad:
					k = out * amp                               # (ears flop sideways)
				else:
					p["next"] = int(p["next"]) - 1
					if int(p["next"]) <= 0 or (happy and _tick % 7 == 0):
						p["next"] = _rng.randi_range(12, 24) if demo else _rng.randi_range(40, 100)
						p["seq"] = [out, out, 0, out, 0] if _rng.randf() < 0.5 else [out, 0]
					if landed:
						p["seq"] = [out, 0]
			"wag":
				if sad:
					k = -amp                                    # (tail down)
				elif happy:
					k = [amp, 0, -amp, 0][_tick % 4]
				elif not sleepy:
					p["next"] = int(p["next"]) - 1
					if int(p["next"]) <= 0:
						p["next"] = _rng.randi_range(14, 26) if demo else _rng.randi_range(40, 90)
						var w := []
						for r in 2:
							for v in [1, 2, 1, 0, -1, -2, -1, 0]:
								w.append(clampi(v, -amp, amp))
						p["seq"] = w
			"flap":
				if sad:
					k = -amp
				elif p["flutter"]:
					# fins and gills never quite stop in the water
					var pat := [0, 1, 0, -1]
					k = pat[((_tick + int(p["phase"])) / (8 if sleepy else (2 if happy else 4))) % 4]
				elif happy or lift > 0:
					k = amp if (_tick / 2) % 2 == 0 else -amp
				elif not sleepy:
					p["next"] = int(p["next"]) - 1
					if int(p["next"]) <= 0:
						p["next"] = _rng.randi_range(16, 30) if demo else _rng.randi_range(50, 110)
						p["seq"] = [amp, amp, 0, -amp, 0, amp, 0]
			"swing":
				var drive := _swing
				if p["flutter"] and not sleepy:
					drive += sin((_tick + int(p["phase"])) * 0.4) * 0.8   # (tentacles always wiggle a little)
				k = clampi(int(round(drive)), -amp, amp)
	return clampi(k, -amp, amp) + amp

func _glow_frame(p: Dictionary, happy: bool, sleepy: bool) -> int:
	if sleepy:
		return 2
	if _tick % 3 != 0:
		return int(p.get("last", 0))
	var r := _rng.randf()
	var f := 0
	if happy:
		f = 1 if r < 0.6 else 0
	else:
		f = 1 if r < 0.22 else (2 if r < 0.36 else 0)
	p["last"] = f
	return f

func _cycle_frame(p: Dictionary, happy: bool, sleepy: bool, sad: bool) -> int:
	if sleepy:
		return 0                                         # (wound down)
	var rate: int = p["rate"]
	if happy:
		rate = maxi(1, rate / 2)
	elif sad:
		rate *= 2
	var n: int = (p["frames"] as Array).size()
	return (_tick / rate) % n

func _twinkle(p: Dictionary, happy: bool, sleepy: bool) -> Dictionary:
	var seq: Array = p["seq"]
	if seq.is_empty():
		var chance := 0.01 if sleepy else (0.09 if happy else 0.035)
		if demo:
			chance *= 2.0
		if _rng.randf() < chance:
			p["seq"] = ["hot", "hot", "rest"] if _rng.randf() < 0.7 else ["dim", "dim", "rest"]
		return {}
	var s: String = seq.pop_front()
	return {"hot": s == "hot", "dim": s == "dim"}

func _drift(p: Dictionary, sleepy: bool) -> Dictionary:
	var o: int = DRIFT[((_tick + int(p["phase"])) / (6 if sleepy else 3)) % DRIFT.size()]
	if p["axis"] == "x":
		return {"dx": o * int(p["dir"]), "dy": 0}
	return {"dx": 0, "dy": o}

## A petal, raindrop or drip falling: down (and drifting, for a petal), fading at the end, gone a
## moment, then back where it began.
func _fall(p: Dictionary) -> Dictionary:
	p["t"] = int(p["t"]) + 1
	var t: int = p["t"]
	var bx: Rect2i = p["box"]
	var dist := clampi(int(p["floor"]) - bx.end.y + 1, 2, 16)
	match p["fstyle"]:
		"drip":
			var hang := 26                                       # (it hangs, then lets go)
			if t < hang:
				p["landed"] = false
				return {}
			var u := t - hang
			var dy := (u * (u + 1)) / 4                         # (falling faster and faster)
			if dy >= dist:
				if not p.get("landed", false):
					p["landed"] = true
					_splash(bx.position.x + bx.size.x / 2, int(p["floor"]), WATER)
				if u > 30:
					p["t"] = 0
				return {"hide": true}
			return {"dy": dy}
		"rain":
			var n := 7
			if t < n:
				return {"dy": t, "dither": t >= n - 2}
			if t > n + 6:
				p["t"] = 0
			return {"hide": true}
		_:
			var steps := dist * 2
			if t < steps:
				return {"dy": t / 2, "dx": -(t / 5), "dither": t >= steps - 4}
			if t > steps + 14:
				p["t"] = 0
			return {"hide": true}

func _rise(p: Dictionary) -> Dictionary:
	p["t"] = int(p["t"]) + 1
	var t: int = p["t"]
	if t < 15:
		return {"dy": -(t / 3), "dx": [0, 0, 1, 1, 0, 0, -1, -1][(t / 2) % 8], "dither": t >= 11}
	if t > 22:
		p["t"] = 0
	return {"hide": true}

func _spawn_ember(p: Dictionary, happy: bool, low: bool, lift: int, shear: int) -> void:
	var chance := 0.06 if low else (0.5 if happy else 0.2)
	if _rng.randf() >= chance:
		return
	var bx: Rect2i = p["box"]
	var x := bx.position.x + _rng.randi_range(1, maxi(1, bx.size.x - 2))
	var y := bx.position.y + _rng.randi_range(0, 2)
	_embers.append([x + OFF.x + shear, y + OFF.y - lift, 0, p["flames"]["tones"]])

func _splash(x: int, y: int, c: Color) -> void:
	_splashes.append([x + OFF.x, y + OFF.y, 0, c])

func _fx_motion(happy: bool, sleepy: bool) -> void:
	for f in _fx:
		match f["type"]:
			"bubbles":
				var b: Array = f["box"]
				if _rng.randf() < (0.08 if sleepy else (0.4 if happy else 0.22)):
					var x := _rng.randi_range(int(b[0]) + 1, int(b[2]) - 1)
					if _liquid(x, int(b[3])):
						_bubbles.append([x, int(b[3])])
			"glints":
				_next_glint -= 1
				if _next_glint <= 0:
					_next_glint = _rng.randi_range(14, 30) if demo else _rng.randi_range(30, 70)
					var pts: Array = f["points"]
					var pt: Array = pts[_rng.randi_range(0, pts.size() - 1)]
					_glints.append([int(pt[0]), int(pt[1]), 0])
			"drip":
				if sleepy:
					continue
				_next_drip -= 1
				if _next_drip <= 0:
					_next_drip = _rng.randi_range(18, 34) if demo else _rng.randi_range(40, 90)
					var at: Array = f["at"]
					_drops.append([int(at[0]) + OFF.x, int(at[1]) + OFF.y, 0.0, WATER])
	var keep := []
	for b in _bubbles:
		if _tick % 2 == 0:
			b[1] -= 1
		if _liquid(b[0], b[1]):
			keep.append(b)
	_bubbles = keep

func _liquid(x: int, y: int) -> bool:
	if x < 0 or y < 0 or x >= S or y >= S:
		return false
	var px: PackedByteArray = _faces["base"]
	var i := (y * S + x) * 4
	return px[i + 3] > 0 and px[i] + px[i + 1] + px[i + 2] > 300

# ------------------------------------------------------------------ DRAWING
func _draw_frame(fr: Dictionary) -> void:
	var face: String = fr["face"]
	var parts: Dictionary = fr.get("parts", {})
	var moved := false
	for nm in _order:
		var p: Dictionary = _parts[nm]
		var m: Dictionary = parts.get(nm, {})
		match p["kind"]:
			"flame":
				moved = true
			"bend":
				var rest: int = 0 if p["style"] == "beat" else int(p["amp"])
				if int(m.get("frame", rest)) != rest:
					moved = true
			"glow", "cycle":
				if int(m.get("frame", 0)) != 0:
					moved = true
			_:
				if m.get("dx", 0) != 0 or m.get("dy", 0) != 0 or m.get("hide", false) or m.get("hot", false) \
						or m.get("dim", false) or m.get("swing", 0) != 0 or m.get("dither", false):
					moved = true
	var src: PackedByteArray
	if moved and not _bodies.is_empty():
		src = (_bodies[face] as PackedByteArray).duplicate()
		for nm in _order:
			_draw_part(src, _parts[nm], parts.get(nm, {}))
	else:
		src = (_faces[face] as PackedByteArray).duplicate()
	_draw_art_fx(src)
	var out := _deform(src, int(fr.get("level", 0)), int(fr.get("lift", 0)), int(fr.get("shear", 0)))
	_overlays(out)
	var img := Image.create_from_data(W, H, false, Image.FORMAT_RGBA8, out)
	_img = img
	if _tex == null:
		_tex = ImageTexture.create_from_image(img)
		sprite.texture = _tex
	else:
		_tex.update(img)

func _draw_part(src: PackedByteArray, p: Dictionary, m: Dictionary) -> void:
	match p["kind"]:
		"flame":
			var fset: Array = p["flames"][m.get("flame", "normal")]
			var fl: Array = fset[(_flame_i + int(p["phase"])) % fset.size()]
			var bx: Rect2i = p["box"]
			_over_at(src, fl[2], fl[0], fl[1], bx.position.x - 1, bx.end.y - fl[1], 0)
		"bend", "glow", "cycle":
			var frs: Array = p["frames"]
			var rest: int = 0 if p["kind"] != "bend" or p["style"] == "beat" else int(p["amp"])
			_over_at(src, frs[int(m.get("frame", rest))], S, S, 0, 0)
		_:
			if m.get("hide", false):
				return
			var px: PackedByteArray = p["px"]
			if m.get("hot", false):
				px = p["hot"]
			elif m.get("dim", false):
				px = p["dim"]
			_over_at(src, px, S, S, int(m.get("dx", 0)), int(m.get("dy", 0)), int(m.get("swing", 0)),
				p["pivot"].y, p["box"].size.y, m.get("dither", false))

## The frame just drawn (QA).
func frame_image() -> Image:
	return _img

## stretch (+) and squash (-): rows doubled or dropped low in the body (under the face), the middle
## column dropped or doubled; the base stays on its row, the middle on its column. lift: up by whole
## pixels; shear: the top leans by that many pixels, the base still.
func _deform(src: PackedByteArray, level: int, lift: int, shear: int) -> PackedByteArray:
	var rows: Array = range(S)
	var cols: Array = range(S)
	var r1 := _top + int((_bottom - _top) * 0.72)
	var r2 := _top + int((_bottom - _top) * 0.84)
	var cut := [r2, r1] if absi(level) >= 2 else [r1]
	for r in cut:
		var mid := cols.find(_cx)
		if mid < 0:
			mid = cols.size() / 2
		if level > 0:
			rows.insert(r, r)
			cols.remove_at(mid)
		elif level < 0:
			rows.remove_at(rows.find(r))
			cols.insert(mid, cols[mid])
	while rows.size() > S:
		rows.pop_front()
	while rows.size() < S:
		rows.push_front(-1)
	while cols.size() > S:
		cols.pop_front()
		if cols.size() > S:
			cols.pop_back()
	while cols.size() < S:
		cols.push_front(-1)
		if cols.size() < S:
			cols.push_back(-1)
	var out := PackedByteArray()
	out.resize(W * H * 4)
	var span := float(maxi(1, BASE - _top))
	for y in S:
		var sy: int = rows[y]
		if sy < 0:
			continue
		var dx := int(round(shear * float(BASE - y) / span))
		var ty := y + OFF.y - lift
		if ty < 0 or ty >= H:
			continue
		for x in S:
			var sx: int = cols[x]
			if sx < 0:
				continue
			var si := (sy * S + sx) * 4
			if src[si + 3] == 0:
				continue
			var tx := x + OFF.x + dx
			if tx < 0 or tx >= W:
				continue
			var ti := (ty * W + tx) * 4
			out[ti] = src[si]
			out[ti + 1] = src[si + 1]
			out[ti + 2] = src[si + 2]
			out[ti + 3] = 255
	return out

## Draw a w x h layer onto the S x S art at (x0, y0); swing leans it from its pivot row down (a
## hanging tassel: the lower the row, the further it goes, up to `swing` px at the bottom); dither
## leaves out every other pixel (fading).
func _over_at(dst: PackedByteArray, src: PackedByteArray, w: int, h: int, x0: int, y0: int,
		swing := 0, pivot_y := 0, span := 1, dither := false) -> void:
	for y in h:
		var sdx := 0
		if swing != 0 and y > pivot_y:
			sdx = int(round(swing * float(y - pivot_y) / float(maxi(1, span))))
		for x in w:
			var si := (y * w + x) * 4
			if src[si + 3] == 0:
				continue
			var tx := x0 + x + sdx
			var ty := y0 + y
			if tx < 0 or ty < 0 or tx >= S or ty >= S:
				continue
			if dither and (tx + ty + _tick) % 2 == 0:
				continue
			var ti := (ty * S + tx) * 4
			dst[ti] = src[si]
			dst[ti + 1] = src[si + 1]
			dst[ti + 2] = src[si + 2]
			dst[ti + 3] = 255

func _put(out: PackedByteArray, x: int, y: int, c: Color, w := W, h := H) -> void:
	if x < 0 or y < 0 or x >= w or y >= h:
		return
	var i := (y * w + x) * 4
	out[i] = c.r8
	out[i + 1] = c.g8
	out[i + 2] = c.b8
	out[i + 3] = 255

func _px_at(px: PackedByteArray, x: int, y: int) -> Color:
	var i := (y * S + x) * 4
	return Color8(px[i], px[i + 1], px[i + 2], px[i + 3])

## On the art itself (so they move with it): bubbles rising in a drink, glints.
func _draw_art_fx(src: PackedByteArray) -> void:
	for b in _bubbles:
		var x: int = b[0]
		var y: int = b[1]
		if src[(y * S + x) * 4 + 3] > 0:
			_put(src, x, y, _px_at(src, x, y).lerp(Color.WHITE, 0.55), S, S)
	var keep := []
	for g in _glints:
		g[2] += 1
		var age: int = g[2]
		if age > 4:
			continue
		keep.append(g)
		var arm: int = [0, 1, 1, 0][age - 1]
		_put(src, g[0], g[1], Color8(255, 255, 250), S, S)
		for k in range(1, arm + 1):
			for dd in [Vector2i(k, 0), Vector2i(-k, 0), Vector2i(0, k), Vector2i(0, -k)]:
				_put(src, g[0] + dd.x, g[1] + dd.y, Color8(255, 246, 210), S, S)
	_glints = keep

## Over the spirit (not stretched with it), stepped like the aura: sleep's Zs, happy's sparkles,
## embers off flames, drips and their splashes.
func _overlays(out: PackedByteArray) -> void:
	var zfill := Color8(236, 230, 255)
	var keep := []
	for z in _zs:
		z[2] += 1
		var age: int = z[2]
		if age > 24:
			continue
		keep.append(z)
		if age > 18 and age % 2 == 0:
			continue                                         # (flickers out)
		var x: int = z[0] + age / 4
		var y: int = z[1] - age / 2
		var big := age > 9
		var glyph: Array = ["####", "..#.", ".#..", "####"] if big else ["###", ".#.", "###"]
		var n: int = glyph.size()
		for gy in range(-1, n + 1):                           # its dark outline first
			for gx in range(-1, n + 1):
				var near := false
				for dy in [-1, 0, 1]:
					for dx in [-1, 0, 1]:
						var yy: int = gy + dy
						var xx: int = gx + dx
						if yy >= 0 and xx >= 0 and yy < n and xx < n and glyph[yy][xx] == "#":
							near = true
				var inside: bool = gy >= 0 and gx >= 0 and gy < n and gx < n and glyph[gy][gx] == "#"
				if near and not inside:
					_put(out, x + gx, y + gy, OUTLINE)
		for gy in n:
			for gx in n:
				if glyph[gy][gx] == "#":
					_put(out, x + gx, y + gy, zfill)
	_zs = keep
	var keep_s := []
	for s in _sparks:
		s[2] += 1
		var age: int = s[2]
		if age > 6:
			continue
		keep_s.append(s)
		var arm: int = [0, 1, 2, 2, 1, 0][age - 1]
		var x: int = s[0]
		var y: int = s[1] - age / 2
		_put(out, x, y, Color8(255, 255, 240))
		for k in range(1, arm + 1):
			var c := Color8(255, 226, 120) if k == arm else Color8(255, 246, 200)
			_put(out, x + k, y, c)
			_put(out, x - k, y, c)
			_put(out, x, y + k, c)
			_put(out, x, y - k, c)
	_sparks = keep_s
	# embers: one pixel each, rising and swaying, pale, then the flame's tone, then its edge, gone
	var keep_e := []
	for e in _embers:
		e[2] += 1
		var age: int = e[2]
		if age > 10:
			continue
		keep_e.append(e)
		if age % 2 == 0:
			e[1] -= 1
		if age % 3 == 0:
			e[0] += _rng.randi_range(-1, 1)
		var tones: Array = e[3]
		var c: Color = tones[2] if age <= 3 else (tones[1] if age <= 7 else tones[0])
		_put(out, e[0], e[1], c)
	_embers = keep_e
	# drips: fall with gravity to the floor, then splash
	var keep_d := []
	var floor_y := BASE + OFF.y
	for dr in _drops:
		dr[2] += 0.35
		dr[1] += int(dr[2])
		if dr[1] >= floor_y:
			_splashes.append([dr[0], floor_y, 0, dr[3]])
			continue
		keep_d.append(dr)
		_put(out, dr[0], dr[1] - 1, dr[3])
		_put(out, dr[0], dr[1], dr[3].darkened(0.25))
	_drops = keep_d
	var keep_p := []
	for sp in _splashes:
		sp[2] += 1
		var age: int = sp[2]
		if age > 3:
			continue
		keep_p.append(sp)
		var c: Color = sp[3]
		if age == 1:
			_put(out, sp[0] - 1, sp[1] - 1, c)
			_put(out, sp[0] + 1, sp[1] - 1, c)
		elif age == 2:
			_put(out, sp[0] - 2, sp[1] - 2, c)
			_put(out, sp[0] + 2, sp[1] - 2, c)
		else:
			_put(out, sp[0] - 3, sp[1] - 1, c.darkened(0.3))
			_put(out, sp[0] + 3, sp[1] - 1, c.darkened(0.3))
	_splashes = keep_p

## White-hot: its colours near white, its dark rim gold, a pale glow round it.
func _hot(src: PackedByteArray) -> PackedByteArray:
	var out := PackedByteArray()
	out.resize(src.size())
	for y in S:
		for x in S:
			var i := (y * S + x) * 4
			if src[i + 3] > 0:
				var dark := src[i] * 0.3 + src[i + 1] * 0.59 + src[i + 2] * 0.11 < 75.0
				var c := Color8(255, 210, 90) if dark else Color8(255, 252, 228)
				out[i] = c.r8
				out[i + 1] = c.g8
				out[i + 2] = c.b8
				out[i + 3] = 255
			else:
				for d in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
					var nx: int = x + d.x
					var ny: int = y + d.y
					if nx >= 0 and ny >= 0 and nx < S and ny < S and src[(ny * S + nx) * 4 + 3] > 0:
						out[i] = 255
						out[i + 1] = 236
						out[i + 2] = 150
						out[i + 3] = 255
						break
	return out

## Dimmed: the same pixels, darker (a bolt between strikes, a star resting).
func _dim(src: PackedByteArray) -> PackedByteArray:
	var out := src.duplicate()
	for i in range(0, out.size(), 4):
		if out[i + 3] > 0:
			out[i] = int(out[i] * 0.62)
			out[i + 1] = int(out[i + 1] * 0.62)
			out[i + 2] = int(out[i + 2] * 0.62)
	return out

## The flame's flicker, from the designer's own flame (its first frame is that flame exactly): eight
## frames of it stretched or squashed from its foot by whole rows, its tip swaying a pixel, its hottest
## pixels dimmed now and then; a taller set (happy) and a low one (asleep, sad); and its three tones
## (edge, body, core) for the embers.
func _build_flames(px: PackedByteArray, box: Rect2i) -> Dictionary:
	var lum := []
	var cols := []
	for y in range(box.position.y, box.end.y):
		for x in range(box.position.x, box.end.x):
			var i := (y * S + x) * 4
			if px[i + 3] > 0:
				var c := Color8(px[i], px[i + 1], px[i + 2])
				lum.append(c.get_luminance())
				cols.append(c)
	lum.sort()
	var hot: float = lum[int(lum.size() * 0.8)] if lum.size() > 4 else 2.0
	var mid := Color8(248, 170, 52)
	for c in cols:                                             # (the mid tone: the median pixel)
		if absf(c.get_luminance() - lum[lum.size() / 2]) < 0.03:
			mid = c
	cols.sort_custom(func(a, b): return a.get_luminance() < b.get_luminance())
	var bright := cols.filter(func(c): return c.get_luminance() > 0.25)
	var tones := [Color8(232, 98, 40), mid, Color8(255, 240, 170)]
	if bright.size() >= 3:
		tones = [bright[int(bright.size() * 0.15)], bright[int(bright.size() * 0.55)], bright[int(bright.size() * 0.95)]]
	var h0 := box.size.y
	var sway := [0, 1, 1, 0, -1, -1, 0, 1]
	var sets := {"normal": [0, 1, 1, 0, -1, 0, 1, 0], "big": [3, 4, 3, 2, 4, 3, 2, 4],
		"small": [0, 0, 1, 0, 0, -1, 0, 1]}
	var out_sets := {"tones": tones}
	for nm in sets:
		var frames := []
		for f in 8:
			var fh: int = h0 + int(sets[nm][f])
			if nm == "small":
				fh = maxi(4, int(round(h0 * 0.55)) + int(sets[nm][f]))
			var fw := box.size.x + 2
			var out := PackedByteArray()
			out.resize(fw * fh * 4)
			for j in fh:
				var sy := box.position.y + mini(h0 - 1, int((j + 0.5) * h0 / fh))
				var tt := float(j) / float(fh)
				var dx := int(round(sway[f] * maxf(0.0, 1.0 - tt / 0.6))) if nm != "normal" or f > 0 else 0
				for x in box.size.x:
					var si := (sy * S + box.position.x + x) * 4
					if px[si + 3] == 0:
						continue
					var tx := x + 1 + dx
					if tx < 0 or tx >= fw:
						continue
					var c := Color8(px[si], px[si + 1], px[si + 2])
					if f % 3 == 1 and c.get_luminance() >= hot:
						c = mid                                      # (the core dims)
					var ti := (j * fw + tx) * 4
					out[ti] = c.r8
					out[ti + 1] = c.g8
					out[ti + 2] = c.b8
					out[ti + 3] = 255
			frames.append([fw, fh, out])
		out_sets[nm] = frames
	return out_sets
