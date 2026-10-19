extends RefCounted
class_name PalPrix2Fx
## Pal Prix 2's moving pieces (scripts/pal_prix_2.gd), each a Node2D that draws itself on the
## games' 4 px grid like Pal Prix's: the craft's trails (its neon light ribbons, drift sparks,
## spray, the transform's puff, contrails), the speed lines over the view, the sea lanes' neon
## buoys, the air lanes' beacons (their lights chasing the way to go), the transform gates' arches,
## the boost rings in the air and the currents on the water, the neon grandstand and its crowd,
## the little words that pop up over the craft ("PERFECT!", "x3"), the aurora, a gravity well.

const OUTLINE := Color8(40, 30, 40)

static func snap(p: Vector2) -> Vector2:
	return p.snapped(Vector2(4, 4))

## A filled disc on the 4 px grid (rows of 4 px)
static func disc(ci: CanvasItem, c: Vector2, r: float, col: Color) -> void:
	var y := -r
	while y <= r:
		var half := sqrt(maxf(0.0, r * r - y * y))
		ci.draw_rect(Rect2(snap(c + Vector2(-half, y)), Vector2(maxf(4.0, roundf(half * 2.0 / 4.0) * 4.0), 4)), col)
		y += 4.0

# ================================================================== THE CRAFT'S TRAILS

## Everything the craft leaves behind: its two neon light ribbons (from the rear thrusters,
## fading fast), drift sparks (blue, then orange, then pink as the drift charges), spray off the
## jet ski, the white puff and sparkles of a transform, the rocket's contrails, splash rings
class Trail extends Node2D:
	var marks: Array = []                 # [position, age, kind, velocity, colour, life]
	var ribbon_col := Color8(110, 240, 255)
	func ribbon(p: Vector2, heading: float, spread: float, col: Color) -> void:
		var back := Vector2.from_angle(heading) * -40.0
		var side := Vector2.from_angle(heading + PI / 2.0) * spread
		marks.append([p + back + side, 0.0, 0, Vector2.ZERO, col, 0.32])
		marks.append([p + back - side, 0.0, 0, Vector2.ZERO, col, 0.32])
	func sparks(p: Vector2, heading: float, n: int, col: Color) -> void:
		for k in n:
			var side := Vector2.from_angle(heading + PI / 2.0) * (1.0 if k % 2 == 0 else -1.0)
			var back := Vector2.from_angle(heading) * -40.0
			var v := side * randf_range(60.0, 180.0) - Vector2.from_angle(heading) * randf_range(80.0, 220.0)
			marks.append([p + back + side * 26.0, 0.0, 1, v, col, randf_range(0.18, 0.32)])
	func spray(p: Vector2, heading: float, n: int, strength := 1.0) -> void:
		for k in n:
			var side := Vector2.from_angle(heading + PI / 2.0) * (1.0 if k % 2 == 0 else -1.0)
			var v := (side * randf_range(90.0, 230.0) - Vector2.from_angle(heading) * randf_range(30.0, 130.0)) * strength
			marks.append([p + side * 22.0 - Vector2.from_angle(heading) * 20.0, 0.0, 2, v, Color(0.85, 0.95, 1.0), randf_range(0.3, 0.45)])
	func wake(p: Vector2, heading: float) -> void:
		var fwd := Vector2.from_angle(heading)
		var side := Vector2.from_angle(heading + PI / 2.0)
		for sd in [-1.0, 1.0]:
			marks.append([p - fwd * 52.0 + side * sd * 18.0, 0.0, 3, (side * sd * randf_range(70.0, 110.0) - fwd * 30.0), Color(1, 1, 1), 1.2])
		marks.append([p - fwd * 58.0 + side * randf_range(-6.0, 6.0), 0.0, 3, -fwd * 20.0, Color(1, 1, 1), 1.0])
	func contrail(p: Vector2, heading: float, col: Color) -> void:
		var side := Vector2.from_angle(heading + PI / 2.0) * 50.0
		var back := Vector2.from_angle(heading) * -12.0
		marks.append([p + back + side, 0.0, 4, Vector2.ZERO, col, 0.55])
		marks.append([p + back - side, 0.0, 4, Vector2.ZERO, col, 0.55])
	func puff(p: Vector2, n := 16) -> void:
		for k in n:
			var a := TAU * k / n + randf() * 0.4
			marks.append([p, 0.0, 5, Vector2.from_angle(a) * randf_range(120.0, 260.0), Color(1, 1, 1), randf_range(0.35, 0.55)])
		for k in 10:
			var a2 := randf() * TAU
			marks.append([p, 0.0, 6, Vector2.from_angle(a2) * randf_range(200.0, 360.0), Color8(255, 240, 150), 0.5])
	func splash(p: Vector2) -> void:
		marks.append([p, 0.0, 7, Vector2.ZERO, Color(1, 1, 1), 0.6])
		spray(p, randf() * TAU, 14, 1.4)
		spray(p, randf() * TAU, 10, 1.1)
	func _process(delta: float) -> void:
		for m in marks:
			m[1] += delta
			if m[2] != 0 and m[2] != 4 and m[2] != 7:
				m[0] += (m[3] as Vector2) * delta
				m[3] = (m[3] as Vector2) * maxf(0.0, 1.0 - delta * (2.5 if m[2] == 3 else 3.5))
		marks = marks.filter(func(m): return m[1] < m[5])
		queue_redraw()
	func _draw() -> void:
		for m in marks:
			var f: float = m[1] / m[5]
			var p: Vector2 = PalPrix2Fx.snap(m[0])
			var c: Color = m[4]
			match int(m[2]):
				0:
					# a light ribbon: bright, then the colour, fading
					var cc := Color(1, 1, 1) if f < 0.15 else c
					cc.a = 0.85 * (1.0 - f)
					draw_rect(Rect2(p - Vector2(4, 4), Vector2(8, 8)), cc)
				1:
					var c1 := c
					c1.a = 1.0 - f
					draw_rect(Rect2(p - Vector2(2, 2), Vector2(4, 4)), c1)
					draw_rect(Rect2(p - (m[3] as Vector2).normalized() * 6.0 - Vector2(2, 2), Vector2(4, 4)), Color(c.r, c.g, c.b, 0.5 * (1.0 - f)))
				2:
					draw_rect(Rect2(p - Vector2(2, 2), Vector2(4, 4)), Color(0.88, 0.96, 1.0, 0.85 * (1.0 - f)))
				3:
					var sz := 4.0 if f < 0.2 else (8.0 if f < 0.6 else 12.0)
					draw_rect(Rect2(p - Vector2(sz, sz) / 2.0 + Vector2(4, 4), Vector2(sz, sz)), Color(0.05, 0.1, 0.25, 0.15 * (1.0 - f)))
					draw_rect(Rect2(p - Vector2(sz, sz) / 2.0, Vector2(sz, sz)), Color(0.97, 0.99, 1.0, 0.85 * (1.0 - f)))
				4:
					draw_rect(Rect2(p - Vector2(4, 4), Vector2(8, 8)), Color(c.r, c.g, c.b, 0.55 * (1.0 - f)))
				5:
					var s5 := 8.0 + 16.0 * f
					draw_rect(Rect2(p - Vector2(s5, s5) / 2.0, Vector2(s5, s5)).abs(), Color(1, 1, 1, 0.9 * (1.0 - f)))
				6:
					draw_rect(Rect2(p - Vector2(2, 2), Vector2(4, 4)), Color(c.r, c.g, c.b, 1.0 - f))
				7:
					# a ring of foam spreading on the water
					var r := 20.0 + 70.0 * f
					for k in 16:
						var q := PalPrix2Fx.snap((m[0] as Vector2) + Vector2.from_angle(k * TAU / 16.0) * Vector2(r, r * 0.8))
						draw_rect(Rect2(q - Vector2(4, 2), Vector2(8, 4)), Color(1, 1, 1, 0.8 * (1.0 - f)))

