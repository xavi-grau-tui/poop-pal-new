extends RefCounted
class_name SumoArt
## Paper Sumo's stages, painted in code (2026-10-16): each world's place, the platform with the
## ring drawn on it and the spotlight from above, as pixel art on a 4 px grid (PX) with two-pixel
## dark outlines. World 1 is the prototype's wooden box, unchanged; then a flat rock in a spring
## koi pond (sakura, an arched bridge, a stone lantern), a log raft on an autumn stream (maples, a
## waterfall), a landing pad on the Moon (the Earth, a toy rocket, a dome), a tree stump in a summer
## forest (beetle sumo is fought on a stump), a festival stage at a shrine at night.
## (The rivals are drawn by the pal renderer: tools/art/sumo_rivals.py -> textures/minigames/sumo.)

# --- the stage's geometry (play-area coordinates, 950x948; paper_sumo.gd uses these) ---
const PX := 4                         # world px per stage pixel
const W := 950.0
const H := 948.0
const RING_C := Vector2(475, 690)     # the ring's centre; the wrestlers stand on this line
const RING_RX := 330.0
const RING_RY := 118.0
const FRONT_Y := 846.0                # where the box's lid ends and its front face begins
const STUMP := Vector2(440, 176)      # a round top (the pond's rock, the stump): an ellipse round the ring
const DARK := 0.38                    # how much darker everything outside the spotlight is
const ROUND := [1, 4]                 # the worlds whose ring is on a round top (STUMP), not a box
const OUTLINE := Color8(70, 44, 30)
const MARGIN := 11                    # (stage px) the place behind is painted this far past the screen (the 3D tilt shifts it)

# the wooden box (world 1, the prototype's)
const WALL := Color8(236, 220, 192)
const WALL_LINE := Color8(222, 202, 170)
const BOX_TOP := Color8(196, 150, 96)
const BOX_LINE := Color8(176, 130, 80)
const BOX_FRONT := Color8(150, 108, 62)
# the ring
const SAND := Color8(234, 212, 162)
const SAND_DARK := Color8(214, 190, 138)
const ROPE := Color8(206, 176, 96)
const ROPE_DARK := Color8(150, 120, 56)

static var _glow := false             # (a wall painter sets it: this pixel is lit already)
static var _cache := {}               # world -> its painted stage (painted once a session)
static var _live := false             # (painting the layers: what moves is left to StageLife)

## A world's stage (0-5): one pixel per PX world px
static func stage(world: int) -> Image:
	if _cache.has(world):
		return _cache[world]
	var w := int(ceil(W / PX))
	var h := int(ceil(H / PX))
	var img := Image.create(w, h, false, Image.FORMAT_RGBA8)
	var stump := world in ROUND                           # (a rock, a stump: a round top)
	var inside := PackedByteArray()
	inside.resize(w * h)
	for y in h:
		for x in w:
			inside[y * w + x] = 1 if _in_box(_px(x, y), stump) else 0
	for y in h:
		for x in w:
			var p := _px(x, y)
			var col: Color
			_glow = false
			if inside[y * w + x] == 0:
				col = _wall(world, p, x, y)
			else:
				# the box's dark outline, two pixels thick, and the edge between lid and front
				var edge := false
				for dy in range(-2, 3):
					for dx in range(-2, 3):
						var nx := x + dx
						var ny := y + dy
						if nx < 0 or ny < 0 or nx >= w or ny >= h or inside[ny * w + nx] == 0:
							edge = true
				if edge or _on_rim(p, stump):
					col = OUTLINE
				elif _on_front(p, stump):
					col = _front(world, p, x, y)
				else:
					col = _ring(world, p, _lid(world, p, x, y))
			img.set_pixel(x, y, col if _glow else col.darkened(1.0 - _light(p)))
	_cache[world] = img
	return img

## A world's stage in two layers, for the 3D tilt and the life on it (the games' shared look):
## [the place behind (painted on under the box too, so it can shift behind it), the box with its
## ring (clear round it)]; what moves (the festival's lanterns) is left out: StageLife draws it
static func stage_layers(world: int) -> Array:
	var key := "layers_%d" % world
	if _cache.has(key):
		return _cache[key]
	var w := int(ceil(W / PX))
	var h := int(ceil(H / PX))
	var back := Image.create(w + MARGIN * 2, h + MARGIN * 2, false, Image.FORMAT_RGBA8)
	var front := Image.create(w, h, false, Image.FORMAT_RGBA8)
	var stump := world in ROUND
	var inside := PackedByteArray()
	inside.resize(w * h)
	for y in h:
		for x in w:
			inside[y * w + x] = 1 if _in_box(_px(x, y), stump) else 0
	_live = true
	for y in range(-MARGIN, h + MARGIN):
		for x in range(-MARGIN, w + MARGIN):
			var pb := _px(x, y)
			_glow = false
			var cb := _wall(world, pb, x, y)
			back.set_pixel(x + MARGIN, y + MARGIN, cb if _glow else cb.darkened(1.0 - _light(pb)))
	for y in h:
		for x in w:
			var p := _px(x, y)
			if inside[y * w + x] == 1:
				var edge := false
				for dy in range(-2, 3):
					for dx in range(-2, 3):
						var nx := x + dx
						var ny := y + dy
						if nx < 0 or ny < 0 or nx >= w or ny >= h or inside[ny * w + nx] == 0:
							edge = true
				_glow = false
				var fc: Color
				if edge or _on_rim(p, stump):
					fc = OUTLINE
				elif _on_front(p, stump):
					fc = _front(world, p, x, y)
				else:
					fc = _ring(world, p, _lid(world, p, x, y))
				front.set_pixel(x, y, fc if _glow else fc.darkened(1.0 - _light(p)))
	_live = false
	_cache[key] = [back, front]
	return _cache[key]

## One of the festival's lanterns as a picture (red or white), its centre in the middle, for
## StageLife to hang and sway
static func lantern_tex(red: bool) -> Texture2D:
	var key := "lantern_%s" % red
	if _cache.has(key):
		return _cache[key]
	var img := Image.create(14, 18, false, Image.FORMAT_RGBA8)
	for y in 18:
		for x in 14:
			var l := (Vector2(x + 0.5, y + 0.5) - Vector2(7, 9)) * PX
			var c := _lantern_at(l, red)
			if c.a > 0.0:
				img.set_pixel(x, y, c)
	_cache[key] = ImageTexture.create_from_image(img)
	return _cache[key]

## The world position of a stage pixel's centre
static func _px(x: int, y: int) -> Vector2:
	return Vector2(x + 0.5, y + 0.5) * PX

## The box: its lid in perspective and its front face (the stump: its round top and bark)
static func _in_box(p: Vector2, stump: bool) -> bool:
	if stump:
		var d := p - RING_C
		if _ell(d, STUMP) <= 1.0:
			return true
		if p.y < RING_C.y or p.y >= H + 8.0:
			return false
		return absf(d.x) <= STUMP.x + maxf(0.0, p.y - 880.0) * 0.5      # (roots: wider at the foot)
	if p.y >= FRONT_Y:
		return p.x >= 20.0 and p.x <= W - 20.0 and p.y < H + 8.0
	if p.y < 470.0:
		return false
	var t := (p.y - 470.0) / (FRONT_Y - 470.0)
	return p.x >= lerpf(110.0, 20.0, t) and p.x <= lerpf(W - 110.0, W - 20.0, t)

