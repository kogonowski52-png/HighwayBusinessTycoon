shader_type spatial;

uniform vec4 tint : source_color = vec4(0.55, 0.62, 0.39, 1.0);
uniform float contrast = 0.2;

varying vec2 world_position;

float hash(vec2 point) {
	return fract(sin(dot(point, vec2(127.1, 311.7))) * 43758.5453);
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
	world_position = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xz;
}

void fragment() {
	float patches = noise(world_position * 0.33) - 0.5;
	float specks = noise(world_position * 9.0) - 0.5;
	ALBEDO = tint.rgb * (1.0 + contrast * (patches + 0.24 * specks));
	ROUGHNESS = 0.93;
}
