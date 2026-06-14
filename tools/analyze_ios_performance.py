#!/usr/bin/env python3
"""Build a compact Markdown report from the iOS performance CSV."""

from __future__ import annotations

import argparse
import csv
import statistics
from pathlib import Path


def percentile(values: list[float], ratio: float) -> float:
    if not values:
        return 0.0
    ordered = sorted(values)
    index = max(0, min(len(ordered) - 1, int(len(ordered) * ratio + 0.999999) - 1))
    return ordered[index]


def number(row: dict[str, str], key: str) -> float:
    try:
        return float(row.get(key, 0) or 0)
    except ValueError:
        return 0.0


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("input", nargs="?", default="ios_performance_log.csv")
    parser.add_argument("--output", default="ios_performance_report.md")
    parser.add_argument("--baseline")
    args = parser.parse_args()

    input_path = Path(args.input)
    rows = list(csv.DictReader(input_path.open(encoding="utf-8")))
    frame = [number(row, "frame_time_avg_5s") for row in rows]
    fps = [number(row, "fps") for row in rows]
    memory = [number(row, "memory_estimate") for row in rows]
    over_33 = sum(value > 33.0 for value in frame)
    over_50 = sum(value > 50.0 for value in frame)
    growth = 0.0 if not memory or memory[0] <= 0 else (memory[-1] - memory[0]) / memory[0] * 100.0
    suspects: list[str] = []
    if percentile(frame, 0.95) > 33.0:
        suspects.append("p95 frame time exceeds the 33 ms target; inspect peak enemy/effect counts.")
    if growth > 20.0:
        suspects.append("Memory growth exceeds 20%; inspect pool active counts and retained UI nodes.")
    if max((number(row, "created_nodes_per_second") for row in rows), default=0.0) > 1.0:
        suspects.append("UI node creation continues after startup; inspect event-driven HUD paths.")
    if not suspects:
        suspects.append("No budget trend violation was detected in this capture.")

    lines = [
        "# iOS Performance Report",
        "",
        f"- Samples: {len(rows)}",
        f"- Average FPS: {statistics.fmean(fps) if fps else 0.0:.2f}",
        f"- p95 frame time: {percentile(frame, 0.95):.2f} ms",
        f"- p99 frame time: {percentile(frame, 0.99):.2f} ms",
        f"- Samples over 33 ms: {over_33}",
        f"- Samples over 50 ms: {over_50}",
        f"- Memory growth: {growth:.2f}%",
        "",
        "## Stutter Timeline",
        "",
        "| Time | Avg ms | p95 ms | Enemies | Effects | Gems | UI nodes | Created nodes/s |",
        "|---:|---:|---:|---:|---:|---:|---:|---:|",
    ]
    for row in rows:
        if number(row, "frame_time_avg_5s") > 33.0 or number(row, "frame_time_p95_30s") > 33.0:
            lines.append(
                "| {time} | {avg} | {p95} | {enemy} | {effect} | {gem} | {ui} | {created} |".format(
                    time=row.get("time", "0"),
                    avg=row.get("frame_time_avg_5s", "0"),
                    p95=row.get("frame_time_p95_30s", "0"),
                    enemy=row.get("enemy_count", "0"),
                    effect=row.get("effect_count", "0"),
                    gem=row.get("gem_count", "0"),
                    ui=row.get("ui_node_count", "0"),
                    created=row.get("created_nodes_per_second", "0"),
                )
            )
    if lines[-1].startswith("|---"):
        lines.append("| - | - | - | - | - | - | - | - |")
    lines.extend(["", "## Suspected Causes", ""])
    lines.extend(f"- {item}" for item in suspects)
    if args.baseline:
        lines.extend(["", "## Before / After", "", f"- Baseline CSV: `{args.baseline}`", f"- Current CSV: `{input_path}`"])
    Path(args.output).write_text("\n".join(lines) + "\n", encoding="utf-8")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
