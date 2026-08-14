extends CharacterBody3D

@export var health: float = 120.0
@export var speed: float = 1.8
@export var attack_distance: float = 2.5
@export var attack_damage: float = 20.0
@export var frozen_color: Color = Color(0.3, 0.6, 1, 1)
@export var model_path: String = "res://models/Fantasy_Heroes_Free/FBX/Characters/Dwarf_Warrior.glb"
@export var model_scale: float = 2.0

const _BONE_MAP: Dictionary = {
	"mixamorig_Hips": "spine",
	"mixamorig_Spine": "spine.001",
	"mixamorig_Spine1": "spine.002",
	"mixamorig_Spine2": "spine.003",
	"mixamorig_Neck": "spine.004",
	"mixamorig_Head": "spine.005",
	"mixamorig_HeadTop_End": "spine.006",
	"mixamorig_LeftShoulder": "shoulder.L",
	"mixamorig_LeftArm": "upper_arm.L",
	"mixamorig_LeftForeArm": "forearm.L",
	"mixamorig_LeftHand": "hand.L",
	"mixamorig_RightShoulder": "shoulder.R",
	"mixamorig_RightArm": "upper_arm.R",
	"mixamorig_RightForeArm": "forearm.R",
	"mixamorig_RightHand": "hand.R",
	"mixamorig_LeftUpLeg": "thigh.L",
	"mixamorig_LeftLeg": "shin.L",
	"mixamorig_LeftFoot": "foot.L",
	"mixamorig_LeftToeBase": "toe.L",
	"mixamorig_RightUpLeg": "thigh.R",
	"mixamorig_RightLeg": "shin.R",
	"mixamorig_RightFoot": "foot.R",
	"mixamorig_RightToeBase": "toe.R",
}

var _player: Node3D = null
var _mesh_instance: MeshInstance3D = null
var _original_color: Color = Color.WHITE
var _health_bar = null
var _max_health: float = 120.0
var _anim_player: AnimationPlayer = null
var _is_alive: bool = true
var _is_paralizado: bool = false
var _original_speed: float = 1.8
var _dying: bool = false
var _skel: Skeleton3D = null
var _skel_path: String = ""
var _ice_block: MeshInstance3D = null
var _ice_mat: StandardMaterial3D = null
var _current_anim: String = ""
var _attack_cooldown: float = 0.0
var _attacking: bool = false
var _nav: NavigationAgent3D = null

func _ready() -> void:
	_original_speed = speed
	_max_health = health
	add_to_group("enemies")
	_load_model()
	_setup_health_bar()
	_nav = NavigationAgent3D.new()
	_nav.name = "NavigationAgent3D"
	_nav.radius = 0.5
	_nav.target_desired_distance = attack_distance * 0.5
	add_child(_nav)

func _load_model() -> void:
	var scene = load(model_path)
	if scene == null:
		print("ERROR: No se pudo cargar modelo: ", model_path)
		return
	var model = scene.instantiate()
	model.name = "Model"
	var wrapper = Node3D.new()
	wrapper.name = "ModelWrapper"
	wrapper.rotation.y = 0
	wrapper.position.y = -1.0
	add_child(wrapper)
	wrapper.add_child(model)
	model.scale = Vector3(model_scale, model_scale, model_scale)

	var meshes = model.find_children("*", "MeshInstance3D", true, false)
	_mesh_instance = meshes[0] as MeshInstance3D if meshes.size() > 0 else null

	var skel_nodes = model.find_children("*", "Skeleton3D", true, false)
	if skel_nodes.size() > 0:
		_skel = skel_nodes[0] as Skeleton3D
	elif model is Skeleton3D:
		_skel = model as Skeleton3D
	if _skel:
		_skel_path = _build_skel_path(model, _skel)

	_anim_player = AnimationPlayer.new()
	_anim_player.name = "AnimationPlayer"
	_anim_player.root_node = NodePath("..")
	model.add_child(_anim_player)

	if _mesh_instance != null:
		if _skel != null and _mesh_instance.get_parent() != _skel:
			_mesh_instance.reparent(_skel)
		var mat: Material = _mesh_instance.material_override
		if mat == null:
			mat = _mesh_instance.get_surface_override_material(0)
		if mat == null and _mesh_instance.mesh != null:
			mat = _mesh_instance.mesh.surface_get_material(0)
		if mat is BaseMaterial3D:
			_original_color = mat.albedo_color
			mat = mat.duplicate()
			_mesh_instance.material_override = mat

	_anim_player.animation_finished.connect(_on_anim_finished)
	_load_anims()

