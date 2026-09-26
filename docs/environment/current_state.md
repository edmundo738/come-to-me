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
- Actions run `36269841970` (`f235f7f`) completed successfully: pinned source build, headless project smoke test, packaging, draft Release upload, and 90-day Actions artifact upload all passed. GitHub Release metadata reports the 92,904,612-byte archive with digest `sha256:cd9b82cc0a6836b71d2f0a18e24ceb986c7a40cd1a57769b0235b6cac4c1aef4`, plus its 114-byte checksum file; the Actions artifact is 91,802,930 bytes.
- A `gh release download` attempt for the small checksum sidecar ended in TLS/EOF. Asset availability is confirmed by GitHub metadata, but actual download and bootstrap restore remain unverified. GitHub API/read access works.
- An explicit `gh workflow run` earlier returned HTTP 403 `Resource not accessible by integration`.

INFERRED:
- The function-name collision was the reported parser failure's cause; the exact incompatible signature plus the post-rename passing parser/scene tests confirm the diagnosis.
- A cached artifact is needed for rapid recovery; the source rebuild path is reproducible but costs about 34 minutes in this workspace.
- GitHub Releases/Actions storage is appropriate for the binary, but artifact availability and download have not been proven with the current GitHub connection.
- Headless results A–E do not establish smoothness, jitter, pivot, scale, halo/shadow appearance, visual continuity, or human approval.

HYPOTHESIS:
- No remaining hypothesis is being used to explain the parser error. Animation visual quality remains unassessed in this environment.

UNKNOWN:
- Whether the published Release asset or Actions artifact can be downloaded and restored by bootstrap; the checksum-sidecar transfer returned TLS/EOF, and the full restore path has not been exercised.
- Whether a human-visible editor session can open in a separate desktop-enabled environment; this binary cannot provide that here.
- Whether visual capture works with another rendering/display backend; no such backend is installed or compiled here.
- Whether a standalone exported game package works; export templates and a graphical/runtime review were not tested.

CURRENT STATE:
- Reconciliation started with workspace `HEAD` at `a1ee6c2` and GitHub branch at `f235f7f` (10 commits ahead). Exact-content comparison found all 400 remote paths in the workspace, no workspace-only files, and exactly three differing files: this state record, `docs/environment/godot_environment.md`, and `tools/godot/bootstrap.sh`.
- The local branch was fast-forwarded to the fetched remote tip without replacing worktree files; the three preserved changes were then synchronized as a narrow checkpoint. The fixed branch tip is the source of truth for the resulting checkpoint.
- Workspace and GitHub are synchronized on the fixed branch; the practical experience hierarchy is recorded in `docs/game_direction.md`.
- The current workspace still has no Godot executable in `PATH`. The pinned CI build and headless smoke suite succeeded remotely; Release/Actions assets are published, but downloading/restoring them has not been confirmed.

NEXT ACTION:
- Continue practical game planning and production from the existing prototype. Do not rebuild Godot or expand recovery infrastructure unless the project needs the tool or the unresolved asset download becomes a real blocker.

LAST VERIFIED:
- 2026-09-26 (workspace local time); eight Python unit tests and shell syntax checks pass in this workspace. Actions run `36269841970` completed all steps successfully. The Godot smoke suite passed on GitHub's runner; it has not been rerun in this workspace because `godot` is absent.

CHECKPOINT POLICY:
- The fixed branch `arena/01a0dda9-come-to-me` is the canonical checkpoint. Confirm its tip and worktree status from Git instead of duplicating a self-referential commit ID in this document.
