# Phase 8 Before / After

## 決定的終盤スナップショット

seed 60606、敵600、弾720、ジェム1,200、進化武器複数、過充電4、ボス1、分裂敵、進行中イベントを共通入力としたWindows headless合成比較。

| 指標 | ios_standard | ios_low | ios_minimal | battery_saver |
| --- | ---: | ---: | ---: | ---: |
| visual commands | 706 | 444 | 196 | 196 |
| rendered projectiles | 190 | 120 | 56 | 56 |
| rendered effects | 96 | 64 | 20 | 20 |
| rendered gems | 420 | 260 | 120 | 120 |
| damage numbers | 36 | 24 | 0 | 0 |
| background particles | 90 | 48 | 0 | 0 |
| arc vertex estimate | 264 | 204 | 120 | 120 |
| Critical欠落 | 0 | 0 | 0 | 0 |

`ios_minimal`は`ios_low`比でvisual commandを55.86%削減した。simulation hash、damage hash、撃破321、EXP 9,876、score 543,210、RNG state 60606は全プロファイル一致した。

## 解釈

この数値は描画対象選択のheadless合成計測であり、実GPU frame timeではない。実iPhoneのMetal、thermal、battery、30分継続frame pacingは未確認で、`docs/qa/phase8_ios_real_device_checklist.md`を実施するまで改善確認済みとは扱わない。
