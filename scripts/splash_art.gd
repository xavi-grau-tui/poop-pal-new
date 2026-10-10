extends RefCounted
class_name SplashArt
## Splash Hoops' look, painted in code (2026-10-10): a plastic water toy in the style of the
## other toy games (hard pixels on the game's 3 px grid, two-tone outlines in the game's dark
## brown, a muted warm palette). The cups, nets and pumps keep the exact outlines of the old art
## (textures/minigames/splash/*.png), only recoloured, so the colliders still fit.

const P := 3.0                               # world px per art px (the game's S)
const OUTLINE := Color8(74, 44, 32)
# the plastic case (top band, side rails, the funnel floor)
const CASE := Color8(238, 224, 194)
const CASE_LIGHT := Color8(250, 240, 216)
const CASE_SHADE := Color8(214, 196, 160)
const CASE_DARK := Color8(182, 160, 122)
# the water, top to bottom (muted teal), and the light rays (one step lighter)
const WATER := [Color8(156, 202, 198), Color8(136, 188, 188), Color8(116, 172, 178), Color8(98, 156, 168), Color8(84, 142, 158)]
# coral plastic: cup rims, pumps
const CORAL := Color8(222, 120, 98)
const CORAL_LIGHT := Color8(242, 162, 134)
const CORAL_DARK := Color8(176, 84, 70)
const NET := Color8(244, 236, 214)
const BALLS := {
	"pink": [Color8(222, 118, 96), Color8(176, 82, 68), Color8(250, 186, 160)],      # coral
	"yellow": [Color8(228, 180, 82), Color8(180, 132, 50), Color8(250, 222, 150)],   # mustard
	"mint": [Color8(118, 194, 160), Color8(76, 148, 118), Color8(186, 232, 206)],    # mint
}

## The tank: top band (the HUD sits on it), water (edge to edge: no side rails, they peeked
## out past the console's screen window) with light rays, the funnel floor
## shaped by floor_at (world coords), a darker hole at each pump
static func tank(w_px: int, h_px: int, band_y: float, _wall_l: float, _wall_r: float, floor_at: Callable, _nozzles: Array) -> Texture2D:
	var img := Image.create(w_px, h_px, false, Image.FORMAT_RGBA8)
	var water_top := band_y
	var water_bottom := 880.0
	for y in h_px:
		for x in w_px:
			var wx := (x + 0.5) * P
			var wy := (y + 0.5) * P
			var col: Color
			var fy: float = floor_at.call(wx)
			if wy < band_y:                                      # the top band
				col = CASE
				if wy < P * 2:
					col = CASE_LIGHT
				elif wy > band_y - P * 3:
					col = CASE_SHADE
				if wy > band_y - P:
					col = OUTLINE
			elif wy > fy:                                        # the funnel floor: sand
				col = _sand(int(wx / P), int(wy / P), wy - fy)
			else:                                                # the water
				var t := clampf((wy - water_top) / (water_bottom - water_top), 0.0, 0.999)
				var band := int(t * WATER.size())
				col = WATER[band]
				if band > 0 and wy < 640.0 and _in_ray(wx, wy - water_top):
					col = WATER[band - 1]                        # light through the water
			img.set_pixel(x, y, col)
	return ImageTexture.create_from_image(img)

## The sand floor: a 2 px outline along its top, a lit lip, then the sand's own colour with
## grains (a lighter and a darker one, scattered) and soft ripples that follow the slope
static func _sand(ax: int, ay: int, depth: float) -> Color:
	if depth < P * 2:
		return OUTLINE
	if depth < P * 3:
		return CASE_LIGHT
	var h := _hash(ax, ay)
	var ripple := int(depth / P + 1.6 * sin(ax * 0.21)) % 10
	if ripple == 0 and h < 0.8:
		return CASE_SHADE.lerp(CASE, 0.35)               # a ripple's shady side
	if ripple == 1 and h < 0.6:
		return CASE_LIGHT                                # its lit crest
	if h < 0.04:
		return CASE_SHADE                                # a few scattered grains
	if h > 0.96:
		return CASE_LIGHT
	return CASE

## A fixed pseudo-random 0..1 per art pixel (the same sand every time)
static func _hash(x: int, y: int) -> float:
	var n := (x * 374761393 + y * 668265263) & 0x7fffffff
	n = ((n ^ (n >> 13)) * 1274126177) & 0x7fffffff
	return float(n % 1000) / 1000.0

## Three soft rays slanting down from the top, narrow at the surface; a checkered edge
static func _in_ray(wx: float, depth: float) -> bool:
	for x0 in [170.0, 470.0, 760.0]:
		var cx: float = x0 + depth * 0.32
		var half := 26.0 + depth * 0.07
		var d := absf(wx - cx)
		if d < half:
			return true
		if d < half + 9.0:
			return (int(wx / P) + int(depth / P)) % 2 == 0      # dithered edge
	return false

