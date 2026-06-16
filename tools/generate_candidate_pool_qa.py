#!/usr/bin/env python3
"""Generate candidate pool QA notes for skip, seal, core, and over-cap rules."""

from __future__ import annotations

import json
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]


def load_json(name: str) -> dict:
    with (ROOT / "data" / name).open(encoding="utf-8") as handle:
        value = json.load(handle)
    return value if isinstance(value, dict) else {}


def main() -> int:
    selection = load_json("selection_actions.json")
    balance = load_json("balance.json")
    sinks = load_json("currency_sinks.json")
    loadout_sinks = sinks.get("loadout", {}) if isinstance(sinks.get("loadout", {}), dict) else {}
    lines = [
        "# Candidate Pool QA",
        "",
        "## Skip / Seal Counts",
        "",
        f"- Skip base count: `{selection.get('skip_base_count', 0)}`",
        f"- Seal base count: `{selection.get('seal_base_count', 0)}`",
        f"- Max skip count: `{selection.get('max_skip_count', 0)}`",
        f"- Max seal count: `{selection.get('max_seal_count', 0)}`",
        f"- Shop skip sink present: `{selection.get('shop_skip_sink_id', '') in loadout_sinks}`",
        f"- Shop seal sink present: `{selection.get('shop_seal_sink_id', '') in loadout_sinks}`",
        f"- Achievement skip rewards: `{len(selection.get('achievement_skip_rewards', []))}`",
        f"- Achievement seal rewards: `{len(selection.get('achievement_seal_rewards', []))}`",
        "",
        "## Equipment Capacity",
        "",
        f"- Level-up weapon cap: `{balance.get('normal_owned_weapons_cap', balance.get('max_owned_weapons', 5))}`",
        f"- Level-up passive cap: `{balance.get('normal_owned_passives_cap', balance.get('max_owned_passives', 5))}`",
        f"- Field pickup can exceed cap: `{balance.get('field_pickup_can_exceed_cap', True)}`",
        f"- Field over-cap max bonus: `{balance.get('field_over_cap_max_bonus', 0)}`",
        "",
        "## Automated Coverage",
        "",
        "- `test_selection_skip_seal_actions.gd` verifies run-only seal, skip reward, counts, shop unlock, and re-generation.",
        "- `test_candidate_pool_respects_disabled_items.gd` verifies persistent OFF pools still apply to level-up and field core choices.",
        "- `test_core_pickup_choice_ui.gd` verifies core pickup opens visible accept/decline choices and can grant over cap.",
        "- `test_equipment_over_cap_field_pickup.gd` verifies field/core pickup can show 6/5 while level-up new items respect 5/5.",
        "",
        "## Guardrails",
        "",
        "- Seal is run-only and does not mutate persistent disabled weapon/passive arrays.",
        "- Skip gives a small recovery/score reward and closes only the current choice.",
        "- Field/core grants use explicit over-cap sources; level-up grants do not.",
        "",
    ]
    output = ROOT / "test-output" / "candidate_pool_qa.md"
    output.parent.mkdir(parents=True, exist_ok=True)
    output.write_text("\n".join(lines), encoding="utf-8", newline="\n")
    print(f"Wrote {output}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
