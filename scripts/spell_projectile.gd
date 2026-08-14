extends Area3D

@export var speed: float = 30.0
@export var damage: float = 125.0

var effect_type: String = "fire"
var freeze_duration: float = 3.0
var freeze_slow: float = 0.5

var _trail_timer: float = 0.0
var _dying: bool = false
var _time: float = 0.0
var _target: Node3D = null
var damage_origin: Node = null

@onready var _light: OmniLight3D = $OmniLight3D
@onready var _flames: Node3D = get_node_or_null("Flames")
@onready var _crystals: Node3D = get_node_or_null("Crystals")

func set_target(node: Node3D) -> void:
	_target = node

static var _pool: Array[MeshInstance3D] = []
static var _pool_idx: int = 0
static var _inited: bool = false

static var _box: BoxMesh = null
static var _fire_trail: StandardMaterial3D = null
static var _ice_trail: StandardMaterial3D = null
static var _fire_hit: StandardMaterial3D = null
static var _ice_hit: StandardMaterial3D = null
static var _ice_shard: StandardMaterial3D = null

const POOL_SIZE := 140

static func _init_pool() -> void:
	if _inited:
		return
	_inited = true
	_box = BoxMesh.new()
	_box.size = Vector3(0.12, 0.12, 0.12)

	_fire_trail = StandardMaterial3D.new()
	_fire_trail.albedo_color = Color(1, 0.55, 0.02, 0.9)
	_fire_trail.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_fire_trail.emission_enabled = true
	_fire_trail.emission = Color(1, 0.55, 0.02)
	_fire_trail.emission_energy_multiplier = 4.0

	_ice_trail = StandardMaterial3D.new()
	_ice_trail.albedo_color = Color(0.6, 0.9, 1, 0.85)
	_ice_trail.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_ice_trail.emission_enabled = true
	_ice_trail.emission = Color(0.6, 0.9, 1)
	_ice_trail.emission_energy_multiplier = 4.0

	_fire_hit = StandardMaterial3D.new()
	_fire_hit.albedo_color = Color(1, 0.5, 0.0, 1)
	_fire_hit.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_fire_hit.emission_enabled = true
	_fire_hit.emission = Color(1, 0.5, 0.0)
	_fire_hit.emission_energy_multiplier = 4.0

	_ice_hit = StandardMaterial3D.new()
	_ice_hit.albedo_color = Color(0.5, 0.8, 1, 1)
	_ice_hit.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_ice_hit.emission_enabled = true
	_ice_hit.emission = Color(0.5, 0.8, 1)
	_ice_hit.emission_energy_multiplier = 4.0

	_ice_shard = StandardMaterial3D.new()
	_ice_shard.albedo_color = Color(0.9, 0.95, 1, 0.9)
	_ice_shard.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_ice_shard.emission_enabled = true
	_ice_shard.emission = Color(0.9, 0.95, 1)
	_ice_shard.emission_energy_multiplier = 5.0

static func _is_free(p: MeshInstance3D) -> bool:
	return is_instance_valid(p) and (not p.visible or p.scale.length_squared() < 0.001)

func _get_piece() -> MeshInstance3D:
	for i in POOL_SIZE:
		var idx := (_pool_idx + i) % POOL_SIZE
		if idx < _pool.size():
			var p := _pool[idx]
			if _is_free(p):
				_pool_idx = (idx + 1) % POOL_SIZE
				return p
	var p := MeshInstance3D.new()
	p.mesh = _box
	get_tree().root.add_child(p)
	p.visible = false
	_pool.append(p)
	return p

func _ready() -> void:
	_init_pool()
	body_entered.connect(_on_body_entered)
	var timer := Timer.new()
	timer.one_shot = true
	timer.timeout.connect(_on_timer_expired)
	add_child(timer)
	timer.start(3.0)

func _on_timer_expired() -> void:
	_dying = true
	queue_free()

func _physics_process(delta: float) -> void:
	if _target and is_instance_valid(_target):
		var dir = global_position.direction_to(_target.global_position)
		var angle_diff = absf(global_transform.basis.z.angle_to(-dir))
		if angle_diff > 0.01:
			look_at(_target.global_position, Vector3.UP)
	global_position -= global_transform.basis.z * speed * delta

func _process(delta: float) -> void:
	_time += delta
	_light.light_energy = 1.2 + sin(_time * 30.0) * 0.4
	if _flames:
		_flames.rotation.y += delta * 3.0
		_flames.rotation.x += delta * 1.5
	if _crystals:
		_crystals.rotation.y += delta * 2.0
		_crystals.rotation.x += delta * 0.8
	if _dying or not is_inside_tree():
		return
	_trail_timer += delta
	while _trail_timer >= 0.02:
		_trail_timer -= 0.02
		_spawn_trail()

