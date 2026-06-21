import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / "test-output" / "persistent_drop_qa.md"


def load(path: str) -> dict:
    return json.loads((ROOT / path).read_text(encoding="utf-8"))


def main() -> int:
    drops = load("data/field_drops.json")
    config = drops.get("_config", {})
    drop_ids = [key for key in drops.keys() if not key.startswith("_")]
    respawn_ids = [
        key
        for key in drop_ids
        if drops.get(key, {}).get("respawn_enabled")
    ]
    OUT.parent.mkdir(parents=True, exist_ok=True)
    OUT.write_text(
        "\n".join(
            [
                "# Persistent Drop QA",
                "",
                f"Time spawn enabled: {config.get('time_spawn_enabled')}",
                f"Time despawn enabled: {config.get('time_despawn_enabled')}",
                f"Base spawn chance: {config.get('base_spawn_chance')}",
                f"Max dynamic per run: {config.get('max_dynamic_per_run')}",
                f"Respawn check interval: {config.get('respawn_check_interval')}",
                f"Drop IDs: {', '.join(drop_ids)}",
                f"Respawn IDs: {', '.join(respawn_ids)}",
                "",
                "Runtime rule: uncollected drops never despawn by time.",
                "After pickup, consumable field drops schedule a bounded respawn through `FieldDropSpawnSystem`.",
                "Field weapons/passives are `field_equipment` rewards and do not time-respawn.",
            ]
        )
        + "\n",
        encoding="utf-8",
    )
    if config.get("time_spawn_enabled") or config.get("time_despawn_enabled"):
        raise SystemExit("time-based drop spawn/despawn must remain disabled")
    if not respawn_ids:
        raise SystemExit("at least one consumable drop must respawn after pickup")
    print(f"Persistent drop QA written: {OUT}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
