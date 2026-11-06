shader_type canvas_item;
// Vertical 3-stop sky gradient with soft moving light bands and vignette.
uniform vec4 top : source_color = vec4(0.1, 0.3, 0.2, 1.0);
uniform vec4 mid : source_color = vec4(0.2, 0.5, 0.3, 1.0);
uniform vec4 bottom : source_color = vec4(0.6, 0.9, 0.5, 1.0);
uniform float light : hint_range(-0.5, 0.5) = 0.0;
uniform float bands : hint_range(0.0, 1.0) = 0.5;
uniform float vignette : hint_range(0.0, 1.0) = 0.45;

void fragment() {
	float y = UV.y;
	vec3 c = y < 0.5 ? mix(top.rgb, mid.rgb, y * 2.0) : mix(mid.rgb, bottom.rgb, (y - 0.5) * 2.0);
	float band = sin(UV.x * 3.0 + TIME * 0.15) * sin(UV.y * 4.0 - TIME * 0.1) * 0.5 + 0.5;
	c += vec3(band * 0.06 * bands) + vec3(light);
	vec2 q = UV - 0.5;
	float v = smoothstep(0.35, 0.95, length(q * vec2(1.0, 0.8)));
	c *= 1.0 - v * vignette;
	COLOR = vec4(c, 1.0);
}
