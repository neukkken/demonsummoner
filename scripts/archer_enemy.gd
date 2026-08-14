extends CharacterBody3D

@export var health: float = 40.0
@export var shoot_interval: float = 2.0
@export var arrow_damage: float = 14.0
@export var move_speed: float = 3.5
@export var strafe_speed: float = 2.5
@export var retreat_speed: float = 5.5
@export var min_range: float = 8.0
@export var max_range: float = 22.0
@export var attack_range: float = 18.0
@export var frozen_color: Color = Color(0.3, 0.6, 1, 1)
@export var model_path: String = "res://models/Fantasy_Heroes_Free/FBX/Characters/Elf_Archer.glb"
@export var bow_path: String = "res://models/Fantasy_Heroes_Free/FBX/Weapons/Hero_Bow.glb"
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
var _nav: NavigationAgent3D = null
var _shoot_cooldown: float = 0.0
var _strafe_dir: float = 1.0
var _strafe_change: float = 0.0
var _dying: bool = false
var _mesh_instance: MeshInstance3D = null
var _original_color: Color = Color.WHITE
var _health_bar = null
var _max_health: float = 40.0
var _is_paralizado: bool = false
var _ice_block: MeshInstance3D = null
var _ice_mat: StandardMaterial3D = null
var _anim_player: AnimationPlayer = null
var _current_anim: String = ""
var _skel: Skeleton3D = null
var _skel_path: String = ""
var _bow_node: Node3D = null

func _ready() -> void:
	_max_health = health
	add_to_group("enemies")
	_load_model()
	_setup_health_bar()
	_nav = NavigationAgent3D.new()
	_nav.name = "NavigationAgent3D"
	_nav.radius = 0.5
	_nav.target_desired_distance = 2.0
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
			if not mat.albedo_texture:
				var tex = load("res://models/Fantasy_Heroes_Free/Texture/Texture.png")
				if tex:
					mat.albedo_texture = tex
			mat.albedo_color = Color(0.35, 0.55, 0.25, 1)

	_anim_player.animation_finished.connect(_on_anim_finished)
	_load_anims()
	_load_bow(model)
	_play_anim("idle")

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
		print("ERROR: Ninguna animacion cargada para Archer")

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

func _load_bow(model: Node3D) -> void:
	var bow_scene = load(bow_path)
	if bow_scene == null:
		return
	_bow_node = bow_scene.instantiate()
	if _skel:
		var bone_idx = _skel.find_bone("mixamorig_RightHand")
		if bone_idx == -1:
			bone_idx = _skel.find_bone("RightHand")
		if bone_idx == -1:
			bone_idx = _skel.find_bone("hand.R")
		if bone_idx != -1:
			_skel.add_child(_bow_node)
			_bow_node.transform = Transform3D()
			_bow_node.position = Vector3(0.15, -0.03, 0.12)
			_bow_node.rotation_degrees = Vector3(0, 0, -90)
			return
	_bow_node.position = Vector3(0.3, 1.0, 0.15)
	_bow_node.rotation_degrees = Vector3(0, 0, -90)
	model.add_child(_bow_node)

func _play_anim(name: String) -> void:
	if _current_anim == name:
		return
	if _anim_player and _anim_player.has_animation(name):
		_anim_player.play(name, 0.2)
		_current_anim = name

func _on_anim_finished(anim_name: String) -> void:
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

func take_damage(amount: float) -> void:
	if _dying:
		return
	health -= amount
	if _health_bar:
		_health_bar.update_health(health, _max_health)
	if health <= 0:
		_die()

func _die() -> void:
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

func paralizar(duracion: float) -> void:
	_is_paralizado = true
	var timer = Timer.new()
	timer.one_shot = true
	timer.timeout.connect(func():
		_is_paralizado = false
	)
	add_child(timer)
	timer.start(duracion)

func apply_freeze(duration: float, slow_factor: float) -> void:
	if _ice_block:
		return
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

func _restore_speed() -> void:
	if _ice_block == null:
		return
	_ice_explode(_ice_block.global_position)
	if _ice_block == null:
		return
	_ice_block.queue_free()
	_ice_block = null
	if _mesh_instance and _mesh_instance.material_override is BaseMaterial3D:
		_mesh_instance.material_override.albedo_color = _original_color
	if _anim_player:
		_anim_player.play(_current_anim)

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