## An old sprite's shape, recoloured: the pixels on its outer edge in OUTLINE, the rest by row
## (light at the top, dark at the bottom). semi = the colour for its half-transparent pixels.
static func recolour(path: String, light: Color, base: Color, dark: Color, semi := Color(0, 0, 0, 0)) -> Texture2D:
	var src: Image = (load(path) as Texture2D).get_image()
	if src.is_compressed():
		src.decompress()
	src.convert(Image.FORMAT_RGBA8)
	var w := src.get_width()
	var h := src.get_height()
	var top := h
	var bottom := -1
	for y in h:
		for x in w:
			if src.get_pixel(x, y).a > 0.8:
				top = mini(top, y)
				bottom = maxi(bottom, y)
	var img := Image.create(w, h, false, Image.FORMAT_RGBA8)
	for y in h:
		for x in w:
			var a := src.get_pixel(x, y).a
			if a <= 0.0:
				continue
			if a < 0.8:
				img.set_pixel(x, y, semi)
				continue
			var edge := false
			for dd in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
				var nx: int = x + dd.x
				var ny: int = y + dd.y
				if nx < 0 or ny < 0 or nx >= w or ny >= h or src.get_pixel(nx, ny).a < 0.8:
					edge = true
			var col := base
			if edge:
				col = OUTLINE
			elif y <= top + 1:
				col = light
			elif y >= bottom - 1:
				col = dark
			img.set_pixel(x, y, col)
	return ImageTexture.create_from_image(img)

## The net: its lattice in cream (outlined at the sides), the holes faintly tinted
static func net(path: String) -> Texture2D:
	var src: Image = (load(path) as Texture2D).get_image()
	if src.is_compressed():
		src.decompress()
	src.convert(Image.FORMAT_RGBA8)
	var img := Image.create(src.get_width(), src.get_height(), false, Image.FORMAT_RGBA8)
	for y in src.get_height():
		var first := -1
		var last := -1
		for x in src.get_width():
			if src.get_pixel(x, y).a > 0.0:
				if first < 0:
					first = x
				last = x
		for x in src.get_width():
			var a := src.get_pixel(x, y).a
			if a <= 0.0:
				continue
			var col := Color(NET, 0.3) if a < 0.8 else NET
			if x == first or x == last or y == src.get_height() - 1:
				col = OUTLINE
			img.set_pixel(x, y, col)
	return ImageTexture.create_from_image(img)

## A ball (13 x 13): outlined, shaded towards the bottom right, a shine top left
static func ball(name: String) -> Texture2D:
	var cols: Array = BALLS[name]
	const N := 13
	var img := Image.create(N, N, false, Image.FORMAT_RGBA8)
	var c := Vector2(N / 2.0, N / 2.0)
	for y in N:
		for x in N:
			var off := Vector2(x + 0.5, y + 0.5) - c
			var d := off.length()
			if d > 6.5:
				continue
			var col: Color = cols[0]
			if d > 5.5:
				col = OUTLINE
			elif off.x + off.y > 3.0:
				col = cols[1]
			img.set_pixel(x, y, col)
	for p in [Vector2i(4, 3), Vector2i(3, 4), Vector2i(4, 4)]:
		img.set_pixel(p.x, p.y, cols[2])
	return ImageTexture.create_from_image(img)

## A bubble: a pale ring, see-through inside, a shine
static func bubble(n: int) -> Texture2D:
	var img := Image.create(n, n, false, Image.FORMAT_RGBA8)
	var c := Vector2(n / 2.0, n / 2.0)
	var r := n / 2.0
	for y in n:
		for x in n:
			var d := Vector2(x + 0.5, y + 0.5).distance_to(c)
			if d > r:
				continue
			img.set_pixel(x, y, Color(0.94, 0.98, 0.97, 0.9) if d > r - 1.2 else Color(0.94, 0.98, 0.97, 0.18))
	img.set_pixel(int(n * 0.3), int(n * 0.3), Color.WHITE)
	return ImageTexture.create_from_image(img)

