# First evasion slice (reversible experiment)

This alternate scene reuses the current player controls, sprites, shields, world renderer, and turn resolution. It does not replace the default scene (`scenes/main.tscn`) or alter the animation assets/review pipeline.

## Run

Open `experiments/evasion_first_slice/evasion_first_slice.tscn` in Godot and press **F6** (Run Current Scene). The project default remains unchanged.

## Hypothesis being tested

A short cycle of visible pursuit, breaking line of sight, investigation of the last seen cell, a two-turn visible scan, and retreat to the original guard point can create a readable escape-and-recovery decision using only existing move, jump, wait, and wall-blocking rules.

The new enemy state is confined to this experiment. Its path search is breadth-first and deterministic; sight has a six-cell Chebyshev range and uses wall-occluded grid line of sight. The sight range and search duration are temporary test values, not approved design values. No directional vision, hiding, object distractions, inventory, dynamic director, or new HUD is introduced.

## Validation and what remains unproven

**MEASURED:** Godot 4.7.2 headless smoke passes. The existing room's 7,482 reachable ordered path pairs produced 0 invalid first steps; tests also pass for pursuit, wall-blocked sight, last-seen investigation, the bounded search, recovery, reacquisition, and experiment-scene integration.

This does not establish whether the pursuit is readable, frightening, fair, or fun. The two shields, short sight range, search duration, map readability, and eye-color state cues still require visual review and a human playtest. Record observed player choices and confusion before tuning parameters.
