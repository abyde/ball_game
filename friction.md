# Friction and Physics Materials

## How Godot combines friction

When two bodies touch, Godot **multiplies** their `friction` values together by default
(e.g. floor=0.7 × ball=1.0 → effective friction=0.7).

The `rough = true` flag on a PhysicsMaterial switches that body's combine mode to **MAX**,
so it takes `max(body_a, body_b)` instead of multiplying. With the ball at the default 1.0,
`rough=true` has no practical effect unless the ball's friction is set below the surface it's touching.

## Current values in the project

| Object       | friction       | rough | bounce | Notes                          |
|--------------|----------------|-------|--------|--------------------------------|
| Ball         | 1.0 (default)  | true  | 0.35   |                                |
| Floor tiles  | 0.7            | —     | 0.1    |                                |
| WallNorth    | 1.0 (default)  | —     | 0.4    |                                |
| WallSouth    | 1.0 (default)  | —     | 0.5    |                                |
| Ramps        | 1.0 (default)  | —     | —      | no PhysicsMaterial set at all  |

There is also `rolling_damp = 0.99` in `ball.gd` which manually bleeds angular velocity each
frame in `_physics_process`. This is a separate custom damping layer on top of Godot's built-in
friction — torque causes rotation, friction converts rotation to rolling, and `rolling_damp`
provides a small additional decay.

## Experimenting with different friction values

The cleanest approach is to save PhysicsMaterial resources as `.tres` files so they can be
shared and tweaked across instances without duplicating inline sub-resources.

### Per-ramp friction

Add an export to `curved_ramp.gd`:

```gdscript
@export var physics_material: PhysicsMaterial

# in _build():
if physics_material:
    physics_material_override = physics_material
```

Then create e.g. `res://physics/slippery.tres`, `grippy.tres` with different `friction` values
and assign them per-ramp in the Inspector.

### Where physics materials are currently defined

- `scenes/ball/ball.tscn` — inline sub-resource `PhysicsMaterial_1` (ball)
- `scenes/rooms/room_01.tscn` — inline sub-resource `FloorPhys` (all four floor tiles),
  `PhysicsMaterial_1ydvn` (WallNorth), `PhysicsMaterial_bbo4o` (WallSouth)
