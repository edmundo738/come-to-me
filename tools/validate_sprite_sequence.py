#!/usr/bin/env python3
"""Validate technical consistency of an RGBA8 PNG animation sequence.

Standard-library-only PNG reader. This reports measurable issues; it does not
judge whether an animation looks good. Usage:
  python tools/validate_sprite_sequence.py characters/.../frente
  python tools/validate_sprite_sequence.py characters/.../frente --report report.md
"""
from __future__ import annotations

import argparse
import struct
import sys
import zlib
from dataclasses import dataclass
from pathlib import Path

PNG_SIGNATURE = b"\x89PNG\r\n\x1a\n"


@dataclass
class FrameMetrics:
    path: Path
    width: int
    height: int
    bbox: tuple[int, int, int, int] | None
    alpha_pixels: int
    partial_alpha_pixels: int
    centroid: tuple[float, float] | None
    rgba: bytes


def paeth(a: int, b: int, c: int) -> int:
    p = a + b - c
    pa, pb, pc = abs(p - a), abs(p - b), abs(p - c)
    if pa <= pb and pa <= pc:
        return a
    if pb <= pc:
        return b
    return c


def read_png_rgba8(path: Path) -> tuple[int, int, bytes]:
    data = path.read_bytes()
    if not data.startswith(PNG_SIGNATURE):
        raise ValueError(f"{path.name}: not a PNG")
    pos = len(PNG_SIGNATURE)
    width = height = bit_depth = color_type = None
    idat = bytearray()
    while pos < len(data):
        if pos + 8 > len(data):
            raise ValueError(f"{path.name}: truncated PNG chunk")
        length = struct.unpack_from(">I", data, pos)[0]
        kind = data[pos + 4 : pos + 8]
        start = pos + 8
        end = start + length
        if end + 4 > len(data):
            raise ValueError(f"{path.name}: invalid PNG chunk length")
        chunk = data[start:end]
        if kind == b"IHDR":
            width, height, bit_depth, color_type, compression, filtering, interlace = struct.unpack(
                ">IIBBBBB", chunk
            )
            if compression != 0 or filtering != 0 or interlace != 0:
                raise ValueError(f"{path.name}: unsupported PNG encoding (needs non-interlaced RGBA8)")
        elif kind == b"IDAT":
            idat.extend(chunk)
        elif kind == b"IEND":
            break
        pos = end + 4  # skip CRC
    if width is None or height is None:
        raise ValueError(f"{path.name}: missing IHDR")
    if bit_depth != 8 or color_type != 6:
        raise ValueError(
            f"{path.name}: expected RGBA8 PNG (bit depth 8, color type 6); got depth={bit_depth}, type={color_type}"
        )

    bpp = 4
    stride = width * bpp
    raw = zlib.decompress(idat)
    expected = height * (stride + 1)
    if len(raw) != expected:
        raise ValueError(f"{path.name}: decompressed data length {len(raw)} != expected {expected}")
    pixels = bytearray(height * stride)
    src = 0
    for y in range(height):
        filter_type = raw[src]
        src += 1
        row_start = y * stride
        previous_start = row_start - stride
        for x in range(stride):
            value = raw[src + x]
            left = pixels[row_start + x - bpp] if x >= bpp else 0
            up = pixels[previous_start + x] if y else 0
            upper_left = pixels[previous_start + x - bpp] if y and x >= bpp else 0
            if filter_type == 1:
                value = (value + left) & 255
            elif filter_type == 2:
                value = (value + up) & 255
            elif filter_type == 3:
                value = (value + ((left + up) >> 1)) & 255
            elif filter_type == 4:
                value = (value + paeth(left, up, upper_left)) & 255
            elif filter_type != 0:
                raise ValueError(f"{path.name}: unknown PNG filter {filter_type}")
            pixels[row_start + x] = value
        src += stride
    return width, height, bytes(pixels)


def measure(path: Path) -> FrameMetrics:
    width, height, rgba = read_png_rgba8(path)
    min_x, min_y, max_x, max_y = width, height, -1, -1
    count = partial = sum_x = sum_y = 0
    for y in range(height):
        row = y * width * 4
        for x in range(width):
            alpha = rgba[row + x * 4 + 3]
            if alpha:
                count += 1
                sum_x += x
                sum_y += y
                min_x = min(min_x, x)
                min_y = min(min_y, y)
                max_x = max(max_x, x)
                max_y = max(max_y, y)
                if alpha != 255:
                    partial += 1
    bbox = None if not count else (min_x, min_y, max_x - min_x + 1, max_y - min_y + 1)
    centroid = None if not count else (sum_x / count, sum_y / count)
    return FrameMetrics(path, width, height, bbox, count, partial, centroid, rgba)


