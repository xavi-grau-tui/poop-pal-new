extends RefCounted
class_name TopSpinArt
## Top Spin's pixel pieces, in the games' shared look (GameFx; docs/ideas_roadmap.md, "The games'
## look"): hard pixels on the 4 px grid (1 board px = 4 px), the dark outline on the play pieces
## only, lit from the top left.
##   - the tops: Beyblade-like tops, "sprite-stacked" like Pal Prix's toys (slices bottom first:
##     the metal tip, the driver, the wheel, the blades' side, the face), so a wobbling top leans
##     and shows its body; the blade ring turning in frames, a haze behind it when it spins fast
##   - the bowl: raised like the race games' tracks: the rim's top, its outer side face on the
##     near side, the far inner wall, the floor shaded as a hollow, the rim's shadow inside it, the
##     ways out (dark pockets) cut through the rim; the near rim is a separate picture drawn over
##     the tops
##   - the places round it, one per world with its own palette and time of day (the Retry rules:
##     no outlines, few colours in dithered steps, the world's light over everything, nothing
##     scattered about): a tatami room in the morning sun, a veranda in the leaves' shade, a
##     lacquered table by lamplight, a bathroom in daylight, a workbench under a hanging lamp, a
##     festival stage at night

const OUTLINE := Color8(40, 30, 40)
const CREAM := Color8(250, 244, 226)

static var _cache := {}

static func _tex(img: Image) -> Texture2D:
	return ImageTexture.create_from_image(img)

static func dith(f: float, x: int, y: int) -> bool:
	return GameFx.dithered(f, x, y)

# ================================================================== THE TOPS

## The blade rings (a Beyblade's attack ring seen from above): the outline's reach at angle `a`
## (0..1 of the top's radius) and how many blades (its turn repeats every TAU / count). The rivals'
## rings tell how they fight, the same in every world (the user, 2026-10-19: "they're Beyblades,
## they should have blades"): the rookie's three little fins, the charger's three hooks, the wall's
## round shield, the heavy's four lugs, a champion's four scythes. Yours is new in each world:
## four blades, a star, petals, waves, gear teeth, a dragon
const BLADES := { "fins3": 3, "hooks3": 3, "shield": 12, "lugs4": 4, "scythe4": 4, "blades4": 4, "star5": 5, "petals6": 6, "wave5": 5, "gear10": 10, "dragon3": 3 }
const FRAMES := 8                       # a top's turn: frames per blade (the ring repeats every blade)
const SEAT_R := 4.0                     # the pal's ball's radius (board px: 16 px at x2), set in the middle

static func blade_r(kind: String, a: float) -> float:
	var n: int = BLADES.get(kind, 4)
	var u := fposmod(a * n / TAU, 1.0)            # 0..1 across one blade
	match kind:
		"fins3":
			return 0.8 + 0.2 * sqrt(maxf(0.0, 1.0 - absf(u - 0.5) / 0.2))
		"hooks3":
			return 0.6 + 0.4 * pow(u / 0.86, 0.8) if u < 0.86 else 0.6 + 0.4 * (1.0 - (u - 0.86) / 0.14)
		"shield":
			return 0.93 + 0.07 * maxf(0.0, cos(u * TAU))
		"lugs4":
			return 1.0 if absf(u - 0.5) < 0.2 else 0.8
		"scythe4":
			return 0.56 + 0.44 * pow(u / 0.84, 1.4) if u < 0.84 else 0.56 + 0.44 * (1.0 - (u - 0.84) / 0.16)
		"blades4":
			return 0.64 + 0.36 * pow(u / 0.72, 0.6) if u < 0.72 else 0.64 + 0.36 * (1.0 - (u - 0.72) / 0.28)
		"star5":
			return 0.72 + 0.28 * (1.0 - absf(u - 0.5) * 2.0)
		"petals6":
			return 0.76 + 0.24 * sqrt(maxf(0.0, sin(u * PI)))
		"wave5":
			return 0.86 + 0.14 * sin(u * TAU)
		"gear10":
			return 1.0 if u < 0.5 else 0.84
		"dragon3":
			return 0.56 + 0.44 * pow(u / 0.8, 0.7) if u < 0.8 else 0.56 + 0.44 * (1.0 - (u - 0.8) / 0.2)
	return 1.0

