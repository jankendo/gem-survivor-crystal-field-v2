# Gem Survivor iOS unsigned IPA

This build includes the landscape iPhone/iPad touch HUD, virtual joystick, touch actions, card selection, and safe-area layout. The game flow from title to result does not require a hardware keyboard.

The current build also includes shop rerolls, increased normal EXP, the developer EXP multiplier setting, persistent field drops, seed-reproducible random field equipment, global magnet/drone gem collection, resonance magnet core, and one-per-run character evolution. Global gem collection is batched and uses a single notification to avoid iOS frame spikes.

This IPA is unsigned. It cannot be installed directly on a normal iPhone.

To test on your own device, sign or sideload it using:

- AltStore
- Sideloadly
- Xcode with your own Apple account

Free Apple ID signing may expire and require re-signing. This build is for local development and testing only. It is not for App Store or TestFlight distribution.

The export preset contains the placeholder Apple Team ID `ABCDE12345`. Replace it with your real Apple Developer Team ID when using your own signing flow.

## 日本語

本ビルドはiPhone/iPad向け横画面タッチHUD、仮想スティック、タッチアクション、カード選択、Safe Area対応を含みます。タイトルからリザルトまで外部キーボードなしで操作できます。

現在のビルドには、ショップ再抽選、通常EXP増加、開発者EXP倍率、永続フィールドドロップ、seed再現可能なランダムフィールド装備、磁石/ドローンの全ジェム回収、共鳴磁核、1ラン1回のキャラクター進化も含まれます。全ジェム回収はバッチ処理と通知1件に集約し、iOSの負荷スパイクを抑えます。

このIPAは未署名です。通常のiPhoneにはそのままインストールできません。

AltStore、Sideloadly、またはXcodeで自分のApple ID署名を行ってください。無料Apple ID署名では一定期間ごとに再署名が必要になる場合があります。

このビルドはローカル開発・動作確認用です。App StoreまたはTestFlight配布用ではありません。

export presetのApple Team ID `ABCDE12345`は仮値です。正式署名時は自分のApple Developer Team IDへ変更してください。
