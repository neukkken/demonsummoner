extends Node3D

@export var enemy_types: Array[PackedScene]
@export var player_path: NodePath
@export var spawn_radius_min: float = 20.0
@export var spawn_radius_max: float = 25.0
@export var spawn_bounds_min: Vector3 = Vector3(-999999.0, 0.0, -999999.0)
@export var spawn_bounds_max: Vector3 = Vector3(999999.0, 0.0, 999999.0)
@export var xp_values: Array[int] = [10, 25]
@export var xp_base_next: int = 20
@export var xp_scale: float = 1.2
@export var hp_scale_per_level: float = 0.15
@export var dmg_scale_per_level: float = 0.1

@export var enable_melee: bool = true
@export var enable_mage: bool = true
@export var enable_suicide: bool = true
@export var enable_archer: bool = true
@export var enable_shaman: bool = true
@export var enable_guardian: bool = true
@export var enable_miniboss: bool = true
@export var enable_spawning: bool = true

const GAME_DURATION := 600.0

var _player: Node3D = null
var _hud: Node = null
var _spawn_timer: Timer = null
var _total_xp: int = 0
var _xp_to_next: int = 20
var _last_level: int = 0
var _elapsed: float = 0.0
var _tracked_enemies: Dictionary = {}
var _muro_triggered: bool = false
var _fin_triggered: bool = false

func _ready():
	add_to_group("wave_spawner")
	if player_path:
		_player = get_node(player_path) as Node3D
		if _player:
			_hud = _find_hud(_player)
	_xp_to_next = xp_base_next
	_spawn_timer = Timer.new()
	_spawn_timer.one_shot = false
	_spawn_timer.timeout.connect(_spawn_enemy)
	if enable_spawning:
		_spawn_timer.start(1.5)
	else:
		_spawn_test_enemies()
	add_child(_spawn_timer)

func _spawn_test_enemies() -> void:
	if _player == null or enemy_types.is_empty():
		print("[DEBUG TEST] Player null or no enemy types")
		return
	print("[DEBUG TEST] Player pos: ", _player.global_position)
	print("[DEBUG TEST] Player is_inside_tree: ", _player.is_inside_tree())
	for i in enemy_types.size():
		if not _can_spawn(i, 9999.0):
			continue
		var chosen := enemy_types[i]
		if chosen == null:
			continue
		var enemy := chosen.instantiate() as CharacterBody3D
		if enemy == null:
			continue
		get_tree().root.add_child(enemy)
		if not enemy.is_in_group("enemies"):
			enemy.add_to_group("enemies")
		var angle := i * TAU / enemy_types.size() + randf_range(-0.3, 0.3)
		var dist := 12.0 if i >= 6 else randf_range(15.0, 20.0)
		var spawn_pos := _player.global_position + Vector3(cos(angle), 0.0, sin(angle)) * dist
		spawn_pos.y = DatosJuego.get_height(spawn_pos.x, spawn_pos.z) + 1.0
		enemy.global_position = spawn_pos
		if enemy.has_method("init_player"):
			enemy.init_player(_player)
		print("[DEBUG TEST] Spawned: ", enemy.name, " idx=", i, " at ", Vector3(snapped(spawn_pos.x, 0.01), snapped(spawn_pos.y, 0.01), snapped(spawn_pos.z, 0.01)), " player at ", Vector3(snapped(_player.global_position.x, 0.01), snapped(_player.global_position.y, 0.01), snapped(_player.global_position.z, 0.01)))

func _process(delta):
	if not enable_spawning:
		return
	_elapsed += delta
	var t = _elapsed
	if t >= 300.0 and not _muro_triggered:
		_trigger_muro()
	if t >= GAME_DURATION and not _fin_triggered:
		_trigger_fin()
	var rate = _get_spawn_rate(t)
	if absf(_spawn_timer.wait_time - rate) > 0.05:
		_spawn_timer.start(rate)
	if _hud and _hud.has_method("set_timer"):
		_hud.set_timer(t, GAME_DURATION)

