# Chrono Merge Tactics_v2 現行資産・仕様監査資料

作成日: 2026-06-23  
対象パス: `D:\user\documents\Chrono Merge Tactics_v2`  
調査目的: バージョン2の大幅アップデート前に、既存資産、現行仕様、技術構成、AGENTS.md制約との整合性、リスクを把握する。

## 1. 結論

このリポジトリの実体は、旧「Chrono Merge Tactics」というターン制・合成タクティクス仕様ではなく、Godot 4.7 + GDScript製のサバイバーアクションゲーム「ジェムサバイバー：クリスタルフィールド」です。

`project.godot`のアプリ名は`Gem Survivor Crystal Field`、説明は`Gem Survivor: Crystal Field bullet-heaven action for Windows.`です。READMEにも、内部フォルダ名とexe名は既存配布互換のため`ChronoMergeTactics`のまま、と明記されています。

したがって、次フェーズで最初に決めるべきことは以下です。

1. 現行の「ジェムサバイバー：クリスタルフィールド」をバージョン2として強化する。
2. AGENTS.mdの「Chrono Merge Tactics」仕様へ寄せて、サバイバー資産を大幅に整理・作り替える。
3. 両者を混ぜず、現行ゲーム名・設計ルール・禁止事項を更新してから作業する。

現状のまま大幅アップデートを始めると、AGENTS.mdの禁止事項と現行実装が多数衝突します。

## 2. 現行プロジェクト概要

| 項目 | 内容 |
| --- | --- |
| エンジン | Godot 4.7 stable / Compatibility renderer |
| 言語 | GDScript |
| メインシーン | `res://scenes/Main.tscn` |
| アプリ名 | `Gem Survivor Crystal Field` |
| 現行ジャンル | 2Dサバイバー / bullet-heavenアクション |
| 主対象 | Windows、iOS |
| Windows出力名 | `ChronoMergeTactics.exe` |
| iOS出力名 | `GemSurvivor.ipa` / 未署名IPA |
| 画面 | 1280x720基準、canvas_items、keep |
| 音 | 完全無音方針。`AudioManager.gd`は呼び出し無効化済み |
| 通信 | オンラインランキングやサーバー連携は確認されない |
| 物理 | Godot物理ノードではなく、独自の座標・衝突解決を中心に実装 |

## 3. 資産規模

| 区分 | ファイル数 | 概算サイズ |
| --- | ---: | ---: |
| `assets` | 883 | 1,053,997 bytes |
| `data` | 48 | 185,671 bytes |
| `scripts` | 162 | 805,823 bytes |
| `scenes` | 4 | 1,427 bytes |
| `tests` | 240 | 392,145 bytes |
| `tools` | 26 | 117,324 bytes |
| `.github` | 1 | 19,342 bytes |

現行資産は小さなGodotシーンに対して、GDScript側でUI・ゲーム進行・描画・データ駆動を大きく構築する構成です。

## 4. ディレクトリ別の役割

| パス | 役割 |
| --- | --- |
| `assets/generated` | ローカル生成SVG中心のキャラ、敵、武器、パッシブ、進化、ボス、フィールド素材 |
| `assets/survivor` | UI、武器、地形、ショップ、タッチ操作などのSVG素材 |
| `assets/ios` | iOSアイコン、ランドスケープ起動画面 |
| `data` | 武器、敵、ボス、キャラ、進行、探索、iOS設定などのバランス定義 |
| `scripts/core` | 実行状態、乱数、ランタイムエンティティ |
| `scripts/systems` | 戦闘、敵、武器、進行、保存、マップ、UI補助、iOS最適化などのシステム群 |
| `scripts/ui` | タイトル、ゲーム画面、描画、リザルト、UI部品 |
| `scenes` | `Main`、`Game`、`Result`、`RewardPopup`の薄いシーン定義 |
| `tests` | 単体テスト、スモーク、長時間オートプレイ、iOSレイアウト/性能検証 |
| `tools` | CI検証、資産生成、QAレポート、バランス分析 |
| `.github/workflows` | Windowsビルド、iOS未署名IPA、標準/長時間テストのCI |
| `builds` | 既存Windows/iOS成果物と過去CI成果物 |
| `test-output` | 過去のテストログ、QAレポート、CI取得物 |

