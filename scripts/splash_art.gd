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
	"violet": [Color8(150, 112, 200), Color8(108, 78, 156), Color8(208, 182, 240)],
	"teal": [Color8(70, 176, 178), Color8(44, 128, 136), Color8(152, 226, 220)],
	"white": [Color8(244, 240, 230), Color8(198, 190, 178), Color8(255, 255, 255)],
	"purple": [Color8(178, 112, 198), Color8(128, 74, 150), Color8(228, 184, 238)],
	"orange": [Color8(246, 150, 70), Color8(196, 104, 40), Color8(255, 208, 152)],
	"red": [Color8(222, 72, 64), Color8(168, 46, 44), Color8(250, 152, 138)],
	# night: they glow (bright, with a halo behind: glow())
	"glow_pink": [Color8(255, 132, 200), Color8(222, 82, 172), Color8(255, 222, 242)],
	"glow_lime": [Color8(194, 255, 112), Color8(132, 222, 62), Color8(242, 255, 212)],
	"glow_cyan": [Color8(112, 240, 255), Color8(62, 192, 232), Color8(222, 255, 255)],
}

## The six worlds' looks (user, 2026-10-11: every world clearly different from the others): the
## water (5 bands, top to bottom), what's printed on the tank's back panel (scene), the sand, the
## baskets' and pumps' plastic, the nets, the balls, the bubbles, the points on the baskets, and
## the level menu's page colour. glow = balls and baskets light up (night, the deep).
## The back panels (2026-10-16, after Pal Prix's Garden): one time of day and one small palette per
## world, depth by haze (things further back are paler, closer to the water's colour), light
## playing through the water (caustics), and the sand dressed (shells, pebbles, seagrass).
const THEMES := [
	{ # 1 Morning Lagoon: the toy as it always was, and a sunny lagoon printed behind it
		"water": WATER, "rays": true, "scene": "lagoon",
		"sand": [CASE, CASE_LIGHT, CASE_SHADE],
		"rim": [CORAL_LIGHT, CORAL, CORAL_DARK], "net": NET,
		"balls": ["pink", "yellow", "mint"], "bubble": Color(0.94, 0.98, 0.97), "glow": false,
		"label": OUTLINE, "menu": Color8(150, 182, 168) },
	{ # 2 Sunset Drift: an orange evening sky, a low striped sun over the sea
		"water": [Color8(252, 206, 146), Color8(246, 172, 118), Color8(214, 120, 108), Color8(170, 94, 112), Color8(126, 72, 110)],
		"rays": false, "scene": "sun",
		"sand": [Color8(238, 198, 160), Color8(252, 224, 192), Color8(212, 168, 134)],
		"rim": [Color8(134, 216, 210), Color8(70, 168, 170), Color8(40, 118, 128)], "net": NET,
		"balls": ["violet", "teal", "white"], "bubble": Color(1.0, 0.95, 0.88), "glow": false,
		"label": OUTLINE, "menu": Color8(230, 148, 108) },
	{ # 3 Pufferfish Reef: bright turquoise, corals, seaweed and little fish on the back
		"water": [Color8(150, 226, 216), Color8(112, 208, 206), Color8(78, 184, 198), Color8(56, 154, 184), Color8(42, 124, 166)],
		"rays": true, "scene": "reef",
		"sand": [Color8(246, 236, 210), Color8(255, 250, 234), Color8(220, 206, 176)],
		"rim": [Color8(255, 228, 122), Color8(240, 184, 60), Color8(186, 128, 34)], "net": NET,
		"balls": ["pink", "purple", "orange"], "bubble": Color(0.94, 0.99, 1.0), "glow": false,
		"label": OUTLINE, "menu": Color8(92, 176, 186) },
	{ # 4 Night Lights: deep blue, a moon and stars, glowing plankton; balls and baskets glow
		"water": [Color8(54, 66, 118), Color8(44, 54, 102), Color8(36, 44, 88), Color8(28, 36, 74), Color8(22, 28, 60)],
		"rays": false, "scene": "night",
		"sand": [Color8(70, 76, 114), Color8(98, 106, 146), Color8(54, 58, 94)],
		"rim": [Color8(176, 255, 246), Color8(82, 228, 222), Color8(36, 150, 172)], "net": Color8(204, 255, 248),
		"balls": ["glow_pink", "glow_lime", "glow_cyan"], "bubble": Color(0.72, 1.0, 0.95), "glow": true,
		"label": Color8(214, 255, 248), "menu": Color8(52, 60, 108) },
	{ # 5 Storm: grey-green water under dark clouds, rain; the current pushes everything
		"water": [Color8(128, 144, 146), Color8(108, 126, 130), Color8(90, 108, 116), Color8(72, 92, 102), Color8(58, 76, 88)],
		"rays": false, "scene": "rain",
		"sand": [Color8(178, 172, 158), Color8(206, 200, 186), Color8(148, 142, 130)],
		"rim": [Color8(255, 192, 112), Color8(240, 134, 52), Color8(180, 88, 32)], "net": NET,
		"balls": ["yellow", "red", "white"], "bubble": Color(0.9, 0.95, 0.96), "glow": false,
		"label": OUTLINE, "menu": Color8(98, 114, 120) },
	{ # 6 Deep Sea (the masters' world): almost black water, glowing life; you see what the light
	  # shows (your pal's glow, the anglerfish's lure); the lure pulls the balls to its jaws
		"water": [Color8(26, 40, 62), Color8(20, 32, 52), Color8(16, 26, 44), Color8(12, 20, 36), Color8(10, 16, 30)],
		"rays": false, "scene": "deep",
		"sand": [Color8(46, 52, 70), Color8(66, 74, 96), Color8(34, 38, 54)],
		"rim": [Color8(255, 196, 240), Color8(232, 120, 214), Color8(150, 62, 160)], "net": Color8(255, 220, 246),
		"balls": ["glow_cyan", "glow_lime", "glow_pink"], "bubble": Color(0.6, 0.9, 1.0), "glow": true,
		"label": Color8(255, 220, 246), "menu": Color8(30, 44, 70), "dark": true },
]