## A top's pieces, all from its colour and its blade ring (cached):
##   slices: the metal tip, the driver, the wheel's base (bottom first; the same at every turn)
##   faces / unders: FRAMES each, the ring seen from above turning one blade's width / the blades'
##     thickness under it (its side, in shade)
##   blur: a haze out to the blades' reach (drawn under the face while it spins fast)
##   period: one blade's turn (rad)
static func top_parts(main: Color, rf: float, kind: String, seat_r := SEAT_R) -> Dictionary:
	var key := "top_%s_%.1f_%s_%.1f" % [main.to_html(), rf, kind, seat_r]
	if _cache.has(key):
		return _cache[key]
	var n := int(ceilf(rf)) * 2 + 2
	var period := TAU / int(BLADES.get(kind, 4))
	var slices: Array[Texture2D] = []
	for sp in [[1.6, Color8(176, 176, 190), Color8(110, 110, 124)], [rf * 0.42, Color8(84, 86, 104), Color8(56, 56, 72)],
			[rf * 0.64, main.darkened(0.5), main.darkened(0.62)]]:
		slices.append(_tex(_disc_img(n, sp[0], sp[1], sp[2])))
	var faces: Array[Texture2D] = []
	var unders: Array[Texture2D] = []
	for f in FRAMES:
		var rot := float(f) / FRAMES * period
		var mask := _blade_mask(n, rf, kind, rot)
		faces.append(_tex(_face_img(n, rf, main, mask, rot, seat_r)))
		unders.append(_tex(_under_img(n, main, mask)))
	var out := { "slices": slices, "faces": faces, "unders": unders, "blur": _tex(_blur_img(n, rf, main, kind)), "period": period,
		"arcs": speed_arc_frames(rf), "rf": rf }
	_cache[key] = out
	return out

static func _disc_img(n: int, r: float, col: Color, shade: Color) -> Image:
	var img := Image.create(n, n, false, Image.FORMAT_RGBA8)
	var c := Vector2(n / 2.0, n / 2.0)
	for y in n:
		for x in n:
			var o := Vector2(x + 0.5, y + 0.5) - c
			var d := o.length()
			if d > r:
				continue
			var col2 := col
			if d > r - 1.0:
				col2 = OUTLINE
			elif o.x + o.y > r * 0.3:
				col2 = shade                                  # its far side, in shade
			img.set_pixel(x, y, col2)
	return img

## The board px the blade ring covers at this turn (its silhouette)
static func _blade_mask(n: int, rf: float, kind: String, rot: float) -> PackedByteArray:
	var m := PackedByteArray()
	m.resize(n * n)
	var c := Vector2(n / 2.0, n / 2.0)
	for y in n:
		for x in n:
			var o := Vector2(x + 0.5, y + 0.5) - c
			if o.length() <= rf * blade_r(kind, o.angle() - rot):
				m[y * n + x] = 1
	return m

static func _inside(m: PackedByteArray, n: int, x: int, y: int) -> bool:
	return x >= 0 and y >= 0 and x < n and y < n and m[y * n + x] == 1

## The face: the blades in the top's colour (lit top-left, a bevel catching the light on their
## top-left edges, shaded on the others), the wheel's dark groove, the energy ring with two marks
## turning on it, and in the middle the socket the pal is set into (the user, 2026-10-19: the pal
## embedded right in the middle, the top its vehicle): a dark seat in a metal lip, the size of the
## pal's ball; the dark outline round it all
static func _face_img(n: int, rf: float, main: Color, m: PackedByteArray, rot: float, seat_r: float) -> Image:
	var img := Image.create(n, n, false, Image.FORMAT_RGBA8)
	var c := Vector2(n / 2.0, n / 2.0)
	var hi := main.lightened(0.32)
	var lo := main.darkened(0.24)
	var seat := seat_r + 1.0 * seat_r / SEAT_R                  # (the ball, and the lip round it)
	for y in n:
		for x in n:
			if not _inside(m, n, x, y):
				continue
			var o := Vector2(x + 0.5, y + 0.5) - c
			var d := o.length()
			var col := main
			if not (_inside(m, n, x + 1, y) and _inside(m, n, x - 1, y) and _inside(m, n, x, y + 1) and _inside(m, n, x, y - 1)):
				col = OUTLINE
			elif d < seat:
				col = Color8(46, 38, 56)                                # the pal's seat (its ball covers it)
				if d > seat - 1.0 * seat_r / SEAT_R:
					col = Color8(214, 218, 230) if o.x + o.y < 0.0 else Color8(136, 140, 158)   # the metal lip round it
			elif d < seat + maxf(1.4, rf * 0.16):
				col = main.lightened(0.55)                             # the energy ring, a lighter tint...
				if fposmod(o.angle() - rot, PI) < 0.45:
					col = main.darkened(0.2)                           # ...with two marks turning on it
			elif d < seat + maxf(1.4, rf * 0.16) + 1.0:
				col = main.darkened(0.45)                              # the groove
			else:
				var lit := -(o.x + o.y) / maxf(d, 0.01)
				if lit > 0.5:
					col = hi
				elif lit < -0.5:
					col = lo
				# the bevel: the blade's edges facing the light catch it, the others fall in shade
				if not _inside(m, n, x - 2, y) or not _inside(m, n, x, y - 2):
					col = main.lightened(0.26)
				elif not _inside(m, n, x + 2, y) or not _inside(m, n, x, y + 2):
					col = main.darkened(0.26)
			img.set_pixel(x, y, col)
	return img