## The pal as a diver: its own sprite shrunk to about `width` art px (not a ball), with a
## diving mask (one wide lens over both eyes, a strap round the sides) and a snorkel up the
## right side. The eyes are found on the small sprite (its dark pixels inside the outline).
static func diver(path: String, width := 30) -> Texture2D:
	var src: Image = (load(path) as Texture2D).get_image()
	if src.is_compressed():
		src.decompress()
	src.convert(Image.FORMAT_RGBA8)
	var used := src.get_used_rect()
	var k := float(used.size.x) / width
	var w := width
	var h := maxi(1, int(ceil(used.size.y / k)))
	# room round the body for the snorkel, the same on both sides so the body stays centred
	# (the game's collider is a circle round the sprite's centre)
	var img := Image.create(w + 6, h + 14, false, Image.FORMAT_RGBA8)
	var ox := 3
	var oy := 7
	var body := Image.create(w, h, false, Image.FORMAT_RGBA8)
	for y in h:
		for x in w:
			# each new pixel: its patch of the sprite; mostly see-through stays so, dark bits win
			var x0 := used.position.x + int(x * k)
			var y0 := used.position.y + int(y * k)
			var x1 := mini(used.position.x + int((x + 1) * k), used.end.x)
			var y1 := mini(used.position.y + int((y + 1) * k), used.end.y)
			var n := 0
			var solid := 0
			var dark := 0
			var acc := Color(0, 0, 0, 0)
			var darkest := Color.WHITE
			for sy in range(y0, y1):
				for sx in range(x0, x1):
					n += 1
					var px := src.get_pixel(sx, sy)
					if px.a < 0.5:
						continue
					solid += 1
					acc += px
					if px.get_luminance() < 0.18:
						dark += 1
						if px.get_luminance() < darkest.get_luminance():
							darkest = px
			if n == 0 or solid * 2 < n:
				continue
			var col := acc / solid
			if dark * 3 >= solid:
				col = darkest
			col.a = 1.0
			body.set_pixel(x, y, col)
	# its outline: the edge pixels in the game's brown
	for y in h:
		for x in w:
			if body.get_pixel(x, y).a <= 0.0:
				continue
			var col := body.get_pixel(x, y)
			for dd in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
				var q: Vector2i = Vector2i(x, y) + dd
				if q.x < 0 or q.y < 0 or q.x >= w or q.y >= h or body.get_pixel(q.x, q.y).a <= 0.0:
					col = OUTLINE
			img.set_pixel(x + ox, y + oy, col)
	# the eyes: dark pixels away from the outline
	var ex0 := w
	var ex1 := -1
	var ey_sum := 0.0
	var ey_n := 0
	for y in range(1, h - 1):
		for x in range(1, w - 1):
			var inside := true
			for dd in [Vector2i(2, 0), Vector2i(-2, 0), Vector2i(0, 2), Vector2i(0, -2)]:
				var q: Vector2i = Vector2i(x, y) + dd
				if q.x < 0 or q.y < 0 or q.x >= w or q.y >= h or body.get_pixel(q.x, q.y).a <= 0.0:
					inside = false
			var px := body.get_pixel(x, y)
			if inside and px.a > 0.0 and px.get_luminance() < 0.18:
				ex0 = mini(ex0, x)
				ex1 = maxi(ex1, x)
				ey_sum += y
				ey_n += 1
	var ey := roundi(ey_sum / ey_n) if ey_n > 0 else h / 2
	if ey_n == 0 or ex1 - ex0 < 4:
		ex0 = w / 2 - 4
		ex1 = w / 2 + 3
	# the strap: across the whole body at the eyes
	var strap := Color8(60, 64, 80)
	for x in w:
		if body.get_pixel(x, ey).a > 0.0:
			img.set_pixel(x + ox, ey + oy, strap)
	# the mask: one wide lens over both eyes (outlined, a glint top left)
	var glass := Color8(176, 222, 236)
	var l0 := maxi(ex0 - 2, 1)
	var l1 := mini(ex1 + 2, w - 2)
	for y in range(ey - 3, ey + 3):
		for x in range(l0, l1 + 1):
			var edge: bool = y == ey - 3 or y == ey + 2 or x == l0 or x == l1
			var corner: bool = (y == ey - 3 or y == ey + 2) and (x == l0 or x == l1)
			if corner:
				continue
			img.set_pixel(x + ox, y + oy, OUTLINE if edge else glass)
	img.set_pixel(l0 + 1 + ox, ey - 2 + oy, Color.WHITE)
	img.set_pixel(l0 + 2 + ox, ey - 2 + oy, Color.WHITE)
	img.set_pixel(l0 + 1 + ox, ey - 1 + oy, Color.WHITE)
	# the snorkel: hugging the body's right side from the strap, its tip a little above the head
	var side := w - 1
	while side > 0 and body.get_pixel(side, ey).a <= 0.0:
		side -= 1
	var sx := side + ox + 2
	var head := 0
	while head < h and body.get_pixel(mini(side, w - 1) - 3, head).a <= 0.0:
		head += 1
	var top := maxi(head + oy - 4, 0)
	for y in range(top + 1, ey + oy + 2):
		img.set_pixel(sx - 1, y, OUTLINE)
		img.set_pixel(sx, y, CORAL)
		img.set_pixel(sx + 1, y, OUTLINE)
	for x in range(sx - 2, sx + 2):
		img.set_pixel(x, top, OUTLINE)
	img.set_pixel(sx - 2, top + 1, CORAL_LIGHT)
	img.set_pixel(sx - 1, top + 1, CORAL)
	img.set_pixel(sx, ey + oy + 2, OUTLINE)
	return ImageTexture.create_from_image(img)
