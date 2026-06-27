from pathlib import Path
import re
import sys


ROOT = Path(__file__).resolve().parents[1]
WORKFLOW = ROOT / ".github" / "workflows" / "build.yml"


def main() -> int:
    if not WORKFLOW.is_file():
        print(f"ERROR: workflow not found: {WORKFLOW}", file=sys.stderr)
        return 1

    text = WORKFLOW.read_text(encoding="utf-8")
    checks = {
        "windows-latest runner": "runs-on: windows-latest" in text,
        "macos-26 runner": "runs-on: macos-26" in text,
        "workflow_dispatch": re.search(r"(?m)^\s*workflow_dispatch:\s*$", text) is not None,
        "full_test input": "full_test:" in text,
        "GODOT_VERSION": 'GODOT_VERSION: "4.7-stable"' in text,
        "TEMPLATE_VERSION": 'TEMPLATE_VERSION: "4.7.stable"' in text,
        "upload-artifact": "actions/upload-artifact@v4" in text,
        "Pillow dependency": "python -m pip install --upgrade pillow" in text,
        "Windows artifact": "ChronoMergeTactics-Windows" in text,
        "Windows artifact archive": "ChronoMergeTactics-Windows.zip" in text,
        "iOS artifact": "GemSurvivor-iOS-unsigned-IPA" in text,
        "balance report artifact": "Balance-Report" in text,
        "safe play area artifact": "Safe-Play-Area-QA" in text,
        "exploration balance artifact": "Exploration-Balance-Report" in text,
        "candidate pool artifact": "Candidate-Pool-QA" in text,
        "asset qa artifact": "Asset-QA-Report" in text,
        "ui redesign artifact": "UI-Redesign-QA" in text,
        "field equipment artifact": "Field-Equipment-QA" in text,
        "selection reroll artifact": "Selection-Reroll-QA" in text,
        "experience balance artifact": "Experience-Balance-Report" in text,
        "persistent drop artifact": "Persistent-Drop-QA" in text,
        "global gem collection artifact": "Global-Gem-Collection-QA" in text,
        "character evolution artifact": "Character-Evolution-QA" in text,
        "knockback artifact": "Knockback-QA" in text,
        "phase4 artifact": "Phase4-iOS-Environment-QA" in text,
        "phase4 title audit": "tools/audit_ios_title_layout.py" in text,
        "phase4 environment asset validation": "tools/environment/validate_environment_assets.py" in text,
        "phase4 environment report": "tools/environment/generate_environment_report.py" in text,
        "phase4 environment autoplay": "auto_play_environment_10min.gd" in text,
        "phase4 item placement environment autoplay": "auto_play_item_placement_environment_30min.gd" in text,
        "phase5 contrast audit": "tools/environment/measure_environment_contrast.py" in text,
        "phase5 collectible audit": "tools/environment/audit_collectible_confusion.py" in text,
        "phase5 readability audit": "tools/environment/audit_environment_readability.py" in text,
        "phase5 grayscale contact sheet": "tools/environment/generate_grayscale_contact_sheet.py" in text,
        "phase5 colorblind contact sheet": "tools/environment/generate_colorblind_contact_sheet.py" in text,
        "phase5 enemy parity autoplay": "auto_play_phase5_enemy_parity.gd" in text,
        "phase5 iOS 60sec autoplay": "auto_play_phase5_ios_60sec.gd" in text,
        "phase5 long density autoplay": "auto_play_phase5_density_60min.gd" in text,
        "phase5 artifact": "Phase5-Performance-QA" in text,
        "phase6 targeted tests": "test_phase6_runner.gd" in text,
        "phase6 benchmark": "auto_play_phase6_renderer_compare.gd" in text,
        "phase6 artifact": "Phase6-Renderer-Frame-QA" in text,
        "Windows SHA256": "SHA256SUMS-Windows.txt" in text,
        "iOS SHA256": "SHA256SUMS-iOS.txt" in text,
        "IPA structure verification": 'unzip -t builds/ios/GemSurvivor-unsigned.ipa' in text,
        "full test matrix": "windows-full-tests:" in text and "fail-fast: false" in text,
        "full shard import": text.count("& $godot --headless --editor --path . --quit-after 1000") >= 2,
        "full shard prerequisites": "prepare_full_test_shard.gd" in text,
        "full core shard": "shard: core-long" in text,
        "full density shard": "shard: density" in text,
        "full shard artifacts": "Full-Test-${{ matrix.shard }}" in text,
    }
    failures = [name for name, passed in checks.items() if not passed]
    if failures:
        for name in failures:
            print(f"ERROR: missing {name}", file=sys.stderr)
        return 1

    print(f"GitHub Actions validation passed: {len(checks)} checks")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
