extends CanvasLayer

var _overlay: ColorRect
var _menu_container: VBoxContainer
var _guide_container: ColorRect
var _guide_visible: bool = false
var _resume_callback: Callable = Callable()

func _ready() -> void:
	process_mode = PROCESS_MODE_ALWAYS
	visible = false
	_build_ui()

func _build_ui() -> void:
	var screen = DisplayServer.window_get_size()

	_overlay = ColorRect.new()
	_overlay.color = Color(0, 0, 0, 0.7)
	_overlay.size = Vector2(screen.x, screen.y)
	_overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(_overlay)

	_menu_container = VBoxContainer.new()
	_menu_container.position = Vector2(screen.x * 0.5 - 150, screen.y * 0.5 - 200)
	_menu_container.size = Vector2(300, 400)
	_menu_container.add_theme_constant_override("separation", 12)
	_overlay.add_child(_menu_container)

	var title = Label.new()
	title.text = "— P A U S A —"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 40)
	title.add_theme_color_override("font_color", Color(0.85, 0.65, 0.1))
	title.custom_minimum_size = Vector2(300, 60)
	_menu_container.add_child(title)

	_menu_container.add_child(_make_button("REANUDAR", Color(0.7, 0.7, 0.7), _resume))
	_menu_container.add_child(_make_button("CÓMO INVOCAR", Color(0.6, 0.6, 0.8), _toggle_guide))
	_menu_container.add_child(_make_button("CONFIGURACIÓN", Color(0.6, 0.6, 0.8), _show_settings))
	_menu_container.add_child(_make_button("MENÚ PRINCIPAL", Color(0.6, 0.6, 0.8), _go_main_menu))
	_menu_container.add_child(_make_button("SALIR", Color(0.6, 0.4, 0.4), _quit))

	_build_guide()

func _build_guide() -> void:
	var screen = DisplayServer.window_get_size()
	_guide_container = ColorRect.new()
	_guide_container.color = Color(0.05, 0.02, 0.08, 0.95)
	_guide_container.size = Vector2(screen.x * 0.7, screen.y * 0.75)
	_guide_container.position = Vector2(screen.x * 0.15, screen.y * 0.12)
	_guide_container.mouse_filter = Control.MOUSE_FILTER_STOP
	_guide_container.visible = false
	_overlay.add_child(_guide_container)

	var scroll = ScrollContainer.new()
	scroll.size = Vector2(_guide_container.size.x - 20, _guide_container.size.y - 80)
	scroll.position = Vector2(10, 10)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_guide_container.add_child(scroll)

	var guide_vbox = VBoxContainer.new()
	guide_vbox.size = Vector2(scroll.size.x - 20, 0)
	guide_vbox.custom_minimum_size = Vector2(scroll.size.x - 20, 0)
	scroll.add_child(guide_vbox)

	var guide_title = Label.new()
	guide_title.text = "I N V O C A C I O N E S"
	guide_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	guide_title.add_theme_font_size_override("font_size", 28)
	guide_title.add_theme_color_override("font_color", Color(0.85, 0.65, 0.1))
	guide_title.custom_minimum_size = Vector2(guide_vbox.size.x, 50)
	guide_vbox.add_child(guide_title)

	guide_vbox.add_child(_make_section("SEGADOR DE SANGRE", "Esbirro cuerpo a cuerpo", Color(0.8, 0.15, 0.1), [
		"Invocación directa con tecla R",
		"Costo: 20% de la vida actual",
		"Duración: 30 segundos",
		"Cooldown: 30 segundos",
		"HP: 300",
		"Ataque: Lanza vórtice de sangre cada 10s",
		"",
		"Cómo usar:",
		"  1. Presiona R para invocar al Segador",
		"  2. Gasta 20% de tu HP actual",
		"  3. El Segador aparece frente a ti",
	]))

	guide_vbox.add_child(_make_section("DEVORADOR DE ALMAS", "Demonio de área devastador", Color(0.5, 0.05, 0.7), [
		"Solo se invoca con el pentagrama (↑ ↓ ← ↑ ↓)",
		"",
		"Requisito: 50 almas cosechadas",
		"Duración: 4 segundos de festín",
		"Daño: 35 de pulso cada 0.5s a todos los enemigos cercanos",
		"",
		"Cómo usar:",
		"  1. Mata enemigos para cosechar almas (blancas)",
		"  2. Cuando tengas 50, el pentagrama aparece en el HUD",
		"  3. Pulsa F para seleccionar NECROMANCIA",
		"  4. Dibuja ↑ ↓ ← ↑ ↓ con Shift + mouse",
		"  5. El Devorador aparece en tu posición",
	]))

	var spacer = Control.new()
	spacer.custom_minimum_size = Vector2(0, 10)
	guide_vbox.add_child(spacer)

	var close_guide = Button.new()
	close_guide.text = "CERRAR"
	close_guide.custom_minimum_size = Vector2(200, 40)
	close_guide.pressed.connect(_toggle_guide)
	close_guide.pressed.connect(AudioManager.play_click)
	close_guide.mouse_entered.connect(AudioManager.play_hover)
	close_guide.add_theme_color_override("font_color", Color(0.8, 0.8, 0.8))
	close_guide.add_theme_font_size_override("font_size", 16)
	guide_vbox.add_child(close_guide)

