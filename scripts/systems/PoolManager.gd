extends RefCounted
class_name PoolManager

var pools: Dictionary = {}
var factories: Dictionary = {}
var resetters: Dictionary = {}
var limits: Dictionary = {}
var stats: Dictionary = {}

func register(type_id: String, factory: Callable, resetter: Callable = Callable(), max_pool_size: int = 256) -> void:
	factories[type_id] = factory
	resetters[type_id] = resetter
	limits[type_id] = maxi(1, max_pool_size)
	pools[type_id] = pools.get(type_id, [])
	stats[type_id] = stats.get(type_id, {
		"created": 0, "destroyed": 0, "reused": 0, "active": 0, "peak_active": 0
	})

func prewarm(type_id: String, count: int) -> void:
	if not factories.has(type_id):
		return
	var pool: Array = pools[type_id]
	while pool.size() < mini(count, int(limits[type_id])):
		pool.append(factories[type_id].call())
		stats[type_id]["created"] += 1

func acquire(type_id: String, args: Array = []):
	if not factories.has(type_id):
		return null
	var pool: Array = pools[type_id]
	var reused := not pool.is_empty()
	var value = pool.pop_back() if reused else factories[type_id].call()
	if reused:
		stats[type_id]["reused"] += 1
	else:
		stats[type_id]["created"] += 1
	if resetters[type_id].is_valid():
		resetters[type_id].call(value, args)
	stats[type_id]["active"] += 1
	stats[type_id]["peak_active"] = maxi(int(stats[type_id]["peak_active"]), int(stats[type_id]["active"]))
	return value

func release(type_id: String, value) -> void:
	if value == null or not pools.has(type_id):
		return
	stats[type_id]["active"] = maxi(0, int(stats[type_id]["active"]) - 1)
	var pool: Array = pools[type_id]
	if pool.size() < int(limits[type_id]):
		pool.append(value)
	else:
		stats[type_id]["destroyed"] += 1

func health_report() -> Dictionary:
	var report := {}
	for type_id in stats:
		var row: Dictionary = stats[type_id].duplicate(true)
		row["pooled"] = pools.get(type_id, []).size()
		row["leaked"] = int(row.get("active", 0)) < 0
		report[type_id] = row
	return report

func csv_header() -> String:
	return "type,created,destroyed,reused,active,peak_active,pooled"

func csv_rows() -> Array:
	var rows: Array = []
	for type_id in health_report():
		var row: Dictionary = health_report()[type_id]
		rows.append("%s,%d,%d,%d,%d,%d,%d" % [
			type_id, row.created, row.destroyed, row.reused, row.active, row.peak_active, row.pooled
		])
	return rows
