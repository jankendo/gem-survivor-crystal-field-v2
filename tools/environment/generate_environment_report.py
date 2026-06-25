from __future__ import annotations

import json
from pathlib import Path

from PIL import Image, ImageStat


ROOT = Path(__file__).resolve().parents[2]
OUT = ROOT / "test-output"
MANIFEST = ROOT / "data" / "environment_asset_manifest.json"
QUALITY = ROOT / "data" / "environment_visual_quality.json"


def res_path(value: str) -> Path:
    return ROOT / value.removeprefix("res://")


def luma(path: Path) -> float:
    with Image.open(path) as image:
        return ImageStat.Stat(image.convert("L")).mean[0]


def main() -> int:
    OUT.mkdir(parents=True, exist_ok=True)
    manifest = json.loads(MANIFEST.read_text(encoding="utf-8"))
    quality = json.loads(QUALITY.read_text(encoding="utf-8"))
    rows = []
    max_bytes = 0
    for biome_id, biome in manifest.get("biomes", {}).items():
        for surface_name, entry in biome.get("surfaces", {}).items():
            path = res_path(entry["albedo_path"])
            max_bytes = max(max_bytes, path.stat().st_size)
            rows.append(
                {
                    "biome": biome_id,
                    "surface": surface_name,
                    "path": entry["albedo_path"],
                    "bytes": path.stat().st_size,
                    "luma": round(luma(path), 2),
                    "walkable": bool(entry.get("walkable", False)),
                    "seamless": bool(entry.get("seamless", False)),
                    "status": entry.get("replacement_status"),
                    "human_review_status": entry.get("human_review_status"),
                }
            )
    summary = {
        "biome_count": len(manifest.get("biomes", {})),
        "surface_count": len(rows),
        "max_albedo_bytes": max_bytes,
        "quality_profiles": sorted(quality.get("profiles", {}).keys()),
        "source_concept_path": manifest.get("source_concept_path", ""),
        "human_review_status": manifest.get("generation_record", {}).get("human_review_status", ""),
    }
    (OUT / "environment_asset_qa.json").write_text(json.dumps({"summary": summary, "rows": rows}, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    (OUT / "environment_performance_qa.json").write_text(json.dumps({"budgets": quality.get("budgets", {}), "profiles": quality.get("profiles", {})}, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    (OUT / "environment_visual_contract_qa.json").write_text(json.dumps({"visibility_contract": manifest.get("visibility_contract", {}), "collision_visual_contract": manifest.get("collision_visual_contract", {})}, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    write_md(OUT / "environment_asset_qa.md", "# Environment Asset QA", summary, rows)
    write_md(OUT / "environment_performance_qa.md", "# Environment Performance QA", quality.get("budgets", {}), [])
    write_md(OUT / "environment_visual_contract_qa.md", "# Environment Visual Contract QA", manifest.get("visibility_contract", {}), rows)
    remaining = [
        "# Phase 4 Remaining Issues",
        "",
        "- iOS実機でのSafe Areaと動画レビューは、このWindows環境では未実施です。",
        "- 生成環境アートはhuman_review_status=needs_reviewです。公開前に人間レビューでapproved/rejectedを記録してください。",
    ]
    (OUT / "phase4_remaining_issues.md").write_text("\n".join(remaining) + "\n", encoding="utf-8")
    print("Environment QA reports generated.")
    return 0


def write_md(path: Path, title: str, summary: dict, rows: list[dict]) -> None:
    lines = [title, ""]
    for key, value in summary.items():
        lines.append(f"- {key}: {value}")
    if rows:
        lines.extend(["", "| Biome | Surface | Luma | Bytes | Status |", "| --- | --- | ---: | ---: | --- |"])
        for row in rows:
            lines.append(f"| {row['biome']} | {row['surface']} | {row['luma']} | {row['bytes']} | {row['status']} / {row['human_review_status']} |")
    path.write_text("\n".join(lines) + "\n", encoding="utf-8")


if __name__ == "__main__":
    raise SystemExit(main())
