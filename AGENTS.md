# Gem Survivor Crystal Field v2 Development Rules

## 現行前提

* このリポジトリの実体は、Godot 4.7 + GDScript製の2Dサバイバーアクションゲーム「Gem Survivor Crystal Field（ジェムサバイバー：クリスタルフィールド）」である。
* `ChronoMergeTactics`というフォルダ名、exe名、保存ファイル名は既存配布互換のため残っている。ターン制・合成ゲームとして扱わない。
* v2は現行の探索型サバイバー / bullet-heaven路線を強化する。別ジャンルへの作り替えは行わない。
* 現行仕様の棚卸しは`docs/current_asset_spec_audit.md`をベースラインとして扱う。

## v2の採用方針

v2では以下の3本柱を同時に満たす。

* A. 中毒性強化: 気持ちよいフィードバック、短期目標、もう1回遊びたくなるラン内盛り上がりを増やす。
* D. アート完全刷新の土台: 既存生成SVGをfallbackに残しつつ、将来の画像生成アセット差し替えに耐える命名、マニフェスト、参照基盤を整える。
* E. 完成度・売れ筋UI/UX: 現行の厚い成長要素を、新規プレイヤーにも理解しやすいHUD、メニュー、リザルトへ整理する。

## 開発ルール

* Godot 4.7 + GDScriptで実装する。
* rendererはWindows/iOSとも`gl_compatibility`を正本とする。Forward+やMobileへ戻す場合は、同一seedのvisual/performance parity、Windows/iOS export、実GPU検証を先に追加する。
* Windows 10/11向け安定動作を最優先する。iOS資産と設定は壊さず、Phase 4以降はiOSタイトルとSafe Areaの回帰も必ず確認する。
* ゲーム本編はEndlessランを中心に維持する。周辺のキャラ選択、ショップ、図鑑、実績、設定はメタ進行UIとして扱う。
* 完全無音方針を維持する。BGM、SE、音声素材、AudioStreamPlayerの新規導入はしない。
* オンライン通信、サーバー機能、オンラインランキング、課金、ガチャは導入しない。
* 外部著作物や無断素材を使わない。外部素材を勝手にダウンロードしない。
* 既存セーブ互換をできるだけ壊さない。保存形式を変える場合は旧データ補完とテストを追加する。
* 乱数再現性を尊重する。ラン内容に関わるランダム処理は`RunRng.gd`または同等のstream RNG経由にする。
* バランス値、v2設定、アセット置換情報は可能な限り`data/*.json`へ寄せる。
* UIとゲームロジックを分離する。新規v2機能は`GameScreen.gd`や`SurvivorState.gd`へ直接肥大化させず、専用system/helperへ切り出す。
* `GameScreen.gd`、`Main.gd`、`SurvivorState.gd`、`WeaponSystem.gd`は巨大ファイルとして扱い、全面リライトではなく局所的で検証可能な分離を行う。
* 実装後は可能な範囲でGodot `--check-only`、スモーク、関連targeted testを実行し、READMEまたはdocsを更新する。
* pickupは到達可能な安全床以外へ配置しない。
* 全pickup生成経路は共通配置契約を通す。
* スターター以外の永久解放はショップ購入だけで成立する。
* 実績や条件は商品公開、購入条件、通貨報酬にだけ使用する。
* プレイヤー向け表示は日本語を正本とする。
* 内部IDをユーザーへ表示しない。
* 本作の独自価値は探索、結晶、危険報酬、ビルド完成に置く。
* 新コンテンツ数より、視認性、選択の意味、手触りを優先する。
* 画像生成アセットは生成履歴と人間の承認状態を記録する。
* iOS/touchタイトル画面はSafe Area内のスクロール可能なレスポンシブUIとして扱い、固定フッターや見切れるボタン配置へ戻さない。
* iOSタイトルの主要ボタンは`IosTitleLayoutSystem.gd`の契約とテストを更新してから実装する。
* 環境アートは`data/environment_asset_manifest.json`と`data/environment_visual_quality.json`を正本にし、描画は`EnvironmentVisualSystem.gd`経由にする。
* 環境デカールやテクスチャは衝突・pickup配置・到達可能性を変更しない。見た目とゲームロジックを分離する。
* 画像生成した環境アートは`human_review_status`を残し、承認前にapproved扱いしない。
* Phase 5以降、iOS性能対策として敵数、スポーン量、スポーンカーブ、敵HP、敵攻撃力、敵速度、ボス、エリート、報酬を下げない。
* Phase 5以降、ボス出現、ボス召喚、分裂子生成で既存敵を削除しない。
* 敵処理最適化は`SpatialHashGrid2D.gd`、`EnemyEntityStore.gd`、`EnemyFrameScheduler.gd`、`CombatFrameBudgetScheduler.gd`などの専用基盤へ寄せる。
* WorkerThreadPoolを使う場合もSceneTree、Node、Resource、ゲーム結果に影響するRNGはメインスレッドに残す。
* 環境視認性は`tools/environment/measure_environment_contrast.py`と`tools/environment/audit_collectible_confusion.py`で数値確認する。
* Phase 6以降、HUDはdirty/cadence更新を維持する。critical HUDは変更時即時かつ上限30Hz、combat/touchは10Hz、equipment/goal/notification/debugは4Hzを基準とする。
* 変化していないLabel textとProgressBar valueを毎フレーム再代入しない。
* static terrainはprecomputed draw cacheを利用し、動的object描画とsimulationを停止しない。
* static cacheはcamera、viewport/orientation、zoom、map seed/構造、renderer、quality、texture条件の変更で無効化する。
* Release標準では詳細performance/energy CSV、Phase 6 counter、debug Dictionary集計を行わない。QAフラグ時だけ有効にする。
* Phase 6 benchmarkはseed 60606、60秒、敵/弾/ジェム条件固定で比較する。負荷低減による見かけの改善を禁止する。
* CIはGodot 4.7 stable editor/export templatesを使用し、Windows releaseと`macos-26`/Xcode 26上の未署名iOS IPAを検証する。
* headless、CI、Simulatorの結果を実iPhone、Metal、thermal、battery、実機60 FPSの証明として扱わない。