## The blades' thickness, seen under the face: the same silhouette in shade, outlined
static func _under_img(n: int, main: Color, m: PackedByteArray) -> Image:
	var img := Image.create(n, n, false, Image.FORMAT_RGBA8)
	for y in n:
		for x in n:
			if not _inside(m, n, x, y):
				continue
			var edge := not (_inside(m, n, x + 1, y) and _inside(m, n, x - 1, y) and _inside(m, n, x, y + 1) and _inside(m, n, x, y - 1))
			img.set_pixel(x, y, OUTLINE if edge else main.darkened(0.46))
	return img

## The ring spinning fast: a haze of its colour out to the blades' reach, denser where the blades
## sweep more of the circle (drawn under the face: it fills the gaps between the blades)
static func _blur_img(n: int, rf: float, main: Color, kind: String) -> Image:
	var img := Image.create(n, n, false, Image.FORMAT_RGBA8)
	var c := Vector2(n / 2.0, n / 2.0)
	var cov := {}
	for y in n:
		for x in n:
			var o := Vector2(x + 0.5, y + 0.5) - c
			var d := o.length()
			if d > rf or d < rf * 0.5:
				continue
			var key := int(d * 4.0)
			if not cov.has(key):
				var hits := 0
				for k in 96:
					if rf * blade_r(kind, k * TAU / 96.0) >= d:
						hits += 1
				cov[key] = hits / 96.0
			var cv: float = cov[key]
			if cv <= 0.0:
				continue
			var col := main.lightened(0.2)
			if -(o.x + o.y) / maxf(d, 0.01) > 0.6:
				col = main.lightened(0.45)
			col.a = 0.2 + 0.55 * cv
			img.set_pixel(x, y, col)
	return img

## The top as one picture (its slices, its blades' side, its face; the pal set in its middle), for
## the how-to card: twice the board's px, so the pal's ball keeps the size it has in the game
static func top_icon(main: Color, rf: float, kind: String, rider: Texture2D = null) -> Texture2D:
	var key := "icon_%s_%.1f_%s_%s" % [main.to_html(), rf, kind, rider.resource_path if rider else ""]
	if _cache.has(key):
		return _cache[key]
	var parts := top_parts(main, rf, kind)
	var layers: Array = []
	layers.append_array(parts["slices"])
	layers.append(parts["unders"][0])
	layers.append(parts["faces"][0])
	var n: int = (layers[0] as Texture2D).get_width()
	var img := Image.create(n, n + layers.size(), false, Image.FORMAT_RGBA8)
	for k in layers.size():
		var src := (layers[k] as Texture2D).get_image()
		img.blend_rect(src, Rect2i(0, 0, n, n), Vector2i(0, layers.size() - 1 - k))
	img.resize(img.get_width() * 2, img.get_height() * 2, Image.INTERPOLATE_NEAREST)
	if rider:
		var ball := rider.get_image()
		ball.convert(Image.FORMAT_RGBA8)
		img.blend_rect(ball, Rect2i(Vector2i.ZERO, ball.get_size()), Vector2i(n - ball.get_width() / 2, n - ball.get_height() / 2))
	_cache[key] = _tex(img)
	return _cache[key]

## The ring of a top's spin seen as a blur round its edge (fast): arcs of light at the rim
static func speed_arc_frames(rf: float) -> Array[Texture2D]:
	var key := "arcs_%.1f" % rf
	if _cache.has(key):
		return _cache[key]
	var out: Array[Texture2D] = []
	var n := int(ceilf(rf)) * 2 + 6
	var c := Vector2(n / 2.0, n / 2.0)
	for f in 6:
		var img := Image.create(n, n, false, Image.FORMAT_RGBA8)
		for y in n:
			for x in n:
				var o := Vector2(x + 0.5, y + 0.5) - c
				var d := o.length()
				if absf(d - (rf + 1.2)) > 0.6:
					continue
				var a := fposmod(o.angle() - f * TAU / 18.0, TAU / 3.0)
				if a < 0.7:
					img.set_pixel(x, y, Color(1, 1, 1, 0.75 - a * 0.7))
		out.append(_tex(img))
	_cache[key] = out
	return out

