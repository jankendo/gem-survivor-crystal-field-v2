from __future__ import annotations

import hashlib
import json
import math
import random
from pathlib import Path

from PIL import Image, ImageDraw, ImageFilter


ROOT = Path(__file__).resolve().parents[1]
DOC_DIR = ROOT / "docs" / "asset_generation"


def rgba(hex_color: str, alpha: int = 255) -> tuple[int, int, int, int]:
    value = hex_color.lstrip("#")
    return tuple(int(value[i : i + 2], 16) for i in range(0, 6, 2)) + (alpha,)


def ensure(path: Path) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)


def glow_layer(size: tuple[int, int], points: list[tuple[float, float]], color: tuple[int, int, int, int], radius: int) -> Image.Image:
    layer = Image.new("RGBA", size, (0, 0, 0, 0))
    draw = ImageDraw.Draw(layer)
    for x, y in points:
        draw.ellipse((x - radius, y - radius, x + radius, y + radius), fill=color)
    return layer.filter(ImageFilter.GaussianBlur(radius / 2))


def crystal_polygon(cx: float, cy: float, r: float, sides: int, stretch_y: float = 1.15, phase: float = -math.pi / 2) -> list[tuple[float, float]]:
    return [
        (cx + math.cos(phase + i * math.tau / sides) * r, cy + math.sin(phase + i * math.tau / sides) * r * stretch_y)
        for i in range(sides)
    ]


def add_stars(draw: ImageDraw.ImageDraw, size: tuple[int, int], seed: int, count: int) -> None:
    rng = random.Random(seed)
    for _ in range(count):
        x = rng.randint(0, size[0] - 1)
        y = rng.randint(0, size[1] - 1)
        a = rng.randint(36, 130)
        draw.point((x, y), fill=(158, 231, 255, a))


def save_sprite(path: Path, image: Image.Image) -> None:
    ensure(path)
    image.save(path)


def transparent_icon(size: int = 256) -> tuple[Image.Image, ImageDraw.ImageDraw]:
    image = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    return image, ImageDraw.Draw(image)


def draw_character_noah(path: Path) -> None:
    img, draw = transparent_icon(512)
    img.alpha_composite(glow_layer(img.size, [(256, 240), (256, 340)], rgba("#68e7ff", 72), 92))
    draw.ellipse((166, 124, 346, 348), fill=rgba("#18263e", 240), outline=rgba("#6de9ff", 230), width=8)
    draw.polygon([(256, 54), (322, 160), (286, 236), (226, 236), (190, 160)], fill=rgba("#314a79", 245), outline=rgba("#c8fbff", 240))
    draw.polygon(crystal_polygon(256, 226, 78, 6), fill=rgba("#65d9ff", 210), outline=rgba("#ffffff", 220))
    draw.polygon([(204, 346), (308, 346), (360, 480), (152, 480)], fill=rgba("#24345a", 245), outline=rgba("#6ee6ff", 210))
    draw.line((196, 384, 316, 384), fill=rgba("#ffd873", 220), width=8)
    save_sprite(path, img)


def draw_enemy(path: Path, kind: str) -> None:
    img, draw = transparent_icon(384)
    palette = {
        "slime": ("#58f0bd", "#11392f", 118, 6),
        "bat": ("#b488ff", "#231a3d", 96, 8),
        "golem": ("#9de7ff", "#213042", 130, 7),
    }[kind]
    glow, body, radius, sides = palette
    img.alpha_composite(glow_layer(img.size, [(192, 202)], rgba(glow, 80), 86))
    if kind == "bat":
        draw.polygon([(58, 184), (154, 108), (192, 176), (230, 108), (326, 184), (236, 238), (192, 206), (148, 238)], fill=rgba(body, 245), outline=rgba(glow, 230))
        draw.ellipse((150, 142, 234, 232), fill=rgba("#2c2248", 245), outline=rgba(glow, 230), width=5)
        draw.ellipse((170, 170, 181, 181), fill=rgba("#fbfbff", 240))
        draw.ellipse((204, 170, 215, 181), fill=rgba("#fbfbff", 240))
    elif kind == "golem":
        draw.polygon(crystal_polygon(192, 196, radius, sides, 1.05), fill=rgba(body, 245), outline=rgba(glow, 235))
        draw.polygon(crystal_polygon(192, 142, 58, 6), fill=rgba("#31466a", 245), outline=rgba("#d9fbff", 230))
        draw.rectangle((116, 245, 268, 310), fill=rgba("#24324d", 235), outline=rgba(glow, 220), width=5)
    else:
        draw.ellipse((74, 116, 310, 298), fill=rgba(body, 245), outline=rgba(glow, 230), width=7)
        draw.polygon(crystal_polygon(192, 172, 74, 7), fill=rgba("#42cfa5", 220), outline=rgba("#eaffff", 210))
        draw.ellipse((144, 176, 162, 195), fill=rgba("#f2fff7", 250))
        draw.ellipse((222, 176, 240, 195), fill=rgba("#f2fff7", 250))
    save_sprite(path, img)


