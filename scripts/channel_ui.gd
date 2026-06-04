extends CanvasLayer

var _progress: float = 0.0
var _direction: String = ""
var _element: String = ""

var _center: Vector2
var _ring: ColorRect
var _ring_progress: ColorRect
var _ring_trail: Array[ColorRect] = []
var _rune_nodes: Dictionary = {}
var _trail_label: Label
var _runes_visible: bool = false

var _rune_textures: Dictionary = {}
var _trail_dots: Array[ColorRect] = []

static var _ring_shader: Shader = null

static func _get_ring_shader() -> Shader:
	if _ring_shader == null:
		_ring_shader = Shader.new()
		_ring_shader.code = "
shader_type canvas_item;
uniform vec4 ring_color : source_color;
uniform float thickness = 0.15;
void fragment() {
	vec2 uv = UV - 0.5;
	float dist = length(uv);
	float ring = 1.0 - smoothstep(thickness - 0.02, thickness, abs(dist - 0.42));
	COLOR = ring_color * ring;
}
"
	return _ring_shader

func _ready() -> void:
	hide()
	_generate_rune_textures()
	_build_ui()

func _generate_rune_textures() -> void:
	_rune_textures["FIRE"] = _make_rune_fire(48)
	_rune_textures["ICE"] = _make_rune_ice(48)
	_rune_textures["VOID"] = _make_rune_void(48)

