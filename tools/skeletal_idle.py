#!/usr/bin/env python3
"""Generate a small, texture-locked breathing loop from one RGBA sprite.

The body is not re-generated per frame. A 2D landmark skeleton determines
small joint displacements; Gaussian-weighted inverse skinning moves the original
pixels with nearest-neighbour sampling. Boot/ground rows and the crown remain
fixed, and shoulder/elbow/wrist offsets are derived from rotations with fixed
bone lengths. This is a prototype tool, not an artistic approval.

Usage:
  python tools/skeletal_idle.py input.png output_directory
  python tools/skeletal_idle.py input.png output_directory --profile left
  python tools/skeletal_idle.py input.png output_directory --profile right
"""
from __future__ import annotations

import argparse
import math
import struct
import sys
import zlib
from array import array
from pathlib import Path

from validate_sprite_sequence import changed_pixels, measure, read_png_rgba8

# Eight control keys describe one small inhale/exhale. Twelve rendered cels are
# sampled between them with periodic Catmull-Rom interpolation; amplitude is
# clamped to the key range so extra fluidity cannot add extra spread.
CHEST_KEYS = (0.00, 0.70, 0.78, 0.90, 1.00, 0.78, 0.50, 0.18)
SHOULDER_KEYS = (0.00, 0.04, 0.14, 0.35, 0.62, 0.88, 0.85, 0.48)
ARM_KEYS = (0.00, 0.02, 0.10, 0.26, 0.50, 0.83, 0.88, 0.55)
FRAME_COUNT = 12
FRAME_DURATIONS_CS = (27, 25, 25, 25, 27, 30, 30, 30, 25, 25, 25, 25)

# Screen-space rigs for the approved front/back and current left-facing master.
# Lower-body/feet remain anchors; the left profile has separate asymmetric
# shoulder, elbow and wrist landmarks because its projected silhouette differs.
PROFILES = {
    "front": {
        "CENTER_X": 192.0, "HEAD": (192.0, 203.0), "NECK": (192.0, 241.0),
        "SHOULDER_L": (148.0, 258.0), "SHOULDER_R": (236.0, 258.0),
        "ELBOW_L": (128.0, 314.0), "ELBOW_R": (256.0, 314.0),
        "WRIST_L": (126.0, 358.0), "WRIST_R": (258.0, 358.0),
        "CHEST_CENTER": (192.0, 302.0), "WAIST": (192.0, 370.0), "HIP": (192.0, 384.0),
    },
    "left": {
        "CENTER_X": 192.0, "HEAD": (188.0, 203.0), "NECK": (194.0, 241.0),
        "SHOULDER_L": (161.0, 258.0), "SHOULDER_R": (226.0, 258.0),
        "ELBOW_L": (143.0, 312.0), "ELBOW_R": (246.0, 312.0),
        "WRIST_L": (141.0, 354.0), "WRIST_R": (237.0, 356.0),
        "CHEST_CENTER": (192.0, 302.0), "WAIST": (192.0, 370.0), "HIP": (192.0, 384.0),
    },
    "right": {
        "CENTER_X": 192.0, "HEAD": (196.0, 203.0), "NECK": (190.0, 241.0),
        "SHOULDER_L": (158.0, 258.0), "SHOULDER_R": (223.0, 258.0),
        "ELBOW_L": (138.0, 312.0), "ELBOW_R": (241.0, 312.0),
        "WRIST_L": (147.0, 356.0), "WRIST_R": (243.0, 354.0),
        "CHEST_CENTER": (192.0, 302.0), "WAIST": (192.0, 370.0), "HIP": (192.0, 384.0),
    },
}
CENTER_X = PROFILES["front"]["CENTER_X"]
HEAD = PROFILES["front"]["HEAD"]
NECK = PROFILES["front"]["NECK"]
SHOULDER_L = PROFILES["front"]["SHOULDER_L"]
SHOULDER_R = PROFILES["front"]["SHOULDER_R"]
ELBOW_L = PROFILES["front"]["ELBOW_L"]
ELBOW_R = PROFILES["front"]["ELBOW_R"]
WRIST_L = PROFILES["front"]["WRIST_L"]
WRIST_R = PROFILES["front"]["WRIST_R"]
CHEST_CENTER = PROFILES["front"]["CHEST_CENTER"]
WAIST = PROFILES["front"]["WAIST"]
HIP = PROFILES["front"]["HIP"]


def smoothstep01(t: float) -> float:
    t = max(0.0, min(1.0, t))
    return t * t * (3.0 - 2.0 * t)


