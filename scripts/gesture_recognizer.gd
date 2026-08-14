extends Node

signal gesture_detected(gesture_name: String)

@export var gesture_min_distance: float = 100.0

var gesture_displacement: Vector2 = Vector2.ZERO
var gesture_active: bool = false

func _input(event: InputEvent) -> void:
	if event is not InputEventMouseMotion:
		return

	var shift_held := Input.is_action_pressed("channel_spell") \
		and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED

	if shift_held:
		if not gesture_active:
			gesture_displacement = Vector2.ZERO
			gesture_active = true
		gesture_displacement += event.relative

	elif gesture_active:
		gesture_active = false
		_process_gesture()

func _process_gesture() -> void:
	var dist := gesture_displacement.length()

	if dist < gesture_min_distance:
		gesture_detected.emit("UNKNOWN")
		print("Gesto: UNKNOWN | distancia: ", snapped(dist, 0.1), " < minimo")
		return

	var angle := rad_to_deg(gesture_displacement.angle())
	var gesture_name := ""

	if angle >= -22.5 and angle < 22.5:
		gesture_name = "RIGHT"
	elif angle >= 22.5 and angle < 67.5:
		gesture_name = "DOWN_RIGHT"
	elif angle >= 67.5 and angle < 112.5:
		gesture_name = "DOWN"
	elif angle >= 112.5 and angle < 157.5:
		gesture_name = "DOWN_LEFT"
	elif angle >= -67.5 and angle < -22.5:
		gesture_name = "UP_RIGHT"
	elif angle >= -112.5 and angle < -67.5:
		gesture_name = "UP"
	elif angle >= -157.5 and angle < -112.5:
		gesture_name = "UP_LEFT"
	else:
		gesture_name = "LEFT"

	gesture_detected.emit(gesture_name)
	print("Gesto: ", gesture_name,
		" | distancia: ", snapped(dist, 0.1),
		" | delta: (", snapped(gesture_displacement.x, 0.1),
		", ", snapped(gesture_displacement.y, 0.1), ")")

func get_progress() -> float:
	if not gesture_active:
		return 0.0
	return clampf(gesture_displacement.length() / gesture_min_distance, 0.0, 1.0)

func get_current_direction() -> String:
	if gesture_displacement.length() < 1.0:
		return "—"
	var angle := rad_to_deg(gesture_displacement.angle())
	if angle >= -22.5 and angle < 22.5:
		return "RIGHT"
	elif angle >= 22.5 and angle < 67.5:
		return "DOWN_RIGHT"
	elif angle >= 67.5 and angle < 112.5:
		return "DOWN"
	elif angle >= 112.5 and angle < 157.5:
		return "DOWN_LEFT"
	elif angle >= -67.5 and angle < -22.5:
		return "UP_RIGHT"
	elif angle >= -112.5 and angle < -67.5:
		return "UP"
	elif angle >= -157.5 and angle < -112.5:
		return "UP_LEFT"
	else:
		return "LEFT"
