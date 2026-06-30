# Phase 9 Crystal Survey Design

## 操作

* 短押し: スキャン。周辺の部屋、アイテム、イベント、敵、地形候補を発見する。
* 長押し: 共鳴抽出。探査共鳴が満タンで、近くに適格な封印対象がある場合だけ成立する。
* 長押し成立時間: 1.45秒。倍速で一瞬成立しないようtouch holdの実時間扱いを維持する。

## 探査共鳴

`survey_resonance`はラン内限定値で、上限は3。新しい部屋、希少アイテム、イベント、ギミックの初回発見で増える。同じ`scan_discovered_keys`から複数回得られない。ラン終了でリセットする。

## 発見対象

* room: `map_data.rooms`の近距離候補。発見時に`explored_room_ids`へ入る。
* drop/equipment/gimmick: `FieldObjectAvailabilitySystem`で現在取得可能な対象だけ。
* enemy: 近距離の敵type代表、boss/eliteを含む。
* event: 実体を持つactive field event。

## 共鳴抽出

対象は`scan_extractable=true`、取得可能時刻到達済み、未取得、距離内のfield equipmentまたはweapon/passive core drop。成立後はsourceをプレイヤー位置へ寄せ、`FieldDropSystem`または`FieldEquipmentPickupSystem`の正規処理に渡す。武器/パッシブコアは通常の候補選択画面を通る。

## 禁止

* 未購入装備の永久解放。
* `unlock_seconds`前の表示や抽出。
* ボス報酬、イベント未達成報酬の横取り。
* RNGを消費する再抽選。
* 同じ対象からの重複共鳴。

## telemetry

オンライン送信しない。`scan_telemetry`に`scan_tap_count`、`scan_hold_count`、`scan_cancel_count`、`scan_discoveries`、`rooms_discovered_by_scan`、`items_discovered_by_scan`、`events_discovered_by_scan`、`resonance_earned`、`extraction_attempts`、`extraction_successes`、`extraction_cancels`、`scan_query_us`を記録する。
