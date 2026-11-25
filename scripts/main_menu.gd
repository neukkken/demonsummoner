extends Control

# ==============================================================================
# MENÚ PRINCIPAL GÓTICO — DEMON SUMMONER
# ==============================================================================

var _bg_tex: Texture2D
var _title_tex: Texture2D
var _btn_normal: Texture2D
var _btn_hover: Texture2D
var _btn_pressed: Texture2D
var _sigil_tex: Texture2D
var _panel_frame_tex: Texture2D
var _font_cinzel_dec: Font
var _font_cinzel: Font
var _sigil_rect: TextureRect = null
var _title_shader: Shader
var _music_player: AudioStreamPlayer
var _title_rect: TextureRect = null
var _time_elapsed: float = 0.0

func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	_generate_all()
	_build_ui()

func _generate_all() -> void:
	_bg_tex = load("res://sprites/rpg_menu_background.jpg")
	_title_tex = load("res://sprites/rpg_title_logo.png")
	_title_shader = load("res://shaders/rpg_title_glow.gdshader")
	_sigil_tex = load("res://sprites/rpg_sigil.png")
	_panel_frame_tex = load("res://sprites/rpg_panel_frame.png")

	_font_cinzel_dec = load("res://fonts/CinzelDecorative-Bold.ttf")
	_font_cinzel = load("res://fonts/Cinzel.ttf")

	_btn_normal = load("res://sprites/rpg_button_normal.png")
	_btn_hover = load("res://sprites/rpg_button_hover.png")
	_btn_pressed = load("res://sprites/rpg_button_pressed.png")
	_setup_music()

func _setup_music() -> void:
	var stream = load("res://music/main theme.mp3")
	if not stream:
		return
	_music_player = AudioStreamPlayer.new()
	_music_player.stream = stream
	_music_player.volume_db = -40.0
	_music_player.bus = "Music"
	add_child(_music_player)
	_music_player.play()
	var tween = create_tween()
	tween.tween_property(_music_player, "volume_db", -12.0, 2.0)

func _process(delta: float) -> void:
	_time_elapsed += delta
	# Suave levitación del título
	if _title_rect:
		_title_rect.position.y = -325.0 + sin(_time_elapsed * 1.8) * 6.0
	# Rotación hipnótica y pulso del sigilo demoníaco
	if _sigil_rect:
		_sigil_rect.rotation += delta * 0.10
		var p = 0.22 + 0.10 * sin(_time_elapsed * 2.2)
		_sigil_rect.modulate.a = p

