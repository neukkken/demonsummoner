extends StaticBody3D

@export var chest_type: String = "demonic" # "wood", "iron", "demonic"
@export var is_opened: bool = false

var _lid_pivot: Node3D = null
var _prompt_label: Label3D = null
var _glow_mesh: MeshInstance3D = null
var _glow_mat: StandardMaterial3D = null
var _interaction_distance: float = 3.2
var _player: Node3D = null

func _ready() -> void:
	add_to_group("interactables")
	add_to_group("chests")
	_build_visuals()
	_build_collision()
	_build_prompt()

func _build_visuals() -> void:
	# 1. Base del cofre
	var base_mesh_inst = MeshInstance3D.new()
	var base_box = BoxMesh.new()
	base_box.size = Vector3(1.2, 0.6, 0.8)
	base_mesh_inst.mesh = base_box
	base_mesh_inst.position = Vector3(0, 0.3, 0)
	
	var base_mat = StandardMaterial3D.new()
	base_mat.albedo_color = Color(0.22, 0.12, 0.08) # Madera oscura
	base_mat.roughness = 0.8
	base_mat.metallic = 0.1
	base_mesh_inst.material_override = base_mat
	add_child(base_mesh_inst)

	# Biseles metálicos en la base
	var rim_mesh_inst = MeshInstance3D.new()
	var rim_box = BoxMesh.new()
	rim_box.size = Vector3(1.24, 0.12, 0.84)
	rim_mesh_inst.mesh = rim_box
	rim_mesh_inst.position = Vector3(0, 0.55, 0)
	var metal_mat = StandardMaterial3D.new()
	metal_mat.albedo_color = Color(0.65, 0.5, 0.2) # Oro / Bronce antiguo
	metal_mat.metallic = 0.8
	metal_mat.roughness = 0.3
	rim_mesh_inst.material_override = metal_mat
	add_child(rim_mesh_inst)

	# 2. Bisagra y Tapa (Pivot en borde superior trasero: Y=0.6, Z=-0.4)
	_lid_pivot = Node3D.new()
	_lid_pivot.name = "LidPivot"
	_lid_pivot.position = Vector3(0, 0.6, -0.4)
	add_child(_lid_pivot)

	var lid_mesh_inst = MeshInstance3D.new()
	var lid_box = BoxMesh.new()
	lid_box.size = Vector3(1.22, 0.25, 0.82)
	lid_mesh_inst.mesh = lid_box
	# Centrar el mesh relativo al pivote
	lid_mesh_inst.position = Vector3(0, 0.125, 0.4)
	lid_mesh_inst.material_override = base_mat
	_lid_pivot.add_child(lid_mesh_inst)

	# Cerrojo en la tapa
	var lock_mesh_inst = MeshInstance3D.new()
	var lock_box = BoxMesh.new()
	lock_box.size = Vector3(0.2, 0.2, 0.08)
	lock_mesh_inst.mesh = lock_box
	lock_mesh_inst.position = Vector3(0, 0.05, 0.82)
	lock_mesh_inst.material_override = metal_mat
	_lid_pivot.add_child(lock_mesh_inst)

	# Brillo demoníaco interior
	_glow_mesh = MeshInstance3D.new()
	var glow_sphere = SphereMesh.new()
	glow_sphere.radius = 0.3
	glow_sphere.height = 0.6
	_glow_mesh.mesh = glow_sphere
	_glow_mesh.position = Vector3(0, 0.4, 0)
	_glow_mat = StandardMaterial3D.new()
	_glow_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_glow_mat.albedo_color = Color(1.0, 0.3, 0.05, 0.8)
	_glow_mat.emission_enabled = true
	_glow_mat.emission = Color(1.0, 0.4, 0.1)
	_glow_mat.emission_energy_multiplier = 4.0
	_glow_mesh.material_override = _glow_mat
	_glow_mesh.visible = false
	add_child(_glow_mesh)

func _build_collision() -> void:
	var col = CollisionShape3D.new()
	var shape = BoxShape3D.new()
	shape.size = Vector3(1.3, 0.9, 0.9)
	col.shape = shape
	col.position = Vector3(0, 0.45, 0)
	add_child(col)

