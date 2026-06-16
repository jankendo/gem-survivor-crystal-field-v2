from __future__ import annotations

import hashlib
import json
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
MANIFEST_PATH = ROOT / "tools" / "asset_generation_manifest.json"


def stable_color(key: str, salt: int = 0) -> str:
    digest = hashlib.sha256(f"{key}:{salt}".encode("utf-8")).digest()
    hue = digest[0] / 255.0
    sat = 0.58 + digest[1] / 255.0 * 0.30
    val = 0.72 + digest[2] / 255.0 * 0.23
    return hsv_to_hex(hue, sat, val)


def hsv_to_hex(h: float, s: float, v: float) -> str:
    i = int(h * 6.0)
    f = h * 6.0 - i
    p = v * (1.0 - s)
    q = v * (1.0 - f * s)
    t = v * (1.0 - (1.0 - f) * s)
    values = [(v, t, p), (q, v, p), (p, v, t), (p, q, v), (t, p, v), (v, p, q)][i % 6]
    return "#%02x%02x%02x" % tuple(max(0, min(255, int(round(c * 255)))) for c in values)


def svg_for(category: str, asset_id: str, display_name: str) -> str:
    primary = stable_color(f"{category}:{asset_id}", 0)
    accent = stable_color(f"{category}:{asset_id}", 1)
    glow = stable_color(f"{category}:{asset_id}", 2)
    shape = int(hashlib.sha256(asset_id.encode("utf-8")).hexdigest()[:2], 16) % 5
    glyph = "".join(part[:1] for part in asset_id.split("_")[:2]).upper()[:2] or "G"
    silhouette = [
        f'<path d="M64 10 L108 38 L96 106 L64 122 L32 106 L20 38 Z" fill="{primary}" stroke="{accent}" stroke-width="5"/>',
        f'<circle cx="64" cy="62" r="42" fill="{primary}" stroke="{accent}" stroke-width="6"/><path d="M28 88 C50 112 82 112 100 86" fill="none" stroke="{glow}" stroke-width="7"/>',
        f'<rect x="22" y="20" width="84" height="88" rx="20" fill="{primary}" stroke="{accent}" stroke-width="5"/><path d="M36 42 H92 M36 66 H92 M36 90 H78" stroke="{glow}" stroke-width="7"/>',
        f'<path d="M64 8 C96 22 112 56 94 108 H34 C16 56 32 22 64 8 Z" fill="{primary}" stroke="{accent}" stroke-width="5"/>',
        f'<path d="M64 12 L92 24 L116 64 L92 104 L64 116 L36 104 L12 64 L36 24 Z" fill="{primary}" stroke="{accent}" stroke-width="5"/>',
    ][shape]
    if category in {"characters", "enemies", "bosses"}:
        center = '<circle cx="54" cy="56" r="5" fill="#071126"/><circle cx="76" cy="56" r="5" fill="#071126"/><path d="M46 82 Q64 96 82 82" fill="none" stroke="#f8fbff" stroke-width="5" opacity="0.70"/>'
    else:
        center = f'<text x="64" y="77" text-anchor="middle" font-family="Arial, sans-serif" font-size="31" font-weight="700" fill="#f8fbff">{glyph}</text>'
    title = display_name.replace("&", "&amp;").replace("<", "&lt;").replace(">", "&gt;")
    return f'''<svg xmlns="http://www.w3.org/2000/svg" width="128" height="128" viewBox="0 0 128 128">
<title>{title}</title>
<defs>
  <radialGradient id="g" cx="50%" cy="42%" r="62%">
    <stop offset="0%" stop-color="#ffffff" stop-opacity="0.88"/>
    <stop offset="46%" stop-color="{glow}" stop-opacity="0.32"/>
    <stop offset="100%" stop-color="#071126" stop-opacity="0.00"/>
  </radialGradient>
  <filter id="shadow" x="-20%" y="-20%" width="140%" height="140%">
    <feDropShadow dx="0" dy="5" stdDeviation="5" flood-color="#020617" flood-opacity="0.55"/>
  </filter>
</defs>
<rect width="128" height="128" rx="18" fill="#071126"/>
<circle cx="64" cy="64" r="58" fill="url(#g)"/>
<g filter="url(#shadow)">
{silhouette}
{center}
</g>
<path d="M18 110 C42 96 84 122 110 94" fill="none" stroke="{glow}" stroke-width="4" opacity="0.48"/>
</svg>
'''


def load_json(path: Path) -> dict:
    return json.loads(path.read_text(encoding="utf-8"))


def write_json(path: Path, data: dict) -> None:
    path.write_text(json.dumps(data, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")


def rows_from(data: dict, spec: dict):
    if "array_key" in spec:
        for item in data.get(spec["array_key"], []):
            if isinstance(item, dict) and item.get("id"):
                yield StringKey(str(item["id"])), item
        return
    skip = set(spec.get("skip_keys", []))
    for key, value in data.items():
        if key in skip or not isinstance(value, dict):
            continue
        yield StringKey(str(key)), value


class StringKey(str):
    pass


def update_array_data(data: dict, spec: dict, category: str, output_root: Path, field: str) -> int:
    count = 0
    for item in data.get(spec["array_key"], []):
        if not isinstance(item, dict) or not item.get("id"):
            continue
        asset_id = str(item["id"])
        path = output_root / category / f"{asset_id}.svg"
        name = str(item.get("name_ja", item.get("title_ja", asset_id)))
        path.parent.mkdir(parents=True, exist_ok=True)
        path.write_text(svg_for(category, asset_id, name), encoding="utf-8")
        item[field] = f"res://assets/generated/{category}/{asset_id}.svg"
        count += 1
    return count


def update_dict_data(data: dict, spec: dict, category: str, output_root: Path, field: str) -> int:
    skip = set(spec.get("skip_keys", []))
    count = 0
    for asset_id, item in data.items():
        if asset_id in skip or not isinstance(item, dict):
            continue
        path = output_root / category / f"{asset_id}.svg"
        name = str(item.get("name_ja", asset_id))
        path.parent.mkdir(parents=True, exist_ok=True)
        path.write_text(svg_for(category, str(asset_id), name), encoding="utf-8")
        item[field] = f"res://assets/generated/{category}/{asset_id}.svg"
        count += 1
    return count


def main() -> int:
    manifest = load_json(MANIFEST_PATH)
    output_root = ROOT / manifest["output_root"]
    output_root.mkdir(parents=True, exist_ok=True)
    generated = {}
    for category, spec in manifest["categories"].items():
        data_path = ROOT / spec["data"]
        data = load_json(data_path)
        field = spec["field"]
        if "array_key" in spec:
            count = update_array_data(data, spec, category, output_root, field)
        else:
            count = update_dict_data(data, spec, category, output_root, field)
        write_json(data_path, data)
        generated[category] = count
    print(json.dumps({"generated": generated}, ensure_ascii=False, indent=2))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
