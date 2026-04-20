shader_type spatial;

// ── Appearance parameters (editable in the Inspector) ─────────────────────────
uniform vec4  ball_color    : source_color = vec4(0.82, 0.36, 0.07, 1.0);
uniform vec4  seam_color    : source_color = vec4(0.07, 0.04, 0.02, 1.0);
uniform float seam_width    : hint_range(0.005, 0.15)  = 0.04;
uniform float pebble_amount : hint_range(0.0,  0.12)   = 0.055;
uniform float roughness_val : hint_range(0.0,  1.0)    = 0.78;
uniform float specular_val  : hint_range(0.0,  1.0)    = 0.22;

// Model-space vertex position, interpolated across the triangle in the
// fragment shader.  Using local space (not world/view) means the pattern
// rotates exactly with the ball's physics transform.
varying vec3 local_pos;

void vertex() {
	local_pos = VERTEX;
}

// ── Basketball seam geometry ──────────────────────────────────────────────────
// A real basketball has four seam curves forming 8 roughly equal panels.
// 1. The y=0 plane
// 2. The x=0 plane
// 3+4.  Each quadrant is almost the line x=7, but as we reach the origin it plunges to the x axis
//       This is modelled by a straight line x=y for (x+y)>c; and a circular segment of radius c/sqrt(2) and center (c,0)

const float sq2 = sqrt(2);

float seam_distance(vec3 p) {
	vec3  n  = normalize(p);

	// focus on positive quadrant
	float ax = abs(n.x);
	float ay = abs(n.y);
	
	float c = 0.6;
	// if these are large enough then just use straight line ax=ay
	
	float dd;
	if (ax + ay > c) {
		// radial segment
		dd = abs(ax-ay)/sq2;	
	} else {
		// circular segment, centre (c, 0)
		float cax = c - ax;
		float distC = sqrt(cax*cax + ay*ay);
		dd = abs(distC - c/sq2);
	}
	
	//float distPrimaryDiagonal = abs(n.x-n.y);
	
	return min(min(ax, ay), dd);
}

// ── 3-D value noise for the pebbled rubber surface ────────────────────────────
float hash3(vec3 p) {
	return fract(sin(dot(p, vec3(127.1, 311.7, 74.7))) * 43758.5453);
}

float value_noise(vec3 p) {
	vec3 i = floor(p);
	vec3 f = fract(p);
	f = f * f * (3.0 - 2.0 * f);   // smoothstep blend

	return mix(
		mix(mix(hash3(i),               hash3(i + vec3(1,0,0)), f.x),
		    mix(hash3(i + vec3(0,1,0)), hash3(i + vec3(1,1,0)), f.x), f.y),
		mix(mix(hash3(i + vec3(0,0,1)), hash3(i + vec3(1,0,1)), f.x),
		    mix(hash3(i + vec3(0,1,1)), hash3(i + vec3(1,1,1)), f.x), f.y),
		f.z);
}

void fragment() {
	// ── Seam lines ────────────────────────────────────────────────────────────
	float d    = seam_distance(local_pos);
	float seam = 1.0 - smoothstep(0.0, seam_width, d);   // 1 on seam, 0 off

	// ── Pebbled surface ───────────────────────────────────────────────────────
	// Two octaves of value noise scaled to ~28 cycles across the ball surface.
	vec3  np     = normalize(local_pos) * 28.0;
	float pebble = (value_noise(np) * 0.65 + value_noise(np * 2.1) * 0.35)
	               * pebble_amount;

	// ── Combine ───────────────────────────────────────────────────────────────
	vec3 color = mix(ball_color.rgb, seam_color.rgb, seam) + pebble;

	ALBEDO    = clamp(color, 0.0, 1.0);
	ROUGHNESS = roughness_val + seam * 0.12;
	SPECULAR  = specular_val  * (1.0 - seam * 0.6);
}
