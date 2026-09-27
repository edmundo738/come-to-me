# Procedural first level — isolated experiment

This is an additive, reversible environment slice. Run `experiments/procedural_first_level/procedural_first_level.tscn` in Godot with **F6**. At the time this experiment was recorded, the project default was `scenes/main.tscn`; since 2026-09-27 the default is Checkpoint 01 at `experiments/visual_foundation/foundation_room.tscn`. This experiment's source and assets remain preserved and unchanged.

## What it tests

- A deterministic randomized depth-first maze with a protected boundary, guaranteed connected exit, carved loop openings, route and optional fragments, decorative floor decals, and blocking pillar cells.
- The existing turn-based movement/jump/wait rules and sprite animation are reused. A small experiment-only breadth-first pursuer replaces greedy movement because greedy Manhattan pursuit can stall at maze corners; it still takes one visible grid step per player turn.
- Walls occupy full grid cells for collision. Decals and cables are visual-only and are placed only over walkable floor; pillars occupy blocking wall cells. The exit and all fragments are reachable by ordinary movement.
- Restart (`R`) advances the deterministic seed by 7,919, producing a reproducible variant. The initial seed is `20260927`.

## Candidate assets

Original generated sources and downsized/alpha-keyed derivatives are in `assets/`. The current Gothic/chess experiment uses the stone floor pair, dark wall-face texture, moss and crimson-resin decals, pillar, and portal sprite. The cable decal is retained as an isolated candidate for a future industrial theme and is deliberately not placed in this level. Some cutouts retain colored glow/fringing. These are provisional AI-generated candidates, not approved production art; the portal candidate in particular still needs camera/style review. The mixed 2.5D camera itself was approved as the environmental reference (`concepts/README.md`), not every image or finish.

## Validation and limits

`tests/godot_procedural_first_level.gd` checks 24 deterministic seeds for connectivity, boundaries, reachable collision-safe placements, and repeatability; it also checks BFS pursuit steps and exercises legal and blocked movement in the alternate scene. The project smoke wrapper runs this test after the animation and evasion suites.

A passing headless test establishes parsing/resource loading and the listed grid invariants only. It cannot establish that the maze is readable, the chase is fair or fun, collision footprints feel right, or the visual style is approved. Review the scene in a display-enabled Godot editor before promoting any asset or changing the default scene.

## Owner playtest evidence — 2026-09-27

**OBSERVED (owner report):** The procedural loop runs, but this slice was not fun, scary, or visually coherent. It read as PNGs placed in an arena; props appeared to have inconsistent depth/perspective, movement felt like teleporting, and the room lacked a grounded-world feeling. This is direct playtest feedback, not a claim about every possible procedural approach. Keep the experiment and its source images as evidence; do not extend this room by adding content or systems.

**Validation status:** GitHub Actions run `36311764605` built the pinned Godot binary but the headless smoke step failed. The log download also failed with TLS/EOF, so the failing subtest and cause are UNKNOWN. Do not treat the 24-seed test as passed until the failure is diagnosed.
