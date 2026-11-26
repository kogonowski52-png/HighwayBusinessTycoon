shader_type spatial;
render_mode cull_disabled, specular_disabled;

uniform vec4 base : source_color = vec4(0.82, 0.60, 0.39, 1.0);
uniform vec4 accent : source_color = vec4(0.95, 0.76, 0.53, 1.0);
uniform float rough = 0.93;
uniform float trail = 0.0;
uniform sampler2D aggregate : repeat_enable, filter_linear_mipmap;
varying vec2 coordinate;

void vertex() {
	coordinate = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xz;
}
void fragment() {
	vec3 sweep = texture(aggregate, coordinate * vec2(0.036, 0.052)).rgb;
	vec3 chip = texture(aggregate, coordinate * 0.241).rgb;
	float bank = smoothstep(0.13, 0.85, sweep.g * 0.81 + chip.g * 0.19);
	vec3 grade = mix(base.rgb, accent.rgb, bank);
	float drift = chip.r * (0.17 + trail * 0.13);
	float patch = trail * (sweep.b * 0.36 + chip.b * 0.15);
	float rut = (1.0 - smoothstep(0.045, 0.106, abs(fract(coordinate.y * 0.27 + 0.17) - 0.5))) * trail;
	ALBEDO = grade * (0.90 + drift - patch - rut * (0.047 + sweep.g * 0.12));
	ROUGHNESS = rough;
}
