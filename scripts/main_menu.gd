extends Control

var _bg_tex: Texture2D
var _title_tex: Texture2D
var _btn_normal: ImageTexture
var _btn_hover: ImageTexture
var _btn_pressed: ImageTexture
var _title_shader: Shader
var _music_player: AudioStreamPlayer

func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	_generate_all()
	_build_ui()

func _generate_all() -> void:
	_bg_tex = load("res://sprites/Main menu bg 2.jpg")
	_title_tex = load("res://sprites/Title_bg_white.jpg")
	_title_shader = load("res://shaders/title_chroma_key.gdshader")
	_btn_normal = AssetLoader.load_asset("buttons/menu_240x48_normal.png", func(): return _make_button(240, 48, "normal"))
	_btn_hover = AssetLoader.load_asset("buttons/menu_240x48_hover.png", func(): return _make_button(240, 48, "hover"))
	_btn_pressed = AssetLoader.load_asset("buttons/menu_240x48_pressed.png", func(): return _make_button(240, 48, "pressed"))
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

func _build_ui() -> void:
	var bg := TextureRect.new()
	bg.texture = _bg_tex
	bg.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	bg.stretch_mode = TextureRect.STRETCH_SCALE
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg)

	if _title_tex and _title_shader:
		var title_rect := TextureRect.new()
		title_rect.texture = _title_tex
		title_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		title_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		title_rect.set_anchors_preset(Control.PRESET_CENTER, false)
		title_rect.position = Vector2(-256, -300)
		title_rect.size = Vector2(512, 280)
		var mat := ShaderMaterial.new()
		mat.shader = _title_shader
		title_rect.material = mat
		add_child(title_rect)

	var buttons := [
		["JUGAR", "_on_play"],
		["PUNTAJES", "_on_scores"],
		["CONFIGURACIÓN", "_on_settings"],
		["SALIR", "_on_quit"],
	]

	for i in buttons.size():
		var label: String = buttons[i][0]
		var signal_name: String = buttons[i][1]
		
		var btn := TextureButton.new()
		btn.texture_normal = _btn_normal
		btn.texture_hover = _btn_hover
		btn.texture_pressed = _btn_pressed
		btn.stretch_mode = TextureButton.STRETCH_KEEP
		btn.custom_minimum_size = Vector2(240, 48)
		btn.size = Vector2(240, 48)
		
		btn.set_anchors_preset(Control.PRESET_CENTER, false)
		btn.position = Vector2(-120, 50 + i * 60)
		
		var btn_label := Label.new()
		btn_label.text = label
		btn_label.add_theme_font_size_override("font_size", 16)
		btn_label.add_theme_color_override("font_color", Color(0.85, 0.8, 0.7))
		btn_label.set_anchors_preset(Control.PRESET_FULL_RECT)
		btn_label.offset_left = 10
		btn_label.offset_top = 5
		btn_label.offset_right = -10
		btn_label.offset_bottom = -5
		btn_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		btn_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		btn.add_child(btn_label)

		btn.pressed.connect(Callable(self, signal_name))
		btn.mouse_entered.connect(func(): AudioManager.play_hover())
		btn.pressed.connect(func(): AudioManager.play_click())

		add_child(btn)

	# N box - bottom right
	var n_box := PanelContainer.new()
	n_box.custom_minimum_size = Vector2(60, 60)
	n_box.size = Vector2(60, 60)
	var n_bg := StyleBoxFlat.new()
	n_bg.bg_color = Color(0, 0, 0, 1.0)
	n_bg.border_width_left = 1
	n_bg.border_width_top = 1
	n_bg.border_width_right = 1
	n_bg.border_width_bottom = 1
	n_bg.border_color = Color(0.3, 0.3, 0.3)
	n_box.add_theme_stylebox_override("panel", n_bg)
	n_box.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	n_box.offset_left = -70
	n_box.offset_top = -70
	n_box.offset_right = -10
	n_box.offset_bottom = -10
	add_child(n_box)

	var n_label := Label.new()
	n_label.text = "N"
	n_label.add_theme_font_size_override("font_size", 28)
	n_label.add_theme_color_override("font_color", Color(1, 1, 1))
	n_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	n_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	n_label.set_anchors_preset(Control.PRESET_FULL_RECT)
	var mono := SystemFont.new()
	mono.font_names = PackedStringArray(["Consolas", "Courier New", "monospace"])
	mono.font_italic = true
	n_label.add_theme_font_override("font", mono)
	n_box.add_child(n_label)

