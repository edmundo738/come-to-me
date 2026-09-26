# Current Godot environment state

FACT:
- The active project is Come to Me on the fixed branch `arena/01a0dda9-come-to-me`.
- The previously validated executable was `/usr/local/bin/godot`, runtime `4.7.2.stable.custom_build`, from tag `4.7.2-stable`, source commit `ed1daf0bf001b61586d9930840f2f1394092c079`. In the workspace inspected for this reconciliation, `godot` is absent from `PATH`; invoking `godot --version` returned `command not found`.
- The original local helper `draw_ellipse(Vector2, Vector2, Color)` collided with native `CanvasItem.draw_ellipse`; it was minimally renamed to `draw_shadow_ellipse` at its definition and two call sites. No animation source pixels or animation logic changed.
- This binary has the headless display driver and dummy rendering only; X11/Wayland GUI and visual review are unavailable here.
- The SpriteDNA walk 01 remains rejected and untouched.

MEASURED:
- Executable: 219,661,192 bytes; SHA-256 `db4cf162429ca0352be3b0a03125e111451c4130b9a078885ba68cf7fca23564`.
- Clean source build: 34:16.39 in SCons; 2,078 seconds including source download, SCons setup and installation.
- `tests/godot_headless_smoke.sh` passes: editor/import scan, PNG checks, runtime SpriteFrames, timed AnimatedSprite2D, TRES save/reload, main-scene integration, default-scene bounded startup, and animation-review scene startup.
- All four 12-frame sequences are RGBA `384×544`; their individual durations match the configured values and each cycle totals 3.19 seconds.
- Front source frames 001/002 differ in 2,449 of 208,896 pixels. This is file-level evidence only, not an art-quality judgment.
- Prepared cache archive: 89 MiB compressed; SHA-256 `60f5d7032e98ec9b87aa3e3debf4da78eaa879c6c0fd6b43755673f649edfb65`. It is outside Git; no final remote asset status is confirmed.

OBSERVED:
- Runtime ClassDB reports `CanvasItem.draw_ellipse(position, major, minor, color, filled, width, antialiased)`; the pre-fix Godot log said the local method signature did not match the parent. After the rename, the editor scan and both scenes run without script/resource errors.
- Project import and headless resource tests produce no screenshot. `DisplayServer.get_name()` returns `headless`, the rendering adapter name is empty, and explicit `--rendering-driver opengl3` is rejected; only dummy rendering is offered.
- Godot generated 153 `.import` sidecars and 8 `.uid` files. `.godot/` is ignored cache and not committed.
- A prior `/usr/local/bin/godot` installation vanished after workspace reset, confirming an out-of-repository binary is not durable by itself.
- A GitHub draft Release exists. Direct `gh release upload` from the sandbox failed with TLS/EOF even for a 653-byte manifest.
- At the latest GitHub poll, Actions run `36269841970` (`f235f7f`) was `in_progress` at “Run the project headless smoke test”; the pinned source build step had completed successfully. GitHub still reported zero run artifacts and the draft Release had zero assets at that instant. `gh auth status`, branch listing, and fetch succeed; the prior HTTP 401 is no longer blocking access.
- An explicit `gh workflow run` earlier returned HTTP 403 `Resource not accessible by integration`.

INFERRED:
- The function-name collision was the reported parser failure's cause; the exact incompatible signature plus the post-rename passing parser/scene tests confirm the diagnosis.
- A cached artifact is needed for rapid recovery; the source rebuild path is reproducible but costs about 34 minutes in this workspace.
- GitHub Releases/Actions storage is appropriate for the binary, but artifact availability and download have not been proven with the current GitHub connection.
- Headless results A–E do not establish smoothness, jitter, pivot, scale, halo/shadow appearance, visual continuity, or human approval.

HYPOTHESIS:
- No remaining hypothesis is being used to explain the parser error. Animation visual quality remains unassessed in this environment.

UNKNOWN:
- Whether Actions run `36269841970` will complete successfully and upload its Release/90-day artifact; at the latest check it was still building and both stores were empty.
- Whether a future artifact can be downloaded and restored by bootstrap; the restore path has not yet been exercised.
- Whether a human-visible editor session can open in a separate desktop-enabled environment; this binary cannot provide that here.
- Whether visual capture works with another rendering/display backend; no such backend is installed or compiled here.
- Whether a standalone exported game package works; export templates and a graphical/runtime review were not tested.

CURRENT STATE:
- Reconciliation started with workspace `HEAD` at `a1ee6c2` and GitHub branch at `f235f7f` (10 commits ahead). Exact-content comparison found all 400 remote paths in the workspace, no workspace-only files, and exactly three differing files: this state record, `docs/environment/godot_environment.md`, and `tools/godot/bootstrap.sh`.
- The local branch was fast-forwarded to the fetched remote tip without replacing worktree files; the three preserved changes were then synchronized as a narrow checkpoint. The fixed branch tip is the source of truth for the resulting checkpoint.
- In the latest pre-sync poll, Actions run `36269841970` had completed source compilation and was smoke-testing; the current workspace has no Godot executable in `PATH`, and remote artifact restoration remains unconfirmed.

NEXT ACTION:
- With workspace and GitHub synchronized, move to practical game planning from the existing prototype. Do not start additional environment work unless the already-running Actions result reveals a concrete blocker or recovery need.

LAST VERIFIED:
- 2026-09-26 (workspace local time); eight Python unit tests and shell syntax checks pass in this workspace. The Godot headless smoke suite passed in the prior validated environment; it cannot be rerun here because `godot` is absent. Actions run `36269841970` was still in progress at its latest poll.

CHECKPOINT POLICY:
- The fixed branch `arena/01a0dda9-come-to-me` is the canonical checkpoint. Confirm its tip and worktree status from Git instead of duplicating a self-referential commit ID in this document.
