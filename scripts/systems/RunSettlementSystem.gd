extends RefCounted
class_name RunSettlementSystem

var settled := false
var manual_exit := false

func reset_run() -> void:
	settled = false
	manual_exit = false

func begin(manual: bool) -> bool:
	if settled:
		return false
	settled = true
	manual_exit = manual
	return true

func decorate_summary(summary: Dictionary, state) -> Dictionary:
	var result := summary.duplicate(true)
	result["end_reason"] = "manual_exit" if manual_exit else String(state.game_over_reason)
	result["run_completed"] = not manual_exit
	result["manually_ended"] = manual_exit
	if manual_exit:
		result["reason"] = "ランを手動終了"
	return result