func _make_button(w: int, h: int, state: String = "normal") -> ImageTexture:
	var img := Image.create(w, h, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))

	var stone := Color(0.12, 0.1, 0.08)
	var edge := Color(0.3, 0.25, 0.2)
	var gold := Color(0.55, 0.42, 0.2)
	var border := 2

	if state == "hover":
		stone = Color(0.18, 0.12, 0.2)
		edge = Color(0.4, 0.3, 0.35)
		gold = Color(0.7, 0.55, 0.3)
	elif state == "pressed":
		stone = Color(0.08, 0.06, 0.05)
		edge = Color(0.2, 0.15, 0.12)
		gold = Color(0.35, 0.25, 0.1)

	for y in h:
		for x in w:
			var col: Color
			if x < border or x >= w - border or y < border or y >= h - border:
				col = edge
			else:
				var pattern := (int(x * 0.3) + int(y * 0.3)) % 3
				col = stone if pattern != 0 else stone.lerp(Color(0.2, 0.17, 0.14), 0.3)
			img.set_pixel(x, y, col)

	# gold corner filigree
	var corners := [[2, 2], [w - 4, 2], [2, h - 4], [w - 4, h - 4]]
	for c in corners:
		var cx: int = c[0]
		var cy: int = c[1]
		for j in 4:
			for k in 2:
				var px: int = cx + j
				var py: int = cy + k
				if px >= 0 and px < w and py >= 0 and py < h:
					img.set_pixel(px, py, gold)
				# mirror for L-shape
				px = cx
				py = cy + j
				if px >= 0 and px < w and py >= 0 and py < h:
					img.set_pixel(px, py, gold)

	# hover glow overlay
	if state == "hover":
		for y in h:
			for x in w:
				var edge_dist := mini(mini(x, w - 1 - x), mini(y, h - 1 - y))
				if edge_dist > 4:
					var col := img.get_pixel(x, y)
					var glow := Color(0.5, 0.15, 0.8, 0.15)
					img.set_pixel(x, y, col.lerp(glow, 0.5))

	return ImageTexture.create_from_image(img)

func _on_play() -> void:
	if _music_player and _music_player.playing:
		var tween = create_tween()
		tween.tween_property(_music_player, "volume_db", -40.0, 0.5)
		tween.tween_callback(func(): _music_player.stop())
		await tween.finished
	get_tree().change_scene_to_file("res://world.tscn")

func _on_scores() -> void:
	_show_leaderboard()

func _on_settings() -> void:
	_show_settings()

func _on_quit() -> void:
	get_tree().quit()

func _load_scores() -> Array:
	var file := FileAccess.open("user://leaderboard.json", FileAccess.READ)
	if file == null:
		return []
	var text := file.get_as_text()
	var json := JSON.new()
	if json.parse(text) != OK:
		return []
	return json.data if json.data is Array else []

