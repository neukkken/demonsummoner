extends CharacterBody3D

@export var walk_speed: float = 5.0
@export var acceleration: float = 10.0
@export var air_control: float = 0.3
@export var gravity: float = 9.8

@export var mouse_sensitivity: float = 0.002
@export var invert_y: bool = false
@export var pitch_limit: float = 90.0

@export var projectile_scene: PackedScene
@export var auto_aim_max_range: float = 30.0
@export var auto_aim_max_angle: float = 20.0

var current_element: String = ""
var is_channeling: bool = false
var _channel_ui = null

var health: float = 100.0
var max_health: float = 100.0

@export var max_mana: float = 100.0
var current_mana: float = 100.0
@export var mana_regen_rate: float = 5.0

var fire_damage_bonus: int = 0
var ice_damage_bonus: int = 0
var level: int = 1

var mana_costs := {
	"FIRE_UP": 15,
	"FIRE_DOWN": 20,
	"FIRE_RIGHT": 18,
	"ICE_UP": 10,
	"ICE_DOWN": 25,
	"ICE_RIGHT": 22,
}

var mouse_relative: Vector2 = Vector2.ZERO
var channeling_mouse_buffer: Vector2 = Vector2.ZERO

var _mouse_captured: bool = false

var _hud = null
var _summon = null
var _summon_cooldown = 0.0
var _summon_cooldown_time = 60.0
var _soul_feeder = null
var _soul_feeder_cooldown = 0.0
var _soul_feeder_cooldown_time = 30.0
var _speed_buff_mult: float = 1.0
var _speed_buff_timer = 0.0
var _shake_intensity: float = 0.0
var _shake_offset: Vector3 = Vector3.ZERO
var _camera_origin: Vector3 = Vector3.ZERO

@onready var head: Node3D = $Head
@onready var camera: Camera3D = $Head/Camera3D
@onready var spell_origin: Marker3D = $Head/Camera3D/SpellOrigin
@onready var gesture_recognizer: Node = $GestureRecognizer

var _wand: Node3D
var _wand_base_rot: Vector3
var _wand_aim: Vector2

var _wand_scene: PackedScene = preload("res://scenes/wizard_wand.tscn")
var _wall_scene: PackedScene = preload("res://scenes/ice_wall.tscn")
var _ice_scene: PackedScene = preload("res://scenes/ice_projectile.tscn")
var _channel_scene: PackedScene = preload("res://scenes/channel_ui.tscn")


var _pentagram_recognizer

func _ready() -> void:
	_camera_origin = camera.position
	_capture_mouse()
	add_to_group("player")

	_pentagram_recognizer = Node.new()
	_pentagram_recognizer.set_script(preload("res://scripts/pentagram_recognizer.gd"))
	add_child(_pentagram_recognizer)

	$GestureRecognizer.gesture_detected.connect(cast_spell)
	$GestureRecognizer.gesture_detected.connect(_pentagram_recognizer.on_gesture)
	_pentagram_recognizer.pentagram_detected.connect(_on_pentagram)
	_pentagram_recognizer.pentagram_progress.connect(_on_pentagram_progress)

	if projectile_scene == null:
		projectile_scene = load("res://scenes/spell_projectile.tscn")
	print("projectile_scene asignado: ", projectile_scene != null)

	var hud_script := load("res://scripts/gothic_hud.gd")
	if hud_script:
		_hud = CanvasLayer.new()
		_hud.set_script(hud_script)
		add_child(_hud)
		var spawner = get_tree().get_first_node_in_group("wave_spawner")
		if spawner != null and spawner.has_method("set_hud"):
			spawner.set_hud(_hud)
	_update_hud_element()
	_update_hud_health()
	_update_hud_mana()
	_update_hud_level()
	_spawn_wand()
	var pause = load("res://scripts/pause_menu.gd")
	if pause:
		var pm = pause.new()
		add_child(pm)
		pm.name = "PauseMenu"


func _spawn_wand() -> void:
	if _wand_scene == null:
		return
	_wand = _wand_scene.instantiate()
	camera.add_child(_wand)
	_wand.position = Vector3(0.3, -0.3, -0.8)
	_wand.rotation_degrees = Vector3(10, 0, 0)
	_wand_base_rot = _wand.rotation_degrees


