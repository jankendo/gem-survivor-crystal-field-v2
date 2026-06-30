extends RefCounted
class_name SelectionActionSystem

const SelectionContextSystemScript = preload("res://scripts/systems/SelectionContextSystem.gd")

const DEFAULT_DEFS := {
	"skip_base_count": 1,
	"reroll_base_count": 1,
	"seal_base_count": 0,
	"max_skip_count": 6,
	"max_reroll_count": 6,
	"max_seal_count": 5,
	"skip_reward": {"score": 120, "heal": 4, "crystal_currency": 2},
	"shop_skip_sink_id": "selection_skip_charm",
	"shop_reroll_sink_id": "levelup_reroll_capacity",
	"shop_seal_sink_id": "selection_seal_art",
	"shop_skip_per_level": 1,
	"shop_reroll_per_level": 1,
	"shop_seal_per_level": 1,
	"achievement_skip_rewards": [],
	"achievement_reroll_rewards": [],
	"achievement_seal_rewards": []
}

var defs: Dictionary = {}

func _init() -> void:
	defs = _json_dict("res://data/selection_actions.json", DEFAULT_DEFS)

func begin_run(state, save_data: Dictionary = {}) -> void:
	state.selection_skip_max = max_skip_count(save_data)
	state.selection_skip_remaining = state.selection_skip_max
	state.selection_reroll_max = max_reroll_count(save_data)
	state.selection_reroll_remaining = state.selection_reroll_max
	state.selection_rerolls_used = 0
	state.selection_seal_max = max_seal_count(save_data)
	state.selection_seal_remaining = state.selection_seal_max
	state.run_sealed_option_uids = []
	state.run_sealed_history = []

func max_skip_count(save_data: Dictionary) -> int:
	var levels: Dictionary = save_data.get("currency_sink_levels", {})
	var count = int(defs.get("skip_base_count", 1))
	count += int(levels.get(String(defs.get("shop_skip_sink_id", "")), 0)) * int(defs.get("shop_skip_per_level", 1))
	count += _achievement_count(save_data, defs.get("achievement_skip_rewards", []))
	return clampi(count, 0, int(defs.get("max_skip_count", 6)))

func max_seal_count(save_data: Dictionary) -> int:
	var levels: Dictionary = save_data.get("currency_sink_levels", {})
	var count = int(defs.get("seal_base_count", 0))
	count += int(levels.get(String(defs.get("shop_seal_sink_id", "")), 0)) * int(defs.get("shop_seal_per_level", 1))
	count += _achievement_count(save_data, defs.get("achievement_seal_rewards", []))
	return clampi(count, 0, int(defs.get("max_seal_count", 5)))

func max_reroll_count(save_data: Dictionary) -> int:
	var levels: Dictionary = save_data.get("currency_sink_levels", {})
	var count = int(defs.get("reroll_base_count", 1))
	count += int(levels.get(String(defs.get("shop_reroll_sink_id", "")), 0)) * int(defs.get("shop_reroll_per_level", 1))
	count += _achievement_count(save_data, defs.get("achievement_reroll_rewards", []))
	return clampi(count, 0, int(defs.get("max_reroll_count", 6)))

func can_skip(state) -> bool:
	return SelectionContextSystemScript.is_level_up(state) and int(state.selection_skip_remaining) > 0

func can_seal(state) -> bool:
	return SelectionContextSystemScript.is_level_up(state) and int(state.selection_seal_remaining) > 0

func can_reroll(state) -> bool:
	return SelectionContextSystemScript.is_level_up(state) and int(state.selection_reroll_remaining) > 0

func consume_reroll(state, events: Array) -> bool:
	if not can_reroll(state):
		return false
	state.selection_reroll_remaining -= 1
	state.selection_rerolls_used += 1
	events.append({"type": "selection_reroll", "remaining": state.selection_reroll_remaining, "used": state.selection_rerolls_used})
	return true

