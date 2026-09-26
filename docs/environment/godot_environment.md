# Godot environment and headless capability record

## Scope

This document records what this repository's Godot installation has actually demonstrated in the Arena Linux workspace. A manual/API description, successful compile, or valid PNG is not treated as proof that the full game or its visuals work.

**Build profile:** Godot 4.7.2 stable source, LinuxBSD x86_64 `editor` target, capable of CLI/headless processing. It has no X11/Wayland display backend and its headless rendering driver is `dummy`; it is not the interactive desktop editor.

## `draw_ellipse` collision: cause confirmed

**FACT:** `scripts/main.gd` originally defined `func draw_ellipse(center: Vector2, radius: Vector2, color: Color) -> void` at line 321 and called it twice to draw player/enemy ground shadows. This three-argument helper does not have the native method's signature.

**FACT:** the pinned Godot 4.7.2 source declares `CanvasItem::draw_ellipse(position: Vector2, major: float, minor: float, color: Color, filled: bool = true, width: float = -1.0, antialiased: bool = false)`. Runtime `ClassDB.class_get_method_list("CanvasItem")` in this build exposes `draw_ellipse` with those seven argument names/types.

**OBSERVED:** before correction, Godot emitted “The function signature doesn't match the parent” for `draw_ellipse`, then identified the local method as overriding `CanvasItem.draw_ellipse`; the warning was treated as an error and `main.gd` failed to load.

**INFERRED / CONFIRMED BY RETEST:** GDScript treated the same-named helper as an override, and the incompatible signature caused the parse failure. The minimal fix renames it to `draw_shadow_ellipse` at its definition and two call sites. Its polygon math, color, geometry, and call arguments are unchanged. The post-fix editor scan, main-scene instantiation, and bounded game-scene boot pass without script parse errors. This is a naming fix only; it does not change animation or artwork.

## Reproducible build identity

- Godot tag: `4.7.2-stable`.
- Source commit: `ed1daf0bf001b61586d9930840f2f1394092c079` (tag resolves to this commit).
- Source archive: `https://codeload.github.com/godotengine/godot/tar.gz/ed1daf0bf001b61586d9930840f2f1394092c079`.
- Verified source archive: 71,921,164 bytes; SHA-256 `e607e9985e1c201bc9cdc1aec8a120f0c3f53b9603f1f828e2b748534a2471ef`.
- Runtime version: `4.7.2.stable.custom_build`.
- Platform/architecture: Debian GNU/Linux 12, `linuxbsd`, x86_64.
- SCons: 4.11.1 in a temporary Python 3.11 virtual environment.
- Compiler: Debian `g++` 12.2.0.
- Build dependencies used: Python 3.11 with venv/pip, SCons, GCC/G++, libc development headers and ordinary GNU build utilities.
- System `pkg-config` and apt mirrors were unavailable. The pinned build script supplies a temporary `pkg-config` version-probe shim and explicitly disables optional system-library integrations; it does not claim those libraries are installed.
- SCons configuration:

```text
platform=linuxbsd target=editor arch=x86_64 optimize=none debug_symbols=no
use_static_cpp=no use_sowrap=no x11=no wayland=no fontconfig=no
alsa=no pulseaudio=no dbus=no speechd=no udev=no sdl=no accesskit=no -j2
```

- Installed executable: `/usr/local/bin/godot`.
- Executable size: 219,661,192 bytes (about 209.5 MiB).
- Executable SHA-256: `db4cf162429ca0352be3b0a03125e111451c4130b9a078885ba68cf7fca23564`.
- Runtime dynamic dependencies reported by `ldd`: `libstdc++.so.6`, `libm.so.6`, `libgcc_s.so.1`, `libc.so.6`, and the ELF loader.
- Clean build time: SCons reported 34:16.39; build script total for source download, SCons setup, compile and install was 2,078 seconds (34:38).
- Temporary build tree measured at 1.7 GiB after 26:25 of compilation; peak disk use was not instrumented. The build script removes this source/object tree when it exits.
- A previous clean install had the same byte size but a different executable hash. The differing hash's cause was not isolated, so the pinned inputs/configuration provide repeatable version and behavior, not a claim of bit-for-bit identical fresh builds. The Release artifact hash below protects the stored binary itself.

