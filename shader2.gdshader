shader_type canvas_item;
//fuelled by crack magic
uniform sampler2D noise;
uniform sampler2D cloud_noise;
uniform sampler2D ocean_gradient;
uniform sampler2D cool_land_gradient;
uniform sampler2D warm_land_gradient;
uniform sampler2D ice_gradient;

uniform int noise_feedback = 1;
uniform float feedback_grain = 2;
uniform float color_bands;

uniform float cloud_opacity = 0.3;
uniform float cloud_warp = 0;
uniform float sea_level;
uniform float temp_multiplier;
uniform float freeze_temp = 0.3;

uniform float rotation;//view rotation
uniform vec2 offset;
uniform float turn_rate;
uniform float cloud_speed = 0.01;
uniform float axis;
const vec2 center = vec2(0.5);

uniform float normal_coeff;
uniform float light_angle;
uniform float light_exp;

const float RAYMARCH_MAX_TRAVEL = 2.;
float sdSphere( vec3 p, float s ){
  return length(p)-s;
}

void fragment() {
	vec3 sphere_col = vec3(1.);
	vec3 col = vec3(0.);
	vec2 uv = 2. * (UV - 0.5);//allow it
	vec3 p = vec3(uv,-1.);
	float d = sdSphere(p,1.);
	float t = 0.;
	while(t < 5.){
		p.z += d;
		t += d;
		if(t > 5.){
			discard;
		}
		if(d < 0.05){
			col = sphere_col;
			break;
		}
		d = sdSphere(p,1.);
	}
	
	
	COLOR = vec4(col,1.);
}