def periodic_catmull_rom(values: tuple[float, ...], t: float) -> float:
    """Smooth periodic interpolation, bounded to the two adjacent key values."""
    count = len(values)
    i = math.floor(t) % count
    u = t - math.floor(t)
    p0, p1 = values[(i - 1) % count], values[i]
    p2, p3 = values[(i + 1) % count], values[(i + 2) % count]
    value = 0.5 * (
        2.0 * p1
        + (-p0 + p2) * u
        + (2.0 * p0 - 5.0 * p1 + 4.0 * p2 - p3) * u * u
        + (-p0 + 3.0 * p1 - 3.0 * p2 + p3) * u * u * u
    )
    return max(min(p1, p2), min(max(p1, p2), value))


def upper_body_falloff(y: float) -> float:
    """Protect the head crown and lower-body contact while easing the torso."""
    if y <= 226.0 or y >= 386.0:
        return 0.0
    if y < 250.0:
        return smoothstep01((y - 226.0) / 24.0)
    if y <= 360.0:
        return 1.0
    return 1.0 - smoothstep01((y - 360.0) / 26.0)


def rotate_vector(dx: float, dy: float, angle: float) -> tuple[float, float]:
    c, s = math.cos(angle), math.sin(angle)
    return c * dx - s * dy, s * dx + c * dy


def node_offsets(chest: float, shoulder: float, arm: float) -> list[tuple[float, float, float, float, float]]:
    """Return (x,y,sigma,dx,dy) controls; arm bones retain their lengths."""

    # Shoulder girdle lifts and widens only a little. The arm segments rotate
    # around their joints; segment lengths are preserved by the rigid rotations.
    s_l = (SHOULDER_L[0] - 0.8 * shoulder, SHOULDER_L[1] - 0.9 * shoulder)
    s_r = (SHOULDER_R[0] + 0.8 * shoulder, SHOULDER_R[1] - 0.9 * shoulder)
    upper_angle = math.radians(1.25 * arm)
    fore_angle = math.radians(0.30 * max(0.0, arm - 0.12))

    upper_l = (ELBOW_L[0] - SHOULDER_L[0], ELBOW_L[1] - SHOULDER_L[1])
    upper_r = (ELBOW_R[0] - SHOULDER_R[0], ELBOW_R[1] - SHOULDER_R[1])
    elbow_l_vec = rotate_vector(*upper_l, upper_angle)
    elbow_r_vec = rotate_vector(*upper_r, -upper_angle)
    e_l = (s_l[0] + elbow_l_vec[0], s_l[1] + elbow_l_vec[1])
    e_r = (s_r[0] + elbow_r_vec[0], s_r[1] + elbow_r_vec[1])

    fore_l = (WRIST_L[0] - ELBOW_L[0], WRIST_L[1] - ELBOW_L[1])
    fore_r = (WRIST_R[0] - ELBOW_R[0], WRIST_R[1] - ELBOW_R[1])
    wrist_l_vec = rotate_vector(*fore_l, fore_angle)
    wrist_r_vec = rotate_vector(*fore_r, -fore_angle)
    w_l = (e_l[0] + wrist_l_vec[0], e_l[1] + wrist_l_vec[1])
    w_r = (e_r[0] + wrist_r_vec[0], e_r[1] + wrist_r_vec[1])

    # Chest rises/expands first; neck and jacket hem follow at much lower gain.
    chest_dy = -1.25 * chest
    neck_dy = -0.12 * chest
    waist_dy = -0.18 * chest
    controls = [
        (HEAD[0], HEAD[1], 24.0, 0.0, 0.0),
        (NECK[0], NECK[1], 23.0, 0.0, neck_dy),
        (s_l[0], s_l[1], 26.0, s_l[0] - SHOULDER_L[0], s_l[1] - SHOULDER_L[1]),
        (s_r[0], s_r[1], 26.0, s_r[0] - SHOULDER_R[0], s_r[1] - SHOULDER_R[1]),
        (e_l[0], e_l[1], 24.0, e_l[0] - ELBOW_L[0], e_l[1] - ELBOW_L[1]),
        (e_r[0], e_r[1], 24.0, e_r[0] - ELBOW_R[0], e_r[1] - ELBOW_R[1]),
        (w_l[0], w_l[1], 21.0, w_l[0] - WRIST_L[0], w_l[1] - WRIST_L[1]),
        (w_r[0], w_r[1], 21.0, w_r[0] - WRIST_R[0], w_r[1] - WRIST_R[1]),
        (CHEST_CENTER[0], CHEST_CENTER[1], 37.0, 0.0, chest_dy),
        (WAIST[0], WAIST[1], 29.0, 0.0, waist_dy),
        (HIP[0], HIP[1], 25.0, 0.0, 0.0),
    ]
    return controls


