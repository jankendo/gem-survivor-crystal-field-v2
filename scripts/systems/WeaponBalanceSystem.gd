extends RefCounted
class_name WeaponBalanceSystem

func damage_multiplier_for_category(category: String) -> float:
	match category:
		"ranged":
			return 0.92
		"melee":
			return 1.20
		"lightning":
			return 0.92
		"poison":
			return 0.84
		"explosion":
			return 1.08
		"deploy":
			return 0.92
		"gem":
			return 0.80
		"knockback":
			return 0.84
		"crystal":
			return 0.94
	return 1.0

func range_for_weapon(data: Dictionary) -> float:
	return float(data.get("range", 0.0))

func is_ranged_long_low_damage(data: Dictionary) -> bool:
	return String(data.get("category", "")) == "ranged" and range_for_weapon(data) >= 780.0 and float(data.get("base_damage_score", 1.0)) <= 0.90

func is_melee_short_high_damage(data: Dictionary) -> bool:
	return String(data.get("category", "")) == "melee" and range_for_weapon(data) <= 280.0 and float(data.get("base_damage_score", 1.0)) >= 1.20

func is_explosion_slow_wide(data: Dictionary) -> bool:
	return String(data.get("category", "")) == "explosion" and float(data.get("base_cooldown_score", 0.0)) >= 2.0 and float(data.get("base_damage_score", 1.0)) >= 1.10
