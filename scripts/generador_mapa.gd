extends Node3D

# ==============================================================================
# GENERADOR PROCEDURAL DE MAZMORRAS 3D MONUMENTALES (COLOSSAL GOTHIC CITADEL)
# Demon Summoner — Arquitectura Colosal, Bóvedas de 18m, 3 Pisos y Escala Épica
# ==============================================================================

const GRID_SIZE := 7
const CELL_SIZE := 32.0
const WALL_HEIGHT := 18.0
const WALL_THICKNESS := 1.2
const DOOR_WIDTH := 7.0
const DOOR_HEIGHT := 11.0
const CORRIDOR_WIDTH := 7.0

const LEVEL_HEIGHTS := [0.0, 10.0, 22.0] # 3 Pisos monumentales de elevación

# Tipos de Sala
enum RoomType {
	SPAWN_HALL,
	TREASURE_VAULT,
	DEMONIC_SHRINE,
	CRYPT_PILLARS,
	LAVA_PIT,
	UPPER_TERRACE,
	CORRIDOR
}

# Estructura de celda
class DungeonCell:
	var grid_pos: Vector2i
	var world_center: Vector3
	var room_type: int
	var floor_height: float = 0.0
	var room_size: Vector2 = Vector2(26.0, 26.0)
	var active: bool = false
	var connections: Array[Vector2i] = [] # Vecinos conectados

var _grid: Dictionary = {} # Vector2i -> DungeonCell
var _nav_region: NavigationRegion3D = null
var _player: Node3D = null

# Materiales compartidos estáticos
var _mat_stone: Material = null
var _mat_dark_stone: StandardMaterial3D = null
var _mat_gold_trim: StandardMaterial3D = null
var _mat_wood: StandardMaterial3D = null
var _mat_obsidian: StandardMaterial3D = null
var _chest_script: Script = null

# Zonas de piso para consulta ultra-rápida de altura
var _floor_zones: Array[Dictionary] = [] # {rect: Rect2, h1: float, h2: float, is_stair: bool, axis: String, c1_coord: float, c2_coord: float}

func _ready() -> void:
	DatosJuego.current_dungeon = self
	_cargar_recursos()
	_limpiar_estaticos()

	_nav_region = NavigationRegion3D.new()
	_nav_region.name = "DungeonNavRegion"
	add_child(_nav_region)

	var nav_mesh = NavigationMesh.new()
	nav_mesh.geometry_parsed_geometry_type = NavigationMesh.PARSED_GEOMETRY_BOTH
	nav_mesh.agent_radius = 0.6
	nav_mesh.agent_height = 2.0
	nav_mesh.agent_max_climb = 0.8
	nav_mesh.agent_max_slope = 45.0
	nav_mesh.cell_size = 0.3
	nav_mesh.cell_height = 0.25
	_nav_region.navigation_mesh = nav_mesh

	# 1. Generar la disposición lógica de la gran ciudadela
	_generar_layout_mazmorra()

	# 2. Construir la arquitectura monumental 3D (Bóvedas, Muros, Escaleras)
	_construir_geometria_mazmorra()

	# 3. Poblar obeliscos, columnas colosales, fosos, cofres y antorchas
	_poblar_elementos_mazmorra()

	# 4. Hornear la malla de navegación
	_nav_region.bake_navigation_mesh(false)

	# 5. Posicionar al jugador en el Spawn Hall central
	_player = get_node_or_null("../Player")
	if _player:
		var spawn_pos = Vector3(0.0, 1.5, 0.0)
		_player.global_position = spawn_pos
		print("[DUNGEON GEN] Gran Ciudadela Gótica construida. Jugador situado en ", spawn_pos)

	_ajustar_atmosfera()

func _cargar_recursos() -> void:
	_chest_script = load("res://scripts/dungeon_chest.gd")
	var stone_res = load("res://materials/stone_material.tres")
	if stone_res:
		_mat_stone = stone_res
	else:
		_mat_stone = StandardMaterial3D.new()
		_mat_stone.albedo_color = Color(0.28, 0.26, 0.25)
		_mat_stone.roughness = 0.85

	_mat_dark_stone = StandardMaterial3D.new()
	_mat_dark_stone.albedo_color = Color(0.12, 0.11, 0.14)
	_mat_dark_stone.roughness = 0.92

	_mat_gold_trim = StandardMaterial3D.new()
	_mat_gold_trim.albedo_color = Color(0.78, 0.62, 0.18)
	_mat_gold_trim.metallic = 0.85
	_mat_gold_trim.roughness = 0.28

	_mat_wood = StandardMaterial3D.new()
	_mat_wood.albedo_color = Color(0.24, 0.13, 0.08)
	_mat_wood.roughness = 0.88

	_mat_obsidian = StandardMaterial3D.new()
	_mat_obsidian.albedo_color = Color(0.05, 0.04, 0.07)
	_mat_obsidian.metallic = 0.6
	_mat_obsidian.roughness = 0.15

func _limpiar_estaticos() -> void:
	var world = get_parent()
	if world:
		var floor_node = world.get_node_or_null("Floor")
		if floor_node: floor_node.queue_free()
		var walls_node = world.get_node_or_null("Walls")
		if walls_node: walls_node.queue_free()
		var pilares_node = world.get_node_or_null("Pilares")
		if pilares_node: pilares_node.queue_free()