func _build_ui() -> void:
	# 1. Fondo principal
	var bg := TextureRect.new()
	bg.texture = _bg_tex
	bg.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	bg.stretch_mode = TextureRect.STRETCH_SCALE
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg)

	# 2. Viñeta oscura periférica para enfocar los elementos centrales
	var vignette := ColorRect.new()
	vignette.set_anchors_preset(Control.PRESET_FULL_RECT)
	vignette.color = Color(0.02, 0.01, 0.03, 0.35)
	add_child(vignette)

	# 3. Sigilo demoníaco giratorio de fondo
	if _sigil_tex:
		_sigil_rect = TextureRect.new()
		_sigil_rect.texture = _sigil_tex
		_sigil_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		_sigil_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		_sigil_rect.custom_minimum_size = Vector2(460, 460)
		_sigil_rect.size = Vector2(460, 460)
		_sigil_rect.pivot_offset = Vector2(230, 230)
		_sigil_rect.set_anchors_preset(Control.PRESET_CENTER, false)
		_sigil_rect.position = Vector2(-230, -75)
		_sigil_rect.modulate = Color(1.0, 0.45, 0.2, 0.26)
		add_child(_sigil_rect)

	# 4. Partículas de ascuas flotantes 2D
	_crear_particulas_ascuas()

	# 5. Título con Shader de fuego y resplandor
	if _title_tex:
		_title_rect = TextureRect.new()
		_title_rect.texture = _title_tex
		_title_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		_title_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		_title_rect.set_anchors_preset(Control.PRESET_CENTER, false)
		_title_rect.position = Vector2(-250, -325)
		_title_rect.size = Vector2(500, 270)
		if _title_shader:
			var mat := ShaderMaterial.new()
			mat.shader = _title_shader
			_title_rect.material = mat
		add_child(_title_rect)

	# 6. Subtítulo gótico
	var subtitle := Label.new()
	subtitle.text = "SOBREVIVE A LA HORDA · COSECHA ALMAS · INVOCA DEMONIOS"
	if _font_cinzel:
		subtitle.add_theme_font_override("font", _font_cinzel)
	subtitle.add_theme_font_size_override("font_size", 12)
	subtitle.add_theme_color_override("font_color", Color(0.92, 0.78, 0.42, 0.95))
	subtitle.add_theme_color_override("font_shadow_color", Color(0.02, 0.01, 0.03, 0.95))
	subtitle.add_theme_constant_override("shadow_offset_y", 1)
	subtitle.set_anchors_preset(Control.PRESET_CENTER, false)
	subtitle.position = Vector2(-280, -62)
	subtitle.size = Vector2(560, 24)
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	add_child(subtitle)

	# 7. Contenedor de botones interactivos góticos (más grandes y elevados del borde inferior)
	var buttons := [
		["JUGAR", "_on_play"],
		["GUÍA Y CONTROLES", "_on_guide"],
		["PUNTAJES", "_on_scores"],
		["CONFIGURACIÓN", "_on_settings"],
		["SALIR", "_on_quit"],
	]

	var btn_w := 380.0
	var btn_h := 52.0
	var btn_start_y := -20.0
	var btn_spacing := 62.0

	for i in buttons.size():
		var label_text: String = buttons[i][0]
		var callback_name: String = buttons[i][1]

		var btn := Button.new()
		btn.text = label_text
		btn.custom_minimum_size = Vector2(btn_w, btn_h)
		btn.size = Vector2(btn_w, btn_h)
		btn.pivot_offset = Vector2(btn_w * 0.5, btn_h * 0.5)

		btn.set_anchors_preset(Control.PRESET_CENTER, false)
		btn.position = Vector2(-btn_w * 0.5, btn_start_y + i * btn_spacing)

		# 9-slice StyleBoxes con texturas góticas de obsidiana y bronce
		if _btn_normal:
			btn.add_theme_stylebox_override("normal", _make_button_stylebox(_btn_normal))
		if _btn_hover:
			btn.add_theme_stylebox_override("hover", _make_button_stylebox(_btn_hover))
		if _btn_pressed:
			btn.add_theme_stylebox_override("pressed", _make_button_stylebox(_btn_pressed))
		btn.add_theme_stylebox_override("focus", StyleBoxEmpty.new())

		# Tipografía gótica Cinzel Decorative en tamaño 16
		if _font_cinzel_dec:
			btn.add_theme_font_override("font", _font_cinzel_dec)
			btn.add_theme_font_size_override("font_size", 16)
		elif _font_cinzel:
			btn.add_theme_font_override("font", _font_cinzel)
			btn.add_theme_font_size_override("font_size", 16)

		# Esquema de color: oro antiguo, resplandor ámbar en hover, carmesí al pulsar
		btn.add_theme_color_override("font_color", Color(0.88, 0.80, 0.65))
		btn.add_theme_color_override("font_hover_color", Color(1.0, 0.94, 0.55))
		btn.add_theme_color_override("font_pressed_color", Color(1.0, 0.50, 0.28))
		btn.add_theme_color_override("font_shadow_color", Color(0.02, 0.01, 0.03, 0.95))
		btn.add_theme_constant_override("shadow_offset_x", 1)
		btn.add_theme_constant_override("shadow_offset_y", 2)
		btn.add_theme_color_override("font_outline_color", Color(0.12, 0.05, 0.03, 0.9))
		btn.add_theme_constant_override("outline_size", 2)

		# Marcadores heráldicos / rúnicos laterales que emergen al pasar el ratón
		var left_marker := Label.new()
		left_marker.text = "✧"
		if _font_cinzel:
			left_marker.add_theme_font_override("font", _font_cinzel)
		left_marker.add_theme_font_size_override("font_size", 15)
		left_marker.add_theme_color_override("font_color", Color(1.0, 0.82, 0.35))
		left_marker.position = Vector2(40, 15)
		left_marker.modulate.a = 0.0
		btn.add_child(left_marker)

		var right_marker := Label.new()
		right_marker.text = "✧"
		if _font_cinzel:
			right_marker.add_theme_font_override("font", _font_cinzel)
		right_marker.add_theme_font_size_override("font_size", 15)
		right_marker.add_theme_color_override("font_color", Color(1.0, 0.82, 0.35))
		right_marker.position = Vector2(btn_w - 56, 15)
		right_marker.modulate.a = 0.0
		btn.add_child(right_marker)

		# Animación interactiva en hover
		btn.mouse_entered.connect(func():
			AudioManager.play_hover()
			var t = btn.create_tween().set_parallel(true).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
			t.tween_property(btn, "scale", Vector2(1.03, 1.03), 0.15)
			t.tween_property(left_marker, "modulate:a", 1.0, 0.2)
			t.tween_property(right_marker, "modulate:a", 1.0, 0.2)
			t.tween_property(left_marker, "position:x", 32.0, 0.2)
			t.tween_property(right_marker, "position:x", btn_w - 48.0, 0.2)
		)
		btn.mouse_exited.connect(func():
			var t = btn.create_tween().set_parallel(true).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
			t.tween_property(btn, "scale", Vector2(1.0, 1.0), 0.15)
			t.tween_property(left_marker, "modulate:a", 0.0, 0.15)
			t.tween_property(right_marker, "modulate:a", 0.0, 0.15)
			t.tween_property(left_marker, "position:x", 40.0, 0.15)
			t.tween_property(right_marker, "position:x", btn_w - 56.0, 0.15)
		)

		btn.pressed.connect(Callable(self, callback_name))
		btn.pressed.connect(func(): AudioManager.play_click())
		add_child(btn)

	# 7. Etiqueta de versión
	var ver_label := Label.new()
	ver_label.text = "v0.7.0 — Mazmorras & Optimización"
	ver_label.add_theme_font_size_override("font_size", 12)
	ver_label.add_theme_color_override("font_color", Color(0.5, 0.45, 0.55))
	ver_label.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
	ver_label.offset_left = 16
	ver_label.offset_top = -28
	add_child(ver_label)

	# 8. Recuadro N (Firma gótica)
	var n_box := PanelContainer.new()
	n_box.custom_minimum_size = Vector2(50, 50)
	n_box.size = Vector2(50, 50)
	var n_bg := StyleBoxFlat.new()
	n_bg.bg_color = Color(0.06, 0.04, 0.08, 0.9)
	n_bg.border_width_left = 1
	n_bg.border_width_top = 1
	n_bg.border_width_right = 1
	n_bg.border_width_bottom = 1
	n_bg.border_color = Color(0.4, 0.35, 0.25)
	n_box.add_theme_stylebox_override("panel", n_bg)
	n_box.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	n_box.offset_left = -60
	n_box.offset_top = -60
	n_box.offset_right = -10
	n_box.offset_bottom = -10
	add_child(n_box)

	var n_label := Label.new()
	n_label.text = "N"
	n_label.add_theme_font_size_override("font_size", 24)
	n_label.add_theme_color_override("font_color", Color(0.85, 0.7, 0.3))
	n_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	n_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	n_label.set_anchors_preset(Control.PRESET_FULL_RECT)
	n_box.add_child(n_label)

