#!/usr/bin/env python3
"""REJECTED SpriteDNA walk experiment 01 — retained for reproducibility only.

The full-image raster warp changed too much of the source texture and produced
unacceptable movement. Do not use this generator for production art. The input
is read-only and the tool refuses to overwrite or write outside review folders.

Usage:
  python experiments/spritedna/walk_01_rejected/generator.py MASTER.png REVIEW_DIRECTORY
"""
from __future__ import annotations

import argparse
import hashlib
import math
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[3]
TOOLS = ROOT / "tools"
sys.path.insert(0, str(TOOLS))
from skeletal_idle import periodic_catmull_rom, warp_rgba_nearest, write_png_rgba8
from validate_sprite_sequence import changed_pixels, measure, read_png_rgba8

FRAME_COUNT = 12
FPS = 12.5
KEY_COUNT = 8
# One cycle has two alternating support steps. The planted foot holds its depth
# for the contact/down portion, then lifts and passes; no root translation is
# baked into the cels.
LEFT_FOOT_Y = (0.0, 0.0, -2.0, -7.0, -12.0, -9.0, -4.0, -1.0)
LEFT_FOOT_X = (0.0, 0.0, 1.0, 4.0, 6.0, 4.0, 1.0, 0.0)
BODY_BOB = (0.0, 0.8, 1.8, 1.0, 0.0, 0.8, 1.8, 1.0)
WEIGHT_SHIFT = (-1.0, -0.5, 0.0, 0.8, 1.0, 0.5, 0.0, -0.8)
ARM_SWING = (0.0, 0.45, 0.8, 0.45, 0.0, -0.45, -0.8, -0.45)

BASE = {
    "head": (192.0, 203.0), "neck": (192.0, 241.0),
    "shoulder_l": (148.0, 258.0), "shoulder_r": (236.0, 258.0),
    "elbow_l": (128.0, 314.0), "elbow_r": (256.0, 314.0),
    "wrist_l": (126.0, 358.0), "wrist_r": (258.0, 358.0),
    "chest": (192.0, 302.0), "waist": (192.0, 370.0),
    "hip_l": (170.0, 393.0), "hip_r": (214.0, 393.0),
    "knee_l": (157.0, 429.0), "knee_r": (227.0, 429.0),
    "ankle_l": (153.0, 459.0), "ankle_r": (231.0, 459.0),
    "toe_l": (142.0, 501.0), "toe_r": (242.0, 501.0),
}


def add(a: tuple[float, float], b: tuple[float, float]) -> tuple[float, float]:
    return a[0] + b[0], a[1] + b[1]


def sub(a: tuple[float, float], b: tuple[float, float]) -> tuple[float, float]:
    return a[0] - b[0], a[1] - b[1]


def rotate(point: tuple[float, float], pivot: tuple[float, float], angle: float) -> tuple[float, float]:
    x, y = sub(point, pivot)
    c, s = math.cos(angle), math.sin(angle)
    return pivot[0] + c * x - s * y, pivot[1] + s * x + c * y


def two_bone_ik(
    root: tuple[float, float], target: tuple[float, float], upper_len: float,
    lower_len: float, bend_side: float,
) -> tuple[float, float]:
    """Solve a 2D knee while retaining the calibrated upper/lower bone lengths."""
    dx, dy = sub(target, root)
    distance = math.hypot(dx, dy)
    distance = max(abs(upper_len - lower_len) + 1e-4, min(upper_len + lower_len - 1e-4, distance))
    ux, uy = dx / distance, dy / distance
    along = (upper_len * upper_len - lower_len * lower_len + distance * distance) / (2.0 * distance)
    height = math.sqrt(max(0.0, upper_len * upper_len - along * along))
    # Perpendicular chosen so the knees keep the subtle outward bend in the
    # approved front master rather than crossing or swapping identities.
    px, py = -uy, ux
    return root[0] + ux * along + px * height * bend_side, root[1] + uy * along + py * height * bend_side


