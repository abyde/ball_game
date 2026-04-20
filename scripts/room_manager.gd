extends Node3D

# ── Room registry ─────────────────────────────────────────────────────────────
# Add an entry here for every room you build.
# "exits" maps edge names to the room_id that edge connects to (null = wall).
const ROOMS: Dictionary = {
	"room_01": {
		"scene": "res://scenes/rooms/room_01.tscn",
		"exits": {
			"north": null,   # set to "room_02" once room_02 exists
			"south": null,
			"east":  null,
			"west":  null,
		},
	},
}

@onready var _room_container: Node3D  = $RoomContainer
@onready var _ball: RigidBody3D       = $Ball
@onready var _camera: Camera3D        = $Camera3D

var _current_room_id: String = "room_01"
var _current_room: Node3D    = null
var _transitioning: bool     = false

func _ready() -> void:
	_camera.target = _room_container
	_ball.fell_off_world.connect(_respawn_ball)
	_load_room(_current_room_id)

# ── Room loading ──────────────────────────────────────────────────────────────

func _load_room(room_id: String) -> void:
	if not ROOMS.has(room_id):
		push_error("room_manager: unknown room '%s'" % room_id)
		return

	_transitioning = true

	if is_instance_valid(_current_room):
		_current_room.queue_free()
		_current_room = null

	var scene: PackedScene = load(ROOMS[room_id]["scene"])
	_current_room = scene.instantiate()
	_room_container.add_child(_current_room)
	_current_room_id = room_id

	# Wire up every exit trigger in the new room.
	for node in _current_room.find_children("*", "Area3D", true):
		if node.is_in_group("exit_triggers"):
			node.ball_exited.connect(_on_exit_triggered)

	_respawn_ball()
	_transitioning = false

# ── Ball placement ────────────────────────────────────────────────────────────

func _respawn_ball() -> void:
	var marker := _current_room.find_child("BallStart") as Node3D
	if is_instance_valid(marker):
		# Offset slightly above the marker so the ball doesn't spawn inside the floor.
		_ball.global_position = marker.global_position + Vector3(0.0, 0.6, 0.0)
	else:
		_ball.global_position = Vector3(0.0, 2.0, 0.0)
	_ball.linear_velocity  = Vector3.ZERO
	_ball.angular_velocity = Vector3.ZERO

# ── Exit handling ─────────────────────────────────────────────────────────────

func _on_exit_triggered(direction: String) -> void:
	if _transitioning:
		return

	var next_id = ROOMS[_current_room_id]["exits"].get(direction)
	if next_id == null:
		return  # No room on this side yet — the wall stops the ball.

	_load_room(next_id)
