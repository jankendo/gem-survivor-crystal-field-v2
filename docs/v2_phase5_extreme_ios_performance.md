# Phase 5: Extreme iOS Performance & Combat Readability

## Scope

Phase 5は、敵数、スポーン量、難易度、ボス、報酬を削らずにiOS終盤のフレーム時間を安定させる内部基盤フェーズである。新コンテンツ数より、処理構造と視認性を優先する。

## Baseline

- Baseline file: `test-output/phase5/baseline_performance.json`
- Capture: Windows headless synthetic iOS harness, 1 minute
- Average FPS: 60
- p95/p99 frame time: 2.009 ms
- Max enemies: 124
- Limitation: real iOS device, Metal System Trace, thermal, battery telemetry are not captured in this Windows environment.

## Delivered

- iOS performance profiles no longer reduce `max_enemies`.
- Boss spawn no longer deletes existing enemies when the enemy list is full.
- Boss minions and split children are not skipped by the enemy cap path.
- Weapon hot loops for beam, pulse, aura, black hole, rune gate, explosions, and slow splash use `SpatialHashGrid2D`.
- Data-oriented enemy store, scheduler, and frame budget contracts are added for future deeper migration.
- Phase 5 environment textures are regenerated with luma separation and pickup confusion audits.

## Not Done

- Real iOS device run.
- Metal System Trace.
- Signed install.
- Full GDExtension port. Decision is documented as deferred.
