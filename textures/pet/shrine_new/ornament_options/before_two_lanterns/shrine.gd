extends Node2D
class_name Shrine
## The shrine around the pal (yokai migration, docs/yokai_migration.md; for now only in the dev
## launcher's SHRINE start): it takes the gut's place in PetView (the gut, its decor and the cam
## window hidden) and is a little box in 3D with the phone's tilt (the same axis as the games and
## the pet screen's wallpaper, TiltParallax): its front face (roof, pillars, pedestal) comes
## towards you, its inside sits deeper behind the pal, the pal stays in the middle. Tilt right:
## the right inner wall shows inside, the left outer wall outside (the box's sides: copies of the
## front's silhouette in side colours, stacked from its back to its front).
## Art: tools/art/shrine.py -> textures/pet/shrine/ (the gut's grid: 110 cells across 925 px).

var side_count := 20
var asset_dir := "res://textures/pet/shrine/"
const CELL := 925.0 / 110.0           # px per grid cell in the pictures
## Px per full tilt, against PetView (which itself comes 14 px towards you: TiltParallax.FRONT)
const FRONT := 20.0                   # the front face, towards you
const INSIDE := 44.0                  # the inside's back wall, away
const BACK := 56.0                    # the box's back (its outer sides end there)
## The pedestal's top slab, a little wider than the wood and reaching out in front of it: a box from
## the shrine's back to SLAB px in front (further than the wooden front), its stacked copies behind
## the wood for the part under the shrine and in front of it for the part that sticks out (its top,
## seen from above)
const SLAB := 46.0
const SLAB_BACK := 80.0                # its back: further back than the shrine's (the shrine stands on it)
const SLAB_BACK_COPIES := 40
const SLAB_FRONT_COPIES := 20
const SIDES := 20                     # copies of the silhouette between the back and the front
## The offering stand (sanbo) on the slab's top, in front of the wood: two boxes, the base and the
## tray (a little wider, on top), their depths (px per full tilt) between the wood's front and the
## slab's; offerings land on the tray (OFFER_AT, grid: the middle of its top)
const TRAY_F := 44.0
const TRAY_B := 22.0
const BASE_F := 41.0
const BASE_B := 25.0
const SANBO_COPIES := 18
## Ornaments on the slab either side of the sanbo (tried, 2026-10-21; kept as possibles for the decor
## menu, not shown: the user): a small stone lantern, a potted sakaki (tools/art/shrine.py); add
## ["orn_stone", ORN_B, ORN_F, 1] / ["orn_plant", ...] to the 3D pieces to show them
const ORN_F := 39.0
const ORN_B := 27.0
const ORN_COPIES := 12
const OFFER_AT := Vector2(55.5, 76.0)
const OFFER_D := 33.0
const OFFER_W := 11.0                 # an offering's width on the tray (grid cells)
## The pal's window in the front (grid): where the inner walls start
const OPEN := Rect2(31, 33, 49, 44)
## Inner walls: [left/right, ceiling, floor], each [lit, shade]
const WALL := [Color8(236, 222, 204), Color8(204, 186, 170)]   # (the vermilion look: cream walls)
const CEIL := [Color8(86, 52, 62), Color8(72, 42, 52)]
const FLOOR := [Color8(214, 160, 128), Color8(184, 132, 106)]
const FLOOR_PLANKS := 0                # the inner floor's boards (0: plain)
const SEAM := Color8(66, 38, 50)            # (the shrine's outline: a dark plum, a little washed out)

var front: Sprite2D
var slab: Sprite2D
var slab_back: Array[Sprite2D] = []   # (copies under the shrine, behind its front)
var slab_front: Array[Sprite2D] = []  # (copies of the part that sticks out, in front of the wood)
var inside: Sprite2D
var sides: Array[Sprite2D] = []
var root_planes: Array[Dictionary] = []  # textures mapped onto vertical side-facing planes
var walls: Node2D
var _depth_of := {}                   # the front pieces placed by depth alone: sprite -> px per full tilt
var offering: Sprite2D                # what's on the tray (show_offering)
## The drink offering: the little cup on the tray (3D like the stand: copies of its body, its face,
## the drink in it) and the bottle that pours
var cup_parts := {}                   # sprite -> depth (placed on the tray by _place_cup)
var cup_liquid: Sprite2D
var tokkuri: Sprite2D
var stream: Node2D                    # the pour (pixel rows, _draw_stream)
var _stream_pts := PackedVector2Array()
var _stream_col := Color.WHITE
var window: Node2D                    # the inside and its walls, seen only through the front's window
## The bell rope (suzu-no-o): the bell on the front, its red and white beads a chain hanging from it
## (verlet), pulled by the real gravity (roll the phone: it swings to hang straight down), a breeze,
## the front's own movement and every tilt of the phone (it swings); ring() kicks it
const ROPE_AT := Vector2(14, 30)      # left eave hanger on the chosen front frame (grid)
const NEW_ROPE_AT := Vector2(22, 30)  # just outside the new shrine's left orange beam block
const ROPE_N := 7                     # beads (the user: modular, like the painted one; the last white one off)
const ROPE_SEG := 3.3                 # grid cells between them (they just overlap, as painted)
const NEW_ROPE_SEG := 4.4             # larger ribbon modules still overlap in the new frame
const NEW_ORNAMENT_SCALE := 1.3
const NEW_RIBBON_SCALE := 1.65
const NEW_ORNAMENT_PIXEL := 3         # source pixels per visible pixel-art block
const ROPE_KICK := 10.0               # how much a tilt of the phone swings it
const ROPE_G := 1600.0                # px/s2
var rope: Array[Sprite2D] = []
var bell: Sprite2D
## The paper lantern (chochin) on the right, the rope's mirror (the user): hung from one point
## under the beam, swinging round it (a pendulum, its picture turned) with the same pushes as the
## rope, as strongly; a candle inside, very faint: a warm glow, flickering, a little more at night
const LANTERN_AT := Vector2(96, 30)  # right eave hanger, mirrored across the spirit room (grid)
const NEW_LANTERN_AT := Vector2(88, 30) # just outside the right orange beam block
const LANTERN_PIVOT := Vector2(10, 3) # that point in its picture (grid cells from LANTERN_BOX's corner)
const LANTERN_L := 8.3                # the point to the lantern's middle (grid cells)
const NEW_LANTERN_L := LANTERN_L * NEW_ORNAMENT_SCALE
const LANTERN_GLOW := Color(1.0, 0.76, 0.44)
var lantern: Sprite2D
var lantern_glow: Sprite2D
var _glow_scale := Vector2.ONE
var _lp := Vector2.ZERO
var _lq := Vector2.ZERO
var _night := 0.0                     # (0 day .. 1 night: the lantern's glow shows more)
## The Lucky Pinch claw comes down through a hatch in the inner ceiling (LuckyPinch._play_visit,
## claw_window): a small dark square, seen only when the tilt shows the ceiling, open while it visits
const HATCH_W := 9.0                  # grid cells
var hatch_open := false
var _prev_tilt := Vector2.ZERO
## The sky behind it, with the real time: the sun on its arc round the shrine by day, the moon by
## night in its real phase, the sky and the clouds tinted at dawn, dusk and night
var sun: Sprite2D
var moon: Sprite2D
var moons: Array[Texture2D] = []
static var qa_hour := -1.0            # (tools/qa hour=H: a pretend time of day)
var _rp: Array[Vector2] = []
var _rq: Array[Vector2] = []
var _t := 0.0
var tilt := Vector2.ZERO              # the wallpaper's tilt, -1..1 (smoothed there)
var _gut_scale := Vector2.ONE
var _inside_center_offset := Vector2.ZERO

