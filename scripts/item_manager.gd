extends Node

const ITEMS := {
	"dented_souls":  {"name": "Almas dentadas",   "type": "weapon", "max_lv": 10, "desc": "1 orbe rojo por nivel que orbita y daña"},
	"ghost_projectile": {"name": "Proyectil fantasma","type": "weapon", "max_lv": 10, "desc": "Dispara proyectil al enemigo cada 1.5s"},
	"necro_cloud":   {"name": "Rastro de veneno", "type": "weapon", "max_lv": 10, "desc": "Deja un rastro venenoso que daña enemigos"},
	"blood_heart":   {"name": "Corazón de sangre", "type": "passive","max_lv": 10, "desc": "+30 HP máximo por nivel"},
	"arcane_battery":{"name": "Batería arcana",     "type": "passive","max_lv": 10, "desc": "+30 Maná +2 regen por nivel"},
	"wind_boots":    {"name": "Botas de viento",    "type": "passive","max_lv": 10, "desc": "+1.5 velocidad por nivel"},
	"shadow_armor":  {"name": "Armadura de sombra", "type": "passive","max_lv": 10, "desc": "+1 armadura por nivel"},
	"soul_magnet":   {"name": "Imán de almas",     "type": "passive","max_lv": 10, "desc": "+1 rango succión por nivel"},
	"old_grimoire":  {"name": "Grimorio antiguo",   "type": "passive","max_lv": 10, "desc": "-20% coste maná acumulable"},
	"xp_gem":        {"name": "Gema de experiencia","type": "passive","max_lv": 10, "desc": "+25% XP ganada acumulable"},
}

var _items: Dictionary = {}
var _player = null
var _weapon_nodes: Array[Node] = []
var _ghost_timer: float = 0.0

func get_level(item_id: String) -> int:
	return _items.get(item_id, 0)

func get_owned() -> Array[String]:
	return _items.keys()

func has(item_id: String) -> bool:
	return _items.has(item_id)

func equip(item_id: String, player: Node) -> void:
	_player = player
	var cur = _items.get(item_id, 0)
	if cur >= ITEMS[item_id]["max_lv"]:
		return
	_items[item_id] = cur + 1
	var info = ITEMS[item_id]
	if info["type"] == "passive":
		_apply_passive(item_id, player)
	else:
		_equip_weapon(item_id, player)

func _apply_passive(item_id: String, player: Node) -> void:
	var lv = _items[item_id]
	match item_id:
		"blood_heart":
			player.max_health += 30
			player.health = minf(player.health + 30, player.max_health)
		"arcane_battery":
			player.max_mana += 30
			player.mana_regen_rate += 2
			player.current_mana = minf(player.current_mana + 30, player.max_mana)
		"wind_boots":
			player.walk_speed += 1.5
		"shadow_armor":
			player.armor = mini(player.armor + 1, 20)
		"soul_magnet":
			player.range_bonus += 1
		"old_grimoire":
			player.mana_cost_mult = maxf(0.1, player.mana_cost_mult - 0.2)
		"xp_gem":
			player.xp_mult += 0.25

func _equip_weapon(item_id: String, player: Node) -> void:
	match item_id:
		"dented_souls":
			_spawn_soul_orb(player)
		"ghost_projectile":
			_spawn_ghost_crystal(player)
		"necro_cloud":
			_spawn_poison_trail(player)

