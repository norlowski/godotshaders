shader_type spatial;
render_mode depth_draw_opaque;

uniform bool use_debug = false;
uniform float season:hint_range(0, 1.0);
uniform sampler2D season_colors;
uniform float alpha_scissor = .1;
uniform float saturation = .5;
uniform vec3 debug_wind;
uniform vec4 dying_albedo:hint_color;


uniform float albedo_mix:hint_range(0.0,1.0);
uniform sampler2D albedo_tex : hint_black;
uniform sampler2D normal_tex : hint_black;
uniform sampler2D ao_tex:hint_black;
uniform float ao_light_affect:hint_range(0,1);
uniform float normal_scale:hint_range(-10,10);
uniform float tex_scale:hint_range(0, 10.0);


uniform sampler2D dissolve_tex;
uniform float debug_age = 0.0;
uniform float water_ratio:hint_range(0.0,1.0) =  1.0;
uniform vec4 unhealthy_albedo:hint_color;
uniform vec4 test_albedo:hint_color;
uniform vec2 ambient_wind_uv_scale = vec2(1.0,1.0);
uniform float ambient_wind_amplitude = 0.5;//what to multiply wind by
uniform sampler2D strength_curve: hint_albedo; //curve to modulate hieght
uniform sampler2D ambient_wind: hint_albedo;
uniform float angle_debug:hint_range(0, 6.3);
const vec3 vert_pivot = vec3(0,0,0);
const float unique_time_divisor = 4000.0;


vec3 rotated_vector(vec3 v3, vec3 pivot, float angle)
{
    mat3 rotation_matrix=mat3(  vec3(cos(angle),0,sin(angle)),
						       vec3(0,1.0,0.0),
                                vec3(-sin(angle),0,cos(angle))
                                );
    v3 -= pivot;
    v3= v3*rotation_matrix;
    v3 += pivot;
    return v3;
}

void vertex() {
	float angle_x;
	float angle_z;
	float wind_rot_y = angle_debug;
	if(INSTANCE_CUSTOM.y!= 0.0){wind_rot_y=INSTANCE_CUSTOM.y;}
	
	float age = INSTANCE_CUSTOM.z;
	if(use_debug){age = debug_age;}
	VERTEX *=age;
	COLOR = INSTANCE_CUSTOM;
	
	vec3 rotated_wind = rotated_vector(debug_wind, vert_pivot, wind_rot_y);

	angle_x = rotated_wind.x;
	angle_z = rotated_wind.z;
	vec2 wind_uv = (WORLD_MATRIX *vec4(VERTEX,1.0)).xz * -.05;	
	wind_uv+= vec2(TIME, TIME) *ambient_wind_uv_scale;
	angle_x *= texture(ambient_wind, wind_uv).r;
	angle_z *= texture(ambient_wind, wind_uv).y;
	float mod_y = texture(strength_curve,vec2(VERTEX.y, 0.0)).r * VERTEX.y;
	float theta_x = angle_x * mod_y * ambient_wind_amplitude;
	float theta_z = angle_z * mod_y  * ambient_wind_amplitude;
	mat3 bendy_rot_matrix_x = mat3(
		vec3(cos(theta_x), -sin(theta_x), 0.0),
		vec3(sin(theta_x), cos(theta_x), 0.0),
		vec3(0,0,1));
	mat3 bendy_rot_matrix_z = mat3(
		vec3(1,0,0),
		vec3(0.0,cos(theta_z), -sin(theta_z)),
		vec3(0.0,sin(theta_z), cos(theta_z)));
	VERTEX = bendy_rot_matrix_x * VERTEX;
	VERTEX = bendy_rot_matrix_z * VERTEX;
}

void fragment(){
	
	
	if(COLOR.r > 1.9  && COLOR.r < 2.1){
		ALBEDO  = dying_albedo.rgb;//mix(ALBEDO,dying_albedo.rgb,(sin(TIME*7.0)+1.0))+1.0 ;	
		discard;
		return;
		//ALPHA = dying_albedo.a;
	}
	ROUGHNESS = 1.0;
	METALLIC = 0.0;
	vec4 tex = texture(albedo_tex, UV* tex_scale);
	vec4 base_color =  texture(season_colors, vec2(season+COLOR.g/unique_time_divisor));
	base_color *=tex;
	float _water_ratio = COLOR.a;
	if(use_debug){_water_ratio = water_ratio;}
	NORMALMAP = texture(normal_tex,UV* tex_scale).rgb;
	NORMALMAP_DEPTH = normal_scale;
	AO = dot(texture(ao_tex,UV* tex_scale),vec4(1,0,0,0));
	AO_LIGHT_AFFECT = ao_light_affect;
	
	ALBEDO = mix(unhealthy_albedo.rgb,base_color.rgb ,_water_ratio);

		float dissolve_value = texture(dissolve_tex, UV+COLOR.g/unique_time_divisor ).r  *2.0 ;
		float alpha = mix( 0.0,dissolve_value, base_color.a);
		if(alpha < .1){discard;}	
	
	if(COLOR.r > 0.0){
		EMISSION = ALBEDO.rgb;
	}

	if(COLOR.r > 1.9  && COLOR.r < 2.1){
		ALBEDO  = dying_albedo.rgb;//mix(ALBEDO,dying_albedo.rgb,(sin(TIME*7.0)+1.0))+1.0 ;	
	}
	else{
		ALBEDO  = mix(ALBEDO,unhealthy_albedo.rgb,(1.0-_water_ratio)) ;
		}

	
	
}