# ball_game

A Marble Madness-style physics game built in Godot 4.6.2 (Jolt physics). Guide a metallic ball through a series of rooms using torque-based rolling.

## Requirements

- Godot 4.6.2 (desktop)
- No additional plugins or addons required

## Running

1. Open Godot and import the project from this directory.
2. Open `scenes/main.tscn` and press F5 (or the play button).

## Controls

| Key             | Action        |
|-----------------|---------------|
| W / Up arrow    | Roll forward  |
| S / Down arrow  | Roll backward |
| A / Left arrow  | Roll left     |
| D / Right arrow | Roll right    |

The camera is a fixed isometric orthographic view — controls are relative to the isometric axes, not the camera's screen space.

## Project structure

```
ball_game/
├── scenes/
│   ├── main.tscn            # Root scene: environment, lighting, camera, ball, room container
│   ├── ball/
│   │   └── ball.tscn        # RigidBody3D ball (instanced into main.tscn)
│   └── rooms/
│       └── room_01.tscn     # Test arena: flat floor, 4 walls, exit triggers, spawn marker
├── scripts/
│   ├── ball.gd              # Input → torque, ground detection, fell_off_world signal
│   ├── camera_iso.gd        # Orthographic isometric camera, lerps to follow target
│   ├── room_manager.gd      # Loads/unloads rooms, wires exit triggers, respawns ball
│   └── exit_trigger.gd      # Area3D that emits ball_exited(direction) on ball overlap
├── shaders/
│   └── boule.gdshader       # Custom shader: metallic reflective ball with dark ridge seams
└── project.godot
```

## Physics notes

The ball is controlled by applying torque, not direct velocity. This gives realistic rolling physics:

- Torque axis for direction `d`: `Vector3(-d.z, 0, d.x)`
- `max_angular_speed` caps player-input spin (physics collisions can exceed this)
- Rolling friction (`rolling_damp = 0.99`) is applied only when grounded (contact count > 0)
- Ground detection uses `_integrate_forces` contact count — no raycasts

Key tunable exports on `ball.gd`:

| Export             | Default | Effect                              |
|--------------------|---------|-------------------------------------|
| `torque_strength`  | 15.0    | How hard player input spins the ball |
| `max_angular_speed`| 25.0    | Speed cap for player-input torque    |
| `rolling_damp`     | 0.99    | Per-frame angular damping on ground  |

## Rendering

- **Ball material**: custom `boule.gdshader` — metallic (METALLIC=1.0, ROUGHNESS=0.0) with two dark great-circle ridges at x=0 and y=0
- **Reflections**: Screen Space Reflections (SSR) enabled in the World Environment; no ReflectionProbe
- **Sky**: ProceduralSkyMaterial (blue gradient) provides IBL for the metallic ball
- **Lighting**: single DirectionalLight3D (sun) with shadows, plus low ambient light

## Adding rooms

1. Duplicate `scenes/rooms/room_01.tscn` or create a new one. Every room needs:
   - A `BallStart` Node3D marker (ball spawns 0.6 m above it)
   - `Area3D` nodes in the `exit_triggers` group with an `ExitTrigger` script and a `direction` set
2. Add an entry to `ROOMS` in `scripts/room_manager.gd`:
   ```gdscript
   "room_02": {
       "scene": "res://scenes/rooms/room_02.tscn",
       "exits": { "north": null, "south": "room_01", "east": null, "west": null },
   },
   ```
3. Update the predecessor room's exits to point at the new room_id.

## Current status

- Room 01: flat test arena (white floor, red east/west walls, yellow north/south walls, tall west wall)
- Ball physics, camera, exit triggers, and respawn all working
- Debug overlay visible in top-left corner (WISH, ANG VEL, ROLLING, etc.)
- No NPCs, hazards, or scoring yet
