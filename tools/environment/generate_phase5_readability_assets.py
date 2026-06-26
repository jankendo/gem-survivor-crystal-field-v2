from __future__ import annotations

import argparse
import hashlib
import json
import math
import random
from datetime import date
from pathlib import Path

from PIL import Image, ImageChops, ImageDraw, ImageFilter

from phase5_readability_common import MANIFEST, ROOT, res_path


SURFACES = ("floor", "wall", "void", "decal")
SURFACE_LUMA = {
    "floor": 58,
    "wall": 122,
    "void": 3,
    "decal": 76,
}


def clamp(value: float) -> int:
    return max(0, min(255, int(round(value))))


def hex_rgb(value: str) -> tuple[int, int, int]:
    raw = value.strip("#")
    return tuple(int(raw[i : i + 2], 16) for i in range(0, 6, 2))


def scale_to_luma(rgb: tuple[int, int, int], target: float) -> tuple[int, int, int]:
    current = max(1.0, rgb[0] * 0.2126 + rgb[1] * 0.7152 + rgb[2] * 0.0722)
    ratio = target / current
    return tuple(clamp(channel * ratio) for channel in rgb)


def blend(a: tuple[int, int, int], b: tuple[int, int, int], t: float) -> tuple[int, int, int]:
    return tuple(clamp(a[i] + (b[i] - a[i]) * t) for i in range(3))


