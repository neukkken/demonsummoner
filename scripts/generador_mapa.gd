extends Node3D

const CHUNK_SIZE := 60.0
const MIN_DIST_SPAWN := 16.0
const UPDATE_INTERVAL := 0.15 # Chequear chunks cada 0.15s para reducir carga de CPU

const BIOMES = {
	"VOLCANIC": {
		"floor_material": "res://materials/stone_material.tres",
		"pillar_material": "res://materials/stone_material.tres",
		"light_color": Color(1.0, 0.35, 0.05), # Red/Orange
		"light_energy": 5.0,
		"hazard_material": "res://materials/lava_material.tres",
		"hazard_type": "lava",
		"hazard_damage": 15.0,
		"hazard_slow": 0.4,
		"hazard_color": Color(1.0, 0.4, 0.1, 0.8)
	},
	"FROZEN": {
		"floor_material": "res://materials/snow_material.tres",
		"pillar_material": "res://materials/stone_material.tres",
		"light_color": Color(0.2, 0.6, 1.0), # Ice blue
		"light_energy": 4.0,
		"hazard_material": "res://materials/water_material.tres",
		"hazard_type": "slush",
		"hazard_damage": 0.0,
		"hazard_slow": 0.3, # Ralentiza mucho
		"hazard_color": Color(0.4, 0.7, 1.0, 0.6)
	},
	"SWAMP": {
		"floor_material": "res://materials/grass_material.tres",
		"pillar_material": "res://materials/stone_material.tres",
		"light_color": Color(0.15, 0.75, 0.25), # Toxic green
		"light_energy": 4.5,
		"hazard_material": "res://materials/water_material.tres",
		"hazard_type": "mud",
		"hazard_damage": 3.0, # Mud tóxico
		"hazard_slow": 0.6,
		"hazard_color": Color(0.18, 0.38, 0.12, 0.8)
	},
	"DESERT": {
		"floor_material": "res://materials/sand_material.tres",
		"pillar_material": "res://materials/stone_material.tres",
		"light_color": Color(0.8, 0.45, 0.95), # Purple/Magical
		"light_energy": 3.5,
		"hazard_material": "res://materials/sand_material.tres",
		"hazard_type": "quicksand",
		"hazard_damage": 0.0,
		"hazard_slow": 0.5,
		"hazard_color": Color(0.25, 0.18, 0.12, 0.9)
	}
}

# Objetivos de interpolación de atmósfera
var target_light_color: Color = Color.WHITE
var target_light_energy: float = 0.15
var target_ambient_color: Color = Color.BLACK
var target_fog_color: Color = Color.BLACK
var blend_speed: float = 1.2

# Referencias a nodos de iluminación/ambiente
var _dir_light: DirectionalLight3D = null
var _env: Environment = null

var _player: Node3D = null
var _time_since_last_update: float = 0.0
var _chunks_to_load: Array[Vector2i] = []
var active_chunks: Dictionary = {} # Vector2i -> Dictionary (region, hazards)


func _ready() -> void:
	_dir_light = get_node_or_null("../DirectionalLight3D")
	var env_node = get_node_or_null("../WorldEnvironment")
	if env_node and env_node.environment:
		env_node.environment = env_node.environment.duplicate()
		_env = env_node.environment

	_limpiar_estaticos()

	# Cargar el chunk central de inmediato para garantizar suelo y colisiones en frame 1
	_cargar_chunk(0, 0)

	# Posicionar al jugador a la altura del terreno al iniciar
	_player = get_node_or_null("../Player")
	if _player:
		var start_h = DatosJuego.get_height(_player.global_position.x, _player.global_position.z)
		_player.global_position.y = start_h + 2.0
		print("[MAP GEN] Jugador colocado en Y = ", _player.global_position.y)

	# Forzar actualización inicial de la grilla de chunks a cargar
	_actualizar_chunks_grid()


