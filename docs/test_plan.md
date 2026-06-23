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
.\.tools\godot-download\Godot_v4.2-stable_win64_console.exe --headless --path . --script res://tests/run_single_suite.gd -- --suite=res://tests/test_v2_momentum_telemetry.gd
.\.tools\godot-download\Godot_v4.2-stable_win64_console.exe --headless --path . --script res://tests/run_single_suite.gd -- --suite=res://tests/test_v2_momentum_deduplication.gd
.\.tools\godot-download\Godot_v4.2-stable_win64_console.exe --headless --path . --script res://tests/run_single_suite.gd -- --suite=res://tests/test_v2_feedback_director.gd
.\.tools\godot-download\Godot_v4.2-stable_win64_console.exe --headless --path . --script res://tests/run_single_suite.gd -- --suite=res://tests/test_v2_feedback_priority.gd
.\.tools\godot-download\Godot_v4.2-stable_win64_console.exe --headless --path . --script res://tests/run_single_suite.gd -- --suite=res://tests/test_v2_hud_presenter.gd
.\.tools\godot-download\Godot_v4.2-stable_win64_console.exe --headless --path . --script res://tests/run_single_suite.gd -- --suite=res://tests/test_v2_asset_registry.gd
.\.tools\godot-download\Godot_v4.2-stable_win64_console.exe --headless --path . --script res://tests/run_single_suite.gd -- --suite=res://tests/test_v2_asset_manifest.gd
.\.tools\godot-download\Godot_v4.2-stable_win64_console.exe --headless --path . --script res://tests/run_single_suite.gd -- --suite=res://tests/test_v2_asset_registry_fallback.gd
.\.tools\godot-download\Godot_v4.2-stable_win64_console.exe --headless --path . --script res://tests/run_single_suite.gd -- --suite=res://tests/test_v2_ui_layout_contract.gd
.\.tools\godot-download\Godot_v4.2-stable_win64_console.exe --headless --path . --script res://tests/run_single_suite.gd -- --suite=res://tests/test_v2_main_navigation.gd
.\.tools\godot-download\Godot_v4.2-stable_win64_console.exe --headless --path . --script res://tests/run_single_suite.gd -- --suite=res://tests/test_v2_result_summary.gd
python tools/validate_v2_asset_manifest.py
```

## 長時間検証

標準テスト全体やオートプレイは時間がかかる。タイムアウトする場合は、実行した範囲、成功した範囲、未完走の範囲を最終報告に明記する。

Phase 2追加:

```powershell
.\.tools\godot-download\Godot_v4.2-stable_win64_console.exe --headless --path . --script res://tests/auto_play_v2_momentum_10min.gd
.\.tools\godot-download\Godot_v4.2-stable_win64_console.exe --headless --path . --script res://tests/capture_v2_phase2_screenshots.gd
```

## 重点確認

* Windowsでタイトルからラン開始できる。
* 既存セーブが読み込める。
* HUDにv2情報が重なりすぎない。
* Momentumがラン内だけで完結する。
* v2アセットが存在しない場合、既存SVG fallbackが返る。
# Phase 3 QA Additions

- `tests/auto_play_item_placement_100_seed.gd`: 100 seedでpickup配置、壁内、到達不能、再現性を検査する。
- `tests/auto_play_shop_entitlement_qa.gd`: ショップ限定解放、二重購入防止、購入後使用可能を検査する。
- `tools/audit_japanese_ui.py`: プレイヤー向け英語用語の残存を監査する。
- `tests/auto_play_first_run_15min.gd` / `tests/auto_play_progression_economy.gd`: 初回体験と経済導線の決定的QAレポートを生成する。