def draw_boss(path: Path) -> None:
    img, draw = transparent_icon(768)
    img.alpha_composite(glow_layer(img.size, [(384, 384)], rgba("#d36dff", 76), 180))
    draw.polygon(crystal_polygon(384, 376, 246, 8, 1.08), fill=rgba("#261d42", 250), outline=rgba("#de8cff", 240))
    draw.polygon(crystal_polygon(384, 306, 112, 6), fill=rgba("#69e8ff", 235), outline=rgba("#ffffff", 230))
    draw.polygon(crystal_polygon(384, 432, 166, 7), fill=rgba("#41306f", 220), outline=rgba("#ffde79", 210))
    for x in (214, 554):
        draw.polygon(crystal_polygon(x, 396, 62, 5), fill=rgba("#6bdfff", 210), outline=rgba("#f4ffff", 230))
    save_sprite(path, img)


def draw_weapon(path: Path, kind: str) -> None:
    img, draw = transparent_icon(256)
    if kind == "magic_bolt":
        img.alpha_composite(glow_layer(img.size, [(128, 128)], rgba("#66e9ff", 96), 58))
        draw.polygon([(54, 134), (164, 34), (146, 112), (204, 98), (92, 222), (110, 148)], fill=rgba("#5bdfff", 245), outline=rgba("#ffffff", 240))
    else:
        img.alpha_composite(glow_layer(img.size, [(128, 128)], rgba("#85dfff", 82), 58))
        draw.arc((42, 42, 214, 214), 14, 342, fill=rgba("#d8fbff", 245), width=15)
        draw.polygon(crystal_polygon(128, 128, 46, 6), fill=rgba("#4fa4ff", 225), outline=rgba("#f4ffff", 230))
        draw.ellipse((48, 78, 86, 116), fill=rgba("#f5ffff", 235))
    save_sprite(path, img)


def draw_passive(path: Path, kind: str) -> None:
    img, draw = transparent_icon(256)
    color = "#6ef7cd" if kind == "magnet" else "#80e9ff"
    img.alpha_composite(glow_layer(img.size, [(128, 128)], rgba(color, 82), 60))
    draw.rounded_rectangle((52, 52, 204, 204), radius=30, fill=rgba("#16233a", 235), outline=rgba(color, 230), width=6)
    if kind == "magnet":
        draw.arc((74, 72, 182, 188), 36, 324, fill=rgba("#ffd86e", 245), width=22)
        draw.rectangle((72, 92, 104, 134), fill=rgba("#ffd86e", 245))
        draw.rectangle((152, 92, 184, 134), fill=rgba("#ffd86e", 245))
    else:
        draw.polygon([(128, 42), (164, 108), (140, 108), (158, 208), (98, 124), (122, 124)], fill=rgba("#7df6ff", 245), outline=rgba("#ffffff", 230))
    save_sprite(path, img)


def draw_evolution(path: Path) -> None:
    img, draw = transparent_icon(256)
    img.alpha_composite(glow_layer(img.size, [(128, 128)], rgba("#ffd873", 92), 68))
    for i in range(8):
        angle = math.tau * i / 8.0
        x = 128 + math.cos(angle) * 76
        y = 128 + math.sin(angle) * 76
        draw.line((128, 128, x, y), fill=rgba("#f5ffff", 195), width=5)
    draw.polygon(crystal_polygon(128, 128, 66, 8), fill=rgba("#6bdfff", 230), outline=rgba("#ffffff", 240))
    draw.polygon(crystal_polygon(128, 128, 34, 5), fill=rgba("#ffd873", 240), outline=rgba("#fff6cc", 240))
    save_sprite(path, img)