func _ready() -> void:
	var view := get_parent()
	var gut: Sprite2D = view.get_node("Intestine-front")
	position = gut.position
	_gut_scale = gut.scale
	asset_dir = "res://textures/pet/shrine_new/" if DevLaunch.new_shrine else "res://textures/pet/shrine/"
	_zoom(view)
	if DevLaunch.new_shrine:
		# Center the new frame's visible bounds in the pet window (its roots sit left and high in the art).
		position += Vector2(18.0, 40.0)
	_lift_clouds()
	_build_land()
	_build_rain()
	for n in ["Intestine-back", "Intestine-front", "PoopCam"]:
		var node := view.get_node_or_null(n) as CanvasItem
		if node:
			node.visible = false
	side_count = 80 if DevLaunch.new_shrine else SIDES
	var side_tex: Texture2D = load(asset_dir + "side.png")
	for j in side_count:
		var sp := _layer(load(asset_dir + "side_back.png") if j == 0 else side_tex, -3)
		if not DevLaunch.new_shrine:
			sp.modulate = Color(1, 1, 1).darkened(0.12 * (1.0 - float(j) / side_count))
		sides.append(sp)
	# (clipped to the window: tilted, the inside slides past the pillars and must not show over the
	# box's outer sides)
	window = Node2D.new()
	window.z_index = -2
	window.clip_children = CanvasItem.CLIP_CHILDREN_ONLY
	window.draw.connect(_draw_window)
	add_child(window)
	inside = _layer(load(asset_dir + "inside.png"), 0)
	inside.reparent(window, false)
	if DevLaunch.new_shrine:
		# Center the rear room's focal circle in the shrine opening (the artwork is right-heavy).
		_inside_center_offset = Vector2(-14.0 * _gut_scale.x, 0.0)
		inside.position = _inside_center_offset
	walls = Node2D.new()
	walls.draw.connect(_draw_walls)
	window.add_child(walls)
	var slab_side: Texture2D = load(asset_dir + "slab_side.png")
	for j in SLAB_BACK_COPIES:
		slab_back.append(_layer(slab_side, -3))
	# the boxes (the stand and the wood, the stone slab on the stand, the wood on the slab) as one 3D
	# scene: all their copies drawn back to front by depth, so the nearer piece covers the further
	# (the stone after the wood at the same depth: the slab is there)
	var by_depth := []
	for j in side_count:
		by_depth.append([lerpf(-BACK, FRONT, float(j) / side_count), 0, sides[j]])
	if DevLaunch.new_shrine:
		for spec in [["roots_middle.png", lerpf(-BACK, FRONT, 0.5), 0.62, 0.90, 0.55, 38.0], ["roots_rear.png", -BACK + 1.0, 0.65, 0.80, 0.48, 28.0]]:
			var tex: Texture2D = load(asset_dir + spec[0])
			var source_image := tex.get_image()
			for side_index in 2:
				var half := Rect2i(side_index * (tex.get_width() / 2), 0, tex.get_width() / 2, tex.get_height())
				var bounds := source_image.get_region(half).get_used_rect()
				bounds.position += half.position
				var atlas := AtlasTexture.new()
				atlas.atlas = tex
				atlas.region = Rect2(bounds)
				var plane := Polygon2D.new()
				plane.texture = atlas
				plane.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
				plane.z_index = -3
				plane.modulate = Color(spec[2], spec[2], spec[2], 1.0)
				plane.uv = PackedVector2Array([Vector2.ZERO, Vector2(1, 0), Vector2.ONE, Vector2(0, 1)])
				add_child(plane)
				var root_material := ShaderMaterial.new()
				root_material.shader = load("res://shaders/shrine_root_plane.gdshader")
				plane.material = root_material
				var x_edge := 32.0 if side_index == 0 else 78.0
				root_planes.append({"node": plane, "depth": float(spec[1]), "x": x_edge,
					"top": 38.0, "bottom": 96.8, "span": float(spec[5]),
					"side": side_index, "scale_y": float(spec[3])})
				by_depth.append([spec[1], -1, plane])
	var slab_back_depth := SLAB_BACK
	for j in SLAB_BACK_COPIES:
		by_depth.append([lerpf(-slab_back_depth, FRONT, float(j) / SLAB_BACK_COPIES), 1, slab_back[j]])
	by_depth.sort_custom(func(a, b): return a[0] < b[0] or (a[0] == b[0] and a[1] < b[1]))
	for e in by_depth:
		move_child(e[2], -1)
	front = _layer(load(asset_dir + "front.png"), 1)
	if DevLaunch.new_shrine:
		# Enlarge the foreground frame slightly around its own center; keep the room and spirit scale.
		front.scale *= 1.04
	for j in SLAB_FRONT_COPIES:
		slab_front.append(_layer(slab_side, 1))
	slab = _layer(load(asset_dir + "slab.png"), 1)
	# the front pieces, one 3D scene too: the wood's front, the slab's part out in front, the
	# offering stand (its base, then its tray: the tray's outline over the base's top), back to front
	# by depth (at the same depth: the wood, the base, the tray, the stone)
	var near := [[FRONT, 0, front], [SLAB, 3, slab]]
	for j in SLAB_FRONT_COPIES:
		near.append([lerpf(FRONT, SLAB, float(j) / SLAB_FRONT_COPIES), 3, slab_front[j]])
	for piece in [["sanbo_base", BASE_B, BASE_F, 1], ["sanbo_tray", TRAY_B, TRAY_F, 2]]:
		var st: Texture2D = load(asset_dir + piece[0] + "_side.png")
		for j in (SANBO_COPIES if piece[0].begins_with("sanbo") else ORN_COPIES):
			var dd := lerpf(piece[1], piece[2], float(j) / (SANBO_COPIES if piece[0].begins_with("sanbo") else ORN_COPIES))
			var sp := _layer(st, 1)
			_depth_of[sp] = dd
			near.append([dd, piece[3], sp])
		var face := _layer(load(asset_dir + piece[0] + ".png"), 1)
		_depth_of[face] = piece[2]
		near.append([piece[2], piece[3], face])
	# what's offered stands on the tray at its depth: seen from below, the tray's front hides its foot
	offering = _layer(null, 1)
	offering.visible = false
	near.append([OFFER_D, 2.5, offering])
	# the drink's cup, stood on the tray the same way (hidden but while a drink is offered), the
	# stream going in behind its front, the drink in its mouth
	var cs: Texture2D = load(asset_dir + "cup_side.png")
	for j in CUP_COPIES:
		var dd := lerpf(CUP_B, CUP_F, float(j) / CUP_COPIES)
		var sp := _prop_sprite(cs)
		cup_parts[sp] = dd
		near.append([dd, 2.6, sp])
	stream = Node2D.new()
	stream.z_index = 1
	stream.draw.connect(_draw_stream)
	stream.visible = false
	add_child(stream)
	near.append([CUP_F, 2.65, stream])
	var cf := _prop_sprite(load(asset_dir + "cup.png"))
	cup_parts[cf] = CUP_F
	near.append([CUP_F, 2.7, cf])
	cup_liquid = _prop_sprite(load(asset_dir + "cup_liquid.png"))
	cup_parts[cup_liquid] = CUP_F
	near.append([CUP_F, 2.8, cup_liquid])
	tokkuri = _prop_sprite(load(asset_dir + "tokkuri.png"), PROP_PX)
	tokkuri.z_index = 2
	tokkuri.scale = Vector2.ONE * TOKKURI_PX * CELL * _gut_scale.x
	near.sort_custom(func(a, b): return a[0] < b[0] or (a[0] == b[0] and a[1] < b[1]))
	for e in near:
		move_child(e[2], -1)

	for i in ROPE_N:
		var segment := _layer(_ornament_texture("bead_red.png" if i % 2 == 0 else "bead_white.png"), 2)
		if DevLaunch.new_shrine:
			segment.scale *= NEW_RIBBON_SCALE
			segment.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		rope.append(segment)
	bell = _layer(_ornament_texture("bell.png"), 2)
	if DevLaunch.new_shrine:
		bell.scale *= NEW_ORNAMENT_SCALE
		bell.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	lantern_glow = _lantern_glow()
	if DevLaunch.new_shrine:
		lantern_glow.scale *= NEW_ORNAMENT_SCALE
		_glow_scale = lantern_glow.scale
	lantern = _layer(_ornament_texture("lantern.png"), 2)
	if DevLaunch.new_shrine:
		lantern.scale *= NEW_ORNAMENT_SCALE
		lantern.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	lantern.centered = false
	lantern.offset = -LANTERN_PIVOT * Vector2(CELL, 8.4)              # (it turns round where it hangs)
	var lantern_at := NEW_LANTERN_AT if DevLaunch.new_shrine else LANTERN_AT
	var lantern_length := NEW_LANTERN_L if DevLaunch.new_shrine else LANTERN_L
	_lp = _g(lantern_at.x, lantern_at.y) + Vector2(0, lantern_length * 8.4 * _gut_scale.y)
	_lq = _lp
	# the sky: behind the clouds, in front of the sky picture (absolute z: the sky's own)
	sun = _layer(load(asset_dir + "sun.png"), -6)
	moon = _layer(load(asset_dir + "moon_0.png"), -6)
	for sp in [sun, moon]:
		sp.z_as_relative = false
	for i in 8:
		moons.append(load(asset_dir + "moon_%d.png" % i))
	sun.modulate.a = 0.7                               # (far away: a little see-through)
	moon.modulate.a = 0.8
	var rope_at := NEW_ROPE_AT if DevLaunch.new_shrine else ROPE_AT
	var a := _g(rope_at.x, rope_at.y)
	for i in ROPE_N:
		var p := a + Vector2(0, _seg() * (i + 1))
		_rp.append(p)
		_rq.append(p)

func _layer(tex: Texture2D, z: int) -> Sprite2D:
	var sp := Sprite2D.new()
	sp.texture = tex
	sp.scale = _gut_scale
	sp.z_index = z
	add_child(sp)
	return sp

func _ornament_texture(file_name: String) -> Texture2D:
	var source: Texture2D = load(asset_dir + file_name)
	if not DevLaunch.new_shrine:
		return source
	var image := source.get_image()
	var size := image.get_size()
	var block := 2 if file_name.begins_with("bead_") else NEW_ORNAMENT_PIXEL
	image.resize(maxi(1, roundi(float(size.x) / block)),
		maxi(1, roundi(float(size.y) / block)), Image.INTERPOLATE_NEAREST)
	image.resize(size.x, size.y, Image.INTERPOLATE_NEAREST)
	return ImageTexture.create_from_image(image)

func _platform_offset() -> Vector2:
	return Vector2(0, -4.0 * CELL * _gut_scale.y) if DevLaunch.new_shrine else Vector2.ZERO

func _process(delta: float) -> void:
	var tp := get_node_or_null("/root/PoopPal/Main UI/TiltParallax")
	var t: Vector2 = tp.get("_offset") if tp else Vector2.ZERO
	# every tilt of the phone swings the rope (the lower beads more)
	var dt_off := t - _prev_tilt
	_prev_tilt = t
	if _rp.size() == ROPE_N and dt_off.length() > 0.0005:
		for i in ROPE_N:
			_rq[i] += Vector2(dt_off.x, dt_off.y * 0.2) * ROPE_KICK * float(i + 1) / ROPE_N   # (mostly sideways)
		_lq += Vector2(dt_off.x, dt_off.y * 0.2) * ROPE_KICK * 0.45      # (it swings about as far as the rope)
	_rope_step(minf(delta, 1.0 / 30.0))
	_sky(t)
	_rain_step(delta)
	if stream.visible:
		_aim_stream()
	if t.is_equal_approx(tilt) and walls.get_meta("drawn", false):
		return
	tilt = t
	if land:
		(land.material as ShaderMaterial).set_shader_parameter("tilt", tilt)
	front.position = (tilt * FRONT).round()
	slab.position = (tilt * SLAB).round() + _platform_offset()
	for j in SLAB_BACK_COPIES:
		var slab_back_depth := SLAB_BACK
		slab_back[j].position = (-tilt * slab_back_depth).lerp(tilt * FRONT, float(j) / SLAB_BACK_COPIES).round() + _platform_offset()
	for j in SLAB_FRONT_COPIES:
		slab_front[j].position = (tilt * FRONT).lerp(tilt * SLAB, float(j) / SLAB_FRONT_COPIES).round() + _platform_offset()

	for sp in _depth_of:
		sp.position = (tilt * float(_depth_of[sp])).round() + _platform_offset()
	_place_offering()
	_place_cup()
	for plane_data in root_planes:
		var plane: Polygon2D = plane_data.node
		var z_center: float = plane_data.depth
		var span: float = plane_data.span
		var z0 := z_center - span * 0.5
		var z1 := z_center + span * 0.5
		var x: float = plane_data.x
		var top: float = plane_data.top
		var bottom: float = plane_data.bottom
		var p0 := _g(x, top) + tilt * z0
		var p1 := _g(x, top) + tilt * z1
		var p2 := _g(x, bottom) + tilt * z1
		var p3 := _g(x, bottom) + tilt * z0
		plane.polygon = PackedVector2Array([p0, p1, p2, p3])
	inside.position = _inside_center_offset + (-tilt * INSIDE).round()
	for j in side_count:
		sides[j].position = (-tilt * BACK).lerp(tilt * FRONT, float(j) / side_count).round()
	walls.set_meta("drawn", true)
	walls.queue_redraw()
	window.queue_redraw()