static func _ell(d: Vector2, r: Vector2) -> float:
	return (d.x * d.x) / (r.x * r.x) + (d.y * d.y) / (r.y * r.y)

## The line between the lid and the front (the stump: the front half of its top's rim)
static func _on_rim(p: Vector2, stump: bool) -> bool:
	if not stump:
		return absf(p.y - FRONT_Y) < PX
	var d := p - RING_C
	if d.y < 0.0:
		return false
	var g := 2.0 * sqrt((d.x * d.x) / pow(STUMP.x, 4) + (d.y * d.y) / pow(STUMP.y, 4))
	return absf((_ell(d, STUMP) - 1.0) / maxf(g, 0.0001)) < 2.6

static func _on_front(p: Vector2, stump: bool) -> bool:
	return _ell(p - RING_C, STUMP) > 1.0 if stump else p.y > FRONT_Y

## The spotlight from above: a cone coming down onto the ring, and the ring (a little beyond its
## apron) fully lit; everything else darker, with a soft one-step edge between them
static func _light(p: Vector2) -> float:
	var d := p - RING_C
	var e := pow(d.x / (RING_RX + 44.0), 2) + pow(d.y / (RING_RY + 34.0), 2)
	var lit := e < 1.0
	var edge := e < 1.14
	if p.y < RING_C.y:                                    # the cone, narrow at the top
		var hw := lerpf(90.0, RING_RX + 30.0, clampf(p.y / RING_C.y, 0.0, 1.0))
		lit = lit or absf(d.x) < hw
		edge = edge or absf(d.x) < hw + 22.0
	return 1.0 if lit else (1.0 - DARK * 0.5 if edge else 1.0 - DARK)

static func _wall(world: int, p: Vector2, x: int, y: int) -> Color:
	match world:
		1: return _wall_pond(p, x, y)
		2: return _wall_stream(p, x, y)
		3: return _wall_moon(p, x, y)
		4: return _wall_forest(p)
		5: return _wall_night(p, x, y)
	# wall: wooden panels (a seam every 90 px, faint vertical grain)
	var col := WALL
	if fposmod(p.x, 90.0) < PX:
		col = WALL_LINE.darkened(0.08)
	elif sin(p.x * 0.2 + sin(p.y * 0.02 + p.x * 0.01) * 2.0) > 0.88:
		col = WALL_LINE
	return col

static func _lid(world: int, p: Vector2, x: int, y: int) -> Color:
	match world:
		1: return _lid_rock(p)
		2: return _lid_raft(p)
		3: return _lid_pad(p, x, y)
		4: return _lid_stump(p)
		5: return _lid_wood(p, Color8(226, 192, 134), Color8(206, 170, 114))      # pale hinoki
	return _lid_wood(p, BOX_TOP, BOX_LINE)

static func _front(world: int, p: Vector2, x: int, y: int) -> Color:
	match world:
		1: return _front_rock(p, x, y)
		2: return _front_raft(p)
		3: return _front_pad(p)
		4: return _front_bark(p, x, y)
		5: return _front_lacquer(p)
	var col := BOX_FRONT                                   # the front face
	if sin(p.y * 0.5 + sin(p.x * 0.015) * 1.5) > 0.82:
		col = BOX_FRONT.darkened(0.12)
	return col

## Wooden planks (seams closer together towards the back) and their grain
static func _lid_wood(p: Vector2, top: Color, line: Color) -> Color:
	var col := top
	if sin(p.y * 0.22 + sin(p.x * 0.01 + p.y * 0.03) * 2.0) > 0.8:
		col = line                                           # grain
	for i in 6:                                               # plank seams in perspective
		var f := float(i + 1) / 7.0
		if absf(p.y - lerpf(470.0, FRONT_Y, f * f)) < PX * 0.5:
			col = line.darkened(0.15)
	return col

## The ring on top of the lid: speckled sand (the stump: its own rings, sanded smooth), the
## twisted straw rope with dark edges, a darker apron, the two white start lines
static func _ring(world: int, p: Vector2, base: Color) -> Color:
	var d := p - RING_C
	var e := (d.x * d.x) / (RING_RX * RING_RX) + (d.y * d.y) / (RING_RY * RING_RY)
	var g := 2.0 * sqrt((d.x * d.x) / pow(RING_RX, 4) + (d.y * d.y) / pow(RING_RY, 4))
	var dist := (e - 1.0) / maxf(g, 0.0001)                  # ~ world px from the rope's middle line
	if absf(dist) < 9.0:
		var ang := atan2(d.y / RING_RY, d.x / RING_RX)
		return ROPE_DARK if fposmod(ang * 40.0 + dist * 0.12, 1.0) < 0.3 else ROPE   # twisted straw
	if absf(dist) < 17.0:
		return ROPE_DARK.darkened(0.25)                      # the rope's dark edges
	if dist < 0.0:
		var col := SAND if world != 3 else Color8(200, 200, 210)    # (the Moon: grey dust)
		if world == 4:
			col = _stump_wood(p, true)
		elif fposmod(sin(p.x * 12.9898 + p.y * 78.233) * 43758.5453, 1.0) < 0.07:
			col = SAND_DARK if world != 3 else Color8(176, 176, 190)    # speckles in the sand (scattered)
		for sx in [-1.0, 1.0]:                               # the two start lines
			if absf(p.x - (RING_C.x + sx * 40.0)) < PX and absf(d.y) < 16.0:
				col = Color.WHITE
		return col
	if dist < 34.0:
		return base.darkened(0.1) if world == 4 else (SAND_DARK if world != 3 else Color8(176, 176, 190))   # the ring's apron
	return base

# --------------------------------------------------------------- 2: the Pond Garden, spring

const WATER_Y := 392.0                # the pond's far edge (behind the rock)
const LILIES := [[Vector2(92, 468), Vector2(46, 13)], [Vector2(236, 522), Vector2(30, 9)], [Vector2(766, 472), Vector2(40, 12)],
	[Vector2(884, 556), Vector2(48, 14)], [Vector2(56, 932), Vector2(60, 18)], [Vector2(902, 936), Vector2(54, 16)]]
const BLOSSOM := [[Vector2(96, 64), 178.0], [Vector2(268, 34), 122.0], [Vector2(352, 120), 70.0], [Vector2(150, 206), 84.0],
	[Vector2(16, 250), 92.0], [Vector2(880, 40), 96.0], [Vector2(950, 150), 70.0]]

