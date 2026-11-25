extends CharacterBody3D

@export var walk_speed: float = 5.0
@export var acceleration: float = 10.0
@export var air_control: float = 0.3
@export var gravity: float = 9.8

@export var mouse_sensitivity: float = 0.002
@export var invert_y: bool = false
@export var pitch_limit: float = 90.0

@export var projectile_scene: PackedScene
@export var auto_aim_max_range: float = 50.0
@export var auto_aim_max_angle: float = 35.0

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
var speed_bonus: int = 0
var range_bonus: int = 0
var armor: int = 0
var lifesteal: int = 0
var level: int = 1
var mana_cost_mult: float = 1.0
var xp_mult: float = 1.0

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
var _summon_cooldown_time = 30.0
var _soul_feeder = null
var _soul_feeder_cooldown = 0.0
var _soul_feeder_cooldown_time = 30.0
var _potion_cooldown: float = 0.0
const POTION_COOLDOWN_TIME: float = 30.0
const POTION_HEAL: float = 50.0
var _speed_buff_mult: float = 1.0
var _speed_buff_timer = 0.0
var _slow_mult: float = 1.0
var _slow_timer: float = 0.0
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

var _debug_frame: int = 0

func _ready() -> void:
	_camera_origin = camera.position
	_capture_mouse()
	add_to_group("player")
	print("[DEBUG] Player _ready - global_position: ", global_position)
	var space = get_world_3d().direct_space_state
	if space:
		var query = PhysicsShapeQueryParameters3D.new()
		var capsule = CapsuleShape3D.new()
		capsule.radius = 0.5
		capsule.height = 1.0
		query.shape = capsule
		query.transform = global_transform
		query.collision_mask = 1
		var hits = space.intersect_shape(query)
		if hits.size() > 0:
			print("[DEBUG] Player overlapping with ", hits.size(), " bodies at spawn:")
			for h in hits:
				print("  - ", h.collider.name, " type: ", h.collider.get_class(), " pos: ", h.collider.global_position if h.collider is Node3D else "N/A")

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
		_hud.add_to_group("hud")
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

	var combo: String = current_element + "_" + gesture
	var cost: float = mana_costs.get(combo, 0.0) * mana_cost_mult
	if current_mana < cost:
		print("Out of Mana (", cost, " necesarios, ", snapped(current_mana, 0.1), " disponibles)")
		return
	current_mana -= cost
	_update_hud_mana()
	print("[CAST] combo=", combo, " cost=", cost, " mana=", snapped(current_mana, 0.1))

	match combo:
		"FIRE_UP":
			launch_fireball()
		"FIRE_DOWN":
			launch_fire_blast()
		"FIRE_RIGHT":
			launch_quick_fireball()
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
	var cost := max_health * 0.2
	health = maxf(health - cost, 1.0)
	print("Sacrificio de sangre: -", cost, " HP. HP restante: ", health)
	_update_hud_health()
	add_shake(0.4)
	_push_enemies_around(5.0, 3.0)
	_spawn_summon()

func _cycle_summon() -> void:
	print("R: Invocación")
	if _summon == null or not is_instance_valid(_summon):
		_cast_blood_sacrifice()
		return
	print("Segador ya activo")

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
	feeder.global_position = Vector3(global_position.x, DatosJuego.get_height(global_position.x, global_position.z) + 0.5, global_position.z)
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
	AudioManager.play_fireball(spell_origin.global_position)
	add_shake(0.3)
	_spawn_projectile("fire", 125.0)

func launch_quick_fireball() -> void:
	print("¡Bola rápida!")
	AudioManager.play_fireball(spell_origin.global_position)
	_spawn_projectile("fire", 75.0)


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
	AudioManager.play_ice_lance(spell_origin.global_position)
	_spawn_projectile("ice", 0.0, _ice_scene)


func launch_ice_wall() -> void:
	print("¡Lanzando Muro de Hielo!")
	AudioManager.play_ice_wall(spell_origin.global_position)
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

func launch_triple_shot() -> void:
	print("¡Ráfaga triple!")
	var spread = deg_to_rad(8)
	var dmg = 125.0 * 0.7 + fire_damage_bonus
	for i in range(3):
		_spawn_projectile("fire", dmg, null, spread * (i - 1))
	AudioManager.play_fireball(spell_origin.global_position)

