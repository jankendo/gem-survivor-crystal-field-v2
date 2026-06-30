from __future__ import annotations

import argparse
import json
import subprocess
from pathlib import Path


ROOT = Path(__file__).resolve().parents[2]


def changed_files(base: str, head: str) -> list[str]:
    result = subprocess.run(
        ["git", "diff", "--name-only", base, head],
        cwd=ROOT,
        check=True,
        capture_output=True,
        text=True,
    )
    return [line.strip().replace("\\", "/") for line in result.stdout.splitlines() if line.strip()]


def route(paths: list[str]) -> dict[str, bool | str | list[str]]:
    docs_only = bool(paths) and all(path.startswith("docs/") or path in {"README.md", "AGENTS.md"} for path in paths)
    common = any(
        path in {"AGENTS.md", "project.godot"}
        or path.startswith(".github/workflows/")
        or path.startswith("scripts/core/")
        for path in paths
    )
    effect = common or any(
        path.startswith(("scripts/systems/Weapon", "scripts/systems/Visual", "scripts/ui/ArenaView", "data/weapon", "data/visual_effect"))
        for path in paths
    )
    phase9 = common or any(
        path.startswith(("scripts/systems/Enemy", "scripts/systems/GemCollection", "scripts/systems/CrystalSurvey", "scripts/systems/SelectionContext", "scripts/ui/ResultView", "scripts/ui/GameScreen", "tests/"))
        or path in {"data/gem_collection_effects.json", "tests/manifests/phase9_perf.json"}
        for path in paths
    )
    ios = common or any(
        "ios" in path.lower() or path in {"export_presets.cfg", "IOS_UNSIGNED_README.md"}
        for path in paths
    )
    return {
        "changed_files": paths,
        "docs_only": docs_only,
        "run_fast_gate": not docs_only,
        "run_phase7_perf": effect and not docs_only,
        "run_phase9_perf": phase9 and not docs_only,
        "run_ios_validation": ios and not docs_only,
        "reason": "common/full" if common else ("docs-only" if docs_only else "targeted"),
    }


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--base", default="HEAD~1")
    parser.add_argument("--head", default="HEAD")
    parser.add_argument("--output", default="test-output/ci/changed-file-routing.json")
    parser.add_argument("--github-output")
    args = parser.parse_args()
    report = route(changed_files(args.base, args.head))
    output = ROOT / args.output
    output.parent.mkdir(parents=True, exist_ok=True)
    output.write_text(json.dumps(report, ensure_ascii=False, indent=2), encoding="utf-8")
    if args.github_output:
        with Path(args.github_output).open("a", encoding="utf-8") as handle:
            for key in ("docs_only", "run_fast_gate", "run_phase7_perf", "run_phase9_perf", "run_ios_validation"):
                handle.write(f"{key}={str(report[key]).lower()}\n")
            handle.write(f"reason={report['reason']}\n")
    print(json.dumps(report, ensure_ascii=False))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
