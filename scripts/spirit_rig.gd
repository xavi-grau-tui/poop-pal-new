extends Node2D
## A spirit's animation, in the drink aura's style (the user, 2026-11-06): every frame redrawn on the
## spirit's own pixel grid (its 56 x 56 art, 1 art px = 2 of the pal's texels) and played stepped at
## 11 fps. PROTOTYPE: the art and rig come from tools/art/spirit_rig.py (docs/mockups/spirits/rig_proto).
##
## What it does:
##   breathing    a slow stretch-and-squash, rows and columns added or dropped below the face
##   blink        the eyes shut for two frames now and then (from the rig's eye boxes)
##   hop          anticipation squash, stretch up, hang, land with a squash, settle
##   wobble       (daruma-like) the body leans from its base side to side, settling
##   bolt         the bolt part flickers and strikes: white-hot with a glow, gone, back; a rumble
##   flame        a small pixel flame over the wick, its tip swaying and its core flickering
##
##   var rig := preload("res://scripts/spirit_rig.gd").new(); pal.add_child(rig)
##   rig.setup("ladyluck", dir, rig_json["ladyluck"])     # pal = the Poop AnimatedSprite2D

const FPS := 11.0
const S := 56                          # the art canvas
const W := 72                          # the working canvas (room for hops, leans, flames)
const H := 72
const OFF := Vector2i(8, 14)           # where the 56 canvas sits in it
const BASE := 54                       # the art canvas row the spirit stands on
const OUTLINE := Color8(34, 16, 26)
const FLAME := [Color8(232, 98, 40), Color8(248, 170, 52), Color8(255, 240, 170)]
const BREATH := [0, 0, 1, 1, 1, 1, 1, 0, 0, 0, 0, -1, -1, -1, -1, -1, 0, 0, 0, 0]

var manual := false                    # (QA: step() by hand)
var demo := false                      # (QA: everything happens soon)
var sprite := Sprite2D.new()
var _tex: ImageTexture
var _open := PackedByteArray()
var _closed := PackedByteArray()
var _bolt := PackedByteArray()
var _bolt_hot := PackedByteArray()
var _flames: Array = []                # [w, h, PackedByteArray]
var _anchor := Vector2i(-1, -1)        # the flame's foot (the wick's top), art px
var _wobbles := false
var _top := 0
var _bottom := 0
var _cx := 28
var _t := 0.0
var _tick := 0
var _act: Array = []                   # queued Vector3i(level, lift, shear) of a hop or a wobble
var _next_act := 60
var _blinks: Array = []
var _next_blink := 30
var _bolt_seq: Array = []
var _next_bolt := 20
var _flame_i := 0
var _rng := RandomNumberGenerator.new()

func setup(id: String, dir: String, rig: Dictionary, baseline_y := 62.0) -> void:
	_open = _load(dir.path_join(id + "_body.png"))
	_closed = _load(dir.path_join(id + "_closed.png"))
	var parts: Dictionary = rig.get("parts", {})
	if parts.has("bolt"):
		_bolt = _load(dir.path_join(id + "_bolt.png"))
		_bolt_hot = _hot(_bolt)
	if parts.has("flame"):
		var a: Array = parts["flame"]["anchor"]
		_anchor = Vector2i(int(a[0]), int(a[1]))
		_build_flames()
	_wobbles = rig.get("wobble", false)
	_bounds()
	if demo:
		_next_blink = 6
		_next_bolt = 4
		_next_act = 14
	sprite.centered = false
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	sprite.scale = Vector2(2, 2)
	# (the art canvas's baseline row lands on the old pals' baseline, its centre on the pal's centre)
	sprite.position = Vector2(-(OFF.x + S / 2) * 2, baseline_y - (OFF.y + BASE + 1) * 2)
	add_child(sprite)
	_render(0, 0, 0, false, 1)

func _load(path: String) -> PackedByteArray:
	var img := Image.load_from_file(ProjectSettings.globalize_path(path))
	img.convert(Image.FORMAT_RGBA8)
	return img.get_data()

func _bounds() -> void:
	_top = S
	_bottom = 0
	var x0 := S
	var x1 := 0
	for y in S:
		for x in S:
			if _open[(y * S + x) * 4 + 3] > 0:
				_top = mini(_top, y)
				_bottom = maxi(_bottom, y)
				x0 = mini(x0, x)
				x1 = maxi(x1, x)
	_cx = (x0 + x1) / 2

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
	var level: int = BREATH[_tick % BREATH.size()]
	var lift := 0
	var shear := 0
	if not _act.is_empty():
		var a: Vector3i = _act.pop_front()
		level = a.x
		lift = a.y
		shear = a.z
	else:
		_next_act -= 1
		if _next_act <= 0:
			_next_act = _rng.randi_range(24, 40) if demo else _rng.randi_range(70, 130)
			_act = _wobble_seq() if _wobbles and _rng.randf() < 0.6 else _hop_seq()
	var closed := false
	if not _blinks.is_empty():
		closed = _blinks.pop_front()
	else:
		_next_blink -= 1
		if _next_blink <= 0:
			_next_blink = _rng.randi_range(18, 34) if demo else _rng.randi_range(28, 60)
			_blinks = [true, true] if _rng.randf() > 0.25 else [true, true, false, true, true]
			closed = _blinks.pop_front()
	var bolt := 1
	if not _bolt.is_empty():
		if not _bolt_seq.is_empty():
			bolt = _bolt_seq.pop_front()
		else:
			_next_bolt -= 1
			if _next_bolt <= 0:
				_next_bolt = _rng.randi_range(12, 26) if demo else _rng.randi_range(16, 40)
				_bolt_seq = [2, 2, 1, 0, 0, 2, 1, 1, 0, 1, 1]
			elif _rng.randf() < 0.04:
				bolt = 0                                   # (a flicker now and then)
		if bolt == 2:
			shear += 1 if _tick % 2 == 0 else -1           # (the strike's rumble)
	if not _flames.is_empty():
		_flame_i = (_flame_i + 1) % _flames.size()
	_render(level, lift, shear, closed, bolt)