func _make_button_stylebox(tex: Texture2D) -> StyleBoxTexture:
	var sb := StyleBoxTexture.new()
	sb.texture = tex
	sb.texture_margin_left = 24
	sb.texture_margin_right = 24
	sb.texture_margin_top = 14
	sb.texture_margin_bottom = 14
	sb.content_margin_left = 28
	sb.content_margin_right = 28
	sb.content_margin_top = 6
	sb.content_margin_bottom = 6
	return sb

func _style_modal_button(btn: Button) -> void:
	if _btn_normal:
		btn.add_theme_stylebox_override("normal", _make_button_stylebox(_btn_normal))
	if _btn_hover:
		btn.add_theme_stylebox_override("hover", _make_button_stylebox(_btn_hover))
	if _btn_pressed:
		btn.add_theme_stylebox_override("pressed", _make_button_stylebox(_btn_pressed))
	btn.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	if _font_cinzel_dec:
		btn.add_theme_font_override("font", _font_cinzel_dec)
		btn.add_theme_font_size_override("font_size", 14)
	elif _font_cinzel:
		btn.add_theme_font_override("font", _font_cinzel)
		btn.add_theme_font_size_override("font_size", 14)
	btn.add_theme_color_override("font_color", Color(0.88, 0.80, 0.65))
	btn.add_theme_color_override("font_hover_color", Color(1.0, 0.94, 0.55))
	btn.add_theme_color_override("font_pressed_color", Color(1.0, 0.50, 0.28))
	btn.add_theme_color_override("font_shadow_color", Color(0.02, 0.01, 0.03, 0.95))
	btn.add_theme_constant_override("shadow_offset_y", 1)

