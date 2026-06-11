extends RefCounted

const FieldHelpSystemScript = preload("res://scripts/systems/FieldHelpSystem.gd")

func run(t) -> void:
	var state = SurvivorState.new()
	state.start_new_run(4201, "field-help")
	state.field_drops.clear()
	state.field_gimmicks.clear()
	state.player_position = Vector2(1000, 1000)
	state.field_drops.append({
		"id": "heal_ore",
		"name_ja": "回復鉱石",
		"position": Vector2(1140, 1000),
		"unlock_seconds": 0.0,
		"collected": false
	})
	var system = FieldHelpSystemScript.new()
	var events: Array = []
	var nearby = system.process(state, events)
	t.assert_eq(String(nearby.get("id", "")), "heal_ore", "nearest field target should be detected")
	t.assert_true(bool(state.field_help_discovered.get("drop:heal_ore", false)), "approaching a target should discover it")
	t.assert_true(_has_event(events, "field_discovery"), "first discovery should emit an event")
	var scanned = system.scan(state)
	t.assert_eq(String(scanned.get("effect_ja", "")), "拾うと最大HPの18%を回復します。", "scan should expose detailed effect")
	t.assert_true(state.field_scan_timer > 0.0, "successful scan should remain visible")

func _has_event(events: Array, type: String) -> bool:
	for event in events:
		if String(event.get("type", "")) == type:
			return true
	return false