def draw_biome(path: Path) -> None:
    size = (1600, 900)
    img = Image.new("RGBA", size, rgba("#07101c", 255))
    draw = ImageDraw.Draw(img)
    add_stars(draw, size, 20260623, 360)
    for y in range(0, size[1], 60):
        color = (18, 37, 62, 70 if y % 120 == 0 else 40)
        draw.line((0, y, size[0], y + 120), fill=color, width=2)
    rng = random.Random(42)
    for _ in range(38):
        x = rng.randint(0, size[0])
        y = rng.randint(120, size[1])
        r = rng.randint(16, 54)
        draw.polygon(crystal_polygon(x, y, r, rng.choice([5, 6, 7]), rng.uniform(1.0, 1.55)), fill=rgba("#1a4662", rng.randint(90, 170)), outline=rgba("#5ddfff", 120))
    img = img.filter(ImageFilter.GaussianBlur(0.2))
    save_sprite(path, img.convert("RGBA"))


def draw_ui(path: Path, kind: str) -> None:
    sizes = {
        "title_key_visual": (1024, 384),
        "primary_crystal_panel": (512, 256),
        "reward_card_frame": (512, 256),
        "momentum_badge": (256, 256),
        "boss_alert_frame": (768, 192),
    }
    size = sizes[kind]
    img = Image.new("RGBA", size, (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    if kind == "title_key_visual":
        img.alpha_composite(glow_layer(size, [(size[0] * 0.55, size[1] * 0.52)], rgba("#68e7ff", 78), 132))
        draw.rounded_rectangle((34, 30, size[0] - 34, size[1] - 30), radius=34, fill=rgba("#081322", 210), outline=rgba("#6de9ff", 230), width=5)
        for i in range(7):
            x = 132 + i * 122
            draw.polygon(crystal_polygon(x, 238 - (i % 3) * 22, 54 + (i % 2) * 12, 6, 1.45), fill=rgba("#2c8bb4", 190), outline=rgba("#a8f7ff", 200))
        draw.polygon(crystal_polygon(720, 160, 72, 7), fill=rgba("#ffd873", 210), outline=rgba("#fff8cc", 230))
    elif kind == "momentum_badge":
        img.alpha_composite(glow_layer(size, [(128, 128)], rgba("#9a76ff", 96), 70))
        draw.ellipse((38, 38, 218, 218), fill=rgba("#161638", 230), outline=rgba("#9a76ff", 235), width=8)
        draw.polygon(crystal_polygon(128, 128, 60, 6), fill=rgba("#6bdfff", 220), outline=rgba("#ffffff", 230))
        draw.arc((62, 62, 194, 194), -55, 250, fill=rgba("#ffd873", 230), width=10)
    elif kind == "boss_alert_frame":
        draw.rounded_rectangle((16, 20, size[0] - 16, size[1] - 20), radius=24, fill=rgba("#2a1022", 225), outline=rgba("#ff5f91", 235), width=7)
        draw.line((54, size[1] / 2, size[0] - 54, size[1] / 2), fill=rgba("#ffd873", 145), width=4)
        for x in (70, size[0] - 70):
            draw.polygon(crystal_polygon(x, size[1] / 2, 34, 3), fill=rgba("#ff5f91", 230), outline=rgba("#fff0f6", 230))
    else:
        accent = "#6de9ff" if kind == "primary_crystal_panel" else "#ffd873"
        draw.rounded_rectangle((18, 18, size[0] - 18, size[1] - 18), radius=24, fill=rgba("#091525", 220), outline=rgba(accent, 225), width=6)
        draw.line((44, 54, size[0] - 44, 54), fill=rgba(accent, 130), width=3)
        draw.line((44, size[1] - 54, size[0] - 44, size[1] - 54), fill=rgba(accent, 100), width=3)
    save_sprite(path, img)


def asset_rows() -> list[dict]:
    return [
        ("character.noah", "character_portrait", "ノア", "assets/v2/characters/noah.png", "assets/generated/characters/noah.svg", "512x512", "1:1", True, "title/character select/default survivor", "P0", "default survivor, readable blue crystal silhouette"),
        ("enemy.slime", "enemy_sprite", "スライム", "assets/v2/enemies/slime.png", "assets/generated/enemies/slime.svg", "384x384", "1:1", True, "early enemy sprite", "P0", "soft green crystal creature"),
        ("enemy.bat", "enemy_sprite", "コウモリ", "assets/v2/enemies/bat.png", "assets/generated/enemies/bat.svg", "384x384", "1:1", True, "fast enemy sprite", "P0", "purple wing silhouette"),
        ("enemy.golem", "enemy_sprite", "ゴーレム", "assets/v2/enemies/golem.png", "assets/generated/enemies/golem.svg", "384x384", "1:1", True, "durable enemy sprite", "P0", "heavy blue crystal rock body"),
        ("boss.boss_5", "boss_sprite", "巨大スライム", "assets/v2/bosses/boss_5.png", "assets/generated/bosses/boss_5.svg", "768x768", "1:1", True, "first boss sprite", "P0", "large purple boss with bright core"),
        ("weapon.magic_bolt", "weapon_icon", "魔弾", "assets/v2/weapons/magic_bolt.png", "assets/generated/weapons/magic_bolt.svg", "256x256", "1:1", True, "weapon icon", "P0", "cyan bolt icon"),
        ("weapon.ice_orbit", "weapon_icon", "氷軌道", "assets/v2/weapons/ice_orbit.png", "assets/generated/weapons/ice_orbit.svg", "256x256", "1:1", True, "weapon icon", "P0", "circular ice orbit icon"),
        ("passive.move_speed", "passive_icon", "移動速度", "assets/v2/passives/move_speed.png", "assets/generated/passives/move_speed.svg", "256x256", "1:1", True, "passive icon", "P0", "speed talisman icon"),
        ("passive.magnet", "passive_icon", "磁力", "assets/v2/passives/magnet.png", "assets/generated/passives/magnet.svg", "256x256", "1:1", True, "passive icon", "P0", "magnet talisman icon"),
        ("evolution.starbreaker_bolt", "evolution_icon", "星砕きの魔弾", "assets/v2/evolutions/starbreaker_bolt.png", "assets/generated/evolutions/starbreaker_bolt.svg", "256x256", "1:1", True, "evolved weapon icon", "P0", "gold-cyan ultimate bolt"),
        ("biome.star_plain", "biome_background", "星晶の原野", "assets/v2/biomes/star_plain.png", "assets/survivor/field_small_crystal.svg", "1600x900", "16:9", False, "subtle default arena background", "P0", "dark star crystal field floor"),
        ("ui.title_key_visual", "ui_panel", "タイトルキービジュアル", "assets/v2/ui/title_key_visual.png", "assets/sprites/title_logo.svg", "1024x384", "8:3", True, "title screen hero visual", "P0", "crystal field key visual without text"),
        ("ui.primary_crystal_panel", "ui_panel", "主要クリスタルパネル", "assets/v2/ui/primary_crystal_panel.png", "assets/survivor/ui/ios_shop_card.svg", "512x256", "2:1", True, "major menu/HUD panel frame", "P0", "thin cyan crystal panel"),
        ("ui.reward_card_frame", "ui_panel", "報酬カード枠", "assets/v2/ui/reward_card_frame.png", "assets/survivor/ui/touch_card_frame.svg", "512x256", "2:1", True, "reward/result card frame", "P0", "gold crystal reward card frame"),
        ("ui.momentum_badge", "ui_icon", "Momentumバッジ", "assets/v2/ui/momentum_badge.png", "assets/survivor/ui/melee_rush_gauge.svg", "256x256", "1:1", True, "momentum HUD badge", "P0", "purple cyan momentum crystal badge"),
        ("ui.boss_alert_frame", "ui_panel", "ボス警告フレーム", "assets/v2/ui/boss_alert_frame.png", "assets/survivor/ui/boss_warning.svg", "768x192", "4:1", True, "boss alert banner frame", "P0", "red purple alert frame"),
    ]


def write_assets() -> None:
    draw_character_noah(ROOT / "assets/v2/characters/noah.png")
    for enemy in ("slime", "bat", "golem"):
        draw_enemy(ROOT / f"assets/v2/enemies/{enemy}.png", enemy)
    draw_boss(ROOT / "assets/v2/bosses/boss_5.png")
    for weapon in ("magic_bolt", "ice_orbit"):
        draw_weapon(ROOT / f"assets/v2/weapons/{weapon}.png", weapon)
    for passive in ("move_speed", "magnet"):
        draw_passive(ROOT / f"assets/v2/passives/{passive}.png", passive)
    draw_evolution(ROOT / "assets/v2/evolutions/starbreaker_bolt.png")
    draw_biome(ROOT / "assets/v2/biomes/star_plain.png")
    for ui in ("title_key_visual", "primary_crystal_panel", "reward_card_frame", "momentum_badge", "boss_alert_frame"):
        draw_ui(ROOT / f"assets/v2/ui/{ui}.png", ui)


def sha256(path: Path) -> str:
    return hashlib.sha256(path.read_bytes()).hexdigest()


def manifest_entries() -> list[dict]:
    entries = []
    for row in asset_rows():
        asset_id, category, display_name, preferred, fallback, resolution, aspect, transparent, usage, priority, style = row
        preferred_path = ROOT / preferred
        entries.append(
            {
                "asset_id": asset_id,
                "category": category,
                "display_name": display_name,
                "preferred_path": "res://" + preferred.replace("\\", "/"),
                "fallback_path": "res://" + fallback.replace("\\", "/"),
                "target_resolution": resolution,
                "aspect_ratio": aspect,
                "transparent": transparent,
                "usage": usage,
                "priority": priority,
                "replacement_status": "integrated" if preferred_path.exists() else "prompt_ready",
                "style_profile": "dark fantasy crystal glow, high contrast, no text in image; " + style,
                "prompt_document": "res://docs/asset_generation/v2_batch_01.md",
                "checksum_optional": sha256(preferred_path) if preferred_path.exists() else "",
            }
        )
    return entries


def write_manifest() -> None:
    manifest = {
        "schema_version": 2,
        "description": "Gem Survivor Crystal Field v2 Phase 2 asset replacement manifest. P0 integrated PNG assets are preferred; existing SVG assets remain fallback.",
        "resolution_order": ["preferred_path", "fallback_path", "code_safe_draw"],
        "allowed_status": ["fallback", "prompt_ready", "generated", "integrated", "approved", "rejected"],
        "assets": manifest_entries(),
    }
    path = ROOT / "data/asset_manifest.json"
    path.write_text(json.dumps(manifest, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")


def prompt_for(entry: dict) -> str:
    return (
        f"Create a completely original {entry['display_name']} asset for a 2D dark fantasy crystal survivor game. "
        f"Use {entry['style_profile']}. Keep the silhouette readable at small size, use safe padding, consistent top-left cyan crystal lighting, "
        f"high contrast on a dark background, no text, no logos, no imitation of existing games, no copyrighted characters."
    )


def write_docs() -> None:
    DOC_DIR.mkdir(parents=True, exist_ok=True)
    entries = manifest_entries()
    batch = []
    for entry in entries:
        batch.append(
            {
                "asset_id": entry["asset_id"],
                "display_name": entry["display_name"],
                "category": entry["category"],
                "usage": entry["usage"],
                "target_resolution": entry["target_resolution"],
                "aspect_ratio": entry["aspect_ratio"],
                "transparent": entry["transparent"],
                "composition": entry["style_profile"],
                "silhouette": "single clear focal object, readable at HUD size",
                "colors": "dark base with cyan, violet, gold, or green crystal glow depending on gameplay role",
                "glow": "controlled rim glow; avoid full-screen flash",
                "worldview": "dark fantasy x crystal glow x exploration sci-fi",
                "complete_prompt": prompt_for(entry),
                "avoid": [
                    "external copyrighted characters",
                    "specific game or artist imitation",
                    "text inside the image",
                    "low-contrast shapes",
                    "overly busy background for icons",
                    "violent gore or realistic horror",
                ],
                "file_name": Path(entry["preferred_path"].replace("res://", "")).name,
                "placement": entry["preferred_path"],
                "godot_display_size": "64-128px icon, 128-192px sprite, or responsive panel/background depending on category",
                "fallback_path": entry["fallback_path"],
                "replacement_status": entry["replacement_status"],
                "checksum_optional": entry["checksum_optional"],
            }
        )
    (DOC_DIR / "v2_batch_01.json").write_text(json.dumps({"batch": "v2_phase2_p0", "assets": batch}, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    lines = [
        "# v2 Batch 01 Asset Generation Notes",
        "",
        "Phase 2 P0 vertical slice assets. All integrated PNG files are original deterministic project-generated raster assets; existing SVG files remain fallback.",
        "",
        "Common constraints: no external assets, no text in image, no imitation of existing games or artists, transparent background for sprites/icons/UI frames where listed.",
        "",
    ]
    for item in batch:
        lines.extend(
            [
                f"## {item['asset_id']} - {item['display_name']}",
                "",
                f"- Category: {item['category']}",
                f"- Usage: {item['usage']}",
                f"- Target: {item['target_resolution']} / {item['aspect_ratio']}",
                f"- Transparent: {item['transparent']}",
                f"- Placement: `{item['placement']}`",
                f"- Fallback: `{item['fallback_path']}`",
                f"- Status: {item['replacement_status']}",
                f"- Prompt: {item['complete_prompt']}",
                f"- Avoid: {', '.join(item['avoid'])}",
                "",
            ]
        )
    (DOC_DIR / "v2_batch_01.md").write_text("\n".join(lines), encoding="utf-8")


def main() -> None:
    write_assets()
    write_manifest()
    write_docs()
    print("Generated Phase 2 P0 assets, manifest, and Batch 01 documentation.")


if __name__ == "__main__":
    main()
