# Phase 2: V2 Visual & Gameplay Vertical Slice

## 目的

Phase 2は、v2基盤を「プレイヤーに見える完成区間」へ進めるフェーズである。新モードや新メタ機能を増やさず、タイトル、主要メニュー、ラン中HUD、Momentum、リザルト、代表アセットを統一する。

## 実装範囲

- Momentum: 理由、段階、残り時間、倍率、終了予告、重複抑止、テレメトリ、リザルト集計。
- Feedback Director: Momentum、進化、ボス、全ジェム回収、シナジー、解放通知の優先度制御。
- v2 Theme: `data/v2_visual_theme.json`と`V2ThemeProvider.gd`で共通色/余白/枠を管理。
- Title: `TitleScreenController.gd`からボタン階層を生成し、P0キービジュアルをRegistry経由で表示。
- Main分離: `MainScreenState.gd`、`TitleScreenController.gd`、`ShopScreenController.gd`、`CollectionScreenController.gd`で段階分離。
- HUD: `V2HudPresenter.gd`を拡張し、Momentumと重要通知をコンパクト表示。
- Result: 生存時間、スコア、レベル、撃破、ボス、主力武器、進化、シナジー、Momentum成果、次行動の順に再構成。
- Assets: P0 16件を`assets/v2/**.png`へ統合し、既存SVG fallbackを保持。
- QA: manifest validator、targeted tests、Momentum 10分相当QA、Phase 2 screenshot/layout QAを追加。

## P0アセット状態

| asset_id | status | preferred |
| --- | --- | --- |
| character.noah | integrated | `res://assets/v2/characters/noah.png` |
| enemy.slime | integrated | `res://assets/v2/enemies/slime.png` |
| enemy.bat | integrated | `res://assets/v2/enemies/bat.png` |
| enemy.golem | integrated | `res://assets/v2/enemies/golem.png` |
| boss.boss_5 | integrated | `res://assets/v2/bosses/boss_5.png` |
| weapon.magic_bolt | integrated | `res://assets/v2/weapons/magic_bolt.png` |
| weapon.ice_orbit | integrated | `res://assets/v2/weapons/ice_orbit.png` |
| passive.move_speed | integrated | `res://assets/v2/passives/move_speed.png` |
| passive.magnet | integrated | `res://assets/v2/passives/magnet.png` |
| evolution.starbreaker_bolt | integrated | `res://assets/v2/evolutions/starbreaker_bolt.png` |
| biome.star_plain | integrated | `res://assets/v2/biomes/star_plain.png` |
| ui.title_key_visual | integrated | `res://assets/v2/ui/title_key_visual.png` |
| ui.primary_crystal_panel | integrated | `res://assets/v2/ui/primary_crystal_panel.png` |
| ui.reward_card_frame | integrated | `res://assets/v2/ui/reward_card_frame.png` |
| ui.momentum_badge | integrated | `res://assets/v2/ui/momentum_badge.png` |
| ui.boss_alert_frame | integrated | `res://assets/v2/ui/boss_alert_frame.png` |

## QA成果物

- `test-output/v2_momentum_balance_report.md`
- `test-output/v2_momentum_balance_summary.json`
- `test-output/screenshots/v2_phase2/phase2_screenshot_report.md`
- `test-output/screenshots/v2_phase2/phase2_screenshot_manifest.json`
- `test-output/screenshots/v2_phase2/*.png`

headlessではGodot dummy rendererのため実画面PNGではなく診断PNGを出力する。Controlツリーは実シーンを構築して検査する。

## 非対象

- 新ゲームモード
- オンライン通信
- 課金/ガチャ/ランキング
- 音声
- 旧ターン制/ブロック合成仕様
- 全アセットの完全置換
