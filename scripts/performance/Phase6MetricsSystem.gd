extends RefCounted
class_name Phase6MetricsSystem

var enabled := false
var counters: Dictionary = {}
var gauges: Dictionary = {}

func configure(should_enable: bool) -> void:
	enabled = should_enable
	counters.clear()
	gauges.clear()

func add(name: String, amount: int = 1) -> void:
	if not enabled:
		return
	counters[name] = int(counters.get(name, 0)) + amount

func max_value(name: String, value: int) -> void:
	if not enabled:
		return
	gauges[name] = maxi(int(gauges.get(name, 0)), value)

func set_value(name: String, value) -> void:
	if not enabled:
		return
	gauges[name] = value

func snapshot() -> Dictionary:
	return {
		"enabled": enabled,
		"counters": counters.duplicate(true),
		"gauges": gauges.duplicate(true)
	}

