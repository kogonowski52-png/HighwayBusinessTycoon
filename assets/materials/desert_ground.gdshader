shader_type spatial;
render_mode cull_disabled;

uniform vec4 base : source_color = vec4(0.82, 0.60, 0.39, 1.0);
uniform vec4 accent : source_color = vec4(0.95, 0.76, 0.53, 1.0);
uniform float rough = 0.93;
uniform float trail = 0.0;
varying vec2 coordinate;

float hash_cell(vec2 p) {
	return fract(sin(dot(p, vec2(127.13, 311.71))) * 43758.547);
}
float grain(vec2 p) {
	vec2 cell = floor(p);
	vec2 f = fract(p);
	vec2 ease = f * f * (3.0 - 2.0 * f);
	return mix(mix(hash_cell(cell), hash_cell(cell + vec2(1.0, 0.0)), ease.x),
		mix(hash_cell(cell + vec2(0.0, 1.0)), hash_cell(cell + vec2(1.0)), ease.x), ease.y);
}
void vertex() {
	coordinate = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xz;
}
void fragment() {
	float sandbank = grain(coordinate * vec2(0.077, 0.13));
	float flakes = grain(coordinate * 8.4);
	float tracks = smoothstep(0.46, 0.53, sin(coordinate.y * 3.0)) * trail;
	ALBEDO = mix(base.rgb, accent.rgb, clamp(0.66 * sandbank + 0.34 * flakes, 0., 1.)) * (1.0 - tracks * 0.085);
	ROUGHNESS = rough;
}
