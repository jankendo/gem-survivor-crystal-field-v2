# Phase 9 Enemy / Gem / Scan Audit

## 実装前監査

* selection actionはレベルアップ、コア、宝箱、契約などで共有され、contextが明示されていなかった。
* 敵表示はArenaView側の個別描画が中心で、通常敵のHPバー、影、glow、phase計算がminimal時にも混ざりやすい構造だった。
* ジェム全回収はsimulation結果は正しいが、ring/proxy表示数が終盤負荷の独立要因になり得た。
* damage numberとtouch hapticはPhase 8で軽量化されていたが、設定名と旧保存値経路が残っていた。
* scanは既存のfield helpに近く、探索の中心機能としては報酬、発見履歴、長押し目的が弱かった。

## 実装後監査

* `SelectionContextSystem.gd`でLEVEL_UPだけ再抽選、skip、seal、banishを許可する。
* `EnemyRenderSnapshotSystem.gd`はsimulation enemyから表示専用commandを作るだけで、position、HP、RNGを変更しない。
* `EnemyVisualBatchSystem.gd`は通常敵をtype/phase/outlineでまとめ、critical enemyは個別に残す。
* `GemCollectionVisualBatchSystem.gd`は1,200個回収でも代表4件の表示に抑え、EXPは即時確定する。
* `CrystalSurveySystem.gd`は`FieldObjectAvailabilitySystem`を通し、`unlock_seconds`前や未購入相当の不正抽出を避ける。
* telemetryは`scan_telemetry`へローカル記録し、オンライン送信しない。

## 測定結果

`test-output/phase9/phase9_extreme_stress.md`はWindows headless CPU fixtureである。実iPhone、Metal、thermal、batteryの証明ではない。

| 指標 | 結果 |
| --- | ---: |
| seed | 90909 |
| enemy count | 600 |
| projectile count | 700 |
| gem count | 1,200 |
| frame p50 | 3.558 ms |
| frame p95 | 4.395 ms |
| frame p99 | 4.822 ms |
| 33ms超過 | 0 |
| 100ms超過 | 0 |
| enemy command削減 | 98.65% |
| enemy visual CPU p95削減 | -31.16% |
| gem collection command削減 | 99.67% |
| gem collection CPU p95削減 | 98.37% |
| temporary allocation proxy削減 | 99.67% |
| scan query p95 | 2.018 ms |
| Critical欠落 | 0 |
| simulation parity | true |

## 判断

敵は表示コマンド削減を達成したが、Windows headlessの単純snapshot p95ではCPU削減未達である。次フェーズでsnapshot buffer再利用、visible rect事前絞り込み、EnemyEntityStore直読み、Dictionary command削減を優先する。

ジェム収集とscanはPhase 9の回帰検出として十分な余裕がある。実GPU負荷は未検証のため、iOS実機チェックリストを残す。