# ================================================================== SPEED

## Speed over the whole view (the user: "speed lines, streaks"): thin white streaks rushing past
## from ahead, more and longer the faster it goes, a burst on a boost; in space, stars streaking
class SpeedLines extends Node2D:
	var view := Rect2()
	var streaks: Array = []               # [position, velocity, age, life, length]
	var k := 0.0                          # how fast (0 none .. 1 a big boost)
	var dir := Vector2.RIGHT              # the way the craft goes (on screen)
	var tint := Color(1, 1, 1)
	func _process(delta: float) -> void:
		var want := int(k * 34.0)
		if streaks.size() < want and randf() < delta * 60.0 * k:
			var c := view.get_center()
			var side := Vector2(-dir.y, dir.x)
			var off := side * randf_range(-view.size.x * 0.55, view.size.x * 0.55)
			if absf(off.dot(side)) < 120.0:
				off += side * signf(off.dot(side) + 0.01) * 120.0          # (never across the craft)
			var p := c + dir * view.size.x * 0.6 + off
			streaks.append([p, -dir * randf_range(1500.0, 2300.0) * (0.6 + 0.6 * k), 0.0, randf_range(0.25, 0.45), randf_range(40.0, 120.0) * (0.5 + k)])
		for s in streaks:
			s[0] += (s[1] as Vector2) * delta
			s[2] += delta
		streaks = streaks.filter(func(s): return s[2] < s[3])
		queue_redraw()
	func _draw() -> void:
		for s in streaks:
			var f: float = s[2] / s[3]
			var a := sin(f * PI) * 0.35 * clampf(k * 1.4, 0.0, 1.0)
			var d: Vector2 = (s[1] as Vector2).normalized()
			var ln: float = s[4]
			var q := 0.0
			while q < ln:
				var p: Vector2 = PalPrix2Fx.snap((s[0] as Vector2) - d * q)
				if view.has_point(p):
					draw_rect(Rect2(p, Vector2(4, 4)), Color(tint.r, tint.g, tint.b, a * (1.0 - q / ln)))
				q += 4.0

