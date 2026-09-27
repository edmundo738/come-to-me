## Update 2026-09-27 — isolated procedural environment slice

FACT:
- The owner approved the intermediate mixed 2.5D camera as an environmental development reference. This is not approval of concept illustrations, candidate textures, prop art, or final polish; `concepts/README.md` now records that distinction.
- `experiments/procedural_first_level/` adds an F6-run alternate scene. It uses the existing player animation and turn-resolution code while generating seeded connected mazes, reachable pickups and exit, blocking walls/pillars, and walkable-only decals. A small experiment-only BFS pursuer prevents maze-corner stalls.
- The default `scenes/main.tscn`, `scripts/main.gd`, `scripts/grid_world.gd`, character frame PNGs, and animation review/promotion workflow remain unchanged. Generated source images and processed candidate textures are kept in the isolated experiment; no candidate is approved production art.
- The Gothic/chess experiment deliberately does not place the cable decal, which remains an isolated candidate for a future industrial theme. Some generated cutouts retain colored glow/fringing.

MEASURED:
- The generated texture candidates are small, grid-sized PNGs; cutout candidates report RGBA channels and transparent corners via ImageMagick. Their residual glow means a transparent corner alone is not a clean-edge/art-quality approval.
- Existing Python tests: 8 passed. Shell syntax check and `git diff --check` passed.

UNKNOWN:
- Godot parsing, scene/resource import, the new 24-seed connectivity/collision test, actual in-engine behavior, and rendered appearance have not been verified in this workspace. No Godot executable is installed; downloading the existing headless Release asset ended with a TLS/EOF transfer error. The project remains headless-only here, with no human visual playtest. Remote pinned-engine CI run `36311764605` for commit `6a148319503ba3e31f081e160fde7cb6a2e28684` is currently building Godot; the smoke suite is pending.
- Whether the generated maze and environmental candidates are readable, attractive, fair, and fun remains for display-enabled review.

CURRENT EXPERIMENT PATHS:
- Scene: `experiments/procedural_first_level/procedural_first_level.tscn` (F6 in Godot).
- Technical test: `tests/godot_procedural_first_level.gd`, added to `tests/godot_headless_smoke.sh` for the next available pinned-engine run.
- Full experiment notes and limitations: `experiments/procedural_first_level/README.md`.

---

# Current Godot environment state

FACT:
- The active project is Come to Me on the fixed branch `arena/01a0dda9-come-to-me`.
- The previously validated executable was `/usr/local/bin/godot`, runtime `4.7.2.stable.custom_build`, from tag `4.7.2-stable`, source commit `ed1daf0bf001b61586d9930840f2f1394092c079`. In the workspace inspected for this reconciliation, `godot` is absent from `PATH`; invoking `godot --version` returned `command not found`.
- The original local helper `draw_ellipse(Vector2, Vector2, Color)` collided with native `CanvasItem.draw_ellipse`; it was minimally renamed to `draw_shadow_ellipse` at its definition and two call sites. No animation source pixels or animation logic changed.
- This binary has the headless display driver and dummy rendering only; X11/Wayland GUI and visual review are unavailable here.
- The SpriteDNA walk 01 remains rejected and untouched.

MEASURED:
- Executable: 219,661,192 bytes; SHA-256 `db4cf162429ca0352be3b0a03125e111451c4130b9a078885ba68cf7fca23564`.
- Historical clean source build: 34:16.39 in SCons; 2,078 seconds including source download, SCons setup and installation.
- This turn's pinned rebuild: SCons 31:00.63; 1,882 seconds including setup/install. Temporary executable `/tmp/come-to-me-godot-install/godot` is 219,661,192 bytes, SHA-256 `98348a419a384e00dadeb3f5573f70b1ffe2510518776a5758266537eadbd235`; binary remains outside Git.
- This turn's `tests/godot_headless_smoke.sh` passes: editor/import scan, existing resource/animation suite, tactical-evasion suite, default-scene startup, and animation-review startup.
- Tactical-evasion suite: all 7,482 reachable ordered room pairs take an optimal valid first step (0 failures); LOS loss, last-seen memory, bounded search, recovery, reacquisition, and alternate-scene turn integration pass.
- All four 12-frame sequences are RGBA `384×544`; their individual durations match the configured values and each cycle totals 3.19 seconds.
- Front source frames 001/002 differ in 2,449 of 208,896 pixels. This is file-level evidence only, not an art-quality judgment.
- Locally prepared archive: 93,208,968 bytes; SHA-256 `60f5d7032e98ec9b87aa3e3debf4da78eaa879c6c0fd6b43755673f649edfb65`, outside Git. Separately, GitHub Release metadata confirms CI archive digest `sha256:cd9b82cc0a6836b71d2f0a18e24ceb986c7a40cd1a57769b0235b6cac4c1aef4`; do not conflate the two builds.