func cast_spell(gesture: String) -> void:
	if gesture == "UNKNOWN":
		return
	if current_element == "":
		print("Sin elemento seleccionado (Q/E)")
		return

	if gesture == "RIGHT" and current_element == "NECROMANCIA":
		_cast_blood_sacrifice()
		current_element = ""
		return

	var combo: String = current_element + "_" + gesture
	var cost: float = mana_costs.get(combo, 0.0)
	if current_mana < cost:
		print("Out of Mana (", cost, " necesarios, ", snapped(current_mana, 0.1), " disponibles)")
		return
	current_mana -= cost
	_update_hud_mana()

	match combo:
		"FIRE_UP":
			launch_fireball()
		"FIRE_DOWN":
			launch_fire_blast()
		"FIRE_RIGHT":
			launch_fire_blast()
		"ICE_UP":
			launch_ice_lance()
		"ICE_DOWN":
			launch_ice_wall()
		"ICE_RIGHT":
			launch_ice_wall()
		_:
			if _pentagram_recognizer.is_active():
				return
			print("Combo desconocido: ", combo)

	current_element = ""
	_update_hud_element()


func _cast_blood_sacrifice() -> void:
	if _summon != null and is_instance_valid(_summon):
		print("Ya tienes un invocación activa")
		return
	if _summon_cooldown > 0.0:
		print("Cooldown: ", snapped(_summon_cooldown, 0.1), "s restantes")
		return
	var cost := max_health * 0.3
	health = maxf(health - cost, 1.0)
	print("Sacrificio de sangre: -", cost, " HP. HP restante: ", health)
	_update_hud_health()
	add_shake(0.4)
	_push_enemies_around(5.0, 3.0)
	_spawn_summon()

func _spawn_summon() -> void:
	_summon_cooldown = _summon_cooldown_time
	_summon = Node3D.new()
	_summon.set_script(preload("res://scripts/summon_minion.gd"))
	var forward := -camera.global_transform.basis.z
	var flat_forward := Vector3(forward.x, 0, forward.z).normalized()
	_summon.position = global_position + flat_forward * 2.0
	_summon.add_to_group("summons")
	_summon.tree_exited.connect(_on_summon_freed)
	_summon.call("init_player", self)
	get_tree().root.add_child(_summon)

func _on_summon_freed() -> void:
	_summon = null

func _try_summon_soul_feeder() -> void:
	if _soul_feeder != null and is_instance_valid(_soul_feeder):
		print("El Devorador de Almas ya está activo")
		return
	if _soul_feeder_cooldown > 0.0:
		print("Devorador de Almas en cooldown: ", snapped(_soul_feeder_cooldown, 0.1), "s")
		return
	if not DatosJuego.almas_suficientes():
		print("Se requieren ", DatosJuego.REQUISITO_DEVORADOR, " almas para invocar al Devorador")
		return
	DatosJuego.consumir_almas()
	_pentagram_recognizer.set_tracking(false)
	_spawn_soul_feeder()

func _spawn_soul_feeder() -> void:
	_soul_feeder_cooldown = _soul_feeder_cooldown_time
	var feeder = Node3D.new()
	feeder.set_script(preload("res://scripts/soul_feeder.gd"))
	feeder.position = Vector3(0, 0.5, 0)
	feeder.add_to_group("summons")
	feeder.tree_exited.connect(_on_soul_feeder_freed)
	feeder.call("init_player", self)
	get_tree().root.add_child(feeder)
	_soul_feeder = feeder
	_speed_buff_mult = 1.5
	_speed_buff_timer = 8.0
	print("¡EL DEVORADOR DE ALMAS HA DESPERTADO!")

func _on_soul_feeder_freed() -> void:
	_soul_feeder = null
	_speed_buff_mult = 1.0
	_speed_buff_timer = 0.0

func _update_pentagram_tracking() -> void:
	if current_element != "NECROMANCIA":
		_pentagram_recognizer.set_tracking(false)
		return
	_pentagram_recognizer.set_tracking(DatosJuego.almas_suficientes())

