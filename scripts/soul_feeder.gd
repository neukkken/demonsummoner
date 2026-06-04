extends Node3D

@export var model_path: String = "res://models/Fantasy_Heroes_Free/FBX/Characters/Knight.glb"

var _lifetime = 4.0
var _time_left = 4.0
var _label: Label3D
var _mesh: MeshInstance3D
var _base_y = 0.0
var _anim_time = 0.0
var _player: Node3D
var _enemigos_marcados: Array[Node3D] = []
var _dano_pulso: float = 35.0
var _pulse_interval: float = 0.5
var _pulse_timer: float = 0.0

func _ready():
	_setup_mesh()
	_setup_label()
	_iniciar_festin()
	var despawn = Timer.new()
	despawn.one_shot = true
	despawn.timeout.connect(_on_despawn)
	add_child(despawn)
	despawn.start(_lifetime)

func _setup_mesh():
	var scene = load(model_path)
	if scene:
		var model = scene.instantiate()
		model.name = "Model"
		add_child(model)
		_mesh = model.find_children("*", "MeshInstance3D", true, false)[0] as MeshInstance3D
		model.position.y = -1.0
		model.scale = Vector3(1.3, 1.3, 1.3)
		if _mesh:
			var mat = _mesh.material_override
			if mat == null:
				mat = _mesh.get_surface_override_material(0)
			if mat == null and _mesh.mesh != null:
				mat = _mesh.mesh.surface_get_material(0)
			if mat is BaseMaterial3D:
				mat = mat.duplicate()
				_mesh.material_override = mat
				if not mat.albedo_texture:
					var tex = load("res://models/Fantasy_Heroes_Free/Texture/Texture.png")
					if tex:
						mat.albedo_texture = tex
				mat.albedo_color = Color(0.25, 0.2, 0.25, 1)
	else:
		_mesh = MeshInstance3D.new()
		var body = BoxMesh.new()
		body.size = Vector3(1.2, 1.5, 0.8)
		var bmat = StandardMaterial3D.new()
		bmat.albedo_color = Color(0.25, 0.02, 0.35)
		bmat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		bmat.emission_enabled = true
		bmat.emission = Color(0.5, 0.05, 0.7)
		bmat.emission_energy_multiplier = 3.0
		bmat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		_mesh.mesh = body
		_mesh.material_override = bmat
		add_child(_mesh)

	var maw = MeshInstance3D.new()
	var maw_box = BoxMesh.new()
	maw_box.size = Vector3(0.6, 0.2, 0.4)
	var mmat = StandardMaterial3D.new()
	mmat.albedo_color = Color(0.8, 0.05, 0.08)
	mmat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mmat.emission_enabled = true
	mmat.emission = Color(1.0, 0.08, 0.05)
	mmat.emission_energy_multiplier = 4.0
	maw.mesh = maw_box
	maw.material_override = mmat
	maw.position = Vector3(0, 0.4, 0.45)
	add_child(maw)

	for i in range(8):
		var tentacle = MeshInstance3D.new()
		var tbox = BoxMesh.new()
		var tw = randf_range(0.04, 0.1)
		var th = randf_range(0.3, 0.7)
		tbox.size = Vector3(tw, th, tw)
		var tmat = StandardMaterial3D.new()
		tmat.albedo_color = Color(0.3, 0.03, 0.4, 0.7)
		tmat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		tmat.emission_enabled = true
		tmat.emission = Color(0.5, 0.05, 0.7)
		tmat.emission_energy_multiplier = 2.0
		tmat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		tentacle.mesh = tbox
		tentacle.material_override = tmat
		var a = float(i) / 8.0 * TAU
		var r = 0.5
		tentacle.position = Vector3(cos(a) * r, -0.3 + th * 0.5, sin(a) * r)
		tentacle.set_meta("angle", a)
		tentacle.set_meta("len", th)
		tentacle.set_meta("phase", randf_range(0, TAU))
		add_child(tentacle)

	var glow = MeshInstance3D.new()
	glow.mesh = QuadMesh.new()
	glow.mesh.size = Vector2(3.0, 3.0)
	glow.rotation.x = deg_to_rad(-90)
	glow.position.y = -0.3
	var gmat = StandardMaterial3D.new()
	gmat.albedo_color = Color(0.4, 0.03, 0.6, 0.2)
	gmat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	gmat.emission_enabled = true
	gmat.emission = Color(0.5, 0.05, 0.7)
	gmat.emission_energy_multiplier = 2.0
	gmat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	glow.material_override = gmat
	add_child(glow)

	var light = OmniLight3D.new()
	light.light_color = Color(0.5, 0.05, 0.7)
	light.light_energy = 5.0
	light.omni_range = 20.0
	add_child(light)

	scale = Vector3.ZERO
	var tween = create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	tween.tween_property(self, "scale", Vector3.ONE, 0.5)