func _crear_particulas_ascuas() -> void:
	var embers := CPUParticles2D.new()
	embers.amount = 40
	embers.lifetime = 4.5
	embers.preprocess = 3.0
	embers.speed_scale = 1.0
	embers.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	var win_w = 1280.0
	var win_h = 720.0
	if DisplayServer.has_feature(DisplayServer.FEATURE_GLOBAL_MENU):
		var ws = DisplayServer.window_get_size()
		win_w = ws.x
		win_h = ws.y
	embers.emission_rect_extents = Vector2(win_w * 0.55, 20)
	embers.position = Vector2(win_w * 0.5, win_h + 10)
	embers.direction = Vector2(0, -1)
	embers.spread = 20.0
	embers.gravity = Vector2(0, -15)
	embers.initial_velocity_min = 35.0
	embers.initial_velocity_max = 75.0
	embers.scale_amount_min = 2.0
	embers.scale_amount_max = 4.5
	embers.color = Color(1.0, 0.5, 0.15, 0.75)
	add_child(embers)

# ------------------------------------------------------------------------------
# ACCIONES DE BOTONES
# ------------------------------------------------------------------------------
func _on_play() -> void:
	if _music_player and _music_player.playing:
		var tween = create_tween()
		tween.tween_property(_music_player, "volume_db", -40.0, 0.5)
		tween.tween_callback(func(): _music_player.stop())
		await tween.finished
	get_tree().change_scene_to_file("res://world.tscn")

func _on_guide() -> void:
	_show_guide_modal()

func _on_scores() -> void:
	_show_leaderboard()

func _on_settings() -> void:
	_show_settings()

func _on_quit() -> void:
	get_tree().quit()

