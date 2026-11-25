extends Node

const BASE = "res://art/HUD/"

var _cache: Dictionary = {}

func _ready() -> void:
	_ensure_dirs()
	_generate_all_placeholders()

func _ensure_dirs() -> void:
	var dirs := ["critical", "high", "medium", "low", "buttons"]
	for d in dirs:
		var full := ProjectSettings.globalize_path(BASE + d)
		if not DirAccess.dir_exists_absolute(full):
			DirAccess.make_dir_recursive_absolute(full)

func load_asset(path: String, fallback: Callable = Callable()) -> Texture2D:
	if _cache.has(path):
		return _cache[path]
	# Try loading from disk via filesystem (works for runtime-saved PNGs)
	var full_fs := ProjectSettings.globalize_path(BASE + path)
	if FileAccess.file_exists(full_fs):
		var img := Image.load_from_file(full_fs)
		if img:
			var tex := ImageTexture.create_from_image(img)
			_cache[path] = tex
			return tex
	# Fallback to procedural generation
	if fallback.is_valid():
		var tex = fallback.call()
		if tex:
			_cache[path] = tex
		return tex
	return null

var _anim_lib_cache: Dictionary = {}

func get_skeleton_anim_library(skel_path: String) -> AnimationLibrary:
	if _anim_lib_cache.has(skel_path):
		return _anim_lib_cache[skel_path]

	var lib = AnimationLibrary.new()
	var paths = {
		"idle": "res://models/skeleton/anim/Skeleton_Idle.fbx",
		"walk": "res://models/skeleton/anim/Skeleton_Walking.fbx",
		"attack": "res://models/skeleton/anim/Steleton_Attack.fbx",
		"die": "res://models/skeleton/anim/Skeleton_Dying.fbx",
	}
	const BONE_MAP: Dictionary = {
		"mixamorig_Hips": "spine",
		"mixamorig_Spine": "spine.001",
		"mixamorig_Spine1": "spine.002",
		"mixamorig_Spine2": "spine.003",
		"mixamorig_Neck": "spine.004",
		"mixamorig_Head": "spine.005",
		"mixamorig_HeadTop_End": "spine.006",
		"mixamorig_LeftShoulder": "shoulder.L",
		"mixamorig_LeftArm": "upper_arm.L",
		"mixamorig_LeftForeArm": "forearm.L",
		"mixamorig_LeftHand": "hand.L",
		"mixamorig_RightShoulder": "shoulder.R",
		"mixamorig_RightArm": "upper_arm.R",
		"mixamorig_RightForeArm": "forearm.R",
		"mixamorig_RightHand": "hand.R",
		"mixamorig_LeftUpLeg": "thigh.L",
		"mixamorig_LeftLeg": "shin.L",
		"mixamorig_LeftFoot": "foot.L",
		"mixamorig_LeftToeBase": "toe.L",
		"mixamorig_RightUpLeg": "thigh.R",
		"mixamorig_RightLeg": "shin.R",
		"mixamorig_RightFoot": "foot.R",
		"mixamorig_RightToeBase": "toe.R",
	}

	for name in paths:
		var res = load(paths[name])
		var anim: Animation = null
		if res is Animation:
			anim = res
		elif res is PackedScene:
			var inst = res.instantiate()
			var ap = inst.find_child("AnimationPlayer", true, false) as AnimationPlayer
			if ap:
				var anim_names = ap.get_animation_list()
				if anim_names.size() > 0:
					anim = ap.get_animation(anim_names[0])
			inst.queue_free()
		if anim:
			anim = anim.duplicate()
			# Strip position tracks
			var i = anim.get_track_count() - 1
			while i >= 0:
				if anim.track_get_type(i) == Animation.TYPE_POSITION_3D:
					anim.remove_track(i)
				i -= 1
			# Remap bones to target skeleton path
			var t = anim.get_track_count() - 1
			while t >= 0:
				var pstr = str(anim.track_get_path(t))
				var col_pos = pstr.find(":")
				if col_pos == -1:
					t -= 1
					continue
				var bone_name = pstr.substr(col_pos + 1)
				var mapped = BONE_MAP.get(bone_name, "")
				if mapped == "" or mapped == "spine":
					anim.remove_track(t)
					t -= 1
					continue
				var new_p = NodePath(skel_path + ":" + mapped)
				anim.track_set_path(t, new_p)
				t -= 1
			anim.loop_mode = Animation.LOOP_LINEAR if name in ["idle", "walk"] else Animation.LOOP_NONE
			lib.add_animation(name, anim)

	_anim_lib_cache[skel_path] = lib
	return lib