## A spring garden: a pale sky, soft hills, a sakura in bloom (its petals falling), a red arched
## bridge and a stone lantern across a koi pond; the ring is on a flat rock in the water
static func _wall_pond(p: Vector2, x: int, y: int) -> Color:
	var c := _blossom(p)
	if c.a > 0.0:
		return c
	c = _sakura_trunk(p)
	if c.a > 0.0:
		return c
	c = _stone_lantern(p)
	if c.a > 0.0:
		return c
	var wl := WATER_Y + 3.0 * sin(p.x * 0.02)
	if p.y < wl:
		c = _bridge(p)
		if c.a > 0.0:
			return c
		if p.y < 330.0 and _hash(x, y) < 0.004:
			return Color8(250, 204, 218)                       # a falling petal
		var yf := 262.0 + 26.0 * _noise(p.x * 0.005, 1.0) + 14.0 * sin(p.x * 0.011)
		var yn := 304.0 + 22.0 * _noise(p.x * 0.008, 4.0)
		if p.y > yn:
			if p.y > wl - PX * 1.5:
				return Color8(84, 130, 80)                         # the bank's edge
			if p.y > 346.0 and _noise(p.x * 0.03, p.y * 0.05) > 0.66:
				return Color8(236, 140, 172) if _hash(x, y) > 0.25 else Color8(248, 186, 206)   # azaleas
			return Color8(116, 166, 98) if _noise(p.x * 0.05, p.y * 0.1) > 0.4 else Color8(104, 154, 90)
		if p.y > yf:
			return Color8(150, 182, 156)                           # the near hills
		if p.y > yf - 40.0 and p.y > 230.0:
			return Color8(182, 200, 204)                           # the far hills, in the haze
		return Color8(214, 230, 242).lerp(Color8(246, 234, 228), clampf(p.y / 330.0, 0.0, 1.0))
	# the pond: the bridge upside down in it, lily pads, petals, ripples
	for l in LILIES:
		var lc: Vector2 = l[0]
		var lr: Vector2 = l[1]
		var q := ((p - lc) / lr).length_squared()
		if q < 1.0:
			var dd := p - lc
			if dd.y < 0.0 and absf(dd.x) < -dd.y * 0.5:
				break                                              # (the notch)
			if q > 0.72:
				return Color8(58, 104, 60)
			return Color8(120, 178, 98) if dd.y < -lr.y * 0.2 else Color8(96, 158, 86)
	var depth := clampf((p.y - wl) / 520.0, 0.0, 1.0)
	var col := Color8(132, 186, 200).lerp(Color8(88, 142, 168), depth)
	var rp := Vector2(p.x + 3.0 * sin(p.y * 0.4), 2.0 * wl - p.y)
	if rp.y > 280.0:
		var rb := _bridge(rp)
		if rb.a > 0.0:
			col = col.lerp(rb, 0.45)                               # the bridge's reflection
	if fposmod(p.y + sin(p.x * 0.03) * 6.0, 22.0) < 2.0 and _noise(p.x * 0.02, p.y * 0.02) > 0.5:
		col = col.lightened(0.12)                                  # ripples
	if _hash(x, y) < 0.005:
		col = Color8(248, 200, 214)                                # petals on the water
	for k in [[Vector2(140, 944), 1.0], [Vector2(812, 912), -1.0]]:   # koi, at the bottom
		var kc: Vector2 = k[0]
		var kd := (p - kc) / Vector2(36, 12)
		if kd.length_squared() < 1.0:
			return Color8(250, 248, 240) if sin(p.x * 0.3) > 0.4 else Color8(240, 112, 52)
		if absf(p.y - kc.y) < 10.0 - absf(p.x - (kc.x - 44.0 * float(k[1]))) * 0.8 and absf(p.x - (kc.x - 40.0 * float(k[1]))) < 10.0:
			return Color8(240, 112, 52)                            # (its tail)
	return col

static func _blossom(p: Vector2) -> Color:
	for b in BLOSSOM:
		var bc: Vector2 = b[0]
		var r: float = b[1]
		var d := (p - bc).length() / r + (_noise(p.x * 0.04, p.y * 0.04) - 0.5) * 0.5
		if d < 1.0:
			var n := _noise(p.x * 0.09, p.y * 0.09)
			if d > 0.86 and p.y > bc.y:
				return Color8(214, 140, 168)                       # the clusters' shaded undersides
			return Color8(252, 220, 230) if n > 0.62 else (Color8(242, 186, 206) if n > 0.3 else Color8(228, 160, 188))
	return Color(0, 0, 0, 0)

static func _sakura_trunk(p: Vector2) -> Color:
	for seg in [[Vector2(-20, 420), Vector2(70, 240), 32.0, 22.0], [Vector2(70, 240), Vector2(150, 120), 22.0, 13.0], [Vector2(96, 196), Vector2(330, 128), 12.0, 6.0],
			[Vector2(960, 300), Vector2(900, 120), 18.0, 10.0]]:
		var a: Vector2 = seg[0]
		var b: Vector2 = seg[1]
		var t := clampf((p - a).dot(b - a) / (b - a).length_squared(), 0.0, 1.0)
		var dist := (p - a.lerp(b, t)).length()
		var hw := lerpf(float(seg[2]), float(seg[3]), t) * 0.5
		if dist < hw:
			if dist > hw - PX:
				return OUTLINE
			var side := (p - a.lerp(b, t)).dot(Vector2(-(b - a).y, (b - a).x).normalized())
			return Color8(116, 76, 70) if side < 0.0 else Color8(86, 54, 52)
	return Color(0, 0, 0, 0)

## The arched bridge across the pond (a taikobashi): its deck, the rail and posts
static func _bridge(p: Vector2) -> Color:
	if p.x < 570.0 or p.x > 890.0:
		return Color(0, 0, 0, 0)
	var yd := 372.0 - 58.0 * sin(PI * (p.x - 570.0) / 320.0)
	var red := Color8(204, 66, 52)
	if p.y >= yd and p.y < yd + 12.0:
		return OUTLINE if p.y >= yd + 9.0 else red
	if p.y >= yd - 28.0 and p.y < yd - 22.0:
		return red.lightened(0.1)                                  # the rail
	if p.y >= yd - 22.0 and p.y < yd and fposmod(p.x - 570.0, 32.0) < 5.0:
		return red.darkened(0.15)                                  # the posts
	return Color(0, 0, 0, 0)

## A stone lantern (a tourou) on the far bank: base, post, the lit box, its roof and knob
static func _stone_lantern(p: Vector2) -> Color:
	if p.x < 830.0 or p.x > 910.0 or p.y < 274.0 or p.y > WATER_Y:
		return Color(0, 0, 0, 0)
	var stone := Color8(156, 154, 148)
	var dx := p.x - 870.0
	var part := ""
	if p.y > 378.0 and absf(dx) < 24.0:
		part = "base"
	elif p.y > 330.0 and absf(dx) < 10.0:
		part = "post"
	elif p.y > 304.0 and absf(dx) < 22.0:
		part = "box"
	elif p.y > 290.0 and absf(dx) < lerpf(18.0, 34.0, (p.y - 290.0) / 14.0):
		part = "roof"
	elif (p - Vector2(870, 284)).length() < 7.0:
		part = "knob"
	if part == "":
		return Color(0, 0, 0, 0)
	if part == "box" and absf(dx) < 10.0 and p.y > 310.0 and p.y < 324.0:
		_glow = true
		return Color8(255, 218, 140)                               # its light
	return stone.lightened(0.12) if dx < -6.0 else (stone.darkened(0.2) if dx > 8.0 else stone)

## The rock's flat top: stone with lighter and darker patches, moss round its edge
static func _lid_rock(p: Vector2) -> Color:
	var e := sqrt(_ell(p - RING_C, STUMP))
	if e > 0.84 and _noise(p.x * 0.05, p.y * 0.08) > 0.42:
		return Color8(122, 156, 84) if _noise(p.x * 0.2, p.y * 0.2) > 0.5 else Color8(140, 172, 94)
	var n := _noise(p.x * 0.02, p.y * 0.045)
	if n > 0.62:
		return Color8(186, 182, 172)
	if n < 0.3:
		return Color8(214, 210, 200)
	return Color8(202, 198, 188)

