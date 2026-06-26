# Frame Budget Contract

## Purpose

Frame budgets are allowed to distribute work over frames, but they are not allowed to reduce game results.

## Allowed

- AI path update cadence by distance.
- Damage event batching if queued events are eventually applied deterministically.
- Visual quality and effect density reduction.

## Forbidden

- Dropping enemies.
- Skipping scheduled spawns.
- Lowering HP, damage, speed, spawn curve, boss count, elite count, or rewards on iOS.

## Implementation

- `EnemyFrameScheduler.gd`
- `CombatFrameBudgetScheduler.gd`
- `IosPerformanceBudgetSystem.gd`

## Tests

- `tests/test_enemy_update_lod.gd`
- `tests/test_phase5_frame_budget_scheduler.gd`
- `tests/test_phase5_enemy_count_parity.gd`
