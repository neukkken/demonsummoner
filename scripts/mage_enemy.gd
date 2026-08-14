extends CharacterBody3D

@export var health: float = 240.0
@export var shoot_interval: float = 1.8
@export var projectile_damage: float = 20.0
@export var frozen_color: Color = Color(0.3, 0.6, 1, 1)
@export var max_range: float = 18.0
@export var min_range: float = 8.0
@export var move_speed: float = 5.0

var _player: Node3D = null
var _mesh_instance: MeshInstance3D = null
var _original_color: Color = Color.WHITE
var _shoot_timer: Timer = null
var _projectile_scene: PackedScene = null
var _health_bar = null
var _max_health: float = 80.0
var _dying: bool = false
var _is_paralizado: bool = false
var _ice_block: MeshInstance3D = null
var _ice_mat: StandardMaterial3D = null
var _anim_player: AnimationPlayer = null
var _anim_time: float = 0.0
var _base_y: float = 0.0
var _float_init: bool = false
var _nav: NavigationAgent3D = null

func _ready() -> void:
	_max_health = health
	add_to_group("enemies")
	_load_model()
	_projectile_scene = load("res://scenes/spell_projectile.tscn")
	_shoot_timer = Timer.new()
	_shoot_timer.one_shot = false
	_shoot_timer.timeout.connect(_shoot_at_player)
	add_child(_shoot_timer)
	_shoot_timer.start(shoot_interval)
	_setup_health_bar()
	_nav = NavigationAgent3D.new()
	_nav.name = "NavigationAgent3D"
	_nav.radius = 0.5
	_nav.target_desired_distance = min_range * 0.5
	add_child(_nav)

func _load_model() -> void:
	var scene = load("res://models/wizard_cat/scene.gltf")
	if scene == null:
		print("ERROR: No se pudo cargar wizard_cat")
		return
	var model = scene.instantiate()
	model.name = "WizardCatModel"
	add_child(model)
	_mesh_instance = model.find_child("MeshInstance3D", true, false) as MeshInstance3D
	_anim_player = model.find_child("AnimationPlayer", true, false) as AnimationPlayer
	if _mesh_instance != null:
		var mat: Material = _mesh_instance.material_override
		if mat == null:
			mat = _mesh_instance.get_surface_override_material(0)
		if mat == null and _mesh_instance.mesh != null:
			mat = _mesh_instance.mesh.surface_get_material(0)
		if mat is BaseMaterial3D:
			_original_color = mat.albedo_color
	if _anim_player:
		_anim_player.play("Animation")
		_anim_player.animation_finished.connect(_on_anim_finished)
	var light = OmniLight3D.new()
	light.light_color = Color(0.6, 0.2, 0.9, 1)
	light.light_energy = 4.0
	light.omni_range = 8.0
	light.shadow_enabled = false
	light.position = Vector3(0, 1.5, 0)
	model.add_child(light)

func _on_anim_finished(anim_name: String) -> void:
	if anim_name == "Animation":
		_anim_player.play("Animation")

func _setup_health_bar() -> void:
	var bar_script := preload("res://scripts/health_bar_3d.gd")
	if bar_script == null:
		return
	_health_bar = bar_script.new()
	_health_bar.name = "HealthBar3D"
	_health_bar.position = Vector3(0, 2.5, 0)
	add_child(_health_bar)
	_health_bar.setup(_max_health)

func init_player(player_node: Node3D) -> void:
	_player = player_node

func paralizar(duracion: float) -> void:
	_is_paralizado = true
	var timer = Timer.new()
	timer.one_shot = true
	timer.timeout.connect(func():
		_is_paralizado = false
	)
	add_child(timer)
	timer.start(duracion)

func take_damage(amount: float) -> void:
	if _dying:
		return
	health -= amount
	print("Mage recibio: ", amount, " HP: ", health)
	if _health_bar != null:
		_health_bar.update_health(health, _max_health)
	if health <= 0:
		_die()

func _die() -> void:
	_dying = true
	AudioManager.play_enemy_death(global_position)
	var death_pos = global_position
	_spawn_soul_at(death_pos)
	if _player != null and _player.has_method("restore_mana"):
		_player.restore_mana(15.0)
	if _health_bar:
		_health_bar.visible = false
	if _ice_block:
		_spawn_ice_black_hole()
	else:
		_spawn_black_hole()

