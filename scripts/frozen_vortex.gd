extends Node3D

var _damage_per_tick = 10.0
var _tick_interval = 0.5
var _duration = 3.0
var _tick_timer = 0.0
var _tex = null
var _inner_ring = null
var _shards = []
var _debris = []
var _beam = null
var _time = 0.0
var _ground_light = null
var _beam_light = null
var _fading_out = false

func _ready():
	_tex = preload("res://scripts/frozen_black_hole.gd").generate(128)

	var quad = MeshInstance3D.new()
	quad.mesh = QuadMesh.new()
	quad.mesh.size = Vector2(30.0, 30.0)
	quad.rotation.x = deg_to_rad(-90)
	quad.position.y = 0.05
	var mat = StandardMaterial3D.new()
	mat.albedo_texture = _tex
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.emission_enabled = true
	mat.emission_texture = _tex
	mat.emission_energy_multiplier = 2.0
	quad.material_override = mat
	add_child(quad)

	_inner_ring = MeshInstance3D.new()
	_inner_ring.mesh = QuadMesh.new()
	_inner_ring.mesh.size = Vector2(20.0, 20.0)
	_inner_ring.rotation.x = deg_to_rad(-90)
	_inner_ring.position.y = 0.1
	var ir_mat = StandardMaterial3D.new()
	ir_mat.albedo_texture = _tex
	ir_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	ir_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	ir_mat.emission_enabled = true
	ir_mat.emission_texture = _tex
	ir_mat.emission_energy_multiplier = 4.0
	_inner_ring.material_override = ir_mat
	add_child(_inner_ring)

	for i in range(12):
		var shard = MeshInstance3D.new()
		shard.mesh = PlaneMesh.new()
		shard.mesh.size = Vector2(0.6, 1.2)
		var smat = StandardMaterial3D.new()
		smat.albedo_color = Color(1.0, 0.15, 0.08, 0.6)
		smat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		smat.emission_enabled = true
		smat.emission = Color(1.0, 0.15, 0.08)
		smat.emission_energy_multiplier = 5.0
		smat.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
		shard.material_override = smat
		var a = float(i) / 12.0 * TAU
		shard.position = Vector3(cos(a) * 8.0, 1.2 + sin(i * 2.3) * 0.8, sin(a) * 8.0)
		shard.set_meta("angle", a)
		shard.set_meta("speed", 0.6 + i * 0.08)
		add_child(shard)
		_shards.append(shard)

	for i in range(30):
		var dot = MeshInstance3D.new()
		dot.mesh = BoxMesh.new()
		var s = randf_range(0.04, 0.12)
		dot.mesh.size = Vector3(s, s, s)
		var dmat = StandardMaterial3D.new()
		dmat.albedo_color = Color(1.0, 0.2, 0.05, 0.5)
		dmat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		dmat.emission_enabled = true
		dmat.emission = Color(1.0, 0.2, 0.05)
		dmat.emission_energy_multiplier = 3.0
		dot.material_override = dmat
		var a2 = randf_range(0, TAU)
		var r2 = randf_range(3.0, 14.0)
		dot.position = Vector3(cos(a2) * r2, randf_range(-0.5, 0.5), sin(a2) * r2)
		dot.set_meta("angle", a2)
		dot.set_meta("radius", r2)
		dot.set_meta("orbit_speed", randf_range(0.3, 1.2))
		add_child(dot)
		_debris.append(dot)

	_beam = MeshInstance3D.new()
	_beam.mesh = CylinderMesh.new()
	_beam.mesh.top_radius = 1.0
	_beam.mesh.bottom_radius = 3.0
	_beam.mesh.height = 20.0
	_beam.mesh.radial_segments = 8
	_beam.position.y = 10.0
	var bmat = StandardMaterial3D.new()
	bmat.albedo_color = Color(1.0, 0.1, 0.04, 0.2)
	bmat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	bmat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	bmat.emission_enabled = true
	bmat.emission = Color(1.0, 0.1, 0.04)
	bmat.emission_energy_multiplier = 1.5
	_beam.material_override = bmat
	add_child(_beam)

	_beam_light = OmniLight3D.new()
	_beam_light.light_color = Color(1.0, 0.1, 0.04)
	_beam_light.light_energy = 2.0
	_beam_light.omni_range = 30.0
	_beam_light.position.y = 15.0
	add_child(_beam_light)

	_ground_light = OmniLight3D.new()
	_ground_light.light_color = Color(1.0, 0.1, 0.04)
	_ground_light.light_energy = 4.0
	_ground_light.omni_range = 30.0
	_ground_light.position.y = 5.0
	add_child(_ground_light)

	var death_timer = Timer.new()
	death_timer.one_shot = true
	death_timer.timeout.connect(_fade_out)
	add_child(death_timer)
	death_timer.start(_duration - 0.5)

	var kill_timer = Timer.new()
	kill_timer.one_shot = true
	kill_timer.timeout.connect(queue_free)
	add_child(kill_timer)
	kill_timer.start(_duration)

	scale = Vector3.ZERO
	var appear = create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	appear.tween_property(self, "scale", Vector3.ONE, 0.35)

