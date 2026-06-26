# Object Pool Contract

## Current Owner

`PoolManager.gd` is the active runtime pool. `SurvivorState` registers enemy, projectile, gem, hit flash, effect line, and damage text pools.

## Phase 5 Rule

Pooling can reduce allocation churn, but it cannot hide result loss. Reused objects must be fully reset before returning to gameplay.

## Tests

- `tests/test_ios_object_pooling_stability.gd`
- `tests/test_enemy_free_list.gd`

## Future Work

If enemy simulation migrates to SoA, the object pool remains the compatibility layer for visual and reward-facing objects until UI and rendering are also migrated.
