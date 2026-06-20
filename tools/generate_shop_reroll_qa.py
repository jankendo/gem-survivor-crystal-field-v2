import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / "test-output" / "shop_reroll_qa.md"


def load(path: str) -> dict:
    return json.loads((ROOT / path).read_text(encoding="utf-8"))


def main() -> int:
    config = load("data/shop_reroll.json")
    OUT.parent.mkdir(parents=True, exist_ok=True)
    OUT.write_text(
        "\n".join(
            [
                "# Shop Reroll QA",
                "",
                f"Featured slots: {config.get('featured_slot_count')}",
                f"Free rerolls per cycle: {config.get('free_rerolls_per_cycle')}",
                f"Costs: {config.get('costs')}",
                f"Max rerolls per cycle: {config.get('max_rerolls_per_cycle')}",
                "",
                "RNG streams: `shop_featured`, keyed by `shop_save_seed`, `shop_cycle_id`, and `shop_reroll_count`.",
                "Persistence: reroll count and featured candidates are saved immediately after reroll.",
            ]
        )
        + "\n",
        encoding="utf-8",
    )
    print(f"Shop reroll QA written: {OUT}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
