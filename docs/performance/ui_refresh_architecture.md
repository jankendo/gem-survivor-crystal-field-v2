# UI Refresh Architecture

## 更新レーン

| レーン | cadence上限 | 即時更新条件 |
| --- | ---: | --- |
| HP / EXP / level / combo | 30Hz | signature変更 |
| boss / critical combat | 30Hz | signature変更 |
| combat HUD / touch controls | 10Hz | signature変更 |
| equipment / goal / notification / debug | 4Hz | signature変更 |
| low HP overlay | frame | 視覚アニメーション |

`_refresh_runtime_frame()`がレーンを選び、従来の全体`_refresh()`は4Hzへ制限する。level-up、chest、pause等のmodal遷移は既存event handlerから明示refreshされる。

## 再代入抑止

LabelとProgressBarは`IosEnergyOptimizer.set_label()` / value比較を通す。同じ値ではGodot propertyへ書き込まない。QA counterはattemptとactual updateを分ける。

## Before / After

同一seed 60秒:

| 指標 | Before | After | 変化 |
| --- | ---: | ---: | ---: |
| `_refresh()` | 3,600 | 225 | -93.75% |
| Label update attempts | 37,583 | 12,312 | -67.24% |
| Label actual updates | 1,569 | 1,288 | -17.91% |
| Progress attempts | 7,200 | 4,314 | -40.08% |

stale防止はsignature変更時の即時更新と、低FPSでも経過時間を累積するcadence判定で担保する。Phase 6テストはHP、EXP相当signature、weapon/passive、同値抑止、30Hz境界を検証する。

## Release / QA

通常ReleaseではPhase 6 metrics、iOS performance CSV、energy CSVを無効にし、配列集計とDictionary構築を行わない。`phase6_benchmark=true`または`qa_telemetry_enabled=true`を明示したQAだけ有効にする。