func _setup_label():
	_label = Label3D.new()
	_label.text = "15"
	_label.font_size = 28
	_label.outline_size = 3
	_label.modulate = Color(0.6, 0.15, 0.9)
	_label.outline_modulate = Color(0.1, 0.0, 0.15, 0.9)
	_label.position = Vector3(0, 3.0, 0)
	_label.no_depth_test = true
	add_child(_label)

func _iniciar_festin():
	if _player == null or not is_instance_valid(_player) or not _player.is_inside_tree():
		return
	_player.restore_mana(_player.max_mana * 0.3)
	_player.call("add_shake", 1.0)

	var efecto = preload("res://scripts/efecto_ritual.gd").new()
	add_child(efecto)
	efecto.iniciar()

	_spawn_howl_ring()

	var enemigos = get_tree().get_nodes_in_group("enemies")
	for e in enemigos:
		var e3d = e as Node3D
		if e3d == null or not is_instance_valid(e3d) or not e3d.is_inside_tree():
			continue
		_spawn_ground_crack(e3d)
		_spawn_energy_pillar(e3d)
		_spawn_rising_spires(e3d)
		if e3d.has_method("paralizar"):
			e3d.paralizar(3.0)
		_enemigos_marcados.append(e3d)

	_spawn_sky_beam()

func _spawn_howl_ring():
	var ring = MeshInstance3D.new()
	ring.mesh = QuadMesh.new()
	ring.mesh.size = Vector2(0.1, 0.1)
	ring.rotation.x = deg_to_rad(-90)
	ring.position.y = 0.05
	var rmat = StandardMaterial3D.new()
	rmat.albedo_color = Color(0.6, 0.05, 0.8, 0.5)
	rmat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	rmat.emission_enabled = true
	rmat.emission = Color(0.7, 0.08, 0.9)
	rmat.emission_energy_multiplier = 4.0
	rmat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	ring.material_override = rmat
	add_child(ring)
	var rt = ring.create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_SINE)
	rt.tween_property(ring, "mesh:size", Vector2(50.0, 50.0), 0.8)
	rt.parallel().tween_property(rmat, "albedo_color", Color(0.6, 0.05, 0.8, 0.0), 0.8)
	rt.tween_callback(ring.queue_free)

func _spawn_sky_beam():
	var beam = MeshInstance3D.new()
	beam.mesh = CylinderMesh.new()
	beam.mesh.top_radius = 5.0
	beam.mesh.bottom_radius = 8.0
	beam.mesh.height = 50.0
	beam.mesh.radial_segments = 6
	beam.position.y = 25.0
	var bmat = StandardMaterial3D.new()
	bmat.albedo_color = Color(0.5, 0.05, 0.7, 0.15)
	bmat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	bmat.emission_enabled = true
	bmat.emission = Color(0.6, 0.08, 0.8)
	bmat.emission_energy_multiplier = 2.0
	bmat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	beam.material_override = bmat
	add_child(beam)
	var bt = beam.create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_SINE)
	bt.tween_property(bmat, "emission_energy_multiplier", 0.0, 3.0)
	bt.parallel().tween_property(bmat, "albedo_color", Color(0.5, 0.05, 0.7, 0.0), 3.0)