## Put an offering on the tray (null: take it away)
func show_offering(tex: Texture2D) -> void:
	offering.texture = tex
	offering.visible = tex != null
	_bites = 0
	_set_bites()
	_place_offering()

var _drop := 0.0                      # px the offering is still above the tray (falling)
var _squash := Vector2.ONE            # its landing squash (its foot stays on the tray)
var _bites := 0

func _place_offering() -> void:
	if not offering.texture:
		return
	var w := float(offering.texture.get_width())
	offering.scale = Vector2.ONE * OFFER_W * CELL * _gut_scale.x / w * _squash
	var h := float(offering.texture.get_height()) * offering.scale.y
	offering.position = (_g(OFFER_AT.x, OFFER_AT.y) + _platform_offset()) + Vector2(0, -h * 0.5 - _drop) + (tilt * OFFER_D).round()

# ------------------------------------------------------------------ FEEDING
## The meal in the shrine (the gut's falling chunks and digestion's place; main_button.gd): the
## whole food drops from above, in front of the roof, onto the sanbo's tray (a whoosh, a wooden
## tok, a bounce and a puff); the spirit notices it and eats it in three bites (a piece gone each
## time, crumbs, a munch); then it blinks exactly as in the gut (Intestine-back's timings), the
## shrine's inside glowing in time and a calm shimmer instead of the gut's hum. The new form (if
## any) comes after, from PetState, as before.
const DROP_FROM := 900.0              # px above the tray it starts (above the screen's top)
const DROP_TIME := 0.6
## The bites (uv on the food's picture): each a couple of round cuts; the last takes the rest
const BITES := [
	[Vector4(0.98, 0.36, 0.24, 1), Vector4(0.92, 0.66, 0.22, 1)],
	[Vector4(0.02, 0.40, 0.25, 1), Vector4(0.08, 0.68, 0.22, 1)],
]

func offer_food(tex: Texture2D) -> void:
	if FoodRainSpawner.is_locked:
		return
	FoodRainSpawner.is_locked = true
	var view := get_parent()
	var pal := view.get_node_or_null("Poop")
	var has_pal := PetState.has_poop()
	show_offering(tex)
	# the drop
	_sfx("res://sounds/fx/offer_whoosh.wav", -14.0)
	var fall := create_tween()
	fall.tween_method(func(v: float): _drop = v; _place_offering(), DROP_FROM, 0.0, DROP_TIME) \
			.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	await fall.finished
	_sfx("res://sounds/fx/offer_tok.wav", -10.0)
	ring(0.35)
	_puff()
	var bounce := create_tween()
	for sq in [Vector2(1.18, 0.78), Vector2(0.94, 1.08), Vector2.ONE]:
		bounce.tween_method(func(v: Vector2): _squash = v; _place_offering(), _squash, sq, 0.08)
	await bounce.finished
	# no spirit yet: the waiting wisp comes down, takes the offering in and swells (the first meal
	# gives it its shape: the hatch comes after the blinking, from PetState, as before)
	if not has_pal and pal and pal.has_method("wisp_go"):
		await get_tree().create_timer(0.3).timeout
		await _wisp_takes(pal)
		await _blink_like_gut(view, pal)
		FoodRainSpawner.is_locked = false
		return
	# the spirit notices it
	await get_tree().create_timer(0.3).timeout
	if has_pal and pal and pal.has_method("notice_food"):
		pal.notice_food()
	await get_tree().create_timer(0.55).timeout
	# three bites
	for i in 3:
		if has_pal and pal and pal.has_method("bite"):
			pal.bite()
		await get_tree().create_timer(0.12).timeout
		_sfx("res://sounds/fx/offer_munch.wav", -9.0, randf_range(0.92, 1.1))
		_crumbs(i)
		if i < 2:
			_bites = i + 1
			_set_bites()
		else:
			show_offering(null)
		await get_tree().create_timer(0.55).timeout
	# the blinking, as in the gut
	await _blink_like_gut(view, pal)
	FoodRainSpawner.is_locked = false

func _wisp_takes(pal: Node) -> void:
	var view := get_parent() as Node2D
	var food_at := offering.position + position         # (PetView's coordinates: the wisp lives there)
	var h := float(offering.texture.get_height()) * offering.scale.y
	await pal.wisp_go(food_at + Vector2(0, -h * 1.4), 0.7)
	_sfx("res://sounds/fx/spirit_inhale.wav", -9.0)
	if not _essence_tex:
		_essence_tex = _puff_texture()
	var to := food_at - position + Vector2(0, -h * 1.4)
	for i in 18:
		_wisp_curve(offering.position + Vector2(randf_range(-h * 0.4, h * 0.4), randf_range(-h * 0.3, h * 0.3)), to,
				Vector2(randf_range(-40, 40), -20), Vector2(randf_range(-30, 30), 10), Color8(226, 242, 255))
		await get_tree().create_timer(0.03).timeout
	var shrink := create_tween()
	shrink.tween_method(func(v: Vector2): _squash = v; _place_offering(), Vector2.ONE, Vector2(0.1, 0.1), 0.45).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
	await shrink.finished
	show_offering(null)
	_squash = Vector2.ONE
	await pal.wisp_swell()
	await pal.wisp_home()

## The send-off's end (main_button.gd): a ring of light where the spirit went out through the roof
func sendoff_ring() -> void:
	var r := Node2D.new()
	r.z_index = 3
	r.position = _g(55.5, 10.0) + front.position
	add_child(r)
	var rad := [6.0]
	var a := [1.0]
	r.draw.connect(func():
		var n := 24
		for i in n:
			var ang := TAU * i / n
			var p: Vector2 = Vector2(cos(ang), sin(ang) * 0.45) * float(rad[0])
			r.draw_rect(Rect2(p.round() - Vector2(3, 3), Vector2(6, 6)), Color(1, 0.98, 0.9, a[0])))
	var t := create_tween()
	t.tween_method(func(u: float):
		rad[0] = lerpf(6.0, 120.0, u)
		a[0] = 1.0 - u
		r.queue_redraw(), 0.0, 1.0, 0.7).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	t.tween_callback(r.queue_free)

func _set_bites() -> void:
	if not offering.material:
		var m := ShaderMaterial.new()
		m.shader = load("res://scripts/shaders/offering_bites.gdshader")
		offering.material = m
	var mat := offering.material as ShaderMaterial
	if offering.texture:
		mat.set_shader_parameter("px", Vector2(offering.texture.get_size()))
	var cuts: Array = []
	for i in mini(_bites, BITES.size()):
		cuts.append_array(BITES[i])
	for k in 4:
		mat.set_shader_parameter("b%d" % k, cuts[k] if k < cuts.size() else Vector4.ZERO)

## Bits of the food flying off a bite (pieces of its own picture), falling off the stand
func _crumbs(bite: int) -> void:
	var tex := offering.texture
	if not tex:
		return
	var sz := tex.get_size()
	var side := 1.0 if bite == 0 else (-1.0 if bite == 1 else 0.0)
	var from := offering.position + Vector2(side * offering.scale.x * sz.x * 0.35, -offering.scale.y * sz.y * 0.1)
	for k in 5:
		var c := Sprite2D.new()
		c.texture = tex
		c.region_enabled = true
		var cx := sz.x * (0.85 if side > 0 else (0.15 if side < 0 else randf_range(0.3, 0.7)))
		c.region_rect = Rect2(Vector2(clampf(cx + randf_range(-4, 4), 0, sz.x - 3), randf_range(sz.y * 0.3, sz.y * 0.6)).floor(), Vector2(3, 3))
		c.scale = offering.scale * randf_range(0.7, 1.0)
		c.z_index = 2
		add_child(c)
		var v := Vector2((side if side != 0.0 else randf_range(-1, 1)) * randf_range(60, 160), randf_range(-260, -120))
		var dur := randf_range(0.45, 0.65)
		var t := create_tween()
		t.tween_method(func(u: float): c.position = from + v * u + Vector2(0, 900.0) * u * u * 0.5, 0.0, dur, dur)
		t.parallel().tween_property(c, "modulate:a", 0.0, dur).set_delay(dur * 0.5)
		t.tween_callback(c.queue_free)

## A little dust where it lands, off both sides of the tray
func _puff() -> void:
	var img := Image.create(2, 2, false, Image.FORMAT_RGBA8)
	img.fill(Color(1, 0.98, 0.94, 0.9))
	var dot := ImageTexture.create_from_image(img)
	var at := (_g(OFFER_AT.x, OFFER_AT.y) + _platform_offset()) + (tilt * OFFER_D).round()
	for k in 8:
		var d := Sprite2D.new()
		d.texture = dot
		d.scale = Vector2.ONE * CELL * _gut_scale.x * randf_range(0.35, 0.6)
		d.z_index = 2
		var side := -1.0 if k % 2 == 0 else 1.0
		d.position = at + Vector2(side * randf_range(10, 40), randf_range(-6, 2))
		add_child(d)
		var t := create_tween()
		t.tween_property(d, "position", d.position + Vector2(side * randf_range(30, 70), randf_range(-26, -8)), 0.45) \
				.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		t.parallel().tween_property(d, "modulate:a", 0.0, 0.45)
		t.tween_callback(d.queue_free)

