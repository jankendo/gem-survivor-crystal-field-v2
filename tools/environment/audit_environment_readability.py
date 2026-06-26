from __future__ import annotations

from audit_collectible_confusion import audit as audit_collectibles
from measure_environment_contrast import measure as measure_contrast
from phase5_readability_common import OUT_DIR, write_json


def main() -> int:
    contrast = measure_contrast()
    collectibles = audit_collectibles()
    errors = list(contrast["errors"]) + list(collectibles["errors"])
    summary = {
        "status": "pass" if not errors else "fail",
        "contrast_errors": len(contrast["errors"]),
        "collectible_confusion_errors": len(collectibles["errors"]),
        "errors": errors,
    }
    write_json(OUT_DIR / "environment_readability_summary.json", summary)
    lines = [
        "# Phase 5 Environment Readability Summary",
        "",
        f"- status: {summary['status']}",
        f"- contrast_errors: {summary['contrast_errors']}",
        f"- collectible_confusion_errors: {summary['collectible_confusion_errors']}",
    ]
    if errors:
        lines.extend(["", "## Errors"])
        lines.extend(f"- {error}" for error in errors)
    (OUT_DIR / "environment_readability_summary.md").write_text("\n".join(lines) + "\n", encoding="utf-8")
    for error in errors:
        print(f"ERROR: {error}")
    return 1 if errors else 0


if __name__ == "__main__":
    raise SystemExit(main())
