# Godot 4.2 to 4.7 Migration

## Commits

* 開始: `e8875dc04bee1f0d6e8fb27a97f7d6ecebe6b498`
* 4.2 Compatibility確定: `4373a55b1d27c39219939639cf01f8483b60d5b4`
* 4.7移行: この文書を含む`build: migrate project and CI from Godot 4.2 to 4.7`コミット

## 配布物

Godot公式`godotengine/godot-builds`の`4.7-stable` releaseを使用する。

* `Godot_v4.7-stable_win64.exe.zip`
* `Godot_v4.7-stable_macos.universal.zip`
* `Godot_v4.7-stable_export_templates.tpz`
* template directory: `4.7.stable`

## 変更

* `application/config/features`: `4.2`から`4.7`
* renderer: Windows/iOSとも`gl_compatibility`
* workflow: `GODOT_VERSION=4.7-stable`、`TEMPLATE_VERSION=4.7.stable`
* global class: 4.7 native `VirtualJoystick`との衝突を避け、project classを`GemVirtualJoystick`へ変更
* 4.7が生成するscript `.gd.uid`をversioned metadataとして追跡し、`.godot` import cacheは追跡しない

`export_presets.cfg`は4.7 release exportで警告・未知optionなし。Windows executable名、iOS bundle id、arm64、export project only、icon、launch screenを維持した。

## 検証

* 4.7 import error 0
* parser/check-only成功
* 全4,790 assertions成功
* Phase 6 targeted成功
* enemy parity 335/335
* 4 biome 640 samples、missing texture 0
* Windows release export成功、15秒起動、Compatibility/OpenGL 3.3確認
* iOS Xcode buildと未署名IPAはGitHub Actions macOSで検証

save schemaは変更していない。既存SaveSystemテストを全suiteで実行した。

## Rollback

`4373a55b1d27c39219939639cf01f8483b60d5b4`へ戻すと4.2 Compatibility版になる。履歴を破壊せず、通常のrevertまたは同commitからbranchを作成する。

## 既知の問題

Windows headless 60秒計測の33ms超過0は未達。実iPhone profiler、thermal、battery、長時間frame pacingは未検証。