func _ajustar_atmosfera() -> void:
	var dir_light: DirectionalLight3D = get_node_or_null("../DirectionalLight3D")
	if dir_light:
		dir_light.light_color = Color(0.65, 0.70, 0.90)
		dir_light.light_energy = 0.4
		dir_light.shadow_enabled = true
		dir_light.shadow_bias = 0.03

	var env_node: WorldEnvironment = get_node_or_null("../WorldEnvironment")
	if env_node and env_node.environment:
		var env = env_node.environment
		env.ambient_light_color = Color(0.12, 0.09, 0.18)
		env.ambient_light_energy = 0.95
		if env.fog_enabled:
			env.fog_light_color = Color(0.05, 0.03, 0.09)
			env.fog_density = 0.008
		if env.volumetric_fog_enabled:
			env.volumetric_fog_density = 0.012
			env.volumetric_fog_albedo = Color(0.08, 0.04, 0.12)
			env.volumetric_fog_emission = Color(0.02, 0.01, 0.03)

# ------------------------------------------------------------------------------
# 1. DISEÑO LÓGICO DEL PLANO (LAYOUT 7x7)
# ------------------------------------------------------------------------------
func _generar_layout_mazmorra() -> void:
	# Grilla 7x7 centrada en (3,3) = Spawn Hall a Y=0.0
	# Pisos: 0.0 (Criptas Bajas y Abismo de Lava) -> 10.0 (Nave de Reliquias) -> 22.0 (Cúspide de Titanes)
	var plan = [
		# Nivel 0 (Y = 0.0) — La Gran Nave y Criptas Centrales
		{"pos": Vector2i(3, 3), "type": RoomType.SPAWN_HALL, "h": 0.0, "size": Vector2(28, 28)},
		{"pos": Vector2i(3, 2), "type": RoomType.CORRIDOR, "h": 0.0, "size": Vector2(12, 12)},
		{"pos": Vector2i(3, 1), "type": RoomType.CRYPT_PILLARS, "h": 0.0, "size": Vector2(26, 26)},
		{"pos": Vector2i(3, 0), "type": RoomType.LAVA_PIT, "h": 0.0, "size": Vector2(28, 28)}, # Foso abisal con puente
		{"pos": Vector2i(2, 3), "type": RoomType.CORRIDOR, "h": 0.0, "size": Vector2(12, 12)},
		{"pos": Vector2i(4, 3), "type": RoomType.CORRIDOR, "h": 0.0, "size": Vector2(12, 12)},
		{"pos": Vector2i(3, 4), "type": RoomType.CRYPT_PILLARS, "h": 0.0, "size": Vector2(26, 26)},

		# Rampa Oeste hacia Nivel 1 (Y = 10.0)
		{"pos": Vector2i(1, 3), "type": RoomType.CORRIDOR, "h": 5.0, "size": Vector2(12, 12)}, # Tramo inclinado 0->10
		{"pos": Vector2i(0, 3), "type": RoomType.TREASURE_VAULT, "h": 10.0, "size": Vector2(26, 26)}, # Gran Bóveda Oeste
		{"pos": Vector2i(0, 2), "type": RoomType.UPPER_TERRACE, "h": 10.0, "size": Vector2(24, 24)},
		{"pos": Vector2i(0, 4), "type": RoomType.UPPER_TERRACE, "h": 10.0, "size": Vector2(24, 24)},

		# Rampa Este hacia Nivel 1 (Y = 10.0)
		{"pos": Vector2i(5, 3), "type": RoomType.CORRIDOR, "h": 5.0, "size": Vector2(12, 12)}, # Tramo inclinado 0->10
		{"pos": Vector2i(6, 3), "type": RoomType.TREASURE_VAULT, "h": 10.0, "size": Vector2(26, 26)}, # Gran Bóveda Este
		{"pos": Vector2i(6, 2), "type": RoomType.UPPER_TERRACE, "h": 10.0, "size": Vector2(24, 24)},

		# Rampa Sur hacia Nivel 1 (Y = 10.0)
		{"pos": Vector2i(3, 5), "type": RoomType.CORRIDOR, "h": 5.0, "size": Vector2(12, 12)},
		{"pos": Vector2i(3, 6), "type": RoomType.UPPER_TERRACE, "h": 10.0, "size": Vector2(26, 26)},

		# Conexiones hacia Nivel 2 (Y = 22.0) — La Cúspide del Santuario Demoníaco
		{"pos": Vector2i(6, 4), "type": RoomType.CORRIDOR, "h": 16.0, "size": Vector2(12, 12)}, # Gran Escalera 10->22
		{"pos": Vector2i(6, 5), "type": RoomType.CORRIDOR, "h": 19.0, "size": Vector2(12, 12)},
		{"pos": Vector2i(6, 6), "type": RoomType.DEMONIC_SHRINE, "h": 22.0, "size": Vector2(30, 30)}, # Trono del Abismo

		{"pos": Vector2i(0, 5), "type": RoomType.CORRIDOR, "h": 16.0, "size": Vector2(12, 12)}, # Gran Escalera Oeste 10->22
		{"pos": Vector2i(0, 6), "type": RoomType.DEMONIC_SHRINE, "h": 22.0, "size": Vector2(28, 28)}, # Santuario del Vacío
		{"pos": Vector2i(1, 6), "type": RoomType.CORRIDOR, "h": 22.0, "size": Vector2(12, 12)},
		{"pos": Vector2i(5, 6), "type": RoomType.CORRIDOR, "h": 22.0, "size": Vector2(12, 12)},
	]

	for entry in plan:
		var cell = DungeonCell.new()
		cell.grid_pos = entry["pos"]
		cell.room_type = entry["type"]
		cell.floor_height = entry["h"]
		cell.room_size = entry["size"]
		var wx = (cell.grid_pos.x - 3) * CELL_SIZE
		var wz = (cell.grid_pos.y - 3) * CELL_SIZE
		cell.world_center = Vector3(wx, cell.floor_height, wz)
		cell.active = true
		_grid[cell.grid_pos] = cell

	# Enlazar conexiones adyacentes ortogonales
	for pos in _grid:
		var cell: DungeonCell = _grid[pos]
		var neighbors = [pos + Vector2i.UP, pos + Vector2i.DOWN, pos + Vector2i.LEFT, pos + Vector2i.RIGHT]
		for n_pos in neighbors:
			if _grid.has(n_pos):
				if not n_pos in cell.connections:
					cell.connections.append(n_pos)