## 5. シーン構成

シーンは非常に薄く、実体はスクリプトで構築されています。

| シーン | ノード | スクリプト | 役割 |
| --- | --- | --- | --- |
| `scenes/Main.tscn` | `Control` | `scripts/ui/Main.gd` | タイトル、キャラ選択、ショップ、図鑑、実績、設定、ゲーム開始 |
| `scenes/Game.tscn` | `Control` | `scripts/ui/GameScreen.gd` | ラン本編、HUD、入力、ゲームループ、各システムの統合 |
| `scenes/Result.tscn` | `Control` | `scripts/ui/ResultView.gd` | リザルト表示、進行差分、次導線 |
| `scenes/RewardPopup.tscn` | `PanelContainer` | `scripts/ui/RewardPopup.gd` | レベルアップ、報酬、契約、選択UI |

## 6. 主要スクリプト

大規模ファイルは以下です。

| ファイル | 行数 | 役割 |
| --- | ---: | --- |
| `scripts/ui/GameScreen.gd` | 1976 | ゲーム本編の統合、HUD、入力、モーダル、各システム呼び出し |
| `scripts/ui/Main.gd` | 1440 | メインメニュー、ショップ、図鑑、実績、設定、ロードアウト |
| `scripts/core/SurvivorState.gd` | 1395 | ラン状態、定義ロード、プレイヤー/敵/弾/ジェム/進行状態 |
| `scripts/ui/ArenaView.gd` | 819 | Canvas描画。プレイヤー、敵、弾、ジェム、マップ、ミニマップ |
| `scripts/systems/WeaponSystem.gd` | 702 | 武器発射、弾処理、ダメージ、進化/特殊効果 |
| `scripts/systems/MetaProgressionSystem.gd` | 627 | キャラ、祝福、実績、解放、図鑑、ラン後更新 |
| `scripts/systems/SaveSystem.gd` | 427 | `user://chrono_merge_tactics.save`保存、デフォルト補完 |
| `scripts/systems/TrueDungeonMapGenerator.gd` | 411 | 部屋/通路/ショートカット/壁生成 |
| `scripts/systems/EnemySpawner.gd` | 401 | 敵スポーン、敵AI、ボス、特殊行動、敵弾 |
| `scripts/systems/MapGenerator.gd` | 349 | map seed、バイオーム、地形、マップ生成 |
| `scripts/systems/LevelUpSystem.gd` | 319 | レベルアップ候補、進化、無限強化、契約、過充電 |

## 7. 現行ゲーム仕様

### 7.1 基本ループ

1. タイトル/メニューでキャラクター、祝福、設定、ロードアウトを選ぶ。
2. Endlessランを開始する。
3. プレイヤーはWASD/矢印またはタッチUIで移動する。
4. 攻撃は武器システムにより自動発動する。
5. 敵、ボス、クリスタル壁、フィールドギミック、報酬部屋から経験値、宝箱、ドロップ、通貨を得る。
6. レベルアップ時に3択から武器/パッシブ/進化/無限強化などを選ぶ。
7. HPが0になるとリザルトへ遷移し、通貨、実績、解放、進行が保存される。

### 7.2 プレイヤーと成長

`SurvivorState.gd`にHP、移動速度、磁石範囲、レベル、経験値、スコア、キル、コンボ、通貨、各種ラン内進行が集約されています。

主な成長軸:

