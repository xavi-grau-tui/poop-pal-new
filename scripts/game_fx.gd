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

# ================================================================== A PLACE'S LIVING LIGHT

## A place's living light (drawn added on: give it an ADD CanvasItemMaterial; over the play
## pieces, so they're lit too): one kind per place. Top Spin's: "tatami" (dust in the morning sun),
## "veranda" (flecks of sun through the leaves), "lacquer" (gold glints, a lamp's pool breathing),
## "bathroom" (light rippling on the water), "workshop" (a lamp swaying on its cord, dust in it),
## "festival" (lanterns flickering, the fireworks' flashes). Tilt Maze's: "wood" (dust drifting
## in the window's light), "tiles" (soap bubbles rising, catching the light), "gut" (glowing
## spores floating, a slow pulse), "sewer" (drips falling from above, rings where they land),
## "factory" (a lamp's flicker, sparks dropping from a weld), "space" (stars twinkling, now and
## then a shooting star). Splash Hoops' (its scenes): "lagoon", "reef" (light glittering under the
## surface, bubbles rising), "sun" (a warmer glitter), "rain" (bubbles), "night" (plankton
## glowing as it drifts), "deep" (marine snow drifting down). `view`: where it draws (the play area
## by default)
class Ambience extends Node2D:
	var kind := ""
	var c := Vector2.ZERO
	var r := 370.0
	var t := 0.0
	var motes: Array = []             # [position, velocity, phase]
	var flash := 0.0
	var flash_col := Color(1, 1, 1)
	var flash_at := Vector2.ZERO
	var next_flash := 4.0
	var view := Rect2(0, 0, 950, 948)
	var W := 950.0
	var H := 948.0
	func setup(k: String, centre: Vector2, radius: float, area := Rect2(0, 0, 950, 948)) -> void:
		kind = k
		c = centre
		r = radius
		view = area
		W = area.end.x
		H = area.end.y
		motes.clear()
		var n: int = { "tatami": 30, "veranda": 18, "lacquer": 12, "workshop": 22, "festival": 16,
			"wood": 24, "tiles": 14, "gut": 18, "sewer": 6, "factory": 10, "space": 40,
			"lagoon": 16, "sun": 16, "reef": 18, "rain": 10, "night": 26, "deep": 30 }.get(k, 0)
		for i in n:
			var vel := Vector2(randf_range(-4.0, 10.0), randf_range(-16.0, -4.0))
			match k:
				"tiles":
					vel = Vector2(randf_range(-6.0, 6.0), randf_range(-26.0, -14.0))      # (bubbles rise)
				"gut":
					vel = Vector2(randf_range(-8.0, 8.0), randf_range(-8.0, 8.0))         # (spores drift every way)
				"sewer":
					vel = Vector2(0, randf_range(260.0, 320.0))                           # (drips fall)
				"factory":
					vel = Vector2(randf_range(-30.0, 30.0), randf_range(80.0, 160.0))
				"space":
					vel = Vector2.ZERO
				"lagoon", "sun", "reef", "rain":
					vel = Vector2(randf_range(-6.0, 6.0), randf_range(-44.0, -26.0))     # (bubbles rising)
				"night":
					vel = Vector2(randf_range(-8.0, 8.0), randf_range(-8.0, 8.0))
				"deep":
					vel = Vector2(randf_range(-4.0, 4.0), randf_range(10.0, 18.0))        # (marine snow)
			motes.append([Vector2(randf_range(view.position.x, W), randf_range(view.position.y, H)), vel, randf() * TAU])
		flash = 0.0
		next_flash = randf_range(3.0, 6.0)
	func _process(delta: float) -> void:
		t += delta
		for m in motes:
			m[0] += (m[1] as Vector2) * delta + Vector2(sin(t * 0.7 + m[2]) * 6.0, 0) * delta
			if m[0].y < view.position.y + 64.0:
				m[0] = Vector2(randf_range(view.position.x, W), H if kind not in ["lagoon", "sun", "reef", "rain"] else view.position.y + view.size.y * 0.78)
			if m[0].y > H:
				m[0] = Vector2(randf_range(view.position.x, W), view.position.y + 64.0)
				m[2] = randf() * TAU
			if m[0].x > W:
				m[0].x = view.position.x
			elif m[0].x < view.position.x:
				m[0].x = W
		if kind == "festival":
			next_flash -= delta
			if next_flash <= 0.0:
				next_flash = randf_range(4.0, 8.0)
				flash = 1.0
				flash_col = [Color8(255, 120, 180), Color8(255, 210, 110), Color8(120, 220, 255), Color8(170, 255, 140)][randi() % 4]
				flash_at = Vector2(randf_range(0.0, W), randf_range(-100.0, 200.0))
			flash = maxf(0.0, flash - delta * 1.6)
		queue_redraw()
	func _draw() -> void:
		match kind:
			"tatami":
				# dust drifting through the slanting sun (only where the sun falls)
				for m in motes:
					var p: Vector2 = m[0]
					var into := clampf(1.0 - absf(p.x + p.y * 0.55 - W * 0.42) / (W * 0.22), 0.0, 1.0)
					if into > 0.2:
						var a := (0.22 + 0.18 * sin(t * 2.0 + m[2])) * into
						draw_rect(Rect2(GameFx.snap(p), Vector2(4, 4)), Color(1, 0.95, 0.8, a))
			"veranda":
				# flecks of sun through the leaves, breathing as the leaves move
				for m in motes:
					var p2: Vector2 = GameFx.snap((m[0] as Vector2) * Vector2(1, 0) + Vector2(0, fposmod(m[2] * 150.0, H)) + Vector2(sin(t * 0.5 + m[2]) * 10.0, 0))
					var a2 := maxf(0.0, sin(t * 1.1 + m[2] * 3.0)) * 0.22
					draw_rect(Rect2(p2 - Vector2(4, 4), Vector2(8, 8)), Color(1, 0.96, 0.75, a2))
					draw_rect(Rect2(p2 - Vector2(8, 0), Vector2(16, 4)), Color(1, 0.96, 0.75, a2 * 0.4))
			"lacquer":
				# the lamp's pool breathing, glints of gold in the lacquer
				var k := 0.03 + 0.012 * sin(t * 1.7) + 0.006 * sin(t * 7.3)
				GameFx.disc(self, c, r * 0.95, Color(1, 0.8, 0.5, k))
				for m in motes:
					var on := sin(t * 1.6 + m[2] * 5.0)
					if on > 0.8:
						var q: Vector2 = GameFx.snap(Vector2(fposmod(m[2] * 977.0, W), fposmod(m[2] * 613.0, H)))
						var a3 := (on - 0.8) * 4.0
						draw_rect(Rect2(q - Vector2(2, 2), Vector2(4, 4)), Color(1, 0.85, 0.45, a3))
						draw_rect(Rect2(q - Vector2(6, 2), Vector2(12, 4)), Color(1, 0.85, 0.45, a3 * 0.4))
						draw_rect(Rect2(q - Vector2(2, 6), Vector2(4, 12)), Color(1, 0.85, 0.45, a3 * 0.4))
			"bathroom":
				# light rippling on the water in the middle of the bowl
				for ring in 4:
					var rr := 40.0 + ring * 28.0
					for k2 in 18:
						var a4 := k2 * TAU / 18.0 + t * (0.4 + ring * 0.12) * (1.0 if ring % 2 == 0 else -1.0)
						var wob := sin(a4 * 3.0 + t * 2.2) * 6.0
						var q2 := GameFx.snap(c + Vector2.from_angle(a4) * (rr + wob))
						var al := 0.1 + 0.08 * sin(a4 * 2.0 + t * 3.0)
						draw_rect(Rect2(q2, Vector2(8, 4)), Color(0.85, 1.0, 1.0, al))
			"workshop":
				# the hanging lamp sways on its cord: its pool of light moves a little; dust in it
				var lc := c + Vector2(sin(t * 0.8) * 26.0, cos(t * 0.8) * 6.0)
				GameFx.disc(self, lc, r * 0.8, Color(1, 0.86, 0.6, 0.035))
				GameFx.disc(self, lc, r * 0.5, Color(1, 0.86, 0.6, 0.03))
				for m in motes:
					var p3: Vector2 = m[0]
					if p3.distance_to(lc) < r * 0.85:
						draw_rect(Rect2(GameFx.snap(p3), Vector2(4, 4)), Color(1, 0.9, 0.7, 0.18 + 0.12 * sin(t * 2.0 + m[2])))
			"festival":
				# the lanterns' warm light flickering round the stage, a firework's flash now and then
				for i in 4:
					var lp := Vector2([90.0, 860.0, 120.0, 830.0][i], [150.0, 170.0, 900.0, 880.0][i])
					var fl := 0.05 + 0.02 * sin(t * 9.0 + i * 1.7) + 0.015 * sin(t * 23.0 + i)
					GameFx.disc(self, lp, 150.0, Color(1, 0.6, 0.3, fl))
					GameFx.disc(self, lp, 70.0, Color(1, 0.7, 0.4, fl))
				if flash > 0.0:
					draw_rect(Rect2(0, 0, W, H), Color(flash_col.r, flash_col.g, flash_col.b, 0.1 * flash))
					GameFx.disc(self, flash_at, 360.0, Color(flash_col.r, flash_col.g, flash_col.b, 0.07 * flash))
				for m in motes:
					var p4: Vector2 = m[0]
					draw_rect(Rect2(GameFx.snap(p4), Vector2(4, 4)), Color(1, 0.6, 0.3, 0.3 + 0.2 * sin(t * 5.0 + m[2])))
			"lagoon", "sun", "reef", "rain":
				# light glittering just under the surface (not in the rain), bubbles rising
				if kind != "rain":
					var gc := Color(1, 0.92, 0.7) if kind == "sun" else Color(0.9, 1.0, 0.97)
					for g in 22:
						var gx := view.position.x + fposmod(g * 97.0 + sin(t * 0.3 + g) * 30.0, view.size.x)
						var gy := view.position.y + 12.0 + fposmod(g * 53.0, 150.0)
						var on := sin(t * 2.2 + g * 1.7)
						if on > 0.6:
							var q8 := GameFx.snap(Vector2(gx, gy))
							var a8 := (on - 0.6) * 1.2 * (1.0 - fposmod(g * 53.0, 150.0) / 170.0)
							draw_rect(Rect2(q8, Vector2(8, 4)), Color(gc.r, gc.g, gc.b, a8))
				for m in motes:
					var p8: Vector2 = GameFx.snap(m[0])
					var br2 := 4.0 + 4.0 * float(int(m[2] * 10.0) % 2)
					GameFx.light_ring(self, p8, br2, Color(0.9, 1.0, 1.0), 8, 4.0, 0.22)
			"night":
				# plankton glowing as it drifts
				for m in motes:
					GameFx.glow(self, m[0], 4.0, Color(0.5, 1.0, 0.95), 0.25 + 0.2 * sin(t * 1.8 + m[2] * 3.0))
			"deep":
				# marine snow drifting down through the dark
				for m in motes:
					draw_rect(Rect2(GameFx.snap(m[0]), Vector2(4, 4)), Color(0.8, 0.9, 1.0, 0.16 + 0.1 * sin(t + m[2])))
			"wood":
				# dust drifting through the window's light (a slanting band from the top-left)
				for m in motes:
					var p5: Vector2 = m[0]
					var into := clampf(1.0 - absf((p5.x - view.position.x) + (p5.y - view.position.y) * 0.6 - view.size.x * 0.45) / (view.size.x * 0.24), 0.0, 1.0)
					if into > 0.15:
						draw_rect(Rect2(GameFx.snap(p5), Vector2(4, 4)), Color(1, 0.94, 0.78, (0.2 + 0.16 * sin(t * 2.0 + m[2])) * into))
			"tiles":
				# soap bubbles rising, a glint on each
				for m in motes:
					var p6: Vector2 = GameFx.snap(m[0])
					var br := 8.0 + 4.0 * float(int(m[2] * 10.0) % 3)
					GameFx.light_ring(self, p6, br, Color(0.85, 0.97, 1.0), 10, 4.0, 0.16)
					draw_rect(Rect2(p6 + Vector2(-br * 0.5, -br * 0.5), Vector2(4, 4)), Color(1, 1, 1, 0.3))
			"gut":
				# glowing spores floating, and the whole lining breathing a little light
				var k6 := 0.02 + 0.015 * sin(t * 1.4)
				GameFx.disc(self, c, r * 0.7, Color(1, 0.6, 0.6, k6))
				for m in motes:
					var a6 := 0.2 + 0.15 * sin(t * 2.4 + m[2])
					GameFx.glow(self, m[0], 4.0, Color(0.85, 1.0, 0.6), a6)
			"sewer":
				# drips falling from the grates above, a ring where each lands
				for m in motes:
					var p7: Vector2 = m[0]
					var land := view.position.y + fposmod(m[2] * 977.0, view.size.y - 120.0) + 100.0
					if p7.y < land:
						draw_rect(Rect2(GameFx.snap(p7), Vector2(4, 8)), Color(0.8, 0.95, 1.0, 0.35))
					else:
						var age := (p7.y - land) / 300.0
						if age < 0.5:
							GameFx.light_ring(self, Vector2(p7.x, land), 8.0 + age * 40.0, Color(0.8, 0.95, 1.0), 10, 4.0, 0.35 * (1.0 - age * 2.0))
			"factory":
				# a lamp's flicker over the floor, sparks dropping from a weld now and then
				var fl := 0.03 + (0.03 if sin(t * 31.0) > 0.7 else 0.0)
				GameFx.disc(self, c, r * 0.8, Color(1, 0.9, 0.7, fl))
				for m in motes:
					if sin(t * 0.9 + m[2] * 4.0) > 0.4:
						draw_rect(Rect2(GameFx.snap(m[0]), Vector2(4, 4)), Color(1, 0.75, 0.3, 0.6))
			"space":
				# the stars twinkling, now and then a shooting star across the deck
				for m in motes:
					var tw := sin(t * (1.0 + fposmod(m[2], 1.0) * 2.0) + m[2] * 7.0)
					if tw > 0.55:
						var q7: Vector2 = GameFx.snap(m[0])
						var a7 := (tw - 0.55) * 1.6
						draw_rect(Rect2(q7, Vector2(4, 4)), Color(1, 1, 1, a7))
						draw_rect(Rect2(q7 + Vector2(-4, 0), Vector2(12, 4)), Color(1, 1, 1, a7 * 0.35))
						draw_rect(Rect2(q7 + Vector2(0, -4), Vector2(4, 12)), Color(1, 1, 1, a7 * 0.35))
				var sh := fposmod(t, 9.0)
				if sh < 0.9:
					var from := view.position + Vector2(view.size.x * 0.2, view.size.y * 0.12)
					var head := from + Vector2(1, 0.45) * sh * 700.0
					for k7 in 8:
						draw_rect(Rect2(GameFx.snap(head - Vector2(1, 0.45) * k7 * 10.0), Vector2(4, 4)), Color(1, 1, 1, 0.6 * (1.0 - k7 / 8.0) * (1.0 - sh / 0.9)))
