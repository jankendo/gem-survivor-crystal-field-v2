# Phase 5 Godot Performance Research

## Sources

- Godot 4.2 General optimization: https://docs.godotengine.org/en/4.2/tutorials/performance/general_optimization.html
- Godot 4.2 CPU optimization: https://docs.godotengine.org/en/4.2/tutorials/performance/cpu_optimization.html
- Godot 4.2 GPU optimization: https://docs.godotengine.org/en/4.2/tutorials/performance/gpu_optimization.html
- Godot 4.2 Optimization using Servers: https://docs.godotengine.org/en/4.2/tutorials/performance/using_servers.html
- Godot 4.2 Thread-safe APIs: https://docs.godotengine.org/en/4.2/tutorials/performance/thread_safe_apis.html
- Godot 4.2 MultiMeshInstance2D: https://docs.godotengine.org/en/4.2/classes/class_multimeshinstance2d.html
- Godot 4.2 WorkerThreadPool: https://docs.godotengine.org/en/4.2/classes/class_workerthreadpool.html
- Godot 4.2 Custom performance monitors: https://docs.godotengine.org/en/4.2/tutorials/scripting/debug/custom_performance_monitors.html
- Godot 4.2 iOS export: https://docs.godotengine.org/en/4.2/tutorials/export/exporting_for_ios.html

## Findings

- Godot公式は、最適化前に測定し、ターゲット端末差を前提にすることを推奨している。Phase 5では`test-output/phase5/baseline_performance.*`を基準にした。
- SceneTree操作はスレッド安全ではない。敵AIや判定のWorkerThread化は、Packed配列や数値バッファだけを渡す段階まで保留する。
- Serversは低レベルAPIで、毎フレーム情報を問い合わせると同期待ちが発生しうる。Phase 5ではRenderingServer移行を即時採用せず、まずGDScript内の全走査削減を優先した。
- Mobile GPUでは過剰なoverdraw、透過、複雑な素材が負荷になる。環境はテクスチャ強度とデカール数を落とし、ゲームロジックには触れない。
- MultiMeshInstance2Dは大量同一描画の候補だが、現行の敵は状態差、ヒット演出、既存描画経路があるためPhase 5では設計候補に留めた。

## Adopted Work

- `scripts/performance/SpatialHashGrid2D.gd`
- `scripts/performance/SpatialQueryBuffer.gd`
- `scripts/performance/EnemyEntityStore.gd`
- `scripts/performance/EnemyFrameScheduler.gd`
- `scripts/performance/CombatFrameBudgetScheduler.gd`
- `scripts/systems/WeaponSystem.gd`
- `scripts/systems/PerformanceProfileSystem.gd`

## Rejected For Now

- SceneTreeをWorkerThreadPoolで直接触る実装。
- iOSだけ敵数やスポーンを減らすプロファイル。
- RenderingServer/MultiMeshへの全面移行。Phase 5では契約とテストを先に固定した。