## The tank: top band (the HUD sits on it), water (edge to edge: no side rails, they peeked
## out past the console's screen window) with light rays, the funnel floor
## shaped by floor_at (world coords), a darker hole at each pump
static func tank(w_px: int, h_px: int, band_y: float, _wall_l: float, _wall_r: float, floor_at: Callable, _nozzles: Array, theme: Dictionary = THEMES[0]) -> Texture2D:
	var img := Image.create(w_px, h_px, false, Image.FORMAT_RGBA8)
	var water_top := band_y
	var water_bottom := 880.0
	var water: Array = theme["water"]
	var sand: Array = theme["sand"]
	var scene: String = theme["scene"]
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
				col = _sand(int(wx / P), int(wy / P), wy - fy, sand)
				col = _sand_decor(scene, wx, wy, fy, col, sand)
			else:                                                # the water
				var t := clampf((wy - water_top) / (water_bottom - water_top), 0.0, 0.999)
				var band := int(t * water.size())
				col = water[band]
				if theme["rays"] and band > 0 and wy < 640.0 and _in_ray(wx, wy - water_top):
					col = water[band - 1]                        # light through the water
				if scene != "":
					col = _scene(scene, wx, wy, fy, col, water)
			img.set_pixel(x, y, col)
	return ImageTexture.create_from_image(img)

## The sand floor: a 2 px outline along its top, a lit lip, then the sand's own colour with
## grains (a lighter and a darker one, scattered) and soft ripples that follow the slope.
## sand = [base, light, shade]
static func _sand(ax: int, ay: int, depth: float, sand: Array = [CASE, CASE_LIGHT, CASE_SHADE]) -> Color:
	if depth < P * 2:
		return OUTLINE
	if depth < P * 3:
		return sand[1]
	var h := _hash(ax, ay)
	var ripple := int(depth / P + 1.6 * sin(ax * 0.21)) % 10
	if ripple == 0 and h < 0.8:
		return (sand[2] as Color).lerp(sand[0], 0.35)    # a ripple's shady side
	if ripple == 1 and h < 0.6:
		return sand[1]                                   # its lit crest
	if h < 0.04:
		return sand[2]                                   # a few scattered grains
	if h > 0.96:
		return sand[1]
	return sand[0]