func _on_pentagram() -> void:
	_try_summon_soul_feeder()

func _on_pentagram_progress(progress: int, total: int) -> void:
	if _hud != null and _hud.has_method("set_pentagram_progress"):
		_hud.set_pentagram_progress(progress, total)

func launch_fireball() -> void:
	print("¡Lanzando Bola de Fuego!")
	add_shake(0.3)
	_spawn_projectile("fire", 25.0)


func launch_fire_blast() -> void:
	print("¡Lanzando Explosión de Fuego!")
	add_shake(0.8)
	_push_enemies_around(5.0, 10.0)
	var blast_scene: PackedScene = preload("res://scenes/fire_blast_effect.tscn")
	var blast = blast_scene.instantiate()
	get_tree().root.add_child(blast)
	blast.global_position = global_position + Vector3(0, 1, 0)


func launch_ice_lance() -> void:
	print("¡Lanzando Lanza de Hielo!")
	_spawn_projectile("ice", 0.0, _ice_scene)


func launch_ice_wall() -> void:
	print("¡Lanzando Muro de Hielo!")
	if _wall_scene == null:
		return
	var wall: StaticBody3D = _wall_scene.instantiate() as StaticBody3D
	if wall == null:
		return
	var forward = -camera.global_transform.basis.z
	var flat_forward = Vector3(forward.x, 0, forward.z).normalized()
	var flat_cam = Vector3(camera.global_position.x, 0, camera.global_position.z)
	get_tree().root.add_child(wall)
	wall.global_position = flat_cam + flat_forward * 3.0
	wall.look_at(flat_cam, Vector3.UP)
	wall.snap_to_ground()


func _spawn_projectile(effect: String = "fire", dmg: float = 25.0, scene_override: PackedScene = null) -> void:
	var scene: PackedScene = scene_override if scene_override != null else projectile_scene
	if scene == null:
		return
	var projectile: Area3D = scene.instantiate() as Area3D
	if projectile == null:
		return
	projectile.effect_type = effect
	if effect == "fire":
		dmg += fire_damage_bonus
	elif effect == "ice":
		dmg += ice_damage_bonus
	projectile.damage = dmg
	get_tree().root.add_child(projectile)
	projectile.global_position = spell_origin.global_position
	projectile.global_transform.basis = camera.global_transform.basis

	var target: Node3D = _find_target_enemy()
	if target != null:
		projectile.look_at(target.global_position, Vector3.UP)
		print("Auto-apuntado a: ", target.name)


func _find_target_enemy() -> Node3D:
	var enemies: Array[Node] = get_tree().get_nodes_in_group("enemies")
	if enemies.is_empty():
		return null
	var cam_pos: Vector3 = camera.global_position
	var cam_forward: Vector3 = -camera.global_transform.basis.z
	var best: Node3D = null
	var best_score: float = INF

	for e in enemies:
		var enemy: Node3D = e as Node3D
		if enemy == null:
			continue
		var offset: Vector3 = enemy.global_position - cam_pos
		var dist: float = offset.length()
		if dist < 1.0 or dist > auto_aim_max_range:
			continue
		var dir: Vector3 = offset / dist
		var dot: float = cam_forward.dot(dir)
		if dot <= 0.0:
			continue
		var angle_deg: float = rad_to_deg(acos(clampf(dot, -1.0, 1.0)))
		if angle_deg > auto_aim_max_angle:
			continue
		var score: float = angle_deg * (1.0 + dist / auto_aim_max_range)
		if score < best_score:
			best_score = score
			best = enemy

	return best


func _push_enemies_around(radius: float, force: float) -> void:
	var enemies: Array[Node] = get_tree().get_nodes_in_group("enemies")
	for enemy_node in enemies:
		var enemy_3d: Node3D = enemy_node as Node3D
		if enemy_3d == null:
			continue
		var dist := global_position.distance_to(enemy_3d.global_position)
		if dist > radius:
			continue
		var push_dir: Vector3 = enemy_3d.global_position - global_position
		push_dir.y = 0.0
		push_dir = push_dir.normalized()
		enemy_3d.global_position += push_dir * force


