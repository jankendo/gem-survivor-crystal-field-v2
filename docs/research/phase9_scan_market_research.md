# Phase 9 Scan Market Research

## 調査方針

Web上の公式ページ、公式Wiki、補助Wiki、信頼できる攻略/技術記事を確認した。ここでの比較は設計原則を作るための材料であり、各作品の評価や売上をスキャン機能だけの因果として扱わない。

## 比較表

| 作品 | 確認できた事実 | 本作への推論 | 採用 | 不採用 |
| --- | --- | --- | --- | --- |
| Metroid Prime Remastered | Nintendo公式ページはScan Visorが機械、歴史、敵弱点の調査に使えると説明している。 | スキャンは情報表示だけでなく、敵攻略、世界理解、探索先判断へ接続すると価値が出る。 | 敵/地形/部屋/アイテムを発見対象にする。 | 長文ログ収集を主報酬にしない。 |
| Subnautica | Scannerは長押しで生命体、技術、fragmentを調べ、BlueprintやDatabankへつながる。 | 長押しは明確な対象と進捗があると理解しやすい。 | 長押し抽出に1.45秒の進捗と対象名を出す。 | 10秒級の長時間停止はbullet-heavenと相性が悪い。 |
| No Man's Sky | Analysis Visorは未発見対象をscanしてdiscoveriesへ追加し、Units報酬や位置/資源情報とつながる。 | 発見を報酬化し、次の行動先を示す必要がある。 | 初回発見で探査共鳴を付与し、navigation targetを設定する。 | 恒久収集図鑑や経済報酬をPhase 9の主軸にしない。 |
| Deep Rock Galactic | Official WikiではLaser Pointerがhold操作で情報共有、Terrain Scannerがholdで3D地形表示に使われる。 | 戦闘中の短押し/長押し役割分担と、迷子防止の位置情報が重要。 | 短押し発見、長押し抽出に分け、マップ/部屋発見へ接続する。 | 3D地形mapや協力pingは2D単独サバイバーには重い。 |
| Death Stranding | Odradekは地形、貨物、危険、BTの検出に使われる。補助記事はR1のpulse scanと水深/危険表示を説明する。 | 危険と報酬を同時に見せるscanは、移動判断を変える。 | 敵/地形/イベント発見を対象に含める。 | 派手な全画面post-process波形はiOS Compatibilityの軽量方針と衝突する。 |
| Warframe | Codex Scannerは対象のscan数、完了表示、Stealth Scan報酬、patch history上の不具合修正が確認できる。 | 完了済み/未完了を区別し、同じ対象を何度も報酬化しないことが重要。 | `scan_discovered_keys`で初回発見だけ探査共鳴を得る。 | 消耗品scanner chargeや外部reputation報酬は入れない。 |
| Horizon Forbidden West | PlayStation公式ページはFocusが資源/興味地点のhighlight、敵情報、部位tag、装備強化や依頼に役立つと説明している。 | scan後の行動は攻撃、収集、強化判断へ直結するとよい。 | 敵やアイテムを発見し、目標表示とリザルト知識へ接続する。 | 複雑な部位破壊/属性相性は導入しない。 |

## 採用した設計原則

* 情報取得だけで終わらせず、発見、navigation、探査共鳴、抽出へつなげる。
* 短押しは一瞬の発見、長押しは報酬化された抽出にする。
* スキャンは使うと得をするが、使わなくてもランが詰まない。
* 戦闘中でも片手で使えるよう、追加メニューではなく既存touch scanボタンに統合する。
* 発見報酬はラン内限定で、ショップ永久解放や課金価値にしない。
* 初回発見だけ報酬化し、重複scanで共鳴を稼げないようにする。
* スキャンの視覚効果は単発リングと少数outlineに留め、iOS minimalではさらに減らす。

## 仮説と未検証

* 仮説: 発見3回で長押し抽出を解放すると、スキャンの短期目標が明確になる。
* 仮説: 1.45秒の長押しは戦闘中に成立可能で、誤爆しにくい。
* 未検証: 人間プレイヤーがスキャン価値を初回ランで理解できるか。
* 未検証: 探査共鳴3点の報酬密度が強すぎないか。
* 未検証: 実iPhone touchで長押し中の移動と自動攻撃が邪魔にならないか。

## 参照ソース

* Metroid Prime Remastered Nintendo公式: https://www.nintendo.com/us/store/products/metroid-prime-remastered-switch/
* Subnautica Scanner Wiki: https://subnautica.fandom.com/wiki/Scanner_(Subnautica)
* No Man's Sky Analysis Visor Wiki: https://nomanssky.fandom.com/wiki/Analysis_Visor
* Deep Rock Galactic Laser Pointer Official Wiki: https://deeprockgalactic.wiki.gg/wiki/Laser_Pointer
* Deep Rock Galactic Terrain Scanner Official Wiki: https://deeprockgalactic.wiki.gg/wiki/Terrain_Scanner
* Death Stranding Odradek Wiki: https://deathstranding.fandom.com/wiki/Odradek
* Death Stranding scanner guide: https://www.pushsquare.com/guides/death-stranding-how-to-use-the-scanner
* Warframe Codex Scanner Wiki: https://warframe.fandom.com/wiki/Codex_Scanner
* Horizon Forbidden West PlayStation公式: https://www.playstation.com/en-us/games/horizon-forbidden-west/