# ------------------------------------------------------------------------------
# 2. CONSTRUCCIÓN GEOMÉTRICA MONUMENTAL (Bóvedas, Arcos, Muros y Rampas)
# ------------------------------------------------------------------------------
func _construir_geometria_mazmorra() -> void:
	for pos in _grid:
		var cell: DungeonCell = _grid[pos]
		_construir_sala(cell)

	# Construir pasillos, arcos y monumentales escaleras
	var processed_pairs: Dictionary = {}
	for pos in _grid:
		var cell: DungeonCell = _grid[pos]
		for n_pos in cell.connections:
			var pair_key = "%s_%s" % [pos, n_pos] if pos < n_pos else "%s_%s" % [n_pos, pos]
			if not processed_pairs.has(pair_key):
				processed_pairs[pair_key] = true
				_construir_conexion(cell, _grid[n_pos])

func _construir_sala(cell: DungeonCell) -> void:
	var floor_node = StaticBody3D.new()
	floor_node.name = "Room_%d_%d" % [cell.grid_pos.x, cell.grid_pos.y]
	floor_node.position = cell.world_center

	var sx = cell.room_size.x
	var sz = cell.room_size.y

	# 1. Suelo de piedra de la sala con base sólida
	_crear_bloque(floor_node, Vector3(0, -0.4, 0), Vector3(sx, 0.8, sz), _mat_stone)

	# Registrar zona de piso plano para consultas de altura
	var half_s = cell.room_size * 0.5
	var r = Rect2(cell.world_center.x - half_s.x, cell.world_center.z - half_s.y, sx, sz)
	_floor_zones.append({
		"rect": r,
		"h1": cell.floor_height,
		"h2": cell.floor_height,
		"is_stair": false,
		"axis": "NONE",
		"c1_coord": 0.0,
		"c2_coord": 0.0
	})

	# 2. Muros perimetrales colosales de 18m con vanos de arcada ojival
	var half_x = sx * 0.5
	var half_z = sz * 0.5

	# Norte (Z -)
	var has_n = cell.connections.has(cell.grid_pos + Vector2i.UP)
	_construir_muro_con_arcada(floor_node, Vector3(0, WALL_HEIGHT * 0.5, -half_z), sx, true, has_n)

	# Sur (Z +)
	var has_s = cell.connections.has(cell.grid_pos + Vector2i.DOWN)
	_construir_muro_con_arcada(floor_node, Vector3(0, WALL_HEIGHT * 0.5, half_z), sx, true, has_s)

	# Oeste (X -)
	var has_w = cell.connections.has(cell.grid_pos + Vector2i.LEFT)
	_construir_muro_con_arcada(floor_node, Vector3(-half_x, WALL_HEIGHT * 0.5, 0), sz, false, has_w)

	# Este (X +)
	var has_e = cell.connections.has(cell.grid_pos + Vector2i.RIGHT)
	_construir_muro_con_arcada(floor_node, Vector3(half_x, WALL_HEIGHT * 0.5, 0), sz, false, has_e)

	# 3. Cornisas superiores y contrafuertes altos para acentuar la monumentalidad
	_construir_cornisas_altas(floor_node, sx, sz)

	_nav_region.add_child(floor_node)

func _construir_muro_con_arcada(parent: Node3D, pos: Vector3, length: float, is_horizontal: bool, has_door: bool) -> void:
	if not has_door:
		# Muro continuo colosal de 18m
		var size = Vector3(length, WALL_HEIGHT, WALL_THICKNESS) if is_horizontal else Vector3(WALL_THICKNESS, WALL_HEIGHT, length)
		_crear_bloque(parent, pos, size, _mat_dark_stone)
		# Relieve decorativo en el medio para romper la monotonía del muro alto
		var band_y = pos.y + WALL_HEIGHT * 0.15
		var band_size = Vector3(length, 0.8, WALL_THICKNESS + 0.3) if is_horizontal else Vector3(WALL_THICKNESS + 0.3, 0.8, length)
		_crear_bloque(parent, Vector3(pos.x, band_y, pos.z), band_size, _mat_stone)
	else:
		# Muro con arcada gótica de paso: jambas laterales + dintel ojival alto
		var side_len = (length - DOOR_WIDTH) * 0.5
		var offset = (DOOR_WIDTH + side_len) * 0.5
		var arch_top_h = WALL_HEIGHT - DOOR_HEIGHT # Altura del muro por encima del vano de la puerta

		if is_horizontal:
			# Jambas laterales (18m de alto)
			_crear_bloque(parent, pos + Vector3(-offset, 0, 0), Vector3(side_len, WALL_HEIGHT, WALL_THICKNESS), _mat_dark_stone)
			_crear_bloque(parent, pos + Vector3(offset, 0, 0), Vector3(side_len, WALL_HEIGHT, WALL_THICKNESS), _mat_dark_stone)
			# Gran tímpano / dintel superior
			var arch_y = DOOR_HEIGHT + arch_top_h * 0.5
			_crear_bloque(parent, pos + Vector3(0, arch_y - WALL_HEIGHT * 0.5, 0), Vector3(DOOR_WIDTH, arch_top_h, WALL_THICKNESS), _mat_stone)
			# Molduras de arquivolta a los lados de la puerta
			_crear_bloque(parent, pos + Vector3(-DOOR_WIDTH * 0.5, DOOR_HEIGHT * 0.5 - WALL_HEIGHT * 0.5, 0), Vector3(0.6, DOOR_HEIGHT, WALL_THICKNESS + 0.2), _mat_gold_trim)
			_crear_bloque(parent, pos + Vector3(DOOR_WIDTH * 0.5, DOOR_HEIGHT * 0.5 - WALL_HEIGHT * 0.5, 0), Vector3(0.6, DOOR_HEIGHT, WALL_THICKNESS + 0.2), _mat_gold_trim)
		else:
			_crear_bloque(parent, pos + Vector3(0, 0, -offset), Vector3(WALL_THICKNESS, WALL_HEIGHT, side_len), _mat_dark_stone)
			_crear_bloque(parent, pos + Vector3(0, 0, offset), Vector3(WALL_THICKNESS, WALL_HEIGHT, side_len), _mat_dark_stone)
			var arch_y = DOOR_HEIGHT + arch_top_h * 0.5
			_crear_bloque(parent, pos + Vector3(0, arch_y - WALL_HEIGHT * 0.5, 0), Vector3(WALL_THICKNESS, arch_top_h, DOOR_WIDTH), _mat_stone)
			_crear_bloque(parent, pos + Vector3(0, DOOR_HEIGHT * 0.5 - WALL_HEIGHT * 0.5, -DOOR_WIDTH * 0.5), Vector3(WALL_THICKNESS + 0.2, DOOR_HEIGHT, 0.6), _mat_gold_trim)
			_crear_bloque(parent, pos + Vector3(0, DOOR_HEIGHT * 0.5 - WALL_HEIGHT * 0.5, DOOR_WIDTH * 0.5), Vector3(WALL_THICKNESS + 0.2, DOOR_HEIGHT, 0.6), _mat_gold_trim)