# ================================================================== THE BOWL

## The bowl from above, raised like the race games' track: [the floor (it goes on under the rim,
## so the rim can shift over it: the 3D tilt), the rim's far half (its top, the far inner wall,
## the ways out), the rim's near half (its top and outer side face, drawn over the tops)], each
## n x n board px round the bowl's middle. bowl: a BOWLS entry; r, rim_w, rim_h: the floor's
## radius, the rim's width and height (px); gaps: the ways out's angles; gap_half; slimes:
## puddles (px from the middle)
static func bowl_images(bowl: Dictionary, r: float, rim_w: float, rim_h: float, gaps: Array, gap_half: float, slimes: Array) -> Array:
	var px := 4.0
	var rr := r / px
	var rw := rim_w / px
	var rh := rim_h / px
	var n := int(ceilf((rr + rw) * 2.0)) + 8
	var floor_img := Image.create(n, n, false, Image.FORMAT_RGBA8)
	var back := Image.create(n, n, false, Image.FORMAT_RGBA8)
	var front := Image.create(n, n, false, Image.FORMAT_RGBA8)
	var c := Vector2(n / 2.0, n / 2.0)              # the floor's middle
	var lip := c - Vector2(0, rh)                    # the rim's top is rh higher
	var light_dir := Vector2(-1, -1).normalized()
	var pocket := Color8(22, 18, 30)
	for y in n:
		for x in n:
			var p := Vector2(x + 0.5, y + 0.5)
			var d0 := (p - c).length()
			var d1 := (p - lip).length()
			var ang0 := (p - c).angle()
			var ang1 := (p - lip).angle()
			var col := Color(0, 0, 0, 0)
			var is_front := false
			if d1 >= rr and d1 < rr + rw:
				# --- the rim's top; a pocket cut through it at each way out ---
				var g1 := _gap_at(gaps, gap_half, ang1)
				if g1 >= 0.0:
					if g1 > 0.86:
						col = OUTLINE                                    # the cut's edges
					elif d0 < rr + rw - 0.5:
						col = pocket.lerp(Color8(54, 46, 62), clampf((d1 - rr) / rw, 0.0, 1.0) * 0.6)
				else:
					var t := (d1 - rr) / rw
					var lit := (p - lip).normalized().dot(light_dir)
					var gr := sin(d1 * 1.4 + sin(ang1 * 9.0 + d1 * 0.08) * 1.8)
					col = bowl["rim"]
					if gr > 0.78:
						col = bowl["rim_dark"]                           # its grain running round
					if bowl["room"] == "workshop" and absf(d1 - (rr + rw * 0.5)) < 0.8 and int(fposmod(ang1, TAU) / TAU * 36.0) % 2 == 0:
						col = bowl["rim_hi"]                             # rivets round the iron rim
					if t > 0.7:
						col = bowl["rim_hi"] if lit > 0.15 else (bowl["rim_dark"] if lit < -0.2 else col)   # the outer bevel, lit top-left
					elif t < 0.24 and lit < -0.25:
						col = bowl["rim_hi"]                             # the inner lip catches the light on the far side
					if d1 < rr + 1.0 or d1 >= rr + rw - 1.0:
						col = OUTLINE
					is_front = p.y > lip.y
			elif d1 >= rr + rw and d0 < rr + rw and p.y > c.y - rh:
				# --- the rim's outer side face, on the near side ---
				if _gap_at(gaps, gap_half, ang0) < 0.0:
					var down := clampf((d0 - (rr + rw - rh)) / rh, 0.0, 1.0)
					col = (bowl["rim_dark"] as Color).darkened(0.1 + 0.3 * down)
					if d0 >= rr + rw - 1.0:
						col = OUTLINE
					is_front = true
			elif d0 >= rr and d1 < rr:
				# --- the far inner wall, between the floor's edge and the lip ---
				var g2 := _gap_at(gaps, gap_half, ang1)
				if g2 >= 0.0:
					col = OUTLINE if g2 > 0.86 else pocket
				else:
					var k := clampf((d0 - rr) / maxf(rh, 0.01), 0.0, 1.0)
					var side := (p - c).normalized().x
					col = (bowl["rim"] as Color).darkened(0.16 + 0.24 * (1.0 - k)).lerp(bowl["rim_hi"], 0.3 * maxf(0.0, side))
					if d0 < rr + 1.0:
						col = OUTLINE                                    # where it meets the floor
			if d0 < rr + rw - 0.5:
				# --- the floor (on under the rim; dark in the ways out): its material, shaded as a
				# hollow, the rim's shadow, puddles ---
				var fc := pocket if d0 >= rr and _gap_at(gaps, gap_half, ang0) >= 0.0 else _floor_px(bowl, p - c, x, y)
				if d0 < rr or fc == pocket:
					var v := (p - c) / rr
					var sdot := v.dot(light_dir)
					if fc != pocket:
						if sdot > 0.66 or (sdot > 0.5 and dith((sdot - 0.5) / 0.16, x, y)):
							fc = fc.darkened(0.1)
						elif sdot < -0.7 or (sdot < -0.56 and dith((-0.56 - sdot) / 0.14, x, y)):
							fc = fc.lightened(0.07)
						var q0 := p - light_dir * 2.6
						if (q0 - lip).length() >= rr - 0.2 and p.y < c.y + rr * 0.3:
							fc = fc.darkened(0.2)
						if d0 > rr - 10.0 and _gap_at(gaps, gap_half, ang0) >= 0.0:
							fc = fc.darkened(0.1)
						for s in slimes:
							var sd0 := ((p - c) * px - (s as Vector2)).length() + sin(ang0 * 5.0 + (s as Vector2).x) * 6.0
							if sd0 < 70.0:
								fc = _slime_px(sd0, x, y)
				else:
					fc = fc.darkened(0.3)                                 # (under the rim: only seen as it shifts)
				floor_img.set_pixel(x, y, fc)
			if col.a > 0.0:
				(front if is_front else back).set_pixel(x, y, col)
	return [floor_img, back, front]

