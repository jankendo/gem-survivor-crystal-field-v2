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
                f"Drop IDs: {', '.join(drop_ids)}",
                "",
                "Runtime rule: normal drops are placed once at map generation and remain until pickup.",
                "Explicit event/boss/test rewards use force spawn, are marked persistent, and do not expire by time.",
            ]
        )
        + "\n",
        encoding="utf-8",
    )
    if config.get("time_spawn_enabled") or config.get("time_despawn_enabled"):
        raise SystemExit("time-based drop spawn/despawn must remain disabled")
    print(f"Persistent drop QA written: {OUT}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
