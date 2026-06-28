# Test Plan

## 最低限の検証

```powershell
.\.tools\godot-4.7\editor\Godot_v4.7-stable_win64_console.exe --headless --path . --check-only --script res://tests/test_runner.gd
.\.tools\godot-4.7\editor\Godot_v4.7-stable_win64_console.exe --headless --path . --script res://tests/smoke_main_scene.gd
.\.tools\godot-4.7\editor\Godot_v4.7-stable_win64_console.exe --headless --path . --script res://tests/run_single_suite.gd -- --suite=res://tests/test_rng.gd
```

## v2 targeted tests

```powershell
.\.tools\godot-4.7\editor\Godot_v4.7-stable_win64_console.exe --headless --path . --script res://tests/run_single_suite.gd -- --suite=res://tests/test_v2_momentum_system.gd
.\.tools\godot-4.7\editor\Godot_v4.7-stable_win64_console.exe --headless --path . --script res://tests/run_single_suite.gd -- --suite=res://tests/test_v2_momentum_telemetry.gd
.\.tools\godot-4.7\editor\Godot_v4.7-stable_win64_console.exe --headless --path . --script res://tests/run_single_suite.gd -- --suite=res://tests/test_v2_momentum_deduplication.gd
.\.tools\godot-4.7\editor\Godot_v4.7-stable_win64_console.exe --headless --path . --script res://tests/run_single_suite.gd -- --suite=res://tests/test_v2_feedback_director.gd
.\.tools\godot-4.7\editor\Godot_v4.7-stable_win64_console.exe --headless --path . --script res://tests/run_single_suite.gd -- --suite=res://tests/test_v2_feedback_priority.gd
.\.tools\godot-4.7\editor\Godot_v4.7-stable_win64_console.exe --headless --path . --script res://tests/run_single_suite.gd -- --suite=res://tests/test_v2_hud_presenter.gd
.\.tools\godot-4.7\editor\Godot_v4.7-stable_win64_console.exe --headless --path . --script res://tests/run_single_suite.gd -- --suite=res://tests/test_v2_asset_registry.gd
.\.tools\godot-4.7\editor\Godot_v4.7-stable_win64_console.exe --headless --path . --script res://tests/run_single_suite.gd -- --suite=res://tests/test_v2_asset_manifest.gd
.\.tools\godot-4.7\editor\Godot_v4.7-stable_win64_console.exe --headless --path . --script res://tests/run_single_suite.gd -- --suite=res://tests/test_v2_asset_registry_fallback.gd
.\.tools\godot-4.7\editor\Godot_v4.7-stable_win64_console.exe --headless --path . --script res://tests/run_single_suite.gd -- --suite=res://tests/test_v2_ui_layout_contract.gd
.\.tools\godot-4.7\editor\Godot_v4.7-stable_win64_console.exe --headless --path . --script res://tests/run_single_suite.gd -- --suite=res://tests/test_v2_main_navigation.gd
.\.tools\godot-4.7\editor\Godot_v4.7-stable_win64_console.exe --headless --path . --script res://tests/run_single_suite.gd -- --suite=res://tests/test_v2_result_summary.gd
python tools/validate_v2_asset_manifest.py
python tools/audit_ios_title_layout.py
python tools/environment/validate_environment_assets.py
python tools/environment/validate_tile_seams.py
python tools/environment/audit_texture_imports.py
python tools/environment/generate_environment_report.py
```

## Phase 4 targeted tests

```powershell
.\.tools\godot-4.7\editor\Godot_v4.7-stable_win64_console.exe --headless --path . --script res://tests/run_single_suite.gd -- --suite=res://tests/test_ios_title_screen_fit.gd
.\.tools\godot-4.7\editor\Godot_v4.7-stable_win64_console.exe --headless --path . --script res://tests/run_single_suite.gd -- --suite=res://tests/test_ios_title_safe_area.gd
.\.tools\godot-4.7\editor\Godot_v4.7-stable_win64_console.exe --headless --path . --script res://tests/run_single_suite.gd -- --suite=res://tests/test_ios_title_button_visibility.gd
.\.tools\godot-4.7\editor\Godot_v4.7-stable_win64_console.exe --headless --path . --script res://tests/run_single_suite.gd -- --suite=res://tests/test_environment_asset_manifest.gd
.\.tools\godot-4.7\editor\Godot_v4.7-stable_win64_console.exe --headless --path . --script res://tests/run_single_suite.gd -- --suite=res://tests/test_environment_quality_profiles.gd
.\.tools\godot-4.7\editor\Godot_v4.7-stable_win64_console.exe --headless --path . --script res://tests/auto_play_environment_10min.gd
.\.tools\godot-4.7\editor\Godot_v4.7-stable_win64_console.exe --headless --path . --script res://tests/auto_play_environment_ios_low_10min.gd
.\.tools\godot-4.7\editor\Godot_v4.7-stable_win64_console.exe --headless --path . --script res://tests/auto_play_environment_windows_high_10min.gd
.\.tools\godot-4.7\editor\Godot_v4.7-stable_win64_console.exe --headless --path . --script res://tests/auto_play_item_placement_environment_30min.gd
.\.tools\godot-4.7\editor\Godot_v4.7-stable_win64_console.exe --headless --path . --script res://tests/auto_play_ios_title_navigation.gd
```

