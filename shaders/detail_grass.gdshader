shader_type spatial;
render_mode blend_mix;

uniform sampler2D albedo_tex : source_color;
uniform sampler2D normal_tex;
uniform sampler2D ao_tex;
uniform float detail_scale = 4.0;
uniform float dirt_strength = 0.35;
uniform float pebble_strength = 0.2;

float hash(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

float noise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	f = f * f * (3.0 - 2.0 * f);
	float a = hash(i);
	float b = hash(i + vec2(1.0, 0.0));
	float c = hash(i + vec2(0.0, 1.0));
	float d = hash(i + vec2(1.0, 1.0));
	return mix(mix(a, b, f.x), mix(c, d, f.x), f.y);
}

void fragment() {
	vec4 albedo = texture(albedo_tex, UV);
	float ao = texture(ao_tex, UV).r;

	float n1 = noise(UV * detail_scale);
	float n2 = noise(UV * detail_scale * 2.5 + 50.0);
	float n3 = noise(UV * detail_scale * 5.0 + 200.0);

	float dirt = smoothstep(0.55, 0.65, n1);
	float pebble = smoothstep(0.8, 0.88, n2);
	float micro = n3 * 0.06;

	vec3 dark_soil = vec3(0.15, 0.1, 0.05);
	vec3 pebble_col = mix(vec3(0.35, 0.33, 0.28), vec3(0.5, 0.48, 0.42), n3);

	vec3 col = albedo.rgb;
	col = mix(col, dark_soil, dirt * dirt_strength);
	col = mix(col, pebble_col, pebble * pebble_strength);
	col += micro;

	ALBEDO = col;
	ROUGHNESS = mix(0.85, 0.95, dirt * 0.3);
	AO = ao;
}