# ------------------------------------------------------------------------------
# MODAL: GUÍA Y CONTROLES DEL JUEGO
# ------------------------------------------------------------------------------
func _show_guide_modal() -> void:
	var root := Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(root)

	var overlay := ColorRect.new()
	overlay.color = Color(0, 0, 0, 0.7)
	overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.add_child(overlay)

	var panel := PanelContainer.new()
	panel.set_anchors_preset(Control.PRESET_CENTER, false)
	panel.position = Vector2(-330, -255)
	panel.size = Vector2(660, 510)
	panel.add_theme_stylebox_override("panel", _make_panel_stylebox())
	root.add_child(panel)

	var vbox := VBoxContainer.new()
	vbox.set_anchors_preset(Control.PRESET_FULL_RECT)
	vbox.offset_left = 28
	vbox.offset_top = 20
	vbox.offset_right = -28
	vbox.offset_bottom = -20
	vbox.add_theme_constant_override("separation", 10)
	panel.add_child(vbox)

	var title := Label.new()
	title.text = "— GRIMORIO DE CONTROLES & GUÍA —"
	if _font_cinzel_dec:
		title.add_theme_font_override("font", _font_cinzel_dec)
		title.add_theme_font_size_override("font_size", 16)
	else:
		title.add_theme_font_size_override("font_size", 17)
	title.add_theme_color_override("font_color", Color(1.0, 0.88, 0.45))
	title.add_theme_color_override("font_shadow_color", Color(0.02, 0.01, 0.03, 0.95))
	title.add_theme_constant_override("shadow_offset_y", 2)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(title)

	var divider := ColorRect.new()
	divider.custom_minimum_size = Vector2(0, 1)
	divider.color = Color(0.70, 0.52, 0.24, 0.55)
	vbox.add_child(divider)

	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(600, 360)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	vbox.add_child(scroll)

	var content := VBoxContainer.new()
	content.add_theme_constant_override("separation", 10)
	scroll.add_child(content)

	content.add_child(_crear_seccion_guia("⚔️ MOVIMIENTO & INTERACCIÓN", [
		"W A S D : Moverte por las salas, balcones y escaleras",
		"Ratón : Apuntar y rotar la cámara",
		"E : Abrir cofres de tesoro para obtener items y gemas",
		"TAB : Beber poción de curación (50 HP)",
		"G : Abrir / Cerrar Grimorio de invocación",
		"1 2 3 : Elegir mejoras al subir de nivel"
	], Color(0.4, 0.8, 1.0)))

	content.add_child(_crear_seccion_guia("🔥 ELEMENTOS & CANALIZACIÓN DE HECHIZOS", [
		"Espacio : Seleccionar Fuego (Llama destructiva)",
		"Shift + R : Seleccionar Hielo (Control y congelamiento)",
		"F : Seleccionar Necromancia (Magia de sangre y almas)",
		"Shift + Clic Derecho (mantener) : Canalizar gesto con el ratón",
		"  ↑ Gesto Arriba : Bola de Fuego / Lanza de Hielo",
		"  ↓ Gesto Abajo : Explosión en área / Muro de Hielo",
		"  → Gesto Derecha : Disparo rápido / Refuerzo"
	], Color(1.0, 0.55, 0.2)))

	content.add_child(_crear_seccion_guia("💀 INVOCACIONES DEMONÍACAS", [
		"R : Invocar Segador de Sangre (Cuerpo a cuerpo, gasta 20% HP)",
		"Cosecha 50 Almas : El Pentagrama ancestral se activará en tu HUD",
		"Dibuja ↑ ↓ ← ↑ ↓ : Despierta al Devorador de Almas, un demonio colosal que erradica a las hordas."
	], Color(0.9, 0.2, 0.7)))

	content.add_child(_crear_seccion_guia("🗝️ MAZMORRA MULTI-NIVEL & COFRES", [
		"Explora los 3 niveles de altura (Piso 0, Piso 1, Piso 2) conectados por escaleras de piedra.",
		"Encuentra las Bóvedas de Tesoro y abre los cofres con la tecla E para subir de nivel tus armas pasivas.",
		"Cuidado con los fosos de lava en el piso inferior que queman y ralentizan."
	], Color(0.6, 0.9, 0.4)))

	# Botón de cerrar
	var close_btn := Button.new()
	close_btn.text = "ENTENDIDO"
	close_btn.custom_minimum_size = Vector2(220, 44)
	close_btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	_style_modal_button(close_btn)
	close_btn.pressed.connect(func():
		AudioManager.play_click()
		root.queue_free()
	)
	vbox.add_child(close_btn)

func _crear_seccion_guia(header: String, lines: Array, col: Color) -> PanelContainer:
	var card := PanelContainer.new()
	var card_bg := StyleBoxFlat.new()
	card_bg.bg_color = Color(0.08, 0.05, 0.10, 0.75)
	card_bg.border_width_left = 2
	card_bg.border_width_top = 1
	card_bg.border_width_right = 1
	card_bg.border_width_bottom = 1
	card_bg.border_color = Color(col.r * 0.65, col.g * 0.65, col.b * 0.65, 0.5)
	card_bg.corner_radius_top_left = 4
	card_bg.corner_radius_top_right = 4
	card_bg.corner_radius_bottom_left = 4
	card_bg.corner_radius_bottom_right = 4
	card_bg.content_margin_left = 14
	card_bg.content_margin_top = 8
	card_bg.content_margin_right = 14
	card_bg.content_margin_bottom = 8
	card.add_theme_stylebox_override("panel", card_bg)

	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 2)
	card.add_child(v)

	var h := Label.new()
	h.text = header
	if _font_cinzel_dec:
		h.add_theme_font_override("font", _font_cinzel_dec)
	h.add_theme_font_size_override("font_size", 13)
	h.add_theme_color_override("font_color", col)
	v.add_child(h)

	for l in lines:
		var lbl := Label.new()
		lbl.text = "  • " + l
		if _font_cinzel:
			lbl.add_theme_font_override("font", _font_cinzel)
		lbl.add_theme_font_size_override("font_size", 11)
		lbl.add_theme_color_override("font_color", Color(0.88, 0.84, 0.88))
		v.add_child(lbl)
	return card