## What's printed on the tank's back panel in each world (world px; the water colour under it)
static func _scene(kind: String, wx: float, wy: float, fy: float, col: Color, water: Array) -> Color:
	var ax := int(wx / P)
	var ay := int(wy / P)
	match kind:
		"lagoon":
			# a sunny lagoon: caustics near the surface, a pale sandbank far back with seagrass on it,
			# a school of little fish, tall seagrass along the floor (all printed paler than the toy)
			var c := _caustic(wx, wy)
			if c > 0.0 and wy < 520.0:
				col = col.lerp(Color8(214, 240, 232), c * (1.0 - (wy - 104.0) / 420.0) * 0.55)
			var bank := 560.0 + 34.0 * sin(wx * 0.006 + 1.0) + 18.0 * sin(wx * 0.017)
			if wy > bank and wy < fy - 40.0:
				col = col.lerp(Color8(176, 214, 198), 0.32)              # the sandbank, hazy
				if absf(fmod(wx + 13.0 * sin(wy * 0.05), 41.0) - 20.0) < 2.0 and wy < bank + 46.0:
					col = col.lerp(Color8(110, 170, 140), 0.35)          # seagrass on it
			for f in [Vector2(250, 330), Vector2(286, 352), Vector2(232, 368), Vector2(272, 384), Vector2(310, 330)]:
				if _fish(wx, wy, f, 1.0, 9.0):
					return col.lerp(Color8(90, 140, 150), 0.42)
			if wy > fy - 190.0:
				for sx in [70.0, 118.0, 400.0, 560.0, 860.0, 905.0]:
					var x0: float = sx + 10.0 * sin(wy * 0.04 + sx * 0.3)
					if absf(wx - x0) < 4.5 and wy > fy - 150.0 - fmod(sx * 7.0, 50.0):
						return col.lerp(Color8(70, 150, 112), 0.5)
			return col
		"sun":
			# the sky above the horizon, a big low sun with a striped bottom, the sea below with
			# the sun's broken reflection
			const SUN := Vector2(720, 250)
			const R := 92.0
			const HORIZON := 402.0
			if wy < HORIZON:
				col = water[0] if wy < 250.0 else water[1]
				# islands far off on the horizon, a palm on each; gulls in the sky
				for it in [[Vector2(220, HORIZON), 110.0, 26.0], [Vector2(470, HORIZON), 60.0, 14.0]]:
					var ic: Vector2 = it[0]
					var dx: float = absf(wx - ic.x) / float(it[1])
					if dx < 1.0 and wy > HORIZON - float(it[2]) * (1.0 - dx * dx):
						return Color8(150, 92, 120)
				for pt in [Vector2(196, HORIZON - 26), Vector2(462, HORIZON - 14)]:
					var tx: float = pt.x + (pt.y - wy) * 0.25
					if absf(wx - tx) < 2.5 and wy < pt.y + 2.0 and wy > pt.y - 44.0:
						return Color8(150, 92, 120)                  # a trunk
					var crown := Vector2(wx, wy) - Vector2(pt.x + 11.0, pt.y - 46.0)
					if absf(crown.y + 0.25 * absf(crown.x)) < 3.0 and absf(crown.x) < 26.0:
						return Color8(150, 92, 120)                  # its fronds
				for bd in [Vector2(330, 160), Vector2(372, 140), Vector2(560, 182)]:
					var bx := absf(wx - bd.x)
					if bx < 9.0 and absf(wy - (bd.y + bx * 0.45)) < 1.5:
						return Color8(120, 70, 100)                  # a gull
				var d := Vector2(wx, wy).distance_to(SUN)
				if d < R:
					var below := wy - SUN.y
					if below > 6.0 and fmod(below, 16.0) < 2.0 + int(below / 16.0) * 1.8:
						return col                                   # the stripes across its bottom half
					return Color8(255, 240, 176) if d < R - 9.0 else Color8(255, 218, 138)
				if d < R + 18.0 and (ax + ay) % 2 == 0:
					return col.lerp(Color8(255, 228, 160), 0.45)     # a dithered glow round it
				return col
			if wy < HORIZON + P:
				return Color8(255, 222, 150)                         # the horizon, lit
			var sea := clampf((wy - HORIZON) / 420.0, 0.0, 0.999)
			col = water[2 + int(sea * 3.0)]
			var half := 70.0 - (wy - HORIZON) * 0.12
			if half > 6.0 and absf(wx - SUN.x) < half and ay % 4 == 0 and _hash(int(wx / 18.0), ay) > 0.35:
				return col.lerp(Color8(255, 210, 150), 0.6)          # the reflection, in streaks
			return col
		"reef":
			# corals, sea fans and seaweed along the bottom, two little fish: printed darker than the
			# water so they stay behind the toy; caustics over the top, a turtle far off
			var cc := _caustic(wx, wy)
			if cc > 0.0 and wy < 460.0:
				col = col.lerp(Color8(220, 250, 246), cc * 0.4)
			var turtle := Vector2(wx, wy) - Vector2(640, 250)
			if (turtle.x / 46.0) * (turtle.x / 46.0) + (turtle.y / 26.0) * (turtle.y / 26.0) < 1.0:
				return col.lerp(water[2], 0.5)                       # its shell, hazy
			for fl in [Vector2(-40, -20), Vector2(30, -24), Vector2(-40, 22), Vector2(34, 20)]:
				var ff: Vector2 = turtle - fl
				if absf(ff.x) < 16.0 and absf(ff.y) < 6.0:
					return col.lerp(water[2], 0.42)                  # its flippers
			if Vector2(wx, wy).distance_to(Vector2(698, 246)) < 13.0:
				return col.lerp(water[2], 0.45)                      # its head
			var back: Color = water[3]
			for f in [Vector2(150, 300), Vector2(800, 360)]:
				var dd: Vector2 = Vector2(wx, wy) - f
				if (dd.x / 22.0) * (dd.x / 22.0) + (dd.y / 11.0) * (dd.y / 11.0) < 1.0 or (dd.x > 18.0 and dd.x < 34.0 and absf(dd.y) < (dd.x - 16.0) * 0.6):
					return col.lerp(back, 0.55)                     # a fish (and its tail)
			if wy > fy - 230.0:
				# seaweed: wavy strands
				for sx in [60.0, 300.0, 610.0, 900.0]:
					var x0: float = sx + 9.0 * sin(wy * 0.045 + sx)
					if absf(wx - x0) < 6.0 and wy > fy - 200.0 + fmod(sx, 60.0):
						return col.lerp(Color8(60, 150, 110), 0.55)
				# lumpy corals (pink, orange, purple)
				var corals := [[Vector2(120, 0), Color8(236, 120, 130)], [Vector2(400, 0), Color8(244, 160, 90)],
						[Vector2(560, 0), Color8(170, 110, 196)], [Vector2(850, 0), Color8(236, 120, 130)]]
				for c in corals:
					var cx: float = c[0].x
					var base_y := fy
					for k in 5:
						var bx: float = cx + [-26.0, -12.0, 0.0, 14.0, 28.0][k]
						var top: float = base_y - [70.0, 110.0, 140.0, 100.0, 64.0][k]
						if absf(wx - bx) < 7.0 and wy > top:
							return col.lerp(c[1], 0.5)
						if Vector2(wx, wy).distance_to(Vector2(bx, top)) < 11.0:
							return col.lerp(c[1], 0.62)
				# a sea fan between them: a half disc with holes
				var fan := Vector2(wx, wy) - Vector2(250, fy - 20.0)
				if fan.y < 0.0 and fan.length() < 90.0 and (ax % 4 != 0 and ay % 4 != 0):
					return col.lerp(Color8(250, 150, 120), 0.4)
			return col
		"night":
			# a moon (craters, a dithered glow), stars up high, glowing plankton down low
			const MOON := Vector2(190, 232)
			var dm := Vector2(wx, wy).distance_to(MOON)
			if dm < 52.0:
				for cr in [Vector2(172, 220), Vector2(206, 250), Vector2(200, 212)]:
					if Vector2(wx, wy).distance_to(cr) < 9.0:
						return Color8(222, 216, 188)
				return Color8(250, 244, 214)
			if dm < 74.0 and (ax + ay) % 2 == 0:
				return col.lerp(Color8(160, 170, 220), 0.35)
			var h := _hash(ax, ay)
			if wy < 560.0 and h < 0.006:
				return Color8(250, 248, 230)                         # a star
			if wy > 520.0 and h > 0.992:
				return col.lerp(Color8(120, 244, 230), 0.7)          # plankton
			# a jellyfish drifting far back: a glowing dome and long trailing tentacles
			var jf := Vector2(wx, wy) - Vector2(720, 330)
			if jf.y < 0.0 and (jf.x / 54.0) * (jf.x / 54.0) + (jf.y / 40.0) * (jf.y / 40.0) < 1.0:
				return col.lerp(Color8(200, 150, 240), 0.45 if jf.y > -30.0 else 0.32)
			if jf.y >= 0.0 and jf.y < 150.0:
				for tx in [-36.0, -14.0, 8.0, 30.0]:
					if absf(jf.x - tx - 8.0 * sin(jf.y * 0.06 + tx)) < 2.0:
						return col.lerp(Color8(190, 140, 230), 0.4 * (1.0 - jf.y / 150.0))
			return col
		"deep":
			# the deep: glowing specks, a kraken's tentacles curling up from the dark far back, a
			# faint glow from the vents on the floor
			var h2 := _hash(ax, ay)
			if h2 > 0.995:
				return col.lerp(Color8(120, 220, 255), 0.75)
			if h2 < 0.003 and wy > 300.0:
				return col.lerp(Color8(255, 150, 220), 0.6)
			for tk in [[140.0, 0.0], [820.0, 2.0], [600.0, 4.0]]:
				var base: float = tk[0]
				var tx: float = base + 46.0 * sin(wy * 0.012 + tk[1]) + 20.0 * sin(wy * 0.031)
				var width := 14.0 * clampf((wy - 260.0) / 500.0, 0.25, 1.0)
				if absf(wx - tx) < width and wy > 260.0 and wy < fy - 30.0:
					var suck := fmod(wy, 26.0) < 6.0 and wx > tx
					return col.lerp(Color8(70, 54, 96) if not suck else Color8(110, 80, 130), 0.55)
			return col
		"rain":
			# dark clouds along the top, rain slanting down
			var puff := 0.0
			for k in 8:
				var c := Vector2(60.0 + k * 125.0, 120.0 + 18.0 * sin(k * 2.1))
				puff = maxf(puff, 1.0 - Vector2(wx, wy).distance_to(c) / (70.0 + 12.0 * sin(k * 1.3)))
			if puff > 0.0:
				if puff > 0.18 or (ax + ay) % 2 == 0:
					return col.lerp(Color8(64, 74, 82), 0.75)
			var u := wx + wy * 0.32
			var lane := int(u / 46.0)
			if fmod(u, 46.0) < 3.0 and fmod(wy + lane * 37.0, 70.0) < 24.0 and wy < fy - 40.0:
				return col.lerp(Color8(186, 200, 204), 0.45)         # a raindrop's streak
			# a lighthouse on a rock far off, its beam sweeping over the waves
			var lh := Vector2(wx, wy) - Vector2(800, 330)
			if absf(lh.x) < 13.0 - lh.y * 0.04 and lh.y > -70.0 and lh.y < 40.0:
				var stripe := int((lh.y + 70.0) / 22.0) % 2 == 0
				return col.lerp(Color8(214, 206, 196) if stripe else Color8(170, 90, 84), 0.55)
			if absf(lh.x) < 16.0 and lh.y > -86.0 and lh.y <= -70.0:
				return col.lerp(Color8(255, 236, 160), 0.7)          # its lamp
			if lh.y > 40.0 and lh.y < 70.0 and absf(lh.x) < 60.0 - lh.y * 0.3:
				return col.lerp(Color8(60, 70, 74), 0.6)             # its rock
			var beam := Vector2(wx, wy) - Vector2(800, 252)
			if beam.x < -20.0 and absf(beam.y + beam.x * 0.08) < 10.0 - beam.x * 0.06 and (ax + ay) % 2 == 0:
				return col.lerp(Color8(255, 240, 190), 0.25)
			# waves breaking along the top, under the clouds
			if wy > 214.0 and wy < 236.0 and fmod(wx + 30.0 * sin(wy * 0.3), 90.0) < 40.0 - (wy - 214.0):
				return col.lerp(Color8(214, 224, 222), 0.35)
			return col
	return col

