extends RefCounted
class_name EffectiveSettingsResolver

const BATTERY_OVERRIDES := {
	"effect_density": "minimal",
	"render_quality": "low",
	"damage_numbers": false,
	"background_particles": false,
	"screen_shake": false,
	"touch_haptics": false,
	"ui_animation_amount": "low",
	"notification_log_amount": "low",
	"equipment_hud_mode": "simple",
	"boss_alert_intensity": "normal",
	"minimap_update_hz": 3,
	"minimap_animation_enabled": false,
	"decorative_effects": false,
	"projectile_trails": false,
	"secondary_glow": false,
	"target_render_fps": 30,
	"arena_redraw_hz": 30,
	"noncritical_hud_update_hz": 4,
	"combat_hud_update_hz": 10,
}

func resolve(stored_settings: Dictionary) -> Dictionary:
	var result := stored_settings.duplicate(true)
	if not battery_saver_enabled(stored_settings):
		result["_battery_saver_effective"] = false
		return result
	for key in BATTERY_OVERRIDES:
		result[key] = BATTERY_OVERRIDES[key]
	result["_battery_saver_effective"] = true
	return result

func battery_saver_enabled(settings: Dictionary) -> bool:
	return bool(settings.get("battery_saver", settings.get("low_power_mode", false)))

func is_overridden(key: String, stored_settings: Dictionary) -> bool:
	return battery_saver_enabled(stored_settings) and BATTERY_OVERRIDES.has(key)

func effective_value_text(key: String, stored_settings: Dictionary, labels: Dictionary = {}) -> String:
	if not is_overridden(key, stored_settings):
		return ""
	var value = BATTERY_OVERRIDES[key]
	var label_table: Dictionary = labels.get(key, {})
	return String(label_table.get(str(value), str(value)))

func battery_description() -> String:
	return "30fps描画・極限軽量エフェクト・背景演出OFF・振動OFF・低頻度UI更新で、発熱と消費電力を最小化します。敵数・攻撃・報酬は変わりません。"
