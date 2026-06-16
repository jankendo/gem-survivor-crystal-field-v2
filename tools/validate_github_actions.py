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
        "macos-latest runner": "runs-on: macos-latest" in text,
        "workflow_dispatch": re.search(r"(?m)^\s*workflow_dispatch:\s*$", text) is not None,
        "full_test input": "full_test:" in text,
        "GODOT_VERSION": 'GODOT_VERSION: "4.2-stable"' in text,
        "TEMPLATE_VERSION": 'TEMPLATE_VERSION: "4.2.stable"' in text,
        "upload-artifact": "actions/upload-artifact@v4" in text,
        "Windows artifact": "ChronoMergeTactics-Windows" in text,
        "Windows artifact archive": "zip -qry ../ChronoMergeTactics-Windows.zip" in text,
        "iOS artifact": "GemSurvivor-iOS-unsigned-IPA" in text,
        "balance report artifact": "Balance-Report" in text,
        "safe play area artifact": "Safe-Play-Area-QA" in text,
        "exploration balance artifact": "Exploration-Balance-Report" in text,
        "candidate pool artifact": "Candidate-Pool-QA" in text,
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
