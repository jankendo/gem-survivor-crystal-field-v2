from __future__ import annotations

import json
import sys
from pathlib import Path


def main() -> int:
    metrics_path, timing_path, summary_path = map(Path, sys.argv[1:4])
    metrics = json.loads(metrics_path.read_text(encoding="utf-8"))
    timing = json.loads(timing_path.read_text(encoding="utf-8"))
    lines = [
        "## Phase 7 Performance",
        f"- scenarios: {metrics['scenario_count']}",
        f"- visual command reduction: {metrics['visual_command_reduction_ratio'] * 100:.2f}%",
        f"- maximum p95: {metrics['max_p95_ms']:.3f} ms",
        f"- maximum p99: {metrics['max_p99_ms']:.3f} ms",
        f"- critical missing: {metrics['critical_missing']}",
        f"- simulation parity: {metrics['simulation_parity']}",
        f"- batch wall time: {timing['total_ms'] / 1000:.3f} s",
        "- real iPhone thermal/GPU/battery: external and unverified",
    ]
    with summary_path.open("a", encoding="utf-8") as handle:
        handle.write("\n".join(lines) + "\n")
    print("\n".join(lines))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())

