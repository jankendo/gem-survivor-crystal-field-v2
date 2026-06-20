import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / "test-output" / "global_gem_collection_qa.md"


def load(path: str) -> dict:
    return json.loads((ROOT / path).read_text(encoding="utf-8"))


def main() -> int:
    effects = load("data/gem_collection_effects.json")
    global_config = effects.get("global_collection", {})
    resonance = effects.get("resonance_magnet_core", {})
    OUT.parent.mkdir(parents=True, exist_ok=True)
    OUT.write_text(
        "\n".join(
            [
                "# Global Gem Collection QA",
                "",
                f"Batch size: {global_config.get('batch_size')}",
                f"Representative effects cap: {global_config.get('max_representative_effects')}",
                f"Notification limit: {global_config.get('notification_limit')}",
                "",
                "Shared systems: `GemRegistry`, `GemCollectionBatchProcessor`, `GlobalGemCollectionSystem`.",
                "Sources: magnet ore, recall drone, resonance magnet core.",
                "iOS rule: no per-gem Tween, Label, or notification is created for global collection.",
                f"Resonance levels: {len(resonance.get('levels', []))}",
            ]
        )
        + "\n",
        encoding="utf-8",
    )
    if int(global_config.get("batch_size", 0)) <= 0:
        raise SystemExit("global collection batch size must be positive")
    print(f"Global gem collection QA written: {OUT}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
