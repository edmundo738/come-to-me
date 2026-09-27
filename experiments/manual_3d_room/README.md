# Manual 3D room — next playable-slice hypothesis

An additive, hand-authored room for testing **3D environment + 2D characters**. It is not the project default and is not a production-art approval. The old `scenes/main.tscn`, the procedural experiment, and `EvasionEnemyState` remain intact.

## Open and edit

1. In the Godot editor, open `manual_3d_room.tscn` from this folder.
2. Select nodes under `Environment/Floor`, `Environment/Walls`, `Environment/Props`, `Environment/Decals`, `Environment/Doors`, `Gameplay`, or `CameraRig` in the Scene tree.
3. Change MeshInstance3D meshes/materials, move individual wall/pillar instances, adjust the red resin plane, move either character, or experiment with the Camera3D transform/projection.
4. Run this scene with **F6**. Project **F5** still runs the preserved 2D main scene.

`WallCell` and `PillarCell` are reusable scenes with real StaticBody3D collision. `GridCellMarker3D` snaps their X/Z transform to the one-metre grid and updates the exported `grid_cell`; the room controller reads blockers from these visible instances at startup. Keep room layout under the identity `ComeToMeWorld` root so world position, physics, and cell coordinates stay aligned. Moving an instance in the editor changes both its visible/collision placement and its logical blocked cell.

## Situation and controls

- Player starts at `(2,4)`, statue at `(8,4)`, exit at `(9,8)`.
- Ten interior pillars reuse the accepted Evasion First cover/sightline layout. The perimeter is built from wall scenes with an opening at the teal exit gate.
- **WASD / arrows:** cardinal continuous movement. Each grid-boundary crossing advances one enemy unit; movement within a cell costs no enemy unit.
- **E:** wait one enemy unit. **R:** restart.
- The teal gate is the objective. No procedural layout or new enemy archetype is included.

The controller directly instantiates the existing `EvasionEnemyState`; its visibility, last-seen memory, pursuit, investigation, search, recovery, and BFS step selection are not replaced. Enemy steps are animated across one cell. The player's CharacterBody3D travels physically, while the logical ActorState updates at the grid boundary. The room test also exercises a partial-cell move and a pillar-induced loss of sight.

## Visual hypotheses, not approvals

- Orthographic Camera3D with X aligned to screen-left/right and Z aligned to screen-up/down; a 40-degree downward pitch is a first adjustable approximation, not a measured match to the owner's visual-language percentages.
- Existing 2D protagonist idles billboarding in 3D. Movement is continuous with a very small body bob because no approved walk sequence is available; whether that feels like walking or gliding is **UNKNOWN**. The rejected SpriteDNA walk is not used. Left/right idle sprites remain review candidates.
- One simple SVG statue silhouette, basic stone meshes/materials, a single editable resin decal, one teal objective light, and one shadow-casting key light. These test scale, depth, collision, and coherence, not final art.
- No HUD, extra mechanics, additional enemies, procedural rooms, or broad asset set is added.

## Validation status

`tests/godot_manual_3d_room.gd` checks the editable node tree, collision-backed blockers, objective reachability, reuse of Evasion First, continuous sub-cell movement without a turn, exactly one enemy unit per boundary crossing, and the existing investigation transition behind cover. It is included in `tests/godot_headless_smoke.sh` before the older procedural test.

**Not yet verified:** parsing/import, running this scene in Godot, 3D physics, camera composition, real movement feel, lighting/shadows, fun, suspense, readability, or art approval. This workspace has no Godot executable or GUI. The previous CI smoke failed on commit `6a14831` and its exact failing subtest is unknown because log transfer ended in TLS/EOF. The next pinned-engine run is required before describing this room as technically working; a display-enabled human playtest is required before judging the experience.