func _spawn_ground_crack(enemigo: Node3D):
	var pos = enemigo.global_position
	var root = Node3D.new()
	root.position = pos
	get_tree().root.add_child(root)
	root.set_meta("festin_root", true)

	for i in range(3):
		var crack = MeshInstance3D.new()
		crack.mesh = QuadMesh.new()
		var s = 2.0 + i * 0.8
		crack.mesh.size = Vector2(s, s)
		crack.rotation.x = deg_to_rad(-90)
		crack.position.y = 0.03 + i * 0.01
		var cmat = StandardMaterial3D.new()
		cmat.albedo_color = Color(0.3 - i * 0.05, 0.01, 0.01, 0.8 - i * 0.15)
		cmat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		cmat.emission_enabled = true
		cmat.emission = Color(0.8 - i * 0.15, 0.03, 0.02)
		cmat.emission_energy_multiplier = 3.0 - i * 0.5
		cmat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		crack.material_override = cmat
		crack.scale = Vector3.ZERO
		root.add_child(crack)
		var ct = crack.create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
		ct.tween_property(crack, "scale", Vector3.ONE, 0.3 + i * 0.1)

func _spawn_energy_pillar(enemigo: Node3D):
	var pos = enemigo.global_position
	var root = Node3D.new()
	root.position = pos
	get_tree().root.add_child(root)
	root.set_meta("festin_root", true)

	var pillar = MeshInstance3D.new()
	pillar.mesh = CylinderMesh.new()
	pillar.mesh.top_radius = 0.1
	pillar.mesh.bottom_radius = 0.4
	pillar.mesh.height = 6.0
	pillar.mesh.radial_segments = 4
	pillar.position.y = 3.0
	var pmat = StandardMaterial3D.new()
	pmat.albedo_color = Color(0.6, 0.05, 0.8, 0.2)
	pmat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	pmat.emission_enabled = true
	pmat.emission = Color(0.7, 0.08, 0.9)
	pmat.emission_energy_multiplier = 2.0
	pmat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	pillar.material_override = pmat
	pillar.scale = Vector3.ONE
	root.add_child(pillar)
	var pt = pillar.create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_SINE)
	pt.tween_property(pmat, "emission_energy_multiplier", 0.0, 3.0)
	pt.parallel().tween_property(pmat, "albedo_color", Color(0.6, 0.05, 0.8, 0.0), 3.0)

func _spawn_rising_spires(enemigo: Node3D):
	var pos = enemigo.global_position
	var root = Node3D.new()
	root.position = pos
	get_tree().root.add_child(root)
	root.set_meta("festin_root", true)

	for i in range(10):
		var spire = MeshInstance3D.new()
		var sbox = BoxMesh.new()
		var sw = randf_range(0.06, 0.15)
		var sh = randf_range(2.0, 4.0)
		sbox.size = Vector3(sw, sh, sw)
		var smat = StandardMaterial3D.new()
		smat.albedo_color = Color(0.5, 0.02, 0.06, 0.9)
		smat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		smat.emission_enabled = true
		smat.emission = Color(1.0, 0.08, 0.05)
		smat.emission_energy_multiplier = 4.0
		smat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		spire.mesh = sbox
		spire.material_override = smat
		var a = float(i) / 10.0 * TAU + randf_range(-0.15, 0.15)
		var r = randf_range(0.4, 1.5)
		spire.position = Vector3(cos(a) * r, -sh * 0.5, sin(a) * r)
		spire.rotation.z = cos(a) * 0.5
		spire.rotation.x = sin(a) * 0.5
		root.add_child(spire)
		var target_h = sh * (0.6 + randf_range(0.0, 0.3))
		var st = spire.create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
		st.tween_property(spire, "position", Vector3(cos(a) * r * 0.5, target_h * 0.3, sin(a) * r * 0.5), 0.4)
		st.parallel().tween_property(smat, "emission_energy_multiplier", 1.0, 0.4)