# ------------------------------------------------------------------------------
# MODAL: CONFIGURACIÓN MEJORADA (Pantalla completa, audio y render)
# ------------------------------------------------------------------------------
func _show_settings() -> void:
	var root := Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(root)

	var overlay := ColorRect.new()
	overlay.color = Color(0, 0, 0, 0.7)
	overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.add_child(overlay)

	var panel := PanelContainer.new()
	panel.set_anchors_preset(Control.PRESET_CENTER, false)
	panel.position = Vector2(-250, -210)
	panel.size = Vector2(500, 420)
	panel.add_theme_stylebox_override("panel", _make_panel_stylebox())
	root.add_child(panel)

	var vbox := VBoxContainer.new()
	vbox.set_anchors_preset(Control.PRESET_FULL_RECT)
	vbox.offset_left = 28
	vbox.offset_top = 20
	vbox.offset_right = -28
	vbox.offset_bottom = -20
	vbox.add_theme_constant_override("separation", 12)
	panel.add_child(vbox)

	var title := Label.new()
	title.text = "— CONFIGURACIÓN —"
	if _font_cinzel_dec:
		title.add_theme_font_override("font", _font_cinzel_dec)
		title.add_theme_font_size_override("font_size", 16)
	else:
		title.add_theme_font_size_override("font_size", 18)
	title.add_theme_color_override("font_color", Color(1.0, 0.88, 0.45))
	title.add_theme_color_override("font_shadow_color", Color(0.02, 0.01, 0.03, 0.95))
	title.add_theme_constant_override("shadow_offset_y", 2)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(title)

	var divider := ColorRect.new()
	divider.custom_minimum_size = Vector2(0, 1)
	divider.color = Color(0.70, 0.52, 0.24, 0.55)
	vbox.add_child(divider)

	# 1. Slider Música
	vbox.add_child(_crear_slider_fila("MÚSICA", AudioManager.get_music_volume_db(), func(val):
		var db = _slider_val_to_db(val)
		AudioManager.set_music_volume_db(db)
	))

	# 2. Slider SFX
	vbox.add_child(_crear_slider_fila("EFECTOS", AudioManager.get_sfx_volume_db(), func(val):
		var db = _slider_val_to_db(val)
		AudioManager.set_sfx_volume_db(db)
		AudioManager.play_click()
	))

	# 3. Pantalla Completa Toggle
	var fs_row := HBoxContainer.new()
	var fs_lbl := Label.new()
	fs_lbl.text = "PANTALLA COMPLETA"
	if _font_cinzel:
		fs_lbl.add_theme_font_override("font", _font_cinzel)
	fs_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	fs_lbl.add_theme_font_size_override("font_size", 12)
	fs_lbl.add_theme_color_override("font_color", Color(0.85, 0.85, 0.8))
	fs_row.add_child(fs_lbl)

	var fs_check := CheckButton.new()
	var is_fs = DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_FULLSCREEN
	fs_check.button_pressed = is_fs
	fs_check.toggled.connect(func(pressed):
		if pressed:
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
		else:
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
		AudioManager.play_click()
	)
	fs_row.add_child(fs_check)
	vbox.add_child(fs_row)

	# 4. Calidad / Distancia de render
	var dist_row := HBoxContainer.new()
	var dist_lbl := Label.new()
	dist_lbl.text = "CALIDAD DE NIEBLA"
	if _font_cinzel:
		dist_lbl.add_theme_font_override("font", _font_cinzel)
	dist_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	dist_lbl.add_theme_font_size_override("font_size", 12)
	dist_lbl.add_theme_color_override("font_color", Color(0.85, 0.85, 0.8))
	dist_row.add_child(dist_lbl)

	var dist_btn := OptionButton.new()
	dist_btn.add_item("Corta")
	dist_btn.add_item("Media")
	dist_btn.add_item("Larga")
	dist_btn.selected = DatosJuego.render_distance
	dist_btn.item_selected.connect(func(idx):
		DatosJuego.render_distance = idx
		AudioManager.play_click()
	)
	dist_row.add_child(dist_btn)
	vbox.add_child(dist_row)

	# Botón Cerrar
	var close_btn := Button.new()
	close_btn.text = "GUARDAR Y CERRAR"
	close_btn.custom_minimum_size = Vector2(220, 44)
	close_btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	_style_modal_button(close_btn)
	close_btn.pressed.connect(func():
		AudioManager.play_click()
		root.queue_free()
	)
	vbox.add_child(close_btn)

