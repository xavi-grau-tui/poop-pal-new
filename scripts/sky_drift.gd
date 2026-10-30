extends Node2D
## The hokora sky's drifting things that aren't cloud layers (Backgrounds > Clouds: HokoraCatalog
## SKY items with "particles"): cherry petals, maple leaves, snow, fireflies, spirit wisps, fireworks,
## sky lanterns, sky goldfish, the cloud dragon. Two layers like the shrine's rain: one behind the
## shrine (over the sky and its clouds), one in front of it, each at its own depth in the 3D tilt.
## The little sprites are made here (pixel art on the shrine's 4 px grid) until the designer's
## arrive: textures/pet/shrine_new/sky/<kind>_<n>.png (n = 0, 1, ...: frames or variants) are used
## instead when they exist (docs/kami_collection_art.md).
##   var drift := preload("res://scripts/sky_drift.gd").new(); shrine.add_child(drift)
##   drift.set_kind("petals")      # "" = nothing
##   drift.step(delta, area, tilt, night)   # every frame, from the shrine

const SKY_ART := "res://textures/pet/shrine_new/sky/"
const PX := 6.0                        # one art pixel on screen (about the hokora's own pixel)
## How many at once, and their two depths (px per full tilt) and shares: [back, front]
const COUNT := { "petals": 16, "maple": 11, "snow": 42, "fireflies": 14, "wisps": 5, "sky_lanterns": 6, "sky_fish": 5, "fireworks": 0, "dragon": 0 }
const FRONT_SHARE := { "petals": 0.35, "maple": 0.35, "snow": 0.4, "fireflies": 0.25, "wisps": 0.0, "sky_lanterns": 0.0, "sky_fish": 0.0 }
const DEPTH := [-40.0, 30.0]

var kind := ""
var _back: Node2D
var _front: Node2D
var _parts: Array = []                 # { pos, vel, t, layer, sprite, size, life, phase }
var _sprites: Array[Texture2D] = []
var _area := Rect2()
var _tilt := Vector2.ZERO
var _night := 0.0
var _boom_t := 1.0                     # (fireworks: the next burst)
var _dragon_t := 6.0
var _time := 0.0

func _ready() -> void:
	_back = Node2D.new()
	_back.z_index = -4                 # (behind the shrine's sides, over the sky: the rain's back layer)
	_back.draw.connect(_draw_layer.bind(0))
	add_child(_back)
	_front = Node2D.new()
	_front.z_index = 3                 # (in front of the shrine and its roof)
	_front.draw.connect(_draw_layer.bind(1))
	add_child(_front)

## What drifts ("" none). "seasons": the season's own, by the real calendar (south: the southern
## half of the world, its seasons the other way round)
func set_kind(k: String, south := false) -> void:
	if k == "seasons":
		k = season_now(south)
	if k == kind:
		return
	kind = k
	_parts.clear()
	_sprites = _load_sprites(k)

static func season_now(south := false) -> String:
	var m: int = Time.get_date_dict_from_system().month
	if south:
		m = (m + 5) % 12 + 1
	if m >= 3 and m <= 5:
		return "petals"
	if m >= 6 and m <= 8:
		return "fireflies"
	if m >= 9 and m <= 11:
		return "maple"
	return "snow"

func step(delta: float, area: Rect2, tilt: Vector2, night: float) -> void:
	_area = area
	_tilt = tilt
	_night = night
	_time += delta
	if kind == "" or _sprites.is_empty():
		if not _parts.is_empty():
			_parts.clear()
			_back.queue_redraw()
			_front.queue_redraw()
		return
	match kind:
		"fireworks":
			_fireworks(delta)
		"dragon":
			_dragon(delta)
		_:
			while _parts.size() < int(COUNT.get(kind, 10)):
				_parts.append(_spawn(_parts.size() < 3 and _time < 0.5))
	var keep: Array = []
	for p in _parts:
		_move(p, delta)
		if p["life"] > 0.0 and _area.grow(120.0).has_point(p["pos"]):
			keep.append(p)
	_parts = keep
	_back.queue_redraw()
	_front.queue_redraw()

