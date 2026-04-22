extends StaticBody3D
# Procedural wedge (triangular prism) ramp.
# Builds its own ArrayMesh and ConvexPolygonShape3D from the export parameters.
# Attach this script to a StaticBody3D node; no children needed in the scene.

@export var x_min  : float = -3.0
@export var x_max  : float = -1.0
@export var z_low  : float = -4.0  # z at the low/front end  (y = y_low)
@export var z_high : float =  1.0  # z at the high/back end  (y = y_high)
@export var y_low  : float =  0.0
@export var y_high : float =  2.0

func _ready() -> void:
	_build()

func _build() -> void:
	# ── Six corners of the triangular prism ───────────────────────────────────
	#
	#     4 ────── 5        ← y_high, z_high
	#    /|       /|
	#   / |      / |
	#  2 ─┼──── 3  |        ← y_low,  z_high
	#  |  0 ────|─ 1        ← y_low,  z_low   (knife edge — height = 0 here)
	#  | /      | /
	#  |/       |/
	#  (no top-front edge — it's a wedge)
	#
	var v : Array[Vector3] = [
		Vector3(x_min, y_low,  z_low ),  # 0  front-left
		Vector3(x_max, y_low,  z_low ),  # 1  front-right
		Vector3(x_min, y_low,  z_high),  # 2  back-left-bottom
		Vector3(x_max, y_low,  z_high),  # 3  back-right-bottom
		Vector3(x_min, y_high, z_high),  # 4  back-left-top
		Vector3(x_max, y_high, z_high),  # 5  back-right-top
	]

	# ── Normals ───────────────────────────────────────────────────────────────
	# Inclined surface normal: perpendicular to the slope, pointing up-forward.
	var ramp_n := Vector3(0.0, z_high - z_low, -(y_high - y_low)).normalized()

	# ── Accumulate geometry ───────────────────────────────────────────────────
	var vdata : Array[Vector3] = []
	var ndata : Array[Vector3] = []

	_quad(vdata, ndata, v[0], v[4], v[5], v[1], ramp_n)              # incline
	_quad(vdata, ndata, v[2], v[3], v[5], v[4], Vector3(0, 0,  1))    # back wall
	_tri (vdata, ndata, v[0], v[2], v[4], Vector3(-1, 0, 0))          # left side
	_tri (vdata, ndata, v[1], v[5], v[3], Vector3( 1, 0, 0))          # right side

	# ── Build ArrayMesh ───────────────────────────────────────────────────────
	var arrays : Array = []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = PackedVector3Array(vdata)
	arrays[Mesh.ARRAY_NORMAL] = PackedVector3Array(ndata)

	var arr_mesh := ArrayMesh.new()
	arr_mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)

	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.1, 0.7, 0.2)
	mat.roughness = 0.8

	var mi := MeshInstance3D.new()
	mi.mesh = arr_mesh
	mi.set_surface_override_material(0, mat)
	add_child(mi)

	# ── Convex collision shape ─────────────────────────────────────────────────
	var shape := ConvexPolygonShape3D.new()
	shape.points = PackedVector3Array(v)
	var cs := CollisionShape3D.new()
	cs.shape = shape
	add_child(cs)

# ── Geometry helpers ──────────────────────────────────────────────────────────

func _quad(vdata: Array[Vector3], ndata: Array[Vector3],
		a: Vector3, b: Vector3, c: Vector3, d: Vector3, n: Vector3) -> void:
	for pt in [a, c, b, a, d, c]:
		vdata.append(pt)
		ndata.append(n)

func _tri(vdata: Array[Vector3], ndata: Array[Vector3],
		a: Vector3, b: Vector3, c: Vector3, n: Vector3) -> void:
	for pt in [a, c, b]:
		vdata.append(pt)
		ndata.append(n)