func _build_skel_path(from: Node, to: Node) -> String:
	var parts: Array[String] = []
	var node = to
	while node != from:
		parts.push_front(node.name)
		node = node.get_parent()
	var result = ""
	for p in parts:
		if result != "":
			result += "/"
		result += p
	return result

func _load_anims() -> void:
	if _anim_player.has_animation_library(""):
		_anim_player.remove_animation_library("")
	var lib = AnimationLibrary.new()
	_anim_player.add_animation_library("", lib)
	var paths = {
		"idle": "res://models/skeleton/anim/Skeleton_Idle.fbx",
		"walk": "res://models/skeleton/anim/Skeleton_Walking.fbx",
		"attack": "res://models/skeleton/anim/Steleton_Attack.fbx",
		"die": "res://models/skeleton/anim/Skeleton_Dying.fbx",
	}
	var loaded = 0
	for name in paths:
		var res = load(paths[name])
		var anim: Animation = null
		if res is Animation:
			anim = res
		elif res is PackedScene:
			var inst = res.instantiate()
			var ap = inst.find_child("AnimationPlayer", true, false) as AnimationPlayer
			if ap:
				var anim_names = ap.get_animation_list()
				if anim_names.size() > 0:
					anim = ap.get_animation(anim_names[0])
			inst.queue_free()
		if anim:
			anim = anim.duplicate()
			_strip_position_tracks(anim)
			_remap_bone_tracks(anim)
			anim.loop_mode = Animation.LOOP_LINEAR if name in ["idle", "walk"] else Animation.LOOP_NONE
			lib.add_animation(name, anim)
			loaded += 1
	if loaded == 0:
		print("ERROR: Ninguna animacion cargada para Guardian")

func _remap_bone_tracks(anim: Animation) -> void:
	if _skel == null:
		return
	var t = anim.get_track_count() - 1
	while t >= 0:
		var pstr = str(anim.track_get_path(t))
		var col_pos = pstr.find(":")
		if col_pos == -1:
			t -= 1
			continue
		var bone_name = pstr.substr(col_pos + 1)
		var mapped = _BONE_MAP.get(bone_name, "")
		if mapped == "" or mapped == "spine":
			anim.remove_track(t)
			t -= 1
			continue
		var new_p = NodePath(_skel_path + ":" + mapped)
		anim.track_set_path(t, new_p)
		t -= 1

func _strip_position_tracks(anim: Animation) -> void:
	var i = anim.get_track_count() - 1
	while i >= 0:
		if anim.track_get_type(i) == Animation.TYPE_POSITION_3D:
			anim.remove_track(i)
		i -= 1

func _play_anim(name: String) -> void:
	if _current_anim == name:
		return
	if _anim_player and _anim_player.has_animation(name):
		_anim_player.play(name, 0.2)
		_current_anim = name

func _on_anim_finished(anim_name: String) -> void:
	if anim_name == "attack":
		_attacking = false
	if anim_name in ["idle", "walk"] and _current_anim == anim_name:
		_anim_player.play(anim_name, 0.05)

func _setup_health_bar() -> void:
	var bar_script = preload("res://scripts/health_bar_3d.gd")
	if bar_script == null:
		return
	_health_bar = bar_script.new()
	_health_bar.name = "HealthBar3D"
	_health_bar.position = Vector3(0, 3.0, 0)
	add_child(_health_bar)
	_health_bar.setup(_max_health)

func init_player(player_node: Node3D) -> void:
	_player = player_node

func _get_target() -> Node3D:
	var summons := get_tree().get_nodes_in_group("summons")
	for s in summons:
		if is_instance_valid(s) and s.is_inside_tree():
			return s
	return _player

func _find_player() -> Node3D:
	if _player and is_instance_valid(_player) and _player.is_inside_tree():
		return _player
	_player = get_tree().get_first_node_in_group("player")
	return _player

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
	if not _is_alive:
		return
	health -= amount
	if _health_bar:
		_health_bar.update_health(health, _max_health)
	if health <= 0:
		_die()

func _die() -> void:
	_is_alive = false
	_dying = true
	AudioManager.play_enemy_death(global_position)
	var death_pos = global_position
	_spawn_soul_at(death_pos)
	if _player and _player.has_method("restore_mana"):
		_player.restore_mana(15.0)
	if _health_bar:
		_health_bar.visible = false
	if _anim_player and _anim_player.has_animation("die"):
		_anim_player.play("die")
		await get_tree().create_timer(2.0).timeout
	else:
		await get_tree().create_timer(0.3).timeout
	queue_free()

