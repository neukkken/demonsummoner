extends CanvasLayer

var _book_tex: ImageTexture
var _slot_frame_tex: ImageTexture
var _close_btn: TextureButton
var _close_tex_normal: ImageTexture
var _close_tex_hover: ImageTexture

func _ready() -> void:
	process_mode = PROCESS_MODE_ALWAYS
	_generate_textures()
	_build_ui()
	get_tree().paused = true
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

func _generate_textures() -> void:
	_book_tex = _make_grimoire(800, 600)
	_slot_frame_tex = _make_slot_frame(64)
	_close_tex_normal = _make_close_btn(28, "normal")
	_close_tex_hover = _make_close_btn(28, "hover")

func _make_grimoire(w: int, h: int) -> ImageTexture:
	var img := Image.create(w, h, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))

	var cx := w / 2
	var spine_w := 20
	var spine_l := cx - spine_w / 2
	var spine_r := cx + spine_w / 2
	var margin := 8

	_draw_wood_bg(img, w, h)
	_draw_spine(img, w, h, spine_l, spine_r)
	_draw_page(img, margin, margin + 4, spine_l - margin, h - margin - 4)
	_draw_page(img, spine_r + margin, margin + 4, w - margin, h - margin - 4)

	var left_cx := (0 + spine_l) / 2
	var left_cy := h / 2
	_draw_triangle_diagram(img, left_cx, left_cy, 70)

	return ImageTexture.create_from_image(img)

func _draw_wood_bg(img: Image, w: int, h: int) -> void:
	for y in h:
		for x in w:
			var noise := sin(x * 0.05 + y * 0.07) * 0.03 + sin(x * 0.11 + y * 0.04) * 0.02
			var r := 0.08 + noise
			var g := 0.04 + noise * 0.7
			var b := 0.02 + noise * 0.5
			var nx := float(x) / w
			var ny := float(y) / h
			var edge := mini(mini(nx, 1.0 - nx), mini(ny, 1.0 - ny)) * 3.0
			if edge < 1.0:
				var t := 1.0 - edge
				r -= t * 0.03
				g -= t * 0.02
				b -= t * 0.01
			img.set_pixel(x, y, Color(clampf(r, 0.0, 1.0), clampf(g, 0.0, 1.0), clampf(b, 0.0, 1.0), 1.0))

func _draw_spine(img: Image, w: int, h: int, spine_l: int, spine_r: int) -> void:
	for y in h:
		for x in range(spine_l, spine_r):
			var t := float(x - spine_l) / float(spine_r - spine_l)
			var leather := Color(0.05, 0.025, 0.015).lerp(Color(0.1, 0.05, 0.03), 1.0 - absf(t - 0.5) * 2.0)
			var noise := sin(x * 0.3 + y * 0.5) * 0.01
			leather.r += noise
			leather.g += noise * 0.7
			if y % 8 == 0 or y % 8 == 1:
				leather = leather.lerp(Color(0.03, 0.015, 0.01), 0.4)
			img.set_pixel(x, y, leather)

func _draw_page(img: Image, x1: int, y1: int, x2: int, y2: int) -> void:
	var pw := x2 - x1
	var ph := y2 - y1
	for y in range(y1, y2):
		for x in range(x1, x2):
			var base := Color(0.38, 0.34, 0.18)
			var noise := sin(x * 0.08 + y * 0.06) * 0.03 + sin(x * 0.15 + y * 0.12) * 0.02
			base.r += noise
			base.g += noise * 0.8
			base.b += noise * 0.4
			var nx := float(x - x1) / pw
			var ny := float(y - y1) / ph
			var edge_dist := mini(mini(nx, 1.0 - nx), mini(ny, 1.0 - ny))
			var scallop := sin(nx * 60.0 + ny * 40.0) * 0.5 + 0.5
			if edge_dist < 0.04:
				var t := edge_dist / 0.04
				var dark := base.lerp(Color(0.18, 0.14, 0.08), 1.0 - t)
				if scallop > 0.6:
					img.set_pixel(x, y, dark)
				else:
					img.set_pixel(x, y, base)
			else:
				img.set_pixel(x, y, base)