func _spawn_explosion(pos: Vector3):
	var root = Node3D.new()
	root.position = pos
	get_tree().root.add_child(root)

	for ring_i in range(3):
		var ring = MeshInstance3D.new()
		ring.mesh = QuadMesh.new()
		ring.mesh.size = Vector2(0.1, 0.1)
		ring.rotation.x = deg_to_rad(-90)
		ring.position.y = 0.1 + ring_i * 0.5
		var rmat = StandardMaterial3D.new()
		rmat.albedo_color = Color(1.0, 0.2 - ring_i * 0.05, 0.05, 0.7 - ring_i * 0.15)
		rmat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		rmat.emission_enabled = true
		rmat.emission = Color(1.0, 0.3 - ring_i * 0.05, 0.05)
		rmat.emission_energy_multiplier = 5.0 - ring_i
		rmat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		ring.material_override = rmat
		root.add_child(ring)
		var rt = ring.create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_SINE)
		rt.tween_property(ring, "mesh:size", Vector2(8.0 + ring_i * 4.0, 8.0 + ring_i * 4.0), 0.5 + ring_i * 0.2)
		rt.parallel().tween_property(rmat, "albedo_color", Color(1.0, 0.2, 0.05, 0.0), 0.5 + ring_i * 0.2)
		rt.tween_callback(ring.queue_free)

	for i in range(18):
		var piece = MeshInstance3D.new()
		var box = BoxMesh.new()
		var s = randf_range(0.08, 0.2)
		box.size = Vector3(s, s, s)
		var pmat = StandardMaterial3D.new()
		pmat.albedo_color = Color(1.0, 0.25, 0.05, 1.0)
		pmat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		pmat.emission_enabled = true
		pmat.emission = Color(1.0, 0.35, 0.05)
		pmat.emission_energy_multiplier = 5.0
		piece.mesh = box
		piece.material_override = pmat
		root.add_child(piece)
		var a = float(i) / 18.0 * TAU
		var dir = Vector3(cos(a), randf_range(-0.3, 1.2), sin(a)).normalized()
		var pt = piece.create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_SINE)
		pt.tween_property(piece, "position", dir * randf_range(2.0, 6.0), 0.6)
		pt.parallel().tween_property(pmat, "albedo_color", Color(0, 0, 0, 0), 0.6)
		pt.tween_callback(piece.queue_free)

	var light = OmniLight3D.new()
	light.light_color = Color(1.0, 0.2, 0.05)
	light.light_energy = 12.0
	light.omni_range = 20.0
	light.position.y = 1.0
	root.add_child(light)
	var lt = light.create_tween()
	lt.tween_property(light, "light_energy", 0.0, 0.6)
	lt.tween_callback(light.queue_free)
	lt.tween_callback(root.queue_free)

func _spawn_final_blast():
	var flash = MeshInstance3D.new()
	flash.mesh = QuadMesh.new()
	flash.mesh.size = Vector2(0.1, 0.1)
	flash.rotation.x = deg_to_rad(-90)
	flash.position.y = 0.1
	var fmat = StandardMaterial3D.new()
	fmat.albedo_color = Color(1.0, 0.3, 0.05, 1.0)
	fmat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	fmat.emission_enabled = true
	fmat.emission = Color(1.0, 0.4, 0.05)
	fmat.emission_energy_multiplier = 10.0
	fmat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	flash.material_override = fmat
	add_child(flash)
	var ft = flash.create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_SINE)
	ft.tween_property(flash, "mesh:size", Vector2(40.0, 40.0), 0.6)
	ft.parallel().tween_property(fmat, "albedo_color", Color(1.0, 0.3, 0.05, 0.0), 0.6)
	ft.tween_callback(flash.queue_free)

	var flash_light = OmniLight3D.new()
	flash_light.light_color = Color(1.0, 0.3, 0.05)
	flash_light.light_energy = 20.0
	flash_light.omni_range = 40.0
	flash_light.position.y = 5.0
	add_child(flash_light)
	var flt = flash_light.create_tween()
	flt.tween_property(flash_light, "light_energy", 0.0, 0.6)
	flt.tween_callback(flash_light.queue_free)

