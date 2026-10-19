extends RefCounted
class_name GameFx
## The games' shared look, so every minigame feels like part of one toy box (the user, 2026-10-19:
## "the same suite"; docs/ideas_roadmap.md, "The games' look"). The race games' rules for all of
## them: hard pixels on the 4 px grid, the dark outline on the play pieces only (never on the
## background), lit from the top left, raised pieces with a side face and a drop shadow. Over that,
## Pal Prix 2177's light and motion, used sparingly for the moments that matter: glows (a soft
## halo, a bright core, a white-hot pixel), sparks with tails, bursts, shockwave rings, light
## ribbons, and a shake with a tiny freeze on the big hits. Words only for the rare big moments:
## the sparks, the burst and the chime say the rest (2177: "a bit annoying" when words popped up).
##
## The HUD is the race games' band across the top (HUD_BAND): the level on the left, the game's
## measure in the middle, the three stars (each dims the moment it's lost), the game's own things
## on the right, the boost at the far right; the band in the game's own material, its foot line in
## the world's accent.

const OUTLINE := Color8(40, 30, 40)
const HUD_BAND := Rect2(27, 26, 896, 66)
## A 2x2 ordered dither: where one colour step meets the next (the background's soft edges)
const DITHER := [[0.125, 0.625], [0.875, 0.375]]

static func snap(p: Vector2) -> Vector2:
	return p.snapped(Vector2(4, 4))

## True where a soft edge at `f` (0..1 of the way into the next step) is already the next one
static func dithered(f: float, x: int, y: int) -> bool:
	return DITHER[posmod(y, 2)][posmod(x, 2)] < f

## 0..1 onto a palette in steps, dithered across the last part of each step (no outlines)
static func steps(v: float, palette: Array, x: int, y: int, edge := 0.75) -> Color:
	var f := clampf(v, 0.0, 0.999) * palette.size()
	var band := int(f)
	var into := f - band
	if into > edge and dithered((into - edge) / (1.0 - edge), x, y):
		band += 1
	return palette[clampi(band, 0, palette.size() - 1)]

## A filled disc on the 4 px grid (rows of 4 px)
static func disc(ci: CanvasItem, c: Vector2, r: float, col: Color) -> void:
	var y := -r
	while y <= r:
		var half := sqrt(maxf(0.0, r * r - y * y))
		ci.draw_rect(Rect2(snap(c + Vector2(-half, y)), Vector2(maxf(4.0, roundf(half * 2.0 / 4.0) * 4.0), 4)), col)
		y += 4.0

## A point of light: a soft halo, the colour's core, a white-hot middle (2177's lights)
static func glow(ci: CanvasItem, p: Vector2, s: float, col: Color, a := 1.0) -> void:
	var q := snap(p)
	var h := s + 8.0
	ci.draw_rect(Rect2(q - Vector2(h, h) / 2.0, Vector2(h, h)), Color(col.r, col.g, col.b, 0.2 * a))
	ci.draw_rect(Rect2(q - Vector2(s, s) / 2.0, Vector2(s, s)), Color(col.r, col.g, col.b, a))
	if s >= 8.0:
		ci.draw_rect(Rect2(q - Vector2(2, 2), Vector2(4, 4)), Color(1, 1, 1, a))

## A ring of light round `c` (a shield, a warning, a target): `n` points of light, `s` px each
static func light_ring(ci: CanvasItem, c: Vector2, r: float, col: Color, n := 24, s := 8.0, a := 1.0, phase := 0.0) -> void:
	for k in n:
		var p := c + Vector2.from_angle(phase + k * TAU / n) * r
		var q := snap(p)
		ci.draw_rect(Rect2(q - Vector2(s + 6, s + 6) / 2.0, Vector2(s + 6, s + 6)), Color(col.r, col.g, col.b, 0.18 * a))
		ci.draw_rect(Rect2(q - Vector2(s, s) / 2.0, Vector2(s, s)), Color(col.r, col.g, col.b, a))

