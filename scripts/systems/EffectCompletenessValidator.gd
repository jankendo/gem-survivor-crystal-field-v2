extends RefCounted
class_name EffectCompletenessValidator

const SUPPORTED_EFFECT_TYPES := [
	"crystal_explosion", "delayed_explosion", "deploy_area", "deploy_defense",
	"deploy_gate", "deploy_laser", "deploy_poison", "explore_projectile",
	"falling_explosion", "gem_orbit", "gem_shot", "gravity_area",
	"laser_beam", "lightning_chain", "melee_arc", "melee_knockback_ring",
	"orbit_area", "poison_area", "ranged_bullet", "reflect_bullet", "summon_bit"
]

func validate(weapons: Dictionary, evolutions: Dictionary, effects: Dictionary) -> Array:
	var errors: Array = []
	for raw_id in weapons.keys():
		var id = String(raw_id)
		_validate_row("weapon", id, weapons[id], effects, errors)
	for raw_id in evolutions.keys():
		var id = String(raw_id)
		_validate_row("evolution", id, evolutions[id], effects, errors)
	for raw_id in effects.keys():
		var id = String(raw_id)
		var effect_type = String(effects[id].get("effect_type", ""))
		if not SUPPORTED_EFFECT_TYPES.has(effect_type):
			errors.append("unsupported effect_type: %s=%s" % [id, effect_type])
		if not effects[id].has("normal") or not effects[id].has("evolved"):
			errors.append("missing visual variants: %s" % id)
	return errors

func _validate_row(kind: String, id: String, row: Dictionary, effects: Dictionary, errors: Array) -> void:
	var effect_id = String(row.get("effect_id", ""))
	if effect_id == "":
		errors.append("%s missing effect_id: %s" % [kind, id])
	elif not effects.has(effect_id):
		errors.append("%s unknown effect_id: %s=%s" % [kind, id, effect_id])
