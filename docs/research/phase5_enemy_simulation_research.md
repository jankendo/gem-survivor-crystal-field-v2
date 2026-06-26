# Phase 5 Enemy Simulation Research

## Problem

Phase 4時点のホットパスは、敵が増えるほど`state.enemies.duplicate()`と全敵走査が増える構造だった。iOSで敵数を減らすのではなく、同じ敵数を処理するために探索範囲を狭める必要がある。

## Adopted Design

- Structure of Arraysの試験実装を`EnemyEntityStore.gd`へ追加。
- free listとgeneration idで古い参照を無効化。
- `SpatialHashGrid2D.gd`で武器判定のbroad phaseを共有。
- `EnemyFrameScheduler.gd`で距離別更新間隔とローテーションを契約化。
- `CombatFrameBudgetScheduler.gd`で将来の被ダメージイベント分割を契約化。

## Gameplay Contract

- iOSプロファイルは`max_enemies`を変更しない。
- ボス出現時に既存敵を削除しない。
- ボス召喚や分裂子は上限到達を理由に消さない。
- スポーンカーブ、敵HP、敵攻撃力、敵速度、敵スポーン倍率はプラットフォームで弱体化しない。

## Tests

- `tests/test_enemy_entity_store.gd`
- `tests/test_enemy_free_list.gd`
- `tests/test_enemy_simulation_determinism.gd`
- `tests/test_enemy_update_lod.gd`
- `tests/test_phase5_spatial_hash_grid.gd`
- `tests/test_phase5_no_enemy_culling.gd`
- `tests/test_phase5_no_difficulty_reduction.gd`
- `tests/test_phase5_spawn_curve_parity.gd`
- `tests/test_phase5_enemy_count_parity.gd`
