extends Node3D

static var _box: BoxMesh = null
static var _mat_main: StandardMaterial3D = null
static var _mat_spark: StandardMaterial3D = null
static var _inited: bool = false

static func _init_resources() -> void:
	if _inited:
		return
	_inited = true
	_box = BoxMesh.new()
	_box.size = Vector3(1.0, 1.0, 1.0)

	_mat_main = StandardMaterial3D.new()
	_mat_main.albedo_color = Color(1, 0.6, 0.05, 0.95)
	_mat_main.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_mat_main.emission_enabled = true
	_mat_main.emission = Color(1, 0.6, 0.05)
	_mat_main.emission_energy_multiplier = 4.0

	_mat_spark = StandardMaterial3D.new()
	_mat_spark.albedo_color = Color(1, 0.85, 0.2, 1.0)
	_mat_spark.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_mat_spark.emission_enabled = true
	_mat_spark.emission = Color(1, 0.85, 0.2)
	_mat_spark.emission_energy_multiplier = 5.0

func _ready() -> void:
	_init_resources()
	for i in range(16):
		var piece = MeshInstance3D.new()
		var s = randf_range(0.12, 0.25)
		piece.mesh = _box
		piece.scale = Vector3(s, s, s)
		piece.material_override = _mat_main
		add_child(piece)
		var angle = randf_range(0, 360)
		var dir = Vector3(cos(deg_to_rad(angle)), randf_range(-0.2, 1.0), sin(deg_to_rad(angle))).normalized()
		var dist = randf_range(1.0, 3.5)
		var tween = piece.create_tween()
		tween.tween_property(piece, "position", dir * dist, 0.5).set_trans(Tween.TRANS_LINEAR)
		tween.parallel().tween_property(piece, "scale", Vector3.ZERO, 0.5)

	for i in range(8):
		var piece = MeshInstance3D.new()
		var s = randf_range(0.05, 0.1)
		piece.mesh = _box
		piece.scale = Vector3(s, s, s)
		piece.material_override = _mat_spark
		add_child(piece)
		var angle = randf_range(0, 360)
		var dir = Vector3(cos(deg_to_rad(angle)), randf_range(0.2, 1.2), sin(deg_to_rad(angle))).normalized()
		var dist = randf_range(1.5, 4.0)
		var tween = piece.create_tween()
		tween.tween_property(piece, "position", dir * dist, 0.45).set_trans(Tween.TRANS_LINEAR)
		tween.parallel().tween_property(piece, "scale", Vector3.ZERO, 0.45)

	var timer = get_tree().create_timer(0.6)
	timer.timeout.connect(queue_free)