## The rock's side, down into the water
static func _front_rock(p: Vector2, x: int, y: int) -> Color:
	var yw := 904.0 + 3.0 * sin(p.x * 0.05)
	if p.y > yw + PX:
		return Color8(84, 132, 152).lerp(Color8(70, 112, 134), clampf((p.y - yw) / 40.0, 0.0, 1.0))
	if p.y > yw - PX:
		return Color8(214, 234, 240)                               # the water's edge
	if p.y < 880.0 and _noise(p.x * 0.06, p.y * 0.1) > 0.58:
		return Color8(112, 146, 78)
	if sin(p.x * 0.13 + _noise(p.y * 0.04, p.x * 0.01) * 3.0) > 0.8:
		return Color8(112, 110, 104)
	return Color8(140, 136, 128) if _hash(x, y) > 0.2 else Color8(128, 124, 118)

# --------------------------------------------------------------- 3: the Autumn Stream

const MAPLES := [[Vector2(70, 60), 170.0], [Vector2(232, 22), 130.0], [Vector2(30, 228), 110.0],
	[Vector2(880, 50), 170.0], [Vector2(716, 20), 110.0], [Vector2(930, 226), 110.0]]
const STREAM_Y := 430.0

## An autumn gorge: misty mountains, a waterfall down a dark cliff in the middle, red and gold
## maples on both sides, mossy boulders on the banks; the ring is on a log raft on the stream
static func _wall_stream(p: Vector2, x: int, y: int) -> Color:
	var c := _maple(p, x, y)
	if c.a > 0.0:
		return c
	for tx in [83.0, 872.0]:                                       # the maples' trunks
		if absf(p.x - tx) < 14.0 and p.y > 120.0 and p.y < STREAM_Y + 10.0:
			return OUTLINE if absf(p.x - tx) > 10.0 else (Color8(92, 64, 56) if p.x < tx else Color8(70, 48, 44))
	if p.y > STREAM_Y + 4.0 * sin(p.x * 0.03):
		var col := Color8(104, 154, 172).lerp(Color8(78, 124, 150), clampf((p.y - STREAM_Y) / 500.0, 0.0, 1.0))
		if fposmod(p.x * 0.05 + p.y * 0.012 + _noise(p.y * 0.02, p.x * 0.01) * 2.0, 1.0) < 0.05 and _noise(p.x * 0.01, p.y * 0.03) > 0.45:
			col = Color8(214, 234, 240)                            # foam, flowing down
		if _hash(x, y) < 0.003:
			col = Color8(214, 76, 44) if _hash(y, x) > 0.5 else Color8(240, 158, 60)   # floating leaves
		return col
	if p.y > 384.0 and absf(p.x - 475.0) > 170.0:                  # mossy boulders on the banks
		var by := 384.0 + 22.0 * _noise(p.x * 0.02, 5.0)
		if p.y > by:
			return Color8(110, 140, 76) if p.y < by + 8.0 else (Color8(112, 118, 106) if _noise(p.x * 0.05, p.y * 0.05) > 0.5 else Color8(96, 102, 92))
	var dx := absf(p.x - 475.0)
	var cliff := 160.0 + 22.0 * _noise(p.x * 0.02, 9.0)
	if dx < 150.0 + 30.0 * _noise(p.y * 0.01, 2.0) and p.y > cliff:
		if dx < 50.0 + 6.0 * sin(p.y * 0.05):
			var fall := Color8(234, 244, 250) if fposmod(p.x * 0.7 + _noise(p.y * 0.01, p.x * 0.05) * 30.0, 9.0) < 5.0 else Color8(196, 222, 234)
			return fall.lerp(Color.WHITE, clampf(1.0 - absf(p.y - 410.0) / 50.0, 0.0, 0.6))      # the mist at its foot
		return Color8(94, 92, 104) if _noise(p.x * 0.04, p.y * 0.04) > 0.45 else Color8(76, 74, 88)
	var r1 := 150.0 + 40.0 * _noise(p.x * 0.004, 2.0) + 30.0 * absf(sin(p.x * 0.006))
	var r2 := 226.0 + 34.0 * _noise(p.x * 0.006, 7.0)
	if p.y > r2:
		return Color8(150, 150, 178)
	if p.y > r1:
		return Color8(180, 176, 202)
	return Color8(240, 230, 210).lerp(Color8(228, 214, 198), clampf(p.y / 260.0, 0.0, 1.0))

static func _maple(p: Vector2, x: int, y: int) -> Color:
	for m in MAPLES:
		var mc: Vector2 = m[0]
		var r: float = m[1]
		var d := (p - mc).length() / r + (_noise(p.x * 0.05, p.y * 0.05) - 0.5) * 0.55
		if d < 1.0:
			if _noise(p.x * 0.12, p.y * 0.12) < 0.18 and d > 0.5:
				break                                              # (gaps in the leaves)
			var n := _noise(p.x * 0.1 + 3.0, p.y * 0.1)
			if d > 0.88 and p.y > mc.y:
				return Color8(150, 36, 36)
			return Color8(244, 170, 62) if n > 0.68 else (Color8(230, 108, 44) if n > 0.4 else Color8(204, 54, 42))
	if p.y < STREAM_Y and _hash(x, y) < 0.003:
		return Color8(230, 108, 44)                                # a falling leaf
	return Color(0, 0, 0, 0)

## The raft's top: logs lying front to back (round, with bark grain), two rope lashings across
static func _lid_raft(p: Vector2) -> Color:
	var t := clampf((p.y - 470.0) / (FRONT_Y - 470.0), 0.0, 1.0)
	var left := lerpf(110.0, 20.0, t)
	var right := lerpf(W - 110.0, W - 20.0, t)
	var u := (p.x - left) / (right - left)
	var lu := fposmod(u * 11.0, 1.0)
	for rt in [0.22, 0.8]:
		if absf(t - rt) < 0.035:
			return ROPE_DARK if fposmod(u * 90.0, 1.0) < 0.3 else ROPE
	if lu < 0.07 or lu > 0.93:
		return Color8(88, 58, 36)
	var col := Color8(146, 100, 62).lerp(Color8(206, 162, 112), sin(lu * PI))
	if fposmod(lu * 7.0 + _noise(t * 20.0, floorf(u * 11.0)) * 2.0, 1.0) < 0.12:
		col = col.darkened(0.12)
	return col

## Its front: the ends of the logs (rings, bark), standing in the stream
static func _front_raft(p: Vector2) -> Color:
	var yw := 924.0 + 3.0 * sin(p.x * 0.06)
	if p.y > yw + PX:
		return Color8(78, 124, 150)
	if p.y > yw - PX:
		return Color8(214, 234, 240)
	var i := floori((p.x - 20.0) / 82.7)
	var d := (p - Vector2(20.0 + (i + 0.5) * 82.7, 882.0)).length()
	if d > 38.0:
		return Color8(60, 40, 26)
	if d > 33.0:
		return Color8(98, 66, 40)
	return Color8(214, 176, 120) if fposmod(d * 0.35 + _noise(p.x * 0.1, p.y * 0.1) * 0.6, 1.0) > 0.25 else Color8(186, 146, 92)

# --------------------------------------------------------------- 4: the Moon Base

const CRATERS := [[Vector2(140, 452), Vector2(64, 18)], [Vector2(330, 404), Vector2(26, 7)], [Vector2(646, 418), Vector2(44, 12)],
	[Vector2(560, 392), Vector2(16, 5)], [Vector2(906, 470), Vector2(40, 12)], [Vector2(40, 400), Vector2(30, 8)]]
const PAD_LIGHTS := [Color8(240, 80, 70), Color8(250, 210, 80), Color8(110, 230, 130), Color8(110, 180, 250)]

