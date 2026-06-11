extends RefCounted
class_name RuneContractSystem

func make_offer(state, count: int = 3) -> Array:
	if state.rune_contracts.size() >= 5:
		return []
	var choices: Array = []
	for id in state.rune_contract_defs.keys():
		if state.rune_contracts.has(String(id)):
			continue
		choices.append(String(id))
	choices.shuffle()
	var options: Array = []
	for id in choices:
		if options.size() >= count - 1:
			break
		var data: Dictionary = state.rune_contract_defs.get(id, {})
		options.append({
			"uid": "contract:%s" % id,
			"kind": "contract",
			"id": id,
			"name_ja": String(data.get("name_ja", id)),
			"description_ja": String(data.get("description_ja", "")),
			"type_label": "契約",
			"type_color": "contract"
		})
	options.append({
		"uid": "contract_skip:skip",
		"kind": "contract_skip",
		"id": "skip",
		"name_ja": "契約しない",
		"description_ja": "今回は安全を取る。契約枠は消費しない。",
		"type_label": "任意",
		"type_color": "contract"
	})
	return options

func offer_after_boss(state, events: Array) -> bool:
	var options = make_offer(state, 3)
	if options.is_empty():
		return false
	state.rune_contract_pending = true
	state.level_up_pending = true
	state.level_up_options = options
	state.selected_reward_index = 0
	events.append({"type": "rune_contract_offer", "options": options})
	return true

func apply_contract(state, id: String, events: Array) -> bool:
	if id == "skip":
		state.rune_contract_pending = false
		state.level_up_pending = false
		state.level_up_options = []
		state.message = "契約を見送りました"
		events.append({"type": "rune_contract_skip"})
		return true
	if state.rune_contracts.size() >= 5 or state.rune_contracts.has(id):
		return false
	var data: Dictionary = state.rune_contract_defs.get(id, {})
	if data.is_empty():
		return false
	state.rune_contracts.append(id)
	state.rune_contract_pending = false
	state.level_up_pending = false
	state.level_up_options = []
	state.message = "%sを結んだ" % String(data.get("name_ja", id))
	if data.has("max_hp_mult"):
		state.max_hp = maxi(1, int(round(float(state.max_hp) * float(data.get("max_hp_mult", 1.0)))))
		state.hp = mini(state.hp, state.max_hp)
		if state.hp <= 0:
			state.hp = 1
	if id == "curse_pact":
		state.danger_zones.append({"id": "contract_curse_%d" % state.rune_contracts.size(), "position": state.random_walkable_position(state.player_position, 240.0, 520.0), "radius": 480.0, "biome": state.current_biome_id})
	events.append({"type": "rune_contract_apply", "id": id, "name": data.get("name_ja", id), "count": state.rune_contracts.size()})
	return true
