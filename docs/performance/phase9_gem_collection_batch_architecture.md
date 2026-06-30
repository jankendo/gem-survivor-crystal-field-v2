# Phase 9 Gem Collection Batch Architecture

## 契約

* ジェムの取得、EXP加算、レベルアップ判定、報酬、RNGはvisual animationを待たずにsimulation側で即時確定する。
* 表示上限でsimulation gemを削除、統合、近似しない。
* 1,200個回収でも個別Tween、個別Node、個別floating text、個別ringを生成しない。

## 構成

* `GemCollectionVisualBatchSystem.gd`: source、total_count、total_exp、centroid、player_position、representative_positionsを持つbatchを作る。
* `GemCollectionBatchProcessor.gd`: 全回収結果のmetricsに`proxy_nodes`、`visual_batch_count`、`representative_gem_count`を含める。
* `data/gem_collection_effects.json`: `visual_mode=batch_minimal`、代表4件、ring上限2を定義する。
* `ArenaView.gd`: minimal時はring/proxy描画をさらに縮退する。

## Phase 9 fixture

1,200ジェムの表示代表は4件。visual command削減とtemporary allocation proxy削減は99.67%。EXP合計は4,794で、simulation hashはbefore/after一致した。

## 未検証

実iPhone GPUでのdraw call、CanvasItem、thermal、batteryは未確認。`docs/qa/phase9_ios_real_device_checklist.md`で別途確認する。
