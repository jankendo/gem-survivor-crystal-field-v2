import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / "test-output" / "experience_balance_report.md"


def load(path: str) -> dict:
    return json.loads((ROOT / path).read_text(encoding="utf-8"))


def main() -> int:
    settings = load("data/experience_settings.json")
    passives = load("data/passives.json")
    resonance = passives.get("resonance_magnet_core", {})
    OUT.parent.mkdir(parents=True, exist_ok=True)
    OUT.write_text(
        "\n".join(
            [
                "# Experience Balance Report",
                "",
                f"Normal EXP multiplier: {settings.get('normal_exp_balance_multiplier')}x",
                f"Debug multipliers: {settings.get('debug_exp_multipliers')}",
                f"Debug progress default: allow={settings.get('allow_debug_progress_default')}",
                f"Target levels: {json.dumps(settings.get('target_levels', {}), ensure_ascii=False)}",
                "",
                "Formula: base gem value * normal balance multiplier * passive EXP multiplier * event/rune/difficulty modifiers * debug multiplier.",
                f"Resonance EXP bonuses: {resonance.get('exp_bonus_by_level')}",
                "Save protection: non-1.0 debug multiplier blocks permanent progress unless explicitly enabled.",
            ]
        )
        + "\n",
        encoding="utf-8",
    )
    print(f"Experience balance report written: {OUT}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
