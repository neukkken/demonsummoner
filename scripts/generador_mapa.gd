extends Node3D

const MIN_PILLARS := 10
const MAX_PILLARS := 15
const ARENA_SIZE := 55.0
const PILLAR_SIZE := Vector3(3, 10, 3)
const PILLAR_HEIGHT := 5.0
const MIN_DIST_PILLAR := 6.0
const MIN_DIST_SPAWN := 8.0
const MAX_ATTEMPTS := 50

static var _stone_mat: StandardMaterial3D = null
static var _inited := false

static func _init_mat():
	if _inited:
		return
	_inited = true
	_stone_mat = StandardMaterial3D.new()
	_stone_mat.albedo_color = Color(0.25, 0.22, 0.2)
	_stone_mat.roughness = 0.9

func _ready():
	generar()
	_crear_navmesh()

func _crear_navmesh():
	var terrain_width := 120.0
	var terrain_depth := 120.0
	var nav_height := 0.5
	var cell_size := 4.0
	var half_w := terrain_width * 0.5
	var half_d := terrain_depth * 0.5
	var step := cell_size
	var cols := int(terrain_width / step)
	var rows := int(terrain_depth / step)

	var verts: PackedVector3Array = []
	var tris: PackedInt32Array = []
	for r in range(rows + 1):
		for c in range(cols + 1):
			var x := -half_w + c * step
			var z := -half_d + r * step
			verts.append(Vector3(x, nav_height, z))
	for r in range(rows):
		for c in range(cols):
			var i := r * (cols + 1) + c
			tris.append(i)
			tris.append(i + 1)
			tris.append(i + cols + 1)
			tris.append(i + 1)
			tris.append(i + cols + 2)
			tris.append(i + cols + 1)

	var nav_mesh := NavigationMesh.new()
	nav_mesh.cell_size = cell_size
	nav_mesh.agent_radius = 0.5
	nav_mesh.agent_height = 2.0
	nav_mesh.vertices = verts
	for j in range(0, tris.size(), 3):
		var poly := PackedInt32Array([tris[j], tris[j + 1], tris[j + 2]])
		nav_mesh.add_polygon(poly)

	var nav_region := NavigationRegion3D.new()
	nav_region.name = "NavigationRegion3D"
	nav_region.navigation_mesh = nav_mesh
	get_tree().root.add_child(nav_region)
	print("[NAV] Navigation mesh creado: ", cols * rows * 2, " triangulos")

func generar():
	_init_mat()
	_limpiar()

	var positions: Array[Vector2] = []
	var count := randi_range(MIN_PILLARS, MAX_PILLARS)
	for i in count:
		for attempt in MAX_ATTEMPTS:
			var x := randf_range(-ARENA_SIZE, ARENA_SIZE)
			var z := randf_range(-ARENA_SIZE, ARENA_SIZE)
			var pos := Vector2(x, z)
			if _validar(pos, positions):
				positions.append(pos)
				_instanciar_pilar(x, z)
				break

func _limpiar():
	var pilares = get_node_or_null("../Pilares")
	if pilares:
		for child in pilares.get_children():
			child.queue_free()
	for child in get_children():
		child.queue_free()

func _validar(pos: Vector2, existentes: Array[Vector2]) -> bool:
	if pos.length() < MIN_DIST_SPAWN:
		return false
	for e in existentes:
		if pos.distance_to(e) < MIN_DIST_PILLAR:
			return false
	return true

func _instanciar_pilar(x: float, z: float):
	var pilar = CSGBox3D.new()
	pilar.size = PILLAR_SIZE
	pilar.use_collision = true
	pilar.material = _stone_mat
	pilar.position = Vector3(x, PILLAR_HEIGHT, z)
	add_child(pilar)

	var antorcha = OmniLight3D.new()
	antorcha.light_color = Color(0.73, 0.35, 0.02)
	antorcha.light_energy = 4.0
	antorcha.omni_range = 15.0
	antorcha.position = Vector3(0, PILLAR_HEIGHT * 0.5, 0)
	pilar.add_child(antorcha)

	var obs = NavigationObstacle3D.new()
	obs.radius = 2.0
	obs.height = PILLAR_SIZE.y
	obs.position = Vector3(0, PILLAR_HEIGHT, 0)
	pilar.add_child(obs)
