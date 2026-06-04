static func make_handpainted(base: Material = null) -> StandardMaterial3D:
	var mat: StandardMaterial3D
	if base is StandardMaterial3D:
		mat = base
	else:
		mat = StandardMaterial3D.new()

	mat.metallic = 0.0
	mat.metallic_specular = 0.0
	mat.roughness = 0.85
	mat.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_PER_PIXEL
	return mat


static func make_glowing(base: Material = null, emission_color: Color = Color(0.8, 0.4, 1.0, 1.0), emission_energy: float = 2.0) -> StandardMaterial3D:
	var mat := make_handpainted(base)
	mat.emission_enabled = true
	mat.emission = emission_color
	mat.emission_energy_multiplier = emission_energy
	mat.emission_on_uv2 = false
	return mat


static func make_water(base: Material = null) -> StandardMaterial3D:
	var mat := make_glowing(base, Color(0.6, 0.3, 1.0, 1.0), 1.5)
	mat.roughness = 0.3
	mat.metallic = 0.0
	mat.flags_transparent = true
	mat.distance_fade = BaseMaterial3D.DISTANCE_FADE_PIXEL_DITHER
	mat.distance_fade_max_distance = 40.0
	return mat
