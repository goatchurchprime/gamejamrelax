shader_type spatial;

uniform vec4 albedo: source_color = vec4(1.0, 1.0, 1.0, 0.4);
uniform float fade_offset : hint_range(-0.1, 0.1, 0.001) = 0.0;
uniform float fade_sharpness : hint_range(0.0, 35.0, 0.01) = 15.00;
uniform vec3 orbcentrerelativetohand = vec3(0.0);
uniform float orbrad = 0.0;
uniform vec4 orbbrightcolour: source_color = vec4(1.0, 0.0, 0.0, 0.9);
uniform float orbdropoff = 0.02;

varying vec3 vertex_pos;

void vertex() {
	vertex_pos = VERTEX;
}

float fresnel(float amount, vec3 normal, vec3 view)
{
	return pow((1.0 - clamp(dot(normalize(normal), normalize(view)), 0.0, 1.0 )), amount);
}

void fragment()
{
	float basic_fresnel = fresnel(3.0, NORMAL, VIEW);
	ALBEDO = albedo.xyz + basic_fresnel;
	ALPHA = albedo.w + basic_fresnel;

	vec3 vertorbvec =  vertex_pos - orbcentrerelativetohand;
	float orbcentredistance = length(vertorbvec);
	if ((orbcentredistance >= orbrad) && (orbcentredistance <= orbrad + orbdropoff))
		ALBEDO = mix(ALBEDO, orbbrightcolour.rgb, orbbrightcolour.a);

	ALPHA = clamp((-vertex_pos.z - fade_offset) * fade_sharpness, 0.00, ALPHA);
}