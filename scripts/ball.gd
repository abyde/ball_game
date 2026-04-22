extends RigidBody3D

enum BallType { BOULE, BASKETBALL }

## Visual and physics style of the ball.  Can be changed at any time, including during gameplay.
@export var ball_type: BallType = BallType.BOULE:
	set(value):
		ball_type = value
		if is_node_ready():
			_apply_ball_type()

## Torque applied per physics frame in response to player input.
@export var torque_strength: float = 5.0

## Maximum angular speed (rad/s) the player input can spin the ball to.
## Does not cap physics-induced spinning (e.g. bouncing off walls).
@export var max_angular_speed: float = 25.0

## Angular damping applied only while grounded (rolling resistance).
## In air, damping is 0 — the ball spins freely (conservation of momentum).
@export var rolling_damp: float = 0.99

## Upward impulse applied when the player jumps (N·s; with mass=1 kg this equals m/s).
@export var jump_strength: float = 5.0

# ── Per-type physics ──────────────────────────────────────────────────────────
const _BOULE_MASS     := 3.0   # kg  — heavy polished metal
const _BOULE_FRICTION := 0.3   # low — smooth surface
const _BOULE_BOUNCE   := 0.2   # metal barely bounces
# rough=false → multiply combine: boule friction always wins against rough floors

const _BBALL_MASS     := 0.6   # kg  — light rubber shell
const _BBALL_FRICTION := 1.5   # high — grippy rubber (>1 is valid in Godot)
const _BBALL_BOUNCE   := 0.7   # rubber bounces well
# rough=true → max combine: basketball stays grippy on any surface

const _BOULE_SHADER      := preload("res://shaders/boule.gdshader")
const _BASKETBALL_SHADER := preload("res://shaders/basketball.gdshader")

var _boule_mat: ShaderMaterial
var _basketball_mat: ShaderMaterial

# timestamp of last jump
var _last_jumped: int
# 100 milliseconds cool-down on jumping
const jump_cooldown: int = 100

# ── Isometric world-space movement directions ────────────────────────────────
const ISO_FWD   := Vector3( -0.707107, 0.0,  0.707107)  # W  / Up arrow
const ISO_BACK  := Vector3(  0.707107, 0.0, -0.707107)  # S  / Down arrow
const ISO_LEFT  := Vector3(  0.707107, 0.0,  0.707107)  # A  / Left arrow
const ISO_RIGHT := Vector3( -0.707107, 0.0, -0.707107)  # D  / Right arrow

## Emitted when the ball falls through the death plane (y < -20).
signal fell_off_world

# ── Debug overlay ─────────────────────────────────────────────────────────────
var _dbg_label: Label
var _dbg_torque_applied: bool = false
var _rolling: bool = false
var _num_contacts: int
var _contact_ids: Array[RID] = []

func _ready() -> void:
	# Duplicate so per-instance changes don't affect the shared scene resource.
	physics_material_override = physics_material_override.duplicate()

	_boule_mat = ShaderMaterial.new()
	_boule_mat.shader = _BOULE_SHADER
	_basketball_mat = ShaderMaterial.new()
	_basketball_mat.shader = _BASKETBALL_SHADER

	_apply_ball_type()
	add_to_group("ball")
	_build_debug_overlay()

func _apply_ball_type() -> void:
	var mi := $MeshInstance3D as MeshInstance3D
	match ball_type:
		BallType.BOULE:
			mi.set_surface_override_material(0, _boule_mat)
			mass = _BOULE_MASS
			physics_material_override.friction = _BOULE_FRICTION
			physics_material_override.bounce   = _BOULE_BOUNCE
			physics_material_override.rough    = false
		BallType.BASKETBALL:
			mi.set_surface_override_material(0, _basketball_mat)
			mass = _BBALL_MASS
			physics_material_override.friction = _BBALL_FRICTION
			physics_material_override.bounce   = _BBALL_BOUNCE
			physics_material_override.rough    = true

# ── Physics callbacks ─────────────────────────────────────────────────────────

func _integrate_forces(state: PhysicsDirectBodyState3D) -> void:	
	_num_contacts = state.get_contact_count()
	_contact_ids.resize(_num_contacts)
	for i in _num_contacts:
		_contact_ids[i] = state.get_contact_collider(i)
	_rolling = _num_contacts > 0

func _physics_process(_delta: float) -> void:
	# ── Gather input ─────────────────────────────────────────────────────────
	var wish := Vector3.ZERO
	if Input.is_action_pressed("roll_forward"):  wish += ISO_FWD
	if Input.is_action_pressed("roll_backward"): wish += ISO_BACK
	if Input.is_action_pressed("roll_left"):     wish += ISO_LEFT
	if Input.is_action_pressed("roll_right"):    wish += ISO_RIGHT

	_dbg_torque_applied = false

	if wish != Vector3.ZERO:
		wish = wish.normalized()

		# Torque axis: for rolling in direction d, ω ∝ (-ŷ) × d = (-d.z, 0, d.x).
		var t_axis := Vector3(-wish.z, 0.0, wish.x)

		var ang_in_dir := angular_velocity.dot(t_axis.normalized())
		if ang_in_dir < max_angular_speed:
			apply_torque(t_axis * torque_strength)
			_dbg_torque_applied = true

	# ── Friction ────────────
	if _rolling:
		angular_velocity = angular_velocity * rolling_damp

	# ── Jump ─────────────────────────────────────────────────────────────────
	var jump_pressed = Input.is_action_pressed("jump")
	# Input.is_action_just_pressed("jump"):
	var jumping = false
	var now = Time.get_ticks_msec()
	if _rolling and jump_pressed and now > _last_jumped + jump_cooldown:
		_last_jumped = now
		jumping = true
		apply_central_impulse(Vector3.UP * jump_strength)

	# ── Ball type toggle ─────────────────────────────────────────────────────────
	if Input.is_action_just_pressed("toggle_ball_type"):
		ball_type = BallType.BASKETBALL if ball_type == BallType.BOULE else BallType.BOULE

	# ── Death plane ───────────────────────────────────────────────────────────
	if global_position.y < -20.0:
		fell_off_world.emit()

	# ── Update debug overlay ──────────────────────────────────────────────────
	_dbg_label.text = (
		"TYPE     %s\n" % BallType.keys()[ball_type] +
		"WISH     %s\n" % _fmt(wish) +
		"ANG VEL  %.2f rad/s  %s\n" % [angular_velocity.length(), _fmt(angular_velocity)] +
		"ROLLING  %s\n" % _rolling +
		"LAST JUMP %s\n" % _last_jumped +
		"JUMPING  %s\n" % jumping +
		"TORQUE   %s\n" % _dbg_torque_applied +
		"POS      %s" % _fmt(global_position)
#		+ "\nContacts %s" % _num_contacts
	)
	#for rid in _contact_ids:
		#_dbg_label.text = _dbg_label.text + ("\n  rid=%s" % rid)

# ── Helpers ───────────────────────────────────────────────────────────────────

func _build_debug_overlay() -> void:
	var canvas := CanvasLayer.new()
	canvas.layer = 128
	add_child(canvas)
	_dbg_label = Label.new()
	_dbg_label.position = Vector2(10, 10)
	_dbg_label.add_theme_font_size_override("font_size", 14)
	canvas.add_child(_dbg_label)

func _fmt(v: Vector3) -> String:
	return "(%.2f, %.2f, %.2f)" % [v.x, v.y, v.z]