| 成長軸 | データ |
| --- | --- |
| 武器 | `data/weapons.json`、31種 |
| パッシブ | `data/passives.json`、40種 |
| 武器進化 | `data/evolutions.json`、26種 |
| 無限強化 | `data/infinite_upgrades.json`、6種 |
| 過充電 | `data/overclocks.json`、8種 |
| キャラクター | `data/characters.json`、27種 |
| キャラクター進化 | `data/character_evolutions.json`、27種 |
| 祝福 | `data/blessings.json`、7種 |
| 永続強化 | `data/meta_upgrades.json`、6種 |
| クリスタルショップ項目 | `data/currency_sinks.json`、33種 |

### 7.3 敵とボス

`data/enemies.json`に19種、`data/bosses.json`に6種が定義されています。AGENTS.mdの「敵を初期3種＋中盤1種以上に増やさない」とは現状一致しません。

敵スポーンは`EnemySpawner.gd`が担当します。経過時間、危険地帯、呪い、地形、難易度倍率に応じてスポーン間隔と数が変化します。

通常敵は原則として弾・爆弾・落下・遠距離攻撃を出さない方針がREADMEにあり、遠距離/特殊行動はボス、エリート、イベント、ギミック、プレイヤー武器側に寄せる設計です。ただしコード上には`shooter`など特殊挙動の分岐が残っているため、v2前に実仕様として許可するか整理が必要です。

ボスは5分刻みのスケジュールで出現します。`boss_5`から`boss_30`まで定義されています。

### 7.4 マップ/探索

現行は固定盤面のターン制ではなく、広いフィールドを移動する探索型です。

関連データ:

| データ | 内容 |
| --- | --- |
| `data/map_generation.json` | 部屋数、グリッド、タイルサイズ、ループ接続、ショートカット |
| `data/terrain_types.json` | 安全拠点、鉱山、危険地帯、ボスアリーナなど10種 |
| `data/terrain_rooms.json` | 必須部屋、重要部屋、行き止まり部屋 |
| `data/biomes.json` | 4バイオーム |
| `data/field_events.json` | フィールドイベント4設定 |
| `data/field_gimmicks.json` | 反射クリスタル、雷クリスタルなど6種 |
| `data/field_drops.json` | 武器コア、パッシブコア、磁力鉱石など11項目 |

マップ生成は`RunRng.gd`のstream RNGを使う設計で、同一seedで再現性を確保する意図があります。

### 7.5 武器/パッシブ/進化

武器は31種、パッシブは40種あります。`WeaponSystem.gd`は多くの武器ロジックを直接持ちます。

代表カテゴリ:

| カテゴリ | 例 |
| --- | --- |
| ranged | 魔弾など |
| melee | 刃扇、回廊刃など |
| area | 氷輪、小型重力球など |
| deploy | ルーン門、鉱灯など |
| explosion | 爆弾系 |
| poison | 毒霧など |
| gem/crystal | ジェム・クリスタル関連 |
| summon | ビット/ドローン系 |

README上の近年の調整では、通常レベルアップは武器5枠、パッシブ5枠、フィールド装備とコアだけが上限超過可能という仕様です。

### 7.6 レベルアップ選択

`LevelUpSystem.gd`が候補抽選と適用を担当します。候補は武器、パッシブ、進化、過充電、ルーン契約、無限強化を含みます。

`SelectionActionSystem.gd`により、スキップ、再抽選、封印がラン内リソースとして管理されます。ショップ再抽選は非推奨/廃止扱いで、`shop_reroll.json`にもdeprecated情報があります。

### 7.7 保存/メタ進行

保存先は`SaveSystem.gd`の`user://chrono_merge_tactics.save`です。

保存対象:

| 項目 | 内容 |
| --- | --- |
| 最高スコア | `best_score` |
| クリスタル通貨 | `crystal_currency` |
| 選択キャラ/祝福 | `selected_character`、`selected_blessing` |
| 解放 | キャラ、武器、パッシブ、祝福、進化 |
| 実績/クエスト | `quests_completed`など |
| 図鑑 | `collection_discovered` |
| ロードアウトOFF | `disabled_weapons`、`disabled_passives` |
| 設定 | タッチ、iOS、品質、EXPデバッグ倍率など |

