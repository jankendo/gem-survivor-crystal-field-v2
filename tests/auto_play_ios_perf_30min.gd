extends SceneTree

const Harness = preload("res://tests/IosPerfAutoplayHarness.gd")

func _initialize() -> void:
	var failures: Array = await Harness.new().run(self, 30, "res://test-output/ios_performance_log_30min.csv")
	if failures.is_empty():
		print("AutoPlay iOS Performance OK: 30 minute synthetic capture.")
		quit(0)
		return
	for failure in failures:
		push_error(failure)
	quit(1)