## The pal blinks just as it does after the gut's meal (Intestine-back's settings: its blinks' count,
## speed and delay, how long the gut blinked); the inside glows in time with the gut's blinks
func _blink_like_gut(view: Node, pal: Node, drink := false, tint := Color(1.28, 1.22, 1.1)) -> void:
	var gut := view.get_node_or_null("Intestine-back")
	var kind := "drink" if drink else "food"
	var loops: int = gut.get(kind + "_blink_loops") if gut else 10
	var dur: float = gut.get(kind + "_blink_duration") if gut else 0.5
	var shimmer := _sfx("res://sounds/fx/spirit_shimmer.wav", -12.0)
	var glow_col := tint if not drink else Color.WHITE.lerp(tint, 0.35) * 1.2
	var glow := create_tween()
	for i in loops:
		glow.tween_property(window, "modulate", glow_col, dur).set_trans(Tween.TRANS_SINE)
		glow.tween_property(window, "modulate", Color.WHITE, dur).set_trans(Tween.TRANS_SINE)
	await get_tree().create_timer(gut.get("poop_blink_delay_" + kind) if gut else 2.0).timeout
	if pal and pal.has_method("blink"):
		pal.blink(gut.get("poop_blink_times_" + kind) if gut else 60, gut.get("poop_blink_opacity_" + kind) if gut else 0.2,
				gut.get("poop_blink_speed_" + kind) if gut else 1.0)
	await glow.finished
	if is_instance_valid(shimmer):
		var fade := create_tween()
		fade.tween_property(shimmer, "volume_db", -60.0, 0.6)
		fade.tween_callback(shimmer.queue_free)

# ------------------------------------------------------------------ THE LAND
## The grassy ground the shrine stands on (the user: grass, the shrine on it; land.png), laid as a
## ground plane for the tilt (land.gdshader: all of it behind the shrine, moving like its back, the
## horizon further: seen from below the horizon drops and the base's sides show down to their lower
## edge, on the grass), behind the shrine's 3D sides, in front of the clouds; tinted with the
## sky's light. The shrine's shadow on it falls away from the sun (from the moon at night, faint),
## longer when it's low.
const SHADOW_AT := Vector2(55.5, 101.8)   # under the pedestal's middle (grid)
const SHADOW_D := -54.0                   # (its depth: the plane's, there)
const SHADOW_COL := Color8(70, 100, 62)
var land: Sprite2D
var shadow: Sprite2D

var _shadow_w := -1

const LAND_ON := false                    # (off for now, the user: floating keeps its magic; kept to try again)

func _build_land() -> void:
	var tex := load(asset_dir + "land.png") as Texture2D
	if not tex or not LAND_ON:
		return
	land = Sprite2D.new()
	land.texture = tex
	land.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	land.scale = _gut_scale
	land.z_index = -3
	var mat := ShaderMaterial.new()
	mat.shader = load("res://scripts/shaders/land.gdshader")
	mat.set_shader_parameter("size_px", tex.get_size() * _gut_scale)
	land.material = mat
	add_child(land)
	move_child(land, 0)                       # (before the shrine's sides: they stand on it)
	shadow = Sprite2D.new()
	shadow.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	shadow.z_index = -3
	add_child(shadow)
	move_child(shadow, 1)

## f: where the light is along the sky (0 rising on the left .. 1 setting on the right)
func _cast_shadow(h: float, rise: float, set_: float, moon_since: float, _ph: float) -> void:
	var f := 0.5
	var strength := 0.0
	if h >= rise and h < set_:
		f = (h - rise) / (set_ - rise)
		strength = 0.45
	elif moon_since < 12.4:
		f = moon_since / 12.4
		strength = 0.18
	var low := absf(f - 0.5) * 2.0                       # 0 at noon .. 1 at the horizon
	var w := int(roundf(68.0 + low * 30.0))               # (cells: longer when it's low)
	if w != _shadow_w:
		_shadow_w = w
		var img := Image.create(w, 5, false, Image.FORMAT_RGBA8)
		for y in 5:
			for x in w:
				var q := Vector2((x + 0.5) / w * 2.0 - 1.0, (y + 0.5) / 5.0 * 2.0 - 1.0)
				if q.length_squared() <= 1.0:
					img.set_pixel(x, y, Color(1, 1, 1, 1.0 if q.length_squared() < 0.55 else 0.6))
		shadow.texture = ImageTexture.create_from_image(img)
		shadow.scale = Vector2(CELL * _gut_scale.x, 8.4 * _gut_scale.y)
	shadow.visible = strength > 0.0
	shadow.modulate = Color(SHADOW_COL.r, SHADOW_COL.g, SHADOW_COL.b, strength) * Color(land.modulate.r, land.modulate.g, land.modulate.b, 1.0)
	var off := (0.5 - f) * 2.0 * 16.0                     # (away from the light, cells)
	shadow.position = (_g(SHADOW_AT.x + off, SHADOW_AT.y) + tilt * SHADOW_D).round()

# ------------------------------------------------------------------ THE RAIN
## When it rains where you are, it rains on the shrine (the user): thin pixel drops falling a little
## slanted in front of it, splashing where they hit the roof (a few droplets bouncing off), drips
## off the eaves' ends, the sky greyer, a soft rain sound; light or heavy as the real rain. Where
## you are comes from your time zone and region (_where, as for the sun), never GPS; asked only
## when live_weather is on (the player says yes first). rain_now forces it (the dev launcher, QA).
const RAIN_SKY := Color(0.8, 0.82, 0.9)
const RAIN_COL := Color(0.94, 0.97, 1.0, 0.75)
const RAIN_SPEED := 1150.0            # px/s
const RAIN_SLANT := 110.0             # px/s sideways
const RAIN_EVERY := 30.0 * 60.0       # how often the weather is asked (s)
static var rain_now := 1              # (0 off, 1 light, 2 heavy: forced, dev / QA; on for now, the user wants to see it)
static var live_weather := false      # (the real weather: only once the player has said yes)
var rain_level := 0                   # what's falling now (0..2)
var _rain_k := 0.0                    # (fades in and out)
var _drops: Array = []                # [pos, life]
var _splash: Array = []               # [pos, vel, life]
var _rain_acc := 0.0
var _drip_t := 0.0
var _rain_node: Node2D
var _rain_back: Node2D                # (the far layer: behind the shrine)
const RAIN_LAYERS := [[0.35, 0.62, 0.4, -40.0], [0.5, 1.0, 1.0, 0.0], [0.15, 1.15, 0.45, 30.0]]  # back, middle (hits the roof), near: [share, size/speed, alpha, depth px per tilt]
var _rain_sound: AudioStreamPlayer
var _weather_t := 0.0
var _weather_http: HTTPRequest

func _build_rain() -> void:
	_rain_node = Node2D.new()
	_rain_node.z_index = 3                # (in front of the shrine, the roof too)
	_rain_node.draw.connect(_draw_rain.bind(false))
	add_child(_rain_node)
	_rain_back = Node2D.new()
	_rain_back.z_index = -4               # (behind the shrine's sides, over the sky)
	_rain_back.draw.connect(_draw_rain.bind(true))
	add_child(_rain_back)
	var st := load("res://sounds/fx/rain_loop.wav") as AudioStreamWAV
	if st:
		st = st.duplicate()
		st.loop_mode = AudioStreamWAV.LOOP_FORWARD
		st.loop_begin = 0
		st.loop_end = int(st.get_length() * st.mix_rate)
		_rain_sound = AudioStreamPlayer.new()
		_rain_sound.stream = st
		_rain_sound.volume_db = -60.0
		add_child(_rain_sound)
	_weather_t = RAIN_EVERY - 2.0             # (ask soon after it opens)

## The roof's top in this node's coordinates at x, at a depth along it (k 0 its front .. 1 its back:
## in the tilt the roof runs back, and the drops land all along it, the user), from the slopes' top
## edges (tools/art/shrine.py: (15, 27) up to the peak (55.5, 6.75) and down to (96, 27)); NAN past
## its eaves
func _roof_y(x: float, k := 0.0) -> float:
	var off := (tilt * lerpf(FRONT, -BACK, k)).round()
	var gx := ((x - off.x) / _gut_scale.x + 462.5) / CELL
	if gx < 15.0 or gx > 96.0:
		return NAN
	var gy := 27.0 - (gx - 15.0) * 0.5 if gx <= 55.5 else 6.75 + (gx - 55.5) * 0.5
	return _g(0.0, gy).y + off.y

