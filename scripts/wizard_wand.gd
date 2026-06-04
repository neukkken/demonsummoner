extends Node3D

@export var crystal_color: Color = Color(0.7, 0.2, 1.0)
@export var wood_color: Color = Color(0.25, 0.12, 0.05)
@export var wood_highlight: Color = Color(0.35, 0.18, 0.08)
@export var glow_intensity: float = 0.8
@export var auto_animate: bool = true

var _handle_mesh: MeshInstance3D
var _crystal_mesh: MeshInstance3D
var _crystal_mat: StandardMaterial3D
var _light: OmniLight3D
var _visual_root: Node3D
var _last_rot: Vector3
var _trail_timer: float = 0.0

var _element_colors := {
	"FIRE": Color(1.0, 0.4, 0.05),
	"ICE": Color(0.3, 0.7, 1.0),
	"NECROMANCIA": Color(0.9, 0.05, 0.05),
}

var _current_element: String = ""

static var _wand_pool: Array[MeshInstance3D] = []
static var _wand_pool_idx: int = 0
static var _wand_box: BoxMesh = null
static var _wand_inited: bool = false

const WAND_POOL_SIZE := 40

static func _init_wand_pool() -> void:
	if _wand_inited:
		return
	_wand_inited = true
	_wand_box = BoxMesh.new()
	_wand_box.size = Vector3(0.03, 0.03, 0.03)

func _ready() -> void:
	_init_wand_pool()
	_build_wand()

func _process(delta: float) -> void:
	_trail_timer += delta
	var rot_change := Vector2(rotation.x - _last_rot.x, rotation.y - _last_rot.y).length()
	_last_rot = rotation
	if rot_change > 0.001 and _trail_timer > 0.02:
		_trail_timer = 0.0
		_spawn_trail_piece()

func set_element(element: String) -> void:
	_current_element = element
	var col: Color = _element_colors.get(element, Color(0.7, 0.2, 1.0))
	_update_crystal_color(col)

func _build_wand() -> void:
	_visual_root = Node3D.new()
	add_child(_visual_root)
	_build_handle()
	_build_crystal()
	_build_light()
	if auto_animate:
		_add_bob()

func _build_handle() -> void:
	var st: SurfaceTool = SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)

	var segments := 8
	var seg_height := 0.05
	var width_min := 0.028
	var width_max := 0.04
	var twist := deg_to_rad(12.0)

	for i in segments:
		var y_base := i * seg_height
		var t := float(i) / float(segments - 1)
		var w := lerpf(width_min, width_max, t)
		var rot := twist * i
		var mid_color: Color = wood_color.lerp(wood_highlight, t)
		var top_color: Color = wood_color.lerp(wood_highlight, t * 0.5 + 0.5)

		var half := w * 0.5
		var y0 := y_base
		var y1 := y_base + seg_height

		var v0 := Vector3(-half, y0, -half)
		var v1 := Vector3(half, y0, -half)
		var v2 := Vector3(half, y0, half)
		var v3 := Vector3(-half, y0, half)
		var v4 := Vector3(-half, y1, -half)
		var v5 := Vector3(half, y1, -half)
		var v6 := Vector3(half, y1, half)
		var v7 := Vector3(-half, y1, half)

		var r := Basis(Vector3(0, 1, 0), rot)
		var r_inv := Basis(Vector3(0, 1, 0), rot - twist * 0.5)

		var verts := [v0, v1, v2, v3, v4, v5, v6, v7]
		var rverts: Array[Vector3] = []
		for v in verts:
			rverts.append(r * v)

		var rverts_mid: Array[Vector3] = []
		for v in verts:
			var v_mid: Vector3 = Vector3(v.x, y_base + seg_height * 0.5, v.z)
			rverts_mid.append(r_inv * v_mid)

		var sides := [
			[0, 1, 5, 4],
			[1, 2, 6, 5],
			[2, 3, 7, 6],
			[3, 0, 4, 7],
		]
		var top_bottom_color: Color = mid_color
		for side in sides:
			var a: Vector3 = rverts[side[0]]
			var b: Vector3 = rverts[side[1]]
			var c: Vector3 = rverts[side[2]]
			var d: Vector3 = rverts[side[3]]
			st.set_color(top_color)
			st.add_vertex(a)
			st.add_vertex(b)
			st.add_vertex(c)
			st.set_color(top_color)
			st.add_vertex(a)
			st.add_vertex(c)
			st.add_vertex(d)

		var tc: Color = mid_color
		st.set_color(mid_color)
		st.add_vertex(rverts[0])
		st.add_vertex(rverts[2])
		st.add_vertex(rverts[1])
		st.set_color(mid_color)
		st.add_vertex(rverts[0])
		st.add_vertex(rverts[3])
		st.add_vertex(rverts[2])

		st.set_color(mid_color)
		st.add_vertex(rverts[4])
		st.add_vertex(rverts[5])
		st.add_vertex(rverts[6])
		st.set_color(mid_color)
		st.add_vertex(rverts[4])
		st.add_vertex(rverts[6])
		st.add_vertex(rverts[7])

	st.generate_normals(false)
	var mesh: Mesh = st.commit()

	var mat: StandardMaterial3D = StandardMaterial3D.new()
	mat.albedo_color = wood_color
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.vertex_color_use_as_albedo = true

	_handle_mesh = MeshInstance3D.new()
	_handle_mesh.mesh = mesh
	_handle_mesh.material_override = mat
	_handle_mesh.position = Vector3(0, -0.5, 0)
	_visual_root.add_child(_handle_mesh)

