extends StaticBody3D

var _wall_height: float = 4.5
var _frost_timer: float = 0.0

static var _frost_box: BoxMesh = null
static var _frost_mat: StandardMaterial3D = null
static var _frost_inited: bool = false

static func _init_frost() -> void:
	if _frost_inited:
		return
	_frost_inited = true
	_frost_box = BoxMesh.new()
	_frost_box.size = Vector3(0.08, 0.08, 0.08)
	_frost_mat = StandardMaterial3D.new()
	_frost_mat.albedo_color = Color(0.75, 0.9, 1, 0.6)
	_frost_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_frost_mat.emission_enabled = true
	_frost_mat.emission = Color(0.75, 0.9, 1)
	_frost_mat.emission_energy_multiplier = 3.0

func _ready() -> void:
	_init_frost()
	add_to_group("ice_walls")
	var timer := Timer.new()
	timer.one_shot = true
	timer.timeout.connect(queue_free)
	add_child(timer)
	timer.start(4.0)

func _process(delta: float) -> void:
	_frost_timer += delta
	while _frost_timer >= 0.15:
		_frost_timer -= 0.15
		_spawn_frost()

func _spawn_frost() -> void:
	var piece := MeshInstance3D.new()
	var s := randf_range(0.05, 0.12)
	piece.mesh = _frost_box
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.75, 0.9, 1, 0.6)
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.emission_enabled = true
	mat.emission = Color(0.75, 0.9, 1)
	mat.emission_energy_multiplier = 3.0
	piece.material_override = mat
	piece.scale = Vector3(s / 0.08, s / 0.08, s / 0.08)
	piece.position = Vector3(randf_range(-1.5, 1.5), randf_range(-1.5, 1.5), 0)
	add_child(piece)
	var target := piece.position + Vector3(randf_range(-0.5, 0.5), randf_range(1.0, 2.5), randf_range(-0.3, 0.3))
	var tween := piece.create_tween()
	tween.tween_property(piece, "position", target, randf_range(1.5, 2.5))
	tween.parallel().tween_property(mat, "emission_energy_multiplier", 0.0, randf_range(1.5, 2.5))
	tween.parallel().tween_property(mat, "albedo_color", Color(0, 0, 0, 0), randf_range(1.5, 2.5))
	tween.tween_callback(piece.queue_free)

func snap_to_ground() -> void:
	var space_state = get_world_3d().direct_space_state
	if space_state == null:
		return
	var start = global_position + Vector3(0, 50, 0)
	var end = global_position + Vector3(0, -50, 0)
	var query = PhysicsRayQueryParameters3D.create(start, end)
	query.collision_mask = 1
	query.exclude = [self]
	var result = space_state.intersect_ray(query)
	if result:
		global_position.y = result.position.y + _wall_height * 0.5