## Light playing through the water: a bright net of wobbly lines (0 = none .. 1 = brightest)
static func _caustic(wx: float, wy: float) -> float:
	var a := sin(wx * 0.045 + 2.0 * sin(wy * 0.03)) * sin(wy * 0.06 + 2.2 * sin(wx * 0.021))
	var v := 1.0 - absf(a) * 9.0
	return clampf(v, 0.0, 1.0) if (int(wx / P) + int(wy / P)) % 2 == 0 or v > 0.6 else 0.0

## A little fish shape facing left (its tail on the right), at f, size k
static func _fish(wx: float, wy: float, f: Vector2, k: float, r: float) -> bool:
	var d := (Vector2(wx, wy) - f) / k
	if (d.x / r) * (d.x / r) + (d.y / (r * 0.5)) * (d.y / (r * 0.5)) < 1.0:
		return true
	return d.x > r * 0.7 and d.x < r * 1.5 and absf(d.y) < (d.x - r * 0.7) * 0.7

## What lies on the sand in each world: shells, a starfish, pebbles, glowing urchins in the deep
static func _sand_decor(kind: String, wx: float, wy: float, fy: float, col: Color, sand: Array) -> Color:
	var depth := wy - fy
	if depth < P * 3 or depth > 70.0:
		return col
	var spots: Array = []
	match kind:
		"lagoon", "reef":
			spots = [[Vector2(96, 18), "shell"], [Vector2(360, 26), "star"], [Vector2(600, 16), "pebble"], [Vector2(880, 22), "shell"]]
		"sun":
			spots = [[Vector2(120, 20), "shell"], [Vector2(830, 24), "pebble"]]
		"night":
			spots = [[Vector2(380, 22), "glow"], [Vector2(590, 18), "glow"]]
		"rain":
			spots = [[Vector2(150, 18), "pebble"], [Vector2(870, 22), "pebble"]]
		"deep":
			spots = [[Vector2(110, 22), "urchin"], [Vector2(475, 30), "glow"], [Vector2(860, 20), "urchin"]]
	for sp in spots:
		var at: Vector2 = sp[0]
		var d := Vector2(wx - at.x, depth - at.y)
		match sp[1]:
			"shell":                                     # a fan shell: ribs, pink
				if d.y < 0.0 and d.length() < 13.0:
					return OUTLINE if d.length() > 11.0 else (Color8(240, 170, 160) if int(atan2(d.y, d.x) * 6.0) % 2 == 0 else Color8(250, 206, 190))
			"star":                                      # a starfish: five arms
				var ang := atan2(d.y, d.x)
				var arm := 6.0 + 7.0 * pow(absf(cos(ang * 2.5)), 4.0)
				if d.length() < arm:
					return OUTLINE if d.length() > arm - 2.0 else Color8(240, 140, 90)
			"pebble":
				if (d.x / 12.0) * (d.x / 12.0) + (d.y / 7.0) * (d.y / 7.0) < 1.0:
					return OUTLINE if (d.x / 12.0) * (d.x / 12.0) + (d.y / 7.0) * (d.y / 7.0) > 0.7 else (sand[2] as Color).darkened(0.15)
			"glow":                                      # a glowing shell
				if d.length() < 9.0:
					return Color8(140, 250, 230) if d.length() < 6.0 else OUTLINE
			"urchin":                                    # a sea urchin, its spines lit at the tips
				var a2 := atan2(d.y, d.x)
				var spine := 5.0 + (4.0 if int((a2 + PI) * 8.0) % 2 == 0 else 0.0)
				if d.length() < spine:
					return Color8(255, 150, 230) if d.length() > spine - 1.5 else Color8(70, 40, 90)
	return col

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
static func net(path: String, colour: Color = NET) -> Texture2D:
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
			var col := Color(colour, 0.3) if a < 0.8 else colour
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