func _build_crystal() -> void:
	var st: SurfaceTool = SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)

	var h := 0.14
	var half_w := 0.035
	var tip_y := h * 0.5
	var base_y := -h * 0.5
	var crystal_center_y := 0.18

	var tip := Vector3(0, tip_y, 0)
	var base := Vector3(0, base_y, 0)
	var mids := [
		Vector3(half_w, 0, 0),
		Vector3(0, 0, half_w),
		Vector3(-half_w, 0, 0),
		Vector3(0, 0, -half_w),
	]

	var col := crystal_color
	var bright := Color(
		minf(col.r * 1.5, 1.0),
		minf(col.g * 1.5, 1.0),
		minf(col.b * 1.5, 1.0),
		1.0
	)

	for i in 4:
		var j: int = (i + 1) % 4
		st.set_color(bright)
		st.add_vertex(tip)
		st.set_color(col)
		st.add_vertex(mids[i])
		st.add_vertex(mids[j])

		st.set_color(bright)
		st.add_vertex(base)
		st.set_color(col)
		st.add_vertex(mids[i])
		st.add_vertex(mids[j])

	st.generate_normals(false)
	var mesh: Mesh = st.commit()

	_crystal_mat = StandardMaterial3D.new()
	_crystal_mat.albedo_color = col
	_crystal_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_crystal_mat.vertex_color_use_as_albedo = true
	_crystal_mat.emission_enabled = true
	_crystal_mat.emission = col
	_crystal_mat.emission_energy_multiplier = glow_intensity

	_crystal_mesh = MeshInstance3D.new()
	_crystal_mesh.mesh = mesh
	_crystal_mesh.material_override = _crystal_mat
	_crystal_mesh.position = Vector3(0, crystal_center_y, 0)
	_visual_root.add_child(_crystal_mesh)

func _update_crystal_color(col: Color) -> void:
	if _crystal_mat:
		_crystal_mat.albedo_color = col
		_crystal_mat.emission = col
	if _light:
		_light.light_color = col

func _build_light() -> void:
	_light = OmniLight3D.new()
	_light.light_color = crystal_color
	_light.light_energy = 0.6
	_light.omni_range = 3.0
	_light.position = Vector3(0, 0.2, 0)
	_visual_root.add_child(_light)

func _spawn_trail_piece() -> void:
	var col: Color = _element_colors.get(_current_element, Color(0.7, 0.2, 1.0))
	var world_pos: Vector3 = _crystal_mesh.global_position

	var piece: MeshInstance3D = null
	for i in WAND_POOL_SIZE:
		var idx := (_wand_pool_idx + i) % WAND_POOL_SIZE
		if idx < _wand_pool.size():
			var p := _wand_pool[idx]
			if p != null and is_instance_valid(p) and (not p.visible or p.scale.length_squared() < 0.001):
				piece = p
				_wand_pool_idx = (idx + 1) % WAND_POOL_SIZE
				break
	if piece == null:
		piece = MeshInstance3D.new()
		piece.mesh = _wand_box
		get_tree().root.add_child(piece)
		piece.visible = false
		_wand_pool.append(piece)

	var mat := StandardMaterial3D.new()
	mat.albedo_color = col
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.emission_enabled = true
	mat.emission = col
	mat.emission_energy_multiplier = 1.0
	piece.material_override = mat
	piece.global_position = world_pos
	piece.scale = Vector3.ONE
	piece.visible = true

	var tween := piece.create_tween().set_parallel()
	tween.tween_property(piece, "scale", Vector3.ZERO, 0.4).set_ease(Tween.EASE_IN)
	tween.tween_property(mat, "emission_energy_multiplier", 0.0, 0.4)
	tween.tween_callback(func():
		if is_instance_valid(piece):
			piece.visible = false
			piece.material_override = null
	)

func _add_bob() -> void:
	var tween: Tween = create_tween().set_loops()
	tween.tween_property(_visual_root, "rotation_degrees", Vector3(1.5, 0, 0), 1.2).set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(_visual_root, "rotation_degrees", Vector3(-1.5, 0, 0), 1.2).set_ease(Tween.EASE_IN_OUT)