## A new one: at the edge it comes in from (anywhere at first, so the sky isn't empty)
func _spawn(anywhere := false) -> Dictionary:
	var a := _area
	var layer := 1 if randf() < float(FRONT_SHARE.get(kind, 0.0)) else 0
	var p := { "layer": layer, "sprite": randi() % _sprites.size(), "t": randf() * 10.0, "life": 999.0,
		"phase": randf() * TAU, "size": 1.0 }
	var x := randf_range(a.position.x, a.end.x)
	var y := randf_range(a.position.y, a.end.y)
	match kind:
		"petals", "maple", "snow":
			var fall: float = float({ "petals": 70.0, "maple": 55.0, "snow": 45.0 }[kind]) * randf_range(0.7, 1.3)
			p["vel"] = Vector2(randf_range(10.0, 40.0), fall) * (0.75 if layer == 0 else 1.15)
			p["pos"] = Vector2(x, y) if anywhere or _time < 0.5 else Vector2(x - 60.0, a.position.y - 20.0)
			if not anywhere and _time >= 0.5 and randf() < 0.3:
				p["pos"] = Vector2(a.position.x - 20.0, y)         # (some come in from the side)
		"fireflies", "wisps":
			p["vel"] = Vector2.from_angle(randf() * TAU) * (14.0 if kind == "fireflies" else 9.0)
			p["pos"] = Vector2(x, randf_range(a.position.y + a.size.y * 0.25, a.end.y - 40.0))
			p["life"] = randf_range(14.0, 26.0)
		"sky_lanterns":
			p["vel"] = Vector2(randf_range(-4.0, 8.0), -randf_range(16.0, 26.0))
			p["pos"] = Vector2(x, y) if anywhere or _time < 0.5 else Vector2(x, a.end.y + 30.0)
		"sky_fish":
			var right := randf() < 0.5
			p["vel"] = Vector2(randf_range(22.0, 38.0) * (1.0 if right else -1.0), 0.0)
			p["pos"] = Vector2(x if anywhere or _time < 0.5 else (a.position.x - 30.0 if right else a.end.x + 30.0),
				randf_range(a.position.y + 40.0, a.position.y + a.size.y * 0.55))
	if not p.has("vel"):
		p["vel"] = Vector2.ZERO
		p["pos"] = Vector2(x, y)
	return p

func _move(p: Dictionary, delta: float) -> void:
	p["t"] += delta
	var t: float = p["t"]
	match kind:
		"petals", "maple":
			# fluttering: a sway across and a slower fall while it turns broadside
			var sway := sin(t * 2.2 + p["phase"]) * (26.0 if kind == "petals" else 20.0)
			p["pos"] += (p["vel"] + Vector2(sway, -absf(sway) * 0.5)) * delta
		"snow":
			p["pos"] += (p["vel"] + Vector2(sin(t * 1.3 + p["phase"]) * 12.0, 0.0)) * delta
		"fireflies", "wisps":
			var turn := sin(t * 0.7 + p["phase"]) * 1.2
			p["vel"] = (p["vel"] as Vector2).rotated(turn * delta)
			p["pos"] += p["vel"] * delta
			p["life"] -= delta
		"sky_lanterns":
			p["pos"] += (p["vel"] + Vector2(sin(t * 0.9 + p["phase"]) * 6.0, 0.0)) * delta
		"sky_fish":
			p["pos"] += (p["vel"] + Vector2(0.0, sin(t * 1.6 + p["phase"]) * 10.0)) * delta
		"fireworks":
			p["vel"] = (p["vel"] as Vector2) * pow(0.25, delta) + Vector2(0.0, 40.0) * delta
			p["pos"] += p["vel"] * delta
			p["life"] -= delta
		"dragon":
			p["pos"] += p["vel"] * delta

## Night only: a burst now and then, high up, its sparks in one colour
func _fireworks(delta: float) -> void:
	_boom_t -= delta
	if _night < 0.35 or _boom_t > 0.0:
		return
	_boom_t = randf_range(1.0, 2.4)
	var c := Vector2(randf_range(_area.position.x + 80.0, _area.end.x - 80.0), randf_range(_area.position.y + 60.0, _area.position.y + _area.size.y * 0.35))
	var hue := randi() % 4
	for i in 22:
		var v := Vector2.from_angle(TAU * i / 22.0 + randf() * 0.1) * randf_range(120.0, 170.0)
		_parts.append({ "pos": c, "vel": v, "t": 0.0, "layer": 0, "sprite": hue % _sprites.size(), "life": randf_range(1.0, 1.5), "phase": 0.0, "size": 1.0 })

## Now and then the dragon of clouds crosses, high up (only with its drawing)
func _dragon(delta: float) -> void:
	_dragon_t -= delta
	if _dragon_t > 0.0 or not _parts.is_empty():
		return
	_dragon_t = randf_range(30.0, 50.0)
	var right := randf() < 0.5
	var y := randf_range(_area.position.y + 40.0, _area.position.y + _area.size.y * 0.3)
	_parts.append({ "pos": Vector2(_area.position.x - 400.0 if right else _area.end.x + 400.0, y), "vel": Vector2(55.0 if right else -55.0, 0.0),
		"t": 0.0, "layer": 0, "sprite": 0, "life": 999.0, "phase": 0.0, "size": -1.0 if not right else 1.0 })