func _rain_step(delta: float) -> void:
	if not _rain_node:
		return
	_weather_step(delta)
	var want := rain_now if rain_now > 0 else rain_level
	_rain_k = move_toward(_rain_k, 1.0 if want > 0 else 0.0, delta / 2.0)
	if _rain_sound:
		var db := lerpf(-60.0, -26.0 if want >= 2 else -32.0, sqrt(_rain_k))   # (soft, in the background: the user)
		_rain_sound.volume_db = db
		if _rain_k > 0.0 and not _rain_sound.playing:
			_rain_sound.play()
		elif _rain_k <= 0.0 and _rain_sound.playing:
			_rain_sound.stop()
	var top := _g(0.0, -4.0).y
	var bottom := _g(0.0, 112.0).y
	var x0 := _g(-6.0, 0.0).x
	var x1 := _g(116.0, 0.0).x
	if want > 0:
		_rain_acc += delta * (55.0 if want == 1 else 170.0) * _rain_k
		while _rain_acc >= 1.0:
			_rain_acc -= 1.0
			var r := randf()
			var layer := 0 if r < RAIN_LAYERS[0][0] else (1 if r < RAIN_LAYERS[0][0] + RAIN_LAYERS[1][0] else 2)
			_drops.append([Vector2(randf_range(x0, x1), top - randf() * 60.0), randf_range(0.85, 1.15) * RAIN_LAYERS[layer][1], layer, randf()])
		_drip_t -= delta
		if _drip_t <= 0.0:                  # a drip off one of the eaves' ends
			_drip_t = randf_range(0.25, 0.7) / want
			var side := 15.3 if randf() < 0.5 else 95.7
			_drops.append([_g(side, 29.5) + front.position, 0.45, 1, 0.0])
	var keep: Array = []
	for d in _drops:
		var p: Vector2 = d[0]
		var sp: float = d[1]
		var np := p + Vector2(RAIN_SLANT * sp, RAIN_SPEED * sp) * delta
		var ry := _roof_y(np.x, d[3]) if int(d[2]) == 1 else NAN     # (only the middle layer meets the roof, somewhere along it)
		if not is_nan(ry) and p.y < ry and np.y >= ry and sp > 0.6:
			for k in randi_range(2, 3):         # it splashes on the roof
				_splash.append([Vector2(np.x, ry - 2.0), Vector2(randf_range(-150, 150), randf_range(-260, -120)), 0.28])
			continue
		if np.y < bottom:
			keep.append([np, sp, d[2], d[3]])
	_drops = keep
	var keep_s: Array = []
	for sp2 in _splash:
		sp2[1] += Vector2(0, 1400.0) * delta
		sp2[0] += sp2[1] * delta
		sp2[2] -= delta
		if sp2[2] > 0.0:
			keep_s.append(sp2)
	_splash = keep_s
	_rain_node.queue_redraw()
	_rain_back.queue_redraw()

func _draw_rain(back: bool) -> void:
	var node := _rain_back if back else _rain_node
	var px := maxf(3.0, roundf(0.5 * CELL * _gut_scale.x))         # (about half the shrine's pixel)
	for d in _drops:
		var layer := int(d[2])
		if (layer == 0) != back:
			continue
		var p: Vector2 = d[0] + tilt * float(RAIN_LAYERS[layer][3])   # (each layer at its depth in the tilt)
		var sp: float = d[1]
		var col := RAIN_COL
		col.a *= _rain_k * float(RAIN_LAYERS[layer][2])
		var w := px if layer > 0 else maxf(2.0, px * 0.6)
		var l := (30.0 if sp > 0.6 else 12.0) * _gut_scale.y * (0.6 if layer == 0 else (1.2 if layer == 2 else 1.0))
		node.draw_rect(Rect2(p.round(), Vector2(w, l).round()), col)
	if back:
		return
	for s2 in _splash:
		var c := RAIN_COL
		c.a *= _rain_k * clampf(s2[2] / 0.28, 0.0, 1.0) * 1.3
		node.draw_rect(Rect2((s2[0] as Vector2).round(), Vector2(px, px) * 1.4), c)

## Asks a free weather service (Open-Meteo, no key) whether it's raining where the phone probably is
## (its time zone and region's country: _where), every RAIN_EVERY seconds, only with live_weather on
func _weather_step(delta: float) -> void:
	if not live_weather:
		return
	_weather_t += delta
	if _weather_t < RAIN_EVERY:
		return
	_weather_t = 0.0
	if not _weather_http:
		_weather_http = HTTPRequest.new()
		_weather_http.timeout = 10.0
		add_child(_weather_http)
		_weather_http.request_completed.connect(_on_weather)
	var local_dict := Time.get_datetime_dict_from_system()
	var utc_dict := Time.get_datetime_dict_from_system(true)
	var tz := (Time.get_unix_time_from_datetime_dict(local_dict) - Time.get_unix_time_from_datetime_dict(utc_dict)) / 3600.0
	var place := _where(tz)
	_weather_http.request("https://api.open-meteo.com/v1/forecast?latitude=%.2f&longitude=%.2f&current=precipitation,weather_code" % [place.x, place.y])

func _on_weather(result: int, code: int, _headers: PackedStringArray, body: PackedByteArray) -> void:
	if result != HTTPRequest.RESULT_SUCCESS or code != 200:
		return                                # (no internet: it just doesn't rain)
	var data = JSON.parse_string(body.get_string_from_utf8())
	if typeof(data) != TYPE_DICTIONARY or not data.has("current"):
		return
	var cur: Dictionary = data["current"]
	var mm := float(cur.get("precipitation", 0.0))
	var wc := int(cur.get("weather_code", 0))
	var wet := wc in [51, 53, 55, 56, 57, 61, 63, 65, 66, 67, 80, 81, 82, 95, 96, 99] or mm > 0.05
	rain_level = 0 if not wet else (2 if mm >= 2.5 or wc in [65, 67, 82, 95, 96, 99] else 1)

# ------------------------------------------------------------------ DRINKS
## The drink in the shrine (the gut's waterfall's place; main_button.gd): the little cup appears on
## the tray, the drink itself (its own picture, the user; a white sake bottle if it has none) comes
## down from above (in front of the roof) and pours into it in its colour (a trickle), goes back up;
## the spirit draws it out as its essence, ribbons of it in its type's colour (the boost's: the
## aura it leaves, BoostAura) curling into it (an airy breath in), it glows that colour; then it
## blinks as after a drink in the gut (Intestine-back's drink timings), the inside glowing in the
## drink's colour, and the cup goes. PetState.drink comes after (the boost, its badge, its aura).
const CUP_F := 37.0                   # the cup's front and back (px per full tilt, on the tray)
const CUP_B := 29.0
const CUP_COPIES := 6
const PROP_PX := 0.36                 # the props' pixels, in grid cells (the foods' size)
const CUP_PX := 0.72                  # the cup's (chunkier, like the shrine: tools/art/shrine.py's CUP_PX)
const STREAM_W := 2                   # the pour's width, in the cup's pixels (and a darker edge each side)
const POUR_FROM := Vector2(-1.7, -6.5) # where its spout pours from, off the cup's mouth (grid)
const TOKKURI_PX := 0.45              # (the bottle a little bigger than the props' pixels: it reads)
const POUR_TILT := 1.95               # how far it tips (radians, towards the cup)
const POUR_TIME := 1.6

var _essence_tex: Texture2D

func _prop_sprite(tex: Texture2D, px := CUP_PX) -> Sprite2D:
	var sp := _layer(tex, 1)
	sp.scale = Vector2.ONE * px * CELL * _gut_scale.x
	sp.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	sp.visible = false
	return sp

func _place_cup() -> void:
	for sp in cup_parts:
		var h: float = sp.texture.get_height() * sp.scale.y
		sp.position = (_g(OFFER_AT.x, OFFER_AT.y) + _platform_offset()) + Vector2(0, -h * 0.5) + (tilt * float(cup_parts[sp])).round()

func _cup_mouth() -> Vector2:
	# (the drink's surface: the mouth's middle, a third of the way down the cup's picture)
	var h: float = cup_liquid.texture.get_height() * cup_liquid.scale.y
	return cup_liquid.position + Vector2(0, -h * 0.5 + h * 0.27)

func _spout() -> Vector2:
	var h: float = tokkuri.texture.get_height() * tokkuri.scale.y
	return tokkuri.position + Vector2(0, -h * 0.5 + 2.0).rotated(tokkuri.rotation)

func _aim_stream() -> void:
	var a := _spout()
	var b := _cup_mouth()
	var mid := (a + b) * 0.5 + Vector2(-6.0, 0)
	_stream_pts = PackedVector2Array([a, a.lerp(mid, 0.6), mid.lerp(b, 0.5), b])
	stream.queue_redraw()

## The pour as pixel art on the cup's pixels (the user: the thin line was off the look): a row of
## pixels per pixel of height down the curve, snapped to the cup's grid, in the drink's colour with
## a darker edge each side and a light streak, so every drink's colour reads, even on the white cup
func _draw_stream() -> void:
	if _stream_pts.size() < 2:
		return
	var px := CUP_PX * CELL * _gut_scale.x
	var b := _stream_pts[_stream_pts.size() - 1]
	var top := _stream_pts[0].y
	var edge := _stream_col.darkened(0.4)
	var lite := _stream_col.lerp(Color.WHITE, 0.45)
	var w := float(STREAM_W)
	var y := b.y - px * 0.6                       # (from the drink's surface up to the spout)
	while y > top - px:
		var x := _stream_x(y)
		var gx := b.x + roundf((x - b.x) / px - w * 0.5) * px
		var gy := b.y + roundf((y - b.y) / px) * px
		stream.draw_rect(Rect2(gx - px, gy, (w + 2.0) * px, px), edge)
		stream.draw_rect(Rect2(gx, gy, w * px, px), _stream_col)
		stream.draw_rect(Rect2(gx, gy, px, px), lite)
		y -= px

func _stream_x(y: float) -> float:
	for i in _stream_pts.size() - 1:
		var p := _stream_pts[i]
		var q := _stream_pts[i + 1]
		if (y - p.y) * (y - q.y) <= 0.0 and absf(q.y - p.y) > 0.01:
			return lerpf(p.x, q.x, (y - p.y) / (q.y - p.y))
	return _stream_pts[0].x if absf(y - _stream_pts[0].y) < absf(y - _stream_pts[-1].y) else _stream_pts[-1].x

func _show_cup(on: bool) -> void:
	for sp in cup_parts:
		sp.visible = on
	_place_cup()

