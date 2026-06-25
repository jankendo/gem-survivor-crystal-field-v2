from __future__ import annotations

import hashlib
import json
import math
import random
from pathlib import Path

from PIL import Image, ImageChops, ImageDraw, ImageFilter


ROOT = Path(__file__).resolve().parents[2]
ASSET_ROOT = ROOT / "assets" / "v2" / "environment"
DOC_DIR = ROOT / "docs" / "asset_generation"
DATA_DIR = ROOT / "data"
SOURCE_CONCEPT = ASSET_ROOT / "generated" / "source" / "phase4_environment_master_concept.png"


BIOMES = {
    "star_plain": {
        "name_ja": "星屑平原",
        "base": "#10253a",
        "dark": "#06111f",
        "glow": "#55dfff",
        "accent": "#d5fbff",
        "ore": "#2a83b5",
    },
    "amethyst_forest": {
        "name_ja": "紫晶の森",
        "base": "#211839",
        "dark": "#0b0718",
        "glow": "#a66cff",
        "accent": "#f0dcff",
        "ore": "#6f37c4",
    },
    "red_mine": {
        "name_ja": "赤熱鉱床",
        "base": "#2a1716",
        "dark": "#100809",
        "glow": "#ff584e",
        "accent": "#ffd0a0",
        "ore": "#9b2a26",
    },
    "void_zone": {
        "name_ja": "虚無領域",
        "base": "#121226",
        "dark": "#05030c",
        "glow": "#a42cff",
        "accent": "#f0d7ff",
        "ore": "#4e2475",
    },
}

SURFACES = {
    "floor": {"resolution": (512, 512), "usage": "walkable_floor", "walkable": True, "seamless": True},
    "wall": {"resolution": (512, 512), "usage": "collision_wall_visual", "walkable": False, "seamless": True},
    "void": {"resolution": (512, 512), "usage": "non_walkable_boundary_visual", "walkable": False, "seamless": True},
    "decal": {"resolution": (512, 512), "usage": "non_collision_small_decals", "walkable": True, "seamless": False},
}


def hex_to_rgba(value: str, alpha: int = 255) -> tuple[int, int, int, int]:
    raw = value.strip("#")
    return tuple(int(raw[i : i + 2], 16) for i in range(0, 6, 2)) + (alpha,)


def ensure(path: Path) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)


def sha256(path: Path) -> str:
    return hashlib.sha256(path.read_bytes()).hexdigest()


def blend(a: tuple[int, int, int, int], b: tuple[int, int, int, int], t: float) -> tuple[int, int, int, int]:
    return tuple(int(a[i] + (b[i] - a[i]) * t) for i in range(4))


def noise_layer(size: tuple[int, int], seed: int, base: tuple[int, int, int, int], dark: tuple[int, int, int, int]) -> Image.Image:
    rng = random.Random(seed)
    img = Image.new("RGBA", size, dark)
    px = img.load()
    for y in range(size[1]):
        for x in range(size[0]):
            wave = (math.sin((x + seed % 37) * 0.045) + math.cos((y - seed % 29) * 0.052)) * 0.5
            grain = rng.random() * 0.32
            t = max(0.0, min(1.0, 0.44 + wave * 0.12 + grain))
            px[x, y] = blend(dark, base, t)
    return img.filter(ImageFilter.GaussianBlur(0.35))


def draw_crystal(draw: ImageDraw.ImageDraw, cx: float, cy: float, radius: float, color: tuple[int, int, int, int], accent: tuple[int, int, int, int]) -> None:
    points = []
    for i in range(6):
        angle = -math.pi / 2 + math.tau * i / 6.0
        stretch = 1.38 if i in (0, 3) else 0.86
        points.append((cx + math.cos(angle) * radius, cy + math.sin(angle) * radius * stretch))
    draw.polygon(points, fill=color, outline=accent)
    draw.line((cx, cy - radius * 1.25, cx + radius * 0.42, cy + radius * 0.52), fill=accent, width=max(1, int(radius / 8)))