func _spawn_soul_at(pos: Vector3) -> void:
	var alma = load("res://scripts/alma_espectral.gd")
	if alma == null:
		return
	var node = Area3D.new()
	node.set_script(alma)
	node.global_position = pos + Vector3(0, 1.0, 0)
	get_tree().root.add_child(node)

func _spawn_black_hole() -> void:
	var root = Node3D.new()
	get_tree().root.add_child(root)
	root.global_position = global_position + Vector3(0, 1.0, 0)
	var duration = 3.0

	var sph = MeshInstance3D.new()
	var sphere = SphereMesh.new()
	sphere.radius = 0.01
	sphere.height = 0.02
	sphere.radial_segments = 24
	sphere.rings = 16
	var smat = StandardMaterial3D.new()
	smat.albedo_color = Color(0.0, 0.0, 0.0, 1)
	smat.emission_enabled = true
	smat.emission = Color(0.15, 0.0, 0.25, 1)
	smat.emission_energy_multiplier = 4.0
	sph.mesh = sphere
	sph.material_override = smat
	root.add_child(sph)
	var stween = sph.create_tween()
	stween.tween_property(sph, "scale", Vector3(6.0, 6.0, 6.0), duration * 0.9).set_trans(Tween.TRANS_QUAD)

	for r in range(5):
		var ring = MeshInstance3D.new()
		var torus = TorusMesh.new()
		torus.inner_radius = 0.03 + r * 0.1
		torus.outer_radius = 0.06 + r * 0.1
		torus.rings = 12
		torus.ring_segments = 16
		var rmat = StandardMaterial3D.new()
		rmat.albedo_color = Color(0.4 - r * 0.06, 0.0, 0.55 - r * 0.06, 0.5 - r * 0.08)
		rmat.emission_enabled = true
		rmat.emission = Color(0.5 - r * 0.06, 0.0, 0.7 - r * 0.06, 1)
		rmat.emission_energy_multiplier = 5.0
		rmat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		ring.mesh = torus
		ring.material_override = rmat
		ring.rotation.x = deg_to_rad(90)
		ring.rotation.z = r * deg_to_rad(72)
		root.add_child(ring)
		var rtween = ring.create_tween()
		rtween.set_parallel(true)
		rtween.tween_property(ring, "scale", Vector3(8.0 - r, 8.0 - r, 8.0 - r), duration * 0.85)
		rtween.tween_property(ring, "rotation", Vector3(deg_to_rad(90), TAU * (5 - r), deg_to_rad(72) * r), duration * 0.85).as_relative()
		rtween.tween_property(rmat, "albedo_color", Color(0, 0, 0, 0), duration * 0.85)
		rtween.tween_property(rmat, "emission", Color(0, 0, 0, 0), duration * 0.85)

	for i in range(80):
		var dot = MeshInstance3D.new()
		var box = BoxMesh.new()
		var s = randf_range(0.04, 0.14)
		box.size = Vector3(s, s, s)
		var dmat = StandardMaterial3D.new()
		dmat.albedo_color = Color(0.5, 0.0, 0.7, 0.9)
		dmat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		dmat.emission_enabled = true
		dmat.emission = Color(0.6, 0.0, 0.9, 1)
		dmat.emission_energy_multiplier = 6.0
		dot.mesh = box
		dot.material_override = dmat
		var angle = randf_range(0, TAU)
		var radius = randf_range(1.5, 5.0)
		var height_off = randf_range(-2.0, 2.0)
		dot.position = Vector3(cos(angle) * radius, height_off, sin(angle) * radius)
		root.add_child(dot)
		var dtween = dot.create_tween()
		dtween.set_parallel(true)
		var t_angle = angle + randf_range(1.0, 3.0)
		var target = Vector3(cos(t_angle) * 0.02, height_off * 0.02, sin(t_angle) * 0.02)
		dtween.tween_property(dot, "position", target, duration * 0.9).set_trans(Tween.TRANS_QUAD)
		dtween.tween_property(dmat, "albedo_color", Color(0, 0, 0, 0), duration * 0.9)
		dtween.tween_property(dmat, "emission", Color(0, 0, 0, 0), duration * 0.9)

	var light = OmniLight3D.new()
	light.light_color = Color(0.5, 0.0, 0.7, 1)
	light.light_energy = 5.0
	light.omni_range = 15.0
	root.add_child(light)
	var ltween = root.create_tween()
	ltween.tween_property(light, "light_energy", 20.0, duration * 0.35).set_trans(Tween.TRANS_QUAD)
	ltween.tween_property(light, "light_energy", 0.0, duration * 0.65).set_delay(duration * 0.35)

	if _anim_player:
		_anim_player.stop()
	set_process(false)
	set_physics_process(false)
	var mtween = create_tween()
	mtween.set_parallel(true)
	mtween.tween_property(self, "scale", Vector3(0.0, 0.0, 0.0), duration * 0.8).set_trans(Tween.TRANS_QUAD)
	var all_meshes = find_children("*", "MeshInstance3D", true)
	for c in all_meshes:
		var m = c.material_override
		if m is StandardMaterial3D:
			mtween.tween_property(m, "albedo_color", Color(0, 0, 0, 0), duration * 0.8)
			mtween.tween_property(m, "emission", Color(0, 0, 0, 0), duration * 0.8)
	await get_tree().create_timer(duration + 0.3).timeout
	root.queue_free()
	queue_free()

