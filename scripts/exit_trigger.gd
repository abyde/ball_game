class_name ExitTrigger
extends Area3D

## Which edge of the room this trigger guards.
@export_enum("north", "south", "east", "west") var direction: String = "north"

## Emitted when the player ball overlaps this area.
signal ball_exited(direction: String)

func _ready() -> void:
	add_to_group("exit_triggers")
	body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node3D) -> void:
	if body.is_in_group("ball"):
		ball_exited.emit(direction)
