extends RefCounted
class_name PalPrix2Course
## Pal Prix 2's course: Pal Prix's circuits (a random patch of grid squares, the course round its
## outline, every corner rounded: it never touches itself), with bigger squares (long bends taken
## flat out, wide roads), cut into stretches of LAND, SEA and AIR with a transform gate where one
## turns into the next (always on a straight, with room before and after). It also makes the
## nearest-point fields the painting shaders read (scripts/shaders/pal_prix_2_*.gdshader): for a
## coarse grid over the mat, the nearest point of the course (all of it, and of each kind), so a
## shader finds its distance to the road, which stretch it's beside and how far along it is.

const PX := 4                          # mat px per board px
const STEP := 8.0                      # centre-line points, every STEP mat px
const LAND := 0
const SEA := 1
const AIR := 2
const CS := 12                         # a coarse cell of the fields, board px
const FIELD_CAP := 1800.0              # the fields reach this far from the course (mat px)
const SEED_TRIES := 30
## A gate needs the course straight this many points before it and after it
const GATE_BEFORE := 26
const GATE_AFTER := 22

var cell := 560.0                      # a grid square (mat px)
var half_w := 150.0                    # the road's half width (mat px)
var margin := 300.0                    # room round the course (mat px)
var centre := PackedVector2Array()     # the course's middle line, closed, clockwise on screen
var count := 0
var lap_length := 0.0
var kinds := PackedByteArray()         # per point: LAND / SEA / AIR
var gates: Array = []                  # per lap, in order: { i, from, to }
var mat_size := Vector2.ZERO
var bw := 0                            # the mat, board px
var bh := 0
var gw := 0                            # the fields' grid
var gh := 0
var near := PackedInt32Array()         # per field cell: [all, land, sea, air] nearest point (-1: none)
var pts_tex: ImageTexture             # per point: board x, y, kind, flags (1 first of its stretch, 2 last)
var near_tex: ImageTexture            # per field cell: the four nearest points (as floats)

## Builds level `spec` ([cols, rows, squares, half width, fixed shape or null, corners wanted, ...])
## with `plan` (the kinds in lap order, e.g. ["land", "sea"]), `n_gates` gates a lap and the kinds'
## `weights` (their share of the lap)
func build(spec: Array, plan: Array, n_gates: int, weights: Dictionary, seed_n: int, sq := 560.0) -> void:
	cell = sq
	half_w = spec[3]
	var kind_plan: Array = plan.map(func(p): return { "land": LAND, "sea": SEA, "air": AIR }[p])
	var best: Array = []
	var best_err := 1 << 40
	var best_centre := PackedVector2Array()
	var best_gates: Array = []
	var tries := 1 if spec[4] != null else SEED_TRIES
	for t in tries:
		var rng := RandomNumberGenerator.new()
		rng.seed = 7919 * seed_n + 104729 * t + 17
		var corners := _patch_outline(rng, spec[0], spec[1], spec[2], spec[4])
		# the corners wanted first, then the longest; a course where the gates fit beats any other
		var err: int = absi(corners.size() - int(spec[5])) * 100000 - _perimeter(corners)
		_make_line(corners)
		var gs := _place_gates(kind_plan, n_gates, weights)
		if gs.size() != (n_gates if kind_plan.size() > 1 else 0):
			err += 1 << 30
		if err < best_err:
			best_err = err
			best = corners
			best_centre = centre.duplicate()
			best_gates = gs
	centre = best_centre
	count = centre.size()
	lap_length = count * STEP
	gates = best_gates
	_set_kinds(kind_plan)
	# the mat: the course's box with room round it
	var lo := Vector2(INF, INF)
	var hi := Vector2(-INF, -INF)
	for p in centre:
		lo = lo.min(p)
		hi = hi.max(p)
	var pad := half_w + margin
	var shift := Vector2(pad, pad) - lo
	for i in count:
		centre[i] += shift
	mat_size = (hi - lo) + Vector2(pad, pad) * 2.0
	bw = int(ceilf(mat_size.x / PX))
	bh = int(ceilf(mat_size.y / PX))