func _crear_slider_fila(nombre: String, db_val: float, callback: Callable) -> VBoxContainer:
	var container := VBoxContainer.new()
	container.add_theme_constant_override("separation", 2)

	var top_row := HBoxContainer.new()
	var lbl := Label.new()
	lbl.text = nombre
	if _font_cinzel:
		lbl.add_theme_font_override("font", _font_cinzel)
	lbl.add_theme_font_size_override("font_size", 12)
	lbl.add_theme_color_override("font_color", Color(0.85, 0.85, 0.8))
	lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top_row.add_child(lbl)

	var val_lbl := Label.new()
	var current_pct = int(_db_to_slider_val(db_val))
	val_lbl.text = str(current_pct) + "%"
	if _font_cinzel:
		val_lbl.add_theme_font_override("font", _font_cinzel)
	val_lbl.add_theme_font_size_override("font_size", 12)
	val_lbl.add_theme_color_override("font_color", Color(0.85, 0.70, 0.40))
	top_row.add_child(val_lbl)
	container.add_child(top_row)

	var slider := HSlider.new()
	slider.min_value = 0.0
	slider.max_value = 100.0
	slider.value = current_pct
	slider.step = 1.0
	slider.value_changed.connect(func(val):
		val_lbl.text = str(int(val)) + "%"
		callback.call(val)
	)
	container.add_child(slider)

	return container

# ------------------------------------------------------------------------------
# MODAL: PUNTAJES (LEADERBOARD)
# ------------------------------------------------------------------------------
func _load_scores() -> Array:
	var file := FileAccess.open("user://leaderboard.json", FileAccess.READ)
	if file == null:
		return []
	var text := file.get_as_text()
	var json := JSON.new()
	if json.parse(text) != OK:
		return []
	return json.data if json.data is Array else []

func _make_panel_stylebox() -> StyleBox:
	if _panel_frame_tex:
		var bg := StyleBoxTexture.new()
		bg.texture = _panel_frame_tex
		bg.texture_margin_left = 28
		bg.texture_margin_top = 28
		bg.texture_margin_right = 28
		bg.texture_margin_bottom = 28
		return bg
	var bg := StyleBoxFlat.new()
	bg.bg_color = Color(0.06, 0.04, 0.08, 0.96)
	bg.border_width_left = 2
	bg.border_width_top = 2
	bg.border_width_right = 2
	bg.border_width_bottom = 2
	bg.border_color = Color(0.70, 0.52, 0.24)
	bg.corner_radius_top_left = 6
	bg.corner_radius_top_right = 6
	bg.corner_radius_bottom_left = 6
	bg.corner_radius_bottom_right = 6
	return bg

