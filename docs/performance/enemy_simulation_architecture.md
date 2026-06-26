# Enemy Simulation Architecture

## Current Runtime

The shipped runtime still uses `SurvivorEnemy` objects in `SurvivorState.enemies` for compatibility. Phase 5 reduces hot full-array scans without replacing the entire runtime in one destructive step.

## Phase 5 Foundation

- `EnemyEntityStore.gd`: SoA storage using Packed arrays.
- `EnemySimulationCore.gd`: deterministic stepping over the SoA store.
- `EnemyFrameScheduler.gd`: frame-to-frame work rotation and distance LOD.
- `SpatialHashGrid2D.gd`: shared broad phase for object and id queries.

## Migration Rule

Move one subsystem at a time. Do not rewrite `SurvivorState.gd`, `EnemySpawner.gd`, or `WeaponSystem.gd` wholesale. Every migration must preserve seed parity, alive count, kill count, boss count, elite count, and rewards.
