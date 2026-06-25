from __future__ import annotations

import json
import sys
from pathlib import Path


ROOT = Path(__file__).resolve().parents[2]
MANIFEST = ROOT / "data" / "environment_asset_manifest.json"


def res_path(value: str) -> Path:
    return ROOT / value.removeprefix("res://")


def main() -> int:
    manifest = json.loads(MANIFEST.read_text(encoding="utf-8"))
    missing: list[str] = []
    for biome in manifest.get("biomes", {}).values():
        for entry in biome.get("surfaces", {}).values():
            for key in ("albedo_path", "normal_path", "specular_path", "emission_path"):
                path = res_path(str(entry.get(key, "")))
                import_path = Path(str(path) + ".import")
                if not import_path.exists():
                    missing.append(str(import_path.relative_to(ROOT)))
    if missing:
        for item in missing:
            print(f"ERROR: missing import file: {item}", file=sys.stderr)
        print("Run Godot editor import once before this audit.", file=sys.stderr)
        return 1
    print("Environment texture import sidecars OK.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
