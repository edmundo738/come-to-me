#!/usr/bin/env python3
"""Build a lossless, full-canvas APNG preview from individual review PNGs.

This preview-only utility preserves RGBA pixels, uses full-frame replacement,
and explicitly clears the previous frame. It avoids GIF palette reduction and
undefined disposal behavior. It never trims, packs, or modifies source frames.

Usage:
  python tools/spritedna_preview_apng.py REVIEW_FRAMES_DIR REVIEW_OUTPUT.apng --fps 12.5
"""
from __future__ import annotations

import argparse
import math
import struct
import zlib
from pathlib import Path

from validate_sprite_sequence import measure, read_png_rgba8

PNG_SIGNATURE = b"\x89PNG\r\n\x1a\n"
DISPOSE_BACKGROUND = 1
BLEND_SOURCE = 0


def png_chunk(kind: bytes, payload: bytes) -> bytes:
    body = kind + payload
    return struct.pack(">I", len(payload)) + body + struct.pack(">I", zlib.crc32(body) & 0xFFFFFFFF)


def control_chunk(sequence: int, width: int, height: int, delay_num: int, delay_den: int) -> bytes:
    payload = struct.pack(
        ">IIIIIHHBB",
        sequence, width, height, 0, 0,
        delay_num, delay_den,
        DISPOSE_BACKGROUND, BLEND_SOURCE,
    )
    return png_chunk(b"fcTL", payload)


def filtered_scanlines(width: int, height: int, rgba: bytes) -> bytes:
    stride = width * 4
    rows = bytearray(height * (stride + 1))
    target = 0
    for y in range(height):
        rows[target] = 0  # PNG filter None; exact RGBA samples follow.
        target += 1
        start = y * stride
        rows[target : target + stride] = rgba[start : start + stride]
        target += stride
    return bytes(rows)


def write_apng(frames_dir: Path, output: Path, fps: float) -> None:
    if not frames_dir.is_dir():
        raise ValueError(f"frame directory does not exist: {frames_dir}")
    if "review" not in output.parts or "animations" in output.parts:
        raise ValueError("preview output must be a new file under review/, never production")
    if output.exists():
        raise ValueError(f"refusing to overwrite existing preview: {output}")
    if not math.isfinite(fps) or fps <= 0:
        raise ValueError("FPS must be a positive finite number")

    paths = sorted(frames_dir.glob("frame_*.png"))
    if len(paths) < 2:
        raise ValueError("at least two individual PNG frames are required")
    expected = [f"frame_{index:03d}.png" for index in range(1, len(paths) + 1)]
    if [path.name for path in paths] != expected:
        raise ValueError("frame names must be contiguous frame_001.png, frame_002.png, ...")

    measured = [measure(path) for path in paths]
    width, height = measured[0].width, measured[0].height
    for frame in measured:
        if (frame.width, frame.height) != (width, height):
            raise ValueError(f"{frame.path.name}: canvas differs; full-canvas animation required")
        if frame.bbox is None:
            raise ValueError(f"{frame.path.name}: fully transparent frame")

    # Store a rational delay in centiseconds so ordinary sprite frame rates are
    # represented exactly enough without converting the source artwork.
    delay_den = 100
    delay_num = round(delay_den / fps)
    if delay_num < 1:
        raise ValueError("FPS above 100 cannot be represented at centisecond precision")

    output.parent.mkdir(parents=True, exist_ok=True)
    data = bytearray(PNG_SIGNATURE)
    data.extend(png_chunk(b"IHDR", struct.pack(">IIBBBBB", width, height, 8, 6, 0, 0, 0)))
    data.extend(png_chunk(b"acTL", struct.pack(">II", len(measured), 0)))
    data.extend(control_chunk(0, width, height, delay_num, delay_den))

    for index, frame in enumerate(measured):
        compressed = zlib.compress(filtered_scanlines(width, height, frame.rgba), level=9)
        if index == 0:
            data.extend(png_chunk(b"IDAT", compressed))
        else:
            sequence = index * 2 - 1
            data.extend(control_chunk(sequence, width, height, delay_num, delay_den))
            data.extend(png_chunk(b"fdAT", struct.pack(">I", sequence + 1) + compressed))
    data.extend(png_chunk(b"IEND", b""))
    output.write_bytes(data)

    print(f"Created lossless {len(measured)}-frame APNG: {output}")
    print(f"Canvas {width}x{height}; {fps:g} FPS; full-frame SOURCE blend; BACKGROUND disposal.")
    print("The source PNG sequence remains unchanged; no trimming or sprite-sheet packing was performed.")


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("frames", type=Path, help="directory containing individual numbered RGBA PNGs")
    parser.add_argument("output", type=Path, help="new .apng file under a review/ directory")
    parser.add_argument("--fps", type=float, default=12.5)
    args = parser.parse_args()
    if args.output.suffix.lower() != ".apng":
        parser.error("output extension must be .apng")
    try:
        write_apng(args.frames, args.output, args.fps)
    except (OSError, ValueError, zlib.error) as exc:
        parser.error(str(exc))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