func _hop_seq() -> Array:
	return [Vector3i(-1, 0, 0), Vector3i(-2, 0, 0), Vector3i(2, 2, 0), Vector3i(1, 5, 0), Vector3i(0, 7, 0),
		Vector3i(0, 8, 0), Vector3i(0, 7, 0), Vector3i(1, 5, 0), Vector3i(1, 2, 0), Vector3i(-2, 0, 0),
		Vector3i(-1, 0, 0), Vector3i(0, 0, 0)]

func _wobble_seq() -> Array:
	var out := []
	for s in [2, 4, 5, 4, 2, 0, -3, -4, -3, -1, 1, 2, 1, 0, -1, 0]:
		out.append(Vector3i(0, 0, s))
	return out

# ------------------------------------------------------------------ DRAWING
func _render(level: int, lift: int, shear: int, closed: bool, bolt: int) -> void:
	var src: PackedByteArray = (_closed if closed else _open).duplicate()
	if bolt > 0 and not _bolt.is_empty():
		_over(src, _bolt_hot if bolt == 2 else _bolt)
	if not _flames.is_empty():
		var f: Array = _flames[_flame_i]
		_over_at(src, f[2], f[0], f[1], _anchor.x - f[0] / 2, _anchor.y - f[1])
	# stretch (+) and squash (-): rows doubled or dropped low in the body (under the face), the
	# middle column dropped or doubled; the base stays on its row, the middle on its column
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
	var img := Image.create_from_data(W, H, false, Image.FORMAT_RGBA8, out)
	if _tex == null:
		_tex = ImageTexture.create_from_image(img)
		sprite.texture = _tex
	else:
		_tex.update(img)

func _over(dst: PackedByteArray, src: PackedByteArray) -> void:
	for i in range(0, src.size(), 4):
		if src[i + 3] > 0:
			dst[i] = src[i]
			dst[i + 1] = src[i + 1]
			dst[i + 2] = src[i + 2]
			dst[i + 3] = 255

func _over_at(dst: PackedByteArray, src: PackedByteArray, w: int, h: int, x0: int, y0: int) -> void:
	for y in h:
		for x in w:
			var si := (y * w + x) * 4
			if src[si + 3] == 0:
				continue
			var tx := x0 + x
			var ty := y0 + y
			if tx < 0 or ty < 0 or tx >= S or ty >= S:
				continue
			var ti := (ty * S + tx) * 4
			dst[ti] = src[si]
			dst[ti + 1] = src[si + 1]
			dst[ti + 2] = src[si + 2]
			dst[ti + 3] = 255

## The bolt white-hot: its colours near white, its outline gold, a pale glow round it.
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

## Eight frames of a small flame: a teardrop whose tip sways and whose height breathes, in three
## tones (deep edge, flame, pale core), with the sprites' dark outline round its top and sides.
func _build_flames() -> void:
	var fw := 9
	var fh := 11
	var tips := [1, 0, 1, 2, 1, 0, 2, 1]
	for f in 8:
		var inside := []
		var tone := []
		inside.resize(fw * fh)
		tone.resize(fw * fh)
		var tip: int = tips[f] + 1
		for y in fh:
			var t := clampf(float(y - tip) / float(fh - 1 - tip), 0.0, 1.0)
			var sway := int(round(sin(f * 0.8 + y * 0.6) * (1.0 - t)))
			var c := 4.0 + sway
			var hw := 2.3 * pow(sin(t * PI * 0.75), 0.8)
			for x in fw:
				var d := absf(x - c)
				var ins := y >= tip and d <= hw + 0.25
				inside[y * fw + x] = ins
				if ins:
					var dn := d / maxf(hw, 0.5)
					var k := 0
					if t > 0.5 and dn < 0.45 and (f + y) % 4 != 0:
						k = 2
					elif dn < 0.8 or t < 0.3:
						k = 1
					tone[y * fw + x] = k
		var px := PackedByteArray()
		px.resize(fw * fh * 4)
		for y in fh:
			for x in fw:
				var i := (y * fw + x) * 4
				var col := Color(0, 0, 0, 0)
				if inside[y * fw + x]:
					col = FLAME[tone[y * fw + x]]
				else:
					for d in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
						var nx: int = x + d.x
						var ny: int = y + d.y
						if nx >= 0 and ny >= 0 and nx < fw and ny < fh and inside[ny * fw + nx] and y < fh - 1:
							col = OUTLINE
							break
				if col.a > 0.0:
					px[i] = col.r8
					px[i + 1] = col.g8
					px[i + 2] = col.b8
					px[i + 3] = 255
		_flames.append([fw, fh, px])