`SaveSystem.gd`は古い保存データ互換のため、多数のデフォルト補完を持っています。

### 7.8 UI/UX

UIはほぼGDScriptで動的構築されています。

主要画面:

| 画面 | 実装 |
| --- | --- |
| タイトル/メニュー | `Main.gd` |
| キャラクター選択 | `Main.gd`、`CharacterCard.gd` |
| ショップ | `Main.gd`、`CurrencySinkSystem.gd`、`ShopCategorySystem.gd` |
| 図鑑 | `Main.gd`、`CollectionCard.gd`、`CollectionFilterSystem.gd` |
| 実績 | `Main.gd`、`AchievementCard.gd` |
| 設定 | `Main.gd`、`ToggleOption.gd`、`SettingsSlider.gd` |
| ゲームHUD | `GameScreen.gd` |
| フィールド描画 | `ArenaView.gd` |
| 報酬選択 | `RewardPopup.gd` |
| リザルト | `ResultView.gd` |

iOS対応として、Safe Area、Safe Play Area、仮想スティック、タップ専用導線、下部タブ、スクロール補助、デバッグOverlay無効化などが実装されています。

### 7.9 入力

Windows:

| 操作 | 内容 |
| --- | --- |
| WASD/矢印 | 移動 |
| R | 回収ドローン |
| Shift | 倍速/速度保持 |
| Esc | ポーズ |
| 1/2/3 | 選択肢 |
| Enter | 開始/決定 |
| マウス | メニュー、選択、ボタン操作 |

iOS/タッチ:

| 操作 | 内容 |
| --- | --- |
| 左下動的仮想スティック | 移動 |
| 右下ボタン | スキャン、回収、倍速 |
| タップ | カード選択、メニュー、ポーズ、報酬確認 |
| ドラッグ | 一覧スクロール |

### 7.10 音声

READMEの方針では完全無音です。`AudioManager.gd`は`audio_disabled := true`で、`play_sfx`は常に`false`を返します。音素材利用や外部音源ダウンロードは見当たりません。

## 8. データファイル一覧

| ファイル | 件数 | 主なキー |
| --- | ---: | --- |
| `balance.json` | 62 | field_width, player_hp, max_owned_weapons |
| `biomes.json` | 4 | star_plain, amethyst_forest, red_mine |
| `blessings.json` | 7 | attack, magnet, mining |
| `bosses.json` | 6 | boss_5, boss_10, boss_15 |
| `build_synergies.json` | 8 | thunder_circuit, melee_ashura |
| `characters.json` | 27 | noah, mio, rai |
| `character_evolutions.json` | 27 | noah, mio, rai |
| `character_unlocks.json` | 27 | noah, mio, rai |
| `currency_sinks.json` | 33 | license系、passive系、blessing系 |
| `enemies.json` | 19 | slime, bat, ghost, golem |
| `evolutions.json` | 26 | starbreaker_bolt, eternal_ice_ring |
| `field_drops.json` | 11 | weapon_core, passive_core, magnet_ore |
| `field_equipment_rewards.json` | 4 | config, reward_rooms, weapon_pool |
| `field_events.json` | 4 | events, start_seconds |
| `field_gimmicks.json` | 6 | reflect_crystal, lightning_crystal |
| `infinite_upgrades.json` | 6 | infinite_damage, infinite_speed |
| `map_generation.json` | 22 | minimum_rooms, grid_width |
| `meta_upgrades.json` | 6 | base_hp, base_damage |
| `overclocks.json` | 8 | starbreaker_bolt, eternal_ice_ring |
| `passives.json` | 40 | move_speed, magnet, might |
| `quests.json` | 17 | survive_10, survive_20 |
| `rune_contracts.json` | 7 | blood_pact, greed_pact |
| `selection_actions.json` | 16 | skip_base_count, reroll_base_count |
| `spawn_curve.json` | 3 | duration_seconds, phases |
| `terrain_types.json` | 10 | safe_room, crystal_corridor |
| `weapon_effects.json` | 31 | magic_bolt, ice_orbit |
| `weapon_unlocks.json` | 31 | magic_bolt, ice_orbit |
| `weapons.json` | 31 | magic_bolt, ice_orbit |

