extends RefCounted
class_name FieldEquipmentRewardSystem

var placement = preload("res://scripts/systems/FieldEquipmentPlacementSystem.gd").new()

func generate_for_map(state, map_data: Dictionary, rng) -> Array:
	return placement.generate(state, map_data, rng)

func exploration_reward_score(state) -> int:
	var chain_bonus = int(state.exploration_chain_max) * 80
	var equipment_bonus = int(state.field_equipment_collected) * 450
	var room_bonus = int(state.reward_room_pickups) * 240
	return chain_bonus + equipment_bonus + room_bonus

func camping_score_estimate(minutes: float) -> int:
	return int(minutes * 120.0)
