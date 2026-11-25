shader_type spatial;

varying vec2 pond;
varying vec2 world_point;

void vertex() {
	pond = VERTEX.xz;
	world_point = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xz;
}

void fragment() {
	float edge = smoothstep(0.25, 0.94, length(pond));
	float wave = sin(world_point.y * 3.4 + TIME * 0.58 + sin(world_point.x * 1.19) * 0.81);
	float crest = smoothstep(0.87, 0.995, wave) * (0.50 + 0.50 * sin(world_point.x * 0.73 - TIME * 0.27));
	ALBEDO = mix(vec3(0.05, 0.27, 0.26), vec3(0.24, 0.44, 0.35), edge);
	ALBEDO += vec3(0.035, 0.051, 0.046) * crest;
	ROUGHNESS = 0.35;
	SPECULAR = 0.42;
}
