# Gem Survivor Crystal Field v2

Godot 4.2 + GDScriptで作る、2D探索型サバイバー / bullet-heavenアクションゲームです。

## Phase 5 Extreme iOS Performance / Combat Readability

v2 Phase 5では、iOS向け最適化で敵数、スポーン量、難易度、ボス、報酬を削らない契約を追加しました。iOS低品質プロファイルでも`max_enemies`は標準と同じ600を維持し、ボス出現時に既存敵を削除しません。

環境アートはPhase 5用に再生成し、床/壁/奈落の明度差とpickup混同を自動監査します。詳細は[docs/v2_phase5_extreme_ios_performance.md](docs/v2_phase5_extreme_ios_performance.md)と[docs/environment_readability_contract.md](docs/environment_readability_contract.md)を正本にします。

## Phase 4 iOS / Environment Upgrade

v2 Phase 4では、iOS横画面タイトルのSafe Area内レスポンシブ化と、結晶迷宮らしい環境アート基盤を追加しています。タイトルはタッチ環境で縦スクロール可能な構造になり、環境テクスチャは`data/environment_asset_manifest.json`と`EnvironmentVisualSystem.gd`で解決します。

生成環境アートはプロジェクト内作成素材ですが、`human_review_status=needs_review`として扱います。iOS実機レビューは物理端末が必要なため、チェックリストを[docs/qa/ios_phase4_real_device_checklist.md](docs/qa/ios_phase4_real_device_checklist.md)に残しています。

## Phase 3 Product Polish

v2 Phase 3では、到達可能な安全床だけにpickupを置く共通配置契約、スターター以外をショップ購入だけで永久解放する権限管理、自然な日本語表示、初回体験と経済QAを追加しています。

```powershell
& .tools/godot-download/Godot_v4.2-stable_win64_console.exe --headless --path . --check-only
& .tools/godot-download/Godot_v4.2-stable_win64_console.exe --headless --path . --script res://tests/smoke_main_scene.gd
& .tools/godot-download/Godot_v4.2-stable_win64_console.exe --headless --path . --script res://tests/test_runner.gd
python tools/audit_ios_title_layout.py
python tools/environment/validate_environment_assets.py
python tools/environment/generate_environment_report.py
```

旧`Chrono Merge Tactics`由来のリポジトリ名が残っていますが、現行の正本は`Gem Survivor Crystal Field v2`です。ターン制、ブロック合成、オンラインランキング、課金、ガチャ、ストーリー複数モードは対象外です。

## 対応プラットフォーム

- Windows 10/11: 最優先ターゲット
- iOS: Safe Play Area、タッチ操作、未署名IPAのCIビルド経路を維持

音声は完全無音です。BGM、SE、音声、`AudioStreamPlayer`は追加しません。

## 現在の主要仕様

- ゲームモードはラン内完結のサバイバー型Endlessのみ
- 探索フィールドで敵を倒し、EXPジェム、宝箱、フィールドドロップを集める
- EXP必要量は時間で変動しない
- フィールドドロップは原則残存し、復活対象は既存データとシステムで管理する
- 全ジェム回収は一括処理で、個別ジェムごとの大量通知にはしない
- 通常敵は原則、弾・爆発・落下物を出さない
- ボスは既存`data/bosses.json`の周期に従う
- 武器、パッシブ、進化、キャラクター進化、実績、永続強化は既存データ駆動
- v2 Momentumはラン内限定の短時間スコア補助で、発動理由、段階、残り時間、倍率、結果集計を表示する
- v2アセットは`data/asset_manifest.json`と`V2AssetRegistry.gd`で解決し、PNGが無い場合は既存SVGへfallbackする
- Phase 4環境アセットは`data/environment_asset_manifest.json`で管理し、床/壁/虚無/デカールの見た目と衝突判定を分離する

詳細な現行仕様は[docs/current_gameplay_spec.md](docs/current_gameplay_spec.md)を正本とします。

## 操作

Windows:

- 移動: WASD / 方向キー
- 決定: Enter / マウスクリック
- 戻る・ポーズ: Esc
- タイトルショートカット: C/U/L/A/S/R/H/I/Esc

iOS相当:

