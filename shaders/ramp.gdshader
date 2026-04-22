shader_type spatial;
// render_mode blend_mix, depth_draw_opaque, cull_back;

uniform vec4 tint : source_color = vec4(0.1, 0.8, 0.6, 1.0);

void fragment() {
	ALBEDO    = tint.rgb;
	ROUGHNESS = 0.15;
	METALLIC  = 0.0;
	ALPHA     = 1.0;
}
