# Phase 9 Before / After

## 比較条件

Phase 8の`phase8_before_after.md`はglobal visual commandの合成比較だった。Phase 9では敵、ジェム収集、scan queryを分けたWindows headless CPU fixtureを追加したため、絶対値は直接比較しない。

## Phase 8からの変更

| 項目 | Phase 8 | Phase 9 |
| --- | --- | --- |
| selection action | 共有選択UIにlevel-up操作が混ざり得る | `SelectionContextSystem`でLEVEL_UPだけ表示/消費 |
| 敵minimal | projectile/effect中心の表示削減 | 通常敵HP、影、glow、二次motionを停止しbatch command化 |
| gem全回収 | simulationは一括、表示はring/proxyが残る | 代表4件以内のbatch visual |
| damage number | minimalでは0、設定経路あり | 機能と設定項目を廃止 |
| touch haptic | minimalではoff、設定経路あり | 機能と設定項目を廃止 |
| scan | field help相当 | 発見、探査共鳴、長押し抽出、map/room発見へ拡張 |
| result | ラン結果中心 | 武器別総ダメージと割合を追加 |

## Phase 9 fixture

| 指標 | 値 |
| --- | ---: |
| enemy visual command削減 | 98.65% |
| enemy visual CPU p95削減 | -31.16% |
| gem collection visual command削減 | 99.67% |
| gem collection CPU p95削減 | 98.37% |
| temporary allocation proxy削減 | 99.67% |
| frame p50/p95/p99 | 3.558 / 4.395 / 4.822 ms |
| 33ms/100ms超過 | 0 / 0 |
| simulation parity | true |

## 未達

敵visual CPU p95は今回のfixtureでは改善していない。表示コマンド削減を先に入れた段階であり、CPU hot loopの本格削減は次の作業に残す。
