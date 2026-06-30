# Phase 9 iOS Real Device Checklist

Windows headless、CI、Simulatorは実iPhone、Metal、thermal、battery、実機touchの証明ではない。以下は物理端末で別途実施する。

## Build

* [ ] unsigned IPAのbundle idが`com.jankendo14.gemsurvivor`
* [ ] arm64 slice
* [ ] icon表示
* [ ] launch screen表示
* [ ] iOS横画面Safe Area内にタイトル/主要ボタンが収まる

## Gameplay

* [ ] touch移動しながら短押しscanできる
* [ ] touch移動しながら長押し抽出できる
* [ ] 長押し中に誤ってlevel-up actionが出ない
* [ ] map/room発見が見切れない
* [ ] リザルト武器別ダメージがSafe Area内に収まる
* [ ] damage numberが表示されない
* [ ] touch hapticが発生しない

## Performance

* [ ] 20分以降の敵600、projectile 700、gem 1,200条件でp50/p95/p99を記録
* [ ] 33ms/100ms超過を記録
* [ ] InstrumentsまたはXcode Organizerでthermal stateを記録
* [ ] battery開始/終了を記録
* [ ] boss/elite/telegraph欠落0を目視確認

## Notes

* device:
* iOS:
* build SHA:
* thermal:
* battery:
* p50/p95/p99:
* screenshots/video:
