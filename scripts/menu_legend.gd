extends Node2D
class_name MenuLegend
## The bottom band of every menu frame ("diapositive"), laid out the same way everywhere:
##   left:   the orange (main) button's controls on a tag, up to two lines ("press: next" / "hold:
##           eat"), as far from the band's left edge as the forward sign is from its right edge
##   right:  the page dots, ending a little before the forward sign; more than DOTS_PER_ROW
##           split into two rows (each as far from the band's top / bottom edge), the lower row
##           half a step further right so it doesn't look like a grid
##   var legend := MenuLegend.attach($Menu)
##   legend.set_lines([["press", "next"], ["hold", "eat"]])     # [] hides it
##   MenuLegend.layout_dots(dots)                              # the page dots shown

# measured on the frame art (diapositive*.png as placed in the menus), Main UI coords
const BAND := Rect2(634, -515, 771, 106)   # the cream bottom band: x 634..1405, y -515..-409
const FORWARD_MARGIN := 80.0               # the forward sign → the band's right edge (and, mirrored,
                                           # the band's left edge → the legend's tag)
const FORWARD_W := 57.2                    # logoforward.png 49 px x the menus' 1.167 scale
const FORWARD_LEFT := 1405.0 - FORWARD_MARGIN - FORWARD_W   # 1267.8: where the forward sign starts
const LEGEND_MARGIN := FORWARD_MARGIN      # band's left edge → the tag: the mirror of the forward sign
const PAD_X := 12.0                        # inside the tag: left / right
const PAD_Y := 6.0                         # inside the tag: above / below the icons
const TAG_STEP := 0.12                     # the tag: the band's colour, moved towards the frame's panel
                                           # orange until it's this much darker (brightness 0..1), so it
                                           # stands out the same on every frame (each band differs)
const DOT_GAP := 24.0                      # last dot → forward sign
const DOT_STEP := 40.0
const DOT_SIZE := 27.0
const DOTS_PER_ROW := 5
const ROW_OFFSET := 22.0                   # two rows: this far above / below the band's middle
const LINE_GAP := 38.0
# The icon and its tag are pixel art on the forward sign's grid (its art pixel is 3x3 px). The
# pixel font (an 8-pixel grid: 125 of its 1000 units per pixel) is at 28 (3.5 px per font pixel:
# the middle between 24 and 32, as asked). The text sits so the middle of its lowercase letters
# (7 font px tall, baseline 12 font px below the top of its box) lines up with the icon's middle.
const PIXEL := 3                          # the icon's and the tag's pixel (the forward sign's own)
const ICON_PX := 11                       # the orange button: 11 x 11 art pixels → 33 px
const ICON_W := ICON_PX * PIXEL
const FONT_SIZE := 28                      # between 24 and 32 (the font's pixel is then 3.5 px)
const FONT_PX := FONT_SIZE / 8.0
const TEXT_GAP := 3 * PIXEL                # icon → text (9 px)
const INK := Color8(84, 66, 50)           # the frame's own brown (its outline and the page dots)

var _rows: Array = []
var dx := 0.0                             # (a menu whose frame sits a little off: the collection, +6 px)
var tag_color := Color8(240, 220, 180)

## frame: the menu's frame Sprite2D (its band / panel colours give the tag's colour)
static func attach(menu_root: Node, frame: Sprite2D = null, frame_dx := 0.0) -> MenuLegend:
	var legend := MenuLegend.new()
	legend.dx = frame_dx
	if frame and frame.texture:
		var img := frame.texture.get_image()
		if img.is_compressed():
			img.decompress()
		var band := img.get_pixel(img.get_width() / 2, int(img.get_height() * 0.9))     # the bottom band
		var panel := img.get_pixel(img.get_width() / 2, int(img.get_height() * 0.38))   # the slide's panel
		var mix := clampf(TAG_STEP / maxf(band.get_luminance() - panel.get_luminance(), 0.01), 0.25, 0.9)
		legend.tag_color = band.lerp(panel, mix)
	legend.z_index = 2
	menu_root.add_child(legend)
	return legend