- 左側ドラッグで移動
- 右側ボタンでスキャン、回収、倍速など
- カード全体をタップして選択
- Safe Play Area外の黒帯は入力領域にしない

## 開発環境

- Godot: `4.2.stable.official.46dc27791`
- 言語: GDScript
- 主要データ: `data/*.json`
- 画像方針: 外部著作物を使わず、プロジェクト内生成/作成素材のみ

## テスト

```powershell
$GODOT = ".tools/godot-download/Godot_v4.2-stable_win64_console.exe"
& $GODOT --version
& $GODOT --headless --path . --check-only --script res://tests/test_runner.gd
& $GODOT --headless --path . --script res://tests/smoke_main_scene.gd
& $GODOT --headless --path . --script res://tests/run_single_suite.gd -- --suite=res://tests/test_rng.gd
& $GODOT --headless --path . --script res://tests/test_runner.gd
& $GODOT --headless --path . --script res://tests/auto_play_60sec.gd
& $GODOT --headless --path . --script res://tests/auto_play_v2_momentum_10min.gd
& $GODOT --headless --path . --script res://tests/capture_v2_phase2_screenshots.gd
python tools/validate_v2_asset_manifest.py
python tools/audit_ios_title_layout.py
python tools/environment/validate_environment_assets.py
python tools/environment/validate_tile_seams.py
python tools/environment/audit_texture_imports.py
python tools/environment/generate_environment_report.py
python tools/environment/measure_environment_contrast.py
python tools/environment/audit_collectible_confusion.py
python tools/environment/audit_environment_readability.py
```

## ビルド

Windows export:

```powershell
$GODOT = ".tools/godot-download/Godot_v4.2-stable_win64_console.exe"
New-Item -ItemType Directory -Force builds/windows | Out-Null
& $GODOT --headless --path . --export-release "Windows Desktop" "builds/windows/ChronoMergeTactics.exe"
```

iOS unsigned IPA:

- GitHub Actionsの`Build Windows and iOS` workflowで作成
- 署名なしIPAは通常のiPhoneへ直接インストールできません
- bundle id: `com.jankendo14.gemsurvivor`
- display name: `Gem Survivor Crystal Field`

## v2正本文書

- [docs/current_gameplay_spec.md](docs/current_gameplay_spec.md)
- [docs/v2_phase5_extreme_ios_performance.md](docs/v2_phase5_extreme_ios_performance.md)
- [docs/environment_readability_contract.md](docs/environment_readability_contract.md)
- [docs/performance/enemy_simulation_architecture.md](docs/performance/enemy_simulation_architecture.md)
- [docs/v2_phase4_ios_environment_upgrade.md](docs/v2_phase4_ios_environment_upgrade.md)
- [docs/ios_responsive_title_spec.md](docs/ios_responsive_title_spec.md)
- [docs/environment_art_direction.md](docs/environment_art_direction.md)
- [docs/environment_rendering_pipeline.md](docs/environment_rendering_pipeline.md)
- [docs/environment_performance_budget.md](docs/environment_performance_budget.md)
- [docs/environment_asset_manifest_spec.md](docs/environment_asset_manifest_spec.md)
- [docs/v2_phase2_vertical_slice.md](docs/v2_phase2_vertical_slice.md)
- [docs/v2_ui_component_map.md](docs/v2_ui_component_map.md)
- [docs/v2_vision.md](docs/v2_vision.md)
- [docs/v2_scope.md](docs/v2_scope.md)
- [docs/v2_gameplay_pillars.md](docs/v2_gameplay_pillars.md)
- [docs/v2_uiux_plan.md](docs/v2_uiux_plan.md)
- [docs/v2_asset_direction.md](docs/v2_asset_direction.md)
- [docs/v2_asset_pipeline.md](docs/v2_asset_pipeline.md)
- [docs/test_plan.md](docs/test_plan.md)

旧READMEの長い更新メモは[docs/archive/legacy_update_notes.md](docs/archive/legacy_update_notes.md)へ退避しています。

## 既知の制約

- iOS実機インストールと署名検証は対象外
- headless環境のスクリーンショットQAはdummy rendererのため、実画面PNGではなく診断PNGとControl矩形レポートを出力する
- v2アセットBatch 01はP0垂直スライスであり、全キャラクター/全敵/全装備の置換は次フェーズ対象
