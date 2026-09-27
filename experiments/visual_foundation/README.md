# Checkpoint 01 — Visual Foundation

A small, hand-authored 3D test chamber for the currently approved visual/movement hypothesis. This scene is the project default; the previous `experiments/manual_3d_room/` remains intact as a separate technical proof. The chamber contains **no enemies, combat, stealth, items, audio, HUD, progression, or procedural generation**.

## Run

Open the project with Godot **4.7.2** and press **F6** on `foundation_room.tscn`, or run the project with **F5** (this scene is `run/main_scene`).

- **W/S:** move forward/back relative to the camera.
- **A/D:** strafe relative to the camera; combinations move diagonally at the same maximum speed.
- **Mouse:** orbit the third-person camera.
- **Mouse wheel:** adjust camera distance.
- **Esc:** release/capture the cursor; click the game view to re-capture it.

The movement is a free physical CharacterBody3D constrained by the floor and scene collisions. It is not a tile/turn movement system. The camera eases behind and above the player, leads very slightly with movement, and shortens/relaxes its boom when a real collider obstructs the orbit. FOV and cinematic combat zooms are deliberately not implemented.

## Editor structure

`foundation_room.tscn` is an editable Node3D scene. Under `Environment`, inspect and move the separate floor, wall-segment, archway, column, low-obstacle, inlay, and light nodes. The reusable pieces are in `modules/`; their meshes and StaticBody3D collision shapes are visible as scene children. Materials and tiny pixel-blockout textures are in `materials/` and `art/`.

The player is a CharacterBody3D with a capsule collider, contact shadow, and `AnimatedSprite3D` using the original individual PNG frames. The initial representation is intentionally a simple, replaceable test hypothesis: upright, Y-facing pixel-art views that receive 3D lighting and cast an alpha-cut shadow. A subtle motion bob is temporary; it is **not** a walk animation. The left/right idle sequences remain review candidates, and the rejected SpriteDNA walk is not used. This does not select a final character-rendering technique.

`CameraRig` and `Camera3D` are normal editable nodes. The camera is third-person with mouse orbit; a physics ray against scene geometry smoothly compresses the boom. Its framing, distance, sensitivity, materials, and geometry are first-test values, not approvals.

## What this test is meant to answer

- Does the 2D/2.5D figure feel grounded and present as the camera orbits, instead of looking pasted over the scene?
- Do shadows, occlusion, lighting, floor contact, object scale, and depth read coherently together?
- Are camera-relative forward, backward, lateral, and diagonal movement understandable and comfortable?
- Does the camera preserve control while smoothly responding to nearby geometry?

Do not call this checkpoint visually successful from script parsing or a headless exit code. The suite at `tests/godot_visual_foundation.gd` checks scene resources, input-vector math, physical floor/wall collisions, and camera controls where a display exists. Headless execution cannot judge art integration or the feel of mouse orbit. A display-backed playtest and a real visual review are required before approval.