# ================================================================== THE LANES

## The sea lanes' edges: neon buoys bobbing on the swell, their lights pulsing (the user liked
## Pal Prix's buoys reacting to the boat): a hull touching one carries it along, it swings back
## on a spring once the craft has gone, ripples round it while it moves
class Buoys extends Node2D:
	const REACH := 40.0
	const SPRING := 22.0
	const DAMP := 4.0
	const MAX_OFF := 50.0
	var rest := PackedVector2Array()
	var off := PackedVector2Array()
	var vel := PackedVector2Array()
	var col: Array[Color] = []
	var t := 0.0
	func setup(spots: Array, a: Color, b: Color) -> void:
		rest.clear()
		off.clear()
		vel.clear()
		col.clear()
		for sp in spots:
			rest.append(sp[0])
			off.append(Vector2.ZERO)
			vel.append(Vector2.ZERO)
			col.append(a if sp[1] else b)
		visible = not rest.is_empty()
		queue_redraw()
	func update(delta: float, hulls: Array) -> int:
		if rest.is_empty():
			return 0
		t += delta
		var bumps := 0
		for i in rest.size():
			var p := rest[i] + off[i]
			var held := false
			for hl in hulls:
				var to: Vector2 = p - (hl[0] as Vector2)
				var dd := to.length()
				if dd < REACH and off[i].length() < MAX_OFF:
					var away := to / dd if dd > 0.01 else Vector2.RIGHT
					p = (hl[0] as Vector2) + away * REACH
					if vel[i].length() < 40.0 and hl[2]:
						bumps += 1
					vel[i] = (hl[1] as Vector2) * 0.5 + away * 60.0
					held = true
			if held:
				off[i] = p - rest[i]
			else:
				vel[i] += -off[i] * SPRING * delta
				vel[i] *= exp(-DAMP * delta)
				off[i] += vel[i] * delta
			if off[i].length() > MAX_OFF:
				off[i] = off[i].normalized() * MAX_OFF
		queue_redraw()
		return bumps
	func _draw() -> void:
		for i in rest.size():
			var p := PalPrix2Fx.snap(rest[i] + off[i])
			var moving := vel[i].length() > 10.0 or off[i].length() > 3.0
			if moving:
				var ring := 4.0 * (4.0 + roundf(fposmod(t * 6.0 + i, 3.0)))
				for a in 10:
					var q := PalPrix2Fx.snap(p + Vector2.from_angle(a * TAU / 10.0) * ring)
					draw_rect(Rect2(q - Vector2(2, 2), Vector2(4, 4)), Color(1, 1, 1, 0.4))
			var bob := -4.0 if sin(t * 1.7 - float(i) * 0.45) > 0.4 else 0.0
			var c := col[i]
			var pulse := 0.5 + 0.5 * sin(t * 4.0 - float(i) * 0.6)
			# its glow on the water, its body (dark, outlined), its light on top
			draw_rect(Rect2(p - Vector2(12, 4), Vector2(24, 12)), Color(c.r, c.g, c.b, 0.18 + 0.12 * pulse))
			draw_rect(Rect2(p + Vector2(-10, -14 + bob), Vector2(20, 18)), OUTLINE)
			draw_rect(Rect2(p + Vector2(-6, -10 + bob), Vector2(12, 10)), Color8(70, 74, 96))
			draw_rect(Rect2(p + Vector2(-6, -10 + bob), Vector2(4, 4)), Color8(130, 134, 160))
			draw_rect(Rect2(p + Vector2(-6, -22 + bob), Vector2(12, 12)), OUTLINE)
			draw_rect(Rect2(p + Vector2(-2, -18 + bob), Vector2(4, 4)), c.lerp(Color(1, 1, 1), 0.5 * pulse))
			draw_rect(Rect2(p + Vector2(-2, -14 + bob), Vector2(4, 4)), c)

