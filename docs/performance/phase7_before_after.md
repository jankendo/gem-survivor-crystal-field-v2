# Phase 7 Before / After

## Conditions

* Godot `4.7.stable.official.5b4e0cb0f`
* renderer `gl_compatibility`
* fixture seed `70707` plus deterministic scenario hash
* five scenarios, 20 simulated seconds each
* 600 enemies, 500 projectiles, 1,000 gems
* evolved multi-projectile, explosion, persistent area, arc/lightning and combined builds
* Windows headless CPU proxy, not real iPhone GPU evidence

## Result

| Metric | Before / Phase 6-equivalent | After |
| --- | ---: | ---: |
| visual commands | 7,240 | 1,880 |
| coalesced commands | 0 | 5,360 |
| visual command reduction | 0% | 74.03% |
| transient allocation proxy | 7,240 | 1,880 |
| transient proxy reduction | 0% | 74.03% |
| maximum p95 | Phase 6-equivalent loop varied by scenario | 2.368 ms in the recorded run |
| maximum p99 | not comparable | 3.427 ms in the recorded run |
| frames over 100 ms | not comparable | 0 |
| Critical missing | not budgeted | 0 |
| simulation hash | baseline | exact match |

The absolute Phase 7 stress criteria p95 below 16.67 ms, p99 below 33 ms and
100 ms exceedances zero passed in the local synthetic harness.

The requested 30% p95 improvement against the Phase 6-equivalent allocation
loop did not pass consistently. Command reduction and parity are proven, but
the RefCounted harness overhead and headless wall clock do not demonstrate a
real iPhone CPU/GPU improvement. This remains an explicit device-validation
gate rather than being hidden by changing the workload.

The separate Phase 6 seed-60606 gameplay regression run produced average
60 FPS, p50 `4.869 ms`, p95 `8.589 ms`, p99 `36.942 ms`, 99 frames above
33 ms, enemy spawn `212`, kills `199` and alive `13`. Gameplay results match
the Phase 6 baseline, but this single headless wall-clock run is slower and
does not satisfy the Phase 6 p99/33 ms goal.

## Source Hot-loop Delta

Across `SurvivorState`, `WeaponSystem`, `ArenaView` and `GameScreen`:

| Operation | Before | After |
| --- | ---: | ---: |
| `duplicate(` | 24 | 18 |
| `.erase(` | 11 | 2 |
| `pop_front(` | 8 | 0 |

Remaining duplicates are setup, summary or non-frame operations. `weapon_effect`
call sites remain but now return an O(1) cached read-only style.