func _draw_triangle_diagram(img: Image, cx: int, cy: int, size: int) -> void:
	var tip := Vector2(cx, cy + int(size * 0.85))
	var tl := Vector2(cx - int(size * 0.75), cy - int(size * 0.4))
	var tr := Vector2(cx + int(size * 0.75), cy - int(size * 0.4))

	var inner_col := Color(0.45, 0.9, 1.0, 0.95)
	var mid_col := Color(0.2, 0.5, 0.85, 0.5)
	var outer_col := Color(0.05, 0.15, 0.4, 0.0)
	var line_half := 4.0
	var glow_radius := 16.0

	var min_x := maxi(0, mini(mini(tl.x, tr.x), tip.x) - int(glow_radius) - 2)
	var max_x := mini(img.get_width() - 1, maxi(maxi(tl.x, tr.x), tip.x) + int(glow_radius) + 2)
	var min_y := maxi(0, mini(mini(tl.y, tr.y), tip.y) - int(glow_radius) - 2)
	var max_y := mini(img.get_height() - 1, maxi(maxi(tl.y, tr.y), tip.y) + int(glow_radius) + 2)

	for y in range(min_y, max_y + 1):
		for x in range(min_x, max_x + 1):
			var d1 := _point_to_segment_dist(x, y, tl, tip)
			var d2 := _point_to_segment_dist(x, y, tip, tr)
			var d3 := _point_to_segment_dist(x, y, tl, tr)
			var min_dist := mini(mini(d1, d2), d3)

			if min_dist < glow_radius:
				var existing := img.get_pixel(x, y)
				var t := min_dist / glow_radius
				var col: Color
				if min_dist < line_half:
					var lt := min_dist / line_half
					col = inner_col.lerp(Color(inner_col.r, inner_col.g, inner_col.b, 0.6), lt)
					var organic := 0.95 + sin(x * 0.3 + y * 0.5) * 0.05
					col.r *= organic
					col.g *= organic
				else:
					var gt := (min_dist - line_half) / (glow_radius - line_half)
					col = mid_col.lerp(outer_col, gt)
					var flicker := 0.85 + sin(x * 0.2 + y * 0.35) * 0.15
					col.a *= flicker
				img.set_pixel(x, y, col.blend(existing))

	_place_vertex_rune(img, tl, 8, Color(0.5, 0.9, 1.0))
	_place_vertex_rune(img, tr, 8, Color(0.5, 0.9, 1.0))
	_place_vertex_rune(img, tip, 10, Color(0.6, 0.95, 1.0))

	var trail_len := 30
	var trail_dir := Vector2(0, 1)
	for i in range(1, trail_len):
		var t := float(i) / float(trail_len)
		var px := int(tip.x + trail_dir.x * i * 1.5 + sin(i * 2.0) * 2.0)
		var py := int(tip.y + trail_dir.y * i * 1.8 + cos(i * 1.5) * 1.5)
		if px < 0 or px >= img.get_width() or py < 0 or py >= img.get_height():
			continue
		var bright := (1.0 - t) * 0.7
		var trail_col := Color(0.3, 0.7, 1.0, bright)
		for dy in range(-1, 2):
			for dx in range(-1, 2):
				var trail_existing := img.get_pixel(px + dx, py + dy)
				var trail_glow := Color(0.1, 0.3, 0.7, bright * 0.3)
				img.set_pixel(px + dx, py + dy, trail_glow.blend(trail_existing))
		var trail_existing2 := img.get_pixel(px, py)
		img.set_pixel(px, py, trail_col.blend(trail_existing2))

static func _point_to_segment_dist(px: float, py: float, a: Vector2, b: Vector2) -> float:
	var ab := b - a
	var ap := Vector2(px - a.x, py - a.y)
	var t := ap.dot(ab) / ab.length_squared()
	t = clampf(t, 0.0, 1.0)
	var closest := a + ab * t
	return sqrt((px - closest.x) * (px - closest.x) + (py - closest.y) * (py - closest.y))