func _get_spawn_rate(t: float) -> float:
	if t < 120.0:
		return 1.5
	elif t < 240.0:
		return 1.2
	elif t < 360.0:
		return 1.0
	elif t < 540.0:
		return 0.8
	elif t < 600.0:
		return 0.6
	return 0.5

func _get_player_level() -> int:
	if _player == null or not is_instance_valid(_player):
		return 1
	return _player.level if "level" in _player else 1

func _spawn_enemy() -> void:
	if _player == null or enemy_types.is_empty():
		return
	var t = _elapsed
	var available: Array[int] = []
	for i in enemy_types.size():
		if _can_spawn(i, t):
			available.append(i)
	if available.is_empty():
		return
	var count = _get_spawn_count(t)
	for s in range(count):
		var idx := available[randi() % available.size()]
		var chosen := enemy_types[idx]
		var enemy := chosen.instantiate() as CharacterBody3D
		if enemy == null:
			continue
		get_tree().root.add_child(enemy)
		if not enemy.is_in_group("enemies"):
			enemy.add_to_group("enemies")
		var spawn_pos: Vector3
		if DatosJuego.current_dungeon and DatosJuego.current_dungeon.has_method("get_random_spawn_point"):
			spawn_pos = DatosJuego.current_dungeon.get_random_spawn_point(_player.global_position, spawn_radius_min, spawn_radius_max)
		else:
			var angle := randf_range(0.0, TAU)
			var edge_dist := 55.0
			var is_mage := idx == 1 and _elapsed >= 120.0
			var dist := randf_range(spawn_radius_min, edge_dist) if is_mage else randf_range(spawn_radius_min, spawn_radius_max)
			var offset := Vector3(cos(angle), 0.0, sin(angle)) * dist
			spawn_pos = _player.global_position + offset
			spawn_pos.x = clampf(spawn_pos.x, spawn_bounds_min.x, spawn_bounds_max.x)
			spawn_pos.z = clampf(spawn_pos.z, spawn_bounds_min.z, spawn_bounds_max.z)
			spawn_pos.y = DatosJuego.get_height(spawn_pos.x, spawn_pos.z) + 1.0
		enemy.global_position = spawn_pos
		if enemy.has_method("init_player"):
			enemy.init_player(_player)
		var level := _get_player_level()
		_escalar_enemigo(enemy, idx, level)
		var xp := xp_values[idx] if idx < xp_values.size() else 10
		xp = ceili(xp * (1.0 + t * 0.001))
		_tracked_enemies[enemy.get_instance_id()] = xp
		if not enemy.tree_exited.is_connected(_on_enemy_killed):
			enemy.tree_exited.connect(_on_enemy_killed.bind(enemy.get_instance_id()))

func _can_spawn(idx: int, t: float) -> bool:
	match idx:
		0: if not enable_melee: return false
		1: if not enable_mage: return false
		2: if not enable_suicide: return false
		3: if not enable_archer: return false
		4: if not enable_shaman: return false
		5: if not enable_guardian: return false
		6: if not enable_miniboss: return false
	if idx == 0:
		return true
	if idx == 1:
		return t >= 120.0
	if idx == 2:
		return t >= 180.0
	if idx == 3:
		return t >= 60.0
	if idx == 4:
		return t >= 90.0
	if idx == 5:
		return t >= 150.0
	if idx == 6:
		return t >= 300.0
	if idx == 7:
		return t >= 420.0
	if idx == 8:
		return t >= 540.0
	return true

func _get_spawn_count(t: float) -> int:
	if t < 60.0:
		return 1
	elif t < 180.0:
		return 2
	elif t < 300.0:
		return 3
	elif t < 480.0:
		return 4
	else:
		return 5

