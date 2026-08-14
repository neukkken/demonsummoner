extends CharacterBody3D

@export var health: float = 10.0
@export var speed: float = 5.0
@export var explosion_damage: float = 25.0
@export var explosion_radius: float = 3.0

var _player: Node3D = null
var _dying: bool = false
var _pulse_time: float = 0.0
var _mesh_instance: MeshInstance3D
var _mat: StandardMaterial3D

func _ready():
	add_to_group("enemies")
	_mesh_instance = MeshInstance3D.new()
	var box = BoxMesh.new()
	box.size = Vector3(0.6, 0.6, 0.6)
	_mat = StandardMaterial3D.new()
	_mat.albedo_color = Color(0.8, 0.02, 0.02)
	_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_mat.emission_enabled = true
	_mat.emission = Color(1.0, 0.05, 0.02)
	_mat.emission_energy_multiplier = 6.0
	_mesh_instance.mesh = box
	_mesh_instance.material_override = _mat
	add_child(_mesh_instance)
	var light = OmniLight3D.new()
	light.light_color = Color(1.0, 0.05, 0.02)
	light.light_energy = 3.0
	light.omni_range = 5.0
	add_child(light)
	var col = CollisionShape3D.new()
	var csphere = SphereShape3D.new()
	csphere.radius = 0.5
	col.shape = csphere
	add_child(col)

func init_player(p: Node3D) -> void:
	_player = p

func take_damage(amount: float) -> void:
	if _dying:
		return
	health -= amount
	if health <= 0:
		_dying = true
		_explode()

func _explode():
	var blast = preload("res://scenes/fire_blast_effect.tscn").instantiate()
	blast.scale = Vector3(2.0, 2.0, 2.0)
	blast.global_position = global_position
	get_tree().root.add_child(blast)
	var player = _find_player()
	if player:
		var dist = global_position.distance_to(player.global_position)
		if dist < explosion_radius and player.has_method("take_damage"):
			player.take_damage(explosion_damage)
	_spawn_xp_gem()
	queue_free()

func _spawn_xp_gem():
	var gem_script = load("res://scripts/alma_espectral.gd")
	if gem_script:
		var gem = Area3D.new()
		gem.set_script(gem_script)
		gem.xp_value = 5
		gem.global_position = global_position + Vector3(0, 0.5, 0)
		get_tree().root.add_child(gem)

func _find_player() -> Node3D:
	if _player and is_instance_valid(_player) and _player.is_inside_tree():
		return _player
	_player = get_tree().get_first_node_in_group("player")
	return _player

func _physics_process(delta):
	if _dying:
		return
	var target = _find_player()
	if target == null:
		return
	var dir = (target.global_position - global_position).normalized()
	dir.y = 0
	var horizontal_velocity = dir * speed

	velocity.x = horizontal_velocity.x
	velocity.z = horizontal_velocity.z
	if not is_on_floor():
		velocity.y -= 9.8 * delta
	else:
		velocity.y = 0.0

	move_and_slide()
	_pulse_time += delta
	var pulse = 1.0 + 0.3 * sin(_pulse_time * 12.0)
	if _mesh_instance:
		_mesh_instance.scale = Vector3(pulse, pulse, pulse)
		_mat.emission_energy_multiplier = 6.0 + 3.0 * sin(_pulse_time * 15.0)
