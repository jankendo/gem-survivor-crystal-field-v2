extends RefCounted
class_name MapPauseSystem

const REASON_MAP := "map"
const REASON_MENU := "menu"
const REASON_LEVELUP := "levelup"
const REASON_CHEST := "chest"
const REASON_CONTRACT := "contract"

func set_reason(state, reason: String, active: bool) -> void:
	if active:
		state.pause_reasons[reason] = true
	else:
		state.pause_reasons.erase(reason)

func refresh_modal_reasons(state, map_open: bool) -> void:
	set_reason(state, REASON_MAP, map_open)
	set_reason(state, REASON_MENU, state.paused)
	set_reason(state, REASON_LEVELUP, state.level_up_pending)
	set_reason(state, REASON_CHEST, state.chest_pending)
	set_reason(state, REASON_CONTRACT, state.rune_contract_pending)

func gameplay_paused(state) -> bool:
	return bool(state.pause_reasons.get(REASON_MAP, false))

func active_reasons(state) -> Array:
	return state.pause_reasons.keys()
