#!/usr/bin/env python3
"""Generate exploration reward balance notes for CI artifacts."""

from __future__ import annotations

import json
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]


def load_json(name: str) -> dict:
    with (ROOT / "data" / name).open(encoding="utf-8") as handle:
        value = json.load(handle)
    return value if isinstance(value, dict) else {}


def main() -> int:
    field_equipment = load_json("field_equipment_rewards.json")
    field_drops = load_json("field_drops.json")
    events = load_json("field_events.json")
    config = field_equipment.get("config", {})
    weapon_pool = field_equipment.get("weapon_pool", [])
    passive_pool = field_equipment.get("passive_pool", [])
    reward_rooms = field_equipment.get("reward_rooms", {})
    drop_ids = [key for key in field_drops.keys() if not key.startswith("_")]
    event_rewards = []
    for event_id, event in events.items():
        if isinstance(event, dict):
            rewards = event.get("reward_candidates", [])
            rare = event.get("rare_rewards", [])
            limited = event.get("limited_rewards", [])
            event_rewards.append((event_id, len(rewards), len(rare), len(limited)))

    lines = [
        "# Exploration Balance Report",
        "",
        "## Exploration Motivation",
        "",
        f"- Field weapon placements per run: `{config.get('max_weapon_pickups_per_run', 0)}`",
        f"- Field passive placements per run: `{config.get('max_passive_pickups_per_run', 0)}`",
        f"- Total equipment pickup cap: `{config.get('max_total_equipment_pickups_per_run', 0)}`",
        f"- Minimum start distance: `{config.get('min_distance_from_start', 0)}`",
        f"- Rare minimum start distance: `{config.get('rare_min_distance_from_start', 0)}`",
        f"- Over-cap pickup allowed: `{config.get('allow_over_cap_pickup', True)}`",
        "",
        "## Reward Sources",
        "",
        f"- Concrete weapon pool entries: `{len(weapon_pool)}`",
        f"- Concrete passive pool entries: `{len(passive_pool)}`",
        f"- Reward room definitions: `{len(reward_rooms)}`",
        f"- Field drop categories: `{len(drop_ids)}`",
        f"- Event definitions with reward previews: `{len(event_rewards)}`",
        "",
        "## Event Reward Preview Coverage",
        "",
        "| Event | Candidates | Rare | Limited |",
        "| --- | ---: | ---: | ---: |",
    ]
    for event_id, candidates, rare, limited in event_rewards:
        lines.append(f"| `{event_id}` | {candidates} | {rare} | {limited} |")
    lines.extend(
        [
            "",
            "## Automated Coverage",
            "",
            "- `test_exploration_reward_rooms.gd` verifies reward rooms, far-room quality, exploration chain, and camping efficiency.",
            "- `test_exploration_vs_camping_balance.gd` compares camping, exploration, and event participation.",
            "- `test_field_equipment_placement.gd` verifies seed reproducibility, max placements, names/icons, and over-cap pickup.",
            "- Full-test autoplays cover skip/seal, exploration, events, field equipment, and camping-vs-exploration runs.",
            "",
            "## Balance Principle",
            "",
            "- Staying near the start is allowed and safer, but lower reward density and broken exploration chains make it less efficient.",
            "- Distant, dangerous, event, and rare rooms carry stronger concrete rewards without requiring punitive anti-camping damage.",
            "",
        ]
    )
    output = ROOT / "test-output" / "exploration_balance_report.md"
    output.parent.mkdir(parents=True, exist_ok=True)
    output.write_text("\n".join(lines), encoding="utf-8", newline="\n")
    print(f"Wrote {output}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
