# Come to Me

A Godot 4 / GDScript prototype for a strategy game with evasion, suspense, survival, and atmospheric exploration. The current project default is the older 2D/grid baseline; the active design test is one additive, hand-built 3D room with 2D characters. Its camera and movement presentation are hypotheses, not approved final art.

## Open and play

1. Open `project.godot` with Godot 4.2 or newer.
2. Run the project (the main scene is `scenes/main.tscn`).
3. Use the keyboard:
   - **WASD / arrow keys** — move one grid cell.
   - **Space** — jump two cells in the last chosen direction. The landing cell must be open; the intermediate cell can be crossed.
   - **E** or **.** — wait one turn.
   - **R** — restart at any time.
4. Reach the teal gate. Gold fragments are optional. You have two shield charges.

Blocked moves do not advance the world. A valid move, jump, or wait resolves the pursuer's planned step. Its next cell is not marked: observe how it moves and learn its pursuit pattern. Moving away can lure it into the cell you vacated. An impact consumes a shield; a hit with no charges ends the run.

## Current development focus: one editable room

Open `experiments/manual_3d_room/manual_3d_room.tscn` in the editor and choose **Run Current Scene (F6)**. The project default remains `scenes/main.tscn`, so the old playable baseline is preserved. The room contains real Godot Nodes and reusable Scenes: a collision-backed stone floor, separate wall-cell and pillar instances, a replaceable mesh decal, an Area3D exit gate, a Camera3D, lights, and 2D billboard characters. The occupancy grid is collected from those same wall/pillar scene instances, keeping visible placement and turn-based blocking aligned.

Controls in the room: **WASD / arrows** move continuously in cardinal directions; crossing a cell boundary advances the enemy once. Movement within the same cell does not spend an enemy unit. **E** waits one unit; **R** restarts. The teal gate is the objective. This scene reuses the existing `EvasionEnemyState` state cycle without replacing it. No procedural layout is used in this test.

To explore/edit it, select nodes under `Environment/Floor`, `Environment/Walls`, `Environment/Props`, `Environment/Decals`, `Environment/Doors`, or `CameraRig`. Wall and pillar instances snap to the one-metre floor grid when moved; their collision and logical blocker cell follow the instance. Adjust materials on their MeshInstance3D children. The player and statue are separate scene instances under `Gameplay`.

## Open it in the Godot editor

If you currently only see the running game, close that game window first. In the **Godot Project Manager**, choose **Import**, select the repository's `project.godot` file, then select the project and click **Edit** (not **Run**). Open `experiments/manual_3d_room/manual_3d_room.tscn` from the **FileSystem** panel to explore the active prototype; open `scenes/main.tscn` for the preserved baseline. The `scripts` and `experiments` folders contain editable GDScript.

To inspect the idle candidates separately, open `scenes/animation_review.tscn` and use **Run Current Scene (F6)**. Use **1–4** to select front/back/left/right, **Space** to pause, **Left/Right** to step while paused, **Up/Down** to adjust speed, and **R** to reset. The left/right loops are test candidates only, not approved production art.

To try the reversible tactical-evasion experiment, open `experiments/evasion_first_slice/evasion_first_slice.tscn` and use **Run Current Scene (F6)**. It does not replace the default main scene. Its pursuit/search behavior and remaining validation are documented in that folder.

The first SpriteDNA walk attempt was rejected by the user and is archived under `experiments/spritedna/walk_01_rejected/`; its source PNGs remain in the review folder as failure evidence. Do not use it as a gameplay animation. Open that folder's `index.html` in a browser (or serve the folder) to step the original PNGs without GIF accumulation. The original approved idle cycles and the main game are unchanged. A pipeline diagnosis and lossless APNG preview tool are documented in `docs/character-animation/sprite_pipeline_diagnosis.md`.

The old 2D baseline still draws its board in `scripts/main.gd`; it remains available for comparison and is not the active environment-building approach. The new room deliberately uses editable 3D nodes/scenes instead of `draw_*()` for world geometry. It reuses the existing front/back idle cycles and the current left/right review sequences only for this test. The tiny gait bob is experimental; the rejected walk candidate is not used. No room look, character integration, or movement quality is approved until viewed and played in Godot.

## Current structure

```text
project.godot
scenes/main.tscn                     # preserved 2D/grid baseline
scenes/animation_review.tscn
scripts/                              # shared grid/state/input and old baseline
experiments/evasion_first_slice/      # accepted enemy-behavior reference
experiments/manual_3d_room/
  manual_3d_room.tscn                 # one hand-built editable 3D room (F6)
  wall_cell.tscn / pillar_cell.tscn   # reusable geometry + collision instances
  player_character.tscn              # CharacterBody3D + AnimatedSprite3D
  enemy_statue.tscn                  # 2D statue silhouette in 3D
  materials/ / art/                   # editable blockout resources
experiments/procedural_first_level/  # preserved, playtest did not meet the goal
experiments/spritedna/walk_01_rejected/ # archived; do not use
```

The old baseline retains integer-grid turn rules and the previous screen-aligned renderer. The new manual room derives its logical blockers from selectable scene instances and keeps the cardinal grid beneath continuous 3D movement. Its 2D characters billboard in the real 3D room; this integration is under visual test, not an established style.

## Project status

- **Identity:** strategy with evasion, suspense, survival, and atmospheric exploration. Read the active decisions in `docs/game_direction.md`.
- **Accepted behavior base:** `EvasionEnemyState` retains vision → pursuit → lost sight → investigation → search → recovery. The manual room reuses it unchanged; see `experiments/evasion_first_slice/`.
- **Current test:** one manual 3D room, editable 3D floor/walls/pillars/door/decal/camera, 2D Player and statue. The project default is intentionally still the old 2D baseline until the new room is inspected.
- **Owner playtest:** the procedural slice did not meet the intended fun, suspense, or visual-coherence goals. Keep it as evidence; do not extend it before the hand-built room answers the core design question.
- **Validation:** all 8 existing Python tests pass. `tests/godot_manual_3d_room.gd` is present but has not been run locally because no Godot executable/editor is available; scene parsing, physics, and visuals remain unverified. Earlier Actions run `36311764605` built Godot but its headless smoke failed, and log transfer failed; the exact failing subtest is UNKNOWN.
- **Art:** accepted front/back idle frames remain unchanged; left/right cycles are review candidates. The rejected walk sequence is not used. The new statue SVG and puddle are blockout assets, not final approvals.
- **Environment limitations:** this workspace has no Godot executable or editor GUI. See `docs/environment/current_state.md` for current evidence and the previous headless-run status.

## Development principle

Context → small decision → implementation → test → observation → checkpoint. Build one situation well before procedural expansion; do not add a mechanic or content batch to cover an unanswered design question.