func _generate_all_placeholders() -> void:
	# Critical - spell icons
	_save_if_missing("critical/fireball_56.png", _gen_icon_fireball(56))
	_save_if_missing("critical/icewall_56.png", _gen_icon_icewall(56))
	_save_if_missing("critical/icelance_56.png", _gen_icon_icelance(56))
	_save_if_missing("critical/blackhole_56.png", _gen_icon_blackhole(56))
	_save_if_missing("critical/segador_56.png", _gen_icon_segador(56))
	_save_if_missing("critical/devorador_56.png", _gen_icon_devorador(56))
	_save_if_missing("critical/crosshair_48.png", _gen_crosshair(48))
	_save_if_missing("critical/rune_fire_48.png", _gen_rune_fire(48))
	_save_if_missing("critical/rune_ice_48.png", _gen_rune_ice(48))
	_save_if_missing("critical/rune_void_48.png", _gen_rune_void(48))

	# High - HUD elements
	_save_if_missing("high/globe_hp_fill_96.png", _gen_globe_fill(96, Color(0.7, 0.05, 0.05)))
	_save_if_missing("high/globe_hp_frame_96.png", _gen_globe_frame(96, false))
	_save_if_missing("high/globe_mp_fill_96.png", _gen_globe_fill(96, Color(0.05, 0.1, 0.7)))
	_save_if_missing("high/globe_mp_frame_96.png", _gen_globe_frame(96, true))
	_save_if_missing("high/slot_frame_64.png", _gen_slot_frame(64))
	_save_if_missing("high/banner_400x120.png", _gen_banner(400, 120))
	_save_if_missing("high/xp_fill_320x14.png", _gen_xp_fill(320, 14))
	_save_if_missing("high/xp_frame_320x14.png", _gen_xp_frame(320, 14))

	# Buttons
	_save_if_missing("buttons/menu_240x48_normal.png", _gen_button(240, 48, "normal"))
	_save_if_missing("buttons/menu_240x48_hover.png", _gen_button(240, 48, "hover"))
	_save_if_missing("buttons/menu_240x48_pressed.png", _gen_button(240, 48, "pressed"))
	_save_if_missing("buttons/gameover_200x36_normal.png", _gen_button(200, 36, "normal"))
	_save_if_missing("buttons/gameover_200x36_hover.png", _gen_button(200, 36, "hover"))
	_save_if_missing("buttons/gameover_200x36_pressed.png", _gen_button(200, 36, "pressed"))
	_save_if_missing("buttons/upgrade_320x50_normal.png", _gen_button(320, 50, "normal"))
	_save_if_missing("buttons/upgrade_320x50_hover.png", _gen_button(320, 50, "hover"))
	_save_if_missing("buttons/upgrade_320x50_pressed.png", _gen_button(320, 50, "pressed"))

	# Medium
	_save_if_missing("medium/grimoire_800x600.png", _gen_grimoire(800, 600))
	_save_if_missing("medium/gameover_panel_440x320.png", _gen_panel_bg(440, 320, Color(0.06, 0.04, 0.08, 0.95)))
	_save_if_missing("medium/upgrade_panel_360x280.png", _gen_panel_bg(360, 280, Color(0.08, 0.06, 0.1, 0.95)))
	_save_if_missing("medium/leaderboard_400x300.png", _gen_panel_bg(400, 300, Color(0.06, 0.04, 0.08, 0.95)))
	_save_if_missing("medium/close_btn_28.png", _gen_close_btn(28, "normal"))
	_save_if_missing("medium/close_btn_28_hover.png", _gen_close_btn(28, "hover"))

	# Low
	_save_if_missing("low/vortex_128.png", _gen_vortex(128))
	_save_if_missing("low/healthbar3d_64x12.png", _gen_healthbar3d(64, 12))

func _save_if_missing(rel_path: String, img: Image) -> void:
	var full_path := ProjectSettings.globalize_path(BASE + rel_path)
	if FileAccess.file_exists(full_path):
		return
	var dir := full_path.get_base_dir()
	if not DirAccess.dir_exists_absolute(dir):
		DirAccess.make_dir_recursive_absolute(dir)
	img.save_png(full_path)

