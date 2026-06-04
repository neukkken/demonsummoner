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
		"Elemento: NECROMANCIA",
		"Gesto: → (RIGHT) — mover mouse a la derecha con Shift",
		"Costo: 30% de la vida actual",
		"Duración: 30 segundos",
		"Cooldown: 60 segundos",
		"HP: 300",
		"Ataque: Lanza vórtice de sangre cada 10s",
		"",
		"Cómo usar:",
		"  1. Presiona R (NECROMANCIA)",
		"  2. Mantén Shift + arrastra mouse a la derecha",
		"  3. Suelta Shift para invocar",
	]))

	guide_vbox.add_child(_make_section("DEVORADOR DE ALMAS", "Demonio de área devastador", Color(0.5, 0.05, 0.7), [
		"Elemento: NECROMANCIA (automático)",
		"Gesto: ↑ → ↓ → ← → ↑ → ↓ (pentagrama)",
		"  (UP, DOWN, LEFT, UP, DOWN)",
		"Requisito: 10 almas cosechadas",
		"Duración: 4 segundos de festín",
		"Cooldown: 30 segundos",
		"Daño: 35 de pulso cada 0.5s a todos los enemigos cercanos",
		"",
		"Cómo usar:",
		"  1. Mata enemigos para cosechar almas (blancas)",
		"  2. Cuando tengas 10, el pentagrama aparece en el HUD",
		"  3. Con NECROMANCIA activa, dibuja ↑ ↓ ← ↑ ↓",
		"  4. El Devorador aparece en tu posición",
	]))

	var spacer = Control.new()
	spacer.custom_minimum_size = Vector2(0, 10)
	guide_vbox.add_child(spacer)

	var close_guide = Button.new()
	close_guide.text = "CERRAR"
	close_guide.custom_minimum_size = Vector2(200, 40)
	close_guide.pressed.connect(_toggle_guide)
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
	return btn

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel") and visible:
		if _guide_visible:
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
