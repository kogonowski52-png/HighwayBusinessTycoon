shader_type spatial;
render_mode specular_disabled;

uniform vec4 tint : source_color = vec4(0.47, 0.57, 0.36, 1.0);
uniform vec4 accent : source_color = vec4(0.69, 0.68, 0.43, 1.0);
uniform float grain = 0.16;
uniform float field = 1.0;
uniform vec2 tile = vec2(0.0);

varying vec2 world_point;

float hash(vec2 point) {
	vec3 p = fract(vec3(point.xyx) * 0.1031);
	p += dot(p, p.yzx + 33.33);
	return fract((p.x + p.y) * p.z);
}

float noise(vec2 point) {
	vec2 cell = floor(point);
	vec2 fraction = fract(point);
	vec2 weight = fraction * fraction * (3.0 - 2.0 * fraction);
	float a = mix(hash(cell), hash(cell + vec2(1.0, 0.0)), weight.x);
	float b = mix(hash(cell + vec2(0.0, 1.0)), hash(cell + vec2(1.0, 1.0)), weight.x);
	return mix(a, b, weight.y);
}

void vertex() {
	world_point = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xz;
}

void fragment() {
	float sweep = noise(world_point * vec2(0.118, 0.159));
	float patches = noise(world_point * 0.71);
	float detail = noise(world_point * 8.0) - 0.5;
	float blend = clamp(0.22 + (sweep - 0.3) * 0.8 + patches * 0.15, 0.0, 1.0) * field;
	vec3 base = mix(tint.rgb, accent.rgb, blend);
	if (tile.x > 0.0) {
		vec2 cell = world_point / tile;
		cell.x += 0.5 * mod(floor(cell.y), 2.0);
		vec2 edge = min(fract(cell), 1.0 - fract(cell));
		float seam = smoothstep(0.004, 0.043, min(edge.x, edge.y));
		base *= (0.83 + seam * 0.17) + (hash(floor(cell)) - 0.5) * 0.088;
	}
	ALBEDO = base * (1.0 + detail * grain * 0.50);
	ROUGHNESS = 0.95;
}
