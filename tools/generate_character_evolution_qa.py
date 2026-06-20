import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / "test-output" / "character_evolution_qa.md"


def load(path: str) -> dict:
    return json.loads((ROOT / path).read_text(encoding="utf-8"))


def main() -> int:
    characters = load("data/characters.json")
    evolutions = load("data/character_evolutions.json")
    unlocks = load("data/character_evolution_unlocks.json")
    missing = [character_id for character_id in characters if character_id not in evolutions]
    missing_assets = []
    for character_id, data in evolutions.items():
        path = str(data.get("evolved_sprite", "")).replace("res://", "")
        if not path or not (ROOT / path).is_file():
            missing_assets.append(character_id)
    OUT.parent.mkdir(parents=True, exist_ok=True)
    OUT.write_text(
        "\n".join(
            [
                "# Character Evolution QA",
                "",
                f"Characters: {len(characters)}",
                f"Evolution rows: {len(evolutions)}",
                f"Unlock rows: {len(unlocks)}",
                f"Missing data: {', '.join(missing) or 'none'}",
                f"Missing assets: {', '.join(missing_assets) or 'none'}",
                "",
                "Run rule: each selected character can evolve at most once per run.",
                "Activation: evolution core or boss chest after level, time, and unique condition are satisfied.",
                "Persistence: unlock/progress/count/fastest-time save keys are migrated in SaveSystem.",
            ]
        )
        + "\n",
        encoding="utf-8",
    )
    if missing or missing_assets:
        raise SystemExit("character evolution data/assets incomplete")
    print(f"Character evolution QA written: {OUT}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
