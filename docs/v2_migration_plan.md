# v2 Migration Plan

## Phase 0: 正本化

AGENTS、docs、READMEの役割を整理し、現行ゲームをGem Survivor Crystal Field v2として扱う。旧ターン制合成仕様は無効化する。

## Phase 1: 安全な基礎実装

ラン内完結のMomentum、HUD表示補助、リザルト要約、アセットregistryを追加する。保存形式は変えない。

## Phase 2: Visual & Gameplay Vertical Slice

`GameScreen.gd`からHUD文言生成、通知文言、リザルト要約をさらに切り出す。`Main.gd`はタイトル、ショップ、図鑑、設定単位で段階的に分離する。P0アセットを`data/asset_manifest.json`で実際に解決し、スクリーンショット/layout QAとMomentum 10分QAをCI再現可能にする。

Phase 2実装済み:

* `TitleScreenController.gd`
* `ShopScreenController.gd`
* `CollectionScreenController.gd`
* `MainScreenState.gd`
* `V2FeedbackDirector.gd`
* `V2MomentumTelemetry.gd`
* `V2ThemeProvider.gd`
* P0 16件の`assets/v2/**/*.png`
* manifest validatorとPhase 2 QA scripts

## Phase 3: アセット置換

`data/asset_manifest.json`の優先度に従い、武器アイコン、パッシブアイコン、敵、ボス、UIパネルの順にv2画像へ置き換える。既存SVGはfallbackとして残す。

## Phase 4: バランスと演出の拡張

Momentumの効果をスコア以外にも広げる場合は、データ駆動、ラン内限定、テスト追加を条件にする。ダメージやドロップ率へ影響させる場合はオートプレイで検証する。

## ロールバック方針

* v2画像が壊れた場合はmanifestの`replacement_status`を`fallback`へ戻す。
* Momentumが不安定なら`data/v2_momentum.json`の`enabled`をfalseにする。
* HUD文言が読みにくい場合は`V2HudPresenter.gd`だけを戻す。
# Phase 3 Save Migration

`ShopEntitlementSystem` introduces `save_schema_version` and `shop_entitlement_migration_version`. Starters and purchase-proven entries are kept; condition-only non-starters are moved to `shop_available` and selected locked character/blessing values are repaired to `noah` / `attack`.
