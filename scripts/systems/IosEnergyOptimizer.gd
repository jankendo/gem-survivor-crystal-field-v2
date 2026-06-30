extends RefCounted
class_name IosEnergyOptimizer

const IosRenderBudgetSystemScript = preload("res://scripts/systems/IosRenderBudgetSystem.gd")
const BatterySaverSettingsSystemScript = preload("res://scripts/systems/BatterySaverSettingsSystem.gd")

var budget_system = IosRenderBudgetSystemScript.new()
var settings_system = BatterySaverSettingsSystemScript.new()
var battery_profile := "standard"
var budget: Dictionary = {}
var timers: Dictionary = {}
var signatures: Dictionary = {}
var ui_rebuild_count := 0
var label_update_count := 0
var minimap_redraw_count := 0
var notification_spawn_count := 0
var haptic_count := 0
var audio_event_count := 0
var save_write_count := 0
var log_write_count := 0

func configure(settings: Dictionary) -> void:
	battery_profile = settings_system.profile_id(settings)
	budget = budget_system.profile(battery_profile)
	timers.clear()
	signatures.clear()
	ui_rebuild_count = 0
	label_update_count = 0
	minimap_redraw_count = 0
	notification_spawn_count = 0
	haptic_count = 0
	audio_event_count = 0
	save_write_count = 0
	log_write_count = 0

func tick(delta: float) -> void:
	for key in timers.keys():
		timers[key] = float(timers[key]) + delta

func should_update(key: String, signature: String, interval_key: String, fallback: float) -> bool:
	var changed := String(signatures.get(key, "")) != signature
	var interval := float(budget.get(interval_key, fallback))
	if not changed and float(timers.get(key, INF)) < interval:
		return false
	signatures[key] = signature
	timers[key] = 0.0
	return true

func set_label(label: Label, value: String) -> bool:
	if label == null or label.text == value:
		return false
	label.text = value
	label_update_count += 1
	return true

func mark_ui_rebuild(count: int = 1) -> void:
	ui_rebuild_count += maxi(0, count)

func mark_minimap_redraw() -> void:
	minimap_redraw_count += 1

func mark_notification() -> void:
	notification_spawn_count += 1

func mark_haptic() -> void:
	haptic_count = 0

func mark_audio() -> void:
	audio_event_count += 1

func mark_save_write() -> void:
	save_write_count += 1

func mark_log_write() -> void:
	log_write_count += 1

func energy_score(state, ui_root: Node) -> float:
	var elapsed := maxf(1.0, float(state.elapsed_seconds))
	var enemy_cost := float(state.enemies.size()) * 0.08
	var projectile_cost := float(state.projectiles.size() + state.enemy_projectiles.size()) * 0.05
	var effect_cost := float(state.hit_flashes.size() + state.effect_lines.size() + state.floating_texts.size()) * 0.06
	var ui_cost := float(label_update_count + ui_rebuild_count * 4) / elapsed * 0.35
	var path_cost := float(state.ios_pathing_update_count) / elapsed * 0.12
	var node_cost := 0.0
	if ui_root != null:
		node_cost = float(ui_root.get_child_count()) * 0.01
	return enemy_cost + projectile_cost + effect_cost + ui_cost + path_cost + node_cost

func estimated_power_risk(score: float) -> String:
	if score >= 80.0:
		return "high"
	if score >= 40.0:
		return "medium"
	return "low"
