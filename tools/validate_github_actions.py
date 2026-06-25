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
        "macos-15 runner": "runs-on: macos-15" in text,
        "workflow_dispatch": re.search(r"(?m)^\s*workflow_dispatch:\s*$", text) is not None,
        "full_test input": "full_test:" in text,
        "GODOT_VERSION": 'GODOT_VERSION: "4.2-stable"' in text,
        "TEMPLATE_VERSION": 'TEMPLATE_VERSION: "4.2.stable"' in text,
        "upload-artifact": "actions/upload-artifact@v4" in text,
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