func launch_ice_explosion() -> void:
	print("¡Explosión de Escarcha!")
	var blast = preload("res://scenes/fire_blast_effect.tscn").instantiate()
	blast.scale = Vector3(4.0, 4.0, 4.0)
	var blast_light = blast.find_child("OmniLight3D", true, false) as OmniLight3D
	if blast_light:
		blast_light.light_color = Color(0.3, 0.7, 1.0)
	blast.global_position = spell_origin.global_position + Vector3(0, 1, 0)
	get_tree().root.add_child(blast)
	var forward = -camera.global_transform.basis.z
	var hit_pos = spell_origin.global_position + forward * 8
	hit_pos.y = 1.0
	blast.global_position = hit_pos
	for enemy in get_tree().get_nodes_in_group("enemies"):
		var e3d = enemy as Node3D
		if e3d and hit_pos.distance_to(e3d.global_position) < 5.0:
			if e3d.has_method("take_damage"):
				e3d.take_damage(100 + ice_damage_bonus)
			if e3d.has_method("apply_freeze"):
				e3d.apply_freeze(3.0, 0.5)

func launch_blood_barrier() -> void:
	print("¡Barrera de Sangre!")
	AudioManager.play_summon_spawn(global_position)
	var shield = MeshInstance3D.new()
	var sphere = SphereMesh.new()
	sphere.radius = 0.1
	sphere.height = 0.2
	var smat = StandardMaterial3D.new()
	smat.albedo_color = Color(0.5, 0.02, 0.05, 0.4)
	smat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	smat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	smat.emission_enabled = true
	smat.emission = Color(0.8, 0.03, 0.05)
	smat.emission_energy_multiplier = 3.0
	shield.mesh = sphere
	shield.material_override = smat
	shield.position = Vector3(0, 1, 0)
	add_child(shield)
	var tween = shield.create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	tween.tween_property(shield, "scale", Vector3(4.0, 4.0, 4.0), 0.3)

	for i in 8:
		var dot = MeshInstance3D.new()
		var box = BoxMesh.new()
		box.size = Vector3(0.06, 0.06, 0.06)
		var dmat = StandardMaterial3D.new()
		dmat.albedo_color = Color(0.8, 0.0, 0.05)
		dmat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		dmat.emission_enabled = true
		dmat.emission = Color(1.0, 0.0, 0.05)
		dmat.emission_energy_multiplier = 6.0
		dot.mesh = box
		dot.material_override = dmat
		var angle = i * TAU / 8
		var radius = 0.8
		dot.position = Vector3(cos(angle) * radius, 0.5 + sin(angle * 2) * 0.3, sin(angle) * radius)
		shield.add_child(dot)
		var dtween = dot.create_tween().set_loops()
		dtween.tween_property(dot, "position", Vector3(cos(angle + TAU) * radius, 0.5 + sin(angle * 2 + TAU) * 0.3, sin(angle + TAU) * radius), 2.0)

	var timer = Timer.new()
	timer.one_shot = true
	timer.wait_time = 3.0
	timer.timeout.connect(func():
		_push_enemies_around(5.0, 12.0)
		AudioManager.play_impact(global_position)
		shield.queue_free()
		timer.queue_free()
	)
	add_child(timer)
	timer.start()

func launch_rain_of_fire() -> void:
	print("¡Lluvia de Fuego!")
	AudioManager.play_fireball(spell_origin.global_position)
	add_shake(0.5)
	var target = _find_target_enemy()
	var center = target.global_position if target != null else spell_origin.global_position + -camera.global_transform.basis.z * 10
	center.y = 0
	for i in 5:
		var proj = projectile_scene.instantiate() as Area3D
		if proj == null:
			continue
		proj.effect_type = "fire"
		proj.damage = 75.0 + fire_damage_bonus
		get_tree().root.add_child(proj)
		var offset := Vector3(randf_range(-3.0, 3.0), 15.0, randf_range(-3.0, 3.0))
		proj.global_position = center + offset
		proj.look_at(center, Vector3.UP)
		proj.damage_origin = self

func launch_flame_shield() -> void:
	print("¡Escudo de Llamas!")
	add_shake(0.3)
	var ring = MeshInstance3D.new()
	var torus = TorusMesh.new()
	torus.inner_radius = 0.2
	torus.outer_radius = 0.3
	torus.rings = 10
	torus.ring_segments = 14
	var mat = StandardMaterial3D.new()
	mat.albedo_color = Color(1, 0.6, 0.0, 0.4)
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.emission_enabled = true
	mat.emission = Color(1, 0.5, 0.0)
	mat.emission_energy_multiplier = 6.0
	ring.mesh = torus
	ring.material_override = mat
	ring.position = Vector3(0, 1, 0)
	add_child(ring)
	var tween = ring.create_tween()
	tween.tween_property(ring, "scale", Vector3(10.0, 10.0, 10.0), 0.3)
	var pulse = ring.create_tween().set_loops()
	pulse.tween_property(mat, "emission_energy_multiplier", 10.0, 0.3)
	pulse.tween_property(mat, "emission_energy_multiplier", 6.0, 0.3)
	var timer = Timer.new()
	timer.one_shot = true
	timer.wait_time = 3.0
	timer.timeout.connect(func():
		for enemy in get_tree().get_nodes_in_group("enemies"):
			var e3d = enemy as Node3D
			if e3d and global_position.distance_to(e3d.global_position) < 5.0:
				if e3d.has_method("take_damage"):
					e3d.take_damage(50 + fire_damage_bonus)
				if e3d.has_method("paralizar"):
					e3d.paralizar(0.5)
		ring.queue_free()
	)
	add_child(timer)
	timer.start()

