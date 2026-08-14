extends CanvasLayer

var hp_bar: TextureProgressBar
var mp_bar: TextureProgressBar
var hp_label: Label
var mp_label: Label
var element_label: Label
var level_label: Label
var xp_bar: TextureProgressBar
var xp_label: Label
var _hp_fill: ImageTexture
var _mp_fill: ImageTexture
var _hp_frame: ImageTexture
var _mp_frame: ImageTexture
var _xp_fill: ImageTexture
var _xp_frame: ImageTexture

var _icon_fireball: ImageTexture
var _icon_icewall: ImageTexture
var _icon_icelance: ImageTexture
var _icon_blackhole: ImageTexture
var _icon_segador: ImageTexture
var _icon_devorador: ImageTexture
var _slot_frame: ImageTexture
var _reticle: ImageTexture
var _banner_tex: ImageTexture
var _icon_potion: ImageTexture

var _demon_bar: HBoxContainer
var _demon_slots: Array[Control] = []
var _demon_cd_labels: Array[Label] = []
var _potion_cd_label: Label
var _banner: Control
var _banner_label: Label
var _banner_visible: bool = false
var _choice_panel: Control

var _choice_visible: bool = false
var _choice_items: Array[String] = []
var _item_grid: GridContainer = null
var _choice_slots: Control = null
var _xp_floating: Label = null
var _IM = null

var _soul_label: Label
var _pentagram_label: Label

var timer_label: Label

var _damage_vignette: TextureRect

func _ready() -> void:
	process_mode = PROCESS_MODE_ALWAYS
	_IM = get_node("/root/ItemManager")
	_generate_textures()
	_build_ui()
	DatosJuego.alma_cosechada.connect(set_souls)

func _generate_textures() -> void:
	_hp_fill = AssetLoader.load_asset("high/globe_hp_fill_96.png", func(): return _make_globe_fill(96, Color(0.7, 0.05, 0.05)))
	_mp_fill = AssetLoader.load_asset("high/globe_mp_fill_96.png", func(): return _make_globe_fill(96, Color(0.05, 0.1, 0.7)))
	_hp_frame = AssetLoader.load_asset("high/globe_hp_frame_96.png", func(): return _make_globe_frame(96, false))
	_mp_frame = AssetLoader.load_asset("high/globe_mp_frame_96.png", func(): return _make_globe_frame(96, true))
	_slot_frame = AssetLoader.load_asset("high/slot_frame_64.png", func(): return _make_slot_frame(64))
	_reticle = AssetLoader.load_asset("critical/crosshair_48.png", func(): return _make_gothic_reticle(48))
	_banner_tex = AssetLoader.load_asset("high/banner_400x120.png", func(): return _make_banner(400, 120))
	_icon_fireball = AssetLoader.load_asset("critical/fireball_56.png", func(): return _make_icon_fireball(56))
	_icon_icewall = AssetLoader.load_asset("critical/icewall_56.png", func(): return _make_icon_icewall(56))
	_icon_icelance = AssetLoader.load_asset("critical/icelance_56.png", func(): return _make_icon_icelance(56))
	_icon_blackhole = AssetLoader.load_asset("critical/blackhole_56.png", func(): return _make_icon_blackhole(56))
	_icon_segador = AssetLoader.load_asset("critical/segador_56.png", func(): return _make_icon_segador(56))
	_icon_devorador = AssetLoader.load_asset("critical/devorador_56.png", func(): return _make_icon_devorador(56))
	_icon_potion = AssetLoader.load_asset("critical/potion_56.png", func(): return _make_icon_potion(56))
	_xp_fill = AssetLoader.load_asset("high/xp_fill_320x14.png", func(): return _make_xp_fill(320, 14))
	_xp_frame = AssetLoader.load_asset("high/xp_frame_320x14.png", func(): return _make_xp_frame(320, 14))