## The Moon: a black sky full of stars, the Earth rising, grey dust and craters, a toy rocket on
## the left and a little glass dome on the right; the ring is on a metal landing pad. (It does its
## own lighting: the Earth, the stars and the lamps glow.)
static func _wall_moon(p: Vector2, x: int, y: int) -> Color:
	_glow = true
	var light := _light(p)
	var c := _rocket(p)
	if c.a > 0.0:
		return c.darkened(1.0 - light)
	var hz := 372.0 + 0.00014 * pow(p.x - 475.0, 2) + 6.0 * _noise(p.x * 0.01, 3.0)
	if p.y < hz:
		c = _earth(p)
		if c.a > 0.0:
			return c
		if _hash(x, y) < 0.01:
			return Color8(240, 238, 226) if _hash(y, x) > 0.5 else Color8(170, 180, 220)
		var sky := Color8(12, 10, 30).lerp(Color8(30, 24, 56), clampf(p.y / 380.0, 0.0, 1.0))
		var eg := clampf(1.0 - ((p - Vector2(740, 150)).length() - 62.0) / 30.0, 0.0, 1.0)
		return sky.darkened(1.0 - light).lerp(Color8(80, 130, 220), eg * 0.35)    # (the Earth's glow)
	c = _dome(p)
	if c.a > 0.0:
		return c
	for cr in CRATERS:
		var q := ((p - (cr[0] as Vector2)) / (cr[1] as Vector2)).length_squared()
		if q < 1.0:
			return (Color8(196, 196, 206) if q > 0.7 and p.y > (cr[0] as Vector2).y else Color8(116, 116, 128)).darkened(1.0 - light)
	var n := _noise(p.x * 0.03, p.y * 0.06)
	var g := Color8(150, 150, 160) if n > 0.55 else (Color8(170, 170, 180) if n > 0.3 else Color8(160, 160, 170))
	if p.y < hz + PX:
		g = Color8(196, 196, 206)                                  # the horizon's lit edge
	return g.darkened(1.0 - light)

static func _earth(p: Vector2) -> Color:
	var d := p - Vector2(740, 150)
	var r := 62.0
	if d.length() > r:
		return Color(0, 0, 0, 0)
	var nz := sqrt(maxf(0.0, 1.0 - d.length_squared() / (r * r)))
	var lit := clampf(-d.x / r * 0.55 - d.y / r * 0.65 + nz * 0.6, 0.0, 1.0)
	var col := Color8(52, 104, 196)
	if _noise(d.x * 0.045 + 3.0, d.y * 0.045) > 0.58:
		col = Color8(88, 150, 86) if _noise(d.x * 0.1, d.y * 0.1) > 0.4 else Color8(176, 158, 104)
	if _noise(d.x * 0.07 + 10.0, d.y * 0.11) > 0.64:
		col = Color8(240, 244, 250)
	if d.length() > r - PX * 1.2 and lit > 0.4:
		col = Color8(150, 200, 255)                                # the air, lit
	return col.darkened(0.7 * (1.0 - lit))

## A toy rocket standing on the dust: white with a red nose, a band, a porthole, fins
static func _rocket(p: Vector2) -> Color:
	var cx := 120.0
	var dx := absf(p.x - cx)
	if p.y < 196.0 or p.y > 388.0 or dx > 54.0:
		return Color(0, 0, 0, 0)
	var hw := 30.0 * sqrt(clampf((p.y - 196.0) / 46.0, 0.0, 1.0))
	if p.y > 330.0 and dx > 26.0 and dx < 26.0 + (p.y - 330.0) * 0.45 and p.y < 384.0:
		return OUTLINE if p.y > 380.0 or dx > 22.0 + (p.y - 330.0) * 0.45 else Color8(214, 62, 56)   # fins
	if p.y > 364.0 or dx > hw:
		return Color(0, 0, 0, 0)
	if dx > hw - PX:
		return OUTLINE
	var pd := (p - Vector2(cx, 272)).length()
	if pd < 13.0:
		return OUTLINE if pd > 10.0 else (Color8(240, 250, 255) if p.x < cx - 3.0 and p.y < 268.0 else Color8(110, 180, 230))
	var red := p.y < 236.0 or (p.y > 304.0 and p.y < 318.0)
	var col := Color8(214, 62, 56) if red else Color8(240, 236, 230)
	return col.lightened(0.12) if p.x < cx - hw * 0.4 else (col.darkened(0.15) if p.x > cx + hw * 0.45 else col)

## The base: a glass dome on a metal ring, an antenna with a blinking lamp
static func _dome(p: Vector2) -> Color:
	var c := Vector2(866, 424)
	var d := (p - c) / Vector2(70, 48)
	if p.y <= c.y and d.length_squared() < 1.0:
		if d.length_squared() > 0.86:
			return OUTLINE
		if (p - (c + Vector2(-26, -26))).length() < 9.0:
			return Color8(240, 250, 255)
		return Color8(150, 206, 226) if d.x + d.y < 0.2 else Color8(120, 176, 204)
	if p.y > c.y and p.y < c.y + 12.0 and absf(p.x - c.x) < 74.0:
		return OUTLINE if p.y > c.y + 9.0 else Color8(150, 156, 170)
	if absf(p.x - (c.x + 30.0)) < 2.0 and p.y > c.y - 78.0 and p.y < c.y - 40.0:
		return Color8(150, 156, 170)
	if (p - Vector2(c.x + 30.0, c.y - 80.0)).length() < 5.0:
		return Color8(255, 96, 80)
	return Color(0, 0, 0, 0)

## The landing pad's top: metal plates (seams in perspective, rivets), hazard stripes round it
static func _lid_pad(p: Vector2, x: int, y: int) -> Color:
	var t := clampf((p.y - 470.0) / (FRONT_Y - 470.0), 0.0, 1.0)
	var left := lerpf(110.0, 20.0, t)
	var right := lerpf(W - 110.0, W - 20.0, t)
	var border := minf(minf(p.x - left, right - p.x), (p.y - 470.0) * 1.6)
	if border < 22.0:
		return Color8(240, 196, 60) if fposmod((p.x + p.y * 1.4) * 0.03, 1.0) < 0.5 else Color8(40, 38, 46)
	var u := (p.x - left) / (right - left)
	var su := fposmod(u * 6.0, 1.0)
	var sv := fposmod(sqrt(t) * 5.0, 1.0)
	if su < 0.02 or sv < 0.03:
		return Color8(96, 102, 116)
	if (su < 0.07 or su > 0.95) and (sv < 0.12 or sv > 0.9):
		return Color8(210, 214, 224)                               # rivets
	return Color8(150, 156, 170) if _noise(p.x * 0.3, p.y * 0.02) > 0.4 else Color8(140, 146, 160)

## Its front: dark metal, a hazard band, a row of lamps (they glow), vents
static func _front_pad(p: Vector2) -> Color:
	if p.y < 860.0:
		return Color8(240, 196, 60) if fposmod((p.x + p.y) * 0.03, 1.0) < 0.5 else Color8(40, 38, 46)
	var i := roundi((p.x - 55.0) / 70.0)
	var lc := Vector2(55.0 + i * 70.0, 896.0)
	var d := (p - lc).length()
	if d < 9.0 and lc.x > 40.0 and lc.x < W - 40.0:
		if d > 7.0:
			return OUTLINE
		_glow = true
		return (PAD_LIGHTS[posmod(i, PAD_LIGHTS.size())] as Color).lightened(0.3 if d < 3.0 else 0.0)
	if p.y > 918.0 and p.y < 926.0 and fposmod(p.x - 20.0, 70.0) > 20.0 and fposmod(p.x - 20.0, 70.0) < 50.0:
		return Color8(40, 42, 52)                                  # vents
	return Color8(92, 98, 114)

