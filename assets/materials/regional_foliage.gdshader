shader_type spatial;

global uniform float hbt_ambient_motion;

void vertex() {
	float phase = TIME * 1.35 + dot(MODEL_MATRIX[3].xz, vec2(0.43, 0.31));
	float canopy = smoothstep(0.95, 3.92, VERTEX.y);
	VERTEX.xz += vec2(sin(phase), cos(0.82 * phase)) * canopy * 0.16 * hbt_ambient_motion;
}

void fragment() {
	ALBEDO = COLOR.rgb;
	ROUGHNESS = 0.78;
}
