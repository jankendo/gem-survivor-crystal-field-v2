#!/usr/bin/env python3
"""Create a deterministic balance report from project data and an optional run log."""

from __future__ import annotations

import argparse
import csv
import json
from pathlib import Path
from statistics import mean


ROOT = Path(__file__).resolve().parents[1]
CATEGORY_DAMAGE = {
    "ranged": 0.92,
    "melee": 1.20,
    "lightning": 0.92,
    "poison": 0.84,
    "explosion": 1.08,
    "deploy": 0.92,
    "gem": 0.80,
    "knockback": 0.84,
    "crystal": 0.94,
}


def display_path(path: Path) -> str:
    try:
        return str(path.resolve().relative_to(ROOT.resolve()))
    except ValueError:
        return str(path)


def load_json(name: str) -> dict:
    with (ROOT / "data" / name).open(encoding="utf-8") as handle:
        return json.load(handle)


def seconds(value: str) -> float:
    if ":" in value:
        minutes, remainder = value.split(":", 1)
        return float(minutes) * 60.0 + float(remainder)
    return float(value or 0)


def number(row: dict, key: str) -> float:
    try:
        return float(row.get(key, 0) or 0)
    except (TypeError, ValueError):
        return 0.0


def weapon_proxy(weapon: dict) -> float:
    damage = float(weapon.get("base_damage_score", weapon.get("base_damage", 1.0)))
    cooldown = max(0.2, float(weapon.get("base_cooldown_score", weapon.get("cooldown", 1.5))))
    reach = min(900.0, float(weapon.get("range", 300.0)))
    category = str(weapon.get("category", ""))
    reach_factor = 0.78 + reach / 3000.0
    return damage * CATEGORY_DAMAGE.get(category, 1.0) * reach_factor / cooldown


def load_log(path: Path) -> list[dict]:
    if not path.exists():
        return []
    with path.open(newline="", encoding="utf-8-sig") as handle:
        return list(csv.DictReader(handle))


def load_optional_json(path: Path) -> dict:
    if not path.exists():
        return {}
    with path.open(encoding="utf-8") as handle:
        value = json.load(handle)
    return value if isinstance(value, dict) else {}


def nearest_row(rows: list[dict], target: float) -> dict | None:
    if not rows:
        return None
    return min(rows, key=lambda row: abs(seconds(str(row.get("time", "0"))) - target))


def candidate_lines(items: list[tuple[str, dict, float]]) -> list[str]:
    return [
        f"- `{weapon_id}` ({data.get('name_ja', weapon_id)}): proxy `{score:.3f}`, "
        f"category `{data.get('category', 'unknown')}`, range `{data.get('range', 0)}`"
        for weapon_id, data, score in items
    ]


