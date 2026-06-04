shader_type spatial;
render_mode blend_mix;

uniform sampler2D albedo_tex : source_color;
uniform sampler2D normal_tex;
uniform sampler2D ao_tex;
uniform float wobble = 0.1;
uniform float detail_scale = 3.0;

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

void vertex() {
	vec3 pos = VERTEX;
	float n = noise(pos.xz * 0.6 + 50.0);
	pos.y += (n - 0.5) * wobble;
	float m = noise(pos.xz * 1.2 + 150.0) - 0.5;
	pos.xz += m * wobble * 0.25;
	VERTEX = pos;
}

void fragment() {
	vec2 u = UV * detail_scale;
	vec4 albedo = texture(albedo_tex, u);
	vec3 normal = texture(normal_tex, u).xyz * 2.0 - 1.0;
	float ao = texture(ao_tex, u).r;

	float n1 = noise(UV * 4.0 + 10.0);
	float n2 = noise(UV * 8.0 + 30.0);
	float dirt = smoothstep(0.55, 0.65, n1);

	vec3 col = albedo.rgb;
	col = mix(col, vec3(0.12, 0.08, 0.04), dirt * 0.3);
	col += (n2 - 0.5) * 0.04;

	ALBEDO = col;
	NORMAL = normal;
	ROUGHNESS = mix(0.85, 0.95, dirt * 0.4);
	AO = ao;
}
