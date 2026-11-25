shader_type spatial;

global uniform float hbt_practical_level;
global uniform float hbt_ambient_motion;
uniform bool beacon = false;

void fragment() {
	ALBEDO = COLOR.rgb;
	float glow = hbt_practical_level;
	if (beacon && glow > 0.4) {
		glow *= 1.0 + sin(TIME * 2.35) * 0.055 * hbt_ambient_motion;
	}
	EMISSION = COLOR.rgb * glow;
	ROUGHNESS = 0.42;
}
