extends DirectionalLight3D

@export var world_environment_path: NodePath = "../WorldEnvironment"


func _ready() -> void:
	_sync()


func _process(_delta: float) -> void:
	_sync()


func _sync() -> void:
	var env_node := get_node_or_null(world_environment_path) as WorldEnvironment
	if env_node == null or env_node.environment == null:
		return

	var sky_mat := env_node.environment.sky.sky_material as ShaderMaterial
	if sky_mat == null:
		return

	var moon_pos: Vector3 = sky_mat.get_shader_parameter("moon_position")
	if moon_pos.length_squared() < 0.001:
		print("moon_light_sync: moon_position no valido")
		return

	var target_pos := global_transform.origin + moon_pos.normalized()
	look_at(target_pos, Vector3.UP)
