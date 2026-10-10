extends RefCounted
class_name UiArt
## Small pixel icons shared by the level menus, the Games menu and the Shop (drawn in code, one
## texture each, cached): the level star (won / not yet), the coin and the padlock.

const OUTLINE := Color8(74, 44, 32)
const GOLD := Color8(250, 204, 70)
const GOLD_LIGHT := Color8(255, 240, 160)
const GOLD_DARK := Color8(214, 146, 40)
const EMPTY := Color8(150, 120, 98)
const EMPTY_DARK := Color8(118, 92, 74)

static var _cache := {}

## The type tags' words and colours (food menu, Shop): muted pastels, the evolution tree's colours
const TYPE_TAGS := {
	"green": ["Green", Color8(176, 200, 150)], "sweet": ["Sweet", Color8(232, 182, 196)],
	"greasy": ["Greasy", Color8(222, 186, 144)], "spicy": ["Spicy", Color8(226, 160, 144)],
	"sour": ["Sour", Color8(226, 214, 150)], "tech": ["Tech", Color8(170, 186, 200)],
	"cosmic": ["Cosmic", Color8(196, 178, 214)], "legend": ["Rare", Color8(236, 208, 140)],
	# drinks
	"watery": ["Watery", Color8(180, 208, 226)], "fizzy": ["Fizzy", Color8(232, 192, 184)],
	"caffeinated": ["Energy", Color8(206, 186, 164)], "milky": ["Milky", Color8(238, 232, 220)],
	"fruity": ["Fruity", Color8(240, 200, 160)],
}


## A five-pointed star, 13 x 13 px: gold when won, a dull hollow one when not
static func star(won: bool) -> Texture2D:
	var key := "star_%s" % won
	if key in _cache:
		return _cache[key]
	const N := 13
	var c := Vector2(N / 2.0, N / 2.0 + 0.4)
	var pts: Array[Vector2] = []
	for i in 10:
		var a := -PI / 2.0 + i * PI / 5.0
		var r := 6.3 if i % 2 == 0 else 2.7
		pts.append(c + Vector2(cos(a), sin(a)) * r)
	var poly := PackedVector2Array(pts)
	var inside := []
	for y in N:
		var row := []
		for x in N:
			row.append(Geometry2D.is_point_in_polygon(Vector2(x + 0.5, y + 0.5), poly))
		inside.append(row)
	var img := Image.create(N, N, false, Image.FORMAT_RGBA8)
	for y in N:
		for x in N:
			if inside[y][x]:
				# lit from the top left, like everything else
				var col := GOLD if won else EMPTY
				if won and (x + y) < N - 3:
					col = GOLD_LIGHT if (x + y) < N - 6 else GOLD
				elif (x + y) > N + 2:
					col = GOLD_DARK if won else EMPTY_DARK
				img.set_pixel(x, y, col)
			else:
				for d in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
					var q: Vector2i = Vector2i(x, y) + d
					if q.x >= 0 and q.y >= 0 and q.x < N and q.y < N and inside[q.y][q.x]:
						img.set_pixel(x, y, OUTLINE)
						break
	var tex := ImageTexture.create_from_image(img)
	_cache[key] = tex
	return tex

## The coin (the same one as in Splash Hoops)
static func coin() -> Texture2D:
	if "coin" not in _cache:
		_cache["coin"] = SplashArt.coin()
	return _cache["coin"]

## A padlock, 9 x 11 px
static func lock() -> Texture2D:
	if "lock" in _cache:
		return _cache["lock"]
	var rows := [
		"..#####..",
		".#.....#.",
		".#.....#.",
		".#.....#.",
		"#########",
		"#bbbbbbb#",
		"#bbb#bbb#",
		"#bbb#bbb#",
		"#bbbbbbb#",
		"#ddddddd#",
		"#########",
	]
	var cols := { "#": OUTLINE, "b": Color8(214, 176, 112), "d": Color8(176, 136, 80) }
	var img := Image.create(9, rows.size(), false, Image.FORMAT_RGBA8)
	for y in rows.size():
		for x in 9:
			var ch: String = rows[y][x]
			if ch in cols:
				img.set_pixel(x, y, cols[ch])
	var tex := ImageTexture.create_from_image(img)
	_cache["lock"] = tex
	return tex

## The food menu's roll-down shutter (pixel art in the panel's orange): slats with light top
## edges, a darker grid, side rails and a dark bottom bar with a little handle. w x h pixels.
static func shutter(w: int, h: int) -> Texture2D:
	var key := "shutter_%d_%d" % [w, h]
	if key in _cache:
		return _cache[key]
	var img := Image.create(w, h, false, Image.FORMAT_RGBA8)
	var base := Color8(215, 160, 96)
	var light := Color8(232, 190, 132)
	var dark := Color8(186, 132, 76)
	var ink := Color8(84, 66, 50)
	for y in h:
		for x in w:
			var col := base
			var slat := y % 12
			if slat == 0:
				col = light
			elif slat == 11:
				col = dark
			if x % 10 == 0 and slat > 0 and slat < 11:
				col = dark
			if y >= h - 6:
				col = ink if y >= h - 2 or y == h - 6 else dark
			if x < 2 or x >= w - 2:
				col = ink
			img.set_pixel(x, y, col)
	for x in range(w / 2 - 8, w / 2 + 8):
		for y in range(h - 12, h - 7):
			img.set_pixel(x, y, ink if (y == h - 12 or x == w / 2 - 8 or x == w / 2 + 7) else light)
	var tex := ImageTexture.create_from_image(img)
	_cache[key] = tex
	return tex

