shader_type canvas_item;
uniform float strength : hint_range(0.0, 1.0) = 0.0;
uniform vec4 tint : source_color = vec4(1.0, 0.1, 0.1, 1.0);
void fragment() {
	vec2 q = UV - 0.5;
	float v = smoothstep(0.25, 0.8, length(q));
	COLOR = vec4(tint.rgb, v * strength);
}
