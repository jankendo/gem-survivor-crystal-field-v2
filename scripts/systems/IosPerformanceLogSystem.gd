extends RefCounted
class_name IosPerformanceLogSystem

const DEFAULT_PATH := "user://ios_performance_log.csv"
const SAMPLE_INTERVAL := 5.0
const FRAME_WINDOW := 1800

var enabled := false
var path := DEFAULT_PATH
var sample_timer := 0.0
var frame_times_ms: Array = []
var long_frame_count := 0
var last_node_count := 0
var created_nodes_per_second := 0.0
var freed_nodes_per_second := 0.0
var long_frame_count_over_50ms := 0

func configure(should_enable: bool, custom_path: String = "") -> void:
	enabled = should_enable
	path = custom_path if custom_path != "" else DEFAULT_PATH
	sample_timer = 0.0
	frame_times_ms.clear()
	long_frame_count = 0
	last_node_count = 0
	created_nodes_per_second = 0.0
	freed_nodes_per_second = 0.0
	long_frame_count_over_50ms = 0

func tick(delta: float, state, ui_root: Node) -> void:
	if not enabled or state == null:
		return
	var frame_ms := delta * 1000.0
	frame_times_ms.append(frame_ms)
	if frame_times_ms.size() > FRAME_WINDOW:
		frame_times_ms.pop_front()
	if frame_ms > 33.0:
		long_frame_count += 1
	if frame_ms > 50.0:
		long_frame_count_over_50ms += 1
	sample_timer += delta
	if sample_timer < SAMPLE_INTERVAL:
		return
	sample_timer = 0.0
	var enemies: Array = state.enemies if state.get("enemies") is Array else []
	var effects: Array = state.hit_flashes + state.effect_lines if state.get("hit_flashes") is Array else []
	var projectiles: Array = state.projectiles if state.get("projectiles") is Array else []
	var gems: Array = state.gems if state.get("gems") is Array else []
	var ui_nodes := _count_nodes(ui_root)
	var control_nodes := _count_controls(ui_root)
	created_nodes_per_second = maxf(0.0, float(ui_nodes - last_node_count) / SAMPLE_INTERVAL)
	freed_nodes_per_second = maxf(0.0, float(last_node_count - ui_nodes) / SAMPLE_INTERVAL)
	last_node_count = ui_nodes
	var sorted := frame_times_ms.duplicate()
	sorted.sort()
	var avg := _average(frame_times_ms)
	var p95 := _percentile(sorted, 0.95)
	var p99 := _percentile(sorted, 0.99)
	var viewport_world := Vector2(1280, 720)
	var map_tile_draw_count := 0
	var minimap_update_count := 0
	if ui_root != null and ui_root.get("arena_view") != null:
		viewport_world = ui_root.arena_view.size / maxf(ui_root.arena_view.camera_zoom, 0.01)
		map_tile_draw_count = int(ui_root.arena_view.map_tile_draw_count)
		minimap_update_count = int(ui_root.arena_view.minimap_update_count)
	var active_enemy_count := 0
	for enemy in enemies:
		if Rect2(state.camera_position - viewport_world * 0.5, viewport_world).grow(96.0).has_point(enemy.position):
			active_enemy_count += 1
	var notification_count := 0
	var fps := Engine.get_frames_per_second()
	var log_count := 0
	if ui_root != null and ui_root.get("notification_log_system") != null:
		notification_count = ui_root.notification_log_system.entries.size()
		log_count = ui_root.notification_log_system.history.size()
	var pooled_count := _pooled_count(state)
	var memory_bytes := OS.get_static_memory_usage()
	var header := "time,fps,frame_time_ms,frame_time_avg_5s,frame_time_p95_30s,frame_time_p99_30s,stutter_count,long_frame_count_over_33ms,long_frame_count_over_50ms,enemy_count,active_enemy_count,offscreen_enemy_count,projectile_count,effect_count,damage_number_count,gem_count,drop_count,ui_node_count,control_node_count,notification_count,log_entry_count,physics_query_count,pathing_update_count,map_tile_draw_count,minimap_update_count,created_nodes_per_second,freed_nodes_per_second,pooled_nodes_count,memory_estimate,memory_estimate_mb,gc_or_cleanup_event,current_scene,current_screen,ios_profile"
	var row := "%.2f,%d,%.3f,%.3f,%.3f,%.3f,%d,%d,%d,%d,%d,%d,%d,%d,%d,%d,%d,%d,%d,%d,%d,%d,%d,%d,%d,%.3f,%.3f,%d,%d,%.3f,%s,%s,%s,%s" % [
		float(state.elapsed_seconds),
		fps,
		frame_ms,
		avg,
		p95,
		p99,
		long_frame_count,
		long_frame_count,
		long_frame_count_over_50ms,
		enemies.size(),
		active_enemy_count,
		enemies.size() - active_enemy_count,
		projectiles.size(),
		effects.size(),
		state.floating_texts.size(),
		gems.size(),
		state.field_drops.size(),
		ui_nodes,
		control_nodes,
		notification_count,
		log_count,
		int(state.ios_physics_query_count),
		int(state.ios_pathing_update_count),
		map_tile_draw_count,
		minimap_update_count,
		created_nodes_per_second,
		freed_nodes_per_second,
		pooled_count,
		memory_bytes,
		float(memory_bytes) / 1048576.0,
		"cleanup" if freed_nodes_per_second > 0.0 else "",
		_csv_text(_current_scene(ui_root)),
		"game",
		_csv_text(String(state.performance_profile_id))
	]
	_append_csv(header, row)

func _average(values: Array) -> float:
	if values.is_empty():
		return 0.0
	var total := 0.0
	for value in values:
		total += float(value)
	return total / float(values.size())

func _percentile(sorted_values: Array, ratio: float) -> float:
	if sorted_values.is_empty():
		return 0.0
	return float(sorted_values[clampi(int(ceil(float(sorted_values.size()) * ratio)) - 1, 0, sorted_values.size() - 1)])

func _count_nodes(node: Node) -> int:
	if node == null:
		return 0
	var count := 1
	for child in node.get_children():
		count += _count_nodes(child)
	return count

func _count_controls(node: Node) -> int:
	if node == null:
		return 0
	var count := 1 if node is Control else 0
	for child in node.get_children():
		count += _count_controls(child)
	return count

func _pooled_count(state) -> int:
	if state == null or state.get("pool_manager") == null:
		return 0
	var total := 0
	for row in state.pool_manager.health_report().values():
		total += int(row.get("pooled", 0))
	return total

func _current_scene(ui_root: Node) -> String:
	if ui_root == null or not ui_root.is_inside_tree() or ui_root.get_tree().current_scene == null:
		return ""
	return ui_root.get_tree().current_scene.scene_file_path

func _csv_text(value: String) -> String:
	return "\"%s\"" % value.replace("\"", "\"\"")

func _append_csv(header: String, row: String) -> void:
	var exists := FileAccess.file_exists(path)
	var file := FileAccess.open(path, FileAccess.READ_WRITE if exists else FileAccess.WRITE)
	if file == null:
		return
	if exists:
		file.seek_end()
	else:
		file.store_line(header)
	file.store_line(row)
