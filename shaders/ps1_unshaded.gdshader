shader_type spatial;
render_mode unshaded;

uniform vec4 albedo_color : source_color = vec4(0.1, 0.1, 0.12, 1.0);
uniform float vertex_snap : hint_range(16.0, 256.0) = 64.0;

void vertex() {
	vec4 mv_pos = MODELVIEW_MATRIX * vec4(VERTEX, 1.0);
	mv_pos.xyz = floor(mv_pos.xyz * vertex_snap) / vertex_snap;
	POSITION = PROJECTION_MATRIX * mv_pos;
}

void fragment() {
	ALBEDO = albedo_color.rgb;
}
