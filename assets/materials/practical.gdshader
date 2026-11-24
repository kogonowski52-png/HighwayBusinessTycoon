shader_type spatial;

void fragment() {
	ALBEDO = COLOR.rgb;
	EMISSION = COLOR.rgb * 0.54;
	ROUGHNESS = 0.42;
}
