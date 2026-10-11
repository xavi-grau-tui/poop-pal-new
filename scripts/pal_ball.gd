class_name PalBall
## The current pal as a little round ball (Tilt Maze, Tile Break, Flipper Belly...):
## a 24 px canvas holding a 16 px ball (the 4 px around it: room for ears, leaves, wrappers),
## shown at x3 by the games. Every pal has its own ball art (textures/minigames/balls/<id>.png,
## made by tools/art/pal_balls.py); one wrapped from the sprite is the fallback. Cached per pal.

const ART := 24                  # canvas size; the ball itself is 16 px across
const SIZE := 16

static var _cache := {}

## The texture for the pal you have now (the classic ball when there's none)
static func texture() -> Texture2D:
	var key: String = PetState.form_id if PetState.has_poop() else ""
	if not _cache.has(key):
		var path := "res://textures/minigames/balls/%s.png" % key
		_cache[key] = load(path) if key != "" and ResourceLoader.exists(path) else _build()
	return _cache[key]

## Your pal as a ball: its own sprite (colours, face, topping) wrapped round onto a ball,
## with the checkpoint balls' look on top: lit top-left, shaded bottom-right, a shine and a
## dark outline. Each new pixel picks from its patch of the sprite and the dark bits (eyes,
## mouth) win, so the face stays readable. Works for every pal.
static func _build() -> Texture2D:
	var path := "res://textures/minigames/balls/classic.png"
	if PetState.has_poop():
		path = PetState.FORMS[PetState.form_id]["frames"][0]
	var src: Image = (load(path) as Texture2D).get_image()
	if src.is_compressed():
		src.decompress()
	src.convert(Image.FORMAT_RGBA8)
	var used := src.get_used_rect()
	var S := ART
	var c0 := Vector2(S / 2.0, S / 2.0)
	var r := 8.0
	var body := _main_colour(src, Rect2i(used.position.x, used.position.y + used.size.y * 55 / 100, used.size.x, used.size.y * 30 / 100))
	var ink := body.darkened(0.65)
	var img := Image.create(S, S, false, Image.FORMAT_RGBA8)
	var inner := r - 1.0
	# the sprite's own outline and the dark shading along it are left out (one round ball,
	# not the pal's shape drawn inside it): only the dark bits inside (eyes, mouth) win
	var edge := {}
	for sy in range(used.position.y, used.end.y):
		for sx in range(used.position.x, used.end.x):
			if src.get_pixel(sx, sy).a < 0.5:
				continue
			for dd: Vector2i in [Vector2i(6, 0), Vector2i(-6, 0), Vector2i(0, 6), Vector2i(0, -6), Vector2i(4, 4), Vector2i(-4, 4), Vector2i(4, -4), Vector2i(-4, -4)]:
				var q := Vector2i(sx, sy) + dd
				if q.x < 0 or q.y < 0 or q.x >= src.get_width() or q.y >= src.get_height() or src.get_pixel(q.x, q.y).a < 0.5:
					edge[Vector2i(sx, sy)] = true
					break
	for y in S:
		for x in S:
			var off := Vector2(x + 0.5, y + 0.5) - c0
			var d := off.length()
			if d > r:
				continue
			if d > r - 1.1:
				img.set_pixel(x, y, ink)
				continue
			# the sprite squeezed into the ball: ball pixel -> a patch of the sprite
			var u0 := (off.x - 0.5) / (inner * 2.0) + 0.5
			var u1 := (off.x + 0.5) / (inner * 2.0) + 0.5
			var v0 := (off.y - 0.5) / (inner * 2.0) + 0.5
			var v1 := (off.y + 0.5) / (inner * 2.0) + 0.5
			var sx0 := used.position.x + int(clampf(u0, 0.0, 1.0) * used.size.x)
			var sx1 := used.position.x + int(clampf(u1, 0.0, 1.0) * used.size.x)
			var sy0 := used.position.y + int(clampf(v0, 0.0, 1.0) * used.size.y)
			var sy1 := used.position.y + int(clampf(v1, 0.0, 1.0) * used.size.y)
			var total := 0
			var opaque := 0
			var dark := 0
			var sum := Color(0, 0, 0, 0)
			var darkest := Color(1, 1, 1, 1)
			for sy in range(sy0, maxi(sy1, sy0 + 1)):
				for sx in range(sx0, maxi(sx1, sx0 + 1)):
					total += 1
					var sc := src.get_pixel(sx, sy)
					if sc.a < 0.5 or edge.has(Vector2i(sx, sy)):
						continue
					opaque += 1
					sum += sc
					if sc.get_luminance() < 0.22:
						dark += 1
						if sc.get_luminance() < darkest.get_luminance():
							darkest = sc
			var col: Color = body                     # (outside the pal's shape: its body colour)
			if opaque * 3 >= total and opaque > 0:
				col = darkest if dark * 3 >= opaque else sum / float(opaque)
			col.a = 1.0
			# a ball's light: brighter top-left, darker bottom-right
			var lit := off.x + off.y
			if lit < -5.0:
				col = col.lightened(0.14)
			elif lit > 5.0:
				col = col.darkened(0.16)
			img.set_pixel(x, y, col)
	# shine
	for p in [Vector2i(-5, -3), Vector2i(-4, -4)]:
		img.set_pixel(int(c0.x) + p.x, int(c0.y) + p.y, Color(1, 1, 1, 0.9))
	return ImageTexture.create_from_image(img)

## The most common (non-outline) colour in a part of the sprite, roughly
static func _main_colour(src: Image, area: Rect2i) -> Color:
	var counts := {}
	var sums := {}
	for y in range(area.position.y, area.end.y):
		for x in range(area.position.x, area.end.x):
			var c := src.get_pixel(x, y)
			if c.a < 0.5 or c.get_luminance() < 0.2:
				continue
			var key := Vector3i(int(c.r * 6), int(c.g * 6), int(c.b * 6))
			counts[key] = counts.get(key, 0) + 1
			sums[key] = sums.get(key, Color(0, 0, 0, 0)) + c
	var best = null
	for k in counts:
		if best == null or counts[k] > counts[best]:
			best = k
	if best == null:
		return Color8(196, 120, 80)
	var col: Color = sums[best] / float(counts[best])
	col.a = 1.0
	return col
