shader_type canvas_item;
//fueled by crack

#define wrap(v , high, low) mod(v - low, high - low) + low

uniform highp vec2 texture_size;

uniform sampler2D noise;
uniform sampler2D cloud_noise;
uniform sampler2D ocean_gradient;
uniform sampler2D cool_land_gradient;
uniform sampler2D warm_land_gradient;
uniform sampler2D ice_gradient;
uniform sampler2D cloud_gradient;

uniform int noise_feedback = 1;
uniform float feedback_grain = 2;
uniform float color_bands;

uniform float cloudiness = 0.3;
uniform float cloud_opacity = 1.;
uniform float cloud_threshhold = 0.8;
uniform float cloud_layers = 100.;
uniform float cloud_warp = 0;
uniform float cloud_normal_coeff = 0.;

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
uniform vec3 light_dir;
uniform float light_exp;

const vec3 RENDER_CAM_POS = vec3(0,0,1);

//bilinear interpolation
float bilerp(float p1, float p2, float p3, float p4, float w1, float w2){
	float c1 = mix(p1, p2, w1);
	float c2 = mix(p3, p4, w1);
	return mix(c1, c2, w2);
}

//rotate vector v by angle t in radians
vec2 rotate(vec2 v, float t){
	float c = cos(t);
	float s = sin(t);
	mat2 rot = mat2(vec2(c,s),vec2(-s,c));
	return v * rot;
}
//i really don't know
float get_dist(vec2 uv){
	return RENDER_CAM_POS.z - (cos(uv.x) + cos(uv.y)) / 2.;
}

//maps a point on the screen to a point on the sphere surface, in UV space
//input range is -1 to 1
vec2 map2sphere(vec2 vec){
	return vec2((asin(vec.x / sqrt(1. - (vec.y * vec.y))) / (TAU) ) ,//RANGE -0.5 to 0.5
	asin(vec.y) / (PI)) ;//RANGE -1 to 1
}

//same steps used in fragment(). isolated to for ease of use. fragment still needs to apply these
//manually as there are some in-between steps
vec2 get_surface_uv(vec2 uv){
	vec2 surf_uv = rotate(uv, axis);
	surf_uv  = map2sphere(surf_uv);//map surf_uv
	surf_uv = rotate(TIME * vec2(turn_rate,0),rotation) + offset + rotate(surf_uv,rotation);
	surf_uv = wrap(surf_uv,vec2(0),vec2(1));
	return surf_uv;
}

float get_noise(vec2 p, int octaves){
	p = wrap(p,vec2(0),vec2(1));
	float t = texture(noise,p).x;
	for (int i = 1; i < octaves; i++){
		p = wrap( p * vec2(float(i) * (feedback_grain)) ,vec2(0),vec2(1));
		t += texture(noise,p).x / float(i);
		p = rotate(p,PI/2.);
		
	}
	
	//strong crack was smoked here
	return t / sqrt(float(octaves));
}

float get_elevation(vec2 p){
	return get_noise(p,noise_feedback);
}

