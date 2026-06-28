# Phase 7 iOS Effect Audit

## Audit Baseline

* Base commit: `f56d4a3a163a054a9614e3341bcc3d16645d00d7`
* Godot: `4.7.stable.official.5b4e0cb0f`
* Renderer: Windows/iOS `gl_compatibility`
* Phase 6 benchmark: seed `60606`, 60 seconds
* Real iPhone, Metal GPU, thermal and battery measurements: not available

## Confirmed Hot Paths

| Area | Before behavior | Risk |
| --- | --- | --- |
| `SurvivorState.weapon_effect()` | Deep-copies a nested Dictionary for every lookup | Per-projectile draw allocation |
| `SurvivorState.trim_runtime_arrays()` | Uses `pop_front()` for projectiles, enemy projectiles and gems | O(n) shifts and simulation loss |
| `PerformanceProfileSystem` | Writes iOS quality caps into simulation keys | iOS result can diverge |
| `WeaponSystem._process_projectiles()` | Copies the projectile array, then calls `has()` and `erase()` | Repeated allocations and scans |
| `WeaponSystem._process_bombs()` | Copies and erases the bomb array | Repeated allocations and scans |
| `_explode()` and `_damage_enemy()` | Explosion flash plus a flash for every damaged enemy | Duplicate visual commands |
| `GameScreen._tick_flashes()` | Copies and erases four runtime arrays | Per-frame transient arrays |
| iOS effect filtering | Replaces state effect arrays with visible-only arrays | Visual budget mutates runtime state |
| `ArenaView` projectile/effect draw | Calls `weapon_effect()` inside draw loops | Deep copies in Canvas draw |
| Minimap | Cadence counter changes, but all content is scanned and drawn every draw | No actual traversal reduction |
| Terrain cache | Caches command Dictionaries, not rendered chunks | Submission count remains high |

Static source count across the four hot files before Phase 7:

| Operation | Occurrences |
| --- | ---: |
| `duplicate(` | 24 |
| `.erase(` | 11 |
| `pop_front(` | 8 |
| `weapon_effect(` | 6 |
| `draw_arc(` | 31 |

The files are already large (`SurvivorState.gd` 1,631 lines, `WeaponSystem.gd` 739,
`ArenaView.gd` 948 and `GameScreen.gd` 2,391), so Phase 7 logic must live in
dedicated systems.

## Phase 6 Runtime Evidence

`test-output/phase6/after_4_7_compatibility.json` records:

* frame p50/p95/p99: `4.033 / 5.515 / 31.697 ms`
* frames over 33 ms: `18`
* peak enemies/projectiles/gems/effects: `19 / 15 / 153 / 4`
* minimap content draws: `60`
* static tile draw submissions: `30,560`

This scenario does not exercise evolved-weapon worst cases. Phase 7 therefore
adds deterministic 20-30 second snapshots with 600 enemies and high projectile,
gem and effect density. Headless results are CPU and contract evidence only.

## Required Corrections

1. Preserve simulation arrays regardless of visual quality.
2. Select render-only views deterministically without replacing state arrays.
3. Cache resolved weapon styles by weapon, evolution and quality.
4. Compact runtime arrays in place and avoid front removal.
5. Coalesce duplicate visual commands while retaining critical and signature cues.
6. Cache minimap command data and use adaptive arc segment counts.
7. Record command, cache, pool and primitive counters only in explicit QA runs.

## Invariants

Enemy count, spawn curve, damage, attack cadence, projectile collision, gems,
EXP, rewards, bosses, summons, splits, RNG stream order, game speed, save format,
Safe Area, Bundle ID and executable name are not Phase 7 tuning levers.