func _make_globe_fill(size: int, col: Color) -> ImageTexture:
	var img := Image.create(size, size, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	var cx := size / 2
	var cy := size / 2
	var r := size / 2 - 8
	for y in size:
		for x in size:
			var dx := x - cx
			var dy := y - cy
			if dx * dx + dy * dy <= r * r:
				var nx := float(dx) / r
				var ny := float(dy) / r
				var shade := 0.7 + 0.3 * (1.0 - sqrt(nx * nx + ny * ny))
				img.set_pixel(x, y, Color(col.r * shade, col.g * shade, col.b * shade, 0.9))
	return ImageTexture.create_from_image(img)

func _make_globe_frame(size: int, bat: bool) -> ImageTexture:
	var img := Image.create(size, size, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	var cx := size / 2
	var cy := size / 2
	var ro := size / 2 - 2
	var ri := ro - 6
	for y in size:
		for x in size:
			var dx := x - cx
			var dy := y - cy
			var dist := sqrt(dx * dx + dy * dy)
			if dist >= ri and dist <= ro:
				var angle := atan2(dy, dx)
				var pat := sin(angle * 6.0 + PI * 0.5) * 0.5 + 0.5
				var b := 0.15 + pat * 0.25
				img.set_pixel(x, y, Color(b * 0.8, b * 0.4, b * 0.2))
			elif dist > ro and dist <= ro + 1:
				img.set_pixel(x, y, Color(0.1, 0.05, 0.02))
	if bat:
		for side in [-1, 1]:
			for i in 3:
				var a := PI * 0.5 - 0.3 + i * 0.3
				var bx: float = cx + cos(a) * ro * side
				var by: float = cy - sin(a) * ro * 0.6
				for j in 3:
					var px := int(bx + side * j * 2)
					var py := int(by + j)
					if px >= 0 and px < size and py >= 0 and py < size:
						img.set_pixel(px, py, Color(0.25, 0.15, 0.35))
	return ImageTexture.create_from_image(img)

func _make_slot_frame(s: int) -> ImageTexture:
	var img := Image.create(s, s, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	var b := 4
	var stone := Color(0.12, 0.1, 0.08)
	var edge := Color(0.28, 0.23, 0.18)
	var gold := Color(0.55, 0.42, 0.2)
	for y in s:
		for x in s:
			var p: Color = Color(0, 0, 0, 0)
			if x < b or x >= s - b or y < b or y >= s - b:
				var d := mini(mini(x, s - 1 - x), mini(y, s - 1 - y))
				var t := float(d) / float(b)
				p = stone.lerp(edge, t)
			else:
				continue
			img.set_pixel(x, y, p)
	# gold corner accents
	for c in [[2, 2], [s - 3, 2], [2, s - 3], [s - 3, s - 3]]:
		for j in 3:
			for k in 2:
				var px: int = c[0] + j
				var py: int = c[1] + k
				if px >= 0 and px < s and py >= 0 and py < s:
					img.set_pixel(px, py, gold)
	return ImageTexture.create_from_image(img)

func _make_icon_fireball(s: int) -> ImageTexture:
	var img := Image.create(s, s, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	var cx := s / 2
	var cy := s / 2
	var r := s / 2 - 3
	for y in s:
		for x in s:
			var dx := x - cx
			var dy := y - cy
			var dist := sqrt(dx * dx + dy * dy)
			if dist <= r:
				var angle := atan2(dy, dx)
				var flame := sin(angle * 5.0 + PI) * 0.3 + 0.7
				var edge_dist := dist / r
				var bright := (1.0 - edge_dist) * flame
				var col: Color
				if bright > 0.6:
					col = Color(1.0, 0.95, 0.6, 0.9)
				elif bright > 0.3:
					col = Color(1.0, 0.5, 0.05, 0.85)
				else:
					col = Color(0.8, 0.15, 0.02, 0.7 * bright * 3.0)
				img.set_pixel(x, y, col)
			elif dist <= r + 2:
				var angle := atan2(dy, dx)
				var fl := sin(angle * 6.0 + PI * 0.3) * 0.5 + 0.5
				if fl > 0.7:
					var t := (dist - r) / 2.0
					img.set_pixel(x, y, Color(0.9 - t * 0.5, 0.3 - t * 0.2, 0.02, 0.6 - t * 0.4))
	return ImageTexture.create_from_image(img)

func _make_icon_icewall(s: int) -> ImageTexture:
	var img := Image.create(s, s, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	var cx := s / 2
	var cy := s / 2
	var crystals := [
		[0, -1, 0.8, 8],
		[-1, 0.5, 0.6, 7],
		[1, 0.3, 0.5, 6],
	]
	for c in crystals:
		var ox: int = c[0] * 8
		var oy: int = c[1] * 8
		var h: int = c[3]
		var w: int = 3
		var tip_x := cx + ox - 1
		var tip_y := cy + oy - h
		var base_y := cy + oy
		var base_l := cx + ox - w
		var base_r := cx + ox + w
		for y in range(tip_y, base_y):
			var t := float(y - tip_y) / float(base_y - tip_y)
			var half_w := int(w * (1.0 - t * 0.7))
			var left := cx + ox - half_w
			var right := cx + ox + half_w
			for x in range(left, right + 1):
				if x >= 0 and x < s and y >= 0 and y < s:
					var bright := 0.5 + 0.5 * (1.0 - t)
					img.set_pixel(x, y, Color(0.4 * bright, 0.7 * bright, 1.0 * bright, 0.9))
	return ImageTexture.create_from_image(img)

func _make_icon_icelance(s: int) -> ImageTexture:
	var img := Image.create(s, s, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	var cx := s / 2
	var cy := s / 2
	var h := s / 2 - 2
	var half_w := 6
	var tip_y := cy - h
	var base_y := cy + h
	for y in range(tip_y, base_y):
		var t := float(y - tip_y) / float(base_y - tip_y)
		var hex_w := int(half_w * (1.0 - absf(t - 0.5) * 0.6))
		var left := cx - hex_w
		var right := cx + hex_w
		for x in range(left, right + 1):
			if x >= 0 and x < s and y >= 0 and y < s:
				var bright := 0.6 + 0.4 * (1.0 - absf(t - 0.5) * 2.0)
				img.set_pixel(x, y, Color(0.3 * bright, 0.8 * bright, 1.0 * bright, 0.9))
	for y in range(tip_y + 2, base_y - 2):
		var t := float(y - tip_y) / float(base_y - tip_y)
		var hex_w := int(half_w * (1.0 - absf(t - 0.5) * 0.6))
		if hex_w > 2:
			img.set_pixel(cx + 1, y, Color(0.8, 1.0, 1.0, 0.6))
	return ImageTexture.create_from_image(img)

func _make_icon_blackhole(s: int) -> ImageTexture:
	var img := Image.create(s, s, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	var cx := s / 2
	var cy := s / 2
	var r := s / 2 - 3
	for y in s:
		for x in s:
			var dx := x - cx
			var dy := y - cy
			var dist := sqrt(dx * dx + dy * dy)
			if dist <= r:
				var angle := atan2(dy, dx)
				var spiral := cos(angle * 3.0 + dist * 0.3) * 0.5 + 0.5
				var edge := dist / r
				var bright := (1.0 - edge) * (0.3 + 0.7 * spiral)
				var purple := Color(0.5 * bright, 0.15 * bright, 0.7 * bright, 0.9)
				var dark := Color(0.02, 0.0, 0.04, 0.95)
				var col := purple.lerp(dark, edge * 0.8)
				img.set_pixel(x, y, col)
	for y in s:
		for x in s:
			var dx := x - cx
			var dy := y - cy
			var dist := sqrt(dx * dx + dy * dy)
			var ring_r := r * 0.35
			var ring_w := 2.0
			if absf(dist - ring_r) < ring_w:
				var t := 1.0 - absf(dist - ring_r) / ring_w
				var angle := atan2(dy, dx)
				var glow := t * (0.5 + 0.5 * sin(angle * 4.0 + PI))
				img.set_pixel(x, y, Color(0.6 * glow, 0.2 * glow, 0.9 * glow, 0.8))
	return ImageTexture.create_from_image(img)

func _make_icon_segador(s: int) -> ImageTexture:
	var img := Image.create(s, s, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	var cx := s / 2
	var cy := s / 2
	var r := s / 2 - 3
	for y in s:
		for x in s:
			var dx := x - cx
			var dy := y - cy
			var dist := sqrt(dx * dx + dy * dy)
			if dist <= r:
				var angle := atan2(dy, dx)
				var pat := sin(angle * 4.0 + PI * 0.5) * 0.5 + 0.5
				var edge := dist / r
				var bright := (1.0 - edge) * (0.4 + 0.6 * pat)
				var col = Color(0.9 * bright, 0.05 * bright, 0.05 * bright, 0.9)
				img.set_pixel(x, y, col)
			elif dist <= r + 2:
				var pat := sin(dx * 0.5 + dy * 0.3) * 0.5 + 0.5
				if pat > 0.65:
					var t := (dist - r) / 2.0
					img.set_pixel(x, y, Color(0.8 - t * 0.6, 0.03, 0.03, 0.5 - t * 0.3))
	return ImageTexture.create_from_image(img)

func _make_icon_devorador(s: int) -> ImageTexture:
	var img := Image.create(s, s, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	var cx := s / 2
	var cy := s / 2
	var r := s / 2 - 3
	for y in s:
		for x in s:
			var dx := x - cx
			var dy := y - cy
			var dist := sqrt(dx * dx + dy * dy)
			if dist <= r:
				var angle := atan2(dy, dx)
				var spiral := cos(angle * 5.0 + dist * 0.4) * 0.5 + 0.5
				var edge := dist / r
				var bright := (1.0 - edge) * (0.3 + 0.7 * spiral)
				var col := Color(0.5 * bright, 0.1 * bright, 0.8 * bright, 0.9)
				img.set_pixel(x, y, col)
	for y in s:
		for x in s:
			var dx := x - cx
			var dy := y - cy
			var dist := sqrt(dx * dx + dy * dy)
			var ring_r := r * 0.7
			var ring_w := 2.0
			if absf(dist - ring_r) < ring_w:
				var t := 1.0 - absf(dist - ring_r) / ring_w
				var angle := atan2(dy, dx)
				var star := sin(angle * 5.0 + PI * 0.5) * 0.5 + 0.5
				var glow := t * star
				img.set_pixel(x, y, Color(0.7 * glow, 0.15 * glow, 1.0 * glow, 0.8))
	return ImageTexture.create_from_image(img)

func _make_icon_potion(s: int) -> ImageTexture:
	var img := Image.create(s, s, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	var cx := s / 2
	var cy := s / 2
	var bg_r := s / 2 - 2
	for y in s:
		for x in s:
			var dx := x - cx
			var dy := y - cy
			var dist := sqrt(dx * dx + dy * dy)
			if dist <= bg_r:
				var edge := dist / bg_r
				var r := 0.1 + 0.15 * (1.0 - edge)
				var g := 0.35 + 0.45 * (1.0 - edge)
				var b := 0.1 + 0.15 * (1.0 - edge)
				img.set_pixel(x, y, Color(r, g, b, 0.9))
			elif dist <= bg_r + 2:
				var t := (dist - bg_r) / 2.0
				img.set_pixel(x, y, Color(0.08 * (1.0 - t), 0.2 * (1.0 - t), 0.08 * (1.0 - t), 0.5 * (1.0 - t)))
	var cross_w := 4
	var cross_h := int(s * 0.45)
	var cx2 := cx
	for y in range(cx2 - cross_h / 2, cx2 + cross_h / 2):
		for x in range(cx2 - cross_w / 2, cx2 + cross_w / 2):
			img.set_pixel(x, y, Color(0.9, 0.95, 0.9, 0.95))
	for y in range(cx2 - cross_w / 2, cx2 + cross_w / 2):
		for x in range(cx2 - cross_h / 2, cx2 + cross_h / 2):
			img.set_pixel(x, y, Color(0.9, 0.95, 0.9, 0.95))
	return ImageTexture.create_from_image(img)

func _make_gothic_reticle(s: int) -> ImageTexture:
	var img := Image.create(s, s, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	var cx := s / 2
	var cy := s / 2
	var outer := s / 2 - 1
	var inner := 4
	var metal := Color(0.4, 0.35, 0.3)
	var bright_m := Color(0.55, 0.5, 0.45)
	for y in s:
		for x in s:
			var dx := x - cx
			var dy := y - cy
			var dist := sqrt(dx * dx + dy * dy)
			# outer ring
			if dist >= outer - 2 and dist <= outer:
				var t := 1.0 - absf(dist - (outer - 1)) / 2.0
				var col := metal.lerp(bright_m, t)
				img.set_pixel(x, y, Color(col.r, col.g, col.b, 0.7 * t))
			# cross lines
			var ax := absf(dx)
			var ay := absf(dy)
			if (ax <= 1 and ay >= inner and ay <= outer) or (ay <= 1 and ax >= inner and ax <= outer):
				img.set_pixel(x, y, Color(0.5, 0.45, 0.4, 0.7))
			# inner glow dot
			if dist <= 2:
				var t := 1.0 - dist / 2.0
				img.set_pixel(x, y, Color(0.7, 0.6, 0.5, t * 0.6))
	return ImageTexture.create_from_image(img)

func _make_banner(w: int, h: int) -> ImageTexture:
	var img := Image.create(w, h, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	var cx := w / 2
	var cy := h / 2
	var stone := Color(0.1, 0.08, 0.06)
	var gold := Color(0.55, 0.42, 0.2)
	var bright := Color(0.7, 0.55, 0.3)
	
	for y in h:
		for x in w:
			var nx := float(x) / w
			var ny := float(y) / h
			# wing shapes on left/right thirds
			var wx := absf(nx - 0.5) * 2.0
			var wy := (ny - 0.5) * 2.0
			if wx > 0.5:
				var wing_x := (wx - 0.5) * 2.0
				var wing_curve := sin(wing_x * PI * 0.8) * 0.3 + 0.3
				var wing_upper := -wing_curve + 0.1
				var wing_lower := wing_curve - 0.1
				if wy > wing_upper and wy < wing_lower:
					var pat := sin(x * 0.5 + y * 0.3) * 0.3 + 0.7
					var col := Color(0.15 * pat, 0.12 * pat, 0.1 * pat)
					img.set_pixel(x, y, col)
					# edge scallops
					var edge_pat := sin(x * 0.8 + y * 0.6) * 0.5 + 0.5
					var edge_dist := mini(absf(wy - wing_upper), absf(wy - wing_lower))
					if edge_dist < 0.02 or edge_pat > 0.85:
						img.set_pixel(x, y, Color(0.3, 0.22, 0.15))
			# center stone banner
			if wx < 0.5:
				var border := 3
				if x < border or x >= w - border or y < border or y >= h - border:
					img.set_pixel(x, y, gold)
				else:
					var stone_pat := (int(x * 0.2) + int(y * 0.2)) % 4
					var col := stone if stone_pat != 0 else stone.lerp(Color(0.15, 0.12, 0.1), 0.3)
					img.set_pixel(x, y, col)
			# gold accents at wing joints
			var joint_x := absf(nx - 0.5)
			if joint_x < 0.04 and (absf(wy) < 0.03 or absf(absf(wy) - 0.35) < 0.03 or absf(absf(wy) - 0.25) < 0.03):
				img.set_pixel(x, y, bright)
	
	return ImageTexture.create_from_image(img)

func _build_ui() -> void:
	var margin := 15
	var gs := 80

	hp_bar = TextureProgressBar.new()
	hp_bar.texture_progress = _hp_fill
	hp_bar.texture_over = _hp_frame
	hp_bar.fill_mode = 5
	hp_bar.value = 100.0
	hp_bar.max_value = 100.0
	hp_bar.position = Vector2(margin, margin)
	hp_bar.size = Vector2(gs, gs)
	add_child(hp_bar)

	hp_label = Label.new()
	hp_label.text = "100"
	hp_label.add_theme_font_size_override("font_size", 13)
	hp_label.add_theme_color_override("font_color", Color(1, 0.85, 0.85))
	hp_label.position = Vector2(margin + gs / 2 - 8, margin + gs / 2 - 8)
	add_child(hp_label)

	mp_bar = TextureProgressBar.new()
	mp_bar.texture_progress = _mp_fill
	mp_bar.texture_over = _mp_frame
	mp_bar.fill_mode = 5
	mp_bar.value = 100.0
	mp_bar.max_value = 100.0
	mp_bar.position = Vector2(margin, margin + gs + 8)
	mp_bar.size = Vector2(gs, gs)
	add_child(mp_bar)

	mp_label = Label.new()
	mp_label.text = "100"
	mp_label.add_theme_font_size_override("font_size", 13)
	mp_label.add_theme_color_override("font_color", Color(0.85, 0.85, 1))
	mp_label.position = Vector2(margin + gs / 2 - 8, margin + gs * 2 + 8 - 8)
	add_child(mp_label)

	element_label = Label.new()
	element_label.text = "NONE"
	element_label.add_theme_font_size_override("font_size", 11)
	element_label.add_theme_color_override("font_color", Color(0.65, 0.45, 0.85))
	element_label.position = Vector2(margin, margin + gs * 2 + 8 + gs + 2)
	add_child(element_label)

	_soul_label = Label.new()
	_soul_label.text = "ALMAS: 0/" + str(DatosJuego.REQUISITO_DEVORADOR)
	_soul_label.add_theme_font_size_override("font_size", 11)
	_soul_label.add_theme_color_override("font_color", Color(0.6, 0.2, 0.8, 0.85))
	_soul_label.position = Vector2(margin + gs + 10, margin + gs * 2 + 8 + gs + 2)
	add_child(_soul_label)

	_pentagram_label = Label.new()
	_pentagram_label.text = ""
	_pentagram_label.add_theme_font_size_override("font_size", 11)
	_pentagram_label.add_theme_color_override("font_color", Color(0.7, 0.3, 0.9, 0.8))
	_pentagram_label.position = Vector2(margin + gs + 10, margin + gs * 2 + 8 + gs + 16)
	add_child(_pentagram_label)

	level_label = Label.new()
	level_label.text = "LV 1"
	level_label.add_theme_font_size_override("font_size", 12)
	level_label.add_theme_color_override("font_color", Color(0.6, 0.5, 0.7, 0.8))
	level_label.set_anchors_preset(Control.PRESET_CENTER, false)
	level_label.position = Vector2(-200, -303)
	level_label.size = Vector2(40, 16)
	level_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	add_child(level_label)

	xp_bar = TextureProgressBar.new()
	xp_bar.value = 0
	xp_bar.max_value = 5
	xp_bar.texture_progress = _xp_fill
	xp_bar.texture_over = _xp_frame
	xp_bar.fill_mode = 0
	xp_bar.size = Vector2(320, 14)
	xp_bar.set_anchors_preset(Control.PRESET_CENTER, false)
	xp_bar.position = Vector2(-160, -300)
	add_child(xp_bar)

	xp_label = Label.new()
	xp_label.text = "0 / 50 XP"
	xp_label.add_theme_font_size_override("font_size", 10)
	xp_label.add_theme_color_override("font_color", Color(0.7, 0.6, 0.8, 0.7))
	xp_label.set_anchors_preset(Control.PRESET_CENTER, false)
	xp_label.position = Vector2(165, -303)
	xp_label.size = Vector2(80, 14)
	xp_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	add_child(xp_label)

	_xp_floating = Label.new()
	_xp_floating.text = ""
	_xp_floating.add_theme_font_size_override("font_size", 14)
	_xp_floating.add_theme_color_override("font_color", Color(1.0, 0.9, 0.4))
	_xp_floating.add_theme_color_override("font_shadow_color", Color(0.3, 0.2, 0.0, 0.8))
	_xp_floating.add_theme_constant_override("shadow_outline_size", 2)
	_xp_floating.set_anchors_preset(Control.PRESET_CENTER, false)
	_xp_floating.position = Vector2(5, -315)
	_xp_floating.size = Vector2(100, 16)
	_xp_floating.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	add_child(_xp_floating)

	# gothic crosshair reticle
	var reticle_node := TextureRect.new()
	reticle_node.texture = _reticle
	reticle_node.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	reticle_node.size = Vector2(48, 48)
	reticle_node.set_anchors_preset(Control.PRESET_CENTER, false)
	reticle_node.position = -reticle_node.size * 0.5
	add_child(reticle_node)

	_banner = Control.new()
	_banner.set_anchors_preset(Control.PRESET_CENTER, false)
	_banner.position = Vector2(-200, -100)
	_banner.size = Vector2(400, 200)
	_banner.visible = false

	var banner_bg := TextureRect.new()
	banner_bg.texture = _banner_tex
	banner_bg.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	banner_bg.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	banner_bg.size = Vector2(400, 120)
	_banner.add_child(banner_bg)

	_banner_label = Label.new()
	_banner_label.text = "¡SUBISTE DE NIVEL!"
	_banner_label.add_theme_font_size_override("font_size", 22)
	_banner_label.add_theme_color_override("font_color", Color(1.0, 0.85, 0.5))
	_banner_label.add_theme_color_override("font_shadow_color", Color(0.2, 0.1, 0.3, 0.8))
	_banner_label.add_theme_constant_override("shadow_outline_size", 2)
	_banner_label.position = Vector2(200, 55)
	_banner_label.size = Vector2(0, 30)
	_banner_label.set_anchors_preset(Control.PRESET_CENTER, false)
	_banner_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_banner.add_child(_banner_label)

	add_child(_banner)

	_build_demon_bar()
	_build_choice_panel()
	_build_item_grid()
	_build_damage_vignette()

func _build_demon_bar() -> void:
	var spell_icons := [_icon_fireball, _icon_icewall, _icon_icelance, _icon_blackhole]
	var spell_keys := ["1", "2", "3", "4"]
	var demon_names := ["SEGADOR", "DEVORADOR"]
	var demon_icons := [_icon_segador, _icon_devorador]

	_demon_bar = HBoxContainer.new()
	_demon_bar.set_anchors_preset(Control.PRESET_CENTER, false)
	_demon_bar.position = Vector2(-140, 220)
	_demon_bar.size = Vector2(460, 76)
	add_child(_demon_bar)

	for i in 4:
		var slot := TextureRect.new()
		slot.texture = _slot_frame
		slot.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		slot.size = Vector2(64, 64)
		slot.custom_minimum_size = Vector2(64, 64)
		if i == 0:
			var icon := TextureRect.new()
			icon.texture = _icon_potion
			icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			icon.position = Vector2(4, 4)
			icon.size = Vector2(56, 56)
			slot.add_child(icon)
			var key_label := Label.new()
			key_label.text = "1"
			key_label.add_theme_font_size_override("font_size", 9)
			key_label.add_theme_color_override("font_color", Color(0.6, 0.5, 0.4, 0.7))
			key_label.position = Vector2(50, 2)
			slot.add_child(key_label)
			_potion_cd_label = Label.new()
			_potion_cd_label.text = ""
			_potion_cd_label.add_theme_font_size_override("font_size", 16)
			_potion_cd_label.add_theme_color_override("font_color", Color(0.3, 1.0, 0.3, 0.9))
			_potion_cd_label.set_anchors_preset(Control.PRESET_CENTER, false)
			_potion_cd_label.position = Vector2(12, 20)
			_potion_cd_label.size = Vector2(40, 24)
			_potion_cd_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			_potion_cd_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
			slot.add_child(_potion_cd_label)
		else:
			var icon := TextureRect.new()
			icon.texture = spell_icons[i]
			icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			icon.position = Vector2(4, 4)
			icon.size = Vector2(56, 56)
			slot.add_child(icon)
			var key_label := Label.new()
			key_label.text = spell_keys[i]
			key_label.add_theme_font_size_override("font_size", 9)
			key_label.add_theme_color_override("font_color", Color(0.6, 0.5, 0.4, 0.7))
			key_label.position = Vector2(50, 2)
			slot.add_child(key_label)
		_demon_bar.add_child(slot)

	for i in 2:
		var slot := TextureRect.new()
		slot.texture = _slot_frame
		slot.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		slot.size = Vector2(64, 64)
		slot.custom_minimum_size = Vector2(64, 64)
		_demon_slots.append(slot)
		var icon := TextureRect.new()
		icon.texture = demon_icons[i]
		icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icon.position = Vector2(4, 4)
		icon.size = Vector2(56, 56)
		slot.add_child(icon)
		var name_label := Label.new()
		name_label.text = demon_names[i]
		name_label.add_theme_font_size_override("font_size", 9)
		name_label.add_theme_color_override("font_color", Color(0.6, 0.5, 0.4, 0.7))
		name_label.position = Vector2(4, 2)
		slot.add_child(name_label)
		var cd_label := Label.new()
		cd_label.text = ""
		cd_label.add_theme_font_size_override("font_size", 16)
		cd_label.add_theme_color_override("font_color", Color(1, 0.3, 0.3, 0.9))
		cd_label.set_anchors_preset(Control.PRESET_CENTER, false)
		cd_label.position = Vector2(12, 20)
		cd_label.size = Vector2(40, 24)
		cd_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		cd_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		slot.add_child(cd_label)
		_demon_cd_labels.append(cd_label)
		_demon_bar.add_child(slot)

func _build_choice_panel() -> void:
	_choice_panel = Control.new()
	_choice_panel.set_anchors_preset(Control.PRESET_FULL_RECT)
	_choice_panel.visible = false
	var overlay := ColorRect.new()
	overlay.color = Color(0, 0, 0, 0.7)
	overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	_choice_panel.add_child(overlay)
	var panel := PanelContainer.new()
	panel.set_anchors_preset(Control.PRESET_CENTER, false)
	panel.position = Vector2(-180, -100)
	panel.size = Vector2(360, 280)
	var panel_tex := AssetLoader.load_asset("medium/upgrade_panel_360x280.png")
	if panel_tex:
		var panel_bg := StyleBoxTexture.new()
		panel_bg.texture = panel_tex
		panel_bg.modulate_color = Color(1, 1, 1, 0.95)
		panel.add_theme_stylebox_override("panel", panel_bg)
	_choice_panel.add_child(panel)
	var title := Label.new()
	title.text = "ELIGE UN ITEM"
	title.add_theme_font_size_override("font_size", 16)
	title.add_theme_color_override("font_color", Color(0.7, 0.5, 0.9))
	title.set_anchors_preset(Control.PRESET_CENTER, false)
	title.position = Vector2(-80, -90)
	title.size = Vector2(160, 24)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_choice_panel.add_child(title)
	_choice_slots = Control.new()
	_choice_slots.set_anchors_preset(Control.PRESET_FULL_RECT)
	_choice_panel.add_child(_choice_slots)
	add_child(_choice_panel)

	timer_label = Label.new()
	timer_label.text = "0:00"
	timer_label.add_theme_font_size_override("font_size", 22)
	timer_label.add_theme_color_override("font_color", Color(0.9, 0.85, 0.9))
	timer_label.add_theme_color_override("font_shadow_color", Color(0.1, 0.0, 0.1, 0.8))
	timer_label.add_theme_constant_override("shadow_offset_x", 1)
	timer_label.add_theme_constant_override("shadow_offset_y", 1)
	timer_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	timer_label.position = Vector2(get_viewport().size.x * 0.5 - 50, 55)
	timer_label.size = Vector2(100, 25)
	add_child(timer_label)

func _build_item_grid() -> void:
	_item_grid = GridContainer.new()
	_item_grid.columns = 5
	_item_grid.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	_item_grid.position = Vector2(-280, -180)
	_item_grid.size = Vector2(270, 110)
	_item_grid.add_theme_constant_override("h_separation", 4)
	_item_grid.add_theme_constant_override("v_separation", 4)
	add_child(_item_grid)

func _item_color(id: String) -> Color:
	match id:
		"dented_souls":   return Color(0.8, 0.0, 0.0)
		"ghost_projectile":return Color(0.2, 0.4, 0.8)
		"necro_cloud":    return Color(0.4, 0.0, 0.6)
		"blood_heart":    return Color(0.8, 0.0, 0.2)
		"arcane_battery": return Color(1.0, 0.8, 0.0)
		"wind_boots":     return Color(0.2, 0.8, 0.4)
		"shadow_armor":   return Color(0.4, 0.4, 0.6)
		"soul_magnet":    return Color(1.0, 0.6, 0.0)
		"old_grimoire":   return Color(0.6, 0.4, 0.2)
		"xp_gem":         return Color(0.0, 0.8, 1.0)
	return Color(0.3, 0.3, 0.3)

func update_item_grid() -> void:
	if _item_grid == null:
		return
	for child in _item_grid.get_children():
		child.queue_free()
	var cols: Array[String] = ["dented_souls","ghost_projectile","necro_cloud","blood_heart","arcane_battery",
		"wind_boots","shadow_armor","soul_magnet","old_grimoire","xp_gem"]
	for id in cols:
		var lv = _IM.get_level(id) if _IM != null else 0
		var slot := ColorRect.new()
		slot.color = _item_color(id) if lv > 0 else Color(0.1, 0.1, 0.1, 0.4)
		slot.size = Vector2(48, 48)
		slot.custom_minimum_size = Vector2(48, 48)
		_item_grid.add_child(slot)
		var lbl := Label.new()
		lbl.text = str(lv) if lv > 0 else ""
		lbl.add_theme_font_size_override("font_size", 14)
		lbl.add_theme_color_override("font_color", Color.WHITE)
		lbl.add_theme_color_override("font_shadow_color", Color.BLACK)
		lbl.add_theme_constant_override("shadow_outline_size", 1)
		lbl.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
		lbl.position = Vector2(-16, -16)
		lbl.size = Vector2(16, 16)
		lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		slot.add_child(lbl)

func _on_item_chosen(item_id: String) -> void:
	var player := get_parent()
	if player.has_method("apply_upgrade"):
		player.apply_upgrade(item_id)
	_choice_panel.visible = false
	_choice_visible = false
	get_tree().paused = false
	update_item_grid()

func _input(event: InputEvent) -> void:
	if not _choice_visible:
		return
	var keys := ["upgrade_slot_1", "upgrade_slot_2", "upgrade_slot_3"]
	for i in keys.size():
		if event.is_action_pressed(keys[i]) and i < _choice_items.size():
			_on_item_chosen(_choice_items[i])
			update_item_grid()
			return

func _make_upgrade_btn(w: int, h: int, state: String) -> ImageTexture:
	var img := Image.create(w, h, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	var stone := Color(0.12, 0.1, 0.08)
	var edge := Color(0.28, 0.23, 0.18)
	var border := 1
	if state == "hover":
		stone = Color(0.18, 0.12, 0.2)
		edge = Color(0.4, 0.3, 0.35)
	elif state == "pressed":
		stone = Color(0.08, 0.06, 0.05)
		edge = Color(0.2, 0.15, 0.12)
	for y in h:
		for x in w:
			if x < border or x >= w - border or y < border or y >= h - border:
				img.set_pixel(x, y, edge)
			else:
				img.set_pixel(x, y, stone)
	if state == "hover":
		for y in h:
			for x in w:
				if x > border and x < w - border - 1 and y > border and y < h - border - 1:
					var col := img.get_pixel(x, y)
					img.set_pixel(x, y, col.lerp(Color(0.5, 0.15, 0.8, 0.2), 0.4))
	return ImageTexture.create_from_image(img)

func _on_upgrade_chosen(btn: TextureButton) -> void:
	AudioManager.play_click()
	var stat: String = btn.get_meta("stat")
	var player := get_parent()
	if player.has_method("apply_upgrade"):
		player.apply_upgrade(stat)
	_choice_panel.visible = false
	_choice_visible = false
	get_tree().paused = false

func set_souls(current: int, required: int) -> void:
	_soul_label.text = "ALMAS: " + str(current) + "/" + str(required)
	if current >= required:
		_soul_label.add_theme_color_override("font_color", Color(1.0, 0.4, 0.9, 1.0))
		_soul_label.add_theme_color_override("font_shadow_color", Color(0.3, 0.0, 0.5, 0.9))

func set_demon_cooldown(slot: int, seconds: float) -> void:
	if slot < 0 or slot >= _demon_cd_labels.size():
		return
	var label = _demon_cd_labels[slot]
	if seconds <= 0.0:
		label.text = "✓"
		label.add_theme_color_override("font_color", Color(0.3, 1.0, 0.3, 0.9))
	else:
		label.text = str(ceili(seconds))
		label.add_theme_color_override("font_color", Color(1.0, 0.3, 0.3, 0.9))

func _build_damage_vignette() -> void:
	_damage_vignette = TextureRect.new()
	_damage_vignette.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_damage_vignette.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_damage_vignette.stretch_mode = TextureRect.STRETCH_SCALE
	_damage_vignette.modulate = Color(1, 1, 1, 0)
	_damage_vignette.set_anchors_preset(Control.PRESET_FULL_RECT)
	var img := Image.create(256, 256, false, Image.FORMAT_RGBA8)
	for x in 256:
		for y in 256:
			var dx := absf(x - 128) / 128.0
			var dy := absf(y - 128) / 128.0
			var dist := maxf(dx, dy)
			var alpha := clampf((dist - 0.6) / 0.4, 0.0, 0.8)
			img.set_pixel(x, y, Color(1, 0, 0, alpha))
	_damage_vignette.texture = ImageTexture.create_from_image(img)
	add_child(_damage_vignette)

func show_damage_vignette() -> void:
	if not is_inside_tree():
		return
	_damage_vignette.modulate = Color(1, 1, 1, 0.5)
	var tw := create_tween()
	tw.tween_property(_damage_vignette, "modulate:a", 0.0, 0.6)

func set_potion_cooldown(seconds: float) -> void:
	if not is_instance_valid(_potion_cd_label):
		return
	if seconds <= 0.0:
		_potion_cd_label.text = "✓"
		_potion_cd_label.add_theme_color_override("font_color", Color(0.3, 1.0, 0.3, 0.9))
	else:
		_potion_cd_label.text = str(ceili(seconds))
		_potion_cd_label.add_theme_color_override("font_color", Color(1.0, 0.3, 0.3, 0.9))

func set_pentagram_progress(progress: int, total: int) -> void:
	if progress <= 0:
		_pentagram_label.text = ""
		return
	if progress < total:
		AudioManager.play_pentagram_tick()
	else:
		AudioManager.play_pentagram_complete()
	var runes := ""
	for i in total:
		runes += "⬟ " if i < progress else "○ "
	_pentagram_label.text = "PENTAGRAMA: " + runes

func set_element(text: String) -> void:
	element_label.text = text

func set_health(current: float, max_hp: float) -> void:
	hp_bar.max_value = max_hp
	hp_bar.value = current
	hp_label.text = str(ceili(current))

func set_mana(current: float, max_m: float) -> void:
	mp_bar.max_value = max_m
	mp_bar.value = current
	mp_label.text = str(ceili(current))

func set_level(lv: int) -> void:
	level_label.text = "LV " + str(lv)

func set_xp(xp: int, needed: int) -> void:
	AudioManager.play_xp_gain()
	xp_bar.max_value = needed
	xp_label.text = str(xp) + " / " + str(needed) + " XP"
	if xp_bar.has_meta("xp_tween"):
		var old: Tween = xp_bar.get_meta("xp_tween")
		old.kill()
	var tween := create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_SINE)
	tween.tween_property(xp_bar, "value", xp, 0.3)
	xp_bar.set_meta("xp_tween", tween)
	if _xp_floating:
		_xp_floating.text = "+" + str(xp) + " XP"
		_xp_floating.modulate = Color(1, 1, 1, 1)
		var timer := Timer.new()
		timer.one_shot = true
		timer.wait_time = 0.8
		timer.timeout.connect(func():
			if is_instance_valid(_xp_floating):
				var ftween = create_tween()
				ftween.tween_property(_xp_floating, "modulate:a", 0.0, 0.4)
			timer.queue_free()
		)
		add_child(timer)
		timer.start()

func show_level_up(_player: Node = null) -> void:
	if _banner_visible:
		return
	AudioManager.play_level_up()
	_banner_visible = true
	_banner.visible = true
	_banner.scale = Vector2(0.5, 0.5)
	_banner.modulate = Color(1, 1, 1, 0)

	var tween := create_tween().set_parallel()
	tween.tween_property(_banner, "scale", Vector2(1.1, 1.1), 0.3).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	tween.tween_property(_banner, "modulate", Color(1, 1, 1, 1), 0.3)
	tween.chain().tween_property(_banner, "scale", Vector2(1.0, 1.0), 0.1).set_ease(Tween.EASE_IN)
	tween.tween_property(_banner_label, "modulate", Color(1, 1, 1, 1), 0.3)

	await get_tree().create_timer(2.0).timeout
	var fade_tween := create_tween()
	fade_tween.tween_property(_banner, "modulate", Color(1, 1, 1, 0), 0.4)
	await fade_tween.finished
	_banner.visible = false
	_banner_visible = false
	update_item_grid()

	if _player and _player.has_method("apply_upgrade"):
		await get_tree().create_timer(0.3).timeout
		_refresh_choice_items()
		get_tree().paused = true
		_choice_panel.visible = true
		_choice_visible = true

func show_event_banner(text: String, color: Color) -> void:
	if _banner_visible:
		return
	_banner_visible = true
	if _banner_label == null:
		return
	_banner_label.text = text
	_banner_label.add_theme_color_override("font_color", color)
	_banner.visible = true
	_banner.scale = Vector2(0.5, 0.5)
	_banner.modulate = Color(1, 1, 1, 0)
	var tween := create_tween().set_parallel()
	tween.tween_property(_banner, "scale", Vector2(1.2, 1.2), 0.3).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	tween.tween_property(_banner, "modulate", Color(1, 1, 1, 1), 0.3)
	tween.chain().tween_property(_banner, "scale", Vector2(1.0, 1.0), 0.1)
	await get_tree().create_timer(3.0).timeout
	var fade_tween := create_tween()
	fade_tween.tween_property(_banner, "modulate", Color(1, 1, 1, 0), 0.4)
	await fade_tween.finished
	_banner.visible = false
	_banner_visible = false

func set_timer(elapsed: float, total: float) -> void:
	var mins = int(elapsed) / 60
	var secs = int(elapsed) % 60
	timer_label.text = str(mins) + ":" + str(secs).pad_zeros(2)
	var remaining = maxf(total - elapsed, 0.0)
	if remaining < 60.0:
		timer_label.add_theme_color_override("font_color", Color(1.0, 0.2, 0.1))

func _make_xp_fill(w: int, h: int) -> ImageTexture:
	var img := Image.create(w, h, false, Image.FORMAT_RGBA8)
	for y in h:
		for x in w:
			if y < 1 or y >= h - 1:
				img.set_pixel(x, y, Color(0, 0, 0, 0))
			else:
				var t = float(x) / w
				var r = 0.5 + 0.2 * sin(t * PI)
				var col = Color(r * 0.9, r * 0.15, r * 0.7, 0.95)
				img.set_pixel(x, y, col)
	return ImageTexture.create_from_image(img)

func _make_xp_frame(w: int, h: int) -> ImageTexture:
	var img := Image.create(w, h, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	for y in h:
		for x in w:
			if x < 1 or x >= w - 1 or y < 1 or y >= h - 1:
				img.set_pixel(x, y, Color(0.25, 0.15, 0.3, 0.9))
			elif y == 2 or y == h - 3:
				img.set_pixel(x, y, Color(0.4, 0.25, 0.5, 0.5))
	return ImageTexture.create_from_image(img)

func _refresh_choice_items() -> void:
	if _IM == null:
		return
	var all_ids: Array = _IM.ITEMS.keys()
	var available: Array[String] = []
	for id in all_ids:
		if _IM.get_level(id) < _IM.ITEMS[id]["max_lv"]:
			available.append(id)
	if available.is_empty():
		available = all_ids.duplicate()
	available.shuffle()
	_choice_items = available.slice(0, 3)
	for i in _choice_items.size():
		var id = _choice_items[i]
		var info = _IM.ITEMS[id]
		var cur_lv = _IM.get_level(id)
		var lv_text = "Nv." + str(cur_lv) + " → " + str(cur_lv + 1) if cur_lv > 0 else "Nuevo"
		var display = info["name"] + " (" + lv_text + ")"
		var col := Color(0.9, 0.4, 0.0) if info["type"] == "weapon" else Color(0.3, 0.7, 1.0)
		var btn := TextureButton.new()
		btn.texture_normal = AssetLoader.load_asset("buttons/upgrade_320x50_normal.png", func(): return _make_upgrade_btn(320, 50, "normal"))
		btn.texture_hover = AssetLoader.load_asset("buttons/upgrade_320x50_hover.png", func(): return _make_upgrade_btn(320, 50, "hover"))
		btn.texture_pressed = AssetLoader.load_asset("buttons/upgrade_320x50_pressed.png", func(): return _make_upgrade_btn(320, 50, "pressed"))
		btn.size = Vector2(320, 50)
		btn.custom_minimum_size = Vector2(320, 50)
		btn.set_anchors_preset(Control.PRESET_CENTER, false)
		btn.position = Vector2(-160, -55 + i * 58)
		btn.set_meta("item_id", id)
		btn.pressed.connect(_on_item_chosen.bind(id))
		btn.mouse_entered.connect(AudioManager.play_hover)
		_choice_slots.add_child(btn)
		var lbl := Label.new()
		lbl.text = display
		lbl.add_theme_font_size_override("font_size", 14)
		lbl.add_theme_color_override("font_color", col)
		lbl.set_anchors_preset(Control.PRESET_CENTER, false)
		lbl.position = Vector2(-140, -55 + i * 58 + 3)
		lbl.size = Vector2(280, 18)
		_choice_slots.add_child(lbl)
		var dsc := Label.new()
		dsc.text = info["desc"]
		dsc.add_theme_font_size_override("font_size", 10)
		dsc.add_theme_color_override("font_color", Color(0.6, 0.5, 0.7))
		dsc.set_anchors_preset(Control.PRESET_CENTER, false)
		dsc.position = Vector2(-140, -55 + i * 58 + 22)
		dsc.size = Vector2(280, 14)
		_choice_slots.add_child(dsc)