func _construir_cornisas_altas(parent: Node3D, sx: float, sz: float) -> void:
	var top_y = WALL_HEIGHT - 0.4
	# Viga perimetral superior que enmarca el techo ausente como una catedral en ruinas
	_crear_bloque(parent, Vector3(0, top_y, -sz * 0.5), Vector3(sx + 0.8, 0.8, WALL_THICKNESS + 0.4), _mat_stone)
	_crear_bloque(parent, Vector3(0, top_y, sz * 0.5), Vector3(sx + 0.8, 0.8, WALL_THICKNESS + 0.4), _mat_stone)
	_crear_bloque(parent, Vector3(-sx * 0.5, top_y, 0), Vector3(WALL_THICKNESS + 0.4, 0.8, sz + 0.8), _mat_stone)
	_crear_bloque(parent, Vector3(sx * 0.5, top_y, 0), Vector3(WALL_THICKNESS + 0.4, 0.8, sz + 0.8), _mat_stone)

func _construir_conexion(c1: DungeonCell, c2: DungeonCell) -> void:
	var con_node = StaticBody3D.new()
	con_node.name = "Con_%d_%d_to_%d_%d" % [c1.grid_pos.x, c1.grid_pos.y, c2.grid_pos.x, c2.grid_pos.y]

	var mid_x = (c1.world_center.x + c2.world_center.x) * 0.5
	var mid_z = (c1.world_center.z + c2.world_center.z) * 0.5
	var dh = c2.floor_height - c1.floor_height
	var is_horizontal = c1.grid_pos.y == c2.grid_pos.y

	var dist = c1.world_center.distance_to(c2.world_center)
	var corridor_len = dist - (c1.room_size.x * 0.5 + c2.room_size.x * 0.5)
	corridor_len = maxf(corridor_len + 1.2, 8.0)

	if absf(dh) < 0.1:
		# 1. Pasillo monumental al mismo nivel
		var base_y = c1.floor_height
		con_node.position = Vector3(mid_x, base_y, mid_z)
		var c_size = Vector3(corridor_len, 0.8, CORRIDOR_WIDTH) if is_horizontal else Vector3(CORRIDOR_WIDTH, 0.8, corridor_len)
		_crear_bloque(con_node, Vector3(0, -0.4, 0), c_size, _mat_stone)

		# Paredes colosales de 18m a los lados del pasillo
		if is_horizontal:
			_crear_bloque(con_node, Vector3(0, WALL_HEIGHT * 0.5, -CORRIDOR_WIDTH * 0.5), Vector3(corridor_len, WALL_HEIGHT, WALL_THICKNESS), _mat_dark_stone)
			_crear_bloque(con_node, Vector3(0, WALL_HEIGHT * 0.5, CORRIDOR_WIDTH * 0.5), Vector3(corridor_len, WALL_HEIGHT, WALL_THICKNESS), _mat_dark_stone)
			# Arcos ojivales transversales en el techo del pasillo cada 8m
			_crear_viga_transversal(con_node, Vector3(0, WALL_HEIGHT - 2.0, 0), Vector3(1.2, 1.6, CORRIDOR_WIDTH))
		else:
			_crear_bloque(con_node, Vector3(-CORRIDOR_WIDTH * 0.5, WALL_HEIGHT * 0.5, 0), Vector3(WALL_THICKNESS, WALL_HEIGHT, corridor_len), _mat_dark_stone)
			_crear_bloque(con_node, Vector3(CORRIDOR_WIDTH * 0.5, WALL_HEIGHT * 0.5, 0), Vector3(WALL_THICKNESS, WALL_HEIGHT, corridor_len), _mat_dark_stone)
			_crear_viga_transversal(con_node, Vector3(0, WALL_HEIGHT - 2.0, 0), Vector3(CORRIDOR_WIDTH, 1.6, 1.2))

		var half_w = CORRIDOR_WIDTH * 0.5
		var half_l = corridor_len * 0.5
		var r = Rect2(mid_x - (half_l if is_horizontal else half_w), mid_z - (half_w if is_horizontal else half_l), corridor_len if is_horizontal else CORRIDOR_WIDTH, CORRIDOR_WIDTH if is_horizontal else corridor_len)
		_floor_zones.append({"rect": r, "h1": base_y, "h2": base_y, "is_stair": false, "axis": "NONE", "c1_coord": 0.0, "c2_coord": 0.0})
	else:
		# 2. Gran Escalera Monumental entre niveles de diferente altura
		var lower_y = minf(c1.floor_height, c2.floor_height)
		var higher_y = maxf(c1.floor_height, c2.floor_height)
		var avg_y = (lower_y + higher_y) * 0.5
		con_node.position = Vector3(mid_x, avg_y, mid_z)

		# Rampa física invisible de BoxShape3D para paso sedoso
		var angle = atan2(absf(dh), corridor_len)
		var ramp_len = sqrt(corridor_len * corridor_len + dh * dh)
		var r_shape = BoxShape3D.new()
		r_shape.size = Vector3(ramp_len, 0.6, CORRIDOR_WIDTH) if is_horizontal else Vector3(CORRIDOR_WIDTH, 0.6, ramp_len)
		var r_col = CollisionShape3D.new()
		r_col.shape = r_shape
		if is_horizontal:
			r_col.rotation.z = angle * (1.0 if (c2.world_center.x > c1.world_center.x) == (c2.floor_height > c1.floor_height) else -1.0)
		else:
			r_col.rotation.x = angle * (1.0 if (c2.world_center.z > c1.world_center.z) == (c2.floor_height > c1.floor_height) else -1.0)
		con_node.add_child(r_col)

		# Escalones visuales monumentales de piedra
		var steps_count = int(round(absf(dh) / 0.45))
		steps_count = clampi(steps_count, 10, 32)
		var step_h = absf(dh) / steps_count
		var step_l = corridor_len / steps_count

		for s in range(steps_count):
			var y_off = -absf(dh) * 0.5 + (s + 1) * step_h - step_h * 0.5
			if (c1.floor_height > c2.floor_height):
				y_off = absf(dh) * 0.5 - (s + 1) * step_h + step_h * 0.5

			var x_off = 0.0
			var z_off = 0.0
			if is_horizontal:
				x_off = -corridor_len * 0.5 + (s + 0.5) * step_l
				if c1.world_center.x > c2.world_center.x:
					x_off *= -1.0
				_crear_bloque(con_node, Vector3(x_off, y_off, 0), Vector3(step_l + 0.1, step_h + 0.1, CORRIDOR_WIDTH), _mat_stone)
			else:
				z_off = -corridor_len * 0.5 + (s + 0.5) * step_l
				if c1.world_center.z > c2.world_center.z:
					z_off *= -1.0
				_crear_bloque(con_node, Vector3(0, y_off, z_off), Vector3(CORRIDOR_WIDTH, step_h + 0.1, step_l + 0.1), _mat_stone)

		# Muros de contención colosales laterales para la gran escalera
		var wall_h_stair = WALL_HEIGHT + absf(dh) * 1.2
		if is_horizontal:
			_crear_bloque(con_node, Vector3(0, wall_h_stair * 0.25, -CORRIDOR_WIDTH * 0.5), Vector3(corridor_len, wall_h_stair, WALL_THICKNESS), _mat_dark_stone)
			_crear_bloque(con_node, Vector3(0, wall_h_stair * 0.25, CORRIDOR_WIDTH * 0.5), Vector3(corridor_len, wall_h_stair, WALL_THICKNESS), _mat_dark_stone)
		else:
			_crear_bloque(con_node, Vector3(-CORRIDOR_WIDTH * 0.5, wall_h_stair * 0.25, 0), Vector3(WALL_THICKNESS, wall_h_stair, corridor_len), _mat_dark_stone)
			_crear_bloque(con_node, Vector3(CORRIDOR_WIDTH * 0.5, wall_h_stair * 0.25, 0), Vector3(WALL_THICKNESS, wall_h_stair, corridor_len), _mat_dark_stone)

		var half_w = CORRIDOR_WIDTH * 0.5
		var half_l = corridor_len * 0.5
		var r = Rect2(mid_x - (half_l if is_horizontal else half_w), mid_z - (half_w if is_horizontal else half_l), corridor_len if is_horizontal else CORRIDOR_WIDTH, CORRIDOR_WIDTH if is_horizontal else corridor_len)
		_floor_zones.append({
			"rect": r,
			"h1": c1.floor_height,
			"h2": c2.floor_height,
			"is_stair": true,
			"axis": "X" if is_horizontal else "Z",
			"c1_coord": c1.world_center.x if is_horizontal else c1.world_center.z,
			"c2_coord": c2.world_center.x if is_horizontal else c2.world_center.z
		})

	_nav_region.add_child(con_node)