func _spawn_soul_at(pos: Vector3) -> void:
	var alma = load("res://scripts/alma_espectral.gd")
	if alma == null:
		return
	var node = Area3D.new()
	node.set_script(alma)
	node.global_position = pos + Vector3(0, 1.0, 0)
	get_tree().root.add_child(node)

func apply_freeze(duration: float, slow_factor: float) -> void:
	if _ice_block:
		return
	speed = 0
	if _anim_player:
		_anim_player.stop()
	if _mesh_instance:
		var mat = _mesh_instance.material_override
		if mat == null:
			mat = _mesh_instance.get_surface_override_material(0)
		if mat == null and _mesh_instance.mesh:
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
	_ice_block = MeshInstance3D.new()
	_ice_block.mesh = cyl
	_ice_block.material_override = _get_ice_mat()
	get_tree().root.add_child(_ice_block)
	_ice_block.global_position = global_position + Vector3(0, 1.0, 0)
	get_tree().create_timer(duration).timeout.connect(_restore_speed)

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

func _restore_speed() -> void:
	if _ice_block == null:
		return
	_ice_explode(_ice_block.global_position)
	if _ice_block == null:
		return
	_ice_block.queue_free()
	_ice_block = null
	speed = _original_speed
	if _anim_player:
		_anim_player.play(_current_anim)
	if _mesh_instance and _mesh_instance.material_override is BaseMaterial3D:
		_mesh_instance.material_override.albedo_color = _original_color

func _spawn_attack_trail() -> void:
	var pos = global_position + Vector3(0, 1.2, 0)
	for i in 8:
		var dot = MeshInstance3D.new()
		var box = BoxMesh.new()
		var s = randf_range(0.04, 0.08)
		box.size = Vector3(s, s, s)
		var mat = StandardMaterial3D.new()
		mat.albedo_color = Color(0.6, 0.8, 1.0, 0.8)
		mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		mat.emission_enabled = true
		mat.emission = Color(0.4, 0.6, 1.0)
		mat.emission_energy_multiplier = 6.0
		dot.mesh = box
		dot.material_override = mat
		var angle = (i / 8.0 - 0.5) * deg_to_rad(120)
		var forward = (-global_transform.basis.z).normalized()
		var right = global_transform.basis.x.normalized()
		dot.global_position = pos + forward * 1.5 + right * sin(angle) * 1.0 + Vector3(0, cos(angle) * 0.5, 0)
		get_tree().root.add_child(dot)
		var dtween = dot.create_tween()
		dtween.tween_property(dot, "scale", Vector3(3.0, 3.0, 3.0), 0.2)
		dtween.parallel().tween_property(mat, "albedo_color", Color(0, 0, 0, 0), 0.2)
		dtween.tween_callback(dot.queue_free)

func _deal_attack_damage() -> void:
	if not _attacking:
		return
	AudioManager.play_melee_swing(global_position)
	var target := _get_target()
	if target != null and target.has_method("take_damage"):
		target.take_damage(attack_damage)

func _physics_process(_delta: float) -> void:
	if not _is_alive or _dying or _ice_block or _is_paralizado:
		return
	var target := _get_target()
	if target == null:
		target = _find_player()
	if target == null:
		return
	var dist := global_position.distance_to(target.global_position)
	var moving = dist > attack_distance + 0.3
	var dir_to_target = (target.global_position - global_position).normalized()
	dir_to_target.y = 0
	rotation.y = atan2(dir_to_target.x, dir_to_target.z)

	var horizontal_velocity = Vector3.ZERO

	if moving:
		_nav.target_position = target.global_position
		var next_pos = _nav.get_next_path_position()
		var to_next = next_pos - global_position
		to_next.y = 0
		if to_next.length_squared() > 0.1:
			horizontal_velocity = to_next.normalized() * speed
		else:
			horizontal_velocity = dir_to_target * speed
		_play_anim("walk")
	else:
		horizontal_velocity = Vector3.ZERO
		_attack_cooldown -= _delta
		if _attack_cooldown <= 0 and dist < attack_distance:
			_play_anim("attack")
			_attack_cooldown = 1.5
			_attacking = true
			_spawn_attack_trail()
			get_tree().create_timer(0.5).timeout.connect(_deal_attack_damage)
		elif dist < attack_distance and not _attacking:
			_play_anim("idle")

	velocity.x = horizontal_velocity.x
	velocity.z = horizontal_velocity.z
	if not is_on_floor():
		velocity.y -= 9.8 * _delta
	else:
		velocity.y = 0.0

	move_and_slide()
