extends DirectionalLight3D

@export var base_energy: float = 0.2
@export var base_color: Color = Color(0.15, 0.12, 0.3)
@export var interval_min: float = 6.0
@export var interval_max: float = 18.0

var _flash_timer: Timer = null
var _lightning_light: OmniLight3D = null


func _ready() -> void:
	light_energy = base_energy
	light_color = base_color

	_lightning_light = OmniLight3D.new()
	_lightning_light.light_color = Color(0.7, 0.75, 1.0)
	_lightning_light.light_energy = 0.0
	_lightning_light.omni_range = 60.0
	_lightning_light.shadow_enabled = false
	get_tree().root.call_deferred("add_child", _lightning_light)

	_flash_timer = Timer.new()
	_flash_timer.one_shot = true
	_flash_timer.timeout.connect(_start_lightning)
	add_child(_flash_timer)
	_schedule_next_flash()


func _schedule_next_flash() -> void:
	_flash_timer.start(randf_range(interval_min, interval_max))


func _start_lightning() -> void:
	var player := get_node_or_null("/root/World/Player")
	if player != null:
		_lightning_light.global_position = player.global_position

	var peak := randf_range(8.0, 15.0)

	var tween := create_tween()
	tween.set_trans(Tween.TRANS_LINEAR)

	tween.tween_property(self, "light_energy", 0.3, 0.02)
	tween.tween_property(self, "light_energy", base_energy * 0.5, 0.05)
	tween.tween_property(self, "light_energy", 0.15, 0.02)
	tween.tween_property(self, "light_energy", base_energy, 0.3)

	tween.parallel().tween_property(_lightning_light, "light_energy", peak, 0.02)
	tween.parallel().tween_property(_lightning_light, "light_energy", 0.3, 0.05)
	tween.parallel().tween_property(_lightning_light, "light_energy", peak * 0.5, 0.02)
	tween.parallel().tween_property(_lightning_light, "light_energy", 0.0, 0.35)

	tween.finished.connect(_schedule_next_flash)