## 9. 生成素材

`test-output/asset_qa_report.md`によると、`assets/generated`はローカル手続き生成SVGで、検査失敗は0です。

| カテゴリ | 検査数 |
| --- | ---: |
| characters | 27 |
| enemies | 19 |
| bosses | 6 |
| weapons | 31 |
| passives | 40 |
| evolutions | 26 |
| blessings | 7 |
| field_drops | 10 |
| field_gimmicks | 6 |
| field_events | 6 |

外部著作物の利用は今回の静的調査では確認されませんでした。ただし、完全保証には各SVG生成スクリプトと元プロンプト/生成履歴の監査が必要です。

## 10. テスト/QA

テスト資産は非常に多く、単体テスト、システムテスト、長時間オートプレイ、iOSレイアウト/性能/省電力、バランス監査を含みます。

既存ログ:

| 証跡 | 内容 |
| --- | --- |
| `test-output/baseline-test-runner-20260620.log` | 既存テスト3248件成功 |
| `test-output/asset_qa_report.md` | 生成素材検査0 failure |
| `balance_report.md` | 静的/候補ランのバランス診断 |
| `test-output/*_qa.md` | EXP、ドロップ、全ジェム回収、キャラ進化など |
| `test-output/screenshots/ios_layout` | iOSレイアウト矩形/検査 |

本資料作成時に確認したGodot実行ファイル:

```text
.tools/godot-download/Godot_v4.2-stable_win64_console.exe --version
4.2.stable.official.46dc27791
```

本資料作成時点では、依頼範囲が調査資料作成であるため、長時間オートプレイやフルビルドは再実行していません。

## 11. ビルド/配布

`export_presets.cfg`にはWindows DesktopとiOSの2プリセットがあります。

Windows:

| 項目 | 内容 |
| --- | --- |
| プリセット | `Windows Desktop` |
| 出力 | `builds/ChronoMergeTactics.exe` |
| product_name | `Gem Survivor Crystal Field` |
| file_version | `0.1.0` |
| product_version | `0.1.0` |
| PCK | embed_pck=true |

iOS:

| 項目 | 内容 |
| --- | --- |
| プリセット | `iOS` |
| 出力 | `builds/ios/GemSurvivor.ipa` |
| bundle_identifier | `com.jankendo14.gemsurvivor` |
| short_version | `0.2.0` |
| version | `2` |
| app_store_team_id | `ABCDE12345` placeholder |
| export_project_only | true |
| capabilities/access_wifi | false |
| push_notifications | false |

`.github/workflows/build.yml`はWindows/macOSでGodot 4.7 stableとexport templatesを取得し、標準テスト、QA生成、Windows export、iOS未署名IPA作成、SHA-256/IPA構造検査、成果物アップロードを行います。

`builds`配下には既存成果物があります。

| 成果物 | 内容 |
| --- | --- |
| `builds/ChronoMergeTactics.exe` | 既存Windows実行ファイル |
| `builds/windows/ChronoMergeTactics.exe` | Windows export |
| `builds/ChronoMergeTactics-Windows-20260621.zip` | Windowsパッケージ |
| `builds/ios/GemSurvivor-unsigned.ipa` | 既存iOS未署名IPA |
| `builds/ci-27482791235` | 過去CI成果物一式 |

