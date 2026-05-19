shader_type canvas_item;

uniform float scanline_intensity : hint_range(0.0, 1.0) = 0.25;
uniform float noise_intensity : hint_range(0.0, 1.0) = 0.08;
uniform float vignette : hint_range(0.0, 1.0) = 0.35;
uniform float corruption : hint_range(0.0, 1.0) = 0.0;
uniform vec4 tint_color : source_color = vec4(0.7, 0.9, 0.7, 1.0);

float rand(vec2 co) {
	return fract(sin(dot(co.xy, vec2(12.9898, 78.233))) * 43758.5453);
}

void fragment() {
	vec2 uv = UV;
	vec4 base = texture(TEXTURE, uv);

	float scan = sin(uv.y * 800.0) * 0.5 + 0.5;
	base.rgb *= 1.0 - scanline_intensity * scan;

	float n = rand(uv + TIME * 0.5);
	base.rgb += (n - 0.5) * noise_intensity;

	float dist = distance(uv, vec2(0.5));
	base.rgb *= 1.0 - dist * vignette;

	if (corruption > 0.01 && rand(vec2(floor(uv.y * 80.0), TIME)) < corruption * 0.15) {
		base.r = base.g;
	}

	base.rgb *= tint_color.rgb;
	COLOR = base;
}
