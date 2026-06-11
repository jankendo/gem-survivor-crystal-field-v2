extends RefCounted
class_name EquipmentHudSystem

var show_weapons := true
var show_passives := true

func configure(settings: Dictionary) -> void:
	show_weapons = bool(settings.get("weapon_hud_enabled", true))
	show_passives = bool(settings.get("passive_hud_enabled", true))

func weapon_text(state) -> String:
	if not show_weapons:
		return ""
	var lines: Array = ["武器 %d/%d" % [state.weapons.size(), state.max_owned_weapons()]]
	for raw_id in state.weapons.keys():
		var id = String(raw_id)
		var evolved = state.evolved_weapons.has(id) or (id == "magic_bolt" and state.evolved_magic_bolt)
		lines.append("%s Lv%d%s" % [state.weapon_name(id), int(state.weapons[id]), " [進化]" if evolved else ""])
	return "\n".join(lines)

func passive_text(state) -> String:
	if not show_passives:
		return ""
	var lines: Array = ["パッシブ %d/%d" % [state.passives.size(), state.max_owned_passives()]]
	for raw_id in state.passives.keys():
		var id = String(raw_id)
		lines.append("%s Lv%d" % [state.passive_name(id), int(state.passives[id])])
	return "\n".join(lines)