func launch_ice_stakes() -> void:
	print("¡Estacas de Hielo!")
	AudioManager.play_ice_lance(spell_origin.global_position)
	for i in 3:
		var spread = deg_to_rad(15) * (i - 1)
		_spawn_projectile("ice", 60.0 + ice_damage_bonus, null, spread)

func launch_ice_storm() -> void:
	print("¡Tormenta de Hielo!")
	AudioManager.play_ice_wall(spell_origin.global_position)
	var forward = -camera.global_transform.basis.z
	var hit_pos = spell_origin.global_position + forward * 8
	hit_pos.y = 1.0
	var root = Node3D.new()
	root.global_position = hit_pos
	get_tree().root.add_child(root)
	for i in 5:
		var ring = MeshInstance3D.new()
		var torus = TorusMesh.new()
		torus.inner_radius = 0.3 + i * 0.6
		torus.outer_radius = 0.5 + i * 0.6
		torus.rings = 10
		torus.ring_segments = 16
		var rmat = StandardMaterial3D.new()
		rmat.albedo_color = Color(0.3, 0.8, 1.0, 0.6)
		rmat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		rmat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		rmat.emission_enabled = true
		rmat.emission = Color(0.2, 0.7, 1.0)
		rmat.emission_energy_multiplier = 8.0
		ring.mesh = torus
		ring.material_override = rmat
		ring.rotation.x = deg_to_rad(90)
		ring.rotation.z = i * deg_to_rad(36)
		root.add_child(ring)
		var rtween = ring.create_tween()
		rtween.set_parallel(true)
		rtween.tween_property(ring, "scale", Vector3(10.0, 10.0, 10.0), 1.2)
		rtween.tween_property(ring, "rotation", Vector3(deg_to_rad(90), TAU, 0), 1.2).as_relative()
		rtween.tween_property(rmat, "albedo_color", Color(1, 1, 1, 0), 1.2)
		rtween.tween_property(rmat, "emission", Color(0, 0, 0, 0), 1.2)
	var flash = MeshInstance3D.new()
	var fbox = BoxMesh.new()
	fbox.size = Vector3(0.1, 0.1, 0.1)
	var fmat = StandardMaterial3D.new()
	fmat.albedo_color = Color(1, 1, 1)
	fmat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	fmat.emission_enabled = true
	fmat.emission = Color(1, 1, 1)
	fmat.emission_energy_multiplier = 20.0
	flash.mesh = fbox
	flash.material_override = fmat
	flash.scale = Vector3(0.1, 0.1, 0.1)
	root.add_child(flash)
	var ftween = flash.create_tween()
	ftween.tween_property(flash, "scale", Vector3(15.0, 15.0, 15.0), 0.2)
	ftween.parallel().tween_property(fmat, "albedo_color", Color(1, 1, 1, 0), 0.2)
	for i in 40:
		var dot = MeshInstance3D.new()
		var box = BoxMesh.new()
		var s = randf_range(0.04, 0.1)
		box.size = Vector3(s, s, s)
		var dmat = StandardMaterial3D.new()
		dmat.albedo_color = Color(0.9, 0.95, 1.0)
		dmat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		dmat.emission_enabled = true
		dmat.emission = Color(0.8, 0.9, 1.0)
		dmat.emission_energy_multiplier = 6.0
		dot.mesh = box
		dot.material_override = dmat
		dot.position = Vector3(randf_range(-5.0, 5.0), randf_range(-1.0, 5.0), randf_range(-5.0, 5.0))
		root.add_child(dot)
		var dtween = dot.create_tween()
		dtween.tween_property(dot, "position", dot.position + Vector3(randf_range(-2, 2), -4.0, randf_range(-2, 2)), 1.0)
		dtween.parallel().tween_property(dmat, "albedo_color", Color(1, 1, 1, 0), 1.0)
	var light = OmniLight3D.new()
	light.light_color = Color(0.3, 0.7, 1.0)
	light.light_energy = 15.0
	light.omni_range = 15.0
	light.position.y = 2.0
	root.add_child(light)
	var ltween = root.create_tween()
	ltween.tween_property(light, "light_energy", 0.0, 1.5)
	ltween.tween_property(light, "light_energy", 5.0, 0.3)
	ltween.tween_property(light, "light_energy", 0.0, 0.7)
	get_tree().create_timer(1.5).timeout.connect(root.queue_free)
	for enemy in get_tree().get_nodes_in_group("enemies"):
		var e3d = enemy as Node3D
		if e3d and hit_pos.distance_to(e3d.global_position) < 8.0:
			if e3d.has_method("apply_freeze"):
				e3d.apply_freeze(4.0, 0.3)
			if e3d.has_method("paralizar"):
				e3d.paralizar(2.0)