## The air lanes' edges: little floating beacons both sides of the way, their lights running in
## a chase towards where to go (the user: the way has to be easy to read), a soft beam under each
class Beacons extends Node2D:
	var spots: Array = []                 # [position, along (points), side]
	var t := 0.0
	var col := Color8(255, 90, 220)
	func setup(s: Array, c: Color) -> void:
		spots = s
		col = c
		visible = not spots.is_empty()
	func _process(delta: float) -> void:
		t += delta
		if visible:
			queue_redraw()
	func _draw() -> void:
		for s in spots:
			var p := PalPrix2Fx.snap(s[0])
			var ph := fposmod(float(s[1]) / 20.0 - t * 3.0, 4.0)
			var on := ph < 1.0
			var bob := roundf(sin(t * 2.0 + float(s[1]) * 0.1) * 1.0) * 4.0
			if on:
				draw_rect(Rect2(p + Vector2(-20, -20 + bob), Vector2(40, 40)), Color(col.r, col.g, col.b, 0.16))
				draw_rect(Rect2(p + Vector2(-16, -16 + bob), Vector2(32, 32)), Color(col.r, col.g, col.b, 0.2))
			draw_rect(Rect2(p + Vector2(-12, -12 + bob), Vector2(24, 24)), OUTLINE)
			draw_rect(Rect2(p + Vector2(-8, -8 + bob), Vector2(16, 16)), Color8(56, 60, 84))
			draw_rect(Rect2(p + Vector2(-4, -4 + bob), Vector2(8, 8)), col if on else col.darkened(0.35))
			if on:
				draw_rect(Rect2(p + Vector2(-4, -4 + bob), Vector2(4, 4)), Color(1, 1, 1))

## A transform gate's arch over the lane: two pylons at its edges, a beam across with chevrons
## flowing the way to go, the new form's sign (a wave, wings, a wheel) over the middle, glowing in
## its colour (water cyan, air pink, land gold); flown under, it flashes
class Gate extends Node2D:
	var a := Vector2.ZERO                 # its two feet (mat px)
	var b := Vector2.ZERO
	var dir := Vector2.RIGHT              # the way through it
	var to := 0                           # the form it makes (0 land, 1 sea, 2 air)
	var t := 0.0
	var flash := 0.0
	const COLS := [Color8(255, 214, 90), Color8(110, 230, 255), Color8(255, 110, 220)]
	func _process(delta: float) -> void:
		t += delta
		flash = maxf(0.0, flash - delta * 2.0)
		queue_redraw()
	func _draw() -> void:
		var c: Color = COLS[to]
		var lift := Vector2(0, -64)
		# the pylons
		for f in [a, b]:
			var p := PalPrix2Fx.snap(f)
			draw_rect(Rect2(p + Vector2(-10, -72), Vector2(20, 76)), OUTLINE)
			draw_rect(Rect2(p + Vector2(-6, -68), Vector2(12, 68)), Color8(70, 74, 100))
			draw_rect(Rect2(p + Vector2(-6, -68), Vector2(4, 68)), Color8(120, 126, 156))
			draw_rect(Rect2(p + Vector2(-2, -60), Vector2(4, 48)), c.darkened(0.2))
		# the beam across, chevrons flowing along it
		var span := b - a
		var n := int(span.length() / 8.0)
		for k in n + 1:
			var q := PalPrix2Fx.snap(a.lerp(b, float(k) / float(maxi(n, 1))) + lift)
			draw_rect(Rect2(q - Vector2(6, 10), Vector2(12, 20)), OUTLINE)
		for k in n + 1:
			var q2 := PalPrix2Fx.snap(a.lerp(b, float(k) / float(maxi(n, 1))) + lift)
			var run := fposmod(float(k) * 0.25 - t * 3.0, 2.0) < 1.0
			var cc := c if run else c.darkened(0.45)
			if flash > 0.0:
				cc = cc.lerp(Color(1, 1, 1), flash)
			draw_rect(Rect2(q2 - Vector2(2, 6), Vector2(4, 12)), cc)
		# the sign in the middle: the form it turns you into
		var m := PalPrix2Fx.snap((a + b) / 2.0 + lift + Vector2(0, -28))
		draw_rect(Rect2(m - Vector2(22, 18), Vector2(44, 36)), OUTLINE)
		draw_rect(Rect2(m - Vector2(18, 14), Vector2(36, 28)), Color8(30, 34, 54))
		var ic := c.lerp(Color(1, 1, 1), 0.3 + 0.3 * sin(t * 5.0))
		match to:
			1:
				for x in 7:
					var y := -4.0 if x % 2 == 0 else 0.0
					draw_rect(Rect2(m + Vector2(-14 + x * 4, y), Vector2(4, 4)), ic)
					draw_rect(Rect2(m + Vector2(-14 + x * 4, y + 6), Vector2(4, 4)), ic.darkened(0.3))
			2:
				draw_rect(Rect2(m + Vector2(-2, -10), Vector2(4, 20)), ic)
				draw_rect(Rect2(m + Vector2(-14, -2), Vector2(28, 4)), ic)
				draw_rect(Rect2(m + Vector2(-10, -6), Vector2(4, 4)), ic)
				draw_rect(Rect2(m + Vector2(6, -6), Vector2(4, 4)), ic)
				draw_rect(Rect2(m + Vector2(-6, 6), Vector2(12, 4)), ic.darkened(0.3))
			_:
				PalPrix2Fx.disc(self, m, 10.0, ic)
				PalPrix2Fx.disc(self, m, 4.0, Color8(30, 34, 54))

