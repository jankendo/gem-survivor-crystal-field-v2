# Changelog

## Phase 8 Nightly 30-minute shard correction

* `auto_play_ios_perf_25min.gd` and `auto_play_ios_perf_30min.gd` no longer repeat the 0-20 minute interval already covered by the parallel 20-minute shard.
* The 20-25 and 25-30 minute intervals start at the normal enemy cap with the same seed, one-second simulation step, spawn curve, difficulty, weapons, rewards, and simulation systems.
* This corrects a reproducible 90-minute GitHub Actions timeout without deleting a test or reducing game-side enemy, combat, reward, or RNG behavior.

## 2026-06-29 Phase 8

### Added

* `ios_minimal` / `desktop_minimal`、保存値非破壊の省電力実効設定、30fps描画契約。
* タッチ倍速固定、手動ラン終了の一度限り清算、日本語OptionButton設定。
* 共通フィールド解放判定、実対象イベント誘導、武器/パッシブコア識別。
* 詳細ショップ解放条件と、不足していた累計ジェム・地形ボス統計接続。
* Phase 8専用27 suite、189 assertions、全5,015 assertions、600敵の決定的終盤比較。

### Validation

* `ios_minimal` visual commandsは`ios_low`比55.86%削減、背景粒子0、ダメージ数字0、Critical欠落0。
* simulation、damage、kill、EXP、score、RNG hash一致。
* 実iPhoneのMetal、thermal、battery、30分継続性能は未検証。

## 2026-06-29 Phase 7

### Added

* Visual effect budget、command buffer/coalescer、projectile render selection、weapon style cache。
* 5種類の20秒相当iOS evolved-effect stress fixtureとPhase 7専用34 assertions。
* Fast Gate、Phase 7 performance、Release build、Nightly fullの分割workflow。
* changed-file routing、batch runner、OS/Godot別cache、suite timing artifact。

### Changed

* iOS qualityをsimulation配列上限からrendered上限へ分離。
* projectile/bomb/effect hot loopを配列copy/eraseから順序維持compactへ変更。
* `weapon_effect()`を毎回deep-copyからread-only style cacheへ変更。
* background gridを複数line drawからrepeat textureへ変更。
* minimapのstate全走査を4-8Hz command cacheへ変更。
* 円弧segmentを画面半径とqualityから8-48で決定。
* Nightlyの同一30分harness二重実行を正本1本へ統合し、既存aliasを残したままCI wall timeを短縮。

### Validation

* Phase 7 targeted 34 assertions、Fast manifest 68 assertions、全4,830 assertions成功。
* 600 enemies、500 projectiles、1,000 gemsでsimulation hash完全一致。
* visual command 7,240から1,880、74.03%削減、Critical欠落0。
* GitHub Actions Fast 36秒、Phase 7 performance 33秒、Release Windows 76秒/iOS 155秒、Nightly 17/17を30.8分で成功。

### Notes

* headless Phase 6相当A/Bのp95 30%改善は未達。実iPhone Instruments、thermal、battery、30分frame pacingは未検証。

## 2026-06-27 Phase 6

### Added

* Renderer比較、UI dirty update、arena static cache、Release telemetry、Godot 4.7移行の設計資料とQA契約。
* Phase 6専用39 assertionsと同一seed 60秒benchmark。
* Phase 6 metrics、renderer report、UI counter、static cache reportのActions artifact。

### Changed

* Godot 4.2から4.7 stableへ移行し、Windows/iOS rendererをCompatibilityへ統一。
* HUD全更新を毎フレーム3,600回から60秒225回へ削減。
* static terrain再構築を60回から14回へ削減。
* Release標準のiOS performance/energy集計とCSVを停止。
* 4.7 native classとの衝突回避のためproject classを`GemVirtualJoystick`へ変更。
* `full_test=true`の44長時間scriptを13 shardへ並列化し、単一jobのtimeoutを解消。
* 30分balance testの敵上限を、Phase 5のprotected boss/minion/split overflow契約とhard safety budget 700へ整合。
* iOS touch 60秒QAのlevel-upを固定EXP注入で決定化し、save進行度依存を除去。
* category balance QAもprotected spawnをsoft cap違反と誤判定せず、hard safety budgetを検証するよう更新。

### Validation

* 4.7 import/parser error 0、全4,790 assertions成功。
* desktop/iOS enemy parity 335/335、4 biome、環境視認性監査成功。
* Windows release exportと15秒起動、Compatibility/OpenGL 3.3を確認。
* iOS未署名IPAはGitHub Actions macOS buildで検証する。

### Notes

* Windows headless合成計測の33ms超過0は未達。実iPhone Instruments、thermal、battery、長時間frame pacingは未検証。

## 2026-06-26 Phase 5

### Added

* Phase 5 performance research, enemy simulation architecture, spatial hash, frame budget, threading, object pool, GDExtension, and iOS device QA docs.
* Data-oriented enemy store, spatial query buffer, 2D spatial hash, enemy frame scheduler, combat frame budget scheduler, and deterministic simulation core.
* Phase 5 enemy count, no culling, spawn parity, frame budget, and environment readability tests.
* Environment readability audit tools and grayscale/colorblind contact sheets.
* Phase 5 readability concept image and regenerated runtime environment textures.

### Changed

* iOS performance profiles no longer reduce `max_enemies`.
* Boss spawn no longer deletes existing enemies when the enemy list is full.
* Boss minions and split children are not skipped by enemy cap paths.
* Weapon hot loops use spatial hash candidates for beams, auras, rune gates, black holes, explosions, and slow splash.
* Environment visual quality profiles reduce texture dominance and decorative decal budgets.

### Notes

* Real iOS device, Metal System Trace, thermal, and battery validation remain external to this Windows environment.

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