func _spawn_drain_beam(from: Vector3, to: Vector3) -> void:
	var mid = (from + to) * 0.5
	var dist = from.distance_to(to)
	var beam = MeshInstance3D.new()
	var cyl = CylinderMesh.new()
	cyl.top_radius = 0.04
	cyl.bottom_radius = 0.1
	cyl.height = dist
	var bmat = StandardMaterial3D.new()
	bmat.albedo_color = Color(0.9, 0.0, 0.03, 0.6)
	bmat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	bmat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	bmat.emission_enabled = true
	bmat.emission = Color(1.0, 0.0, 0.03)
	bmat.emission_energy_multiplier = 10.0
	beam.mesh = cyl
	beam.material_override = bmat
	beam.global_position = mid
	beam.look_at(to, Vector3.UP)
	beam.rotate_object_local(Vector3.RIGHT, deg_to_rad(90))
	get_tree().root.add_child(beam)
	var btween = beam.create_tween()
	btween.tween_property(bmat, "albedo_color", Color(1, 0, 0, 0), 0.8)
	btween.parallel().tween_property(bmat, "emission", Color(0, 0, 0, 0), 0.8)
	btween.tween_callback(beam.queue_free)

	for i in 15:
		var timer = Timer.new()
		timer.one_shot = true
		timer.wait_time = i * 0.05
		var dot = MeshInstance3D.new()
		var box = BoxMesh.new()
		var s = randf_range(0.04, 0.08)
		box.size = Vector3(s, s, s)
		var dmat = StandardMaterial3D.new()
		dmat.albedo_color = Color(0.9, 0.0, 0.03)
		dmat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		dmat.emission_enabled = true
		dmat.emission = Color(1.0, 0.0, 0.03)
		dmat.emission_energy_multiplier = 10.0
		dot.mesh = box
		dot.material_override = dmat
		dot.global_position = from + Vector3(randf_range(-0.15, 0.15), randf_range(-0.15, 0.15), randf_range(-0.15, 0.15))
		get_tree().root.add_child(dot)
		timer.timeout.connect(func():
			if is_instance_valid(dot):
				var dtween = dot.create_tween()
				dtween.tween_property(dot, "global_position", to + Vector3(randf_range(-0.15, 0.15), randf_range(-0.15, 0.15), randf_range(-0.15, 0.15)), 0.5)
				dtween.parallel().tween_property(dmat, "albedo_color", Color(1, 0, 0, 0), 0.6)
				dtween.tween_callback(dot.queue_free)
			timer.queue_free()
		)
		add_child(timer)
		timer.start()

	var light = OmniLight3D.new()
	light.light_color = Color(1.0, 0.0, 0.03)
	light.light_energy = 5.0
	light.omni_range = 4.0
	light.global_position = from
	get_tree().root.add_child(light)
	var ltween = light.create_tween()
	ltween.tween_property(light, "light_energy", 0.0, 0.8)
	ltween.tween_callback(light.queue_free)

func launch_drain() -> void:
	print("¡Drenaje!")
	add_shake(0.5)
	var target = _find_target_enemy()
	AudioManager.play_mage_shoot(spell_origin.global_position)
	var drain_dmg = 75.0 + fire_damage_bonus + ice_damage_bonus
	if target != null:
		var from = target.global_position + Vector3(0, 1, 0)
		var to = global_position + Vector3(0, 1, 0)
		_spawn_drain_beam(from, to)
		target.take_damage(drain_dmg)
		AudioManager.play_impact(to)
		var heal = drain_dmg * 0.3
		health = minf(health + heal, max_health)
		_update_hud_health()
	else:
		var fwd = -camera.global_transform.basis.z
		var from = spell_origin.global_position + fwd * 5
		var to = spell_origin.global_position
		_spawn_drain_beam(from, to)