def frame_pose(frame_index: int) -> dict[str, tuple[float, float]]:
    t = frame_index * KEY_COUNT / FRAME_COUNT
    def curve(keys: tuple[float, ...], phase: float = 0.0) -> float:
        return periodic_catmull_rom(keys, t + phase)

    bob = curve(BODY_BOB)
    weight = curve(WEIGHT_SHIFT)
    sway = curve(ARM_SWING)
    foot_l = (curve(LEFT_FOOT_X), curve(LEFT_FOOT_Y))
    foot_r = (-foot_l[0], curve(LEFT_FOOT_Y, 4.0))
    pose: dict[str, tuple[float, float]] = {}

    # Head and face stay recognizable; the upper body only follows the gait
    # with a small, phase-delayed vertical response.
    pose["head"] = add(BASE["head"], (0.0, bob * 0.18))
    pose["neck"] = add(BASE["neck"], (weight * 0.16, bob * 0.45))
    pose["chest"] = add(BASE["chest"], (weight * 0.30, bob * 0.62))
    pose["waist"] = add(BASE["waist"], (weight * 0.65, bob * 0.82))

    for side, sign in (("l", -1.0), ("r", 1.0)):
        shoulder = add(BASE[f"shoulder_{side}"], (weight * 0.30, bob * 0.52))
        elbow = rotate(BASE[f"elbow_{side}"], BASE[f"shoulder_{side}"], sign * sway * 0.105)
        wrist = rotate(BASE[f"wrist_{side}"], BASE[f"elbow_{side}"], sign * sway * 0.075)
        elbow = add(elbow, (weight * 0.25, bob * 0.55))
        wrist = add(wrist, (weight * 0.35, bob * 0.55))
        pose[f"shoulder_{side}"] = shoulder
        pose[f"elbow_{side}"] = elbow
        pose[f"wrist_{side}"] = wrist

        hip = add(BASE[f"hip_{side}"], (weight * 0.60, bob))
        foot = foot_l if side == "l" else foot_r
        ankle = add(BASE[f"ankle_{side}"], (foot[0], foot[1]))
        knee = two_bone_ik(hip, ankle, 38.0, 31.0, 1.0 if side == "l" else -1.0)
        toe = add(BASE[f"toe_{side}"], (foot[0] * 0.8, foot[1]))
        pose[f"hip_{side}"] = hip
        pose[f"knee_{side}"] = knee
        pose[f"ankle_{side}"] = ankle
        pose[f"toe_{side}"] = toe
    return pose


