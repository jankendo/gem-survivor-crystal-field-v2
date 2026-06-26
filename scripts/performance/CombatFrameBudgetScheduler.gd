extends RefCounted
class_name CombatFrameBudgetScheduler

var max_logic_updates := 600
var max_damage_events := 4096
var logic_updates_used := 0
var damage_events_used := 0

func configure(config: Dictionary) -> void:
	max_logic_updates = int(config.get("max_logic_updates_per_frame", max_logic_updates))
	max_damage_events = int(config.get("max_damage_events_per_frame", max_damage_events))

func begin_frame() -> void:
	logic_updates_used = 0
	damage_events_used = 0

func consume_logic_update(count: int = 1) -> bool:
	if logic_updates_used + count > max_logic_updates:
		return false
	logic_updates_used += count
	return true

func consume_damage_event(count: int = 1) -> bool:
	if damage_events_used + count > max_damage_events:
		return false
	damage_events_used += count
	return true

func snapshot() -> Dictionary:
	return {
		"max_logic_updates": max_logic_updates,
		"logic_updates_used": logic_updates_used,
		"max_damage_events": max_damage_events,
		"damage_events_used": damage_events_used
	}

