# Balance Report

This report is diagnostic only. It never rewrites balance data.

## Input

- Weapons: 31
- Passives: 39
- Evolutions: 26
- Run log: `run_balance_log.csv` (not available; static analysis only)
- Candidate run audit: loaded
- Runtime summary: not available

## Strong Candidates

- `ice_orbit` (氷輪): proxy `2.174`, category `area`, range `180`
- `blade_fan` (刃扇): proxy `1.548`, category `melee`, range `260`
- `magic_bolt` (魔弾): proxy `1.378`, category `ranged`, range `900`
- `corridor_blade` (回廊刃): proxy `1.155`, category `melee`, range `290`
- `poison_mist` (毒霧): proxy `1.084`, category `poison`, range `240`

## Weak Candidates

- `black_hole` (小型重力球): proxy `0.258`, category `area`, range `680`
- `gravity_anchor` (重力錨): proxy `0.302`, category `area`, range `660`
- `frost_wall` (氷壁): proxy `0.314`, category `deploy`, range `280`
- `rune_gate` (ルーン門): proxy `0.337`, category `deploy`, range `520`
- `mine_lantern` (鉱灯): proxy `0.343`, category `deploy`, range `520`

## Category DPS Proxy

| Category | Weapons | Mean proxy |
| --- | ---: | ---: |
| area | 3 | 0.911 |
| crystal | 2 | 0.634 |
| deploy | 5 | 0.354 |
| explosion | 3 | 0.482 |
| gem | 2 | 0.571 |
| knockback | 2 | 0.393 |
| laser | 1 | 0.736 |
| lightning | 1 | 0.636 |
| melee | 4 | 1.166 |
| poison | 2 | 0.715 |
| ranged | 5 | 0.985 |
| summon | 1 | 0.812 |

## Actual Run DPS

| Weapon | DPS | Boss damage | Enemy damage | Pick count | Evolved |
| --- | ---: | ---: | ---: | ---: | :---: |
| `black_hole` (小型重力球) | 653.12 | 14000 | 377874 | 1 | no |
| `rune_gate` (ルーン門) | 530.77 | 13710 | 304755 | 1 | no |
| `gravity_anchor` (重力錨) | 346.24 | 8000 | 199744 | 1 | no |
| `frost_wall` (氷壁) | 300.00 | 0 | 180000 | 1 | no |
| `mine_lantern` (鉱灯) | 300.00 | 0 | 180000 | 1 | no |
| `ice_orbit` (氷輪) | 239.19 | 11952 | 131562 | 1 | no |
| `corridor_blade` (回廊刃) | 226.67 | 0 | 136000 | 1 | no |
| `relic_chain` (遺物鎖) | 185.00 | 0 | 111000 | 1 | no |
| `blade_fan` (刃扇) | 60.00 | 0 | 36000 | 1 | no |
| `magic_bolt` (魔弾) | 21.67 | 0 | 13000 | 1 | no |

## Measured Outliers

- Median measured DPS: 300.00
- Strong candidates: `black_hole`
- Weak candidates: `blade_fan`, `magic_bolt`
- Interpret deploy/area outliers as dense-pack specialization, not universal single-target DPS.

## Usage and Evolution Rate

- Weapon picks: `{}`
- Passive picks: `{}`
- Evolved weapons: `{}`
- Disabled weapons: `[]`
- Disabled passives: `[]`
- OFF rate requires multiple player runs; this report records disabled lists without inventing population usage.

## Evolution Timing

- First evolution gate: 5.0 minutes.
- Evolution cooldown: 3.0 minutes.
- Overclock delay after evolution: 2.0 minutes.
- Early evolution candidate: any first evolution before the configured gate.
- Late evolution candidate: no evolution by 10 minutes in a build that met its material requirements.

## Survival Pressure at 5/10/20/30 Minutes

| Time | HP | Enemies | Damage/min | Difficulty | Kills |
| --- | ---: | ---: | ---: | ---: | ---: |
| 5m | n/a | n/a | n/a | n/a | n/a |
| 10m | n/a | n/a | n/a | n/a | n/a |
| 20m | n/a | n/a | n/a | n/a | n/a |
| 30m | n/a | n/a | n/a | n/a | n/a |

## Level Ups

- Final level: n/a
- Last-minute level ups: n/a

## Currency Gain

- Logged currency gain: n/a
- Currency should be reviewed across multiple characters; Lily and SS rank bonuses are intentionally capped below their previous values.

## Healing Load

- Healing by source: `{}`
- Runtime caps: regen <= 3 HP/s, pickup heal <= 4 HP, oasis heal <= 6 HP per 2.5 seconds.
- Defensive and economy passives are evaluated by survival/healing/currency contribution, not direct DPS.

## DPS Guide

- Total logged weapon damage: n/a
- Proxy scores compare metadata and category modifiers, not real multi-target DPS.
- Confirm outliers with category autoplays and `weapon_damage_by_id` run summaries before changing values.

## Adjustment Notes

- Ice orbit, corridor blade, and relic chain were reduced after measured dense-pack output.
- Gravity anchor damage attribution was fixed and its pull identity retained.
- Black hole and rune gate were not blindly buffed because measured dense-pack DPS was already high.
- Might, cooldown, and area passives were slightly reduced; corridor, room, choke-point, and mining specializations were slightly strengthened.

## Change Verification

- Re-run candidate audit and all seven category 10-minute autoplays.
- Compare boss damage separately from enemy damage.
- Review real-player pick, OFF, evolution, death-cause, healing, and currency-source data across multiple runs.
