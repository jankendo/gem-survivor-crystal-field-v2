extends RefCounted
class_name WeaponRenderStyleCache

const ROOT_KEYS := [
	"effect_type", "primary_color", "secondary_color", "hit_effect",
	"evolved_effect_type", "screen_priority", "opacity", "lifetime",
	"max_effect_count", "melee_arc", "lightning_line", "shock_icon"
]

var cache: Dictionary = {}
var weapon_defs: Dictionary = {}
var effect_defs: Dictionary = {}
var quality_profile := "standard"
var renderer := "gl_compatibility"
var hits := 0
var misses := 0

func configure(
		new_weapon_defs: Dictionary,
		new_effect_defs: Dictionary,
		new_quality_profile: String = "standard",
		new_renderer: String = "gl_compatibility"
	) -> void:
	var definitions_changed := not is_same(weapon_defs, new_weapon_defs) or not is_same(effect_defs, new_effect_defs)
	if definitions_changed or quality_profile != new_quality_profile or renderer != new_renderer:
		cache.clear()
	weapon_defs = new_weapon_defs
	effect_defs = new_effect_defs
	quality_profile = new_quality_profile
	renderer = new_renderer

func resolve(weapon_id: String, evolved: bool) -> Dictionary:
	var key := "%s|%d|%s|%s" % [weapon_id, int(evolved), quality_profile, renderer]
	if cache.has(key):
		hits += 1
		return cache[key]
	misses += 1
	var definition: Dictionary = weapon_defs.get(weapon_id, {})
	var effect_id := String(definition.get("effect_id", weapon_id))
	var data: Dictionary = effect_defs.get(effect_id, {})
	if data.is_empty():
		cache[key] = {}
		return cache[key]
	var variant: Dictionary = data.get("evolved", {}) if evolved else data.get("normal", {})
	var resolved: Dictionary = {}
	for entry_key in variant:
		resolved[entry_key] = variant[entry_key]
	for entry_key in ROOT_KEYS:
		if data.has(entry_key) and not resolved.has(entry_key):
			resolved[entry_key] = data[entry_key]
	resolved["weapon_id"] = weapon_id
	resolved["evolved"] = evolved
	resolved["quality_profile"] = quality_profile
	resolved["renderer"] = renderer
	resolved["arc_segments"] = _base_arc_segments(resolved)
	resolved["glow_size"] = _glow_size(resolved)
	resolved["line_width"] = 4.0 if bool(resolved.get("thick_line", false)) else 2.0
	resolved["priority"] = _priority(resolved)
	resolved.make_read_only()
	cache[key] = resolved
	return cache[key]

func invalidate() -> void:
	cache.clear()

func stats() -> Dictionary:
	return {"hits": hits, "misses": misses, "size": cache.size()}

func _base_arc_segments(style: Dictionary) -> int:
	var base := 24
	if quality_profile.contains("low"):
		base = 16
	elif quality_profile.contains("high"):
		base = 32
	if int(style.get("screen_priority", 0)) >= 5:
		base = maxi(base, 32)
	return base

func _glow_size(style: Dictionary) -> float:
	if quality_profile.contains("low"):
		return 0.65
	if quality_profile.contains("high"):
		return 1.15
	return 0.85

func _priority(style: Dictionary) -> int:
	var screen_priority := int(style.get("screen_priority", 3))
	if screen_priority >= 5:
		return 1
	if screen_priority <= 2:
		return 3
	return 2

