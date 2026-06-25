from __future__ import annotations

import json
import sys
from pathlib import Path

from PIL import Image


ROOT = Path(__file__).resolve().parents[2]
MANIFEST = ROOT / "data" / "environment_asset_manifest.json"
EXPECTED_BIOMES = {"star_plain", "amethyst_forest", "red_mine", "void_zone"}
EXPECTED_SURFACES = {"floor", "wall", "void", "decal"}
MATERIAL_KEYS = ("albedo_path", "normal_path", "specular_path", "emission_path")


def res_path(value: str) -> Path:
    if not value.startswith("res://"):
        raise ValueError(f"not a res:// path: {value}")
    return ROOT / value.removeprefix("res://")


def validate() -> list[str]:
    errors: list[str] = []
    if not MANIFEST.exists():
        return [f"missing manifest: {MANIFEST}"]
    manifest = json.loads(MANIFEST.read_text(encoding="utf-8"))
    biomes = manifest.get("biomes", {})
    missing_biomes = EXPECTED_BIOMES - set(biomes)
    if missing_biomes:
        errors.append(f"missing biomes: {sorted(missing_biomes)}")
    source = str(manifest.get("source_concept_path", ""))
    if source and not res_path(source).exists():
        errors.append(f"source concept missing: {source}")
    for biome_id, biome in biomes.items():
        surfaces = biome.get("surfaces", {})
        missing_surfaces = EXPECTED_SURFACES - set(surfaces)
        if missing_surfaces:
            errors.append(f"{biome_id}: missing surfaces {sorted(missing_surfaces)}")
        for surface_name, entry in surfaces.items():
            if entry.get("replacement_status") != "integrated":
                errors.append(f"{biome_id}/{surface_name}: replacement_status must be integrated")
            if entry.get("human_review_status") != "needs_review":
                errors.append(f"{biome_id}/{surface_name}: human_review_status must be needs_review")
            sizes: set[tuple[int, int]] = set()
            for key in MATERIAL_KEYS:
                try:
                    path = res_path(str(entry.get(key, "")))
                except ValueError as exc:
                    errors.append(f"{biome_id}/{surface_name}: {exc}")
                    continue
                if not path.exists():
                    errors.append(f"{biome_id}/{surface_name}: missing {key}: {path}")
                    continue
                with Image.open(path) as image:
                    sizes.add(image.size)
                    if image.size != (512, 512):
                        errors.append(f"{biome_id}/{surface_name}: {key} must be 512x512, got {image.size}")
            if len(sizes) > 1:
                errors.append(f"{biome_id}/{surface_name}: material maps have mismatched sizes {sorted(sizes)}")
    return errors


def main() -> int:
    errors = validate()
    if errors:
        for error in errors:
            print(f"ERROR: {error}", file=sys.stderr)
        return 1
    print("Environment asset manifest OK.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
