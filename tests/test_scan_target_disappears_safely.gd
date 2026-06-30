extends RefCounted
const Helper = preload("res://tests/helpers/Phase9TestScenarios.gd")
func run(t) -> void:
	Helper.new().scan_extract_cancel_safe(t)