func _spawn_trail() -> void:
	var piece := _get_piece()
	if piece == null:
		return
	var s := randf_range(0.12, 0.3)
	var mat: StandardMaterial3D = _fire_trail if effect_type == "fire" else _ice_trail
	piece.scale = Vector3(s / 0.12, s / 0.12, s / 0.12)
	piece.material_override = mat
	piece.global_position = global_position + Vector3(randf_range(-0.12, 0.12), randf_range(-0.08, 0.08), randf_range(-0.12, 0.12))
	piece.visible = true
	var tween := piece.create_tween()
	tween.tween_property(piece, "scale", Vector3.ZERO, 0.7)
	tween.tween_callback(func():
		if is_instance_valid(piece):
			piece.visible = false
			piece.scale = Vector3.ONE
			piece.material_override = null
	)

func _make_impact_mat(col: Color) -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = col
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.emission_enabled = true
	mat.emission = col
	mat.emission_energy_multiplier = 4.0
	return mat

func _spawn_impact() -> void:
	if not is_inside_tree():
		return
	var is_fire := effect_type == "fire"
	var base_pos := global_position

	for i in range(40):
		var piece := _get_piece()
		if piece == null:
			break
		var s := randf_range(0.06, 0.22)
		piece.scale = Vector3(s / 0.12, s / 0.12, s / 0.12)
		var col: Color
		if is_fire:
			var t := randf()
			col = Color(1, 0.85, 0.15, 1) if t > 0.5 else Color(1, randf_range(0.35, 0.65), 0.0, 1)
		else:
			col = Color(0.5, 0.8, 1, 1)
		piece.material_override = _make_impact_mat(col)
		piece.global_position = base_pos
		piece.visible = true
		var dir := Vector3(randf_range(-1, 1), randf_range(-0.3, 1.2), randf_range(-1, 1)).normalized()
		var dist := randf_range(1.0, 4.0)
		var tween := piece.create_tween()
		tween.tween_property(piece, "global_position", base_pos + dir * dist, 0.7).set_trans(Tween.TRANS_LINEAR)
		tween.parallel().tween_property(piece, "scale", Vector3.ZERO, 0.7)
		tween.tween_callback(func():
			if is_instance_valid(piece):
				piece.visible = false
				piece.scale = Vector3.ONE
				piece.material_override = null
		)

	if not is_fire:
		for i in range(20):
			var piece := _get_piece()
			if piece == null:
				break
			var s := randf_range(0.03, 0.08)
			piece.scale = Vector3(s / 0.12, s / 0.12, s / 0.12)
			piece.material_override = _make_impact_mat(Color(0.9, 0.95, 1, 0.9))
			piece.global_position = base_pos
			piece.visible = true
			var dir := Vector3(randf_range(-1, 1), randf_range(-0.5, 1.2), randf_range(-1, 1)).normalized()
			var dist := randf_range(1.5, 5.0)
			var tween := piece.create_tween()
			tween.tween_property(piece, "global_position", base_pos + dir * dist, 0.8).set_trans(Tween.TRANS_LINEAR)
			tween.parallel().tween_property(piece, "scale", Vector3.ZERO, 0.8)
			tween.tween_callback(func():
				if is_instance_valid(piece):
					piece.visible = false
					piece.scale = Vector3.ONE
					piece.material_override = null
			)

	var light := OmniLight3D.new()
	light.light_color = Color(1, 0.5, 0, 1) if is_fire else Color(0.3, 0.6, 1, 1)
	light.light_energy = 8.0
	light.omni_range = 8.0
	var ltween := create_tween()
	ltween.tween_property(light, "light_energy", 0.0, 0.6)
	ltween.tween_callback(light.queue_free)

func _on_body_entered(body: Node) -> void:
	if _dying:
		return
	if body.is_in_group("ice_walls"):
		if effect_type == "fire":
			_spawn_impact()
			body.queue_free()
			_dying = true
			queue_free()
		return
	_spawn_impact()
	if effect_type == "ice" and body.has_method("apply_freeze"):
		body.apply_freeze(freeze_duration, freeze_slow)
	elif body.has_method("take_damage"):
		body.take_damage(damage)
		if damage_origin and damage_origin.has_method("_on_projectile_hit"):
			damage_origin._on_projectile_hit(damage)
	_dying = true
	queue_free()
