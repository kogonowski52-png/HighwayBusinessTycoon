shader_type spatial;
render_mode unshaded, cull_disabled, blend_mix, depth_draw_never, shadows_disabled, fog_disabled;

uniform float opacity = 0.42;
uniform vec4 ink : source_color = vec4(0.10, 0.18, 0.19, 1.0);

void fragment() {
	float radius = length((UV - vec2(0.5)) * 2.0);
	ALBEDO = ink.rgb;
	ALPHA = (1.0 - smoothstep(0.19, 0.98, radius)) * opacity;
}
