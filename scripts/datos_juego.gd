extends Node

var almas_cosechadas: int = 0
var render_distance: int = 1 # 0: Corta, 1: Media, 2: Larga
const REQUISITO_DEVORADOR: int = 50

var _gems_since_last_soul: int = 0
const GEMS_PER_SOUL: int = 3

signal alma_cosechada(almas: int, requisito: int)
signal pacto_listo()

func add_gem() -> void:
	_gems_since_last_soul += 1
	if _gems_since_last_soul >= GEMS_PER_SOUL:
		_gems_since_last_soul = 0
		cosechar_alma_directa()

func cosechar_alma_directa() -> void:
	if almas_cosechadas < REQUISITO_DEVORADOR:
		almas_cosechadas += 1
		print("Alma absorbida. Progreso: ", almas_cosechadas, "/", REQUISITO_DEVORADOR)
		alma_cosechada.emit(almas_cosechadas, REQUISITO_DEVORADOR)
		if almas_cosechadas >= REQUISITO_DEVORADOR:
			print("¡EL PACTO DE SOMBRA ESTÁ LISTO!")
			pacto_listo.emit()

func reset() -> void:
	almas_cosechadas = 0
	_gems_since_last_soul = 0

func consumir_almas() -> void:
	almas_cosechadas = 0
	alma_cosechada.emit(0, REQUISITO_DEVORADOR)

func almas_suficientes() -> bool:
	return almas_cosechadas >= REQUISITO_DEVORADOR

func obtener_almas() -> int:
	return almas_cosechadas

var current_dungeon: Node = null
var _noise: FastNoiseLite = null

func _init_noise() -> void:
	if _noise != null:
		return
	_noise = FastNoiseLite.new()
	_noise.noise_type = FastNoiseLite.TYPE_SIMPLEX
	_noise.seed = 987654
	_noise.frequency = 0.005 # Colinas anchas y espaciadas
	_noise.fractal_octaves = 4
	_noise.fractal_lacunarity = 2.2
	_noise.fractal_gain = 0.35 # Micro-detalle suave para que no se vea sintético

func get_height(world_x: float, world_z: float) -> float:
	if current_dungeon != null and is_instance_valid(current_dungeon) and current_dungeon.has_method("get_floor_height_at"):
		return current_dungeon.get_floor_height_at(world_x, world_z)

	if _noise == null:
		_init_noise()
	
	var dist = Vector2(world_x, world_z).length()
	var raw = _noise.get_noise_2d(world_x, world_z)
	
	# Rampa de transición suave (Smoothstep entre 30m y 120m de distancia)
	var factor = clampf((dist - 30.0) / 90.0, 0.0, 1.0)
	factor = factor * factor * (3.0 - 2.0 * factor)
	
	return raw * 16.0 * factor