## A boost ring in the air (the rocket's boost plate): an upright hoop across the lane, neon,
## seen from above at an angle, drawn in two halves (the far one under the craft, the near one
## over it, so it flies through); the next one glows, a hit one bursts
class Ring extends Node2D:
	var n := Vector2.RIGHT
	var r := 90.0
	var upper := true
	var d := Vector2.DOWN
	var t := 0.0
	var state := 0                        # 0 waiting, 1 next, 2 flown through (fading)
	var col := Color8(255, 110, 220)
	func _process(delta: float) -> void:
		t += delta
		queue_redraw()
	func _draw() -> void:
		if state == 2 and modulate.a <= 0.01:
			return
		var steps := 36
		for k in steps:
			var a := TAU * k / steps
			var q := n * r * cos(a) + Vector2(-n.y, n.x) * r * 0.42 * sin(a)
			if (q.dot(d) <= 0.0) != upper:
				continue
			var p := PalPrix2Fx.snap(q)
			var glow := 0.5 + 0.5 * sin(t * 6.0 - a * 3.0)
			draw_rect(Rect2(p - Vector2(12, 12), Vector2(24, 24)), Color(col.r, col.g, col.b, 0.18))
			draw_rect(Rect2(p - Vector2(8, 8), Vector2(16, 16)), OUTLINE)
			var c := col.lerp(Color(1, 1, 1), glow * 0.45)
			draw_rect(Rect2(p - Vector2(6, 6), Vector2(12, 12)), c)
			if glow > 0.7:
				draw_rect(Rect2(p - Vector2(2, 2), Vector2(4, 4)), Color(1, 1, 1))

## A current on the water (the jet ski's boost plate): chevrons flowing down the lane over a warm
## glow, like Pal Prix's
class Current extends Node2D:
	var dir := Vector2.RIGHT
	var length := 70.0
	var width := 60.0
	var t := 0.0
	var col := Color8(255, 214, 70)
	func _process(delta: float) -> void:
		t += delta
		queue_redraw()
	func _draw() -> void:
		var side := Vector2(-dir.y, dir.x)
		var shift := fposmod(t * 160.0, 32.0)
		var u := -length - 32.0 + shift
		while u < length:
			var fade := clampf(1.0 - absf(u) / length, 0.0, 1.0)
			var v := -width
			while v <= width:
				var q := PalPrix2Fx.snap(dir * (u - absf(v) * 0.6) + side * v)
				draw_rect(Rect2(q - Vector2(4, 4) + Vector2(0, 4), Vector2(8, 8)), Color(0.1, 0.06, 0.12, 0.4 * fade))
				draw_rect(Rect2(q - Vector2(4, 4), Vector2(8, 8)), Color(col.r, col.g, col.b, 0.95 * fade))
				draw_rect(Rect2(q - Vector2(4, 4), Vector2(4, 4)), Color(1, 0.97, 0.75, 0.95 * fade))
				v += 4.0
			u += 32.0

# ================================================================== THE CROWD

