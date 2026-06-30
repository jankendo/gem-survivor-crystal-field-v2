# Phase 9 Enemy Render Architecture

## 契約

* simulation position、HP、attack、collision、RNGは敵の正本であり、render positionやsnapshot値をAI/攻撃へ戻さない。
* offscreen enemyは描画しないが、simulationからは削除しない。
* boss、elite、attack telegraphはCriticalとして残す。
* extreme batteryでも敵数、敵挙動、報酬、DPSは変更しない。

## 構成

* `EnemyRenderSnapshotSystem.gd`: enemy配列から表示専用commandを作る。
* `EnemyAnimationPhaseCache.gd`: type単位のphaseを6から10Hz程度へ量子化する。
* `EnemyVisualBatchSystem.gd`: 通常敵をtype、phase、outline layerでbatch化する。
* `ArenaView.gd`: minimal時は通常敵を単純形状へ描画し、HPバー/影/glowを省略する。

## MultiMesh A/B

Phase 9ではMultiMeshを正本採用していない。Compatibility RendererとiOS上でtransform uploadと素材切替の実測が必要で、Windows headlessだけでは採用判断できないためである。現時点の正本はdraw command batchである。

## 次の最適化候補

* snapshot commandのDictionary生成をstruct-like配列へ寄せる。
* camera rect内候補をEnemyEntityStore/SpatialHashGrid2Dから直接列挙する。
* type/color/radius/shape cacheをさらに前段へ寄せる。
* hit flash coalescingを敵type/area単位で統合する。
