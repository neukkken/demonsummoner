extends CanvasLayer

# ==============================================================================
# HUD GÓTICO PROFESIONAL (GOTHIC ARPG HUD)
# Demon Summoner — Tipografía Cinzel, Orbes de Cristal, Relicario y Modal Arcano
# ==============================================================================

var hp_bar: TextureProgressBar
var mp_bar: TextureProgressBar
var hp_label: Label
var mp_label: Label
var hp_badge: Label
var mp_badge: Label

var element_label: Label
var level_label: Label
var xp_bar: TextureProgressBar
var xp_label: Label
var _xp_floating: Label = null

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
var _choice_slots: Control = null
var _choice_card_btns: Array[TextureButton] = []

var _item_grid: GridContainer = null
var _IM = null

var _soul_label: Label
var _pentagram_label: Label
var timer_label: Label
var _damage_vignette: TextureRect

# Tipografías góticas auténticas
var _font_cinzel_dec: FontFile = null
var _font_cinzel: FontFile = null

func _ready() -> void:
	process_mode = PROCESS_MODE_ALWAYS
	_IM = get_node_or_null("/root/ItemManager")
	_cargar_fuentes()
	_generate_textures()
	_build_ui()
	DatosJuego.alma_cosechada.connect(set_souls)
	get_viewport().size_changed.connect(_on_viewport_resized)

func _cargar_fuentes() -> void:
	if ResourceLoader.exists("res://fonts/CinzelDecorative-Bold.ttf"):
		_font_cinzel_dec = load("res://fonts/CinzelDecorative-Bold.ttf")
	if ResourceLoader.exists("res://fonts/Cinzel.ttf"):
		_font_cinzel = load("res://fonts/Cinzel.ttf")

func _aplicar_fuente(lbl: Label, is_decorative: bool, size: int, color: Color, shadow_col: Color = Color(0.04, 0.02, 0.06, 0.9), shadow_size: int = 2) -> void:
	var f = _font_cinzel_dec if is_decorative else _font_cinzel
	if f:
		lbl.add_theme_font_override("font", f)
	lbl.add_theme_font_size_override("font_size", size)
	lbl.add_theme_color_override("font_color", color)
	if shadow_col.a > 0.0:
		lbl.add_theme_color_override("font_shadow_color", shadow_col)
		lbl.add_theme_constant_override("shadow_outline_size", shadow_size)
		lbl.add_theme_constant_override("shadow_offset_x", 1)
		lbl.add_theme_constant_override("shadow_offset_y", 1)

func _on_viewport_resized() -> void:
	if is_instance_valid(timer_label):
		timer_label.position = Vector2(get_viewport().size.x * 0.5 - 60, 48)

# ------------------------------------------------------------------------------
# GENERACIÓN DE TEXTURAS PROCEDURALES GÓTICAS DE ALTA RESOLUCIÓN
# ------------------------------------------------------------------------------
func _generate_textures() -> void:
	_hp_fill = AssetLoader.load_asset("high/gothic_globe_hp_fill_100.png", func(): return _make_globe_fill(100, Color(0.85, 0.08, 0.08)))
	_mp_fill = AssetLoader.load_asset("high/gothic_globe_mp_fill_100.png", func(): return _make_globe_fill(100, Color(0.12, 0.35, 0.95)))
	_hp_frame = AssetLoader.load_asset("high/gothic_globe_hp_frame_100.png", func(): return _make_globe_frame(100, false))
	_mp_frame = AssetLoader.load_asset("high/gothic_globe_mp_frame_100.png", func(): return _make_globe_frame(100, true))
	_slot_frame = AssetLoader.load_asset("high/gothic_slot_frame_64.png", func(): return _make_slot_frame(64))
	_reticle = AssetLoader.load_asset("critical/gothic_crosshair_48.png", func(): return _make_gothic_reticle(48))
	_banner_tex = AssetLoader.load_asset("high/gothic_banner_440x120.png", func(): return _make_banner(440, 120))
	_xp_fill = AssetLoader.load_asset("high/gothic_xp_fill_380x16.png", func(): return _make_xp_fill(380, 16))
	_xp_frame = AssetLoader.load_asset("high/gothic_xp_frame_380x16.png", func(): return _make_xp_frame(380, 16))

	_icon_fireball = AssetLoader.load_asset("critical/icon_fireball_56.png", func(): return _make_icon_fireball(56))
	_icon_icewall = AssetLoader.load_asset("critical/icon_icewall_56.png", func(): return _make_icon_icewall(56))
	_icon_icelance = AssetLoader.load_asset("critical/icon_icelance_56.png", func(): return _make_icon_icelance(56))
	_icon_blackhole = AssetLoader.load_asset("critical/icon_blackhole_56.png", func(): return _make_icon_blackhole(56))
	_icon_segador = AssetLoader.load_asset("critical/icon_segador_56.png", func(): return _make_icon_segador(56))
	_icon_devorador = AssetLoader.load_asset("critical/icon_devorador_56.png", func(): return _make_icon_devorador(56))
	_icon_potion = AssetLoader.load_asset("critical/icon_potion_56.png", func(): return _make_icon_potion(56))