## The grandstand by the start: pals of every kind (their balls; your own among them), hopping
## when the craft goes by, at GO and at the finish, screaming at a bump nearby; a futuristic
## stand: dark metal tiers with glowing lips, a big screen at the back showing your pal
class Crowd extends Node2D:
	const TIERS := 5
	const ROW := 24.0
	const SEAT := 30.0
	var rect := Rect2()
	var along_x := true
	var away := Vector2.UP
	var dots: Array = []                 # [position, its pal, hop start, hops, scared until, scatter, height, beat, next idle hop]
	var pals: Array[Texture2D] = []
	var star: Texture2D
	var watch := Vector2.ZERO
	var t := 0.0
	var party := false
	var glow := Color8(65, 227, 255)
	func setup(r: Rect2, horizontal: bool, seed_n: int, away_dir: Vector2, accent: Color) -> void:
		rect = r
		along_x = horizontal
		away = away_dir
		glow = accent
		texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		dots.clear()
		pals.clear()
		party = false
		var rng := RandomNumberGenerator.new()
		rng.seed = seed_n
		var mine: Array[Texture2D] = []
		for id in PetState.discovered:
			var path := "res://textures/minigames/balls/%s.png" % id
			if ResourceLoader.exists(path):
				mine.append(load(path))
		var others: Array = PetState.FORMS.keys().filter(func(id): return id not in PetState.discovered)
		for i in range(others.size() - 1, 0, -1):
			var j := rng.randi() % (i + 1)
			var tmp = others[i]
			others[i] = others[j]
			others[j] = tmp
		var mix: Array[Texture2D] = []
		for id in others:
			if mix.size() >= 14:
				break
			var path2 := "res://textures/minigames/balls/%s.png" % id
			if ResourceLoader.exists(path2):
				mix.append(load(path2))
		pals.append_array(mine)
		pals.append_array(mix)
		if pals.is_empty():
			pals.append(PalBall.texture())
		star = PalBall.texture()
		var n_mine := mine.size()
		var long := r.size.x if horizontal else r.size.y
		for tier in TIERS:
			var n := int((long - 36.0) / SEAT)
			for k in n:
				if rng.randf() < 0.12:
					continue
				var a := 26.0 + k * SEAT + (SEAT / 2.0 if tier % 2 else 0.0)
				if a > long - 18.0:
					continue
				var b := _tier_at(tier) + 10.0
				var p := r.position + (Vector2(a, b) if horizontal else Vector2(b, a))
				var who := rng.randi() % pals.size()
				if n_mine > 0 and (rng.randf() < 0.33 or n_mine == pals.size()):
					who = rng.randi() % n_mine
				elif pals.size() > n_mine:
					who = n_mine + rng.randi() % (pals.size() - n_mine)
				dots.append([PalPrix2Fx.snap(p), who, -10.0, 1, -10.0, Vector2.ZERO, 20.0, rng.randf() * TAU, rng.randf() * 3.0])
		dots.sort_custom(func(x, y): return x[0].y < y[0].y)
		queue_redraw()
	func cheer(from: Vector2, hops := 1) -> void:
		for d in dots:
			var dist: float = absf((d[0].x - from.x) if along_x else (d[0].y - from.y))
			d[2] = t + dist / 700.0 + randf() * 0.06
			d[3] = hops
			d[6] = 20.0
	func scream(at: Vector2) -> void:
		if not rect.grow(320.0).has_point(at):
			return
		for d in dots:
			var off: Vector2 = d[0] - at
			if off.length() < 300.0:
				d[4] = t + 1.2
				d[5] = off.normalized() * randf_range(10.0, 22.0)
				d[2] = t + randf() * 0.1
				d[3] = 3
				d[6] = 30.0
	func _process(delta: float) -> void:
		t += delta
		var near_k := clampf(1.0 - (watch.distance_to(rect.get_center()) - 300.0) / 700.0, 0.0, 1.0)
		for d in dots:
			var busy: bool = t < d[2] + 0.36 * d[3]
			if party and not busy:
				d[2] = t + randf() * 0.25
				d[3] = 1
				d[6] = 20.0
			elif not busy and t > d[8]:
				d[2] = t
				d[3] = 2 if near_k > 0.5 and randf() < 0.4 else 1
				d[6] = 8.0 + 8.0 * near_k
				d[8] = t + lerpf(randf_range(2.0, 5.5), randf_range(0.5, 1.4), near_k)
		queue_redraw()
	func _tier_at(tier: int) -> float:
		var depth := rect.size.y if along_x else rect.size.x
		var toward_neg := (away.y < 0.0) if along_x else (away.x < 0.0)
		return (depth - ROW * (tier + 1)) if toward_neg else (ROW * tier)
	func _draw() -> void:
		if rect.size == Vector2.ZERO:
			return
		draw_rect(rect.grow(4), OUTLINE)
		draw_rect(rect, Color8(36, 38, 56))
		var metal := [Color8(46, 48, 70), Color8(54, 56, 80), Color8(62, 64, 90), Color8(70, 72, 100), Color8(78, 80, 110)]
		for tier in TIERS:
			var at := _tier_at(tier)
			var r: Rect2
			if along_x:
				r = Rect2(rect.position + Vector2(0, at), Vector2(rect.size.x, ROW))
			else:
				r = Rect2(rect.position + Vector2(at, 0), Vector2(ROW, rect.size.y))
			draw_rect(r, metal[tier])
			var lip := Rect2(r.position, Vector2(r.size.x, 4)) if along_x else Rect2(r.position, Vector2(4, r.size.y))
			var pulse := 0.6 + 0.4 * sin(t * 3.0 + tier)
			draw_rect(lip, Color(glow.r, glow.g, glow.b, pulse))
		# the big screen at the back: your pal, its scanlines rolling
		var toward_neg := (away.y < 0.0) if along_x else (away.x < 0.0)
		var scr: Rect2
		if along_x:
			scr = Rect2(Vector2(rect.get_center().x - 60, (rect.position.y - 84) if toward_neg else rect.end.y + 4), Vector2(120, 80))
		else:
			scr = Rect2(Vector2((rect.position.x - 124) if toward_neg else rect.end.x + 4, rect.get_center().y - 40), Vector2(120, 80))
		draw_rect(scr.grow(4), OUTLINE)
		draw_rect(scr, Color8(20, 24, 44))
		if star:
			var bounce := 4.0 if fposmod(t * 2.0, 1.0) < 0.5 else 0.0
			draw_texture_rect(star, Rect2(scr.get_center() - Vector2(30, 34 + bounce), Vector2(60, 60)), false)
		var line := fposmod(t * 40.0, scr.size.y)
		draw_rect(Rect2(scr.position + Vector2(0, roundf(line / 4.0) * 4.0), Vector2(scr.size.x, 4)), Color(1, 1, 1, 0.12))
		for d in dots:
			var u: float = (t - d[2]) / 0.36
			var up := 0.0
			var scared: bool = t < d[4]
			if u >= 0.0 and u < float(d[3]):
				up = sin(fposmod(u, 1.0) * PI) * float(d[6])
			var p: Vector2 = d[0] - Vector2(0, roundf(up / 4.0) * 4.0)
			var lean := watch.x - (d[0] as Vector2).x
			p.x += 4.0 * (signf(lean) if along_x and absf(lean) > 40.0 and watch != Vector2.ZERO else roundf(sin(t * 1.7 + float(d[7]))))
			if scared:
				var k := clampf((d[4] - t) / 1.2, 0.0, 1.0)
				p += (d[5] as Vector2) * sin(k * PI) + Vector2(4.0 if int(t * 30.0) % 2 == 0 else -4.0, 0) * k
			p = PalPrix2Fx.snap(p)
			draw_texture_rect(pals[d[1]], Rect2(p - Vector2(24, 28), Vector2(48, 48)), false)
			if scared and int(d[1]) % 2 == 0:
				draw_rect(Rect2(p + Vector2(-2, -46), Vector2(4, 10)), Color8(250, 246, 236))
				draw_rect(Rect2(p + Vector2(-2, -32), Vector2(4, 4)), Color8(250, 246, 236))

