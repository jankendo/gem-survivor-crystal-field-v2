# Renderer Selection Report

## 比較条件

Godot 4.2、seed 60606、60秒、同一ゲーム設定、同一敵密度でWindows headless合成CPU計測を実施した。これはrenderer起動互換性とCPU側の比較であり、GPU profilerや実iPhoneの証拠ではない。

| Renderer | p50 ms | p95 ms | p99 ms | >33ms | enemy_spawn | alive |
| --- | ---: | ---: | ---: | ---: | ---: | ---: |
| Forward+ | 4.530 | 8.330 | 34.548 | 64 | 212 | 13 |
| Mobile | 4.423 | 6.164 | 32.806 | 28 | 212 | 13 |
| Compatibility | 4.372 | 7.133 | 32.287 | 18 | 212 | 13 |

## 互換性

* Forward+: 高機能3D向け。本作で必要なForward+専用shader、compute、3D lightingは確認されなかった。
* Mobile: Vulkan/Metal系のmobile向け。2D本作ではCompatibilityより保守対象を増やす利点が確認できなかった。
* Compatibility: OpenGL/OpenGL ES系の2D向け経路。Windows/iOSを同一設定にでき、現行CanvasItem、texture、font、Safe Area機能と互換だった。

## 採用

Compatibilityを採用した。理由は2D機能適合、Windows/iOSの設定統一、Forward+依存なし、4.2比較で最少の33ms超過だったためである。4.7 Windows通常起動では`OpenGL 3.3 ... Compatibility`を確認した。

## Visual parity

既存の4 biome、environment texture、pickup視認性、Safe Areaの自動監査は成功した。headless screenshotはdummy renderer制約があるため、実GPU screenshotの最終目視はWindows実画面とiPhone実機で継続する。

## 未検証

Metal System Trace、Time Profiler、thermal、battery、30分以上の実iPhone frame pacing、device別GPU比較は未実施。Compatibilityが全iPhoneで60 FPSを保証するという結論は出していない。