## A word in the games' pixel font with the dark outline all round (4 px), centred on `at`
static func outlined_text(ci: CanvasItem, font: Font, at: Vector2, text: String, size: int, col: Color, ink := OUTLINE) -> void:
	if not font:
		return
	var w := font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, size).x
	var p := snap(at - Vector2(w / 2.0, -size * 0.35))
	var o := Color(ink.r, ink.g, ink.b, col.a)
	for d in [Vector2(-4, 0), Vector2(4, 0), Vector2(0, -4), Vector2(0, 4), Vector2(-4, -4), Vector2(4, 4), Vector2(-4, 4), Vector2(4, -4)]:
		ci.draw_string(font, p + d, text, HORIZONTAL_ALIGNMENT_LEFT, -1, size, o)
	ci.draw_string(font, p, text, HORIZONTAL_ALIGNMENT_LEFT, -1, size, col)

# ================================================================== THE HUD BAND

## The band across the top (the race games' HUD): its face, its foot line, and a bar along the foot
## (a timer, a charge...: set its size.x and colour). Returns { band, foot, bar }
static func build_band(parent: Node, face: Color, foot: Color) -> Dictionary:
	var band := ColorRect.new()
	band.color = face
	band.position = HUD_BAND.position
	band.size = HUD_BAND.size
	parent.add_child(band)
	var line := ColorRect.new()
	line.color = foot
	line.position = Vector2(HUD_BAND.position.x, HUD_BAND.end.y - 8)
	line.size = Vector2(HUD_BAND.size.x, 8)
	parent.add_child(line)
	var bar := ColorRect.new()
	bar.position = line.position
	bar.size = Vector2(0, 8)
	parent.add_child(bar)
	return { "band": band, "foot": line, "bar": bar }

## The three stars on the band (from `at`, 40 px apart), lit; set_stars dims and lights them
static func build_stars(parent: Node, at: Vector2) -> Array[TextureRect]:
	var out: Array[TextureRect] = []
	for i in 3:
		var st := TextureRect.new()
		st.texture = UiArt.star(true)
		st.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		st.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		st.size = Vector2(36, 36)
		st.pivot_offset = st.size / 2.0
		st.position = at + Vector2(i * 40, 0)
		parent.add_child(st)
		out.append(st)
	return out

## Shows `now` stars of three: one lost dims with a little pop (the race games' stars). Returns `now`
static func set_stars(stars: Array[TextureRect], shown: int, now: int) -> int:
	if now < shown:
		for i in range(now, shown):
			var st := stars[i]
			st.texture = UiArt.star(false)
			var tw := st.create_tween()
			tw.tween_property(st, "scale", Vector2(1.4, 1.4), 0.08)
			tw.tween_property(st, "scale", Vector2.ONE, 0.2)
	elif now > shown:
		for i in range(shown, now):
			var st2 := stars[i]
			st2.texture = UiArt.star(true)
			var tw2 := st2.create_tween()
			tw2.tween_property(st2, "scale", Vector2(1.5, 1.5), 0.08)
			tw2.tween_property(st2, "scale", Vector2.ONE, 0.2)
	return now

## A label in the games' pixel font
static func label(parent: Node, font: Font, pos: Vector2, sz: Vector2, font_size: int, align: int, color: Color) -> Label:
	var l := Label.new()
	l.position = pos
	l.size = sz
	l.horizontal_alignment = align
	l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	if font:
		l.add_theme_font_override("font", font)
	l.add_theme_font_size_override("font_size", font_size)
	l.add_theme_color_override("font_color", color)
	parent.add_child(l)
	return l

## The big word across the middle ("GO!", "WIN!", a world's name): the race games' banner
static func banner(parent: Node, font: Font, ink: Color, y := 474.0) -> Label:
	var b := label(parent, font, Vector2(0, y - 70), Vector2(950, 140), 72, HORIZONTAL_ALIGNMENT_CENTER, Color(1, 0.97, 0.9))
	b.add_theme_color_override("font_outline_color", ink)
	b.add_theme_constant_override("outline_size", 16)
	b.modulate.a = 0.0
	return b