def build_field(width: int, height: int, controls: list[tuple[float, float, float, float, float]], chest_phase: float, silhouette_x: tuple[int, int]):
    dx_field = array("f", [0.0]) * (width * height)
    dy_field = array("f", [0.0]) * (width * height)
    gaussians = []
    for cx, cy, sigma, dx, dy in controls:
        inv = 1.0 / (2.0 * sigma * sigma)
        gaussians.append((cx, cy, inv, dx, dy))

    for y in range(height):
        falloff = upper_body_falloff(float(y))
        if falloff == 0.0:
            continue
        row = y * width
        for x in range(width):
            sum_w = sx = sy = 0.0
            for cx, cy, inv, ndx, ndy in gaussians:
                ox, oy = x - cx, y - cy
                weight = math.exp(-(ox * ox + oy * oy) * inv)
                sum_w += weight
                sx += weight * ndx
                sy += weight * ndy
            if sum_w > 1.0e-12:
                dx = sx / sum_w
                dy = sy / sum_w
                # Smooth ribcage expansion, strongest at the chest and fading
                # toward neck and waist. It changes neither overall scale nor root.
                tx = (x - CENTER_X) / 47.0
                ty = (y - CHEST_CENTER[1]) / 49.0
                rib = math.exp(-0.5 * (tx * tx + ty * ty)) * chest_phase
                dx += (1.05 if x >= CENTER_X else -1.05) * rib
                dy += -0.42 * rib
                # Pin the extreme left/right silhouette envelope. Breath may
                # reshape the chest internally, but the sprite never scales or
                # becomes a different overall width.
                half_extent = CENTER_X - silhouette_x[0] if x < CENTER_X else silhouette_x[1] - CENTER_X
                edge_t = max(0.0, min(1.0, (half_extent - abs(x - CENTER_X)) / 12.0))
                edge_guard = smoothstep01(edge_t)
                dx_field[row + x] = max(-1.2, min(1.2, dx * falloff * edge_guard))
                dy_field[row + x] = max(-1.6, min(1.2, dy * falloff))
    return dx_field, dy_field


def warp_rgba_nearest(rgba: bytes, width: int, height: int, dx_field: array, dy_field: array) -> bytes:
    output = bytearray(width * height * 4)
    for y in range(height):
        for x in range(width):
            sx, sy = float(x), float(y)
            # Invert the smooth deformation field. Small bounded displacements
            # converge rapidly and preserve the source pixel texture.
            for _ in range(4):
                ix = min(width - 1, max(0, int(round(sx))))
                iy = min(height - 1, max(0, int(round(sy))))
                field_i = iy * width + ix
                sx = x - dx_field[field_i]
                sy = y - dy_field[field_i]
            src_x = min(width - 1, max(0, int(round(sx))))
            src_y = min(height - 1, max(0, int(round(sy))))
            src_i = (src_y * width + src_x) * 4
            dst_i = (y * width + x) * 4
            output[dst_i : dst_i + 4] = rgba[src_i : src_i + 4]
    return bytes(output)


def png_chunk(kind: bytes, payload: bytes) -> bytes:
    return struct.pack(">I", len(payload)) + kind + payload + struct.pack(">I", zlib.crc32(kind + payload) & 0xFFFFFFFF)


