shader_type spatial;
render_mode cull_disabled, specular_schlick_ggx;

uniform vec4 shallows : source_color = vec4(0.27, 0.68, 0.64, 1.0);
uniform vec4 channel : source_color = vec4(0.17, 0.51, 0.65, 1.0);
uniform bool sea = false;
varying vec2 world;

void vertex() {
	world = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xz;
}

void fragment() {
	float t = TIME * (sea ? 0.68 : 0.45);
	float ripple = sin(world.x * 1.25 + world.y * 0.48 + t)
		* cos(world.x * 0.55 - world.y * 0.73 + t * 0.8);
	float flow = sin(world.x * 0.21 + world.y * 0.53 + t * 1.52) * 0.5 + 0.5;
	float depth = sea ? clamp((world.y - 23.0) * 0.09, 0.0, 1.0) : clamp(1.0 - abs(world.x + 30.0) * 0.24, 0.0, 1.0);
	float foam = smoothstep(0.80, 0.98, ripple) * (sea ? (1.0 - depth) : 0.39) * flow;
	ALBEDO = mix(shallows.rgb, channel.rgb, depth * 0.81);
	ALBEDO = mix(ALBEDO * (0.98 + 0.084 * ripple), vec3(0.78, 0.94, 0.85), foam * 0.65);
	ALBEDO += flow * vec3(0.012, 0.029, 0.026);
	ROUGHNESS = 0.39;
	SPECULAR = 0.43;
}