## Pops the banner up: a quick grow in, held, faded out
static func show_banner(b: Label, text: String, hold: float) -> void:
	b.text = text
	b.pivot_offset = b.size / 2.0
	b.scale = Vector2(0.8, 0.8)
	var t := b.create_tween()
	t.tween_property(b, "modulate:a", 1.0, 0.12)
	t.parallel().tween_property(b, "scale", Vector2.ONE, 0.18).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	t.tween_interval(hold)
	t.tween_property(b, "modulate:a", 0.0, 0.3)

# ================================================================== BURSTS

## Everything that flies off a moment and fades: sparks with tails, a white puff, gold sparkles,
## a shockwave ring, dust, a flash, light ribbons behind a fast thing, confetti. One node per game
## (over its pieces); everything on the 4 px grid
class Burst extends Node2D:
	enum { SPARK, PUFF, SPARKLE, RING, DUST, FLASH, RIBBON, CONFETTI, SCUFF }
	var marks: Array = []                 # [position, age, kind, velocity, colour, life, size]
	func sparks(at: Vector2, n: int, cols: Array, speed := 1.0) -> void:
		for k in n:
			var v := Vector2.from_angle(randf() * TAU) * randf_range(160.0, 420.0) * speed
			marks.append([at, 0.0, SPARK, v, cols[k % cols.size()], randf_range(0.2, 0.38), 4.0])
	## sparks thrown one way (a spray off a scrape or a hit), within `spread` rad of `dir`
	func spray(at: Vector2, dir: Vector2, n: int, cols: Array, spread := 0.9, speed := 1.0) -> void:
		for k in n:
			var v := dir.normalized().rotated(randf_range(-spread, spread)) * randf_range(180.0, 460.0) * speed
			marks.append([at, 0.0, SPARK, v, cols[k % cols.size()], randf_range(0.18, 0.34), 4.0])
	func puff(at: Vector2, n := 10, col := Color(1, 1, 1), reach := 1.0) -> void:
		for k in n:
			var a := TAU * k / n + randf() * 0.5
			marks.append([at, 0.0, PUFF, Vector2.from_angle(a) * randf_range(90.0, 200.0) * reach, col, randf_range(0.3, 0.5), 8.0])
	func sparkle(at: Vector2, n := 8, col := Color8(255, 236, 150), reach := 1.0) -> void:
		for k in n:
			marks.append([at, 0.0, SPARKLE, Vector2.from_angle(randf() * TAU) * randf_range(140.0, 320.0) * reach, col, 0.5, 4.0])
	## a shockwave: a ring of points spreading from r0 to r1 and fading
	func ring(at: Vector2, col: Color, r0 := 20.0, r1 := 100.0, life := 0.35, size := 8.0) -> void:
		marks.append([at, 0.0, RING, Vector2(r0, r1), col, life, size])
	func dust(at: Vector2, n := 8, col := Color8(200, 190, 170), reach := 1.0) -> void:
		for k in n:
			var a := TAU * k / n + randf() * 0.6
			marks.append([at, 0.0, DUST, Vector2.from_angle(a) * randf_range(50.0, 130.0) * reach, col, randf_range(0.4, 0.7), 4.0])
	func flash(at: Vector2, r: float, col := Color(1, 1, 1), life := 0.14) -> void:
		marks.append([at, 0.0, FLASH, Vector2.ZERO, col, life, r])
	## a light ribbon point behind something fast (call it every frame it moves): white, then its colour
	func ribbon(at: Vector2, col: Color, life := 0.3, size := 8.0) -> void:
		marks.append([at, 0.0, RIBBON, Vector2.ZERO, col, life, size])
	func confetti(at: Vector2, n: int, cols: Array) -> void:
		for k in n:
			var v := Vector2(randf_range(-1.0, 1.0), randf_range(-1.6, -0.5)) * randf_range(220.0, 460.0)
			marks.append([at, 0.0, CONFETTI, v, cols[k % cols.size()], randf_range(0.9, 1.4), 8.0 if k % 3 else 4.0])
	## a mark left on the ground (a scrape): dark, it fades slowly
	func scuff(at: Vector2, col: Color, life := 2.5) -> void:
		marks.append([at, 0.0, SCUFF, Vector2.ZERO, col, life, 4.0])
	func _process(delta: float) -> void:
		for m in marks:
			m[1] += delta
			match int(m[2]):
				SPARK, PUFF, SPARKLE, DUST:
					m[0] += (m[3] as Vector2) * delta
					m[3] = (m[3] as Vector2) * maxf(0.0, 1.0 - delta * (3.5 if m[2] != DUST else 4.5))
				CONFETTI:
					m[0] += (m[3] as Vector2) * delta
					m[3] = (m[3] as Vector2) * maxf(0.0, 1.0 - delta * 1.6) + Vector2(sin(m[1] * 9.0 + m[0].x) * 30.0, 520.0) * delta
		marks = marks.filter(func(m): return m[1] < m[5])
		queue_redraw()
	func _draw() -> void:
		for m in marks:
			var f: float = m[1] / m[5]
			var p: Vector2 = GameFx.snap(m[0])
			var c: Color = m[4]
			var s: float = m[6]
			match int(m[2]):
				SPARK:
					var c1 := Color(1, 1, 1) if f < 0.25 else c
					c1.a = 1.0 - f
					draw_rect(Rect2(p - Vector2(2, 2), Vector2(4, 4)), c1)
					var back := (m[3] as Vector2).normalized()
					for k in 2:
						var q := GameFx.snap((m[0] as Vector2) - back * 6.0 * (k + 1))
						draw_rect(Rect2(q - Vector2(2, 2), Vector2(4, 4)), Color(c.r, c.g, c.b, (0.55 - 0.2 * k) * (1.0 - f)))
				PUFF:
					var s5 := s + 12.0 * f
					s5 = roundf(s5 / 4.0) * 4.0
					draw_rect(Rect2(p - Vector2(s5, s5) / 2.0, Vector2(s5, s5)), Color(c.r, c.g, c.b, 0.85 * (1.0 - f)))
				SPARKLE:
					var on := fposmod(m[1] * 14.0, 1.0) < 0.6
					if on:
						draw_rect(Rect2(p - Vector2(2, 2), Vector2(4, 4)), Color(c.r, c.g, c.b, 1.0 - f))
						if f < 0.5:
							draw_rect(Rect2(p - Vector2(6, 2), Vector2(12, 4)), Color(1, 1, 1, 0.5 * (1.0 - f)))
							draw_rect(Rect2(p - Vector2(2, 6), Vector2(4, 12)), Color(1, 1, 1, 0.5 * (1.0 - f)))
				RING:
					var rr: Vector2 = m[3]
					var r := lerpf(rr.x, rr.y, 1.0 - (1.0 - f) * (1.0 - f))
					var n := clampi(int(r * TAU / 18.0), 12, 48)
					GameFx.light_ring(self, m[0], r, c, n, s * (1.0 - f * 0.5), 1.0 - f)
				DUST:
					var s2 := 4.0 if f < 0.4 else 8.0
					draw_rect(Rect2(p - Vector2(s2, s2) / 2.0, Vector2(s2, s2)), Color(c.r, c.g, c.b, 0.7 * (1.0 - f)))
				FLASH:
					GameFx.disc(self, m[0], s * (0.7 + 0.3 * f), Color(c.r, c.g, c.b, 0.75 * (1.0 - f)))
				RIBBON:
					var cr := Color(1, 1, 1) if f < 0.18 else c
					cr.a = 0.8 * (1.0 - f)
					var sr := roundf(s * (1.0 - 0.5 * f) / 4.0) * 4.0
					draw_rect(Rect2(p - Vector2(sr, sr) / 2.0, Vector2(sr, sr)), cr)
				CONFETTI:
					var flip := fposmod(m[1] * 8.0 + float(m[0].y) * 0.01, 1.0) < 0.5
					draw_rect(Rect2(p, Vector2(s, 4.0 if flip else s)), Color(c.r, c.g, c.b, 1.0 if f < 0.7 else (1.0 - f) / 0.3))
				SCUFF:
					draw_rect(Rect2(p - Vector2(2, 2), Vector2(4, 4)), Color(c.r, c.g, c.b, c.a * (1.0 - f)))
