extends RefCounted
class_name EquipmentHudSystem

var show_weapons := true
var show_passives := true
var display_mode := "simple"
var cache: Dictionary = {}

func configure(settings: Dictionary) -> void:
	show_weapons = bool(settings.get("weapon_hud_enabled", true))
	show_passives = bool(settings.get("passive_hud_enabled", true))
	display_mode = String(settings.get("equipment_hud_mode", "simple"))
	if display_mode == "hidden":
		show_weapons = false
		show_passives = false

func compact_text(state) -> String:
	var signature := _signature(state, "compact")
	if cache.has(signature):
		return cache[signature]
	if display_mode == "hidden":
		return ""
	var weapon_parts: Array = []
	var passive_parts: Array = []
	for raw_id in state.weapons.keys():
		var id := String(raw_id)
		weapon_parts.append("%s%d" % ["◆" if state.evolved_weapons.has(id) else "◇", int(state.weapons[id])])
	for raw_id in state.passives.keys():
		passive_parts.append("○%d" % int(state.passives[raw_id]))
	if display_mode in ["detail", "detailed"]:
		var detailed := "%s\n%s" % [weapon_text(state), passive_text(state)]
		cache[signature] = detailed
		return detailed
	var text := "武器 %s　補助 %s" % [
		" ".join(weapon_parts) if not weapon_parts.is_empty() else "-",
		" ".join(passive_parts) if not passive_parts.is_empty() else "-"
	]
	cache[signature] = text
	return text

func weapon_text(state) -> String:
	if not show_weapons:
		return ""
	var lines: Array = ["武器 %s" % state.equipment_count_label("weapon")]
	for raw_id in state.weapons.keys():
		var id = String(raw_id)
		var evolved = state.evolved_weapons.has(id) or (id == "magic_bolt" and state.evolved_magic_bolt)
		lines.append("%s Lv%d%s" % [state.weapon_name(id), int(state.weapons[id]), " [進化]" if evolved else ""])
	return "\n".join(lines)

func passive_text(state) -> String:
	if not show_passives:
		return ""
	var lines: Array = ["パッシブ %s" % state.equipment_count_label("passive")]
	for raw_id in state.passives.keys():
		var id = String(raw_id)
		lines.append("%s Lv%d" % [state.passive_name(id), int(state.passives[id])])
	return "\n".join(lines)

func _signature(state, prefix: String) -> String:
	return "%s:%s:%s:%s:%d" % [prefix, str(state.weapons), str(state.passives), str(state.evolved_weapons), int(state.field_over_cap_pickups)]