def make_floor(biome_id: str, palette: dict, seed: int) -> Image.Image:
    size = SURFACES["floor"]["resolution"]
    img = noise_layer(size, seed, hex_to_rgba(palette["base"]), hex_to_rgba(palette["dark"]))
    draw = ImageDraw.Draw(img, "RGBA")
    rng = random.Random(seed)
    glow = hex_to_rgba(palette["glow"], 110)
    accent = hex_to_rgba(palette["accent"], 150)
    for gx in range(-32, size[0] + 64, 96):
        draw.line((gx, -16, gx + 84, size[1] + 16), fill=(*glow[:3], 44), width=2)
    for gy in range(0, size[1] + 64, 96):
        draw.line((-16, gy, size[0] + 16, gy - 56), fill=(*accent[:3], 22), width=1)
    for _ in range(22):
        x = rng.randint(0, size[0] - 1)
        y = rng.randint(0, size[1] - 1)
        r = rng.randint(4, 13)
        draw_crystal(draw, x, y, r, hex_to_rgba(palette["ore"], rng.randint(80, 140)), hex_to_rgba(palette["glow"], rng.randint(110, 190)))
    if biome_id == "red_mine":
        for _ in range(10):
            y = rng.randint(16, size[1] - 16)
            draw.line((-20, y, size[0] + 20, y + rng.randint(-36, 36)), fill=(255, 65, 38, 86), width=3)
    if biome_id == "amethyst_forest":
        for _ in range(12):
            x = rng.randint(0, size[0])
            y = rng.randint(0, size[1])
            draw.arc((x - 58, y - 34, x + 58, y + 34), 10, 230, fill=(72, 36, 88, 130), width=5)
    if biome_id == "void_zone":
        for _ in range(28):
            x = rng.randint(0, size[0])
            y = rng.randint(0, size[1])
            draw.ellipse((x - 2, y - 2, x + 2, y + 2), fill=hex_to_rgba(palette["glow"], rng.randint(70, 150)))
    return _make_seamless(img)


def make_wall(palette: dict, seed: int) -> Image.Image:
    size = SURFACES["wall"]["resolution"]
    img = noise_layer(size, seed, hex_to_rgba(palette["dark"]), (0, 0, 0, 255))
    draw = ImageDraw.Draw(img, "RGBA")
    rng = random.Random(seed)
    for _ in range(34):
        x = rng.randint(-20, size[0] + 20)
        y = rng.randint(20, size[1] - 10)
        r = rng.randint(18, 58)
        draw_crystal(draw, x, y, r, hex_to_rgba(palette["ore"], rng.randint(150, 220)), hex_to_rgba(palette["glow"], rng.randint(155, 230)))
    draw.rectangle((0, size[1] - 62, size[0], size[1]), fill=(0, 0, 0, 86))
    return _make_seamless(img.filter(ImageFilter.UnsharpMask(radius=1, percent=110)))


def make_void(palette: dict, seed: int) -> Image.Image:
    size = SURFACES["void"]["resolution"]
    img = noise_layer(size, seed, hex_to_rgba(palette["dark"]), (0, 0, 0, 255)).filter(ImageFilter.GaussianBlur(0.9))
    draw = ImageDraw.Draw(img, "RGBA")
    rng = random.Random(seed)
    for _ in range(52):
        x = rng.randint(0, size[0])
        y = rng.randint(0, size[1])
        r = rng.randint(1, 4)
        draw.ellipse((x - r, y - r, x + r, y + r), fill=hex_to_rgba(palette["glow"], rng.randint(45, 145)))
    for _ in range(8):
        y = rng.randint(20, size[1] - 20)
        draw.line((-12, y, size[0] + 12, y + rng.randint(-80, 80)), fill=hex_to_rgba(palette["glow"], 48), width=3)
    return _make_seamless(img)


def make_decal(palette: dict, seed: int) -> Image.Image:
    size = SURFACES["decal"]["resolution"]
    img = Image.new("RGBA", size, (0, 0, 0, 0))
    draw = ImageDraw.Draw(img, "RGBA")
    rng = random.Random(seed)
    for _ in range(18):
        x = rng.randint(26, size[0] - 26)
        y = rng.randint(26, size[1] - 26)
        r = rng.randint(9, 28)
        draw_crystal(draw, x, y, r, hex_to_rgba(palette["ore"], rng.randint(120, 210)), hex_to_rgba(palette["glow"], 210))
    return img


def make_emission(albedo: Image.Image, palette: dict) -> Image.Image:
    glow = Image.new("RGBA", albedo.size, hex_to_rgba(palette["glow"], 0))
    gray = albedo.convert("L").point(lambda p: 255 if p > 116 else 0)
    glow.putalpha(gray.filter(ImageFilter.GaussianBlur(1.4)).point(lambda p: int(p * 0.48)))
    return glow


