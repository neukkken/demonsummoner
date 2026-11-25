extends Area3D

var xp_value: int = 10
var _collected: bool = false
var _speed: float = 0.0
var _magnetic: bool = false
var _target: Node3D = null
var _gem_type: String = "xp"
var _mesh_inst: MeshInstance3D
var _mesh_mat: StandardMaterial3D
var _time: float = 0.0

func _ready():
	_setup_visual()
	body_entered.connect(_on_body_entered)
	var timer = Timer.new()
	timer.one_shot = true
	timer.timeout.connect(queue_free)
	add_child(timer)
	timer.start(12.0)
	await get_tree().create_timer(0.3).timeout
	_magnetic = true

func _setup_visual():
	var sphere = SphereMesh.new()
	var radius = 0.4
	if _gem_type == "heal":
		radius = 0.5
	elif _gem_type == "big":
		radius = 0.55
	sphere.radius = radius
	sphere.height = radius * 2

	_mesh_inst = MeshInstance3D.new()
	_mesh_inst.mesh = sphere
	_mesh_mat = StandardMaterial3D.new()
	_mesh_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_mesh_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_mesh_mat.emission_enabled = true
	_mesh_mat.emission_energy_multiplier = 8.0
	match _gem_type:
		"xp":
			_mesh_mat.albedo_color = Color(1.0, 0.95, 0.6, 0.95)
			_mesh_mat.emission = Color(1.0, 0.95, 0.5)
		"big":
			_mesh_mat.albedo_color = Color(0.3, 0.5, 1, 0.95)
			_mesh_mat.emission = Color(0.3, 0.6, 1)
		"heal":
			_mesh_mat.albedo_color = Color(0.1, 0.9, 0.3, 0.95)
			_mesh_mat.emission = Color(0.2, 1, 0.4)
	_mesh_inst.material_override = _mesh_mat
	add_child(_mesh_inst)

	var col = CollisionShape3D.new()
	var csphere = SphereShape3D.new()
	csphere.radius = 0.8
	col.shape = csphere
	add_child(col)

func _process(delta):
	if _collected:
		return
	_time += delta
	if _mesh_inst:
		var pulse = 1.0 + 0.15 * sin(_time * 3.0)
		_mesh_inst.scale = Vector3(pulse, pulse, pulse)
		_mesh_mat.emission_energy_multiplier = 8.0 + 3.0 * sin(_time * 4.0)
	if _mesh_inst:
		_mesh_inst.position.y = sin(_time * 2.0) * 0.15

func _physics_process(delta):
	if _collected:
		return
	if _target == null or not is_instance_valid(_target) or not _target.is_inside_tree():
		_target = get_tree().get_first_node_in_group("player")
		if _target == null:
			return
	var dest = _target.global_position + Vector3(0, 1, 0)
	var dist = global_position.distance_to(dest)
	if dist < 10.0 or _magnetic:
		if dist < 0.8:
			_collect()
			return
		var dir = (dest - global_position).normalized()
		_speed += 15.0 * delta
		_speed = minf(_speed, 30.0)
		global_position += dir * _speed * delta

func _on_body_entered(body):
	if body.is_in_group("player") and not _collected:
		_collect()

func _collect():
	if _collected:
		return
	_collected = true
	match _gem_type:
		"xp", "big":
			DatosJuego.add_gem()
			var spawner = get_tree().get_first_node_in_group("wave_spawner")
			if spawner and spawner.has_method("add_xp"):
				spawner.add_xp(xp_value)
		"heal":
			var player = _target
			if player == null:
				player = get_tree().get_first_node_in_group("player")
			if player:
				player.health = minf(player.health + player.max_health * 0.1, player.max_health)
				if player.has_method("_update_hud_health"):
					player._update_hud_health()
	_spawn_xp_label()
	queue_free()

func _spawn_xp_label():
	var player_pos = _target.global_position + Vector3(0, 1.5, 0) if _target and is_instance_valid(_target) else global_position

	var label = Label3D.new()
	match _gem_type:
		"xp":
			label.text = "+" + str(xp_value) + " XP"
			label.modulate = Color(1.0, 0.95, 0.5)
			label.outline_modulate = Color(0.3, 0.2, 0.0, 0.8)
		"big":
			label.text = "+" + str(xp_value) + " XP"
			label.modulate = Color(0.3, 0.6, 1.0)
			label.outline_modulate = Color(0.0, 0.1, 0.3, 0.8)
		"heal":
			label.text = "CURA"
			label.modulate = Color(0.2, 1.0, 0.4)
			label.outline_modulate = Color(0.0, 0.2, 0.05, 0.8)
	label.font_size = 48
	label.outline_size = 4
	label.no_depth_test = true
	label.global_position = player_pos
	get_tree().root.add_child(label)

	var tween = label.create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_SINE)
	tween.tween_property(label, "global_position", player_pos + Vector3(0, 2.5, 0), 0.8)
	tween.parallel().tween_property(label, "modulate", Color(label.modulate.r, label.modulate.g, label.modulate.b, 0.0), 0.8)
	tween.tween_callback(label.queue_free)