## A soft glow (night): w x h art px, brightest in the middle, fading out; drawn added on
## (CanvasItemMaterial BLEND_MODE_ADD) behind a ball or a basket rim
static func glow(w: int, h: int, colour: Color) -> Texture2D:
	var img := Image.create(w, h, false, Image.FORMAT_RGBA8)
	var c := Vector2(w / 2.0, h / 2.0)
	for y in h:
		for x in w:
			var d := Vector2((x + 0.5 - c.x) / (w / 2.0), (y + 0.5 - c.y) / (h / 2.0)).length()
			if d < 1.0:
				var a := (1.0 - d) * (1.0 - d)
				img.set_pixel(x, y, Color(colour, a * 0.85))
	return ImageTexture.create_from_image(img)

## A bubble: a pale ring, see-through inside, a shine
static func bubble(n: int, tint: Color = Color(0.94, 0.98, 0.97)) -> Texture2D:
	var img := Image.create(n, n, false, Image.FORMAT_RGBA8)
	var c := Vector2(n / 2.0, n / 2.0)
	var r := n / 2.0
	for y in n:
		for x in n:
			var d := Vector2(x + 0.5, y + 0.5).distance_to(c)
			if d > r:
				continue
			img.set_pixel(x, y, Color(tint, 0.9) if d > r - 1.2 else Color(tint, 0.18))
	img.set_pixel(int(n * 0.3), int(n * 0.3), Color.WHITE)
	return ImageTexture.create_from_image(img)