func _make_soul_orb(pos: Vector3) -> Node3D:
	var root = Node3D.new()
	root.global_position = pos
	var blocker = StaticBody3D.new()
	var bcol = CollisionShape3D.new()
	var bshape = SphereShape3D.new()
	bshape.radius = 1.2
	bcol.shape = bshape
	blocker.add_child(bcol)
	root.add_child(blocker)
	var detector = Area3D.new()
	var dcol = CollisionShape3D.new()
	var dshape = SphereShape3D.new()
	dshape.radius = 1.2
	dcol.shape = dshape
	detector.add_child(dcol)
	detector.collision_mask = 1
	detector.body_entered.connect(_on_soul_wall_hit)
	root.add_child(detector)
	var mesh = MeshInstance3D.new()
	var sphere = SphereMesh.new()
	sphere.radius = 1.0
	sphere.height = 2.0
	var mat = StandardMaterial3D.new()
	mat.albedo_color = Color(0.5, 0.0, 0.8)
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.emission_enabled = true
	mat.emission = Color(0.6, 0.0, 1.0)
	mat.emission_energy_multiplier = 12.0
	mesh.mesh = sphere
	mesh.material_override = mat
	root.add_child(mesh)
	get_tree().root.add_child(root)
	var ftween = root.create_tween().set_loops()
	ftween.tween_property(root, "scale", Vector3(1.5, 1.5, 1.5), 0.5)
	ftween.tween_property(root, "scale", Vector3(1.0, 1.0, 1.0), 0.5)
	return root

func _spawn_soul_spark(pos: Vector3) -> void:
	for i in 6:
		var dot = MeshInstance3D.new()
		var box = BoxMesh.new()
		box.size = Vector3(0.03, 0.03, 0.03)
		var dmat = StandardMaterial3D.new()
		dmat.albedo_color = Color(0.6, 0.0, 1.0)
		dmat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		dmat.emission_enabled = true
		dmat.emission = Color(0.7, 0.0, 1.0)
		dmat.emission_energy_multiplier = 10.0
		dot.mesh = box
		dot.material_override = dmat
		dot.global_position = pos
		get_tree().root.add_child(dot)
		var dtween = dot.create_tween()
		dtween.tween_property(dot, "global_position", pos + Vector3(randf_range(-0.5, 0.5), randf_range(-0.3, 0.5), randf_range(-0.5, 0.5)), 0.2)
		dtween.parallel().tween_property(dmat, "albedo_color", Color(1, 1, 1, 0), 0.2)
		dtween.tween_callback(dot.queue_free)

func _on_soul_wall_hit(body: Node) -> void:
	if body.is_in_group("enemies") and body.has_method("take_damage"):
		body.take_damage(60 + fire_damage_bonus + ice_damage_bonus)
		_spawn_soul_spark(body.global_position)
		AudioManager.play_impact(body.global_position)

func launch_soul_wall() -> void:
	print("¡Muro de Almas!")
	add_shake(0.3)
	AudioManager.play_summon_spawn(global_position)
	var forward = -camera.global_transform.basis.z
	var flat_forward = Vector3(forward.x, 0, forward.z).normalized()
	var base_pos = global_position + flat_forward * 3.0
	var orbs: Array[Node3D] = []
	for i in 5:
		var offset = Vector3((i - 2) * 1.2, 0.5, 0)
		var orb = _make_soul_orb(base_pos + offset)
		orbs.append(orb)
	await get_tree().create_timer(8.0).timeout
	for o in orbs:
		if is_instance_valid(o):
			var tween_out = o.create_tween()
			tween_out.tween_property(o, "scale", Vector3.ZERO, 0.3)
			tween_out.tween_callback(o.queue_free)