## A "?" the size of a food icon (32 x 32): a special food you don't have yet
static func question() -> Texture2D:
	if "question" in _cache:
		return _cache["question"]
	var rows := [
		"....######....",
		"...########...",
		"..###....###..",
		"..##......##..",
		"..........##..",
		".........###..",
		"........###...",
		".......###....",
		"......###.....",
		"......##......",
		"......##......",
		"..............",
		"......##......",
		"......##......",
	]
	const PX := 2
	var img := Image.create(32, 32, false, Image.FORMAT_RGBA8)
	var ox: int = (32 - String(rows[0]).length() * PX) / 2
	var oy: int = (32 - rows.size() * PX) / 2
	var fill := Color8(150, 154, 96)
	var light := Color8(186, 190, 126)
	var inside := {}
	for y in rows.size():
		var row: String = rows[y]
		for x in row.length():
			if row[x] == "#":
				for by in PX:
					for bx in PX:
						inside[Vector2i(ox + x * PX + bx, oy + y * PX + by)] = true
	for p in inside:
		img.set_pixel(p.x, p.y, light if p.y < 16 and p.x < 16 else fill)
	# the dark outline round it
	for p in inside:
		for d in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1), Vector2i(1, 1)]:
			var q: Vector2i = p + d
			if q.x >= 0 and q.y >= 0 and q.x < 32 and q.y < 32 and not inside.has(q):
				img.set_pixel(q.x, q.y, OUTLINE)
	var tex := ImageTexture.create_from_image(img)
	_cache["question"] = tex
	return tex

## A list's scroll mark (the food menu's right edge): a small round pip, filled in for the items
## on screen, hollow for the rest
static func scroll_mark(on: bool) -> Texture2D:
	var key := "scroll_%s" % on
	if key in _cache:
		return _cache[key]
	var rows := [
		".###.",
		"#fff#",
		"#fff#",
		"#fff#",
		".###.",
	]
	var fill := Color8(92, 60, 44) if on else Color8(240, 214, 170)
	var cols := { "#": Color8(92, 60, 44), "f": fill }
	var img := Image.create(5, 5, false, Image.FORMAT_RGBA8)
	for y in 5:
		for x in 5:
			var ch: String = rows[y][x]
			if ch in cols:
				img.set_pixel(x, y, cols[ch])
	var tex := ImageTexture.create_from_image(img)
	_cache[key] = tex
	return tex

## The level / size icons: a type's icon 1-3 times (foods: Sho 1, Chu 2, Dai 3; drinks: power 1-3).
## Art: textures/menus/tiers/<type>.png (docs/mockups/food_drafts/tier_icons.py, drink_drafts/level_icons.py)
static func tier_row(kind: String, n: int) -> Texture2D:
	var key := "tier_%s_%d" % [kind, n]
	if key in _cache:
		return _cache[key]
	var path := "res://textures/menus/tiers/%s.png" % kind
	if n <= 0 or not ResourceLoader.exists(path):
		return null
	var one: Image = (load(path) as Texture2D).get_image()
	one.convert(Image.FORMAT_RGBA8)
	var w := one.get_width()
	var img := Image.create(w * n + (n - 1), one.get_height(), false, Image.FORMAT_RGBA8)
	for i in n:
		img.blit_rect(one, Rect2i(0, 0, w, one.get_height()), Vector2i(i * (w + 1), 0))
	var tex := ImageTexture.create_from_image(img)
	_cache[key] = tex
	return tex

## The 1-3 level icons on a tag's top-right corner (the food menu's cards and the Shop's)
static func place_tier_icons(parent: Node, tag: Sprite2D, family: String, level: int) -> void:
	var icons: Sprite2D = parent.get_node_or_null("TierIcons")
	var tex := UiArt.tier_row(family, level)
	if not tex:
		if icons:
			icons.visible = false
		return
	if not icons:
		icons = Sprite2D.new()
		icons.name = "TierIcons"
		icons.centered = false
		icons.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		icons.z_index = tag.z_index + 1
		parent.add_child(icons)
	var k: float = tag.scale.x / 0.84 * 2.0          # (the frame's scale x2, like the mock-up)
	icons.texture = tex
	icons.scale = Vector2(k, k)
	var tag_size: Vector2 = tag.texture.get_size() * tag.scale
	icons.position = tag.position + Vector2(tag_size.x - tex.get_width() * k + 4.0 * k, -tex.get_height() * k * 0.5 - 1.0 * k)
	icons.visible = true
