from __future__ import annotations

from PIL import Image, ImageDraw

from phase5_readability_common import OUT_DIR, SURFACE_ORDER, load_manifest, res_path


MATRICES = {
    "normal": ((1.0, 0.0, 0.0), (0.0, 1.0, 0.0), (0.0, 0.0, 1.0)),
    "protan": ((0.57, 0.43, 0.0), (0.56, 0.44, 0.0), (0.0, 0.24, 0.76)),
    "deutan": ((0.62, 0.38, 0.0), (0.70, 0.30, 0.0), (0.0, 0.30, 0.70)),
    "tritan": ((0.95, 0.05, 0.0), (0.0, 0.43, 0.57), (0.0, 0.48, 0.52)),
}


def transform(image: Image.Image, matrix: tuple[tuple[float, float, float], ...]) -> Image.Image:
    rgb = image.convert("RGB")
    pixels = rgb.load()
    for y in range(rgb.size[1]):
        for x in range(rgb.size[0]):
            r, g, b = pixels[x, y]
            pixels[x, y] = (
                int(min(255, r * matrix[0][0] + g * matrix[0][1] + b * matrix[0][2])),
                int(min(255, r * matrix[1][0] + g * matrix[1][1] + b * matrix[1][2])),
                int(min(255, r * matrix[2][0] + g * matrix[2][1] + b * matrix[2][2])),
            )
    return rgb


def main() -> int:
    manifest = load_manifest()
    tile = 96
    margin = 16
    biomes = list(manifest.get("biomes", {}).items())
    width = margin + len(SURFACE_ORDER) * (tile + margin)
    height = margin + len(biomes) * len(MATRICES) * (tile + margin)
    sheet = Image.new("RGB", (width, height), (18, 18, 20))
    draw = ImageDraw.Draw(sheet)
    row = 0
    for biome_id, biome in biomes:
        for mode, matrix in MATRICES.items():
            y = margin + row * (tile + margin)
            draw.text((2, y + 4), f"{biome_id[:7]} {mode}", fill=(230, 230, 230))
            for col, surface in enumerate(SURFACE_ORDER):
                entry = biome.get("surfaces", {}).get(surface)
                if not entry:
                    continue
                x = margin + col * (tile + margin)
                with Image.open(res_path(entry["albedo_path"])) as image:
                    thumb = transform(image.resize((tile, tile)), matrix)
                sheet.paste(thumb, (x, y))
                draw.rectangle((x, y, x + tile - 1, y + tile - 1), outline=(235, 235, 235))
            row += 1
    OUT_DIR.mkdir(parents=True, exist_ok=True)
    sheet.save(OUT_DIR / "environment_colorblind_contact_sheet.png")
    print(OUT_DIR / "environment_colorblind_contact_sheet.png")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
