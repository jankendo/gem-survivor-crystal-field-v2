# Gem Survivor Crystal Field v2 Development Rules

## 現行前提

* このリポジトリの実体は、Godot 4.2 + GDScript製の2Dサバイバーアクションゲーム「Gem Survivor Crystal Field（ジェムサバイバー：クリスタルフィールド）」である。
* `ChronoMergeTactics`というフォルダ名、exe名、保存ファイル名は既存配布互換のため残っている。ターン制・合成ゲームとして扱わない。
* v2は現行の探索型サバイバー / bullet-heaven路線を強化する。別ジャンルへの作り替えは行わない。
* 現行仕様の棚卸しは`docs/current_asset_spec_audit.md`をベースラインとして扱う。

## v2の採用方針

v2では以下の3本柱を同時に満たす。

* A. 中毒性強化: 気持ちよいフィードバック、短期目標、もう1回遊びたくなるラン内盛り上がりを増やす。
* D. アート完全刷新の土台: 既存生成SVGをfallbackに残しつつ、将来の画像生成アセット差し替えに耐える命名、マニフェスト、参照基盤を整える。
* E. 完成度・売れ筋UI/UX: 現行の厚い成長要素を、新規プレイヤーにも理解しやすいHUD、メニュー、リザルトへ整理する。

## 開発ルール

* Godot 4.2 + GDScriptで実装する。
* Windows 10/11向け安定動作を最優先する。iOS資産と設定は壊さないが、今回の主対象はWindowsである。
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

## 禁止事項

* ターン制・合成ゲームへ戻さない。
* 旧`TurnSystem.gd`、`MergeSystem.gd`、`ActivationSystem.gd`前提の設計へ戻さない。
* 大規模破壊的リファクタを一度に行わない。
* 視認性を落とす過剰演出を入れない。
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
* 画像生成プロンプト雛形: `docs/v2_asset_prompt_templates.md`
* 移行計画: `docs/v2_migration_plan.md`
* テスト計画: `docs/test_plan.md`
* 変更履歴: `docs/changelog.md`
