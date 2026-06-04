extends Node3D

@export var enemy_types: Array[PackedScene]
@export var enemy_enabled: Array[bool] = [true, true]
@export var player_path: NodePath
@export var spawn_interval_base: float = 3.0
@export var spawn_radius_min: float = 15.0
@export var spawn_radius_max: float = 25.0
@export var min_spawn_interval: float = 0.8
@export var spawn_bounds_min: Vector3 = Vector3(-55, 0, -55)
@export var spawn_bounds_max: Vector3 = Vector3(55, 0, 55)
@export var xp_values: Array[int] = [10, 25]
@export var xp_base_next: int = 50
@export var xp_scale: float = 1.3
@export var hp_scale_per_level: float = 0.15
@export var dmg_scale_per_level: float = 0.1
@export var spawn_rate_exponent: float = 0.12
@export var spawning_paused: bool = false:
	set(value):
		spawning_paused = value
		if _spawn_timer != null:
			_spawn_timer.paused = spawning_paused

var _player: Node3D = null
var _hud: Node = null
var _spawn_timer: Timer = null
var _total_xp: int = 0
var _xp_to_next: int = 50
var _tracked_enemies: Dictionary = {}
var _last_level: int = 0


func _ready() -> void:
	add_to_group("wave_spawner")
	if player_path:
		_player = get_node(player_path) as Node3D
		if _player:
			_hud = _find_hud(_player)
	_xp_to_next = xp_base_next

	_spawn_timer = Timer.new()
	_spawn_timer.one_shot = false
	_spawn_timer.timeout.connect(_spawn_enemy)
	add_child(_spawn_timer)
	_actualizar_intervalo()


func _get_player_level() -> int:
	if _player == null or not is_instance_valid(_player):
		return 1
	return _player.level if "level" in _player else 1

func _actualizar_intervalo():
	var level := _get_player_level()
	var rate = spawn_interval_base * exp(-spawn_rate_exponent * (level - 1))
	rate = maxf(rate, min_spawn_interval)
	_spawn_timer.start(rate)
	if level != _last_level:
		print("Nivel ", level, " — intervalo de spawn: ", snapped(rate, 0.1), "s")
		_last_level = level

func _spawn_enemy() -> void:
	if spawning_paused or enemy_types.is_empty() or _player == null:
		return
	_actualizar_intervalo()

	var available: Array[int] = []
	for i in enemy_types.size():
		if i < enemy_enabled.size() and enemy_enabled[i]:
			available.append(i)
	if available.is_empty():
		return

	var level := _get_player_level()
	var count := 1 + (level / 3)
	count = mini(count, 5)

	for s in range(count):
		var idx := available[randi() % available.size()]
		var chosen := enemy_types[idx]
		var enemy := chosen.instantiate() as CharacterBody3D
		if enemy == null:
			continue

		get_tree().root.add_child(enemy)

		var angle := randf_range(0.0, TAU)
		var dist := randf_range(spawn_radius_min, spawn_radius_max)
		var offset := Vector3(cos(angle), 0.0, sin(angle)) * dist
		var spawn_pos := _player.global_position + offset
		spawn_pos.x = clampf(spawn_pos.x, spawn_bounds_min.x, spawn_bounds_max.x)
		spawn_pos.z = clampf(spawn_pos.z, spawn_bounds_min.z, spawn_bounds_max.z)
		spawn_pos.y = 1.0
		enemy.global_position = spawn_pos

		if enemy.has_method("init_player"):
			enemy.init_player(_player)

		_escalar_enemigo(enemy, idx, level)

		var xp := xp_values[idx] if idx < xp_values.size() else 10
		xp = ceili(xp * (1.0 + level * 0.2))
		_tracked_enemies[enemy.get_instance_id()] = xp
		enemy.tree_exited.connect(_on_enemy_killed.bind(enemy.get_instance_id()))

func _escalar_enemigo(enemy: CharacterBody3D, idx: int, level: int) -> void:
	if level <= 1:
		return
	var hp_mult := 1.0 + hp_scale_per_level * (level - 1)
	var dmg_mult := 1.0 + dmg_scale_per_level * (level - 1)

	if "health" in enemy:
		enemy.health = ceili(enemy.health * hp_mult)
	if "attack_damage" in enemy:
		enemy.attack_damage = enemy.attack_damage * dmg_mult
	if "projectile_damage" in enemy:
		enemy.projectile_damage = enemy.projectile_damage * dmg_mult
	if "speed" in enemy and idx == 0:
		enemy.speed = enemy.speed * (1.0 + 0.05 * (level - 1))
	if "shoot_interval" in enemy and idx == 1:
		enemy.shoot_interval = maxf(1.0, enemy.shoot_interval - 0.15 * (level - 1))


func _on_enemy_killed(eid: int) -> void:
	if not _tracked_enemies.has(eid):
		return
	var xp: int = _tracked_enemies[eid]
	_tracked_enemies.erase(eid)
	_total_xp += xp
	if _player == null or not _player.is_inside_tree():
		return
	if _hud == null:
		_hud = _find_hud(_player)
		if _hud == null:
			return

	if _total_xp >= _xp_to_next:
		_total_xp -= _xp_to_next
		_xp_to_next = ceili(_xp_to_next * xp_scale)
		_hud.set_xp(_total_xp, _xp_to_next)
		_hud.show_level_up(_player)
	else:
		_hud.set_xp(_total_xp, _xp_to_next)


func set_hud(hud: Node) -> void:
	_hud = hud

func _find_hud(player: Node) -> Node:
	for child in player.get_children():
		if child is CanvasLayer and child.has_method("set_xp"):
			return child
	return null


func _increase_difficulty() -> void:
	_actualizar_intervalo()
