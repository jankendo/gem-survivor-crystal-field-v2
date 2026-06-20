extends RefCounted
class_name ResonanceMagnetSystem

const GlobalGemCollectionSystemScript = preload("res://scripts/systems/GlobalGemCollectionSystem.gd")

var global_collection = GlobalGemCollectionSystemScript.new()

func process(state, delta: float, events: Array) -> void:
	var level = int(state.passives.get("resonance_magnet_core", 0))
	if level <= 0:
		state.resonance_magnet_timer = 0.0
		return
	var interval = state.resonance_magnet_interval()
	if state.resonance_magnet_timer <= 0.0:
		state.resonance_magnet_timer = interval
	state.resonance_magnet_timer = maxf(0.0, state.resonance_magnet_timer - delta)
	if state.resonance_magnet_timer > 0.0:
		return
	var radius = state.resonance_magnet_radius()
	var result = global_collection.collect_nearby(state, state.player_position, radius, events, "resonance_magnet_core")
	state.resonance_magnet_collections += 1 if int(result.get("count", 0)) > 0 else 0
	state.resonance_magnet_last_count = int(result.get("count", 0))
	state.resonance_magnet_pulse_timer = 0.55
	state.resonance_magnet_timer = interval
	if int(result.get("count", 0)) > 0:
		state.add_floating_text("共鳴磁核 %d" % int(result.get("count", 0)), state.player_position + Vector2(0, -66), Color(0.58, 1.0, 0.92))
		events.append({"type": "resonance_magnet_collect", "count": int(result.get("count", 0)), "exp": int(result.get("exp", 0)), "radius": radius})