`target=editor` includes editor classes and headless editor/import mode. It does not make this a GUI-capable editor: both display backends are disabled, and this workspace has no `DISPLAY` or `WAYLAND_DISPLAY`.

## Preserve / recovery design

A prior turn installed Godot only outside the repository (`/usr/local/bin`) and kept source files under `/tmp`. At the beginning of this turn both were absent after the workspace reset. This is direct evidence that the system install alone is not a durable checkpoint.

- **Level 1 — rebuild:** `tools/godot/build_headless.sh` pins the source commit and archive SHA, SCons version, platform, architecture, and flags; installs the resulting binary; and prints version, size, SHA and elapsed time.
- **Level 2 — cached artifact:** the binary is much too large for normal Git history. A checksummed GitHub draft Release asset is used as the fast path and is stored outside branch history. The bootstrap downloads it with authenticated `gh`, checks its archive SHA, checks the executable SHA inside the archive, and checks `--version`. Exact tag, asset name and archive SHA are recorded after upload verification.
- **Level 3 — bootstrap:** `tools/godot/bootstrap.sh` reuses a matching installed Godot, otherwise restores the checksummed Release asset, otherwise rebuilds from the pinned source, then runs the project smoke test.
- **Required to run:** verified Godot executable plus project source/assets. The `.godot/` imported cache is regenerated by the smoke test.
- **Required to rebuild if the asset cannot be fetched:** network access to PyPI and `codeload.github.com`, Python 3.11/venv, SCons 4.11.1, GCC/G++, libc development headers, and the pinned build utilities.
- **Not kept in normal Git:** Godot source tree, `.o` files/SCons cache, executable build artifacts, `.godot/`, smoke captures, and `user://` TRES test output.

The repository's `.gitignore` excludes `.godot/` (cache), not `*.import` sidecars. Godot 4.7 import documentation says `<asset>.import` contains important import configuration and should be committed. The generated 153 PNG `.import` sidecars and 8 script `.uid` identity files are therefore retained in this checkpoint; the 21 MiB `.godot/` cache is not committed.

## Evidence vocabulary

- **CONFIRMED / HEADLESS:** passed an executable test in this workspace; exact evidence is listed.
- **EXPERIMENTAL / UNKNOWN:** not demonstrated, or the current build prevents a conclusive result.
- **NOT AVAILABLE HERE:** the build/workspace lacks the required display or human-interaction capability.

A passing A–E test does not replace visual review F. Tests establish resource loading, timing and scene/runtime processing, not animation quality or art approval.

## Godot headless smoke test

Run:

```sh
tests/godot_headless_smoke.sh
```

The script verifies the pinned version; runs the editor/import/script scan; executes `tests/godot_headless_smoke.gd`; boots the default game scene for 12 frames; and boots `scenes/animation_review.tscn` for 60 frames. It fails on script parse errors and engine/resource errors, except for the build's known fontconfig-disabled diagnostic. It does not modify or regenerate animation artwork.

### Animation tests A–F

- **A — integrity: CONFIRMED.** Four existing 12-PNG sequences (front, back, left review candidate 05, right review candidate 02) exist, decode, are RGBA, have consistent per-sequence dimensions of `384×544`, and load as `Texture2D`.
- **B — SpriteFrames: CONFIRMED.** The actual `animation_review.tscn` is instantiated; its existing script builds all four named looping `SpriteFrames`, 12 textured frames each.
- **C — AnimatedSprite2D: CONFIRMED.** The actual `AnimatedSprite2D` is processed in the headless scene and advances from frame 0 in each of the four directions.
- **D — timing: CONFIRMED.** Godot read-back for each direction matches `[0.27, 0.25, 0.25, 0.25, 0.27, 0.30, 0.30, 0.30, 0.25, 0.25, 0.25, 0.25]` seconds; the cycle totals `3.19` seconds at base speed `1.0`. A timed 0.36-second process interval advances each direction from its first frame. This checks engine timing, not perceived smoothness.
- **E — integration: CONFIRMED.** The instantiated main scene creates its own `AnimatedSprite2D` and integrates the same four 12-frame `SpriteFrames`; the main gameplay scene also boots for a bounded 12-frame run without script/resource errors.
- **F — visual: NOT AVAILABLE HERE.** No X11/Wayland display is compiled in, no display environment is set, and no human can inspect the animation in this workspace. Do not infer jitter, pivot, scale, halo, shadow, continuity, or visual quality from A–E.

