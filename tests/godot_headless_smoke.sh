#!/usr/bin/env bash
set -Eeuo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
GODOT_BIN="${GODOT_BIN:-$(command -v godot || true)}"
EXPECTED_VERSION="4.7.2.stable.custom_build"

if [[ -z "$GODOT_BIN" || ! -x "$GODOT_BIN" ]]; then
  echo "ERROR: Godot executable not found. Set GODOT_BIN or run tools/godot/bootstrap.sh." >&2
  exit 127
fi

version="$($GODOT_BIN --version 2>&1 | tail -n 1)"
if [[ "$version" != "$EXPECTED_VERSION" ]]; then
  echo "ERROR: expected Godot $EXPECTED_VERSION, found '$version' at $GODOT_BIN" >&2
  exit 2
fi

work="$(mktemp -d)"
trap 'rm -rf "$work"' EXIT

fail_on_engine_errors() {
  local log="$1"
  local label="$2"
  local findings
  findings="$(grep -E 'SCRIPT ERROR:|Parse Error:|Failed to load script|ERROR:' "$log" | grep -v 'Godot was compiled without fontconfig, system font support is disabled' || true)"
  if [[ -n "$findings" ]]; then
    printf '%s\n' "$findings"
    echo "ERROR: Godot reported an engine/script/resource error during $label" >&2
    return 1
  fi
}

run_and_check() {
  local label="$1"
  shift
  local log="$work/${label//[^a-zA-Z0-9_-]/_}.log"
  echo "[RUN] $label"
  if ! "$GODOT_BIN" "$@" >"$log" 2>&1; then
    cat "$log"
    echo "ERROR: $label exited unsuccessfully" >&2
    return 1
  fi
  if ! fail_on_engine_errors "$log" "$label"; then
    cat "$log"
    return 1
  fi
  grep -E 'GODOT_HEADLESS_SMOKE:|GODOT_EVASION_EXPERIMENT:|GODOT_PROCEDURAL_FIRST_LEVEL:|\[MEASURED\]|\[CONFIRMED\]|\[FACT\]|\[UNKNOWN\]' "$log" || true
  echo "[PASS] $label"
}

run_and_check "project import and editor script scan" --headless --editor --path "$ROOT" --quit

capture="$work/headless_capture.png"
GODOT_SMOKE_CAPTURE="$capture" run_and_check "resource and animation smoke suite" --headless --path "$ROOT" --script res://tests/godot_headless_smoke.gd
run_and_check "tactical evasion experiment" --headless --path "$ROOT" --script res://tests/godot_evasion_experiment.gd
run_and_check "procedural first-level experiment" --headless --path "$ROOT" --script res://tests/godot_procedural_first_level.gd

run_and_check "default gameplay scene" --headless --path "$ROOT" --quit-after 12
run_and_check "animation_review scene" --headless --path "$ROOT" --quit-after 60 res://scenes/animation_review.tscn

if [[ -s "$capture" ]]; then
  echo "[MEASURED] capture artifact: $capture ($(stat -c '%s bytes' "$capture"))"
else
  echo "[UNKNOWN] no screenshot artifact was produced by the headless renderer"
fi

echo "GODOT_HEADLESS_SMOKE: PASS ($version)"