func _make_rune_fire(s: int) -> ImageTexture:
	var img := Image.create(s, s, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	var cx := s / 2
	var cy := s / 2
	for y in s:
		for x in s:
			var dx := x - cx
			var dy := y - cy
			var dist := sqrt(dx * dx + dy * dy)
			if dist > s / 2 - 1:
				continue
			var angle := atan2(dy, dx)
			var pat := sin(angle * 3.0) * cos(dist * 0.3) * 0.5 + 0.5
			var edge := dist / (s / 2)
			var bright := pat * (1.0 - edge * 0.5)
			if bright > 0.3:
				img.set_pixel(x, y, Color(1.0 * bright, 0.3 * bright, 0.02 * bright, bright * 0.9))
	return ImageTexture.create_from_image(img)

func _make_rune_ice(s: int) -> ImageTexture:
	var img := Image.create(s, s, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	var cx := s / 2
	var cy := s / 2
	for y in s:
		for x in s:
			var dx := x - cx
			var dy := y - cy
			var dist := sqrt(dx * dx + dy * dy)
			if dist > s / 2 - 1:
				continue
			var angle := atan2(dy, dx)
			var pat := absf(cos(angle * 2.0)) * (1.0 - dist / (s / 2))
			var sharp := pow(pat, 2.0) * 1.5
			if sharp > 0.2:
				img.set_pixel(x, y, Color(0.3 * sharp, 0.8 * sharp, 1.0 * sharp, minf(sharp, 0.9)))
	return ImageTexture.create_from_image(img)

func _make_rune_void(s: int) -> ImageTexture:
	var img := Image.create(s, s, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	var cx := s / 2
	var cy := s / 2
	for y in s:
		for x in s:
			var dx := x - cx
			var dy := y - cy
			var dist := sqrt(dx * dx + dy * dy)
			if dist > s / 2 - 1:
				continue
			var angle := atan2(dy, dx)
			var spiral := sin(angle * 2.0 + dist * 0.5) * 0.5 + 0.5
			var edge := 1.0 - dist / (s / 2)
			var bright := spiral * edge * 1.2
			if bright > 0.15:
				img.set_pixel(x, y, Color(0.5 * bright, 0.1 * bright, 0.8 * bright, minf(bright, 0.85)))
	return ImageTexture.create_from_image(img)

func _build_ui() -> void:
	var cs := get_viewport().get_visible_rect().size
	_center = cs * 0.5

	# progress ring background
	_ring = ColorRect.new()
	_ring.color = Color(0.15, 0.12, 0.15, 0.3)
	_ring.size = Vector2(120, 120)
	_ring.position = _center - _ring.size * 0.5
	_ring.material = _make_ring_mat(Color(0.3, 0.25, 0.3, 0.5))
	add_child(_ring)

	# progress arc
	_ring_progress = ColorRect.new()
	_ring_progress.color = Color(0.5, 0.1, 0.3, 0.6)
	_ring_progress.size = Vector2(120, 120)
	_ring_progress.position = _center - _ring_progress.size * 0.5
	_ring_progress.material = _make_ring_mat(Color(0.7, 0.15, 0.4, 0.7))
	add_child(_ring_progress)

	# rotating trail sparks on ring
	for i in 8:
		var spark := ColorRect.new()
		spark.color = Color(0.8, 0.6, 0.2, 0.7)
		spark.size = Vector2(4, 4)
		add_child(spark)
		_ring_trail.append(spark)

	# runes in 4 directions
	var rune_positions := {
		"UP": Vector2(_center.x, _center.y - 80),
		"DOWN": Vector2(_center.x, _center.y + 80),
		"LEFT": Vector2(_center.x - 80, _center.y),
		"RIGHT": Vector2(_center.x + 80, _center.y),
	}
	for dir_name in rune_positions:
		var pos: Vector2 = rune_positions[dir_name]
		var rune_rect := TextureRect.new()
		rune_rect.size = Vector2(36, 36)
		rune_rect.position = pos - rune_rect.size * 0.5
		rune_rect.modulate = Color(0.3, 0.25, 0.35, 0.3)
		var label := Label.new()
		label.text = dir_name
		label.add_theme_font_size_override("font_size", 8)
		label.add_theme_color_override("font_color", Color(0.4, 0.35, 0.45, 0.4))
		label.position = pos + Vector2(-12, 18)
		add_child(rune_rect)
		add_child(label)
		_rune_nodes[dir_name] = rune_rect

	# direction trail text
	_trail_label = Label.new()
	_trail_label.add_theme_font_size_override("font_size", 22)
	_trail_label.add_theme_color_override("font_color", Color(0.8, 0.6, 0.2, 0.6))
	_trail_label.position = _center + Vector2(0, 50)
	_trail_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	add_child(_trail_label)

	# pre-create trail dot pool
	for i in 12:
		var dot := ColorRect.new()
		dot.visible = false
		add_child(dot)
		_trail_dots.append(dot)

func _make_ring_mat(col: Color) -> Material:
	var mat := ShaderMaterial.new()
	mat.shader = _get_ring_shader()
	mat.set_shader_parameter("ring_color", col)
	mat.set_shader_parameter("thickness", 0.15)
	return mat

func update_display(progress: float, direction: String) -> void:
	_progress = progress
	_direction = direction

	var col: Color
	var trail_col: Color
	var element_name: String
	match _element:
		"FIRE":
			col = Color(1.0, 0.35, 0.02)
			trail_col = Color(1.0, 0.5, 0.05)
			element_name = "FIRE"
		"ICE":
			col = Color(0.2, 0.6, 1.0)
			trail_col = Color(0.3, 0.8, 1.0)
			element_name = "ICE"
		"NECROMANCIA":
			col = Color(0.9, 0.1, 0.05)
			trail_col = Color(1.0, 0.2, 0.08)
			element_name = "NECROMANCIA"
		_:
			col = Color(0.6, 0.2, 0.9)
			trail_col = Color(0.5, 0.15, 0.8)
			element_name = "VOID"

	# update ring progress
	var mat := _ring_progress.material as ShaderMaterial
	if mat:
		mat.set_shader_parameter("ring_color", Color(col.r, col.g, col.b, 0.4 + progress * 0.4))
	_ring_progress.modulate = Color(col.r, col.g, col.b, 0.3 + progress * 0.5)

	# trail sparks rotate around ring
	for i in _ring_trail.size():
		var angle := float(i) / _ring_trail.size() * TAU + progress * TAU
		var radius := 56.0
		var sx := _center.x + cos(angle) * radius
		var sy := _center.y + sin(angle) * radius
		var spark := _ring_trail[i]
		spark.position = Vector2(sx - 2, sy - 2)
		spark.color = Color(trail_col.r, trail_col.g, trail_col.b, 0.3 + progress * 0.5)

	# rune activation
	var active_dir: Vector2 = Vector2.ZERO
	var dir_vec: Vector2 = Vector2.ZERO
	match direction:
		"UP":
			active_dir = Vector2(_center.x, _center.y - 80)
			dir_vec = Vector2(0, -1)
		"DOWN":
			active_dir = Vector2(_center.x, _center.y + 80)
			dir_vec = Vector2(0, 1)
		"LEFT":
			active_dir = Vector2(_center.x - 80, _center.y)
			dir_vec = Vector2(-1, 0)
		"RIGHT":
			active_dir = Vector2(_center.x + 80, _center.y)
			dir_vec = Vector2(1, 0)

	for dir_name in _rune_nodes:
		var rune := _rune_nodes[dir_name] as TextureRect
		if dir_name == direction and progress > 0:
			var tex: ImageTexture = _rune_textures.get(element_name)
			if tex:
				rune.texture = tex
			rune.modulate = Color(col.r, col.g, col.b, 0.6 + progress * 0.4)
			rune.size = Vector2(36 + progress * 12, 36 + progress * 12)
			rune.position = active_dir - rune.size * 0.5
		else:
			rune.texture = null
			rune.modulate = Color(0.3, 0.25, 0.35, 0.2)
			rune.size = Vector2(36, 36)

	# direction trail text
	if progress >= 1.0:
		_trail_label.text = "[" + direction + "]"
		_trail_label.modulate = Color(col.r, col.g, col.b, 1.0)
	else:
		_trail_label.text = direction
		_trail_label.modulate = Color(trail_col.r, trail_col.g, trail_col.b, 0.4 + progress * 0.4)

	# trail particles from center toward direction
	_update_trail_particles(dir_vec, trail_col, progress)

func _update_trail_particles(dir: Vector2, col: Color, progress: float) -> void:
	# hide all dots first
	for dot in _trail_dots:
		dot.visible = false

	if progress <= 0:
		return

	var count := mini(int(progress * 12), _trail_dots.size())
	for i in count:
		var dot := _trail_dots[i]
		var t := float(i) / float(maxi(count - 1, 1))
		var dist := 15.0 + t * 55.0
		var spread := (1.0 - t) * 12.0
		var offset := Vector2(
			randf_range(-spread, spread),
			randf_range(-spread, spread)
		)
		var pos := _center + dir * dist + offset
		dot.color = Color(col.r, col.g, col.b, (1.0 - t) * 0.7)
		dot.size = Vector2(3 + (1.0 - t) * 4, 3 + (1.0 - t) * 4)
		dot.position = pos - dot.size * 0.5
		dot.visible = true

func set_element(element: String) -> void:
	_element = element