func _place_vertex_rune(img: Image, pos: Vector2, r: int, col: Color) -> void:
	var cx := int(pos.x)
	var cy := int(pos.y)
	for y in range(cy - r, cy + r + 1):
		for x in range(cx - r, cx + r + 1):
			if x < 0 or x >= img.get_width() or y < 0 or y >= img.get_height():
				continue
			var dx := x - cx
			var dy := y - cy
			var dist := sqrt(dx * dx + dy * dy)
			if dist > r:
				continue
			var angle := atan2(dy, dx)
			var pat := sin(angle * 4.0) * cos(dist * 0.6) * 0.5 + 0.5
			var edge := dist / r
			var bright := pat * (1.0 - edge * 0.6)
			if bright > 0.2:
				var existing := img.get_pixel(x, y)
				var rune_col := Color(col.r * bright, col.g * bright, col.b * bright, bright * 0.85)
				img.set_pixel(x, y, rune_col.blend(existing))

func _make_slot_frame(s: int) -> ImageTexture:
	var img := Image.create(s, s, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	var b := 3
	var stone := Color(0.15, 0.12, 0.1)
	var edge := Color(0.32, 0.26, 0.2)
	var gold := Color(0.6, 0.45, 0.22)
	var inner := Color(0.08, 0.06, 0.04)
	for y in s:
		for x in s:
			var d := mini(mini(x, s - 1 - x), mini(y, s - 1 - y))
			var col: Color
			if d < b:
				var t := float(d) / float(b)
				col = edge.lerp(stone, t)
			else:
				var noise := sin(x * 0.2 + y * 0.3) * 0.015
				col = Color(inner.r + noise, inner.g + noise * 0.8, inner.b + noise * 0.5)
			img.set_pixel(x, y, col)
	for c in [[0, 0], [s - 3, 0], [0, s - 3], [s - 3, s - 3]]:
		for j in 3:
			for k in 2:
				var gx: int = c[0] + j
				var gy: int = c[1] + k
				if gx >= 0 and gx < s and gy >= 0 and gy < s:
					img.set_pixel(gx, gy, gold)
				gx = c[0]
				gy = c[1] + j
				if gx >= 0 and gx < s and gy >= 0 and gy < s:
					img.set_pixel(gx, gy, gold)
	return ImageTexture.create_from_image(img)

func _make_close_btn(s: int, state: String) -> ImageTexture:
	var img := Image.create(s, s, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	var x_col := Color(0.55, 0.42, 0.3)
	var bg := Color(0.08, 0.05, 0.04)
	if state == "hover":
		x_col = Color(0.85, 0.6, 0.35)
		bg = Color(0.15, 0.1, 0.08)
	var half := s / 2
	for y in s:
		for x in s:
			var dx := x - half
			var dy := y - half
			if dx * dx + dy * dy > half * half:
				continue
			if absf(dx - dy) <= 1 or absf(dx + dy) <= 1:
				img.set_pixel(x, y, x_col)
			else:
				img.set_pixel(x, y, bg)
	return ImageTexture.create_from_image(img)

func _build_ui() -> void:
	var vs := get_viewport().get_visible_rect().size

	var overlay := ColorRect.new()
	overlay.color = Color(0, 0, 0, 0.8)
	overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(overlay)

	var book_rect := TextureRect.new()
	book_rect.texture = _book_tex
	book_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	book_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	book_rect.size = Vector2(800, 600)
	book_rect.position = vs * 0.5 - book_rect.size * 0.5
	add_child(book_rect)

	var left_title := Label.new()
	left_title.text = "RITUAL DE INVOCACIÓN"
	left_title.add_theme_font_size_override("font_size", 24)
	left_title.add_theme_color_override("font_color", Color(0.8, 0.7, 0.5))
	left_title.add_theme_color_override("font_shadow_color", Color(0.1, 0.08, 0.04, 0.9))
	left_title.add_theme_constant_override("shadow_outline_size", 3)
	left_title.position = book_rect.position + Vector2(35, 25)
	left_title.size = Vector2(350, 36)
	add_child(left_title)

	var right_title := Label.new()
	right_title.text = "REQUISITOS DEL RITUAL"
	right_title.add_theme_font_size_override("font_size", 22)
	right_title.add_theme_color_override("font_color", Color(0.8, 0.7, 0.5))
	right_title.add_theme_color_override("font_shadow_color", Color(0.1, 0.08, 0.04, 0.9))
	right_title.add_theme_constant_override("shadow_outline_size", 3)
	right_title.position = book_rect.position + Vector2(440, 25)
	right_title.size = Vector2(330, 36)
	right_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	add_child(right_title)

	var right_text1 := Label.new()
	right_text1.text = "El Círculo de Invocación demanda\nun alma atada a la voluntad del\nconjurador. Los antiguos textos\nadvierten que solo aquellos con\nsuficiente poder arcano pueden\ncontrolar lo que yace al otro lado."
	right_text1.add_theme_font_size_override("font_size", 16)
	right_text1.add_theme_color_override("font_color", Color(0.75, 0.65, 0.5))
	right_text1.add_theme_color_override("font_shadow_color", Color(0.1, 0.08, 0.04, 0.8))
	right_text1.add_theme_constant_override("shadow_outline_size", 2)
	right_text1.position = book_rect.position + Vector2(425, 70)
	right_text1.size = Vector2(350, 130)
	right_text1.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	add_child(right_text1)

	var pacto_title := Label.new()
	pacto_title.text = "PACTO: DEVORADOR DE ALMAS"
	pacto_title.add_theme_font_size_override("font_size", 15)
	pacto_title.add_theme_color_override("font_color", Color(0.7, 0.3, 0.9))
	pacto_title.add_theme_color_override("font_shadow_color", Color(0.1, 0.0, 0.15, 0.9))
	pacto_title.add_theme_constant_override("shadow_outline_size", 2)
	pacto_title.position = book_rect.position + Vector2(425, 210)
	pacto_title.size = Vector2(350, 24)
	add_child(pacto_title)

	var pacto_text := Label.new()
	pacto_text.text = "Ofrendad 10 almas de enemigos\ncaídos en combate. Trazad el\npentagrama (↑ ↓ ← ↑ ↓) para\ninvocarlo. Desata un aullido\nespectral que ralentiza enemigos\ny otorga velocidad y maná."
	pacto_text.add_theme_font_size_override("font_size", 14)
	pacto_text.add_theme_color_override("font_color", Color(0.65, 0.45, 0.75))
	pacto_text.add_theme_color_override("font_shadow_color", Color(0.08, 0.02, 0.12, 0.8))
	pacto_text.add_theme_constant_override("shadow_outline_size", 2)
	pacto_text.position = book_rect.position + Vector2(425, 238)
	pacto_text.size = Vector2(350, 120)
	pacto_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	add_child(pacto_text)

	var slot_label := Label.new()
	slot_label.text = "Componente necesario:"
	slot_label.add_theme_font_size_override("font_size", 14)
	slot_label.add_theme_color_override("font_color", Color(0.8, 0.7, 0.55))
	slot_label.add_theme_color_override("font_shadow_color", Color(0.1, 0.08, 0.04, 0.8))
	slot_label.add_theme_constant_override("shadow_outline_size", 2)
	slot_label.position = book_rect.position + Vector2(505, 260)
	slot_label.size = Vector2(200, 22)
	add_child(slot_label)

	var slot_rect := TextureRect.new()
	slot_rect.texture = _slot_frame_tex
	slot_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	slot_rect.position = book_rect.position + Vector2(573, 218)
	slot_rect.size = Vector2(64, 64)
	add_child(slot_rect)

	var slot_item_label := Label.new()
	slot_item_label.text = "— Vacío —"
	slot_item_label.add_theme_font_size_override("font_size", 12)
	slot_item_label.add_theme_color_override("font_color", Color(0.6, 0.5, 0.35))
	slot_item_label.add_theme_color_override("font_shadow_color", Color(0.1, 0.08, 0.04, 0.8))
	slot_item_label.add_theme_constant_override("shadow_outline_size", 2)
	slot_item_label.position = book_rect.position + Vector2(555, 286)
	slot_item_label.size = Vector2(100, 18)
	slot_item_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	add_child(slot_item_label)

	_close_btn = TextureButton.new()
	_close_btn.texture_normal = _close_tex_normal
	_close_btn.texture_hover = _close_tex_hover
	_close_btn.size = Vector2(28, 28)
	_close_btn.position = book_rect.position + book_rect.size - Vector2(36, 36)
	_close_btn.pressed.connect(_on_close)
	add_child(_close_btn)

func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.keycode == KEY_G and event.pressed and not event.echo:
		queue_free()

func _exit_tree() -> void:
	if get_tree() == null:
		return
	get_tree().paused = false
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _on_close() -> void:
	queue_free()
