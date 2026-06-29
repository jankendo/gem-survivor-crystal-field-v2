# Phase 8 iOS Extreme Lite Audit

## Baseline

* Base branch: `phase7/ios-effect-budget-fast-ci`
* Base commit: `077372d1789acf41c2953990f01895211e6a7048`
* Godot: `4.7.stable.official.5b4e0cb0f`
* Renderer: Windows/iOS `gl_compatibility`
* Real iPhone, Metal, thermal and battery evidence: unavailable

## Existing Phase 7 Contracts

Phase 7 already separates simulation arrays from rendered views, keeps Critical
visuals above soft budgets, coalesces short-lived visual commands, caches weapon
styles and limits QA metrics to explicit runs. Phase 8 must extend these systems
without changing enemies, projectile simulation, damage, collision, drops, EXP,
rewards or RNG order.

## Confirmed Remaining Cost

| Area | Current behavior | Phase 8 correction |
| --- | --- | --- |
| visual profiles | low/standard/high only | add desktop/iOS minimal profiles |
| battery saver | 45 FPS and modest cadence changes | resolve runtime-only minimal settings |
| weapon drawing | low profile still draws glow, secondary lines, trails and animated areas | common static minimal primitives |
| arcs | Critical uses 48 and ordinary arcs use 8-32 | minimal ordinary 8-12, Critical 24-32 |
| background | particles and biome decorations can still draw | zero particles and static background in minimal |
| minimap | cache exists but animation/profile flags are absent | 2-4 Hz static cache |
| frame pacing | writes `Engine.max_fps` | keep simulation deterministic and cap redraw cadence separately |

## Invariants

The comparison fixture must retain 600 enemies, simulation projectile/gem
counts, evolved weapons, overclocks, boss, split enemies, active event and touch
configuration. `ios_standard`, `ios_low`, `ios_minimal` and `battery_saver` must
produce identical simulation, damage, kill, EXP, score and RNG hashes.

## Implemented Result

`ios_minimal`は弾56、ジェム120、エフェクト20、ダメージ数字0、背景粒子0となった。600敵の決定的終盤fixtureでは`ios_low`の444 commandsから196 commandsへ55.86%削減し、Critical欠落0、simulation/damage/kill/EXP/score/RNG一致を確認した。実iPhone計測は未実施。
