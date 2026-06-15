extends RefCounted
class_name IosEnergyLogSystem

const DEFAULT_PATH := "user://ios_energy_log.csv"

var enabled := false
var path := DEFAULT_PATH
var sample_timer := 0.0
var frame_times_5s: Array = []
var frame_times_30s: Array = []

func configure(should_enable: bool, custom_path: String = "") -> void:
	enabled = should_enable
	path = custom_path if custom_path != "" else DEFAULT_PATH
	sample_timer = 0.0
	frame_times_5s.clear()
	frame_times_30s.clear()

func tick(delta: float, state, ui_root: Node, optimizer) -> void:
	if not enabled or state == null or optimizer == null:
		return
	var frame_ms := delta * 1000.0
	frame_times_5s.append(frame_ms)
	frame_times_30s.append(frame_ms)
	while frame_times_5s.size() > 300:
		frame_times_5s.pop_front()
	while frame_times_30s.size() > 1800:
		frame_times_30s.pop_front()
	sample_timer += delta
	var interval := float(optimizer.budget.get("max_log_write_interval", 5.0))
	if sample_timer < interval:
		return
	sample_timer = 0.0
	var sorted := frame_times_30s.duplicate()
	sorted.sort()
	var arena = ui_root.get("arena_view") if ui_root != null else null
	var canvas_items := _count_canvas_items(ui_root)
	var transparent_layers := _count_transparent_controls(ui_root)
	var visible_effects: int = int(state.hit_flashes.size() + state.effect_lines.size() + state.floating_texts.size())
	var draw_calls: int = int(canvas_items + visible_effects + state.projectiles.size() + state.enemy_projectiles.size())
	var overdraw := float(transparent_layers) * 2.0 + float(visible_effects) * 0.08
	var score: float = float(optimizer.energy_score(state, ui_root))
	var header := "time,fps,frame_time_avg_5s,frame_time_p95_30s,draw_call_estimate,canvas_item_count,visible_effect_count,transparent_layer_count,overdraw_risk_score,ui_rebuild_count,label_update_count,minimap_redraw_count,damage_number_spawn_count,notification_spawn_count,haptic_count,audio_event_count,save_write_count,log_write_count,enemy_ai_updates,pathing_updates,battery_profile,energy_score,estimated_power_risk"
	var row := "%.2f,%d,%.3f,%.3f,%d,%d,%d,%d,%.3f,%d,%d,%d,%d,%d,%d,%d,%d,%d,%d,%d,%s,%.3f,%s" % [
		float(state.elapsed_seconds),
		Engine.get_frames_per_second(),
		_average(frame_times_5s),
		_percentile(sorted, 0.95),
		draw_calls,
		canvas_items,
		visible_effects,
		transparent_layers,
		overdraw,
		int(optimizer.ui_rebuild_count),
		int(optimizer.label_update_count),
		int(arena.minimap_update_count if arena != null else optimizer.minimap_redraw_count),
		int(state.damage_number_spawn_count),
		int(optimizer.notification_spawn_count),
		int(optimizer.haptic_count),
		int(optimizer.audio_event_count),
		int(SaveSystem.get_write_count()),
		int(optimizer.log_write_count + 1),
		int(state.enemies.size()),
		int(state.ios_pathing_update_count),
		optimizer.battery_profile,
		score,
		optimizer.estimated_power_risk(score)
	]
	_append_csv(header, row)
	optimizer.mark_log_write()

func _average(values: Array) -> float:
	if values.is_empty():
		return 0.0
	var total := 0.0
	for value in values:
		total += float(value)
	return total / float(values.size())

func _percentile(values: Array, ratio: float) -> float:
	if values.is_empty():
		return 0.0
	return float(values[clampi(int(ceil(values.size() * ratio)) - 1, 0, values.size() - 1)])

func _count_canvas_items(node: Node) -> int:
	if node == null:
		return 0
	var count := 1 if node is CanvasItem and (node as CanvasItem).is_visible_in_tree() else 0
	for child in node.get_children():
		count += _count_canvas_items(child)
	return count

func _count_transparent_controls(node: Node) -> int:
	if node == null:
		return 0
	var count := 0
	if node is ColorRect:
		var rect := node as ColorRect
		if rect.is_visible_in_tree() and rect.color.a > 0.0 and rect.color.a < 1.0:
			count = 1
	for child in node.get_children():
		count += _count_transparent_controls(child)
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