OBSERVED:
- Runtime ClassDB reports `CanvasItem.draw_ellipse(position, major, minor, color, filled, width, antialiased)`; the pre-fix Godot log said the local method signature did not match the parent. After the rename, the editor scan and main, animation-review, and evasion experiment scenes run without script/resource errors.
- Project import and headless resource tests produce no screenshot. `DisplayServer.get_name()` returns `headless`, the rendering adapter name is empty, and explicit `--rendering-driver opengl3` is rejected; only dummy rendering is offered. The latest smoke again produced no screenshot artifact.
- Godot generated 153 `.import` sidecars and 8 `.uid` files. `.godot/` is ignored cache and not committed.
- A prior `/usr/local/bin/godot` installation vanished after workspace reset, confirming an out-of-repository binary is not durable by itself.
- A GitHub draft Release exists. Direct `gh release upload` from the sandbox failed with TLS/EOF even for a 653-byte manifest.
- Actions run `36269841970` (`f235f7f`) completed successfully: pinned source build, headless project smoke test, packaging, draft Release upload, and 90-day Actions artifact upload all passed. GitHub Release metadata reports the 92,904,612-byte archive with digest `sha256:cd9b82cc0a6836b71d2f0a18e24ceb986c7a40cd1a57769b0235b6cac4c1aef4`, plus its 114-byte checksum file; the Actions artifact is 91,802,930 bytes.
- A `gh release download` attempt for the small checksum sidecar ended in TLS/EOF. Asset availability is confirmed by GitHub metadata, but actual download and bootstrap restore remain unverified. GitHub API/read access works.
- The latest Actions run `36274222692` for the evasion checkpoint completed successfully: pinned engine build, project headless smoke (including the new evasion tests), packaging, Release upload, and Actions artifact upload all succeeded. The uploaded binary targets Linux x86_64 and is headless; it is neither a Windows Godot editor nor an exported game. Asset download on the user's machine has not been confirmed.
- An explicit `gh workflow run` earlier returned HTTP 403 `Resource not accessible by integration`.

INFERRED:
- The function-name collision was the reported parser failure's cause; the exact incompatible signature plus the post-rename passing parser/scene tests confirm the diagnosis.
- A cached artifact is needed for rapid recovery; the source rebuild path is reproducible but costs about 34 minutes in this workspace.
- Release and Actions artifact publication is confirmed. GitHub metadata can be read; actual asset download and bootstrap restoration have not been proven because the sidecar transfer returned TLS/EOF.
- Headless results A–E do not establish smoothness, jitter, pivot, scale, halo/shadow appearance, visual continuity, or human approval.

HYPOTHESIS:
- No remaining hypothesis is being used to explain the parser error. Animation visual quality remains unassessed in this environment.

UNKNOWN:
- Whether the published Release asset or Actions artifact can be downloaded and restored by bootstrap; the checksum-sidecar transfer returned TLS/EOF, and the full restore path has not been exercised.
- Cause of the local Git ref resetting to the initial commit at the start of a later workspace turn; the exact source tree was present, but the repository metadata needed re-alignment.
- Whether a human-visible editor session can open in a separate desktop-enabled environment; this binary cannot provide that here.
- Whether visual capture works with another rendering/display backend; no such backend is installed or compiled here.
- Whether a standalone exported game package works; export templates and a graphical/runtime review were not tested.

CURRENT STATE:
- At the start of this turn, local Git refs again showed `HEAD=a1ee6c2` while GitHub was at `5b20cbf`. Exact-content comparison found all 401 remote files present locally, with no missing, extra, or differing source files. The local ref was re-aligned by a mixed reset without replacing files. The reason this metadata reset recurs across turns is UNKNOWN.
- The fixed branch now contains the approved experience hierarchy, gameplay research, and the isolated first evasion experiment; details and limits are recorded in `docs/game_direction.md`, `docs/gameplay_core_research.md`, and `experiments/evasion_first_slice/`.
- At this turn's start no Godot executable was available in `PATH`, and both GitHub Release/Actions binary downloads failed with TLS/EOF. A checksum-pinned Godot 4.7.2 headless source rebuild was completed to `/tmp/come-to-me-godot-install/godot` (not in Git, no editor GUI/display). The Godot smoke and tactical-evasion suite passed locally.
- The evasion experiment's exhaustive grid check measured 7,482 reachable ordered pairs and 0 invalid first steps; line-of-sight/state transitions and alternate-scene integration also passed. No headless screenshot was produced.

NEXT ACTION:
- Open `experiments/evasion_first_slice/evasion_first_slice.tscn` in a display-enabled Godot environment and observe a first-time player without explaining the intended route. Record whether they identify the initial sight, use a route change, interpret the last-seen search, and exploit or ignore the recovery window. Headless evidence cannot establish readability, fun, or art approval.

LAST VERIFIED:
- 2026-09-26 (workspace local time); pinned Godot `4.7.2.stable.custom_build` local headless smoke passes, including 7,482 BFS pairs and the evasion state/integration tests. Eight Python unit tests, shell syntax checks, and `git diff --check` pass. The headless run did not produce a screenshot; human visual playtest remains unperformed.

CHECKPOINT POLICY:
- The fixed branch `arena/01a0dda9-come-to-me` is the canonical checkpoint. Confirm its tip and worktree status from Git instead of duplicating a self-referential commit ID in this document.