func _spawn_soul_orb(player: Node) -> void:
	var root = Node3D.new()
	root.name = "DentedSouls" + str(_weapon_nodes.size())
	player.add_child(root)
	var mesh = MeshInstance3D.new()
	var sphere = SphereMesh.new()
	sphere.radius = 0.4
	sphere.height = 0.8
	var mat = StandardMaterial3D.new()
	mat.albedo_color = Color(0.8, 0.0, 0.05)
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.emission_enabled = true
	mat.emission = Color(1.0, 0.0, 0.05)
	mat.emission_energy_multiplier = 8.0
	mesh.mesh = sphere
	mesh.material_override = mat
	root.add_child(mesh)
	var col = CollisionShape3D.new()
	var cshape = SphereShape3D.new()
	cshape.radius = 0.6
	col.shape = cshape
	root.add_child(col)
	var area = Area3D.new()
	area.collision_mask = 1
	area.add_child(col)
	root.add_child(area)

	var orb_script = preload("res://scripts/item_effect.gd")
	if orb_script:
		root.set_script(orb_script)
		root.damage = _items["dented_souls"] * 100
		root.orbit_radius = 3.5
		root.orbit_speed = 1.5
		root.target_player = player

	_weapon_nodes.append(root)

func _spawn_ghost_crystal(player: Node) -> void:
	var root = Node3D.new()
	root.name = "GhostProjectile"
	player.add_child(root)
	var mesh = MeshInstance3D.new()
	var box = BoxMesh.new()
	box.size = Vector3(0.1, 0.15, 0.1)
	var mat = StandardMaterial3D.new()
	mat.albedo_color = Color(0.3, 0.6, 1.0)
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.emission_enabled = true
	mat.emission = Color(0.2, 0.5, 1.0)
	mat.emission_energy_multiplier = 6.0
	mesh.mesh = box
	mesh.material_override = mat
	mesh.position.y = 2.5
	root.add_child(mesh)
	var orb_script = preload("res://scripts/item_effect.gd")
	if orb_script:
		root.set_script(orb_script)
		root.damage = _items["ghost_projectile"] * 60
		root.target_player = player
		root._type = "ghost"
	_weapon_nodes.append(root)

func _spawn_poison_trail(player: Node) -> void:
	var root = Node3D.new()
	root.name = "PoisonTrail"
	player.add_child(root)
	var trail_script = preload("res://scripts/item_effect.gd")
	if trail_script:
		root.set_script(trail_script)
		root.damage = _items["necro_cloud"] * 100
		root.target_player = player
		root._type = "trail"
		root._trail_interval = maxf(0.15, 0.5 - _items["necro_cloud"] * 0.03)
	_weapon_nodes.append(root)

func _find_nearest_enemy() -> Node3D:
	if _player == null:
		return null
	var enemies: Array[Node] = _player.get_tree().get_nodes_in_group("enemies")
	var best: Node3D = null
	var best_dist: float = INF
	var cam_pos: Vector3 = _player.global_position
	for e in enemies:
		var e3d := e as Node3D
		if e3d == null:
			continue
		var d: float = cam_pos.distance_squared_to(e3d.global_position)
		if d < best_dist:
			best_dist = d
			best = e3d
	return best

func tick(delta: float) -> void:
	if _player == null:
		return
	for wn in _weapon_nodes:
		if is_instance_valid(wn) and wn.has_method("weapon_tick"):
			wn.weapon_tick(delta)
	var lv = _items.get("ghost_projectile", 0)
	if lv > 0:
		_ghost_timer -= delta
		if _ghost_timer <= 0:
			_ghost_timer = maxf(0.5, 1.5 - lv * 0.1)
			var target = _find_nearest_enemy()
			if target:
				var proj = preload("res://scenes/spell_projectile.tscn").instantiate() as Area3D
				if proj:
					proj.effect_type = "fire"
					proj.damage = lv * 60
					_player.get_tree().root.add_child(proj)
					var dir = (target.global_position - _player.global_position).normalized()
					dir.y = 0
					proj.global_position = _player.global_position + dir * 3.0 + Vector3(0, 1.0, 0)
					proj.set_target(target)
					proj.look_at(target.global_position, Vector3.UP)
					proj.damage_origin = _player

func clear(player: Node) -> void:
	_items.clear()
	_player = null
	for wn in _weapon_nodes:
		if is_instance_valid(wn):
			wn.queue_free()
	_weapon_nodes.clear()
	_ghost_timer = 0.0