func _process(delta: float) -> void:
	if _player == null or not is_instance_valid(_player):
		_player = get_node_or_null("../Player")
	if _player == null:
		return

	# 1. Procesar transiciones de iluminación/niebla suavemente
	_procesar_transiciones_atmosfera(delta)

	# 2. Amortiguar chequeos de chunks para evitar sobrecarga en _process
	_time_since_last_update += delta
	if _time_since_last_update >= UPDATE_INTERVAL:
		_time_since_last_update = 0.0
		_actualizar_chunks_grid()

	# 3. Procesar un único chunk de la cola por frame (amortigua lag por frame)
	if not _chunks_to_load.is_empty():
		var next_coord = _chunks_to_load.pop_front()
		_cargar_chunk(next_coord.x, next_coord.y)


func _procesar_transiciones_atmosfera(delta: float) -> void:
	if _dir_light:
		_dir_light.light_color = _dir_light.light_color.lerp(target_light_color, blend_speed * delta)
		_dir_light.light_energy = lerpf(_dir_light.light_energy, target_light_energy, blend_speed * delta)
	if _env:
		_env.ambient_light_color = _env.ambient_light_color.lerp(target_ambient_color, blend_speed * delta)
		if _env.fog_enabled:
			_env.fog_light_color = _env.fog_light_color.lerp(target_fog_color, blend_speed * delta)
		if _env.volumetric_fog_enabled:
			_env.volumetric_fog_albedo = _env.volumetric_fog_albedo.lerp(target_fog_color, blend_speed * delta)
			_env.volumetric_fog_emission = _env.volumetric_fog_emission.lerp(target_fog_color, blend_speed * delta)

func _limpiar_estaticos() -> void:
	# Eliminar las paredes perimetrales y el suelo estático original para hacer el mapa infinito
	var world = get_parent()
	if world:
		var floor_node = world.get_node_or_null("Floor")
		if floor_node:
			floor_node.queue_free()
		var walls_node = world.get_node_or_null("Walls")
		if walls_node:
			walls_node.queue_free()
		var pilares_node = world.get_node_or_null("Pilares")
		if pilares_node:
			pilares_node.queue_free()
	print("[MAP GEN] Estructuras estáticas perimetrales limpiadas.")

func _get_biome_for_chunk(cx: int, cz: int) -> String:
	var rng = RandomNumberGenerator.new()
	rng.seed = (cx * 73856093) ^ (cz * 19349663)
	var keys = BIOMES.keys()
	return keys[rng.randi() % keys.size()]

func _actualizar_chunks_grid() -> void:
	var player_pos = _player.global_position
	var p_cx = int(round(player_pos.x / CHUNK_SIZE))
	var p_cz = int(round(player_pos.z / CHUNK_SIZE))

	# Actualizar objetivos de iluminación según el bioma del chunk actual del jugador
	var player_biome_name = _get_biome_for_chunk(p_cx, p_cz)
	var player_biome = BIOMES[player_biome_name]
	target_light_color = player_biome["light_color"]
	target_ambient_color = player_biome["light_color"] * 0.15
	target_fog_color = player_biome["light_color"] * 0.10 # Neblina moderada y agradable
	target_light_energy = player_biome["light_energy"]

	var radius := 1
	var fog_begin := 50.0
	var fog_end := 120.0
	var fog_density := 0.015
	
	match DatosJuego.render_distance:
		0: # Corta
			radius = 1
			fog_begin = 25.0
			fog_end = 65.0
			fog_density = 0.03
		1: # Media
			radius = 2
			fog_begin = 50.0
			fog_end = 120.0
			fog_density = 0.015
		2: # Larga
			radius = 3
			fog_begin = 80.0
			fog_end = 200.0
			fog_density = 0.008



	if _env:
		_env.volumetric_fog_density = fog_density
		if _env.fog_enabled:
			_env.fog_depth_begin = fog_begin
			_env.fog_depth_end = fog_end

	var required_coords: Array[Vector2i] = []
	# Grilla de chunks activos según el radio
	for dx in range(-radius, radius + 1):
		for dz in range(-radius, radius + 1):
			required_coords.append(Vector2i(p_cx + dx, p_cz + dz))

	# 1. Limpiar chunks lejanos
	var active_coords = active_chunks.keys()
	for coord in active_coords:
		if not coord in required_coords:
			var chunk_data = active_chunks[coord]
			# Eliminar hazards
			for hazard in chunk_data["hazards"]:
				if is_instance_valid(hazard):
					hazard.queue_free()
			# Eliminar región
			var region = chunk_data["region"]
			if is_instance_valid(region):
				region.queue_free()
			active_chunks.erase(coord)

	# 2. Quitar de la cola coordenadas que ya no son requeridas
	var i = _chunks_to_load.size() - 1
	while i >= 0:
		if not _chunks_to_load[i] in required_coords:
			_chunks_to_load.remove_at(i)
		i -= 1

	# 3. Agregar nuevos chunks requeridos a la cola
	for coord in required_coords:
		if not coord in active_chunks and not coord in _chunks_to_load:
			_chunks_to_load.append(coord)