## How far into a way out `ang` is (0 its middle .. 1 its edge), or -1 outside every one
static func _gap_at(gaps: Array, gap_half: float, ang: float) -> float:
	for g in gaps:
		var dd := absf(angle_difference(ang, g))
		if dd < gap_half:
			return dd / gap_half
	return -1.0

## The bowl's floor at `o` (board px from its middle): its own wood (grain and turned rings) or
## lacquer with gold swirls, a dragon's scales, porcelain round water, a brass plate
static func _floor_px(bowl: Dictionary, o: Vector2, x: int, y: int) -> Color:
	var px := 4.0
	var d := o * px
	var r := d.length()
	var ang := d.angle()
	var g := sin(d.y * 0.11 + sin(d.x * 0.012 + d.y * 0.004) * 2.6 + sin(d.x * 0.031) * 0.6)
	var col: Color = bowl["floor"]
	if g > 0.72:
		col = bowl["grain"]
	elif g < -0.9:
		col = bowl["light"]
	if r > 40.0 and fposmod(r, 52.0) < px:
		col = bowl["lathe"]                                   # the turned rings
	if r < 16.0 and r > 9.0:
		col = bowl["lathe"]                                   # the lathe's centre mark
	if bowl.get("swirls", false):
		var sw := sin(ang * 2.0 + r * 0.03)
		if absf(sw) < 0.035 and r > 90.0 and int(r / 60.0) % 2 == 0:
			col = Color8(176, 140, 64)                       # gold maki-e swirls on the black lacquer
	if bowl.get("scales", false):
		var row := int(r / 34.0)
		var ca := fposmod(ang * r / 34.0 + row * 0.5, 1.0)
		if fposmod(r, 34.0) < px and (ca < 0.16 or ca > 0.84):
			col = (bowl["lathe"] as Color).darkened(0.12)     # a dragon's scales: rows of little arcs
	match bowl["room"]:
		"bathroom":
			if r < 150.0:
				col = Color8(170, 214, 230) if r > 140.0 else Color8(186, 226, 238)   # the water in the middle
				if fposmod(r, 38.0) < px and r > 30.0:
					col = Color8(214, 240, 248)
		"workshop":
			if (int(d.x / 24.0) + int(d.y / 24.0)) % 2 == 0 and fposmod(d.x, 24.0) < px:
				col = bowl["grain"]                           # engraved lines on the brass
	return col

## A puddle on the floor (the soap in the Toilet Bowl): pale foam with a glossy edge
static func _slime_px(sd: float, x: int, y: int) -> Color:
	var base := Color8(206, 232, 246)
	if sd > 62.0:
		return Color8(150, 196, 220)
	if sd < 20.0 or ((x * 7 + y * 3) % 11 == 0):
		return Color8(236, 248, 255)
	return base

# ================================================================== THE PLACES