func _get_target() -> Node3D:
	var summons := get_tree().get_nodes_in_group("summons")
	for s in summons:
		if is_instance_valid(s) and s.is_inside_tree():
			return s
	return _player

func _shoot_at_player() -> void:
	if _dying or _projectile_scene == null or _ice_block or _is_paralizado:
		return
	var target := _get_target()
	if target == null:
		return
	var dist := global_position.distance_to(target.global_position)
	if dist > max_range:
		return
	AudioManager.play_mage_shoot(global_position)
	var proj := _projectile_scene.instantiate() as Area3D
	if proj == null:
		return
	proj.effect_type = "fire"
	proj.damage = projectile_damage
	get_tree().root.add_child(proj)
	proj.global_position = global_position + Vector3(0, 1.5, 0)
	proj.look_at(target.global_position)

func _physics_process(_delta: float) -> void:
	if _dying or _ice_block or _is_paralizado or not is_inside_tree():
		return
	var target := _get_target()
	if target == null:
		return
	var dist := global_position.distance_to(target.global_position)
	var dir := target.global_position - global_position
	rotation.y = atan2(dir.x, dir.z)

	if Engine.get_frames_drawn() % 60 == 0:
		print("[MAGE] dist=", snapped(dist, 0.1), " max=", max_range, " min=", min_range, " nav=", _nav.is_navigation_finished())

	if dist > max_range:
		var desired = target.global_position - dir.normalized() * max_range * 0.8
		_nav.target_position = desired
		var next_pos = _nav.get_next_path_position()
		var to_next = next_pos - global_position
		to_next.y = 0
		if to_next.length_squared() > 0.1:
			velocity = to_next.normalized() * move_speed
		else:
			velocity = (desired - global_position).normalized() * move_speed
			if Engine.get_frames_drawn() % 60 == 0:
				print("[MAGE] nav dio current pos, directo")
	elif dist < min_range:
		var away_dir = (global_position - target.global_position).normalized()
		var desired = global_position + away_dir * min_range
		_nav.target_position = desired
		var next_pos = _nav.get_next_path_position()
		var to_next = next_pos - global_position
		to_next.y = 0
		if to_next.length_squared() > 0.1:
			velocity = to_next.normalized() * move_speed
		else:
			velocity = (desired - global_position).normalized() * move_speed
			if Engine.get_frames_drawn() % 60 == 0:
				print("[MAGE] nav dio current pos (away)")
	else:
		_nav.target_position = global_position
		velocity = Vector3.ZERO
		if Engine.get_frames_drawn() % 60 == 0:
			print("[MAGE] en rango, quieto")
	move_and_slide()

func _process(delta: float) -> void:
	if _dying or _ice_block or _is_paralizado or not is_inside_tree():
		return
	_anim_time += delta
	var target_h = DatosJuego.get_height(global_position.x, global_position.z)
	global_position.y = target_h + 1.8 + sin(_anim_time * 1.2) * 0.5

