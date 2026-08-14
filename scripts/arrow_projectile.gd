extends Area3D

var velocity: Vector3

func _physics_process(delta):
	global_position += velocity * delta
