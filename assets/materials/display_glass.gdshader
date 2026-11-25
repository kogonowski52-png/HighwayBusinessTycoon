shader_type spatial;
render_mode blend_mix, depth_draw_never, shadows_disabled;

varying vec3 position_world;

void vertex() {
	position_world = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

void fragment() {
	float fresnel = pow(1.0 - max(dot(normalize(NORMAL), normalize(VIEW)), 0.0), 2.2);
	float glint = smoothstep(0.73, 0.86, fract((position_world.x + position_world.z * 0.73 + position_world.y * 1.46) * 0.24));
	float reflection = min(0.72, fresnel * 0.76 + glint * 0.14);
	ALBEDO = mix(COLOR.rgb, vec3(0.64, 0.85, 0.83), reflection);
	ALPHA = 0.15 + reflection * 0.51;
	ROUGHNESS = 0.22;
	SPECULAR = 0.52;
}
