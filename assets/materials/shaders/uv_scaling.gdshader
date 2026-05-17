shader_type spatial;

uniform sampler2D main_tex;
uniform float max_dist = 50;
uniform float min_dist = 10;
uniform float res_high = 16.0;
uniform float res_low = 2.0;

void fragment () {
	vec3 world_camera = (VIEW_MATRIX * vec4(vec3(0.0), 1.0)).xyz;
	vec4 a = VIEW_MATRIX * vec4(VERTEX, 1.0);
	vec3 low_tex = texture(main_tex, UV * res_low).rgb;
	vec3 hi_tex = texture(main_tex, UV * res_high).rgb;
	ALBEDO = mix(hi_tex, low_tex, smoothstep(min_dist, max_dist, distance(a.xyz, world_camera)));
}