func offer_drink(color: Color, drink_data := {}) -> void:
	if DrinkWaterfallSpawner.is_locked:
		return
	DrinkWaterfallSpawner.is_locked = true
	var view := get_parent()
	# The pet badge is not part of the shrine presentation; hide it before the pour begins as well as
	# when the new boost state arrives at the end of the animation.
	var badge := view.get_node_or_null("BoostBadge") as CanvasItem
	if badge:
		badge.hide()
	var pal := view.get_node_or_null("Poop")
	var drink := Color(color.r, color.g, color.b, 1.0)
	var aura: Array = BoostAura.COLORS.get(str(drink_data.get("boost", "")), [drink, drink])
	var icon: Texture2D = drink_data.get("icon", null)
	if icon:
		tokkuri.texture = icon
		tokkuri.scale = Vector2.ONE * PROP_PX * CELL * _gut_scale.x
	else:
		tokkuri.texture = load(asset_dir + "tokkuri.png")
		tokkuri.scale = Vector2.ONE * TOKKURI_PX * CELL * _gut_scale.x
	# the cup pops onto the tray
	_show_cup(true)
	cup_liquid.visible = false
	_sfx("res://sounds/fx/offer_tok.wav", -12.0, 1.25)
	for sp in cup_parts:
		var base: Vector2 = sp.scale
		sp.scale = base * 0.2
		create_tween().tween_property(sp, "scale", base, 0.3).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	await get_tree().create_timer(0.45).timeout
	# the bottle comes down
	# (where it hovers: its spout, tipped, just over the cup's mouth)
	var half: float = tokkuri.texture.get_height() * tokkuri.scale.y * 0.5
	var hover := _cup_mouth() + POUR_FROM * CELL * _gut_scale.x - Vector2(0, -half + 2.0).rotated(POUR_TILT)
	tokkuri.position = hover - Vector2(0, DROP_FROM)
	tokkuri.rotation = 0.0
	tokkuri.visible = true
	_sfx("res://sounds/fx/offer_whoosh.wav", -16.0, 1.15)
	var t := create_tween()
	t.tween_property(tokkuri, "position", hover, 0.7).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	await t.finished
	# it tips and pours
	t = create_tween()
	t.tween_property(tokkuri, "rotation", POUR_TILT, 0.35).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	await t.finished
	_stream_col = Color(drink.r, drink.g, drink.b, 1.0)
	stream.visible = true
	_aim_stream()
	_sfx("res://sounds/fx/offer_pour.wav", -10.0)
	cup_liquid.visible = true
	cup_liquid.modulate = Color(drink.r, drink.g, drink.b, 0.0)
	create_tween().tween_property(cup_liquid, "modulate:a", 1.0, POUR_TIME * 0.8)
	await get_tree().create_timer(POUR_TIME).timeout
	stream.visible = false
	t = create_tween()
	t.tween_property(tokkuri, "rotation", 0.0, 0.3).set_trans(Tween.TRANS_SINE)
	t.tween_property(tokkuri, "position", hover - Vector2(0, DROP_FROM), 0.6).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	t.tween_callback(func(): tokkuri.visible = false)
	await get_tree().create_timer(0.5).timeout
	# the spirit draws out its essence; once it's in, the aura comes on (no blinking: the user, the
	# essence going in already shows it), the empty cup fading away meanwhile
	await _draw_essence(aura[0], pal)
	var gone := create_tween()
	for sp in cup_parts:
		gone.parallel().tween_property(sp, "modulate:a", 0.0, 0.35)
	gone.tween_callback(func():
		_show_cup(false)
		for sp in cup_parts:
			sp.modulate.a = 1.0
		DrinkWaterfallSpawner.is_locked = false)     # (not before: a new cup would be hidden)

## Ribbons of the drink's essence out of the cup into the spirit (soft pixel puffs streaming out
## to its sides, then circling round its body, over it, closing in to sink into its middle; the cup
## emptying), the spirit glowing in its colour at the end. (The user: it went over its head and in
## at the top; it should go round it, over it.)
func _draw_essence(drink: Color, pal: Node) -> void:
	if not _essence_tex:
		_essence_tex = _puff_texture()
	var from := _cup_mouth()
	var centre := from + Vector2(0, -16.0 * 8.4 * _gut_scale.y)
	var rad := Vector2.ONE * 7.0 * CELL * _gut_scale.x
	if pal and PetState.has_poop():
		var body: Rect2 = pal.get("_body_rect")
		var p2 := pal as Node2D
		centre = to_local(p2.to_global(body.get_center()))
		rad = (to_local(p2.to_global(body.end)) - centre).abs()
	_sfx("res://sounds/fx/spirit_inhale.wav", -9.0)
	var bright := drink.lerp(Color.WHITE, 0.25)
	# three ribbons: up the left and round over the top, up the right and round, and one low round
	# the front (where on the body's ring each joins it, which way it turns)
	var ribbons := [[PI, 1.0], [0.0, -1.0], [PI * 0.8, -1.0]]
	var n := 60
	for i in n:
		var rb: Array = ribbons[i % ribbons.size()]
		_wisp(from + Vector2(randf_range(-8, 8), 0), centre, rad * randf_range(1.15, 1.4),
				float(rb[0]) + randf_range(-0.2, 0.2), float(rb[1]), bright)
		if i == n / 2:
			create_tween().tween_property(cup_liquid, "modulate:a", 0.0, 0.9)
		await get_tree().create_timer(0.03).timeout
	await get_tree().create_timer(1.4).timeout
	if pal and PetState.has_poop() and pal.has_method("absorb_essence"):
		pal.absorb_essence(bright)
	await get_tree().create_timer(0.3).timeout

## One puff of essence: out of the cup and up to the body's ring at `ang` (a curve swinging out
## sideways first), then round the body over it (`dir` the way it turns), closing in to its middle
func _wisp(a: Vector2, centre: Vector2, rad: Vector2, ang: float, dir: float, col: Color) -> void:
	var w := Sprite2D.new()
	w.texture = _essence_tex
	w.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	var s0 := PROP_PX * CELL * _gut_scale.x * randf_range(1.3, 2.0)
	w.scale = Vector2.ONE * s0
	w.modulate = Color(col.r, col.g, col.b, 0.0)
	w.z_index = 3                       # (over the spirit)
	add_child(w)
	var join := centre + Vector2(cos(ang), sin(ang)) * rad
	var ctrl := Vector2(join.x + (join.x - centre.x) * 0.35, a.y)
	var phase := randf() * TAU
	var turn := randf_range(1.0, 1.3) * TAU
	var dur := randf_range(1.5, 1.8)
	const UP := 0.35                    # (the share of the time spent getting to the ring)
	var t := create_tween()
	t.tween_method(func(u: float):
		var p: Vector2
		if u < UP:
			var k := u / UP
			p = a.lerp(ctrl, k).lerp(ctrl.lerp(join, k), k)
			p += (join - a).orthogonal().normalized() * sin(k * 7.0 + phase) * 4.0 * (1.0 - k)
		else:
			var k := (u - UP) / (1.0 - UP)
			var an := ang + dir * turn * (1.0 - pow(1.0 - k, 1.6))
			p = centre + Vector2(cos(an), sin(an)) * rad * pow(1.0 - k, 0.9)
		w.position = p
		w.scale = Vector2.ONE * s0 * lerpf(1.0, 0.35, u * u)
		w.modulate.a = clampf(u * 8.0, 0, 1) * clampf((1.0 - u) * 5.0, 0, 1), 0.0, 1.0, dur)
	t.tween_callback(w.queue_free)

## A puff along a cubic curve from a to b (the empty shrine's wisp drawing in the first offering)
func _wisp_curve(a: Vector2, b: Vector2, c1: Vector2, c2: Vector2, col: Color) -> void:
	var w := Sprite2D.new()
	w.texture = _essence_tex
	w.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	var s0 := PROP_PX * CELL * _gut_scale.x * randf_range(1.3, 2.0)
	w.scale = Vector2.ONE * s0
	w.modulate = Color(col.r, col.g, col.b, 0.0)
	w.z_index = 2
	add_child(w)
	var p1 := a + c1                    # (a cubic curve: out from the cup, round, into the spirit)
	var p2 := b + c2
	var phase := randf() * TAU
	var dur := randf_range(1.0, 1.2)
	var t := create_tween()
	t.tween_method(func(u: float):
		var v := 1.0 - u
		var p := a * v * v * v + p1 * 3.0 * v * v * u + p2 * 3.0 * v * u * u + b * u * u * u
		var side := (b - a).orthogonal().normalized() * sin(u * 9.0 + phase) * 6.0 * (1.0 - u)
		w.position = p + side
		w.scale = Vector2.ONE * s0 * lerpf(1.0, 0.4, u * u)
		w.modulate.a = clampf(u * 6.0, 0, 1) * clampf((1.0 - u) * 4.0, 0, 1), 0.0, 1.0, dur)
	t.tween_callback(w.queue_free)

## A soft round puff of essence (white, tinted by the game): 7 px, three stepped levels
static func _puff_texture() -> Texture2D:
	var img := Image.create(7, 7, false, Image.FORMAT_RGBA8)
	for y in 7:
		for x in 7:
			var r := Vector2(x - 3, y - 3).length()
			var a := 1.0 if r < 1.6 else (0.6 if r < 2.6 else (0.25 if r < 3.3 else 0.0))
			img.set_pixel(x, y, Color(1, 1, 1, a))
	return ImageTexture.create_from_image(img)

func _sfx(path: String, db: float, pitch := 1.0) -> AudioStreamPlayer:
	var stream := load(path) as AudioStream
	if not stream:
		return null
	var p := AudioStreamPlayer.new()
	p.stream = stream
	p.volume_db = db
	p.pitch_scale = pitch
	add_child(p)
	p.play()
	p.finished.connect(p.queue_free)
	return p

func _seg() -> float:
	return (NEW_ROPE_SEG if DevLaunch.new_shrine else ROPE_SEG) * 8.4 * _gut_scale.y

## Kick the rope (an offering, a poke): it swings and the bell shakes
func ring(strength := 1.0) -> void:
	for i in range(1, ROPE_N):
		_rq[i] -= Vector2(14.0 * strength * float(i) / ROPE_N, 0)
	_lq -= Vector2(4.0 * strength, 0)                  # (the lantern sways too: short, so a smaller push)

## Where the claw visits (PetView coordinates): the shrine's opening, under the beam, the pal inside
func claw_window() -> Rect2:
	var a := _g(OPEN.position.x, OPEN.position.y) + front.position + position
	var b := _g(OPEN.end.x, OPEN.end.y) + front.position + position
	return Rect2(a, b - a)

func set_hatch(open: bool) -> void:
	hatch_open = open
	walls.queue_redraw()