func _get_ice_mat() -> StandardMaterial3D:
	if _ice_mat == null:
		_ice_mat = StandardMaterial3D.new()
		_ice_mat.albedo_color = Color(0.35, 0.65, 0.95, 1)
		_ice_mat.emission_enabled = true
		_ice_mat.emission = Color(0.15, 0.4, 0.8, 0.6)
		_ice_mat.metallic = 0.6
		_ice_mat.roughness = 0.1
	return _ice_mat

func _ice_explode(pos: Vector3) -> void:
	var explosion_root = Node3D.new()
	get_tree().root.add_child(explosion_root)
	explosion_root.global_position = pos
	for i in range(28):
		var piece = MeshInstance3D.new()
		var s = randf_range(0.15, 0.35)
		var box = BoxMesh.new()
		box.size = Vector3(s, s, s)
		var mat = StandardMaterial3D.new()
		mat.albedo_color = Color(0.5, 0.8, 1, 1)
		mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		mat.emission_enabled = true
		mat.emission = Color(0.3, 0.6, 1, 1)
		mat.emission_energy_multiplier = 3.0
		piece.mesh = box
		piece.material_override = mat
		explosion_root.add_child(piece)
		var dir = Vector3(randf_range(-1, 1), randf_range(-0.5, 1), randf_range(-1, 1)).normalized()
		var dist = randf_range(1.0, 4.0)
		var tween = piece.create_tween()
		tween.tween_property(piece, "position", dir * dist, 0.6).set_trans(Tween.TRANS_LINEAR)
		tween.parallel().tween_property(mat, "emission", Color(0, 0, 0, 0), 0.6)
		tween.parallel().tween_property(mat, "albedo_color", Color(0, 0, 0, 0), 0.6)
	var light = OmniLight3D.new()
	light.light_color = Color(0.3, 0.6, 1, 1)
	light.light_energy = 6.0
	light.omni_range = 6.0
	explosion_root.add_child(light)
	var ltween = explosion_root.create_tween()
	ltween.tween_property(light, "light_energy", 0.0, 0.5)
	get_tree().create_timer(1.0).timeout.connect(explosion_root.queue_free)
	var enemies = get_tree().get_nodes_in_group("enemies")
	for e in enemies:
		var dist = pos.distance_to(e.global_position)
		var dmg = 10.0 if e == self else 20.0
		if dist < 5.0 and e.has_method("take_damage"):
			e.take_damage(dmg)

func apply_freeze(duration: float, slow_factor: float) -> void:
	if _ice_block:
		return
	if _anim_player and _anim_player.is_playing():
		_anim_player.stop()
	if _mesh_instance != null:
		var mat: Material = _mesh_instance.material_override
		if mat == null:
			mat = _mesh_instance.get_surface_override_material(0)
		if mat == null and _mesh_instance.mesh != null:
			mat = _mesh_instance.mesh.surface_get_material(0)
		if not mat is BaseMaterial3D:
			mat = StandardMaterial3D.new()
		else:
			mat = mat.duplicate()
		_mesh_instance.material_override = mat
		mat.albedo_color = frozen_color
	var cyl = CylinderMesh.new()
	cyl.top_radius = 1.0
	cyl.bottom_radius = 3.0
	cyl.height = 4.0
	cyl.radial_segments = 6
	var bmat = _get_ice_mat()
	_ice_block = MeshInstance3D.new()
	_ice_block.mesh = cyl
	_ice_block.material_override = bmat
	get_tree().root.add_child(_ice_block)
	_ice_block.global_position = global_position + Vector3(0, 1.0, 0)
	get_tree().create_timer(duration).timeout.connect(_restore_speed)