func _spawn_single_enemy(idx: int, pos: Vector3, hp_mult: float = 1.0) -> void:
	if idx < 0 or idx >= enemy_types.size():
		return
	var chosen := enemy_types[idx]
	if chosen == null:
		return
	var enemy := chosen.instantiate() as CharacterBody3D
	if enemy == null:
		return
	get_tree().root.add_child(enemy)
	if not enemy.is_in_group("enemies"):
		enemy.add_to_group("enemies")
	enemy.global_position = pos
	if enemy.has_method("init_player"):
		enemy.init_player(_player)
	if hp_mult > 1.0 and "health" in enemy:
		enemy.health = ceili(enemy.health * hp_mult)
	if "attack_damage" in enemy:
		enemy.attack_damage = enemy.attack_damage * hp_mult
	var xp := xp_values[idx] if idx < xp_values.size() else 10
	_tracked_enemies[enemy.get_instance_id()] = xp
	if not enemy.tree_exited.is_connected(_on_enemy_killed):
		enemy.tree_exited.connect(_on_enemy_killed.bind(enemy.get_instance_id()))

func _trigger_muro() -> void:
	_muro_triggered = true
	print("⚠️ EL MURO")
	if _hud and _hud.has_method("show_event_banner"):
		_hud.show_event_banner("⚠️ EL MURO", Color(1, 0.2, 0.1))
	_spawn_single_enemy(6, Vector3(0, DatosJuego.get_height(0, 0) + 1.0, 0), 3.0)
	for i in 8:
		var angle := i * TAU / 8
		var mpos := Vector3(cos(angle) * 10.0, 0.0, sin(angle) * 10.0)
		mpos.y = DatosJuego.get_height(mpos.x, mpos.z) + 1.0
		_spawn_single_enemy(1, mpos)
	AudioManager.play_dragon_roar(Vector3(0, 1, 0))

func _trigger_fin() -> void:
	_fin_triggered = true
	print("🏁 EL FIN")
	_spawn_timer.stop()
	if _player == null or not _player.is_inside_tree():
		return
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	get_tree().paused = true
	var go = load("res://scenes/game_over.tscn")
	if go:
		var go_ui: CanvasLayer = go.instantiate()
		var elapsed_sec = int(_elapsed)
		var elapsed_str = str(elapsed_sec / 60) + ":" + str(elapsed_sec % 60).pad_zeros(2)
		var stats = _player
		go_ui.set_stats(stats.level, stats.fire_damage_bonus, stats.ice_damage_bonus, int(stats.max_health - 100), int(stats.max_mana - 100), int(stats.mana_regen_rate - 5), elapsed_str)
		_player.add_child(go_ui)

func _escalar_enemigo(enemy: CharacterBody3D, idx: int, level: int) -> void:
	if level <= 1:
		return
	var hp_mult := 1.0 + hp_scale_per_level * (level - 1)
	var dmg_mult := 1.0 + dmg_scale_per_level * (level - 1)
	var t = _elapsed
	if t >= 180.0 and (idx == 0 or idx == 2):
		hp_mult *= 2.0
		dmg_mult *= 1.5
	if "health" in enemy:
		enemy.health = ceili(enemy.health * hp_mult)
	if "attack_damage" in enemy:
		enemy.attack_damage = enemy.attack_damage * dmg_mult
	if "projectile_damage" in enemy:
		enemy.projectile_damage = enemy.projectile_damage * dmg_mult
	if "arrow_damage" in enemy:
		enemy.arrow_damage = enemy.arrow_damage * dmg_mult
	if "shoot_interval" in enemy and idx == 1:
		enemy.shoot_interval = maxf(1.0, enemy.shoot_interval - 0.15 * (level - 1))
	if "shoot_interval" in enemy and idx == 3:
		enemy.shoot_interval = maxf(1.2, enemy.shoot_interval - 0.1 * (level - 1))
	if "shoot_interval" in enemy and idx == 4:
		enemy.shoot_interval = maxf(1.5, enemy.shoot_interval - 0.08 * (level - 1))
	if t >= 300.0 and enemy.has_method("paralizar"):
		pass

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

func add_xp(amount: int) -> void:
	_total_xp += amount
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

func get_elapsed_str() -> String:
	var sec = int(_elapsed)
	return str(sec / 60) + ":" + str(sec % 60).pad_zeros(2)

func set_hud(hud: Node) -> void:
	_hud = hud

func _find_hud(player: Node) -> Node:
	for child in player.get_children():
		if child is CanvasLayer and child.has_method("set_xp"):
			return child
	return null