def build_displacement_field(width: int, height: int, pose: dict[str, tuple[float, float]]) -> tuple[list[float], list[float]]:
    radii = {
        "head": 28.0, "neck": 31.0, "chest": 54.0, "waist": 48.0,
        "shoulder_l": 30.0, "shoulder_r": 30.0,
        "elbow_l": 23.0, "elbow_r": 23.0, "wrist_l": 18.0, "wrist_r": 18.0,
        "hip_l": 31.0, "hip_r": 31.0,
        "knee_l": 25.0, "knee_r": 25.0,
        "ankle_l": 22.0, "ankle_r": 22.0,
        "toe_l": 18.0, "toe_r": 18.0,
    }
    controls = []
    for name, source in BASE.items():
        target = pose[name]
        controls.append((source[0], source[1], radii[name], target[0] - source[0], target[1] - source[1]))

    dx_field = [0.0] * (width * height)
    dy_field = [0.0] * (width * height)
    # Gaussian-weighted skinning blends articulated landmarks smoothly across
    # connected clothing; two fixed-point inverse-map passes preserve the
    # original texture with nearest-neighbour sampling.
    for y in range(height):
        row = y * width
        for x in range(width):
            sum_w = sx = sy = 0.0
            for cx, cy, radius, ndx, ndy in controls:
                ox, oy = x - cx, y - cy
                weight = math.exp(-(ox * ox + oy * oy) / (2.0 * radius * radius))
                sum_w += weight
                sx += weight * ndx
                sy += weight * ndy
            if sum_w > 1e-12:
                index = row + x
                dx_field[index] = max(-7.0, min(7.0, sx / sum_w))
                dy_field[index] = max(-12.0, min(12.0, sy / sum_w))
    return dx_field, dy_field


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("master", type=Path, help="read-only approved front-facing master PNG")
    parser.add_argument("output", type=Path, help="new review-only directory; existing directories are rejected")
    args = parser.parse_args()
    if args.output.exists():
        parser.error(f"refusing to overwrite existing review data: {args.output}")
    if "review" not in args.output.parts or "animations" in args.output.parts:
        parser.error("walk experiments may write only to a new review/ directory, never production folders")

    source_sha256 = hashlib.sha256(args.master.read_bytes()).hexdigest()
    width, height, rgba = read_png_rgba8(args.master)
    if (width, height) != (384, 544):
        parser.error(f"expected the approved 384x544 canvas; got {width}x{height}")
    source = measure(args.master)
    if source.bbox != (106, 150, 172, 354):
        parser.error(f"master alpha bounds differ from approved front baseline: {source.bbox}")

    frames_dir = args.output / "frames"
    frames_dir.mkdir(parents=True)
    reports = []
    for index in range(FRAME_COUNT):
        pose = frame_pose(index)
        for side in ("l", "r"):
            upper = math.dist(pose[f"hip_{side}"], pose[f"knee_{side}"])
            lower = math.dist(pose[f"knee_{side}"], pose[f"ankle_{side}"])
            if abs(upper - 38.0) > 1e-6 or abs(lower - 31.0) > 1e-6:
                raise RuntimeError(f"frame {index + 1}: {side} leg bone length constraint failed")
        dx, dy = build_displacement_field(width, height, pose)
        frame = warp_rgba_nearest(rgba, width, height, dx, dy)
        target = frames_dir / f"frame_{index + 1:03d}.png"
        write_png_rgba8(target, width, height, frame)
        reports.append((target, max(abs(v) for v in dx), max(abs(v) for v in dy)))

    metrics = [measure(path) for path, _, _ in reports]
    errors = []
    for index, current in enumerate(metrics):
        if (current.width, current.height) != (width, height):
            errors.append(f"{current.path.name}: canvas changed")
        if current.bbox is None:
            errors.append(f"{current.path.name}: fully transparent")
        if index and changed_pixels(metrics[index - 1].rgba, current.rgba) == 0:
            errors.append(f"{current.path.name}: duplicate adjacent frame")
    if changed_pixels(metrics[-1].rgba, metrics[0].rgba) == 0:
        errors.append("loop end duplicates frame 001")
    if errors:
        raise RuntimeError("\n".join(errors))

    if hashlib.sha256(args.master.read_bytes()).hexdigest() != source_sha256:
        raise RuntimeError("read-only master changed during generation")

    rows = [
        "# WALK_N_FRENTE — SpriteDNA experiment 01",
        "",
        "**Status:** review-only prototype. It is not approved production art and has not been tested in Godot.",
        f"**Input (read-only):** `{args.master}`",
        f"**Input SHA-256:** `{source_sha256}`",
        f"**Method:** deterministic 2D landmarks, two-bone IK for knees (38 px + 31 px lengths asserted per frame), opposite-phase arm swing, subtle pelvis/torso weight transfer, Gaussian-weighted inverse deformation and nearest-neighbour sampling.",
        f"**Timing:** {FRAME_COUNT} frames at {FPS:g} FPS ({FRAME_COUNT/FPS:.2f} s per two-step loop).",
        "**No root motion is baked into the PNGs.** The game should move the root between cells separately if/when this candidate is approved.",
        "",
        "| Frame | Alpha bounds | Alpha pixels | Changed pixels from previous | Max displacement (x/y) |",
        "|---:|---|---:|---:|---:|",
    ]
    for index, (metric, (_, max_dx, max_dy)) in enumerate(zip(metrics, reports)):
        diff = "—" if index == 0 else str(changed_pixels(metrics[index - 1].rgba, metric.rgba))
        rows.append(f"| {index + 1:03d} | {metric.bbox} | {metric.alpha_pixels} | {diff} | {max_dx:.2f}px / {max_dy:.2f}px |")
    rows.extend(["", "## Review checklist", "", "- Check contact/down/pass/up at native size.", "- Look for foot sliding, toe clipping, holes, limb warping and arm/leg overlap.", "- Compare loop frame 012 → 001 and inspect the GIF at gameplay scale.", "- Do not integrate this sequence into production or overwrite any approved cycle before human review."])
    (args.output / "VALIDATION.md").write_text("\n".join(rows) + "\n", encoding="utf-8")
    print(f"Generated {FRAME_COUNT} review-only frames in {frames_dir}")
    print(f"Loop: {FRAME_COUNT/FPS:.2f}s at {FPS:g} FPS; source untouched; no production folder written.")
    print("Frame bounds:", [metric.bbox for metric in metrics])
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
