#!/usr/bin/env python3
"""Validate Godot-exported iOS UI rectangles and write a CI-readable report."""

from __future__ import annotations

import argparse
import json
from pathlib import Path


def rect(data: dict) -> tuple[float, float, float, float]:
    return (
        float(data["x"]),
        float(data["y"]),
        float(data["width"]),
        float(data["height"]),
    )


def encloses(outer: tuple[float, float, float, float], inner: tuple[float, float, float, float]) -> bool:
    ox, oy, ow, oh = outer
    ix, iy, iw, ih = inner
    return ix >= ox and iy >= oy and ix + iw <= ox + ow and iy + ih <= oy + oh


def intersects(a: tuple[float, float, float, float], b: tuple[float, float, float, float]) -> bool:
    ax, ay, aw, ah = a
    bx, by, bw, bh = b
    return ax < bx + bw and ax + aw > bx and ay < by + bh and ay + ah > by


def inspect(input_path: Path) -> tuple[list[str], list[str]]:
    payload = json.loads(input_path.read_text(encoding="utf-8"))
    layouts = payload.get("layouts", [])
    errors: list[str] = []
    rows: list[str] = []
    expected_counts = {
        (1334, 750): 3,
        (1792, 828): 4,
        (2532, 1170): 4,
        (2796, 1290): 5,
        (2388, 1668): 8,
        (2732, 2048): 8,
    }
    for layout in layouts:
        viewport = rect(layout["viewport"])
        size = (round(viewport[2]), round(viewport[3]))
        safe = rect(layout["safe_area"])
        joystick = rect(layout["joystick_rect"])
        actions = rect(layout["actions_rect"])
        minimap = rect(layout["minimap_rect"])
        pause = rect(layout["pause_rect"])
        prefix = f"{size[0]}x{size[1]}"
        for name, target in (("joystick", joystick), ("actions", actions), ("minimap", minimap), ("pause", pause)):
            if not encloses(safe, target):
                errors.append(f"{prefix}: {name} is outside the safe area")
        if intersects(actions, minimap):
            errors.append(f"{prefix}: action buttons overlap the minimap")
        if float(layout["action_button_extent"]) < 64:
            errors.append(f"{prefix}: action target is below 64px")
        if float(layout["joystick_visual_extent"]) < 180:
            errors.append(f"{prefix}: joystick visual is below 180px")
        if float(layout["joystick_touch_extent"]) <= float(layout["joystick_visual_extent"]):
            errors.append(f"{prefix}: joystick touch area is not larger than its visual")
        if float(layout["minimap_size"]) < 180:
            errors.append(f"{prefix}: minimap is below 180px")
        if int(layout["visible_characters"]) < expected_counts.get(size, 3):
            errors.append(f"{prefix}: character density target is not met")
        if bool(layout.get("debug_overlay", True)):
            errors.append(f"{prefix}: developer overlay is enabled")
        rows.append(
            f"| {prefix} | {layout['profile']} | {layout['visible_characters']} | "
            f"{layout['joystick_visual_extent']:.0f}/{layout['joystick_touch_extent']:.0f} | "
            f"{layout['action_button_extent']:.0f} | {layout['minimap_size']:.0f} | "
            f"{layout['camera_zoom']:.2f} |"
        )
    return errors, rows


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument(
        "--input",
        default="test-output/screenshots/ios_layout/layout_rects.json",
        type=Path,
    )
    parser.add_argument(
        "--output",
        default="test-output/screenshots/ios_layout/inspection_report.md",
        type=Path,
    )
    args = parser.parse_args()
    errors, rows = inspect(args.input)
    args.output.parent.mkdir(parents=True, exist_ok=True)
    status = "PASS" if not errors else "FAIL"
    report = [
        "# iOS Layout QA",
        "",
        f"Status: **{status}**",
        "",
        "| Viewport | Profile | Visible characters | Joystick visual/touch | Action | Minimap | Camera zoom |",
        "|---|---:|---:|---:|---:|---:|---:|",
        *rows,
        "",
        "## Findings",
        "",
        *([f"- {error}" for error in errors] if errors else ["- No layout violations detected."]),
        "",
    ]
    args.output.write_text("\n".join(report), encoding="utf-8")
    print(f"iOS layout QA {status}: {len(rows)} layouts, {len(errors)} errors")
    return 1 if errors else 0


if __name__ == "__main__":
    raise SystemExit(main())

