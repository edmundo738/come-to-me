# Current Godot environment state

FACT:
- The active project is Come to Me on the fixed branch `arena/01a0dda9-come-to-me`.
- Godot is installed at `/usr/local/bin/godot`; runtime version is `4.7.2.stable.custom_build` from tag `4.7.2-stable`, source commit `ed1daf0bf001b61586d9930840f2f1394092c079`.
- The original local helper `draw_ellipse(Vector2, Vector2, Color)` collided with native `CanvasItem.draw_ellipse`; it was minimally renamed to `draw_shadow_ellipse` at its definition and two call sites. No animation source pixels or animation logic changed.
- This binary has the headless display driver and dummy rendering only; X11/Wayland GUI and visual review are unavailable here.
- The SpriteDNA walk 01 remains rejected and untouched.

MEASURED:
- Executable: 219,661,192 bytes; SHA-256 `db4cf162429ca0352be3b0a03125e111451c4130b9a078885ba68cf7fca23564`.
- Clean source build: 34:16.39 in SCons; 2,078 seconds including source download, SCons setup and installation.
- `tests/godot_headless_smoke.sh` passes: editor/import scan, PNG checks, runtime SpriteFrames, timed AnimatedSprite2D, TRES save/reload, main-scene integration, default-scene bounded startup, and animation-review scene startup.
- All four 12-frame sequences are RGBA `384×544`; their individual durations match the configured values and each cycle totals 3.19 seconds.
- Front source frames 001/002 differ in 2,449 of 208,896 pixels. This is file-level evidence only, not an art-quality judgment.
- GitHub Release archive currently measures 89 MiB compressed; its hash and bootstrap retrieval are to be verified before finalizing this record.

OBSERVED:
- Runtime ClassDB reports `CanvasItem.draw_ellipse(position, major, minor, color, filled, width, antialiased)`; the pre-fix Godot log said the local method signature did not match the parent. After the rename, the editor scan and both scenes run without script/resource errors.
- Project import and headless resource tests produce no screenshot. `DisplayServer.get_name()` returns `headless`, the rendering adapter name is empty, and explicit `--rendering-driver opengl3` is rejected; only dummy rendering is offered.
- Godot generated 153 `.import` sidecars and 8 `.uid` files. `.godot/` is ignored cache and not committed.
- A prior `/usr/local/bin/godot` installation vanished after workspace reset, confirming an out-of-repository binary is not durable by itself.

INFERRED:
- The function-name collision was the reported parser failure's cause; the exact incompatible signature plus the post-rename passing parser/scene tests confirm the diagnosis.
- A checksummed GitHub Release asset outside Git history is the appropriate recovery fast path for this 210 MiB executable; the pinned source build remains fallback.
- Headless results A–E do not establish smoothness, jitter, pivot, scale, halo/shadow appearance, visual continuity, or human approval.

HYPOTHESIS:
- No remaining hypothesis is being used to explain the parser error. Animation visual quality remains unassessed in this environment.

UNKNOWN:
- Whether a human-visible editor session can open in a separate desktop-enabled environment; this binary cannot provide that here.
- Whether visual capture works with another rendering/display backend; no such backend is installed or compiled here.
- Whether a standalone exported game package works; export templates and a graphical/runtime review were not tested.

CURRENT STATE:
- Project smoke test is green in headless mode. Tests A–E are recorded as confirmed; render/capture/visual review are recorded unavailable for this build.
- The build and bootstrap scripts, smoke tests, environment report, current-state record and helper-name fix are ready for checkpoint.
- The 89 MiB checksummed GitHub Release asset has been prepared outside Git; draft Release upload and restore-path test are the remaining environment-preservation steps.

NEXT ACTION:
- Commit and push the project checkpoint to the fixed branch, create a draft Release outside normal Git history, verify download/restore through bootstrap, update the artifact hash/status and push that final documentation checkpoint.

LAST VERIFIED:
- 2026-09-26 (workspace local time); headless smoke suite and 8 Python unit tests pass.

COMMIT:
- Pending checkpoint commit.
