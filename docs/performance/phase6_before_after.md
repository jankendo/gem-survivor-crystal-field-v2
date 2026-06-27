# Phase 6 Before / After

## 条件

seed 60606、60秒、60Hz固定simulation、同じ装備、同じ敵密度。数値はWindows headless合成CPU計測であり、実iPhone計測ではない。

| 指標 | 4.2 Forward+ Before | 4.2 Compatibility After | 4.7 Compatibility |
| --- | ---: | ---: | ---: |
| average FPS | 60 | 60 | 60 |
| p50 ms | 4.493 | 4.151 | 4.611 |
| p95 ms | 5.753 | 6.564 | 6.873 |
| p99 ms | 32.854 | 32.923 | 33.644 |
| >33ms | 30 | 33 | 65 |
| enemy_spawn | 212 | 212 | 212 |
| alive | 13 | 13 | 13 |
| kills | 199 | 199 | 199 |
| enemy peak | 19 | 19 | 19 |
| projectile peak | 15 | 15 | 15 |
| gem peak | 153 | 153 | 153 |
| effect peak | 4 | 4 | 4 |
| `_refresh()` | 3,600 | 225 | 225 |
| Label attempts | 37,583 | 12,312 | 12,312 |
| static rebuild | 60 | 14 | 14 |

4.2 Compatibility After比で4.7はp95 +4.71%、p99 +2.19%で5%以内。ゲーム結果とdraw/UI counterは一致した。

## 判定

UI全refreshは93.75%、static再構築は76.67%削減し、敵・弾・ジェム条件は維持した。一方で合成CPU benchmarkの「33ms超過0」は未達である。headless wall-clockにはOS schedulingと1秒ごとのrender flushが含まれるため、値を削除・補正せず記録する。実GPU/iPhoneの合否は実機計測待ち。
