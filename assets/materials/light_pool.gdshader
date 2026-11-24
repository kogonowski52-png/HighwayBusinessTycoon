shader_type spatial;
render_mode unshaded, cull_disabled, blend_add, depth_draw_never, shadows_disabled, fog_disabled;

uniform vec4 tint : source_color = vec4(1.0, 0.68, 0.33, 1.0);
uniform float intensity = 0.20;

void fragment() {
	float shape = max(0.0, 1.0 - length((UV - vec2(0.5)) * 2.0));
	ALBEDO = tint.rgb;
	ALPHA = shape * shape * intensity;
}