## 12. AGENTS.mdとの整合性

### 12.1 適合している点

| ルール | 現状 |
| --- | --- |
| Godot 4 + GDScript | 適合 |
| Windows 10/11向け2Dゲーム | Windows exportあり |
| オンライン通信を入れない | 通信系の実装は確認されない |
| サーバー機能を入れない | サーバー機能は確認されない |
| バランス値を可能な限り`data/*.json`管理 | 多くがJSON化済み |
| 外部素材を無断ダウンロードしない | 生成SVG中心。外部素材利用は静的調査で未確認 |
| ゲームが起動し遊べる状態優先 | 既存ビルド、テストログ、オートプレイ資産あり |

### 12.2 不適合または要整理の点

| AGENTS.mdルール | 現状 |
| --- | --- |
| ゲームモードはEndlessのみ | 実プレイはEndless中心だが、メタ進行、ショップ、図鑑、実績、探索など周辺機能が多数 |
| ストーリーを実装しない | 長編ストーリーは薄いが、キャラ/進化/称号/説明文は多い |
| 複数モードを実装しない | 戦闘モードは1つでも、メニュー/ショップ/図鑑/実績/ロードアウトが大規模 |
| 複雑な属性相性を入れない | 属性相性そのものは薄いが、武器カテゴリ、シナジー、地形、契約、進化が複雑 |
| ブロックを初期4種以上に増やさない | そもそもブロック合成ゲームではない |
| 敵を初期3種＋中盤1種以上に増やさない | 敵19種、ボス6種 |
| 覚醒Lvを初期実装に入れない | キャラクター進化、武器進化、過充電がある |
| Lv5以上のブロックを作らない | ブロックLv概念なし。武器/パッシブLvや無限強化あり |
| 全盤面探索型の複雑な合成連鎖を実装しない | 合成連鎖ではないが、探索・マップ生成は複雑 |
| 長いチュートリアルを入れない | 初回タッチ説明は短い方針。ただしREADME/ヘルプ文章は長め |
| UIとゲームロジックを分離 | 一部は分離済みだが、`GameScreen.gd`と`Main.gd`が大きく統合責務を持つ |
| 全ランダム処理は`RunRng.gd`経由 | 本体は概ねRunRng。直接`RandomNumberGenerator`は`RunRng.gd`内のみ確認。ただしテスト/将来追加時は監視必須 |
| 1ターン処理は`TurnSystem.gd` | ファイルなし。ターン制ではない |
| 合成処理は`MergeSystem.gd` | ファイルなし。合成ゲームではない |
| 発動処理は`ActivationSystem.gd` | ファイルなし。武器発動は`WeaponSystem.gd`中心 |
| 敵処理は`EnemySystem.gd` | ファイルなし。`EnemySpawner.gd`と周辺システム |
| スコア処理は`ScoreSystem.gd` | ファイルなし。`SurvivorState.gd`や各システムに分散 |

## 13. v2前の設計判断ポイント

### 13.1 最重要判断

現行コードを活かすなら、AGENTS.mdを現行サバイバー仕様に更新する必要があります。AGENTS.mdを正とするなら、現行サバイバー資産の大部分は仕様外であり、v2では削除または別プロジェクト化が必要です。

推奨は、まず以下のどちらかを明文化することです。

| 方針 | 内容 | 影響 |
| --- | --- | --- |
| A. サバイバーv2 | 現行`Gem Survivor Crystal Field`を強化する | 既存資産・テスト・ビルドを最大活用できる |
| B. Chrono Merge Tacticsへ再定義 | AGENTS.md通りのEndlessターン制合成ゲームへ作り替える | 現行資産の多くが仕様外。大規模削除/再設計が必要 |

### 13.2 現行を活かす場合の整理対象