func _cargar_chunk(cx: int, cz: int) -> void:
	# Crear la región de navegación para el chunk
	var nav_region = NavigationRegion3D.new()
	nav_region.name = "Chunk_%d_%d" % [cx, cz]
	nav_region.position = Vector3(cx * CHUNK_SIZE, 0.0, cz * CHUNK_SIZE)
	
	var nav_mesh = NavigationMesh.new()
	nav_mesh.geometry_parsed_geometry_type = NavigationMesh.PARSED_GEOMETRY_BOTH
	nav_mesh.agent_radius = 0.5
	nav_mesh.agent_height = 2.0
	nav_mesh.agent_max_climb = 0.25
	nav_mesh.agent_max_slope = 45.0
	nav_mesh.cell_size = 0.25
	nav_mesh.cell_height = 0.25
	nav_region.navigation_mesh = nav_mesh

	# Añadir al árbol de escenas primero, antes de poblar e iniciar el bake
	add_child(nav_region)

	var hazards_array: Array[Node3D] = []
	active_chunks[Vector2i(cx, cz)] = {
		"region": nav_region,
		"hazards": hazards_array
	}

	# Obtener bioma determinista para este chunk
	var biome_name = _get_biome_for_chunk(cx, cz)
	var biome = BIOMES[biome_name]

	# 1. Generar suelo local deformado (montañas)
	var floor_body = _generar_suelo_deformado(cx, cz, biome)
	nav_region.add_child(floor_body)

	# 2. Generar obstáculos y peligros
	var seed_val = (cx * 123456789) ^ (cz * 987654321)
	var rng = RandomNumberGenerator.new()
	rng.seed = seed_val

	# Grilla de 6x6 celdas locales
	var step := 10.0
	for x_idx in range(6):
		for z_idx in range(6):
			var lx = -25.0 + x_idx * step
			var lz = -25.0 + z_idx * step

			var wx = cx * CHUNK_SIZE + lx
			var wz = cz * CHUNK_SIZE + lz
			var world_pos = Vector2(wx, wz)

			# Omitir origen
			if world_pos.length() < MIN_DIST_SPAWN:
				continue

			var ox = lx + rng.randf_range(-1.5, 1.5)
			var oz = lz + rng.randf_range(-1.5, 1.5)

			var roll = rng.randf()
			# Obtener altura global para posicionamiento de obstáculos
			var height = DatosJuego.get_height(cx * CHUNK_SIZE + ox, cz * CHUNK_SIZE + oz)

			if roll < 0.08:
				# Los peligros (hazards) se añaden directamente al nodo raiz
				# Esto evita que el baker los procese innecesariamente (reduciendo CPU de baking)
				_instanciar_hazard_local(cx, cz, ox, oz, height, biome, hazards_array)
			elif roll < 0.18:
				_instanciar_pilar_local(nav_region, ox, oz, height, biome)
			elif roll < 0.26:
				_instanciar_ruina_local(nav_region, ox, oz, height, biome, rng)

	# 3. Hornear NavMesh del chunk asíncronamente en segundo plano (no congela el hilo principal)
	nav_region.bake_navigation_mesh(true)

