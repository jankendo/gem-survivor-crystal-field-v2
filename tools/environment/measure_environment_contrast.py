from __future__ import annotations

from phase5_readability_common import OUT_DIR, image_stats, load_manifest, normalized_luma_delta, res_path, write_json, write_md_table


MIN_FLOOR_WALL = 0.16
MIN_FLOOR_VOID = 0.14
MIN_WALL_VOID = 0.25


def measure() -> dict:
    manifest = load_manifest()
    rows: list[dict] = []
    errors: list[str] = []
    for biome_id, biome in manifest.get("biomes", {}).items():
        surfaces = biome.get("surfaces", {})
        stats = {
            surface: image_stats(res_path(entry["albedo_path"]))
            for surface, entry in surfaces.items()
            if surface in ("floor", "wall", "void")
        }
        floor_wall = normalized_luma_delta(stats["floor"]["luma"], stats["wall"]["luma"])
        floor_void = normalized_luma_delta(stats["floor"]["luma"], stats["void"]["luma"])
        wall_void = normalized_luma_delta(stats["wall"]["luma"], stats["void"]["luma"])
        row = {
            "biome": biome_id,
            "floor_luma": round(stats["floor"]["luma"], 2),
            "wall_luma": round(stats["wall"]["luma"], 2),
            "void_luma": round(stats["void"]["luma"], 2),
            "floor_wall_delta": round(floor_wall, 3),
            "floor_void_delta": round(floor_void, 3),
            "wall_void_delta": round(wall_void, 3),
            "pass": floor_wall >= MIN_FLOOR_WALL and floor_void >= MIN_FLOOR_VOID and wall_void >= MIN_WALL_VOID,
        }
        rows.append(row)
        if floor_wall < MIN_FLOOR_WALL:
            errors.append(f"{biome_id}: floor/wall luma delta {floor_wall:.3f} < {MIN_FLOOR_WALL}")
        if floor_void < MIN_FLOOR_VOID:
            errors.append(f"{biome_id}: floor/void luma delta {floor_void:.3f} < {MIN_FLOOR_VOID}")
        if wall_void < MIN_WALL_VOID:
            errors.append(f"{biome_id}: wall/void luma delta {wall_void:.3f} < {MIN_WALL_VOID}")
    return {"thresholds": {"floor_wall": MIN_FLOOR_WALL, "floor_void": MIN_FLOOR_VOID, "wall_void": MIN_WALL_VOID}, "rows": rows, "errors": errors}


def main() -> int:
    result = measure()
    write_json(OUT_DIR / "environment_contrast.json", result)
    table_rows = [
        [
            row["biome"],
            str(row["floor_luma"]),
            str(row["wall_luma"]),
            str(row["void_luma"]),
            str(row["floor_wall_delta"]),
            str(row["floor_void_delta"]),
            "OK" if row["pass"] else "NG",
        ]
        for row in result["rows"]
    ]
    write_md_table(
        OUT_DIR / "environment_contrast.md",
        "Phase 5 Environment Contrast",
        [f"- errors: {len(result['errors'])}"],
        ["Biome", "Floor", "Wall", "Void", "Floor/Wall", "Floor/Void", "Status"],
        table_rows,
    )
    for error in result["errors"]:
        print(f"ERROR: {error}")
    return 1 if result["errors"] else 0


if __name__ == "__main__":
    raise SystemExit(main())
