extends RefCounted
class_name EnemySimulationCore

const EnemyEntityStoreScript = preload("res://scripts/performance/EnemyEntityStore.gd")
const SpatialHashGrid2DScript = preload("res://scripts/performance/SpatialHashGrid2D.gd")
const EnemyFrameSchedulerScript = preload("res://scripts/performance/EnemyFrameScheduler.gd")

var store = EnemyEntityStoreScript.new()
var grid = SpatialHashGrid2DScript.new(160.0)
var scheduler = EnemyFrameSchedulerScript.new()

func spawn(enemy_type: String, position: Vector2, hit_points: int, radius: float, speed: float) -> int:
	return store.allocate(enemy_type, position, hit_points, radius, speed)

func rebuild_spatial_index() -> void:
	grid.clear()
	for id in store.active_ids():
		grid.insert_id(id, store.position_of(id))

func query_near(position: Vector2, radius: float) -> Array:
	rebuild_spatial_index()
	return grid.query_ids_radius(position, radius)

func step_toward(target: Vector2, delta: float, max_updates: int = 600) -> Dictionary:
	scheduler.begin_frame()
	var updated := 0
	for index in scheduler.select_indices(store.active_indices(), max_updates):
		var id := int(store.generations[index]) * EnemyEntityStoreScript.ID_INDEX_SPACE + int(index)
		if not store.is_alive(id):
			continue
		var direction: Vector2 = (target - store.positions[index]).normalized()
		store.positions[index] += direction * float(store.speeds[index]) * delta
		updated += 1
	rebuild_spatial_index()
	return {"updated": updated, "alive": store.alive_count, "capacity": store.positions.size()}
