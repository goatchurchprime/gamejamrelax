shader_type spatial;
render_mode unshaded, blend_mix, depth_draw_opaque, cull_back, diffuse_burley, specular_schlick_ggx;

void vertex() {
}

void fragment() {
	vec2 base_uv = UV;
	ALBEDO = COLOR.rgb*4.0;
	ROUGHNESS = 1.0;
}
