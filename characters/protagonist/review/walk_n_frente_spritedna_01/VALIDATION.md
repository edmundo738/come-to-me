# WALK_N_FRENTE — SpriteDNA experiment 01

**Status:** **REJECTED by the user as visually unacceptable**. Keep only as a failed experiment; do not integrate or promote. It has not been tested in Godot.
**Input (read-only):** `characters/protagonist/animations/idle_normal/frente/frame_001.png`
**Input SHA-256:** `1c3eafe1be506c742b53cc51336dfc30c1f2120c56054fbb6d42e1c81d5b3ffa`
**Method:** deterministic 2D landmarks, two-bone IK for knees (38 px + 31 px lengths asserted per frame), opposite-phase arm swing, subtle pelvis/torso weight transfer, Gaussian-weighted full-image inverse deformation and nearest-neighbour sampling. This raster-warp approach is rejected.
**Reproducibility:** a second generation produced byte-identical PNGs for all 12 frames. See `CHECKSUMS.sha256`.
**Pipeline diagnosis:** `docs/character-animation/sprite_pipeline_diagnosis.md`. The legacy GIF preview had undefined disposal and is retained only as `preview_gif_rejected_undefined_disposal.gif`; `preview.apng` is the lossless frame-replacement preview.
**Timing:** 12 frames at 12.5 FPS (0.96 s per two-step loop).
**No root motion is baked into the PNGs.** The game should move the root between cells separately if/when this candidate is approved.

| Frame | Alpha bounds | Alpha pixels | Changed pixels from previous | Max displacement (x/y) |
|---:|---|---:|---:|---:|
| 001 | (106, 150, 172, 354) | 37509 | — | 6.49px / 11.91px |
| 002 | (106, 150, 171, 354) | 37447 | 12785 | 6.28px / 10.37px |
| 003 | (107, 150, 169, 354) | 37355 | 29051 | 5.59px / 7.35px |
| 004 | (108, 150, 168, 352) | 37283 | 17155 | 4.39px / 3.96px |
| 005 | (108, 150, 169, 352) | 37353 | 16601 | 3.92px / 5.18px |
| 006 | (107, 150, 171, 354) | 37395 | 30475 | 4.32px / 8.89px |
| 007 | (106, 150, 172, 354) | 37410 | 17045 | 4.80px / 11.91px |
| 008 | (105, 150, 174, 354) | 37680 | 13538 | 4.84px / 10.36px |
| 009 | (104, 150, 176, 354) | 37950 | 29009 | 4.78px / 7.35px |
| 010 | (103, 150, 178, 352) | 38153 | 17344 | 4.39px / 3.96px |
| 011 | (104, 150, 176, 352) | 38044 | 15771 | 4.71px / 5.18px |
| 012 | (105, 150, 174, 354) | 37786 | 31419 | 5.75px / 8.89px |

## Review checklist

- Check contact/down/pass/up at native size.
- Look for foot sliding, toe clipping, holes, limb warping and arm/leg overlap.
- Compare loop frame 012 → 001 using `preview.apng` or the Godot frame viewer.
- Treat the APNG only as a faithful preview of the rejected frames, not as a quality fix for the gait.
- Do not integrate this sequence into production or overwrite any approved cycle.