def changed_pixels(left: bytes, right: bytes) -> int:
    return sum(1 for i in range(0, len(left), 4) if left[i : i + 4] != right[i : i + 4])


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("directory", type=Path)
    parser.add_argument("--min-frames", type=int, default=8)
    parser.add_argument("--report", type=Path, help="also write the Markdown report to this path")
    args = parser.parse_args()
    files = sorted(args.directory.glob("frame_*.png"))
    if not files:
        print(f"ERROR: no frame_*.png files in {args.directory}", file=sys.stderr)
        return 2

    errors: list[str] = []
    warnings: list[str] = []
    expected_names = [f"frame_{i:03d}.png" for i in range(1, len(files) + 1)]
    actual_names = [p.name for p in files]
    if actual_names != expected_names:
        errors.append(f"Frame names/order are not contiguous: {actual_names}")
    if len(files) < args.min_frames:
        errors.append(f"Found {len(files)} frames; project minimum is {args.min_frames}")

    try:
        frames = [measure(p) for p in files]
    except (OSError, ValueError, zlib.error) as exc:
        print(f"ERROR: {exc}", file=sys.stderr)
        return 2

    base_size = (frames[0].width, frames[0].height)
    base_bbox = frames[0].bbox
    for frame in frames:
        if (frame.width, frame.height) != base_size:
            errors.append(f"{frame.path.name}: canvas {frame.width}x{frame.height} differs from {base_size}")
        if frame.bbox is None:
            errors.append(f"{frame.path.name}: fully transparent image")
        elif frame.bbox != base_bbox:
            warnings.append(f"{frame.path.name}: alpha bounds {frame.bbox} differ from frame 001 {base_bbox}")

    pair_diffs: list[int] = []
    for previous, current in zip(frames, frames[1:]):
        diff = changed_pixels(previous.rgba, current.rgba)
        pair_diffs.append(diff)
        if diff == 0:
            errors.append(f"Duplicate consecutive frames: {previous.path.name} and {current.path.name}")
    loop_diff = changed_pixels(frames[-1].rgba, frames[0].rgba) if len(frames) > 1 else 0
    if len(frames) > 1 and loop_diff == 0:
        warnings.append("Last frame is an exact duplicate of the first; check for a loop pause")

    lines = [
        f"# Sprite sequence validation — {args.directory}",
        "",
        "**Scope:** technical checks only; not an artistic approval.",
        "",
        f"- Frames: {len(frames)} (minimum requested: {args.min_frames})",
        f"- Canvas: {base_size[0]} × {base_size[1]} px",
        f"- Alpha bounds (frame 001): {base_bbox}",
        f"- Alpha pixels (frame 001): {frames[0].alpha_pixels}",
        f"- Partial-alpha edge pixels (frame 001): {frames[0].partial_alpha_pixels}",
        f"- Adjacent changed-pixel counts: {pair_diffs}",
        f"- Last → first changed pixels: {loop_diff}",
        "",
        "| Frame | Canvas | Alpha bounds | Alpha pixels | Partial alpha | Alpha centroid |",
        "|---|---:|---:|---:|---:|---:|",
    ]
    for frame in frames:
        centroid = "—" if frame.centroid is None else f"({frame.centroid[0]:.2f}, {frame.centroid[1]:.2f})"
        lines.append(
            f"| {frame.path.name} | {frame.width}×{frame.height} | {frame.bbox} | "
            f"{frame.alpha_pixels} | {frame.partial_alpha_pixels} | {centroid} |"
        )
    lines.extend(["", "## Errors", ""])
    lines.extend([f"- {item}" for item in errors] or ["- None"])
    lines.extend(["", "## Warnings", ""])
    lines.extend([f"- {item}" for item in warnings] or ["- None"])
    lines.append("")
    report = "\n".join(lines)
    print(report)
    if args.report:
        args.report.parent.mkdir(parents=True, exist_ok=True)
        args.report.write_text(report, encoding="utf-8")
    return 1 if errors else 0


if __name__ == "__main__":
    raise SystemExit(main())
