shader_type spatial;
render_mode cull_disabled;

void fragment() {
	ALBEDO = COLOR.rgb;
	METALLIC = UV.x;
	ROUGHNESS = UV.y;
}
