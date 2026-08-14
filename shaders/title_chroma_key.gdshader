shader_type canvas_item;

// Chroma key
uniform float threshold : hint_range(0.0, 1.0) = 0.85;
uniform float edge_softness : hint_range(0.0, 0.3) = 0.1;

// Fire effect
uniform vec4 fire_color_bottom : source_color = vec4(1.0, 0.9, 0.2, 1.0);
uniform vec4 fire_color_mid : source_color = vec4(1.0, 0.45, 0.05, 1.0);
uniform vec4 fire_color_top : source_color = vec4(0.7, 0.05, 0.02, 1.0);
uniform float fire_speed : hint_range(0.0, 5.0) = 1.8;
uniform float fire_intensity : hint_range(0.0, 2.0) = 0.7;
uniform float fire_height : hint_range(0.0, 1.0) = 0.45;
uniform float fire_scale : hint_range(1.0, 20.0) = 6.0;

float hash(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

float noise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	f = f * f * (3.0 - 2.0 * f);
	return mix(
		mix(hash(i), hash(i + vec2(1.0, 0.0)), f.x),
		mix(hash(i + vec2(0.0, 1.0)), hash(i + vec2(1.0, 1.0)), f.x),
		f.y
	);
}

float fbm(vec2 p) {
	float v = 0.0;
	float a = 0.5;
	for (int i = 0; i < 4; i++) {
		v += a * noise(p);
		p *= 2.0;
		a *= 0.5;
	}
	return v;
}

void fragment() {
	vec4 col = texture(TEXTURE, UV);
	float brightness = (col.r + col.g + col.b) / 3.0;
	float alpha = 1.0 - smoothstep(threshold - edge_softness, threshold + edge_softness, brightness);

	// Fire on top of text
	float text_mask = step(0.1, alpha);
	vec2 fire_uv = UV * vec2(fire_scale, fire_scale * 0.5);
	fire_uv.y -= TIME * fire_speed;

	float n = fbm(fire_uv);
	n *= fbm(fire_uv * 1.5 + vec2(0.0, TIME * 0.3));

	// Fire rises from bottom of text
	float rise = 1.0 - UV.y;
	float fire_zone = smoothstep(0.0, fire_height, rise);
	float flicker = 0.8 + 0.2 * sin(TIME * 8.0 + UV.x * 12.0);
	float fire_mask = n * fire_zone * fire_intensity * flicker * text_mask;

	// Color gradient
	vec4 fire_col = fire_color_bottom;
	fire_col = mix(fire_col, fire_color_mid, smoothstep(0.2, 0.6, rise));
	fire_col = mix(fire_col, fire_color_top, smoothstep(0.5, 1.0, rise));
	fire_col.a = fire_mask;

	// Composite: text + fire
	col.a = max(alpha, fire_mask * 0.6);
	col.rgb = mix(col.rgb, fire_col.rgb, clamp(fire_mask, 0.0, 1.0));

	COLOR = col;
}
