extends CanvasLayer

var _player_level: int = 1
var _player_xp: int = 0
var _top_stat: String = ""
var _top_stat_val: int = 0

func _ready() -> void:
	process_mode = PROCESS_MODE_ALWAYS
	_build_ui()

func set_stats(level: int, fire: int, ice: int, hp: int, mana: int, regen: int) -> void:
	_player_level = level
	_player_xp = fire * 50 + ice * 50
	var stats := {"Fuego": fire, "Hielo": ice, "Vida": hp, "Maná": mana, "Regen": regen}
	var best_key: String = ""
	var best_val: int = 0
	for k in stats:
		if stats[k] > best_val:
			best_val = stats[k]
			best_key = k
	_top_stat = best_key
	_top_stat_val = best_val
	_save_score()
	_update_display()

func _save_score() -> void:
	var scores := _load_scores()
	var entry := {
		"level": _player_level,
		"xp": _player_xp,
		"top_stat": _top_stat,
		"top_val": _top_stat_val,
		"date": Time.get_datetime_string_from_system()
	}
	scores.append(entry)
	scores.sort_custom(func(a, b): return a["level"] > b["level"] or (a["level"] == b["level"] and a["xp"] > b["xp"]))
	if scores.size() > 10:
		scores.resize(10)
	var file := FileAccess.open("user://leaderboard.json", FileAccess.WRITE)
	if file:
		file.store_line(JSON.stringify(scores))

func _load_scores() -> Array:
	var file := FileAccess.open("user://leaderboard.json", FileAccess.READ)
	if file == null:
		return []
	var text := file.get_as_text()
	var json := JSON.new()
	if json.parse(text) != OK:
		return []
	return json.data if json.data is Array else []

func _build_ui() -> void:
	var overlay := ColorRect.new()
	overlay.color = Color(0, 0, 0, 0.85)
	overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(overlay)

	var panel := PanelContainer.new()
	panel.set_anchors_preset(Control.PRESET_CENTER, false)
	panel.position = Vector2(-220, -160)
	panel.size = Vector2(440, 320)
	var panel_bg := StyleBoxFlat.new()
	panel_bg.bg_color = Color(0.06, 0.04, 0.08, 0.95)
	panel_bg.border_width_left = 2
	panel_bg.border_width_top = 2
	panel_bg.border_width_right = 2
	panel_bg.border_width_bottom = 2
	panel_bg.border_color = Color(0.4, 0.2, 0.5, 0.8)
	add_child(panel)

	var title := Label.new()
	title.text = "GAME OVER"
	title.add_theme_font_size_override("font_size", 28)
	title.add_theme_color_override("font_color", Color(0.8, 0.15, 0.15))
	title.set_anchors_preset(Control.PRESET_CENTER, false)
	title.position = Vector2(-100, -150)
	title.size = Vector2(200, 36)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	add_child(title)

	var stats_label := Label.new()
	stats_label.name = "StatsText"
	stats_label.add_theme_font_size_override("font_size", 14)
	stats_label.add_theme_color_override("font_color", Color(0.7, 0.6, 0.8))
	stats_label.set_anchors_preset(Control.PRESET_CENTER, false)
	stats_label.position = Vector2(-200, -100)
	stats_label.size = Vector2(400, 100)
	add_child(stats_label)

	var lb_title := Label.new()
	lb_title.text = "— MEJORES PUNTAJES —"
	lb_title.add_theme_font_size_override("font_size", 12)
	lb_title.add_theme_color_override("font_color", Color(0.5, 0.4, 0.6))
	lb_title.set_anchors_preset(Control.PRESET_CENTER, false)
	lb_title.position = Vector2(-150, -10)
	lb_title.size = Vector2(300, 20)
	lb_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	add_child(lb_title)

	var lb_label := Label.new()
	lb_label.name = "LeaderboardText"
	lb_label.add_theme_font_size_override("font_size", 11)
	lb_label.add_theme_color_override("font_color", Color(0.6, 0.5, 0.7))
	lb_label.set_anchors_preset(Control.PRESET_CENTER, false)
	lb_label.position = Vector2(-200, 15)
	lb_label.size = Vector2(400, 100)
	lb_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	add_child(lb_label)

	var retry_btn := TextureButton.new()
	retry_btn.texture_normal = _make_btn_tex("normal")
	retry_btn.texture_hover = _make_btn_tex("hover")
	retry_btn.texture_pressed = _make_btn_tex("pressed")
	retry_btn.size = Vector2(200, 36)
	retry_btn.custom_minimum_size = Vector2(200, 36)
	retry_btn.set_anchors_preset(Control.PRESET_CENTER, false)
	retry_btn.position = Vector2(-100, 120)
	retry_btn.pressed.connect(_on_retry)
	add_child(retry_btn)

	var retry_label := Label.new()
	retry_label.text = "INTENTAR DE NUEVO"
	retry_label.add_theme_font_size_override("font_size", 13)
	retry_label.add_theme_color_override("font_color", Color(0.85, 0.8, 0.7))
	retry_label.set_anchors_preset(Control.PRESET_CENTER, false)
	retry_label.position = Vector2(-80, 128)
	retry_label.size = Vector2(160, 20)
	retry_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	add_child(retry_label)

	var quit_btn := TextureButton.new()
	quit_btn.texture_normal = _make_btn_tex("normal")
	quit_btn.texture_hover = _make_btn_tex("hover")
	quit_btn.texture_pressed = _make_btn_tex("pressed")
	quit_btn.size = Vector2(200, 36)
	quit_btn.custom_minimum_size = Vector2(200, 36)
	quit_btn.set_anchors_preset(Control.PRESET_CENTER, false)
	quit_btn.position = Vector2(-100, 165)
	quit_btn.pressed.connect(_on_quit)
	add_child(quit_btn)

	var quit_label := Label.new()
	quit_label.text = "SALIR"
	quit_label.add_theme_font_size_override("font_size", 13)
	quit_label.add_theme_color_override("font_color", Color(0.85, 0.8, 0.7))
	quit_label.set_anchors_preset(Control.PRESET_CENTER, false)
	quit_label.position = Vector2(-80, 173)
	quit_label.size = Vector2(160, 20)
	quit_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	add_child(quit_label)

