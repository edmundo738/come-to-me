#!/usr/bin/env bash
set -Eeuo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
EXPECTED_VERSION="4.7.2.stable.custom_build"
RELEASE_TAG="godot-headless-4.7.2-custom-linux-x86_64"
RELEASE_ASSET="godot-headless-4.7.2-custom-linux-x86_64.tar.gz"
RELEASE_ASSET_SHA="${RELEASE_ASSET}.sha256"
EXPECTED_RELEASE_SHA256="60f5d7032e98ec9b87aa3e3debf4da78eaa879c6c0fd6b43755673f649edfb65"
EXPECTED_BINARY_SHA256="db4cf162429ca0352be3b0a03125e111451c4130b9a078885ba68cf7fca23564"
INSTALL_DIR="${GODOT_INSTALL_DIR:-/usr/local/bin}"

install_binary() {
  local source="$1"
  mkdir -p "$INSTALL_DIR"
  if [[ -w "$INSTALL_DIR" ]]; then
    install -m 0755 "$source" "$INSTALL_DIR/godot"
  elif command -v sudo >/dev/null && sudo -n true 2>/dev/null; then
    sudo install -m 0755 "$source" "$INSTALL_DIR/godot"
  else
    echo "Cannot write $INSTALL_DIR and non-interactive sudo is unavailable." >&2
    return 1
  fi
}

if [[ "${GODOT_FORCE_RESTORE:-0}" != "1" ]] && command -v godot >/dev/null; then
  installed_version="$(godot --version 2>&1 | tail -n 1)"
  if [[ "$installed_version" == "$EXPECTED_VERSION" ]]; then
    echo "Reusing $EXPECTED_VERSION at $(command -v godot)"
    GODOT_BIN="$(command -v godot)" "$ROOT/tests/godot_headless_smoke.sh"
    exit $?
  fi
  echo "Found Godot $installed_version; the pinned build is $EXPECTED_VERSION."
fi

work="$(mktemp -d "${TMPDIR:-/tmp}/come-to-me-godot-bootstrap.XXXXXX")"
trap 'rm -rf "$work"' EXIT
restored=false

# A draft GitHub Release asset is preferred to avoid a full source rebuild.
# It lives outside normal Git history; if absent or unavailable, build from the
# pinned source commit and verified codeload archive instead.
if command -v gh >/dev/null && gh release download "$RELEASE_TAG" \
    --repo edmundo738/come-to-me --dir "$work" --pattern "$RELEASE_ASSET*" >/dev/null 2>&1; then
  archive="$work/$RELEASE_ASSET"
  expected_archive_sha="$(awk '{print $1}' "$work/$RELEASE_ASSET_SHA" 2>/dev/null || true)"
  actual_archive_sha="$(sha256sum "$archive" 2>/dev/null | awk '{print $1}' || true)"
  if [[ -s "$archive" \
      && "$expected_archive_sha" == "$EXPECTED_RELEASE_SHA256" \
      && "$actual_archive_sha" == "$EXPECTED_RELEASE_SHA256" ]] \
      && tar -tzf "$archive" >/dev/null 2>&1; then
    mkdir "$work/unpacked"
    tar -xzf "$archive" -C "$work/unpacked"
    actual_binary_sha="$(sha256sum "$work/unpacked/godot" 2>/dev/null | awk '{print $1}' || true)"
    if [[ -x "$work/unpacked/godot" \
        && "$("$work/unpacked/godot" --version 2>&1 | tail -n 1)" == "$EXPECTED_VERSION" \
        && "$actual_binary_sha" == "$EXPECTED_BINARY_SHA256" \
        && -f "$work/unpacked/SHA256SUMS" ]]; then
      (cd "$work/unpacked" && sha256sum -c SHA256SUMS)
      install_binary "$work/unpacked/godot"
      restored=true
      echo "Restored Godot from GitHub Release asset $RELEASE_TAG/$RELEASE_ASSET"
    fi
  fi
fi

if [[ "$restored" != true ]]; then
  echo "No verified cached binary was available; rebuilding from pinned source."
  GODOT_INSTALL_DIR="$INSTALL_DIR" "$(dirname "${BASH_SOURCE[0]}")/build_headless.sh"
fi

installed="$INSTALL_DIR/godot"
actual_version="$("$installed" --version 2>&1 | tail -n 1)"
if [[ "$actual_version" != "$EXPECTED_VERSION" ]]; then
  echo "Bootstrap installed unexpected version '$actual_version'." >&2
  exit 2
fi

echo "Verified $installed ($actual_version)"
GODOT_BIN="$installed" "$ROOT/tests/godot_headless_smoke.sh"