func _crear_viga_transversal(parent: Node3D, pos: Vector3, size: Vector3) -> void:
	var mesh_inst = MeshInstance3D.new()
	var box = BoxMesh.new()
	box.size = size
	mesh_inst.mesh = box
	mesh_inst.position = pos
	mesh_inst.material_override = _mat_stone
	parent.add_child(mesh_inst)

func _crear_bloque(parent: Node3D, pos: Vector3, size: Vector3, mat: Material) -> MeshInstance3D:
	var col = CollisionShape3D.new()
	var box_shape = BoxShape3D.new()
	box_shape.size = size
	col.shape = box_shape
	col.position = pos
	parent.add_child(col)

	var mesh_inst = MeshInstance3D.new()
	var box_mesh = BoxMesh.new()
	box_mesh.size = size
	mesh_inst.mesh = box_mesh
	mesh_inst.position = pos
	mesh_inst.material_override = mat
	parent.add_child(mesh_inst)
	return mesh_inst

# ------------------------------------------------------------------------------
# 3. ELEMENTOS MONUMENTALES (Columnas de 18m, Obeliscos, Fosos y Templos)
# ------------------------------------------------------------------------------
func _poblar_elementos_mazmorra() -> void:
	for pos in _grid:
		var cell: DungeonCell = _grid[pos]
		match cell.room_type:
			RoomType.SPAWN_HALL:
				_decorar_spawn_hall(cell)
			RoomType.TREASURE_VAULT:
				_decorar_treasure_vault(cell)
			RoomType.DEMONIC_SHRINE:
				_decorar_demonic_shrine(cell)
			RoomType.CRYPT_PILLARS:
				_decorar_crypt(cell)
			RoomType.LAVA_PIT:
				_decorar_lava_pit(cell)
			RoomType.UPPER_TERRACE:
				_decorar_terrace(cell)