func launch_necro_explosion() -> void:
	print("¡Explosión Necrótica!")
	add_shake(0.8)
	AudioManager.play_dragon_roar(global_position)
	var root = Node3D.new()
	root.global_position = global_position + Vector3(0, 1, 0)
	get_tree().root.add_child(root)
	for i in 4:
		var ring = MeshInstance3D.new()
		var torus = TorusMesh.new()
		torus.inner_radius = 0.2 + i * 0.15
		torus.outer_radius = 0.35 + i * 0.15
		torus.rings = 10
		torus.ring_segments = 14
		var rmat = StandardMaterial3D.new()
		rmat.albedo_color = Color(0.5, 0.0, 0.7, 0.6)
		rmat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		rmat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		rmat.emission_enabled = true
		rmat.emission = Color(0.6, 0.0, 0.9)
		rmat.emission_energy_multiplier = 8.0
		ring.mesh = torus
		ring.material_override = rmat
		ring.rotation.x = deg_to_rad(90)
		ring.rotation.z = i * deg_to_rad(45)
		root.add_child(ring)
		var rtween = ring.create_tween()
		rtween.tween_property(ring, "scale", Vector3(7.0, 7.0, 7.0), 0.6)
		rtween.parallel().tween_property(rmat, "albedo_color", Color(0, 0, 0, 0), 0.6)
		rtween.parallel().tween_property(rmat, "emission", Color(0, 0, 0, 0), 0.6)
	var flash = MeshInstance3D.new()
	var fbox = BoxMesh.new()
	fbox.size = Vector3(0.1, 0.1, 0.1)
	var fmat = StandardMaterial3D.new()
	fmat.albedo_color = Color(0.8, 0.9, 1.0)
	fmat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	fmat.emission_enabled = true
	fmat.emission = Color(1.0, 1.0, 1.0)
	fmat.emission_energy_multiplier = 20.0
	flash.mesh = fbox
	flash.material_override = fmat
	root.add_child(flash)
	var ftween = flash.create_tween()
	ftween.tween_property(flash, "scale", Vector3(12.0, 12.0, 12.0), 0.15)
	ftween.parallel().tween_property(fmat, "albedo_color", Color(1, 1, 1, 0), 0.15)

	for i in 30:
		var dot = MeshInstance3D.new()
		var box = BoxMesh.new()
		var s = randf_range(0.05, 0.1)
		box.size = Vector3(s, s, s)
		var dmat = StandardMaterial3D.new()
		dmat.albedo_color = Color(0.6, 0.0, 0.9)
		dmat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		dmat.emission_enabled = true
		dmat.emission = Color(0.7, 0.0, 1.0)
		dmat.emission_energy_multiplier = 6.0
		dot.mesh = box
		dot.material_override = dmat
		dot.position = Vector3(randf_range(-1.0, 1.0), randf_range(-1.0, 1.0), randf_range(-1.0, 1.0))
		root.add_child(dot)
		var dtween = dot.create_tween()
		dtween.tween_property(dot, "position", Vector3(randf_range(-6.0, 6.0), randf_range(-3.0, 5.0), randf_range(-6.0, 6.0)), 0.6)
		dtween.parallel().tween_property(dmat, "albedo_color", Color(0, 0, 0, 0), 0.6)

	var light = OmniLight3D.new()
	light.light_color = Color(0.5, 0.0, 0.8)
	light.light_energy = 12.0
	light.omni_range = 12.0
	light.position.y = 1.0
	root.add_child(light)
	var ltween = root.create_tween()
	ltween.tween_property(light, "light_energy", 0.0, 0.8)
	get_tree().create_timer(1.0).timeout.connect(root.queue_free)
	AudioManager.play_impact(global_position)

	var total_dmg = 0
	for enemy in get_tree().get_nodes_in_group("enemies"):
		var e3d = enemy as Node3D
		if e3d and global_position.distance_to(e3d.global_position) < 6.0:
			var dmg = 125.0 + fire_damage_bonus + ice_damage_bonus
			if e3d.has_method("take_damage"):
				e3d.take_damage(dmg)
				total_dmg += dmg
	var heal = total_dmg * 0.1
	health = minf(health + heal, max_health)
	_update_hud_health()

func launch_double_summon() -> void:
	print("¡Invocación Doble!")
	add_shake(0.4)
	AudioManager.play_summon_spawn(global_position)
	var circle = MeshInstance3D.new()
	var torus = TorusMesh.new()
	torus.inner_radius = 0.8
	torus.outer_radius = 1.0
	torus.rings = 14
	torus.ring_segments = 18
	var cmat = StandardMaterial3D.new()
	cmat.albedo_color = Color(0.6, 0.0, 0.05, 0.5)
	cmat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	cmat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	cmat.emission_enabled = true
	cmat.emission = Color(0.8, 0.0, 0.05)
	cmat.emission_energy_multiplier = 5.0
	circle.mesh = torus
	circle.material_override = cmat
	circle.position = Vector3(0, 0.1, 0)
	circle.rotation.x = deg_to_rad(90)
	add_child(circle)
	var ctween = circle.create_tween()
	ctween.tween_property(circle, "scale", Vector3(3.0, 3.0, 3.0), 0.3)
	ctween.tween_property(cmat, "albedo_color", Color(1, 0, 0, 0), 0.7)
	ctween.parallel().tween_property(cmat, "emission", Color(0, 0, 0, 0), 0.7)
	ctween.tween_callback(circle.queue_free)

	for i in 2:
		var summon = Node3D.new()
		summon.set_script(preload("res://scripts/summon_minion.gd"))
		var forward := -camera.global_transform.basis.z
		var flat_forward := Vector3(forward.x, 0, forward.z).normalized()
		summon.position = global_position + flat_forward * 2.0 + Vector3((i - 1) * 1.5, 0, 0)
		summon.add_to_group("summons")
		summon.tree_exited.connect(_on_summon_freed)
		summon.call("init_player", self)
		get_tree().root.add_child(summon)