# --------------------------------------------------------------- 5: the Tree Stump, a forest

## Trunks behind: [x, half width, haze (0 near, more = paler, farther)]
const TRUNKS := [[64.0, 46.0, 0.0], [292.0, 22.0, 0.45], [668.0, 28.0, 0.35], [902.0, 52.0, 0.0]]

## Summer light through the leaves: the canopy at the top, trunks, shafts of sun, ferns
static func _wall_forest(p: Vector2) -> Color:
	var col := Color8(208, 232, 184).lerp(Color8(150, 196, 124), clampf(p.y / 470.0, 0.0, 1.0))
	for t in TRUNKS:
		var hw: float = float(t[1]) * (1.0 + maxf(0.0, p.y - 380.0) / 300.0)
		var dx := p.x - float(t[0])
		if absf(dx) < hw:
			var s := dx / hw
			var bark := Color8(118, 96, 74)
			if s < -0.55:
				bark = bark.lightened(0.16)
			elif s > 0.5:
				bark = bark.darkened(0.22)
			if sin(p.x * 0.45 + _noise(p.y * 0.02, float(t[0])) * 7.0) > 0.72:
				bark = bark.darkened(0.15)
			col = bark.lerp(col, float(t[2]))
			break
	var top := 110.0 + 70.0 * _noise(p.x * 0.012, 3.0) + 34.0 * _noise(p.x * 0.05, 9.0)
	if p.y < top:
		var n := _noise(p.x * 0.05, p.y * 0.05)
		col = Color8(92, 150, 80) if n < 0.4 else (Color8(124, 180, 96) if n < 0.72 else Color8(166, 208, 118))
	if fposmod(p.x + p.y * 0.55, 190.0) < 30.0 and p.y > top:
		col = col.lightened(0.07)                              # shafts of sunlight
	var fern := 424.0 - 44.0 * _noise(p.x * 0.03, 5.0)
	if p.y > fern:
		col = Color8(98, 152, 78).lerp(Color8(70, 122, 60), _noise(p.x * 0.1, p.y * 0.1))
	return col

## The stump's top: its growth rings, a light layer under the bark, two cracks
static func _lid_stump(p: Vector2) -> Color:
	var d := p - RING_C
	var e := sqrt(_ell(d, STUMP))
	if e > 0.955:
		return Color8(108, 74, 48)
	if e > 0.93:
		return Color8(244, 222, 178)
	if e > 0.62:
		var ang := atan2(d.y / STUMP.y, d.x / STUMP.x)
		for a0 in [2.55, -0.45]:
			if absf(wrapf(ang - a0 - (e - 0.62) * 0.35, -PI, PI)) < 0.012 / e:
				return Color8(150, 112, 72)
	return _stump_wood(p, false)

static func _stump_wood(p: Vector2, sanded: bool) -> Color:
	var d := p - RING_C
	var e := sqrt(_ell(d, STUMP))
	var col := Color8(236, 208, 160) if sanded else Color8(224, 192, 142)
	if fposmod(e * 24.0 + _noise(atan2(d.y, d.x) * 3.0, e * 4.0) * 0.6, 1.0) < 0.14:
		col = col.darkened(0.1)
	return col

## The bark: deep furrows, moss low down
static func _front_bark(p: Vector2, x: int, y: int) -> Color:
	if p.y > 900.0 and _noise(p.x * 0.04, p.y * 0.04) > 0.62:
		return Color8(112, 150, 72) if _hash(x, y) > 0.3 else Color8(140, 176, 88)
	var f := sin(p.x * 0.11 + _noise(p.y * 0.03, p.x * 0.01) * 4.0)
	if f > 0.75:
		return Color8(76, 52, 34)
	if f < -0.85:
		return Color8(128, 94, 62)
	return Color8(100, 70, 46)

# --------------------------------------------------------------- 6: the Shrine Festival, night

const LANTERN_X := [42.0, 146.0, 250.0, 352.0, 598.0, 700.0, 804.0, 908.0]

## A night sky with stars and the moon, a torii behind the ring (in the spotlight), red and white
## paper lanterns glowing on a string. (It does its own lighting: the lanterns and the stars glow.)
static func _wall_night(p: Vector2, x: int, y: int) -> Color:
	_glow = true
	var lan := _lantern(p)
	if lan.a > 0.0:
		return lan
	var light := _light(p)
	var tor := _torii(p)
	if tor.a > 0.0:
		return tor.darkened(1.0 - light)
	var sky := Color8(26, 24, 56).lerp(Color8(58, 42, 82), clampf(p.y / 470.0, 0.0, 1.0))
	var md := p - Vector2(700, 96)
	if md.length() < 34.0:
		if (md - Vector2(-9, 7)).length() < 8.0 or (md - Vector2(12, -9)).length() < 5.0:
			return Color8(232, 218, 172)
		return Color8(250, 238, 198)                           # the moon
	if p.y < 420.0 and _hash(x, y) < 0.007:
		return Color8(240, 236, 214) if _hash(y, x) > 0.4 else Color8(170, 170, 204)
	sky = sky.darkened(1.0 - light)
	if md.length() < 64.0:
		sky = sky.lerp(Color8(120, 110, 140), (64.0 - md.length()) / 30.0 * 0.3)
	var glow := 0.0
	for lx in LANTERN_X:
		var lc := Vector2(lx, _string_y(lx) + 32.0)
		glow = maxf(glow, 1.0 - (p - lc).length() / 74.0)
	return sky.lerp(Color8(236, 128, 76), clampf(glow, 0.0, 1.0) * 0.38)

static func _string_y(x: float) -> float:
	return 150.0 + 50.0 * (1.0 - pow((x - 475.0) / 560.0, 2))

## A chōchin: ribbed paper, black caps, glowing from inside (red and white in turns); painting the
## layers, only the string (StageLife hangs the lanterns, swaying)
static func _lantern(p: Vector2) -> Color:
	if p.y < 300.0 and absf(p.y - _string_y(p.x)) < 2.5:
		return Color8(30, 24, 30)
	if _live:
		return Color(0, 0, 0, 0)
	for i in LANTERN_X.size():
		var lx: float = LANTERN_X[i]
		var c := _lantern_at(p - Vector2(lx, _string_y(lx) + 32.0), i % 2 == 0)
		if c.a > 0.0:
			return c
	return Color(0, 0, 0, 0)

## A lantern's pixel at `l` from its centre (red or white)
static func _lantern_at(l: Vector2, red: bool) -> Color:
	if absf(l.x) <= 12.0 and (absf(l.y + 30.0) < 4.0 or absf(l.y - 30.0) < 4.0):
		return Color8(36, 30, 34)                          # the caps
	var q := (l / Vector2(22, 27)).length_squared()
	if q > 1.0:
		return Color(0, 0, 0, 0)
	if q > 0.82:
		return Color8(60, 30, 30)
	var col := Color8(226, 70, 54) if red else Color8(250, 238, 214)
	col = col.lerp(Color8(255, 214, 150), clampf(1.0 - q * 1.6, 0.0, 1.0) * 0.6)   # the flame inside
	if fposmod(l.y + 30.0, 9.0) < PX:
		col = col.darkened(0.2)                            # the ribs
	return col

