# Come to Me

A Godot 4 / GDScript prototype for a 2.5D isometric, turn-based survival adventure. This first slice deliberately focuses on a small playable foundation rather than future content.

## Open and play

1. Open `project.godot` with Godot 4.2 or newer.
2. Run the project (the main scene is `scenes/main.tscn`).
3. Use the keyboard:
   - **WASD / arrow keys** — move one grid cell.
   - **Space** — jump two cells in the last chosen direction. The landing cell must be open; the intermediate cell can be crossed.
   - **E** or **.** — wait one turn.
   - **R** — restart at any time.
4. Reach the teal gate. Gold fragments are optional. You have two shield charges.

Blocked moves do not advance the world. A valid move, jump, or wait resolves the pursuer's already-visible intention. The red marker shows the cell it plans to enter on its next turn; stepping away can lure it into the cell you vacated. An impact consumes a shield and pushes the encounter back. A hit with no charges ends the run.

## Current structure

```text
project.godot
scenes/main.tscn
scripts/
  main.gd          # run state, turn resolution, drawing and prototype UI
  grid_world.gd    # logical map, walkability, isometric projection
  actor_state.gd   # shared logical actor position
  enemy_state.gd   # deterministic pursuit planning / intent
  input_router.gd  # device input -> logical actions
```

The map and game rules use integer grid coordinates; projection and rendering are kept separate. Input is normalized at the boundary so new device bindings can feed the same logical actions. The current room is intentionally hand-authored and the first visual pass uses vector shapes drawn in GDScript—there are no external art assets or plugins.

## Project status

- **Implemented:** Godot project/scene, isometric grid rendering, player movement, turn-based enemy response and telegraphed intent, collision and limited shields, directional two-cell jump, wait, fragments, exit, win/game-over states, restart, adaptive viewport centering.
- **Working by code inspection:** the intended turn order, deterministic pursuit, and map path to the exit.
- **Validated in Godot:** not yet. This environment does not currently have a Godot executable available, so the project has not been launched or runtime-tested here. Please run it in Godot before treating the prototype as validated.
- **Not in this slice:** touchscreen/controller/remote bindings, animations, sound, procedural maps, multiple levels/characters, narrative progression, and final art/UI.

## Development principle

Plan → implement → test → observe → correct → confirm → expand. The prototype should establish the rules before adding scale or content.
