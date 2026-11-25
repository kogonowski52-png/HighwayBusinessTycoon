shader_type spatial;

global uniform float hbt_ambient_motion;

void vertex() {
	float phase = TIME * 1.65 + dot(MODEL_MATRIX[3].xz, vec2(0.53, 0.34));
	float tip = max(0.0, VERTEX.y);
	VERTEX.xz += vec2(sin(phase), cos(phase * 0.77)) * tip * tip * 0.13 * hbt_ambient_motion;
}

void fragment() {
	ALBEDO = COLOR.rgb;
	ROUGHNESS = 0.82;
}
