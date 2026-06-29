# Phase 8 iOS極限軽量・ゲームプレイUX

## 目的

Phase 8は、敵数、スポーン、攻撃、報酬、RNGを維持したまま、iOSの表示負荷と操作上の迷いを減らす更新である。Windows/iOSともGodot 4.7と`gl_compatibility`を正本とする。

## 極限軽量

`effect_density=minimal`は`desktop_minimal` / `ios_minimal`へ解決される。iOSでは表示上限を弾56、ジェム120、エフェクト20、ダメージ数字0、背景粒子0とする。軌跡、二次glow、装飾、重複演出を停止するが、simulation配列、衝突、DPS、撃破、EXP、報酬、RNGには触れない。Critical表示はsoft budgetを超えても残す。

省電力モードは`EffectiveSettingsResolver`がラン開始時の実効設定だけを上書きする。保存済みの品質・振動・背景設定は変更しない。実効値は30fps、minimal、振動OFF、背景粒子OFF、低頻度UI更新となる。

## 操作と清算

タッチ倍速は0.9秒長押しで固定し、固定中の短いタップで解除する。ポーズ、マップ、選択画面、宝箱、ボス警告中は一時的に1倍へ戻り、閉じると固定状態を復元する。固定状態は新規ランで初期化する。

ゲーム中の「ランを終了」はタイトルへ直行しない。`RunSettlementSystem`で一度だけ清算し、`end_reason=manual_exit`、`run_completed=false`、`manually_ended=true`を持つリザルトを表示する。

## UIと探索

設定の複数候補は日本語`OptionButton`で選択する。通常変更では画面を再構築せず、省電力プロファイル切替時だけスクロール位置とフォーカスを復元して再構築する。

コア候補は解放済み、ON、未封印、未最大、容量内だけを決定的RNGで選ぶ。フィールド対象は`FieldObjectAvailabilitySystem`を処理、描画、ミニマップ、スキャン、目標で共有し、解放時刻前は存在を見せない。

イベント誘導は生成した壁、イベントエリート、危険地帯、呪い宝箱のruntime IDへ向ける。生存型イベントに偽の位置矢印は出さない。ショップは条件、現在値、目標、残量、費用、所持通貨、進化関係、購入不可理由を日本語で表示する。

## CI

Fast Gateは15分、Phase 8 Performanceは20分、Releaseは25分、Nightlyの各シャードは90分を上限とする。Phase 7の既存検証は削除せず、Phase 8の27テストと決定的600敵ストレスを追加する。