func _decorar_spawn_hall(cell: DungeonCell) -> void:
	# "The Great Cathedral Nave" — Doble columnata de 8 columnas colosales de 18m
	var offsets = [
		Vector3(-8.0, 0, -9.0), Vector3(8.0, 0, -9.0),
		Vector3(-8.0, 0, -3.0), Vector3(8.0, 0, -3.0),
		Vector3(-8.0, 0, 3.0),  Vector3(8.0, 0, 3.0),
		Vector3(-8.0, 0, 9.0),  Vector3(8.0, 0, 9.0)
	]
	for off in offsets:
		_crear_columna_gotica(cell.world_center + off, cell.floor_height, Color(1.0, 0.65, 0.22), true)

	# Gran sello rúnico ceremonial en el piso central
	var dais_pos = cell.world_center + Vector3(0, 0.05, 0)
	_crear_bloque(_nav_region, dais_pos, Vector3(6.0, 0.1, 6.0), _mat_obsidian)

func _decorar_treasure_vault(cell: DungeonCell) -> void:
	# Pedestal elevado con escalón y cofre legendario
	var dais_pos = cell.world_center + Vector3(0, 0.4, 0)
	_crear_bloque(_nav_region, dais_pos, Vector3(8.0, 0.8, 8.0), _mat_stone)
	_crear_bloque(_nav_region, dais_pos + Vector3(0, 0.5, 0), Vector3(5.0, 0.4, 5.0), _mat_gold_trim)

	# Cofre demoníaco central
	_instanciar_cofre(cell.world_center + Vector3(0, 0.95, 0), "demonic")
	if randf() > 0.4:
		_instanciar_cofre(cell.world_center + Vector3(2.5, 0.95, 0), "iron")

	# 4 Columnas colosales con fuego azul espectral
	var offsets = [Vector3(-9.0, 0, -9.0), Vector3(9.0, 0, -9.0), Vector3(-9.0, 0, 9.0), Vector3(9.0, 0, 9.0)]
	for off in offsets:
		_crear_columna_gotica(cell.world_center + off, cell.floor_height, Color(0.2, 0.68, 1.0), true)

func _decorar_demonic_shrine(cell: DungeonCell) -> void:
	# Santuario en la cúspide (Y = 22.0) — El Trono del Abismo
	# 1. Monolito / Obelisco de Obsidiana Colosal de 14 metros de altura
	var monolith_pos = cell.world_center + Vector3(0, 7.0, 0)
	var monolith = _crear_bloque(_nav_region, monolith_pos, Vector3(3.6, 14.0, 3.6), _mat_obsidian)

	# Núcleo de energía demoníaca brillante en la punta del obelisco
	var core_pos = cell.world_center + Vector3(0, 15.0, 0)
	var core_mesh = MeshInstance3D.new()
	var cbox = BoxMesh.new()
	cbox.size = Vector3(1.8, 2.5, 1.8)
	core_mesh.mesh = cbox
	core_mesh.position = core_pos
	var cmat = StandardMaterial3D.new()
	cmat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	cmat.albedo_color = Color(0.9, 0.15, 0.85)
	cmat.emission_enabled = true
	cmat.emission = Color(0.95, 0.2, 0.9)
	cmat.emission_energy_multiplier = 5.0
	core_mesh.material_override = cmat
	_nav_region.add_child(core_mesh)

	var shrine_light = OmniLight3D.new()
	shrine_light.light_color = Color(0.9, 0.1, 0.8)
	shrine_light.light_energy = 5.0
	shrine_light.omni_range = 28.0
	shrine_light.position = core_pos
	shrine_light.shadow_enabled = false
	_nav_region.add_child(shrine_light)

	# 2. Altar ceremonial escalonado y cofre
	var altar_pos = cell.world_center + Vector3(0, 0.5, 5.0)
	_crear_bloque(_nav_region, altar_pos, Vector3(6.0, 1.0, 4.0), _mat_stone)
	_instanciar_cofre(altar_pos + Vector3(0, 0.65, 0), "demonic")

	# 3. Anillo de 8 columnas ceremoniales colosales de 18m con fuego amatista
	for i in 8:
		var angle = i * TAU / 8.0
		var cpos = cell.world_center + Vector3(cos(angle) * 11.0, 0, sin(angle) * 11.0)
		_crear_columna_gotica(cpos, cell.floor_height, Color(0.85, 0.15, 0.9), false)

