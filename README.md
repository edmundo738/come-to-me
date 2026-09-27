# Come to Me

Exploration-first game prototype in Godot: a real 3D world with a pixel-art/2.5D presentation. The long-term direction keeps stealth, mystery, survival and strategy together; the **current executable test is only Checkpoint 01 — Visual Foundation**.

## Run Checkpoint 01

Open `project.godot` in Godot **4.7.2** and press **F5**. The default scene is `experiments/visual_foundation/foundation_room.tscn`.

- **W/S:** move forward/back relative to the camera.
- **A/D:** strafe left/right relative to the camera.
- **W+A, W+D, S+A, S+D:** camera-relative diagonals, normalized to the same top speed.
- **Mouse:** orbit the third-person camera.
- **Mouse wheel:** move the camera closer/farther.
- **Esc:** release/capture the pointer; click the game view to capture it again.

The player moves freely on the floor plane with physical collision. The camera follows behind and above, eases with movement, and shortens its path when geometry blocks it. This is a first camera test, not the final cinematic camera system.

## Edit the room

Open `experiments/visual_foundation/foundation_room.tscn` in the editor. It is built from editable Godot nodes and reusable scenes, not a world painted with `draw_*()`:

- `Environment/Floor` — mesh floor and physics collider.
- `Environment/Architecture` — separate wall segments, archways, columns and low obstacles; each reusable piece contains its meshes/materials and `StaticBody3D` collision.
- `Environment/DecorativeInlays` — simple editable geometry details.
- `Environment/WorldEnvironment`, `KeyLight`, fill and threshold lights — real 3D environment and lighting.
- `Player` — `CharacterBody3D`, capsule collision, contact shadow and individual PNG idle frames in `AnimatedSprite3D`.
- `CameraRig/Camera3D` — mouse-orbit camera with smoothed following and collision-aware distance.

Meshes, collisions, transforms, materials, camera settings and lights can be changed in the scene tree/Inspector. Blockout textures are in `experiments/visual_foundation/art/`; editable materials are in `materials/`; reusable geometry is in `modules/`.

## Checkpoint scope and status

**In the scene:** one small manually composed 3D test chamber, free camera-relative ground movement, mouse orbit/zoom, lighting, shadows, depth, collision and the protagonist's existing pixel-art idle views. A small movement bob is temporary; it does not claim to be a walk animation.

**Deliberately not in this checkpoint:** enemies, statues, demons, Mirrors, Shadows, Reflections, stealth/Shift, combat, throwables, sound, breathing/heartbeat, HUD, progression, turn/cell gameplay, procedural generation or open-world systems. Those remain future direction, not scope creep for this visual proof.

**The character technique is not a final decision.** The first reversible test uses a Y-facing `AnimatedSprite3D` lit by the 3D scene, an alpha-cut sprite shadow and a contact shadow. Front/back idle frames are the existing approved art; side views remain review candidates. The rejected walk sequence is not used. Whether this figure feels voluminous, grounded and spatially integrated is still UNKNOWN until observed in a display-backed run.

### Validation

- `tests/godot_visual_foundation.gd` exercises the scene tree, input-vector math, free movement, physical floor/obstacle collisions and camera behavior where the display driver permits it.
- The pinned Godot source build used by CI is 4.7.2. This local workspace has no Godot executable or GUI/display backend. Static checks and headless tests do **not** establish the required visual result.
- Previous Actions run `36315052254` compiled Godot but failed during its headless smoke step; the log download failed with TLS/EOF, so the failing subtest is UNKNOWN. A fresh run is still needed. Even a headless PASS cannot approve camera comfort or character/world integration.
- **Checkpoint 01 is not declared visually successful yet.** It requires a real playtest and an observed answer to: “Does the character feel present in the world, and do camera, movement, character and environment belong together?”

## Preserved experiments and evidence

- `experiments/manual_3d_room/manual_3d_room.tscn` — previous hand-built 3D room retained as technical evidence; not the final camera/art target.
- `experiments/evasion_first_slice/` — accepted pursuit/visibility behavior preserved for a later real-time stealth test; not included in Checkpoint 01.
- `experiments/procedural_first_level/` — preserved experiment. The owner's playtest found it visually incoherent and not fun/suspenseful; investigate that evidence rather than extending the generator now.
- `scenes/main.tscn` and `experiments/spritedna/walk_01_rejected/` remain preserved. The rejected walk is not used.
- `scenes/animation_review.tscn` remains available for reviewing idle cycles. Side-facing candidates are not production-approved.

## Rendering configuration

The project selects Godot **Forward+** and asks for the **Direct3D 12 (`d3d12`) driver on Windows**. Godot handles other supported drivers/platforms and may fall back when necessary. This configuration has not yet been tested on Windows hardware or benchmarked. The small scene uses standard meshes/materials and controlled lights rather than a custom rendering layer.

## Direction and technical notes

- Active direction and validation vocabulary: `docs/game_direction.md`.
- Current environment evidence and unknowns: `docs/environment/current_state.md`.
- Gameplay research: `docs/gameplay_core_research.md`.
- Scene-specific editing/test notes: `experiments/visual_foundation/README.md`.
- Do not infer that code compiles, physics behaves, or visuals look good unless that exact thing was tested and observed.