func _show_leaderboard() -> void:
	var root := Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(root)

	var overlay := ColorRect.new()
	overlay.color = Color(0, 0, 0, 0.6)
	overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.add_child(overlay)

	var panel := PanelContainer.new()
	panel.set_anchors_preset(Control.PRESET_CENTER, false)
	panel.position = Vector2(-200, -150)
	panel.size = Vector2(400, 300)
	var panel_tex := AssetLoader.load_asset("medium/leaderboard_400x300.png")
	if panel_tex:
		var bg := StyleBoxTexture.new()
		bg.texture = panel_tex
		bg.modulate_color = Color(1, 1, 1, 0.95)
		panel.add_theme_stylebox_override("panel", bg)
	root.add_child(panel)

	var title := Label.new()
	title.text = "MEJORES PUNTAJES"
	title.add_theme_font_size_override("font_size", 16)
	title.add_theme_color_override("font_color", Color(0.7, 0.5, 0.9))
	title.set_anchors_preset(Control.PRESET_CENTER, false)
	title.position = Vector2(-120, -135)
	title.size = Vector2(240, 24)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	root.add_child(title)

	var scores := _load_scores()
	var text := ""
	var rank := 1
	for entry in scores:
		text += "#" + str(rank) + "  LV " + str(entry["level"]) + "  " + str(entry["top_stat"]) + " +" + str(entry["top_val"]) + "  (" + str(entry.get("date", "").left(10)) + ")\n"
		rank += 1
	if text == "":
		text = "(sin datos)"

	var lb := Label.new()
	lb.text = text
	lb.add_theme_font_size_override("font_size", 12)
	lb.add_theme_color_override("font_color", Color(0.6, 0.5, 0.7))
	lb.set_anchors_preset(Control.PRESET_CENTER, false)
	lb.position = Vector2(-180, -100)
	lb.size = Vector2(360, 180)
	lb.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	root.add_child(lb)

	var close_btn := TextureButton.new()
	close_btn.texture_normal = _btn_normal
	close_btn.texture_hover = _btn_hover
	close_btn.texture_pressed = _btn_pressed
	close_btn.size = Vector2(120, 32)
	close_btn.custom_minimum_size = Vector2(120, 32)
	close_btn.set_anchors_preset(Control.PRESET_CENTER, false)
	close_btn.position = Vector2(-60, 95)
	close_btn.pressed.connect(root.queue_free)
	close_btn.mouse_entered.connect(func(): AudioManager.play_hover())
	close_btn.pressed.connect(func(): AudioManager.play_click())
	root.add_child(close_btn)

	var close_lbl := Label.new()
	close_lbl.text = "CERRAR"
	close_lbl.add_theme_font_size_override("font_size", 12)
	close_lbl.add_theme_color_override("font_color", Color(0.85, 0.8, 0.7))
	close_lbl.set_anchors_preset(Control.PRESET_CENTER, false)
	close_lbl.position = Vector2(-40, 101)
	close_lbl.size = Vector2(80, 20)
	close_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	root.add_child(close_lbl)