## The pal as a diver: its own sprite shrunk to about `width` art px (not a ball), with a
## diving mask (one wide rounded lens over both eyes, a strap round the sides) and a snorkel up
## the left side. The eyes are found on the small sprite (its dark pixels inside the outline).
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
	# the eyes, found on the full-size sprite, then in the small one's pixels
	var eyes := _find_eyes(src, used)
	var ey := h / 2
	var ex0 := w / 2 - 4
	var ex1 := w / 2 + 3
	if eyes.size() > 0:
		ey = clampi(roundi((eyes[0] - used.position.y) / k), 4, h - 4)
		ex0 = int((eyes[1] - used.position.x) / k)
		ex1 = int((eyes[2] - used.position.x) / k)
	# the lens: centred on the eyes, a sensible width
	var ec := (ex0 + ex1) / 2.0
	var half := clampf((ex1 - ex0) / 2.0 + 3.0, 6.5, 8.5)
	ex0 = int(ec - half) + 3
	ex1 = int(ec + half) - 3
	# the mask (like a real snorkel set, minus the nose bit): one wide rounded lens in a blue
	# frame, a blue strap round the head, a blue snorkel up the left side with a J at the bottom
	var blue := Color8(66, 114, 190)
	var blue_light := Color8(126, 168, 226)
	var blue_dark := Color8(44, 72, 132)
	var glass := Color8(196, 230, 238)
	for x in w:
		if body.get_pixel(x, ey).a > 0.0:
			img.set_pixel(x + ox, ey + oy, blue_dark)            # the strap
	var l0 := maxi(ex0 - 3, 0)
	var l1 := mini(ex1 + 3, w - 1)
	const INSET := [2, 1, 0, 0, 0, 0, 1, 3]                     # its rounded outline, row by row
	var top := ey - 4
	var shape := {}
	for r in INSET.size():
		for x in range(l0 + INSET[r], l1 - INSET[r] + 1):
			shape[Vector2i(x, top + r)] = true
	var rim := {}                                               # its outline: shape pixels at the edge
	for q: Vector2i in shape:
		for dd in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
			if not shape.has(q + dd):
				rim[q] = true
	for q: Vector2i in shape:
		var col: Color
		if rim.has(q):
			col = OUTLINE
		else:
			var frame := false                                  # next to the outline: the blue frame
			for dd in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1), Vector2i(1, 1), Vector2i(-1, -1), Vector2i(1, -1), Vector2i(-1, 1)]:
				if rim.has(q + dd):
					frame = true
			if frame:
				col = blue_light if q.y <= top + 1 else blue
			else:
				# the glass: see-through, the pal's eyes behind it
				var under := body.get_pixel(q.x, q.y) if q.x >= 0 and q.y >= 0 and q.x < w and q.y < h else Color(0, 0, 0, 0)
				col = glass if under.a <= 0.0 else Color(under.r, under.g, under.b).lerp(glass, 0.45)
		img.set_pixel(q.x + ox, q.y + oy, col)
	# a glint on the glass, top left
	for g in [Vector2i(l0 + 3, top + 2), Vector2i(l0 + 4, top + 2), Vector2i(l0 + 3, top + 3)]:
		if shape.has(g):
			img.set_pixel(g.x + ox, g.y + oy, Color.WHITE)
	# the snorkel: up the body's left side, its top a little above the head...
	var side := 0
	while side < w - 1 and body.get_pixel(side, ey).a <= 0.0:
		side += 1
	var sx := maxi(side + ox - 1, 1)
	var head := 0
	while head < h and body.get_pixel(mini(side + 3, w - 1), head).a <= 0.0:
		head += 1
	var tube_top := maxi(head + oy - 4, 0)
	var tube_end := ey + oy + 4
	sx = maxi(sx - 1, 1)
	for y in range(tube_top, tube_end + 1):
		img.set_pixel(sx - 1, y, OUTLINE)
		img.set_pixel(sx, y, blue_light)
		img.set_pixel(sx + 1, y, blue)
		img.set_pixel(sx + 2, y, OUTLINE)
	for x in range(sx - 1, sx + 3):
		img.set_pixel(x, tube_top, OUTLINE)
	# ...and its J: the clear mouthpiece curling in under the mask
	var clear := Color8(214, 226, 230)
	var mouth_x := l0 + ox + 3
	for x in range(sx, mouth_x + 1):
		img.set_pixel(x, tube_end, clear if x > sx + 1 else blue)
		img.set_pixel(x, tube_end + 1, OUTLINE)
	img.set_pixel(mouth_x + 1, tube_end, OUTLINE)
	img.set_pixel(mouth_x + 1, tube_end - 1, OUTLINE)
	img.set_pixel(mouth_x, tube_end - 1, clear)
	return ImageTexture.create_from_image(img)

# the pufferfish: pale mustard with brown spots and a cream belly
const PUFF := Color8(232, 200, 110)
const PUFF_BELLY := Color8(250, 238, 204)
const PUFF_SPOT := Color8(184, 136, 66)

