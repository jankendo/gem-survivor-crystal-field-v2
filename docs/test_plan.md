# Test Plan

## 最低限の検証

```powershell
.\.tools\godot-download\Godot_v4.2-stable_win64_console.exe --headless --path . --check-only --script res://tests/test_runner.gd
.\.tools\godot-download\Godot_v4.2-stable_win64_console.exe --headless --path . --script res://tests/smoke_main_scene.gd
.\.tools\godot-download\Godot_v4.2-stable_win64_console.exe --headless --path . --script res://tests/run_single_suite.gd -- --suite=res://tests/test_rng.gd
```

## v2 targeted tests

```powershell
.\.tools\godot-download\Godot_v4.2-stable_win64_console.exe --headless --path . --script res://tests/run_single_suite.gd -- --suite=res://tests/test_v2_momentum_system.gd
.\.tools\godot-download\Godot_v4.2-stable_win64_console.exe --headless --path . --script res://tests/run_single_suite.gd -- --suite=res://tests/test_v2_hud_presenter.gd
.\.tools\godot-download\Godot_v4.2-stable_win64_console.exe --headless --path . --script res://tests/run_single_suite.gd -- --suite=res://tests/test_v2_asset_registry.gd
```

## 長時間検証

標準テスト全体やオートプレイは時間がかかる。タイムアウトする場合は、実行した範囲、成功した範囲、未完走の範囲を最終報告に明記する。

## 重点確認

* Windowsでタイトルからラン開始できる。
* 既存セーブが読み込める。
* HUDにv2情報が重なりすぎない。
* Momentumがラン内だけで完結する。
* v2アセットが存在しない場合、既存SVG fallbackが返る。

