# Come to Me

A Godot 4 / GDScript prototype for a 2.5D, screen-aligned grid survival adventure. This first slice deliberately focuses on a small playable foundation rather than future content. The camera is a shallow top-down view: the grid stays square to the screen, so logical up/down/left/right remain visually up/down/left/right.

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

## Open it in the Godot editor

If you currently only see the running game, close that game window first. In the **Godot Project Manager**, choose **Import**, select the repository's `project.godot` file, then select the project and click **Edit** (not **Run**). In the editor, `scenes/main.tscn` is in the **FileSystem** panel; double-click it to open the scene. The `scripts` folder contains the GDScript files; double-click a script to edit it.

This first playable prototype draws its board and gameplay characters from code, so the main Scene tree is intentionally sparse. Map walls, coins, player/enemy start cells, and the exit are currently specified in `scripts/grid_world.gd` and `scripts/main.gd`; they are not yet draggable objects in the 2D viewport. Protagonist idle artwork remains in review under `characters/protagonist/review/`; `scenes/animation_review.tscn` is a separate Godot `AnimatedSprite2D` test scene that lets you switch among the four direction cycles, not the main game. The game can be edited in the built-in script editor, but level placement still needs a future editor-friendly pass.

## Current structure

```text
project.godot
scenes/main.tscn
scenes/animation_review.tscn  # four-direction idle review scene
scripts/
  animation_review.gd # review-only playback and frame controls
  main.gd          # run state, turn resolution, drawing and prototype UI
  grid_world.gd    # logical map, walkability, screen-aligned projection
  actor_state.gd   # shared logical actor position
  enemy_state.gd   # deterministic pursuit planning / intent
  input_router.gd  # device input -> logical actions
```

The map and game rules use integer grid coordinates; projection and rendering are kept separate. Input is normalized at the boundary so new device bindings can feed the same logical actions. The current room is intentionally hand-authored and its gameplay visual pass uses vector shapes drawn in GDScript. Character sprite candidates are separate review assets and have not been integrated into gameplay. The screen-aligned cells, shallow depth treatment, and raised wall faces are a camera/readability prototype, not final art.

## Project status

- **Implemented:** Godot project/scene, screen-aligned shallow top-down grid, four-direction movement, turn-based enemy response with hidden internal planning, collision and limited shields, directional two-cell jump, wait, fragments, exit, win/game-over states, restart, adaptive viewport centering.
- **Confirmed running by the project owner:** the project opens in Godot and the game is playable. The owner clarified the camera should not be classic diamond isometric and that enemy movement should be learned by observation, without a visible intent marker. The current pass follows those rules; its camera and wall-depth changes still need a fresh in-editor check.
- **Working by code inspection:** the intended turn order, deterministic pursuit, and map path to the exit.
- **Validated in this environment:** source changes pass `git diff --check`; the complete walkable map was checked for reachability. No Godot executable is available here to run the latest visual pass.
- **Not yet in the playable slice:** touchscreen/controller/remote bindings, integrating the review-only idle cycles into gameplay, sound, procedural maps, multiple levels/characters, narrative progression, and final art/UI.

## Development principle

Plan → implement → test → observe → correct → confirm → expand. The prototype should establish the rules before adding scale or content.