func _draw_layer(layer: int) -> void:
	var node := _back if layer == 0 else _front
	var off: Vector2 = (_tilt * DEPTH[layer]).round()
	for p in _parts:
		if int(p["layer"]) != layer:
			continue
		var tex: Texture2D = _sprites[int(p["sprite"]) % _sprites.size()]
		var a := 1.0
		match kind:
			"fireflies":
				a = (0.15 + 0.85 * _night) * (0.55 + 0.45 * sin(float(p["t"]) * 3.0 + float(p["phase"])))
				a *= clampf(float(p["life"]) / 2.0, 0.0, 1.0)
			"wisps":
				a = (0.35 + 0.55 * _night) * clampf(float(p["life"]) / 3.0, 0.0, 1.0) * clampf(float(p["t"]) / 3.0, 0.0, 1.0)
			"fireworks":
				a = clampf(float(p["life"]) / 0.6, 0.0, 1.0)
			"sky_lanterns":
				a = 0.75 + 0.25 * _night
			"snow":
				a = 0.9 if layer == 1 else 0.7
		var sz := tex.get_size() * PX
		var flip := (kind == "sky_fish" and (p["vel"] as Vector2).x < 0.0) or float(p["size"]) < 0.0
		var flutter := (kind in ["petals", "maple"]) and sin(float(p["t"]) * 4.0 + float(p["phase"])) < 0.0
		var at: Vector2 = (p["pos"] as Vector2 + off - sz / 2.0).round()
		var rect := Rect2(at, sz)
		if flip:
			rect = Rect2(at + Vector2(sz.x, 0.0), Vector2(-sz.x, sz.y))
		if flutter:                                         # (turning: seen thinner for a moment)
			rect = Rect2(at + Vector2(0.0, sz.y * 0.25), Vector2(rect.size.x, sz.y * 0.5))
		node.draw_texture_rect(tex, rect, false, Color(1, 1, 1, a))

# ------------------------------------------------------------------ the sprites (placeholders)

static func _load_sprites(k: String) -> Array[Texture2D]:
	var out: Array[Texture2D] = []
	if k == "":
		return out
	for i in 8:
		var p := "%s%s_%d.png" % [SKY_ART, k, i]
		if ResourceLoader.exists(p):
			out.append(load(p))
	if not out.is_empty() or k == "dragon":
		return out                       # (the dragon only with its drawing)
	for rows in _placeholder_rows(k):
		out.append(_texture(rows))
	return out

## A tiny pixel sprite from rows of letters (each a colour, "." clear)
static func _texture(rows: Array) -> Texture2D:
	var pal := { "p": Color8(246, 190, 204), "P": Color8(226, 142, 168), "w": Color8(255, 246, 250),
		"r": Color8(214, 84, 52), "o": Color8(236, 138, 56), "y": Color8(240, 196, 84), "d": Color8(122, 54, 40),
		"s": Color8(250, 252, 255), "S": Color8(214, 226, 240), "g": Color8(232, 250, 150), "G": Color8(176, 220, 96),
		"b": Color8(214, 236, 255), "B": Color8(140, 196, 250), "c": Color8(96, 150, 230),
		"l": Color8(248, 208, 128), "L": Color8(232, 128, 72), "k": Color8(84, 46, 40),
		"f": Color8(246, 120, 64), "F": Color8(252, 236, 220), "e": Color8(40, 24, 24),
		"1": Color8(255, 140, 150), "2": Color8(160, 220, 255), "3": Color8(255, 226, 120), "4": Color8(190, 255, 170) }
	var h := rows.size()
	var w := 0
	for r in rows:
		w = maxi(w, (r as String).length())
	var img := Image.create(w, h, false, Image.FORMAT_RGBA8)
	for y in h:
		var r: String = rows[y]
		for x in r.length():
			var ch := r[x]
			if pal.has(ch):
				img.set_pixel(x, y, pal[ch])
	return ImageTexture.create_from_image(img)

static func _placeholder_rows(k: String) -> Array:
	match k:
		"petals":
			return [[".pp", "pPp", "pp."], ["pp.", "pPp", ".pw"], [".p.", "pPp", ".p."]]
		"maple":
			return [[".r.r.", "rrorr", ".rdr.", "..d.."], [".o.o.", "ooyoo", ".odo.", "..d.."], [".y.y.", "yyoyy", ".ydy.", "..d.."]]
		"snow":
			return [["s"], [".S.", "SsS", ".S."], ["s."]]
		"fireflies":
			return [[".G.", "GgG", ".G."], ["g"]]
		"wisps":
			return [[".b..", "bBb.", "bBBb", ".bBc", "..bc", "...c"], ["..b.", ".bBb", "bBBb", "cBb.", "cb..", "c..."]]
		"sky_lanterns":
			return [[".kk.", "lLLl", "lllL", "lLLl", ".kk."]]
		"sky_fish":
			return [["..ff.F", ".fffFF", "efffff", ".fffFF", "..ff.F"]]
		"fireworks":
			return [["11", "11"], ["22", "22"], ["33", "33"], ["44", "44"]]
	return []

## A card's picture for a particle drift: a few of its sprites on a sky swatch (the menu)
static func preview(k: String, sky: Color) -> Texture2D:
	var sprites := _load_sprites("petals" if k == "seasons" else k)    # (Seasons: its spring)
	var img := Image.create(48, 48, false, Image.FORMAT_RGBA8)
	img.fill(sky)
	if sprites.is_empty():
		return ImageTexture.create_from_image(img)
	var spots := [Vector2i(8, 7), Vector2i(30, 12), Vector2i(16, 26), Vector2i(36, 32), Vector2i(6, 38)]
	for i in spots.size():
		var s := sprites[i % sprites.size()].get_image()
		img.blend_rect(s, Rect2i(Vector2i.ZERO, s.get_size()), spots[i])
	return ImageTexture.create_from_image(img)