func _show_settings() -> void:
	var root := Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(root)

	var overlay := ColorRect.new()
	overlay.color = Color(0, 0, 0, 0.6)
	overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	root.add_child(overlay)

	var panel := PanelContainer.new()
	panel.set_anchors_preset(Control.PRESET_CENTER, false)
	panel.position = Vector2(-200, -155)
	panel.size = Vector2(400, 310)
	var panel_tex := AssetLoader.load_asset("medium/leaderboard_400x300.png")
	if panel_tex:
		var bg := StyleBoxTexture.new()
		bg.texture = panel_tex
		bg.modulate_color = Color(1, 1, 1, 0.95)
		panel.add_theme_stylebox_override("panel", bg)
	root.add_child(panel)

	var title := Label.new()
	title.text = "CONFIGURACIÓN"
	title.add_theme_font_size_override("font_size", 16)
	title.add_theme_color_override("font_color", Color(0.7, 0.5, 0.9))
	title.set_anchors_preset(Control.PRESET_CENTER, false)
	title.position = Vector2(-170, -140)
	title.size = Vector2(340, 24)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	root.add_child(title)

	var music_label := Label.new()
	music_label.text = "MÚSICA"
	music_label.add_theme_font_size_override("font_size", 14)
	music_label.add_theme_color_override("font_color", Color(0.85, 0.8, 0.7))
	music_label.set_anchors_preset(Control.PRESET_CENTER, false)
	music_label.position = Vector2(-165, -95)
	music_label.size = Vector2(80, 24)
	root.add_child(music_label)

	var music_slider := HSlider.new()
	music_slider.name = "MusicSlider"
	music_slider.min_value = 0.0
	music_slider.max_value = 100.0
	music_slider.value = _db_to_slider_val(AudioManager.get_music_volume_db())
	music_slider.step = 1.0
	music_slider.set_anchors_preset(Control.PRESET_CENTER, false)
	music_slider.position = Vector2(-80, -95)
	music_slider.size = Vector2(200, 24)
	music_slider.add_theme_color_override("background_color", Color(0.15, 0.12, 0.1))
	music_slider.add_theme_color_override("grabber_color", Color(0.6, 0.4, 0.7))
	music_slider.add_theme_color_override("grabber_highlight_color", Color(0.7, 0.5, 0.9))
	music_slider.add_theme_stylebox_override("slider", _make_slider_bg())
	music_slider.drag_ended.connect(_on_music_slider_changed.bind(music_slider))
	root.add_child(music_slider)

	var music_val := Label.new()
	music_val.name = "MusicVal"
	music_val.text = str(int(music_slider.value)) + "%"
	music_val.add_theme_font_size_override("font_size", 12)
	music_val.add_theme_color_override("font_color", Color(0.6, 0.5, 0.7))
	music_val.set_anchors_preset(Control.PRESET_CENTER, false)
	music_val.position = Vector2(130, -95)
	music_val.size = Vector2(50, 24)
	music_val.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	root.add_child(music_val)

	var sfx_label := Label.new()
	sfx_label.text = "EFECTOS"
	sfx_label.add_theme_font_size_override("font_size", 14)
	sfx_label.add_theme_color_override("font_color", Color(0.85, 0.8, 0.7))
	sfx_label.set_anchors_preset(Control.PRESET_CENTER, false)
	sfx_label.position = Vector2(-165, -55)
	sfx_label.size = Vector2(80, 24)
	root.add_child(sfx_label)

	var sfx_slider := HSlider.new()
	sfx_slider.name = "SfxSlider"
	sfx_slider.min_value = 0.0
	sfx_slider.max_value = 100.0
	sfx_slider.value = _db_to_slider_val(AudioManager.get_sfx_volume_db())
	sfx_slider.step = 1.0
	sfx_slider.set_anchors_preset(Control.PRESET_CENTER, false)
	sfx_slider.position = Vector2(-80, -55)
	sfx_slider.size = Vector2(200, 24)
	sfx_slider.add_theme_color_override("background_color", Color(0.15, 0.12, 0.1))
	sfx_slider.add_theme_color_override("grabber_color", Color(0.6, 0.4, 0.7))
	sfx_slider.add_theme_color_override("grabber_highlight_color", Color(0.7, 0.5, 0.9))
	sfx_slider.add_theme_stylebox_override("slider", _make_slider_bg())
	sfx_slider.drag_ended.connect(_on_sfx_slider_changed.bind(sfx_slider))
	root.add_child(sfx_slider)

	var sfx_val := Label.new()
	sfx_val.name = "SfxVal"
	sfx_val.text = str(int(sfx_slider.value)) + "%"
	sfx_val.add_theme_font_size_override("font_size", 12)
	sfx_val.add_theme_color_override("font_color", Color(0.6, 0.5, 0.7))
	sfx_val.set_anchors_preset(Control.PRESET_CENTER, false)
	sfx_val.position = Vector2(130, -55)
	sfx_val.size = Vector2(50, 24)
	sfx_val.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	root.add_child(sfx_val)

	var dist_label := Label.new()
	dist_label.text = "DISTANCIA"
	dist_label.add_theme_font_size_override("font_size", 14)
	dist_label.add_theme_color_override("font_color", Color(0.85, 0.8, 0.7))
	dist_label.set_anchors_preset(Control.PRESET_CENTER, false)
	dist_label.position = Vector2(-165, -15)
	dist_label.size = Vector2(80, 24)
	root.add_child(dist_label)

	var dist_slider := HSlider.new()
	dist_slider.name = "DistSlider"
	dist_slider.min_value = 0.0
	dist_slider.max_value = 2.0
	dist_slider.value = float(DatosJuego.render_distance)
	dist_slider.step = 1.0
	dist_slider.set_anchors_preset(Control.PRESET_CENTER, false)
	dist_slider.position = Vector2(-80, -15)
	dist_slider.size = Vector2(200, 24)
	dist_slider.add_theme_color_override("background_color", Color(0.15, 0.12, 0.1))
	dist_slider.add_theme_color_override("grabber_color", Color(0.6, 0.4, 0.7))
	dist_slider.add_theme_color_override("grabber_highlight_color", Color(0.7, 0.5, 0.9))
	dist_slider.add_theme_stylebox_override("slider", _make_slider_bg())
	root.add_child(dist_slider)

	var dist_val := Label.new()
	dist_val.name = "DistVal"
	var dist_names := ["CORTA", "MEDIA", "LARGA"]
	dist_val.text = dist_names[DatosJuego.render_distance]
	dist_val.add_theme_font_size_override("font_size", 12)
	dist_val.add_theme_color_override("font_color", Color(0.6, 0.5, 0.7))
	dist_val.set_anchors_preset(Control.PRESET_CENTER, false)
	dist_val.position = Vector2(130, -15)
	dist_val.size = Vector2(50, 24)
	dist_val.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	root.add_child(dist_val)

	dist_slider.value_changed.connect(func(val):
		DatosJuego.render_distance = int(val)
		dist_val.text = dist_names[int(val)]
	)

	var close_btn := TextureButton.new()
	close_btn.texture_normal = _btn_normal
	close_btn.texture_hover = _btn_hover
	close_btn.texture_pressed = _btn_pressed
	close_btn.size = Vector2(120, 32)
	close_btn.custom_minimum_size = Vector2(120, 32)
	close_btn.set_anchors_preset(Control.PRESET_CENTER, false)
	close_btn.position = Vector2(-60, 120)
	close_btn.pressed.connect(root.queue_free)
	close_btn.mouse_entered.connect(func(): AudioManager.play_hover())
	close_btn.pressed.connect(func(): AudioManager.play_click())
	root.add_child(close_btn)

	var close_lbl := Label.new()
	close_lbl.text = "CERRAR"
	close_lbl.add_theme_font_size_override("font_size", 12)
	close_lbl.add_theme_color_override("font_color", Color(0.85, 0.8, 0.7))
	close_lbl.set_anchors_preset(Control.PRESET_CENTER, false)
	close_lbl.position = Vector2(-40, 126)
	close_lbl.size = Vector2(80, 20)
	close_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	root.add_child(close_lbl)

