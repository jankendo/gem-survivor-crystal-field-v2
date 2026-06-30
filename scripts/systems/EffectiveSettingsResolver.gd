extends RefCounted
class_name EffectiveSettingsResolver

const BATTERY_OVERRIDES := {
	"effect_density": "minimal",
	"render_quality": "low",
	"damage_numbers": false,
	"background_particles": false,
	"screen_shake": false,
	"touch_haptics": false,
	"ui_animation_amount": "off",
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
	"enemy_visual_quality": "minimal",
	"enemy_animation_hz": 8,
	"enemy_render_snapshot_hz": 24,
	"offscreen_enemy_animation_hz": 0,
	"normal_enemy_shadow": false,
	"normal_enemy_glow": false,
	"normal_enemy_hp_bar": false,
	"normal_enemy_idle_motion": false,
	"normal_enemy_secondary_motion": false,
	"normal_enemy_hit_squash": false,
	"normal_enemy_rotation_animation": false,
	"normal_enemy_outline_layers": 1,
	"normal_enemy_flash_coalescing": true,
	"enemy_batch_rendering": true,
	"boss_visual_quality": "readable",
	"elite_visual_quality": "readable",
	"attack_telegraph_quality": "readable",
	"gem_render_quality": "minimal",
	"gem_collection_visual_mode": "batch_minimal",
	"max_collection_representatives": 4,
	"gem_collection_animation_hz": 8,
	"gem_orbit_animation": false,
	"gem_collection_trail": false,
	"gem_collection_glow": false,
	"gem_collection_ring_count": 1,
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
	return "30fps描画、極限軽量エフェクト、敵アニメーション最小化、ジェム収集演出の一括表示、背景演出OFF、低頻度UI更新で発熱と消費電力を最小化します。敵数、攻撃、EXP、報酬は変わりません。"
