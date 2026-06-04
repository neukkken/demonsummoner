extends Area3D

var _velocidad: float = 0.0
var _magnetismo: bool = false
var _target: Node3D = null
var _cosechada: bool = false

func _ready():
	_setup_visual()
	body_entered.connect(_on_body_entered)
	var timer = Timer.new()
	timer.one_shot = true
	timer.timeout.connect(queue_free)
	add_child(timer)
	timer.start(10.0)
	await get_tree().create_timer(0.3).timeout
	_magnetismo = true

func _setup_visual():
	var mesh = MeshInstance3D.new()
	mesh.mesh = SphereMesh.new()
	mesh.mesh.radius = 0.2
	mesh.mesh.height = 0.4
	var mat = StandardMaterial3D.new()
	mat.albedo_color = Color(0.1, 0.9, 0.3, 0.95)
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.emission_enabled = true
	mat.emission = Color(0.2, 1.0, 0.4)
	mat.emission_energy_multiplier = 5.0
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mesh.material_override = mat
	add_child(mesh)

	var trail = MeshInstance3D.new()
	trail.mesh = QuadMesh.new()
	trail.mesh.size = Vector2(0.4, 0.4)
	trail.rotation.x = deg_to_rad(-90)
	var tmat = StandardMaterial3D.new()
	tmat.albedo_color = Color(0.1, 0.9, 0.3, 0.3)
	tmat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	tmat.emission_enabled = true
	tmat.emission = Color(0.2, 1.0, 0.4)
	tmat.emission_energy_multiplier = 3.0
	tmat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	trail.material_override = tmat
	add_child(trail)

	var light = OmniLight3D.new()
	light.light_color = Color(0.2, 1.0, 0.4)
	light.light_energy = 3.0
	light.omni_range = 5.0
	add_child(light)

	var colshape = CollisionShape3D.new()
	var sphere = SphereShape3D.new()
	sphere.radius = 0.5
	colshape.shape = sphere
	add_child(colshape)

func _physics_process(delta: float) -> void:
	if not _magnetismo:
		return
	if _target == null or not is_instance_valid(_target) or not _target.is_inside_tree():
		_target = get_tree().get_first_node_in_group("player")
		if _target == null:
			return
	var destino = _target.global_position + Vector3(0, 1.0, 0)
	var dist = global_position.distance_to(destino)
	if dist < 1.0:
		_curar()
		return
	var direccion = (destino - global_position).normalized()
	_velocidad += 15.0 * delta
	_velocidad = minf(_velocidad, 30.0)
	global_position += direccion * _velocidad * delta

func _on_body_entered(body: Node) -> void:
	if body.is_in_group("player"):
		_curar()

func _curar():
	if _cosechada:
		return
	_cosechada = true
	var player = _target
	if player == null or not is_instance_valid(player):
		player = get_tree().get_first_node_in_group("player")
	if player == null or not is_instance_valid(player):
		queue_free()
		return
	if player.has_method("restore_mana"):
		player.restore_mana(player.max_mana * 0.15)
	player.health = minf(player.health + player.max_health * 0.1, player.max_health)
	if player.has_method("_update_hud_health"):
		player._update_hud_health()
	if player.has_method("_update_hud_mana"):
		player._update_hud_mana()
	queue_free()
