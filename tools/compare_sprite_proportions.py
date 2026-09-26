#!/usr/bin/env python3
"""Compare alpha silhouette proportions between a master sprite and a candidate.

This is a screen-space consistency gate, not an art judge. It aligns by alpha
bounds and compares whole-sprite scale plus normalized vertical regions. Different
orientations may need different tolerances; review the metrics before rejecting.

Usage:
  python tools/compare_sprite_proportions.py master.png candidate.png --report compare.md
  python tools/compare_sprite_proportions.py master.png candidate.png --fail-on-warnings
"""
from __future__ import annotations

import argparse
import sys
from dataclasses import dataclass
from pathlib import Path

from validate_sprite_sequence import read_png_rgba8


@dataclass
class Region:
    name: str
    y0: int
    y1: int
    bbox_width: int
    bbox_height: int
    alpha_area: int
    area_share: float
    mean_row_width: float


@dataclass
class Sprite:
    path: Path
    width: int
    height: int
    bbox: tuple[int, int, int, int]
    alpha_area: int
    centroid: tuple[float, float]
    row_widths: list[int]
    regions: dict[str, Region]


def build_sprite(path: Path) -> Sprite:
    width, height, rgba = read_png_rgba8(path)
    min_x, min_y, max_x, max_y = width, height, -1, -1
    area = sx = sy = 0
    row_min = [width] * height
    row_max = [-1] * height
    row_area = [0] * height
    for y in range(height):
        row = y * width * 4
        for x in range(width):
            if rgba[row + x * 4 + 3] == 0:
                continue
            area += 1
            sx += x
            sy += y
            min_x = min(min_x, x)
            min_y = min(min_y, y)
            max_x = max(max_x, x)
            max_y = max(max_y, y)
            row_min[y] = min(row_min[y], x)
            row_max[y] = max(row_max[y], x)
            row_area[y] += 1
    if area == 0:
        raise ValueError(f"{path}: fully transparent sprite")
    bbox = (min_x, min_y, max_x - min_x + 1, max_y - min_y + 1)
    row_widths = [0] * height
    for y in range(min_y, max_y + 1):
        if row_max[y] >= row_min[y]:
            row_widths[y] = row_max[y] - row_min[y] + 1

    regions: dict[str, Region] = {}
    h = bbox[3]
    for name, start, end in (
        ("head_neck", 0.00, 0.24),
        ("shoulders_chest", 0.24, 0.58),
        ("pelvis_legs_feet", 0.58, 1.00),
    ):
        y0 = min(height, min_y + round(h * start))
        y1 = min(height, min_y + round(h * end))
        xs: list[int] = []
        ys: list[int] = []
        widths: list[int] = []
        region_area = 0
        for y in range(y0, y1):
            rw = row_widths[y]
            if rw:
                widths.append(rw)
                xs.extend((row_min[y], row_max[y]))
                ys.append(y)
                region_area += row_area[y]
        if xs and ys:
            region_bbox_width = max(xs) - min(xs) + 1
            region_bbox_height = max(ys) - min(ys) + 1
            mean_width = sum(widths) / max(1, len(widths))
        else:
            region_bbox_width = region_bbox_height = 0
            mean_width = 0.0
        regions[name] = Region(
            name,
            y0,
            y1,
            region_bbox_width,
            region_bbox_height,
            region_area,
            region_area / area,
            mean_width,
        )
    return Sprite(path, width, height, bbox, area, (sx / area, sy / area), row_widths, regions)


def pct(candidate: float, master: float) -> float:
    if master == 0:
        return 0.0 if candidate == 0 else float("inf")
    return (candidate / master - 1.0) * 100.0