func _spawn_alma_curacion(pos: Vector3):
	var alma = preload("res://scripts/alma_curacion.gd")
	if alma == null:
		return
	var node = Area3D.new()
	node.set_script(alma)
	node.global_position = pos + Vector3(0, 1.0, 0)
	get_tree().root.add_child(node)

func init_player(player_node: Node3D) -> void:
	_player = player_node

func _on_despawn():
	_explosion_final()
	if _player != null and is_instance_valid(_player) and _player.is_inside_tree():
		if _player.has_method("restore_mana"):
			_player.restore_mana(20.0)
	queue_free()

func _process(delta):
	_time_left = maxf(_time_left - delta, 0.0)
	if _label:
		_label.text = str(ceili(_time_left))

	_pulse_timer += delta
	if _pulse_timer >= _pulse_interval:
		_pulse_timer -= _pulse_interval
		_pulse_damage()

	_anim_time += delta
	if _mesh:
		_mesh.rotation.y += delta * 0.3
		_mesh.position.y = _base_y + sin(_anim_time * 1.2) * 0.2
		var pulse = 1.0 + 0.1 * sin(_anim_time * 3.0)
		_mesh.scale = Vector3(pulse, 1.0, pulse)

	for child in get_children():
		if not is_instance_valid(child):
			continue
		if child is MeshInstance3D and child != _mesh and child.has_meta("angle"):
			var a = child.get_meta("angle")
			var phase = child.get_meta("phase")
			var len = child.get_meta("len")
			a += delta * 2.0
			child.set_meta("angle", a)
			var r = 0.5 + 0.15 * sin(_anim_time * 2.5 + phase)
			child.position = Vector3(cos(a) * r, -0.3 + len * 0.5 + sin(_anim_time * 1.8 + phase) * 0.2, sin(a) * r)

func _pulse_damage():
	for e in _enemigos_marcados:
		if is_instance_valid(e) and e.is_inside_tree():
			if e.has_method("take_damage"):
				e.take_damage(_dano_pulso)

	if _player == null or not is_instance_valid(_player):
		return
	for i in range(3):
		var ring = MeshInstance3D.new()
		ring.mesh = QuadMesh.new()
		ring.mesh.size = Vector2(0.1, 0.1)
		ring.rotation.x = deg_to_rad(-90)
		ring.position = Vector3(randf_range(-5, 5), 0.05, randf_range(-5, 5))
		var rmat = StandardMaterial3D.new()
		rmat.albedo_color = Color(0.6, 0.05, 0.8, 0.3)
		rmat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		rmat.emission_enabled = true
		rmat.emission = Color(0.7, 0.08, 0.9)
		rmat.emission_energy_multiplier = 2.0
		rmat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		ring.material_override = rmat
		add_child(ring)
		var rt = ring.create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_SINE)
		rt.tween_property(ring, "mesh:size", Vector2(15.0, 15.0), 0.5)
		rt.parallel().tween_property(rmat, "albedo_color", Color(0.6, 0.05, 0.8, 0.0), 0.5)
		rt.tween_callback(ring.queue_free)

func _explosion_final():
	for e in _enemigos_marcados:
		if is_instance_valid(e):
			_spawn_explosion(e.global_position)
			_spawn_alma_curacion(e.global_position)

	for child in get_tree().root.get_children():
		if not is_instance_valid(child):
			continue
		if child is Node3D and child.get_meta("festin_root", false):
			child.queue_free()

	_spawn_final_blast()
	_enemigos_marcados.clear()
