shader_type spatial;
render_mode cull_back;

uniform vec4 paint : source_color = vec4(0.10,0.53,0.50,1.0);
uniform sampler2D grain : repeat_enable, filter_linear_mipmap;
uniform vec4 dirt_a = vec4(1.0);
uniform vec4 dirt_b = vec4(1.0);
uniform vec4 dirt_c = vec4(1.0);
varying vec2 shell;

void vertex() {
	shell = vec2(VERTEX.x / 1.72 + 0.5, VERTEX.z / 3.62 + 0.5);
}

float stain(int index) {
	if (index < 4) {
		return dirt_a[index];
	}
	if (index < 8) {
		return dirt_b[index - 4];
	}
	return dirt_c[index - 8];
}

void fragment() {
	vec2 texture_data = texture(grain, (shell + vec2(0.11,0.0)) * vec2(1.63,2.11)).rg;
	vec2 map = clamp(shell * vec2(3.0,4.0) - 0.5, vec2(0.0), vec2(1.999,2.999));
	ivec2 nearest = ivec2(floor(map));
	int corner = 3 * nearest.y + nearest.x;
	vec2 fade = smoothstep(vec2(0.12), vec2(0.87), fract(map));
	float row_a = mix(stain(corner), stain(corner + 1), fade.x);
	float row_b = mix(stain(corner + 3), stain(corner + 4), fade.x);
	float soil = mix(row_a, row_b, fade.y);
	float dust = clamp(soil * (0.51 + (texture_data.r + texture_data.g) * 0.40), 0.0, 0.94);
	vec3 base = mix(paint.rgb * COLOR.rgb, vec3(0.30,0.18,0.085) * (0.62 + 0.62 * texture_data.g), dust);
	ALBEDO = base;
	METALLIC = mix(0.18, 0.02, dust);
	ROUGHNESS = mix(0.26, 0.92, dust);
}
