from __future__ import annotations

import json
from pathlib import Path

from PIL import Image, ImageStat


ROOT = Path(__file__).resolve().parents[2]
MANIFEST = ROOT / "data" / "environment_asset_manifest.json"
FIELD_DROPS = ROOT / "data" / "field_drops.json"
OUT_DIR = ROOT / "test-output" / "phase5"
SURFACE_ORDER = ("floor", "wall", "void", "decal")


def res_path(value: str) -> Path:
    if not value.startswith("res://"):
        raise ValueError(f"not a res:// path: {value}")
    return ROOT / value.removeprefix("res://")


def load_json(path: Path) -> dict:
    return json.loads(path.read_text(encoding="utf-8"))


def load_manifest() -> dict:
    return load_json(MANIFEST)


def surface_entries(manifest: dict | None = None) -> list[dict]:
    manifest = manifest or load_manifest()
    rows: list[dict] = []
    for biome_id, biome in manifest.get("biomes", {}).items():
        surfaces = biome.get("surfaces", {})
        for surface in SURFACE_ORDER:
            if surface not in surfaces:
                continue
            entry = dict(surfaces[surface])
            entry["biome"] = biome_id
            entry["biome_name_ja"] = biome.get("name_ja", biome_id)
            entry["surface"] = surface
            rows.append(entry)
    return rows


def image_stats(path: Path) -> dict:
    with Image.open(path) as image:
        rgba = image.convert("RGBA")
        rgb = rgba.convert("RGB")
        luma = ImageStat.Stat(rgb.convert("L")).mean[0]
        mean = ImageStat.Stat(rgb).mean
        alpha = ImageStat.Stat(rgba.getchannel("A")).mean[0]
    return {
        "luma": float(luma),
        "rgb": [float(mean[0]), float(mean[1]), float(mean[2])],
        "alpha": float(alpha),
    }


def normalized_luma_delta(a: float, b: float) -> float:
    return abs(float(a) - float(b)) / 255.0


def normalized_rgb_distance(a: list[float], b: list[float]) -> float:
    return sum((float(a[i]) - float(b[i])) ** 2 for i in range(3)) ** 0.5 / 441.67295593


def pickup_colors() -> list[dict]:
    data = load_json(FIELD_DROPS)
    rows: list[dict] = []
    for drop_id, entry in data.items():
        if drop_id.startswith("_") or not isinstance(entry, dict):
            continue
        color = entry.get("color")
        if not isinstance(color, list) or len(color) < 3:
            continue
        rgb = [float(color[0]) * 255.0, float(color[1]) * 255.0, float(color[2]) * 255.0]
        luma = rgb[0] * 0.2126 + rgb[1] * 0.7152 + rgb[2] * 0.0722
        rows.append({"id": drop_id, "name_ja": entry.get("name_ja", drop_id), "rgb": rgb, "luma": luma})
    return rows


def write_json(path: Path, payload: dict) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(json.dumps(payload, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")


def write_md_table(path: Path, title: str, summary: list[str], headers: list[str], rows: list[list[str]]) -> None:
    lines = [f"# {title}", ""]
    lines.extend(summary)
    if rows:
        lines.extend(["", "| " + " | ".join(headers) + " |", "| " + " | ".join(["---"] * len(headers)) + " |"])
        for row in rows:
            lines.append("| " + " | ".join(row) + " |")
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text("\n".join(lines) + "\n", encoding="utf-8")