func _rope_step(dt: float) -> void:
	_t += dt
	var rope_at := NEW_ROPE_AT if DevLaunch.new_shrine else ROPE_AT
	var anchor := _g(rope_at.x, rope_at.y) + front.position
	# Gravity follows the same two-axis phone tilt as the shrine's depth. Keep a strong screen-down
	# component so the ornaments still hang naturally when the phone is held upright.
	var down := Vector2(clampf(tilt.x * 0.75, -0.75, 0.75), clampf(1.0 - tilt.y * 0.65, 0.3, 1.7)).normalized()
	var breeze := Vector2(sin(_t * 1.3) * 60.0 + sin(_t * 0.53) * 40.0, 0)
	for i in ROPE_N:
		var v := _rp[i] - _rq[i]
		_rq[i] = _rp[i]
		_rp[i] += v * 0.975 + (down * ROPE_G + breeze * float(i + 1) / ROPE_N) * dt * dt
	var seg := _seg()
	for it in 8:
		var prev := anchor
		for i in ROPE_N:
			var d := _rp[i] - prev
			var l := d.length()
			if l > 0.001:
				var fix := d * (1.0 - seg / l)
				if i == 0:
					_rp[i] -= fix
				else:
					_rp[i] -= fix * 0.5
					_rp[i - 1] += fix * 0.5
			prev = _rp[i]
	bell.position = anchor
	for i in ROPE_N:
		rope[i].position = _rp[i].round()
		if DevLaunch.new_shrine:
			var previous: Vector2 = anchor if i == 0 else _rp[i - 1]
			var following: Vector2 = _rp[i] if i == ROPE_N - 1 else _rp[i + 1]
			var direction := following - previous
			rope[i].rotation = -atan2(direction.x, direction.y)
	_lantern_step(dt, down, breeze)

func _lantern_step(dt: float, down: Vector2, breeze: Vector2) -> void:
	var lantern_at := NEW_LANTERN_AT if DevLaunch.new_shrine else LANTERN_AT
	var top := _g(lantern_at.x, lantern_at.y) + front.position
	var v := _lp - _lq
	_lq = _lp
	_lp += v * 0.975 + (down * ROPE_G + breeze) * dt * dt               # (as the rope's beads)
	var l := (NEW_LANTERN_L if DevLaunch.new_shrine else LANTERN_L) * 8.4 * _gut_scale.y
	var d := _lp - top
	if d.length() > 0.001:
		var a := clampf(atan2(d.x, d.y), -0.6, 0.6)                    # (no more than ~35 degrees)
		_lp = top + Vector2(sin(a), cos(a)) * l
	lantern.position = top.round()
	lantern.rotation = -atan2(_lp.x - top.x, _lp.y - top.y)
	lantern_glow.position = _lp.round()
	# a candle: a slow breathing pulse with a quicker flicker over it (the user: more noticeable)
	var pulse := 0.5 + 0.5 * sin(_t * 3.4)
	var f := 0.62 + 0.3 * pulse + 0.06 * sin(_t * 11.3 + 0.7) + 0.03 * sin(_t * 27.0)
	lantern_glow.modulate.a = f * lerpf(0.7, 1.0, _night)
	lantern_glow.scale = _glow_scale * (0.94 + 0.1 * pulse)
	var warm := 1.0 + 0.12 * f * lerpf(0.7, 1.0, _night)     # (the candle through the paper)
	lantern.modulate = Color(warm, warm * 0.97, 1.0)

## The candle's glow: a soft warm halo, stepped in the shrine's pixels, added on (very faint)
func _lantern_glow() -> Sprite2D:
	var sz := Vector2i(25, 27)
	var img := Image.create(sz.x, sz.y, false, Image.FORMAT_RGBA8)
	var c := Vector2(sz) * 0.5
	for y in sz.y:
		for x in sz.x:
			var r := ((Vector2(x + 0.5, y + 0.5) - c) / (Vector2(sz) * 0.5)).length()
			var a := 0.5 if r < 0.4 else (0.32 if r < 0.66 else (0.16 if r < 0.88 else (0.07 if r < 1.0 else 0.0)))
			img.set_pixel(x, y, Color(1, 1, 1, a))
	var sp := Sprite2D.new()
	sp.texture = ImageTexture.create_from_image(img)
	sp.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	sp.scale = Vector2(CELL * _gut_scale.x, 8.4 * _gut_scale.y)
	_glow_scale = sp.scale
	sp.self_modulate = LANTERN_GLOW
	var mat := CanvasItemMaterial.new()
	mat.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	sp.material = mat
	sp.z_index = 2
	add_child(sp)
	return sp


## The sky with the real time: the sun between today's sunrise and sunset where you are (estimated:
## your time zone, your phone's region, the date: _sun_times), the moon while it's up (its rise and
## set follow its phase: full at sunset, new at sunrise), each along a path that climbs the sky on
## the left, runs above the roof's slope (it meets the roof only round midday) and comes down on
## the right; held still on the screen (not in the 3D tilt); the sky and the clouds tinted (dawn
## and dusk warm, night blue)
const SKY_PATH := [Vector2(110, -760), Vector2(110, -1110), Vector2(320, -1228), Vector2(523, -1236),
		Vector2(726, -1228), Vector2(936, -1110), Vector2(936, -760)]
var _sun_cache := {}

func _sky(_t: Vector2) -> void:
	var tp := get_node_or_null("/root/PoopPal/Main UI/TiltParallax")
	var view_shift: Vector2 = tp.get("_view_applied") if tp else Vector2.ZERO
	var hold := -view_shift - position                 # (PetView moves in the tilt: undo it)
	var h := _local_hour()
	var st := _sun_times()
	var rise: float = st[0]
	var set_: float = st[1]
	sun.visible = h >= rise and h < set_
	if sun.visible:
		sun.position = _on_path((h - rise) / (set_ - rise)) + hold
	# the moon: up for ~12.4 h round its transit, which follows its phase (new: with the sun)
	var ph := _moon_phase_f()
	var transit := fposmod(st[2] + ph * 24.84, 24.0)
	var since := fposmod(h - (transit - 6.2), 24.0)
	moon.visible = since < 12.4
	if moon.visible:
		moon.position = _on_path(since / 12.4) + hold
		moon.texture = moons[int(roundf(ph * 8.0)) % 8]
		moon.modulate.a = 0.8 if not sun.visible else 0.45     # (a day moon: paler)
	# the sky's light
	var night := Color(0.58, 0.62, 0.86)
	var warm := Color(1.0, 0.86, 0.76)
	var tint := Color.WHITE
	if h < rise - 1.0 or h >= set_ + 1.0:
		tint = night
	elif h < rise:
		tint = night.lerp(warm, h - (rise - 1.0))
	elif h < rise + 1.5:
		tint = warm.lerp(Color.WHITE, (h - rise) / 1.5)
	elif h >= set_ - 1.5 and h < set_:
		tint = Color.WHITE.lerp(warm, (h - (set_ - 1.5)) / 1.5)
	elif h >= set_:
		tint = warm.lerp(night, h - set_)
	_night = clampf((1.0 - tint.r) / 0.42, 0.0, 1.0)
	tint = tint * Color.WHITE.lerp(RAIN_SKY, _rain_k)                  # (greyer while it rains)
	if land:
		land.modulate = tint
		_cast_shadow(h, rise, set_, since, ph)
	var bg := get_node_or_null("/root/PoopPal/Main UI/PetBackground")
	if bg:
		for n in ["PinkBackground", "CloudA", "CloudB"]:
			var l := bg.get_node_or_null(n) as CanvasItem
			if l:
				l.modulate = tint

## A point along SKY_PATH, f 0 (rise, low on the left) .. 1 (set, low on the right), by length
func _on_path(f: float) -> Vector2:
	var total := 0.0
	for i in SKY_PATH.size() - 1:
		total += (SKY_PATH[i + 1] as Vector2).distance_to(SKY_PATH[i])
	var want := clampf(f, 0.0, 1.0) * total
	for i in SKY_PATH.size() - 1:
		var a: Vector2 = SKY_PATH[i]
		var b: Vector2 = SKY_PATH[i + 1]
		var l := a.distance_to(b)
		if want <= l:
			return a.lerp(b, want / maxf(l, 0.001))
		want -= l
	return SKY_PATH[SKY_PATH.size() - 1]

func _local_hour() -> float:
	if qa_hour >= 0.0:
		return qa_hour
	var now := Time.get_datetime_dict_from_system()
	return now.hour + now.minute / 60.0 + now.second / 3600.0

## Today's sunrise, sunset and solar noon on the local clock (hours): where you are estimated from
## the phone's region (a country's middle; for the widest countries the longitude from the time
## zone) and the time zone's offset now (daylight saving included); the sun's declination and the
## equation of time from the day of the year. Cached per day.
func _sun_times() -> Array:
	var d := Time.get_date_dict_from_system()
	var key := "%d-%d-%d" % [d.year, d.month, d.day]
	if _sun_cache.get("key", "") == key:
		return _sun_cache["v"]
	var local_dict := Time.get_datetime_dict_from_system()
	var utc_dict := Time.get_datetime_dict_from_system(true)
	var tz := (Time.get_unix_time_from_datetime_dict(local_dict) - Time.get_unix_time_from_datetime_dict(utc_dict)) / 3600.0
	var place := _where(tz)
	var lat := deg_to_rad(place.x)
	var lon: float = place.y
	var n := fposmod(float(Time.get_unix_time_from_datetime_dict(local_dict) - Time.get_unix_time_from_datetime_dict({"year": d.year, "month": 1, "day": 1, "hour": 0, "minute": 0, "second": 0})) / 86400.0, 366.0)
	var decl := deg_to_rad(-23.44) * cos(TAU / 365.0 * (n + 10.0))
	var bb := TAU * (n - 81.0) / 364.0
	var eot := 9.87 * sin(2.0 * bb) - 7.53 * cos(bb) - 1.5 * sin(bb)             # minutes
	var noon := 12.0 - lon / 15.0 + tz - eot / 60.0
	var cos_h := (cos(deg_to_rad(90.833)) - sin(lat) * sin(decl)) / (cos(lat) * cos(decl))
	var half := rad_to_deg(acos(clampf(cos_h, -1.0, 1.0))) / 15.0
	var v := [noon - half, noon + half, noon]
	_sun_cache = {"key": key, "v": v}
	return v