def seamless(image: Image.Image) -> Image.Image:
    shifted = ImageChops.offset(image, image.size[0] // 2, image.size[1] // 2)
    mask = Image.new("L", image.size, 0)
    draw = ImageDraw.Draw(mask)
    draw.rectangle((image.size[0] // 2 - 48, 0, image.size[0] // 2 + 48, image.size[1]), fill=90)
    draw.rectangle((0, image.size[1] // 2 - 48, image.size[0], image.size[1] // 2 + 48), fill=90)
    return Image.composite(image, shifted.filter(ImageFilter.GaussianBlur(0.8)), mask)


def base_noise(size: tuple[int, int], base: tuple[int, int, int], dark: tuple[int, int, int], seed: int, contrast: float) -> Image.Image:
    rng = random.Random(seed)
    image = Image.new("RGBA", size, (*base, 255))
    px = image.load()
    for y in range(size[1]):
        row_wave = math.sin((y + seed % 41) * 0.035) * contrast
        for x in range(size[0]):
            wave = row_wave + math.cos((x - seed % 37) * 0.041) * contrast
            grain = (rng.random() - 0.5) * contrast
            t = max(0.0, min(1.0, 0.42 + wave + grain))
            px[x, y] = (*blend(dark, base, t), 255)
    return image.filter(ImageFilter.GaussianBlur(0.25))


def draw_ridge(draw: ImageDraw.ImageDraw, x: float, y: float, radius: float, color: tuple[int, int, int], edge: tuple[int, int, int], alpha: int) -> None:
    points = [
        (x, y - radius * 1.35),
        (x + radius * 0.70, y - radius * 0.25),
        (x + radius * 0.42, y + radius * 1.10),
        (x - radius * 0.48, y + radius * 1.02),
        (x - radius * 0.75, y - radius * 0.22),
    ]
    draw.polygon(points, fill=(*color, alpha), outline=(*edge, min(255, alpha + 28)))
    draw.line((x, y - radius * 1.18, x + radius * 0.28, y + radius * 0.82), fill=(*edge, min(255, alpha + 45)), width=max(1, int(radius / 9)))


def make_surface(surface: str, palette: dict, seed: int) -> Image.Image:
    size = (512, 512)
    base = scale_to_luma(hex_rgb(palette["base"]), SURFACE_LUMA[surface])
    dark = scale_to_luma(hex_rgb(palette["dark"]), max(5, SURFACE_LUMA[surface] - 34))
    glow = scale_to_luma(hex_rgb(palette["glow"]), 190 if surface == "wall" else 150)
    ore = scale_to_luma(hex_rgb(palette["ore"]), 118 if surface == "wall" else 86)
    if surface == "void":
        image = base_noise(size, scale_to_luma(hex_rgb(palette["dark"]), 3), (0, 0, 1), seed, 0.04)
    elif surface == "wall":
        image = base_noise(size, base, dark, seed, 0.20)
    else:
        image = base_noise(size, base, dark, seed, 0.09)
    draw = ImageDraw.Draw(image, "RGBA")
    rng = random.Random(seed + 700)
    if surface == "floor":
        for x in range(-64, size[0] + 90, 128):
            draw.line((x, -20, x + 68, size[1] + 20), fill=(*glow, 32), width=2)
        for _ in range(18):
            x = rng.randint(0, size[0])
            y = rng.randint(0, size[1])
            draw.line((x - 28, y, x + 28, y + rng.randint(-10, 10)), fill=(*ore, 42), width=2)
    elif surface == "wall":
        for _ in range(30):
            draw_ridge(draw, rng.randint(-20, size[0] + 20), rng.randint(18, size[1] - 8), rng.randint(20, 58), ore, glow, rng.randint(160, 230))
        draw.rectangle((0, size[1] - 58, size[0], size[1]), fill=(0, 0, 0, 88))
    elif surface == "void":
        for _ in range(36):
            x = rng.randint(0, size[0])
            y = rng.randint(0, size[1])
            r = rng.randint(1, 3)
            draw.ellipse((x - r, y - r, x + r, y + r), fill=(*glow, rng.randint(12, 34)))
        for y in range(40, size[1], 148):
            draw.line((-18, y, size[0] + 18, y + rng.randint(-34, 34)), fill=(*glow, 10), width=2)
    else:
        image = Image.new("RGBA", size, (0, 0, 0, 0))
        draw = ImageDraw.Draw(image, "RGBA")
        for _ in range(13):
            draw_ridge(draw, rng.randint(30, size[0] - 30), rng.randint(30, size[1] - 30), rng.randint(7, 18), ore, glow, rng.randint(55, 105))
    if surface != "decal":
        image = seamless(image)
    return image


def make_emission(albedo: Image.Image, surface: str) -> Image.Image:
    gray = albedo.convert("L")
    threshold = 120 if surface == "wall" else 150
    alpha = gray.point(lambda px: int(max(0, px - threshold) * (1.25 if surface == "wall" else 0.55)))
    image = Image.new("RGBA", albedo.size, (80, 220, 255, 0))
    image.putalpha(alpha.filter(ImageFilter.GaussianBlur(1.0)))
    return image


def make_normal(albedo: Image.Image) -> Image.Image:
    gray = albedo.convert("L").filter(ImageFilter.GaussianBlur(0.8))
    dx = ImageChops.subtract(ImageChops.offset(gray, -1, 0), ImageChops.offset(gray, 1, 0))
    dy = ImageChops.subtract(ImageChops.offset(gray, 0, -1), ImageChops.offset(gray, 0, 1))
    normal = Image.new("RGBA", albedo.size, (128, 128, 255, 255))
    px = normal.load()
    xpx = dx.load()
    ypx = dy.load()
    for y in range(albedo.size[1]):
        for x in range(albedo.size[0]):
            px[x, y] = (clamp(128 + xpx[x, y] * 0.30), clamp(128 + ypx[x, y] * 0.30), 255, 255)
    return normal


def make_specular(albedo: Image.Image, surface: str) -> Image.Image:
    strength = 1.25 if surface == "wall" else 0.55
    alpha = albedo.convert("L").point(lambda px: clamp(max(0, px - 80) * strength))
    image = Image.new("RGBA", albedo.size, (255, 255, 255, 255))
    image.putalpha(alpha)
    return image


def sha256(path: Path) -> str:
    return hashlib.sha256(path.read_bytes()).hexdigest()


def write_asset(path: Path, image: Image.Image) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    image.save(path)


def update_manifest(source_generation_path: str) -> dict:
    manifest = json.loads(MANIFEST.read_text(encoding="utf-8"))
    manifest["source_concept_path"] = "res://assets/v2/environment/generated/source/phase5_environment_readability_concept.png"
    manifest["source_generation_path"] = source_generation_path
    manifest["generation_record"] = {
        "generation_date": date.today().isoformat(),
        "source_model_or_tool": "built_in_image_generation_plus_phase5_local_readability_pipeline",
        "human_review_status": "needs_review",
        "legal_review_status": "project_original_no_external_download",
        "approval_state": "generated_unreviewed",
        "prompt_document": "res://docs/asset_generation/v2_environment_readability_batch.md",
    }
    manifest["visibility_contract"] = {
        "pickup_contrast_min": 0.42,
        "enemy_contrast_min": 0.38,
        "floor_wall_luma_delta_min": 0.16,
        "floor_void_luma_delta_min": 0.14,
        "pickup_floor_luma_delta_min": 0.18,
        "ui_overlay_dimming_allowed": True,
        "max_albedo_average_luma": 145,
    }
    for biome_index, (biome_id, biome) in enumerate(manifest.get("biomes", {}).items()):
        palette = biome.get("palette", {})
        for surface_index, surface in enumerate(SURFACES):
            entry = biome.get("surfaces", {}).get(surface)
            if not entry:
                continue
            albedo = make_surface(surface, palette, 50500 + biome_index * 19 + surface_index * 5)
            paths = {
                "albedo_path": res_path(entry["albedo_path"]),
                "normal_path": res_path(entry["normal_path"]),
                "specular_path": res_path(entry["specular_path"]),
                "emission_path": res_path(entry["emission_path"]),
            }
            write_asset(paths["albedo_path"], albedo)
            write_asset(paths["normal_path"], make_normal(albedo))
            write_asset(paths["specular_path"], make_specular(albedo, surface))
            write_asset(paths["emission_path"], make_emission(albedo, surface))
            entry["checksum"] = sha256(paths["albedo_path"])
            entry["human_review_status"] = "needs_review"
            entry["replacement_status"] = "integrated"
            with Image.open(paths["albedo_path"]) as image:
                pixel = image.convert("RGB").resize((1, 1)).getpixel((0, 0))
            entry["fallback_color"] = [int(pixel[0]), int(pixel[1]), int(pixel[2])]
    MANIFEST.write_text(json.dumps(manifest, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    return manifest


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--source-generation-path", default="")
    args = parser.parse_args()
    source = args.source_generation_path or "C:/Users/janke/.codex/generated_images/019ef2b2-15a4-7b60-bc36-67a441e2a33c/ig_0019202507a009ad016a3dfd86c43c8191badb18bf2f2d813c.png"
    update_manifest(source)
    print("Phase 5 readability assets generated.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
