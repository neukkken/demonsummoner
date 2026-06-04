extends Node3D

@export var model_path: String = "res://models/Horror Free/FBX/Ghost.glb"

var _attack_timer = 0.0
var _attack_interval = 10.0
var _max_targets = 2
var _vortex_script = null
var _lifetime = 30.0
var _time_left = 30.0
var _label
var _health = 300.0
var _dying = false
var _player
var _anim_time = 0.0
var _is_casting = false
var _mesh = null
var _base_y = 0.0
var _blood_particles: Array[MeshInstance3D] = []
var _spawn_y: float = 0.0

func _ready() -> void:
	_vortex_script = load("res://scripts/frozen_vortex.gd")
	_setup_label()
	_setup_mesh()
	_setup_timer()

func _setup_label() -> void:
	_label = Label3D.new()
	_label.text = "30"
	_label.font_size = 32
	_label.outline_size = 3
	_label.modulate = Color(1.0, 0.15, 0.08)
	_label.outline_modulate = Color(0.2, 0.0, 0.0, 0.9)
	_label.position = Vector3(0, 3.5, 0)
	_label.no_depth_test = true
	add_child(_label)

func _setup_mesh() -> void:
	var scene = load(model_path)
	if scene:
		var model = scene.instantiate()
		model.name = "Model"
		add_child(model)
		var meshes = model.find_children("*", "MeshInstance3D", true, false)
		_mesh = meshes[0] as MeshInstance3D if meshes.size() > 0 else null
		model.position.y = -1.0
		model.scale = Vector3(1.5, 1.5, 1.5)
		if _mesh:
			var mat = _mesh.material_override
			if mat == null:
				mat = _mesh.get_surface_override_material(0)
			if mat == null and _mesh.mesh != null:
				mat = _mesh.mesh.surface_get_material(0)
			if mat is BaseMaterial3D:
				mat = mat.duplicate()
				_mesh.material_override = mat
				if not mat.albedo_texture:
					var tex = load("res://models/Horror Free/Texture/Texture.png")
					if tex:
						mat.albedo_texture = tex
				mat.albedo_color = Color(0.3, 0.25, 0.25, 1)
	else:
		_mesh = MeshInstance3D.new()
		_mesh.mesh = BoxMesh.new()
		add_child(_mesh)
	if _mesh:
		_base_y = _mesh.global_position.y

	scale = Vector3.ZERO
	var tween = create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	tween.tween_property(self, "scale", Vector3.ONE, 0.4)
	_setup_blood_particles()

func _setup_blood_particles():
	_spawn_y = global_position.y
	for i in range(12):
		var piece = MeshInstance3D.new()
		var box = BoxMesh.new()
		var s = randf_range(0.04, 0.1)
		box.size = Vector3(s, s, s)
		var mat = StandardMaterial3D.new()
		mat.albedo_color = Color(0.6, 0.02, 0.02, 0.6)
		mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		mat.emission_enabled = true
		mat.emission = Color(0.8, 0.03, 0.02)
		mat.emission_energy_multiplier = 3.0
		mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		piece.mesh = box
		piece.material_override = mat
		var a = float(i) / 12.0 * TAU
		var r = randf_range(0.8, 1.5)
		piece.position = Vector3(cos(a) * r, randf_range(-0.5, 0.5), sin(a) * r)
		piece.set_meta("angle", a)
		piece.set_meta("radius", r)
		piece.set_meta("speed", randf_range(0.5, 1.5))
		piece.set_meta("phase", randf_range(0, TAU))
		add_child(piece)
		_blood_particles.append(piece)

func _setup_timer() -> void:
	var timer = Timer.new()
	timer.one_shot = true
	timer.timeout.connect(queue_free)
	add_child(timer)
	timer.start(_lifetime)

func _process(delta: float) -> void:
	_attack_timer += delta
	if _attack_timer >= _attack_interval:
		_attack_timer -= _attack_interval
		_try_attack()

	if _label:
		_time_left = maxf(_time_left - delta, 0.0)
		_label.text = str(ceili(_time_left))

	if _player and is_instance_valid(_player) and _player.is_inside_tree():
		var ppos = _player.global_position
		var dist = global_position.distance_to(ppos)
		if dist > 5.0:
			var dir_vec = (ppos - global_position).normalized()
			global_position += dir_vec * 3.0 * delta

	_anim_time += delta
	if _mesh:
		if _is_casting:
			_mesh.rotation.y += delta * 6.0
		else:
			_mesh.rotation.y += delta * 0.5
	var float_y = _spawn_y + 1.0 + sin(_anim_time * 1.2) * 0.5
	global_position.y = float_y

	for p in _blood_particles:
		if not is_instance_valid(p):
			continue
		var a = p.get_meta("angle") + delta * p.get_meta("speed") * 1.5
		p.set_meta("angle", a)
		var r = p.get_meta("radius") + sin(_anim_time * 2.0 + p.get_meta("phase")) * 0.2
		var y_off = sin(_anim_time * 1.5 + p.get_meta("phase")) * 0.5
		var scale_pulse = 0.8 + sin(_anim_time * 3.0 + p.get_meta("phase")) * 0.2
		p.position = Vector3(cos(a) * r, y_off, sin(a) * r)
		p.scale = Vector3(scale_pulse, scale_pulse, scale_pulse)
		var mat = p.material_override
		if mat and mat is StandardMaterial3D:
			var alpha = 0.3 + sin(_anim_time * 2.5 + p.get_meta("phase")) * 0.2
			mat.albedo_color.a = clampf(alpha, 0.1, 0.6)

func init_player(player: Node3D) -> void:
	_player = player

func take_damage(amount: float) -> void:
	if _dying:
		return
	_health -= amount
	print("Summon recibio: ", amount, " HP: ", _health)
	if _health <= 0:
		_dying = true
		queue_free()

func _try_attack() -> void:
	if _mesh and not _is_casting:
		_is_casting = true
		var tween = create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
		tween.tween_property(_mesh, "rotation:y", deg_to_rad(360), 0.4).as_relative()
		tween.tween_callback(func():
			_is_casting = false
		)
	var targets = _find_targets()
	for target in targets:
		if not is_instance_valid(target) or not target.is_inside_tree():
			continue
		if _vortex_script == null:
			continue
		var vortex = Node3D.new()
		vortex.set_script(_vortex_script)
		var tpos = target.global_position
		tpos.y = 0.0
		vortex.position = tpos
		get_tree().root.add_child(vortex)

func _find_targets():
	var enemies = get_tree().get_nodes_in_group("enemies")
	if enemies.is_empty():
		return []
	var valid = []
	for e in enemies:
		var e3d = e as Node3D
		if e3d == null or not is_instance_valid(e3d) or not e3d.is_inside_tree():
			continue
		valid.append(e3d)
	valid.sort_custom(func(a, b): return global_position.distance_squared_to(a.global_position) < global_position.distance_squared_to(b.global_position))
	var result = []
	var count = mini(_max_targets, valid.size())
	for i in count:
		var idx = i * (valid.size() / count) if count > 1 else 0
		idx = mini(idx, valid.size() - 1)
		result.append(valid[idx])
	return result