def make_normal_like(albedo: Image.Image) -> Image.Image:
    gray = albedo.convert("L")
    blurred = gray.filter(ImageFilter.GaussianBlur(1))
    dx = ImageChops.subtract(gray, ImageChops.offset(blurred, 1, 0))
    dy = ImageChops.subtract(gray, ImageChops.offset(blurred, 0, 1))
    normal = Image.new("RGBA", albedo.size, (128, 128, 255, 255))
    px = normal.load()
    xpx = dx.load()
    ypx = dy.load()
    for y in range(albedo.size[1]):
        for x in range(albedo.size[0]):
            px[x, y] = (max(80, min(176, 128 + xpx[x, y] // 3)), max(80, min(176, 128 + ypx[x, y] // 3)), 255, 255)
    return normal


def make_specular(albedo: Image.Image) -> Image.Image:
    gray = albedo.convert("L").point(lambda p: int(max(0, p - 55) * 1.45))
    img = Image.new("RGBA", albedo.size, (0, 0, 0, 255))
    img.putalpha(gray)
    return img


def _make_seamless(img: Image.Image) -> Image.Image:
    half = (img.size[0] // 2, img.size[1] // 2)
    shifted = ImageChops.offset(img, half[0], half[1])
    mask = Image.new("L", img.size, 0)
    draw = ImageDraw.Draw(mask)
    draw.rectangle((half[0] - 64, 0, half[0] + 64, img.size[1]), fill=96)
    draw.rectangle((0, half[1] - 64, img.size[0], half[1] + 64), fill=96)
    return _seal_edges(Image.composite(img, shifted.filter(ImageFilter.GaussianBlur(0.6)), mask))


def _seal_edges(img: Image.Image) -> Image.Image:
    sealed = img.copy().convert("RGBA")
    px = sealed.load()
    width, height = sealed.size
    for y in range(height):
        left = px[0, y]
        right = px[width - 1, y]
        avg = tuple(int((left[i] + right[i]) / 2) for i in range(4))
        px[0, y] = avg
        px[width - 1, y] = avg
    for x in range(width):
        top = px[x, 0]
        bottom = px[x, height - 1]
        avg = tuple(int((top[i] + bottom[i]) / 2) for i in range(4))
        px[x, 0] = avg
        px[x, height - 1] = avg
    return sealed


def save_image(path: Path, image: Image.Image) -> None:
    ensure(path)
    image.save(path)


def res(path: Path) -> str:
    return "res://" + path.relative_to(ROOT).as_posix()


def generate_images() -> dict:
    manifest: dict = {
        "schema_version": 1,
        "source_concept_path": res(SOURCE_CONCEPT) if SOURCE_CONCEPT.exists() else "",
        "source_generation_path": "C:/Users/janke/.codex/generated_images/019ef2b2-15a4-7b60-bc36-67a441e2a33c/ig_08bca61624134a22016a3c791958748191b21227f9823053da.png",
        "generation_record": {
            "generation_date": "2026-06-25",
            "source_model_or_tool": "built_in_image_generation_plus_project_local_generation_pipeline",
            "human_review_status": "needs_review",
            "legal_review_status": "project_original_no_external_download",
            "approval_state": "generated_unreviewed",
            "prompt_document": "res://docs/asset_generation/v2_environment_batch_01.md",
        },
        "visibility_contract": {
            "pickup_contrast_min": 0.42,
            "enemy_contrast_min": 0.38,
            "ui_overlay_dimming_allowed": True,
            "max_albedo_average_luma": 150,
        },
        "collision_visual_contract": {
            "floor": {"walkable": True, "collision_source": "map_data floor/corridor cells"},
            "wall": {"walkable": False, "collision_source": "crystal_walls/map boundary only"},
            "void": {"walkable": False, "collision_source": "boundary_cells and unreachable space"},
            "decal": {"walkable": True, "collision_source": "none"},
        },
        "biomes": {},
    }
    for biome_index, (biome_id, palette) in enumerate(BIOMES.items()):
        biome_dir = ASSET_ROOT / biome_id
        surfaces: dict = {}
        for surface_index, surface in enumerate(SURFACES):
            seed = 20260625 + biome_index * 97 + surface_index * 19
            if surface == "floor":
                albedo = make_floor(biome_id, palette, seed)
            elif surface == "wall":
                albedo = make_wall(palette, seed)
            elif surface == "void":
                albedo = make_void(palette, seed)
            else:
                albedo = make_decal(palette, seed)
            albedo_path = biome_dir / f"{surface}_albedo.png"
            normal_path = biome_dir / f"{surface}_normal.png"
            specular_path = biome_dir / f"{surface}_specular.png"
            emission_path = biome_dir / f"{surface}_emission.png"
            save_image(albedo_path, albedo)
            save_image(normal_path, make_normal_like(albedo.convert("RGBA")))
            save_image(specular_path, make_specular(albedo.convert("RGBA")))
            save_image(emission_path, make_emission(albedo.convert("RGBA"), palette))
            surfaces[surface] = {
                "asset_id": f"environment.{biome_id}.{surface}",
                "display_name": f"{palette['name_ja']} {surface}",
                "albedo_path": res(albedo_path),
                "normal_path": res(normal_path),
                "specular_path": res(specular_path),
                "emission_path": res(emission_path),
                "resolution": f"{SURFACES[surface]['resolution'][0]}x{SURFACES[surface]['resolution'][1]}",
                "usage": SURFACES[surface]["usage"],
                "walkable": SURFACES[surface]["walkable"],
                "seamless": SURFACES[surface]["seamless"],
                "replacement_status": "integrated",
                "human_review_status": "needs_review",
                "checksum": sha256(albedo_path),
                "fallback_color": list(hex_to_rgba(palette["base"] if surface == "floor" else palette["dark"])[:3]),
            }
        manifest["biomes"][biome_id] = {
            "name_ja": palette["name_ja"],
            "palette": palette,
            "surfaces": surfaces,
        }
    (DATA_DIR / "environment_asset_manifest.json").write_text(json.dumps(manifest, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    return manifest


def write_quality() -> None:
    quality = {
        "schema_version": 1,
        "default_profile": "medium",
        "profiles": {
            "ios_low": {
                "texture_enabled": True,
                "material_maps": False,
                "decals_per_screen": 18,
                "max_environment_lights": 0,
                "tile_texture_alpha": 0.72,
                "target_fps": 60,
            },
            "low": {
                "texture_enabled": True,
                "material_maps": False,
                "decals_per_screen": 24,
                "max_environment_lights": 0,
                "tile_texture_alpha": 0.78,
                "target_fps": 60,
            },
            "medium": {
                "texture_enabled": True,
                "material_maps": True,
                "decals_per_screen": 38,
                "max_environment_lights": 2,
                "tile_texture_alpha": 0.86,
                "target_fps": 60,
            },
            "high": {
                "texture_enabled": True,
                "material_maps": True,
                "decals_per_screen": 56,
                "max_environment_lights": 4,
                "tile_texture_alpha": 0.92,
                "target_fps": 60,
            },
        },
        "budgets": {
            "max_texture_size_px": 512,
            "max_single_environment_png_bytes": 900000,
            "max_visible_environment_tiles": 520,
            "max_cpu_ms_for_environment_draw": 2.6,
            "max_vram_estimate_mb": 96,
        },
    }
    (DATA_DIR / "environment_visual_quality.json").write_text(json.dumps(quality, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")


def write_docs(manifest: dict) -> None:
    DOC_DIR.mkdir(parents=True, exist_ok=True)
    batch = {
        "batch": "v2_phase4_environment_batch_01",
        "source_concept_path": manifest["source_concept_path"],
        "source_generation_path": manifest["source_generation_path"],
        "approval_state": "generated_unreviewed",
        "assets": [],
    }
    for biome_id, biome in manifest["biomes"].items():
        for surface, data in biome["surfaces"].items():
            batch["assets"].append(
                {
                    "asset_id": data["asset_id"],
                    "display_name": data["display_name"],
                    "target_resolution": data["resolution"],
                    "placement": data["albedo_path"],
                    "material_maps": [data["normal_path"], data["specular_path"], data["emission_path"]],
                    "seamless": data["seamless"],
                    "walkable": data["walkable"],
                    "replacement_status": data["replacement_status"],
                    "human_review_status": data["human_review_status"],
                    "prompt": (
                        f"Original top-down {biome['name_ja']} {surface} texture for a dark fantasy crystal labyrinth survivor game; "
                        "readable at 64px tiles, high contrast, no text, no logos, no copyrighted references."
                    ),
                    "avoid": [
                        "external copyrighted assets",
                        "direct imitation of a named game",
                        "text or UI labels in texture",
                        "low-contrast busy detail under pickups",
                    ],
                }
            )
    (DOC_DIR / "v2_environment_batch_01.json").write_text(json.dumps(batch, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    lines = [
        "# v2 Environment Batch 01",
        "",
        "Phase 4 environment art batch. The concept sheet was generated with the built-in image generation tool and copied into the project as an unreviewed source candidate. Runtime PNGs are project-local deterministic derivatives with no external downloads.",
        "",
        f"- Source concept: `{manifest['source_concept_path']}`",
        "- Human approval: needs_review",
        "- Legal status: project_original_no_external_download",
        "",
    ]
    for item in batch["assets"]:
        lines.extend(
            [
                f"## {item['asset_id']}",
                "",
                f"- Display: {item['display_name']}",
                f"- Placement: `{item['placement']}`",
                f"- Material maps: {', '.join('`%s`' % p for p in item['material_maps'])}",
                f"- Seamless: {item['seamless']}",
                f"- Walkable: {item['walkable']}",
                f"- Status: {item['replacement_status']} / {item['human_review_status']}",
                f"- Prompt: {item['prompt']}",
                "",
            ]
        )
    (DOC_DIR / "v2_environment_batch_01.md").write_text("\n".join(lines), encoding="utf-8")


def main() -> int:
    manifest = generate_images()
    write_quality()
    write_docs(manifest)
    print(f"Generated {len(BIOMES) * len(SURFACES)} environment albedo sets.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
