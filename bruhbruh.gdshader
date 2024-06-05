shader_type canvas_item;

#define wrap(v , high, low) mod(v - low, high - low) + low

uniform sampler2D noise;

uniform float brighten  = 1.;
uniform float darken_exp = 1.;
uniform float grain_rotate = 0.;
uniform float grain = 0.5;
uniform int octaves = 1;

vec2 rotate(vec2 v, float t){
	float c = cos(t);
	float s = sin(t);
	mat2 rot = mat2(vec2(c,s),vec2(-s,c));
	return v * rot;
}
float bilerp(float p1, float p2, float p3, float p4, float w1, float w2){
	float c1 = mix(p1, p2, w1);
	float c2 = mix(p3, p4, w1);
	return mix(c1, c2, w2);
}
float get_noise(vec2 p){
	p = wrap(p,vec2(0),vec2(1));
	vec2 p2;
	vec2 pp;
	vec2 center_offset = vec2(0.5);
	float t = 0.;
	vec2 d = vec2(1);
	#define grain_coeff (p + grain * float(i) * d )
	for (int i = 1; i < octaves + 1; i++){
		
		d = vec2(1);
		p2 = wrap(grain * p + grain_coeff ,vec2(0),vec2(1));
		float t1 = texture(noise,p2).x;
		d = vec2(-1,1);
		p2 = wrap(grain * p + grain_coeff ,vec2(0),vec2(1));
		float t2 = texture(noise,p2).x;
		d = vec2(1,-1);
		p2 = wrap(grain * p + grain_coeff ,vec2(0),vec2(1));
		float t3 = texture(noise,p2).x;
		d = -vec2(1);
		p2 = wrap(grain * p + grain_coeff ,vec2(0),vec2(1));
		float t4 = texture(noise,p2).x;
		
		t += bilerp(t1,t2,t3,t4,p.x,p.y) / float(i);
		p = (rotate(p - center_offset, grain_rotate) + center_offset);
		center_offset += rotate(vec2(grain), grain_rotate);
		
	}
	//strong crack was smoked here
	return t / float(sqrt(float(octaves)));
}

void fragment() {
	vec2 uv =4. * (UV);
	float t = get_noise(uv);
	t = pow(t, darken_exp);
	//t -= 5. * dFdx(t);//bump highlighting
	vec3 col = brighten * vec3(pow(t,1));
	COLOR = vec4(col,1.);
}