func _make_section(title: String, subtitle: String, color: Color, lines: Array[String]) -> VBoxContainer:
	var section = VBoxContainer.new()
	section.custom_minimum_size = Vector2(0, 0)
	section.add_theme_constant_override("separation", 3)

	var t = Label.new()
	t.text = title
	t.add_theme_font_size_override("font_size", 22)
	t.add_theme_color_override("font_color", color)
	section.add_child(t)

	var sub = Label.new()
	sub.text = subtitle
	sub.add_theme_font_size_override("font_size", 14)
	sub.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7))
	section.add_child(sub)

	for line in lines:
		var l = Label.new()
		l.text = line
		l.add_theme_font_size_override("font_size", 13)
		l.add_theme_color_override("font_color", Color(0.85, 0.85, 0.85))
		section.add_child(l)

	var spacer = Control.new()
	spacer.custom_minimum_size = Vector2(0, 10)
	section.add_child(spacer)

	return section

func _make_button(text: String, color: Color, callback: Callable) -> Button:
	var btn = Button.new()
	btn.text = text
	btn.custom_minimum_size = Vector2(250, 45)
	btn.add_theme_color_override("font_color", color)
	btn.add_theme_font_size_override("font_size", 18)
	btn.pressed.connect(callback)
	btn.pressed.connect(AudioManager.play_click)
	btn.mouse_entered.connect(AudioManager.play_hover)
	return btn

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel") and visible:
		if _settings_container != null:
			_close_settings()
		elif _guide_visible:
			_toggle_guide()
		else:
			_resume()
		get_viewport().set_input_as_handled()

func _pause() -> void:
	get_tree().paused = true
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	visible = true
	_guide_visible = false
	_guide_container.visible = false
	if _settings_container != null:
		_settings_container.queue_free()
		_settings_container = null

func _resume() -> void:
	get_tree().paused = false
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	visible = false
	_guide_visible = false
	_guide_container.visible = false

func _toggle_guide() -> void:
	_guide_visible = not _guide_visible
	_guide_container.visible = _guide_visible
	_menu_container.visible = not _guide_visible

func _go_main_menu() -> void:
	get_tree().paused = false
	get_tree().change_scene_to_file("res://scenes/main_menu.tscn")

func _quit() -> void:
	get_tree().quit()

var _settings_container: ColorRect = null
var _settings_visible: bool = false

func _show_settings() -> void:
	if _settings_container != null:
		_settings_container.queue_free()
	_settings_container = ColorRect.new()
	_settings_container.color = Color(0.05, 0.02, 0.08, 0.95)
	var screen = DisplayServer.window_get_size()
	_settings_container.size = Vector2(400, 310)
	_settings_container.position = Vector2(screen.x * 0.5 - 200, screen.y * 0.5 - 155)
	_settings_container.mouse_filter = Control.MOUSE_FILTER_STOP
	_overlay.add_child(_settings_container)
	_menu_container.visible = false

	var title := Label.new()
	title.text = "CONFIGURACIÓN"
	title.add_theme_font_size_override("font_size", 18)
	title.add_theme_color_override("font_color", Color(0.85, 0.65, 0.1))
	title.set_anchors_preset(Control.PRESET_CENTER, false)
	title.position = Vector2(30, 15)
	title.size = Vector2(340, 28)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_settings_container.add_child(title)

	_make_setting_slider("MÚSICA", AudioManager.get_music_volume_db(), Vector2(30, 60), _on_pause_slider_changed.bind("MÚSICAVal", AudioManager.set_music_volume_db), _settings_container)
	_make_setting_slider("EFECTOS", AudioManager.get_sfx_volume_db(), Vector2(30, 105), _on_pause_slider_changed.bind("EFECTOSVal", AudioManager.set_sfx_volume_db), _settings_container)
	_make_distance_slider(Vector2(30, 150), _settings_container)

	var close_btn := Button.new()
	close_btn.text = "CERRAR"
	close_btn.custom_minimum_size = Vector2(200, 36)
	close_btn.set_anchors_preset(Control.PRESET_CENTER, false)
	close_btn.position = Vector2(100, 230)
	close_btn.pressed.connect(_close_settings)
	close_btn.pressed.connect(AudioManager.play_click)
	close_btn.mouse_entered.connect(AudioManager.play_hover)
	close_btn.add_theme_color_override("font_color", Color(0.8, 0.8, 0.8))
	close_btn.add_theme_font_size_override("font_size", 14)
	_settings_container.add_child(close_btn)