## The pufferfish, facing left (flip it to face right): hand-drawn, chunkier than the rest (the
## game shows it at twice the scale). Calm: an oval fish with a tail and a few spines on its back;
## puffed up (scared): a round ball with spines all round and its mouth in an "o".
##   o outline · y body · s spot · b belly · k pupil · w eye white · m mouth
const PUFFER_CALM := [
	"...o.o.o.......",
	"..ooooooooo....",
	".oyysyyyysyo.oo",
	"okwyyyyyyyyyoyo",
	"oyyyysyyyyyyyyo",
	"myyyyyyyyyyyoyo",
	"obbbbbbbbbbo.oo",
	".obbbbbbbbo....",
	"..oooooooo.....",
]
const PUFFER_PUFFED := [
	"o......o......o",
	".o.....o.....o.",
	".....ooooo.....",
	"...ooyyysyoo...",
	"..oyysyyyyyyo..",
	"..okwyyyysyyo..",
	".oyyyyyyyyyyyo.",
	"oomyyysyyyyyyoo",
	".oyyyyyyyyysyo.",
	"..obbbbbbbbbo..",
	"..obbbbbbbbbo..",
	"...oobbbbboo...",
	".....ooooo.....",
	".o.....o.....o.",
	"o......o......o",
]

static func puffer(puffed: bool) -> Texture2D:
	var cols := { "o": OUTLINE, "y": PUFF, "s": PUFF_SPOT, "b": PUFF_BELLY, "k": OUTLINE,
		"w": Color.WHITE, "m": CORAL_DARK }
	var rows: Array = PUFFER_PUFFED if puffed else PUFFER_CALM
	var img := Image.create(rows[0].length(), rows.size(), false, Image.FORMAT_RGBA8)
	for y in rows.size():
		for x in rows[y].length():
			var ch: String = rows[y][x]
			if cols.has(ch):
				img.set_pixel(x, y, cols[ch])
	return ImageTexture.create_from_image(img)

## Where a pal's eyes are on its sprite: [row, left x, right x] (sprite pixels), or [] if not
## found. The eyes = rows (in the middle band of the pal) with a small near-black blob left of the
## middle AND one right of it, and nothing dark in the middle of that row (so not the mouth, not a
## line across the body); the darkest run of such rows, its middle. No eyes like that: a robot's
## visor (one dark bar across the middle).
static func _find_eyes(src: Image, used: Rect2i) -> Array:
	var cx := used.position.x + used.size.x / 2.0
	var gap := used.size.x * 0.06                    # the middle strip that must stay clear
	var reach := used.size.x * 0.4                   # how far out an eye can be
	var m := maxi(5, int(used.size.x * 0.1))         # this far in from the pal's edge (past its outline)
	# dark = well under the body's own brightness (some pals have dark green eyes, not black)
	var lums := []
	for y in range(used.position.y, used.end.y, 2):
		for x in range(used.position.x, used.end.x, 2):
			var q := src.get_pixel(x, y)
			if q.a > 0.5:
				lums.append(q.get_luminance())
	lums.sort()
	var dark := minf(0.32, lums[lums.size() / 2] * 0.55) if lums.size() > 0 else 0.2
	var rows := []                                   # [y, min x, max x] of each eye row
	var visor := []                                  # (robots: rows with one dark bar across the middle)
	# (only the middle band of the pal: leaves, hats and toppings sit above it)
	for y in range(used.position.y + int(used.size.y * 0.28), used.position.y + int(used.size.y * 0.8)):
		var mid := false
		var lx := []                             # the dark pixels' x, left and right of the middle
		var rx := []
		var lum_sum := 0.0
		for x in range(used.position.x + 2, used.end.x - 2):
			var px := src.get_pixel(x, y)
			if px.a < 0.5 or px.get_luminance() > dark or px.s > 0.65:
				continue
			# (not the sprite's own outline: well inside its shape)
			if x - m < 0 or x + m >= src.get_width() or src.get_pixel(x - m, y).a < 0.5 or src.get_pixel(x + m, y).a < 0.5 \
					or src.get_pixel(x, maxi(y - m, 0)).a < 0.5 or src.get_pixel(x, mini(y + m, src.get_height() - 1)).a < 0.5:
				continue
			var d := x - cx
			if absf(d) <= gap:
				mid = true
			elif d < 0 and d > -reach:
				lx.append(x)
				lum_sum += px.get_luminance()
			elif d > 0 and d < reach:
				rx.append(x)
				lum_sum += px.get_luminance()
		# an eye is a small blob: each side's dark bit no wider than a fifth of the pal
		var small := used.size.x * 0.2
		var ok: bool = not mid and lx.size() > 0 and rx.size() > 0 \
				and lx.max() - lx.min() < small and rx.max() - rx.min() < small
		rows.append([y, lx.min(), rx.max(), lum_sum / maxf(lx.size() + rx.size(), 1)] if ok else [])
		if mid and lx.size() > 0 and rx.size() > 0 and rx.max() - lx.min() < used.size.x * 0.6:
			visor.append([y, lx.min(), rx.max()])
	# the runs of eye rows; the eyes = the darkest run (leaves' shading, specks: lighter)
	var best := []
	var best_lum := 9.0
	var run := []
	for row in rows + [[]]:
		if row.is_empty():
			if run.size() >= 2:
				var lum := 0.0
				for rr in run:
					lum += rr[3]
				lum /= run.size()
				if lum < best_lum:
					best = run
					best_lum = lum
			run = []
		else:
			run.append(row)
	if visor.size() > best.size():
		best = visor                                 # (a visor beats a few specks in a robot's metal)
	if best.is_empty():
		return []
	var x_min := 99999
	var x_max := -1
	for row in best:
		x_min = mini(x_min, row[1])
		x_max = maxi(x_max, row[2])
	return [(best[0][0] + best[-1][0]) / 2.0, x_min, x_max]