func skip_current(state, events: Array) -> bool:
	if not can_skip(state):
		return false
	state.selection_skip_remaining -= 1
	var reward: Dictionary = defs.get("skip_reward", {})
	var score_gain = int(reward.get("score", 0))
	if score_gain > 0:
		state.add_score(score_gain, state.player_position)
	var heal = int(reward.get("heal", 0))
	if heal > 0:
		state.hp = mini(state.max_hp, state.hp + heal)
	state.selection_skip_rewards += 1
	state.level_up_pending = false
	state.rune_contract_pending = false
	state.level_up_options = []
	state.selection_context = SelectionContextSystemScript.NONE
	state.message = "選択をスキップ：HP+%d / スコア+%d" % [heal, score_gain]
	events.append({"type": "selection_skip", "score": score_gain, "heal": heal, "currency": int(reward.get("crystal_currency", 0))})
	return true

func seal_option(state, option_uid: String, events: Array) -> bool:
	if not can_seal(state) or option_uid == "":
		return false
	var option = _find_option(state.level_up_options, option_uid)
	if option.is_empty():
		return false
	if not String(option.get("kind", "")).begins_with("contract_skip"):
		if not state.run_sealed_option_uids.has(option_uid):
			state.run_sealed_option_uids.append(option_uid)
	state.selection_seal_remaining -= 1
	state.run_sealed_history.append({
		"uid": option_uid,
		"kind": String(option.get("kind", "")),
		"id": String(option.get("id", "")),
		"name_ja": String(option.get("name_ja", option_uid))
	})
	state.selection_seals_used += 1
	events.append({"type": "selection_seal", "uid": option_uid, "name": option.get("name_ja", option_uid), "remaining": state.selection_seal_remaining})
	return true

func is_option_sealed(state, uid: String) -> bool:
	return uid != "" and state.run_sealed_option_uids.has(uid)

func option_uid(kind: String, id: String) -> String:
	return "%s:%s" % [kind, id]

func controls_for(state, controls: Dictionary = {}) -> Dictionary:
	var result := controls.duplicate(true)
	var context: String = SelectionContextSystemScript.current_context(state)
	var level_up_actions: bool = SelectionContextSystemScript.can_use_levelup_actions(context)
	result["context"] = context
	result["context_label"] = SelectionContextSystemScript.label_for(context)
	result["level_up_actions"] = level_up_actions
	result["skip_remaining"] = int(state.selection_skip_remaining) if level_up_actions else 0
	result["skip_max"] = int(state.selection_skip_max) if level_up_actions else 0
	result["rerolls"] = int(state.selection_reroll_remaining) if level_up_actions else 0
	result["reroll_remaining"] = int(state.selection_reroll_remaining) if level_up_actions else 0
	result["reroll_max"] = int(state.selection_reroll_max) if level_up_actions else 0
	result["seal_remaining"] = int(state.selection_seal_remaining) if level_up_actions else 0
	result["seal_max"] = int(state.selection_seal_max) if level_up_actions else 0
	result["can_skip"] = level_up_actions and (bool(result.get("can_skip", false)) or can_skip(state))
	result["can_reroll"] = level_up_actions and can_reroll(state)
	result["can_seal"] = level_up_actions and can_seal(state)
	var reward: Dictionary = defs.get("skip_reward", {})
	result["skip_reward_text"] = "HP+%d / スコア+%d" % [int(reward.get("heal", 0)), int(reward.get("score", 0))]
	return result

func _achievement_count(save_data: Dictionary, rewards) -> int:
	var total := 0
	var stats: Dictionary = save_data.get("stats", {})
	for entry in rewards:
		if not entry is Dictionary:
			continue
		if float(stats.get(String(entry.get("stat", "")), 0.0)) >= float(entry.get("value", 0.0)):
			total += int(entry.get("count", 0))
	return total

func _find_option(options: Array, uid: String) -> Dictionary:
	for option in options:
		if String(option.get("uid", "")) == uid:
			return option
	return {}

func _json_dict(path: String, fallback: Dictionary) -> Dictionary:
	if not FileAccess.file_exists(path):
		return fallback.duplicate(true)
	var file = FileAccess.open(path, FileAccess.READ)
	if file == null:
		return fallback.duplicate(true)
	var parsed = JSON.parse_string(file.get_as_text())
	return parsed if parsed is Dictionary else fallback.duplicate(true)
