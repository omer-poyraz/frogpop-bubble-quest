shader_type canvas_item;
uniform float speed = 0.6;
void fragment() {
	vec4 tex = texture(TEXTURE, UV);
	vec2 p = UV * 2.0 - 1.0;
	float a = atan(p.y, p.x) / 6.2831853 + 0.5 + TIME * speed;
	vec3 rgb = 0.5 + 0.5 * cos(6.2831853 * (vec3(a) + vec3(0.0, 0.33, 0.67)));
	float lum = dot(tex.rgb, vec3(0.333));
	COLOR = vec4(mix(tex.rgb, rgb * (0.5 + lum), 0.75), tex.a) * COLOR;
}