## Phase 5 targeted tests

```powershell
.\.tools\godot-4.7\editor\Godot_v4.7-stable_win64_console.exe --headless --path . --script res://tests/run_single_suite.gd -- --suite=res://tests/test_enemy_entity_store.gd
.\.tools\godot-4.7\editor\Godot_v4.7-stable_win64_console.exe --headless --path . --script res://tests/run_single_suite.gd -- --suite=res://tests/test_phase5_no_enemy_culling.gd
.\.tools\godot-4.7\editor\Godot_v4.7-stable_win64_console.exe --headless --path . --script res://tests/run_single_suite.gd -- --suite=res://tests/test_phase5_no_difficulty_reduction.gd
.\.tools\godot-4.7\editor\Godot_v4.7-stable_win64_console.exe --headless --path . --script res://tests/run_single_suite.gd -- --suite=res://tests/test_phase5_spawn_curve_parity.gd
.\.tools\godot-4.7\editor\Godot_v4.7-stable_win64_console.exe --headless --path . --script res://tests/run_single_suite.gd -- --suite=res://tests/test_phase5_environment_readability.gd
python tools/environment/measure_environment_contrast.py
python tools/environment/audit_collectible_confusion.py
python tools/environment/audit_environment_readability.py
python tools/environment/generate_grayscale_contact_sheet.py
python tools/environment/generate_colorblind_contact_sheet.py
.\.tools\godot-4.7\editor\Godot_v4.7-stable_win64_console.exe --headless --path . --script res://tests/auto_play_phase5_enemy_parity.gd
.\.tools\godot-4.7\editor\Godot_v4.7-stable_win64_console.exe --headless --path . --script res://tests/auto_play_phase5_all_biomes.gd
.\.tools\godot-4.7\editor\Godot_v4.7-stable_win64_console.exe --headless --path . --script res://tests/auto_play_phase5_visual_adaptation.gd
.\.tools\godot-4.7\editor\Godot_v4.7-stable_win64_console.exe --headless --path . --script res://tests/auto_play_phase5_ios_60sec.gd
.\.tools\godot-4.7\editor\Godot_v4.7-stable_win64_console.exe --headless --path . --script res://tests/auto_play_phase5_ios_10min.gd
.\.tools\godot-4.7\editor\Godot_v4.7-stable_win64_console.exe --headless --path . --script res://tests/auto_play_phase5_density_30min.gd
.\.tools\godot-4.7\editor\Godot_v4.7-stable_win64_console.exe --headless --path . --script res://tests/auto_play_phase5_density_45min.gd
.\.tools\godot-4.7\editor\Godot_v4.7-stable_win64_console.exe --headless --path . --script res://tests/auto_play_phase5_density_60min.gd
```

## Phase 6 targeted tests

```powershell
$GODOT = ".\.tools\godot-4.7\editor\Godot_v4.7-stable_win64_console.exe"
& $GODOT --headless --editor --path . --quit-after 3000
& $GODOT --headless --path . --check-only --script res://tests/test_runner.gd
& $GODOT --headless --path . --script res://tests/test_phase6_runner.gd
& $GODOT --headless --path . --script res://tests/test_runner.gd
& $GODOT --headless --path . --script res://tests/auto_play_phase6_renderer_compare.gd -- --stem=res://test-output/phase6/after_4_7_compatibility --label=Godot_4_7_Compatibility_Phase6
& $GODOT --headless --path . --script res://tests/auto_play_phase5_enemy_parity.gd
& $GODOT --headless --path . --script res://tests/auto_play_phase5_all_biomes.gd
python tools/environment/measure_environment_contrast.py
python tools/environment/audit_collectible_confusion.py
python tools/validate_github_actions.py
python tools/validate_ios_workflow.py
```