## The palettes and the light of each place (see room_image)
const TATAMI := [Color8(170, 168, 112), Color8(184, 180, 120), Color8(196, 190, 130), Color8(208, 202, 144)]
const VERANDA := [Color8(150, 112, 80), Color8(164, 124, 88), Color8(178, 138, 98), Color8(190, 150, 108)]
const LACQUER := [Color8(40, 16, 22), Color8(52, 20, 26), Color8(64, 24, 30), Color8(78, 30, 34)]
const TILES := [Color8(226, 238, 240), Color8(236, 246, 246), Color8(198, 230, 222), Color8(210, 238, 230)]
const BENCH := [Color8(132, 92, 62), Color8(148, 104, 70), Color8(164, 118, 80), Color8(180, 132, 90)]
const STAGE := [Color8(58, 40, 44), Color8(70, 48, 50), Color8(84, 58, 58), Color8(98, 68, 64)]

static var _noise: FastNoiseLite

static func _n(x: float, y: float, seed_n: int) -> float:
	if _noise == null:
		_noise = FastNoiseLite.new()
		_noise.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
		_noise.frequency = 0.02
	_noise.seed = seed_n
	return (_noise.get_noise_2d(x, y) + 1.0) * 0.5

## The place round the bowl (w x h board px), the bowl's drop shadow on it, and the world's light
## baked over it. c: the bowl's middle (board px), rr: its outer radius (board px)
static func room_image(kind: String, w: int, h: int, c: Vector2, rr: float) -> Image:
	var key := "room_%s_%d_%d_%s_%.1f" % [kind, w, h, c, rr]
	if _cache.has(key):
		return _cache[key]
	var img := Image.create(w, h, false, Image.FORMAT_RGBA8)
	var sc := c + Vector2(3.0, 4.0)                  # the bowl's shadow: down and right of it
	for y in h:
		for x in w:
			var col := _surface(kind, x, y, w, h)
			var sd := Vector2(x + 0.5, y + 0.5).distance_to(sc)
			if sd < rr + 1.0 or (sd < rr + 2.5 and dith(0.5, x, y)):
				col = col.lerp(Color8(30, 22, 40), 0.42)
			col = lit(kind, col, Vector2(x, y), w, h)
			img.set_pixel(x, y, col)
	_cache[key] = img
	return img

## The place's own surface, in its palette (dithered steps, no outlines, nothing scattered on it)
static func _surface(kind: String, x: int, y: int, w: int, h: int) -> Color:
	match kind:
		"tatami":
			# mats of 60 x 30, every other row turned, woven along their length, dark cloth borders
			var row := y / 30
			var mx := x + (30 if row % 2 else 0)
			var lx := mx % 60
			var ly := y % 30
			if ly < 2 or ly >= 29:
				return Color8(52, 66, 58) if ly != 1 else Color8(64, 80, 70)        # the heri (border cloth)
			if lx == 0:
				return Color8(150, 146, 98)
			var v := _n(x * 1.6, y * 0.6, 11) * 0.6 + (0.3 if (lx / 2) % 2 == 0 else 0.15)
			return GameFx.steps(v, TATAMI, x, y)
		"veranda":
			# long boards across, their seams, the grain's soft streaks
			var plank := y / 14
			var ly2 := y % 14
			if ly2 == 0:
				return Color8(104, 74, 54)
			var v2 := _n(x * 0.35 + plank * 37.0, y * 2.0, 23) * 0.8 + (0.12 if plank % 2 else 0.0)
			return GameFx.steps(v2, VERANDA, x, y)
		"lacquer":
			# a lacquered table: deep red-black, its glossy streak, a gold line inset round it
			var e := mini(mini(x, y), mini(w - 1 - x, h - 1 - y))
			if e == 6:
				return Color8(196, 156, 70)
			var v3 := _n(x * 0.4, y * 0.4, 5) * 0.7 + 0.15
			var cl := GameFx.steps(v3, LACQUER, x, y)
			var gloss := absf((x - y * 0.55) - w * 0.32)
			if gloss < 7.0 or (gloss < 10.0 and dith(0.5, x, y)):
				cl = cl.lightened(0.1)
			return cl
		"bathroom":
			# square tiles, white and mint by turns, grout between them
			var tx := x % 18
			var ty := y % 18
			if tx == 0 or ty == 0:
				return Color8(176, 192, 196)
			var mint := ((x / 18) + (y / 18)) % 2 == 1
			var base: Color = TILES[2] if mint else TILES[0]
			if tx <= 3 and ty <= 3 and tx + ty <= 4:
				base = base.lightened(0.35)                                      # each tile's glaze catching the light
			return base
		"workshop":
			# a workbench: thick planks running down, their seams, the grain
			var p := x / 20
			if x % 20 == 0:
				return Color8(96, 64, 44)
			var v4 := _n(x * 2.0, y * 0.3 + p * 41.0, 31) * 0.8 + (0.1 if p % 2 else 0.0)
			return GameFx.steps(v4, BENCH, x, y)
		"festival":
			# a wooden stage at night: boards across, their seams
			var plank2 := y / 16
			if y % 16 == 0:
				return Color8(40, 28, 34)
			var v5 := _n(x * 0.3 + plank2 * 53.0, y * 2.0, 47) * 0.8
			return GameFx.steps(v5, STAGE, x, y)
	return Color8(58, 66, 84)

