from __future__ import annotations

import json
import sys
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
MANIFEST_PATH = ROOT / "tools" / "asset_generation_manifest.json"
REPORT_PATH = ROOT / "test-output" / "asset_qa_report.md"


def load_json(path: Path) -> dict:
    return json.loads(path.read_text(encoding="utf-8"))


def iter_items(data: dict, spec: dict):
    if "array_key" in spec:
        for item in data.get(spec["array_key"], []):
            if isinstance(item, dict) and item.get("id"):
                yield str(item["id"]), item
        return
    skip = set(spec.get("skip_keys", []))
    for key, value in data.items():
        if key in skip or not isinstance(value, dict):
            continue
        yield str(key), value


def main() -> int:
    manifest = load_json(MANIFEST_PATH)
    failures = []
    rows = []
    for category, spec in manifest["categories"].items():
        data_path = ROOT / spec["data"]
        data = load_json(data_path)
        field = spec["field"]
        checked = 0
        for asset_id, item in iter_items(data, spec):
            checked += 1
            ref = str(item.get(field, ""))
            if not ref.startswith("res://assets/generated/"):
                failures.append(f"{category}:{asset_id} missing {field}")
                continue
            path = ROOT / ref.replace("res://", "")
            if not path.is_file():
                failures.append(f"{category}:{asset_id} missing file {ref}")
                continue
            text = path.read_text(encoding="utf-8")
            if "<svg" not in text or "</svg>" not in text:
                failures.append(f"{category}:{asset_id} invalid svg {ref}")
        rows.append((category, checked))
    REPORT_PATH.parent.mkdir(parents=True, exist_ok=True)
    report = [
        "# Asset QA Report",
        "",
        "Generated assets are local procedural SVG files under `assets/generated`.",
        "",
        "| Category | Checked |",
        "| --- | ---: |",
    ]
    report += [f"| {category} | {checked} |" for category, checked in rows]
    report += ["", f"Failures: {len(failures)}"]
    if failures:
        report += ["", "## Failures"] + [f"- {failure}" for failure in failures]
    REPORT_PATH.write_text("\n".join(report) + "\n", encoding="utf-8")
    if failures:
        print("\n".join(failures), file=sys.stderr)
        return 1
    print(f"Generated asset validation passed: {sum(checked for _, checked in rows)} assets")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