func take_damage(amount: float) -> void:
	health = maxf(health - amount, 0.0)
	print("Jugador recibió ", amount, " de daño. HP: ", health)
	_update_hud_health()
	add_shake(0.5)
	if health <= 0.0:
		print("Jugador derrotado")
		for e in get_tree().get_nodes_in_group("enemies"):
			if is_instance_valid(e):
				e.queue_free()
		if _summon != null and is_instance_valid(_summon):
			_summon.queue_free()
			_summon = null
		if _soul_feeder != null and is_instance_valid(_soul_feeder):
			_soul_feeder.queue_free()
			_soul_feeder = null
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		get_tree().paused = true
		var go := load("res://scenes/game_over.tscn")
		if go:
			var go_ui: CanvasLayer = go.instantiate()
			add_child(go_ui)
			go_ui.set_stats(level, fire_damage_bonus, ice_damage_bonus, int(max_health - 100), int(max_mana - 100), int(mana_regen_rate - 5))


func _update_hud_element() -> void:
	if _hud != null:
		var display: String = current_element if current_element != "" else "None"
		_hud.call("set_element", display)


func _update_hud_health() -> void:
	if _hud != null:
		_hud.call("set_health", health, max_health)


func _update_hud_mana() -> void:
	if _hud != null:
		_hud.call("set_mana", current_mana, max_mana)

func _update_hud_level() -> void:
	if _hud != null:
		_hud.call("set_level", level)


func restore_mana(amount: float) -> void:
	current_mana = minf(current_mana + amount, max_mana)
	_update_hud_mana()

func apply_upgrade(stat: String) -> void:
	match stat:
		"FIRE":
			fire_damage_bonus += 5
		"ICE":
			ice_damage_bonus += 5
		"HP":
			max_health += 20
			health = minf(health + 20, max_health)
		"MANA":
			max_mana += 20
			current_mana = minf(current_mana + 20, max_mana)
		"REGEN":
			mana_regen_rate += 1
	level += 1
	_update_hud_level()
	_update_hud_health()
	_update_hud_mana()
	print("Nivel ", level, " - ", stat, " mejorado. Total: fire_bonus=", fire_damage_bonus, " ice_bonus=", ice_damage_bonus, " hp=", max_health, " mana=", max_mana, " regen=", mana_regen_rate)


func _capture_mouse() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	_mouse_captured = true


func _toggle_mouse() -> void:
	if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		_mouse_captured = false
	else:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
		_mouse_captured = true


func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		if not _mouse_captured:
			_capture_mouse()

	if event.is_action_pressed("ui_cancel"):
		var pm = find_child("PauseMenu", true, false)
		if pm and pm.has_method("_pause"):
			if _mouse_captured:
				pm._pause()
			elif pm.visible:
				pm._resume()
		else:
			if _mouse_captured:
				_toggle_mouse()
			else:
				get_tree().change_scene_to_file("res://scenes/main_menu.tscn")

	if event.is_action_pressed("element_fire"):
		current_element = "FIRE"
		print("Elemento: FIRE")
		_update_hud_element()
		if _wand:
			_wand.set_element("FIRE")
		if _channel_ui:
			_channel_ui.set_element("FIRE")
		_pentagram_recognizer.set_tracking(false)
	if event.is_action_pressed("element_ice"):
		current_element = "ICE"
		print("Elemento: ICE")
		_update_hud_element()
		if _wand:
			_wand.set_element("ICE")
		if _channel_ui:
			_channel_ui.set_element("ICE")
		_pentagram_recognizer.set_tracking(false)
	if event.is_action_pressed("element_necromancia"):
		current_element = "NECROMANCIA"
		print("Elemento: NECROMANCIA")
		_update_hud_element()
		if _wand:
			_wand.set_element("NECROMANCIA")
		if _channel_ui:
			_channel_ui.set_element("NECROMANCIA")
		_update_pentagram_tracking()
	var shift_held := Input.is_action_pressed("channel_spell") and _mouse_captured

	if event is InputEventMouseMotion and _mouse_captured:
		if shift_held:
			channeling_mouse_buffer += event.relative
			_wand_aim.x += event.relative.x * 0.02
			_wand_aim.y += event.relative.y * 0.02
			_wand_aim.x = clampf(_wand_aim.x, -45.0, 45.0)
			_wand_aim.y = clampf(_wand_aim.y, -30.0, 30.0)
		else:
			mouse_relative = event.relative
			head.rotate_y(-event.relative.x * mouse_sensitivity)

			var pitch_delta: float = -event.relative.y * mouse_sensitivity
			if invert_y:
				pitch_delta = -pitch_delta
			camera.rotation.x = clamp(camera.rotation.x + pitch_delta, deg_to_rad(-pitch_limit), deg_to_rad(pitch_limit))


