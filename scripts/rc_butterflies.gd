class_name RcButterflies
extends Node2D
## RC Prix's Garden (new art): a few butterflies fluttering over the mat. The designer drew one
## butterfly in three wing frames (NOTES_ROUND_12, drawn white); the game tints, moves and flaps
## them and gives each a little shadow on the ground. They keep to the lawn, off the track (the user).

const COUNT := 16                          # (the user, 2026-10-28: more, they were often out of sight)
const TINTS := [Color8(255, 214, 120), Color8(255, 176, 196), Color8(170, 214, 255), Color8(250, 250, 240), Color8(206, 186, 255)]
const FLAPS := [0, 1, 2, 1]                # the frames, round and round
const FLAP_FPS := 12.0
const SPEED := Vector2(26.0, 42.0)          # world px a second, slowest / fastest
const TURN := 1.6                           # how quickly one swings to a new heading
const SHADOW := Vector2(10, 18)             # its shadow, down and right (the light from the top left)
const SHADOW_COL := Color(0.05, 0.08, 0.04, 0.22)

var _frames: Array[Texture2D] = []
var _bounds := Rect2()
var _track: Image                           # the raised track as painted (art px): where they don't go
const KEEP_OFF := 14.0                      # how far ahead (world px) one looks for the track
var _flies: Array = []                      # [position, heading, wanted heading, speed, its tint, its beat, next turn (s)]
var _rng := RandomNumberGenerator.new()
var _t := 0.0

## Starts them over the race's mat's lawn, or hides them (null: not the new Garden)
func start(rc, track: Image = null) -> void:
	_flies.clear()
	visible = rc != null and ResourceLoader.exists(RcTiles.DIR + "butterfly_0.png")
	set_process(visible)
	if not visible:
		return
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_frames = [RcTiles.drawn("butterfly_0"), RcTiles.drawn("butterfly_1"), RcTiles.drawn("butterfly_2")]
	var edge := RcTiles.FRAME * RcTiles.ART_PX + 24.0
	_bounds = Rect2(Vector2(edge, edge), rc.mat_size - Vector2(edge, edge) * 2.0)
	_track = track
	_rng.seed = 6151 * rc.course_seed + 3
	for i in COUNT:
		var p := _bounds.position + Vector2(_rng.randf(), _rng.randf()) * _bounds.size
		for _try in 40:                         # (somewhere on the lawn)
			if not _on_track(p):
				break
			p = _bounds.position + Vector2(_rng.randf(), _rng.randf()) * _bounds.size
		var h := _rng.randf() * TAU
		_flies.append([p, h, h, _rng.randf_range(SPEED.x, SPEED.y), TINTS[i % TINTS.size()], _rng.randf() * 10.0, _rng.randf_range(0.5, 2.0)])

func _process(delta: float) -> void:
	_t += delta
	for f in _flies:
		f[6] -= delta
		if f[6] <= 0.0:                         # a new whim: somewhere a little to one side
			f[2] = f[1] + _rng.randf_range(-1.6, 1.6)
			f[6] = _rng.randf_range(0.6, 2.2)
		var p: Vector2 = f[0]
		if not _bounds.has_point(p):            # back over the mat
			f[2] = (_bounds.get_center() - p).angle()
		f[1] = lerp_angle(f[1], f[2], minf(1.0, TURN * delta))
		var ahead := p + Vector2.from_angle(f[1]) * KEEP_OFF
		if _on_track(ahead):                    # the track ahead: veer off to whichever side is lawn
			for turn in [0.6, -0.6, 1.2, -1.2, 1.8, -1.8, PI]:
				if not _on_track(p + Vector2.from_angle(f[1] + turn) * KEEP_OFF):
					f[1] += turn
					f[2] = f[1]
					break
		f[0] = p + Vector2.from_angle(f[1]) * f[3] * delta
	queue_redraw()

## Is a world point over the track (or its tyre walls)?
func _on_track(p: Vector2) -> bool:
	if _track == null:
		return false
	var q := Vector2i((p / RcTiles.ART_PX).floor())
	if q.x < 0 or q.y < 0 or q.x >= _track.get_width() or q.y >= _track.get_height():
		return false
	return _track.get_pixelv(q).a > 0.0

func _draw() -> void:
	var k := RcTiles.ART_PX
	for f in _flies:
		var beat: float = _t + f[5]
		var fr: Texture2D = _frames[FLAPS[int(beat * FLAP_FPS) % FLAPS.size()]]
		var size := fr.get_size() * k
		var bob := roundf(sin(beat * 3.0) * 3.0)    # (a little up and down as it flutters)
		var p: Vector2 = (f[0] as Vector2).round()
		draw_rect(Rect2(p + SHADOW - Vector2(size.x * 0.3, 2), Vector2(size.x * 0.6, 4)), SHADOW_COL)
		draw_texture_rect(fr, Rect2(p - size / 2.0 + Vector2(0, bob), size), false, f[4])
