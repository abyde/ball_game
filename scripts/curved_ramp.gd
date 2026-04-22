extends StaticBody3D
# Procedural circular prism ramp.
# Builds its own ArrayMesh and ConcavePolygonShape3D from the export parameters.
# Attach this script to a StaticBody3D node; no children needed in the scene.

@export var x_min  : float = 0.0
@export var x_max  : float = 1.0
@export var z_low  : float = 0.0  # z at the low/front end  (y = y_low)
@export var z_high : float = 1.0  # z at the high/back end  (y = y_high)
@export var y_low  : float = 0.0
@export var y_high : float = 1.0
@export var segments : int = 10

# must be less than or equal to PI/2 or weird shit will happen
@export var sweep  : float = PI/4

func _ready() -> void:
	_build()

const sq2 = sqrt(2)

func _build() -> void:
	# we're doing a quarter circle, so z_high is at z_low + z_scale/sqrt(2)
	# ... same for y
	var z_scale = (z_high - z_low)*sq2
	var y_scale = (y_high - y_low)*sq2
	# center is at z_low, y_low + y_scale
	var cy = y_low + y_scale
	var angle_per_face = sweep/segments

	#
	# .
	# |\
	# | \
	# |  \
	# +--^
	# faces must be wound anti-clockwise
	# (segments+1) curve rings; side faces and end face
	var v : Array[Vector3] = []
	var b : Array[Vector3] = []
	# Exact outward-pointing surface normals at each curve ring vertex.
	# At angle a on a cylinder of this orientation: n = (0, cos(a), -sin(a)).
	var vn : Array[Vector3] = []

	var size = 2*(segments+1)
	v.resize(size)
	b.resize(size)
	vn.resize(segments+1)

	for f in segments+1:
		var i = 2*f
		var angle = f * angle_per_face
		v[i]   = Vector3(x_min, cy - y_scale * cos(angle), z_low + z_scale * sin(angle))
		v[i+1] = Vector3(x_max, v[i].y, v[i].z)
		b[i]   = Vector3(x_min, y_low, v[i].z)
		b[i+1] = Vector3(x_max, y_low, v[i].z)
		vn[f]  = Vector3(0.0, cos(angle), -sin(angle))

	# ── Accumulate geometry ───────────────────────────────────────────────────
	var vdata : Array[Vector3] = []
	var ndata : Array[Vector3] = []

	var left  = Vector3(-1.0, 0.0, 0.0)
	var right = Vector3( 1.0, 0.0, 0.0)
	for f in segments:
		var i = 2*f
		# left side, top (smooth), right side
		_quad(vdata, ndata, v[i],   b[i],   b[i+2], v[i+2], left)
		_smooth_quad(vdata, ndata, v[i+1], v[i], v[i+2], v[i+3], vn[f], vn[f+1])
		_quad(vdata, ndata, b[i+3], b[i+1], v[i+1], v[i+3], right)

	# back side
	_quad(vdata, ndata, b[size-2], b[size-1], v[size-1], v[size-2], Vector3(0.0, 0.0, 1.0))

	# ── Build ArrayMesh ───────────────────────────────────────────────────────
	var arrays : Array = []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = PackedVector3Array(vdata)
	arrays[Mesh.ARRAY_NORMAL] = PackedVector3Array(ndata)

	var arr_mesh := ArrayMesh.new()
	arr_mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)

	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(1.0, 0.9, 0.2)
	mat.roughness = 0.8

	var mi := MeshInstance3D.new()
	mi.mesh = arr_mesh
	mi.set_surface_override_material(0, mat)
	add_child(mi)

	# ── Concave trimesh collision shape ────────────────────────────────────────
	# ConcavePolygonShape3D matches the exact triangle geometry, so the ball
	# rolls on the true curved surface rather than the convex hull.
	var shape := ConcavePolygonShape3D.new()
	shape.backface_collision = true
	shape.set_faces(PackedVector3Array(vdata))
	var cs := CollisionShape3D.new()
	cs.shape = shape
	add_child(cs)

# ── Geometry helpers ──────────────────────────────────────────────────────────

func _quad(vdata: Array[Vector3], ndata: Array[Vector3],
		a: Vector3, b: Vector3, c: Vector3, d: Vector3, n: Vector3) -> void:
	for pt in [a, c, b, a, d, c]:
		vdata.append(pt)
		ndata.append(n)

# Curved quad with per-vertex normals that vary linearly across the arc:
# n_start is applied at vertices a and b (start of arc segment),
# n_end is applied at vertices c and d (end of arc segment).
# Winding is identical to _quad: triangles [a,c,b] and [a,d,c].
func _smooth_quad(vdata: Array[Vector3], ndata: Array[Vector3],
		a: Vector3, b: Vector3, c: Vector3, d: Vector3,
		n_start: Vector3, n_end: Vector3) -> void:
	for pt_n in [[a, n_start], [c, n_end], [b, n_start],
				 [a, n_start], [d, n_end], [c, n_end]]:
		vdata.append(pt_n[0])
		ndata.append(pt_n[1])

func _tri(vdata: Array[Vector3], ndata: Array[Vector3],
		a: Vector3, b: Vector3, c: Vector3, n: Vector3) -> void:
	for pt in [a, c, b]:
		vdata.append(pt)
		ndata.append(n)