# ─── Icon generators ───────────────────────────────────────

func _gen_icon_fireball(s: int) -> Image:
	var img := Image.create(s, s, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	var cx := s / 2; var cy := s / 2; var r := s / 2 - 3
	for y in s:
		for x in s:
			var dx := x - cx; var dy := y - cy
			var dist := sqrt(dx * dx + dy * dy)
			if dist <= r:
				var angle := atan2(dy, dx)
				var flame := sin(angle * 5.0 + PI) * 0.3 + 0.7
				var edge_dist := dist / r
				var bright := (1.0 - edge_dist) * flame
				var col: Color
				if bright > 0.6: col = Color(1.0, 0.95, 0.6, 0.9)
				elif bright > 0.3: col = Color(1.0, 0.5, 0.05, 0.85)
				else: col = Color(0.8, 0.15, 0.02, 0.7 * bright * 3.0)
				img.set_pixel(x, y, col)
			elif dist <= r + 2:
				var angle := atan2(dy, dx)
				var fl := sin(angle * 6.0 + PI * 0.3) * 0.5 + 0.5
				if fl > 0.7:
					var t := (dist - r) / 2.0
					img.set_pixel(x, y, Color(0.9 - t * 0.5, 0.3 - t * 0.2, 0.02, 0.6 - t * 0.4))
	return img

func _gen_icon_icewall(s: int) -> Image:
	var img := Image.create(s, s, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	var cx := s / 2; var cy := s / 2
	var crystals := [[0, -1, 0.8, 8], [-1, 0.5, 0.6, 7], [1, 0.3, 0.5, 6]]
	for c in crystals:
		var ox: int = c[0] * 8; var oy: int = c[1] * 8
		var h: int = c[3]; var w: int = 3
		var tip_y := cy + oy - h; var base_y := cy + oy
		for y in range(tip_y, base_y):
			var t := float(y - tip_y) / float(base_y - tip_y)
			var half_w := int(w * (1.0 - t * 0.7))
			var left := cx + ox - half_w; var right := cx + ox + half_w
			for x in range(left, right + 1):
				if x >= 0 and x < s and y >= 0 and y < s:
					var bright := 0.5 + 0.5 * (1.0 - t)
					img.set_pixel(x, y, Color(0.4 * bright, 0.7 * bright, 1.0 * bright, 0.9))
	return img

func _gen_icon_icelance(s: int) -> Image:
	var img := Image.create(s, s, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	var cx := s / 2; var cy := s / 2
	var h := s / 2 - 2; var half_w := 6
	var tip_y := cy - h; var base_y := cy + h
	for y in range(tip_y, base_y):
		var t := float(y - tip_y) / float(base_y - tip_y)
		var hex_w := int(half_w * (1.0 - absf(t - 0.5) * 0.6))
		var left := cx - hex_w; var right := cx + hex_w
		for x in range(left, right + 1):
			if x >= 0 and x < s and y >= 0 and y < s:
				var bright := 0.6 + 0.4 * (1.0 - absf(t - 0.5) * 2.0)
				img.set_pixel(x, y, Color(0.3 * bright, 0.8 * bright, 1.0 * bright, 0.9))
	for y in range(tip_y + 2, base_y - 2):
		var t := float(y - tip_y) / float(base_y - tip_y)
		var hex_w := int(half_w * (1.0 - absf(t - 0.5) * 0.6))
		if hex_w > 2:
			img.set_pixel(cx + 1, y, Color(0.8, 1.0, 1.0, 0.6))
	return img

func _gen_icon_blackhole(s: int) -> Image:
	var img := Image.create(s, s, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	var cx := s / 2; var cy := s / 2; var r := s / 2 - 3
	for y in s:
		for x in s:
			var dx := x - cx; var dy := y - cy
			var dist := sqrt(dx * dx + dy * dy)
			if dist <= r:
				var angle := atan2(dy, dx)
				var spiral := cos(angle * 3.0 + dist * 0.3) * 0.5 + 0.5
				var edge := dist / r
				var bright := (1.0 - edge) * (0.3 + 0.7 * spiral)
				var purple := Color(0.5 * bright, 0.15 * bright, 0.7 * bright, 0.9)
				var dark := Color(0.02, 0.0, 0.04, 0.95)
				img.set_pixel(x, y, purple.lerp(dark, edge * 0.8))
	for y in s:
		for x in s:
			var dx := x - cx; var dy := y - cy
			var dist := sqrt(dx * dx + dy * dy)
			var ring_r := r * 0.35; var ring_w := 2.0
			if absf(dist - ring_r) < ring_w:
				var t := 1.0 - absf(dist - ring_r) / ring_w
				var angle := atan2(dy, dx)
				var glow := t * (0.5 + 0.5 * sin(angle * 4.0 + PI))
				img.set_pixel(x, y, Color(0.6 * glow, 0.2 * glow, 0.9 * glow, 0.8))
	return img

func _gen_icon_segador(s: int) -> Image:
	var img := Image.create(s, s, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	var cx := s / 2; var cy := s / 2; var r := s / 2 - 3
	for y in s:
		for x in s:
			var dx := x - cx; var dy := y - cy
			var dist := sqrt(dx * dx + dy * dy)
			if dist <= r:
				var angle := atan2(dy, dx)
				var pat := sin(angle * 4.0 + PI * 0.5) * 0.5 + 0.5
				var edge := dist / r
				var bright := (1.0 - edge) * (0.4 + 0.6 * pat)
				img.set_pixel(x, y, Color(0.9 * bright, 0.05 * bright, 0.05 * bright, 0.9))
			elif dist <= r + 2:
				var pat := sin(dx * 0.5 + dy * 0.3) * 0.5 + 0.5
				if pat > 0.65:
					var t := (dist - r) / 2.0
					img.set_pixel(x, y, Color(0.8 - t * 0.6, 0.03, 0.03, 0.5 - t * 0.3))
	return img

func _gen_icon_devorador(s: int) -> Image:
	var img := Image.create(s, s, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	var cx := s / 2; var cy := s / 2; var r := s / 2 - 3
	for y in s:
		for x in s:
			var dx := x - cx; var dy := y - cy
			var dist := sqrt(dx * dx + dy * dy)
			if dist <= r:
				var angle := atan2(dy, dx)
				var spiral := cos(angle * 5.0 + dist * 0.4) * 0.5 + 0.5
				var edge := dist / r
				var bright := (1.0 - edge) * (0.3 + 0.7 * spiral)
				img.set_pixel(x, y, Color(0.5 * bright, 0.1 * bright, 0.8 * bright, 0.9))
	for y in s:
		for x in s:
			var dx := x - cx; var dy := y - cy
			var dist := sqrt(dx * dx + dy * dy)
			var ring_r := r * 0.7; var ring_w := 2.0
			if absf(dist - ring_r) < ring_w:
				var t := 1.0 - absf(dist - ring_r) / ring_w
				var angle := atan2(dy, dx)
				var star := sin(angle * 5.0 + PI * 0.5) * 0.5 + 0.5
				var glow := t * star
				img.set_pixel(x, y, Color(0.7 * glow, 0.15 * glow, 1.0 * glow, 0.8))
	return img

func _gen_crosshair(s: int) -> Image:
	var img := Image.create(s, s, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	var cx := s / 2; var cy := s / 2
	var outer := s / 2 - 1; var inner := 4
	var metal := Color(0.4, 0.35, 0.3); var bright_m := Color(0.55, 0.5, 0.45)
	for y in s:
		for x in s:
			var dx := x - cx; var dy := y - cy
			var dist := sqrt(dx * dx + dy * dy)
			if dist >= outer - 2 and dist <= outer:
				var t := 1.0 - absf(dist - (outer - 1)) / 2.0
				var col := metal.lerp(bright_m, t)
				img.set_pixel(x, y, Color(col.r, col.g, col.b, 0.7 * t))
			var ax := absf(dx); var ay := absf(dy)
			if (ax <= 1 and ay >= inner and ay <= outer) or (ay <= 1 and ax >= inner and ax <= outer):
				img.set_pixel(x, y, Color(0.5, 0.45, 0.4, 0.7))
			if dist <= 2:
				var t := 1.0 - dist / 2.0
				img.set_pixel(x, y, Color(0.7, 0.6, 0.5, t * 0.6))
	return img

func _gen_rune_fire(s: int) -> Image:
	var img := Image.create(s, s, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	var cx := s / 2; var cy := s / 2
	for y in s:
		for x in s:
			var dx := x - cx; var dy := y - cy
			var dist := sqrt(dx * dx + dy * dy)
			if dist > s / 2 - 1: continue
			var angle := atan2(dy, dx)
			var pat := sin(angle * 3.0) * cos(dist * 0.3) * 0.5 + 0.5
			var edge := dist / (s / 2)
			var bright := pat * (1.0 - edge * 0.5)
			if bright > 0.3:
				img.set_pixel(x, y, Color(1.0 * bright, 0.3 * bright, 0.02 * bright, bright * 0.9))
	return img

func _gen_rune_ice(s: int) -> Image:
	var img := Image.create(s, s, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	var cx := s / 2; var cy := s / 2
	for y in s:
		for x in s:
			var dx := x - cx; var dy := y - cy
			var dist := sqrt(dx * dx + dy * dy)
			if dist > s / 2 - 1: continue
			var angle := atan2(dy, dx)
			var pat := absf(cos(angle * 2.0)) * (1.0 - dist / (s / 2))
			var sharp := pow(pat, 2.0) * 1.5
			if sharp > 0.2:
				img.set_pixel(x, y, Color(0.3 * sharp, 0.8 * sharp, 1.0 * sharp, minf(sharp, 0.9)))
	return img

func _gen_rune_void(s: int) -> Image:
	var img := Image.create(s, s, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	var cx := s / 2; var cy := s / 2
	for y in s:
		for x in s:
			var dx := x - cx; var dy := y - cy
			var dist := sqrt(dx * dx + dy * dy)
			if dist > s / 2 - 1: continue
			var angle := atan2(dy, dx)
			var spiral := sin(angle * 2.0 + dist * 0.5) * 0.5 + 0.5
			var edge := 1.0 - dist / (s / 2)
			var bright := spiral * edge * 1.2
			if bright > 0.15:
				img.set_pixel(x, y, Color(0.5 * bright, 0.1 * bright, 0.8 * bright, minf(bright, 0.85)))
	return img

func _gen_globe_fill(size: int, col: Color) -> Image:
	var img := Image.create(size, size, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	var cx := size / 2; var cy := size / 2; var r := size / 2 - 8
	for y in size:
		for x in size:
			var dx := x - cx; var dy := y - cy
			if dx * dx + dy * dy <= r * r:
				var nx := float(dx) / r; var ny := float(dy) / r
				var shade := 0.7 + 0.3 * (1.0 - sqrt(nx * nx + ny * ny))
				img.set_pixel(x, y, Color(col.r * shade, col.g * shade, col.b * shade, 0.9))
	return img

func _gen_globe_frame(size: int, bat: bool) -> Image:
	var img := Image.create(size, size, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	var cx := size / 2; var cy := size / 2
	var ro := size / 2 - 2; var ri := ro - 6
	for y in size:
		for x in size:
			var dx := x - cx; var dy := y - cy
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
	return img

func _gen_slot_frame(s: int) -> Image:
	var img := Image.create(s, s, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	var b := 4; var stone := Color(0.12, 0.1, 0.08); var edge := Color(0.28, 0.23, 0.18); var gold := Color(0.55, 0.42, 0.2)
	for y in s:
		for x in s:
			if x < b or x >= s - b or y < b or y >= s - b:
				var d := mini(mini(x, s - 1 - x), mini(y, s - 1 - y))
				var t := float(d) / float(b)
				img.set_pixel(x, y, stone.lerp(edge, t))
	for c in [[2, 2], [s - 3, 2], [2, s - 3], [s - 3, s - 3]]:
		for j in 3:
			for k in 2:
				var px: int = c[0] + j; var py: int = c[1] + k
				if px >= 0 and px < s and py >= 0 and py < s:
					img.set_pixel(px, py, gold)
	return img

func _gen_banner(w: int, h: int) -> Image:
	var img := Image.create(w, h, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	var cx := w / 2; var cy := h / 2
	var stone := Color(0.1, 0.08, 0.06); var gold := Color(0.55, 0.42, 0.2); var bright := Color(0.7, 0.55, 0.3)
	for y in h:
		for x in w:
			var nx := float(x) / w; var ny := float(y) / h
			var wx := absf(nx - 0.5) * 2.0; var wy := (ny - 0.5) * 2.0
			if wx > 0.5:
				var wing_x := (wx - 0.5) * 2.0
				var wing_curve := sin(wing_x * PI * 0.8) * 0.3 + 0.3
				var wing_upper := -wing_curve + 0.1; var wing_lower := wing_curve - 0.1
				if wy > wing_upper and wy < wing_lower:
					var pat := sin(x * 0.5 + y * 0.3) * 0.3 + 0.7
					img.set_pixel(x, y, Color(0.15 * pat, 0.12 * pat, 0.1 * pat))
					var edge_pat := sin(x * 0.8 + y * 0.6) * 0.5 + 0.5
					var edge_dist := mini(absf(wy - wing_upper), absf(wy - wing_lower))
					if edge_dist < 0.02 or edge_pat > 0.85:
						img.set_pixel(x, y, Color(0.3, 0.22, 0.15))
			if wx < 0.5:
				var border := 3
				if x < border or x >= w - border or y < border or y >= h - border:
					img.set_pixel(x, y, gold)
				else:
					var stone_pat := (int(x * 0.2) + int(y * 0.2)) % 4
					img.set_pixel(x, y, stone if stone_pat != 0 else stone.lerp(Color(0.15, 0.12, 0.1), 0.3))
			var joint_x := absf(nx - 0.5)
			if joint_x < 0.04 and (absf(wy) < 0.03 or absf(absf(wy) - 0.35) < 0.03 or absf(absf(wy) - 0.25) < 0.03):
				img.set_pixel(x, y, bright)
	return img

func _gen_xp_fill(w: int, h: int) -> Image:
	var img := Image.create(w, h, false, Image.FORMAT_RGBA8)
	for y in h:
		for x in w:
			if y < 1 or y >= h - 1:
				img.set_pixel(x, y, Color(0, 0, 0, 0))
			else:
				var t = float(x) / w
				var r = 0.5 + 0.2 * sin(t * PI)
				img.set_pixel(x, y, Color(r * 0.9, r * 0.15, r * 0.7, 0.95))
	return img

func _gen_xp_frame(w: int, h: int) -> Image:
	var img := Image.create(w, h, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	for y in h:
		for x in w:
			if x < 1 or x >= w - 1 or y < 1 or y >= h - 1:
				img.set_pixel(x, y, Color(0.25, 0.15, 0.3, 0.9))
			elif y == 2 or y == h - 3:
				img.set_pixel(x, y, Color(0.4, 0.25, 0.5, 0.5))
	return img

func _gen_button(w: int, h: int, state: String) -> Image:
	var img := Image.create(w, h, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	var stone := Color(0.12, 0.1, 0.08); var edge := Color(0.3, 0.25, 0.2); var gold := Color(0.55, 0.42, 0.2)
	var border := 2
	if state == "hover":
		stone = Color(0.18, 0.12, 0.2); edge = Color(0.4, 0.3, 0.35); gold = Color(0.7, 0.55, 0.3)
	elif state == "pressed":
		stone = Color(0.08, 0.06, 0.05); edge = Color(0.2, 0.15, 0.12); gold = Color(0.35, 0.25, 0.1)
	for y in h:
		for x in w:
			if x < border or x >= w - border or y < border or y >= h - border:
				img.set_pixel(x, y, edge)
			else:
				var pattern := (int(x * 0.3) + int(y * 0.3)) % 3
				img.set_pixel(x, y, stone if pattern != 0 else stone.lerp(Color(0.2, 0.17, 0.14), 0.3))
	var corners := [[2, 2], [w - 4, 2], [2, h - 4], [w - 4, h - 4]]
	for c in corners:
		for j in 4:
			for k in 2:
				var px: int = c[0] + j; var py: int = c[1] + k
				if px >= 0 and px < w and py >= 0 and py < h:
					img.set_pixel(px, py, gold)
				px = c[0]; py = c[1] + j
				if px >= 0 and px < w and py >= 0 and py < h:
					img.set_pixel(px, py, gold)
	if state == "hover":
		for y in h:
			for x in w:
				var edge_dist := mini(mini(x, w - 1 - x), mini(y, h - 1 - y))
				if edge_dist > 4:
					img.set_pixel(x, y, img.get_pixel(x, y).lerp(Color(0.5, 0.15, 0.8, 0.15), 0.5))
	return img

func _gen_grimoire(w: int, h: int) -> Image:
	var img := Image.create(w, h, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	var cx := w / 2; var spine_w := 20; var spine_l := cx - spine_w / 2; var spine_r := cx + spine_w / 2; var margin := 8
	_draw_wood_bg(img, w, h)
	_draw_spine(img, w, h, spine_l, spine_r)
	_draw_page(img, margin, margin + 4, spine_l - margin, h - margin - 4)
	_draw_page(img, spine_r + margin, margin + 4, w - margin, h - margin - 4)
	var left_cx := (0 + spine_l) / 2; var left_cy := h / 2
	_draw_triangle_diagram(img, left_cx, left_cy, 70)
	return img

func _draw_wood_bg(img: Image, w: int, h: int) -> void:
	for y in h:
		for x in w:
			var noise := sin(x * 0.05 + y * 0.07) * 0.03 + sin(x * 0.11 + y * 0.04) * 0.02
			var r := 0.08 + noise; var g := 0.04 + noise * 0.7; var b := 0.02 + noise * 0.5
			var nx := float(x) / w; var ny := float(y) / h
			var edge := mini(mini(nx, 1.0 - nx), mini(ny, 1.0 - ny)) * 3.0
			if edge < 1.0:
				var t := 1.0 - edge; r -= t * 0.03; g -= t * 0.02; b -= t * 0.01
			img.set_pixel(x, y, Color(clampf(r, 0.0, 1.0), clampf(g, 0.0, 1.0), clampf(b, 0.0, 1.0), 1.0))

func _draw_spine(img: Image, _w: int, h: int, spine_l: int, spine_r: int) -> void:
	for y in h:
		for x in range(spine_l, spine_r):
			var t := float(x - spine_l) / float(spine_r - spine_l)
			var leather := Color(0.05, 0.025, 0.015).lerp(Color(0.1, 0.05, 0.03), 1.0 - absf(t - 0.5) * 2.0)
			var noise := sin(x * 0.3 + y * 0.5) * 0.01
			leather.r += noise; leather.g += noise * 0.7
			if y % 8 == 0 or y % 8 == 1:
				leather = leather.lerp(Color(0.03, 0.015, 0.01), 0.4)
			img.set_pixel(x, y, leather)

func _draw_page(img: Image, x1: int, y1: int, x2: int, y2: int) -> void:
	var pw := x2 - x1; var ph := y2 - y1
	for y in range(y1, y2):
		for x in range(x1, x2):
			var base := Color(0.38, 0.34, 0.18)
			var noise := sin(x * 0.08 + y * 0.06) * 0.03 + sin(x * 0.15 + y * 0.12) * 0.02
			base.r += noise; base.g += noise * 0.8; base.b += noise * 0.4
			var nx := float(x - x1) / pw; var ny := float(y - y1) / ph
			var edge_dist := mini(mini(nx, 1.0 - nx), mini(ny, 1.0 - ny))
			if edge_dist < 0.04:
				var t := edge_dist / 0.04
				img.set_pixel(x, y, base.lerp(Color(0.18, 0.14, 0.08), 1.0 - t))
			else:
				img.set_pixel(x, y, base)

func _draw_triangle_diagram(img: Image, cx2: int, cy2: int, size: int) -> void:
	var tip := Vector2(cx2, cy2 + int(size * 0.85))
	var tl := Vector2(cx2 - int(size * 0.75), cy2 - int(size * 0.4))
	var tr := Vector2(cx2 + int(size * 0.75), cy2 - int(size * 0.4))
	var inner_col := Color(0.45, 0.9, 1.0, 0.95)
	var mid_col := Color(0.2, 0.5, 0.85, 0.5)
	var outer_col := Color(0.05, 0.15, 0.4, 0.0)
	var line_half := 4.0; var glow_radius := 16.0
	var min_x := maxi(0, mini(mini(tl.x, tr.x), tip.x) - int(glow_radius) - 2)
	var max_x := mini(img.get_width() - 1, maxi(maxi(tl.x, tr.x), tip.x) + int(glow_radius) + 2)
	var min_y := maxi(0, mini(mini(tl.y, tr.y), tip.y) - int(glow_radius) - 2)
	var max_y := mini(img.get_height() - 1, maxi(maxi(tl.y, tr.y), tip.y) + int(glow_radius) + 2)
	for y in range(min_y, max_y + 1):
		for x in range(min_x, max_x + 1):
			var d1 := _pt_seg_dist(x, y, tl, tip)
			var d2 := _pt_seg_dist(x, y, tip, tr)
			var d3 := _pt_seg_dist(x, y, tl, tr)
			var min_dist := mini(mini(d1, d2), d3)
			if min_dist < glow_radius:
				var existing := img.get_pixel(x, y)
				var t := min_dist / glow_radius
				var col: Color
				if min_dist < line_half:
					var lt := min_dist / line_half
					col = inner_col.lerp(Color(inner_col.r, inner_col.g, inner_col.b, 0.6), lt)
					col.r *= 0.95 + sin(x * 0.3 + y * 0.5) * 0.05
					col.g *= 0.95 + sin(x * 0.3 + y * 0.5) * 0.05
				else:
					var gt := (min_dist - line_half) / (glow_radius - line_half)
					col = mid_col.lerp(outer_col, gt)
					col.a *= 0.85 + sin(x * 0.2 + y * 0.35) * 0.15
				img.set_pixel(x, y, col.blend(existing))

static func _pt_seg_dist(px: float, py: float, a: Vector2, b: Vector2) -> float:
	var ab := b - a; var ap := Vector2(px - a.x, py - a.y)
	var t := ap.dot(ab) / ab.length_squared()
	t = clampf(t, 0.0, 1.0)
	var closest := a + ab * t
	return sqrt((px - closest.x) * (px - closest.x) + (py - closest.y) * (py - closest.y))

func _gen_close_btn(s: int, state: String) -> Image:
	var img := Image.create(s, s, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	var x_col := Color(0.55, 0.42, 0.3); var bg := Color(0.08, 0.05, 0.04)
	if state == "hover":
		x_col = Color(0.85, 0.6, 0.35); bg = Color(0.15, 0.1, 0.08)
	var half := s / 2
	for y in s:
		for x in s:
			var dx := x - half; var dy := y - half
			if dx * dx + dy * dy > half * half: continue
			if absf(dx - dy) <= 1 or absf(dx + dy) <= 1:
				img.set_pixel(x, y, x_col)
			else:
				img.set_pixel(x, y, bg)
	return img

func _gen_vortex(s: int) -> Image:
	var img := Image.create(s, s, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	var cx := s / 2; var cy := s / 2; var r := s / 2 - 2
	for y in s:
		for x in s:
			var dx := x - cx; var dy := y - cy
			var dist := sqrt(dx * dx + dy * dy)
			if dist <= r:
				var angle := atan2(dy, dx)
				var spiral := sin(angle * 3.0 + dist * 0.4) * 0.5 + 0.5
				var edge := dist / r
				var bright := (1.0 - edge) * (0.3 + 0.7 * spiral)
				img.set_pixel(x, y, Color(0.8 * bright, 0.05 * bright, 0.05 * bright, 0.9))
	return img

func _gen_healthbar3d(w: int, h: int) -> Image:
	var img := Image.create(w, h, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	for y in h:
		for x in w:
			if x < 1 or x >= w - 1 or y < 1 or y >= h - 1:
				img.set_pixel(x, y, Color(0.2, 0.15, 0.1, 0.8))
			else:
				img.set_pixel(x, y, Color(0.1, 0.08, 0.05, 0.6))
	return img

func _gen_panel_bg(w: int, h: int, bg_col: Color) -> Image:
	var img := Image.create(w, h, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	var border := 3
	var border_col := Color(0.4, 0.2, 0.5, 0.8)
	var edge_col := Color(0.25, 0.12, 0.35, 0.9)
	for y in h:
		for x in w:
			if x < border or x >= w - border or y < border or y >= h - border:
				var d := mini(mini(x, w - 1 - x), mini(y, h - 1 - y))
				var t := float(d) / float(border)
				img.set_pixel(x, y, border_col.lerp(edge_col, t))
			else:
				var noise := sin(x * 0.04 + y * 0.06) * 0.01
				img.set_pixel(x, y, Color(bg_col.r + noise, bg_col.g + noise * 0.8, bg_col.b + noise * 0.5, bg_col.a))
	return img
