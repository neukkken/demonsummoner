extends Node3D

var damage: float = 25.0
var orbit_radius: float = 3.5
var orbit_speed: float = 1.5
var orbit_angle: float = 0.0
var target_player = null
var _type: String = "orb"
var _cooldown: float = 0.0
var _trail_interval: float = 0.4
var _trail_timer: float = 0.0
var _trail_pieces: Array = []

static var _trail_mat: StandardMaterial3D = null

static func _init_trail_mat() -> void:
	if _trail_mat:
		return
	_trail_mat = StandardMaterial3D.new()
	_trail_mat.albedo_color = Color(0.3, 0.9, 0.1, 0.7)
	_trail_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_trail_mat.emission_enabled = true
	_trail_mat.emission = Color(0.2, 0.8, 0.05)
	_trail_mat.emission_energy_multiplier = 4.0

func weapon_tick(delta: float) -> void:
	if target_player == null:
		return
	match _type:
		"orb":
			orbit_angle += delta * orbit_speed
			var pos = Vector3(cos(orbit_angle) * orbit_radius, 0.8 + sin(orbit_angle * 1.3) * 0.3, sin(orbit_angle) * orbit_radius)
			position = pos
			_cooldown -= delta
			if _cooldown <= 0:
				_check_hit()
		"ghost":
			var cam = target_player.get_viewport().get_camera_3d()
			if cam:
				var fwd = -cam.global_transform.basis.z
				position = position.lerp(target_player.global_position + fwd * 3.0 + Vector3(0, 2.0, 0), delta * 3.0)
				rotation.y += delta * 2.0
		"trail":
			_trail_timer -= delta
			if _trail_timer <= 0:
				_trail_timer = _trail_interval
				_spawn_trail_piece()
			_check_trail_hits()
			_clean_trail(delta)

func _check_hit() -> void:
	_cooldown = 0.5
	if target_player == null:
		return
	var enemies: Array[Node] = target_player.get_tree().get_nodes_in_group("enemies")
	for e in enemies:
		var e3d := e as Node3D
		if e3d == null:
			continue
		if global_position.distance_to(e3d.global_position) < 6.0:
			if e3d.has_method("take_damage"):
				e3d.take_damage(damage)
				AudioManager.play_impact(e3d.global_position)

func _spawn_trail_piece() -> void:
	_init_trail_mat()
	if target_player == null:
		return
	var dot = MeshInstance3D.new()
	var box = BoxMesh.new()
	box.size = Vector3(0.2, 0.04, 0.2)
	dot.mesh = box
	dot.material_override = _trail_mat
	dot.global_position = target_player.global_position + Vector3(randf_range(-0.3, 0.3), 0.05, randf_range(-0.3, 0.3))
	target_player.get_tree().root.add_child(dot)
	var light = OmniLight3D.new()
	light.light_color = Color(0.2, 0.9, 0.1)
	light.light_energy = 2.0
	light.omni_range = 2.0
	dot.add_child(light)
	var tween = dot.create_tween()
	tween.tween_property(light, "light_energy", 0.0, 2.0)
	_trail_pieces.append({"dot": dot, "life": 2.0})

func _check_trail_hits() -> void:
	if target_player == null:
		return
	var enemies: Array[Node] = target_player.get_tree().get_nodes_in_group("enemies")
	for p in _trail_pieces:
		if not is_instance_valid(p["dot"]):
			continue
		var ppos = p["dot"].global_position
		for e in enemies:
			var e3d := e as Node3D
			if e3d == null:
				continue
			if ppos.distance_to(e3d.global_position) < 1.5:
				if e3d.has_method("take_damage"):
					e3d.take_damage(damage)
					AudioManager.play_impact(e3d.global_position)
				p["dot"].queue_free()
				p["life"] = -1
				break

func _clean_trail(delta: float) -> void:
	var i = _trail_pieces.size() - 1
	while i >= 0:
		_trail_pieces[i]["life"] -= delta
		if _trail_pieces[i]["life"] <= 0:
			var p = _trail_pieces[i]["dot"]
			if is_instance_valid(p):
				p.queue_free()
			_trail_pieces.remove_at(i)
		i -= 1
