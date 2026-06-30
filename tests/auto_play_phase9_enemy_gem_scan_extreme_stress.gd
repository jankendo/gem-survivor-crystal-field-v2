extends RefCounted
const Helper = preload("res://tests/helpers/Phase9TestScenarios.gd")
const Phase9PerformanceHarness = preload("res://tests/Phase9PerformanceHarness.gd")
func run(t) -> void:
	var h = Helper.new()
	h.enemy_snapshot_and_batch(t)
	h.gem_collection_batch(t)
	h.scan_discovery(t)
	var summary: Dictionary = Phase9PerformanceHarness.new().run()
	t.assert_true(bool(summary.get("ok", false)), "Phase 9 performance harness should keep parity and scan ok")
	t.assert_eq(int(summary.get("over_100ms", -1)), 0, "Phase 9 fixture should have no 100ms CPU-frame samples")
