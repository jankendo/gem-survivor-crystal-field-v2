# Gem Survivor Crystal Field v2

Godot 4.2 + GDScriptで作る、2D探索型サバイバー / bullet-heavenアクションゲームです。

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