## A vermilion torii: the curved top beam (black on top), the tie beam, two pillars
static func _torii(p: Vector2) -> Color:
	var red := Color8(198, 62, 48)
	var dx := p.x - RING_C.x
	var lift := 14.0 * pow(absf(dx) / 205.0, 4)               # (the top beam's ends turn up)
	if absf(dx) < 205.0 and p.y > 188.0 - lift and p.y < 206.0 - lift:
		return Color8(40, 30, 34) if p.y < 196.0 - lift else red
	if absf(dx) < 186.0 and p.y >= 206.0 - lift * 0.5 and p.y < 216.0:
		return red.darkened(0.12)
	if absf(dx) < 182.0 and p.y > 252.0 and p.y < 266.0:
		return red.darkened(0.08)
	if absf(dx) < 18.0 and p.y >= 216.0 and p.y < 252.0:
		return Color8(40, 30, 34) if absf(dx) > 13.0 or p.y < 221.0 or p.y > 247.0 else Color8(214, 176, 90)   # the plaque
	for sx in [-150.0, 150.0]:
		var u: float = dx - sx
		if absf(u) < 13.0 and p.y >= 206.0:
			if p.y > 446.0:
				return Color8(40, 30, 34)
			return red.lightened(0.12) if u < -6.0 else (red.darkened(0.2) if u > 6.0 else red)
	return Color(0, 0, 0, 0)

## Red lacquer with gold trim and gold crests, a shine across it
static func _front_lacquer(p: Vector2) -> Color:
	if absf(p.y - 860.0) < 4.0 or absf(p.y - 936.0) < 4.0:
		return Color8(232, 186, 80)
	var cx := RING_C.x + roundf((p.x - RING_C.x) / 120.0) * 120.0
	if absf(cx - RING_C.x) <= 240.0:
		var d := (p - Vector2(cx, 898.0)).length()
		if absf(d - 14.0) < 3.0 or d < 4.0:
			return Color8(232, 186, 80)
	if fposmod(p.x * 0.5 - p.y, 300.0) < 16.0:
		return Color8(170, 40, 38).lightened(0.12)
	return Color8(170, 40, 38)

# --------------------------------------------------------------- noise

## A fixed pseudo-random 0..1 per pixel (the same every time)
static func _hash(x: int, y: int) -> float:
	var n := (x * 374761393 + y * 668265263) & 0x7fffffff
	n = ((n ^ (n >> 13)) * 1274126177) & 0x7fffffff
	return float(n % 1000) / 1000.0

## Smooth value noise, 0..1
static func _noise(x: float, y: float) -> float:
	var ix := floori(x)
	var iy := floori(y)
	var fx := x - ix
	var fy := y - iy
	fx = fx * fx * (3.0 - 2.0 * fx)
	fy = fy * fy * (3.0 - 2.0 * fy)
	return lerpf(lerpf(_hash(ix, iy), _hash(ix + 1, iy), fx), lerpf(_hash(ix, iy + 1), _hash(ix + 1, iy + 1), fx), fy)

# ================================================================== THE PLACES' LIFE

