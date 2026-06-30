extends RefCounted
const Helper = preload("res://tests/helpers/Phase9TestScenarios.gd")
func run(t) -> void:
	var h = Helper.new()
	h.scan_discovery(t)
	h.scan_extract_regular_pickup(t)