func _show_leaderboard() -> void:
	var root := Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(root)

	var overlay := ColorRect.new()
	overlay.color = Color(0, 0, 0, 0.7)
	overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.add_child(overlay)

	var panel := PanelContainer.new()
	panel.set_anchors_preset(Control.PRESET_CENTER, false)
	panel.position = Vector2(-240, -190)
	panel.size = Vector2(480, 380)
	panel.add_theme_stylebox_override("panel", _make_panel_stylebox())
	root.add_child(panel)

	var vbox := VBoxContainer.new()
	vbox.set_anchors_preset(Control.PRESET_FULL_RECT)
	vbox.offset_left = 28
	vbox.offset_top = 20
	vbox.offset_right = -28
	vbox.offset_bottom = -20
	vbox.add_theme_constant_override("separation", 12)
	panel.add_child(vbox)

	var title := Label.new()
	title.text = "— MEJORES PUNTAJES —"
	if _font_cinzel_dec:
		title.add_theme_font_override("font", _font_cinzel_dec)
		title.add_theme_font_size_override("font_size", 16)
	else:
		title.add_theme_font_size_override("font_size", 18)
	title.add_theme_color_override("font_color", Color(1.0, 0.88, 0.45))
	title.add_theme_color_override("font_shadow_color", Color(0.02, 0.01, 0.03, 0.95))
	title.add_theme_constant_override("shadow_offset_y", 2)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(title)

	var divider := ColorRect.new()
	divider.custom_minimum_size = Vector2(0, 1)
	divider.color = Color(0.70, 0.52, 0.24, 0.55)
	vbox.add_child(divider)

	var scores := _load_scores()
	var text := ""
	var rank := 1
	for entry in scores:
		text += "#%d  Nivel %s  ·  %s +%s  (%s)\n" % [rank, str(entry["level"]), str(entry["top_stat"]), str(entry["top_val"]), str(entry.get("date", "").left(10))]
		rank += 1
	if text == "":
		text = "\n(Aún no hay puntuaciones registradas)\n¡Sobrevive a la mazmorra para entrar al ranking!"

	var lb := Label.new()
	lb.text = text
	if _font_cinzel:
		lb.add_theme_font_override("font", _font_cinzel)
	lb.add_theme_font_size_override("font_size", 12)
	lb.add_theme_color_override("font_color", Color(0.88, 0.84, 0.9))
	lb.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lb.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.add_child(lb)

	var close_btn := Button.new()
	close_btn.text = "CERRAR"
	close_btn.custom_minimum_size = Vector2(200, 44)
	close_btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	_style_modal_button(close_btn)
	close_btn.pressed.connect(func():
		AudioManager.play_click()
		root.queue_free()
	)
	vbox.add_child(close_btn)

# ------------------------------------------------------------------------------
# GENERACIÓN DE TEXTURAS DE BOTONES PROCEDURALES
# ------------------------------------------------------------------------------
func _make_button(w: int, h: int, state: String = "normal") -> ImageTexture:
	var img := Image.create(w, h, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))

	var stone := Color(0.12, 0.1, 0.08)
	var edge := Color(0.35, 0.28, 0.2)
	var gold := Color(0.65, 0.5, 0.2)
	var border := 2

	if state == "hover":
		stone = Color(0.2, 0.14, 0.22)
		edge = Color(0.5, 0.38, 0.4)
		gold = Color(0.85, 0.7, 0.3)
	elif state == "pressed":
		stone = Color(0.08, 0.06, 0.05)
		edge = Color(0.2, 0.15, 0.12)
		gold = Color(0.4, 0.3, 0.1)

	for y in h:
		for x in w:
			var col: Color
			if x < border or x >= w - border or y < border or y >= h - border:
				col = edge
			else:
				var pattern := (int(x * 0.3) + int(y * 0.3)) % 3
				col = stone if pattern != 0 else stone.lerp(Color(0.25, 0.2, 0.16), 0.3)
			img.set_pixel(x, y, col)

	# Esquineras doradas ornamentales
	var corners := [[2, 2], [w - 5, 2], [2, h - 5], [w - 5, h - 5]]
	for c in corners:
		var cx: int = c[0]
		var cy: int = c[1]
		for j in 4:
			for k in 2:
				var px: int = cx + j
				var py: int = cy + k
				if px >= 0 and px < w and py >= 0 and py < h:
					img.set_pixel(px, py, gold)
				px = cx
				py = cy + j
				if px >= 0 and px < w and py >= 0 and py < h:
					img.set_pixel(px, py, gold)

	return ImageTexture.create_from_image(img)

static func _slider_val_to_db(val: float) -> float:
	if val <= 0.0: return -80.0
	var t := val / 100.0
	return -80.0 * (1.0 - t) * (1.0 - t)

static func _db_to_slider_val(db: float) -> float:
	if db <= -80.0: return 0.0
	return (1.0 - sqrt(db / -80.0)) * 100.0
