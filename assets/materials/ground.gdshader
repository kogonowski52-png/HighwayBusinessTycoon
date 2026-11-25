shader_type spatial;
render_mode specular_disabled;

uniform vec4 tint : source_color = vec4(0.47, 0.57, 0.36, 1.0);
uniform vec4 accent : source_color = vec4(0.69, 0.68, 0.43, 1.0);
uniform float grain = 0.16;
uniform float field = 1.0;
uniform vec2 tile = vec2(0.0);
uniform sampler2D paving_noise : repeat_enable, filter_linear_mipmap;
uniform bool highway = false;

varying vec2 world_point;

float hash(vec2 point) {
	vec3 p = fract(vec3(point.xyx) * 0.1031);
	p += dot(p, p.yzx + 33.33);
	return fract((p.x + p.y) * p.z);
}

void vertex() {
	world_point = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xz;
}

void fragment() {
	vec2 detail = texture(paving_noise, world_point * 0.40).rg;
	float sweep = texture(paving_noise, world_point * vec2(0.024, 0.030)).g;
	float blend = clamp(0.12 + sweep * 0.63 + detail.g * 0.21, 0.0, 1.0) * field;
	vec3 base = mix(tint.rgb, accent.rgb, blend);
	if (tile.x > 0.0) {
		vec2 cell = world_point / tile;
		cell.x += 0.5 * mod(floor(cell.y), 2.0);
		vec2 edge = min(fract(cell), 1.0 - fract(cell));
		float seam = smoothstep(0.004, 0.043, min(edge.x, edge.y));
		base *= (0.83 + seam * 0.17) + (hash(floor(cell)) - 0.5) * 0.088;
	}
	if (highway) {
		float lane = world_point.y < 10.5 ? 8.78 : 12.17;
		float rubber = abs(abs(world_point.y - lane) - 0.71);
		float wear = 1.0 - smoothstep(0.09, 0.49, rubber);
		base *= 1.0 - wear * (0.054 + 0.082 * sweep);
	}
	ALBEDO = base * (1.0 + (detail.r - 0.5) * grain);
	ROUGHNESS = 0.89 + detail.r * 0.10;
}
