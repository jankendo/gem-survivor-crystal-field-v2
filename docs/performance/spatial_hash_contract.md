# Spatial Hash Contract

## Owner

`scripts/performance/SpatialHashGrid2D.gd`

## Contract

- Cell size defaults to 160 px.
- `rebuild(items)` is valid once per combat frame before weapon processing.
- Query methods return candidates, not guaranteed hits. Callers must keep precise radius/segment checks.
- Query buffers may be reused to reduce allocations.
- Spatial hash must never delete, hide, or merge enemies.

## Current Users

- `WeaponSystem.gd`
- `EnemySimulationCore.gd`

## Tests

- `tests/test_phase5_spatial_hash_grid.gd`
- Existing `tests/test_ios_spatial_optimization.gd`
