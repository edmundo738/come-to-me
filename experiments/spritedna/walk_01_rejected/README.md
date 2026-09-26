# SpriteDNA walk experiment 01 — rejected

This is a preserved failure, not an active animation tool or production asset.

- **User review:** visually rejected as unacceptable.
- **Generator:** `generator.py` applies full-image Gaussian-weighted raster deformation to one flattened sprite. Bone-length tests passed, but they did not assess the artwork; the method caused too much texture/silhouette change.
- **Frames:** preserved under `characters/protagonist/review/walk_n_frente_spritedna_01/frames/` with hashes and technical reports.
- **Old scene:** preserved here for historical reproduction only; it is not a recommended project scene.
- **Preview bug:** the old GIF used undefined disposal and could accumulate transparent frames. It is archived beside the frames; use `preview.apng` or the review folder's `index.html` to inspect frame replacement.
- **No production assets were edited.** Approved idle images and the main gameplay scene are unchanged.

Root-cause measurements, external research and the next pipeline decision are in `docs/character-animation/sprite_pipeline_diagnosis.md`.
