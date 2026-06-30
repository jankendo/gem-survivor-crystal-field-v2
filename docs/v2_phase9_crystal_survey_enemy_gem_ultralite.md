# Phase 9 Crystal Survey / Enemy & Gem Ultra-Lite

## 目的

Phase 9は、Phase 8の極限軽量表示と省電力実効設定を維持したまま、探索スキャンをラン内の短期目標へ引き上げ、終盤の敵表示と大量ジェム回収表示をさらに軽くする更新である。Windows/iOSともGodot 4.7 stable、GDScript、`gl_compatibility`を正本とする。

## 採用範囲

* レベルアップ専用操作は`SelectionContextSystem`で通常EXPレベルアップだけに限定する。
* 敵simulationと敵visual snapshotを分離し、通常敵はminimal時にHPバー、影、glow、二次モーションを省略する。
* 敵描画は`EnemyRenderSnapshotSystem`と`EnemyVisualBatchSystem`で通常敵を型、phase、outline単位へbatch化する。
* ジェム取得結果は即時確定し、`GemCollectionVisualBatchSystem`で代表4件以内の表示だけを作る。
* 最高生存時間は分秒形式で表示する。
* ダメージ数字とタッチ振動は設定UI、実効設定、旧保存値の反映から廃止する。
* ポーズ中に現在seedを確認、コピーできる。
* リザルトに武器別総ダメージと割合を表示する。
* スキャンは部屋、アイテム、イベント、敵、地形を発見し、初回発見でラン内値`survey_resonance`を得る。
* スキャン長押しは`survey_resonance`満タン時に封印対象を抽出し、通常のpickup/choice処理へ接続する。

## 非採用範囲

* 敵数、スポーン数、HP、攻撃、速度、DPS、EXP、通貨、報酬、RNG順の削減や近似は行わない。
* MultiMeshは今回の正本にしない。Compatibility/iOSで安定高速化を実測するまで、ArenaView側のbatch draw commandを正本にする。
* スキャンはショップ永久解放、`unlock_seconds`、イベント達成条件を回避しない。
* 市場調査は設計仮説の材料であり、スキャンが他作品の評価や売上を生んだ原因とは扱わない。

## 検証

* `tests/phase9_test_runner.gd`: 340 assertions。
* `test-output/phase9/phase9_extreme_stress.md`: Windows headless CPU fixture。実iPhone、Metal、thermal、batteryの証明ではない。
* Phase 9 fixture結果: p50 3.558ms、p95 4.395ms、p99 4.822ms、33ms超過0、100ms超過0。
* 敵表示コマンド削減は98.65%。ただし同fixtureの敵visual CPU p95は31.16%悪化で、追加最適化対象として残す。
* ジェム収集visual CPU p95削減は98.37%、temporary allocation proxy削減は99.67%。
* scan query p95は2.018ms。

## 正本文書

* 市場調査: `docs/research/phase9_scan_market_research.md`
* 監査/性能: `docs/performance/phase9_enemy_gem_scan_audit.md`
* Before/After: `docs/performance/phase9_before_after.md`
* 敵描画構成: `docs/performance/phase9_enemy_render_architecture.md`
* ジェムbatch構成: `docs/performance/phase9_gem_collection_batch_architecture.md`
* スキャン設計: `docs/design/phase9_crystal_survey_design.md`
* UI/Result監査: `docs/qa/phase9_ui_result_audit.md`
* iOS実機確認: `docs/qa/phase9_ios_real_device_checklist.md`
* 手動評価票: `docs/qa/phase9_scan_playtest_form.md`