## A coin (11 x 11): gold, outlined, an inner ring, a shine
static func coin() -> Texture2D:
	const N := 11
	var gold := Color8(240, 196, 84)
	var ring := Color8(204, 150, 52)
	var img := Image.create(N, N, false, Image.FORMAT_RGBA8)
	var c := Vector2(N / 2.0, N / 2.0)
	for y in N:
		for x in N:
			var d := Vector2(x + 0.5, y + 0.5).distance_to(c)
			if d > 5.5:
				continue
			var col := gold
			if d > 4.6:
				col = OUTLINE
			elif d > 2.6 and d < 3.6:
				col = ring
			img.set_pixel(x, y, col)
	img.set_pixel(3, 3, Color8(255, 246, 200))
	img.set_pixel(4, 2, Color8(255, 246, 200))
	return ImageTexture.create_from_image(img)

## The anglerfish (Deep Sea), facing left (flip it to face right): a dark round fish with a big
## jaw of white teeth, a pale belly, and its lure on a stalk over its head (the glowing bulb is
## drawn separately: angler_lure). o outline · d body · D its lit top · b belly · t tooth · w eye
## white · k pupil · f fin
const ANGLER := [
	"..........oooooo..........",
	".......oooddddddooo.......",
	".....ooDDDDDDdddddoo......",
	"....oDDDDDDDDdddddddo..oo.",
	"...owkdddddddddddddddoofo.",
	"..oddddddddddddddddddoffo.",
	".otototododdddddddddddffo.",
	"o..........obbdddddddooffo",
	"otototototobbbddddddo.ofo.",
	".oddddddddbbbbdddddo..oo..",
	"..oobbbbbbbbbdddddo.......",
	"....oooobbbbbddoo.........",
	"........oooooo............",
]

static func angler() -> Texture2D:
	var cols := { "o": OUTLINE, "d": Color8(92, 74, 110), "D": Color8(122, 102, 142), "b": Color8(160, 140, 168),
		"t": Color8(250, 248, 236), "w": Color.WHITE, "k": OUTLINE, "f": Color8(70, 56, 90) }
	var img := Image.create(ANGLER[0].length(), ANGLER.size(), false, Image.FORMAT_RGBA8)
	for y in ANGLER.size():
		for x in ANGLER[y].length():
			var ch: String = ANGLER[y][x]
			if cols.has(ch):
				img.set_pixel(x, y, cols[ch])
	return ImageTexture.create_from_image(img)

## The lure's stalk and glowing bulb (7 x 9), its bulb at the top left
static func angler_lure() -> Texture2D:
	var rows := [".LL....", "LYYL...", "LYYL...", ".LLs...", "...s...", "....s..", ".....s.", ".....s.", "......s"]
	var cols := { "L": Color8(150, 240, 255), "Y": Color8(255, 255, 220), "s": Color8(70, 56, 90) }
	var img := Image.create(7, 9, false, Image.FORMAT_RGBA8)
	for y in rows.size():
		for x in 7:
			var ch: String = rows[y][x]
			if cols.has(ch):
				img.set_pixel(x, y, cols[ch])
	return ImageTexture.create_from_image(img)

## The golden hoop (a secret: only fizzy jets throw a ball up through it), 22 x 22: a gold ring,
## lit at the top left, twinkling
static func golden_hoop() -> Texture2D:
	var img := Image.create(22, 22, false, Image.FORMAT_RGBA8)
	var c := Vector2(11, 11)
	for y in 22:
		for x in 22:
			var off := Vector2(x + 0.5, y + 0.5) - c
			var d := off.length()
			if d > 10.5 or d < 6.5:
				continue
			var col := Color8(246, 204, 70) if off.x + off.y < 0 else Color8(214, 150, 40)
			if d > 9.6 or d < 7.4:
				col = OUTLINE
			elif off.x + off.y < -9.0:
				col = Color8(255, 246, 190)
			img.set_pixel(x, y, col)
	return ImageTexture.create_from_image(img)

## A basket's icon for the HUD's tray (9 x 8): an empty net, or gold once it's filled
static func basket_icon(full: bool, rim: Color) -> Texture2D:
	var rows := ["#########", "#rrrrrrr#", "#########", ".#n.n.n#.", ".#.n.n.#.", "..#n.n#..", "..#.n.#..", "...###..."]
	var img := Image.create(9, 8, false, Image.FORMAT_RGBA8)
	for y in rows.size():
		for x in 9:
			var ch: String = rows[y][x]
			var col := Color(0, 0, 0, 0)
			if ch == "#":
				col = OUTLINE
			elif ch == "r":
				col = rim
			elif ch == "n":
				col = Color8(250, 214, 90) if full else Color8(244, 236, 214)
			elif ch == "." and full and y >= 3 and x > 1 and x < 7 and rows[y].substr(0, x).count("#") == 1:
				col = Color8(240, 190, 60)                     # (filled: gold inside the net)
			if col.a > 0.0:
				img.set_pixel(x, y, col)
	return ImageTexture.create_from_image(img)
