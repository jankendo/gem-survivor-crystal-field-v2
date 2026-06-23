# v2 Asset Pipeline

## カテゴリ

* `character_portrait`
* `character_sprite`
* `enemy_sprite`
* `boss_sprite`
* `weapon_icon`
* `passive_icon`
* `evolution_icon`
* `field_drop_icon`
* `field_gimmick_icon`
* `biome_background`
* `ui_panel`
* `ui_button`

## 命名規則

アセットIDは既存データIDを基準にする。

```text
assets/v2/{category}/{asset_id}.webp
assets/v2/{category}/{asset_id}.png
assets/generated/{legacy_category}/{asset_id}.svg
```

例:

```text
assets/v2/weapon_icon/magic_bolt.webp
assets/v2/passive_icon/magnet.webp
assets/v2/enemy_sprite/slime.webp
assets/generated/weapons/magic_bolt.svg
```

## 推奨形式

| 用途 | 推奨形式 | fallback |
| --- | --- | --- |
| アイコン | WebPまたはPNG、透過あり | SVG |
| キャラスプライト | WebPまたはPNG、透過あり | SVG |
| 敵/ボス | WebPまたはPNG、透過あり | SVG |
| UIパネル | PNGまたは9-slice可能な素材 | コード描画 |
| 背景 | WebP、非透過 | コード描画/既存背景 |

## 解像度基準

| カテゴリ | 基準 |
| --- | --- |
| アイコン | 256x256 |
| ゲーム内スプライト | 512x512原寸から縮小 |
| ボス | 1024x1024 |
| 立ち絵 | 1024x1536 |
| UIパネル | 1024幅以上、9-slice前提 |
| 背景 | 1920x1080 |

## 差し替え手順

1. `data/asset_manifest.json`へ対象IDを登録する。
2. `style_profile`、`target_resolution`、`transparent`、`fallback_path`を確認する。
3. 生成画像を`assets/v2/{category}/`へ配置する。
4. 画像が存在する場合のみ`replacement_status`を`generated`、ゲーム内統合済みなら`integrated`へ変更する。
5. `python tools/validate_v2_asset_manifest.py`を通す。
6. Godot import後、表示確認とスモークを通す。
7. 視認性OKなら`replacement_status`を`approved`にする。

## fallback運用

`V2AssetRegistry.gd`は、v2画像が存在する場合はv2画像を優先し、存在しない場合は既存SVGへ戻す。これにより、カテゴリ単位ではなくID単位で安全に差し替えられる。

Phase 2時点の解決順:

1. `preferred_path`のv2 PNG/WebP
2. `fallback_path`の既存SVG
3. 呼び出し元の安全なコード描画

## 量産フロー

1. 優先度`P0`と`P1`のアセットを選ぶ。
2. `docs/v2_asset_prompt_templates.md`のテンプレートから生成プロンプトを作る。
3. 画像を生成する。
4. 32px/64px/ゲーム内原寸で可読性を確認する。
5. `data/asset_manifest.json`を更新する。
6. `tests/test_v2_asset_registry.gd`を通す。

Phase 2のP0対象と生成条件は`docs/asset_generation/v2_batch_01.md`を正とする。
# Phase 3 Asset Pipeline

Use `docs/asset_generation/v2_batch_02.md` and `.json` for prompt history. `data/asset_manifest.json` records generation method, source tool, legal review state, human review state, and approval status.