Additional measured smoke evidence:

- The front `frame_001.png` vs `frame_002.png` comparison found `2,449 / 208,896` pixels different. This proves only that the decoded images differ, not that motion is good.
- `SpriteFrames` serialized to `user://godot_smoke_spriteframes.tres` and reloaded with 12 front frames.
- `godot --headless --editor --path . --quit`, the GDScript smoke suite, the default main-scene boot, and the animation-review-scene boot all exited successfully after the fix.

## Capability matrix

| Capability | Evidence / test | Result |
|---|---|---|
| Import project | Headless editor scan/import; no parse/resource error | **CONFIRMED** |
| Load PNG | Image decode, RGBA format, size and `Texture2D` checks on 48 frames | **CONFIRMED** |
| Create `SpriteFrames` | Runtime resource from `animation_review.tscn`, four animations × 12 frames | **CONFIRMED** |
| Reproduce `AnimatedSprite2D` | Frame advanced in each animation under SceneTree processing | **CONFIRMED** |
| Per-frame timing | All 48 duration values match and each 3.19 s cycle is measured | **CONFIRMED** |
| Load/instantiate scenes | Main and review `PackedScene`s instantiate; both direct boots pass | **CONFIRMED** |
| Integrate animation into main | `main.gd` creates 4 × 12 frame `SpriteFrames` in the instantiated scene | **CONFIRMED** |
| Run the game | Default main scene ran for 12 headless frames without script/resource errors | **CONFIRMED for bounded startup only**; gameplay/input/visual behavior untested |
| Save/export a Godot resource | `SpriteFrames` saved as `.tres` and reloaded | **CONFIRMED** (resource serialization only; standalone project export not tested) |
| Compare source frames | Pixel-difference count produced for two decoded PNGs | **CONFIRMED** as a numeric comparison; not an art-quality test |
| Render a readable viewport frame | `DisplayServer.get_name()` is `headless`; adapter name is empty; root viewport read returned a null dummy texture | **NOT AVAILABLE in this build** |
| Capture a screenshot | No nonempty PNG produced; `--rendering-driver opengl3` is rejected, with only the dummy driver available | **NOT AVAILABLE in this build** |
| Inspect the GUI editor visually | GUI display backend and human display absent | **NOT AVAILABLE HERE** |

A successful bounded boot is not proof of a full playable run. The project-owner's existing human gameplay observation remains separate evidence.

## Animation scope and rejection status

The existing architecture remains authoritative: individual PNG frames, runtime `SpriteFrames`, `AnimatedSprite2D`, and the separate `scenes/animation_review.tscn`. This checkpoint adds only validation infrastructure and a Godot helper-name correction; it does not regenerate or change any animation image.

The archived SpriteDNA walk 01 remains rejected. Its source frames were made by deforming the flattened image, alpha bounds varied, and the old GIF had undefined disposal. A clean PNG/APNG round-trip, a Godot resource load, or the pixel-difference test cannot fix/approve that walk or establish coherent movement. Do not regenerate it blindly or use it as gameplay animation.

## Recovery files

- Source rebuild: `tools/godot/build_headless.sh`.
- Version-check / Release-restore / source-rebuild bootstrap: `tools/godot/bootstrap.sh`.
- Project smoke test: `tests/godot_headless_smoke.sh` and `tests/godot_headless_smoke.gd`.
- Current structured state: `docs/environment/current_state.md`.