## What moves in each place (the user, 2026-10-19: moving, more beautiful backgrounds keeping what
## each place is): drawn every frame on the 4 px grid over the place behind the ring (it shifts
## with it: the 3D tilt), behind the box and the wrestlers. The wooden box: dust drifting in the
## spotlight's cone · the pond: sakura petals fluttering down, glints on the water, two koi gliding
## past behind the rock · the autumn stream: the waterfall pouring and its mist breathing, maple
## leaves twirling down, foam drifting on the stream · the Moon: stars twinkling, clouds sliding
## across the Earth, the dome's lamp and the rocket's light blinking, now and then a shooting star
## · the forest: shafts of sun swaying through the leaves, pollen floating in them · the shrine
## festival: the paper lanterns swaying on their string and flickering, fireworks bursting high on
## both sides of the sky
class StageLife extends Node2D:
	var world := 0
	var t := 0.0
	var motes: Array = []             # [position, velocity, phase, kind]
	var bursts: Array = []            # the festival's fireworks: [centre, age, colour]
	var next_burst := 1.5
	var lanterns: Array[Texture2D] = []
	func setup(w: int) -> void:
		world = w
		motes.clear()
		bursts.clear()
		var n: int = [26, 30, 26, 46, 26, 34][clampi(w, 0, 5)]
		for i in n:
			motes.append([Vector2(randf_range(0, SumoArt.W), randf_range(0, 600)), Vector2(randf_range(-8, 8), randf_range(-6, 6)), randf() * TAU, i % 3])
		if w == 5:
			lanterns = [SumoArt.lantern_tex(true), SumoArt.lantern_tex(false)]
		queue_redraw()
	func _process(delta: float) -> void:
		t += delta
		match world:
			1, 2:
				# petals / leaves: falling slowly, fluttering sideways, round again from the trees
				for m in motes:
					m[0] += Vector2(28.0 + 30.0 * sin(t * 1.3 + m[2]), 46.0 + 12.0 * sin(t * 0.7 + m[2])) * delta
					if m[0].y > SumoArt.RING_C.y - 60.0 or m[0].x > SumoArt.W + 20.0:
						m[0] = Vector2(randf_range(-60, SumoArt.W * 0.7), randf_range(0, 120))
			5:
				next_burst -= delta
				if next_burst <= 0.0:
					next_burst = randf_range(1.6, 3.2)
					var left := randf() < 0.5
					bursts.append([Vector2(randf_range(60, 260) if left else randf_range(760, 900), randf_range(60, 150)), 0.0,
						[Color8(255, 120, 180), Color8(255, 214, 110), Color8(140, 220, 255), Color8(170, 255, 150)][randi() % 4]])
				for b in bursts:
					b[1] += delta
				bursts = bursts.filter(func(b): return b[1] < 1.6)
			_:
				for m in motes:
					m[0] += (m[1] as Vector2) * delta + Vector2(0, -6.0) * delta
					if m[0].y < 0.0:
						m[0].y = 600.0
					m[0].x = fposmod(m[0].x, SumoArt.W)
		queue_redraw()
	func _sq(p: Vector2, s: float, col: Color) -> void:
		draw_rect(Rect2(GameFx.snap(p) - Vector2(s, s) / 2.0, Vector2(s, s)), col)
	func _draw() -> void:
		var rc := SumoArt.RING_C
		match world:
			0:
				# dust drifting in the spotlight's cone
				for m in motes:
					var p: Vector2 = m[0]
					var hw := lerpf(90.0, SumoArt.RING_RX + 30.0, clampf(p.y / rc.y, 0.0, 1.0))
					if absf(p.x - rc.x) < hw and p.y < rc.y - 40.0:
						_sq(p, 4.0, Color(1, 0.96, 0.84, 0.22 + 0.16 * sin(t * 2.0 + m[2])))
			1:
				# glints on the pond, and two koi gliding past behind the rock
				for g in 18:
					var gx := fposmod(g * 113.0 + sin(t * 0.4 + g) * 20.0, SumoArt.W)
					var gy := SumoArt.WATER_Y + 16.0 + fposmod(g * 37.0, 90.0)
					if sin(t * 2.0 + g * 1.9) > 0.55:
						draw_rect(Rect2(GameFx.snap(Vector2(gx, gy)), Vector2(12, 4)), Color(1, 1, 1, 0.45))
				for k in 2:
					var kx := fposmod(t * (34.0 + 10.0 * k) + k * 480.0, SumoArt.W + 200.0) - 100.0
					var ky := SumoArt.WATER_Y + 46.0 + k * 34.0 + 6.0 * sin(t * 0.8 + k)
					var face := 1.0
					for seg in 6:
						var sx := kx - face * seg * 8.0
						var wob := sin(t * 5.0 - seg * 0.8 + k) * 3.0 * seg / 5.0
						var col := Color8(240, 120, 60, 170) if (seg + k) % 3 != 1 else Color8(250, 246, 240, 170)
						var sz := 12.0 - absf(seg - 1.5) * 2.0
						_sq(Vector2(sx, ky + wob), maxf(4.0, sz), col)
				# petals fluttering down from the sakura
				for m in motes:
					var flip := sin(t * 6.0 + m[2]) > 0.0
					draw_rect(Rect2(GameFx.snap(m[0]), Vector2(8, 4) if flip else Vector2(4, 8)), Color8(250, 196, 214) if m[3] != 1 else Color8(255, 232, 240))
			2:
				# the waterfall pouring (light streaks running down it), its mist breathing at the foot
				var fx2 := 475.0
				for k in 14:
					var x := fx2 - 44.0 + k * 7.0
					var top := 170.0 + 22.0 * sin(x * 0.02)
					var run := fposmod(t * 260.0 + k * 53.0, 260.0)
					var y := top + run
					if y < 408.0:
						draw_rect(Rect2(GameFx.snap(Vector2(x, y)), Vector2(4, 24)), Color(1, 1, 1, 0.5))
				var mist := 0.18 + 0.08 * sin(t * 1.5)
				for k in 5:
					GameFx.disc(self, Vector2(fx2 - 60.0 + k * 30.0, 412.0 + 6.0 * sin(t + k)), 22.0 + 6.0 * sin(t * 1.2 + k), Color(1, 1, 1, mist))
				# foam drifting on the stream
				for k in 10:
					var fx3 := fposmod(k * 97.0 + t * 30.0, SumoArt.W)
					var fy := SumoArt.STREAM_Y + 14.0 + fposmod(k * 41.0, 60.0)
					draw_rect(Rect2(GameFx.snap(Vector2(fx3, fy)), Vector2(16, 4)), Color(0.86, 0.94, 0.96, 0.5))
				# maple leaves twirling down
				for m in motes:
					var flip2 := sin(t * 5.0 + m[2]) > 0.0
					var lc: Color = [Color8(214, 76, 44), Color8(240, 158, 60), Color8(232, 196, 70)][int(m[3])]
					draw_rect(Rect2(GameFx.snap(m[0]), Vector2(8, 8) if flip2 else Vector2(8, 4)), lc)
			3:
				# stars twinkling above the horizon
				for m in motes:
					var p3: Vector2 = Vector2(m[0].x, fposmod(m[0].y, 340.0))
					if sin(t * (1.0 + fposmod(m[2], 1.0)) + m[2] * 5.0) > 0.6:
						_sq(p3, 4.0, Color(1, 1, 1, 0.9))
						draw_rect(Rect2(GameFx.snap(p3) - Vector2(6, 2), Vector2(12, 4)), Color(1, 1, 1, 0.3))
				# clouds sliding across the Earth (kept inside its disc)
				var ec := Vector2(740, 150)
				for k in 4:
					var cy := ec.y - 40.0 + k * 22.0
					var cx := fposmod(t * (10.0 + k * 3.0) + k * 37.0, 160.0) - 80.0 + ec.x
					var y4 := cy - ec.y
					var half := sqrt(maxf(0.0, 58.0 * 58.0 - y4 * y4))
					var x0 := maxf(cx - 22.0, ec.x - half)
					var x1 := minf(cx + 22.0, ec.x + half)
					if x1 > x0:
						draw_rect(Rect2(GameFx.snap(Vector2(x0, cy)), Vector2(roundf((x1 - x0) / 4.0) * 4.0, 4)), Color(1, 1, 1, 0.55))
				# the dome's lamp and the rocket's nose light blinking
				if fposmod(t, 1.2) < 0.5:
					GameFx.glow(self, Vector2(896, 344), 8.0, Color8(255, 96, 80))
				if fposmod(t + 0.6, 1.6) < 0.4:
					GameFx.glow(self, Vector2(120, 196), 8.0, Color8(255, 220, 120))
				# now and then a shooting star
				var sh := fposmod(t, 7.0)
				if sh < 0.7:
					var head := Vector2(160, 60) + Vector2(1, 0.35) * sh * 600.0
					for k in 8:
						_sq(head - Vector2(1, 0.35) * k * 9.0, 4.0, Color(1, 1, 1, 0.7 * (1.0 - k / 8.0) * (1.0 - sh / 0.7)))
			4:
				# shafts of sun swaying through the leaves, pollen floating in them
				for k in 3:
					var sx2 := 200.0 + k * 260.0 + 30.0 * sin(t * 0.3 + k)
					var y5 := 120.0
					while y5 < rc.y - 80.0:
						var x5 := sx2 + (y5 - 120.0) * 0.35
						draw_rect(Rect2(GameFx.snap(Vector2(x5 - 30.0, y5)), Vector2(60, 4)), Color(1, 0.98, 0.8, 0.06 + 0.03 * sin(t * 0.8 + k)))
						y5 += 4.0
				for m in motes:
					_sq(m[0], 4.0, Color(1, 0.98, 0.75, 0.3 + 0.2 * sin(t * 2.0 + m[2])))
			5:
				# fireworks bursting high on both sides of the sky
				for b in bursts:
					var f: float = b[1] / 1.6
					var r := 20.0 + 90.0 * (1.0 - (1.0 - f) * (1.0 - f))
					var bc: Color = b[2]
					for k in 18:
						var p6: Vector2 = (b[0] as Vector2) + Vector2.from_angle(k * TAU / 18.0) * r + Vector2(0, f * f * 30.0)
						_sq(p6, 4.0, Color(bc.r, bc.g, bc.b, 1.0 - f))
						if f < 0.5:
							_sq(p6 - Vector2.from_angle(k * TAU / 18.0) * 8.0, 4.0, Color(1, 1, 1, 0.5 * (1.0 - f * 2.0)))
					if f < 0.15:
						GameFx.disc(self, b[0], 60.0, Color(bc.r, bc.g, bc.b, 0.12 * (1.0 - f / 0.15)))
				# the lanterns swaying on their string, flickering
				for i in SumoArt.LANTERN_X.size():
					var lx: float = SumoArt.LANTERN_X[i]
					var sway := roundf(sin(t * 1.3 + i * 0.9) * 1.2) * 4.0
					var lc2 := Vector2(lx + sway, SumoArt._string_y(lx) + 32.0)
					var fl := 0.1 + 0.05 * sin(t * 11.0 + i * 2.3) + 0.03 * sin(t * 23.0 + i)
					GameFx.disc(self, lc2, 40.0, Color(1, 0.6, 0.3, fl))
					draw_line(Vector2(lx, SumoArt._string_y(lx)), lc2 - Vector2(0, 30), Color8(30, 24, 30), 4.0)
					var tex: Texture2D = lanterns[i % 2]
					var sz := tex.get_size() * SumoArt.PX
					draw_texture_rect(tex, Rect2(lc2 - sz / 2.0, sz), false)
