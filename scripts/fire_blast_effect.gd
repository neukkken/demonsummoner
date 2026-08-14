extends Node3D

func _ready() -> void:
	for i in range(18):
		var piece = MeshInstance3D.new()
		var s = randf_range(0.12, 0.25)
		var box = BoxMesh.new()
		box.size = Vector3(s, s, s)
		var t = randf()
		var color = Color(1, 0.85, 0.15, 1) if t > 0.5 else Color(1, randf_range(0.35, 0.6), 0.0, 0.95)
		var mat = StandardMaterial3D.new()
		mat.albedo_color = color
		mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		mat.emission_enabled = true
		mat.emission = color
		mat.emission_energy_multiplier = 4.0
		piece.mesh = box
		piece.material_override = mat
		add_child(piece)
		var angle = randf_range(0, 360)
		var dir = Vector3(cos(deg_to_rad(angle)), randf_range(-0.2, 1.0), sin(deg_to_rad(angle))).normalized()
		var dist = randf_range(1.0, 4.0)
		var tween = piece.create_tween()
		tween.tween_property(piece, "position", dir * dist, 0.6).set_trans(Tween.TRANS_LINEAR)
		tween.parallel().tween_property(mat, "emission", Color(0, 0, 0, 0), 0.6)
		tween.parallel().tween_property(mat, "albedo_color", Color(0, 0, 0, 0), 0.6)
		tween.tween_callback(piece.queue_free)

	for i in range(10):
		var piece = MeshInstance3D.new()
		var s = randf_range(0.05, 0.1)
		var box = BoxMesh.new()
		box.size = Vector3(s, s, s)
		var color = Color(1, randf_range(0.7, 0.95), randf_range(0.1, 0.3), 1)
		var mat = StandardMaterial3D.new()
		mat.albedo_color = color
		mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		mat.emission_enabled = true
		mat.emission = color
		mat.emission_energy_multiplier = 5.0
		piece.mesh = box
		piece.material_override = mat
		add_child(piece)
		var angle = randf_range(0, 360)
		var dir = Vector3(cos(deg_to_rad(angle)), randf_range(0.2, 1.2), sin(deg_to_rad(angle))).normalized()
		var dist = randf_range(2.0, 5.0)
		var tween = piece.create_tween()
		tween.tween_property(piece, "position", dir * dist, 0.5).set_trans(Tween.TRANS_LINEAR)
		tween.parallel().tween_property(mat, "emission", Color(0, 0, 0, 0), 0.5)
		tween.parallel().tween_property(mat, "albedo_color", Color(0, 0, 0, 0), 0.5)
		tween.tween_callback(piece.queue_free)

	var light = OmniLight3D.new()
	light.light_color = Color(1, 0.5, 0, 1)
	light.light_energy = 6.0
	light.omni_range = 10.0
	add_child(light)
	var tween = create_tween()
	tween.tween_property(light, "light_energy", 0.0, 0.6)
	tween.tween_callback(queue_free)