# ================================================================== WORDS, SKIES, WELLS

## A little word popping up over the craft and floating off ("PERFECT!", "x3", "DRIFT!"),
## outlined, in the game's pixel font
class Pops extends Node2D:
	var items: Array = []                 # [text, position, age, colour, size]
	var font: Font
	var view := Rect2()                   # (what the view shows: the words stay inside it)
	func say(text: String, at: Vector2, col: Color, size := 30) -> void:
		items.append([text, at, 0.0, col, size])
	func _process(delta: float) -> void:
		for it in items:
			it[2] += delta
			it[1] += Vector2(0, -70.0 * delta)
		items = items.filter(func(it): return it[2] < 0.9)
		queue_redraw()
	func _draw() -> void:
		if not font:
			return
		for it in items:
			var f: float = it[2] / 0.9
			var s: int = it[4]
			var w := font.get_string_size(it[0], HORIZONTAL_ALIGNMENT_LEFT, -1, s).x
			var p: Vector2 = (it[1] as Vector2) - Vector2(w / 2.0, 0)
			if view.size.x > 0.0:
				p.x = clampf(p.x, view.position.x + 16.0, maxf(view.position.x + 16.0, view.end.x - w - 16.0))
				p.y = clampf(p.y, view.position.y + 40.0, view.end.y - 16.0)
			p = PalPrix2Fx.snap(p)
			var c: Color = it[3]
			c.a = 1.0 if f < 0.6 else (1.0 - (f - 0.6) / 0.4)
			var o := Color(OUTLINE.r, OUTLINE.g, OUTLINE.b, c.a)
			for dd in [Vector2(-4, 0), Vector2(4, 0), Vector2(0, -4), Vector2(0, 4), Vector2(-4, -4), Vector2(4, 4), Vector2(-4, 4), Vector2(4, -4)]:
				draw_string(font, p + dd, it[0], HORIZONTAL_ALIGNMENT_LEFT, -1, s, o)
			draw_string(font, p, it[0], HORIZONTAL_ALIGNMENT_LEFT, -1, s, c)

