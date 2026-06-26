from __future__ import annotations

from phase5_readability_common import (
    OUT_DIR,
    image_stats,
    load_manifest,
    normalized_luma_delta,
    normalized_rgb_distance,
    pickup_colors,
    res_path,
    write_json,
    write_md_table,
)


MIN_LUMA_DELTA = 0.18
MIN_RGB_DISTANCE = 0.20


def audit() -> dict:
    manifest = load_manifest()
    pickups = pickup_colors()
    rows: list[dict] = []
    errors: list[str] = []
    for biome_id, biome in manifest.get("biomes", {}).items():
        floor = image_stats(res_path(biome["surfaces"]["floor"]["albedo_path"]))
        decal = image_stats(res_path(biome["surfaces"]["decal"]["albedo_path"]))
        for pickup in pickups:
            floor_luma = normalized_luma_delta(pickup["luma"], floor["luma"])
            decal_luma = normalized_luma_delta(pickup["luma"], decal["luma"])
            floor_rgb = normalized_rgb_distance(pickup["rgb"], floor["rgb"])
            decal_rgb = normalized_rgb_distance(pickup["rgb"], decal["rgb"])
            confused = (floor_luma < MIN_LUMA_DELTA and floor_rgb < MIN_RGB_DISTANCE) or (decal_luma < MIN_LUMA_DELTA and decal_rgb < MIN_RGB_DISTANCE)
            row = {
                "biome": biome_id,
                "pickup": pickup["id"],
                "floor_luma_delta": round(floor_luma, 3),
                "floor_rgb_distance": round(floor_rgb, 3),
                "decal_luma_delta": round(decal_luma, 3),
                "decal_rgb_distance": round(decal_rgb, 3),
                "pass": not confused,
            }
            rows.append(row)
            if confused:
                errors.append(f"{biome_id}/{pickup['id']}: pickup is too close to floor or decal")
    return {"thresholds": {"luma_delta": MIN_LUMA_DELTA, "rgb_distance": MIN_RGB_DISTANCE}, "rows": rows, "errors": errors}


def main() -> int:
    result = audit()
    write_json(OUT_DIR / "collectible_confusion.json", result)
    write_md_table(
        OUT_DIR / "collectible_confusion.md",
        "Phase 5 Collectible Confusion Audit",
        [f"- checked_pairs: {len(result['rows'])}", f"- errors: {len(result['errors'])}"],
        ["Biome", "Pickup", "Floor Luma", "Floor RGB", "Decal Luma", "Decal RGB", "Status"],
        [
            [
                row["biome"],
                row["pickup"],
                str(row["floor_luma_delta"]),
                str(row["floor_rgb_distance"]),
                str(row["decal_luma_delta"]),
                str(row["decal_rgb_distance"]),
                "OK" if row["pass"] else "NG",
            ]
            for row in result["rows"]
        ],
    )
    for error in result["errors"]:
        print(f"ERROR: {error}")
    return 1 if result["errors"] else 0


if __name__ == "__main__":
    raise SystemExit(main())
