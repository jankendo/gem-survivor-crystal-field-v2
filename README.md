# ジェムサバイバー：クリスタルフィールド

Godot 4.2 + GDScript製のWindows/iOS向けサバイバーアクションです。内部フォルダ名とexe名は既存配布互換のため`ChronoMergeTactics`のままです。iOSはGitHub Actionsで未署名IPAを生成します。

## iOS実機UX最終調整メモ

2026年6月14日の実機映像では、ポーズ中の一部ボタンが押せない、一覧をスクロールバーからしか動かせない、CPU/FPS/GPU/Memory系の開発者表示が通常画面へ残る、HUDとモーダルの入力優先順位が不明確という問題を確認しました。

設計と実装はApple公式の[Layout](https://developer.apple.com/design/human-interface-guidelines/layout)、[Buttons](https://developer.apple.com/design/human-interface-guidelines/buttons)、[Designing for games](https://developer.apple.com/design/human-interface-guidelines/designing-for-games)、[Game controls](https://developer.apple.com/design/human-interface-guidelines/game-controls)、[Accessibility](https://developer.apple.com/design/human-interface-guidelines/accessibility)を基準にしています。Godot側は4.2公式の[Control](https://docs.godotengine.org/en/4.2/classes/class_control.html)、[ScrollContainer](https://docs.godotengine.org/en/4.2/classes/class_scrollcontainer.html)、[InputEventScreenTouch](https://docs.godotengine.org/en/4.2/classes/class_inputeventscreentouch.html)、[InputEventScreenDrag](https://docs.godotengine.org/en/4.2/classes/class_inputeventscreendrag.html)を参照しています。

### 映像解析で確認した問題と修正

* ポーズ中にアクションボタンを毎フレーム破棄・再生成していたため、押下から解放までの間に対象Buttonが消えていました。アクション構成が変わった時だけ再構築する方式へ変更しています。
* タッチHUDがポーズ画面と確認ダイアログより後に追加されていました。現在はゲームHUD、暗幕、ポーズ本体、確認ダイアログの順で入力優先度を固定し、ポーズ中はタッチHUD全体を非表示にします。
* 全ScrollContainerを`MobileScrollSystem.gd`へ登録し、コンテンツ領域の指ドラッグで縦横スクロールできるようにしました。移動量12px未満はタップ、12px以上はドラッグです。
* ドラッグ開始時は対象ScrollContainer配下のButtonを一時的に無効化し、指を離した後に元の状態へ戻します。購入、キャラ選択、フィルタ切替の誤発火を防ぎます。
* iOS、Release、Windows標準、Windowsタッチプレビューでは開発者Overlayを生成しません。PCデバッグビルドだけ、隠し操作`Ctrl+F12`で有効化できます。
* iPhone/iPadのタッチUIでは`content_scale_aspect`を`expand`へ切り替え、16:9固定による余分な黒帯を避けつつSafe Area内へUIを配置します。Windows標準は従来の`keep`です。

### iOS入力レイヤー

入力順は以下で固定しています。

1. タイトル復帰確認ダイアログ
2. ポーズメニュー本体
3. ポーズ暗幕
4. タッチHUD
5. ゲーム画面

Buttonは`MOUSE_FILTER_STOP`、装飾ラベル・カード背景・HUD表示は`MOUSE_FILTER_IGNORE`を基本にします。ポーズ暗幕と確認ダイアログ背景だけが全画面入力を停止します。非表示デバッグOverlayが入力を吸うことはありません。

### MobileScrollSystem

キャラクター、祝福、ショップカテゴリ、ショップ商品、図鑑カテゴリ・フィルタ・一覧、実績フィルタ・一覧、設定カテゴリ・項目、ポーズタブ・本文・ログ、リザルト詳細を共通処理しています。横スクロールと縦スクロールがネストしている場合は、ドラッグの主方向と最も深いScrollContainerから操作対象を決めます。軽い慣性と端位置クランプを持ち、スクロールバーは表示補助であり必須操作ではありません。WindowsのタッチUIプレビューではマウスドラッグで同じ経路を確認できます。

### 入力監査と性能ログ

* `TouchHitTestDebugSystem.gd`: 開発時だけタップ座標、最前面Control、Button、`mouse_filter`、表示状態、矩形、CanvasLayer、`z_index`を`user://touch_hit_test_log.csv`へ記録します。通常iOSでは生成・表示しません。
* `TouchActionAuditSystem.gd`: iOSテスト時の画面、Control、操作、座標、期待結果、実結果、遮蔽Control、矩形を`user://ios_touch_action_audit.csv`へ記録します。CIでは同内容を`iOS-Touch-Audit` artifactとして保存します。
* `IosPerformanceLogSystem.gd`: iOSで5秒ごとにFPS、frame time、敵、エフェクト、Projectile、UIノード数、メモリ推定を`user://ios_performance_log.csv`へ記録します。性能値は画面には表示しません。

### iOS実機映像QAチェック

1. 起動直後にCPU/FPS/GPU表示がない
2. タイトルのボタンが大きく押せる
3. キャラ一覧を指で横スクロールできる
4. ショップを指で縦スクロールできる
5. 図鑑/実績を指でスクロールできる
6. ポーズの全ボタンが押せる
7. ポーズ内の内容を指でスクロールできる
8. レベルアップカードをタップ選択できる
9. 契約スキップできる
10. 宝箱画面をタップで閉じられる
11. リザルトのボタンが押せる
12. Home Indicatorに重要UIが被らない
13. Dynamic Islandに重要UIが被らない
14. 10分プレイして操作不能にならない

### 最終入力テスト

```powershell
& $GODOT --headless --path $PROJECT --script "res://tests/test_runner.gd"
& $GODOT --headless --path $PROJECT --script "res://tests/auto_play_ios_pause_scroll_flow.gd"
& $GODOT --headless --path $PROJECT --script "res://tests/auto_play_ios_full_ui_flow.gd"
```

Windows/CIではタッチUIプレビューのGUIアクション配信とマウスドラッグを検査します。Dynamic Island、Home Indicator、端末固有の座標変換、実指での慣性の感触、振動、10分以上の熱・電力状態はiPhone/iPad実機映像で最終確認が必要です。

GitHub ActionsのIPAは未署名です。通常のiPhoneへ直接インストールできないため、AltStore、Sideloadly、Xcode、または自身のApple署名フローを使用してください。

## iOS実機最適化UI/UX再設計メモ

2026年6月13日にApple公式の[Layout](https://developer.apple.com/design/human-interface-guidelines/layout)、[Buttons](https://developer.apple.com/design/human-interface-guidelines/buttons)、[Designing for games](https://developer.apple.com/design/human-interface-guidelines/designing-for-games)、[Game controls](https://developer.apple.com/design/human-interface-guidelines/game-controls)、[Accessibility](https://developer.apple.com/design/human-interface-guidelines/accessibility)を再確認しました。実装面ではGodot 4.2の[DisplayServer](https://docs.godotengine.org/en/4.2/classes/class_displayserver.html)、[Control](https://docs.godotengine.org/en/4.2/classes/class_control.html)、[Camera2D](https://docs.godotengine.org/en/4.2/classes/class_camera2d.html)、[InputEventScreenTouch](https://docs.godotengine.org/en/4.2/classes/class_inputeventscreentouch.html)を参照しています。

今回の実機最適化では次を基準にしています。

* 操作対象は44pt相当以上、主要ボタンは64から80px、補助ボタンは52から60pxを下限にする。
* 仮想スティックは外輪180から220px、ノブ72から96pxとし、入力領域は見た目より30%広くする。
* Dynamic Island、ノッチ、角丸、Home Indicatorを避けるため、端末別推定値と`screen_get_usable_rect()`の両方からSafe Areaを決定する。
* iPhoneは親指操作を優先し、左下を移動、右下をアクション、右上をミニマップとポーズに固定する。
* 小型iPhoneでは長文や詳細を常設せず、横スクロール、折りたたみ、下部シートへ逃がす。
* キャラクター一覧はコンパクトカードと詳細を分離し、小型iPhoneで3件、標準で4件、Pro Maxで5件、iPadで8件以上を同時に確認できる密度にする。
* iPadはiPhoneの単純拡大にせず、4:3に近い画面では2カラムまたは4列グリッドを使う。
* ミニマップはiPhoneで従来の約1.5倍にし、タップで拡大マップを開閉できるようにする。
* iOS、release、desktop初期状態ではCPU、FPS、メモリ、profiler、safe area、touch pointなどの開発者表示を一切出さない。
* Windowsでは従来HUDとキー操作を維持し、設定でタッチUIプレビューを有効にした場合だけモバイルUIを表示する。

端末分類は`compact_phone`、`regular_phone`、`large_phone`、`tablet`の4段階です。寸法値は`data/mobile_ui_scale.json`で管理し、メニュー、キャラクター選択、HUD、仮想スティック、ミニマップ、カメラ表示が同じ分類結果を使います。

### iOS実機品質チェックリスト

* キャラクター一覧が2件だけにならず、端末分類ごとの最低表示数を満たす。
* ボタン、カード、仮想スティックを指で安定して操作できる。
* ミニマップのピンを識別でき、タップで拡大マップを開閉できる。
* CPU、FPS、memory、debug、profiler、内部ID、タッチ座標が通常画面に出ない。
* Dynamic Island、ノッチ、角丸、Home Indicatorに主要UIが重ならない。
* 1334x750相当でも本文16px以上、主要本文18px以上を維持する。
* Pro Maxで操作UIが中央へ寄りすぎず、iPadで余白が間延びしない。
* レベルアップ、契約、宝箱、ポーズ、リザルトをタップだけで連続操作できる。
* 10分以降も低電力設定、通知件数、ミニマップ更新頻度、背景粒子制限が機能する。
* Windows標準起動では巨大なタッチUIが表示されず、WASD、F、R、Shift、Escが維持される。

## iOS完全タッチ対応 / UI設計メモ

Apple公式Human Interface Guidelinesの[Layout](https://developer.apple.com/design/human-interface-guidelines/layout)、[Buttons](https://developer.apple.com/design/human-interface-guidelines/buttons)、[Designing for games](https://developer.apple.com/design/human-interface-guidelines/designing-for-games)、[Game controls](https://developer.apple.com/design/human-interface-guidelines/game-controls)、[Accessibility](https://developer.apple.com/design/human-interface-guidelines/accessibility)を確認しました。Godot側は[DisplayServer](https://docs.godotengine.org/en/4.2/classes/class_displayserver.html)、[InputEventScreenTouch](https://docs.godotengine.org/en/4.2/classes/class_inputeventscreentouch.html)、[InputEventScreenDrag](https://docs.godotengine.org/en/4.2/classes/class_inputeventscreendrag.html)、[Input examples](https://docs.godotengine.org/en/4.2/tutorials/inputs/input_examples.html)を実装根拠にしています。

反映する設計原則:

* iOSではキーボード必須操作とキー前提の案内を表示せず、全操作をタップ、ドラッグ、長押しで完結させる。
* タップ対象は44pt相当以上とし、ゲーム中の主要ボタンは56px以上、仮想スティック領域は120から160px以上を確保する。
* 左下を移動、右下をスキャン、回収、倍速、右上をポーズとし、画面中央の戦闘視認性を維持する。
* `DisplayServer.screen_get_usable_rect()`と端末解像度プリセットを併用し、Dynamic Island、ノッチ、角丸、Home Indicatorを避ける。
* iPhoneは縦積み、横スクロール、下部タブを優先し、iPadは2カラムを許可する。PC UIを単純縮小しない。
* 選択カード全体をタップ可能にし、契約スキップ、報酬確認、ポーズ再開、戻るを常時見えるボタンとして用意する。
* 押下、使用不可、クールダウン、READY、倍速中の状態を色と明度で区別し、必要な操作に短い振動フィードバックを付ける。
* Windowsでは従来のキーボードとマウスを維持し、設定の「タッチUIプレビュー」で同じタッチ導線をマウス検証できるようにする。

レイアウト検証対象は横画面の`1334x750`、`1792x828`、`2532x1170`、`2556x1179`、`2796x1290`、`2388x1668`、`2732x2048`です。

### iOS完全タップ対応

タイトル、キャラクター選択、ショップ、図鑑、実績、設定、ゲームHUD、レベルアップ、ルーン契約、宝箱、ポーズ、リザルトをタップだけで操作できます。iOS実行時は`ios_touch`を自動選択し、Windowsでは設定の「タッチ操作UI」を`on`にするとマウスで同じ導線を確認できます。

ゲーム中は左下の動的仮想スティックで移動し、右下のスキャン、回収、倍速長押しを使用します。ログ、目標表示、ポーズはSafe Area内の上部ボタンです。回収READY、スキャン対象、使用不可、倍速中を明度と文言で表示します。

レベルアップ、パッシブ、進化候補、過充電、ルーン契約はカード全体をタップできます。再抽選、封印、契約スキップは残り回数付きボタンです。宝箱待機中は「報酬を確認」で即時に進行できます。

ポーズはiPhone向けに中央スクロールと下部タブへ切り替わります。リザルトは「もう一度」「キャラ変更」「強化へ」「図鑑へ」「タイトルへ」を常設し、詳細はスクロールできます。Windows版のWASD/矢印、F/右クリック、R、Shift、Esc、1/2/3、Enter、マウス操作は維持しています。

### iOS設定

設定画面には仮想スティック、タッチボタンサイズ、ボタン透明度、右利き/左利き、HUDサイズ、Safe Area余白、振動、描画品質、エフェクト量、ダメージ数字、画面揺れ、通知ログ量があります。iOS低品質設定はエフェクト、ダメージ数字、通知行、UIアニメーション上限をデスクトップより低くします。

初回タッチ操作説明は3枚だけです。

1. 左下をドラッグして移動
2. 右下ボタンでスキャン・回収・倍速
3. カード全体をタップして選択

設定から再表示でき、いつでもスキップできます。

### 操作対応表

| 操作 | Windows | iOS |
| --- | --- | --- |
| 移動 | WASD / 矢印 | 仮想スティック |
| スキャン | F / 右クリック | スキャンボタン |
| 回収 | R | 回収ボタン |
| 倍速 | Shift等を長押し | 倍速ボタンを長押し |
| ポーズ | Esc | ポーズボタン |
| レベルアップ | 1/2/3 / クリック | カードタップ |
| 契約 | 1/2/3 / クリック | カードタップ / スキップ |
| 宝箱 | 自動 / クリック | 報酬を確認 |
| リザルト | Enter / クリック | タップボタン |

### iOSテスト

```powershell
& $GODOT --headless --path $PROJECT --script "res://tests/test_runner.gd"
& $GODOT --headless --path $PROJECT --script "res://tests/auto_play_ios_touch_60sec.gd"
& $GODOT --headless --path $PROJECT --script "res://tests/auto_play_ios_touch_5min.gd"
& $GODOT --headless --path $PROJECT --script "res://tests/auto_play_ios_levelup_selection.gd"
& $GODOT --headless --path $PROJECT --script "res://tests/auto_play_ios_menu_flow.gd"
```

単体テストはキーボード不要導線、選択画面、禁止入力文言、7解像度Safe Area、メニュー、ポーズ、リザルト、iOS性能上限を検査します。GitHub Actionsの標準テストはこれらを`test_runner.gd`経由で実行し、`full_test=true`では4本のiOSタッチ自動プレイも実行します。

### 既知の問題と手動確認

CIとWindowsのタッチプレビューではSafe Areaとタッチ導線を検証できますが、Dynamic Island/Home Indicatorの実表示、端末ごとの指の届きやすさ、振動強度、iPadの余白は実機確認が必要です。iPhoneで仮想スティック、選択カード、契約、宝箱、リザルトが連続操作できること、左右利き手配置、文字サイズ、10分以降の描画負荷を確認してください。

GitHub ActionsはWindows artifactとiOS unsigned IPAを生成します。IPAは未署名で、通常のiPhoneへ直接インストールできません。AltStore、Sideloadly、Xcode、または自身のApple署名フローが必要です。

## 真ダンジョン・倍速・戦況HUD

フィールドは120x120グリッド、1タイル64pxで生成します。14から20室の矩形、横長、縦長、L字、円形、洞窟、小部屋、金庫、闘技場と、直線、L字、ジグザグ、細道、広道、ループ、破壊ショートカットをseedから決定します。床セル以外は奈落で、プレイヤー、敵、ドロップ、宝箱、イベント生成物は床セル上だけに存在できます。

開始部屋は4本以上の出口を持ち、全重要部屋への接続、分岐、ループ、歩行可能率を生成後に検査します。同じseedでは部屋、廊下、敵出現、報酬配置が再現され、ランダム処理は`RunRng.gd`経由です。

プレイ中は設定したキーを長押しすると1.5倍または2.0倍になります。初期値は左Shiftの2.0倍です。Tab、Space、マウス中ボタンへ変更できます。ポーズ、レベルアップ選択、宝箱選択、契約選択、ボス5秒警告中は自動的に等速へ戻ります。

右側の通知ログは最大5件、ポーズの「ログ」タブは直近50件を保持します。ボスは出現5秒前の赤い警告、ミニマップ位置、出現後の専用HPバーを持ちます。武器とパッシブの常時HUDは個別に非表示へ切り替えられ、進化武器は`[進化]`表示になります。

全31武器と26進化は`effect_id`を持ち、`data/weapon_effects.json`の通常/進化演出へ解決されます。未定義ID、未対応描画型、通常/進化バリアント不足は`EffectCompletenessValidator.gd`とテストで失敗します。

## 地形生成・雑魚弾禁止・大型解放拡張

### 雑魚敵の弾禁止

通常敵はProjectileを生成しません。射撃虫は赤い予告線の後に方向固定で突進し、突進後に硬直します。結晶狙撃手は地面へ予告円を置き、時間差で結晶棘を発生させます。遠距離弾を使えるのはボス、エリート、ギミック、イベントだけで、発生元区分と警告表示を持ちます。

### 本格ランダム地形

同じseedから14から20部屋、部屋数以上の接続、多形状廊下、構造壁、採掘結晶、破壊ショートカットを再現します。開始部屋は安全域と4方向以上の出口を持ち、接続グラフ検査で重要部屋への到達を保証します。

地形は安全拠点、結晶回廊、採掘室、危険巣窟、回復の泉、遺物庫、ボス闘技場、イベント室、近道結晶壁、封印室です。地形ごとに敵出現倍率、敵ダメージ倍率、報酬倍率が異なり、回復の泉では敵圧を残したまま継続回復します。

ミニマップは探索済み/未探索部屋、廊下、構造壁、破壊壁、危険地帯、回復、宝、ボス、イベントを描き分けます。現在地と地形特徴はHUDとポーズの地形ガイドで確認できます。

### 追加コンテンツ

キャラクター12体、武器15種、パッシブ23種、進化12種を追加しました。すべて既存の候補上限を守り、追加武器と追加パッシブは初期解放されません。条件達成、キャラクター解放、探索実績、またはショップライセンスで解放します。

追加キャラクター: 回廊騎士ロウ、洞窟地図師ユナ、遺物狩りラズ、祭壇守りオルガ、隧道走者キリ、晶魔女フィア、鍛冶師ドーガ、雷巡礼者テン、爆破鉱夫バル、泉の聖者リノ、虚無地図師、深淵商人。

追加武器: 回廊刃、壁跳弾砲、掘削突進、鉱灯、遺物鎖、祭壇光線、棘種、氷壁、貨幣輪、反響鐘、虚無鏡、溶岩核、羅針星、守護壁、重力錨。

追加進化: 回廊断罪刃、無限跳弾砲、神掘り破砕槍、星鉱灯、呪王鎖、聖域裁光、棘獄庭園、永久氷壁、黄金軌道、終音鐘、虚空反照、特異点錨。

### 通貨とショップ

ショップはキャラ、永続強化、武器ライセンス、パッシブライセンス、祝福、探索装備、鍛冶屋、研究所、外見、高難度の10カテゴリです。所持通貨、おすすめ対象、現在Lv、最大Lv、次Lv効果、必要通貨、条件を常時表示します。追加購入先は28種あり、価格は`base_cost * pow(1.35, current_level)`で上昇します。

通貨は生存、撃破、探索部屋、イベント成功、ボス、宝箱、進化、契約、称号、高難度刻印から算出します。序盤の小強化から、終盤の高額外見・研究・高難度刻印まで段階的な用途を持ちます。

### 図鑑・地形実績

図鑑は解放済み、未解放、シークレット、近接、遠距離、雷、毒、爆発、結晶、探索、通貨、進化可能、未進化で絞り込めます。解放状態、系統、最高Lv、取得回数でも並び替えできます。

地形実績として回廊突破者、採掘王、危険巣の主、遺物中毒、地図埋め、探索者、ショートカット職人を追加し、通貨、キャラクター、武器の解放へ接続しました。

## 最新プレイ映像を反映した製品版UI/UX改善

最新プレイ映像で確認された実績画面の1文字縦並び、キャラクター選択の情報競合、HUDの圧迫、ポーズ画面の視線誘導不足、フィールド対象の説明不足を修正しました。

### 縦長文字バグ修正

`UiLayoutFixSystem.gd`を追加し、ScrollContainer、直接の子Container、Label、RichTextLabel、カードへ横方向の展開フラグと最小幅を設定しました。実績、設定、図鑑、キャラクター選択、ショップ、ポーズ、リザルトの長文は自然に折り返し、画面外へ出る情報はスクロールします。基準解像度は1280x720、UIスケール範囲は0.85から1.18です。

### キャラクター選択UX

左を2列のキャラクター一覧、右を選択中キャラクター詳細に分離しました。キャラクターカードには役割、初期武器、特性、弱点、解放状態、解放条件、購入可能状態、選択中マークを表示します。祝福選択は右詳細内の折りたたみ式2列グリッドで、一覧へ重なりません。

### ポーズ画面UX

上部に時間とキャラクター名、左に9タブ、中央に詳細、右にHP・ビルド・進化・目標・イベントの要約、下部に設定・タイトル復帰・再開を配置しました。タブはステータス、武器、パッシブ、進化条件、ビルド相性、フィールドヘルプ、契約/過充電、設定、ログです。進化条件には現在値と不足値を表示します。

### HUDと次の目標

HPバーを16pxへ縮小し、HP50%未満を黄、25%未満を赤、10%以下を画面端赤パルスで通知します。常時HUDはHP、Lv、EXP、時間、撃破数を中心にし、右側へ主目標1件と副目標最大2件、イベント目標、探索ランクをまとめました。目標は低HP、進化可能、イベント、ボス、武器枠、ビルド相性、進行時間の順で決まります。ミニマップには金・緑・赤・紫・青の簡易凡例を表示します。

### フィールド説明とスキャン

ドロップやギミックへ近づくと名前、効果、短い対処方法を表示します。`F`または右クリックで周辺をスキャンすると、効果、対処方法、報酬、おすすめビルド、5段階危険度を表示します。初回発見はセーブされ、図鑑のドロップ、ギミック、イベント分類へ連動します。

### 動的ドロップ

45秒後から30秒ごとに58%を基準として抽選し、1ラン最大12個、未取得は180秒で消滅します。種類ごとのクールダウンと上限を持ち、進化核などの強力な報酬は遠方へ配置します。出現時は距離付き通知、目標インジケーター、ミニマップへ反映します。`data/field_drops.json`の`spawn_log_enabled`を有効にすると`user://dynamic_field_drops.csv`へ時刻、ID、位置、距離、バイオーム、理由、消滅時刻を記録します。

### 解放UX

武器は5種、パッシブは6種を初期解放とし、未解放項目はレベルアップ候補から除外します。図鑑では解放状態、条件、最高Lv、取得撃破、進化済みかを確認できます。ラン終了時に新しく解放された武器とパッシブをリザルトへ表示します。

### イベントUX

イベントは4分以降、120から180秒間隔で開始します。開始通知、残り時間、目標、リスク、報酬、成功または失敗をHUDとメッセージで示します。イベント図鑑には効果、対処、報酬、おすすめビルド、危険度を表示します。

### 探索マスタリーと探索チェーン

ドロップ回収、遠方・危険地帯回収、ギミック利用、イベント成功を探索スコアへ加算し、D/C/B/A/S/SSを判定します。クリスタル貨ボーナスは順に0/5/10/20/35/40%です。

60秒以内に探索行動を連続するとチェーンが増えます。x2でクリスタル貨+5、x3で60秒間ドロップ率1.5倍、x4で8秒フィーバー、x5で90秒間レア候補率1.75倍です。

### 難易度調整

回復鉱石は動的出現上限4、クールダウン75秒です。武器コア、進化核、過充電核は距離と種類別クールダウンを持ちます。動的ドロップ1個につき敵圧を1.5%増加し、最大18%で制限します。探索報酬を追うほど移動リスクと敵圧が上がる設計です。

### 追加生成アセット

`tools/generate_survivor_assets.py`は既存のドロップ8種、ギミック6種に加え、以下を`assets/survivor/ui/`へ生成します。

* `field_event.svg`
* `field_scan.svg`
* `exploration_chain.svg`
* `exploration_rank_d.svg`
* `exploration_rank_c.svg`
* `exploration_rank_b.svg`
* `exploration_rank_a.svg`
* `exploration_rank_s.svg`
* `exploration_rank_ss.svg`

## UI/UX改善メモ

製品版UI/UX改修では、ダークSF、クリスタル、ネオン、読みやすいカードUIを基準にします。メニューはマウスだけで自然に操作でき、キーボード操作も残します。

反映する方針:

* タイトル、キャラクター選択、ショップ、図鑑、実績、設定、リザルト、ポーズをボタン/カード中心に整理する。
* 選択肢には種別、効果、進化関連、現在の不足を表示し、プレイヤーが次に何を目指すべきかを画面内で伝える。
* 武器カードは赤/橙、パッシブカードは青/緑、進化関連は金/白、シークレットは紫/黒、危険/呪いは赤紫で色分けする。
* ラン中はEscポーズでステータス、武器、パッシブ、進化条件、契約/過充電、設定をすぐ確認できるようにする。
* UI部品を共通化し、ホバー、クリック、スクロール、戻る導線、確認ダイアログを画面ごとにバラつかせない。
* シード制ランダムマップで毎回の探索感を出しつつ、初期地点周辺の安全と再現性を守る。
* 武器エフェクトとキャラクター見た目は外部素材を使わず、プロジェクト内生成アセットとコード描画で視認性を上げる。

## 今回のUI/UX改善

### UI/UX改善方針

タイトル、キャラクター選択、強化、図鑑、実績、設定、ポーズ、リザルトを共通ボタン/カード中心に整理しました。見た目は暗いSF背景、クリスタル調の枠、武器/パッシブ/進化/危険の色分けを基準にしています。

### マウス操作対応

主要メニューはマウスだけで遷移、選択、購入、設定変更、リトライ、タイトル復帰ができます。既存のキーボード操作も残しているため、マウス/キーボード併用で遊べます。

### 進化ヒント表示

レベルアップ報酬カードとポーズの進化条件タブに、進化先、必要パッシブ、不足Lv、宝箱で進化可能かを表示します。パッシブ候補にも関連する進化武器を出すため、ビルド目標を見失いにくくしています。

### ポーズメニュー改善

Escポーズはタブ式です。ステータス、武器、パッシブ、進化条件、契約/過充電、操作/設定、タイトルへ戻るを確認できます。タイトルへ戻る操作は確認ダイアログを挟み、誤操作でランを失わないようにしました。

### ランダムマップ/シード

`scripts/systems/MapGenerator.gd`でシード制ランダムマップを生成します。同じシードなら同じ危険地帯、結晶壁、ミニマップ誘導になります。ランダム処理は`RunRng.gd`経由で行い、初期地点周辺は壁と危険地帯を避けます。

### キャラアセット

`tools/generate_survivor_assets.py`で全キャラクターSVG、シークレット未解放シルエット、パッシブアイコン、UI素材を生成します。外部素材は使っていません。

### 武器エフェクト強化

`data/weapon_effects.json`で武器ごとの通常/進化後エフェクト色、形状、軌跡を管理します。`ArenaView.gd`はこのデータを読み、弾、軌道、命中フラッシュを武器ごとに描き分けます。

### UIコンポーネント

`scripts/ui/components/`に共通UIを追加しました。

* `CrystalButton.gd`
* `CrystalCard.gd`
* `RewardCard.gd`
* `CharacterCard.gd`
* `EvolutionConditionPanel.gd`
* `TabbedPanel.gd`
* `ScrollableList.gd`
* `ConfirmDialog.gd`
* `TooltipPanel.gd`
* `SettingsSlider.gd`
* `ToggleOption.gd`

## クリスタル探索ビルド強化フェーズ

### 攻撃エフェクト強化

`data/weapon_effects.json`を拡張し、全武器に`effect_type`、`primary_color`、`secondary_color`、`hit_effect`、`evolved_effect_type`、`screen_priority`、`opacity`、`lifetime`、`max_effect_count`を持たせました。近接は円弧/斬撃波、雷は稲妻線/感電アイコン/感電爆発リング、爆発は予告円/衝撃波、毒は境界リングと毒状態表示を基準にしています。

### 武器カテゴリ別バランス

`data/weapons.json`に`category`、`range`、`base_damage_score`、`base_cooldown_score`を追加し、`WeaponBalanceSystem.gd`と`SurvivorState`のカテゴリ補正で反映します。

| カテゴリ | 方針 |
| --- | --- |
| ranged | 射程長め、火力控えめ |
| melee | 射程短め、火力高め、ラッシュで伸びる |
| lightning | 感電スタックで中密度の群れに強い |
| poison | 即効性は低いが継続/危険地帯で伸びる |
| explosion | 範囲と爽快感が高いがクールダウン長め |
| deploy/crystal | 位置取りと結晶攻略に強い |
| gem/summon | 安定火力だが序盤は控えめ |

### フィールドドロップ

`FieldDropSystem.gd`と`data/field_drops.json`を追加しました。同じマップシードなら同じ位置に配置され、強力なドロップは初期地点近くに出ません。

| ID | 表示名 | 上限 | 出現開始 |
| --- | --- | ---: | ---: |
| weapon_core | 武器コア | 3 | 3分 |
| passive_core | パッシブ結晶 | 4 | 3分 |
| evolution_core | 進化核 | 2 | 8分 |
| overclock_core | 過充電核 | 1 | 15分 |
| cursed_relic | 呪いの遺物 | 3 | 7分 |
| heal_ore | 回復鉱石 | 10 | 0分 |
| magnet_ore | 磁力鉱石 | 6 | 1.5分 |
| crystal_cache | 結晶貯蔵庫 | 5 | 4分 |

### フィールドギミック

`FieldGimmickSystem.gd`と`data/field_gimmicks.json`を追加しました。

| ID | 表示名 | 役割 |
| --- | --- | --- |
| reflect_crystal | 反射水晶 | 弾を反射し、反射/遠距離ビルドの価値を上げる |
| lightning_crystal | 雷導結晶 | 感電爆発範囲を広げる |
| explosive_vein | 爆薬鉱脈 | 壊すと敵にも当たる爆発 |
| healing_spring | 回復泉 | 危険地帯攻略の拠点 |
| spawn_rift | 召喚裂け目 | 放置すると敵が湧く、破壊可能 |
| sealed_chest_pillar | 封印宝箱柱 | 周囲を掃除すると宝箱を開放 |

### ビルド相性ボーナス

`BuildSynergySystem.gd`と`data/build_synergies.json`を追加しました。所持武器、パッシブ、キャラ特性からタグを集計し、ポーズ/リザルトに発動中または発動履歴を表示します。レベルアップカードには、選ぶと相性が完成する場合に「ビルド完成」と表示します。

実装済み: 雷鳴回路、近接修羅、星詠み、採掘王、毒呪領域、宝石機関、爆裂核、守護陣。

### 近接ラッシュ

`MeleeRushSystem.gd`を追加しました。近接タグ武器で敵を倒すと累積し、20/50/100撃破でラッシュが発動します。

| 段階 | 条件 | 効果 |
| --- | ---: | --- |
| Lv1 | 20撃破 | 4.5秒、近接範囲+20% |
| Lv2 | 50撃破 | 5.5秒、近接範囲+30%、斬撃波表現を強化 |
| Lv3 | 100撃破 | 6.5秒、近接ダメージ+35%。各段階は1ラン1回 |

### 雷感電スタック

`ShockStackSystem.gd`を追加しました。雷攻撃で感電スタックを付与し、3スタックで感電爆発します。2スタック以上の敵は移動速度が下がり、雷導結晶の近くでは爆発範囲が30%広がります。

### 目的地インジケーター

`ObjectiveIndicatorSystem.gd`で目的地優先度を統合しました。進化核、ボス、過充電核、武器コア、宝箱、回復泉、フィールドイベント、磁力鉱石/大量ジェム、召喚裂け目/封印宝箱柱から最大3件を画面端に表示します。

### UI見切れ修正

`UiSafeAreaSystem.gd`と`data/ui_layout.json`を追加しました。1280x720、1366x768、1600x900、1920x1080を想定し、HUD余白、メッセージ下余白、インジケーター数、UIスケールの上下限をデータ管理します。リザルトはスクロール化し、ポーズはセーフエリア内に収めています。

### 難易度調整

強力ドロップには時間ロックと距離制限を設定しました。武器コア/進化核/過充電核は遠く、呪いの遺物は報酬と引き換えに`cursed_power`を上げます。爆発/近接/遠距離/毒/雷はカテゴリ補正で長所短所が出るようにしています。

### 追加アセット

`tools/generate_survivor_assets.py`で以下を生成します。

* `assets/survivor/effects/`: 斬撃、斬撃波、雷線、感電アイコン、感電リング
* `assets/survivor/drops/`: 武器コア、パッシブ結晶、進化核、過充電核、呪いの遺物、回復鉱石、磁力鉱石、結晶貯蔵庫
* `assets/survivor/gimmicks/`: 反射水晶、雷導結晶、爆薬鉱脈、回復泉、召喚裂け目、封印宝箱柱
* `assets/survivor/synergies/`: 8種類のビルド相性アイコン
* `assets/survivor/ui/`: 目的地矢印、近接ラッシュゲージ

## ゲーム概要

敵を倒し、ジェムを吸い、ビルドを選び、進化して、危険地帯と結晶壁を利用しながら30分以降の地獄を目指します。

```text
0〜3分: 気持ちよく倒して吸う
3〜7分: 敵圧が上がり、被弾が起き始める
7〜12分: 進化素材と宝箱を追う
12〜18分: 特殊敵と危険地帯が怖くなる
18〜25分: 強ビルドでないと押される
25〜30分: 死神、地形圧、ボス予告攻撃で逃げ場が減る
30分以降: 完成ビルドでもギリギリ
```

## 操作

| 操作 | 内容 |
| --- | --- |
| WASD / 矢印キー | 移動 |
| F / 右クリック | フィールド対象をスキャン |
| R | 回収ドローン発動 |
| 1 / 2 / 3 | レベルアップ、契約を選択 |
| Enter | 開始 / 選択 / リトライ |
| C | キャラクター選択 |
| U | 解放 / 永続強化 |
| L | 図鑑 |
| A | 実績 / クエスト |
| S | 設定 |
| H | 遊び方 |
| I | タイトルで「無限強化だけ自動選択」ON/OFF |
| Esc | プレイ中ポーズ / 戻る / タイトルで終了 |

## メタ進行

ゲームモードはEndlessのみです。ラン後に「クリスタル貨」を獲得し、次のランへ向けてキャラクター解放と永続強化を進めます。オンライン通信、ランキング、課金、ガチャ、デイリー/ウィークリーはありません。

### クリスタル貨

ラン終了時に、生存時間、撃破数、ボス撃破、宝箱開封、進化武器数、ルーン契約数、称号数から算出されます。通貨系永続強化とキャラクター特性も反映され、セーブデータへ保存されます。

### キャラクター

初期12体以上 + シークレット3体以上を`data/characters.json`で管理します。各キャラクターは初期武器、役割、特性、弱点、武器タグ補正を持ちます。

| キャラ | 初期武器 | 特性 |
| --- | --- | --- |
| 探鉱者ノア | 魔弾 | 吸収範囲+15%、移動速度+5%、HP-10 |
| 氷術師ミオ | 氷輪 | 氷/軌道系が得意 |
| 斬影カエデ | 魂刈り | 近接タグ武器ダメージ+30% |
| 宝石商リリィ | 宝石砲台 | クリスタル貨+20%、レア報酬+6%、攻撃力-14% |
| 終末観測者ゼロ | 光槍 | 進化武器ダメージ+35% |

シークレットキャラは未解放時に名前を隠し、条件だけを短く表示します。

### 永続強化 / 祝福

`data/meta_upgrades.json`で基礎HP、基礎攻撃、吸収範囲、ラン後通貨、宝箱感知、結晶採掘を管理します。祝福は`data/blessings.json`で管理し、キャラクター選択画面からロードアウトとして選びます。

### 実績 / 図鑑

`data/quests.json`の実績は条件達成時に自動で報酬を付与します。図鑑はキャラクター、武器、パッシブ、進化、敵、ボスを発見状態で保存します。

### ポーズ画面

プレイ中にEscで停止し、ステータス、武器、パッシブ、進化条件、契約/過充電、操作/設定、タイトルへ戻るタブを確認できます。進化条件タブでは不足内容を「武器Lv不足」「素材不足」と表示し、条件達成済みなら「宝箱で進化可能」と表示します。

### セーブ初期化

設定画面から初期化できます。誤操作防止のため、`RESET`または`初期化`の入力が必要です。進行状況、通貨、解放、図鑑は消えますが、設定と遊び方既読は残ります。

## 難易度スケーリング再設計

`data/difficulty_curve.json`で時間ごとの倍率を管理します。`scripts/systems/DifficultySystem.gd`が補間し、敵HP、攻撃、速度、出現数、特殊敵率、敵弾、エリート率、ボスHP、結晶HP、ジェム価値へ反映します。

| 時間 | ティア | 方針 |
| --- | ---: | --- |
| 0:00〜3:00 | 1 | 導入。弱いが退屈にしない |
| 3:00〜7:00 | 2 | 敵数増加。被弾が起き始める |
| 7:00〜12:00 | 3 | 特殊敵増加。進化準備が必要 |
| 12:00〜18:00 | 4 | 敵HP/速度/弾が増える |
| 18:00〜25:00 | 5 | 強ビルド以外は押される |
| 25:00〜30:00 | 6 | 死神、射撃敵、ボス圧が強い |
| 30:00以降 | 7 | エンドレス地獄 |

## ボス/宝箱の出現制御

ボスは5/10/15/20/25/30分、以降5分ごとに1体だけです。同時に存在できるボスは最大1体で、既存ボスが生存中なら次のボス時刻では新規出現せず、既存ボスを強化します。

宝箱は最大3個です。発生源はボス撃破、エリート撃破のクールダウン報酬、フィールドイベント、レア結晶壁の低確率だけです。エリート宝箱は通常90秒、幸運で最短60秒まで短縮されます。5分放置された宝箱は消えて大ジェムになります。

宝箱レアリティ:

| 種類 | 内容 |
| --- | --- |
| 通常 | 所持武器/パッシブを強化 |
| 進化 | 条件達成済み武器を進化 |
| 過充電 | 進化武器へオーバークロック |
| 呪い | 強い報酬と敵強化 |
| 黄金 | 複数強化、低確率 |

## EXPカーブ再調整

必要EXPは以下です。

```text
required_exp(level) = 20 + floor(12 * pow(level, 1.55)) + floor(level * level * 0.28)
20分以降: required_exp *= 1.0 + max(0, elapsed_minutes - 20) * 0.015
```

通常敵のジェムドロップは一定割合にし、最低1EXPが敵数で暴走しないようにしました。序盤のジェム価値も抑え、危険地帯、フィーバー、契約、欲張り系で効率を伸ばす設計です。

## 追加武器

| ID | 日本語名 | 役割 |
| --- | --- | --- |
| rune_gate | ルーン門 | 設置型。通過した敵へ継続ダメージ |
| comet_staff | 彗星杖 | 落下型。群れへ彗星を落とす |
| soul_scythe | 魂刈り | 近接円弧。撃破回復の可能性 |
| mirror_shard | 鏡片 | 反射弾 |
| sonic_wave | 音波衝撃 | 周囲ノックバック |
| gem_turret | 宝石砲台 | 回収ジェムの残響を消費して砲撃 |

## 追加進化

| 武器 | 進化名 | 効果 |
| --- | --- | --- |
| ルーン門 | 永劫門 | 大型門が複数発生 |
| 彗星杖 | 隕星群 | 複数彗星が連続落下 |
| 魂刈り | 死魂鎌 | HP吸収つき広範囲斬撃 |
| 鏡片 | 万華鏡片 | 反射弾が強化/分裂 |
| 音波衝撃 | 破音領域 | 全周ノックバック領域 |
| 宝石砲台 | 宝星砲 | ジェム吸収で自動砲撃 |

## 追加敵

| ID | 日本語名 | 役割 |
| --- | --- | --- |
| leech | 吸血虫 | 接近中に継続吸収ダメージ |
| bomber | 爆弾虫 | 死亡時に爆発 |
| crystal_sniper | 結晶狙撃手 | 予告円の後に地面結晶棘 |
| swarm_mother | 群母 | 小型敵を産む |
| void_knight | 虚無騎士 | 高HP、高ダメージ、遅い |
| curse_eye | 呪眼 | プレイヤー周辺に危険地帯を生成 |

## オーバークロック

進化済み武器ごとに最大2つまで付与できます。同じオーバークロックは重複しません。進化後2分間は出現せず、過充電核は1ラン1個、20分以降はレベルアップ候補にも出ます。

例:

| 進化武器 | オーバークロック |
| --- | --- |
| 星砕きの魔弾 | 流星群、超新星、彗星軌道 |
| 永久氷環 | 絶対零度、氷河拡張、粉雪連鎖 |
| 天罰連鎖 | 神罰増幅、落雷領域、感電爆発 |
| 終焉花火 | 多段開花、焼夷残火、花火過積載 |

## フィールドイベント

4分以降、2〜3分に1回、30〜60秒のイベントが発生します。同時発生は最大1つです。

| ID | 日本語名 | リスク/報酬 |
| --- | --- | --- |
| gem_storm | ジェム嵐 | ジェム効率UP、敵出現UP |
| crystal_surge | 結晶隆起 | 壁増加、結晶報酬UP |
| elite_hunt | エリート狩り | エリート出現、撃破で宝箱 |
| danger_bloom | 危険地帯拡大 | 危険地帯増加、倍率UP |
| meteor_rain | 流星雨 | 隕石が落ちるが敵にも当たる |
| cursed_treasure | 呪いの宝箱 | 強い宝箱、敵強化 |

## ルーン契約

5分以降、ボス撃破後に契約を選べます。契約は任意でスキップ可能、1ラン最大5契約です。強力なメリットと明確なデメリットを持ち、スコア倍率も伸びます。

例:

| 契約 | メリット | デメリット |
| --- | --- | --- |
| 血の契約 | ダメージ+40% | 最大HP-20% |
| 欲望の契約 | ジェム価値+50% | 敵出現+25% |
| 雷鳴の契約 | 攻撃速度+30% | 被ダメージ+20% |
| 巨人殺し | ボス/エリート特効 | ザコ火力低下 |
| 破滅の契約 | スコア+150% | 10分ごとに死神 |
| 採掘契約 | 結晶報酬+100% | 結晶壁HP+80% |
| 呪詛契約 | レア報酬率UP | 危険地帯増加 |

## 回収ドローン

3分ごとにゲージが溜まり、READY中にRキーで発動します。周囲のジェムを一気に吸い寄せ、5秒間ジェム価値+20%です。温存できます。

## 開発用バランスログ

`state.balance_log_enabled = true`にすると`user://run_balance_log.csv`へ1秒ごとに出力できます。

記録項目:

```text
time, level, exp_percent, hp_percent, enemy_count, gem_count, projectile_count,
kill_count, chest_count, boss_alive, evolved_weapon_count, difficulty_factor,
damage_taken_last_minute, levelups_last_minute, total_weapon_damage,
currency_gain, crystal_gain, map_room_count, exploration_score
```

## ローカル生成アセット

`tools/generate_survivor_assets.py`で`assets/survivor/`へSVGを生成します。外部ダウンロードは不要です。追加武器、追加敵、オーバークロック、契約、ドローン用UI素材も生成対象です。

```powershell
python "D:\user\documents\Chrono Merge Tactics\tools\generate_survivor_assets.py"
```

## データファイル

| ファイル | 内容 |
| --- | --- |
| data/difficulty_curve.json | 時間難易度 |
| data/weapons.json | 武器 |
| data/passives.json | パッシブ |
| data/evolutions.json | 進化 |
| data/overclocks.json | オーバークロック |
| data/enemies.json | 敵 |
| data/bosses.json | ボス |
| data/field_events.json | フィールドイベント |
| data/rune_contracts.json | ルーン契約 |
| data/spawn_curve.json | スポーン基礎 |
| data/balance.json | 上限、宝箱、フィーバー、ドローン |
| data/biomes.json | バイオーム |
| data/weapon_effects.json | 武器エフェクト |
| data/build_synergies.json | ビルドシナジー |
| data/field_drops.json | フィールドドロップ |
| data/field_gimmicks.json | フィールドギミック |
| data/ui_layout.json | UIセーフエリア / インジケーター |
| data/characters.json | キャラクター |
| data/character_unlocks.json | キャラクター解放条件 |
| data/meta_upgrades.json | 永続強化 |
| data/quests.json | 実績 / クエスト |
| data/mastery.json | キャラクター熟練度 |
| data/blessings.json | 祝福ロードアウト |
| data/collection.json | 図鑑分類 |

## テスト方法

```powershell
$GODOT = "D:\user\Download\Godot_v4.2-stable_win64.exe\Godot_v4.2-stable_win64_console.exe"
$PROJECT = "D:\user\documents\Chrono Merge Tactics"

& $GODOT --version
& $GODOT --headless --path $PROJECT --check-only --script "res://tests/test_runner.gd"
& $GODOT --headless --path $PROJECT --script "res://tests/test_runner.gd"
& $GODOT --headless --path $PROJECT --script "res://tests/smoke_main_scene.gd"
& $GODOT --headless --path $PROJECT --script "res://tests/auto_play_60sec.gd"
& $GODOT --headless --path $PROJECT --script "res://tests/auto_play_5min.gd"
& $GODOT --headless --path $PROJECT --script "res://tests/auto_play_10min.gd"
& $GODOT --headless --path $PROJECT --script "res://tests/auto_play_30min_balance.gd"
& $GODOT --headless --path $PROJECT --script "res://tests/auto_play_meta_progression.gd"
& $GODOT --headless --path $PROJECT --script "res://tests/auto_play_exploration_10min.gd"
& $GODOT --headless --path $PROJECT --script "res://tests/auto_play_unlock_event_15min.gd"
& $GODOT --headless --path $PROJECT --script "res://tests/auto_play_ui_exploration_10min.gd"
& $GODOT --headless --path $PROJECT --script "res://tests/auto_play_procedural_map_10min.gd"
& $GODOT --headless --path $PROJECT --script "res://tests/auto_play_currency_shop_flow.gd"
& $GODOT --headless --path $PROJECT --script "res://tests/auto_play_true_dungeon_10min.gd"
& $GODOT --headless --path $PROJECT --script "res://tests/auto_play_speed_hold_5min.gd"
& $GODOT --headless --path $PROJECT --script "res://tests/auto_play_boss_alert_log_10min.gd"
```

追加/更新テスト:

* `test_difficulty_curve_stronger.gd`
* `test_boss_spawn_pacing.gd`
* `test_chest_pacing.gd`
* `test_boss_chest_spawn_limits.gd`
* `test_exp_curve_rebalanced.gd`
* `test_overclock_system.gd`
* `test_field_events.gd`
* `test_rune_contracts.gd`
* `test_recall_drone.gd`
* `test_character_unlocks.gd`
* `test_character_traits.gd`
* `test_currency_system.gd`
* `test_pause_menu.gd`
* `test_evolution_condition_ui.gd`
* `test_meta_upgrades.gd`
* `test_quests.gd`
* `test_save_reset.gd`
* `test_collection.gd`
* `test_weapon_effect_metadata.gd`
* `test_weapon_effect_visibility.gd`
* `test_weapon_category_balance.gd`
* `test_field_drops.gd`
* `test_field_gimmicks.gd`
* `test_build_synergies.gd`
* `test_melee_rush.gd`
* `test_shock_stack.gd`
* `test_objective_indicators.gd`
* `test_ui_safe_area.gd`
* `test_character_assets.gd`
* `test_ui_mouse_navigation.gd`
* `test_levelup_evolution_hints.gd`
* `test_pause_menu_mouse_tabs.gd`
* `test_random_map_generation.gd`
* `test_map_seed_reproducibility.gd`
* `test_vertical_text_bug.gd`
* `test_menu_layout_regression.gd`
* `test_field_tooltips.gd`
* `test_field_help_scan.gd`
* `test_dynamic_field_drop_spawn.gd`
* `test_weapon_unlocks.gd`
* `test_passive_unlocks.gd`
* `test_field_events_extended.gd`
* `test_exploration_mastery.gd`
* `test_exploration_chain.gd`
* `test_no_trash_enemy_projectiles.gd`
* `test_procedural_map_generation.gd`
* `test_map_connectivity.gd`
* `test_currency_sinks.gd`
* `test_added_characters_weapons_passives_evolutions.gd`
* `test_collection_filters.gd`
* `test_shop_category_ui.gd`
* `test_terrain_difficulty_balance.gd`
* `test_speed_hold_system.gd`
* `test_true_dungeon_generation.gd`
* `test_dungeon_collision_pathing.gd`
* `test_notification_log_system.gd`
* `test_boss_alert_system.gd`
* `test_equipment_hud_system.gd`
* `test_effect_completeness.gd`
* `auto_play_meta_progression.gd`
* `auto_play_10min.gd`
* `auto_play_30min_balance.gd`
* `auto_play_exploration_10min.gd`
* `auto_play_unlock_event_15min.gd`
* `auto_play_ui_exploration_10min.gd`
* `auto_play_true_dungeon_10min.gd`
* `auto_play_speed_hold_5min.gd`
* `auto_play_boss_alert_log_10min.gd`

## ビルド方法

```powershell
$GODOT = "D:\user\Download\Godot_v4.2-stable_win64.exe\Godot_v4.2-stable_win64_console.exe"
$PROJECT = "D:\user\documents\Chrono Merge Tactics"
$OUT = "D:\user\documents\Chrono Merge Tactics\builds\ChronoMergeTactics.exe"

& $GODOT --headless --path $PROJECT --export-release "Windows Desktop" $OUT
```

## GitHub Actions: Windows EXE / iOS未署名IPA

リポジトリは[GitHub](https://github.com/jankendo/chrono-merge-tactics)でPublic運用します。Publicにする理由は、秘密情報を持たないオープンなゲーム本体に対してGitHub ActionsのWindows/macOS runnerを無料枠で利用し、WindowsとiOSの成果物を同じコミットから再現するためです。証明書、Provisioning Profile、Apple ID、API key、セーブデータ、`builds/`は追跡しません。

`.github/workflows/build.yml`は`main`へのpushと手動実行に対応します。

* `windows-build`: `windows-latest`で標準テスト後に`builds/windows/ChronoMergeTactics.exe`を生成し、Windows上でサイズまで検証。
* `ios-unsigned-build`: `macos-latest`で配布用Windows ZIPをクロスexportし、GodotのXcode project生成と未署名`xcodebuild`も実行。
* Godot本体とexport templatesは公式`4.2-stable`をActions内で取得します。大容量テンプレートはリポジトリへ含めません。
* `workflow_dispatch`の`full_test=true`で30分テストと7カテゴリの10分バランステストも実行します。

Artifacts:

| Artifact | 内容 |
| --- | --- |
| `ChronoMergeTactics-Windows` | `ChronoMergeTactics-Windows.zip`（中に`ChronoMergeTactics.exe`と`README.md`） |
| `GemSurvivor-iOS-unsigned-IPA` | `GemSurvivor-unsigned.ipa`, `README.md`, `IOS_UNSIGNED_README.md` |
| `Balance-Report` | `balance_report.md` |

GitHubの`Actions`から対象runを開き、画面下部の`Artifacts`から取得します。

## iOS export / 未署名IPA

`export_presets.cfg`には既存の`Windows Desktop`に加えて`iOS` presetがあります。

```text
表示名: Gem Survivor Crystal Field
Bundle Identifier: com.jankendo14.gemsurvivor
App Store Team ID: ABCDE12345
Orientation: landscape
Export mode: Xcode project only
```

`ABCDE12345`は未署名CI exportを成立させるための仮Team IDです。正式署名には自分のApple Developer Team IDへ変更してください。iOSのネイティブビルドにはXcodeが必要なため、GitHub ActionsではmacOS runnerを使います。

生成される`GemSurvivor-unsigned.ipa`は未署名です。通常のiPhoneへそのままインストールできません。AltStore、Sideloadly、またはXcodeと自分のApple accountで署名/サイドロードしてください。無料Apple ID署名は期限切れ後に再署名が必要になる場合があります。App Store/TestFlight配布物ではありません。

## iOSタッチ操作 / パフォーマンス

iOSでは左下の仮想スティックと、右下のスキャン、回収ドローン、倍速ホールド、ポーズを表示します。仮想スティックはマウスドラッグでも確認できます。Windowsでは自動設定時に非表示で、WASD/矢印、F/右クリック、R、Shift、Escを維持します。

設定:

* タッチ操作UI: 自動 / ON / OFF
* 仮想スティック: ON / OFF
* タッチボタンサイズ: 小 / 標準 / 大
* 描画品質: 低 / 標準 / 高
* エフェクト量: 控えめ / 標準 / 多い
* ダメージ数字、画面揺れ: ON / OFF

`data/balance.json`の`desktop_low/standard/high`と`ios_low/standard/high`で敵、ジェム、弾、敵弾、エフェクト、文字、背景粒子の上限を分離します。iOS初期値は`ios_standard`で、Windowsの上限は従来の`desktop_standard`を維持します。

## 2026-06 バランス再調整

カテゴリの役割を残したまま、遠距離/毒/設置/ノックバック/採掘の序盤性能を補強し、近接、通貨、回復、永続強化、過充電の上振れを抑えました。

* 遠距離: 安全性を維持し、カテゴリ火力を`0.92`へ緩和。密集処理は近接/爆発より低い。
* 近接: 火力`1.20`、範囲`0.86`。ラッシュLv3は+35%、6.5秒、各段階1回だけ。
* 雷: 連鎖/感電による群れ処理を維持し、単体倍率は`0.92`。
* 毒: 初撃と範囲を強化し、継続戦向け。即効火力は`0.84`に制限。
* 爆発: 範囲火力`1.08`、CD`1.18`で、強いが遅い。
* 設置: 火力`0.92`、範囲`1.12`、CD`0.92`。廊下/部屋配置で伸びる。
* 反射/ノックバック: ノックバック火力を`0.84`へ強化し、防御役割を維持。
* 結晶: 通常敵への補助火力を改善し、壁報酬倍率は抑制。
* ジェム/通貨: 序盤火力`0.80`、CD`1.12`。成長後に伸びるがリリィとSS報酬を弱体化。
* 防御/回復: 再生は最大3 HP/秒、吸収治癒は最大4 HP、泉は最大6 HP/2.5秒。防御は無敵化しない。

進化は最短5分、次の進化まで3分、過充電は進化後2分待機です。過充電は武器ごとに最大2個、過充電核は1ラン1個です。基礎攻撃永続強化は1Lvあたり+1.5%、通貨強化は+2.5%です。

## バランス分析

静的JSONと任意の`run_balance_log.csv`から診断レポートを生成します。自動でゲーム数値を書き換えることはありません。

```powershell
python tools/analyze_balance.py
python tools/analyze_balance.py --log path\to\run_balance_log.csv --output balance_report.md
```

`balance_report.md`には強弱候補、カテゴリDPS proxy、未使用/過使用の判定可否、進化時刻、5/10/20/30分の敵圧、レベル、通貨、回復、総武器ダメージを出力します。実測判断には複数runのログと`weapon_damage_by_id`を併用してください。

## CI/バランス検証

```powershell
python tools/validate_github_actions.py
python tools/validate_ios_workflow.py

& $GODOT --headless --path $PROJECT --script "res://tests/test_runner.gd"
& $GODOT --headless --path $PROJECT --script "res://tests/auto_play_balance_ranged_10min.gd"
& $GODOT --headless --path $PROJECT --script "res://tests/auto_play_balance_melee_10min.gd"
& $GODOT --headless --path $PROJECT --script "res://tests/auto_play_balance_lightning_10min.gd"
& $GODOT --headless --path $PROJECT --script "res://tests/auto_play_balance_poison_10min.gd"
& $GODOT --headless --path $PROJECT --script "res://tests/auto_play_balance_explosion_10min.gd"
& $GODOT --headless --path $PROJECT --script "res://tests/auto_play_balance_deploy_10min.gd"
& $GODOT --headless --path $PROJECT --script "res://tests/auto_play_balance_gem_10min.gd"
```

## 既知の問題

* 自動テストでは30分相当まで通過しますが、手動での「気持ちよさ」は追加調整が必要です。
* iOS IPAは未署名で、実機確認には利用者側の署名が必要です。
* Windows上ではXcode/iOS実機ビルドを直接検証できないため、iOS成果物の最終判定はGitHub Actions macOS jobで行います。
* タッチ操作はヘッドレス設定/入力テスト済みですが、実機の指サイズ、セーフエリア、発熱、フレームレートは手動確認が必要です。
* 追加SVGは生成済みですが、描画は軽量なコード描画中心です。全面スプライト化は今後の改善余地です。
* ボス/エリートの遠距離攻撃と地面結晶棘にはコード描画の予告があります。専用アニメーションと個別SEは追加調整余地があります。
* 感電爆発、爆発鉱脈、宝箱柱の報酬ログは最低限です。派手さと報酬演出は今後の調整余地です。
* フィールドギミックはEndless中毒性を優先した軽量実装です。専用SEや複雑なアニメーションは未実装です。
* ヘッドレステストでは実ピクセルの文字レンダリングまでは判定できないため、各対象解像度での最終目視確認が必要です。
* マウスホバーは近接説明を利用し、詳細スキャンの明示操作はFまたは右クリックです。

## 次に手動確認すべきこと

* 5分時点の敵圧
* 10分時点の進化重要度
* 宝箱が多すぎないか
* ボスが山場になっているか
* レベルアップ頻度
* ルーン契約が面白いか
* 回収ドローンが気持ちいいか
* キャラクターごとの初期武器と弱点が直感的か
* クリスタル貨の獲得量が解放テンポとして気持ちいいか
* ポーズ中の情報量が多すぎないか
* 近接ラッシュが強すぎず、近接を選ぶ理由になっているか
* 感電スタックと感電爆発が見えて、雷ビルドの強みとして伝わるか
* フィールドドロップを拾いに行きたくなる配置と報酬になっているか
* 反射結晶、雷結晶、爆発鉱脈、回復泉、リフト、宝箱柱が短時間で理解できるか
* 1280x720、1366x768、1920x1080でHUDとリザルト表示が窮屈でないか
* 30分を目指したくなるか
* 実績、設定、図鑑、ポーズ、リザルトで1文字縦並びが完全に消えたか
* キャラクター一覧と折りたたみ祝福が重ならず、購入可能状態が伝わるか
* ポーズ右側サマリーから次の行動を判断できるか
* HPバー、目標、フィールドヘルプが戦闘視界を塞がないか
* ドロップとギミックの近接説明、F/右クリックの詳細説明が短時間で理解できるか
* 動的ドロップ通知と矢印が探索したくなる距離・頻度になっているか
* 探索ランクとチェーンが次の目標へ移る動機になっているか
* Actionsから`ChronoMergeTactics-Windows`と`GemSurvivor-iOS-unsigned-IPA`を取得できるか
* IPAをAltStore/Sideloadlyで自分のApple ID署名へ変換できるか
* iPhone実機で仮想スティック、スキャン、回収、倍速ホールド、ポーズが操作できるか
* iOS標準/低品質で10分以降も重すぎず、発熱が許容範囲か
* 遠距離/近接/雷/毒/爆発/設置の実プレイ差が自動プレイ結果どおりか
* 通貨/永続強化を進めたセーブでも難易度が崩壊しないか
