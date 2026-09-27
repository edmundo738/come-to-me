# Come to Me

Exploration-first game prototype in Godot: a real 3D world with a pixel-art/2.5D presentation. The long-term direction keeps stealth, mystery, survival and strategy together; the **current executable test remains Checkpoint 01 — Visual Foundation, now in Iteration 02**.

## Run Checkpoint 01

Open `project.godot` in Godot **4.7.2** and press **F5**. The default scene is `experiments/visual_foundation/foundation_room.tscn`.

- **W/S:** move forward/back relative to the camera.
- **A/D:** strafe left/right relative to the camera.
- **W+A, W+D, S+A, S+D:** camera-relative diagonals, normalized to the same top speed.
- **Mouse:** orbit the third-person camera.
- **Mouse wheel:** move the camera closer/farther.
- **Esc:** release/capture the pointer; click the game view to capture it again.

The player moves freely on the floor plane with physical collision. Horizontal velocity eases toward a camera-relative target, and the body turns toward its heading instead of snapping. The camera's orbit, follow, position and collision-distance responses are damped independently. This is a second-feel pass, not a final cinematic camera system; its results still need the owner's playtest.

## Edit the room

Open `experiments/visual_foundation/foundation_room.tscn` in the editor. It is built from editable Godot nodes and reusable scenes, not a world painted with `draw_*()`:

- `Environment/Floor` — mesh floor and physics collider.
- `Environment/Architecture` — separate wall segments, threshold frames, columns and a single stone bench; each reusable piece contains editable meshes/materials and `StaticBody3D` collision.
- `Environment/DecorativeInlays` — simple editable geometry details.
- `Environment/WorldEnvironment`, `KeyLight`, fill and threshold lights — real 3D environment and lighting.
- `Player` — `CharacterBody3D`, capsule collision, contact shadow and individual PNG idle frames in `AnimatedSprite3D`.
- `CameraRig/Camera3D` — mouse-orbit camera with smoothed following and collision-aware distance.

Meshes, collisions, transforms, materials, camera settings and lights can be changed in the scene tree/Inspector. Blockout textures are in `experiments/visual_foundation/art/`; editable materials are in `materials/`; reusable geometry is in `modules/`.

## Checkpoint scope and status

**In the scene:** one manually composed 3D test chamber, free camera-relative ground movement, mouse orbit/zoom, lighting, shadows, depth, collision and the protagonist's existing pixel-art idle views. Iteration 02 tunes camera damping, velocity/turn response, and a small velocity-driven settle; it does not introduce a new walk cycle.

**Deliberately not in this checkpoint:** enemies, statues, demons, Mirrors, Shadows, Reflections, stealth/Shift, combat, throwables, sound, breathing/heartbeat, HUD, progression, turn/cell gameplay, procedural generation or open-world systems. Those remain future direction, not scope creep for this visual proof.

**The character technique is not a final decision.** The reversible test uses a Y-facing `AnimatedSprite3D` lit by the 3D scene, an alpha-cut sprite shadow and a contact shadow. Front/back idle frames are the existing approved art; side views remain review candidates. The rejected walk sequence is not used. In the owner's first display-backed run the perspective felt promising, but full spatial integration and camera comfort still need further playtests.

### First playtest and next validation

- **FACT — owner ran Iteration 01 in Godot.** **OBSERVED:** free 3D movement works as a first proof; the player perspective is promising; the room composition suggests an interesting temple-like space. **OBSERVED:** proportions and blockout assets look artificial/geometric, motion is stiff, orbit/framing need substantial refinement, and camera transitions must not announce a hard boundary. The complete report and next checkpoint scope are in `docs/game_direction.md`.
- Iteration 02 addresses only camera/character feel and visual coherence: damped orbit/follow/obstruction response, acceleration/braking and smoothed body turn, stable source-view selection, rounder repeated architecture, fewer props, and a restrained palette/light cue. It adds no gameplay systems or particle effects.
- Remote headless run `36328344782` built the pinned Godot and imported/executed the scene test, but one bench-collision assertion failed at X=7.63. The collision test is being aligned to the bench center and the block is being reshaped as a bench; this must be re-run, not assumed fixed.
- Static checks and headless tests do **not** establish art quality, comfort or spatial integration. This workspace has no desktop Godot executable/display, so only the owner can provide the next actual visual playtest here.
- **Iteration 02 is not approved yet.** The user's five evaluation questions remain open until the updated folder is run and observed.

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