## Where the phone probably is: [latitude, longitude] of its region's country (OS locale)
const PLACES := {
	"ES": [40.2, -3.7], "PT": [39.6, -8.0], "FR": [46.6, 2.4], "GB": [53.0, -1.8], "IE": [53.2, -8.0], "DE": [51.1, 10.4],
	"IT": [42.8, 12.6], "NL": [52.2, 5.5], "BE": [50.6, 4.6], "CH": [46.8, 8.2], "AT": [47.6, 14.1], "PL": [52.1, 19.4],
	"SE": [60.1, 15.6], "NO": [61.0, 9.0], "DK": [56.0, 10.0], "FI": [62.0, 26.0], "GR": [39.0, 22.0], "TR": [39.0, 35.0],
	"JP": [36.2, 138.3], "KR": [36.5, 127.9], "TW": [23.7, 121.0], "HK": [22.3, 114.2], "SG": [1.35, 103.8], "TH": [15.0, 101.0],
	"VN": [16.0, 107.0], "PH": [12.9, 121.8], "MY": [4.2, 102.0], "ID": [-2.5, 118.0], "IN": [22.0, 79.0], "CN": [35.0, 105.0],
	"AE": [24.3, 54.4], "SA": [24.0, 45.0], "IL": [31.5, 34.9], "EG": [26.8, 30.8], "MA": [31.8, -7.1], "ZA": [-29.0, 24.0],
	"MX": [23.6, -102.5], "BR": [-14.2, -51.9], "AR": [-34.6, -64.0], "CL": [-33.4, -70.6], "CO": [4.6, -74.1], "PE": [-9.2, -75.0],
	"US": [39.0, -98.0], "CA": [50.0, -96.0], "AU": [-27.0, 134.0], "NZ": [-41.0, 174.0], "RU": [56.0, 50.0],
}
const WIDE := ["US", "CA", "RU", "AU", "BR", "CN", "MX", "ID"]

func _where(tz: float) -> Vector2:
	var loc := OS.get_locale()
	var region := loc.get_slice("_", 1).left(2).to_upper() if "_" in loc else ""
	var p: Array = PLACES.get(region, [40.0, tz * 15.0])
	var lon: float = p[1]
	if region in WIDE or not PLACES.has(region):
		lon = (tz - (1.0 if _likely_dst() else 0.0)) * 15.0    # (the time zone says roughly where)
	return Vector2(p[0], lon)

## Northern summer time, roughly (April to October): the clock is an hour ahead of the sun
func _likely_dst() -> bool:
	var m: int = Time.get_date_dict_from_system().month
	return m >= 4 and m <= 10

## Today's moon phase, 0 new .. 0.5 full .. 1, from a known new moon (2000-01-06 18:14 UTC)
static func _moon_phase_f() -> float:
	var days := (Time.get_unix_time_from_system() - 947182440.0) / 86400.0
	return fposmod(days / 29.530588, 1.0)

## grid -> px (this node's space, around the pictures' middle)
## A little bigger than the gut it replaces (the user: the whole thing, the pixels as they are), with
## the spirit. Keep the original model scale; reduce the new frame and anchor its base so the roof
## comes down into the pet view, balancing the visible margins above and below.
const ZOOM := 1.06
const ZOOM_AT := 2.5
const NEW_ZOOM := 0.95
const NEW_ZOOM_AT := 55.0

func _zoom(view: Node) -> void:
	var zoom := NEW_ZOOM if DevLaunch.new_shrine else ZOOM
	var zoom_at := NEW_ZOOM_AT if DevLaunch.new_shrine else ZOOM_AT
	var fixed := position + _g(55.0, zoom_at)
	_gut_scale *= zoom
	position = fixed - _g(55.0, zoom_at)
	var pal := view.get_node_or_null("Poop") as Node2D
	if pal:
		pal.position = fixed + (pal.position - fixed) * zoom
		if DevLaunch.new_shrine:
			pal.position.y += 8.0
		pal.scale *= zoom
		pal.set("base_position", pal.position)
		pal.set("base_scale", pal.scale)
		var breath: Tween = pal.get("breathing_tween")
		if breath and breath.is_valid():
			pal.call("_start_breathing")              # (its breathing was made with the old size)

## The rolling clouds (PetBackground's CloudA / CloudB, their scroll shaders): the upper ones a bit
## lower, so they don't touch the screen's top, the lower ones a bit higher, off the floor (the user)
const CLOUDS_DOWN := 0.035            # (UV: of the clouds' picture, 925 px)
const CLOUDS_UP := 0.05               # (0.11 with the land, off its horizon)

func _lift_clouds() -> void:
	for n in ["CloudA", "CloudB"]:
		var c := get_node_or_null("/root/PoopPal/Main UI/PetBackground/" + n) as CanvasItem
		if c and c.material is ShaderMaterial:
			(c.material as ShaderMaterial).set_shader_parameter("top_down", CLOUDS_DOWN)
			(c.material as ShaderMaterial).set_shader_parameter("bottom_up", CLOUDS_UP)

func _g(gx: float, gy: float) -> Vector2:
	return Vector2((gx * CELL - 462.5) * _gut_scale.x, (gy * 8.4 - 462.0) * _gut_scale.y)

## The window in the front (a cell bigger all round: the pillars and the beam cover its edges)
func _draw_window() -> void:
	var a := _g(OPEN.position.x - 1.0, OPEN.position.y - 1.0) + front.position
	var b := _g(OPEN.end.x + 1.0, OPEN.end.y + 1.0) + front.position
	window.draw_rect(Rect2(a, b - a), Color.WHITE)

## The inner walls, between the window in the front and the same window on the inside's back wall:
## the side the inside slid away from shows (tilt right: the right wall), in strips a grid cell
## wide (the art's pixels), darker deeper in, a dark seam where they meet the back
func _draw_walls() -> void:
	var f0 := _g(OPEN.position.x, OPEN.position.y) + front.position
	var f1 := _g(OPEN.end.x, OPEN.end.y) + front.position
	var d := inside.position - front.position
	var b0 := f0 + d
	var b1 := f1 + d
	var cw := CELL * _gut_scale.x
	var ch := 8.4 * _gut_scale.y
	# left / right inner wall: from the window's edge to the back's edge
	var seams: Array[Rect2] = []           # (its strips: the column's edge lines go over the floor's)
	if absf(d.x) >= 1.0:
		var right := d.x < 0.0
		var xa := f1.x if right else f0.x
		var xb := b1.x if right else b0.x
		var n := maxi(1, int(ceilf(absf(xb - xa) / cw)))
		for k in n:
			var u0 := float(k) / n
			var u1 := float(k + 1) / n
			var x0 := lerpf(xa, xb, u0)
			var x1 := lerpf(xa, xb, u1)
			var y0 := lerpf(f0.y, b0.y, (u0 + u1) * 0.5)
			var y1 := lerpf(f1.y, b1.y, (u0 + u1) * 0.5)
			var col: Color = WALL[0] if right else WALL[1]
			col = col.darkened(0.25 * u0)
			if k == n - 1:
				col = SEAM
			walls.draw_rect(Rect2(Vector2(minf(x0, x1), y0), Vector2(absf(x1 - x0) + 0.5, y1 - y0)), col)
			seams.append(Rect2(Vector2(minf(x0, x1), y0), Vector2(absf(x1 - x0) + 0.5, y1 - y0)))
	# ceiling (tilt down) or floor (tilt up): from the window's top / bottom to the back's
	if absf(d.y) >= 1.0:
		var down := d.y > 0.0                  # the inside slid down: the ceiling shows
		var ya := f0.y if down else f1.y
		var yb := b0.y if down else b1.y
		var n := maxi(1, int(ceilf(absf(yb - ya) / ch)))
		for k in n:
			var u0 := float(k) / n
			var u1 := float(k + 1) / n
			var y0 := lerpf(ya, yb, u0)
			var y1 := lerpf(ya, yb, u1)
			var x0 := lerpf(f0.x, b0.x, (u0 + u1) * 0.5)
			var x1 := lerpf(f1.x, b1.x, (u0 + u1) * 0.5)
			var pal: Array = CEIL if down else FLOOR
			var col: Color = (pal[0] as Color).darkened(0.25 * u0)
			if k == n - 1:
				col = SEAM
			walls.draw_rect(Rect2(Vector2(x0, minf(y0, y1)), Vector2(x1 - x0, absf(y1 - y0) + 0.5)), col)
			if not down and k < n - 1 and FLOOR_PLANKS > 0:   # the boards' joints, running back
				for i in range(1, FLOOR_PLANKS):
					var jx := lerpf(x0, x1, float(i) / FLOOR_PLANKS)
					walls.draw_rect(Rect2(Vector2(jx - cw * 0.2, minf(y0, y1)), Vector2(cw * 0.4, absf(y1 - y0) + 0.5)),
							(pal[1] as Color).darkened(0.3 + 0.25 * u0))
			if down and k < n - 1:               # the claw's hatch in the middle of the ceiling
				var hw := HATCH_W * cw * 0.5
				var mid := (x0 + x1) * 0.5
				walls.draw_rect(Rect2(Vector2(mid - hw, minf(y0, y1)), Vector2(hw * 2.0, absf(y1 - y0) + 0.5)),
						Color8(18, 12, 14) if hatch_open else (pal[1] as Color).darkened(0.35 + 0.25 * u0))
	# the column's inner side meets the beam above and the floor below: an outline along both (the
	# user: the columns' ends outlined from every side, as on the front)
	var t := ch * 0.8
	for r in seams:
		walls.draw_rect(Rect2(r.position, Vector2(r.size.x, t)), SEAM)
		walls.draw_rect(Rect2(Vector2(r.position.x, r.end.y - t), Vector2(r.size.x, t)), SEAM)