func _final_push():
	var enemies = get_tree().get_nodes_in_group("enemies")
	var center = global_position
	for e in enemies:
		var e3d = e as Node3D
		if e3d == null or not is_instance_valid(e3d) or not e3d.is_inside_tree():
			continue
		var dist = center.distance_to(e3d.global_position)
		if dist < 15.0:
			var dir = (e3d.global_position - center).normalized()
			dir.y = 0.0
			var force = 10.0 * (1.0 - dist / 15.0)
			e3d.global_position += dir * force

func _fade_out():
	_final_push()
	_fading_out = true
	var fade = create_tween().set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_SINE)
	fade.tween_property(self, "scale", Vector3.ZERO, 0.45)

func _process(delta):
	if _fading_out:
		return
	_time += delta
	_tick_timer += delta
	if _tick_timer >= _tick_interval:
		_tick_timer -= _tick_interval
		_damage_and_pull()

	var t = _time
	if _inner_ring:
		_inner_ring.rotation.z = t * 0.5
		var pulse = 0.9 + 0.1 * sin(t * 4.0)
		_inner_ring.scale = Vector3(pulse, pulse, pulse)
		var ir_mat = _inner_ring.material_override as StandardMaterial3D
		if ir_mat:
			ir_mat.emission_energy_multiplier = 2.0 + 3.0 * sin(t * 3.0)

	if _ground_light:
		_ground_light.light_energy = 4.0 + 3.0 * sin(t * 2.5)

	if _beam:
		var bm = _beam.material_override as StandardMaterial3D
		if bm:
			bm.emission_energy_multiplier = 1.5 + 1.5 * sin(t * 2.0)
			bm.albedo_color = Color(1.0, 0.1, 0.04, 0.15 + 0.1 * sin(t * 1.5))

	for shard in _shards:
		var a = shard.get_meta("angle")
		var speed = shard.get_meta("speed")
		a += delta * 1.2 * speed
		shard.set_meta("angle", a)
		var radius = 8.0 + 2.0 * sin(t * 0.7 + a)
		var h = 1.2 + sin(t * 1.8 + a * 2.0) * 2.0
		shard.position = Vector3(cos(a) * radius, 0.2 + h * 0.5, sin(a) * radius)
		shard.scale = Vector3(0.8 + 0.4 * sin(t * 2.0 + a), 1.0, 1.0)

	for dot in _debris:
		var a2 = dot.get_meta("angle")
		var r2 = dot.get_meta("radius")
		var os = dot.get_meta("orbit_speed")
		a2 += delta * 0.5 * os
		dot.set_meta("angle", a2)
		var r_target = maxf(r2 - delta * 1.5 * os, 1.0)
		dot.set_meta("radius", r_target)
		dot.position = Vector3(cos(a2) * r_target, dot.position.y + sin(t * 3.0 + a2) * delta * 0.3, sin(a2) * r_target)

func _damage_and_pull():
	var enemies = get_tree().get_nodes_in_group("enemies")
	var center = global_position
	for e in enemies:
		var e3d = e as Node3D
		if e3d == null or not is_instance_valid(e3d) or not e3d.is_inside_tree():
			continue
		var dist_sq = center.distance_squared_to(e3d.global_position)
		if dist_sq < 225.0:
			if e3d.has_method("take_damage"):
				e3d.take_damage(_damage_per_tick)
			var dir = (center - e3d.global_position).normalized()
			var dist = sqrt(dist_sq)
			var pull = 3.0 * (1.0 - dist / 15.0)
			if e3d is CharacterBody3D:
				e3d.velocity += dir * pull * 1.5
