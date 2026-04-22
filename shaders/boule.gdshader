shader_type spatial;

// ── Appearance parameters (editable in the Inspector) ─────────────────────────
uniform vec4  ball_color    : source_color = vec4(0.95, 0.97, 0.98, 1.0);  // steel grey
uniform vec4  ridge_color   : source_color = vec4(0.10, 0.10, 0.11, 1.0);  // dark groove
uniform float ridge_width   : hint_range(0.005, 0.15) = 0.06;
uniform float metallic_val  : hint_range(0.0, 1.0)    = 0.92;
uniform float roughness_val : hint_range(0.0, 1.0)    = 0.08;
// How much the ridges kill the metallic/reflective quality (0 = no effect).
uniform float ridge_depth   : hint_range(0.0, 1.0)    = 0.80;

varying vec3 local_pos;

void vertex() {
	local_pos = VERTEX;
}

// ── Ridge geometry ────────────────────────────────────────────────────────────
// Returns the arc-distance (≈ component magnitude on the unit sphere) to the
// nearest ridge.  Add more great-circle planes here to add more ridges.
//
// Current ridges:
//   x = 0  →  great circle in the YZ plane
//   y = 0  →  great circle in the XZ plane  (equator)
//
// Hint: |n.x| is the sine of the angle from the YZ plane, which equals the
// arc-distance to the great circle for small angles — good enough for seam use.

float ridge_distance_simple(vec3 p) {
	vec3 n = normalize(p);

	float d1 = abs(n.x);   // x = 0  (YZ great circle)
	float d2 = abs(n.y);   // y = 0  (XZ great circle / equator)

	return min(d1, d2);
}

float ridge_distance(vec3 p) {
	vec3 n = normalize(p);

	float sep = 0.2;
	float d1 = min(abs(n.x + sep), abs(n.x - sep));
	float d2 = min(abs(n.y + sep), abs(n.y - sep));
	float d3 = min(abs(n.z + sep), abs(n.z - sep));

	return min(d1, min(d2, d3));
}

void fragment() {
	float d     = ridge_distance(local_pos);
	float ridge = 1.0 - smoothstep(0.0, ridge_width, d);   // 1 on ridge, 0 off

	ALBEDO    = clamp(mix(ball_color.rgb, ridge_color.rgb, ridge), 0.0, 1.0);
	//ALBEDO    = clamp(ball_color.rgb, 0.0, 1.0);
	METALLIC  = 1.0;
	ROUGHNESS = 0.1;
	SPECULAR  = 0.1;
}