func _make_globe_fill(size: int, base_col: Color) -> ImageTexture:
	var img := Image.create(size, size, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	var cx := size / 2
	var cy := size / 2
	var r := float(size / 2 - 8)

	for y in size:
		for x in size:
			var dx := float(x - cx)
			var dy := float(y - cy)
			var dist_sq := dx * dx + dy * dy
			if dist_sq <= r * r:
				var dist := sqrt(dist_sq)
				var nx := dx / r
				var ny := dy / r
				var nz := sqrt(maxf(0.0, 1.0 - (nx * nx + ny * ny)))

				# Gradiente líquido esférico
				var depth_factor := 0.65 + 0.35 * (1.0 - dist / r)
				var bottom_shade := 0.8 + 0.2 * ny # Más oscuro arriba, más denso abajo
				var col := base_col * depth_factor * bottom_shade

				# Reflejo especular curvo de cristal en cuadrante superior izquierdo
				var spec_dx := dx + r * 0.32
				var spec_dy := dy + r * 0.32
				var spec_dist := sqrt(spec_dx * spec_dx + spec_dy * spec_dy)
				if spec_dist < r * 0.45:
					var spec_intensity := (1.0 - spec_dist / (r * 0.45)) * 0.55
					col = col.lerp(Color(1.0, 1.0, 1.0), spec_intensity)

				# Halo interior en el borde de la esfera
				var edge_glow := pow(dist / r, 3.0) * 0.25
				col = col.lerp(base_col.lightened(0.3), edge_glow)
				col.a = 0.94
				img.set_pixel(x, y, col)

	return ImageTexture.create_from_image(img)

func _make_globe_frame(size: int, is_mana: bool) -> ImageTexture:
	var img := Image.create(size, size, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	var cx := size / 2
	var cy := size / 2
	var r_outer := float(size / 2 - 2)
	var r_inner := r_outer - 7.0

	var gold_bright := Color(0.85, 0.70, 0.25)
	var gold_dark := Color(0.40, 0.30, 0.12)
	var bronze := Color(0.28, 0.20, 0.14)
	var iron := Color(0.12, 0.10, 0.14)

	for y in size:
		for x in size:
			var dx := float(x - cx)
			var dy := float(y - cy)
			var dist := sqrt(dx * dx + dy * dy)

			# Anillo biselado metálico
			if dist >= r_inner and dist <= r_outer:
				var t := (dist - r_inner) / (r_outer - r_inner)
				var angle := atan2(dy, dx)
				var facet := sin(angle * 8.0) * 0.5 + 0.5
				var base_m := gold_dark.lerp(gold_bright, facet * 0.4 + 0.3)
				var rim_col := base_m.lerp(bronze, t)
				if dist > r_outer - 1.2:
					rim_col = iron
				img.set_pixel(x, y, rim_col)

			# Garfios / Claws góticos en las 4 diagonales
			var d_diag := absf(absf(dx) - absf(dy))
			if dist >= r_inner - 3.0 and dist <= r_outer + 2.0 and d_diag < 3.5:
				img.set_pixel(x, y, gold_bright)

	# Adornos de alas de gárgola a los costados
	for side in [-1, 1]:
		for i in 4:
			var angle := PI * 0.5 - 0.35 + i * 0.25
			var bx: float = cx + cos(angle) * r_outer * side
			var by: float = cy - sin(angle) * r_outer * 0.55
			for j in 3:
				var px := int(bx + side * j * 2)
				var py := int(by + j)
				if px >= 0 and px < size and py >= 0 and py < size:
					var wing_col = Color(0.45, 0.22, 0.55) if is_mana else Color(0.65, 0.30, 0.15)
					img.set_pixel(px, py, wing_col)

	return ImageTexture.create_from_image(img)

func _make_slot_frame(s: int) -> ImageTexture:
	var img := Image.create(s, s, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	var stone_bg := Color(0.08, 0.07, 0.09, 0.95)
	var gold_border := Color(0.68, 0.52, 0.22)
	var gold_bright := Color(0.92, 0.78, 0.38)
	var inner_shadow := Color(0.04, 0.03, 0.05, 0.8)

	for y in s:
		for x in s:
			var d_edge = mini(mini(x, s - 1 - x), mini(y, s - 1 - y))
			if d_edge == 0:
				img.set_pixel(x, y, Color(0.12, 0.10, 0.14)) # Borde oscuro
			elif d_edge <= 2:
				img.set_pixel(x, y, gold_border) # Borde dorado
			elif d_edge == 3:
				img.set_pixel(x, y, inner_shadow)
			else:
				img.set_pixel(x, y, stone_bg)

	# Biseles ornamentales de flor de lis / esquinas de reliquia
	var corners = [[2, 2], [s - 4, 2], [2, s - 4], [s - 4, s - 4]]
	for c in corners:
		for j in 3:
			for k in 3:
				var px: int = c[0] + j
				var py: int = c[1] + k
				if px >= 0 and px < s and py >= 0 and py < s:
					img.set_pixel(px, py, gold_bright)

	return ImageTexture.create_from_image(img)

func _make_xp_fill(w: int, h: int) -> ImageTexture:
	var img := Image.create(w, h, false, Image.FORMAT_RGBA8)
	var purple_dark := Color(0.35, 0.05, 0.55, 0.95)
	var purple_bright := Color(0.85, 0.30, 1.0, 0.98)
	var core_white := Color(0.95, 0.80, 1.0, 0.98)

	for y in h:
		for x in w:
			if y < 1 or y >= h - 1:
				img.set_pixel(x, y, Color(0, 0, 0, 0))
			else:
				var ny = float(y) / float(h)
				var center_dist = absf(ny - 0.5) * 2.0
				var col = purple_bright.lerp(purple_dark, center_dist)
				if center_dist < 0.25:
					col = col.lerp(core_white, (1.0 - center_dist / 0.25) * 0.45)
				img.set_pixel(x, y, col)

	return ImageTexture.create_from_image(img)

func _make_xp_frame(w: int, h: int) -> ImageTexture:
	var img := Image.create(w, h, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	var gold := Color(0.72, 0.58, 0.24)
	var dark := Color(0.08, 0.06, 0.10)

	for y in h:
		for x in w:
			if x == 0 or x == w - 1 or y == 0 or y == h - 1:
				img.set_pixel(x, y, gold)
			elif y == 1 or y == h - 2:
				img.set_pixel(x, y, dark)

	# Marcadores de hitos a 25%, 50%, 75%
	for frac in [0.25, 0.5, 0.75]:
		var mx = int(w * frac)
		for y in range(0, h):
			img.set_pixel(mx, y, gold)

	return ImageTexture.create_from_image(img)

func _make_banner(w: int, h: int) -> ImageTexture:
	var img := Image.create(w, h, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	var stone := Color(0.08, 0.06, 0.10, 0.92)
	var gold := Color(0.75, 0.60, 0.22)
	var bright := Color(0.95, 0.82, 0.45)

	for y in h:
		for x in w:
			var nx := float(x) / float(w)
			var ny := float(y) / float(h)
			var d_edge = mini(mini(x, w - 1 - x), mini(y, h - 1 - y))

			if d_edge < 2:
				img.set_pixel(x, y, gold)
			elif d_edge < 4:
				img.set_pixel(x, y, bright)
			else:
				img.set_pixel(x, y, stone)

	return ImageTexture.create_from_image(img)

func _make_gothic_reticle(s: int) -> ImageTexture:
	var img := Image.create(s, s, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	var cx := s / 2
	var cy := s / 2
	var outer_r := s / 2 - 2
	var inner_gap := 5
	var metal := Color(0.9, 0.85, 0.7, 0.85)

	for y in s:
		for x in s:
			var dx := x - cx
			var dy := y - cy
			var dist := sqrt(float(dx * dx + dy * dy))

			# Anillo sutil exterior
			if absf(dist - outer_r) < 1.0:
				img.set_pixel(x, y, Color(metal.r, metal.g, metal.b, 0.5))

			# Mirilla de cruz con hueco central limpio
			var ax := absi(dx)
			var ay := absi(dy)
			if (ax == 0 and ay >= inner_gap and ay <= outer_r) or (ay == 0 and ax >= inner_gap and ax <= outer_r):
				img.set_pixel(x, y, metal)

			# Punto central brillante diminuto
			if dist <= 1.2:
				img.set_pixel(x, y, Color(1.0, 0.95, 0.85, 0.95))

	return ImageTexture.create_from_image(img)

func _make_icon_fireball(s: int) -> ImageTexture:
	var img := Image.create(s, s, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	var cx := s / 2
	var cy := s / 2
	var r := s / 2 - 4
	for y in s:
		for x in s:
			var dx := x - cx
			var dy := y - cy
			var dist := sqrt(float(dx * dx + dy * dy))
			if dist <= r:
				var t := dist / r
				var col = Color(1.0, 0.85, 0.2).lerp(Color(0.85, 0.15, 0.05), t)
				col.a = 0.95
				img.set_pixel(x, y, col)
	return ImageTexture.create_from_image(img)

func _make_icon_icewall(s: int) -> ImageTexture:
	var img := Image.create(s, s, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	var cx := s / 2
	var cy := s / 2
	var r := s / 2 - 4
	for y in s:
		for x in s:
			var dx := x - cx
			var dy := y - cy
			var dist := sqrt(float(dx * dx + dy * dy))
			if dist <= r:
				var t := dist / r
				var col = Color(0.8, 0.95, 1.0).lerp(Color(0.1, 0.45, 0.85), t)
				col.a = 0.95
				img.set_pixel(x, y, col)
	return ImageTexture.create_from_image(img)

func _make_icon_icelance(s: int) -> ImageTexture:
	var img := Image.create(s, s, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	var cx := s / 2
	var cy := s / 2
	var r := s / 2 - 4
	for y in s:
		for x in s:
			var dx := x - cx
			var dy := y - cy
			var dist := sqrt(float(dx * dx + dy * dy))
			if dist <= r:
				var t := dist / r
				var col = Color(0.9, 0.98, 1.0).lerp(Color(0.15, 0.6, 0.9), t)
				col.a = 0.95
				img.set_pixel(x, y, col)
	return ImageTexture.create_from_image(img)

func _make_icon_blackhole(s: int) -> ImageTexture:
	var img := Image.create(s, s, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	var cx := s / 2
	var cy := s / 2
	var r := s / 2 - 4
	for y in s:
		for x in s:
			var dx := x - cx
			var dy := y - cy
			var dist := sqrt(float(dx * dx + dy * dy))
			if dist <= r:
				var t := dist / r
				var col = Color(0.05, 0.0, 0.08).lerp(Color(0.65, 0.15, 0.85), t)
				col.a = 0.95
				img.set_pixel(x, y, col)
	return ImageTexture.create_from_image(img)

func _make_icon_segador(s: int) -> ImageTexture:
	var img := Image.create(s, s, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	var cx := s / 2
	var cy := s / 2
	var r := s / 2 - 4
	for y in s:
		for x in s:
			var dx := x - cx
			var dy := y - cy
			var dist := sqrt(float(dx * dx + dy * dy))
			if dist <= r:
				var t := dist / r
				var col = Color(0.9, 0.1, 0.1).lerp(Color(0.2, 0.02, 0.04), t)
				col.a = 0.95
				img.set_pixel(x, y, col)
	return ImageTexture.create_from_image(img)

func _make_icon_devorador(s: int) -> ImageTexture:
	var img := Image.create(s, s, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	var cx := s / 2
	var cy := s / 2
	var r := s / 2 - 4
	for y in s:
		for x in s:
			var dx := x - cx
			var dy := y - cy
			var dist := sqrt(float(dx * dx + dy * dy))
			if dist <= r:
				var t := dist / r
				var col = Color(0.75, 0.2, 0.95).lerp(Color(0.12, 0.02, 0.18), t)
				col.a = 0.95
				img.set_pixel(x, y, col)
	return ImageTexture.create_from_image(img)

func _make_icon_potion(s: int) -> ImageTexture:
	var img := Image.create(s, s, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	var cx := s / 2
	var cy := s / 2
	var r := s / 2 - 4
	for y in s:
		for x in s:
			var dx := x - cx
			var dy := y - cy
			var dist := sqrt(float(dx * dx + dy * dy))
			if dist <= r:
				var t := dist / r
				var col = Color(0.2, 0.85, 0.35).lerp(Color(0.05, 0.25, 0.1), t)
				col.a = 0.95
				img.set_pixel(x, y, col)
	return ImageTexture.create_from_image(img)

# ------------------------------------------------------------------------------
# CONSTRUCCIÓN DE LA INTERFAZ DE USUARIO (HUD)
# ------------------------------------------------------------------------------
func _build_ui() -> void:
	var margin := 24
	var globe_size := 100

	# 1. Orbe de Vida (Health Globe)
	hp_bar = TextureProgressBar.new()
	hp_bar.texture_progress = _hp_fill
	hp_bar.texture_over = _hp_frame
	hp_bar.fill_mode = 5
	hp_bar.value = 100.0
	hp_bar.max_value = 100.0
	hp_bar.position = Vector2(margin, margin)
	hp_bar.size = Vector2(globe_size, globe_size)
	add_child(hp_bar)

	hp_badge = Label.new()
	hp_badge.text = "HP"
	_aplicar_fuente(hp_badge, true, 11, Color(0.85, 0.65, 0.35))
	hp_badge.position = Vector2(margin + 41, margin + 22)
	hp_badge.size = Vector2(20, 14)
	hp_badge.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	add_child(hp_badge)

	hp_label = Label.new()
	hp_label.text = "100"
	_aplicar_fuente(hp_label, false, 16, Color(1.0, 0.92, 0.92), Color(0.3, 0.0, 0.0, 0.95), 2)
	hp_label.position = Vector2(margin + 20, margin + 38)
	hp_label.size = Vector2(60, 24)
	hp_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	add_child(hp_label)

	# 2. Orbe de Maná (Mana Globe)
	mp_bar = TextureProgressBar.new()
	mp_bar.texture_progress = _mp_fill
	mp_bar.texture_over = _mp_frame
	mp_bar.fill_mode = 5
	mp_bar.value = 100.0
	mp_bar.max_value = 100.0
	mp_bar.position = Vector2(margin, margin + globe_size + 14)
	mp_bar.size = Vector2(globe_size, globe_size)
	add_child(mp_bar)

	mp_badge = Label.new()
	mp_badge.text = "MP"
	_aplicar_fuente(mp_badge, true, 11, Color(0.55, 0.75, 1.0))
	mp_badge.position = Vector2(margin + 40, margin + globe_size + 14 + 22)
	mp_badge.size = Vector2(20, 14)
	mp_badge.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	add_child(mp_badge)

	mp_label = Label.new()
	mp_label.text = "100"
	_aplicar_fuente(mp_label, false, 16, Color(0.9, 0.95, 1.0), Color(0.0, 0.1, 0.35, 0.95), 2)
	mp_label.position = Vector2(margin + 20, margin + globe_size + 14 + 38)
	mp_label.size = Vector2(60, 24)
	mp_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	add_child(mp_label)

	# 3. Estado de Elemento, Almas y Pentagrama
	var stats_y = margin + globe_size * 2 + 28

	element_label = Label.new()
	element_label.text = "ELEMENTO: NINGUNO"
	_aplicar_fuente(element_label, true, 12, Color(0.85, 0.70, 0.35))
	element_label.position = Vector2(margin + 4, stats_y)
	add_child(element_label)

	_soul_label = Label.new()
	_soul_label.text = "✦ ALMAS: 0/" + str(DatosJuego.REQUISITO_DEVORADOR)
	_aplicar_fuente(_soul_label, true, 12, Color(0.82, 0.45, 1.0), Color(0.2, 0.05, 0.3, 0.9), 2)
	_soul_label.position = Vector2(margin + 4, stats_y + 20)
	add_child(_soul_label)

	_pentagram_label = Label.new()
	_pentagram_label.text = ""
	_aplicar_fuente(_pentagram_label, true, 12, Color(1.0, 0.4, 0.9), Color(0.3, 0.0, 0.3, 0.9), 2)
	_pentagram_label.position = Vector2(margin + 4, stats_y + 40)
	add_child(_pentagram_label)

	# 4. Barra Superior de Nivel y Experiencia
	level_label = Label.new()
	level_label.text = "NV 1"
	_aplicar_fuente(level_label, true, 14, Color(1.0, 0.88, 0.45))
	level_label.set_anchors_preset(Control.PRESET_CENTER_TOP, false)
	level_label.position = Vector2(-250, 16)
	level_label.size = Vector2(50, 20)
	level_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	add_child(level_label)

	xp_bar = TextureProgressBar.new()
	xp_bar.value = 0
	xp_bar.max_value = 50
	xp_bar.texture_progress = _xp_fill
	xp_bar.texture_over = _xp_frame
	xp_bar.fill_mode = 0
	xp_bar.size = Vector2(380, 16)
	xp_bar.set_anchors_preset(Control.PRESET_CENTER_TOP, false)
	xp_bar.position = Vector2(-190, 18)
	add_child(xp_bar)

	xp_label = Label.new()
	xp_label.text = "0 / 50 XP"
	_aplicar_fuente(xp_label, false, 11, Color(0.85, 0.80, 0.92))
	xp_label.set_anchors_preset(Control.PRESET_CENTER_TOP, false)
	xp_label.position = Vector2(200, 17)
	xp_label.size = Vector2(100, 18)
	xp_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	add_child(xp_label)

	_xp_floating = Label.new()
	_xp_floating.text = ""
	_aplicar_fuente(_xp_floating, true, 15, Color(1.0, 0.92, 0.45), Color(0.3, 0.2, 0.0, 0.95), 2)
	_xp_floating.set_anchors_preset(Control.PRESET_CENTER_TOP, false)
	_xp_floating.position = Vector2(20, 38)
	_xp_floating.size = Vector2(100, 20)
	add_child(_xp_floating)

	# 5. Reloj / Cronómetro Central
	timer_label = Label.new()
	timer_label.text = "0:00"
	_aplicar_fuente(timer_label, false, 24, Color(0.92, 0.90, 0.95), Color(0.05, 0.02, 0.08, 0.95), 3)
	timer_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	timer_label.position = Vector2(get_viewport().size.x * 0.5 - 60, 48)
	timer_label.size = Vector2(120, 30)
	add_child(timer_label)

	# 6. Retícula / Mirilla Gótica
	var reticle_node := TextureRect.new()
	reticle_node.texture = _reticle
	reticle_node.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	reticle_node.size = Vector2(48, 48)
	reticle_node.set_anchors_preset(Control.PRESET_CENTER, false)
	reticle_node.position = -reticle_node.size * 0.5
	add_child(reticle_node)

	# 7. Banner de Subida de Nivel / Eventos
	_banner = Control.new()
	_banner.set_anchors_preset(Control.PRESET_CENTER, false)
	_banner.position = Vector2(-220, -110)
	_banner.size = Vector2(440, 120)
	_banner.visible = false

	var banner_bg := TextureRect.new()
	banner_bg.texture = _banner_tex
	banner_bg.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	banner_bg.size = Vector2(440, 120)
	_banner.add_child(banner_bg)

	_banner_label = Label.new()
	_banner_label.text = "✦ ¡SUBISTE DE NIVEL! ✦"
	_aplicar_fuente(_banner_label, true, 22, Color(1.0, 0.88, 0.45), Color(0.2, 0.05, 0.25, 0.95), 3)
	_banner_label.position = Vector2(0, 44)
	_banner_label.size = Vector2(440, 32)
	_banner_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_banner.add_child(_banner_label)

	add_child(_banner)

	# 8. Componentes Clave
	_build_demon_bar()
	_build_choice_panel()
	_build_item_grid()
	_build_damage_vignette()

# ------------------------------------------------------------------------------
# RELICARIO INFERIOR: BARRA DE HECHIZOS Y DEMONIOS
# ------------------------------------------------------------------------------
func _build_demon_bar() -> void:
	var spell_icons := [_icon_potion, _icon_fireball, _icon_icewall, _icon_icelance]
	var spell_keys := ["1", "2", "3", "4"]
	var demon_names := ["SEGADOR", "DEVORADOR"]
	var demon_icons := [_icon_segador, _icon_devorador]

	_demon_bar = HBoxContainer.new()
	_demon_bar.set_anchors_preset(Control.PRESET_CENTER_BOTTOM, false)
	_demon_bar.position = Vector2(-235, -90)
	_demon_bar.size = Vector2(470, 72)
	_demon_bar.add_theme_constant_override("separation", 10)
	add_child(_demon_bar)

	# 4 Ranuras de Hechizos / Poción
	for i in 4:
		var slot := TextureRect.new()
		slot.texture = _slot_frame
		slot.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		slot.size = Vector2(64, 64)
		slot.custom_minimum_size = Vector2(64, 64)

		var icon := TextureRect.new()
		icon.texture = spell_icons[i]
		icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icon.position = Vector2(4, 4)
		icon.size = Vector2(56, 56)
		slot.add_child(icon)

		var key_label := Label.new()
		key_label.text = spell_keys[i]
		_aplicar_fuente(key_label, true, 10, Color(0.9, 0.78, 0.35))
		key_label.position = Vector2(48, 3)
		slot.add_child(key_label)

		if i == 0:
			_potion_cd_label = Label.new()
			_potion_cd_label.text = ""
			_aplicar_fuente(_potion_cd_label, false, 18, Color(0.3, 1.0, 0.4), Color(0.0, 0.3, 0.05, 0.95), 2)
			_potion_cd_label.position = Vector2(8, 20)
			_potion_cd_label.size = Vector2(48, 24)
			_potion_cd_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			slot.add_child(_potion_cd_label)

		_demon_bar.add_child(slot)

	# 2 Ranuras de Invocación Demoníaca
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
		_aplicar_fuente(name_label, true, 8, Color(0.85, 0.55, 0.95))
		name_label.position = Vector2(4, 2)
		slot.add_child(name_label)

		var cd_label := Label.new()
		cd_label.text = ""
		_aplicar_fuente(cd_label, false, 18, Color(1.0, 0.3, 0.3), Color(0.3, 0.0, 0.0, 0.95), 2)
		cd_label.position = Vector2(8, 20)
		cd_label.size = Vector2(48, 24)
		cd_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		slot.add_child(cd_label)
		_demon_cd_labels.append(cd_label)

		_demon_bar.add_child(slot)

# ------------------------------------------------------------------------------
# MODAL GÓTICO DE ELECCIÓN DE MEJORAS (UPGRADE MODAL)
# ------------------------------------------------------------------------------
func _build_choice_panel() -> void:
	_choice_panel = Control.new()
	_choice_panel.set_anchors_preset(Control.PRESET_FULL_RECT)
	_choice_panel.visible = false

	# Velo oscuro con ligero tinte amatista
	var overlay := ColorRect.new()
	overlay.color = Color(0.03, 0.02, 0.05, 0.88)
	overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	_choice_panel.add_child(overlay)

	# Contenedor central del modal
	var modal_box := Control.new()
	modal_box.set_anchors_preset(Control.PRESET_CENTER, false)
	modal_box.position = Vector2(-260, -180)
	modal_box.size = Vector2(520, 360)
	_choice_panel.add_child(modal_box)

	# Título gótico con alas ceremoniales
	var title := Label.new()
	title.text = "✦ ELEGIR BENDICIÓN ARCANO ✦"
	_aplicar_fuente(title, true, 20, Color(1.0, 0.88, 0.45), Color(0.2, 0.05, 0.25, 0.95), 3)
	title.position = Vector2(0, 0)
	title.size = Vector2(520, 28)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	modal_box.add_child(title)

	var subtitle := Label.new()
	subtitle.text = "Selecciona una reliquia para fortalecer tu alma contra la horda"
	_aplicar_fuente(subtitle, false, 11, Color(0.70, 0.62, 0.78))
	subtitle.position = Vector2(0, 30)
	subtitle.size = Vector2(520, 18)
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	modal_box.add_child(subtitle)

	# Contenedor dinámico de las 3 cartas
	_choice_slots = Control.new()
	_choice_slots.position = Vector2(0, 60)
	_choice_slots.size = Vector2(520, 300)
	modal_box.add_child(_choice_slots)

	add_child(_choice_panel)

func _make_card_texture(w: int, h: int, state: String) -> ImageTexture:
	var img := Image.create(w, h, false, Image.FORMAT_RGBA8)
	var bg_col := Color(0.09, 0.07, 0.12, 0.96)
	var border_col := Color(0.55, 0.42, 0.18)
	var corner_col := Color(0.85, 0.70, 0.30)

	if state == "hover":
		bg_col = Color(0.18, 0.12, 0.24, 0.98)
		border_col = Color(0.92, 0.78, 0.38)
		corner_col = Color(1.0, 0.92, 0.55)
	elif state == "pressed":
		bg_col = Color(0.06, 0.04, 0.08, 0.98)
		border_col = Color(0.40, 0.30, 0.12)

	for y in h:
		for x in w:
			var d = mini(mini(x, w - 1 - x), mini(y, h - 1 - y))
			if d == 0:
				img.set_pixel(x, y, Color(0.05, 0.03, 0.07))
			elif d <= 2:
				img.set_pixel(x, y, border_col)
			else:
				img.set_pixel(x, y, bg_col)

	# Esquinas ornamentales doradas
	var corners = [[2, 2], [w - 5, 2], [2, h - 5], [w - 5, h - 5]]
	for c in corners:
		for j in 4:
			for k in 4:
				var px = c[0] + j
				var py = c[1] + k
				if px >= 0 and px < w and py >= 0 and py < h:
					img.set_pixel(px, py, corner_col)

	return ImageTexture.create_from_image(img)

func _refresh_choice_items() -> void:
	if _IM == null:
		return

	# Limpiar cartas anteriores
	for child in _choice_slots.get_children():
		child.queue_free()
	_choice_card_btns.clear()

	var all_ids: Array = _IM.ITEMS.keys()
	var available: Array[String] = []
	for id in all_ids:
		if _IM.get_level(id) < _IM.ITEMS[id]["max_lv"]:
			available.append(id)
	if available.is_empty():
		available = all_ids.duplicate()
	available.shuffle()
	_choice_items = available.slice(0, 3)

	var card_w := 500
	var card_h := 74
	var card_sep := 14

	for i in _choice_items.size():
		var id = _choice_items[i]
		var info = _IM.ITEMS[id]
		var cur_lv = _IM.get_level(id)
		var is_weapon: bool = info["type"] == "weapon"

		var btn := TextureButton.new()
		btn.texture_normal = AssetLoader.load_asset("cards/card_500x74_normal.png", func(): return _make_card_texture(500, 74, "normal"))
		btn.texture_hover = AssetLoader.load_asset("cards/card_500x74_hover.png", func(): return _make_card_texture(500, 74, "hover"))
		btn.texture_pressed = AssetLoader.load_asset("cards/card_500x74_pressed.png", func(): return _make_card_texture(500, 74, "pressed"))
		btn.size = Vector2(card_w, card_h)
		btn.position = Vector2(10, i * (card_h + card_sep))
		btn.set_meta("item_id", id)
		btn.pressed.connect(_on_item_chosen.bind(id))
		btn.mouse_entered.connect(AudioManager.play_hover)
		_choice_slots.add_child(btn)
		_choice_card_btns.append(btn)

		# Ícono de la mejora / reliquia
		var icon_slot := TextureRect.new()
		icon_slot.texture = _slot_frame
		icon_slot.size = Vector2(52, 52)
		icon_slot.position = Vector2(12, 11)
		icon_slot.mouse_filter = Control.MOUSE_FILTER_IGNORE
		btn.add_child(icon_slot)

		var icon_img := ColorRect.new()
		icon_img.color = _item_color(id)
		icon_img.size = Vector2(36, 36)
		icon_img.position = Vector2(8, 8)
		icon_img.mouse_filter = Control.MOUSE_FILTER_IGNORE
		icon_slot.add_child(icon_img)

		# Título en CinzelDecorative
		var name_lbl := Label.new()
		name_lbl.text = info["name"]
		var title_col = Color(1.0, 0.88, 0.45) if is_weapon else Color(0.4, 0.85, 1.0)
		_aplicar_fuente(name_lbl, true, 15, title_col)
		name_lbl.position = Vector2(74, 12)
		name_lbl.size = Vector2(300, 20)
		name_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
		btn.add_child(name_lbl)

		# Indicador de Nivel
		var lv_lbl := Label.new()
		lv_lbl.text = "[ NV. " + str(cur_lv) + " → " + str(cur_lv + 1) + " ]" if cur_lv > 0 else "[ NUEVA RELIQUIA ]"
		_aplicar_fuente(lv_lbl, false, 11, Color(0.85, 0.70, 0.35))
		lv_lbl.position = Vector2(330, 14)
		lv_lbl.size = Vector2(120, 18)
		lv_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		lv_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
		btn.add_child(lv_lbl)

		# Descripción en Cinzel limpia
		var desc_lbl := Label.new()
		desc_lbl.text = info["desc"]
		_aplicar_fuente(desc_lbl, false, 11, Color(0.82, 0.80, 0.88))
		desc_lbl.position = Vector2(74, 38)
		desc_lbl.size = Vector2(370, 28)
		desc_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		desc_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
		btn.add_child(desc_lbl)

		# Sello de tecla de atajo rápida [1, 2, 3]
		var key_seal := Label.new()
		key_seal.text = "[" + str(i + 1) + "]"
		_aplicar_fuente(key_seal, true, 13, Color(1.0, 0.85, 0.45))
		key_seal.position = Vector2(462, 26)
		key_seal.size = Vector2(28, 22)
		key_seal.mouse_filter = Control.MOUSE_FILTER_IGNORE
		btn.add_child(key_seal)

# ------------------------------------------------------------------------------
# INVENTARIO DE RELIQUIAS Y ATRIBUTOS PASIVOS
# ------------------------------------------------------------------------------
func _build_item_grid() -> void:
	_item_grid = GridContainer.new()
	_item_grid.columns = 5
	_item_grid.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	_item_grid.position = Vector2(-270, -140)
	_item_grid.size = Vector2(250, 95)
	_item_grid.add_theme_constant_override("h_separation", 6)
	_item_grid.add_theme_constant_override("v_separation", 6)
	add_child(_item_grid)

func _item_color(id: String) -> Color:
	match id:
		"dented_souls":   return Color(0.85, 0.15, 0.15)
		"ghost_projectile": return Color(0.25, 0.55, 0.95)
		"necro_cloud":    return Color(0.55, 0.1, 0.8)
		"blood_heart":    return Color(0.9, 0.1, 0.25)
		"arcane_battery": return Color(1.0, 0.85, 0.1)
		"wind_boots":     return Color(0.2, 0.85, 0.45)
		"shadow_armor":   return Color(0.45, 0.45, 0.65)
		"soul_magnet":    return Color(1.0, 0.65, 0.1)
		"old_grimoire":   return Color(0.7, 0.45, 0.2)
		"xp_gem":         return Color(0.1, 0.85, 1.0)
	return Color(0.35, 0.35, 0.35)

func update_item_grid() -> void:
	if _item_grid == null:
		return
	for child in _item_grid.get_children():
		child.queue_free()

	var cols: Array[String] = [
		"dented_souls", "ghost_projectile", "necro_cloud", "blood_heart", "arcane_battery",
		"wind_boots", "shadow_armor", "soul_magnet", "old_grimoire", "xp_gem"
	]

	for id in cols:
		var lv = _IM.get_level(id) if _IM != null else 0
		var slot := TextureRect.new()
		slot.texture = _slot_frame
		slot.size = Vector2(44, 44)
		slot.custom_minimum_size = Vector2(44, 44)
		_item_grid.add_child(slot)

		if lv > 0:
			var fill := ColorRect.new()
			fill.color = _item_color(id)
			fill.position = Vector2(6, 6)
			fill.size = Vector2(32, 32)
			slot.add_child(fill)

			var lbl := Label.new()
			lbl.text = str(lv)
			_aplicar_fuente(lbl, false, 12, Color.WHITE, Color.BLACK, 2)
			lbl.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
			lbl.position = Vector2(-16, -16)
			lbl.size = Vector2(14, 14)
			lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			slot.add_child(lbl)

# ------------------------------------------------------------------------------
# CONTROL DE EVENTOS E INPUTS
# ------------------------------------------------------------------------------
func _on_item_chosen(item_id: String) -> void:
	var player := get_parent()
	if player and player.has_method("apply_upgrade"):
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
			return

# ------------------------------------------------------------------------------
# VIGNETTE DE DAÑO
# ------------------------------------------------------------------------------
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
			var dx := absf(float(x - 128)) / 128.0
			var dy := absf(float(y - 128)) / 128.0
			var dist := maxf(dx, dy)
			var alpha := clampf((dist - 0.55) / 0.45, 0.0, 0.85)
			img.set_pixel(x, y, Color(0.85, 0.02, 0.02, alpha))
	_damage_vignette.texture = ImageTexture.create_from_image(img)
	add_child(_damage_vignette)

func show_damage_vignette() -> void:
	if not is_inside_tree():
		return
	_damage_vignette.modulate = Color(1, 1, 1, 0.55)
	var tw := create_tween()
	tw.tween_property(_damage_vignette, "modulate:a", 0.0, 0.6)

# ------------------------------------------------------------------------------
# INTERFAZ PÚBLICA DE ACTUALIZACIÓN DE ESTADO
# ------------------------------------------------------------------------------
func set_souls(current: int, required: int) -> void:
	_soul_label.text = "✦ ALMAS: " + str(current) + "/" + str(required)
	if current >= required:
		_soul_label.add_theme_color_override("font_color", Color(1.0, 0.45, 0.95))
		_soul_label.add_theme_color_override("font_shadow_color", Color(0.4, 0.0, 0.6, 0.95))

func set_demon_cooldown(slot: int, seconds: float) -> void:
	if slot < 0 or slot >= _demon_cd_labels.size():
		return
	var label = _demon_cd_labels[slot]
	if seconds <= 0.0:
		label.text = "✓"
		label.add_theme_color_override("font_color", Color(0.3, 1.0, 0.4, 0.95))
	else:
		label.text = str(ceili(seconds))
		label.add_theme_color_override("font_color", Color(1.0, 0.3, 0.3, 0.95))

func set_potion_cooldown(seconds: float) -> void:
	if not is_instance_valid(_potion_cd_label):
		return
	if seconds <= 0.0:
		_potion_cd_label.text = "✓"
		_potion_cd_label.add_theme_color_override("font_color", Color(0.3, 1.0, 0.4, 0.95))
	else:
		_potion_cd_label.text = str(ceili(seconds))
		_potion_cd_label.add_theme_color_override("font_color", Color(1.0, 0.3, 0.3, 0.95))

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
	_pentagram_label.text = "⛧ RITUAL: " + runes

func set_element(text: String) -> void:
	element_label.text = "ELEMENTO: " + text.to_upper()
	match text.to_upper():
		"FIRE", "FUEGO":
			element_label.add_theme_color_override("font_color", Color(1.0, 0.45, 0.15))
		"ICE", "HIELO":
			element_label.add_theme_color_override("font_color", Color(0.3, 0.85, 1.0))
		"NECROMANCIA", "VOID", "VACIO":
			element_label.add_theme_color_override("font_color", Color(0.85, 0.35, 1.0))
		_:
			element_label.add_theme_color_override("font_color", Color(0.85, 0.70, 0.35))

func set_health(current: float, max_hp: float) -> void:
	hp_bar.max_value = max_hp
	hp_bar.value = current
	hp_label.text = str(ceili(current))

func set_mana(current: float, max_m: float) -> void:
	mp_bar.max_value = max_m
	mp_bar.value = current
	mp_label.text = str(ceili(current))

func set_level(lv: int) -> void:
	level_label.text = "NV " + str(lv)

func set_xp(xp: int, needed: int) -> void:
	AudioManager.play_xp_gain()
	xp_bar.max_value = needed
	xp_label.text = str(xp) + " / " + str(needed) + " XP"
	if xp_bar.has_meta("xp_tween"):
		var old: Tween = xp_bar.get_meta("xp_tween")
		if old and old.is_valid():
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

func show_level_up(_player_node: Node = null) -> void:
	if _banner_visible:
		return
	AudioManager.play_level_up()
	_banner_visible = true
	_banner.visible = true
	_banner.scale = Vector2(0.5, 0.5)
	_banner.modulate = Color(1, 1, 1, 0)

	var tween := create_tween().set_parallel()
	tween.tween_property(_banner, "scale", Vector2(1.05, 1.05), 0.3).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	tween.tween_property(_banner, "modulate", Color(1, 1, 1, 1), 0.3)
	tween.chain().tween_property(_banner, "scale", Vector2(1.0, 1.0), 0.1).set_ease(Tween.EASE_IN)

	await get_tree().create_timer(1.8).timeout
	var fade_tween := create_tween()
	fade_tween.tween_property(_banner, "modulate", Color(1, 1, 1, 0), 0.3)
	await fade_tween.finished
	_banner.visible = false
	_banner_visible = false
	update_item_grid()

	if _player_node and _player_node.has_method("apply_upgrade"):
		await get_tree().create_timer(0.2).timeout
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
	tween.tween_property(_banner, "scale", Vector2(1.1, 1.1), 0.3).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	tween.tween_property(_banner, "modulate", Color(1, 1, 1, 1), 0.3)
	tween.chain().tween_property(_banner, "scale", Vector2(1.0, 1.0), 0.1)
	await get_tree().create_timer(2.5).timeout
	var fade_tween := create_tween()
	fade_tween.tween_property(_banner, "modulate", Color(1, 1, 1, 0), 0.35)
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
