import json
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / "test-output" / "field_equipment_qa.md"


def load(path: str) -> dict:
    return json.loads((ROOT / path).read_text(encoding="utf-8"))


def main() -> int:
    rewards = load("data/field_equipment_rewards.json")
    weapon_unlocks = load("data/weapon_unlocks.json")
    passive_unlocks = load("data/passive_unlocks.json")
    initial_weapons = {k for k, v in weapon_unlocks.items() if v.get("initial")}
    initial_passives = {k for k, v in passive_unlocks.items() if v.get("initial")}
    weapon_pool = [row.get("id", "") for row in rewards.get("weapon_pool", [])]
    passive_pool = [row.get("id", "") for row in rewards.get("passive_pool", [])]
    initially_available_weapons = [item for item in weapon_pool if item in initial_weapons]
    initially_available_passives = [item for item in passive_pool if item in initial_passives]
    OUT.parent.mkdir(parents=True, exist_ok=True)
    OUT.write_text(
        "\n".join([
            "# Field Equipment QA",
            "",
            f"Weapon pool entries: {len(weapon_pool)}",
            f"Passive pool entries: {len(passive_pool)}",
            f"Initial unlocked weapon entries in pool: {', '.join(initially_available_weapons) or 'none'}",
            f"Initial unlocked passive entries in pool: {', '.join(initially_available_passives) or 'none'}",
            "",
            "Runtime placement is filtered by `FieldEquipmentPlacementSystem.is_id_run_available`.",
            "Pickup fallback converts stale invalid equipment into score instead of leaving a no-op reward.",
        ]) + "\n",
        encoding="utf-8",
    )
    if not initially_available_weapons or not initially_available_passives:
        raise SystemExit("field equipment pool needs at least one initially available weapon and passive")
    print(f"Field equipment QA written: {OUT}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
