#!/usr/bin/env bash
set -Eeuo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
EXPECTED_VERSION="4.7.2.stable.custom_build"
RELEASE_TAG="godot-headless-4.7.2-custom-linux-x86_64"
RELEASE_ASSET="godot-headless-4.7.2-custom-linux-x86_64.tar.gz"
RELEASE_ASSET_SHA="${RELEASE_ASSET}.sha256"
# These hashes pin the verified cached binary/archive, not arbitrary rebuilds.
EXPECTED_RELEASE_SHA256="60f5d7032e98ec9b87aa3e3debf4da78eaa879c6c0fd6b43755673f649edfb65"
EXPECTED_BINARY_SHA256="db4cf162429ca0352be3b0a03125e111451c4130b9a078885ba68cf7fca23564"
ACTIONS_ARTIFACT_NAME="godot-headless-4.7.2-linux-x86_64"
WORKFLOW_FILE="godot-headless-artifact.yml"
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

restore_archive() {
  local archive="$1"
  local checksum_file="$2"
  local expected_archive_sha actual_archive_sha actual_binary_sha
  local unpack_dir="$3"

  expected_archive_sha="$(awk '{print $1}' "$checksum_file" 2>/dev/null || true)"
  actual_archive_sha="$(sha256sum "$archive" 2>/dev/null | awk '{print $1}' || true)"
  [[ -s "$archive" \
      && "$expected_archive_sha" == "$EXPECTED_RELEASE_SHA256" \
      && "$actual_archive_sha" == "$EXPECTED_RELEASE_SHA256" ]] || return 1
  tar -tzf "$archive" >/dev/null 2>&1 || return 1
  mkdir -p "$unpack_dir"
  tar -xzf "$archive" -C "$unpack_dir"
  [[ -x "$unpack_dir/godot" && -f "$unpack_dir/SHA256SUMS" ]] || return 1
  actual_binary_sha="$(sha256sum "$unpack_dir/godot" | awk '{print $1}')"
  [[ "$actual_binary_sha" == "$EXPECTED_BINARY_SHA256" ]] || return 1
  [[ "$("$unpack_dir/godot" --version 2>&1 | tail -n 1)" == "$EXPECTED_VERSION" ]] || return 1
  (cd "$unpack_dir" && sha256sum -c SHA256SUMS)
  install_binary "$unpack_dir/godot"
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

# Prefer the durable draft Release asset. It stays outside normal Git history.
if command -v gh >/dev/null && gh release download "$RELEASE_TAG" \
    --repo edmundo738/come-to-me --dir "$work/release" --pattern "$RELEASE_ASSET*" >/dev/null 2>&1; then
  if restore_archive "$work/release/$RELEASE_ASSET" \
      "$work/release/$RELEASE_ASSET_SHA" "$work/release/unpacked"; then
    restored=true
    echo "Restored Godot from GitHub Release $RELEASE_TAG"
  else
    echo "Release asset did not match the pinned archive/binary hashes; ignoring it." >&2
  fi
fi

# Actions artifacts are a 90-day fallback when the durable Release asset cannot
# be fetched. Query only successful runs of this repository's pinned workflow.
if [[ "$restored" != true ]] && command -v gh >/dev/null; then
  run_id="$(gh run list --repo edmundo738/come-to-me \
    --workflow "$WORKFLOW_FILE" --branch arena/01a0dda9-come-to-me --limit 20 \
    --json databaseId,conclusion \
    --jq '[.[] | select(.conclusion == "success")][0].databaseId // empty' 2>/dev/null || true)"
  if [[ -n "$run_id" ]] && gh run download "$run_id" \
      --repo edmundo738/come-to-me --name "$ACTIONS_ARTIFACT_NAME" \
      --dir "$work/actions" >/dev/null 2>&1; then
    if restore_archive "$work/actions/$RELEASE_ASSET" \
        "$work/actions/$RELEASE_ASSET_SHA" "$work/actions/unpacked"; then
      restored=true
      echo "Restored Godot from successful Actions artifact run $run_id"
    else
      echo "Actions artifact did not match the pinned hashes; ignoring it." >&2
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
