extends Control

var _bg_tex: ImageTexture
var _btn_normal: ImageTexture
var _btn_hover: ImageTexture
var _btn_pressed: ImageTexture
var _title_text: String = "DEMON SUMMONER"
var _subtitle_text: String = "A Dark Fantasy Ritual"

func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	_generate_all()
	_build_ui()

func _generate_all() -> void:
	_bg_tex = _generate_background(1024, 768)
	_btn_normal = _make_button(240, 48, "normal")
	_btn_hover = _make_button(240, 48, "hover")
	_btn_pressed = _make_button(240, 48, "pressed")

func _generate_background(w: int, h: int) -> ImageTexture:
	var img := Image.create(w, h, false, Image.FORMAT_RGBA8)
	img.fill(Color(0.02, 0.01, 0.03))
	
	for y in h:
		for x in w:
			var nx := float(x) / w
			var ny := float(y) / h
			var col: Color
			
			# sky gradient (top to mid)
			var sky := Color(0.04, 0.01, 0.06).lerp(Color(0.01, 0.0, 0.02), ny * 2.0)
			
			# floor fog (bottom 40%)
			var fog_h := 0.4
			var fog_ny := (ny - (1.0 - fog_h)) / fog_h
			var floor_color := Color(0.03, 0.01, 0.05)
			
			if ny < 1.0 - fog_h:
				col = sky
			else:
				var fog := clampf(fog_ny, 0.0, 1.0)
				var fog_pat := sin(nx * 8.0 + ny * 3.0) * 0.3 + 0.5
				var fog_col := Color(0.15, 0.05, 0.25).lerp(Color(0.08, 0.02, 0.15), fog_pat)
				col = floor_color.lerp(fog_col, fog)
			
			# stone pillars (left + right)
			var pillar_left := nx < 0.12
			var pillar_right := nx > 0.88
			var pillar_w := 0.08
			var pillar_edge := 2.0
			if (nx < 0.12 and nx > 0.04) or (nx > 0.88 and nx < 0.96):
				var stone_noise := sin(x * 0.3 + y * 0.7) * 0.08 + sin(x * 1.1 + y * 0.4) * 0.04
				var stone := Color(0.12 + stone_noise, 0.1 + stone_noise, 0.08 + stone_noise)
				col = col.lerp(stone, 0.9)
				# pillar edge highlight
				var d_left := absf(nx - 0.04)
				var d_right := absf(nx - 0.12)
				var d_pillar := mini(d_left, d_right) * 15.0
				if d_pillar < 1.0:
					col = col.lerp(Color(0.3, 0.2, 0.15), 1.0 - d_pillar)
			
			# torchlight glow on pillars
			var torch_pos := Vector2(0.08, 0.5)
			var tdx := nx - torch_pos.x
			var tdy := ny - torch_pos.y
			var tdist := sqrt(tdx * tdx + tdy * tdy) * 3.0
			if tdist < 1.0:
				var glow := (1.0 - tdist) * 0.3
				col = col.lerp(Color(1.0, 0.5, 0.1), glow)
			
			torch_pos = Vector2(0.92, 0.5)
			tdx = nx - torch_pos.x
			tdy = ny - torch_pos.y
			tdist = sqrt(tdx * tdx + tdy * tdy) * 3.0
			if tdist < 1.0:
				var glow := (1.0 - tdist) * 0.3
				col = col.lerp(Color(1.0, 0.5, 0.1), glow)
			
			# wizard silhouette (center)
			var wx := (nx - 0.5) * 2.0
			var wy := (ny - 0.35) * 3.0
			if _is_in_wizard(wx, wy):
				col = Color(0.01, 0.0, 0.02).lerp(col, 0.3)
				# staff glow
				var sx := (nx - 0.5) * 2.0 + 0.08
				var sy := (ny - 0.15) * 3.0
				var sdist := sqrt(sx * sx + sy * sy) * 2.5
				if sdist < 1.0:
					var sglow := (1.0 - sdist) * 0.5
					col = col.lerp(Color(0.6, 0.2, 0.9), sglow)
			
			img.set_pixel(x, y, col)
	
	return ImageTexture.create_from_image(img)

func _is_in_wizard(x: float, y: float) -> bool:
	# cloak body
	if y > 0.1 and y < 0.8 and absf(x) < 0.12 * (1.0 - (y - 0.1) * 0.5):
		return true
	# head
	if y > -0.1 and y < 0.15 and sqrt(x * x + y * y) < 0.08:
		return true
	# hat (pointed)
	if y > -0.45 and y < -0.05 and absf(x) < 0.07 * (1.0 - absf(y + 0.25) * 1.5):
		return true
	# staff (vertical line)
	if y > 0.0 and y < 0.8 and absf(x - 0.08) < 0.015:
		return true
	return false

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

func _build_ui() -> void:
	var bg := TextureRect.new()
	bg.texture = _bg_tex
	bg.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	bg.stretch_mode = TextureRect.STRETCH_SCALE
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg)

	var fog_panel := ColorRect.new()
	fog_panel.color = Color(0.08, 0.02, 0.15, 0.15)
	fog_panel.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(fog_panel)

	var title := Label.new()
	title.text = _title_text
	title.add_theme_font_size_override("font_size", 36)
	title.add_theme_color_override("font_color", Color(0.7, 0.5, 0.9))
	title.set_anchors_preset(Control.PRESET_CENTER, false)
	title.position = Vector2(-200, -180)
	title.size = Vector2(400, 50)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	add_child(title)

	var subtitle := Label.new()
	subtitle.text = _subtitle_text
	subtitle.add_theme_font_size_override("font_size", 14)
	subtitle.add_theme_color_override("font_color", Color(0.5, 0.35, 0.7, 0.7))
	subtitle.set_anchors_preset(Control.PRESET_CENTER, false)
	subtitle.position = Vector2(-180, -140)
	subtitle.size = Vector2(360, 30)
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	add_child(subtitle)

	var buttons := [
		["JUGAR", "_on_play"],
		["PUNTAJES", "_on_scores"],
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

		add_child(btn)

func _on_play() -> void:
	get_tree().change_scene_to_file("res://world.tscn")

func _on_scores() -> void:
	_show_leaderboard()

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
	var bg := StyleBoxFlat.new()
	bg.bg_color = Color(0.06, 0.04, 0.08, 0.95)
	bg.border_width_left = 2
	bg.border_width_top = 2
	bg.border_width_right = 2
	bg.border_width_bottom = 2
	bg.border_color = Color(0.4, 0.2, 0.5, 0.8)
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
