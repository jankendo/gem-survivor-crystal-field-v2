extends RefCounted
class_name IosPerformanceLogSystem

const DEFAULT_PATH := "user://ios_performance_log.csv"
const SAMPLE_INTERVAL := 5.0

var enabled := false
var path := DEFAULT_PATH
var sample_timer := 0.0

func configure(should_enable: bool, custom_path: String = "") -> void:
	enabled = should_enable
	path = custom_path if custom_path != "" else DEFAULT_PATH
	sample_timer = 0.0

func tick(delta: float, state, ui_root: Node) -> void:
	if not enabled or state == null:
		return
	sample_timer += delta
	if sample_timer < SAMPLE_INTERVAL:
		return
	sample_timer = 0.0
	var enemies: Array = state.enemies if state.get("enemies") is Array else []
	var effects: Array = state.effects if state.get("effects") is Array else []
	var projectiles: Array = state.projectiles if state.get("projectiles") is Array else []
	var header := "time,fps,frame_time,enemy_count,effect_count,projectile_count,ui_node_count,memory_estimate"
	var fps := Engine.get_frames_per_second()
	var row := "%.2f,%d,%.4f,%d,%d,%d,%d,%d" % [
		float(state.elapsed_seconds),
		fps,
		1.0 / maxf(float(fps), 1.0),
		enemies.size(),
		effects.size(),
		projectiles.size(),
		_count_nodes(ui_root),
		OS.get_static_memory_usage()
	]
	_append_csv(header, row)

func _count_nodes(node: Node) -> int:
	if node == null:
		return 0
	var count := 1
	for child in node.get_children():
		count += _count_nodes(child)
	return count

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
