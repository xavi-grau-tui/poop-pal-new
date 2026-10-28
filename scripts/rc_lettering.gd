class_name RcLettering
extends Node2D
## RC Prix's race messages ("LAP 2", "GO!", ...) in the designer's racing pixel font (round 17b:
## textures/minigames/rcprix/font, one PNG per character, 24 px tall), the letters popping in one by
## one, then floating up and fading out one by one (the user, 2026-10-27). say() answers false when the
## font lacks a character of the text: the caller shows it its old way.

const DIR := "res://textures/minigames/rcprix/font/"
const NAMES := { "!": "excl", "?": "quest", ".": "dot", ",": "comma", ":": "colon", "/": "slash", "-": "dash", "'": "apos" }
const PX := 4.0                       # screen px per glyph px
const GAP := 2                        # glyph px between letters
const SPACE := 10                     # a space's width, glyph px
const STAGGER := 0.045                # one letter after another (s)
const POP := 0.16                     # each letter's pop in (s)
const OUT := 0.22                     # ...and its float out (s)

var max_width := 0.0                  # the widest a message may be (screen px); a longer one is drawn smaller

var _cache := {}
var _letters: Array[Sprite2D] = []
var _tween: Tween

## The glyph for a character, or null (none drawn)
func glyph(c: String) -> Texture2D:
	var name: String = NAMES.get(c, c.to_upper())
	if not _cache.has(name):
		var path := DIR + name + ".png"
		_cache[name] = load(path) if ResourceLoader.exists(path) else null
	return _cache[name]

## Can the font write this text?
func can_say(text: String) -> bool:
	for c in text:
		if c != " " and glyph(c) == null:
			return false
	return true

## A line's width in glyph px
func _width(line: String) -> float:
	var width := 0.0
	for c in line:
		var tex: Texture2D = null if c == " " else glyph(c)
		width += (float(SPACE) if tex == null else float(tex.get_width())) + GAP
	return maxf(0.0, width - GAP)

## Shows the text centred on this node for `hold` seconds; false (nothing shown) if the font can't write it
func say(text: String, hold: float) -> bool:
	if not can_say(text):
		return false
	for l in _letters:
		l.queue_free()
	_letters.clear()
	if _tween:
		_tween.kill()
	# (the user, 2026-10-28: "Out of lives!" ran off the screen) too wide: on two lines, split at the space
	# nearest the middle; still too wide: smaller, by whole steps (crisp pixels)
	var lines: Array = [text]
	if max_width > 0.0 and _width(text) * PX > max_width and text.contains(" "):
		var best := -1
		for i in text.length():
			if text[i] == " " and (best < 0 or absi(i - text.length() / 2) < absi(best - text.length() / 2)):
				best = i
		lines = [text.substr(0, best), text.substr(best + 1)]
	var widest := 0.0
	for line in lines:
		widest = maxf(widest, _width(line))
	var k := PX
	while max_width > 0.0 and widest * k > max_width and k > 1.0:
		k -= 1.0
	var line_h := 26.0 * k
	for li in lines.size():
		var y := (li - (lines.size() - 1) / 2.0) * line_h
		var x := -_width(lines[li]) / 2.0
		for c in lines[li]:
			var tex: Texture2D = null if c == " " else glyph(c)
			var w: float = float(SPACE) if tex == null else float(tex.get_width())
			if tex:
				var s := Sprite2D.new()
				s.texture = tex
				s.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
				s.position = Vector2((x + w / 2.0) * k, y)
				s.scale = Vector2.ZERO
				add_child(s)
				_letters.append(s)
			x += w + GAP
	_tween = create_tween().set_parallel(true)
	var n := _letters.size()
	for i in n:                                    # in: each letter pops up from nothing, a little too big, then settles
		var s := _letters[i]
		_tween.tween_property(s, "scale", Vector2.ONE * k * 1.25, POP * 0.6).set_delay(i * STAGGER).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		_tween.tween_property(s, "scale", Vector2.ONE * k, POP * 0.4).set_delay(i * STAGGER + POP * 0.6)
	var out_at := (n - 1) * STAGGER + POP + hold
	for i in n:                                    # out: each letter floats up and fades, one after another
		var s := _letters[i]
		var at := out_at + i * STAGGER
		_tween.tween_property(s, "position:y", s.position.y - 10.0 * k, OUT).set_delay(at).set_ease(Tween.EASE_IN)
		_tween.tween_property(s, "modulate:a", 0.0, OUT).set_delay(at)
	return true
