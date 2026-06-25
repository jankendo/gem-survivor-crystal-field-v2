# Changelog

## 2026-06-25 Phase 4

### Added

* iOS/touchタイトル画面のSafe Area内レスポンシブレイアウト契約を追加。
* `IosTitleLayoutSystem.gd`とタイトル専用QAを追加。
* 結晶迷宮環境アートの生成元、ランタイムPNG、マニフェスト、品質プロファイルを追加。
* `EnvironmentVisualSystem.gd`で環境色/テクスチャ/決定的variantを解決。
* Phase 4調査資料、環境仕様、iOS実機チェックリストを追加。

### Changed

* タッチタイトルから固定フッターをなくし、縦スクロール可能なSafe Area内メニューへ変更。
* `ArenaView.gd`の床/境界描画に環境ビジュアル解決層を挿入。
* 製品バージョンを`0.4.0` build `4`へ更新。

### Notes

* 生成環境アートは`human_review_status=needs_review`であり、人間レビュー前にapproved扱いしない。
* iOS実機確認は物理端末待ちとしてQAチェックリストに残す。

## 2026-06-23

### Added

* Gem Survivor Crystal Field v2向けの開発ルールへ`AGENTS.md`を更新。
* v2設計文書一式を追加。
* v2 Momentum、HUD presenter、アセットregistryの土台を追加。
* 将来の画像生成差し替え用アセットマニフェストとプロンプト雛形を追加。

### Changed

* READMEの入口にv2ドキュメント案内を追加。
* HUDとリザルトにv2向けのビルド/盛り上がり情報を追加。

### Notes

* 現行サバイバー路線を維持する。旧Chrono Merge Tacticsのターン制合成仕様へは戻さない。

## 2026-06-23 Phase 2

### Added

* `docs/current_gameplay_spec.md`を現行ゲームプレイ正本として追加。
* `V2MomentumTelemetry.gd`とMomentum重複抑止/集計を追加。
* `V2FeedbackDirector.gd`と`data/v2_feedback.json`を追加。
* `data/v2_visual_theme.json`と`V2ThemeProvider.gd`を追加。
* Main画面用Controller群を追加。
* P0垂直スライスPNG 16件、Batch 01生成資料、manifest validatorを追加。
* Phase 2 screenshot/layout QAとMomentum 10分相当QAを追加。

### Changed

* READMEを現行製品入口へ縮小し、旧更新メモを`docs/archive/legacy_update_notes.md`へ退避。
* タイトル、HUD、リザルトでv2情報階層を適用。
* `V2AssetRegistry.gd`がpreferred PNGを優先し、未import PNGも安全に読み込めるよう更新。

### Verification

* `python tools/validate_v2_asset_manifest.py`
* 新規v2 targeted suites
* `tests/auto_play_v2_momentum_10min.gd`
* `tests/capture_v2_phase2_screenshots.gd`
# v2 Phase 3

- Added reachable pickup placement contract with `WorldPlacementValidator`, `ItemPlacementSystem`, and placement telemetry.
- Changed permanent unlock policy so non-starter weapons, passives, characters, and blessings become usable only after shop purchase.
- Added save migration for legacy condition-only unlocks.
- Added Japanese localization source data, terminology guide, and Phase 3 QA scripts.
- Unified product version to `0.3.0` build `3`.