func _build_prompt() -> void:
	_prompt_label = Label3D.new()
	_prompt_label.text = "[E] Abrir Cofre"
	_prompt_label.font_size = 28
	_prompt_label.outline_size = 6
	_prompt_label.modulate = Color(1.0, 0.85, 0.3)
	_prompt_label.outline_modulate = Color(0, 0, 0)
	_prompt_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_prompt_label.position = Vector3(0, 1.25, 0)
	_prompt_label.visible = false
	add_child(_prompt_label)

func _process(delta: float) -> void:
	if is_opened:
		if _prompt_label.visible:
			_prompt_label.visible = false
		return

	if _player == null or not is_instance_valid(_player):
		_player = get_tree().get_first_node_in_group("player")
		if _player == null:
			return

	var dist = global_position.distance_to(_player.global_position)
	var in_range = dist <= _interaction_distance
	if _prompt_label.visible != in_range:
		_prompt_label.visible = in_range
	
	if in_range:
		# Suave pulso en el prompt
		var pulse = 1.0 + 0.1 * sin(Time.get_ticks_msec() * 0.006)
		_prompt_label.scale = Vector3(pulse, pulse, pulse)

func interact(player: Node) -> void:
	if is_opened:
		return
	is_opened = true
	_prompt_label.visible = false

	# Animación de apertura de la tapa
	if _lid_pivot:
		var tween = create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
		tween.tween_property(_lid_pivot, "rotation:x", -deg_to_rad(115), 0.6)

	# Sonido épico
	AudioManager.play_pentagram_complete()
	
	# Efecto visual de resplandor
	if _glow_mesh:
		_glow_mesh.visible = true
		var gtween = create_tween()
		gtween.tween_property(_glow_mesh, "scale", Vector3(2.5, 2.5, 2.5), 0.4)
		gtween.parallel().tween_property(_glow_mat, "emission_energy_multiplier", 12.0, 0.4)
		gtween.tween_property(_glow_mesh, "scale", Vector3.ZERO, 0.5)

	# Recompensas
	_soltar_loot(player)

func _soltar_loot(player: Node) -> void:
	# 1. Otorgar o mejorar un item pasivo o arma aleatoria
	var im = get_node_or_null("/root/ItemManager")
	var item_name = "Tesoro Arcano"
	if im and player:
		var all_items = im.ITEMS.keys()
		# Buscar items que aún no estén en nivel máximo
		var available: Array[String] = []
		for id in all_items:
			if im.get_level(id) < im.ITEMS[id]["max_lv"]:
				available.append(id)
		if not available.is_empty():
			var chosen_id = available[randi() % available.size()]
			item_name = im.ITEMS[chosen_id]["name"]
			if player.has_method("apply_upgrade"):
				player.apply_upgrade(chosen_id)
			else:
				im.equip(chosen_id, player)

	# 2. Notificación en HUD
	var hud = get_tree().get_first_node_in_group("hud")
	if hud and hud.has_method("show_event_banner"):
		hud.show_event_banner("¡COFRE: %s MEJORADO!" % item_name.to_upper(), Color(1.0, 0.85, 0.2))

	# 3. Soltar gemas de XP grande y orbe de curación expulsados físicamente
	var alma_script = load("res://scripts/alma_espectral.gd")
	if alma_script:
		# Gema de XP Grande (50 XP)
		_spawn_bouncing_gem(alma_script, "big", 50, Vector3(-0.5, 0.8, 0.5))
		_spawn_bouncing_gem(alma_script, "big", 50, Vector3(0.5, 0.8, 0.5))
		# Gema de Cura
		_spawn_bouncing_gem(alma_script, "heal", 0, Vector3(0.0, 0.9, -0.3))

func _spawn_bouncing_gem(alma_script: Script, type: String, xp: int, offset_dir: Vector3) -> void:
	var gem = Area3D.new()
	gem.set_script(alma_script)
	gem._gem_type = type
	gem.xp_value = xp
	gem.global_position = global_position + Vector3(0, 0.6, 0)
	get_tree().root.add_child(gem)
	
	# Pequeño salto de expulsión
	var target_pos = global_position + offset_dir * 2.0
	target_pos.y = global_position.y + 0.5
	var tween = gem.create_tween().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(gem, "global_position:y", global_position.y + 1.8, 0.3)
	tween.parallel().tween_property(gem, "global_position:x", target_pos.x, 0.5)
	tween.parallel().tween_property(gem, "global_position:z", target_pos.z, 0.5)
	tween.chain().tween_property(gem, "global_position:y", target_pos.y, 0.25).set_ease(Tween.EASE_IN)
