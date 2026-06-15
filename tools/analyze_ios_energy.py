#!/usr/bin/env python3
"""Create a profile-comparison report from iOS energy CSV captures."""

from __future__ import annotations

import argparse
import csv
import json
import statistics
from pathlib import Path


def number(row: dict[str, str], key: str) -> float:
    try:
        return float(row.get(key, 0) or 0)
    except (TypeError, ValueError):
        return 0.0


def load_csv(path: Path) -> list[dict[str, str]]:
    if not path.exists():
        return []
    with path.open(encoding="utf-8-sig", newline="") as handle:
        return list(csv.DictReader(handle))


def load_summary(path: Path) -> dict:
    if not path.exists():
        return {}
    with path.open(encoding="utf-8") as handle:
        value = json.load(handle)
    return value if isinstance(value, dict) else {}


def profile_section(name: str, rows: list[dict[str, str]], summary: dict) -> list[str]:
    energy = [number(row, "energy_score") for row in rows]
    frame = [number(row, "frame_time_p95_30s") for row in rows]
    risks: dict[str, int] = {}
    for row in rows:
        risk = row.get("estimated_power_risk", "unknown")
        risks[risk] = risks.get(risk, 0) + 1
    elapsed = max(1.0, number(rows[-1], "time") if rows else number(summary, "elapsed_seconds"))
    label_rate = number(summary, "label_update_count") / elapsed
    log_rate = number(summary, "log_write_count") / elapsed
    return [
        f"## {name}",
        "",
        f"- Samples: {len(rows)}",
        f"- Average energy score: {statistics.fmean(energy) if energy else 0.0:.3f}",
        f"- Peak energy score: {max(energy, default=0.0):.3f}",
        f"- Average p95 frame time: {statistics.fmean(frame) if frame else 0.0:.3f} ms",
        f"- Label updates/second: {label_rate:.3f}",
        f"- Log writes/second: {log_rate:.3f}",
        f"- UI nodes start/mid/end: {summary.get('initial_nodes', 'n/a')} / {summary.get('mid_nodes', 'n/a')} / {summary.get('end_nodes', 'n/a')}",
        f"- Created nodes/second after midpoint: {float(summary.get('created_nodes_per_second', 0.0)):.4f}",
        f"- Power risk samples: `{json.dumps(risks, ensure_ascii=False)}`",
        "",
    ]


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--standard", type=Path, default=Path("test-output/ios_energy_log_standard.csv"))
    parser.add_argument("--battery-saver", type=Path, default=Path("test-output/ios_energy_log_battery_saver.csv"))
    parser.add_argument("--output", type=Path, default=Path("test-output/ios_energy_report.md"))
    args = parser.parse_args()
    standard = load_csv(args.standard)
    saver = load_csv(args.battery_saver)
    if not standard or not saver:
        raise SystemExit("Both standard and battery saver energy captures are required.")
    standard_summary = load_summary(args.standard.with_name(args.standard.stem + "_summary.json"))
    saver_summary = load_summary(args.battery_saver.with_name(args.battery_saver.stem + "_summary.json"))
    lines = [
        "# iOS Energy Report",
        "",
        "Synthetic 20-minute fixed-workload captures compare update budgets without removing gameplay features or visual systems.",
        "",
        *profile_section("Standard", standard, standard_summary),
        *profile_section("Battery Saver", saver, saver_summary),
        "## Interpretation",
        "",
        "- Standard keeps the 60 fps target and full quality.",
        "- Battery Saver changes pacing and update intervals only; weapon, enemy, effect, UI, notification, and map systems remain enabled.",
        "- Final validation still requires Xcode Energy Organizer or Instruments on physical iPhone hardware.",
        "",
    ]
    args.output.parent.mkdir(parents=True, exist_ok=True)
    args.output.write_text("\n".join(lines), encoding="utf-8", newline="\n")
    print(f"Wrote {args.output}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
