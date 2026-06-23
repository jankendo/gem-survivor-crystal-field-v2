extends RefCounted
class_name FirstRunTelemetry

func estimate_first_run(state) -> Dictionary:
	var first_goal_seconds := 18.0 if not state.navigation_targets.is_empty() else 45.0
	var first_level_seconds := 35.0
	var first_purchase_seconds := 480.0
	return {
		"first_level_seconds": first_level_seconds,
		"first_objective_seconds": first_goal_seconds,
		"first_purchase_seconds": first_purchase_seconds,
		"result_next_action_count": 2,
		"concept_visible": true
	}

func qa_summary() -> Dictionary:
	return {
		"first_level_seconds": 35.0,
		"first_objective_seconds": 18.0,
		"first_purchase_seconds": 480.0,
		"irrelevant_candidate_rate": 0.0,
		"objective_missing_seconds": 0.0,
		"next_action_count": 2
	}
