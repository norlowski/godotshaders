shader_type spatial;
render_mode depth_draw_opaque;

uniform bool use_debug = false;
uniform bool use_season = false;
uniform vec4 base_albedo : hint_color;
uniform sampler2D season_colors;
uniform float season:hint_range(0, 1.0);
uniform float saturation:hint_range(0, 1.0);
uniform vec3 debug_wind;
uniform vec4 dying_albedo:hint_color;

const float  unique_time_divisor = 1000.0;
uniform float albedo_mix:hint_range(0.0,1.0);
uniform sampler2D albedo_tex : hint_black;
uniform sampler2D normal_tex : hint_black;
uniform sampler2D ao_tex:hint_black;
uniform float ao_light_affect:hint_range(0,1);
uniform float normal_scale:hint_range(-10,10);
uniform float tex_scale:hint_range(0, 10.0);


uniform float metallic:hint_range(0.0,1.0);
uniform float roughness:hint_range(0.0,1.0);


uniform sampler2D dissolve_tex;
uniform float debug_age = 0.0;
uniform float water_ratio =  1.0;
uniform vec4 unhealthy_albedo:hint_color;


uniform vec2 ambient_wind_uv_scale = vec2(1.0,1.0);
uniform float ambient_wind_amplitude = 0.5;//what to multiply wind by
uniform bool is_leaves=true;

uniform sampler2D strength_curve: hint_albedo; //curve to modulate hieght
uniform sampler2D ambient_wind: hint_albedo;
uniform float angle_debug:hint_range(0, 6.3);
const vec3 vert_pivot = vec3(0,0,0);

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
	
	float 	age = INSTANCE_CUSTOM.z;
	if(use_debug){age = debug_age;}
	VERTEX *=age;
	COLOR = INSTANCE_CUSTOM;
	vec3 rotated_wind = rotated_vector(debug_wind, vert_pivot, wind_rot_y);

	angle_x = rotated_wind.x;
	angle_z = rotated_wind.z;
//	if( INSTANCE_CUSTOM.x == 0.0){angle_x = rotated_wind.x;}
//	else{angle_x=INSTANCE_CUSTOM.x;}
//	if( INSTANCE_CUSTOM.z == 0.0){angle_z = rotated_wind.z;}
//	else{angle_z = INSTANCE_CUSTOM.z;}
	
	vec2 wind_uv = (WORLD_MATRIX *vec4(VERTEX,1.0)).xz * -.05;
	//vec2 wind_uv = VERTEX.xz;
	
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
	ROUGHNESS = roughness;
	METALLIC = metallic;
	//vec4 tex = texture(albedo_tex, UV* tex_scale);
	
	vec4 tex = texture(albedo_tex, UV* tex_scale);
	vec4 base_color =  texture(season_colors, vec2(season+COLOR.g/unique_time_divisor));
	base_color *=tex;
	
	AO = dot(texture(ao_tex,UV* tex_scale),vec4(1,0,0,0));
	AO_LIGHT_AFFECT = ao_light_affect;
	
	vec4 season_color =  texture(season_colors, vec2(season) * 0.97);
	
	
	
	
	
	
	
	//ALPHA = 1.1;
	//ALPHA = 1.0;
	if(use_season){
		vec3 alpha = texture(dissolve_tex, UV* 1.1).rgb;
		
		ALBEDO = mix(tex, season_color, albedo_mix).rgb * saturation;
		
		float _dissolve_amt = 0.0;
		if(season<.2){
			//ALPHA = clamp(season - alpha.r * .1,0.0,1.0);
		}
		if(season>.8){
			//ALPHA = clamp(1.0-season - alpha.r * .1,0.0,1.0);
		}
			
	}else{
		ALBEDO = mix(tex.rgb, base_albedo.rgb, albedo_mix).rgb * saturation;
		
	}
	
	if(COLOR.r > 0.0){
	EMISSION = ALBEDO.rgb;
	}
	float _water_ratio = COLOR.a;
	if(use_debug){_water_ratio = water_ratio;}
	
	//ALBEDO  = mix(ALBEDO,unhealthy_albedo.rgb,(1.0-_water_ratio)) ;
	
	if(is_leaves && COLOR.r > 1.9  && COLOR.r < 2.1){
		ALBEDO  = dying_albedo.rgb;//mix(ALBEDO,dying_albedo.rgb,(sin(TIME*7.0)+1.0))+1.0 ;	
		//ALPHA = dying_albedo.a;
	}
	else{
		ALBEDO  = mix(ALBEDO,unhealthy_albedo.rgb,(1.0-_water_ratio)) ;
		}
	
	
	
}