## The Ice Fjord's aurora over the view: soft curtains of green and violet light rippling across
## the sky (drawn over everything, faint), and snow drifting down
class Aurora extends Node2D:
	var view := Rect2()
	var t := 0.0
	var flakes: Array = []
	func _ready() -> void:
		for i in 50:
			flakes.append([randf_range(0, 950), randf_range(0, 948), randf_range(40, 90), randf() * TAU])
	func _process(delta: float) -> void:
		t += delta
		for f in flakes:
			f[1] += f[2] * delta
			f[0] += sin(t * 1.3 + f[3]) * 20.0 * delta
			if f[1] > view.end.y:
				f[1] = view.position.y
				f[0] = randf_range(view.position.x, view.end.x)
		queue_redraw()
	func _draw() -> void:
		for band in 3:
			var x := view.position.x
			while x < view.end.x:
				var y := view.position.y + 60.0 + band * 110.0 + sin(x * 0.006 + t * 0.6 + band * 1.7) * 60.0
				var h := 70.0 + 40.0 * sin(x * 0.011 + t * 0.9 + band)
				var c := Color8(90, 255, 170) if band != 1 else Color8(190, 120, 255)
				c.a = 0.07 + 0.04 * sin(x * 0.02 + t * 2.0 + band)
				draw_rect(Rect2(Vector2(x, roundf(y / 4.0) * 4.0), Vector2(8, roundf(h / 4.0) * 4.0)), c)
				x += 8.0
		for f in flakes:
			var p := PalPrix2Fx.snap(Vector2(f[0], f[1]))
			if view.has_point(p):
				draw_rect(Rect2(p, Vector2(4, 4)), Color(1, 1, 1, 0.7))

## The canyon's wind across the flight in a gust: pale streaks blowing over it, at the rocket's
## height, with a few grains of sand in it
class Gusts extends Node2D:
	var zones: Array = []                 # [points (the flight there), the way it blows]
	var bits: Array = []                  # [position, velocity, age, sand]
	func setup(z: Array) -> void:
		zones = z
		bits.clear()
		visible = not zones.is_empty()
	func _process(delta: float) -> void:
		if zones.is_empty():
			return
		for z in zones:
			if randf() < delta * 30.0:
				var pts: PackedVector2Array = z[0]
				var at := pts[randi() % pts.size()]
				var way: Vector2 = z[1]
				bits.append([at - way * 300.0 + Vector2(randf_range(-80, 80), randf_range(-80, 80)), way * randf_range(420.0, 560.0), 0.0, randf() < 0.3])
		for b in bits:
			b[0] += (b[1] as Vector2) * delta
			b[2] += delta
		bits = bits.filter(func(b): return b[2] < 1.2)
		queue_redraw()
	func _draw() -> void:
		for b in bits:
			var p: Vector2 = PalPrix2Fx.snap(b[0])
			var v: Vector2 = (b[1] as Vector2).normalized()
			var a := 0.6 * sin(b[2] / 1.2 * PI)
			if b[3]:
				draw_rect(Rect2(p, Vector2(4, 4)), Color(0.95, 0.75, 0.5, a))
				continue
			for k in 6:
				draw_rect(Rect2(PalPrix2Fx.snap(p - v * k * 6.0), Vector2(4, 4)), Color(1, 0.97, 0.92, a * (1.0 - k / 6.0)))

## A gravity well (the space worlds): a swirl that pulls the craft in; its arms turning, its eye
## pulsing, rings sinking in
class Well extends Node2D:
	var r := 220.0
	var t := 0.0
	var col := Color8(170, 110, 255)
	func _process(delta: float) -> void:
		t += delta
		queue_redraw()
	func _draw() -> void:
		for ring in 4:
			var rr := r * (1.0 - fposmod(t * 0.4 + ring * 0.25, 1.0))
			var a := 0.12 + 0.2 * (1.0 - rr / r)
			for k in 28:
				var q := PalPrix2Fx.snap(Vector2.from_angle(k * TAU / 28.0) * rr)
				draw_rect(Rect2(q - Vector2(2, 2), Vector2(4, 4)), Color(col.r, col.g, col.b, a))
		PalPrix2Fx.disc(self, Vector2.ZERO, r * 0.45, Color(col.r, col.g, col.b, 0.1))
		PalPrix2Fx.disc(self, Vector2.ZERO, r * 0.25, Color(col.r, col.g, col.b, 0.16))
		for arm in 4:
			for k in 26:
				var rad := 16.0 + k * (r / 28.0)
				var ang := -t * 2.4 + arm * TAU / 4.0 + rad * 0.02
				var q2 := PalPrix2Fx.snap(Vector2.from_angle(ang) * rad)
				var a2 := 0.95 * (1.0 - float(k) / 26.0)
				draw_rect(Rect2(q2 - Vector2(6, 6), Vector2(12, 12)), Color(col.r, col.g, col.b, a2 * 0.5))
				draw_rect(Rect2(q2 - Vector2(4, 4), Vector2(8, 8)), Color(col.r, col.g, col.b, a2))
				draw_rect(Rect2(q2 - Vector2(2, 2), Vector2(4, 4)), Color(1, 0.9, 1, a2 * 0.9))
		var eye := 12.0 + 4.0 * roundf(sin(t * 3.0))
		PalPrix2Fx.disc(self, Vector2.ZERO, eye + 4.0, OUTLINE)
		PalPrix2Fx.disc(self, Vector2.ZERO, eye, Color8(20, 10, 40))
