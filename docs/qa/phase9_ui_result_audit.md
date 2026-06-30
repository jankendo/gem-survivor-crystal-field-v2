# Phase 9 UI / Result Audit

## 実装前

* 通常レベルアップ以外の選択でも、再抽選/スキップ/封印系UIが混ざるリスクがあった。
* 最高生存時間は秒数表示が混在し、新規プレイヤーに読みにくかった。
* damage numberとtouch hapticはPhase 8で軽量化済みだが、設定項目として残っていた。
* ポーズ中にseed確認/コピー導線がなかった。
* リザルトは総合結果中心で、武器別総ダメージの理解が弱かった。

## 実装後

* RewardPopupはcontextを受け、LEVEL_UP以外でlevel-up actionsを生成しない。
* TouchSelectionSystemもLEVEL_UP以外のaction requestを送らない。
* 最高生存時間は`JaText.format_time`で`MM:SS`表示に統一。
* 設定UIからdamage numberとtouch hapticを削除し、旧保存値は無視する。
* pause actionsにseed copyを追加し、headlessでも安全に成功扱いできる。
* ResultViewは`ResultDamageFormatter`で武器別総ダメージと割合を表示する。

## 自動検証

* `test_selection_actions_level_up_only.gd`
* `test_selection_actions_hidden_for_core.gd`
* `test_selection_actions_hidden_for_chest.gd`
* `test_selection_action_charge_integrity.gd`
* `test_survival_time_japanese_format.gd`
* `test_best_survival_display_consistency.gd`
* `test_damage_numbers_removed.gd`
* `test_touch_haptics_removed.gd`
* `test_pause_seed_copy.gd`
* `test_result_weapon_damage_totals.gd`
* `test_result_damage_safe_area.gd`