func _physics_process(delta: float) -> void:
	var move_input := Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	var direction := Vector3.ZERO
	if move_input.length() > 0:
		direction = (head.transform.basis * Vector3(move_input.x, 0, move_input.y)).normalized()

	var target_velocity := direction * walk_speed * _speed_buff_mult
	target_velocity.y = velocity.y

	var control: float = acceleration if is_on_floor() else acceleration * air_control
	velocity.x = lerp(velocity.x, target_velocity.x, control * delta)
	velocity.z = lerp(velocity.z, target_velocity.z, control * delta)

	if not is_on_floor():
		velocity.y -= gravity * delta

	move_and_slide()


func add_shake(intensity: float) -> void:
	_shake_intensity = maxf(_shake_intensity, intensity)


func _process(delta: float) -> void:
	if _shake_intensity > 0.0:
		_shake_offset = Vector3(
			randf_range(-_shake_intensity, _shake_intensity),
			randf_range(-_shake_intensity, _shake_intensity),
			0.0
		)
		camera.position = _camera_origin + _shake_offset
		_shake_intensity = lerpf(_shake_intensity, 0.0, delta * 10.0)
		if _shake_intensity < 0.05:
			_shake_intensity = 0.0
			camera.position = _camera_origin

	var was_channeling: bool = is_channeling
	is_channeling = Input.is_action_pressed("channel_spell") and _mouse_captured

	if is_channeling and not was_channeling:
		_show_channel_ui()
	elif not is_channeling and was_channeling:
		_hide_channel_ui()

	if is_channeling and _channel_ui != null and _channel_ui.visible:
		var progress: float = gesture_recognizer.get_progress()
		var direction: String = gesture_recognizer.get_current_direction()
		_channel_ui.call("update_display", progress, direction)

	if current_mana < max_mana:
		current_mana = minf(current_mana + mana_regen_rate * delta, max_mana)
		_update_hud_mana()

	if not is_channeling:
		channeling_mouse_buffer = Vector2.ZERO

	if _summon_cooldown > 0.0:
		_summon_cooldown = maxf(_summon_cooldown - delta, 0.0)

	if _soul_feeder_cooldown > 0.0:
		_soul_feeder_cooldown = maxf(_soul_feeder_cooldown - delta, 0.0)

	if _hud != null and _hud.has_method("set_demon_cooldown"):
		_hud.set_demon_cooldown(0, _summon_cooldown)
		_hud.set_demon_cooldown(1, _soul_feeder_cooldown)

	if _speed_buff_timer > 0.0:
		_speed_buff_timer -= delta
		if _speed_buff_timer <= 0.0 and _soul_feeder == null:
			_speed_buff_mult = 1.0

	if current_element == "NECROMANCIA" and not _pentagram_recognizer.is_tracking():
		_update_pentagram_tracking()

	if _wand:
		if is_channeling:
			_wand.rotation_degrees = _wand_base_rot + Vector3(-_wand_aim.y, _wand_aim.x, 0)
		else:
			_wand_aim = _wand_aim.lerp(Vector2.ZERO, delta * 8.0)
			_wand.rotation_degrees = _wand_base_rot + Vector3(-_wand_aim.y, _wand_aim.x, 0)

func _show_channel_ui() -> void:
	if _channel_ui == null:
		if _channel_scene == null:
			return
		_channel_ui = _channel_scene.instantiate()
		add_child(_channel_ui)
	_channel_ui.set_element(current_element)
	_channel_ui.show()


func _hide_channel_ui() -> void:
	if _channel_ui != null:
		_channel_ui.hide()
