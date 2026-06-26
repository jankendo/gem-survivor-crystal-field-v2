from __future__ import annotations

from PIL import Image, ImageDraw

from phase5_readability_common import OUT_DIR, SURFACE_ORDER, load_manifest, res_path


def main() -> int:
    manifest = load_manifest()
    tile = 128
    margin = 18
    biomes = list(manifest.get("biomes", {}).items())
    sheet = Image.new("RGB", (margin + len(SURFACE_ORDER) * (tile + margin), margin + len(biomes) * (tile + margin)), (18, 18, 20))
    draw = ImageDraw.Draw(sheet)
    for row, (biome_id, biome) in enumerate(biomes):
        y = margin + row * (tile + margin)
        draw.text((2, y + 4), biome_id[:10], fill=(220, 220, 220))
        for col, surface in enumerate(SURFACE_ORDER):
            entry = biome.get("surfaces", {}).get(surface)
            if not entry:
                continue
            x = margin + col * (tile + margin)
            with Image.open(res_path(entry["albedo_path"])) as image:
                thumb = image.convert("L").resize((tile, tile)).convert("RGB")
            sheet.paste(thumb, (x, y))
            draw.rectangle((x, y, x + tile - 1, y + tile - 1), outline=(235, 235, 235))
    OUT_DIR.mkdir(parents=True, exist_ok=True)
    sheet.save(OUT_DIR / "environment_grayscale_contact_sheet.png")
    print(OUT_DIR / "environment_grayscale_contact_sheet.png")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