1. `GameScreen.gd`を、ゲームループ統合、HUD、入力、モーダル生成に分割する。
2. `Main.gd`を、タイトル、キャラ選択、ショップ、図鑑、実績、設定に分割する。
3. `SurvivorState.gd`を、ラン状態、定義ロード、メタ状態、イベント状態に整理する。
4. `WeaponSystem.gd`を武器カテゴリ別またはデータ駆動発動へ寄せる。
5. スコア計算、通貨計算、実績進行を明確な責務に分離する。
6. READMEの長い更新履歴から、現行仕様書、操作説明、開発メモを分離する。
7. Windows向けを主対象に戻すなら、iOS専用コード/データを保持するか凍結するか決める。

### 13.3 AGENTS.mdへ寄せる場合の整理対象

1. `TurnSystem.gd`、`MergeSystem.gd`、`ActivationSystem.gd`、`EnemySystem.gd`、`ScoreSystem.gd`を新設する。
2. 初期ブロック4種以内、Lv5未満、単純合成、Endlessのみへ仕様を縮小する。
3. 敵は初期3種＋中盤1種以上に制限する。
4. 武器31、パッシブ40、キャラ27、進化26、ボス6、探索、ショップ、図鑑、iOS対応、実績などを仕様外として棚卸しする。
5. 現行サバイバー資産は別ブランチ/別フォルダに退避する。

## 14. リスク

| リスク | 内容 | 影響 |
| --- | --- | --- |
| 仕様名と実体の不一致 | Chrono Merge Tactics名だが中身はGem Survivor | v2方針がぶれる |
| AGENTS.mdとの衝突 | 禁止事項と現行実装が多数不一致 | 追加実装がルール違反になりやすい |
| 巨大UI統合ファイル | `GameScreen.gd`、`Main.gd`が肥大化 | 修正時の副作用が大きい |
| 状態集中 | `SurvivorState.gd`が多数責務を持つ | 保存互換/ランタイム不具合の原因になりやすい |
| データ量過多 | v2で変更対象が多い | バランス崩壊やテスト時間増加 |
| iOS対応の混在 | Windows専用方針とiOS資産が混在 | 対象プラットフォーム判断が必要 |
| README肥大 | 更新履歴が仕様書を兼ねている | 正式仕様の読み取りコストが高い |

## 15. 推奨する次工程

1. 方針A/Bを決める。
2. 方針に合わせて`AGENTS.md`を更新する。
3. READMEから仕様と履歴を分離し、`docs/spec.md`、`docs/changelog.md`、`docs/test_plan.md`へ整理する。
4. v2対象機能を「必須」「削除」「凍結」「後回し」に分類する。
5. 最初の実装前に、Godotヘッドレスの`test_runner.gd`と短時間オートプレイを再実行し、現行ベースラインを確定する。

## 16. 監査で確認した主要ファイル

| ファイル | 確認内容 |
| --- | --- |
| `AGENTS.md` | 開発ルール、禁止事項 |
| `project.godot` | アプリ名、メインシーン、画面設定 |
| `README.md` | 現行仕様、更新履歴、QA方針 |
| `export_presets.cfg` | Windows/iOS export設定 |
| `.github/workflows/build.yml` | CIビルド/テスト/成果物 |
| `scripts/core/RunRng.gd` | seed/stream RNG |
| `scripts/core/SurvivorState.gd` | ラン状態 |
| `scripts/systems/EnemySpawner.gd` | 敵/ボス処理 |
| `scripts/systems/LevelUpSystem.gd` | レベルアップ候補 |
| `scripts/systems/SaveSystem.gd` | 保存 |
| `scripts/systems/WeaponSystem.gd` | 武器処理 |
| `scripts/ui/GameScreen.gd` | 本編統合 |
| `scripts/ui/Main.gd` | メニュー統合 |
| `test-output/asset_qa_report.md` | 生成素材QA |
| `test-output/baseline-test-runner-20260620.log` | 既存テスト成功証跡 |
| `balance_report.md` | バランス診断 |