## The patch's corners -> the rounded, evenly spaced line, clockwise, its start on the longest
## straight
func _make_line(corners: Array) -> void:
	var pts: Array[Vector2] = []
	for c in corners:
		pts.append(Vector2(c) * cell)
	centre = _resample(_rounded(pts))
	count = centre.size()
	var area := 0.0
	for i in count:
		area += centre[i].cross(centre[(i + 1) % count])
	if area < 0.0:
		centre.reverse()
	var best_i := 0
	var best_run := 0
	var run := 0
	for i in count * 2:
		var a := centre[i % count]
		var b := centre[(i + 1) % count]
		var c := centre[(i + 2) % count]
		if absf((b - a).angle_to(c - b)) < 0.01:
			run += 1
			if run > best_run:
				best_run = run
				best_i = (i - run / 2 + count) % count
		else:
			run = 0
	var rolled := PackedVector2Array()
	for i in count:
		rolled.append(centre[(best_i + i) % count])
	centre = rolled

## Is the course straight from `a` points before i to `b` after it?
func straight(i: int, a: int, b: int) -> bool:
	for o in range(-a, b + 1, 3):
		var p := centre[posmod(i + o - 2, count)]
		var q := centre[posmod(i + o, count)]
		var r := centre[posmod(i + o + 2, count)]
		if absf((q - p).angle_to(r - q)) > 0.01:
			return false
	return true

## The gates: the lap cut into n stretches whose kinds follow the plan, each as long as its kind's
## weight (the start in the middle of the first), each gate moved onto the nearest straight with
## room. [] when they don't all fit.
func _place_gates(plan: Array, n: int, weights: Dictionary) -> Array:
	if plan.size() < 2 or n < 2:
		return []
	var kind_of := func(s: int) -> int: return plan[s % plan.size()]
	var names := ["land", "sea", "air"]
	var total := 0.0
	for s in n:
		total += float(weights.get(names[kind_of.call(s)], 1.0))
	var at := float(weights.get(names[kind_of.call(0)], 1.0)) / total / 2.0
	var out: Array = []
	var last := 40
	for s in n:
		var want := int(at * count)
		var found := -1
		for o in range(0, int(count * 0.14)):
			for sg in [1, -1]:
				var i: int = want + o * sg
				if i <= last + 40 or i >= count - 50:
					continue
				if straight(i, GATE_BEFORE, GATE_AFTER):
					found = i
					break
			if found >= 0:
				break
		if found < 0:
			return out
		out.append({ "i": found, "from": kind_of.call(s), "to": kind_of.call(s + 1) })
		last = found
		if s + 1 < n:
			at += float(weights.get(names[kind_of.call(s + 1)], 1.0)) / total
	return out

## Each point's kind: from the gates (the start's stretch is the plan's first kind)
func _set_kinds(plan: Array) -> void:
	kinds = PackedByteArray()
	kinds.resize(count)
	kinds.fill(plan[0])
	if gates.is_empty():
		return
	for gi in gates.size():
		var g: Dictionary = gates[gi]
		var end_i: int = gates[gi + 1]["i"] if gi + 1 < gates.size() else count
		for i in range(int(g["i"]), end_i):
			kinds[i] = g["to"]

## The kind of the stretch at point i
func kind_at(i: int) -> int:
	return kinds[posmod(i, count)]

## The left normal of the line at point i (screen: to the right when facing along it)
func normal(i: int) -> Vector2:
	var d := (centre[(i + 1) % count] - centre[i]).normalized()
	return Vector2(-d.y, d.x)

func direction(i: int) -> Vector2:
	return (centre[(i + 1) % count] - centre[posmod(i, count)]).normalized()

# ================================================================== THE FIELDS (for the shaders)