func _generar_suelo_deformado(cx: int, cz: int, biome: Dictionary) -> StaticBody3D:
	var points := 11
	var step_size = CHUNK_SIZE / (points - 1)

	var st = SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)

	# Generar vértices, normales y UVs
	for j in range(points):
		for i in range(points):
			var lx = -CHUNK_SIZE/2.0 + i * step_size
			var lz = -CHUNK_SIZE/2.0 + j * step_size
			var wx = cx * CHUNK_SIZE + lx
			var wz = cz * CHUNK_SIZE + lz
			
			var height = DatosJuego.get_height(wx, wz)
			
			# Tiling de textura repetido 4 veces
			var u = float(i) / (points - 1) * 4.0
			var v = float(j) / (points - 1) * 4.0
			
			st.set_uv(Vector2(u, v))
			st.add_vertex(Vector3(lx, height, lz))

	# Generar índices
	for j in range(points - 1):
		for i in range(points - 1):
			var i0 = j * points + i
			var i1 = j * points + (i + 1)
			var i2 = (j + 1) * points + i
			var i3 = (j + 1) * points + (i + 1)
			
			# Triángulo 1
			st.add_index(i0)
			st.add_index(i1)
			st.add_index(i2)
			
			# Triángulo 2
			st.add_index(i1)
			st.add_index(i3)
			st.add_index(i2)

	st.generate_normals()
	var mesh = st.commit()

	var floor_body = StaticBody3D.new()
	floor_body.name = "Floor"

	var f_col = CollisionShape3D.new()
	f_col.shape = mesh.create_trimesh_shape()
	floor_body.add_child(f_col)

	var f_mesh_inst = MeshInstance3D.new()
	f_mesh_inst.mesh = mesh
	f_mesh_inst.material_override = load(biome["floor_material"])
	floor_body.add_child(f_mesh_inst)

	return floor_body

func _instanciar_pilar_local(parent: Node3D, x: float, z: float, height: float, biome: Dictionary) -> void:
	var pillar = StaticBody3D.new()
	pillar.name = "Pillar_%s_%s" % [snapped(x, 1), snapped(z, 1)]
	# La posición central en Y del colisionador de 10.0m de alto debe ser height + 5.0
	pillar.position = Vector3(x, height + 5.0, z)

	var col = CollisionShape3D.new()
	var shape = CylinderShape3D.new()
	shape.radius = 1.2
	shape.height = 10.0
	col.shape = shape
	pillar.add_child(col)

	var mesh_inst = MeshInstance3D.new()
	var mesh = CylinderMesh.new()
	mesh.top_radius = 1.2
	mesh.bottom_radius = 1.2
	mesh.height = 10.0
	mesh.radial_segments = 6 # Hexagonal retro
	mesh_inst.mesh = mesh
	mesh_inst.material_override = load(biome["pillar_material"])
	pillar.add_child(mesh_inst)

	# Iluminación local de antorcha
	var torch = OmniLight3D.new()
	torch.light_color = biome["light_color"]
	torch.light_energy = biome["light_energy"]
	torch.omni_range = 15.0
	torch.shadow_enabled = true
	torch.position = Vector3(0, 1.0, 0)
	pillar.add_child(torch)

	parent.add_child(pillar)

