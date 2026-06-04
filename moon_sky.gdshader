shader_type sky;

uniform vec3 moon_position = vec3(-0.3, 0.45, -0.85);
uniform float moon_size = 0.15;
uniform float moon_softness = 0.005;
uniform vec3 moon_color = vec3(0.7, 0.72, 0.9);
uniform float moon_brightness = 1.2;
uniform float moon_glow = 0.3;
uniform float glow_spread = 60.0;
uniform vec3 sky_top = vec3(0.005, 0.005, 0.02);
uniform vec3 sky_horizon = vec3(0.03, 0.025, 0.05);
uniform vec3 sky_ground = vec3(0.003, 0.003, 0.006);
uniform vec3 cloud_color = vec3(0.06, 0.03, 0.08);
uniform vec3 cloud_highlight = vec3(0.25, 0.15, 0.35);
uniform float cloud_density = 1.2;
uniform float cloud_speed = 0.012;
uniform float cloud_height = 0.35;
uniform float cloud_thickness = 2.0;
uniform float star_brightness = 0.8;


float hash(vec2 p) {
	p = fract(p * vec2(234.34, 435.345));
	p += dot(p, p + 19.19);
	return fract(p.x * p.y);
}


float hash21(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}


float noise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	f = f * f * (3.0 - 2.0 * f);
	return mix(mix(hash(i), hash(i + vec2(1, 0)), f.x),
		mix(hash(i + vec2(0, 1)), hash(i + vec2(1, 1)), f.x), f.y);
}


float fbm(vec2 p) {
	float v = 0.0;
	float a = 0.5;
	mat2 rot = mat2(vec2(0.877, 0.479), vec2(-0.479, 0.877));
	for (int i = 0; i < 5; i++) {
		v += a * noise(p);
		p = rot * p * 2.0;
		a *= 0.5;
	}
	return v;
}


void sky() {
	vec3 dir = normalize(EYEDIR);
	float h = 1.0 - abs(dir.y);

	vec3 col = mix(sky_top, sky_horizon, h * h);
	if (dir.y < 0.0) {
		col = mix(sky_horizon, sky_ground, abs(dir.y) * 4.0);
	}

	float stars = 0.0;
	if (dir.y > 0.02) {
		vec2 star_uv = dir.xz / max(dir.y, 0.01) * 0.3;
		vec2 cell = floor(star_uv * 80.0);
		vec2 sub = fract(star_uv * 80.0) - 0.5;
		float r = hash21(cell + 100.0);
		float size = 0.02 + r * 0.04;
		float dist = length(sub);
		if (dist < size) {
			float twinkle = 0.6 + 0.4 * sin(TIME * (2.0 + r * 5.0) + r * 100.0);
			stars = (1.0 - dist / size) * r * star_brightness * twinkle;
			stars = pow(stars, 1.5);
		}
	}
	col += vec3(stars * 0.9, stars * 0.85, stars * 1.0);

	float cloud_alt = smoothstep(0.0, cloud_height, max(dir.y, 0.0));
	cloud_alt *= 1.0 - smoothstep(cloud_height, 1.0, dir.y);
	cloud_alt = pow(cloud_alt, 0.5);

	if (cloud_alt > 0.01) {
		vec2 base_uv = dir.xz / max(dir.y, 0.01) * 0.4;
		vec2 drift = vec2(TIME * cloud_speed, TIME * cloud_speed * 0.25);

		float total_cloud = 0.0;
		for (int i = 0; i < 4; i++) {
			float fi = float(i);
			float scale = 1.0 + fi * 0.8;
			float depth = fi / 4.0;
			vec2 layer_uv = base_uv * scale + drift * (1.0 + fi * 0.2);
			float n = fbm(layer_uv + 500.0 + fi * 100.0);
			n = smoothstep(0.5 - cloud_density * 0.4, 0.9, n);
			total_cloud += n * (1.0 - depth * 0.5);
		}
		total_cloud = total_cloud / 4.0;
		total_cloud *= cloud_alt * cloud_thickness;
		total_cloud = clamp(total_cloud, 0.0, 1.0);

		float edge_detail = fbm(base_uv * 1.5 + drift * 1.2 + 800.0);
		vec3 cloud_col = mix(cloud_color, cloud_highlight, edge_detail * 0.6);
		col = mix(col, cloud_col, total_cloud);
	}

	float d = acos(clamp(dot(dir, normalize(moon_position)), 0.0, 1.0));
	float disk = 1.0 - smoothstep(moon_size - moon_softness, moon_size + moon_softness, d);
	float glow = exp(-d * d * glow_spread) * moon_glow * moon_brightness;
	col += glow * moon_color;

	if (disk > 0.001) {
		vec3 up = vec3(0.0, 1.0, 0.0);
		vec3 tangent = normalize(cross(moon_position, up));
		vec3 bitangent = normalize(cross(moon_position, tangent));
		vec2 uv = vec2(dot(dir, tangent), dot(dir, bitangent)) / (moon_size * 0.5);

		float crater_noise = fbm(uv * 10.0 + 100.0);
		float mare_noise = smoothstep(0.4, 0.6, fbm(uv * 3.0 + 200.0));
		float detail = fbm(uv * 20.0 + 300.0) * 0.3;

		float bright = mix(0.4, 1.0, 1.0 - mare_noise);
		bright *= mix(0.7, 1.0, crater_noise + detail);
		bright = clamp(bright, 0.0, 1.0);

		vec3 silver = vec3(0.85, 0.86, 0.95);
		vec3 dark_mare = vec3(0.25, 0.2, 0.15);
		vec3 surface = mix(dark_mare, silver, bright);
		surface *= moon_brightness;

		col = mix(col, surface, disk);
	}

	COLOR = col;
}
