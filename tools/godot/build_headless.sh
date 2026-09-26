#!/usr/bin/env bash
set -Eeuo pipefail

# Reproducible source build for the environment-tested Godot 4.7.2 CLI/editor.
# The resulting editor binary supports --headless but intentionally has no GUI
# display backend or system-font integration.
readonly SOURCE_COMMIT="ed1daf0bf001b61586d9930840f2f1394092c079"
readonly SOURCE_SHA256="e607e9985e1c201bc9cdc1aec8a120f0c3f53b9603f1f828e2b748534a2471ef"
readonly SCONS_VERSION="4.11.1"
readonly GODOT_VERSION="4.7.2.stable.custom_build"
readonly SCONS_FLAGS=(
  platform=linuxbsd
  target=editor
  arch=x86_64
  optimize=none
  debug_symbols=no
  use_static_cpp=no
  use_sowrap=no
  x11=no
  wayland=no
  fontconfig=no
  alsa=no
  pulseaudio=no
  dbus=no
  speechd=no
  udev=no
  sdl=no
  accesskit=no
)
COMPILER_FLAGS=()
if [[ -n "${GODOT_CC:-}" && -n "${GODOT_CXX:-}" ]]; then
  COMPILER_FLAGS=("CC=$GODOT_CC" "CXX=$GODOT_CXX")
fi
BUILD_CC="${GODOT_CC:-gcc}"
BUILD_CXX="${GODOT_CXX:-g++}"

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
INSTALL_DIR="${GODOT_INSTALL_DIR:-/usr/local/bin}"
BUILD_JOBS="${GODOT_BUILD_JOBS:-2}"
BUILD_ROOT="$(mktemp -d "${TMPDIR:-/tmp}/come-to-me-godot-build.XXXXXX")"
START_SECONDS=$SECONDS
cleanup() { rm -rf "$BUILD_ROOT"; }
trap cleanup EXIT

for command_name in python3 "$BUILD_CC" "$BUILD_CXX" tar sha256sum; do
  command -v "$command_name" >/dev/null || { echo "Missing build dependency: $command_name" >&2; exit 1; }
done
[[ "$(uname -m)" == "x86_64" ]] || { echo "This pinned build is for x86_64 only." >&2; exit 1; }

python3 -m venv "$BUILD_ROOT/venv"
"$BUILD_ROOT/venv/bin/pip" install --disable-pip-version-check "scons==$SCONS_VERSION"

python3 - "$BUILD_ROOT/godot-source.tar.gz" "$SOURCE_COMMIT" <<'PY'
import hashlib
import sys
import urllib.request
from pathlib import Path

destination = Path(sys.argv[1])
commit = sys.argv[2]
url = f"https://codeload.github.com/godotengine/godot/tar.gz/{commit}"
request = urllib.request.Request(url, headers={"User-Agent": "come-to-me-godot-bootstrap/1"})
digest = hashlib.sha256()
size = 0
with urllib.request.urlopen(request, timeout=60) as response, destination.open("wb") as output:
    while True:
        block = response.read(1024 * 1024)
        if not block:
            break
        output.write(block)
        digest.update(block)
        size += len(block)
expected = "e607e9985e1c201bc9cdc1aec8a120f0c3f53b9603f1f828e2b748534a2471ef"
actual = digest.hexdigest()
if actual != expected:
    destination.unlink(missing_ok=True)
    raise SystemExit(f"Godot source checksum mismatch: expected {expected}, got {actual}")
print(f"Verified Godot source archive: {size} bytes, SHA-256 {actual}")
PY

mkdir "$BUILD_ROOT/source"
tar -xzf "$BUILD_ROOT/godot-source.tar.gz" -C "$BUILD_ROOT/source" --strip-components=1

# The upstream LinuxBSD detector requires pkg-config even in this configuration.
# All optional system libraries and display backends are disabled below, so this
# shim only answers the detector's version probe and reports no system packages.
mkdir "$BUILD_ROOT/build-tools"
cat >"$BUILD_ROOT/build-tools/pkg-config" <<'PKGCONFIG'
#!/bin/sh
case "$1" in
  --version) echo '0.29.2'; exit 0 ;;
  --exists|--modversion) exit 1 ;;
  --cflags|--libs) exit 0 ;;
  *) exit 0 ;;
esac
PKGCONFIG
chmod +x "$BUILD_ROOT/build-tools/pkg-config"

PATH="$BUILD_ROOT/build-tools:$PATH" "$BUILD_ROOT/venv/bin/scons" \
  -C "$BUILD_ROOT/source" -j"$BUILD_JOBS" "${SCONS_FLAGS[@]}" "${COMPILER_FLAGS[@]}"

BUILT_BINARY="$BUILD_ROOT/source/bin/godot.linuxbsd.editor.x86_64"
[[ -x "$BUILT_BINARY" ]] || { echo "SCons completed without the expected executable." >&2; exit 1; }
actual_version="$("$BUILT_BINARY" --version 2>&1 | tail -n 1)"
[[ "$actual_version" == "$GODOT_VERSION" ]] || {
  echo "Unexpected build version: $actual_version" >&2
  exit 1
}

mkdir -p "$INSTALL_DIR"
if [[ -w "$INSTALL_DIR" ]]; then
  install -m 0755 "$BUILT_BINARY" "$INSTALL_DIR/godot"
elif command -v sudo >/dev/null && sudo -n true 2>/dev/null; then
  sudo install -m 0755 "$BUILT_BINARY" "$INSTALL_DIR/godot"
else
  echo "Cannot write to $INSTALL_DIR; set GODOT_INSTALL_DIR to a writable directory." >&2
  exit 1
fi

installed="$INSTALL_DIR/godot"
installed_sha="$(sha256sum "$installed" | awk '{print $1}')"
installed_size="$(stat -c '%s' "$installed")"
source_archive_size="$(stat -c '%s' "$BUILD_ROOT/godot-source.tar.gz")"
BUILD_ELAPSED=$((SECONDS - START_SECONDS))
printf 'Installed: %s\nVersion: %s\nBytes: %s\nSHA-256: %s\n' \
  "$installed" "$actual_version" "$installed_size" "$installed_sha"

if [[ -n "${GODOT_ARTIFACT_DIR:-}" ]]; then
  mkdir -p "$GODOT_ARTIFACT_DIR"
  install -m 0755 "$installed" "$GODOT_ARTIFACT_DIR/godot"
  cat >"$GODOT_ARTIFACT_DIR/manifest.txt" <<MANIFEST
Godot version: $actual_version
Source tag: 4.7.2-stable
Source commit: $SOURCE_COMMIT
Source archive SHA-256: $SOURCE_SHA256
Architecture: x86_64
Platform: linuxbsd
Build target: editor; headless-capable, no X11/Wayland GUI backends
Compiler: $("$BUILD_CXX" --version | head -n 1)
SCons flags: ${SCONS_FLAGS[*]} ${COMPILER_FLAGS[*]}
Build jobs: -j$BUILD_JOBS
Source archive bytes: $source_archive_size
Observed build + install elapsed seconds: $BUILD_ELAPSED
Executable bytes: $installed_size
Executable SHA-256: $installed_sha
MANIFEST
  sha256sum "$GODOT_ARTIFACT_DIR/godot" >"$GODOT_ARTIFACT_DIR/SHA256SUMS"
  echo "Preserved build artifact in $GODOT_ARTIFACT_DIR"
fi

echo "Build + install elapsed seconds: $BUILD_ELAPSED"
"$installed" --version