func _make_btn_tex(state: String) -> ImageTexture:
	var w := 200
	var h := 36
	var img := Image.create(w, h, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	var stone := Color(0.12, 0.1, 0.08)
	var edge := Color(0.28, 0.23, 0.18)
	var gold := Color(0.55, 0.42, 0.2)
	if state == "hover":
		stone = Color(0.18, 0.12, 0.2)
		edge = Color(0.4, 0.3, 0.35)
		gold = Color(0.7, 0.55, 0.3)
	elif state == "pressed":
		stone = Color(0.08, 0.06, 0.05)
		edge = Color(0.2, 0.15, 0.12)
	for y in h:
		for x in w:
			if x < 2 or x >= w - 2 or y < 2 or y >= h - 2:
				img.set_pixel(x, y, edge)
			else:
				img.set_pixel(x, y, stone)
	for c in [[2, 2], [w - 4, 2], [2, h - 4], [w - 4, h - 4]]:
		for j in 4:
			for k in 2:
				var px: int = c[0] + j
				var py: int = c[1] + k
				if px >= 0 and px < w and py >= 0 and py < h:
					img.set_pixel(px, py, gold)
				px = c[0]
				py = c[1] + j
				if px >= 0 and px < w and py >= 0 and py < h:
					img.set_pixel(px, py, gold)
	if state == "hover":
		for y in h:
			for x in w:
				if x >= 2 and y >= 2 and x < w - 2 and y < h - 2:
					var col := img.get_pixel(x, y)
					img.set_pixel(x, y, col.lerp(Color(0.5, 0.15, 0.8, 0.2), 0.4))
	return ImageTexture.create_from_image(img)

func _update_display() -> void:
	var stats_node: Label = get_node("StatsText")
	if stats_node:
		stats_node.text = "Nivel: " + str(_player_level) + "\nXP: " + str(_player_xp) + "\nMejora: " + _top_stat + " +" + str(_top_stat_val)

	var lb_node: Label = get_node("LeaderboardText")
	if lb_node:
		var scores := _load_scores()
		var text := ""
		var rank := 1
		for entry in scores:
			var name: String = "TÚ" if entry["level"] == _player_level and entry["xp"] == _player_xp else "Jugador"
			text += "#" + str(rank) + "  " + name + "  LV " + str(entry["level"]) + "  " + str(entry["top_stat"]) + " +" + str(entry["top_val"]) + "\n"
			rank += 1
		lb_node.text = text if text else "(sin datos)"

func _on_retry() -> void:
	get_tree().paused = false
	get_tree().reload_current_scene()

func _on_quit() -> void:
	get_tree().paused = false
	get_tree().change_scene_to_file("res://scenes/main_menu.tscn")
