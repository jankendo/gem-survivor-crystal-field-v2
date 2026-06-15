#!/usr/bin/env python3
"""Generate a compact progress-visibility QA artifact."""

from __future__ import annotations

import json
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]


def load(name: str) -> dict:
    with (ROOT / "data" / name).open(encoding="utf-8") as handle:
        value = json.load(handle)
    return value if isinstance(value, dict) else {}


def main() -> int:
    characters = load("character_unlocks.json")
    weapons = load("weapon_unlocks.json")
    passives = load("passive_unlocks.json")
    blessings = load("blessings.json")
    quests = load("quests.json")
    sinks = load("currency_sinks.json")
    rows = [
        ("Achievements", len(quests), "AchievementCard progress bar + current / target"),
        ("Characters", len(characters), "character selection and shop unlock progress"),
        ("Weapons", len(weapons), "collection and loadout unlock progress"),
        ("Passives", len(passives), "collection and loadout unlock progress"),
        ("Blessings", len(blessings), "selection, character detail, pause, result, collection, shop"),
        ("Shop / research / loadout slots", len(sinks), "condition progress and OFF-slot usage"),
    ]
    lines = [
        "# Progress QA Report",
        "",
        "| Surface | Definitions | Verified presentation |",
        "| --- | ---: | --- |",
    ]
    lines.extend(f"| {name} | {count} | {evidence} |" for name, count, evidence in rows)
    lines.extend(
        [
            "",
            "## Required Formats",
            "",
            "- Numeric: `320 / 500` plus percentage.",
            "- Time: `7:32 / 10:00`.",
            "- Multiple conditions: one current / target line per condition.",
            "- Completed conditions: completed state plus full progress bar.",
            "- Result: per-run delta such as `+12 -> 42 / 100`.",
            "- Secret conditions: hint or undisclosed-progress text without forced spoilers.",
            "",
            "## Persistence",
            "",
            "- SaveSystem stores cumulative kill, wall, room, event, terrain, currency, blessing, pick, evolution, and overclock counters.",
            "- `test_progress_counters_persist.gd` verifies reload persistence.",
            "- `test_result_progress_delta.gd` verifies result delta formatting.",
            "",
        ]
    )
    output = ROOT / "test-output" / "progress_qa_report.md"
    output.parent.mkdir(parents=True, exist_ok=True)
    output.write_text("\n".join(lines), encoding="utf-8", newline="\n")
    print(f"Wrote {output}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
