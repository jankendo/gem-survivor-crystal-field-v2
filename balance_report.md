# Balance Report

This report is diagnostic only. It never rewrites balance data.

## Input

- Weapons: 31
- Passives: 39
- Evolutions: 26
- Run log: `run_balance_log.csv` (not available; static analysis only)

## Strong Candidates

- `ice_orbit` (氷輪): proxy `2.632`, category `area`, range `180`
- `blade_fan` (刃扇): proxy `1.548`, category `melee`, range `260`
- `corridor_blade` (回廊刃): proxy `1.429`, category `melee`, range `290`
- `magic_bolt` (魔弾): proxy `1.378`, category `ranged`, range `900`
- `relic_chain` (遺物鎖): proxy `1.150`, category `melee`, range `270`

## Weak Candidates

- `black_hole` (小型重力球): proxy `0.258`, category `area`, range `680`
- `gravity_anchor` (重力錨): proxy `0.302`, category `area`, range `660`
- `frost_wall` (氷壁): proxy `0.314`, category `deploy`, range `280`
- `rune_gate` (ルーン門): proxy `0.337`, category `deploy`, range `520`
- `mine_lantern` (鉱灯): proxy `0.343`, category `deploy`, range `520`

## Category DPS Proxy

| Category | Weapons | Mean proxy |
| --- | ---: | ---: |
| area | 3 | 1.064 |
| crystal | 2 | 0.634 |
| deploy | 5 | 0.354 |
| explosion | 3 | 0.482 |
| gem | 2 | 0.571 |
| knockback | 2 | 0.393 |
| laser | 1 | 0.736 |
| lightning | 1 | 0.636 |
| melee | 4 | 1.282 |
| poison | 2 | 0.715 |
| ranged | 5 | 0.985 |
| summon | 1 | 0.812 |

## Unused Weapons

- Per-weapon pick data is unavailable in the standard CSV. Use `weapon_damage_by_id` from run summaries for pick and usage diagnosis.

## Overused Weapons

- No overuse claim is made without per-weapon pick counts from multiple runs.

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

- The standard log does not yet separate every healing source.
- Runtime caps: regen <= 3 HP/s, pickup heal <= 4 HP, oasis heal <= 6 HP per 2.5 seconds.

## DPS Guide

- Total logged weapon damage: n/a
- Proxy scores compare metadata and category modifiers, not real multi-target DPS.
- Confirm outliers with category autoplays and `weapon_damage_by_id` run summaries before changing values.
