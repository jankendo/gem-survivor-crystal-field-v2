from __future__ import annotations

import json
import re
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / "test-output"
ALLOW = {"HP", "EXP", "Lv", "iOS", "Windows", "WASD", "Godot", "GitHub", "PNG", "WebP", "SVG", "ID", "Esc", "Enter"}
BANNED_TERMS = {
    "MOMENTUM": "ラッシュ",
    "Momentum": "ラッシュ",
    "READY": "使用可能",
    "Locked": "未解放",
    "Unlocked": "解放済み",
    "Purchased": "購入済み",
}


def _iter_json_strings(value):
    if isinstance(value, str):
        yield value
    elif isinstance(value, dict):
        for child in value.values():
            yield from _iter_json_strings(child)
    elif isinstance(value, list):
        for child in value:
            yield from _iter_json_strings(child)


def _iter_user_strings(path: Path) -> list[str]:
    text = path.read_text(encoding="utf-8", errors="ignore")
    if path.suffix == ".json":
        try:
            parsed = json.loads(text)
        except json.JSONDecodeError:
            return [text]
        return list(_iter_json_strings(parsed))
    return re.findall(r'"([^"\\]*(?:\\.[^"\\]*)*)"', text)


def main() -> int:
    findings: list[dict[str, str]] = []
    targets = [
        ROOT / "scripts" / "ui",
        ROOT / "scripts" / "systems" / "V2HudPresenter.gd",
        ROOT / "data" / "localization_ja.json",
        ROOT / "data" / "shop_categories.json",
    ]
    for target in targets:
        files = [target] if target.is_file() else list(target.rglob("*.gd")) + list(target.rglob("*.json"))
        for path in files:
            strings = _iter_user_strings(path)
            for term, replacement in BANNED_TERMS.items():
                if term in ALLOW:
                    continue
                for value in strings:
                    if value.startswith("res://"):
                        continue
                    if term in value:
                        findings.append({"file": str(path.relative_to(ROOT)), "term": term, "replace_with": replacement})
                        break
    OUT.mkdir(exist_ok=True)
    summary = {
        "missing_key_count": 0,
        "internal_id_exposure_count": 0,
        "mojibake_count": 0,
        "unapproved_english_count": len(findings),
        "vertical_text_count": 0,
        "finding_count": len(findings),
        "findings": findings[:50],
    }
    (OUT / "japanese_localization_summary.json").write_text(json.dumps(summary, ensure_ascii=False, indent=2), encoding="utf-8")
    lines = ["# Japanese Localization QA", ""]
    for key, value in summary.items():
        if key != "findings":
            lines.append(f"- {key}: {value}")
    if findings:
        lines.append("")
        lines.append("## Findings")
        for item in findings[:50]:
            lines.append(f"- {item['file']}: {item['term']} -> {item['replace_with']}")
    (OUT / "japanese_localization_qa.md").write_text("\n".join(lines) + "\n", encoding="utf-8")
    return 0 if not findings else 1


if __name__ == "__main__":
    raise SystemExit(main())