func _decorar_crypt(cell: DungeonCell) -> void:
	# Cripta de los Titanes con 6 columnas ciclópeas de 18m
	var offsets = [
		Vector3(-6.0, 0, -6.0), Vector3(0.0, 0, -6.0), Vector3(6.0, 0, -6.0),
		Vector3(-6.0, 0, 6.0),  Vector3(0.0, 0, 6.0),  Vector3(6.0, 0, 6.0)
	]
	for off in offsets:
		_crear_columna_gotica(cell.world_center + off, cell.floor_height, Color(1.0, 0.5, 0.12), true)

	if randf() > 0.35:
		_instanciar_cofre(cell.world_center + Vector3(-9.0, 0.1, -9.0), "iron")

func _decorar_lava_pit(cell: DungeonCell) -> void:
	# Foso abisal de lava con puente de piedra monumental
	var hazard_script = load("res://scripts/map_hazard.gd")
	if hazard_script:
		var hazard = Area3D.new()
		hazard.name = "LavaHazard"
		hazard.set_script(hazard_script)
		hazard.position = cell.world_center + Vector3(0, 0.05, 0)
		hazard.hazard_type = "lava"
		hazard.damage_per_second = 20.0
		hazard.slow_factor = 0.45

		var col = CollisionShape3D.new()
		var box_shape = BoxShape3D.new()
		box_shape.size = Vector3(26.0, 0.6, 14.0)
		col.shape = box_shape
		hazard.add_child(col)

		var mesh_inst = MeshInstance3D.new()
		var box_mesh = BoxMesh.new()
		box_mesh.size = Vector3(26.0, 0.1, 14.0)
		mesh_inst.mesh = box_mesh
		var lava_mat = load("res://materials/lava_material.tres")
		if lava_mat:
			mesh_inst.material_override = lava_mat
		hazard.add_child(mesh_inst)

		# Resplandor de magma ardiente
		var lava_light = OmniLight3D.new()
		lava_light.light_color = Color(1.0, 0.35, 0.05)
		lava_light.light_energy = 4.5
		lava_light.omni_range = 24.0
		lava_light.shadow_enabled = false
		hazard.add_child(lava_light)

		add_child(hazard)

	# Puente de piedra central (7m de ancho) cruzando el magma de Norte a Sur
	var bridge_pos = cell.world_center + Vector3(0, 0.3, 0)
	_crear_bloque(_nav_region, bridge_pos, Vector3(7.0, 0.6, 26.0), _mat_stone)

	# Parapetos / pretiles laterales del puente
	_crear_bloque(_nav_region, bridge_pos + Vector3(-3.4, 0.6, 0), Vector3(0.5, 0.8, 26.0), _mat_dark_stone)
	_crear_bloque(_nav_region, bridge_pos + Vector3(3.4, 0.6, 0), Vector3(0.5, 0.8, 26.0), _mat_dark_stone)

	# 4 Columnas colosales que flanquean las entradas del puente
	_crear_columna_gotica(cell.world_center + Vector3(-5.5, 0, -9.0), cell.floor_height, Color(1.0, 0.35, 0.05), false)
	_crear_columna_gotica(cell.world_center + Vector3(5.5, 0, -9.0), cell.floor_height, Color(1.0, 0.35, 0.05), false)
	_crear_columna_gotica(cell.world_center + Vector3(-5.5, 0, 9.0), cell.floor_height, Color(1.0, 0.35, 0.05), false)
	_crear_columna_gotica(cell.world_center + Vector3(5.5, 0, 9.0), cell.floor_height, Color(1.0, 0.35, 0.05), false)

func _decorar_terrace(cell: DungeonCell) -> void:
	# Terraza de guardia elevada con parapeto almenado
	_crear_columna_gotica(cell.world_center + Vector3(-8.0, 0, -8.0), cell.floor_height, Color(0.85, 0.75, 0.35), true)
	_crear_columna_gotica(cell.world_center + Vector3(8.0, 0, -8.0), cell.floor_height, Color(0.85, 0.75, 0.35), true)
	if randf() > 0.3:
		_instanciar_cofre(cell.world_center + Vector3(0, 0.1, 7.0), "wood")