## The world's light over a colour at board px `p` (the place and the bowl painted under it): the
## morning sun through the shoji, the leaves' shade, a lamp's pool, daylight, a hanging lamp, the
## lanterns at night (dithered steps, like the race games' worlds)
static func lit(kind: String, col: Color, p: Vector2, w: int, h: int) -> Color:
	var x := int(p.x)
	var y := int(p.y)
	match kind:
		"tatami":
			# a slanting band of sun through the shoji (its lattice's thin shadows in it), the rest
			# in the room's cool shade
			var u := p.x + p.y * 0.55
			var into := clampf(1.0 - absf(u - w * 0.42) / (w * 0.22), 0.0, 1.0)
			var sun := into > 0.25 or (into > 0.12 and dith((into - 0.12) / 0.13, x, y))
			if sun:
				var lat := fposmod(p.x - p.y * 0.9, 30.0) < 1.0 or fposmod(p.y + p.x * 0.18, 34.0) < 1.0
				if lat:
					return col.lerp(Color8(120, 110, 90), 0.12)
				return Color(minf(1.0, col.r * 1.1 + 0.07), minf(1.0, col.g * 1.08 + 0.05), minf(1.0, col.b * 1.0 + 0.02))
			return col.lerp(Color8(70, 84, 104), 0.14)
		"veranda":
			# the eaves' and a tree's shade towards the top-left, with flecks of sun through the
			# leaves; the rest in the warm afternoon sun
			var reach := clampf(1.0 - (p.x * 0.8 + p.y) / (w * 0.75), 0.0, 1.0)
			var n := _n(p.x * 1.1, p.y * 1.1, 77) * 0.5 + reach * 0.62
			var shade := n > 0.62 or (n > 0.56 and dith((n - 0.56) / 0.06, x, y))
			if shade:
				var fleck := ((x / 2 * 73856093) ^ (y / 2 * 19349663)) & 63
				if fleck < 3:
					return Color(minf(1.0, col.r * 1.14 + 0.06), minf(1.0, col.g * 1.12 + 0.05), col.b * 1.02)
				return col.lerp(Color8(40, 70, 64), 0.3)
			return Color(minf(1.0, col.r * 1.06 + 0.04), minf(1.0, col.g * 1.04 + 0.03), col.b)
		"lacquer", "workshop":
			# a lamp's warm pool round the bowl, the corners in the dark
			var cen := Vector2(w * 0.48, h * 0.54)
			var k := clampf(1.0 - (p.distance_to(cen) - w * 0.47) / (w * 0.26), 0.0, 1.0)
			var steps_n := k * 3.0
			k = (floorf(steps_n) + (1.0 if steps_n - floorf(steps_n) > GameFx.DITHER[y % 2][x % 2] else 0.0)) / 3.0
			var warm := Color8(255, 200, 130) if kind == "lacquer" else Color8(255, 214, 150)
			return col.darkened(0.55 * (1.0 - k)).lerp(warm, 0.08 * k)
		"bathroom":
			# bright daylight from a frosted window up and to the left
			var k2 := clampf(1.0 - (p.x + p.y) / (w + h) * 1.2, 0.0, 1.0)
			if k2 > 0.4 or (k2 > 0.3 and dith((k2 - 0.3) / 0.1, x, y)):
				return col.lightened(0.06)
			return col.lerp(Color8(150, 176, 196), 0.06)
		"festival":
			# night: the lanterns over the stage light the bowl, the edges fall away into the dark
			var cen2 := Vector2(w * 0.5, h * 0.54)
			var k3 := clampf(1.0 - (p.distance_to(cen2) - w * 0.46) / (w * 0.26), 0.0, 1.0)
			var s3 := k3 * 3.0
			k3 = (floorf(s3) + (1.0 if s3 - floorf(s3) > GameFx.DITHER[y % 2][x % 2] else 0.0)) / 3.0
			return col.darkened(0.5 * (1.0 - k3)).lerp(Color8(255, 170, 110), 0.1 * k3)
	return col