func _spawn_projectile(effect: String = "fire", dmg: float = 25.0, scene_override: PackedScene = null, spread_angle: float = 0.0) -> void:
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
	var basis = camera.global_transform.basis
	if spread_angle != 0.0:
		basis = basis.rotated(basis.y, spread_angle)
	projectile.global_transform.basis = basis

	var target: Node3D = _find_target_enemy()
	if target != null:
		projectile.set_target(target)
		projectile.look_at(target.global_position, Vector3.UP)
	projectile.damage_origin = self

func _on_projectile_hit(damage: float) -> void:
	if lifesteal > 0:
		var heal = damage * lifesteal * 0.01
		health = minf(health + heal, max_health)
		_update_hud_health()


func _find_target_enemy() -> Node3D:
	var enemies: Array[Node] = get_tree().get_nodes_in_group("enemies")
	if enemies.is_empty():
		return null
	var cam_pos: Vector3 = camera.global_position
	var cam_forward: Vector3 = -camera.global_transform.basis.z
	var best: Node3D = null
	var best_score: float = INF
	var max_range = auto_aim_max_range + range_bonus * 2.0

	for e in enemies:
		var enemy: Node3D = e as Node3D
		if enemy == null:
			continue
		var offset: Vector3 = enemy.global_position - cam_pos
		var dist: float = offset.length()
		if dist < 1.0 or dist > max_range:
			continue
		var dir: Vector3 = offset / dist
		var dot: float = cam_forward.dot(dir)
		if dot <= 0.0:
			continue
		var angle_deg: float = rad_to_deg(acos(clampf(dot, -1.0, 1.0)))
		if angle_deg > auto_aim_max_angle:
			continue
		var score: float = angle_deg * (1.0 + dist / max_range)
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
	var armor_mult = maxf(1.0 - armor * 0.05, 0.1)
	amount *= armor_mult
	health = maxf(health - amount, 0.0)
	print("Jugador recibió ", snapped(amount, 0.1), " de daño. HP: ", health)
	AudioManager.play_hit()
	_update_hud_health()
	if _hud != null and _hud.has_method("show_damage_vignette"):
		_hud.show_damage_vignette()
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
			var spawner = get_tree().get_first_node_in_group("wave_spawner")
			var elapsed_str = "?"
			if spawner and spawner.has_method("get_elapsed_str"):
				elapsed_str = spawner.get_elapsed_str()
			go_ui.set_stats(level, fire_damage_bonus, ice_damage_bonus, int(max_health - 100), int(max_mana - 100), int(mana_regen_rate - 5), elapsed_str)


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


func apply_freeze(duration: float, slow_factor: float) -> void:
	_slow_mult = slow_factor
	_slow_timer = duration

func restore_mana(amount: float) -> void:
	current_mana = minf(current_mana + amount, max_mana)
	_update_hud_mana()

func drain_mana(amount: float) -> void:
	current_mana = maxf(current_mana - amount, 0.0)
	_update_hud_mana()