func _make_slider_bg() -> StyleBoxFlat:
	var bg := StyleBoxFlat.new()
	bg.bg_color = Color(0.12, 0.1, 0.08)
	bg.border_width_left = 1
	bg.border_width_top = 1
	bg.border_width_right = 1
	bg.border_width_bottom = 1
	bg.border_color = Color(0.3, 0.25, 0.2)
	return bg

func _on_music_slider_changed(_was_dragged: bool, slider: HSlider) -> void:
	var db := _slider_val_to_db(slider.value)
	AudioManager.set_music_volume_db(db)
	var parent := slider.get_parent()
	var val_label := parent.get_node("MusicVal") as Label
	if val_label:
		val_label.text = str(int(slider.value)) + "%"

func _on_sfx_slider_changed(_was_dragged: bool, slider: HSlider) -> void:
	var db := _slider_val_to_db(slider.value)
	AudioManager.set_sfx_volume_db(db)
	var parent := slider.get_parent()
	var val_label := parent.get_node("SfxVal") as Label
	if val_label:
		val_label.text = str(int(slider.value)) + "%"

static func _slider_val_to_db(val: float) -> float:
	if val <= 0.0: return -80.0
	var t := val / 100.0
	return -80.0 * (1.0 - t) * (1.0 - t)

static func _db_to_slider_val(db: float) -> float:
	if db <= -80.0: return 0.0
	return (1.0 - sqrt(db / -80.0)) * 100.0
