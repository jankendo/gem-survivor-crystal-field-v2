from __future__ import annotations

import json
import sys
from pathlib import Path

from PIL import Image, ImageStat


ROOT = Path(__file__).resolve().parents[2]
MANIFEST = ROOT / "data" / "environment_asset_manifest.json"
SEAM_THRESHOLD = 32.0


def res_path(value: str) -> Path:
    return ROOT / value.removeprefix("res://")


def edge_delta(image: Image.Image) -> float:
    rgb = image.convert("RGB")
    left = rgb.crop((0, 0, 1, rgb.height))
    right = rgb.crop((rgb.width - 1, 0, rgb.width, rgb.height))
    top = rgb.crop((0, 0, rgb.width, 1))
    bottom = rgb.crop((0, rgb.height - 1, rgb.width, rgb.height))
    horizontal = ImageStat.Stat(abs_image(left, right)).mean
    vertical = ImageStat.Stat(abs_image(top, bottom)).mean
    return max(sum(horizontal) / 3.0, sum(vertical) / 3.0)


def abs_image(a: Image.Image, b: Image.Image) -> Image.Image:
    import PIL.ImageChops as Chops

    return Chops.difference(a, b)


def main() -> int:
    manifest = json.loads(MANIFEST.read_text(encoding="utf-8"))
    failures: list[str] = []
    for biome_id, biome in manifest.get("biomes", {}).items():
        for surface_name, entry in biome.get("surfaces", {}).items():
            if not entry.get("seamless", False):
                continue
            path = res_path(entry["albedo_path"])
            with Image.open(path) as image:
                delta = edge_delta(image)
            if delta > SEAM_THRESHOLD:
                failures.append(f"{biome_id}/{surface_name}: seam delta {delta:.2f} exceeds {SEAM_THRESHOLD:.2f}")
    if failures:
        for failure in failures:
            print(f"ERROR: {failure}", file=sys.stderr)
        return 1
    print("Environment tile seams OK.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