# ------------------------------------------------------------------------------
# 4. COLUMNAS Y ARCOS GÓTICOS COLOSALES (18m DE ALTURA)
# ------------------------------------------------------------------------------
func _crear_columna_gotica(pos: Vector3, base_y: float, flame_color: Color, with_arch: bool) -> void:
	var pillar = StaticBody3D.new()
	pillar.position = Vector3(pos.x, base_y, pos.z)

	# 1. Base / Plinto escalonado de piedra (2.6m x 1.4m x 2.6m)
	var plinth_shape = BoxShape3D.new()
	plinth_shape.size = Vector3(2.6, 1.4, 2.6)
	var plinth_col = CollisionShape3D.new()
	plinth_col.shape = plinth_shape
	plinth_col.position = Vector3(0, 0.7, 0)
	pillar.add_child(plinth_col)

	var plinth_mesh = MeshInstance3D.new()
	var pbox = BoxMesh.new()
	pbox.size = Vector3(2.6, 1.4, 2.6)
	plinth_mesh.mesh = pbox
	plinth_mesh.position = Vector3(0, 0.7, 0)
	plinth_mesh.material_override = _mat_dark_stone
	pillar.add_child(plinth_mesh)

	# 2. Fuste cilíndrico colosal de 18m de altura
	var col = CollisionShape3D.new()
	var shape = CylinderShape3D.new()
	shape.radius = 1.1
	shape.height = WALL_HEIGHT
	col.shape = shape
	col.position = Vector3(0, WALL_HEIGHT * 0.5, 0)
	pillar.add_child(col)

	var mesh_inst = MeshInstance3D.new()
	var mesh = CylinderMesh.new()
	mesh.top_radius = 1.05
	mesh.bottom_radius = 1.15
	mesh.height = WALL_HEIGHT
	mesh.radial_segments = 12
	mesh_inst.mesh = mesh
	mesh_inst.position = Vector3(0, WALL_HEIGHT * 0.5, 0)
	mesh_inst.material_override = _mat_stone
	pillar.add_child(mesh_inst)

	# 3. Capitel gótico ornamental en la parte superior (Y = 17.5m)
	var cap_mesh = MeshInstance3D.new()
	var cap_box = BoxMesh.new()
	cap_box.size = Vector3(2.8, 1.2, 2.8)
	cap_mesh.mesh = cap_box
	cap_mesh.position = Vector3(0, WALL_HEIGHT - 0.6, 0)
	cap_mesh.material_override = _mat_dark_stone
	pillar.add_child(cap_mesh)

	# Nervios de bóveda de crucería gótica hacia el techo
	if with_arch:
		var arch_arm1 = MeshInstance3D.new()
		var abox = BoxMesh.new()
		abox.size = Vector3(4.0, 0.6, 0.8)
		arch_arm1.mesh = abox
		arch_arm1.position = Vector3(1.5, WALL_HEIGHT - 0.8, 0)
		arch_arm1.rotation.z = deg_to_rad(22.0)
		arch_arm1.material_override = _mat_stone
		pillar.add_child(arch_arm1)

		var arch_arm2 = MeshInstance3D.new()
		arch_arm2.mesh = abox
		arch_arm2.position = Vector3(-1.5, WALL_HEIGHT - 0.8, 0)
		arch_arm2.rotation.z = deg_to_rad(-22.0)
		arch_arm2.material_override = _mat_stone
		pillar.add_child(arch_arm2)

	# 4. Gran pebetero / brasero gótico de hierro forjado con llama eterna (a 2.2m del suelo)
	var brazier_mount = MeshInstance3D.new()
	var b_box = BoxMesh.new()
	b_box.size = Vector3(0.5, 0.8, 0.5)
	brazier_mount.mesh = b_box
	brazier_mount.position = Vector3(0, 2.2, 1.25)
	brazier_mount.material_override = _mat_obsidian
	pillar.add_child(brazier_mount)

	var flame_mesh = MeshInstance3D.new()
	var fbox = BoxMesh.new()
	fbox.size = Vector3(0.45, 0.6, 0.45)
	flame_mesh.mesh = fbox
	flame_mesh.position = Vector3(0, 2.8, 1.25)
	var fmat = StandardMaterial3D.new()
	fmat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	fmat.albedo_color = flame_color
	fmat.emission_enabled = true
	fmat.emission = flame_color
	fmat.emission_energy_multiplier = 4.5
	flame_mesh.material_override = fmat
	pillar.add_child(flame_mesh)

	# Luz omnidireccional optimizada para ambientar la inmensidad
	var light = OmniLight3D.new()
	light.light_color = flame_color
	light.light_energy = 3.6
	light.omni_range = 18.0
	light.shadow_enabled = false
	light.position = Vector3(0, 3.0, 1.4)
	pillar.add_child(light)

	_nav_region.add_child(pillar)

func _instanciar_cofre(pos: Vector3, type: String) -> void:
	if _chest_script == null:
		return
	var chest = StaticBody3D.new()
	chest.set_script(_chest_script)
	chest.chest_type = type
	chest.position = pos
	_nav_region.add_child(chest)

# ------------------------------------------------------------------------------
# 5. CONSULTA DE ALTURA Y SPAWNING
# ------------------------------------------------------------------------------
func get_floor_height_at(world_x: float, world_z: float) -> float:
	var pt = Vector2(world_x, world_z)
	for zone in _floor_zones:
		var r: Rect2 = zone["rect"]
		if r.has_point(pt):
			if not zone["is_stair"]:
				return zone["h1"]
			else:
				var c1 = zone["c1_coord"]
				var c2 = zone["c2_coord"]
				var curr = world_x if zone["axis"] == "X" else world_z
				var denom = c2 - c1
				if absf(denom) < 0.001:
					return zone["h1"]
				var t = clampf((curr - c1) / denom, 0.0, 1.0)
				return lerpf(zone["h1"], zone["h2"], t)

	# Fallback a la celda de grilla 7x7 más cercana (centro en 3,3)
	var gx = int(round(world_x / CELL_SIZE)) + 3
	var gz = int(round(world_z / CELL_SIZE)) + 3
	var cell_pos = Vector2i(clampi(gx, 0, GRID_SIZE - 1), clampi(gz, 0, GRID_SIZE - 1))
	if _grid.has(cell_pos):
		return _grid[cell_pos].floor_height

	return 0.0

func get_random_spawn_point(player_pos: Vector3, min_dist: float, max_dist: float) -> Vector3:
	var valid_cells: Array[DungeonCell] = []
	for pos in _grid:
		var cell: DungeonCell = _grid[pos]
		var d = player_pos.distance_to(cell.world_center)
		if d >= min_dist and d <= max_dist:
			valid_cells.append(cell)

	if valid_cells.is_empty():
		for pos in _grid:
			valid_cells.append(_grid[pos])

	var chosen: DungeonCell = valid_cells[randi() % valid_cells.size()]
	var rx = randf_range(-chosen.room_size.x * 0.38, chosen.room_size.x * 0.38)
	var rz = randf_range(-chosen.room_size.y * 0.38, chosen.room_size.y * 0.38)
	return chosen.world_center + Vector3(rx, 1.0, rz)