## How the world's light falls on a moving piece (a top, a peg) at board px `p`: a multiplier
## (the same light as the place's, without the dither)
static func light_at(kind: String, p: Vector2, w: int, h: int) -> Color:
	match kind:
		"tatami":
			var into := clampf(1.0 - absf(p.x + p.y * 0.55 - w * 0.42) / (w * 0.22), 0.0, 1.0)
			return Color(1.0, 1.0, 1.0).lerp(Color(1.1, 1.08, 1.0), clampf(into * 2.0, 0.0, 1.0)) if into > 0.12 else Color(0.92, 0.94, 0.98)
		"veranda":
			var reach := clampf(1.0 - (p.x * 0.8 + p.y) / (w * 0.75), 0.0, 1.0)
			return Color(0.84, 0.92, 0.9) if _n(p.x * 1.1, p.y * 1.1, 77) * 0.5 + reach * 0.62 > 0.59 else Color(1.04, 1.03, 1.0)
		"lacquer", "workshop":
			var k := clampf(1.0 - (p.distance_to(Vector2(w * 0.48, h * 0.54)) - w * 0.47) / (w * 0.26), 0.0, 1.0)
			return Color(1, 1, 1).lerp(Color(0.5, 0.48, 0.52), 1.0 - k)
		"festival":
			var k2 := clampf(1.0 - (p.distance_to(Vector2(w * 0.5, h * 0.54)) - w * 0.46) / (w * 0.26), 0.0, 1.0)
			return Color(1.02, 0.98, 0.94).lerp(Color(0.56, 0.54, 0.66), 1.0 - k2)
	return Color(1, 1, 1)

# ================================================================== PEGS, GEARS

## A bouncer: a turned peg in the rim's colour as slices, bottom first (its dark foot, the body,
## the lit top with a lathe ring and a brass dot); 20 x 20 board px... drawn 4 px apart
static func peg_slices(bowl: Dictionary) -> Array[Texture2D]:
	var key := "peg_%s" % (bowl["rim"] as Color).to_html()
	if _cache.has(key):
		return _cache[key]
	var out: Array[Texture2D] = []
	var rim: Color = bowl["rim"]
	var hi: Color = bowl["rim_hi"]
	var dk: Color = bowl["rim_dark"]
	for layer in 3:
		const S := 18
		var img := Image.create(S, S, false, Image.FORMAT_RGBA8)
		var c := Vector2(S / 2.0, S / 2.0)
		for y in S:
			for x in S:
				var o := Vector2(x + 0.5, y + 0.5) - c
				var d := o.length()
				if d > 7.5:
					continue
				var col := dk
				if d > 6.5:
					col = OUTLINE
				elif layer == 1:
					col = dk if o.x + o.y > 0.0 else rim
				elif layer == 2:
					if d > 5.0 and d < 6.0:
						col = dk                                         # a lathe ring on its top
					elif d < 2.0:
						col = Color8(236, 200, 110) if o.x + o.y < 0 else Color8(186, 146, 70)   # the brass dot
					else:
						col = hi if o.x + o.y < -1.0 else rim
				img.set_pixel(x, y, col)
		out.append(_tex(img))
	_cache[key] = out
	return out

## A gear plate (the Clockwork Bowl), frame `f` of its teeth's turn (12 teeth: a 30 degree turn in
## 6 frames), flush with the floor: brass lit top-left, its spokes and hub, outlined
static func gear(r_px: float, f: int) -> Texture2D:
	var key := "gear_%.0f_%d" % [r_px, f]
	if _cache.has(key):
		return _cache[key]
	var rr := r_px / 4.0
	var n := int(ceilf(rr)) * 2 + 6
	var img := Image.create(n, n, false, Image.FORMAT_RGBA8)
	var c := Vector2(n / 2.0, n / 2.0)
	var rot := float(f) / 6.0 * TAU / 12.0
	for y in n:
		for x in n:
			var o := Vector2(x + 0.5, y + 0.5) - c
			var d := o.length()
			var a := o.angle() - rot
			var tooth := 1.6 if fposmod(a * 12.0 / TAU, 1.0) < 0.5 else 0.0
			if d > rr + tooth:
				continue
			var col := Color8(226, 190, 108) if o.x + o.y < 0 else Color8(198, 160, 82)
			if d > rr + tooth - 1.0:
				col = OUTLINE
			elif d < 5.0:
				col = Color8(120, 92, 50) if d > 2.0 else OUTLINE
			elif absf(d - rr * 0.62) < 0.6:
				col = Color8(170, 132, 66)
			elif fposmod(a * 5.0 / TAU, 1.0) < 0.12 and d < rr * 0.62:
				col = Color8(170, 132, 66)                           # its spokes
			img.set_pixel(x, y, col)
	_cache[key] = _tex(img)
	return _cache[key]
