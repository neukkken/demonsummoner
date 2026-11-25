shader_type canvas_item;

// Shader de resplandor ígneo y destellos para el título de Demon Summoner
uniform float pulse_speed : hint_range(0.5, 5.0) = 2.2;
uniform float ember_speed : hint_range(0.1, 4.0) = 1.2;
uniform vec4 glow_color : source_color = vec4(1.0, 0.4, 0.12, 1.0);
uniform float glow_intensity : hint_range(0.0, 2.0) = 0.45;

void fragment() {
	vec4 col = texture(TEXTURE, UV);
	if (col.a > 0.02) {
		// Detectar runas ígneas y grietas de magma (predominio rojo/cálido)
		float fire_tint = clamp((col.r - col.b * 1.2) * 1.4, 0.0, 1.0);
		
		// Pulso respiratorio de calor
		float pulse = 0.5 + 0.5 * sin(TIME * pulse_speed + UV.x * 5.0 - UV.y * 3.0);
		
		// Destello místico diagonal sobre los cuernos y filigranas
		float sweep = sin(UV.x * 8.0 - UV.y * 4.0 + TIME * ember_speed);
		float sweep_glow = pow(clamp(sweep, 0.0, 1.0), 5.0) * 0.5;
		
		// Iluminación aditiva integrada
		vec3 fire_boost = glow_color.rgb * (fire_tint * pulse * glow_intensity) + col.rgb * sweep_glow * 0.4;
		col.rgb += fire_boost;
	}
	COLOR = col;
}
