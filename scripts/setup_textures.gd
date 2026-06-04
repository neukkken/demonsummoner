extends Node


func _ready() -> void:
	_create_material("grass", "Grass")
	_create_material("sand", "Sand")
	_create_material("snow", "Snow")
	_create_water_material()
	_create_lava_material()
	print("Todos los materiales creados en res://materials/")
	queue_free()


func _create_material(folder: String, base_name: String) -> void:
	var mat := StandardMaterial3D.new()
	mat.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	mat.roughness = 0.9
	mat.metallic = 0.0
	mat.metallic_specular = 0.0

	var albedo_path := "res://textures/%s/%s.png" % [folder.capitalize(), base_name]
	var normal_path := "res://textures/%s/%s_Normal.jpg" % [folder.capitalize(), base_name]
	var occlusion_path := "res://textures/%s/%s_Occlusion.jpg" % [folder.capitalize(), base_name]

	if ResourceLoader.exists(albedo_path):
		mat.albedo_texture = load(albedo_path)
	if ResourceLoader.exists(normal_path):
		mat.normal_texture = load(normal_path)
	if ResourceLoader.exists(occlusion_path):
		mat.ao_texture = load(occlusion_path)
	mat.ao_enabled = ResourceLoader.exists(occlusion_path)

	ResourceSaver.save(mat, "res://materials/%s_material.tres" % folder)


func _create_water_material() -> void:
	var mat := StandardMaterial3D.new()
	mat.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	mat.roughness = 0.3
	mat.metallic = 0.0
	mat.metallic_specular = 0.0
	mat.flags_transparent = true

	var albedo := load("res://textures/Water/Water.png")
	var normal := load("res://textures/Water/Water_Normal.jpg")
	var occlusion := load("res://textures/Water/Water_Occlusion.jpg")

	if albedo: mat.albedo_texture = albedo
	if normal: mat.normal_texture = normal
	if occlusion:
		mat.ao_texture = occlusion
		mat.ao_enabled = true

	mat.emission_enabled = true
	mat.emission = Color(0.6, 0.3, 1.0, 1.0)
	mat.emission_energy_multiplier = 2.0
	if albedo:
		mat.emission_texture = albedo

	ResourceSaver.save(mat, "res://materials/water_material.tres")


func _create_lava_material() -> void:
	var mat := StandardMaterial3D.new()
	mat.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	mat.roughness = 0.4
	mat.metallic = 0.2
	mat.metallic_specular = 0.0
	mat.flags_transparent = true

	var albedo := load("res://textures/Lava/Lava.png")
	var normal := load("res://textures/Lava/Lava_Normal.jpg")

	if albedo: mat.albedo_texture = albedo
	if normal: mat.normal_texture = normal

	mat.emission_enabled = true
	mat.emission = Color(1.0, 0.3, 0.05, 1.0)
	mat.emission_energy_multiplier = 3.0
	if albedo:
		mat.emission_texture = albedo

	ResourceSaver.save(mat, "res://materials/lava_material.tres")