func _shoot_arrow() -> void:
	if _dying or _ice_block or _is_paralizado:
		return
	var target = _get_target()
	if target == null:
		return
	var dist = global_position.distance_to(target.global_position)
	if dist > max_range or dist < min_range * 0.5:
		return
	_play_anim("attack")
	AudioManager.play_mage_shoot(global_position)
	var arrow = Area3D.new()
	arrow.name = "ArrowProjectile"
	var col = CollisionShape3D.new()
	var cshape = BoxShape3D.new()
	cshape.size = Vector3(0.15, 0.15, 0.6)
	col.shape = cshape
	arrow.add_child(col)
	var body = MeshInstance3D.new()
	var box = BoxMesh.new()
	box.size = Vector3(0.06, 0.06, 0.5)
	var mat = StandardMaterial3D.new()
	mat.albedo_color = Color(0.45, 0.35, 0.25)
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.emission_enabled = true
	mat.emission = Color(0.35, 0.25, 0.15)
	mat.emission_energy_multiplier = 1.5
	body.mesh = box
	body.material_override = mat
	arrow.add_child(body)
	var tip = MeshInstance3D.new()
	var cone = CylinderMesh.new()
	cone.top_radius = 0.0
	cone.bottom_radius = 0.08
	cone.height = 0.15
	var tmat = StandardMaterial3D.new()
	tmat.albedo_color = Color(0.55, 0.45, 0.35)
	tmat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	tmat.emission_enabled = true
	tmat.emission = Color(0.4, 0.3, 0.2)
	tmat.emission_energy_multiplier = 2.0
	tip.mesh = cone
	tip.material_override = tmat
	tip.position.z = -0.3
	arrow.add_child(tip)
	var fletch = MeshInstance3D.new()
	var fbox = BoxMesh.new()
	fbox.size = Vector3(0.12, 0.02, 0.04)
	var fmat = StandardMaterial3D.new()
	fmat.albedo_color = Color(0.6, 0.15, 0.1)
	fmat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	fletch.mesh = fbox
	fletch.material_override = fmat
	fletch.position.z = 0.25
	fletch.rotation.y = deg_to_rad(45)
	arrow.add_child(fletch)
	var fletch2 = fletch.duplicate()
	fletch2.rotation.y = deg_to_rad(-45)
	arrow.add_child(fletch2)
	var arrow_script = load("res://scripts/arrow_projectile.gd")
	if arrow_script:
		arrow.set_script(arrow_script)
	arrow.collision_mask = 1
	arrow.body_entered.connect(_on_arrow_hit.bind(arrow))
	get_tree().root.add_child(arrow)
	arrow.global_position = global_position + Vector3(0, 1.5, 0)
	var dir = (target.global_position - arrow.global_position).normalized()
	arrow.look_at(arrow.global_position + dir, Vector3.UP)
	if arrow.has_method("set_velocity") or "velocity" in arrow:
		arrow.velocity = dir * 28.0
	arrow.set_meta("damage", arrow_damage)
	get_tree().create_timer(3.0).timeout.connect(func():
		if is_instance_valid(arrow):
			arrow.queue_free()
	)

func _on_arrow_hit(body: Node, arrow: Area3D) -> void:
	if not is_instance_valid(arrow):
		return
	if body.is_in_group("enemies") or body == self:
		return
	if body.has_method("take_damage"):
		body.take_damage(arrow.get_meta("damage", arrow_damage))
	arrow.queue_free()

func _physics_process(delta: float) -> void:
	if _dying or _ice_block or _is_paralizado or not is_inside_tree():
		return
	var target = _get_target()
	if target == null:
		target = _find_player()
	if target == null:
		return
	var dist = global_position.distance_to(target.global_position)
	var dir_to_target = (target.global_position - global_position).normalized()
	dir_to_target.y = 0
	rotation.y = atan2(dir_to_target.x, dir_to_target.z)

	var horizontal_velocity = Vector3.ZERO

	if dist > max_range:
		_nav.target_position = target.global_position
		var next_pos = _nav.get_next_path_position()
		var to_next = next_pos - global_position
		to_next.y = 0
		if to_next.length_squared() > 0.1:
			horizontal_velocity = to_next.normalized() * move_speed
		else:
			horizontal_velocity = dir_to_target * move_speed
		_play_anim("walk")
	elif dist < min_range:
		var away_dir = (global_position - target.global_position).normalized()
		away_dir.y = 0
		var desired = global_position + away_dir * min_range
		_nav.target_position = desired
		var next_pos = _nav.get_next_path_position()
		var to_next = next_pos - global_position
		to_next.y = 0
		if to_next.length_squared() > 0.1:
			horizontal_velocity = to_next.normalized() * retreat_speed
		else:
			horizontal_velocity = away_dir * retreat_speed
		_play_anim("walk")
	elif dist < attack_range:
		_strafe_change -= delta
		if _strafe_change <= 0:
			_strafe_dir = 1.0 if randf() > 0.5 else -1.0
			_strafe_change = randf_range(1.0, 3.0)
		var strafe_vec = dir_to_target.cross(Vector3.UP).normalized() * _strafe_dir
		var strafe_target = global_position + strafe_vec * 3.0
		_nav.target_position = strafe_target
		var next_pos = _nav.get_next_path_position()
		var to_next = next_pos - global_position
		to_next.y = 0
		if to_next.length_squared() > 0.5:
			horizontal_velocity = to_next.normalized() * strafe_speed
			_play_anim("walk")
		else:
			horizontal_velocity = Vector3.ZERO
			_play_anim("idle")
		_shoot_cooldown -= delta
		if _shoot_cooldown <= 0:
			_shoot_arrow()
			_shoot_cooldown = shoot_interval + randf_range(-0.3, 0.3)
	else:
		_nav.target_position = global_position
		horizontal_velocity = Vector3.ZERO
		_play_anim("idle")

	velocity.x = horizontal_velocity.x
	velocity.z = horizontal_velocity.z
	if not is_on_floor():
		velocity.y -= 9.8 * delta
	else:
		velocity.y = 0.0

	move_and_slide()
