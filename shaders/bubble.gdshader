shader_type canvas_item;
// Adds animated rim shimmer + inner pulse on top of the baked bubble art (volume, specular, fresnel are baked).
uniform float shimmer : hint_range(0.0, 1.0) = 0.35;
uniform float pulse : hint_range(0.0, 1.0) = 0.0;
uniform vec4 danger_tint : source_color = vec4(1.0, 0.25, 0.25, 1.0);
varying vec2 wpos;

void vertex() {
	wpos = (MODEL_MATRIX * vec4(VERTEX, 0.0, 1.0)).xy;
}

void fragment() {
	vec4 tex = texture(TEXTURE, UV);
	vec2 p = UV * 2.0 - 1.0;
	float r = length(p);
	float ph = wpos.x * 0.011 + wpos.y * 0.017;
	float rim = smoothstep(0.62, 0.95, r) * (0.55 + 0.45 * sin(TIME * 2.2 + ph * 3.0));
	float sweep = smoothstep(0.0, 0.12, 0.12 - abs(fract(UV.x * 0.8 + UV.y * 0.6 - TIME * 0.25 + ph) - 0.5)) * 0.0;
	vec3 col = tex.rgb + vec3(rim * shimmer * 0.5);
	col = mix(col, danger_tint.rgb * 1.2, pulse * 0.45 * (0.5 + 0.5 * sin(TIME * 12.0)));
	COLOR = vec4(col, tex.a) * COLOR;
}