func _make_distance_slider(pos: Vector2, parent: Control) -> void:
	var lbl := Label.new()
	lbl.text = "DISTANCIA"
	lbl.add_theme_font_size_override("font_size", 14)
	lbl.add_theme_color_override("font_color", Color(0.85, 0.8, 0.7))
	lbl.position = pos
	lbl.size = Vector2(80, 28)
	parent.add_child(lbl)

	var slider := HSlider.new()
	slider.min_value = 0.0
	slider.max_value = 2.0
	slider.value = float(DatosJuego.render_distance)
	slider.step = 1.0
	slider.position = Vector2(pos.x + 90, pos.y)
	slider.size = Vector2(180, 28)
	slider.add_theme_color_override("grabber_color", Color(0.6, 0.4, 0.7))
	slider.add_theme_color_override("grabber_highlight_color", Color(0.7, 0.5, 0.9))
	
	var val_label := Label.new()
	var names := ["CORTA", "MEDIA", "LARGA"]
	val_label.text = names[DatosJuego.render_distance]
	val_label.add_theme_font_size_override("font_size", 12)
	val_label.add_theme_color_override("font_color", Color(0.6, 0.5, 0.7))
	val_label.position = Vector2(pos.x + 280, pos.y)
	val_label.size = Vector2(50, 28)
	val_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	parent.add_child(val_label)
	
	slider.value_changed.connect(func(val):
		DatosJuego.render_distance = int(val)
		val_label.text = names[int(val)]
	)
	parent.add_child(slider)

func _close_settings() -> void:
	if _settings_container:
		_settings_container.queue_free()
		_settings_container = null
	_menu_container.visible = true

func _make_setting_slider(label_text: String, db_val: float, pos: Vector2, callback: Callable, parent: Control) -> void:
	var lbl := Label.new()
	lbl.text = label_text
	lbl.add_theme_font_size_override("font_size", 14)
	lbl.add_theme_color_override("font_color", Color(0.85, 0.8, 0.7))
	lbl.position = Vector2(pos.x, pos.y)
	lbl.size = Vector2(80, 28)
	parent.add_child(lbl)

	var slider := HSlider.new()
	slider.min_value = 0.0
	slider.max_value = 100.0
	slider.value = _db_to_slider_val(db_val)
	slider.step = 1.0
	slider.position = Vector2(pos.x + 90, pos.y)
	slider.size = Vector2(180, 28)
	slider.add_theme_color_override("grabber_color", Color(0.6, 0.4, 0.7))
	slider.add_theme_color_override("grabber_highlight_color", Color(0.7, 0.5, 0.9))
	slider.drag_ended.connect(callback.bind(slider))
	parent.add_child(slider)

	var val_label := Label.new()
	val_label.text = str(int(slider.value)) + "%"
	val_label.add_theme_font_size_override("font_size", 12)
	val_label.add_theme_color_override("font_color", Color(0.6, 0.5, 0.7))
	val_label.position = Vector2(pos.x + 280, pos.y)
	val_label.size = Vector2(50, 28)
	val_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	val_label.name = label_text + "Val"
	parent.add_child(val_label)

func _on_pause_slider_changed(_was_dragged: bool, slider: HSlider, label_name: String, setter: Callable) -> void:
	var db := _slider_val_to_db(slider.value)
	setter.call(db)
	var lbl := _settings_container.get_node(label_name) as Label
	if lbl:
		lbl.text = str(int(slider.value)) + "%"

static func _slider_val_to_db(val: float) -> float:
	if val <= 0.0: return -80.0
	var t := val / 100.0
	return -80.0 * (1.0 - t) * (1.0 - t)

static func _db_to_slider_val(db: float) -> float:
	if db <= -80.0: return 0.0
	return (1.0 - sqrt(db / -80.0)) * 100.0
