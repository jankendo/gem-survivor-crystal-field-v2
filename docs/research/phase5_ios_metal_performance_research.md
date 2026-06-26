# Phase 5 iOS and Metal Performance Research

## Sources

- Apple Energy Diagnostics guide: https://developer.apple.com/library/archive/documentation/Performance/Conceptual/EnergyGuide-iOS/MonitorEnergyWithInstruments.html
- Apple Metal tools overview: https://developer.apple.com/metal/tools/
- Apple Metal developer workflows: https://developer.apple.com/documentation/Xcode/Metal-developer-workflows
- Apple memory use in Xcode: https://developer.apple.com/documentation/xcode/gathering-information-about-memory-use
- Apple WWDC 2020 GPU performance: https://developer.apple.com/videos/play/wwdc2020/10602/
- Apple WWDC 2022 game memory: https://developer.apple.com/videos/play/wwdc2022/10106/
- Godot iOS export: https://docs.godotengine.org/en/4.2/tutorials/export/exporting_for_ios.html

## Findings

- iOSビルドと実機のMetal計測はmacOS/Xcodeが必要。Windows headlessではMetal System Trace、thermal、battery drainは取得できない。
- Apple InstrumentsではTime Profiler、Allocations、Energy Diagnostics、Metal System Traceを使ってCPU/GPU/メモリ/エネルギーを分けて見る。
- Apple GPUはtile based deferred rendering前提で、透明な重ね描きと不要なフルスクリーン効果が負荷になりやすい。
- Godot iOS exportはmacOSのXcode工程が必要。署名なしIPAはCIで作れるが、通常端末へ直接インストールできない。

## Adopted Work

- GitHub Actions macOSでunsigned IPAを継続生成する。
- 実機未確認項目は`docs/qa/phase5_ios_real_device_checklist.md`へ分離する。
- 環境は`data/environment_visual_quality.json`でiOS低品質時のデカール数、マテリアル、テクスチャalphaを抑制する。

## Current Baseline

- Source: `test-output/phase5/baseline_performance.json`
- Capture: Windows Godot 4.2 headless synthetic iOS harness, 1 minute
- Average FPS: 60
- p95 frame time: 2.009 ms
- Max enemies: 124
- Limitations: no real iOS device, no Metal System Trace, no thermal or battery telemetry
