extends RefCounted
class_name SelectionContextSystem

const NONE := "none"
const LEVEL_UP := "level_up"
const WEAPON_CORE := "weapon_core"
const PASSIVE_CORE := "passive_core"
const CHEST := "chest"
const RUNE_CONTRACT := "rune_contract"
const OVERCLOCK := "overclock"
const EVENT_REWARD := "event_reward"
const FIELD_EQUIPMENT := "field_equipment"
const CHARACTER_EVOLUTION := "character_evolution"

static func current_context(state) -> String:
	if state == null:
		return NONE
	if not bool(state.level_up_pending):
		return NONE
	if not state.pending_core_choice.is_empty():
		return WEAPON_CORE if String(state.pending_core_choice.get("kind", "")) == "weapon" else PASSIVE_CORE
	if not state.pending_field_equipment_choice.is_empty():
		return FIELD_EQUIPMENT
	if bool(state.rune_contract_pending):
		return RUNE_CONTRACT
	if bool(state.chest_pending):
		return CHEST
	if bool(state.character_evolution_pending):
		return CHARACTER_EVOLUTION
	var stored := String(state.selection_context)
	return LEVEL_UP if stored == "" or stored == NONE else stored

static func is_level_up(state) -> bool:
	return current_context(state) == LEVEL_UP

static func can_use_levelup_actions(context: String) -> bool:
	return context == LEVEL_UP

static func label_for(context: String) -> String:
	match context:
		LEVEL_UP:
			return "レベルアップ"
		WEAPON_CORE:
			return "武器コア"
		PASSIVE_CORE:
			return "パッシブコア"
		CHEST:
			return "宝箱"
		RUNE_CONTRACT:
			return "ルーン契約"
		OVERCLOCK:
			return "過充電"
		EVENT_REWARD, FIELD_EQUIPMENT:
			return "探索報酬"
		CHARACTER_EVOLUTION:
			return "キャラ進化"
	return "なし"