func apply_upgrade(item_id: String) -> void:
	if not is_inside_tree():
		return
	var im = get_node("/root/ItemManager")
	im.equip(item_id, self)
	if im.ITEMS[item_id]["type"] == "passive":
		_update_hud_health()
		_update_hud_mana()
	level += 1
	_update_hud_level()
	var im2 = get_node("/root/ItemManager")
	print("Nivel ", level, " - ", im2.ITEMS[item_id]["name"], " mejorado.")


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
		AudioManager.play_element_select()
		_update_hud_element()
		if _wand:
			_wand.set_element("FIRE")
		if _channel_ui:
			_channel_ui.set_element("FIRE")
		_pentagram_recognizer.set_tracking(false)
	if event.is_action_pressed("element_ice"):
		current_element = "ICE"
		print("Elemento: ICE")
		AudioManager.play_element_select()
		_update_hud_element()
		if _wand:
			_wand.set_element("ICE")
		if _channel_ui:
			_channel_ui.set_element("ICE")
		_pentagram_recognizer.set_tracking(false)
	if event.is_action_pressed("element_necromancia"):
		_cycle_summon()
		return
	if event is InputEventKey and event.keycode == KEY_TAB and event.pressed and not event.echo and _mouse_captured:
		_use_potion()
		return
	if event is InputEventKey and event.keycode == KEY_E and event.pressed and not event.echo:
		_try_interact()
		return
	if event is InputEventKey and event.keycode == KEY_F and event.pressed and not event.echo:
		current_element = "NECROMANCIA"
		print("Elemento: NECROMANCIA")
		AudioManager.play_element_select()
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
	_debug_frame += 1
	if _debug_frame <= 10:
		var on_floor = is_on_floor()
		print("[DEBUG] Frame ", _debug_frame, " vel: ", Vector3(snapped(velocity.x, 0.01), snapped(velocity.y, 0.01), snapped(velocity.z, 0.01)), " pos: ", Vector3(snapped(global_position.x, 0.01), snapped(global_position.y, 0.01), snapped(global_position.z, 0.01)), " on_floor: ", on_floor)
	var move_input := Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	var direction := Vector3.ZERO
	if move_input.length() > 0:
		direction = (head.transform.basis * Vector3(move_input.x, 0, move_input.y)).normalized()

	var target_velocity := direction * walk_speed * _speed_buff_mult * _slow_mult
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

	if _potion_cooldown > 0.0:
		_potion_cooldown = maxf(_potion_cooldown - delta, 0.0)

	if _hud != null and _hud.has_method("set_demon_cooldown"):
		_hud.set_demon_cooldown(0, _summon_cooldown)
		_hud.set_demon_cooldown(1, _soul_feeder_cooldown)
	if _hud != null and _hud.has_method("set_potion_cooldown"):
		_hud.set_potion_cooldown(_potion_cooldown)

	if _speed_buff_timer > 0.0:
		_speed_buff_timer -= delta
		if _speed_buff_timer <= 0.0 and _soul_feeder == null:
			_speed_buff_mult = 1.0

	if _slow_timer > 0.0:
		_slow_timer -= delta
		if _slow_timer <= 0.0:
			_slow_mult = 1.0

	var im_tick = get_node("/root/ItemManager")
	if im_tick:
		im_tick.tick(delta)

	if current_element == "NECROMANCIA" and not _pentagram_recognizer.is_tracking():
		_update_pentagram_tracking()

	if _wand:
		if is_channeling:
			_wand.rotation_degrees = _wand_base_rot + Vector3(-_wand_aim.y, _wand_aim.x, 0)
		else:
			_wand_aim = _wand_aim.lerp(Vector2.ZERO, delta * 8.0)
			_wand.rotation_degrees = _wand_base_rot + Vector3(-_wand_aim.y, _wand_aim.x, 0)

func _try_interact() -> void:
	var interactables = get_tree().get_nodes_in_group("interactables")
	var closest: Node = null
	var min_dist: float = 3.5
	for obj in interactables:
		if is_instance_valid(obj) and obj is Node3D:
			var d = global_position.distance_to(obj.global_position)
			if d < min_dist:
				min_dist = d
				closest = obj
	if closest and closest.has_method("interact"):
		closest.interact(self)

func _use_potion() -> void:
	if _potion_cooldown > 0.0:
		print("Poción en cooldown: ", snapped(_potion_cooldown, 0.1), "s")
		return
	health = minf(health + POTION_HEAL, max_health)
	_potion_cooldown = POTION_COOLDOWN_TIME
	_update_hud_health()
	AudioManager.play_heal()
	_spawn_heal_effect()

func _spawn_heal_effect() -> void:
	for i in 20:
		var piece := MeshInstance3D.new()
		var box := BoxMesh.new()
		var s := randf_range(0.04, 0.1)
		box.size = Vector3(s, s, s)
		var mat := StandardMaterial3D.new()
		mat.albedo_color = Color(0.2, 0.9, 0.2)
		mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		mat.emission_enabled = true
		mat.emission = Color(0.2, 1.0, 0.2)
		mat.emission_energy_multiplier = 6.0
		piece.mesh = box
		piece.material_override = mat
		piece.global_position = global_position + Vector3(0, 1, 0) + Vector3(randf_range(-0.5, 0.5), randf_range(-0.3, 1.0), randf_range(-0.5, 0.5))
		get_tree().root.add_child(piece)
		var tween := piece.create_tween()
		tween.tween_property(piece, "global_position", piece.global_position + Vector3(randf_range(-3, 3), randf_range(0.5, 3), randf_range(-3, 3)), 0.6)
		tween.parallel().tween_property(mat, "albedo_color", Color(0, 0, 0, 0), 0.6)
		tween.parallel().tween_property(mat, "emission", Color(0, 0, 0, 0), 0.6)
		tween.tween_callback(piece.queue_free)
	var light := OmniLight3D.new()
	light.light_color = Color(0.2, 1.0, 0.2)
	light.light_energy = 6.0
	light.omni_range = 5.0
	light.global_position = global_position + Vector3(0, 1, 0)
	get_tree().root.add_child(light)
	var ltween := create_tween()
	ltween.tween_property(light, "light_energy", 0.0, 0.5)
	ltween.tween_callback(light.queue_free)

func _show_channel_ui() -> void:
	AudioManager.play_channel_start()
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
