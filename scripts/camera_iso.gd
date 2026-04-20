extends Camera3D

## The node this camera follows.  Set by room_manager at startup.
@export var target: Node3D = null

## Lerp speed: how quickly the camera position catches up to the ball.
@export var follow_speed: float = 6.0

## Distance from target along the isometric view axis (world units).
@export var view_distance: float = 22.0

## Orthographic viewport height in world units.  Adjust to zoom in/out.
@export var view_size: float = 14.0

# Camera sits at  target + ISO_DIR * view_distance  and looks back toward target.
# (1,1,1) normalized = the classic isometric view axis (45° yaw, ~35.26° pitch).
const _ISO_DIR := Vector3(0.577350, 0.577350, 0.577350)

func _ready() -> void:
	projection = PROJECTION_ORTHOGONAL
	size = view_size
	_snap_to_target()

func _process(delta: float) -> void:
	if not is_instance_valid(target):
		return
	var desired := target.global_position + _ISO_DIR * view_distance
	global_position = global_position.lerp(desired, follow_speed * delta)
	# Rotation is constant for a fixed isometric view — set once in _ready,
	# no need to call look_at every frame (which would cause micro-jitter).

# ── Helpers ──────────────────────────────────────────────────────────────────

func _snap_to_target() -> void:
	var center := target.global_position if is_instance_valid(target) else Vector3.ZERO
	global_position = center + _ISO_DIR * view_distance
	# look_at the point directly below the camera along the iso axis.
	# Using Vector3.UP as the "up" hint gives the standard iso orientation:
	#   screen-right  = world (1, 0, -1) / sqrt(2)
	#   screen-up     = world (-1, 2, -1) / sqrt(6)
	look_at(center, Vector3.UP)
