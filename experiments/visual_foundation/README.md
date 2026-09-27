# Checkpoint 01 — Iteration 02: camera, character, and visual coherence

This is a focused second pass on the hand-authored visual foundation, based on the owner's first display-backed playtest. The first pass proved that the 2D/2.5D figure and free camera-relative movement can work in the room; the owner also saw a promising temple-like spatial composition. The blockout art is still provisional and is not being treated as approved production art.

## Run

Open the project with Godot **4.7.2** and press **F5** (or open `foundation_room.tscn` and press **F6**).

- **W/S:** move forward/back relative to the camera.
- **A/D:** strafe; diagonals are normalized.
- **Mouse:** orbit the third-person camera. Orbit response and camera follow are eased; the mouse still sets the orbit target.
- **Mouse wheel:** adjust distance; the boom compresses near geometry and relaxes more gently when clear.
- **Esc:** release/capture the cursor; click the game view to capture it again.

## Iteration 02 changes

- The horizontal velocity now approaches a target vector with separate acceleration/braking, rather than changing each axis independently. The body turns toward the requested heading with damping. Existing idle frames remain the only character animation; a tiny velocity-driven body settle is not presented as a walk cycle.
- Directional source views use a small hysteresis band at the front/side boundary to reduce flickering as the camera moves. This is still the reversible `AnimatedSprite3D` hypothesis, not a final 2.5D technique.
- Camera yaw, pitch, follow pivot, camera position, and obstacle distance now ease independently. Collision remains geometry-driven. This is an iteration to evaluate, not a claim of AAA-quality camera feel.
- The room keeps its temple-like layout but uses a more consistent architectural vocabulary: rounder matching column/threshold supports, fewer repeated props, and the previous block recast as one collision-backed stone bench. A muted aged-stone/bronze palette and one low-energy teal seam are a restrained first hint of supernatural technology; there are no particle effects.

## Editable scene structure

`foundation_room.tscn` is a normal editable `Node3D` scene. Under `Environment`, inspect the floor, wall segments, threshold frames, columns, single bench, inlays, `WorldEnvironment`, and lights. Reusable scenes are in `modules/`; materials and small pixel-blockout textures are in `materials/` and `art/`.

`Player` is a `CharacterBody3D` with a capsule, contact shadow and `AnimatedSprite3D`. The trailing camera sees the original `tras` view moving away and `frente` moving toward it. Left/right remain review candidates; the rejected SpriteDNA walk remains unused. Mesh proportions, art, architecture, material palette, framing, and motion values are all adjustable and provisional.

## Test and approval status

The first iteration has been executed by the owner. His observations are recorded in `docs/game_direction.md`: the free movement and the character perspective are promising, while the blockout looks artificial/disproportionate and camera/movement need substantial smoothing. Iteration 02 has **not** yet been playtested or visually approved.

`tests/godot_visual_foundation.gd` checks scene resources, input-vector math, gradual acceleration, ground/bench collision, and camera obstruction response where supported. Headless tests cannot assess comfort, aesthetics, or character/world integration. Please repeat a display-backed playtest after this pass and report the camera feel, starts/stops/turns, view changes, bench collision, scale, atmosphere, and what still reads as a primitive.

## Small update download

`ComeToMe-VisualFoundation-Iteration02.zip` is a **focused patch**, not a second copy of the whole GitHub repository. Extract it into the root of the existing Godot project, preserving its folder structure and allowing files to overwrite; then reopen the project and press **F5**. The archive contains only the updated scene/resources, project settings and the character frames those scenes directly use. Keep your existing project backup.
