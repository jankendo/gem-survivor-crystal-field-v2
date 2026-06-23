# v2 UI Component Map

## Main

`scripts/ui/Main.gd`は画面全体のオーケストレーションを担当する。保存、購入、解放、実績反映など既存ロジックは既存Systemを呼び出す。

| 責務 | ファイル | 内容 |
| --- | --- | --- |
| 画面状態 | `scripts/ui/main/MainScreenState.gd` | current/previousとメニュー画面判定 |
| タイトル階層 | `scripts/ui/main/TitleScreenController.gd` | タイトルのボタンID、ラベル、優先度、色 |
| ショップ選択 | `scripts/ui/main/ShopScreenController.gd` | カテゴリindexのwrap/clamp/select |
| 図鑑選択 | `scripts/ui/main/CollectionScreenController.gd` | タブ、フィルタ、ソートindex |
| 共通テーマ | `scripts/ui/v2/V2ThemeProvider.gd` | 色、余白、枠線、panel style |
| アセット解決 | `scripts/systems/V2AssetRegistry.gd` | preferred PNGとfallback SVGの解決/cache |

## Game HUD

| 責務 | ファイル |
| --- | --- |
| HUD文言 | `scripts/systems/V2HudPresenter.gd` |
| Momentum状態 | `scripts/systems/V2MomentumSystem.gd` |
| Momentum計測 | `scripts/systems/V2MomentumTelemetry.gd` |
| 通知優先度 | `scripts/systems/V2FeedbackDirector.gd` |
| HUD配置 | `scripts/ui/GameScreen.gd` |

`GameScreen.gd`はNodeの配置と既存ゲーム進行を維持する。Momentum文言、発動理由、結果要約、通知優先度は専用Systemへ寄せる。

## Result

`scripts/ui/ResultView.gd`は、リザルト表示順を次の階層へ整理する。

1. 生存時間
2. スコア
3. 到達レベル
4. 撃破数
5. ボス撃破
6. 主力武器
7. 進化武器
8. 発動シナジー
9. Momentum成果
10. 詳細、解放、通貨、次の目標

Momentum成果の行生成は`V2HudPresenter.gd`へ寄せる。

## Feedback Priority

| Priority | Events |
| --- | --- |
| critical | キャラクター進化、ボス撃破、武器進化 |
| high | ボス出現、ボス警告、全ジェム回収、ビルド相性、新規解放 |
| normal | Momentum開始、Momentum段階上昇 |
| low | Momentum終了予告、連続回収 |

同時に大バナーを複数出さず、同一内容の連続表示を抑止する。ゲーム停止中は表示時間を進めない。
