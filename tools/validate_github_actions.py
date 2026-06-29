from pathlib import Path
import sys


ROOT = Path(__file__).resolve().parents[1]
WORKFLOW_DIR = ROOT / ".github" / "workflows"
REQUIRED = {
    "ci-fast.yml",
    "ci-ios-perf.yml",
    "build-release.yml",
    "nightly-full.yml",
}


def main() -> int:
    failures: list[str] = []
    missing = [name for name in REQUIRED if not (WORKFLOW_DIR / name).is_file()]
    failures.extend(f"missing workflow: {name}" for name in missing)
    if failures:
        for failure in failures:
            print(f"ERROR: {failure}", file=sys.stderr)
        return 1

    texts = {
        name: (WORKFLOW_DIR / name).read_text(encoding="utf-8")
        for name in REQUIRED
    }
    combined = "\n".join(texts.values())
    fast = texts["ci-fast.yml"]
    perf = texts["ci-ios-perf.yml"]
    release = texts["build-release.yml"]
    nightly = texts["nightly-full.yml"]
    ios_perf_30 = (ROOT / "tests" / "auto_play_ios_perf_30min.gd").read_text(encoding="utf-8")
    density_30_alias = (ROOT / "tests" / "auto_play_phase5_density_30min.gd").read_text(encoding="utf-8")
    canonical_30_call = "Harness.new().run(self, 30,"
    checks = {
        "Godot 4.7": combined.count('GODOT_VERSION: "4.7-stable"') == 4,
        "actions/cache v4": all("actions/cache@v4" in text for text in texts.values()),
        "OS-specific cache keys": "${{ runner.os }}" in combined,
        "import cache": ".godot/imported" in combined,
        "Fast Gate pull request": "pull_request:" in fast,
        "Fast Gate concurrency": "cancel-in-progress: true" in fast,
        "changed-file routing": "select_test_manifest.py" in fast,
        "batch runner": "batch_test_runner.gd" in fast and "fast_gate.json" in fast,
        "Phase 7 stress": "auto_play_ios_effect_budget_snapshot.gd" in fast,
        "Phase 7 parity": "auto_play_ios_visual_simulation_parity.gd" in fast,
        "Fast Gate target": "timeout-minutes: 15" in fast,
        "Phase 7 perf dispatch": "workflow_dispatch:" in perf,
        "Phase 7 perf target": "timeout-minutes: 20" in perf,
        "Phase 7 perf artifact": "phase7-performance-summary" in perf,
        "release dispatch": "workflow_dispatch:" in release,
        "Windows runner": "runs-on: windows-latest" in release,
        "macos-26 runner": "runs-on: macos-26" in release,
        "release target": release.count("timeout-minutes: 25") == 2,
        "Windows artifact": "ChronoMergeTactics-Windows" in release,
        "iOS artifact": "GemSurvivor-iOS-unsigned-IPA" in release,
        "unsigned iOS": "CODE_SIGNING_ALLOWED=NO" in release,
        "arm64 inspection": 'grep -q "arm64"' in release,
        "PCK inspection": 'test -f "${APP_DIR}/GemSurvivor.pck"' in release,
        "icon inspection": 'test -f "${APP_DIR}/Assets.car"' in release,
        "SHA256 Windows": "SHA256SUMS-Windows.txt" in release,
        "SHA256 iOS": "SHA256SUMS-iOS.txt" in release,
        "nightly schedule": "schedule:" in nightly,
        "nightly dispatch": "workflow_dispatch:" in nightly,
        "nightly full assertions": "test_runner.gd" in nightly,
        "nightly canonical density 30": (
            "auto_play_ios_perf_30min.gd" in nightly
            and "auto_play_phase5_density_30min.gd" not in nightly
            and canonical_30_call in ios_perf_30
            and canonical_30_call in density_30_alias
        ),
        "nightly density 45": "auto_play_phase5_density_45min.gd" in nightly,
        "nightly density 60": "auto_play_phase5_density_60min.gd" in nightly,
        "nightly all shard artifact": "Full-Test-${{ matrix.shard }}" in nightly,
        "timing output": "timing.ndjson" in nightly and "fast_gate_timing.json" in fast,
        "consolidated Fast artifact": "fast-qa-summary" in fast,
        "failure artifact": "failure-logs" in fast,
    }
    failures.extend(name for name, passed in checks.items() if not passed)
    if failures:
        for failure in failures:
            print(f"ERROR: missing {failure}", file=sys.stderr)
        return 1
    print(f"GitHub Actions validation passed: {len(checks)} checks")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
