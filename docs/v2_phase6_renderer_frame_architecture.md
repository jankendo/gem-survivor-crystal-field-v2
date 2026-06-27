# Phase 6 Renderer / Frame Architecture

## 結論

Phase 6ではゲーム内容を減らさず、Godot 4.7 stable + Compatibility rendererを採用する。敵数、スポーン、HP、速度、ボス、分裂、報酬、ジェム、武器、ゲーム速度は変更しない。

## 実装範囲

* `GameScreen.gd`: 毎フレームの全HUD更新を廃止し、critical 30Hz、combat/touch 10Hz、full 4Hzへ分割した。値変更時はcadenceを待たず更新する。
* `UiDirtyFlagSystem.gd`: signatureと経過時間でdirty updateを判定する。
* `IosEnergyOptimizer.gd`: 同一Label text、ProgressBar valueの再代入を抑止する。
* `ArenaView.gd`: corridor、room、boundaryの可視描画データをcamera cell単位で再利用する。敵、弾、ジェム、effect等の動的描画は毎フレーム維持する。
* `Phase6MetricsSystem.gd`: QA/benchmark明示時だけcounterを集計する。
* `IosPerformanceLogSystem` / `IosEnergyLogSystem`: Release標準ではCSV生成だけでなくframe集計も停止する。

## Renderer

`project.godot`の正本は次のとおり。

```ini
config/features=PackedStringArray("4.7", "GL Compatibility")
renderer/rendering_method="gl_compatibility"
renderer/rendering_method.mobile="gl_compatibility"
```

本作は2D CanvasItem中心で、Forward+限定機能を使用していない。WindowsとiOSで同じrendering methodを維持し、実行時は`RenderingServer.get_current_rendering_method()`で確認する。

## 不変条件

* desktop/iOSの`max_enemies=600`を維持する。
* 同一seedのdesktop/iOS parityは`enemy_spawn=335`、`alive=335`。
* save形式、bundle id、exe名、Windows操作、Safe Area契約を変えない。
* static cacheは描画だけを再利用し、collision、pickup配置、RNG、simulationへ関与しない。
* headless計測を実iPhone/GPU性能として扱わない。

## 検証

4.7でimport error 0、parser error 0、全4,790 assertions成功、Phase 6専用39 assertions成功、Windows release exportと15秒起動を確認した。iOSはGitHub Actions macOS runnerで未署名IPAを作成し、構造とSHA-256を検査する。

合成60秒計測では平均60 FPSだが、33ms超過0の目標はWindows headlessで未達である。詳細は`docs/performance/phase6_before_after.md`に記録する。
