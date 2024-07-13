shader_type spatial;
render_mode world_vertex_coords,blend_mix,depth_draw_opaque,cull_back,diffuse_burley,specular_schlick_ggx,unshaded;

uniform vec4 albedo : source_color;
uniform float point_size : hint_range(0,128) = 15.0;

const vec3 closecol = vec3(1,1,1);
uniform vec3 farcol = vec3(0.1,0.1,0.8);
const float fardist = 9.0;
const float fardisttaper = 2.0;
const float fardisttaperfac = -(fardisttaper*((fardisttaper + fardist)))/fardist;
uniform float colormixweight = 0.05;
const vec3 bordercolor = vec3(0.1, 0.1, 0.2);

varying float outertrimradsq;
void vertex() {
	float distcamera = length(CAMERA_POSITION_WORLD - VERTEX);
	POINT_SIZE = point_size/distcamera;
	//POINT_SIZE = 40.0;
	if (COLOR.r > 0.9)
		POINT_SIZE *= (1.0 - COLOR.r)*10.0;

	float mixval = (1.0/(distcamera + fardisttaper) - 1.0/fardisttaper)*fardisttaperfac;
	//vec3 distancecolor = mix(closecol, farcol, mixval);
	//COLOR.rgb = mix(distancecolor, COLOR.rgb, colormixweight);
	const vec3 nearcol = vec3(1.0);
	COLOR.rgb = mix(nearcol, farcol, mixval);
	NORMAL = vec3(0.0,1.0,0.0);
}


void fragment() {
	vec2 base_uv = UV;
	ALBEDO = albedo.rgb * COLOR.rgb;
	METALLIC = 0.0;
	ROUGHNESS = 0.0;
	SPECULAR = 0.0;
	ALPHA *= albedo.a * COLOR.a;

	float rsq = (POINT_COORD.x-0.5)*(POINT_COORD.x-0.5) + (POINT_COORD.y-0.5)*(POINT_COORD.y-0.5);
	if (rsq > 0.25)
		discard;

	//ALPHA = 0.6*mix(1.0, 0.0, rsq*4.0);
	//ALBEDO *= mix(vec3(1.0, 1.0, 1.0), bordercolor, rsq*3.0);
	ALPHA *= mix(1.0, 0.0, abs(cos((1.0+rsq*8.0)))) + 0.1;

}