func set_lines(lines: Array) -> void:
	for r in _rows:
		r.queue_free()
	_rows.clear()
	visible = not lines.is_empty()
	if lines.is_empty():
		return
	var font: Font = load("res://fonts/pixChicago.ttf")
	var mid := BAND.get_center().y
	# the tag behind them, sized to the lines (one or two), on the same pixel grid
	var text_w := 0.0
	for line in lines:
		text_w = maxf(text_w, font.get_string_size("%s: %s" % [line[0], line[1]], HORIZONTAL_ALIGNMENT_LEFT, -1, FONT_SIZE).x)
	var tag_size := Vector2(PAD_X + ICON_W + TEXT_GAP + text_w + PAD_X, (lines.size() - 1) * LINE_GAP + ICON_W + PAD_Y * 2.0)
	var tag_pos := Vector2(BAND.position.x + dx + LEGEND_MARGIN, round(mid - tag_size.y / 2.0))
	var tag := Sprite2D.new()
	tag.texture = _tag_texture(int(ceil(tag_size.x / PIXEL)), int(ceil(tag_size.y / PIXEL)), tag_color)
	tag.centered = false
	tag.scale = Vector2(PIXEL, PIXEL)
	tag.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	tag.position = tag_pos
	add_child(tag)
	_rows.append(tag)
	var x := tag_pos.x + PAD_X + ICON_W / 2.0
	for i in lines.size():
		var row := Node2D.new()
		row.position = Vector2(x, mid + (i - (lines.size() - 1) / 2.0) * LINE_GAP)
		add_child(row)
		_rows.append(row)
		var icon := Sprite2D.new()
		icon.texture = _icon()
		icon.scale = Vector2(PIXEL, PIXEL)
		icon.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		row.add_child(icon)
		var l := Label.new()
		l.text = "%s: %s" % [lines[i][0], lines[i][1]]
		# top of the text box = icon middle - (baseline 12 font px - half the 7 px x-height)
		l.position = Vector2(ICON_W / 2.0 + TEXT_GAP, -round((12.0 - 3.5) * FONT_PX))
		l.size = Vector2(320, 15 * FONT_PX)
		l.vertical_alignment = VERTICAL_ALIGNMENT_TOP
		l.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		if font:
			l.add_theme_font_override("font", font)
		l.add_theme_font_size_override("font_size", FONT_SIZE)
		l.add_theme_color_override("font_color", INK)
		l.mouse_filter = Control.MOUSE_FILTER_IGNORE
		row.add_child(l)

## The orange (main) button in miniature: pixel art on the forward sign's grid, in the frame's own
## muted orange and brown, cut corners, a light top-left edge and a shaded bottom-right one.
static var _icon_tex: Texture2D
static func _icon() -> Texture2D:
	if _icon_tex:
		return _icon_tex
	const N := ICON_PX
	var img := Image.create(N, N, false, Image.FORMAT_RGBA8)
	# the frame's own colours, so it sits in the band like part of the print
	var orange := Color8(215, 160, 96)        # the frame's orange panel
	var light := Color8(230, 186, 128)
	var shade := Color8(190, 136, 78)
	for y in N:
		for x in N:
			var corner := (x == 0 or x == N - 1) and (y == 0 or y == N - 1)
			if corner:
				continue
			var col := orange
			if x == 0 or y == 0 or x == N - 1 or y == N - 1:
				col = INK
			elif x == 1 or y == 1:
				col = light
			elif x == N - 2 or y == N - 2:
				col = shade
			img.set_pixel(x, y, col)
	img.set_pixel(1, 1, INK)                  # (the cut corners, one step in)
	img.set_pixel(N - 2, 1, INK)
	img.set_pixel(1, N - 2, INK)
	img.set_pixel(N - 2, N - 2, INK)
	_icon_tex = ImageTexture.create_from_image(img)
	return _icon_tex

## Where a menu's forward sign goes (its centre x): FORWARD_MARGIN from the band's right edge.
## frame_dx: a menu whose frame sits a little off (the collection's, +6 px)
static func forward_center_x(frame_dx := 0.0) -> float:
	return frame_dx + FORWARD_LEFT + FORWARD_W / 2.0

## A tag like the food cards' type tags: a flat rounded rectangle (its corners cut one pixel)
static func _tag_texture(w: int, h: int, color: Color) -> Texture2D:
	var img := Image.create(w, h, false, Image.FORMAT_RGBA8)
	img.fill(color)
	for p in [Vector2i(0, 0), Vector2i(w - 1, 0), Vector2i(0, h - 1), Vector2i(w - 1, h - 1)]:
		img.set_pixel(p.x, p.y, Color(0, 0, 0, 0))
	return ImageTexture.create_from_image(img)

## Places the first `count` page dots (Controls under a Node2D) on the band's right: one row,
## or two staggered rows when there are more than DOTS_PER_ROW. Reading order: top row first.
static func layout_dots(dots: Array, count := -1, frame_dx := 0.0) -> void:
	var n := dots.size() if count < 0 else mini(count, dots.size())
	if n == 0:
		return
	var parent_pos: Vector2 = (dots[0].get_parent() as Node2D).position
	var right := frame_dx + FORWARD_LEFT - DOT_GAP           # the last dot's right edge (before the sign)
	var mid := BAND.get_center().y
	var rows: Array = [[n, mid, right]]
	if n > DOTS_PER_ROW:
		var top := int(ceil(n / 2.0))
		rows = [[top, mid - ROW_OFFSET, right - DOT_STEP / 2.0], [n - top, mid + ROW_OFFSET, right]]
	var k := 0
	for row in rows:
		var m: int = row[0]
		for i in m:
			var left: float = row[2] - DOT_SIZE - (m - 1 - i) * DOT_STEP
			dots[k].position = Vector2(left, row[1] - DOT_SIZE / 2.0) - parent_pos
			k += 1
