shader_type canvas_item;

const float DX_SAMPLE_DISTANCE = 0.01;
const int RAYMARCH_MAX_ITER = 50;
const float RAYMARCH_MAX_TRAVEL = 10.;
const float RAYMARCH_COLLIDE = 0.001;

uniform vec3 light_col : source_color = vec3(1.);
uniform vec3 dark_col : source_color = vec3(0.1);
uniform vec3 background_col : source_color = vec3(0.);

uniform vec3 light_pos = vec3(0,2,0);
uniform vec3 camera_position = vec3(0,0,-1.);
uniform vec2 resolution = vec2(128.);
uniform float fov = 50.;

float sdSphere(vec3 o, float r, vec3 p){
	return length(p - o) - r;
}

vec2 rotate(vec2 v, float t){
	float s = sin(t);
	float c = cos(t);
	mat2 rot = mat2(vec2(c,-s),vec2(s,c));
	return v * rot;
}

float scene(vec3 p){
	float d = sdSphere(vec3(0.),0.4,p);
	d = min(d, sdSphere(light_pos,0.1,p));
	return d;
}

//local difference
vec3 get_normal(vec3 p){
	vec2 e = vec2(DX_SAMPLE_DISTANCE,0.);
	float d = scene(p);
	vec3 n = d - vec3(
		scene(p-e.xyy),
		scene(p-e.yxy),
		scene(p-e.yyx));
	return normalize(n);
}

float raymarch(vec2 uv, vec3 basis){
	vec3 p = camera_position;
	
	float d = scene(p);//initial distance to the scene
	float t = 0.;//distance travelled
	vec3 normal = vec3(0);
	
	for (int i = 0; i < RAYMARCH_MAX_ITER; i++){
		p += basis * d;//move forward in the direction of basis by distance to the scene
		t += d;
		d = scene(p);//get new distance to scene
		//if collision occurs or ray has travelled too far, break loop and return
		if(d < RAYMARCH_COLLIDE || t > RAYMARCH_MAX_TRAVEL){
			normal = get_normal(p);
			break;
		}
	}
	return t;// return distance travelled
}

void fragment() {
	vec2 uv = (2. * UV) -1.;
	vec3 basis = vec3(0,0,1);
	
	basis = normalize(vec3(uv.x, uv.y, 1));//this works
	
	float depth = raymarch(uv,basis);
	vec3 p = basis * depth;
	vec3 normal = get_normal(p);
	vec3 light_dir = normalize(light_pos - p);
	float light_strength = dot(normal,light_dir);
	
	vec2 grid_uv = fract(uv * 5.);//for drawing background grid
	grid_uv.x = fract(grid_uv.x + 0.5 * step(grid_uv.y,0.5));//yeah it works
	vec3 col = mix(vec3(0),vec3(1,0,1),step(grid_uv.x,0.5));
	
	if(depth < RAYMARCH_MAX_TRAVEL){
		col = mix(dark_col,light_col,light_strength);
	}
	
	//col = vec3(depth / RAYMARCH_MAX_TRAVEL);
	COLOR = vec4(col,1.);
}