func _instanciar_ruina_local(parent: Node3D, x: float, z: float, height: float, biome: Dictionary, rng: RandomNumberGenerator) -> void:
	var ruin = StaticBody3D.new()
	ruin.name = "Ruin_%s_%s" % [snapped(x, 1), snapped(z, 1)]
	# La posición central en Y de la pared de 6.0m de alto debe ser height + 3.0
	ruin.position = Vector3(x, height + 3.0, z)
	ruin.rotation.y = [0.0, PI/2.0, PI, 3.0*PI/2.0][rng.randi() % 4]

	var is_l_shape = rng.randf() > 0.5
	if is_l_shape:
		# Muro 1
		var col1 = CollisionShape3D.new()
		var shape1 = BoxShape3D.new()
		shape1.size = Vector3(8.0, 6.0, 1.2)
		col1.shape = shape1
		ruin.add_child(col1)

		var mesh1 = MeshInstance3D.new()
		var box1 = BoxMesh.new()
		box1.size = Vector3(8.0, 6.0, 1.2)
		mesh1.mesh = box1
		mesh1.material_override = load(biome["pillar_material"])
		ruin.add_child(mesh1)

		# Muro 2 perpendicular
		var col2 = CollisionShape3D.new()
		var shape2 = BoxShape3D.new()
		shape2.size = Vector3(1.2, 6.0, 8.0)
		col2.shape = shape2
		col2.position = Vector3(3.4, 0, -3.4)
		ruin.add_child(col2)

		var mesh2 = MeshInstance3D.new()
		var box2 = BoxMesh.new()
		box2.size = Vector3(1.2, 6.0, 8.0)
		mesh2.mesh = box2
		mesh2.material_override = load(biome["pillar_material"])
		mesh2.position = Vector3(3.4, 0, -3.4)
		ruin.add_child(mesh2)
	else:
		# Muro recto simple
		var col = CollisionShape3D.new()
		var shape = BoxShape3D.new()
		shape.size = Vector3(8.0, 6.0, 1.2)
		col.shape = shape
		ruin.add_child(col)

		var mesh_inst = MeshInstance3D.new()
		var box = BoxMesh.new()
		box.size = Vector3(8.0, 6.0, 1.2)
		mesh_inst.mesh = box
		mesh_inst.material_override = load(biome["pillar_material"])
		ruin.add_child(mesh_inst)

	parent.add_child(ruin)

func _instanciar_hazard_local(cx: int, cz: int, ox: float, oz: float, height: float, biome: Dictionary, hazards_array: Array) -> void:
	var hazard_script = load("res://scripts/map_hazard.gd")
	if not hazard_script:
		return

	var hazard = Area3D.new()
	hazard.name = "HazardPool_%s_%s" % [snapped(cx * CHUNK_SIZE + ox, 1), snapped(cz * CHUNK_SIZE + oz, 1)]
	hazard.set_script(hazard_script)
	# Posición absoluta respecto a GeneradorMapa, con elevación de 0.05 sobre el relieve
	hazard.position = Vector3(cx * CHUNK_SIZE + ox, height + 0.05, cz * CHUNK_SIZE + oz)

	hazard.hazard_type = biome["hazard_type"]
	hazard.damage_per_second = biome["hazard_damage"]
	hazard.slow_factor = biome["hazard_slow"]

	var col = CollisionShape3D.new()
	var shape = CylinderShape3D.new()
	shape.radius = 4.0
	shape.height = 1.0
	col.shape = shape
	hazard.add_child(col)

	var mesh_inst = MeshInstance3D.new()
	var mesh = CylinderMesh.new()
	mesh.top_radius = 4.0
	mesh.bottom_radius = 4.0
	mesh.height = 0.02
	mesh.radial_segments = 8 # Charco octogonal retro
	mesh_inst.mesh = mesh

	var base_mat = load(biome["hazard_material"])
	if base_mat:
		var mat = base_mat.duplicate()
		mat.albedo_color = biome["hazard_color"]
		mat.roughness = 0.6
		mesh_inst.material_override = mat

	hazard.add_child(mesh_inst)
	
	# Añadirlo a nosotros mismos, no al nav_region (se descarta de geometría del NavMesh)
	add_child(hazard)
	hazards_array.append(hazard)
