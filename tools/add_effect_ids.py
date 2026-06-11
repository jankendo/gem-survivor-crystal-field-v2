import json
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]


def load(name: str) -> dict:
    return json.loads((ROOT / "data" / name).read_text(encoding="utf-8"))


def save(name: str, data: dict) -> None:
    text = json.dumps(data, ensure_ascii=False, indent=2) + "\n"
    (ROOT / "data" / name).write_text(text, encoding="utf-8")


weapons = load("weapons.json")
evolutions = load("evolutions.json")

for weapon_id, weapon in weapons.items():
    weapon["effect_id"] = weapon_id

for evolution_id, evolution in evolutions.items():
    source_weapon = str(evolution.get("weapon", evolution.get("source_weapon", "")))
    evolution["effect_id"] = source_weapon if source_weapon in weapons else evolution_id

save("weapons.json", weapons)
save("evolutions.json", evolutions)