func _spawn_ice_black_hole() -> void:
	var ice_pos = global_position + Vector3(0, 1.0, 0)
	if _ice_block != null:
		ice_pos = _ice_block.global_position
		_ice_block.queue_free()
		_ice_block = null

	var root = Node3D.new()
	get_tree().root.add_child(root)
	root.global_position = ice_pos
	var duration = 2.5

	for i in range(60):
		var piece = MeshInstance3D.new()
		var s = randf_range(0.05, 0.2)
		var box = BoxMesh.new()
		box.size = Vector3(s, s, s)
		var mat = StandardMaterial3D.new()
		var is_ice = randf() > 0.35
		if is_ice:
			mat.albedo_color = Color(0.4, 0.7, 1, 0.6)
			mat.emission_enabled = true
			mat.emission = Color(0.2, 0.5, 1, 0.3)
		else:
			mat.albedo_color = Color(0.4, 0.0, 0.6, 0.8)
			mat.emission_enabled = true
			mat.emission = Color(0.5, 0.0, 0.7, 0.8)
			mat.emission_energy_multiplier = 3.0
		mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		piece.mesh = box
		piece.material_override = mat
		var angle = randf_range(0, TAU)
		var radius = randf_range(0.5, 2.0)
		var height_off = randf_range(-1.5, 1.5)
		piece.position = Vector3(cos(angle) * radius, height_off, sin(angle) * radius)
		root.add_child(piece)
		var ptween = piece.create_tween()
		ptween.set_parallel(true)
		if i % 2 == 0:
			var outward = Vector3(cos(angle + randf_range(-0.5, 0.5)), randf_range(-1, 1), sin(angle + randf_range(-0.5, 0.5))).normalized()
			ptween.tween_property(piece, "position", outward * randf_range(2.0, 5.0), duration * 0.5).set_trans(Tween.TRANS_QUAD)
		else:
			ptween.tween_property(piece, "position", Vector3(0, 0, 0), duration * 0.7).set_trans(Tween.TRANS_QUAD)
		ptween.tween_property(mat, "albedo_color", Color(0, 0, 0, 0), duration * 0.7)
		ptween.tween_property(mat, "emission", Color(0, 0, 0, 0), duration * 0.7)

	var sph = MeshInstance3D.new()
	var sphere = SphereMesh.new()
	sphere.radius = 0.01
	sphere.height = 0.02
	sphere.radial_segments = 20
	sphere.rings = 14
	var smat = StandardMaterial3D.new()
	smat.albedo_color = Color(0.0, 0.0, 0.0, 1)
	smat.emission_enabled = true
	smat.emission = Color(0.15, 0.0, 0.3, 1)
	smat.emission_energy_multiplier = 4.0
	sph.mesh = sphere
	sph.material_override = smat
	root.add_child(sph)
	var stween = sph.create_tween()
	stween.tween_property(sph, "scale", Vector3(3.0, 3.0, 3.0), duration * 0.75).set_trans(Tween.TRANS_QUAD)

	var light = OmniLight3D.new()
	light.light_color = Color(0.3, 0.0, 0.6, 1)
	light.light_energy = 4.0
	light.omni_range = 12.0
	root.add_child(light)
	var ltween = root.create_tween()
	ltween.tween_property(light, "light_energy", 15.0, duration * 0.3).set_trans(Tween.TRANS_QUAD)
	ltween.tween_property(light, "light_energy", 0.0, duration * 0.7).set_delay(duration * 0.3)

	set_process(false)
	set_physics_process(false)
	var mtween = create_tween()
	mtween.set_parallel(true)
	mtween.tween_property(self, "scale", Vector3(0.0, 0.0, 0.0), duration * 0.7).set_trans(Tween.TRANS_QUAD)
	var all_meshes = find_children("*", "MeshInstance3D", true)
	for c in all_meshes:
		var m = c.material_override
		if m is StandardMaterial3D:
			mtween.tween_property(m, "albedo_color", Color(0, 0, 0, 0), duration * 0.7)
			mtween.tween_property(m, "emission", Color(0, 0, 0, 0), duration * 0.7)
	await get_tree().create_timer(duration + 0.3).timeout
	root.queue_free()
	queue_free()

func _restore_speed() -> void:
	if _dying or _ice_block == null:
		return
	_ice_explode(_ice_block.global_position)
	if _dying or _ice_block == null:
		return
	_ice_block.queue_free()
	_ice_block = null
	if _mesh_instance != null and _mesh_instance.material_override is BaseMaterial3D:
		_mesh_instance.material_override.albedo_color = _original_color
	if _anim_player:
		_anim_player.play("Animation")