## The nearest-point fields and the shaders' textures; `reach` (mat px) how far from the course
## they're needed
func make_fields() -> void:
	gw = int(ceilf(bw / float(CS))) + 1
	gh = int(ceilf(bh / float(CS))) + 1
	var n := gw * gh
	near = PackedInt32Array()
	near.resize(n * 4)
	near.fill(-1)
	var best := PackedFloat32Array()
	best.resize(n)
	best.fill(INF)
	var cap2 := FIELD_CAP * FIELD_CAP
	var cmat := float(CS * PX)
	for kind in [LAND, SEA, AIR]:
		if not kinds.has(kind):
			continue
		var ch: int = kind + 1
		var dist := PackedFloat32Array()
		dist.resize(n)
		dist.fill(INF)
		var q := PackedInt32Array()
		for k in range(0, count, 2):
			if kinds[k] != kind:
				continue
			var cx := int(centre[k].x / cmat)
			var cy := int(centre[k].y / cmat)
			if cx < 0 or cy < 0 or cx >= gw or cy >= gh:
				continue
			var c := cy * gw + cx
			var d := (Vector2(cx + 0.5, cy + 0.5) * cmat).distance_squared_to(centre[k])
			if d < dist[c]:
				dist[c] = d
				near[c * 4 + ch] = k
				q.append(c)
		var head := 0
		while head < q.size():
			var c := q[head]
			head += 1
			var k := near[c * 4 + ch]
			var p := centre[k]
			var cx := c % gw
			var cy := c / gw
			for dy in [-1, 0, 1]:
				var ny: int = cy + dy
				if ny < 0 or ny >= gh:
					continue
				for dx in [-1, 0, 1]:
					var nx: int = cx + dx
					if nx < 0 or nx >= gw or (dx == 0 and dy == 0):
						continue
					var nc := ny * gw + nx
					var d := Vector2((nx + 0.5) * cmat - p.x, (ny + 0.5) * cmat - p.y).length_squared()
					if d < dist[nc] and d < cap2:
						dist[nc] = d
						near[nc * 4 + ch] = k
						q.append(nc)
		# (the course as a whole: whichever kind is nearer)
		for c in n:
			if dist[c] < best[c]:
				best[c] = dist[c]
				near[c * 4] = near[c * 4 + ch]
	# the textures: the points (board px, kind, flags) and the fields (as floats)
	var pf := PackedFloat32Array()
	pf.resize(count * 4)
	for i in count:
		var flags := 0
		if kinds[posmod(i - 1, count)] != kinds[i]:
			flags |= 1
		if kinds[(i + 1) % count] != kinds[i]:
			flags |= 2
		pf[i * 4] = centre[i].x / PX
		pf[i * 4 + 1] = centre[i].y / PX
		pf[i * 4 + 2] = kinds[i]
		pf[i * 4 + 3] = flags
	pts_tex = ImageTexture.create_from_image(Image.create_from_data(count, 1, false, Image.FORMAT_RGBAF, pf.to_byte_array()))
	var nf := PackedFloat32Array()
	nf.resize(n * 4)
	for i in n * 4:
		nf[i] = near[i]
	near_tex = ImageTexture.create_from_image(Image.create_from_data(gw, gh, false, Image.FORMAT_RGBAF, nf.to_byte_array()))

# ================================================================== THE OUTLINE (Pal Prix's)

## A patch of `n` grid squares grown from the middle, and its outline as corner points (grid
## coordinates, clockwise). No two squares may touch only at a corner (the outline would pinch)
func _patch_outline(rng: RandomNumberGenerator, cols: int, rows: int, n: int, shape) -> Array:
	var cells := {}
	if shape != null:
		for r in shape:
			for x in range(r.position.x, r.end.x):
				for y in range(r.position.y, r.end.y):
					cells[Vector2i(x, y)] = true
	else:
		cells[Vector2i(cols / 2, rows / 2)] = true
	var tries := 0
	while shape == null and cells.size() < n and tries < 400:
		tries += 1
		var from: Vector2i = cells.keys()[rng.randi() % cells.size()]
		var d: Vector2i = [Vector2i.RIGHT, Vector2i.LEFT, Vector2i.DOWN, Vector2i.UP][rng.randi() % 4]
		var c := from + d
		if c.x < 0 or c.y < 0 or c.x >= cols or c.y >= rows or cells.has(c):
			continue
		cells[c] = true
		if _pinched(cells) or _holed(cells, cols, rows):
			cells.erase(c)
	var nxt := {}
	for c in cells:
		var x: int = c.x
		var y: int = c.y
		if not cells.has(Vector2i(x, y - 1)): nxt[Vector2i(x, y)] = Vector2i(x + 1, y)
		if not cells.has(Vector2i(x + 1, y)): nxt[Vector2i(x + 1, y)] = Vector2i(x + 1, y + 1)
		if not cells.has(Vector2i(x, y + 1)): nxt[Vector2i(x + 1, y + 1)] = Vector2i(x, y + 1)
		if not cells.has(Vector2i(x - 1, y)): nxt[Vector2i(x, y + 1)] = Vector2i(x, y)
	var start: Vector2i = nxt.keys()[0]
	var loop: Array[Vector2i] = [start]
	var p: Vector2i = nxt[start]
	var guard := 0
	while p != start and guard < 1000:
		loop.append(p)
		p = nxt[p]
		guard += 1
	var corners: Array = []
	for i in loop.size():
		var a: Vector2i = loop[(i - 1 + loop.size()) % loop.size()]
		var b: Vector2i = loop[i]
		var c: Vector2i = loop[(i + 1) % loop.size()]
		if (b - a) != (c - b):
			corners.append(b)
	return corners

