extends RefCounted
class_name RcSky
## RC Prix's Sky in the designer's art (docs/mockups/rcprix_sky/PLAN.md), a TRIAL behind the dev launcher's
## RC ART switch like the Garden and the Lagoon (the old look stays a switch away). Round 1: the rings, the
## start pad (its deck, the start line, the landing lights, the drone rotors as pieces the game spins) and
## the cloud the Garden's stands sit on, their canopy light blue. The ground far below and the drifting
## clouds are still the old ones (later rounds). One art px = ART_PX world px.

const DIR := "res://textures/minigames/rcprix/sky/"
const ART_PX := 2.0
const RINGS := [124, 112, 100, 88]     # the painted sizes (ring_r, world px): a level's rings drawn at the nearest
const PAD_MARGIN := 33                 # the pad's picture reaches this far past its deck, art px (the guides: the rotors)
const CLOUD_MARGIN := 22               # the stand's cloud reaches this far past its pieces, art px (the guides)
const CANOPY_HUE := 0.56               # the stand's canopy, light blue (the user, 2026-10-28)
static var _imgs := {}
static var _texs := {}

static func on(look: String) -> bool:
	return DevLaunch.rc_new_art and look == "sky" and ResourceLoader.exists(DIR + "ring_124.png")

static func img(name: String) -> Image:
	if not _imgs.has(name):
		var path := DIR + name + ".png"
		var im: Image = null
		if ResourceLoader.exists(path):
			im = (load(path) as Texture2D).get_image()
			if im.is_compressed():
				im.decompress()
			im.convert(Image.FORMAT_RGBA8)
		_imgs[name] = im
	return _imgs[name]

## A piece as a texture for _draw calls (flipped across / down when asked: the rotors' arms)
static func tex(name: String, flip_x := false, flip_y := false) -> Texture2D:
	var key := "%s_%s_%s" % [name, flip_x, flip_y]
	if not _texs.has(key):
		var im := img(name)
		if im == null:
			_texs[key] = null
		else:
			im = im.duplicate()
			if flip_x:
				im.flip_x()
			if flip_y:
				im.flip_y()
			_texs[key] = ImageTexture.create_from_image(im)
	return _texs[key]

## One half of a ring, its look "candy" / "gold" / "grey": the designer's wide ring at the painted size nearest
## r (turned over its diagonal for a course going sideways: the light stays top left), only the pixels on
## the half the plane flies in by (upper) or leaves by. -> [texture, its top left (world px), its scale]
static func ring_half(r: float, look: String, n: Vector2, d: Vector2, upper: bool) -> Array:
	var size: int = RINGS[0]
	for s in RINGS:
		if absf(s - r) < absf(size - r):
			size = s
	var name := "ring_%d" % size if look == "candy" else "ring_%s_%d" % [look, size]
	var im := img(name).duplicate()
	if absf(n.y) > absf(n.x):
		im.rotate_90(CLOCKWISE)                       # (then mirrored: over the diagonal)
		im.flip_x()
	var half := Vector2(im.get_width(), im.get_height()) * 0.5
	for y in im.get_height():
		for x in im.get_width():
			var q := (Vector2(x + 0.5, y + 0.5) - half) * ART_PX
			if (q.dot(d) <= 0.0) != upper:
				im.set_pixel(x, y, Color(0, 0, 0, 0))
	return [ImageTexture.create_from_image(im), -half * ART_PX, ART_PX]

## A stand piece with its canopy light blue (the Garden's greens turned, as the Lagoon turned them warm)
static func stand_tex(name: String) -> Texture2D:
	var key := "stand_" + name
	if not _texs.has(key):
		var im := RcTiles.img(name)
		if im == null:
			_texs[key] = null
			return null
		im = im.duplicate()
		for y in im.get_height():
			for x in im.get_width():
				var c := im.get_pixel(x, y)
				if c.a > 0.0 and c.s > 0.25 and c.h > 0.2 and c.h < 0.5:
					im.set_pixel(x, y, Color.from_hsv(CANOPY_HUE, minf(1.0, c.s * 0.55), minf(1.0, c.v * 1.35), c.a))
		_texs[key] = ImageTexture.create_from_image(im)
	return _texs[key]