def write_png_rgba8(path: Path, width: int, height: int, rgba: bytes) -> None:
    rows = bytearray()
    stride = width * 4
    for y in range(height):
        rows.append(0)  # PNG filter: None
        rows.extend(rgba[y * stride : (y + 1) * stride])
    header = struct.pack(">IIBBBBB", width, height, 8, 6, 0, 0, 0)
    data = bytearray(b"\x89PNG\r\n\x1a\n")
    data.extend(png_chunk(b"IHDR", header))
    data.extend(png_chunk(b"sRGB", b"\x00"))
    data.extend(png_chunk(b"IDAT", zlib.compress(bytes(rows), level=9)))
    data.extend(png_chunk(b"IEND", b""))
    path.write_bytes(data)


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("input", type=Path, help="one canonical RGBA8 PNG pose")
    parser.add_argument("output", type=Path, help="directory for twelve review-only frames")
    parser.add_argument("--profile", choices=PROFILES, default="front", help="screen-space skeleton rig (front, left or right)")
    args = parser.parse_args()
    global CENTER_X, HEAD, NECK, SHOULDER_L, SHOULDER_R, ELBOW_L, ELBOW_R, WRIST_L, WRIST_R, CHEST_CENTER, WAIST, HIP
    for landmark, value in PROFILES[args.profile].items():
        globals()[landmark] = value
    width, height, rgba = read_png_rgba8(args.input)
    if (width, height) != (384, 544):
        parser.error(f"canonical sprite must be 384x544, got {width}x{height}")

    source_box = measure(args.input).bbox
    if source_box is None:
        parser.error("canonical sprite is fully transparent")
    silhouette_x = (source_box[0], source_box[0] + source_box[2] - 1)

    args.output.mkdir(parents=True, exist_ok=True)
    sampled_phases = []
    key_count = len(CHEST_KEYS)
    for i in range(FRAME_COUNT):
        t = i * key_count / FRAME_COUNT
        sampled_phases.append((
            periodic_catmull_rom(CHEST_KEYS, t),
            periodic_catmull_rom(SHOULDER_KEYS, t),
            periodic_catmull_rom(ARM_KEYS, t),
        ))

    rows = []
    generated: list[Path] = []
    for i, (phase, shoulder_phase, arm_phase) in enumerate(sampled_phases):
        controls = node_offsets(phase, shoulder_phase, arm_phase)
        dx, dy = build_field(width, height, controls, phase, silhouette_x)
        frame = warp_rgba_nearest(rgba, width, height, dx, dy)
        out = args.output / f"frame_{i + 1:03d}.png"
        write_png_rgba8(out, width, height, frame)
        generated.append(out)
        max_dx = max(abs(v) for v in dx)
        max_dy = max(abs(v) for v in dy)
        rows.append((i + 1, phase, shoulder_phase, arm_phase, max_dx, max_dy))
        print(f"{out}: chest={phase:.2f}, shoulder={shoulder_phase:.2f}, arm={arm_phase:.2f}, max|dx|={max_dx:.2f}, max|dy|={max_dy:.2f}")

    measured = [measure(path) for path in generated]
    stride = width * 4
    top_bytes = 226 * stride
    lower_start = 386 * stride
    for index, item in enumerate(measured):
        if item.bbox != source_box:
            raise RuntimeError(f"{item.path.name}: sprite bounds drifted from canonical pose: {item.bbox} != {source_box}")
        if item.rgba[:top_bytes] != rgba[:top_bytes]:
            raise RuntimeError(f"{item.path.name}: crown/head anchor changed")
        if item.rgba[lower_start:] != rgba[lower_start:]:
            raise RuntimeError(f"{item.path.name}: planted lower body changed")
        if index and changed_pixels(measured[index - 1].rgba, item.rgba) == 0:
            raise RuntimeError(f"{item.path.name}: exact duplicate frame")
    if changed_pixels(measured[-1].rgba, measured[0].rgba) == 0:
        raise RuntimeError("Loop end is an exact duplicate of frame 001")

    meta = [
        f"# Skeletal breathing review — {args.profile} profile",
        "",
        f"Canonical source: `{args.input}`",
        f"Rig profile: `{args.profile}` screen-space landmarks.",
        f"Method: 8 bounded control keys interpolated periodically into {FRAME_COUNT} cels with Catmull-Rom; fixed-root 2D landmarks, constant-length shoulder→elbow→wrist rotations, Gaussian-weighted inverse displacement, nearest-neighbour pixel sampling.",
        f"Preview timing: {FRAME_DURATIONS_CS} centiseconds (total {sum(FRAME_DURATIONS_CS)/100:.2f}s).",
        "Bone rule: p' = s' + R(theta)(p-s), so each shoulder→elbow and elbow→wrist length is invariant under its rotation.",
        "Skinning field: w_j(q)=exp(-||q-j||²/(2σ_j²)); D(q)=Σ(w_jΔ_j)/Σw_j + D_rib(q). For each output pixel p, solve q=p-D(q) by four fixed-point iterations, then sample the nearest source pixel.",
        "Rib expansion is a small Gaussian around the chest center, scaled by the chest phase; joint phase curves make the chest lead, shoulders lag, and arms follow.",
        "Global scale is exactly 1.0. The outer silhouette envelope is pinned horizontally; crown (`y<=226`) and lower body/feet (`y>=386`) are byte-identical to the source in all frames. The script asserts unchanged alpha bounds and no exact duplicate frames. This is a review prototype, not an artistic approval.",
        "",
        "| Frame | Chest phase | Shoulder phase | Arm phase | Max horizontal displacement | Max vertical displacement |",
        "|---:|---:|---:|---:|---:|---:|",
    ]
    for row in rows:
        meta.append(f"| {row[0]:03d} | {row[1]:.2f} | {row[2]:.2f} | {row[3]:.2f} | {row[4]:.2f}px | {row[5]:.2f}px |")
    (args.output.parent / "SKELETON_MODEL.md").write_text("\n".join(meta) + "\n", encoding="utf-8")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
