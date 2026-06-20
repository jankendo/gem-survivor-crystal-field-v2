from __future__ import annotations

import json
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
CHARACTERS = ROOT / "data" / "characters.json"
EVOLUTIONS = ROOT / "data" / "character_evolutions.json"
UNLOCKS = ROOT / "data" / "character_evolution_unlocks.json"
ASSET_DIR = ROOT / "assets" / "generated" / "character_evolutions"


NAME_OVERRIDES = {
    "noah": "星晶探鉱者ノア",
    "mio": "永久氷晶ミオ",
    "kaede": "真影カエデ",
}

TYPE_CYCLE = ["gems_collected", "kills", "rooms_discovered", "crystals_destroyed", "boss_defeats"]


def evolved_name(character_id: str, name: str) -> str:
    return NAME_OVERRIDES.get(character_id, f"進化{name}")


def unique_condition(index: int) -> dict:
    kind = TYPE_CYCLE[index % len(TYPE_CYCLE)]
    if kind == "gems_collected":
        return {"type": kind, "value": 260, "text_ja": "ジェム260個回収"}
    if kind == "kills":
        return {"type": kind, "value": 520, "text_ja": "撃破520体"}
    if kind == "rooms_discovered":
        return {"type": kind, "value": 7, "text_ja": "部屋7室発見"}
    if kind == "crystals_destroyed":
        return {"type": kind, "value": 24, "text_ja": "結晶壁24個破壊"}
    return {"type": kind, "value": 1, "text_ja": "ボス1体撃破"}


def color_for(index: int) -> tuple[str, str, str]:
    palettes = [
        ("#0f2742", "#69d8ff", "#fff37a"),
        ("#231b43", "#b98cff", "#8dffd6"),
        ("#2f1730", "#ff7ad9", "#ffe082"),
        ("#143522", "#76ff9f", "#7ad7ff"),
        ("#38210f", "#ffb15a", "#a9ff86"),
    ]
    return palettes[index % len(palettes)]


def svg(character_id: str, name: str, index: int) -> str:
    bg, primary, accent = color_for(index)
    initials = "".join(part[:1] for part in name.replace("　", " ").split())[:2] or character_id[:2]
    return f'''<svg xmlns="http://www.w3.org/2000/svg" width="160" height="160" viewBox="0 0 160 160">
  <rect width="160" height="160" rx="24" fill="{bg}"/>
  <circle cx="80" cy="80" r="58" fill="none" stroke="{primary}" stroke-width="7"/>
  <path d="M80 20 L94 60 L136 60 L102 86 L116 128 L80 103 L44 128 L58 86 L24 60 L66 60 Z" fill="{primary}" opacity="0.28"/>
  <circle cx="80" cy="78" r="33" fill="{primary}" opacity="0.34" stroke="{accent}" stroke-width="5"/>
  <text x="80" y="91" text-anchor="middle" font-family="sans-serif" font-size="30" fill="{accent}" font-weight="700">{initials}</text>
  <path d="M42 124 C62 106,98 106,118 124" fill="none" stroke="{accent}" stroke-width="8" stroke-linecap="round"/>
</svg>
'''


def main() -> None:
    characters = json.loads(CHARACTERS.read_text(encoding="utf-8"))
    ASSET_DIR.mkdir(parents=True, exist_ok=True)
    evolutions = {}
    unlocks = {}
    for index, (character_id, character) in enumerate(characters.items()):
        name = character.get("name_ja", character_id)
        evolved = evolved_name(character_id, name)
        asset_path = ASSET_DIR / f"{character_id}_evolved.svg"
        asset_path.write_text(svg(character_id, evolved, index), encoding="utf-8")
        evolutions[character_id] = {
            "character_id": character_id,
            "base_name_ja": name,
            "evolved_name_ja": evolved,
            "required_level": 20,
            "required_seconds": 600.0,
            "activation": ["evolution_core", "boss_chest"],
            "unique_condition": unique_condition(index),
            "trait_upgrade_ja": f"{character.get('trait_ja', '特性')}を強化し、進化副特性を追加",
            "subtrait_ja": "最大HP+12、吸収範囲+8%",
            "modifiers": {
                "damage_mult": 1.08,
                "gem_value_mult": 1.06,
                "move_mult": 1.03,
            },
            "subtraits": {
                "max_hp_flat": 12,
                "magnet_mult": 1.08,
            },
            "evolved_sprite": f"res://assets/generated/character_evolutions/{character_id}_evolved.svg",
        }
        unlocks[character_id] = {
            "condition": {"type": "character_mastery_points", "value": 350},
            "text_ja": "そのキャラクターの熟練度350ptで進化解放",
        }
    unlocks["noah"] = {"initial": True, "text_ja": "初期解放"}
    EVOLUTIONS.write_text(json.dumps(evolutions, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    UNLOCKS.write_text(json.dumps(unlocks, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")


if __name__ == "__main__":
    main()
