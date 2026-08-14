extends Area3D

@export var hazard_type: String = "lava"
@export var damage_per_second: float = 10.0
@export var slow_factor: float = 0.5

var _bodies: Array[Node3D] = []
var _tick_timer: float = 0.0

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)

func _on_body_entered(body: Node3D) -> void:
	if body.is_in_group("player") or body.is_in_group("enemies"):
		_bodies.append(body)
		_apply_slow_effect(body)

func _on_body_exited(body: Node3D) -> void:
	_bodies.erase(body)
	_remove_slow_effect(body)

func _apply_slow_effect(body: Node3D) -> void:
	if body.is_in_group("player"):
		body.apply_freeze(0.2, slow_factor)
	else:
		var speed_prop = "speed" if "speed" in body else ("move_speed" if "move_speed" in body else "")
		if speed_prop != "":
			var orig_speed = body.get(speed_prop)
			if orig_speed != null and not body.has_meta("original_hazard_speed"):
				body.set_meta("original_hazard_speed", orig_speed)
				body.set(speed_prop, orig_speed * slow_factor)

func _remove_slow_effect(body: Node3D) -> void:
	if body.is_in_group("player"):
		body.apply_freeze(0.0, 1.0)
	else:
		if body.has_meta("original_hazard_speed"):
			var orig_speed = body.get_meta("original_hazard_speed")
			var speed_prop = "speed" if "speed" in body else ("move_speed" if "move_speed" in body else "")
			if speed_prop != "":
				body.set(speed_prop, orig_speed)
			body.remove_meta("original_hazard_speed")

func _physics_process(delta: float) -> void:
	# Asegurar que el slow se mantenga frame a frame
	for body in _bodies:
		if is_instance_valid(body):
			if body.is_in_group("player"):
				body.apply_freeze(0.2, slow_factor)
			else:
				var speed_prop = "speed" if "speed" in body else ("move_speed" if "move_speed" in body else "")
				if speed_prop != "" and body.has_meta("original_hazard_speed"):
					var orig = body.get_meta("original_hazard_speed")
					body.set(speed_prop, orig * slow_factor)

	# Aplicar daño periódico cada 0.5 segundos
	_tick_timer += delta
	if _tick_timer >= 0.5:
		_tick_timer = 0.0
		for body in _bodies:
			if is_instance_valid(body) and body.has_method("take_damage"):
				body.take_damage(damage_per_second * 0.5)

# Limpieza preventiva
func _exit_tree() -> void:
	for body in _bodies:
		if is_instance_valid(body):
			_remove_slow_effect(body)
	_bodies.clear()
