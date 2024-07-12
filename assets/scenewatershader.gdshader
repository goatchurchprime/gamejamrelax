shader_type spatial;
render_mode unshaded, blend_mix, depth_draw_opaque, cull_back, diffuse_burley, specular_schlick_ggx;

uniform float timeoffset = 0.3;
uniform float timemod = 0.2;
uniform float timefac = 0.2;
uniform float watercutoff = 1.0;
uniform float jaggy = 0.3;

varying vec3 p;
void vertex() {
	p = VERTEX;
}

void fragment() {
	if ((p.z > 0.0) || (p.z > -watercutoff + jaggy*(sin(p.x*10.0 + p.y*7.0))))
		discard;
	ALBEDO = COLOR.rgb*2.0;
	if (abs(COLOR.r - (mod((TIME+timeoffset)*timefac,timemod)-0.05)) < 0.01)
		ALBEDO = ALBEDO*0.8 + vec3(0.2);
}