## 禁止事項

* ターン制・合成ゲームへ戻さない。
* 旧`TurnSystem.gd`、`MergeSystem.gd`、`ActivationSystem.gd`前提の設計へ戻さない。
* 大規模破壊的リファクタを一度に行わない。
* 視認性を落とす過剰演出を入れない。
* Safe Area外へiOS/touchタイトルの操作ボタンを置かない。
* 環境アートを理由にpickupや敵の視認性を下げない。
* iOSだけ敵数、スポーン密度、敵性能、報酬を落とさない。
* フレーム低下対策として敵を削除、統合、非生成、報酬なし間引きしない。
* 複雑すぎる属性相性や説明困難な新システムを追加しない。
* 既存のWindows操作、既存セーブ、既存テスト資産を軽視しない。

## 文書の正本

* 現行監査: `docs/current_asset_spec_audit.md`
* v2ビジョン: `docs/v2_vision.md`
* v2スコープ: `docs/v2_scope.md`
* ゲームプレイ柱: `docs/v2_gameplay_pillars.md`
* UI/UX計画: `docs/v2_uiux_plan.md`
* アート方向性: `docs/v2_asset_direction.md`
* アセットパイプライン: `docs/v2_asset_pipeline.md`
* Phase 4 iOS/環境: `docs/v2_phase4_ios_environment_upgrade.md`
* Phase 5 iOS性能/視認性: `docs/v2_phase5_extreme_ios_performance.md`
* Phase 5敵処理: `docs/performance/enemy_simulation_architecture.md`
* Phase 5環境視認性: `docs/environment_readability_contract.md`
* Phase 6 renderer/frame: `docs/v2_phase6_renderer_frame_architecture.md`
* Phase 6 renderer選定: `docs/performance/renderer_selection_report.md`
* Phase 6 UI更新: `docs/performance/ui_refresh_architecture.md`
* Phase 6 arena cache: `docs/performance/arena_render_cache_architecture.md`
* Godot 4.7移行: `docs/migration/godot_4_2_to_4_7.md`
* Phase 6 iOS実機: `docs/qa/phase6_ios_real_device_checklist.md`
* iOSタイトル仕様: `docs/ios_responsive_title_spec.md`
* 環境アート方向性: `docs/environment_art_direction.md`
* 環境描画パイプライン: `docs/environment_rendering_pipeline.md`
* 環境性能予算: `docs/environment_performance_budget.md`
* 環境アセットマニフェスト: `docs/environment_asset_manifest_spec.md`
* 画像生成プロンプト雛形: `docs/v2_asset_prompt_templates.md`
* 移行計画: `docs/v2_migration_plan.md`
* テスト計画: `docs/test_plan.md`
* 変更履歴: `docs/changelog.md`
