extends RefCounted
class_name ItemPlacementTelemetry

var generated_count := 0
var candidate_valid_count := 0
var reroll_count := 0
var repaired_count := 0
var skipped_count := 0
var invalid_after_repair_count := 0
var by_type: Dictionary = {}
var repair_reasons: Dictionary = {}

func reset() -> void:
	generated_count = 0
	candidate_valid_count = 0
	reroll_count = 0
	repaired_count = 0
	skipped_count = 0
	invalid_after_repair_count = 0
	by_type = {}
	repair_reasons = {}

func record(result: Dictionary) -> void:
	var pickup_type := String(result.get("pickup_type", "unknown"))
	var row: Dictionary = by_type.get(pickup_type, {
		"generated": 0,
		"candidate_valid": 0,
		"rerolls": 0,
		"repaired": 0,
		"skipped": 0,
		"invalid_after_repair": 0
	})
	if bool(result.get("ok", false)):
		generated_count += 1
		row["generated"] = int(row.get("generated", 0)) + 1
	else:
		skipped_count += 1
		row["skipped"] = int(row.get("skipped", 0)) + 1
	if bool(result.get("candidate_valid", false)):
		candidate_valid_count += 1
		row["candidate_valid"] = int(row.get("candidate_valid", 0)) + 1
	if bool(result.get("repaired", false)):
		repaired_count += 1
		row["repaired"] = int(row.get("repaired", 0)) + 1
	var rerolls := int(result.get("rerolls", 0))
	reroll_count += rerolls
	row["rerolls"] = int(row.get("rerolls", 0)) + rerolls
	if bool(result.get("invalid_after_repair", false)):
		invalid_after_repair_count += 1
		row["invalid_after_repair"] = int(row.get("invalid_after_repair", 0)) + 1
	var reason := String(result.get("reason", ""))
	if reason != "":
		repair_reasons[reason] = int(repair_reasons.get(reason, 0)) + 1
	by_type[pickup_type] = row

func summary() -> Dictionary:
	return {
		"generated_count": generated_count,
		"candidate_valid_count": candidate_valid_count,
		"reroll_count": reroll_count,
		"repaired_count": repaired_count,
		"skipped_count": skipped_count,
		"invalid_after_repair_count": invalid_after_repair_count,
		"by_type": by_type.duplicate(true),
		"repair_reasons": repair_reasons.duplicate(true)
	}