func _perimeter(corners: Array) -> int:
	var l := 0
	for i in corners.size():
		var d: Vector2i = corners[(i + 1) % corners.size()] - corners[i]
		l += absi(d.x) + absi(d.y)
	return l

func _pinched(cells: Dictionary) -> bool:
	for c in cells:
		for d in [Vector2i(1, 1), Vector2i(1, -1)]:
			var o: Vector2i = c + d
			if cells.has(o) and not cells.has(Vector2i(o.x, c.y)) and not cells.has(Vector2i(c.x, o.y)):
				return true
	return false

func _holed(cells: Dictionary, cols: int, rows: int) -> bool:
	var seen := {}
	var queue: Array[Vector2i] = []
	for x in range(-1, cols + 1):
		for y in range(-1, rows + 1):
			if x == -1 or y == -1 or x == cols or y == rows:
				queue.append(Vector2i(x, y))
				seen[Vector2i(x, y)] = true
	while queue.size() > 0:
		var c: Vector2i = queue.pop_back()
		for d in [Vector2i.RIGHT, Vector2i.LEFT, Vector2i.DOWN, Vector2i.UP]:
			var o: Vector2i = c + d
			if o.x < -1 or o.y < -1 or o.x > cols or o.y > rows or seen.has(o) or cells.has(o):
				continue
			seen[o] = true
			queue.append(o)
	return seen.size() + cells.size() < (cols + 2) * (rows + 2)

## Every corner rounded: a quarter circle of up to half a square
func _rounded(pts: Array[Vector2]) -> PackedVector2Array:
	var out := PackedVector2Array()
	var n := pts.size()
	for i in n:
		var p := pts[(i - 1 + n) % n]
		var v := pts[i]
		var q := pts[(i + 1) % n]
		var r := minf(cell * 0.5, minf(v.distance_to(p), v.distance_to(q)) * 0.5)
		var dp := (p - v).normalized()
		var dq := (q - v).normalized()
		var cp := v + (dp + dq) * r
		var a0 := (v + dp * r - cp).angle()
		var a1 := (v + dq * r - cp).angle()
		var da := wrapf(a1 - a0, -PI, PI)
		for k in 13:
			out.append(cp + Vector2.from_angle(a0 + da * k / 12.0) * r)
	return out

## Points every STEP px along the closed line
func _resample(line: PackedVector2Array) -> PackedVector2Array:
	var n := line.size()
	var total := 0.0
	for i in n:
		total += line[i].distance_to(line[(i + 1) % n])
	var m := int(total / STEP)
	var step := total / m
	var out := PackedVector2Array()
	var i := 0
	var at := 0.0
	for k in m:
		var want := k * step
		while i < n - 1 and at + line[i].distance_to(line[(i + 1) % n]) < want:
			at += line[i].distance_to(line[(i + 1) % n])
			i += 1
		var seg := line[i].distance_to(line[(i + 1) % n])
		out.append(line[i].lerp(line[(i + 1) % n], clampf((want - at) / maxf(seg, 0.001), 0.0, 1.0)))
	return out