def build_report(
    rows: list[dict],
    log_path: Path,
    candidate_runs: dict,
    run_summary: dict,
) -> str:
    weapons = load_json("weapons.json")
    passives = load_json("passives.json")
    evolutions = load_json("evolutions.json")
    balance = load_json("balance.json")
    scored = sorted(
        ((weapon_id, data, weapon_proxy(data)) for weapon_id, data in weapons.items()),
        key=lambda item: item[2],
        reverse=True,
    )
    category_scores: dict[str, list[float]] = {}
    for _, data, score in scored:
        category_scores.setdefault(str(data.get("category", "unknown")), []).append(score)
    measured = candidate_runs.get("runs", []) if isinstance(candidate_runs.get("runs", []), list) else []
    measured = [row for row in measured if isinstance(row, dict)]
    measured_dps = [number(row, "dps") for row in measured if number(row, "dps") > 0]
    measured_median = sorted(measured_dps)[len(measured_dps) // 2] if measured_dps else 0.0

    lines = [
        "# Balance Report",
        "",
        "This report is diagnostic only. It never rewrites balance data.",
        "",
        "## Input",
        "",
        f"- Weapons: {len(weapons)}",
        f"- Passives: {len(passives)}",
        f"- Evolutions: {len(evolutions)}",
        f"- Run log: `{display_path(log_path)}` ({'loaded' if rows else 'not available; static analysis only'})",
        f"- Candidate run audit: {'loaded' if measured else 'not available'}",
        f"- Runtime summary: {'loaded' if run_summary else 'not available'}",
        "",
        "## Strong Candidates",
        "",
        *candidate_lines(scored[:5]),
        "",
        "## Weak Candidates",
        "",
        *candidate_lines(list(reversed(scored[-5:]))),
        "",
        "## Category DPS Proxy",
        "",
        "| Category | Weapons | Mean proxy |",
        "| --- | ---: | ---: |",
    ]
    for category in sorted(category_scores):
        values = category_scores[category]
        lines.append(f"| {category} | {len(values)} | {mean(values):.3f} |")

    lines.extend(
        [
            "",
            "## Actual Run DPS",
            "",
            "| Weapon | DPS | Boss damage | Enemy damage | Pick count | Evolved |",
            "| --- | ---: | ---: | ---: | ---: | :---: |",
        ]
    )
    for row in sorted(measured, key=lambda item: number(item, "dps"), reverse=True):
        weapon_id = str(row.get("weapon_id", "unknown"))
        name = weapons.get(weapon_id, {}).get("name_ja", weapon_id)
        lines.append(
            f"| `{weapon_id}` ({name}) | {number(row, 'dps'):.2f} | "
            f"{int(number(row, 'boss_damage'))} | {int(number(row, 'enemy_damage'))} | "
            f"{int(number(row, 'pick_count'))} | {'yes' if row.get('evolved') else 'no'} |"
        )
    if not measured:
        lines.append("| n/a | n/a | n/a | n/a | n/a | n/a |")

    high_measured = [
        row for row in measured
        if measured_median > 0 and number(row, "dps") >= measured_median * 1.8
    ]
    low_measured = [
        row for row in measured
        if measured_median > 0 and number(row, "dps") <= measured_median * 0.35
    ]
    lines.extend(["", "## Measured Outliers", ""])
    lines.append(f"- Median measured DPS: {measured_median:.2f}")
    lines.append(
        "- Strong candidates: "
        + (", ".join(f"`{row.get('weapon_id')}`" for row in high_measured) or "none")
    )
    lines.append(
        "- Weak candidates: "
        + (", ".join(f"`{row.get('weapon_id')}`" for row in low_measured) or "none")
    )
    lines.append("- Interpret deploy/area outliers as dense-pack specialization, not universal single-target DPS.")

    lines.extend(
        [
            "",
            "## Usage and Evolution Rate",
            "",
            f"- Weapon picks: `{json.dumps(run_summary.get('weapon_pick_count_by_id', {}), ensure_ascii=False)}`",
            f"- Passive picks: `{json.dumps(run_summary.get('passive_pick_count_by_id', {}), ensure_ascii=False)}`",
            f"- Evolved weapons: `{json.dumps(run_summary.get('weapon_evolved_by_id', {}), ensure_ascii=False)}`",
            f"- Disabled weapons: `{json.dumps(run_summary.get('disabled_weapons', []), ensure_ascii=False)}`",
            f"- Disabled passives: `{json.dumps(run_summary.get('disabled_passives', []), ensure_ascii=False)}`",
            "- OFF rate requires multiple player runs; this report records disabled lists without inventing population usage.",
            "",
            "## Evolution Timing",
            "",
            f"- First evolution gate: {float(balance.get('first_evolution_seconds', 300.0)) / 60.0:.1f} minutes.",
            f"- Evolution cooldown: {float(balance.get('evolution_cooldown_seconds', 180.0)) / 60.0:.1f} minutes.",
            f"- Overclock delay after evolution: {float(balance.get('overclock_delay_seconds', 120.0)) / 60.0:.1f} minutes.",
            "- Early evolution candidate: any first evolution before the configured gate.",
            "- Late evolution candidate: no evolution by 10 minutes in a build that met its material requirements.",
            "",
            "## Survival Pressure at 5/10/20/30 Minutes",
            "",
            "| Time | HP | Enemies | Damage/min | Difficulty | Kills |",
            "| --- | ---: | ---: | ---: | ---: | ---: |",
        ]
    )
    for minute in (5, 10, 20, 30):
        row = nearest_row(rows, minute * 60.0)
        if row is None:
            lines.append(f"| {minute}m | n/a | n/a | n/a | n/a | n/a |")
        else:
            lines.append(
                f"| {minute}m | {number(row, 'hp_percent'):.1%} | "
                f"{int(number(row, 'enemy_count'))} | {int(number(row, 'damage_taken_last_minute'))} | "
                f"{number(row, 'difficulty_factor'):.2f} | {int(number(row, 'kill_count'))} |"
            )

    final = rows[-1] if rows else {}
    lines.extend(
        [
            "",
            "## Level Ups",
            "",
            f"- Final level: {int(number(final, 'level')) if final else 'n/a'}",
            f"- Last-minute level ups: {int(number(final, 'levelups_last_minute')) if final else 'n/a'}",
            "",
            "## Currency Gain",
            "",
            f"- Logged currency gain: {int(number(final, 'currency_gain')) if final else 'n/a'}",
            "- Currency should be reviewed across multiple characters; Lily and SS rank bonuses are intentionally capped below their previous values.",
            "",
            "## Healing Load",
            "",
            f"- Healing by source: `{json.dumps(run_summary.get('healing_by_source', {}), ensure_ascii=False)}`",
            "- Runtime caps: regen <= 3 HP/s, pickup heal <= 4 HP, oasis heal <= 6 HP per 2.5 seconds.",
            "- Defensive and economy passives are evaluated by survival/healing/currency contribution, not direct DPS.",
            "",
            "## DPS Guide",
            "",
            f"- Total logged weapon damage: {int(number(final, 'total_weapon_damage')) if final else 'n/a'}",
            "- Proxy scores compare metadata and category modifiers, not real multi-target DPS.",
            "- Confirm outliers with category autoplays and `weapon_damage_by_id` run summaries before changing values.",
            "",
            "## Adjustment Notes",
            "",
            "- Ice orbit, corridor blade, and relic chain were reduced after measured dense-pack output.",
            "- Gravity anchor damage attribution was fixed and its pull identity retained.",
            "- Black hole and rune gate were not blindly buffed because measured dense-pack DPS was already high.",
            "- Might, cooldown, and area passives were slightly reduced; corridor, room, choke-point, and mining specializations were slightly strengthened.",
            "",
            "## Change Verification",
            "",
            "- Re-run candidate audit and all seven category 10-minute autoplays.",
            "- Compare boss damage separately from enemy damage.",
            "- Review real-player pick, OFF, evolution, death-cause, healing, and currency-source data across multiple runs.",
            "",
        ]
    )
    return "\n".join(lines)


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--log", type=Path, default=ROOT / "run_balance_log.csv")
    parser.add_argument("--output", type=Path, default=ROOT / "balance_report.md")
    parser.add_argument("--candidate-runs", type=Path, default=ROOT / "test-output" / "balance_candidate_runs.json")
    parser.add_argument("--summary", type=Path, default=ROOT / "run_balance_summary.json")
    args = parser.parse_args()
    rows = load_log(args.log)
    report = build_report(
        rows,
        args.log,
        load_optional_json(args.candidate_runs),
        load_optional_json(args.summary),
    )
    args.output.write_text(report, encoding="utf-8", newline="\n")
    print(f"Wrote {args.output} ({len(rows)} log rows)")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