def close_enough(delta_pct: float, tolerance_pct: float) -> bool:
    return abs(delta_pct) <= tolerance_pct


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("master", type=Path)
    parser.add_argument("candidate", type=Path)
    parser.add_argument("--report", type=Path)
    parser.add_argument("--height-tol", type=float, default=2.0, help="whole-sprite height tolerance in percent")
    parser.add_argument("--width-tol", type=float, default=4.0, help="whole-sprite width tolerance in percent")
    parser.add_argument("--head-area-tol", type=float, default=15.0, help="head/neck regional area tolerance in percent")
    parser.add_argument("--head-width-tol", type=float, default=25.0, help="head/neck region width tolerance in percent")
    parser.add_argument("--torso-area-tol", type=float, default=10.0, help="shoulders/chest regional area tolerance in percent")
    parser.add_argument("--legs-area-tol", type=float, default=10.0, help="pelvis/legs/feet regional area tolerance in percent")
    parser.add_argument("--fail-on-warnings", action="store_true", help="exit 1 if any tolerance is exceeded")
    args = parser.parse_args()
    try:
        master = build_sprite(args.master)
        candidate = build_sprite(args.candidate)
    except Exception as exc:
        print(f"ERROR: {exc}", file=sys.stderr)
        return 2

    warnings: list[str] = []
    rows: list[tuple[str, float, float, bool]] = []
    mh, ch = master.bbox[3], candidate.bbox[3]
    mw, cw = master.bbox[2], candidate.bbox[2]
    height_delta = pct(ch, mh)
    width_delta = pct(cw, mw)
    rows.append(("Whole-sprite height", mh, ch, close_enough(height_delta, args.height_tol)))
    rows.append(("Whole-sprite width", mw, cw, close_enough(width_delta, args.width_tol)))
    if not close_enough(height_delta, args.height_tol):
        warnings.append(f"Whole-sprite height differs by {height_delta:+.1f}% (limit ±{args.height_tol:.1f}%)")
    if not close_enough(width_delta, args.width_tol):
        warnings.append(f"Whole-sprite width differs by {width_delta:+.1f}% (limit ±{args.width_tol:.1f}%)")

    region_limits = {
        "head_neck": ("alpha_area", args.head_area_tol),
        "shoulders_chest": ("alpha_area", args.torso_area_tol),
        "pelvis_legs_feet": ("alpha_area", args.legs_area_tol),
    }
    # Head width is checked separately because an orientation change can strongly
    # alter face visibility while still preserving the head's screen-space height.
    r_master = master.regions["head_neck"]
    r_candidate = candidate.regions["head_neck"]
    head_width_delta = pct(r_candidate.bbox_width, r_master.bbox_width)
    rows.append(("Head/neck region width", r_master.bbox_width, r_candidate.bbox_width, close_enough(head_width_delta, args.head_width_tol)))
    if not close_enough(head_width_delta, args.head_width_tol):
        warnings.append(f"Head/neck region width differs by {head_width_delta:+.1f}% (limit ±{args.head_width_tol:.1f}%)")

    for name, (field, tolerance) in region_limits.items():
        rm, rc = master.regions[name], candidate.regions[name]
        vm, vc = getattr(rm, field), getattr(rc, field)
        delta = pct(vc, vm)
        rows.append((f"{name} alpha area", vm, vc, close_enough(delta, tolerance)))
        if not close_enough(delta, tolerance):
            warnings.append(f"{name} alpha area differs by {delta:+.1f}% (limit ±{tolerance:.1f}%)")

    report_lines = [
        "# Cross-frame sprite proportion comparison",
        "",
        "**Scope:** screen-space geometry heuristic; direction/camera changes require a human-calibrated tolerance. This does not judge art style or natural acting.",
        "",
        f"- Master: `{master.path}` — bbox `{master.bbox}`, alpha pixels `{master.alpha_area}`, centroid `({master.centroid[0]:.2f},{master.centroid[1]:.2f})`",
        f"- Candidate: `{candidate.path}` — bbox `{candidate.bbox}`, alpha pixels `{candidate.alpha_area}`, centroid `({candidate.centroid[0]:.2f},{candidate.centroid[1]:.2f})`",
        "",
        "| Metric | Master | Candidate | Delta | Result |",
        "|---|---:|---:|---:|---|",
    ]
    for index, (label, base, value, passed) in enumerate(rows):
        delta = pct(value, base)
        report_lines.append(f"| {label} | {base:.2f} | {value:.2f} | {delta:+.1f}% | {'PASS' if passed else 'REVIEW'} |")
    report_lines.extend(["", "## Regional silhouette shares", "", "| Region | Master area / total | Candidate area / total |", "|---|---:|---:|"])
    for name in ("head_neck", "shoulders_chest", "pelvis_legs_feet"):
        rm, rc = master.regions[name], candidate.regions[name]
        report_lines.append(f"| {name} | {rm.area_share * 100:.1f}% | {rc.area_share * 100:.1f}% |")
    report_lines.extend(["", "## Warnings", ""])
    report_lines.extend([f"- {warning}" for warning in warnings] or ["- None"])
    report_lines.append("")
    report = "\n".join(report_lines)
    print(report)
    if args.report:
        args.report.parent.mkdir(parents=True, exist_ok=True)
        args.report.write_text(report, encoding="utf-8")
    return 1 if (warnings and args.fail_on_warnings) else 0


if __name__ == "__main__":
    raise SystemExit(main())
