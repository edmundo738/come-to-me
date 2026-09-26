# Study 04 — WALK_NORMAL

**Production dependency:** final four-direction walk production still waits for approved directional masters and a stable camera/pivot. The user authorized one isolated front-facing proof; **experiment 01 was then rejected as visually unacceptable**. No walk sequence is currently approved for gameplay.
**Emotional read:** ordinary, alert exploration with human weight.
**Not in this study:** running, fear gait, root-motion baked into PNG frames, scenery.

## SpriteDNA experiment 01 — WALK_N_FRENTE (REJECTED)

A 12-frame experiment was generated from the approved front idle master (read-only). The PNGs and reports remain under `characters/protagonist/review/walk_n_frente_spritedna_01/`; the generator and test scene are archived in `experiments/spritedna/walk_01_rejected/`. The user judged the motion visually unacceptable; do not integrate or promote it.

The experiment used Gaussian-weighted inverse deformation over the flattened full-body raster. Bone-length assertions passed, but that does not establish good pixel-art motion. Measured alpha bounds varied (width 168–178 px vs 172 px in the master; height by up to 2 px), adjacent changed-pixel counts were 12,785–31,419, and the preview GIF had undefined frame disposal. The evidence and corrected preview workflow are documented in `sprite_pipeline_diagnosis.md`. Keep the existing idle/master assets unchanged; no new walk frames should be generated with this approach.

## Motion study

A walk is a repeated transfer of support, not a sliding character. Use the recognizable pose sequence **contact → down/weight acceptance → passing → up/push-off**, then repeat it for the other leg. Opposite arm/leg timing helps balance. This basic model is documented in walk-cycle teaching material such as [Spotlight FX's guide](https://spotlightfx.com/blog/walk-cycle-animation-beginners-guide-to-creating-realistic-movement); it must be redrawn for Come to Me's overhead/oblique camera, not copied from a side-view example.

## Frame plan: 8-frame, two-step prototype

1. Contact A: left/right lead chosen in the master pose sheet; leading foot finds the ground, trailing foot still supports.
2. Down A: accept weight over planted foot; slight knee/torso compression.
3. Passing A: free foot passes under the body; planted support remains fixed.
4. Up A: push-off/high point; prepare opposite contact.
5. Contact B: opposite foot leads; mirror the *action logic*, not necessarily the pixels.
6. Down B: transfer weight to opposite planted foot.
7. Passing B: other free foot passes under the body.
8. Up B/recovery: complete the second step and flow toward contact A without an artificial repeated-frame pause.

Eight frames are the project floor. If the change from one key pose to another pops at gameplay scale, plan 10–12 frames/in-betweens with a clear reason. Every frame should advance a specific foot/body phase.

## Grid movement separation

The gameplay code changes the logical cell discretely. The visual walk animates the body's stride while the root/pivot moves from source to destination. Define how playback is triggered relative to the turn/movement tween; do not encode extra world displacement inside PNGs. Test the walk at actual cell-transition duration so the feet do not skate. Idle/walk switching must not change canvas origin or pivot.

## Overhead-direction adaptation

The camera remains fixed; “front/back/left/right” are world-facing orientations. For each of the four, draw a separate overhead/oblique view with the same foreshortening, head visibility, body length and lighting logic. Keep world axes screen-aligned; avoid rotating the sprite into a diamond or substituting a conventional side-on view. A side-world orientation is still seen from above.

## Review checks

- Step the animation frame by frame and identify contact, down, passing, up.
- Verify the supporting foot's pixel position stays planted through its support interval.
- Check hips/torso carry weight rather than bobbing symmetrically like a pogo stick.
- Check opposite arm/leg rhythm; simplify arms if they collapse into the torso at native scale.
- Loop last→first and compare stride length and velocity.
- Review at game scale and several FPS values; make FPS follow movement speed.
- Keep files transparent, same canvas/pivot, one direction per folder.

## Failure conditions

Foot sliding, no down pose/weight, both feet teleporting, symmetrical robot sway, camera drift, a diagonal/isometric-facing sprite, accidental running, or changes to the character's identity.
