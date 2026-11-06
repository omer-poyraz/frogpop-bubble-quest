shader_type canvas_item;
uniform float rate = 2.0;
uniform float amount = 0.25;
void fragment() {
	vec4 tex = texture(TEXTURE, UV);
	float p = 1.0 + amount * (0.5 + 0.5 * sin(TIME * rate));
	COLOR = vec4(tex.rgb * p, tex.a) * COLOR;
}
