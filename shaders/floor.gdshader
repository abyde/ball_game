shader_type spatial;

uniform vec4 base_color : source_color = vec4(0.8, 0.8, 0.8, 1.0);
uniform vec4 line_color : source_color = vec4(0.35, 0.35, 0.35, 1.0);
uniform float line_width : hint_range(0.005, 0.25) = 0.05;

// World-space position so grid lines stay aligned across multiple floor pieces.
varying vec3 world_pos;

void vertex() {
	world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

// Returns 1.0 on a grid line, 0.0 away from it.
float grid_line(float coord) {
	float f      = fract(coord);
	float d      = min(f, 1.0 - f);
	float half_w = line_width * 0.5;
	float aa     = fwidth(coord) * 1.5;
	return 1.0 - smoothstep(half_w - aa, half_w + aa, d);
}

void fragment() {
	float on_line = max(grid_line(world_pos.x), grid_line(world_pos.z));

	ALBEDO    = mix(base_color.rgb, line_color.rgb, on_line);
	ROUGHNESS = 0.9;
	METALLIC  = 0.0;
}