void fragment() {
	vec2 px = 1. / texture_size ;
	vec3 col = vec3(1.);
	vec2 uv = 2. * (UV - center);//normalized UV -1 to 1
	//discard if farther than sphere radius
	if (length(uv) > 1.){
		discard;
	}
	float light_strength = 0.;
	vec2 surf_uv = rotate(uv, axis);//texture uv on sphere surface
	surf_uv  = map2sphere(surf_uv);//map surf_uv
	vec2 cloud_surf_uv = surf_uv ;//copy surf_uv for clouds. seperate transformation later
	float longitude = 2.*surf_uv.y;// -1 = south pole, 1 = north pole
	
	surf_uv = rotate(TIME * vec2(turn_rate,0),rotation) + offset + rotate(surf_uv,rotation);
	surf_uv = wrap(surf_uv,vec2(0),vec2(1));

	float cloud_offset = mix(0,smoothstep(0,1,(longitude+1.)/2.) / 1000.,cloud_warp);
	cloud_surf_uv =  wrap((TIME * vec2(cloud_speed + turn_rate - cloud_offset,0)) + cloud_surf_uv + offset,vec2(0),vec2(1));
	

	float t = get_elevation(surf_uv);
	float temperature = pow(1. - abs(longitude),1.5) * temp_multiplier;//1 at equator, 0 at poles, before mult
	temperature -= pow(t,2.) * 0.9;//get colder at extreme elevations
	
	float dist = get_dist(uv);
	//beware of crack smoking
	vec3 p = RENDER_CAM_POS + vec3(uv,-dist);
	vec3 cloud_p = p;
	vec3 sphere_normal = p;
	p += sphere_normal * t * normal_coeff;
	vec3 p1 = p + dFdx(p);
	vec3 p2 = p + dFdy(p);
	vec3 C = normalize((p + p1 + p2) / vec3(3.0));
	vec3 surf_normal = normalize(cross(p1 - p, p2 - p));
	if( dot(surf_normal, C) <=  dot(-surf_normal,C)){
		surf_normal = -surf_normal;
	}

	bool freeze = bool(step(temperature ,freeze_temp));
	float depth;//used for color mixing
	if(freeze){
		t += sea_level;
		depth = pow(t,2.);
		col = texture(ice_gradient,vec2(depth,0.5)).rgb;
	}
	else if (t <= sea_level){// if below sea level
		surf_normal = mix(surf_normal,sphere_normal,0.6);
		float depth = t / sea_level;//0 is ocean floor,1 is sea level
		depth = floor(depth * color_bands + 1.) / color_bands;
		col = texture(ocean_gradient,vec2(depth,0.5)).rgb;
	}
	else{// if above sea level
		float depth = (t - sea_level)/(1. - sea_level);
		float exaggerate = 2.;
		depth = min(pow(depth * exaggerate,2.) / exaggerate ,1.);//slightly exaggerate landscape
		depth = floor(depth * color_bands + 1.) / color_bands;
		
		col = texture(cool_land_gradient,vec2(depth,0.5)).rgb;
		col = mix(col, texture(warm_land_gradient,vec2(depth,0.5)).rgb,temperature);
		
	}
	
	float cloud = texture(cloud_noise,cloud_surf_uv).x * cloudiness;
	cloud_p += sphere_normal * cloud * cloud_normal_coeff;
	vec3 cloud_p1 = cloud_p + dFdx(cloud_p);
	vec3 cloud_p2 = cloud_p + dFdy(cloud_p);
	vec3 cloud_C = normalize((cloud_p + cloud_p1 + cloud_p2) / vec3(3.0));
	vec3 cloud_normal = normalize(cross(cloud_p1 - cloud_p, cloud_p2 - cloud_p));
	if( dot(cloud_normal, cloud_C) <=  dot(-cloud_normal,cloud_C)){
		cloud_normal = -cloud_normal;
	}
	
	cloud *= smoothstep(0,0.05,cloud);//idk
	cloud = floor((cloud ) * cloud_layers) / cloud_layers;
	float cloud_mix = min(cloud * cloud_opacity,1.);
	float cloud_light = max(dot(normalize(light_dir),cloud_normal),0.);
	if(cloud > cloud_threshhold){
		cloud_mix = 1.;
	}
	col  = mix(col,texture(cloud_gradient,vec2(cloud,0.)).rgb,cloud_mix);
	
	//mix between bumpy normal and smooth normal
	float smooth_lighting = max(dot(normalize(light_dir),sphere_normal),0.);//smooth. this value also happens to make a nice weight for mixing
	float bumpy_lighting = max(dot(normalize(light_dir),surf_normal),0.);//bumpy
	bumpy_lighting = mix(bumpy_lighting,cloud_light,cloud_mix);
	light_strength = mix(smooth_lighting,bumpy_lighting,min(smooth_lighting,1.) );//mix. i am extremely smart
	
	col = min(col,vec3(1));
	col = mix(col * 0.03,col, pow(light_strength,light_exp) );
	

	
	//-----------debug lines. uncomment individual lines to draw some info---------------
	//col = vec3(t);//raw elevation after processing
	//col = vec3(mix(vec2(1.),surf_uv,step(max(abs(surf_uv.x),abs(surf_uv.y)),0.999)),0);//mapped surf_uv with outline
	
	//col = texture(noise,wrap(5.*surf_uv ,vec2(0),vec2(1))).rgb;
	//col = vec3(surf_uv,0);
	//col = sphere_normal;
	//col = vec3(uv,1.);

	//------------final color application------------------
	
	COLOR = vec4(col,1.);
}
