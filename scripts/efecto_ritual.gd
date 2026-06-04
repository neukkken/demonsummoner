extends Node

var _luces: Array[Node3D] = []
var _world_env: WorldEnvironment = null
var _ambient_orig: float = 0.0
var _fog_orig: float = 0.0
var _vfog_emission_orig: Color = Color(0, 0, 0)
var _vfog_density_orig: float = 0.0

func iniciar():
	_buscar_luces()
	_buscar_world_env()

	for luz in _luces:
		if not is_instance_valid(luz):
			continue
		luz.set_meta("_ritual_energy", luz.light_energy)
		var tween = create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_SINE)
		tween.tween_property(luz, "light_energy", 0.0, 0.5)

	if _world_env:
		var env = _world_env.environment
		if env:
			_ambient_orig = env.ambient_light_energy
			_fog_orig = env.fog_density
			_vfog_emission_orig = env.volumetric_fog_emission
			_vfog_density_orig = env.volumetric_fog_density
			var tween = create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_SINE)
			tween.tween_property(env, "ambient_light_energy", 0.01, 0.5)
			tween.parallel().tween_property(env, "fog_density", 0.0, 0.5)
			tween.parallel().tween_property(env, "volumetric_fog_density", _vfog_density_orig * 4.0, 0.8)
			tween.parallel().tween_property(env, "volumetric_fog_emission", Color(1.0, 0.15, 0.05), 0.8)

	await get_tree().create_timer(3.5).timeout
	_restaurar()

func _restaurar():
	for luz in _luces:
		if not is_instance_valid(luz):
			continue
		var orig = luz.get_meta("_ritual_energy", luz.light_energy)
		var tween = create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_SINE)
		tween.tween_property(luz, "light_energy", orig, 0.5)

	if _world_env and _world_env.environment:
		var env = _world_env.environment
		var tween = create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_SINE)
		tween.tween_property(env, "ambient_light_energy", _ambient_orig, 0.5)
		tween.parallel().tween_property(env, "fog_density", _fog_orig, 0.5)
		tween.parallel().tween_property(env, "volumetric_fog_density", _vfog_density_orig, 0.5)
		tween.parallel().tween_property(env, "volumetric_fog_emission", _vfog_emission_orig, 0.5)

	await get_tree().create_timer(0.7).timeout
	if _world_env and _world_env.environment:
		var env = _world_env.environment
		env.volumetric_fog_emission = _vfog_emission_orig
		env.ambient_light_energy = _ambient_orig
		env.fog_density = _fog_orig
		env.volumetric_fog_density = _vfog_density_orig
	for luz in _luces:
		if is_instance_valid(luz):
			luz.light_energy = luz.get_meta("_ritual_energy", luz.light_energy)
	queue_free()

func _buscar_luces():
	var root = get_tree().root
	_revisar_nodo(root)

func _revisar_nodo(nodo: Node):
	for child in nodo.get_children():
		if child is OmniLight3D or child is DirectionalLight3D:
			_luces.append(child)
		if child.get_child_count() > 0:
			_revisar_nodo(child)

func _buscar_world_env():
	_world_env = get_tree().root.find_child("WorldEnvironment", true, false) as WorldEnvironment
