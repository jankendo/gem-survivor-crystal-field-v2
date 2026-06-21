import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / "test-output" / "shop_reroll_qa.md"


def load(path: str) -> dict:
    return json.loads((ROOT / path).read_text(encoding="utf-8"))


def main() -> int:
    deprecated = load("data/shop_reroll.json")
    selection = load("data/selection_actions.json")
    sinks = load("data/currency_sinks.json")
    reroll_sink = sinks.get(selection.get("shop_reroll_sink_id", "levelup_reroll_capacity"), {})
    OUT.parent.mkdir(parents=True, exist_ok=True)
    OUT.write_text(
        "\n".join(
            [
                "# Selection Reroll QA",
                "",
                f"Deprecated shop inventory reroll: {deprecated.get('deprecated')} / enabled={deprecated.get('shop_inventory_reroll_enabled')}",
                f"Base level-up rerolls: {selection.get('reroll_base_count')}",
                f"Max level-up rerolls: {selection.get('max_reroll_count')}",
                f"Permanent sink id: {selection.get('shop_reroll_sink_id')}",
                f"Permanent sink name: {reroll_sink.get('name_ja')}",
                f"Effect per level: {reroll_sink.get('effect_per_level_ja')}",
                "",
                "Legacy keys tolerated but ignored: `shop_cycle_id`, `shop_reroll_count`, `shop_featured_items`, `shop_save_seed`.",
                "Runtime rule: reroll means level-up 3-choice reroll count, not shop product inventory reroll.",
            ]
        )
        + "\n",
        encoding="utf-8",
    )
    if deprecated.get("shop_inventory_reroll_enabled") is not False:
        raise SystemExit("shop inventory reroll must stay disabled")
    print(f"Selection reroll QA written: {OUT}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