Phase 6 benchmarkはseed 60606、60秒、同一装備と同一敵密度で実行する。Windows/headlessの結果は実iPhone/GPU性能の証明ではない。実機項目は`docs/qa/phase6_ios_real_device_checklist.md`で別管理する。

## Phase 7 targeted tests

```powershell
$GODOT = ".\.tools\godot-4.7\editor\Godot_v4.7-stable_win64_console.exe"
& $GODOT --headless --path . --script res://tests/test_phase7_runner.gd
& $GODOT --headless --path . --script res://tests/batch_test_runner.gd -- --manifest=res://tests/manifests/fast_gate.json --output=res://test-output/ci/fast_gate_timing.json
& $GODOT --headless --path . --script res://tests/auto_play_ios_evolved_effect_stress.gd
& $GODOT --headless --path . --script res://tests/auto_play_ios_effect_budget_snapshot.gd
& $GODOT --headless --path . --script res://tests/auto_play_ios_visual_simulation_parity.gd
python tools/validate_github_actions.py
python tools/validate_ios_workflow.py
```

Phase 7 stressはseed 70707を基準に、5 scenarioを各20秒相当、敵600、simulation弾500、gem 1000で実行する。visual command数、coalesce、Critical欠落、p50/p95/p99、100ms超過、pool、simulation hashを記録する。2Hzの決定的snapshotであり、実時間20秒待機や実iPhone GPU計測ではない。

CIの正本は`ci-fast.yml`、`ci-ios-perf.yml`、`build-release.yml`、`nightly-full.yml`。既存長時間scriptは削除せずNightlyへ保持する。

`workflow_dispatch full_test=true`は既存44本の長時間scriptを削除せず、通常群に加えてiOS perf 10/20/30分、energy、density 30/45/60分を個別化した13 Ubuntu shardで並列実行する。Windows固有契約はstandard Windows jobで別途検証する。高密度runner差を吸収するため各shard timeoutはGitHub Actionsの最大枠360分とする。各shardは個別artifactを残し、1件でも失敗すればworkflowを失敗させる。

full shardの共通save準備では初回ヘルプだけを既読化し、`qa_telemetry_enabled=false`を維持する。各performance/energy harnessが必要なloggerを直接有効化するため、GameScreenのRelease標準loggerを重ねて動かさない。

density 30/45分は0分から1秒simulation stepで連続実行する。density 60分は45分時点から60分までを1秒stepで実行し、開始時に正規enemy entityを600体まで決定的にprefillする。連続0〜45分と高密度45〜60分を合わせてlong-horizonを覆う。seed、装備、敵上限、60分時点のspawn/difficulty curve、hard budget検査は維持し、敵削除や密度削減は行わない。

## 長時間検証

標準テスト全体やオートプレイは時間がかかる。タイムアウトする場合は、実行した範囲、成功した範囲、未完走の範囲を最終報告に明記する。

Phase 2追加:

```powershell
.\.tools\godot-4.7\editor\Godot_v4.7-stable_win64_console.exe --headless --path . --script res://tests/auto_play_v2_momentum_10min.gd
.\.tools\godot-4.7\editor\Godot_v4.7-stable_win64_console.exe --headless --path . --script res://tests/capture_v2_phase2_screenshots.gd
```

## 重点確認

* Windowsでタイトルからラン開始できる。
* 既存セーブが読み込める。
* HUDにv2情報が重なりすぎない。
* Momentumがラン内だけで完結する。
* v2アセットが存在しない場合、既存SVG fallbackが返る。
* iOSタイトルのボタンがSafe Area内に収まり、縦スクロールfallbackで到達できる。
* 環境アートがpickup、敵、ボス警告、HUDの視認性を妨げない。
# Phase 3 QA Additions

- `tests/auto_play_item_placement_100_seed.gd`: 100 seedでpickup配置、壁内、到達不能、再現性を検査する。
- `tests/auto_play_shop_entitlement_qa.gd`: ショップ限定解放、二重購入防止、購入後使用可能を検査する。
- `tools/audit_japanese_ui.py`: プレイヤー向け英語用語の残存を監査する。
- `tests/auto_play_first_run_15min.gd` / `tests/auto_play_progression_economy.gd`: 初回体験と経済導線の決定的QAレポートを生成する。
